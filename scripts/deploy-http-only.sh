#!/bin/bash
# Simple HTTP-only deployment - NO SSL/HTTPS
# Frontend gets LoadBalancer, Backend stays internal

set -e

echo "🚀 Deploying Formerr (HTTP Only - No SSL)"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check kubectl connection
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_success "Connected to cluster"

# Check if cert-manager is installed and offer to remove it
CERT_MANAGER_NS=$(kubectl get namespace cert-manager --ignore-not-found 2>/dev/null || echo "")
if [[ -n "$CERT_MANAGER_NS" ]]; then
    print_warning "cert-manager is installed but not needed for HTTP-only setup"
    echo "Would you like to remove it? (y/n)"
    read -r REMOVE_CERT_MANAGER
    if [[ "$REMOVE_CERT_MANAGER" =~ ^[Yy]$ ]]; then
        print_status "Removing cert-manager..."
        bash "$SCRIPT_DIR/remove-cert-manager.sh"
    else
        print_warning "Keeping cert-manager (but not using it)"
    fi
fi

# Install ultra simple infrastructure
print_status "Installing ultra simple infrastructure (HTTP only)..."
bash "$SCRIPT_DIR/install-ultra-simple-infrastructure.sh"

# Wait for infrastructure
print_status "Waiting for infrastructure to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s || print_warning "Prometheus not ready yet"
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s || print_warning "Grafana not ready yet"

# Deploy applications
print_status "Deploying applications..."

# Create namespace
kubectl create namespace formerr --dry-run=client -o yaml | kubectl apply -f -

# Deploy backend (internal)
print_status "Deploying backend (internal ClusterIP)..."
kubectl apply -f "$PROJECT_ROOT/k8s/production/backend-deployment.yaml"

# Deploy frontend (LoadBalancer)
print_status "Deploying frontend (LoadBalancer)..."
kubectl apply -f "$PROJECT_ROOT/k8s/production/frontend-deployment.yaml"

# Deploy ingress for backend (HTTP only)
print_status "Deploying backend ingress (HTTP only)..."
kubectl apply -f "$PROJECT_ROOT/k8s/production/ingress-simple.yaml"

# Wait for deployments
print_status "Waiting for deployments to be ready..."
kubectl wait --for=condition=available deployment/formerr-backend -n formerr --timeout=300s
kubectl wait --for=condition=available deployment/formerr-frontend -n formerr --timeout=300s

# Get frontend LoadBalancer IP
print_status "Waiting for frontend LoadBalancer IP..."
FRONTEND_IP=""
for i in {1..30}; do
    FRONTEND_IP=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [[ -n "$FRONTEND_IP" ]]; then
        break
    fi
    echo "Waiting for LoadBalancer IP... ($i/30)"
    sleep 10
done

# Show deployment status
echo ""
print_success "🎉 Deployment completed!"
echo ""
print_status "📋 Deployment Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Architecture: Ultra Simple (HTTP Only)"
echo "✅ SSL/HTTPS: Disabled (no cert-manager)"
echo "✅ Frontend: LoadBalancer (direct access)"
echo "✅ Backend: ClusterIP (internal only)"
echo "✅ Monitoring: Prometheus + Grafana"
echo ""

print_status "🌐 Access Information:"
if [[ -n "$FRONTEND_IP" ]]; then
    echo "🌍 Frontend: http://$FRONTEND_IP"
else
    echo "🌍 Frontend: Getting LoadBalancer IP..."
    echo "   Check with: kubectl get svc formerr-frontend-service -n formerr"
fi

echo "🔒 Backend: Internal only (http://formerr-backend-service.formerr.svc.cluster.local:8000)"
echo "📊 Prometheus: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "📈 Grafana: kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "   • Username: admin"
echo "   • Password: admin"
echo ""

print_status "🔧 Management Commands:"
echo "• Check frontend IP: kubectl get svc formerr-frontend-service -n formerr"
echo "• Check pods: kubectl get pods -n formerr"
echo "• Check logs:"
echo "  - Frontend: kubectl logs -f deployment/formerr-frontend -n formerr"
echo "  - Backend: kubectl logs -f deployment/formerr-backend -n formerr"
echo "• Scale frontend: kubectl scale deployment formerr-frontend --replicas=3 -n formerr"
echo "• Scale backend: kubectl scale deployment formerr-backend --replicas=2 -n formerr"
echo ""

print_warning "⚠️  Important Notes:"
echo "• This is HTTP only - no HTTPS/SSL"
echo "• Perfect for development and testing"
echo "• Update your DNS to point to the LoadBalancer IP"
echo "• Backend is only accessible internally"
echo ""

print_success "🚀 Ready to use!"

# Final check
echo ""
print_status "🔍 Final Status Check:"
echo "Pods:"
kubectl get pods -n formerr
echo ""
echo "Services:"
kubectl get services -n formerr
echo ""
if [[ -n "$FRONTEND_IP" ]]; then
    print_success "✅ Frontend LoadBalancer IP: $FRONTEND_IP"
else
    print_warning "⏳ Frontend LoadBalancer IP still being assigned"
fi
