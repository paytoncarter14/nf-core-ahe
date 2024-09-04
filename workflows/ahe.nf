include {AHE_ASSEMBLY     } from '../subworkflows/local/ahe_assembly'
include {PREPARE_REFERENCE} from '../subworkflows/local/prepare_reference'

include {FASTP    } from '../modules/nf-core/fastp/main'
include {GETLOCI  } from '../modules/local/getloci'
include {SPLITLOCI} from '../modules/local/splitloci'
include {STRIPLOCI} from '../modules/local/striploci'
include {MAFFT    } from '../modules/nf-core/mafft/main'
include {STRIPR   } from '../modules/local/stripr'
include {IQTREE   } from '../modules/local/iqtree'

include {softwareVersionsToYAML} from '../subworkflows/nf-core/utils_nfcore_pipeline'

workflow AHE {

    take:
    ch_samplesheet

    main:

    ch_versions = Channel.empty()
    ch_reference = file(params.reference)
    ch_probes = file(params.probes)

    // subworkflow: prepare_reference
    PREPARE_REFERENCE (ch_reference, ch_probes)

    // filter adapters, gather sequencing qc with fastp
    FASTP (ch_samplesheet, [], false, false)
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    // subworkflow: ahe_assembly
    AHE_ASSEMBLY (FASTP.out.reads, ch_probes, PREPARE_REFERENCE.out.db, PREPARE_REFERENCE.out.blast)

    // get loci names
    GETLOCI (ch_probes)

    // split orthologs into one fasta per locus
    SPLITLOCI ( GETLOCI.out.loci.splitCsv().map{it[0]}, AHE_ASSEMBLY.out.probe_orthologs.map{it[1]}.collect() )

    // strip locus and scaffold info
    STRIPLOCI ( SPLITLOCI.out.locus )

    // mafft alignment
    MAFFT ( STRIPLOCI.out.locus, [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ], false )

    // strip _R_ from reverse complement sequences
    STRIPR ( MAFFT.out.fas )

    // iqtree
    IQTREE ( STRIPR.out.locus.map{it[1]}.collect() )
    
    // Collate and save software versions
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    emit:
    versions = ch_versions
}