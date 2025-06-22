#!/bin/bash

# Smart Infrastructure Installation Script
# Only installs components that are not already working

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🧠 Smart Infrastructure Installation${NC}"
echo "==================================="
echo ""
echo "This script will check what's already installed and only install missing components:"
echo "- Traefik Ingress Controller"
echo "- Monitoring Stack (Prometheus + Grafana)"
echo ""

# Function to check Traefik installation
check_traefik() {
    echo "🔍 Checking Traefik installation..."
    
    TRAEFIK_DEPLOYMENT=$(kubectl get deployment traefik -n traefik 2>/dev/null || echo "")
    TRAEFIK_SERVICE=$(kubectl get service traefik -n traefik 2>/dev/null || echo "")
    
    if [[ -n "$TRAEFIK_DEPLOYMENT" && -n "$TRAEFIK_SERVICE" ]]; then
        TRAEFIK_READY=$(kubectl get pods -n traefik -l app.kubernetes.io/name=traefik --field-selector=status.phase=Running 2>/dev/null | grep -c "Running" || echo "0")
        EXTERNAL_IP=$(kubectl get service traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [[ "$TRAEFIK_READY" -gt 0 && -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "<pending>" ]]; then
            echo -e "${GREEN}✅ Traefik is already operational (IP: $EXTERNAL_IP)${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}⚠️  Traefik needs installation${NC}"
    return 1
}

# Function to check monitoring installation
check_monitoring() {
    echo "🔍 Checking monitoring stack..."
    
    PROMETHEUS_DEPLOYMENT=$(kubectl get deployment prometheus -n monitoring 2>/dev/null || echo "")
    GRAFANA_DEPLOYMENT=$(kubectl get deployment grafana -n monitoring 2>/dev/null || echo "")
    
    if [[ -n "$PROMETHEUS_DEPLOYMENT" && -n "$GRAFANA_DEPLOYMENT" ]]; then
        PROMETHEUS_READY=$(kubectl get pods -n monitoring -l app=prometheus --field-selector=status.phase=Running 2>/dev/null | grep -c "Running" || echo "0")
        GRAFANA_READY=$(kubectl get pods -n monitoring -l app=grafana --field-selector=status.phase=Running 2>/dev/null | grep -c "Running" || echo "0")
        
        if [[ "$PROMETHEUS_READY" -gt 0 && "$GRAFANA_READY" -gt 0 ]]; then
            echo -e "${GREEN}✅ Monitoring stack is already operational${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}⚠️  Monitoring stack needs installation${NC}"
    return 1
}

# Main execution
INSTALL_TRAEFIK=false
INSTALL_MONITORING=false

# Check what needs to be installed
if ! check_traefik; then
    INSTALL_TRAEFIK=true
fi

if ! check_monitoring; then
    INSTALL_MONITORING=true
fi

# Install only what's needed
if [[ "$INSTALL_TRAEFIK" == "false" && "$INSTALL_MONITORING" == "false" ]]; then
    echo ""
    echo -e "${GREEN}🎉 All infrastructure components are already operational!${NC}"
    echo ""
    echo "📋 Current Status:"
    echo "   ✅ Traefik Ingress Controller: Ready"
    echo "   ✅ Monitoring Stack: Ready"
    echo ""
    echo "⚡ Skipping installation completely - saving time!"
    exit 0
fi

echo ""
echo "📋 Installation Plan:"
if [[ "$INSTALL_TRAEFIK" == "true" ]]; then
    echo "   🔄 Traefik Ingress Controller will be installed"
else
    echo "   ✅ Traefik Ingress Controller already operational"
fi

if [[ "$INSTALL_MONITORING" == "true" ]]; then
    echo "   🔄 Monitoring Stack will be installed"
else
    echo "   ✅ Monitoring Stack already operational"
fi

echo ""
read -t 10 -p "Continue with installation? (auto-continue in 10s) [Y/n]: " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled by user."
    exit 0
fi

# Install Traefik if needed
if [[ "$INSTALL_TRAEFIK" == "true" ]]; then
    echo ""
    echo -e "${BLUE}🚀 Installing Traefik...${NC}"
    if bash "$SCRIPT_DIR/install-traefik.sh"; then
        echo -e "${GREEN}✅ Traefik installation completed${NC}"
    else
        echo -e "${RED}❌ Traefik installation failed${NC}"
        exit 1
    fi
fi

# Install monitoring if needed
if [[ "$INSTALL_MONITORING" == "true" ]]; then
    echo ""
    echo -e "${BLUE}📊 Installing monitoring stack...${NC}"
    if bash "$SCRIPT_DIR/install-simple-monitoring.sh"; then
        echo -e "${GREEN}✅ Monitoring installation completed${NC}"
    else
        echo -e "${RED}❌ Monitoring installation failed${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}🎉 Smart installation completed!${NC}"
echo ""
echo "📋 Final Status:"

# Show final status
if check_traefik > /dev/null 2>&1; then
    TRAEFIK_IP=$(kubectl get service traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    echo "   ✅ Traefik: Ready (IP: $TRAEFIK_IP)"
else
    echo "   ❌ Traefik: Failed"
fi

if check_monitoring > /dev/null 2>&1; then
    echo "   ✅ Monitoring: Ready"
else
    echo "   ❌ Monitoring: Failed"
fi

echo ""
echo "🔗 Access Instructions:"
echo "   Traefik Dashboard: kubectl port-forward -n traefik svc/traefik 8080:8080"
echo "   Prometheus: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "   Grafana: kubectl port-forward -n monitoring svc/grafana 3000:3000"
