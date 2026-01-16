# HRProfiler Pipeline: Usage Guide

## Table of Contents

- [Introduction](#introduction)
- [Running the pipeline](#running-the-pipeline)
- [Input requirements](#input-requirements)
- [Pipeline parameters](#pipeline-parameters)
- [Resource requirements](#resource-requirements)
- [Examples](#examples)

## Introduction

This pipeline analyzes tumor samples to determine their Homologous Recombination Deficiency (HRD) status. HRD is an important biomarker for selecting patients who may benefit from PARP inhibitor therapy.

### What do I need to run the pipeline?

1. **Somatic variant VCFs**: VCF file from a variant caller like Mutect2, Strelka2, or similar
2. **CNV segments**: Segment file from ASCAT, FACETS, SEQUENZA, or PURPLE
3. **Docker or Singularity**: To run containers

## Running the pipeline

### Basic command

```bash
nextflow run main.nf \
    -profile docker \
    --input samplesheet.csv \
    --outdir results
```

### With full image (includes genome)

```bash
nextflow run main.nf \
    -profile docker \
    --input samplesheet.csv \
    --outdir results
```

> **Note**: The `florpio/hrprofiler:1.0-full` image already includes the GRCh38 genome.

### With externally mounted genome

```bash
nextflow run main.nf \
    -profile docker \
    --input samplesheet.csv \
    --genome_path /path/to/genome \
    --outdir results
```

## Input requirements

### Samplesheet format

The pipeline requires a CSV with 4 columns:

```csv
sample,vcf,vcf_index,segments
TUMOR_001,/data/tumor001.vcf.gz,/data/tumor001.vcf.gz.tbi,/data/tumor001.segments.txt
TUMOR_002,/data/tumor002.vcf.gz,/data/tumor002.vcf.gz.tbi,/data/tumor002.segments.txt
```

| Column | Required | Description |
|--------|----------|-------------|
| sample | ✓ | Unique sample ID |
| vcf | ✓ | Path to somatic variant VCF |
| vcf_index | ✓ | Path to VCF index (.tbi) |
| segments | ✓ | Path to CNV segments file |

### VCF requirements

The VCF should contain:
- Somatic variants (SNVs and Indels)
- FILTER column with variants marked as PASS
- Depth (DP) and allele frequency (AF) information

**Expected header format:**
```
##fileformat=VCFv4.2
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  TUMOR   NORMAL
```

### Segments requirements

The segment file should contain copy number information. Format varies by tool:

**ASCAT format:**
```
Sample  chr  startpos  endpos  nMajor  nMinor
TUMOR_001  1  10000  50000000  2  1
```

**FACETS format:**
```
Sample  chrom  start  end  tcn.em  lcn.em
TUMOR_001  1  10000  50000000  3  1
```

The pipeline automatically converts to the format required by HRProfiler.

## Pipeline parameters

### Required parameters

| Parameter | Description |
|-----------|-------------|
| `--input` | Path to samplesheet CSV |
| `--outdir` | Output directory |

### Optional parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--organ` | BREAST | Organ type (BREAST, OVARIAN) |
| `--cnv_file_type` | ASCAT | Segment format (ASCAT, FACETS, SEQUENZA, PURPLE) |
| `--genome` | GRCh38 | Reference genome |
| `--hrd_threshold` | 0.5 | Threshold for HRD classification |
| `--min_dp` | 10 | Minimum depth for filtering |
| `--min_af` | 0.05 | Minimum allele frequency |
| `--genome_path` | null | Path to genome (only with lightweight image) |

## Resource requirements

### Memory

| Process | Minimum RAM | Recommended RAM |
|---------|-------------|-----------------|
| FILTER_VCF | 2 GB | 4 GB |
| PREPARE_SEGMENTS | 1 GB | 2 GB |
| HRPROFILER | 12 GB | 16 GB |

### Disk

- **Lightweight Docker image**: ~2 GB
- **Full Docker image**: ~20 GB
- **GRCh38 genome**: ~15 GB
- **Results per sample**: ~50 MB

### Runtime

| Number of samples | Approximate time |
|-------------------|------------------|
| 1 | 3-5 minutes |
| 10 | 10-15 minutes |
| 50 | 30-45 minutes |

## Examples

### Example 1: Breast cancer analysis

```bash
nextflow run main.nf \
    -profile docker \
    --input breast_samples.csv \
    --organ BREAST \
    --cnv_file_type ASCAT \
    --outdir breast_hrd_results
```

### Example 2: Ovarian cancer with FACETS

```bash
nextflow run main.nf \
    -profile docker \
    --input ovarian_samples.csv \
    --organ OVARIAN \
    --cnv_file_type FACETS \
    --hrd_threshold 0.7 \
    --outdir ovarian_hrd_results
```

### Example 3: HPC execution with Singularity

```bash
nextflow run main.nf \
    -profile singularity \
    --input samples.csv \
    --outdir results \
    -queue-size 50 \
    -resume
```

### Example 4: Stricter filters

```bash
nextflow run main.nf \
    -profile docker \
    --input samples.csv \
    --min_dp 20 \
    --min_af 0.10 \
    --hrd_threshold 0.6 \
    --outdir strict_results
```

## Tips and Best Practices

### Use -resume

Always use `-resume` to continue interrupted runs:

```bash
nextflow run main.nf -profile docker --input samples.csv --outdir results -resume
```

### Verify inputs before running

```bash
# Verify VCFs
for vcf in $(cut -d',' -f2 samplesheet.csv | tail -n+2); do
    bcftools view -h $vcf | head -1
done

# Verify segments
for seg in $(cut -d',' -f4 samplesheet.csv | tail -n+2); do
    head -2 $seg
done
```

### Monitor execution

```bash
# In another terminal
watch -n 5 'ls -la work/*/.*'
```
