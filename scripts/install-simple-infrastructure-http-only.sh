#!/bin/bash
# Simple Infrastructure Installation - HTTP Only, No SSL
# Frontend gets direct LoadBalancer, Backend stays internal
# Monitoring only - no SSL complexity

set -e

echo "🚀 Installing Simple Infrastructure (HTTP Only - No SSL)"
echo "========================================================"

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

# Check kubectl connection
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_success "Connected to cluster"

# Check monitoring
print_status "Checking monitoring stack..."

# Check if Prometheus is installed via Helm
PROMETHEUS_HELM=$(helm list -A | grep prometheus || echo "")
GRAFANA_HELM=$(helm list -A | grep grafana || echo "")

if [[ -z "$PROMETHEUS_HELM" ]]; then
    print_status "Installing Prometheus monitoring stack..."
    
    # Add helm repos
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add stable https://charts.helm.sh/stable
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Prometheus stack (includes Grafana)
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.retention=30d \
        --set alertmanager.enabled=true \
        --set grafana.adminPassword=admin \
        --set grafana.service.type=ClusterIP \
        --set prometheus.service.type=ClusterIP \
        --timeout 600s
    
    print_success "Prometheus stack installed"
    
    # Wait for deployments
    print_status "Waiting for monitoring components to be ready..."
    kubectl wait --for=condition=available deployment/prometheus-grafana -n monitoring --timeout=300s
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s
    
else
    print_success "Prometheus monitoring stack already installed"
fi

# Install NGINX Ingress Controller (for backend only)
print_status "Checking NGINX Ingress Controller..."

NGINX_INGRESS=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx 2>/dev/null || echo "")
if [[ -z "$NGINX_INGRESS" ]]; then
    print_status "Installing NGINX Ingress Controller..."
    
    # Install NGINX Ingress Controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    
    # Wait for NGINX to be ready
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    print_success "NGINX Ingress Controller installed"
else
    print_success "NGINX Ingress Controller already running"
fi

# Check application namespace
kubectl create namespace formerr --dry-run=client -o yaml | kubectl apply -f -

# Summary
print_status "Simple infrastructure installation summary:"
echo "✅ Monitoring: Prometheus + Grafana (via Helm)"
echo "✅ Ingress: NGINX (for backend internal access only)"
echo "✅ Namespace: formerr"
echo "❌ SSL/HTTPS: NOT INSTALLED (HTTP only for simplicity)"
echo "❌ Cert-manager: NOT INSTALLED (no SSL needed)"
echo "❌ Traefik: NOT INSTALLED (using direct LoadBalancer)"
echo ""
print_success "Simple infrastructure ready!"
print_warning "Note: This setup uses HTTP only - no HTTPS complexity"
print_warning "Frontend will use direct LoadBalancer, Backend uses internal ingress"
print_warning "Perfect for development and testing!"

# Show access instructions
echo ""
print_status "🌐 Access Instructions:"
echo "1. Frontend: Will get direct LoadBalancer IP"
echo "2. Backend: Internal via NGINX ingress (HTTP only)"
echo "3. Monitoring:"
echo "   • Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   • Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   • Grafana credentials: admin/admin"
echo "4. All services use HTTP (no HTTPS complexity)"
echo ""
print_success "🎉 Ready for application deployment!"
