process STRIPLOCI {
    tag "$meta.id"
    label 'process_single'

    container 'biocontainers/perl:5.32'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path('*.locus_only.fa'), emit: locus

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cat ${fasta} | perl -pe 's/^>.*?:/>/g; s/::.*\$//g;' > ${meta.id}.locus_only.fa
    """
}
