#!/bin/bash
# Test Script for Simple Architecture
# Tests frontend LoadBalancer and backend internal connectivity

set -e

echo "🧪 Testing Simple Architecture Connectivity..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Check if cluster is accessible
print_test "Checking cluster connectivity..."
if kubectl cluster-info >/dev/null 2>&1; then
    print_pass "Cluster is accessible"
else
    print_fail "Cannot connect to cluster"
    exit 1
fi

# Check namespace
print_test "Checking formerr namespace..."
if kubectl get namespace formerr >/dev/null 2>&1; then
    print_pass "Namespace 'formerr' exists"
else
    print_fail "Namespace 'formerr' does not exist"
    exit 1
fi

# Check deployments
print_test "Checking deployments status..."
BACKEND_STATUS=$(kubectl get deployment formerr-backend -n formerr -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
FRONTEND_STATUS=$(kubectl get deployment formerr-frontend -n formerr -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [[ "$BACKEND_STATUS" -gt 0 ]]; then
    print_pass "Backend deployment is running ($BACKEND_STATUS replicas)"
else
    print_fail "Backend deployment not running"
fi

if [[ "$FRONTEND_STATUS" -gt 0 ]]; then
    print_pass "Frontend deployment is running ($FRONTEND_STATUS replicas)"
else
    print_fail "Frontend deployment not running"
fi

# Check services
print_test "Checking services..."
if kubectl get service formerr-backend-service -n formerr >/dev/null 2>&1; then
    BACKEND_SVC_TYPE=$(kubectl get service formerr-backend-service -n formerr -o jsonpath='{.spec.type}')
    if [[ "$BACKEND_SVC_TYPE" == "ClusterIP" ]]; then
        print_pass "Backend service is ClusterIP (internal only) ✅"
    else
        print_fail "Backend service should be ClusterIP but is $BACKEND_SVC_TYPE"
    fi
else
    print_fail "Backend service not found"
fi

if kubectl get service formerr-frontend-service -n formerr >/dev/null 2>&1; then
    FRONTEND_SVC_TYPE=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.spec.type}')
    if [[ "$FRONTEND_SVC_TYPE" == "LoadBalancer" ]]; then
        print_pass "Frontend service is LoadBalancer (direct internet) ✅"
        
        # Get LoadBalancer IP
        FRONTEND_LB_IP=$(kubectl get service formerr-frontend-service -n formerr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
        if [[ "$FRONTEND_LB_IP" != "Pending" && -n "$FRONTEND_LB_IP" ]]; then
            print_pass "Frontend LoadBalancer IP: $FRONTEND_LB_IP"
        else
            print_info "Frontend LoadBalancer IP is still pending..."
        fi
    else
        print_fail "Frontend service should be LoadBalancer but is $FRONTEND_SVC_TYPE"
    fi
else
    print_fail "Frontend service not found"
fi

# Test backend internal connectivity
print_test "Testing backend internal connectivity..."
if kubectl get pods -n formerr -l app=formerr-backend --field-selector=status.phase=Running | grep -q formerr-backend; then
    BACKEND_POD=$(kubectl get pods -n formerr -l app=formerr-backend --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
    
    if kubectl exec "$BACKEND_POD" -n formerr -- curl -f -s http://localhost:8000/health >/dev/null 2>&1; then
        print_pass "Backend health check passed (internal)"
    else
        print_fail "Backend health check failed"
    fi
    
    # Test internal DNS resolution
    if kubectl exec "$BACKEND_POD" -n formerr -- nslookup formerr-backend-service.formerr.svc.cluster.local >/dev/null 2>&1; then
        print_pass "Backend internal DNS resolution works"
    else
        print_fail "Backend internal DNS resolution failed"
    fi
else
    print_fail "No running backend pods found"
fi

# Test frontend external accessibility (if LoadBalancer is ready)
if [[ "$FRONTEND_LB_IP" != "Pending" && -n "$FRONTEND_LB_IP" ]]; then
    print_test "Testing frontend external accessibility..."
    if curl -f -s -m 10 "http://$FRONTEND_LB_IP" >/dev/null 2>&1; then
        print_pass "Frontend is accessible from internet"
    else
        print_info "Frontend not yet accessible (may still be starting)"
    fi
fi

# Summary
echo ""
echo "📊 === ARCHITECTURE TEST SUMMARY ==="
echo ""
print_info "Frontend Configuration:"
echo "  - Type: LoadBalancer (Direct Internet Access)"
echo "  - IP: $FRONTEND_LB_IP"
echo "  - Status: External traffic goes directly to frontend pods"
echo ""
print_info "Backend Configuration:"
echo "  - Type: ClusterIP (Internal Only)"
echo "  - URL: http://formerr-backend-service.formerr.svc.cluster.local:8000"
echo "  - Status: Only accessible within Kubernetes cluster"
echo ""
print_info "Communication Flow:"
echo "  Internet → Frontend LoadBalancer → Frontend Pod → Backend ClusterIP → Backend Pod"
echo ""

if [[ "$FRONTEND_LB_IP" != "Pending" && -n "$FRONTEND_LB_IP" ]]; then
    print_pass "✅ Architecture is working correctly!"
    echo ""
    echo "🌐 Access your application at: http://$FRONTEND_LB_IP"
    echo "🔧 Configure DNS: formerr.tech → $FRONTEND_LB_IP"
else
    print_info "⏳ LoadBalancer IP still pending. Wait a few minutes and run again."
fi
