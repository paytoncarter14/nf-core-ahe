include {BLAST_MAKEBLASTDB    } from '../../modules/nf-core/blast/makeblastdb/main'
include {BLAST_BLASTN         } from '../../modules/nf-core/blast/blastn/main'
include {GNU_SORT             } from '../../modules/nf-core/gnu/sort/main'
include {GNU_SORT as GNU_SORT2} from '../../modules/nf-core/gnu/sort/main'

workflow PREPARE_REFERENCE {

    take:
    ch_genome
    ch_probes

    main:

    ch_versions = Channel.empty()

    // make reference genome blast db
    BLAST_MAKEBLASTDB ([[id: ch_genome.baseName], ch_genome])
    ch_versions = ch_versions.mix(BLAST_MAKEBLASTDB.out.versions.first())

    // blastn probes to reference genome
    BLAST_BLASTN ([[id: ch_probes.baseName], ch_probes], BLAST_MAKEBLASTDB.out.db)
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions.first())

    // sort probe/reference hits by bitscore
    GNU_SORT (BLAST_BLASTN.out.txt)
    ch_versions = ch_versions.mix(GNU_SORT.out.versions.first())

    // keep only best probe/reference hit by bitscore
    GNU_SORT2 (GNU_SORT.out.sorted)
    ch_versions = ch_versions.mix(GNU_SORT2.out.versions.first())

    emit:
    db = BLAST_MAKEBLASTDB.out.db.first()
    blast = GNU_SORT2.out.sorted.first()
    versions = ch_versions
}

