#!/bin/bash
# Build and push Docker image to GitHub Container Registry (GHCR)
# Usage: ./scripts/build-and-push.sh [version]
# Example: ./scripts/build-and-push.sh v1.0.0

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERSION=${1:-v1.0.0}
REGISTRY="ghcr.io"
IMAGE_PREFIX="${REGISTRY}/raolivei"
IMAGE_NAME="us-law-severity-map-web"
FULL_IMAGE_NAME="${IMAGE_PREFIX}/${IMAGE_NAME}"

echo -e "${GREEN}🐳 Building Docker image: ${FULL_IMAGE_NAME}:${VERSION}${NC}"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Build the image
echo -e "${BLUE}Building ${FULL_IMAGE_NAME}:${VERSION}...${NC}"
if docker build -t "${FULL_IMAGE_NAME}:${VERSION}" -t "${FULL_IMAGE_NAME}:latest" .; then
    echo -e "${GREEN}✅ Image built successfully${NC}"
else
    echo -e "${RED}❌ Failed to build image${NC}"
    exit 1
fi

# If PUSH environment variable is set, push the image
if [ "${PUSH}" = "true" ]; then
    echo ""
    echo -e "${BLUE}Pushing images to ${REGISTRY}...${NC}"
    
    # Check if logged in
    if ! docker info 2>/dev/null | grep -q "Username"; then
        echo -e "${RED}Error: Not logged in to Docker. Please log in first:${NC}"
        echo "  echo \$GITHUB_TOKEN | docker login ${REGISTRY} -u raolivei --password-stdin"
        exit 1
    fi
    
    echo -e "${YELLOW}Pushing ${FULL_IMAGE_NAME}:${VERSION}...${NC}"
    if docker push "${FULL_IMAGE_NAME}:${VERSION}"; then
        echo -e "${GREEN}✅ Pushed ${FULL_IMAGE_NAME}:${VERSION}${NC}"
    else
        echo -e "${RED}❌ Failed to push ${FULL_IMAGE_NAME}:${VERSION}${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Pushing ${FULL_IMAGE_NAME}:latest...${NC}"
    if docker push "${FULL_IMAGE_NAME}:latest"; then
        echo -e "${GREEN}✅ Pushed ${FULL_IMAGE_NAME}:latest${NC}"
    else
        echo -e "${RED}❌ Failed to push ${FULL_IMAGE_NAME}:latest${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ Successfully pushed images to ${REGISTRY}${NC}"
else
    echo ""
    echo -e "${YELLOW}Build complete. To push to GHCR:${NC}"
    echo "1. Log in to GHCR:"
    echo "   echo \$GITHUB_TOKEN | docker login ${REGISTRY} -u raolivei --password-stdin"
    echo ""
    echo "2. Push the image:"
    echo "   PUSH=true ./scripts/build-and-push.sh ${VERSION}"
fi

