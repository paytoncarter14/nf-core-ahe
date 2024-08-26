process SIMPLECAT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'biocontainers/pigz:2.3.4' }"

    input:
    tuple val(meta), path(file1)
    tuple val(meta2), path(file2)

    output:
    tuple val(meta), path("${prefix}.${suffix}"), emit: file_out
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    prefix   = task.ext.prefix ?: "${meta.id}"
    suffix   = task.ext.suffix ?: "${file1.extension}"
    
    if(file1 == prefix + suffix || file2 == prefix + suffix) {
        error "The name of the input file can't be the same as for the output prefix in the " +
        "module CAT_CAT (currently `$prefix`). Please choose a different one."
    }
    """
    cat \\
        $args \\
        ${file1} ${file2} \\
        > ${prefix}.${suffix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """

    stub:
    def file_list   = files_in.collect { it.toString() }
    prefix          = task.ext.prefix ?: "${meta.id}${file_list[0].substring(file_list[0].lastIndexOf('.'))}"
    if(file_list.contains(prefix.trim())) {
        error "The name of the input file can't be the same as for the output prefix in the " +
        "module CAT_CAT (currently `$prefix`). Please choose a different one."
    }
    """
    touch $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """
}
