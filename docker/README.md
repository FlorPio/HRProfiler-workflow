# Docker Images para HRProfiler

## Imágenes disponibles

| Imagen | Tamaño | Descripción |
|--------|--------|-------------|
| `florpio/hrprofiler:1.0` | ~2GB | Imagen ligera, requiere montar genoma |
| `florpio/hrprofiler:1.0-full` | ~20GB | Imagen completa con genoma GRCh38 incluido |

## Construcción

```bash
cd docker/

# Imagen ligera (recomendada)
./build.sh --light

# Imagen completa (incluye genoma, tarda ~1 hora)
./build.sh --full

# Ambas
./build.sh --all

# Probar
./build.sh --test

# Publicar a Docker Hub
./build.sh --push
```

## Uso

### Opción 1: Imagen ligera + Genoma montado (Recomendado)

Esta opción es más eficiente porque:
- La imagen es pequeña (~2GB)
- El genoma se descarga una sola vez en tu sistema
- Múltiples containers pueden compartir el mismo genoma

**Paso 1: Descargar genoma (solo una vez)**

```bash
# Crear directorio para el genoma
mkdir -p ~/hrprofiler_genome

# Descargar genoma usando el container
docker run --rm \
    -v ~/hrprofiler_genome:/root/.SigProfilerMatrixGenerator \
    florpio/hrprofiler:1.0 \
    -c "from SigProfilerMatrixGenerator import install as genInstall; genInstall.install('GRCh38', rsync=False, bash=True)"
```

**Paso 2: Ejecutar HRProfiler**

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

### Opción 2: Imagen completa

Más simple pero la imagen es grande:

```bash
docker run --rm \
    -v /path/to/data:/data \
    florpio/hrprofiler:1.0-full \
    /data/HRD.py \
        --snv-dir /data/snv \
        --cnv-dir /data/cnv \
        --output-dir /data/results
```

## Uso con Nextflow

En `nextflow.config`:

```groovy
process {
    withName: 'HRPROFILER' {
        container = 'florpio/hrprofiler:1.0'
        
        // Montar genoma (si usas imagen ligera)
        containerOptions = '-v /path/to/genome:/root/.SigProfilerMatrixGenerator'
    }
}
```

O para la imagen completa:

```groovy
process {
    withName: 'HRPROFILER' {
        container = 'florpio/hrprofiler:1.0-full'
    }
}
```

## Uso con Singularity

```bash
# Convertir imagen Docker a Singularity
singularity pull hrprofiler_1.0.sif docker://florpio/hrprofiler:1.0

# Ejecutar
singularity exec \
    --bind ~/hrprofiler_genome:/root/.SigProfilerMatrixGenerator \
    --bind /path/to/data:/data \
    hrprofiler_1.0.sif \
    python /data/HRD.py --snv-dir /data/snv --cnv-dir /data/cnv --output-dir /data/results
```

## Verificar instalación

```bash
# Verificar dependencias
docker run --rm florpio/hrprofiler:1.0 /opt/check_install.py

# Output esperado:
# ✓ numpy 2.x.x
# ✓ HRProfiler installed
# ✓ SigProfilerMatrixGenerator installed
# ✓ All dependencies installed correctly
```

## Troubleshooting

### Error: Genome not found

Si ves errores sobre genoma no encontrado:

```
FileNotFoundError: GRCh38 reference not installed
```

Solución: Descargar el genoma o usar la imagen `-full`:

```bash
# Descargar genoma
docker run --rm \
    -v ~/hrprofiler_genome:/root/.SigProfilerMatrixGenerator \
    florpio/hrprofiler:1.0 \
    -c "from SigProfilerMatrixGenerator import install as genInstall; genInstall.install('GRCh38', rsync=False, bash=True)"
```

### Error: Permission denied

Si hay problemas de permisos con volúmenes montados:

```bash
docker run --rm \
    --user $(id -u):$(id -g) \
    -v /path/to/data:/data \
    florpio/hrprofiler:1.0 ...
```

### Memoria insuficiente

HRProfiler puede necesitar bastante RAM. Aumentar límites:

```bash
docker run --rm \
    --memory=16g \
    -v /path/to/data:/data \
    florpio/hrprofiler:1.0 ...
```
