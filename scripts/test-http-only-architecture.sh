#!/bin/bash
# Test HTTP-Only Architecture
# Validates that the new simplified architecture is working

set -e

echo "🧪 Testing HTTP-Only Architecture"
echo "================================="

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

echo ""
print_status "🔍 Testing Infrastructure Components"
echo "─────────────────────────────────────"

# Test 1: Check if cert-manager is NOT installed
print_status "1. Checking that cert-manager is NOT installed..."
CERT_MANAGER_NS=$(kubectl get namespace cert-manager --ignore-not-found 2>/dev/null || echo "")
if [[ -z "$CERT_MANAGER_NS" ]]; then
    print_success "✅ cert-manager is NOT installed (correct for HTTP-only)"
else
    print_warning "⚠️  cert-manager is still installed (not needed for HTTP-only)"
fi

# Test 2: Check monitoring
print_status "2. Checking monitoring stack..."
PROMETHEUS_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --ignore-not-found 2>/dev/null | grep -v NAME || echo "")
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --ignore-not-found 2>/dev/null | grep -v NAME || echo "")

if [[ -n "$PROMETHEUS_POD" ]]; then
    print_success "✅ Prometheus is running"
else
    print_error "❌ Prometheus is not running"
fi

if [[ -n "$GRAFANA_POD" ]]; then
    print_success "✅ Grafana is running"
else
    print_error "❌ Grafana is not running"
fi

# Test 3: Check application namespace
print_status "3. Checking application namespace..."
FORMERR_NS=$(kubectl get namespace formerr --ignore-not-found 2>/dev/null || echo "")
if [[ -n "$FORMERR_NS" ]]; then
    print_success "✅ formerr namespace exists"
else
    print_warning "⚠️  formerr namespace does not exist"
fi

echo ""
print_status "🌐 Testing Application Services"
echo "─────────────────────────────────"

# Test 4: Check frontend service (LoadBalancer)
print_status "4. Checking frontend service..."
FRONTEND_SVC=$(kubectl get service formerr-frontend-service -n formerr --ignore-not-found 2>/dev/null || echo "")
if [[ -n "$FRONTEND_SVC" ]]; then
    FRONTEND_TYPE=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
    if [[ "$FRONTEND_TYPE" == "LoadBalancer" ]]; then
        print_success "✅ Frontend service is LoadBalancer type (correct)"
        
        # Check for external IP
        FRONTEND_IP=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [[ -n "$FRONTEND_IP" ]]; then
            print_success "✅ Frontend has external IP: $FRONTEND_IP"
        else
            print_warning "⏳ Frontend LoadBalancer IP is still being assigned"
        fi
    else
        print_warning "⚠️  Frontend service type is $FRONTEND_TYPE (should be LoadBalancer)"
    fi
else
    print_warning "⚠️  Frontend service not found"
fi

