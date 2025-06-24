#!/bin/bash
# Remove cert-manager completely from cluster
# Use this to clean up SSL/HTTPS infrastructure

set -e

echo "🧹 Removing cert-manager and SSL components"
echo "==========================================="

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

# Check if cert-manager exists
CERT_MANAGER_NS=$(kubectl get namespace cert-manager --ignore-not-found 2>/dev/null || echo "")

if [[ -z "$CERT_MANAGER_NS" ]]; then
    print_success "cert-manager not found - nothing to remove"
    exit 0
fi

print_warning "Found cert-manager installation - removing..."

# Remove cert-manager resources first
print_status "Removing cert-manager CRDs and resources..."

# Delete ClusterIssuers first
kubectl delete clusterissuer --all --ignore-not-found=true || true

# Delete Issuers
kubectl delete issuer --all --all-namespaces --ignore-not-found=true || true

# Delete Certificates
kubectl delete certificate --all --all-namespaces --ignore-not-found=true || true

# Delete CertificateRequests
kubectl delete certificaterequest --all --all-namespaces --ignore-not-found=true || true

# Remove helm release if it exists
print_status "Removing helm release..."
helm uninstall cert-manager -n cert-manager --ignore-not-found || true

# Remove the cert-manager deployment the direct way
print_status "Removing cert-manager deployment..."
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml --ignore-not-found=true || true

# Force remove the namespace
print_status "Removing cert-manager namespace..."
kubectl delete namespace cert-manager --ignore-not-found=true || true

# Wait a bit for cleanup
sleep 5

# Remove any remaining CRDs
print_status "Cleaning up cert-manager CRDs..."
kubectl get crd | grep cert-manager | awk '{print $1}' | xargs -r kubectl delete crd || true

# Remove webhook configurations that might be stuck
print_status "Cleaning up webhook configurations..."
kubectl delete validatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true || true
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true || true

# Remove any stuck finalizers
print_status "Removing finalizers from stuck resources..."
kubectl get certificate --all-namespaces -o json | \
  jq '.items[] | select(.metadata.finalizers != null) | "\(.metadata.namespace) \(.metadata.name)"' -r | \
  while read namespace name; do
    kubectl patch certificate "$name" -n "$namespace" --type merge -p '{"metadata":{"finalizers":[]}}' || true
  done

kubectl get certificaterequest --all-namespaces -o json | \
  jq '.items[] | select(.metadata.finalizers != null) | "\(.metadata.namespace) \(.metadata.name)"' -r | \
  while read namespace name; do
    kubectl patch certificaterequest "$name" -n "$namespace" --type merge -p '{"metadata":{"finalizers":[]}}' || true
  done

print_success "cert-manager removal completed!"

# Show what's left
print_status "Checking for any remaining cert-manager components..."
REMAINING_CRDS=$(kubectl get crd | grep cert-manager || echo "")
REMAINING_NS=$(kubectl get namespace cert-manager --ignore-not-found 2>/dev/null || echo "")

if [[ -z "$REMAINING_CRDS" && -z "$REMAINING_NS" ]]; then
    print_success "✅ cert-manager completely removed!"
else
    print_warning "⚠️  Some components might still be present:"
    [[ -n "$REMAINING_CRDS" ]] && echo "CRDs: $REMAINING_CRDS"
    [[ -n "$REMAINING_NS" ]] && echo "Namespace: still exists"
fi

echo ""
print_status "🎉 SSL/HTTPS infrastructure removed!"
print_status "Your cluster is now ready for HTTP-only setup"
print_warning "Remember to update your applications to use HTTP instead of HTTPS"
