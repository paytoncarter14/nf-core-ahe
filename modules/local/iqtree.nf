process IQTREE {
    tag "iqtree"
    label 'process_high'

    container 'biocontainers/iqtree:2.3.4--h21ec9f0_0'

    input:
    path(fasta), stageAs: 'alignments/*'

    output:
    path("*.treefile"), emit: tree
    path("*.model.gz"), emit: model_checkpoint
    path("*.ckp.gz"),   emit: tree_checkpoint

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    if [ -e ${workDir}/iqtree_checkpoint ]; then
        cp ${workDir}/iqtree_checkpoint/alignments.* .
    fi

    ln -sfn \${PWD} ${workDir}/iqtree_checkpoint
    iqtree -s alignments 
    """
}
