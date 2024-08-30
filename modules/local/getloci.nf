process GETLOCI {
    tag "$meta"
    label 'process_single'

    container 'biocontainers/grep:2.14--1'

    input:
    path(fasta)

    output:
    path("loci.txt"), emit: loci

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    grep "^>" --no-group-separator -h ${fasta} | sed 's/^>//g' > loci.txt 
    """
}
