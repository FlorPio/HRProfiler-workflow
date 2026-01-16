# =============================================================================
# Dockerfile para HRProfiler
# Imagen: florpio/hrprofiler:1.0
# =============================================================================

FROM python:3.12-slim

LABEL maintainer="Flor Pio"
LABEL description="HRProfiler for HRD analysis"
LABEL version="1.0"

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Instalar dependencias del sistema
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

# Crear directorio de trabajo
WORKDIR /opt

# Instalar dependencias Python base
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Instalar numpy primero (requerido por HRProfiler)
RUN pip install --no-cache-dir "numpy>=2.0.0"

# Instalar SigProfilerMatrixGenerator (dependencia de HRProfiler)
RUN pip install --no-cache-dir SigProfilerMatrixGenerator

# Instalar HRProfiler desde GitHub
RUN pip install --no-cache-dir git+https://github.com/AlexandrovLab/HRProfiler.git@main

# Instalar otras dependencias que pueda necesitar
RUN pip install --no-cache-dir \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn

# =============================================================================
# NOTA SOBRE EL GENOMA GRCh38:
# El genoma es ~15GB y tarda mucho en descargar durante el build.
# Opciones:
#   1. Descargarlo en el container (aumenta tamaño de imagen)
#   2. Montarlo como volumen en runtime (recomendado para producción)
#
# Para incluirlo en la imagen (descomentar siguiente línea):
# RUN python -c "from SigProfilerMatrixGenerator import install as genInstall; genInstall.install('GRCh38', rsync=False, bash=True)"
#
# Para montarlo en runtime, usar:
# docker run -v /path/to/genome:/root/.SigProfilerMatrixGenerator florpio/hrprofiler:1.0
# =============================================================================

# Crear directorio para el genoma (se puede montar como volumen)
RUN mkdir -p /root/.SigProfilerMatrixGenerator/references

# Copiar script de verificación
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

# Verificar instalación
RUN python /opt/check_install.py

# Directorio de trabajo por defecto
WORKDIR /data

# NO usar ENTRYPOINT fijo - Nextflow necesita ejecutar bash
# Para correr manualmente: docker run --rm florpio/hrprofiler:1.0 python script.py
CMD ["/bin/bash"]
