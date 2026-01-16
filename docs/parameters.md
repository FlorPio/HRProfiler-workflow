# HRProfiler Pipeline: Parameters Reference

## Required Parameters

### `--input`

- **Type**: Path (string)
- **Required**: Yes
- **Description**: Path to the input samplesheet CSV file

```bash
--input /path/to/samplesheet.csv
```

### `--outdir`

- **Type**: Path (string)
- **Required**: Yes
- **Default**: `results`
- **Description**: Output directory for results

```bash
--outdir /path/to/results
```

---

## Analysis Parameters

### `--organ`

- **Type**: String
- **Required**: No
- **Default**: `BREAST`
- **Options**: `BREAST`, `OVARIAN`
- **Description**: Organ type for HRD prediction model. Different models are optimized for breast and ovarian cancer.

```bash
--organ BREAST
--organ OVARIAN
```

### `--cnv_file_type`

- **Type**: String
- **Required**: No
- **Default**: `ASCAT`
- **Options**: `ASCAT`, `SEQUENZA`, `FACETS`, `PURPLE`
- **Description**: Format of the input CNV segments file

```bash
--cnv_file_type ASCAT
--cnv_file_type FACETS
```

### `--genome`

- **Type**: String
- **Required**: No
- **Default**: `GRCh38`
- **Options**: `GRCh38`, `GRCh37`
- **Description**: Reference genome version

```bash
--genome GRCh38
```

### `--hrd_threshold`

- **Type**: Float
- **Required**: No
- **Default**: `0.5`
- **Range**: 0.0 - 1.0
- **Description**: Probability threshold for HRD classification. Samples with HRD_probability >= threshold are classified as HRD+.

```bash
--hrd_threshold 0.5    # Standard
--hrd_threshold 0.7    # More stringent
--hrd_threshold 0.3    # More sensitive
```

---

## VCF Filtering Parameters

### `--min_dp`

- **Type**: Integer
- **Required**: No
- **Default**: `10`
- **Description**: Minimum read depth in tumor for variant inclusion

```bash
--min_dp 10   # Standard
--min_dp 20   # More stringent
--min_dp 5    # Less stringent (low coverage data)
```

### `--min_af`

- **Type**: Float
- **Required**: No
- **Default**: `0.05`
- **Range**: 0.0 - 1.0
- **Description**: Minimum allele frequency in tumor for variant inclusion

```bash
--min_af 0.05    # Standard (5%)
--min_af 0.10    # More stringent (10%)
--min_af 0.01    # High sensitivity (1%)
```

---

## Docker/Container Parameters

### `--genome_path`

- **Type**: Path (string)
- **Required**: No (only needed with `florpio/hrprofiler:1.0`)
- **Default**: `null`
- **Description**: Path to pre-downloaded SigProfilerMatrixGenerator genome. Not needed when using `florpio/hrprofiler:1.0-full`.

```bash
--genome_path /home/user/.SigProfilerMatrixGenerator
```

---

## Script Parameters

### `--hrd_script`

- **Type**: Path (string)
- **Required**: No
- **Default**: `${projectDir}/bin/HRD.py`
- **Description**: Path to HRProfiler wrapper script

```bash
--hrd_script /path/to/custom/HRD.py
```

---

## Nextflow Parameters

These are standard Nextflow parameters:

### `-profile`

- **Options**: `docker`, `singularity`, `conda`, `test`
- **Description**: Configuration profile to use

```bash
-profile docker
-profile singularity
-profile docker,test
```

### `-resume`

- **Description**: Resume previous run from cached results

```bash
-resume
```

### `-work-dir`

- **Default**: `work`
- **Description**: Directory for intermediate files

```bash
-work-dir /scratch/nextflow_work
```

### `-with-report`

- **Description**: Generate HTML execution report

```bash
-with-report report.html
```

### `-with-timeline`

- **Description**: Generate HTML timeline

```bash
-with-timeline timeline.html
```

### `-with-dag`

- **Description**: Generate DAG visualization

```bash
-with-dag pipeline_dag.png
```

---

## Configuration File

Parameters can also be set in `nextflow.config` or a custom config file:

```groovy
params {
    // Input/Output
    input                = null
    outdir               = 'results'
    
    // Analysis
    organ                = 'BREAST'
    cnv_file_type        = 'ASCAT'
    genome               = 'GRCh38'
    hrd_threshold        = 0.5
    
    // Filtering
    min_dp               = 10
    min_af               = 0.05
    
    // Scripts
    hrd_script           = "${projectDir}/bin/HRD.py"
    
    // Container
    genome_path          = null
}
```

### Using custom config

```bash
nextflow run main.nf -c custom.config --input samplesheet.csv
```

---

## Parameter Combinations

### Standard breast cancer analysis

```bash
nextflow run main.nf \
    -profile docker \
    --input samples.csv \
    --outdir results \
    --organ BREAST \
    --cnv_file_type ASCAT \
    --hrd_threshold 0.5
```

### Stringent ovarian cancer analysis

```bash
nextflow run main.nf \
    -profile docker \
    --input samples.csv \
    --outdir results_stringent \
    --organ OVARIAN \
    --cnv_file_type FACETS \
    --min_dp 20 \
    --min_af 0.10 \
    --hrd_threshold 0.7
```

### High-sensitivity analysis (low tumor purity)

```bash
nextflow run main.nf \
    -profile docker \
    --input samples.csv \
    --outdir results_sensitive \
    --organ BREAST \
    --min_dp 5 \
    --min_af 0.01 \
    --hrd_threshold 0.3
```

---

## Parameter Validation

The pipeline validates parameters at startup. Invalid values will cause an error:

| Parameter | Validation |
|-----------|------------|
| `--input` | File must exist |
| `--organ` | Must be BREAST or OVARIAN |
| `--cnv_file_type` | Must be ASCAT, SEQUENZA, FACETS, or PURPLE |
| `--hrd_threshold` | Must be between 0.0 and 1.0 |
| `--min_dp` | Must be positive integer |
| `--min_af` | Must be between 0.0 and 1.0 |
