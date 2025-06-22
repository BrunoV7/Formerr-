#!/bin/bash

# Fix Traefik RBAC Permissions Script
# Ensures Traefik has all necessary permissions to function properly

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing Traefik RBAC Permissions${NC}"
echo "===================================="

# Check if Traefik namespace exists
if ! kubectl get namespace traefik &>/dev/null; then
    echo -e "${YELLOW}⚠️  Traefik namespace not found - skipping RBAC fix${NC}"
    exit 0
fi

# Check if Traefik ClusterRole exists
if ! kubectl get clusterrole traefik &>/dev/null; then
    echo -e "${YELLOW}⚠️  Traefik ClusterRole not found - skipping RBAC fix${NC}"
    exit 0
fi

echo "🔍 Checking Traefik ClusterRole permissions..."

# Get current ClusterRole permissions
CURRENT_RESOURCES=$(kubectl get clusterrole traefik -o jsonpath='{.rules[3].resources}' 2>/dev/null || echo "[]")

# Check if serverstransporttcps permission exists
if echo "$CURRENT_RESOURCES" | grep -q "serverstransporttcps"; then
    echo -e "${GREEN}✅ Traefik already has serverstransporttcps permission${NC}"
else
    echo -e "${YELLOW}⚠️  Adding missing serverstransporttcps permission to Traefik${NC}"
    
    # Add the missing permission
    if kubectl patch clusterrole traefik --type='json' -p='[{"op": "add", "path": "/rules/3/resources/-", "value": "serverstransporttcps"}]' 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully added serverstransporttcps permission${NC}"
        
        # Restart Traefik deployment to apply new permissions
        echo "🔄 Restarting Traefik deployment to apply new permissions..."
        kubectl rollout restart deployment traefik -n traefik
        
        # Wait for deployment to be ready
        echo "⏳ Waiting for Traefik to be ready..."
        kubectl rollout status deployment traefik -n traefik --timeout=120s
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Traefik restarted successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Traefik restart may still be in progress${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not patch ClusterRole (may already be correct)${NC}"
    fi
fi

# Verify Traefik pod status
echo ""
echo "📊 Traefik Status:"
echo "=================="
kubectl get pods -n traefik

# Check if Traefik is ready
READY_PODS=$(kubectl get pods -n traefik -l app=traefik -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -c "True" || echo "0")

if [ "$READY_PODS" -gt 0 ]; then
    echo -e "${GREEN}✅ Traefik is running and ready${NC}"
    
    # Show LoadBalancer status
    echo ""
    echo "🌐 LoadBalancer Status:"
    echo "======================"
    kubectl get svc traefik -n traefik
    
    # Get LoadBalancer IP
    LB_IP=$(kubectl get svc traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
    echo ""
    echo "📍 External IP: $LB_IP"
    
    if [[ "$LB_IP" != "Pending..." && -n "$LB_IP" ]]; then
        echo ""
        echo -e "${GREEN}🎉 Traefik is ready for traffic!${NC}"
        echo ""
        echo "💡 Test with:"
        echo "   curl -H \"Host: your-domain.com\" http://$LB_IP"
        echo "   curl -H \"Host: your-domain.com\" https://$LB_IP -k"
    fi
else
    echo -e "${YELLOW}⚠️  Traefik pods are not ready yet${NC}"
    echo ""
    echo "🔍 Recent logs:"
    kubectl logs -n traefik deployment/traefik --tail=5 2>/dev/null || echo "   (Could not fetch logs)"
fi

echo ""
echo -e "${GREEN}🔧 Traefik RBAC fix completed!${NC}"
