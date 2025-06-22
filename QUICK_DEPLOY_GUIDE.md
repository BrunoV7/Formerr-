# Quick Deployment Guide - Formerr Infrastructure

## 🚀 Quick Start

### Prerequisites
- DigitalOcean account with API token
- GitHub repository with required secrets
- `doctl` and `terraform` installed locally (for manual deployment)

### Required GitHub Secrets

#### Production Secrets
```
DO_TOKEN_PROD=your-production-digitalocean-token
GITHUB_CLIENT_ID=your-github-oauth-client-id
GITHUB_CLIENT_SECRET=your-github-oauth-client-secret
JWT_SECRET=your-jwt-secret-key
SESSION_SECRET=your-session-secret-key
DATABASE_URL=your-production-database-url
DB_HOST=your-db-host
DB_PORT=5432
DB_NAME=your-db-name
DB_USER=your-db-user
DB_PASSWORD=your-db-password
```

#### Staging Secrets
```
DO_STAGING_TOKEN=your-staging-digitalocean-token
# GitHub secrets are shared between environments
```

## 🎯 Deployment Options

### Option 1: GitHub Actions (Recommended)

#### Deploy to Staging
1. Push to `develop` or `staging` branch
2. Or manually trigger workflow:
   - Go to Actions → "Deploy to Staging"
   - Click "Run workflow"

#### Deploy to Production
1. Push to `main` branch
2. Or manually trigger workflow:
   - Go to Actions → "Deploy to Production"
   - Click "Run workflow"

### Option 2: Manual Deployment

#### 1. Validate Configuration
```bash
chmod +x scripts/*.sh
./scripts/validate-terraform.sh
```

#### 2. Deploy to Staging
```bash
# Set environment variables
export DO_TOKEN="your-staging-token"
export GITHUB_CLIENT_ID="your-client-id"
export GITHUB_CLIENT_SECRET="your-client-secret"
export JWT_SECRET="your-jwt-secret"
export SESSION_SECRET="your-session-secret"

# Deploy
./scripts/smart-deploy.sh staging formerr-staging
```

#### 3. Deploy to Production
```bash
# Set all environment variables (including database)
export DO_TOKEN="your-production-token"
export GITHUB_CLIENT_ID="your-client-id"
export GITHUB_CLIENT_SECRET="your-client-secret"
export JWT_SECRET="your-jwt-secret"
export SESSION_SECRET="your-session-secret"
export DATABASE_URL="your-database-url"
export DB_HOST="your-db-host"
export DB_PORT="5432"
export DB_NAME="your-db-name"
export DB_USER="your-db-user"
export DB_PASSWORD="your-db-password"

# Deploy
./scripts/smart-deploy.sh production formerr-registry
```

## 📋 Post-Deployment Checklist

### 1. Verify Infrastructure
```bash
# Check clusters
doctl kubernetes cluster list

# Check registries
doctl registry list

# Check load balancers
doctl load-balancer list
```

### 2. Verify Kubernetes Deployment
```bash
# Get cluster config
doctl kubernetes cluster kubeconfig save <cluster-name>

# Check pods
kubectl get pods -n formerr

# Check services
kubectl get svc -n formerr

# Check ingress
kubectl get ing -n formerr
```

### 3. Test Application
```bash
# Check backend health
kubectl exec -n formerr deployment/formerr-backend -- curl -f http://localhost:8000/health

# Get load balancer IP
kubectl get service ingress-nginx-controller -n ingress-nginx
```

## 🛠️ Troubleshooting

### Common Issues & Solutions

#### 1. "Resource already exists" error
**Solution**: Use the smart deployment script - it detects existing resources automatically.

#### 2. Terraform validation fails
```bash
# Check syntax
terraform validate

# Check formatting
terraform fmt -check
```

#### 3. Container registry authentication fails
```bash
# Re-login to registry
doctl registry login

# Check registry access
doctl registry repository list
```

#### 4. Kubernetes connection issues
```bash
# Refresh cluster config
doctl kubernetes cluster kubeconfig save <cluster-name>

# Test connection
kubectl cluster-info
```

### Debug Commands

```bash
# Check resource detection
./scripts/smart-deploy.sh staging formerr-staging --dry-run

# View Terraform plan
cd infrastructure/digitalocean-staging
terraform plan

# Check GitHub Actions logs
# Go to GitHub → Actions → Select workflow run → View logs
```

## 🔧 Customization

### Modify Resource Configuration

Edit the appropriate Terraform files:
- **Production**: `infrastructure/digitalocean-production/main.tf`
- **Staging**: `infrastructure/digitalocean-staging/main.tf`

### Update Scripts

- **Smart Deploy**: `scripts/smart-deploy.sh`
- **Validation**: `scripts/validate-terraform.sh`
- **Staging Update**: `scripts/update-staging.sh`

### Modify Workflows

- **Production**: `.github/workflows/deploy-production.yml`
- **Staging**: `.github/workflows/deploy-staging.yml`
- **Destroy**: `.github/workflows/destroy-infrastructure.yml`

## 🗑️ Cleanup/Destroy

### Destroy Infrastructure
1. Go to GitHub Actions
2. Select "Destroy Infrastructure" workflow
3. Choose environment (staging/production)
4. Type "DESTROY" to confirm
5. Run workflow

### Manual Destroy
```bash
cd infrastructure/digitalocean-staging  # or digitalocean-production
terraform destroy
```

## 📞 Support

### Documentation
- [IDEMPOTENT_INFRASTRUCTURE.md](./IDEMPOTENT_INFRASTRUCTURE.md) - Detailed technical documentation
- [DEPLOYMENT_README.md](./DEPLOYMENT_README.md) - General deployment guide

### Getting Help
1. Check GitHub Actions logs for error details
2. Review Terraform plan output
3. Verify all required secrets are set
4. Ensure DigitalOcean API tokens have required permissions

### Useful Links
- [DigitalOcean API Documentation](https://docs.digitalocean.com/reference/api/)
- [Terraform DigitalOcean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
