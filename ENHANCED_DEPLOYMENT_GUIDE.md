# 🚀 Enhanced Infrastructure Deployment Guide

## 📋 Quick Start

This guide shows how to deploy the enhanced infrastructure manifests that resolve all the issues encountered with the previous deployment.

## 🔧 Prerequisites

1. **Kubectl configured** for your DigitalOcean cluster
2. **doctl installed** and authenticated
3. **Enhanced manifests** available in this repository

## 🚀 Option 1: Automated Deployment (Recommended)

### **Production Deployment**
```bash
# Make script executable
chmod +x scripts/enhanced-smart-deploy.sh

# Deploy to production
./scripts/enhanced-smart-deploy.sh production
```

### **Staging Deployment**
```bash
# Deploy to staging
./scripts/enhanced-smart-deploy.sh staging
```

The enhanced script will:
- ✅ Clean up orphaned resources
- ✅ Install Traefik with proper configuration
- ✅ Deploy monitoring stack
- ✅ Deploy application with enhanced manifests
- ✅ Verify deployment health
- ✅ Display access information

## 🛠️ Option 2: Manual Step-by-Step Deployment

### **Step 1: Clean Up Previous Issues**
```bash
# Clean orphaned webhooks
bash scripts/clean-orphaned-webhooks.sh

# Remove old NGINX resources
kubectl delete validatingwebhookconfiguration ingress-nginx-admission --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration ingress-nginx-admission --ignore-not-found=true
kubectl delete ingressclass nginx --ignore-not-found=true
```

### **Step 2: Deploy Enhanced Traefik**
```bash
# Deploy complete Traefik configuration with fixes
kubectl apply -f k8s/ingress/traefik-production-complete.yaml

# Wait for Traefik to be ready
kubectl wait --namespace=traefik \
  --for=condition=ready pod \
  --selector=app=traefik \
  --timeout=300s

# Check LoadBalancer IP
kubectl get svc traefik -n traefik
```

### **Step 3: Deploy Application Namespace**
```bash
# Create namespace with proper configuration
kubectl apply -f k8s/production/namespace-and-secrets.yaml
```

### **Step 4: Deploy Enhanced Monitoring**
```bash
# Deploy complete monitoring stack
kubectl apply -f k8s/monitoring/production-monitoring-complete.yaml

# Wait for monitoring to be ready
kubectl wait --namespace=monitoring \
  --for=condition=ready pod \
  --selector=app=prometheus \
  --timeout=300s
  
kubectl wait --namespace=monitoring \
  --for=condition=ready pod \
  --selector=app=grafana \
  --timeout=300s
```

### **Step 5: Deploy Enhanced Application**
```bash
# Deploy backend with enhanced configuration
kubectl apply -f k8s/production/backend-deployment-enhanced.yaml

# Deploy frontend with enhanced configuration
kubectl apply -f k8s/production/frontend-deployment-enhanced.yaml

# Deploy enhanced ingress
kubectl apply -f k8s/production/ingress-enhanced.yaml

# Wait for application deployments
kubectl wait --namespace=formerr \
  --for=condition=available deployment/formerr-backend \
  --timeout=600s
  
kubectl wait --namespace=formerr \
  --for=condition=available deployment/formerr-frontend \
  --timeout=600s
```

## 🔍 Verification

