// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { SPADES            } from '../../../modules/nf-core/spades/main'
include { VSEARCH_CLUSTER   } from '../../../modules/nf-core/vsearch/cluster/main'
include { VSEARCH_SORT      } from '../../../modules/nf-core/vsearch/sort/main'
include { BLAST_MAKEBLASTDB } from '../../../modules/nf-core/blast/makeblastdb/main'
include { BLAST_TBLASTX     } from '../../../modules/local/blast_tblastx/main'
include { BLAST_TBLASTX
          as BLAST_TBLASTX2 } from '../../../modules/local/blast_tblastx/main'
include { BITSCOREFILTER    } from '../../../modules/local/bitscorefilter/main'
include { FASTASINGLELINE   } from '../../../modules/local/fastasingleline/main'
include { BLASTTOBED        } from '../../../modules/local/blasttobed/main'
include { BEDTOOLS_GETFASTA } from '../../../modules/nf-core/bedtools/getfasta/main'
include { SIMPLECAT         } from '../../../modules/local/simplecat/main'
include { GNU_SORT
          as GNU_SORT3      } from '../../../modules/nf-core/gnu/sort/main'
include { GNU_SORT
          as GNU_SORT4      } from '../../../modules/nf-core/gnu/sort/main'
include { ORTHOLOGFILTER    } from '../../../modules/local/orthologfilter/main'
include { BEDTOOLS_GETFASTA
          as ORTHOLOGS_PROBEGETFASTA } from '../../../modules/nf-core/bedtools/getfasta/main'
include { BEDTOOLS_GETFASTA
          as ORTHOLOGS_FULLGETFASTA } from '../../../modules/nf-core/bedtools/getfasta/main'


workflow AHE_ASSEMBLY {

    take:
    ch_reads  // channel (mandatory): [ val(meta), [ path(reads) ] ]
    probes // path (mandatory)
    genome_db
    probe_coordinates

    main:

    ch_versions = Channel.empty()

    // assemble reads
    SPADES ( ch_reads.map{[it[0], it[1], [], []]}, [], [] )
    ch_versions = ch_versions.mix(SPADES.out.versions.first())

    // collapse similar scaffolds
    VSEARCH_CLUSTER ( SPADES.out.scaffolds )
    ch_versions = ch_versions.mix(VSEARCH_CLUSTER.out.versions.first())

    // sort scaffolds
    VSEARCH_SORT ( VSEARCH_CLUSTER.out.centroids, '--sortbylength')
    ch_versions = ch_versions.mix(VSEARCH_SORT.out.versions.first())

    // make blast db from scaffolds
    BLAST_MAKEBLASTDB ( VSEARCH_SORT.out.fasta )
    ch_versions = ch_versions.mix(BLAST_MAKEBLASTDB.out.versions.first())

    // tblastx probes (query) to scaffolds (db)
    BLAST_TBLASTX ( BLAST_MAKEBLASTDB.out.db.map{[it[0], file(probes)]}, BLAST_MAKEBLASTDB.out.db )
    ch_versions = ch_versions.mix(BLAST_TBLASTX.out.versions.first())

    // keep probe/scaffold hits with bit scores at least 80% of top bit score per probe
    BITSCOREFILTER ( BLAST_TBLASTX.out.txt )
    ch_versions = ch_versions.mix(BITSCOREFILTER.out.versions.first())

    // put scaffold sequences on single line
    // FASTASINGLELINE ( VSEARCH_SORT.out.fasta )
    // ch_versions = ch_versions.mix(FASTASINGLELINE.out.versions.first())

    // transform probe/scaffold blast output to bed for bedtools
    BLASTTOBED ( BITSCOREFILTER.out.txt )
    ch_versions = ch_versions.mix(BLASTTOBED.out.versions.first())

    // pull regions of scaffold sequences (putative orthologs) that had tblastx probe hits
    together = BLASTTOBED.out.bed.join(VSEARCH_SORT.out.fasta)
    BEDTOOLS_GETFASTA ( together.map{it[0..1]}, together.map{it[2]} )
    ch_versions = ch_versions.mix(BEDTOOLS_GETFASTA.out.versions.first())

    // tblastx putative orthologs (query) to reference genome (db)
    BLAST_TBLASTX2 ( BEDTOOLS_GETFASTA.out.fasta, genome_db )
    ch_versions = ch_versions.mix(BLAST_TBLASTX2.out.versions.first())

    // keep only top ortholog/reference hit by bitscore for each ortholog
    GNU_SORT3 ( BLAST_TBLASTX2.out.txt )
    GNU_SORT4 ( GNU_SORT3.out.sorted )
    ch_versions = ch_versions.mix(GNU_SORT3.out.versions.first())
    ch_versions = ch_versions.mix(GNU_SORT4.out.versions.first())

    // concat ortholog/genome tblastx top hit to probes
    // SIMPLECAT ( GNU_SORT4.out.sorted, probe_coordinates )
    // ch_versions = ch_versions.mix(SIMPLECAT.out.versions.first())

    // ortholog filter: make sure putative orthologs intersect the same coordinates as the probe/reference blast
    ORTHOLOGFILTER ( GNU_SORT4.out.sorted, probe_coordinates )
    ch_versions = ch_versions.mix(ORTHOLOGFILTER.out.versions.first())

    // pull full and probe orthologs
    probe_together = ORTHOLOGFILTER.out.probe.join(VSEARCH_SORT.out.fasta)
    full_together = ORTHOLOGFILTER.out.full.join(VSEARCH_SORT.out.fasta)
    ORTHOLOGS_PROBEGETFASTA ( probe_together.map{it[0..1]}, probe_together.map{it[2]} )
    ORTHOLOGS_FULLGETFASTA ( full_together.map{it[0..1]}, full_together.map{it[2]} )

    emit:
    // TODO nf-core: edit emitted channels

    probe_orthologs = ORTHOLOGS_PROBEGETFASTA.out.fasta
    full_orthologs = ORTHOLOGS_FULLGETFASTA.out.fasta

    // bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    // bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    // csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

