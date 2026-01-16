process PREPARE_SEGMENTS {
    tag "${meta.id}"
    label 'process_single'

    // Solo usa bash/awk, no necesita container específico
    conda "conda-forge::coreutils=9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
        'ubuntu:22.04' }"

    input:
    tuple val(meta), path(segments)

    output:
    tuple val(meta), path("*.hrprofiler.segments.txt"), emit: segments
    path "versions.yml",                                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Convertir formato ASCAT a formato HRProfiler
    # Input:  sample, chr, start, end, nMajor, nMinor (u otro formato)
    # Output: Sample, chr, startpos, endpos, total.copy.number.inTumour, nMajor, nMinor
    
    awk -v sample="${prefix}" 'BEGIN {OFS="\\t"} 
    NR==1 {
        # Imprimir header esperado por HRProfiler
        print "Sample", "chr", "startpos", "endpos", "total.copy.number.inTumour", "nMajor", "nMinor"
    } 
    NR>1 {
        chr = \$2
        start = \$3
        end = \$4
        nMajor = \$5
        nMinor = \$6
        total = nMajor + nMinor
        print sample, chr, start, end, total, nMajor, nMinor
    }' ${segments} > ${prefix}.hrprofiler.segments.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | head -1 | sed 's/GNU Awk //' | sed 's/,.*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e "Sample\\tchr\\tstartpos\\tendpos\\ttotal.copy.number.inTumour\\tnMajor\\tnMinor" > ${prefix}.hrprofiler.segments.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | head -1 | sed 's/GNU Awk //' | sed 's/,.*//')
    END_VERSIONS
    """
}
