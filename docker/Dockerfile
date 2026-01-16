# =============================================================================
# Dockerfile for HRProfiler
# Imagen: florpio/hrprofiler:1.0
# =============================================================================

FROM python:3.12-slim

LABEL maintainer="Flor Pio"
LABEL description="HRProfiler for HRD analysis"
LABEL version="1.0"

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    build-essential \
    libz-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /opt

# Install base Python dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install numpy first (required by HRProfiler)
RUN pip install --no-cache-dir "numpy>=2.0.0"

# Install SigProfilerMatrixGenerator (dependency of HRProfiler)
RUN pip install --no-cache-dir SigProfilerMatrixGenerator

# Install HRProfiler from GitHub
RUN pip install --no-cache-dir git+https://github.com/AlexandrovLab/HRProfiler.git@main

# Install other potential dependencies
RUN pip install --no-cache-dir \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn

# =============================================================================
# NOTE REGARDING GRCh38 GENOME:
# The genome is ~15GB and takes a long time to download during the build.
# Options:
#   1. Download it into the container (increases image size)
#   2. Mount it as a volume at runtime (recommended for production)
#
# To include it in the image (uncomment the next line):
# RUN python -c "from SigProfilerMatrixGenerator import install as genInstall; genInstall.install('GRCh38', rsync=False, bash=True)"
#
# To mount it at runtime, use:
# docker run -v /path/to/genome:/root/.SigProfilerMatrixGenerator florpio/hrprofiler:1.0
# =============================================================================

# Create directory for the genome (can be mounted as a volume)
RUN mkdir -p /root/.SigProfilerMatrixGenerator/references

# Copy verification script
COPY --chmod=755 <<EOF /opt/check_install.py
#!/usr/bin/env python3
"""Verificar instalación de HRProfiler"""
import sys

def check():
    errors = []
    
    try:
        import numpy
        print(f"✓ numpy {numpy.__version__}")
    except ImportError as e:
        errors.append(f"✗ numpy: {e}")
    
    try:
        import HRProfiler
        print(f"✓ HRProfiler installed")
    except ImportError as e:
        errors.append(f"✗ HRProfiler: {e}")
    
    try:
        from SigProfilerMatrixGenerator import install
        print(f"✓ SigProfilerMatrixGenerator installed")
    except ImportError as e:
        errors.append(f"✗ SigProfilerMatrixGenerator: {e}")
    
    if errors:
        print("\nErrors:")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)
    else:
        print("\n✓ All dependencies installed correctly")
        sys.exit(0)

if __name__ == "__main__":
    check()
EOF

# Verify installation
RUN python /opt/check_install.py

# Default working directory
WORKDIR /data

# DO NOT use a fixed ENTRYPOINT - Nextflow needs to execute bash
# To run manually: docker run --rm florpio/hrprofiler:1.0 python script.py
CMD ["/bin/bash"]
