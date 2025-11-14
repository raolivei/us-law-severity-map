#!/bin/bash
# Script to deploy us-law-severity-map to Kubernetes cluster
# Ensures deployment and KEDA ScaledObject are applied with correct replica settings

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
K8S_DIR="$PROJECT_ROOT/k8s"
KEDA_SCALEDOBJECT="$PROJECT_ROOT/../pi-fleet/clusters/eldertree/observability/keda/scaledobjects/us-law-severity-map-web-scaledobject.yaml"

echo -e "${GREEN}🚀 Deploying us-law-severity-map to Kubernetes${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if KUBECONFIG is set
if [ -z "${KUBECONFIG:-}" ]; then
    echo -e "${YELLOW}⚠️  KUBECONFIG not set. Using default config.${NC}"
    echo -e "${YELLOW}   To use a specific cluster, set: export KUBECONFIG=~/.kube/config-eldertree${NC}"
    echo ""
fi

# Apply namespace
echo -e "${GREEN}📋 Applying namespace...${NC}"
kubectl apply -f "$K8S_DIR/namespace.yaml"

# Apply deployment (ensures replicas: 1)
echo -e "${GREEN}📋 Applying deployment (replicas: 1)...${NC}"
kubectl apply -f "$K8S_DIR/deploy.yaml"

# Verify deployment replicas
echo -e "${YELLOW}🔍 Verifying deployment replicas...${NC}"
CURRENT_REPLICAS=$(kubectl get deployment us-law-severity-map-web -n us-law-severity-map -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
echo "   Current replicas in deployment: $CURRENT_REPLICAS"

if [ "$CURRENT_REPLICAS" != "1" ]; then
    echo -e "${YELLOW}⚠️  Deployment has $CURRENT_REPLICAS replicas, scaling to 1...${NC}"
    kubectl scale deployment us-law-severity-map-web -n us-law-severity-map --replicas=1
fi

# Apply KEDA ScaledObject (ensures minReplicaCount: 1)
if [ -f "$KEDA_SCALEDOBJECT" ]; then
    echo -e "${GREEN}📋 Applying KEDA ScaledObject (minReplicaCount: 1)...${NC}"
    kubectl apply -f "$KEDA_SCALEDOBJECT"
    
    # Verify ScaledObject minReplicaCount
    echo -e "${YELLOW}🔍 Verifying KEDA ScaledObject minReplicaCount...${NC}"
    MIN_REPLICAS=$(kubectl get scaledobject us-law-severity-map-web-scaler -n us-law-severity-map -o jsonpath='{.spec.minReplicaCount}' 2>/dev/null || echo "0")
    echo "   Current minReplicaCount: $MIN_REPLICAS"
    
    if [ "$MIN_REPLICAS" != "1" ]; then
        echo -e "${RED}❌ ScaledObject minReplicaCount is $MIN_REPLICAS, should be 1${NC}"
        echo -e "${YELLOW}   Please check the ScaledObject configuration${NC}"
    else
        echo -e "${GREEN}✅ ScaledObject minReplicaCount is correctly set to 1${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  KEDA ScaledObject file not found at: $KEDA_SCALEDOBJECT${NC}"
    echo -e "${YELLOW}   Skipping ScaledObject deployment${NC}"
fi

# Apply service
echo -e "${GREEN}📋 Applying service...${NC}"
kubectl apply -f "$K8S_DIR/service.yaml"

# Apply ingress
echo -e "${GREEN}📋 Applying ingress...${NC}"
kubectl apply -f "$K8S_DIR/ingress.yaml"

# Wait for rollout
echo ""
echo -e "${YELLOW}⏳ Waiting for deployment rollout...${NC}"
kubectl rollout status deployment/us-law-severity-map-web -n us-law-severity-map --timeout=300s

# Check pod status
echo ""
echo -e "${GREEN}✅ Checking pod status...${NC}"
kubectl get pods -n us-law-severity-map -l app=us-law-severity-map

# Show replica information
echo ""
echo -e "${GREEN}📊 Replica Information:${NC}"
echo "   Deployment replicas: $(kubectl get deployment us-law-severity-map-web -n us-law-severity-map -o jsonpath='{.spec.replicas}')"
echo "   Current pod count: $(kubectl get pods -n us-law-severity-map -l app=us-law-severity-map --no-headers 2>/dev/null | wc -l | tr -d ' ')"
if kubectl get scaledobject us-law-severity-map-web-scaler -n us-law-severity-map &>/dev/null; then
    echo "   KEDA minReplicaCount: $(kubectl get scaledobject us-law-severity-map-web-scaler -n us-law-severity-map -o jsonpath='{.spec.minReplicaCount}')"
    echo "   KEDA maxReplicaCount: $(kubectl get scaledobject us-law-severity-map-web-scaler -n us-law-severity-map -o jsonpath='{.spec.maxReplicaCount}')"
fi

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}To check logs:${NC}"
echo "  kubectl logs -n us-law-severity-map -l app=us-law-severity-map --tail=50"