### **Check All Components**
```bash
# Check Traefik
kubectl get pods -n traefik
kubectl get svc -n traefik

# Check Application
kubectl get pods -n formerr
kubectl get svc -n formerr
kubectl get ingress -n formerr

# Check Monitoring
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### **Get LoadBalancer IP**
```bash
EXTERNAL_IP=$(kubectl get svc traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "LoadBalancer IP: $EXTERNAL_IP"
```

### **Test Health Endpoints**
```bash
# Test backend health
curl -H "Host: api.formerr.tech" http://$EXTERNAL_IP/health

# Test frontend (should return HTML)
curl -H "Host: formerr.tech" http://$EXTERNAL_IP/
```

## 🌐 DNS Configuration

Update your DNS records to point to the LoadBalancer IP:

### **Production**
- `formerr.tech` → `$EXTERNAL_IP`
- `api.formerr.tech` → `$EXTERNAL_IP`
- `prometheus.formerr.tech` → `$EXTERNAL_IP`
- `grafana.formerr.tech` → `$EXTERNAL_IP`
- `traefik.formerr.tech` → `$EXTERNAL_IP`

### **Staging**
- `staging.formerr.tech` → `$EXTERNAL_IP`
- `api-staging.formerr.tech` → `$EXTERNAL_IP`

## 📊 Access Services

### **With DNS (after DNS propagation)**
- **Frontend**: https://formerr.tech
- **Backend API**: https://api.formerr.tech
- **Grafana**: https://grafana.formerr.tech (admin:admin)
- **Prometheus**: https://prometheus.formerr.tech
- **Traefik Dashboard**: https://traefik.formerr.tech (admin:admin)

### **Port-Forward (immediate access)**
```bash
# Frontend
kubectl port-forward -n formerr svc/formerr-frontend-service 3000:3000

# Backend
kubectl port-forward -n formerr svc/formerr-backend-service 8000:8000

# Grafana
kubectl port-forward -n monitoring svc/grafana 3001:3000

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Traefik Dashboard
kubectl port-forward -n traefik svc/traefik-dashboard 8082:8082
```

## 🔐 Default Credentials

### **Grafana**
- Username: `admin`
- Password: `admin`

### **Traefik Dashboard**
- Username: `admin`
- Password: `admin`

⚠️ **Security Note**: Change these default passwords in production!

## 📈 Import Grafana Dashboard

1. Access Grafana via port-forward or DNS
2. Go to **Dashboards** → **Import**
3. Upload `monitoring/grafana-dashboard-formerr.json`
4. Configure Prometheus datasource if needed

## 🚨 Troubleshooting

### **Traefik Pod CrashLoopBackOff**
```bash
# Check logs
kubectl logs -n traefik -l app=traefik

# Common fix: restart deployment
kubectl rollout restart deployment/traefik -n traefik
```

### **LoadBalancer IP Not Assigned**
```bash
# Check LoadBalancer status
kubectl describe svc traefik -n traefik

# Force recreation if stuck
kubectl delete svc traefik -n traefik
kubectl apply -f k8s/ingress/traefik-production-complete.yaml
```

### **SSL Certificates Not Issued**
```bash
# Check certificate secrets
kubectl get secrets -n formerr | grep tls

# Check Traefik logs for ACME
kubectl logs -n traefik -l app=traefik | grep -i acme
```

### **Pods Not Starting**
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check resource constraints
kubectl top nodes
kubectl top pods --all-namespaces
```

## 🔄 Rollback Strategy

If you need to rollback to previous manifests:

```bash
# Rollback application
kubectl apply -f k8s/production/backend-deployment.yaml
kubectl apply -f k8s/production/frontend-deployment.yaml
kubectl apply -f k8s/production/ingress.yaml

# Or use kubectl rollout undo
kubectl rollout undo deployment/formerr-backend -n formerr
kubectl rollout undo deployment/formerr-frontend -n formerr
```

## ✅ Success Indicators

Your deployment is successful when:

1. ✅ All pods are in `Running` state
2. ✅ LoadBalancer has an external IP
3. ✅ Health endpoints respond successfully
4. ✅ SSL certificates are automatically issued
5. ✅ Grafana dashboard shows metrics
6. ✅ Application is accessible via domain names

## 📞 Support

If you encounter issues:

1. Check the logs: `kubectl logs -l app=<component> -n <namespace>`
2. Verify resources: `kubectl describe <resource> <name> -n <namespace>`
3. Review the troubleshooting section above
4. Consult `INFRASTRUCTURE_ENHANCEMENT_SUMMARY.md` for detailed explanations

## 🎯 Next Steps

After successful deployment:

1. **Monitor Performance**: Watch Grafana dashboards
2. **Test Auto-scaling**: Generate load to test HPA
3. **Security Review**: Update default passwords
4. **Backup Strategy**: Configure regular backups
5. **Documentation**: Update team documentation