# Test 5: Check backend service (ClusterIP)
print_status "5. Checking backend service..."
BACKEND_SVC=$(kubectl get service formerr-backend-service -n formerr --ignore-not-found 2>/dev/null || echo "")
if [[ -n "$BACKEND_SVC" ]]; then
    BACKEND_TYPE=$(kubectl get service formerr-backend-service -n formerr -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
    if [[ "$BACKEND_TYPE" == "ClusterIP" ]]; then
        print_success "✅ Backend service is ClusterIP type (correct for internal access)"
    else
        print_warning "⚠️  Backend service type is $BACKEND_TYPE (should be ClusterIP)"
    fi
else
    print_warning "⚠️  Backend service not found"
fi

# Test 6: Check ingress (should be HTTP only)
print_status "6. Checking backend ingress..."
BACKEND_INGRESS=$(kubectl get ingress formerr-backend-ingress -n formerr --ignore-not-found 2>/dev/null || echo "")
if [[ -n "$BACKEND_INGRESS" ]]; then
    # Check if ingress has TLS section
    TLS_SECTION=$(kubectl get ingress formerr-backend-ingress -n formerr -o jsonpath='{.spec.tls}' 2>/dev/null || echo "")
    if [[ -z "$TLS_SECTION" || "$TLS_SECTION" == "null" ]]; then
        print_success "✅ Backend ingress has NO TLS section (correct for HTTP-only)"
    else
        print_warning "⚠️  Backend ingress still has TLS configuration"
    fi
    
    # Check cert-manager annotations
    CERT_ANNOTATION=$(kubectl get ingress formerr-backend-ingress -n formerr -o jsonpath='{.metadata.annotations.cert-manager\.io/cluster-issuer}' 2>/dev/null || echo "")
    if [[ -z "$CERT_ANNOTATION" ]]; then
        print_success "✅ Backend ingress has NO cert-manager annotations (correct)"
    else
        print_warning "⚠️  Backend ingress still has cert-manager annotations"
    fi
else
    print_warning "⚠️  Backend ingress not found"
fi

echo ""
print_status "🏥 Health Checks"
echo "─────────────────"

# Test 7: Pod status
print_status "7. Checking pod status..."
if kubectl get namespace formerr >/dev/null 2>&1; then
    FRONTEND_PODS=$(kubectl get pods -n formerr -l app=formerr-frontend --no-headers 2>/dev/null | wc -l || echo "0")
    BACKEND_PODS=$(kubectl get pods -n formerr -l app=formerr-backend --no-headers 2>/dev/null | wc -l || echo "0")
    
    if [[ "$FRONTEND_PODS" -gt 0 ]]; then
        FRONTEND_READY=$(kubectl get pods -n formerr -l app=formerr-frontend --no-headers 2>/dev/null | grep "Running" | wc -l || echo "0")
        print_success "✅ Frontend pods: $FRONTEND_READY/$FRONTEND_PODS running"
    else
        print_warning "⚠️  No frontend pods found"
    fi
    
    if [[ "$BACKEND_PODS" -gt 0 ]]; then
        BACKEND_READY=$(kubectl get pods -n formerr -l app=formerr-backend --no-headers 2>/dev/null | grep "Running" | wc -l || echo "0")
        print_success "✅ Backend pods: $BACKEND_READY/$BACKEND_PODS running"
    else
        print_warning "⚠️  No backend pods found"
    fi
fi

echo ""
print_status "🌍 Connectivity Tests"
echo "─────────────────────"

# Test 8: Frontend connectivity (if LoadBalancer IP available)
if [[ -n "$FRONTEND_IP" ]]; then
    print_status "8. Testing frontend connectivity..."
    if curl -s -m 10 "http://$FRONTEND_IP" >/dev/null; then
        print_success "✅ Frontend is accessible via HTTP at $FRONTEND_IP"
    else
        print_warning "⚠️  Frontend not responding at $FRONTEND_IP (might still be starting)"
    fi
else
    print_warning "⚠️  Cannot test frontend - no LoadBalancer IP yet"
fi

# Test 9: Backend internal connectivity
print_status "9. Testing backend internal connectivity..."
if kubectl get pods -n formerr >/dev/null 2>&1; then
    # Create a test pod to check internal connectivity
    kubectl run test-connectivity --rm -i --tty --image=curlimages/curl --restart=Never --timeout=30s -- \
        curl -s -m 5 http://formerr-backend-service.formerr.svc.cluster.local:8000/health 2>/dev/null && \
        print_success "✅ Backend is accessible internally" || \
        print_warning "⚠️  Backend not responding internally (might not be deployed yet)"
else
    print_warning "⚠️  Cannot test backend - namespace not ready"
fi

echo ""
print_status "📊 Summary"
echo "═══════════"

# Architecture validation
echo "🏗️  Architecture Type: HTTP-Only (Simplified)"
echo "🌍 Frontend Access: Direct LoadBalancer"
echo "🔒 Backend Access: Internal ClusterIP only"
echo "📊 Monitoring: Port-forward access"
echo "⚡ SSL/HTTPS: Disabled (for simplicity)"

echo ""
if [[ -n "$FRONTEND_IP" ]]; then
    print_status "🌐 Access URLs:"
    echo "• Frontend: http://$FRONTEND_IP"
    echo "• Backend: Internal only (http://formerr-backend-service.formerr.svc.cluster.local:8000)"
    echo "• Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo "• Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
else
    print_status "🌐 Access URLs:"
    echo "• Frontend: Check 'kubectl get svc formerr-frontend-service -n formerr' for IP"
    echo "• Backend: Internal only"
    echo "• Monitoring: Use port-forward commands"
fi

echo ""
print_success "🎉 HTTP-Only Architecture Test Complete!"
print_status "Next steps:"
echo "1. Update your DNS to point to the LoadBalancer IP"
echo "2. Test your application functionality"
echo "3. Configure monitoring dashboards"
echo "4. Deploy your application if not already done"
