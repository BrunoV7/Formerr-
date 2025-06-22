#!/bin/bash

# Test ClusterIssuers Installation
# This script verifies that ClusterIssuers are working correctly

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing ClusterIssuers Installation${NC}"
echo "========================================"

# Check if ClusterIssuers exist
echo ""
echo "📋 Checking ClusterIssuers..."
CLUSTER_ISSUERS=$(kubectl get clusterissuers -o name 2>/dev/null | wc -l)

if [ "$CLUSTER_ISSUERS" -eq 0 ]; then
    echo -e "${RED}❌ No ClusterIssuers found${NC}"
    echo "   You may need to run:"
    echo "   kubectl apply -f k8s/monitoring/ingress-cert-manager.yaml"
    exit 1
else
    echo -e "${GREEN}✅ Found $CLUSTER_ISSUERS ClusterIssuer(s)${NC}"
    kubectl get clusterissuers
fi

# Check ClusterIssuer status
echo ""
echo "📊 ClusterIssuer Details:"
echo "========================"

for issuer in $(kubectl get clusterissuers -o name 2>/dev/null); do
    issuer_name=$(echo $issuer | cut -d'/' -f2)
    echo ""
    echo "🔍 $issuer_name:"
    
    # Get the status
    STATUS=$(kubectl get clusterissuer $issuer_name -o jsonpath='{.status.conditions[0].status}' 2>/dev/null || echo "Unknown")
    REASON=$(kubectl get clusterissuer $issuer_name -o jsonpath='{.status.conditions[0].reason}' 2>/dev/null || echo "Unknown")
    MESSAGE=$(kubectl get clusterissuer $issuer_name -o jsonpath='{.status.conditions[0].message}' 2>/dev/null || echo "No message")
    
    if [ "$STATUS" = "True" ]; then
        echo -e "   Status: ${GREEN}Ready${NC}"
    elif [ "$STATUS" = "False" ]; then
        echo -e "   Status: ${RED}Not Ready${NC}"
    else
        echo -e "   Status: ${YELLOW}Unknown${NC}"
    fi
    
    echo "   Reason: $REASON"
    echo "   Message: $MESSAGE"
done

# Check cert-manager pods
echo ""
echo "🔧 Cert-Manager Pod Status:"
echo "============================"
kubectl get pods -n cert-manager

# Check for any cert-manager errors
echo ""
echo "🔍 Recent Cert-Manager Logs (errors only):"
echo "==========================================="
kubectl logs -n cert-manager deployment/cert-manager --tail=20 | grep -i error || echo "   No recent errors found"

# Test webhook endpoint
echo ""
echo "🌐 Testing Cert-Manager Webhook:"
echo "================================="
if kubectl get validatingwebhookconfigurations cert-manager-webhook &>/dev/null; then
    echo -e "${GREEN}✅ Cert-Manager webhook configuration found${NC}"
else
    echo -e "${RED}❌ Cert-Manager webhook configuration missing${NC}"
fi

# Provide next steps
echo ""
echo "🔗 Next Steps:"
echo "=============="
echo "1. If ClusterIssuers are ready, you can create Ingress resources with TLS"
echo "2. Use these annotations in your Ingress:"
echo "   cert-manager.io/cluster-issuer: letsencrypt-prod"
echo "   kubernetes.io/ingress.class: nginx"
echo ""
echo "3. Example Ingress with TLS:"
echo "   apiVersion: networking.k8s.io/v1"
echo "   kind: Ingress"
echo "   metadata:"
echo "     name: example-ingress"
echo "     annotations:"
echo "       cert-manager.io/cluster-issuer: letsencrypt-prod"
echo "       kubernetes.io/ingress.class: nginx"
echo "   spec:"
echo "     tls:"
echo "     - hosts:"
echo "       - your-domain.com"
echo "       secretName: example-tls"
echo "     rules:"
echo "     - host: your-domain.com"
echo "       http:"
echo "         paths:"
echo "         - path: /"
echo "           pathType: Prefix"
echo "           backend:"
echo "             service:"
echo "               name: your-service"
echo "               port:"
echo "                 number: 80"

echo ""
echo -e "${GREEN}🎉 ClusterIssuer test completed!${NC}"
