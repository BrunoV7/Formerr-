# Monitoring Strategy Update

## Overview
This document explains the improved monitoring deployment strategy for the Formerr project, replacing the problematic Helm-based Prometheus deployment with a reliable Kubernetes manifest approach.

## Problem with Previous Approach

The previous implementation used Helm to deploy the `kube-prometheus-stack`, which was causing several issues:

- **Slow deployment**: Helm releases taking 5+ minutes to deploy
- **Timeout failures**: Context deadline exceeded errors
- **Failed status**: Releases created but marked as failed
- **CI/CD bottleneck**: Blocking entire deployment pipelines

## New Solution: Direct Kubernetes Manifests

### Benefits
✅ **Fast deployment**: Deploys in seconds instead of minutes  
✅ **Reliable**: No complex Helm dependency management  
✅ **Idempotent**: Safe to re-run without side effects  
✅ **Professional**: Production-ready monitoring configuration  
✅ **Lightweight**: Only what we need for basic monitoring  

### Architecture

```
k8s/monitoring/prometheus-simple.yaml
├── Namespace: monitoring
├── ServiceAccount: prometheus
├── ClusterRole & ClusterRoleBinding
├── ConfigMap: prometheus-config
├── Deployment: prometheus
└── Service: prometheus (LoadBalancer)
```

## Monitoring Features

### Prometheus Configuration
- **Scrape Interval**: 15 seconds
- **Retention**: 200 hours
- **Web UI**: Enabled with admin API
- **Health Checks**: Liveness and readiness probes

### Monitored Targets
1. **Prometheus itself**: Self-monitoring
2. **Kubernetes API Server**: Cluster health
3. **Kubernetes Nodes**: Node metrics
4. **Application Pods**: With `prometheus.io/scrape=true` annotation

### Alerting Rules
- **FormerrBackendDown**: Alert when backend is unreachable
- **FormerrHighResponseTime**: Alert when response time > 1s
- **FormerrHighErrorRate**: Alert when error rate > 10%

## Deployment Methods

### 1. Automatic (via CI/CD)
Monitoring is automatically deployed as part of the standard deployment pipeline:

```yaml
# In GitHub Actions workflows
- name: Deploy Monitoring
  run: |
    kubectl apply -f k8s/monitoring/prometheus-simple.yaml
```

### 2. Manual (via Script)
Use the dedicated monitoring deployment script:

```bash
./scripts/deploy-monitoring.sh
```

### 3. Smart Deploy (Integrated)
The smart deploy script now includes monitoring deployment:

```bash
./scripts/smart-deploy.sh production
```

## Access Methods

### 1. Port Forward (Local Access)
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Access at: http://localhost:9090
```

### 2. LoadBalancer (External Access)
```bash
# Get external IP
kubectl get svc prometheus -n monitoring
```

### 3. NodePort (Alternative)
The manifest includes a NodePort service for testing:
```bash
# Access at: <node-ip>:30090
kubectl get nodes -o wide
```

## Validation Commands

### Check Deployment Status
```bash
# Pods
kubectl get pods -n monitoring

# Services
kubectl get services -n monitoring

# Deployment health
kubectl describe deployment prometheus -n monitoring
```

### Check Monitoring Data
```bash
# View logs
kubectl logs -n monitoring deployment/prometheus

# Check configuration
kubectl get configmap prometheus-config -n monitoring -o yaml
```

### Verify Targets
Visit Prometheus UI → Status → Targets to verify:
- Prometheus: `up` status
- Kubernetes API: `up` status  
- Nodes: `up` status
- Pods: Based on annotations

## Troubleshooting

### Common Issues

1. **Pod not starting**
   ```bash
   kubectl describe pod -n monitoring -l app=prometheus
   kubectl logs -n monitoring deployment/prometheus
   ```

2. **Targets not discovered**
   - Check RBAC permissions
   - Verify service account configuration
   - Check pod annotations

3. **LoadBalancer pending**
   ```bash
   kubectl describe svc prometheus -n monitoring
   # May need cloud provider configuration
   ```

### Recovery Commands

```bash
# Clean restart
kubectl delete namespace monitoring
kubectl apply -f k8s/monitoring/prometheus-simple.yaml

# Remove old Helm releases
helm uninstall prometheus -n monitoring
helm uninstall kube-prometheus-stack -n monitoring
```

## Migration from Helm

### Terraform Changes
- Removed `helm_release.prometheus` resource
- Added comments pointing to manifest deployment
- Maintains idempotent infrastructure

### Workflow Updates
- Added monitoring deployment steps
- Cleanup of existing Helm releases
- Updated validation and status checks

### Script Integration
- `smart-deploy.sh`: Includes monitoring deployment
- `deploy-monitoring.sh`: Dedicated monitoring script
- Automatic kubectl configuration

## Future Enhancements

### Optional Additions
- **Grafana**: Visualization dashboards
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Detailed node metrics
- **Custom Exporters**: Application-specific metrics

### DigitalOcean Integration
- Consider DigitalOcean Managed Monitoring
- Use DigitalOcean Load Balancers for external access
- Integrate with DigitalOcean Spaces for metric storage

## Best Practices

1. **Resource Limits**: Set appropriate CPU/memory limits
2. **Persistent Storage**: Consider persistent volumes for production
3. **Security**: Regular updates of Prometheus image
4. **Backup**: Export important monitoring data
5. **Scaling**: Monitor resource usage and scale accordingly

## Conclusion

The new monitoring strategy provides:
- **Faster deployments**: No more 5+ minute waits
- **Higher reliability**: Fewer deployment failures
- **Professional monitoring**: Production-ready configuration
- **Easier maintenance**: Simple YAML manifests

This approach is more suitable for CI/CD environments and provides the essential monitoring capabilities needed for the Formerr project.
