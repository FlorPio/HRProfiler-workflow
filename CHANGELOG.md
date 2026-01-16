# Changelog

All notable changes to the HRProfiler Pipeline will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-12

### Added

- Initial release of HRProfiler Pipeline
- **FILTER_VCF module**: Filters somatic VCFs by PASS status, depth, and allele frequency
- **PREPARE_SEGMENTS module**: Converts CNV segments to HRProfiler format
- **HRPROFILER module**: Executes HRD analysis with batch processing support
- Support for multiple CNV file formats: ASCAT, SEQUENZA, FACETS, PURPLE
- Support for breast and ovarian cancer models
- Docker images published to Docker Hub:
  - `florpio/hrprofiler:1.0` (lightweight, requires genome mount)
  - `florpio/hrprofiler:1.0-full` (includes GRCh38 genome)
- Comprehensive documentation:
  - README.md with quick start guide
  - docs/usage.md with detailed usage instructions
  - docs/output.md with output file descriptions
  - docs/parameters.md with parameter reference
- Example samplesheet in `assets/`

### Technical Details

- Built with Nextflow DSL2
- Uses `collect()` operator for efficient batch processing
- Configurable VCF filtering parameters
- Automatic conversion of CNV formats
- Software versions tracking

### Known Issues

- HRProfiler output directory requires trailing `/` in path
- Docker ENTRYPOINT must use `CMD ["/bin/bash"]` not `ENTRYPOINT ["python"]`
- Genome build with `--no-cache` required for full image

## [Unreleased]

### Planned Features

- Singularity definition file for HPC environments
- Integration with nf-core/sarek pipeline
- Support for additional CNV callers
- HTML report generation
- MultiQC integration
