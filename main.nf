#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { AHE                     } from './workflows/ahe'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_ahe_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_ahe_pipeline'

workflow NFCORE_AHE {

    take:
    samplesheet

    main:
    AHE (
        samplesheet
    )

}

workflow {

    main:
    PIPELINE_INITIALISATION (
        params.version,
        params.help,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input
    )

    NFCORE_AHE (
        PIPELINE_INITIALISATION.out.samplesheet
    )

    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        []
    )
}