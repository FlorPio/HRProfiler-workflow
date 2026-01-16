# HRProfiler Pipeline: Output Documentation

## Output Directory Structure

```
results/
├── filtered_vcfs/                          # Step 1: Filtered VCFs
│   ├── SAMPLE1.filtered.vcf
│   ├── SAMPLE2.filtered.vcf
│   └── ...
│
├── prepared_segments/                      # Step 2: Prepared segments
│   ├── SAMPLE1.hrprofiler.segments.txt
│   ├── SAMPLE2.hrprofiler.segments.txt
│   └── ...
│
├── hrprofiler/                             # Step 3: HRProfiler results
│   └── results_hrd/
│       ├── output/
│       │   ├── hrd_predictions_organ_*.txt     # HRD PREDICTIONS
│       │   └── hrd_probability_organ_*.pdf     # Probability plot
│       └── logs/
│           ├── HRProfiler_YYYY-MM-DD.out
│           └── HRProfiler_YYYY-MM-DD.err
│
└── pipeline_info/
    └── hrd_analysis_software_versions.yml   # Software versions
```

## Detailed File Descriptions

### 1. Filtered VCFs (`filtered_vcfs/`)

Quality-filtered VCFs.

**File**: `{sample}.filtered.vcf`

**Filters applied**:
- FILTER = PASS
- Tumor DP ≥ 10 (configurable with `--min_dp`)
- Tumor AF ≥ 0.05 (configurable with `--min_af`)

**Usage**: These VCFs can be used for other downstream analyses.

---

### 2. Prepared Segments (`prepared_segments/`)

Segment files converted to HRProfiler format.

**File**: `{sample}.hrprofiler.segments.txt`

**Format**:
```
Sample	chr	startpos	endpos	total.copy.number.inTumour	nMajor	nMinor
SAMPLE1	1	10000	5000000	3	2	1
SAMPLE1	1	5000001	10000000	2	1	1
```

| Column | Description |
|--------|-------------|
| Sample | Sample ID |
| chr | Chromosome (1-22, X, Y) |
| startpos | Segment start position |
| endpos | Segment end position |
| total.copy.number.inTumour | Total copy number |
| nMajor | Major allele |
| nMinor | Minor allele |

---

### 3. HRProfiler Results (`hrprofiler/results_hrd/output/`)

#### 3.1 HRD Predictions ( MAIN RESULT)

**File**: `hrd_predictions_organ_breast_model_type_wes.txt`

**Example content**:
```
	samples	hrd.prob	prediction	NCTG	NCGT	DEL_5_MH	LOH.1.40Mb	3-9:HET.10.40Mb	2-4:HET.40Mb
0	1128_T04_vs_1128_N03	1.31e-06	0	0.707	0.002	0	0.094	0.0	0.625
1	871_T12_vs_871_N11	0.484	0	0.274	0.027	0	0.363	0.175	0.175
```

| Column | Description | Range/Values |
|--------|-------------|--------------|
| samples | Sample ID | - |
| **hrd.prob** | HRD probability | 0.0 - 1.0 |
| **prediction** | Binary classification | 0 = HRD-, 1 = HRD+ |
| NCTG | Proportion of N→C mutations in TG context | 0.0 - 1.0 |
| NCGT | Proportion of N→C mutations in GT context | 0.0 - 1.0 |
| DEL_5_MH | Deletions with microhomology ≥5bp | Count |
| LOH.1.40Mb | Proportion of LOH segments 1-40Mb | 0.0 - 1.0 |
| 3-9:HET.10.40Mb | Proportion of heterozygous segments 10-40Mb with CN 3-9 | 0.0 - 1.0 |
| 2-4:HET.40Mb | Proportion of heterozygous segments >40Mb with CN 2-4 | 0.0 - 1.0 |

---

#### 3.2 Results Interpretation

**Key columns**:

| Column | Description |
|--------|-------------|
| `hrd.prob` | HRD probability (0 to 1). Higher values = greater HRD evidence |
| `prediction` | Final classification: **0** = HRD negative, **1** = HRD positive |


**Important features for HRD**:

| Feature | Association with HRD |
|---------|---------------------|
| `DEL_5_MH` | Deletions with microhomology - MMEJ repair signature (high = HRD+) |
| `LOH.1.40Mb` | LOH in medium segments - genomic instability (high = HRD+) |
| `3-9:HET.10.40Mb` | Allelic heterozygosity - CNV pattern (high = HRD+) |



---

#### 3.3 Visualization Plot

**File**: `hrd_probability_organ_breast_model_type_wes.pdf`

The barplot shows:
- X-axis: Samples ordered by HRD probability
- Y-axis: HRD probability (0 to 0.5+)
- Threshold line at 0.5 (if applicable)
- Taller bars = higher HRD probability

---

### 4. Pipeline Info (`pipeline_info/`)

**File**: `hrd_analysis_software_versions.yml`

```yaml
HRPROFILER_PIPELINE:HRD_ANALYSIS:FILTER_VCF:
    bcftools: 1.19
HRPROFILER_PIPELINE:HRD_ANALYSIS:PREPARE_SEGMENTS:
    awk: GNU Awk 5.1.0
HRPROFILER_PIPELINE:HRD_ANALYSIS:HRPROFILER:
    python: 3.12.0
    hrprofiler: 1.0.0
    vcf_samples: 7
    segment_samples: 7
```
