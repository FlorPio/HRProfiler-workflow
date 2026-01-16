process HRPROFILER {
    tag "batch"
    label 'process_medium'

    // Container with HRProfiler and GRCh38 genome included
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://florpio/hrprofiler:1.0-full' :
        'docker.io/florpio/hrprofiler:1.0-full' }"

    input:
    path(vcfs)              // List of VCFs (staged in work dir)
    path(segments)          // List of segments (staged in work dir)
    path(hrd_script)        // HRD.py script

    output:
    path("results_hrd/output/*.pdf"),           emit: plots,       optional: true
    path("results_hrd/output/*predictions*"),   emit: predictions, optional: true
    path("results_hrd/output/*"),               emit: results,     optional: true
    path("results_hrd/logs/*"),                 emit: logs,        optional: true
    path "versions.yml",                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    def organ = task.ext.organ ?: params.organ ?: 'BREAST'
    def genome = task.ext.genome ?: params.genome ?: 'GRCh38'
    def cnv_file_type = task.ext.cnv_file_type ?: params.cnv_file_type ?: 'ASCAT'
    def hrd_threshold = task.ext.hrd_threshold ?: params.hrd_threshold ?: 0.5
    
    // Count samples (vcfs can be a list or single file)
    def vcf_list = vcfs instanceof List ? vcfs : [vcfs]
    def seg_list = segments instanceof List ? segments : [segments]
    def n_vcfs = vcf_list.size()
    def n_segs = seg_list.size()
    """
    # Create directories
    mkdir -p snv_input cnv_input

    # Copy VCFs - use glob because Nextflow already staged the files
    echo "=== Staged VCF files ==="
    ls -la *.filtered.vcf 2>/dev/null || ls -la *.vcf 2>/dev/null || echo "No VCFs found"
    
    echo "=== Staged segment files ==="
    ls -la *.segments.txt 2>/dev/null || ls -la *.txt 2>/dev/null || echo "No segments found"

    # Copy all VCFs to snv_input directory
    for f in *.filtered.vcf; do
        [ -f "\$f" ] && cp "\$f" snv_input/
    done

    # Copy all segments to cnv_input directory
    for f in *.hrprofiler.segments.txt; do
        [ -f "\$f" ] && cp "\$f" cnv_input/
    done

    # Debug: show copied files
    echo "=== VCFs in snv_input ==="
    ls -la snv_input/
    echo "=== Segments in cnv_input ==="
    ls -la cnv_input/

    # Debug: verify genome
    echo "=== Checking genome installation ==="
    ls -la /root/.SigProfilerMatrixGenerator/references/ 2>/dev/null || echo "Genome directory not found"

    # Run HRProfiler
    python ${hrd_script} \\
        --snv-dir snv_input \\
        --cnv-dir cnv_input \\
        --output-dir results_hrd/ \\
        --organ ${organ} \\
        --genome ${genome} \\
        --cnv-file-type ${cnv_file_type} \\
        --hrd-threshold ${hrd_threshold} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //')
        hrprofiler: \$(python -c "import HRProfiler; print(HRProfiler.__version__)" 2>/dev/null || echo "unknown")
        vcf_samples: ${n_vcfs}
        segment_samples: ${n_segs}
    END_VERSIONS
    """

    stub:
    """
    mkdir -p results_hrd/output results_hrd/logs
    touch results_hrd/output/hrd_predictions.txt
    touch results_hrd/output/hrd_probability.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //')
        hrprofiler: "stub"
    END_VERSIONS
    """
}
