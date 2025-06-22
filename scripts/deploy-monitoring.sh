#!/bin/bash

# Formerr Monitoring Deployment Script
# Deploys Prometheus monitoring to Kubernetes cluster

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🚀 Formerr Monitoring Deployment${NC}"
echo "=================================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    echo "   Please install kubectl and configure it to access your cluster"
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

# Change to project root
cd "$PROJECT_ROOT"

# Check if monitoring manifests exist
if [[ ! -f "k8s/monitoring/prometheus-simple.yaml" ]]; then
    echo -e "${RED}❌ Prometheus manifests not found${NC}"
    echo "   Expected: k8s/monitoring/prometheus-simple.yaml"
    exit 1
fi

echo -e "${GREEN}✅ Monitoring manifests found${NC}"

# Clean up any existing Helm releases (idempotent approach)
echo ""
echo "🧹 Cleaning up any existing Helm Prometheus releases..."
if command -v helm &> /dev/null; then
    helm uninstall prometheus -n monitoring 2>/dev/null || true
    helm uninstall kube-prometheus-stack -n monitoring 2>/dev/null || true
    echo -e "${GREEN}✅ Helm cleanup completed${NC}"
else
    echo -e "${YELLOW}⚠️  Helm not found, skipping cleanup${NC}"
fi

# Deploy Prometheus monitoring
echo ""
echo "📊 Deploying Prometheus monitoring..."
if kubectl apply -f k8s/monitoring/prometheus-simple.yaml; then
    echo -e "${GREEN}✅ Prometheus manifests applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply Prometheus manifests${NC}"
    exit 1
fi

# Wait for namespace to be ready
echo ""
echo "⏳ Waiting for monitoring namespace to be ready..."
kubectl wait --for=condition=Ready namespace/monitoring --timeout=30s 2>/dev/null || true

# Wait for Prometheus deployment to be ready
echo "⏳ Waiting for Prometheus deployment to be ready..."
kubectl wait --for=condition=available deployment/prometheus -n monitoring --timeout=120s || {
    echo -e "${YELLOW}⚠️  Timeout waiting for Prometheus deployment, but continuing...${NC}"
}

# Wait for Prometheus pod to be ready
echo "⏳ Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s || {
    echo -e "${YELLOW}⚠️  Timeout waiting for Prometheus pod, but continuing...${NC}"
}

# Show monitoring status
echo ""
echo "📊 Current Monitoring Status:"
echo "=============================="

echo ""
echo "📋 Monitoring Namespace:"
kubectl get namespace monitoring 2>/dev/null || echo "   (namespace not ready)"

echo ""
echo "📋 Monitoring Pods:"
kubectl get pods -n monitoring 2>/dev/null || echo "   (pods not ready)"

echo ""
echo "📋 Monitoring Services:"
kubectl get services -n monitoring 2>/dev/null || echo "   (services not ready)"

echo ""
echo "📋 Monitoring Deployments:"
kubectl get deployments -n monitoring 2>/dev/null || echo "   (deployments not ready)"

# Show access instructions
echo ""
echo -e "${GREEN}✅ Monitoring deployment completed!${NC}"
echo ""
echo "🔗 Access Prometheus:"
echo "================================"
echo "1. Port forward to access locally:"
echo "   kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "   Then open: http://localhost:9090"
echo ""
echo "2. Or use the LoadBalancer service (if configured):"
echo "   kubectl get svc -n monitoring"
echo ""
echo "🔍 Useful monitoring commands:"
echo "   kubectl logs -n monitoring deployment/prometheus"
echo "   kubectl describe pod -n monitoring -l app=prometheus"
echo "   kubectl get events -n monitoring --sort-by='.lastTimestamp'"
echo ""
echo "📊 Monitoring targets should include:"
echo "   - Prometheus itself"
echo "   - Kubernetes API server"
echo "   - Kubernetes nodes"
echo "   - Application pods (with prometheus.io/scrape=true annotation)"
echo ""
echo -e "${GREEN}🎉 Monitoring deployment script completed!${NC}"
