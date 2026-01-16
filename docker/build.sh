#!/bin/bash
# =============================================================================
# Script para construir y publicar imágenes Docker de HRProfiler
# =============================================================================

set -e

# Configuración
DOCKER_USER="florpio"
IMAGE_NAME="hrprofiler"
VERSION="1.0"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  HRProfiler Docker Build Script"
echo "========================================"
echo ""

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  --light    Construir imagen ligera (sin genoma, ~2GB)"
    echo "  --full     Construir imagen completa (con genoma, ~20GB)"
    echo "  --push     Publicar imágenes a Docker Hub"
    echo "  --test     Probar imagen localmente"
    echo "  --all      Construir ambas imágenes"
    echo "  --help     Mostrar esta ayuda"
    echo ""
}

# Construir imagen ligera
build_light() {
    echo -e "${GREEN}▶ Construyendo imagen ligera...${NC}"
    docker build \
        -t ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} \
        -t ${DOCKER_USER}/${IMAGE_NAME}:latest \
        -f Dockerfile \
        .
    echo -e "${GREEN}✓ Imagen ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} construida${NC}"
}

# Construir imagen completa
build_full() {
    echo -e "${YELLOW}▶ Construyendo imagen completa (esto tardará ~1 hora)...${NC}"
    docker build \
        -t ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full \
        -f Dockerfile.full \
        .
    echo -e "${GREEN}✓ Imagen ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full construida${NC}"
}

# Publicar imágenes
push_images() {
    echo -e "${GREEN}▶ Publicando imágenes a Docker Hub...${NC}"
    
    # Login (si no está logueado)
    docker login
    
    # Push imagen ligera
    if docker image inspect ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} &> /dev/null; then
        docker push ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}
        docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
        echo -e "${GREEN}✓ ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} publicada${NC}"
    fi
    
    # Push imagen completa
    if docker image inspect ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full &> /dev/null; then
        docker push ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full
        echo -e "${GREEN}✓ ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full publicada${NC}"
    fi
}

# Probar imagen
test_image() {
    echo -e "${GREEN}▶ Probando imagen...${NC}"
    
    # Verificar instalación
    docker run --rm ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} /opt/check_install.py
    
    # Probar HRProfiler import
    docker run --rm ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} -c "from HRProfiler.scripts import HRProfiler; print('HRProfiler import OK')"
    
    echo -e "${GREEN}✓ Tests pasaron correctamente${NC}"
}

# Procesar argumentos
case "$1" in
    --light)
        build_light
        ;;
    --full)
        build_full
        ;;
    --push)
        push_images
        ;;
    --test)
        test_image
        ;;
    --all)
        build_light
        build_full
        ;;
    --help)
        show_help
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "  Completado"
echo "========================================"
