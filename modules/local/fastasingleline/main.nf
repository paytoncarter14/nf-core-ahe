process FASTASINGLELINE {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    if ("${fasta}" == "${prefix}.fa") error "Input and output names are the same, set prefix in module configuration to disambiguate!"

    """
    zcat -f ${fasta} | perl -pe '\$. > 1 and /^>/ ? print "\n" : chomp' > ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        zcat: \$(zcat --version | sed -n 's/zcat (gzip) \\(.*\\)\$/\\1/p')
        perl: \$(perl --version | sed -n 's/.*(v\\(.*\\)).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        zcat: \$(zcat --version | sed -n 's/zcat (gzip) \\(.*\\)\$/\\1/p')
        perl: \$(perl --version | sed -n 's/.*(v\\(.*\\)).*/\\1/p')
    END_VERSIONS
    """
}
