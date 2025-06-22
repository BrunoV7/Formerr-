#!/bin/bash

# Simple Monitoring Installation Script
# Installs Prometheus and Grafana without requiring Prometheus Operator

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}📊 Installing Simple Monitoring Stack${NC}"
echo "===================================="

# Check if monitoring stack is already installed and working
echo ""
echo "🔍 Checking if monitoring stack is already installed..."

PROMETHEUS_DEPLOYMENT=$(kubectl get deployment prometheus -n monitoring 2>/dev/null || echo "")
GRAFANA_DEPLOYMENT=$(kubectl get deployment grafana -n monitoring 2>/dev/null || echo "")

if [[ -n "$PROMETHEUS_DEPLOYMENT" && -n "$GRAFANA_DEPLOYMENT" ]]; then
    # Check if pods are running
    PROMETHEUS_READY=$(kubectl get pods -n monitoring -l app=prometheus --field-selector=status.phase=Running 2>/dev/null | grep -c "Running" || echo "0")
    GRAFANA_READY=$(kubectl get pods -n monitoring -l app=grafana --field-selector=status.phase=Running 2>/dev/null | grep -c "Running" || echo "0")
    
    if [[ "$PROMETHEUS_READY" -gt 0 && "$GRAFANA_READY" -gt 0 ]]; then
        echo -e "${GREEN}✅ Monitoring stack is already installed and running${NC}"
        echo "   Prometheus pods running: $PROMETHEUS_READY"
        echo "   Grafana pods running: $GRAFANA_READY"
        echo ""
        echo "🚀 Skipping installation, monitoring stack is already operational!"
        
        # Show access information
        echo ""
        echo "🔗 Access Information:"
        echo "   Prometheus: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
        echo "   Grafana: kubectl port-forward -n monitoring svc/grafana 3000:3000"
        echo "   Grafana default credentials: admin/admin"
        
        exit 0
    fi
fi

echo -e "${YELLOW}⚠️  Monitoring stack not found or not fully operational, proceeding with installation...${NC}"
echo ""
echo "This will install:"
echo "- Prometheus for metrics collection"
echo "- Grafana for visualization"
echo "- Custom Formerr monitoring rules"
echo ""

# Create monitoring namespace if not exists
echo "📁 Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Apply the simple monitoring configuration
echo ""
echo "📊 Deploying Prometheus and Grafana..."
if kubectl apply -f "${SCRIPT_DIR}/../k8s/monitoring/simple-monitoring.yaml"; then
    echo -e "${GREEN}✅ Monitoring stack deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy monitoring stack${NC}"
    exit 1
fi

# Wait for Prometheus to be ready
echo ""
echo "⏳ Waiting for Prometheus to be ready..."
if kubectl wait --namespace monitoring \
  --for=condition=available deployment/prometheus \
  --timeout=300s; then
    echo -e "${GREEN}✅ Prometheus is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Timeout waiting for Prometheus, but continuing...${NC}"
fi

# Wait for Grafana to be ready
echo ""
echo "⏳ Waiting for Grafana to be ready..."
if kubectl wait --namespace monitoring \
  --for=condition=available deployment/grafana \
  --timeout=300s; then
    echo -e "${GREEN}✅ Grafana is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Timeout waiting for Grafana, but continuing...${NC}"
fi

# Show status
echo ""
echo "📊 Monitoring Stack Status:"
echo "=========================="

echo ""
echo "📋 Prometheus:"
kubectl get pods -n monitoring -l app=prometheus

echo ""
echo "📋 Grafana:"
kubectl get pods -n monitoring -l app=grafana

echo ""
echo "📋 Services:"
kubectl get services -n monitoring

# Setup port forwarding instructions
echo ""
echo "🔗 Access Instructions:"
echo "======================"
echo ""
echo "📊 To access Prometheus:"
echo "   kubectl port-forward -n monitoring service/prometheus 9090:9090"
echo "   Then visit: http://localhost:9090"
echo ""
echo "📈 To access Grafana:"
echo "   kubectl port-forward -n monitoring service/grafana 3000:3000"
echo "   Then visit: http://localhost:3000"
echo "   Default login: admin/admin123"
echo ""
echo "🔧 To configure Grafana with Prometheus:"
echo "   1. Login to Grafana"
echo "   2. Go to Configuration > Data Sources"
echo "   3. Add Prometheus data source"
echo "   4. URL: http://prometheus.monitoring.svc.cluster.local:9090"
echo "   5. Click 'Save & Test'"
echo ""

# Optional: Create Ingress for monitoring if Traefik is installed
echo "🌐 Optional - Exposing via Ingress:"
echo "==================================="
echo ""
echo "If you want to expose monitoring via your domain:"
echo ""
echo "1. Create Ingress for Prometheus:"
echo "   kubectl apply -f - <<EOF"
echo "   apiVersion: networking.k8s.io/v1"
echo "   kind: Ingress"
echo "   metadata:"
echo "     name: prometheus-ingress"
echo "     namespace: monitoring"
echo "     annotations:"
echo "       traefik.ingress.kubernetes.io/router.tls: \"true\""
echo "       traefik.ingress.kubernetes.io/router.tls.certresolver: \"letsencrypt\""
echo "   spec:"
echo "     rules:"
echo "     - host: prometheus.yourdomain.com"
echo "       http:"
echo "         paths:"
echo "         - path: /"
echo "           pathType: Prefix"
echo "           backend:"
echo "             service:"
echo "               name: prometheus"
echo "               port:"
echo "                 number: 9090"
echo "   EOF"
echo ""
echo "2. Create Ingress for Grafana:"
echo "   kubectl apply -f - <<EOF"
echo "   apiVersion: networking.k8s.io/v1"
echo "   kind: Ingress"
echo "   metadata:"
echo "     name: grafana-ingress"
echo "     namespace: monitoring"
echo "     annotations:"
echo "       traefik.ingress.kubernetes.io/router.tls: \"true\""
echo "       traefik.ingress.kubernetes.io/router.tls.certresolver: \"letsencrypt\""
echo "   spec:"
echo "     rules:"
echo "     - host: grafana.yourdomain.com"
echo "       http:"
echo "         paths:"
echo "         - path: /"
echo "           pathType: Prefix"
echo "           backend:"
echo "             service:"
echo "               name: grafana"
echo "               port:"
echo "                 number: 3000"
echo "   EOF"
echo ""

echo -e "${GREEN}🎉 Simple Monitoring Stack installation completed!${NC}"
echo ""
echo "📚 Next Steps:"
echo "1. Access Grafana and configure Prometheus data source"
echo "2. Import Kubernetes dashboards (ID: 8588, 6417)"
echo "3. Set up alerts and notifications"
echo "4. Monitor your Formerr application metrics"
