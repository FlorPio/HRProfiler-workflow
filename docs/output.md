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
│       │   ├── snv.SBS96.all                   # SBS96 matrix (all samples)
│       │   ├── indel.ID83.all                  # ID83 matrix (all samples)
│       │   ├── cnv.CNV48.matrix.tsv            # CNV48 matrix (all samples)
│       │   ├── hrd_predictions_organ_*.txt     # ⭐ HRD PREDICTIONS
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

#### 3.1 HRD Predictions (⭐ MAIN RESULT)

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

**Clinical interpretation**:

| prediction | hrd.prob | Interpretation | Recommendation |
|------------|----------|----------------|----------------|
| **1** | ≥ 0.5 | HRD positive | Potential candidate for PARP inhibitor therapy |
| **0** | < 0.5 | HRD negative | PARPi not indicated based on HRD |
| **0** | 0.3 - 0.5 | Gray zone | Consider other clinical factors (BRCA mutations, etc.) |

**Important features for HRD**:

| Feature | Association with HRD |
|---------|---------------------|
| `DEL_5_MH` | Deletions with microhomology - MMEJ repair signature (high = HRD+) |
| `LOH.1.40Mb` | LOH in medium segments - genomic instability (high = HRD+) |
| `3-9:HET.10.40Mb` | Allelic heterozygosity - CNV pattern (high = HRD+) |

> ⚠️ **Clinical note**: This prediction should be evaluated along with other clinical factors such as:
> - BRCA1/BRCA2 mutation status
> - Family history
> - Tumor histological type
> - Consult with the medical team before making therapeutic decisions.

---

#### 3.3 Real results example

```
samples                        hrd.prob      prediction
1128_T04_vs_1128_N03          0.000001      0 (HRD-)
1229_T08_vs_1229_N07          0.000144      0 (HRD-)
711_T02_vs_711_N01            0.000016      0 (HRD-)
871_T12_vs_871_N11            0.484         0 (HRD-) ← close to threshold
IMAX014b_T01_vs_IMAX014b_N01  0.007         0 (HRD-)
IMAX1141_T01_vs_IMAX1141_N01  0.182         0 (HRD-)
IMAX1278_T01_vs_IMAX1278_N01  0.038         0 (HRD-)
```

In this example:
- **No sample is HRD+** (all prediction = 0)
- **871_T12** has the highest probability (0.484), very close to the 0.5 threshold
- Other samples have very low probabilities (<0.2)

---

#### 3.4 Visualization Plot

**File**: `hrd_probability_organ_breast_model_type_wes.pdf`

The barplot shows:
- X-axis: Samples ordered by HRD probability
- Y-axis: HRD probability (0 to 0.5+)
- Threshold line at 0.5 (if applicable)
- Taller bars = higher HRD probability

---

### 4. Feature Matrices

**SBS96 Matrix** (`snv.SBS96.all`)
- 96 single base substitution categories
- Trinucleotide context of each mutation

**ID83 Matrix** (`indel.ID83.all`)
- 83 indel categories
- Includes microhomology information

**CNV48 Matrix** (`cnv.CNV48.matrix.tsv`)
- 48 copy number alteration categories
- Based on segment size and allelic state

---

### 5. Pipeline Info (`pipeline_info/`)

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

## Accessing Results

### Quick commands

```bash
# View HRD predictions
cat results/hrprofiler/results_hrd/output/hrd_predictions_organ_*.txt

# View only main columns
cut -f2,3,4 results/hrprofiler/results_hrd/output/hrd_predictions_organ_*.txt

# Filter samples with high probability (>0.3)
awk -F'\t' 'NR==1 || $3>0.3' results/hrprofiler/results_hrd/output/hrd_predictions_organ_*.txt

# View HRD+ samples (prediction=1)
awk -F'\t' '$4==1' results/hrprofiler/results_hrd/output/hrd_predictions_organ_*.txt

# Sort by probability (descending)
sort -t$'\t' -k3 -nr results/hrprofiler/results_hrd/output/hrd_predictions_organ_*.txt | head
```

### Parsing with Python

```python
import pandas as pd

# Read predictions
predictions = pd.read_csv(
    'results/hrprofiler/results_hrd/output/hrd_predictions_organ_breast_model_type_wes.txt',
    sep='\t',
    index_col=0
)

# Show summary
print(predictions[['samples', 'hrd.prob', 'prediction']])

# Filter high probability samples
high_risk = predictions[predictions['hrd.prob'] > 0.3]
print(f"\nSamples with probability > 0.3:")
print(high_risk[['samples', 'hrd.prob', 'prediction']])

# Statistics
print(f"\nStatistics:")
print(f"  Total samples: {len(predictions)}")
print(f"  HRD+ (prediction=1): {(predictions['prediction']==1).sum()}")
print(f"  HRD- (prediction=0): {(predictions['prediction']==0).sum()}")
print(f"  Mean probability: {predictions['hrd.prob'].mean():.4f}")
print(f"  Max probability: {predictions['hrd.prob'].max():.4f}")
```

### Parsing with R

```r
library(tidyverse)

# Read predictions
predictions <- read_tsv(
  "results/hrprofiler/results_hrd/output/hrd_predictions_organ_breast_model_type_wes.txt"
)

# Summary
predictions %>%
  select(samples, hrd.prob, prediction) %>%
  arrange(desc(hrd.prob))

# Visualization
ggplot(predictions, aes(x = reorder(samples, hrd.prob), y = hrd.prob)) +
  geom_col(aes(fill = factor(prediction))) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "red") +
  scale_fill_manual(values = c("0" = "steelblue", "1" = "coral"),
                    labels = c("HRD-", "HRD+"),
                    name = "Prediction") +
  coord_flip() +
  theme_minimal() +
  labs(x = "Sample", y = "HRD Probability", 
       title = "HRD Predictions",
       subtitle = "Red line = 0.5 threshold")
```

## Quality Control

### Verify results

```bash
# Verify all samples were processed
n_input=$(tail -n+2 samplesheet.csv | wc -l)
n_output=$(tail -n+2 results/hrprofiler/results_hrd/output/hrd_predictions_organ_*.txt | wc -l)
echo "Input: $n_input samples, Output: $n_output samples"

# Verify prediction distribution
echo "=== Prediction distribution ==="
cut -f4 results/hrprofiler/results_hrd/output/hrd_predictions_organ_*.txt | sort | uniq -c

# Check logs for errors
grep -i error results/hrprofiler/results_hrd/logs/*.err 2>/dev/null || echo "No errors found"
```

### Quality indicators

| Indicator | Expected value | Concerning |
|-----------|----------------|------------|
| SNVs per sample | 50-5000 | < 20 or > 10000 |
| Indels per sample | 10-500 | < 5 |
| CNV segments | 20-200 | < 10 |
| DEL_5_MH (HRD+) | > 2 | 0 in expected HRD+ sample |
| LOH.1.40Mb (HRD+) | > 0.2 | < 0.1 in expected HRD+ sample |
