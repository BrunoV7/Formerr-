#!/bin/bash

# Clean Orphaned Webhooks Script
# Remove webhooks órfãos que podem interferir com novos ingress controllers

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning Orphaned Webhooks${NC}"
echo "==============================="

# Remove orphaned NGINX webhooks
echo ""
echo "🔍 Checking for orphaned NGINX webhooks..."

# Check for nginx admission webhook
if kubectl get validatingwebhookconfigurations ingress-nginx-admission &>/dev/null; then
    echo -e "${YELLOW}⚠️  Found orphaned NGINX admission webhook${NC}"
    kubectl delete validatingwebhookconfigurations ingress-nginx-admission
    echo -e "${GREEN}✅ Removed ingress-nginx-admission webhook${NC}"
else
    echo -e "${GREEN}✅ No orphaned NGINX admission webhook found${NC}"
fi

# Check for mutating webhook
if kubectl get mutatingwebhookconfigurations ingress-nginx-admission &>/dev/null; then
    echo -e "${YELLOW}⚠️  Found orphaned NGINX mutating webhook${NC}"
    kubectl delete mutatingwebhookconfigurations ingress-nginx-admission
    echo -e "${GREEN}✅ Removed ingress-nginx-admission mutating webhook${NC}"
else
    echo -e "${GREEN}✅ No orphaned NGINX mutating webhook found${NC}"
fi

# Check for cert-manager orphaned webhooks
if kubectl get validatingwebhookconfigurations cert-manager-webhook &>/dev/null; then
    # Check if cert-manager namespace exists
    if ! kubectl get namespace cert-manager &>/dev/null; then
        echo -e "${YELLOW}⚠️  Found orphaned cert-manager webhook (no cert-manager namespace)${NC}"
        kubectl delete validatingwebhookconfigurations cert-manager-webhook
        echo -e "${GREEN}✅ Removed cert-manager-webhook${NC}"
    else
        echo -e "${GREEN}✅ cert-manager webhook is valid (namespace exists)${NC}"
    fi
else
    echo -e "${GREEN}✅ No orphaned cert-manager webhook found${NC}"
fi

echo ""
echo "🔄 Updating existing Ingresses to use Traefik..."

# Get all ingresses without ingressClassName
INGRESSES=$(kubectl get ingress --all-namespaces -o json | jq -r '.items[] | select(.spec.ingressClassName == null or .spec.ingressClassName == "") | "\(.metadata.namespace)/\(.metadata.name)"')

if [ -z "$INGRESSES" ]; then
    echo -e "${GREEN}✅ All ingresses already have ingressClassName set${NC}"
else
    echo "Found ingresses without ingressClassName:"
    echo "$INGRESSES"
    
    # Update each ingress to use traefik
    echo "$INGRESSES" | while read ingress; do
        namespace=$(echo $ingress | cut -d'/' -f1)
        name=$(echo $ingress | cut -d'/' -f2)
        
        echo "  📝 Updating $namespace/$name to use traefik..."
        kubectl patch ingress "$name" -n "$namespace" -p '{"spec":{"ingressClassName":"traefik"}}' || true
    done
    
    echo -e "${GREEN}✅ Updated ingresses to use traefik${NC}"
fi

echo ""
echo "📊 Current Ingress Status:"
echo "=========================="
kubectl get ingress --all-namespaces

echo ""
echo "🎯 IngressClasses Available:"
echo "============================"
kubectl get ingressclass

echo ""
echo -e "${GREEN}🎉 Webhook cleanup completed!${NC}"
echo ""
echo "💡 If you still have issues, try:"
echo "   1. Restart problematic pods: kubectl rollout restart deployment <deployment-name> -n <namespace>"
echo "   2. Check Traefik logs: kubectl logs -n traefik deployment/traefik"
echo "   3. Test with curl: curl -H \"Host: your-domain.com\" http://TRAEFIK-IP"
