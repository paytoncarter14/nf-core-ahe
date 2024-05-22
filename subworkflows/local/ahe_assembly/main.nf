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
include { BITSCOREFILTER    } from '../../../modules/local/bitscorefilter/main'
include { FASTASINGLELINE   } from '../../../modules/local/fastasingleline/main'

workflow AHE_ASSEMBLY {

    take:
    ch_reads  // channel (mandatory): [ val(meta), [ path(reads) ] ]
    probes // path (mandatory)

    main:

    ch_versions = Channel.empty()

    SPADES ( ch_reads.map{[it[0], it[1], [], []]}, [], [] )
    ch_versions = ch_versions.mix(SPADES.out.versions.first())

    VSEARCH_CLUSTER ( SPADES.out.scaffolds )
    ch_versions = ch_versions.mix(VSEARCH_CLUSTER.out.versions.first())

    VSEARCH_SORT ( VSEARCH_CLUSTER.out.centroids, '--sortbylength')
    ch_versions = ch_versions.mix(VSEARCH_SORT.out.versions.first())

    BLAST_MAKEBLASTDB ( VSEARCH_SORT.out.fasta )
    ch_versions = ch_versions.mix(BLAST_MAKEBLASTDB.out.versions.first())

    BLAST_TBLASTX (BLAST_MAKEBLASTDB.out.db.map{[it[0], file(probes)]}, BLAST_MAKEBLASTDB.out.db )
    ch_versions = ch_versions.mix(BLAST_TBLASTX.out.versions.first())

    BITSCOREFILTER (BLAST_TBLASTX.out.txt)
    ch_versions = ch_versions.mix(BITSCOREFILTER.out.versions.first())

    FASTASINGLELINE ( VSEARCH_SORT.out.fasta )
    ch_versions = ch_versions.mix(FASTASINGLELINE.out.versions.first())

    emit:
    // TODO nf-core: edit emitted channels
    // bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    // bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    // csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

