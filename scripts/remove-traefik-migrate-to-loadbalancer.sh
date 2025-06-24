#!/bin/bash
# Script para remover Traefik e migrar para LoadBalancer direto
# Remove componentes desnecessários para simplificar a arquitetura

set -e

echo "🧹 Removing Traefik and Migrating to Direct LoadBalancer"
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

# Check kubectl connection
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_success "Connected to cluster"

# Check if Traefik is installed
print_status "Checking for existing Traefik installation..."

TRAEFIK_NAMESPACE=$(kubectl get namespace traefik 2>/dev/null || echo "")
TRAEFIK_DEPLOYMENT=$(kubectl get deployment traefik -n traefik 2>/dev/null || echo "")

if [[ -n "$TRAEFIK_NAMESPACE" || -n "$TRAEFIK_DEPLOYMENT" ]]; then
    print_warning "Found Traefik installation. Proceeding with removal..."
    
    # Get current Traefik LoadBalancer IP (for reference)
    TRAEFIK_LB_IP=$(kubectl get service traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A")
    print_status "Current Traefik LoadBalancer IP: $TRAEFIK_LB_IP"
    
    # Scale down Traefik first (graceful shutdown)
    print_status "Scaling down Traefik deployment..."
    kubectl scale deployment traefik -n traefik --replicas=0 2>/dev/null || true
    
    # Wait a bit for graceful shutdown
    sleep 10
    
    # Remove Traefik resources
    print_status "Removing Traefik resources..."
    
    # Remove IngressRoutes that use Traefik
    kubectl delete ingressroute --all -n formerr 2>/dev/null || true
    kubectl delete ingressroute --all -n monitoring 2>/dev/null || true
    kubectl delete ingressroute --all -A 2>/dev/null || true
    
    # Remove Traefik middleware
    kubectl delete middleware --all -A 2>/dev/null || true
    
    # Remove Traefik deployment and service
    kubectl delete deployment traefik -n traefik 2>/dev/null || true
    kubectl delete service traefik -n traefik 2>/dev/null || true
    kubectl delete serviceaccount traefik -n traefik 2>/dev/null || true
    
    # Remove Traefik RBAC
    kubectl delete clusterrole traefik 2>/dev/null || true
    kubectl delete clusterrolebinding traefik 2>/dev/null || true
    
    # Remove Traefik CRDs
    kubectl delete crd ingressroutes.traefik.containo.us 2>/dev/null || true
    kubectl delete crd middlewares.traefik.containo.us 2>/dev/null || true
    kubectl delete crd tlsoptions.traefik.containo.us 2>/dev/null || true
    kubectl delete crd serverstransports.traefik.containo.us 2>/dev/null || true
    kubectl delete crd ingressroutetcps.traefik.containo.us 2>/dev/null || true
    kubectl delete crd ingressrouteudps.traefik.containo.us 2>/dev/null || true
    kubectl delete crd tlsstores.traefik.containo.us 2>/dev/null || true
    kubectl delete crd traefikservices.traefik.containo.us 2>/dev/null || true
    
    # Remove Traefik namespace
    kubectl delete namespace traefik 2>/dev/null || true
    
    print_success "Traefik removal completed"
    
    # Show what was removed
    print_status "Removed components:"
    echo "  ❌ Traefik LoadBalancer (IP: $TRAEFIK_LB_IP)"
    echo "  ❌ Traefik IngressRoutes"
    echo "  ❌ Traefik Middleware"
    echo "  ❌ Traefik CRDs"
    echo "  ❌ Traefik RBAC"
    
else
    print_success "No Traefik installation found - nothing to remove"
fi

# Verify frontend service is configured as LoadBalancer
print_status "Checking frontend service configuration..."

FRONTEND_SERVICE=$(kubectl get service formerr-frontend-service -n formerr 2>/dev/null || echo "")
if [[ -n "$FRONTEND_SERVICE" ]]; then
    SERVICE_TYPE=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.spec.type}')
    
    if [[ "$SERVICE_TYPE" == "LoadBalancer" ]]; then
        print_success "✅ Frontend service is already configured as LoadBalancer"
        
        # Get LoadBalancer IP
        FRONTEND_LB_IP=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
        print_status "Frontend LoadBalancer IP: $FRONTEND_LB_IP"
        
    else
        print_warning "Frontend service is $SERVICE_TYPE, should be LoadBalancer"
        print_status "Updating frontend service to LoadBalancer..."
        
        kubectl patch service formerr-frontend-service -n formerr -p '{"spec":{"type":"LoadBalancer"}}'
        print_success "Frontend service updated to LoadBalancer"
    fi
else
    print_warning "Frontend service not found - will be created on next deployment"
fi

# Check backend service (should be ClusterIP)
BACKEND_SERVICE=$(kubectl get service formerr-backend-service -n formerr 2>/dev/null || echo "")
if [[ -n "$BACKEND_SERVICE" ]]; then
    BACKEND_TYPE=$(kubectl get service formerr-backend-service -n formerr -o jsonpath='{.spec.type}')
    
    if [[ "$BACKEND_TYPE" == "ClusterIP" ]]; then
        print_success "✅ Backend service is correctly configured as ClusterIP (internal)"
    else
        print_warning "Backend service is $BACKEND_TYPE, should be ClusterIP for security"
        print_status "Updating backend service to ClusterIP..."
        
        kubectl patch service formerr-backend-service -n formerr -p '{"spec":{"type":"ClusterIP"}}'
        print_success "Backend service updated to ClusterIP (internal only)"
    fi
fi

# Summary
echo ""
print_success "🎉 Migration to Direct LoadBalancer completed!"
echo ""
print_status "New Architecture Summary:"
echo "  ✅ Frontend: Direct LoadBalancer (internet facing)"
echo "  ✅ Backend: ClusterIP (internal only)"
echo "  ✅ No Traefik complexity"
echo "  ✅ Monitoring: Still available via simple ingress (if needed)"
echo ""
print_status "Benefits:"
echo "  🚀 Faster: No proxy overhead"
echo "  🔒 Secure: Backend not exposed"
echo "  🎯 Simple: Direct routing"
echo "  💰 Cost: One less LoadBalancer"
echo ""

# Show current services
print_status "Current services in formerr namespace:"
kubectl get services -n formerr 2>/dev/null || echo "No services found"

echo ""
print_success "Migration completed successfully! 🎉"
print_warning "Remember to update your DNS records to point to the new frontend LoadBalancer IP"
