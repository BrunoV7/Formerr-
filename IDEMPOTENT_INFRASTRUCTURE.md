# Idempotent Multi-Cloud Infrastructure for Formerr

This document describes the robust, idempotent infrastructure setup for the Formerr project, designed to handle resource existence checks, smart deployments, and resilient operations across multiple environments.

## Overview

The infrastructure has been redesigned to:
- ✅ **Detect existing resources** before attempting to create new ones
- ✅ **Use data sources** to reference existing infrastructure
- ✅ **Provide safe re-deployment** capabilities
- ✅ **Support both production and staging** environments
- ✅ **Enable smart resource management** through helper scripts

## Infrastructure Structure

```
infrastructure/
├── digitalocean-production/
│   ├── main.tf              # Production infrastructure with idempotent logic
│   ├── variables.tf         # Variables for resource control
│   └── outputs.tf           # Dynamic outputs for existing/new resources
├── digitalocean-staging/
│   ├── main.tf              # Staging infrastructure with idempotent logic
│   ├── variables.tf         # Variables for resource control
│   └── outputs.tf           # Dynamic outputs for existing/new resources
└── scripts/
    ├── smart-deploy.sh      # Smart deployment with resource detection
    ├── validate-terraform.sh # Terraform validation script
    └── update-staging.sh    # Staging environment synchronization
```

## Key Features

### 1. Resource Existence Detection

The infrastructure automatically detects existing resources:

- **VPC**: Checks for existing VPC by name before creating
- **Kubernetes Cluster**: Detects existing clusters
- **Container Registry**: Finds existing registries
- **Load Balancer**: Checks for existing load balancers

### 2. Control Variables

Each environment supports control variables:

```hcl
variable "use_existing_vpc" {
  description = "Use existing VPC instead of creating new one"
  type        = bool
  default     = false
}

variable "use_existing_cluster" {
  description = "Use existing cluster instead of creating new one"
  type        = bool
  default     = false
}

variable "use_existing_loadbalancer" {
  description = "Use existing load balancer instead of creating new one"
  type        = bool
  default     = false
}

variable "create_registry" {
  description = "Create new container registry"
  type        = bool
  default     = true
}
```

### 3. Data Sources and Local Values

Resources are abstracted through local values:

```hcl
locals {
  vpc_id = var.use_existing_vpc ? data.digitalocean_vpc.existing[0].id : digitalocean_vpc.formerr_vpc[0].id
  cluster_id = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing[0].id : digitalocean_kubernetes_cluster.formerr_cluster[0].id
  registry_endpoint = var.create_registry ? digitalocean_container_registry.formerr_registry[0].endpoint : data.digitalocean_container_registry.existing[0].endpoint
}
```

## Smart Deployment Scripts

### 1. Smart Deploy Script (`scripts/smart-deploy.sh`)

Automatically detects existing resources and sets appropriate Terraform variables:

```bash
./scripts/smart-deploy.sh production formerr-registry
./scripts/smart-deploy.sh staging formerr-staging
```

**Features:**
- Detects existing VPC, cluster, registry, and load balancer
- Sets appropriate Terraform variables
- Runs Terraform with optimal configuration
- Provides detailed logging

### 2. Validation Script (`scripts/validate-terraform.sh`)

Validates both production and staging Terraform configurations:

```bash
./scripts/validate-terraform.sh
```

**Features:**
- Validates syntax and configuration
- Checks for common issues
- Ensures consistency between environments

### 3. Staging Update Script (`scripts/update-staging.sh`)

Ensures staging environment is synchronized with production patterns:

```bash
./scripts/update-staging.sh
```

## Updated GitHub Actions Workflows

### Production Deployment (`.github/workflows/deploy-production.yml`)

**Key Updates:**
- Uses smart deployment script
- Dynamic resource detection
- Terraform output-based configuration
- Registry endpoint detection

```yaml
- name: Detect Existing Resources and Deploy Infrastructure
  run: |
    chmod +x scripts/smart-deploy.sh scripts/validate-terraform.sh
    ./scripts/validate-terraform.sh
    
    export DO_TOKEN="${{ secrets.DO_TOKEN_PROD }}"
    # ... other environment variables
    
    ./scripts/smart-deploy.sh production "formerr-registry"

- name: Configure kubectl for Production Cluster
  run: |
    cd infrastructure/digitalocean-production
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME"
```

### Staging Deployment (`.github/workflows/deploy-staging.yml`)

