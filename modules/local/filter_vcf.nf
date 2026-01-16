process FILTER_VCF {
    tag "${meta.id}"
    label 'process_low'

    conda "bioconda::bcftools=1.19"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.19--h8b25389_1' :
        'quay.io/biocontainers/bcftools:1.19--h8b25389_1' }"

    input:
    tuple val(meta), path(vcf), path(tbi)

    output:
    tuple val(meta), path("*.filtered.vcf"), emit: vcf
    path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    // Default filters: PASS, tumor DP>=10, tumor AF>=0.05
    def min_dp = task.ext.min_dp ?: 10
    def min_af = task.ext.min_af ?: 0.05
    def filter_expr = task.ext.filter_expr ?: "FORMAT/AD[1:1]>=${min_dp} && FORMAT/AF[1:0]>=${min_af}"
    """
    bcftools view \\
        -f PASS \\
        -i '${filter_expr}' \\
        ${vcf} \\
        -O v \\
        -o ${prefix}.filtered.vcf \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -1 | sed 's/bcftools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.filtered.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -1 | sed 's/bcftools //')
    END_VERSIONS
    """
}
