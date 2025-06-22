#!/bin/bash

# Install NGINX Ingress Controller and Cert-Manager
# For DigitalOcean Kubernetes clusters

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Installing NGINX Ingress Controller and Cert-Manager${NC}"
echo "=================================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we can access the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot access Kubernetes cluster${NC}"
    echo "   Please configure kubectl to access your cluster:"
    echo "   doctl kubernetes cluster kubeconfig save <cluster-name>"
    exit 1
fi

echo -e "${GREEN}✅ kubectl configured and cluster accessible${NC}"

# Install NGINX Ingress Controller
echo ""
echo "📦 Installing NGINX Ingress Controller..."
if kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml; then
    echo -e "${GREEN}✅ NGINX Ingress Controller manifests applied${NC}"
else
    echo -e "${RED}❌ Failed to apply NGINX Ingress Controller manifests${NC}"
    exit 1
fi

# Wait for NGINX Ingress Controller to be ready
echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
if kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s; then
    echo -e "${GREEN}✅ NGINX Ingress Controller is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Timeout waiting for NGINX Ingress Controller, but continuing...${NC}"
fi

# Install Cert-Manager
echo ""
echo "🔐 Installing Cert-Manager..."
if kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml; then
    echo -e "${GREEN}✅ Cert-Manager manifests applied${NC}"
else
    echo -e "${RED}❌ Failed to apply Cert-Manager manifests${NC}"
    exit 1
fi

# Wait for Cert-Manager to be ready
echo "⏳ Waiting for Cert-Manager to be ready..."
if kubectl wait --namespace cert-manager \
  --for=condition=available deployment/cert-manager \
  --timeout=300s; then
    echo -e "${GREEN}✅ Cert-Manager is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Timeout waiting for Cert-Manager, but continuing...${NC}"
fi

# Wait for Cert-Manager webhook to be ready
echo "⏳ Waiting for Cert-Manager webhook to be ready..."
if kubectl wait --namespace cert-manager \
  --for=condition=available deployment/cert-manager-webhook \
  --timeout=300s; then
    echo -e "${GREEN}✅ Cert-Manager webhook is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Timeout waiting for Cert-Manager webhook, but continuing...${NC}"
fi

# Wait a bit more for webhooks to fully initialize
echo "⏳ Waiting for webhooks to fully initialize..."
sleep 30

# Apply ClusterIssuers (Let's Encrypt)
echo ""
echo "📜 Applying Let's Encrypt ClusterIssuers..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try to apply ClusterIssuers with retry logic
RETRY_COUNT=0
MAX_RETRIES=3

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if kubectl apply -f "$SCRIPT_DIR/../k8s/monitoring/ingress-cert-manager.yaml"; then
        echo -e "${GREEN}✅ ClusterIssuers applied successfully${NC}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}⚠️  Failed to apply ClusterIssuers, retrying in 10 seconds... (attempt $RETRY_COUNT/$MAX_RETRIES)${NC}"
            sleep 10
        else
            echo -e "${YELLOW}⚠️  Failed to apply ClusterIssuers after $MAX_RETRIES attempts${NC}"
            echo "   This is usually because the cert-manager webhook isn't fully ready yet."
            echo "   You can apply them manually later:"
            echo "   kubectl apply -f k8s/monitoring/ingress-cert-manager.yaml"
        fi
    fi
done

# Wait for ClusterIssuers to be ready (if applied successfully)
if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "⏳ Waiting for ClusterIssuers to be ready..."
    kubectl wait --for=condition=ready clusterissuer/letsencrypt-prod --timeout=60s 2>/dev/null || echo "   letsencrypt-prod: still initializing..."
    kubectl wait --for=condition=ready clusterissuer/letsencrypt-staging --timeout=60s 2>/dev/null || echo "   letsencrypt-staging: still initializing..."
fi

# Show status
echo ""
echo "📊 Installation Status:"
echo "======================"

echo ""
echo "📋 NGINX Ingress Controller:"
kubectl get pods -n ingress-nginx

echo ""
echo "📋 Cert-Manager:"
kubectl get pods -n cert-manager

echo ""
echo "📋 ClusterIssuers:"
kubectl get clusterissuers 2>/dev/null || echo "   (ClusterIssuers not ready yet)"

echo ""
echo "📋 Services:"
echo "NGINX Ingress Controller LoadBalancer:"
kubectl get service ingress-nginx-controller -n ingress-nginx

# Get LoadBalancer IP
echo ""
echo "🌐 LoadBalancer Information:"
LB_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
echo "   External IP: $LB_IP"

if [[ "$LB_IP" != "Pending..." && -n "$LB_IP" ]]; then
    echo ""
    echo -e "${GREEN}✅ Installation completed successfully!${NC}"
    echo ""
    echo "🔗 Next steps:"
    echo "1. Update your DNS to point to: $LB_IP"
    echo "2. Create Ingress resources with TLS certificates"
    echo "3. Use annotations for automatic certificate generation:"
    echo "   cert-manager.io/cluster-issuer: letsencrypt-prod"
else
    echo ""
    echo -e "${YELLOW}⚠️  LoadBalancer IP is still pending${NC}"
    echo "   Check again in a few minutes with:"
    echo "   kubectl get service ingress-nginx-controller -n ingress-nginx"
fi

echo ""
echo "📚 Useful commands:"
echo "   # Check NGINX Ingress status"
echo "   kubectl get pods -n ingress-nginx"
echo "   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller"
echo ""
echo "   # Check Cert-Manager status"
echo "   kubectl get pods -n cert-manager"
echo "   kubectl logs -n cert-manager deployment/cert-manager"
echo ""
echo "   # Check certificates"
echo "   kubectl get certificates --all-namespaces"
echo "   kubectl describe certificate <cert-name> -n <namespace>"
echo ""
echo -e "${GREEN}🎉 NGINX Ingress and Cert-Manager installation completed!${NC}"
