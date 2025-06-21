#!/bin/bash

echo "🔍 Obtendo IPs dos Load Balancers..."
echo ""

echo "📋 PRODUÇÃO (main cluster):"
echo "Comando para obter IP do Load Balancer:"
echo "kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""

echo "📋 STAGING (develop cluster):"
echo "Comando para obter IP do Load Balancer:"
echo "kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""

echo "💡 EXEMPLO de resultado:"
echo "Produção IP: 157.245.100.50"
echo "Staging IP: 142.93.200.75"
echo ""

echo "📝 Use esses IPs para configurar o DNS..."
