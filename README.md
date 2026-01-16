# HRProfiler Pipeline

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![Docker](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/florpio/hrprofiler)

## Introduction

**HRProfiler Pipeline** is a Nextflow DSL2 workflow for **Homologous Recombination Deficiency (HRD)** analysis in tumor samples. The pipeline integrates somatic variant data (SNVs/Indels) and copy number alterations (CNAs) to predict HRD status, which is clinically relevant for determining patient eligibility for PARP inhibitor therapy.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         HRProfiler Pipeline                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    VCFs (Mutect2)              Segments (ASCAT/FACETS/etc.)                │
│         │                              │                                    │
│         ▼                              ▼                                    │
│   ┌──────────┐                  ┌──────────────┐                           │
│   │FILTER_VCF│ (parallel)       │PREPARE_SEGS │ (parallel)                 │
│   └────┬─────┘                  └──────┬───────┘                           │
│        │                               │                                    │
│        └───────────┬───────────────────┘                                   │
│                    │ collect()                                              │
│                    ▼                                                        │
│            ┌─────────────┐                                                  │
│            │ HRPROFILER  │ (batch processing)                              │
│            └──────┬──────┘                                                  │
│                   │                                                         │
│                   ▼                                                         │
│         HRD Predictions + Plots                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Batch processing**: Multiple samples processed efficiently in parallel
- **Automatic VCF filtering**: PASS variants, DP≥10, AF≥0.05
- **Multiple CNV formats**: Support for ASCAT, SEQUENZA, FACETS, PURPLE
- **HRD prediction**: Binary classification (HRD+/HRD-) with probabilities
- **Visualizations**: HRD probability diagnostic plots
- **Containerized**: Docker images available on Docker Hub

## Quick Start

### Requirements

- Nextflow ≥23.04.0
- Docker or Singularity
- ≥16 GB RAM (for genome processing)

### Installation

```bash
# Clone the repository
git clone https://github.com/florpio/hrprofiler-pipeline.git
cd hrprofiler-pipeline

# Verify Nextflow installation
nextflow -version
```

### Basic execution

```bash
nextflow run main.nf \
    -profile docker \
    --input samplesheet.csv \
    --outdir results
```

## Documentation

| Document | Description |
|----------|-------------|
| [Usage](docs/usage.md) | Detailed usage guide and examples |
| [Output](docs/output.md) | Output file descriptions |
| [Parameters](docs/parameters.md) | Complete parameter reference |

## Input: Samplesheet

The pipeline requires a CSV file with the following structure:

```csv
sample,vcf,vcf_index,segments
SAMPLE1,/path/to/sample1.vcf.gz,/path/to/sample1.vcf.gz.tbi,/path/to/sample1.segments.txt
SAMPLE2,/path/to/sample2.vcf.gz,/path/to/sample2.vcf.gz.tbi,/path/to/sample2.segments.txt
```

| Column | Description |
|--------|-------------|
| `sample` | Unique sample identifier |
| `vcf` | Somatic variant VCF (Mutect2, Strelka, etc.) |
| `vcf_index` | VCF index (.tbi) |
| `segments` | CNV segments file (ASCAT, FACETS, etc.) |

## Main Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | - | Samplesheet CSV (required) |
| `--outdir` | `results` | Output directory |
| `--organ` | `BREAST` | Organ type (`BREAST`, `OVARIAN`) |
| `--cnv_file_type` | `ASCAT` | CNV file format |
| `--hrd_threshold` | `0.5` | HRD probability threshold |
| `--min_dp` | `10` | Minimum depth for filtering |
| `--min_af` | `0.05` | Minimum allele frequency |

## Output

```
results/
├── filtered_vcfs/                    # Filtered VCFs
│   └── {sample}.filtered.vcf
├── prepared_segments/                # Formatted segments
│   └── {sample}.hrprofiler.segments.txt
├── hrprofiler/                       # HRProfiler results
│   └── results_hrd/
│       ├── output/
│       │   ├── hrd_predictions_organ_*.txt  # ⭐ HRD predictions
│       │   ├── hrd_probability_organ_*.pdf  # Probability plot
│       │   └── *.matrix.tsv                 # Feature matrices
│       └── logs/
└── pipeline_info/
    └── hrd_analysis_software_versions.yml
```

## Results Interpretation

The `hrd_predictions_organ_breast_model_type_wes.txt` file contains:

| Column | Description |
|--------|-------------|
| `samples` | Sample identifier |
| `hrd.prob` | HRD probability (0-1) |
| `prediction` | Classification: **0** = HRD-, **1** = HRD+ |
| `NCTG`, `NCGT` | Mutational features |
| `DEL_5_MH` | Deletions with microhomology |
| `LOH.1.40Mb` | LOH proportion |
| `3-9:HET.10.40Mb`, `2-4:HET.40Mb` | CNV features |

**Clinical interpretation:**

| prediction | hrd.prob | Interpretation |
|------------|----------|----------------|
| **1** | ≥ 0.5 | **HRD+**: Potential candidate for PARP inhibitor therapy |
| **0** | < 0.5 | **HRD-**: No evidence of HRD |
| **0** | 0.3-0.5 | **Gray zone**: Consider other factors (BRCA mutations, etc.) |

## Docker Images

| Image | Size | Description |
|-------|------|-------------|
| `florpio/hrprofiler:1.0` | ~2 GB | Requires GRCh38 genome mount |
| `florpio/hrprofiler:1.0-full` | ~20 GB | Includes GRCh38 genome |

## Pipeline Workflow

### 1. FILTER_VCF
Filters somatic variant VCFs:
- PASS variants only
- Tumor depth ≥10
- Allele frequency ≥0.05

### 2. PREPARE_SEGMENTS
Converts segment files to HRProfiler format:
```
Sample  chr  startpos  endpos  total.copy.number.inTumour  nMajor  nMinor
```

### 3. HRPROFILER
Executes HRD analysis:
- Extracts SNV features (SBS, DBS, ID)
- Extracts CNV features (CNV48)
- Applies organ-specific predictive model
- Generates predictions and visualizations

## Profiles

```bash
# Docker (recommended)
nextflow run main.nf -profile docker --input samplesheet.csv --outdir results

# Singularity (HPC)
nextflow run main.nf -profile singularity --input samplesheet.csv --outdir results
```

## Troubleshooting

### Error: "The specified genome GRCh38 has not been installed"
```bash
# Rebuild image with genome
docker build --no-cache -t florpio/hrprofiler:1.0-full -f docker/Dockerfile.full docker/
```

### Memory error
Adjust in `nextflow.config`:
```groovy
process {
    withLabel: process_medium {
        memory = '12.GB'
    }
}
```

## Citations

If you use this pipeline, please cite:

- **HRProfiler**: [Chopra et al., 2024](https://github.com/AlexandrovLab/HRProfiler)
- **SigProfilerMatrixGenerator**: [Bergstrom et al., 2019](https://bmcgenomics.biomedcentral.com/articles/10.1186/s12864-019-6041-2)
- **Nextflow**: [Di Tommaso et al., 2017](https://www.nature.com/articles/nbt.3820)

## License

MIT License

## Contact

- **Author**: Flor Pio
- **GitHub**: [github.com/florpio](https://github.com/florpio)
