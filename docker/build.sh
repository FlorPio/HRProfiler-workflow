#!/bin/bash
# =============================================================================
# Script to build and push HRProfiler Docker images
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

# Function to show help
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Opciones:"
    echo "  --light    Build lightweight image (no genome, ~2GB)"
    echo "  --full     Build full image (with genome, ~20GB)"
    echo "  --push     Push images to Docker Hub"
    echo "  --test     Test image locally"
    echo "  --all      Build both images"
    echo "  --help     Show this help"
    echo ""
}

# Build lightweight image
build_light() {
    echo -e "${GREEN}▶ Building lightweight image...${NC}"
    docker build \
        -t ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} \
        -t ${DOCKER_USER}/${IMAGE_NAME}:latest \
        -f Dockerfile \
        .
    echo -e "${GREEN}✓ Image ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} built${NC}"
}

# Build full image
build_full() {
    echo -e "${YELLOW}▶ Building full image (this will take ~1 hour)...${NC}"
    docker build \
        -t ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full \
        -f Dockerfile.full \
        .
    echo -e "${GREEN}✓ Image ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full built${NC}"
}

# Push images
push_images() {
    echo -e "${GREEN}▶ Pushing images to Docker Hub...${NC}"
    
    # Login (if not logged in)
    docker login
    
    # Push lightweight image
    if docker image inspect ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} &> /dev/null; then
        docker push ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}
        docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
        echo -e "${GREEN}✓ ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} pushed${NC}"
    fi
    
    # Push full image
    if docker image inspect ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full &> /dev/null; then
        docker push ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full
        echo -e "${GREEN}✓ ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}-full pushed${NC}"
    fi
}

# Test image
test_image() {
    echo -e "${GREEN}▶ Testing image...${NC}"
    
    # Verify installation
    docker run --rm ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} /opt/check_install.py
    
    # Test HRProfiler import
    docker run --rm ${DOCKER_USER}/${IMAGE_NAME}:${VERSION} -c "from HRProfiler.scripts import HRProfiler; print('HRProfiler import OK')"
    
    echo -e "${GREEN}✓ Tests pasaron correctamente${NC}"
}

# Process arguments
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
        echo "Unrecognized option: $1"
        show_help
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "  Completed"
echo "========================================"
