# 🚀 Formerr - Clean Redeploy Guide

## ✅ Pre-Deployment Checklist

### 1. **GitHub Secrets Verification** ✅
Confirm all secrets are set in GitHub repository settings:
- `DO_TOKEN_PROD` - DigitalOcean Production Token
- `CLIENT_ID` - GitHub OAuth App Client ID  
- `CLIENT_SECRET` - GitHub OAuth App Client Secret
- `JWT_SECRET` - JWT Secret Key
- `SESSION_SECRET` - Session Secret Key
- `DATABASE_URL` - Will be generated during deployment
- `DB_HOST` - Will be configured during deployment
- `DB_PORT` - Will be configured during deployment
- `DB_NAME` - Will be configured during deployment
- `DB_USER` - Will be configured during deployment
- `DB_PASSWORD` - Will be configured during deployment

### 2. **DNS Configuration Ready** ✅
Prepare to update these DNS A records after deployment:
- `formerr.tech` → Load Balancer IP
- `api.formerr.tech` → Load Balancer IP
- `prometheus.formerr.tech` → Load Balancer IP
- `grafana.formerr.tech` → Load Balancer IP

### 3. **GitHub OAuth App Configuration** ✅
Update authorization callback URL to:
- `https://api.formerr.tech/auth/github/callback`

---

## 🧹 Clean Environment Setup

### Step 1: Complete Cleanup (Optional but Recommended)
```bash
# Set your DigitalOcean token
export DO_TOKEN_PROD="your_digitalocean_token_here"

# Run the cleanup script
chmod +x scripts/cleanup-digitalocean.sh
./scripts/cleanup-digitalocean.sh
```

### Step 2: Wait for Cleanup
Wait 5-10 minutes for all DigitalOcean resources to be fully deleted.

---

## 🚀 Fresh Deployment

### Step 3: Trigger Deployment
```bash
# Commit any final changes
git add .
git commit -m "feat: prepare for clean production deployment"
git push origin main
```

### Step 4: Monitor Deployment
1. Go to GitHub Actions: `https://github.com/your-username/Formerr-/actions`
2. Watch the "Deploy to Production (DigitalOcean)" workflow
3. Expected runtime: 15-20 minutes

---

## 🔍 Post-Deployment Verification

### Step 5: Get Load Balancer IP
After deployment completes, the pipeline will output the Load Balancer IP.

### Step 6: Update DNS Records
Update all DNS A records to point to the new Load Balancer IP:
```
A    formerr.tech           → NEW_LB_IP
A    api.formerr.tech       → NEW_LB_IP  
A    prometheus.formerr.tech → NEW_LB_IP
A    grafana.formerr.tech   → NEW_LB_IP
```

### Step 7: Test Access
Wait 5-10 minutes for DNS propagation, then test:

1. **Frontend**: https://formerr.tech
2. **API Health**: https://api.formerr.tech/health
3. **Prometheus**: https://prometheus.formerr.tech (admin/admin123)
4. **Grafana**: https://grafana.formerr.tech (admin/admin123)

### Step 8: SSL Certificate Verification
```bash
# Connect to cluster
doctl kubernetes cluster kubeconfig save formerr-production-cluster

# Check certificate status
kubectl get certificates -n formerr
kubectl get certificates -n monitoring

# Should show READY=True after 5-10 minutes
```

---

## 🎯 Key Improvements in This Deployment

### ✅ **Fixed Issues**
- **Frontend Build**: Added missing utility files (`src/lib/utils.ts`, `src/lib/api.ts`)
- **CORS Configuration**: Properly configured for both domains
- **Database Connectivity**: Automated firewall configuration using cluster ID
- **Load Balancer**: Disabled PROXY protocol for DigitalOcean compatibility
- **Resource Optimization**: Removed autoscaling for free tier compatibility
- **Monitoring**: Added Prometheus and Grafana with proper ingress
- **SSL/TLS**: Proper cert-manager configuration with Let's Encrypt

### ✅ **Pipeline Enhancements**
- **Idempotent Infrastructure**: Terraform handles existing resources gracefully
- **Dynamic Database Config**: Automatically configures database network access
- **Smart Resource Detection**: Detects and reuses existing infrastructure
- **Comprehensive Validation**: Health checks and status verification
- **Monitoring Integration**: Automated monitoring stack deployment

### ✅ **Security & Best Practices**
- **Network Policies**: Kubernetes network security
- **Resource Limits**: Memory and CPU quotas
- **Secret Management**: Kubernetes secrets for sensitive data
- **Basic Auth**: Protected monitoring endpoints
- **TLS Everywhere**: HTTPS for all services

---

## 🚨 Troubleshooting

### If Deployment Fails:
1. Check GitHub Actions logs for specific error
2. Common issues and solutions:
   - **Database connection**: Check firewall rules in DigitalOcean dashboard
   - **DNS issues**: Verify A records are correct
   - **Certificate issues**: Check cert-manager logs: `kubectl logs -n cert-manager deployment/cert-manager`
   - **Ingress issues**: Check ingress controller: `kubectl logs -n ingress-nginx deployment/ingress-nginx-controller`

### If Services Are Unreachable:
1. Verify Load Balancer IP: `kubectl get service ingress-nginx-controller -n ingress-nginx`
2. Check ingress status: `kubectl get ingress -A`
3. Verify pods are running: `kubectl get pods -A`
4. Check DNS propagation: `nslookup formerr.tech`

---

## 📞 Support Commands

```bash
# Connect to cluster
doctl kubernetes cluster kubeconfig save formerr-production-cluster

# Check overall status
kubectl get pods -A
kubectl get services -A
kubectl get ingress -A

# Check logs
kubectl logs -n formerr deployment/formerr-frontend
kubectl logs -n formerr deployment/formerr-backend
kubectl logs -n monitoring deployment/prometheus
kubectl logs -n monitoring deployment/grafana

# Force certificate renewal
kubectl delete certificate formerr-tls -n formerr
kubectl delete certificate monitoring-tls -n monitoring
kubectl apply -f k8s/production/ingress.yaml
kubectl apply -f k8s/monitoring/monitoring-ingress.yaml
```

---

## 🎉 Success Criteria

**Deployment is successful when:**
- ✅ All pods are running and ready
- ✅ Load Balancer has external IP
- ✅ DNS records are updated
- ✅ All HTTPS endpoints are accessible
- ✅ SSL certificates are issued (READY=True)
- ✅ Backend health check passes
- ✅ Frontend loads without errors
- ✅ Monitoring dashboards are accessible

**Expected Total Time:** 30-45 minutes (including cleanup and DNS propagation)
