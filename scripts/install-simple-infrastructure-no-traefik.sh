#!/bin/bash
# Simple Infrastructure Installation - NO Traefik
# Frontend gets direct LoadBalancer, Backend stays internal

set -e

echo "🚀 Installing Simple Infrastructure (No Traefik)"
echo "================================================"

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

# Check what's needed
print_status "Checking existing infrastructure..."

# Check monitoring
PROMETHEUS_DEPLOYMENT=$(kubectl get deployment prometheus-kube-prometheus-prometheus -n monitoring 2>/dev/null || echo "")
GRAFANA_DEPLOYMENT=$(kubectl get deployment prometheus-grafana -n monitoring 2>/dev/null || echo "")

# Install monitoring if needed
if [[ -z "$PROMETHEUS_DEPLOYMENT" || -z "$GRAFANA_DEPLOYMENT" ]]; then
    print_status "Installing monitoring stack (Prometheus + Grafana)..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Install using simple monitoring stack
    if [ -f "$SCRIPT_DIR/install-simple-monitoring.sh" ]; then
        bash "$SCRIPT_DIR/install-simple-monitoring.sh"
    else
        print_warning "Simple monitoring script not found, installing basic monitoring..."
        
        # Create basic Prometheus deployment
        kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF
    fi
    
    print_success "Monitoring stack installed"
else
    print_success "Monitoring stack already running"
fi

# Check cert-manager (optional, for SSL)
CERT_MANAGER=$(kubectl get deployment cert-manager -n cert-manager 2>/dev/null || echo "")
if [[ -z "$CERT_MANAGER" ]]; then
    print_status "Installing cert-manager for SSL certificates..."
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
    
    print_success "Cert-manager installed"
else
    print_success "Cert-manager already running"
fi

# Create cluster issuers for Let's Encrypt (if not exists)
print_status "Creating Let's Encrypt cluster issuers..."

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@formerr.tech
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@formerr.tech
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

print_success "Cluster issuers created"

# Check application namespace
kubectl create namespace formerr --dry-run=client -o yaml | kubectl apply -f -

# Summary
print_status "Infrastructure installation summary:"
echo "✅ Monitoring: Prometheus + Grafana"
echo "✅ SSL: Cert-manager + Let's Encrypt"
echo "✅ Namespace: formerr"
echo "❌ Traefik: NOT INSTALLED (using direct LoadBalancer)"
echo ""
print_success "Simple infrastructure ready!"
print_warning "Note: Frontend will use direct LoadBalancer, Backend stays internal"
print_warning "No complex ingress routing - simple and reliable!"
