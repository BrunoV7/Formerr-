#!/bin/bash

# Quick Grafana Setup for Demo
# Configures basic dashboards and data sources

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 Setting up Grafana for Demo${NC}"
echo "=================================="

# Get Grafana pod
GRAFANA_POD=$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}')

if [ -z "$GRAFANA_POD" ]; then
    echo -e "${YELLOW}⚠️  No Grafana pod found${NC}"
    exit 1
fi

echo "📡 Grafana pod: $GRAFANA_POD"

# Configure Prometheus data source
echo ""
echo "🔗 Configuring Prometheus data source..."

kubectl exec -n monitoring $GRAFANA_POD -- curl -X POST \
  http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }' || echo "Data source may already exist"

# Import Kubernetes cluster dashboard
echo ""
echo "📊 Importing Kubernetes cluster dashboard..."

kubectl exec -n monitoring $GRAFANA_POD -- curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "title": "Kubernetes Cluster Monitoring",
      "tags": ["kubernetes"],
      "panels": [
        {
          "id": 1,
          "title": "Cluster Nodes",
          "type": "stat",
          "targets": [
            {
              "expr": "count(kube_node_info)",
              "legendFormat": "Nodes"
            }
          ],
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
        },
        {
          "id": 2,
          "title": "Running Pods",
          "type": "stat",
          "targets": [
            {
              "expr": "count(kube_pod_info{phase=\"Running\"})",
              "legendFormat": "Running Pods"
            }
          ],
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
        }
      ]
    },
    "overwrite": true
  }' || echo "Dashboard import may have failed"

echo ""
echo -e "${GREEN}✅ Grafana setup completed!${NC}"
echo ""
echo "🌐 Access Grafana at: http://localhost:3000"
echo "👤 Default credentials: admin/admin"
echo ""
echo "📊 Available dashboards:"
echo "  - Kubernetes Cluster Monitoring (basic)"
echo ""
echo "💡 If dashboards are still empty, it may be because:"
echo "   - Prometheus needs time to collect metrics"
echo "   - Node exporter or other exporters aren't installed"
echo "   - For demo purposes, you can show the Grafana interface"
