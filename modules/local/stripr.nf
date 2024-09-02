process STRIPR {
    tag "$meta"
    label 'process_single'

    container 'biocontainers/sed:4.8'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.rstripped.fas"), emit: locus

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    sed 's/^>_R_/>/g' ${fasta} > ${fasta.simpleName}.rstripped.fas 
    """
}
