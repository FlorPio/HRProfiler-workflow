# Docker Images for HRProfiler

## Available Images

| Image  | Size   | Description |
|--------|--------|-------------|
| `florpio/hrprofiler:1.0` | ~2GB | Lightweight image, requires mounting genome |
| `florpio/hrprofiler:1.0-full` | ~20GB | Full image with GRCh38 genome included |

## Build

```bash
cd docker/

# Lightweight image (recommended)
./build.sh --light

# Full image (includes genome, takes ~1 hour)
./build.sh --full

# Both
./build.sh --all

# Test
./build.sh --test

# Push to Docker Hub
./build.sh --push
```

## Usage

### Option 1: Lightweight Image + Mounted Genome (Recommended)

This option is more efficient because:
- The image is small (~2GB)
- The genome is downloaded only once on your system.
- Multiple containers can share the same genome.

**Step 1: Download genome (only once)**

```bash
# Create directory for the genome
mkdir -p ~/hrprofiler_genome

# Download genome using the container
docker run --rm \
    -v ~/hrprofiler_genome:/root/.SigProfilerMatrixGenerator \
    florpio/hrprofiler:1.0 \
    -c "from SigProfilerMatrixGenerator import install as genInstall; genInstall.install('GRCh38', rsync=False, bash=True)"
```

**Step 2: Run HRProfiler**

```bash
docker run --rm \
    -v ~/hrprofiler_genome:/root/.SigProfilerMatrixGenerator \
    -v /path/to/data:/data \
    florpio/hrprofiler:1.0 \
    /data/HRD.py \
        --snv-dir /data/snv \
        --cnv-dir /data/cnv \
        --output-dir /data/results
```

### Option 2: Full Image

Simpler, but the image is large:

```bash
docker run --rm \
    -v /path/to/data:/data \
    florpio/hrprofiler:1.0-full \
    /data/HRD.py \
        --snv-dir /data/snv \
        --cnv-dir /data/cnv \
        --output-dir /data/results
```

## Usage with Nextflow

In `nextflow.config`:

```groovy
process {
    withName: 'HRPROFILER' {
        container = 'florpio/hrprofiler:1.0'
        
        // Mount genome (if using lightweight image)
        containerOptions = '-v /path/to/genome:/root/.SigProfilerMatrixGenerator'
    }
}
```

Or for the full image:

```groovy
process {
    withName: 'HRPROFILER' {
        container = 'florpio/hrprofiler:1.0-full'
    }
}
```

## Usage with Singularity

```bash
# Convert Docker image to Singularity
singularity pull hrprofiler_1.0.sif docker://florpio/hrprofiler:1.0

# Run
singularity exec \
    --bind ~/hrprofiler_genome:/root/.SigProfilerMatrixGenerator \
    --bind /path/to/data:/data \
    hrprofiler_1.0.sif \
    python /data/HRD.py --snv-dir /data/snv --cnv-dir /data/cnv --output-dir /data/results
```

## Verify Installation

```bash
# Verify dependencies
docker run --rm florpio/hrprofiler:1.0 /opt/check_install.py

# Expected Output:
# ✓ numpy 2.x.x
# ✓ HRProfiler installed
# ✓ SigProfilerMatrixGenerator installed
# ✓ All dependencies installed correctly
```

## Troubleshooting

### Error: Genome not found

If you see errors about the genome not being found:

```
FileNotFoundError: GRCh38 reference not installed
```

Solution: Download the genome or use the`-full` image:

```bash
# Download genome
docker run --rm \
    -v ~/hrprofiler_genome:/root/.SigProfilerMatrixGenerator \
    florpio/hrprofiler:1.0 \
    -c "from SigProfilerMatrixGenerator import install as genInstall; genInstall.install('GRCh38', rsync=False, bash=True)"
```

### Error: Permission denied

If there are permission issues with mounted volumes:

```bash
docker run --rm \
    --user $(id -u):$(id -g) \
    -v /path/to/data:/data \
    florpio/hrprofiler:1.0 ...
```

### Insufficient Memory

HRProfiler may need a lot of RAM. Increase limits:

```bash
docker run --rm \
    --memory=16g \
    -v /path/to/data:/data \
    florpio/hrprofiler:1.0 ...
```
