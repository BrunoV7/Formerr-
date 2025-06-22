# Multi-Cloud Deployment Checklist

## Pre-Deployment Setup

### 1. GitHub Repository Secrets Configuration

#### Production Environment Secrets
- [ ] `DO_TOKEN_PROD` - DigitalOcean API token for production
- [ ] `DATABASE_URL` - Complete PostgreSQL connection string
- [ ] `DB_HOST` - Database host URL
- [ ] `DB_PORT` - Database port (usually 5432)
- [ ] `DB_NAME` - Database name
- [ ] `DB_USER` - Database username
- [ ] `DB_PASSWORD` - Database password
- [ ] `GITHUB_CLIENT_ID` - OAuth application client ID
- [ ] `GITHUB_CLIENT_SECRET` - OAuth application client secret
- [ ] `JWT_SECRET` - Secret for JWT token signing
- [ ] `SESSION_SECRET` - Session encryption secret

#### Staging Environment Secrets
- [ ] `DO_STAGING_TOKEN` - DigitalOcean API token for staging
- [ ] `GITHUB_CLIENT_ID` - OAuth application client ID (can be same as prod)
- [ ] `GITHUB_CLIENT_SECRET` - OAuth application client secret
- [ ] `JWT_SECRET` - JWT secret (different from production)
- [ ] `SESSION_SECRET` - Session secret (different from production)

#### Optional Monitoring/Notification Secrets
- [ ] `SLACK_WEBHOOK_URL` - For deployment notifications (optional)

### 2. DigitalOcean Setup

#### Production
- [ ] Create DigitalOcean account and project
- [ ] Generate API tokens for production and staging
- [ ] Create managed PostgreSQL database (production)
- [ ] Configure database firewall rules
- [ ] Set up DNS records (if using custom domain)

#### Container Registry
- [ ] Verify container registry access
- [ ] Test docker login with API token

### 3. Domain and DNS (Optional)
- [ ] Register domain name
- [ ] Configure DNS to point to load balancer IP
- [ ] Set up subdomains for staging environment

## Infrastructure Deployment

### 4. Terraform Validation
- [ ] Review `terraform.tfvars.example` files
- [ ] Validate Terraform configurations locally:
  ```bash
  cd infrastructure/digitalocean-production
  terraform init
  terraform validate
  terraform plan
  ```
- [ ] Check Kubernetes version compatibility
- [ ] Verify DigitalOcean region availability

### 5. Database Setup (Production)
- [ ] Create managed PostgreSQL database on DigitalOcean
- [ ] Configure connection security (VPC, firewall rules)
- [ ] Test database connectivity
- [ ] Run initial schema migration (if needed)
- [ ] Configure automated backups

## Application Deployment

### 6. CI/CD Pipeline Testing
- [ ] Test staging deployment first
- [ ] Verify container image builds successfully
- [ ] Check application starts without errors
- [ ] Validate all environment variables are set

### 7. Production Deployment Steps

#### Infrastructure
- [ ] Deploy Terraform infrastructure:
  ```bash
  # This is done automatically by GitHub Actions
  # Manual deployment:
  cd infrastructure/digitalocean-production
  terraform apply
  ```

#### Application Deployment
- [ ] Push to `main` branch to trigger production deployment
- [ ] Monitor GitHub Actions workflow progress
- [ ] Verify all steps complete successfully

#### Post-Deployment Verification
- [ ] Check all pods are running:
  ```bash
  kubectl get pods -n formerr
  ```
- [ ] Verify services are accessible:
  ```bash
  kubectl get services -n formerr
  ```
- [ ] Test application endpoints:
  - [ ] Health check: `/health`
  - [ ] API health: `/api/health`
  - [ ] Frontend loads correctly
  - [ ] Backend API responds

### 8. Monitoring and Alerting Setup
- [ ] Verify Prometheus is collecting metrics
- [ ] Access Grafana dashboard
- [ ] Configure alert routing (if using AlertManager)
- [ ] Test monitoring alerts

### 9. Security Verification
- [ ] Verify network policies are applied
- [ ] Check pod security contexts
- [ ] Validate secrets are properly configured
- [ ] Test SSL/TLS certificate (if using HTTPS)

## Post-Deployment Tasks

### 10. Performance Testing
- [ ] Run load testing:
  ```bash
  pip install locust
  locust -f scripts/load_test.py --host=https://your-domain.com
  ```
- [ ] Verify autoscaling works under load
- [ ] Check resource utilization

### 11. Backup and Recovery Testing
- [ ] Test database backup procedures
- [ ] Verify application data backup (if applicable)
- [ ] Test disaster recovery procedures

### 12. Documentation and Handover
- [ ] Update deployment documentation
- [ ] Document any environment-specific configurations
- [ ] Create runbooks for common operations
- [ ] Share access credentials with team (securely)

## Ongoing Maintenance

### 13. Regular Tasks
- [ ] Monitor application performance
- [ ] Review and rotate secrets regularly
- [ ] Update dependencies and security patches
- [ ] Review and optimize resource usage
- [ ] Monitor costs and optimize as needed

### 14. Scaling Considerations
- [ ] Monitor autoscaling effectiveness
- [ ] Review and adjust resource limits
- [ ] Plan for traffic growth
- [ ] Consider implementing CDN (if needed)

## Troubleshooting Checklist

### Common Issues
- [ ] **Pods not starting**: Check image pull secrets and container registry access
- [ ] **Database connection failed**: Verify connection strings and network policies
- [ ] **High memory usage**: Check for memory leaks, adjust resource limits
- [ ] **SSL certificate issues**: Check cert-manager logs and DNS configuration
- [ ] **Slow response times**: Review application logs and database performance

### Debugging Commands
```bash
# Check pod status
kubectl get pods -n formerr

# View pod logs
kubectl logs -f deployment/formerr-backend -n formerr

# Describe problematic pods
kubectl describe pod <pod-name> -n formerr

# Check ingress configuration
kubectl get ingress -n formerr

# View service endpoints
kubectl get endpoints -n formerr

# Check HPA status
kubectl get hpa -n formerr

# Monitor resource usage
kubectl top pods -n formerr
```

## Success Criteria

✅ **Deployment is successful when:**
- [ ] All infrastructure is provisioned via Terraform
- [ ] All pods are running and healthy
- [ ] Application is accessible via load balancer/ingress
- [ ] Database connectivity is working
- [ ] Monitoring is collecting metrics
- [ ] Autoscaling is configured and functional
- [ ] CI/CD pipelines are working
- [ ] Performance tests pass
- [ ] Security policies are in place
- [ ] Backup procedures are tested

## Emergency Procedures

### 1. Rollback Application
```bash
# Rollback to previous deployment
kubectl rollout undo deployment/formerr-backend -n formerr
kubectl rollout undo deployment/formerr-frontend -n formerr
```

### 2. Scale Down/Up
```bash
# Emergency scale down
kubectl scale deployment formerr-backend --replicas=0 -n formerr

# Scale back up
kubectl scale deployment formerr-backend --replicas=3 -n formerr
```

### 3. Emergency Infrastructure Destroy
```bash
# Run the destroy workflow via GitHub Actions
# Or manually:
cd infrastructure/digitalocean-production
terraform destroy -auto-approve
```

This checklist ensures a comprehensive and reliable deployment of your multi-cloud Formerr application with proper monitoring, security, and operational procedures in place.
