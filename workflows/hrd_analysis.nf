/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HRD ANALYSIS WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Workflow for Homologous Recombination Deficiency analysis using HRProfiler
    
    Processes multiple samples:
    - FILTER_VCF and PREPARE_SEGMENTS run in parallel per sample
    - HRPROFILER receives all samples together for batch processing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FILTER_VCF        } from '../modules/local/filter_vcf'
include { PREPARE_SEGMENTS  } from '../modules/local/prepare_segments'
include { HRPROFILER        } from '../modules/local/hrprofiler'

workflow HRD_ANALYSIS {

    take:
    ch_samplesheet  // channel: [ meta, vcf, vcf_tbi, segments ]

    main:

    ch_versions = Channel.empty()

    // =========================================
    // Split inputs
    // =========================================
    
    ch_vcfs = ch_samplesheet
        .map { meta, vcf, tbi, segments -> [ meta, vcf, tbi ] }

    ch_segments = ch_samplesheet
        .map { meta, vcf, tbi, segments -> [ meta, segments ] }

    // =========================================
    // 1. FILTER VCFs (parallel)
    // =========================================
    
    FILTER_VCF(ch_vcfs)
    ch_versions = ch_versions.mix(FILTER_VCF.out.versions.first())

    // =========================================
    // 2. PREPARE SEGMENTS (parallel)
    // =========================================
    
    PREPARE_SEGMENTS(ch_segments)
    ch_versions = ch_versions.mix(PREPARE_SEGMENTS.out.versions.first())

    // =========================================
    // 3. RUN HRPROFILER (batch)
    // =========================================
    
    // Collect VCFs as list (without meta)
    ch_all_vcfs = FILTER_VCF.out.vcf
        .map { meta, vcf -> vcf }
        .collect()

    // Collect segments as list (without meta)
    ch_all_segments = PREPARE_SEGMENTS.out.segments
        .map { meta, segments -> segments }
        .collect()

    // Pass both lists separately (DO NOT use combine)
    HRPROFILER(
        ch_all_vcfs,
        ch_all_segments,
        file(params.hrd_script)
    )
    ch_versions = ch_versions.mix(HRPROFILER.out.versions.first())

    // =========================================
    // Collate versions
    // =========================================
    ch_versions
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'hrd_analysis_software_versions.yml',
            sort: true,
            newLine: true
        )
        .set { ch_collated_versions }

    emit:
    predictions = HRPROFILER.out.predictions
    results     = HRPROFILER.out.results
    plots       = HRPROFILER.out.plots
    versions    = ch_versions
}