**Key Updates:**
- Uses staging-specific scripts
- PostgreSQL database deployment
- Integration testing
- Dynamic resource management

### Destroy Infrastructure (`.github/workflows/destroy-infrastructure.yml`)

**Key Updates:**
- Environment-specific variable handling
- Safe destruction process
- Proper variable passing

## Usage Examples

### Manual Deployment

1. **Validate configuration:**
   ```bash
   ./scripts/validate-terraform.sh
   ```

2. **Deploy to staging:**
   ```bash
   export DO_TOKEN="your-staging-token"
   export GITHUB_CLIENT_ID="your-client-id"
   # ... set other required variables
   
   ./scripts/smart-deploy.sh staging formerr-staging
   ```

3. **Deploy to production:**
   ```bash
   export DO_TOKEN="your-production-token"
   # ... set all required variables including database configs
   
   ./scripts/smart-deploy.sh production formerr-registry
   ```

### GitHub Actions Deployment

1. **Push to develop/staging branch** → Triggers staging deployment
2. **Push to main branch** → Triggers production deployment
3. **Manual workflow dispatch** → Deploy to specific environment

## Resource Management

### Existing Resources

When resources exist, the infrastructure:
- Uses data sources to reference them
- Applies local values for consistent access
- Maintains existing resource configuration
- Avoids conflicts and errors

### New Resources

When resources don't exist, the infrastructure:
- Creates new resources with proper naming
- Applies tags and metadata
- Configures networking and security
- Sets up monitoring and logging

## Monitoring and Validation

### Health Checks

The deployment includes health checks for:
- ✅ Kubernetes cluster connectivity
- ✅ Container registry accessibility
- ✅ Load balancer functionality
- ✅ Application deployment status

### Post-Deployment Validation

```bash
# Check cluster status
kubectl get nodes

# Verify deployments
kubectl get deployments -n formerr

# Check services and ingress
kubectl get svc,ing -n formerr

# Test application health
kubectl exec -n formerr deployment/formerr-backend -- curl -f http://localhost:8000/health
```

## Best Practices

### 1. Always Validate First
```bash
./scripts/validate-terraform.sh
```

### 2. Use Environment Variables
Set all required environment variables before deployment

### 3. Monitor Terraform State
- Keep state files secure
- Use remote state storage in production
- Regular state file backups

### 4. Test in Staging First
- Always test changes in staging
- Validate with integration tests
- Monitor for 24 hours before production

### 5. Resource Naming Conventions
- Use consistent naming patterns
- Include environment in resource names
- Apply proper tags for organization

## Troubleshooting

### Common Issues

1. **Resource Already Exists Error**
   - Solution: Use smart deployment script
   - The script will detect and use existing resources

2. **Terraform State Conflicts**
   - Solution: Check state file location
   - Ensure proper workspace isolation

3. **Container Registry Access Issues**
   - Solution: Verify registry permissions
   - Check token validity and scope

4. **Cluster Connection Problems**
   - Solution: Verify cluster exists and is accessible
   - Check kubectl configuration

### Debug Commands

```bash
# Check detected resources
doctl vpcs list
doctl kubernetes cluster list
doctl registry list
doctl load-balancer list

# Validate Terraform
terraform validate
terraform plan -detailed-exitcode

# Check Kubernetes connectivity
kubectl cluster-info
kubectl get nodes
```

## Security Considerations

### Secrets Management
- Use GitHub Secrets for sensitive data
- Rotate tokens regularly
- Limit token scope and permissions

### Network Security
- VPC isolation between environments
- Network policies for pod communication
- Secure ingress configuration

### Container Security
- Image scanning in registry
- Security contexts for containers
- Regular base image updates

## Future Enhancements

1. **Multi-Cloud Support**: Extend to AWS, Azure, GCP
2. **Auto-Scaling**: Implement intelligent scaling policies
3. **Disaster Recovery**: Automated backup and recovery
4. **Cost Optimization**: Resource usage monitoring and optimization
5. **Security Scanning**: Automated vulnerability assessments

## Conclusion

This idempotent infrastructure setup provides:
- ✅ **Safe and repeatable deployments**
- ✅ **Resource conflict prevention**
- ✅ **Smart resource management**
- ✅ **Environment consistency**
- ✅ **Operational reliability**

The infrastructure is now production-ready and can handle complex deployment scenarios while maintaining consistency and reliability across environments.
