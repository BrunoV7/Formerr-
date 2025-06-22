#!/bin/bash

# Resource Detection and Smart Deployment Script
# Automatically detects existing DigitalOcean resources and configures Terraform accordingly

set -e

echo "🔍 DigitalOcean Resource Detection & Smart Deployment"
echo "===================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "📋 Checking dependencies..."
if ! command_exists doctl; then
    echo -e "${RED}❌ doctl not found. Please install DigitalOcean CLI first.${NC}"
    echo "   curl -sL https://github.com/digitalocean/doctl/releases/download/v1.100.0/doctl-1.100.0-linux-amd64.tar.gz | tar -xzv"
    exit 1
fi

if ! command_exists terraform; then
    echo -e "${RED}❌ terraform not found. Please install Terraform first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies OK${NC}"

# Get environment choice
echo ""
read -p "🌍 Which environment to deploy? (production/staging): " environment
environment=${environment:-staging}

if [[ "$environment" != "production" && "$environment" != "staging" ]]; then
    echo -e "${RED}❌ Invalid environment. Choose 'production' or 'staging'${NC}"
    exit 1
fi

# Set environment-specific variables
if [[ "$environment" == "production" ]]; then
    INFRA_DIR="infrastructure/digitalocean-production"
    VPC_NAME="formerr-production-vpc"
    CLUSTER_NAME="formerr-production-cluster"
    LB_NAME="formerr-production-lb"
    TOKEN_VAR="DO_TOKEN_PROD"
    echo -e "${BLUE}🏭 Production environment selected${NC}"
else
    INFRA_DIR="infrastructure/digitalocean-staging"
    VPC_NAME="formerr-staging-vpc"
    CLUSTER_NAME="formerr-staging-cluster"
    LB_NAME="formerr-staging-lb"
    TOKEN_VAR="DO_STAGING_TOKEN"
    echo -e "${BLUE}🧪 Staging environment selected${NC}"
fi

# Check for DigitalOcean token
if [[ -z "${!TOKEN_VAR}" ]]; then
    echo ""
    read -p "🔑 Enter your DigitalOcean API token: " -s DO_TOKEN
    echo ""
    export ${TOKEN_VAR}="$DO_TOKEN"
    export DIGITALOCEAN_TOKEN="$DO_TOKEN"
else
    export DIGITALOCEAN_TOKEN="${!TOKEN_VAR}"
fi

echo ""
echo "🔍 Detecting existing resources..."

# Check for existing VPC
echo -n "   📡 Checking VPC '$VPC_NAME'... "
if doctl vpcs list --format Name --no-header | grep -q "^${VPC_NAME}$"; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_VPC=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_VPC=false
fi

# Check for existing Kubernetes cluster
echo -n "   ⚙️  Checking Kubernetes cluster '$CLUSTER_NAME'... "
if doctl kubernetes cluster list --format Name --no-header | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_CLUSTER=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_CLUSTER=false
fi

# Check for existing load balancer
echo -n "   ⚖️  Checking load balancer '$LB_NAME'... "
if doctl compute load-balancer list --format Name --no-header | grep -q "^${LB_NAME}$"; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_LB=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_LB=false
fi

# Check for existing container registry
echo -n "   📦 Checking container registry... "
if doctl registry get >/dev/null 2>&1; then
    REGISTRY_NAME=$(doctl registry get --format Name --no-header)
    echo -e "${YELLOW}EXISTS ($REGISTRY_NAME)${NC}"
    USE_EXISTING_REGISTRY=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_REGISTRY=false
    REGISTRY_NAME="formerr-registry"
fi

echo ""
echo "📊 Resource Detection Summary:"
echo "=============================="
echo -e "VPC:                ${USE_EXISTING_VPC:+${YELLOW}Use existing${NC}}${USE_EXISTING_VPC:+}${USE_EXISTING_VPC:-${GREEN}Create new${NC}}"
echo -e "Kubernetes Cluster: ${USE_EXISTING_CLUSTER:+${YELLOW}Use existing${NC}}${USE_EXISTING_CLUSTER:+}${USE_EXISTING_CLUSTER:-${GREEN}Create new${NC}}"
echo -e "Load Balancer:      ${USE_EXISTING_LB:+${YELLOW}Use existing${NC}}${USE_EXISTING_LB:+}${USE_EXISTING_LB:-${GREEN}Create new${NC}}"
echo -e "Container Registry: ${USE_EXISTING_REGISTRY:+${YELLOW}Use existing ($REGISTRY_NAME)${NC}}${USE_EXISTING_REGISTRY:+}${USE_EXISTING_REGISTRY:-${GREEN}Create new${NC}}"

echo ""
read -p "🤔 Continue with this configuration? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi

# Navigate to infrastructure directory
cd "$INFRA_DIR"

echo ""
echo "🚀 Starting smart Terraform deployment..."

# Initialize Terraform
echo "📥 Initializing Terraform..."
terraform init

# Create auto-generated terraform.tfvars file
echo "📝 Creating terraform.tfvars with detected resources..."
cat > terraform.tfvars <<EOF
# DigitalOcean Configuration
do_token = "${!TOKEN_VAR}"
region = "nyc1"

# Kubernetes Configuration
k8s_version = "1.31.1-do.3"
node_count = $([[ "$environment" == "production" ]] && echo "3" || echo "2")

# Resource Names
vpc_name = "$VPC_NAME"
cluster_name = "$CLUSTER_NAME"
loadbalancer_name = "$LB_NAME"
registry_name = "$REGISTRY_NAME"

# Resource Existence Flags (auto-detected)
use_existing_vpc = $USE_EXISTING_VPC
use_existing_cluster = $USE_EXISTING_CLUSTER
use_existing_loadbalancer = $USE_EXISTING_LB
create_registry = $([[ "$USE_EXISTING_REGISTRY" == "true" ]] && echo "false" || echo "true")

# Application Secrets (placeholders - update with real values)
github_client_id = "placeholder_github_client_id"
github_client_secret = "placeholder_github_client_secret"
jwt_secret = "$(openssl rand -hex 32)"
session_secret = "$(openssl rand -hex 32)"
EOF

# Add database variables for production
if [[ "$environment" == "production" ]]; then
    cat >> terraform.tfvars <<EOF

# Database Configuration (Production - using managed DB)
database_url = "postgresql://user:pass@host:5432/dbname"
db_host = "your-db-host.db.ondigitalocean.com"
db_port = "5432"
db_name = "formerr_db"
db_user = "your_db_user"
db_password = "your_db_password"
EOF
fi

echo ""
echo "⚠️  terraform.tfvars created with auto-detected settings and placeholder secrets"
echo "   Update with real values before production deployment!"

# Plan deployment
echo ""
echo "📋 Planning deployment..."
terraform plan

# Ask for confirmation
echo ""
read -p "🚀 Apply these changes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "✨ Applying Terraform configuration..."
    terraform apply -auto-approve
    
    echo ""
    echo -e "${GREEN}✅ Smart deployment completed successfully!${NC}"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update GitHub repository secrets with real values"
    echo "2. Push code to trigger CI/CD pipeline"
    echo "3. Monitor deployment in GitHub Actions"
    echo ""
    echo "🔗 Useful commands:"
    echo "   doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
    echo "   kubectl get pods -n formerr"
    echo "   kubectl get services -n formerr"
    
    if [[ "$USE_EXISTING_CLUSTER" == "false" ]]; then
        echo ""
        echo "🎉 New cluster created! Configure kubectl:"
        echo "   doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
    fi
    
else
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Smart deployment script completed!${NC}"
