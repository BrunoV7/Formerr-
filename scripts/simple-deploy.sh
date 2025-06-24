#!/bin/bash
# Simple Deploy Script - No Complex Load Balancers
# Frontend gets direct LoadBalancer, Backend stays internal

set -e

echo "🚀 Starting SIMPLIFIED Formerr Deployment..."
echo "📋 Architecture:"
echo "   - Frontend: Direct LoadBalancer (Internet facing)"
echo "   - Backend: ClusterIP only (Internal)"
echo "   - No complex ingress routing"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is configured
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "kubectl is not configured or cluster is not accessible"
    exit 1
fi

print_status "Cluster info:"
kubectl cluster-info

# Create namespace
print_status "Creating namespace..."
kubectl create namespace formerr --dry-run=client -o yaml | kubectl apply -f -

# Deploy backend (internal only)
print_status "Deploying backend (internal access only)..."
kubectl apply -f k8s/production/backend-deployment.yaml

# Deploy frontend (with direct LoadBalancer)
print_status "Deploying frontend (direct internet access)..."
kubectl apply -f k8s/production/frontend-deployment.yaml

# Optional: Deploy minimal ingress for monitoring
if [[ "${DEPLOY_MONITORING:-yes}" == "yes" ]]; then
    print_status "Deploying monitoring ingress..."
    kubectl apply -f k8s/monitoring/monitoring-ingress.yaml 2>/dev/null || print_warning "Monitoring ingress not found, skipping"
fi

# Wait for deployments
print_status "Waiting for deployments to be ready..."
kubectl rollout status deployment/formerr-backend -n formerr --timeout=300s
kubectl rollout status deployment/formerr-frontend -n formerr --timeout=300s

# Get status
print_status "Deployment Status:"
kubectl get pods -n formerr
kubectl get services -n formerr

# Get frontend LoadBalancer IP
print_status "Getting frontend access information..."
FRONTEND_LB_IP=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")

echo ""
print_success "=== DEPLOYMENT COMPLETED ==="
echo ""
echo "🌐 Frontend Access:"
echo "   IP: $FRONTEND_LB_IP"
echo "   URL: http://$FRONTEND_LB_IP"
echo ""
echo "🔒 Backend Access:"
echo "   Internal Only: http://formerr-backend-service.formerr.svc.cluster.local:8000"
echo "   Status: Not exposed to internet ✅"
echo ""
echo "⚠️  Configure DNS:"
echo "   A    formerr.tech    -> $FRONTEND_LB_IP"
echo ""
echo "✅ Benefits of this architecture:"
echo "   - Simple and reliable"
echo "   - Frontend has direct internet access"
echo "   - Backend is secure (internal only)"
echo "   - No complex load balancer routing"
echo "   - Lower latency for frontend"

if [[ "$FRONTEND_LB_IP" == "Pending..." ]]; then
    print_warning "LoadBalancer IP is still pending. Wait a few minutes and check again:"
    print_warning "kubectl get service formerr-frontend-service -n formerr"
fi
