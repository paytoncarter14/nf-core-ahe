process SPLITLOCI {
    tag "$locus"
    label 'process_single'

    container 'biocontainers/grep:2.14--1'

    input:
    val(locus)
    path(fasta), stageAs: 'alignments/*'

    output:
    tuple val(meta), path("*.fa"), emit: locus

    when:
    task.ext.when == null || task.ext.when

    script:
    meta = [id: locus]
    """
    grep --no-group-separator -h -A1 "^>${locus}:" alignments/*.fa > ${locus}.fa 
    """
}
