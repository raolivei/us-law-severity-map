#!/bin/bash
# Setup GHCR secret for us-law-severity-map namespace
# This script creates a docker-registry secret for pulling images from ghcr.io

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="us-law-severity-map"
SECRET_NAME="ghcr-secret"

echo -e "${GREEN}🔐 Setting up GHCR secret for ${NAMESPACE} namespace${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    echo -e "${YELLOW}Namespace ${NAMESPACE} does not exist. Creating it...${NC}"
    kubectl create namespace "${NAMESPACE}"
fi

# Option 1: Get token from Vault (if available)
echo -e "${BLUE}Checking Vault for GHCR token...${NC}"
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$VAULT_POD" ]; then
    VAULT_TOKEN=$(kubectl logs -n vault $VAULT_POD 2>/dev/null | grep "Root Token" | tail -1 | awk '{print $NF}' || echo "root")
    
    GHCR_TOKEN=$(kubectl exec -n vault $VAULT_POD -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN='${VAULT_TOKEN}' && vault kv get -field=token secret/us-law-severity-map/ghcr-token 2>/dev/null" || echo "")
    
    if [ -n "$GHCR_TOKEN" ]; then
        echo -e "${GREEN}Found GHCR token in Vault${NC}"
        kubectl create secret docker-registry "${SECRET_NAME}" \
            --docker-server=ghcr.io \
            --docker-username=raolivei \
            --docker-password="$GHCR_TOKEN" \
            -n "${NAMESPACE}" \
            --dry-run=client -o yaml | kubectl apply -f -
        echo -e "${GREEN}✅ Created ${SECRET_NAME} in ${NAMESPACE} namespace${NC}"
        
        # Update deployment to use imagePullSecrets
        echo -e "${YELLOW}Updating deployment to use imagePullSecrets...${NC}"
        kubectl patch deployment us-law-severity-map-web -n "${NAMESPACE}" \
            --type='json' \
            -p='[{"op": "add", "path": "/spec/template/spec/imagePullSecrets", "value": [{"name": "'"${SECRET_NAME}"'"}]}]' 2>/dev/null || \
            echo -e "${YELLOW}Note: Deployment may not exist yet. Apply k8s/deploy.yaml after creating the secret.${NC}"
        
        echo -e "${GREEN}✅ Done!${NC}"
        exit 0
    fi
fi

# Option 2: Prompt for token
echo -e "${YELLOW}GHCR token not found in Vault${NC}"
echo -e "${YELLOW}You can either:${NC}"
echo -e "  1. Make the repository public on GitHub (no auth needed)"
echo -e "  2. Create a Personal Access Token with 'read:packages' scope"
echo ""
echo -e "${BLUE}To create a GitHub Personal Access Token:${NC}"
echo -e "  1. Go to: https://github.com/settings/tokens"
echo -e "  2. Click 'Generate new token (classic)'"
echo -e "  3. Select scope: 'read:packages'"
echo -e "  4. Generate and copy the token"
echo ""
read -p "Enter GitHub Personal Access Token (or press Enter to skip): " GHCR_TOKEN

if [ -z "$GHCR_TOKEN" ]; then
    echo -e "${YELLOW}Skipping secret creation. If images are public, this is fine.${NC}"
    echo -e "${YELLOW}If you get ImagePullBackOff errors, make the package public or run this script again with a token.${NC}"
    exit 0
fi

# Create the secret
echo -e "${BLUE}Creating ${SECRET_NAME}...${NC}"
kubectl create secret docker-registry "${SECRET_NAME}" \
    --docker-server=ghcr.io \
    --docker-username=raolivei \
    --docker-password="$GHCR_TOKEN" \
    -n "${NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Created ${SECRET_NAME} in ${NAMESPACE} namespace${NC}"
echo ""

# Update deployment to use imagePullSecrets
echo -e "${YELLOW}Updating deployment to use imagePullSecrets...${NC}"
kubectl patch deployment us-law-severity-map-web -n "${NAMESPACE}" \
    --type='json' \
    -p='[{"op": "add", "path": "/spec/template/spec/imagePullSecrets", "value": [{"name": "'"${SECRET_NAME}"'"}]}]' 2>/dev/null || \
    echo -e "${YELLOW}Note: Deployment may not exist yet. You'll need to add imagePullSecrets manually or apply k8s/deploy.yaml.${NC}"

echo ""
echo -e "${GREEN}✅ Done!${NC}"
echo -e "${YELLOW}To verify: kubectl get secret ${SECRET_NAME} -n ${NAMESPACE}${NC}"

