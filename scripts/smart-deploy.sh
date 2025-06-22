#!/bin/bash

# Resource Detection and Smart Deployment Script
# Automatically detects existing DigitalOcean resources and configures Terraform accordingly
#
# Usage: ./smart-deploy.sh [environment] [registry_name]
#   environment: production|staging (default: interactive prompt)
#   registry_name: name for container registry (default: auto-detect or formerr-registry)
#
# Environment Variables:
#   DO_TOKEN_PROD: DigitalOcean token for production
#   DO_STAGING_TOKEN: DigitalOcean token for staging  
#   DO_TOKEN: Fallback DigitalOcean token
#   SKIP_CONFIRM: Skip confirmation prompt (for CI/CD)

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

# Get environment choice from command line or prompt
if [ "$1" ]; then
    environment="$1"
    echo -e "${BLUE}🌍 Environment: $environment (from argument)${NC}"
else
    echo ""
    read -p "🌍 Which environment to deploy? (production/staging): " environment
    environment=${environment:-staging}
fi

if [[ "$environment" != "production" && "$environment" != "staging" ]]; then
    echo -e "${RED}❌ Invalid environment. Choose 'production' or 'staging'${NC}"
    exit 1
fi

# Get registry name from command line or use default
if [ "$2" ]; then
    REGISTRY_NAME_ARG="$2"
    echo -e "${BLUE}📦 Registry: $REGISTRY_NAME_ARG (from argument)${NC}"
else
    REGISTRY_NAME_ARG=""
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
    if [[ -z "$DO_TOKEN" ]]; then
        echo -e "${RED}❌ DigitalOcean token not found in environment variable ${TOKEN_VAR} or DO_TOKEN${NC}"
        echo "   Please set one of these environment variables before running the script."
        exit 1
    else
        export ${TOKEN_VAR}="$DO_TOKEN"
        export DIGITALOCEAN_TOKEN="$DO_TOKEN"
    fi
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
    EXISTING_REGISTRY_NAME=$(doctl registry get --format Name --no-header)
    echo -e "${YELLOW}EXISTS ($EXISTING_REGISTRY_NAME)${NC}"
    USE_EXISTING_REGISTRY=true
    # Use the existing registry name unless overridden by command line
    if [[ -z "$REGISTRY_NAME_ARG" ]]; then
        REGISTRY_NAME="$EXISTING_REGISTRY_NAME"
    else
        REGISTRY_NAME="$REGISTRY_NAME_ARG"
    fi
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_REGISTRY=false
    # Use provided registry name or default
    REGISTRY_NAME=${REGISTRY_NAME_ARG:-$REGISTRY_NAME}
fi

# Check for existing Kubernetes namespace (if cluster is accessible)
echo -n "   📁 Checking namespace 'formerr'... "
if doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" >/dev/null 2>&1 && kubectl get namespace formerr >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_NAMESPACE=true
    
    # Check for existing secrets in the namespace
    echo -n "   🔐 Checking database secret... "
    if kubectl get secret formerr-db-secret -n formerr >/dev/null 2>&1; then
        echo -e "${YELLOW}EXISTS${NC}"
        USE_EXISTING_DB_SECRET=true
    else
        echo -e "${GREEN}NOT FOUND (will create)${NC}"
        USE_EXISTING_DB_SECRET=false
    fi
    
    echo -n "   🐳 Checking registry secret... "
    if kubectl get secret formerr-registry-secret -n formerr >/dev/null 2>&1; then
        echo -e "${YELLOW}EXISTS${NC}"
        USE_EXISTING_REGISTRY_SECRET=true
    else
        echo -e "${GREEN}NOT FOUND (will create)${NC}"
        USE_EXISTING_REGISTRY_SECRET=false
    fi
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_NAMESPACE=false
    USE_EXISTING_DB_SECRET=false
    USE_EXISTING_REGISTRY_SECRET=false
fi

echo ""
echo "📊 Resource Detection Summary:"
echo "=============================="
if [ "$USE_EXISTING_VPC" = true ]; then
    echo -e "VPC:                ${YELLOW}Use existing${NC}"
else
    echo -e "VPC:                ${GREEN}Create new${NC}"
fi

if [ "$USE_EXISTING_CLUSTER" = true ]; then
    echo -e "Kubernetes Cluster: ${YELLOW}Use existing${NC}"
else
    echo -e "Kubernetes Cluster: ${GREEN}Create new${NC}"
fi

if [ "$USE_EXISTING_LB" = true ]; then
    echo -e "Load Balancer:      ${YELLOW}Use existing${NC}"
else
    echo -e "Load Balancer:      ${GREEN}Create new${NC}"
fi

if [ "$USE_EXISTING_REGISTRY" = true ]; then
    echo -e "Container Registry: ${YELLOW}Use existing ($REGISTRY_NAME)${NC}"
else
    echo -e "Container Registry: ${GREEN}Create new ($REGISTRY_NAME)${NC}"
fi

if [ "$USE_EXISTING_NAMESPACE" = true ]; then
    echo -e "Kubernetes Namespace: ${YELLOW}Use existing (formerr)${NC}"
else
    echo -e "Kubernetes Namespace: ${GREEN}Create new (formerr)${NC}"
fi

echo ""
# Skip confirmation if running non-interactively or if SKIP_CONFIRM is set
if [[ -t 0 && -z "$SKIP_CONFIRM" ]]; then
    read -p "🤔 Continue with this configuration? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Deployment cancelled${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Auto-continuing with configuration (non-interactive mode)${NC}"
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

# Check required environment variables
echo "🔍 Validating environment variables..."

# Required for all environments
if [[ -z "$GITHUB_CLIENT_ID" ]]; then
    echo -e "${RED}❌ GITHUB_CLIENT_ID environment variable is required${NC}"
    exit 1
fi

if [[ -z "$GITHUB_CLIENT_SECRET" ]]; then
    echo -e "${RED}❌ GITHUB_CLIENT_SECRET environment variable is required${NC}"
    exit 1
fi

if [[ -z "$JWT_SECRET" ]]; then
    echo -e "${RED}❌ JWT_SECRET environment variable is required${NC}"
    exit 1
fi

if [[ -z "$SESSION_SECRET" ]]; then
    echo -e "${RED}❌ SESSION_SECRET environment variable is required${NC}"
    exit 1
fi

# Additional checks for production
if [[ "$environment" == "production" ]]; then
    if [[ -z "$DATABASE_URL" ]]; then
        echo -e "${RED}❌ DATABASE_URL environment variable is required for production${NC}"
        exit 1
    fi
    
    if [[ -z "$DB_HOST" ]]; then
        echo -e "${RED}❌ DB_HOST environment variable is required for production${NC}"
        exit 1
    fi
    
    if [[ -z "$DB_USER" ]]; then
        echo -e "${RED}❌ DB_USER environment variable is required for production${NC}"
        exit 1
    fi
    
    if [[ -z "$DB_PASSWORD" ]]; then
        echo -e "${RED}❌ DB_PASSWORD environment variable is required for production${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Environment variables validated${NC}"

cat > terraform.tfvars <<EOF
# DigitalOcean Configuration
do_token = "${!TOKEN_VAR}"
region = "nyc1"

# Kubernetes Configuration
k8s_version = "1.33.1-do.0"
node_count = $([[ "$environment" == "production" ]] && echo "3" || echo "2")

# Resource Names
vpc_name = "$VPC_NAME"
cluster_name = "$CLUSTER_NAME"
loadbalancer_name = "$LB_NAME"
registry_name = "$REGISTRY_NAME"
namespace_name = "formerr"

# Resource Existence Flags (auto-detected)
use_existing_vpc = $USE_EXISTING_VPC
use_existing_cluster = $USE_EXISTING_CLUSTER
use_existing_loadbalancer = $USE_EXISTING_LB
use_existing_namespace = $USE_EXISTING_NAMESPACE
use_existing_db_secret = $USE_EXISTING_DB_SECRET
use_existing_registry_secret = $USE_EXISTING_REGISTRY_SECRET
create_registry = $([[ "$USE_EXISTING_REGISTRY" == "true" ]] && echo "false" || echo "true")

# Application Secrets (from environment variables)
GITHUB_CLIENT_ID = "$GITHUB_CLIENT_ID"
github_client_secret = "$GITHUB_CLIENT_SECRET"
jwt_secret = "$JWT_SECRET"
session_secret = "$SESSION_SECRET"
EOF

# Add database variables for production
if [[ "$environment" == "production" ]]; then
    cat >> terraform.tfvars <<EOF

# Database Configuration (Production - from environment variables)
database_url = "$DATABASE_URL"
db_host = "$DB_HOST"
db_port = "${DB_PORT:-5432}"
db_name = "${DB_NAME:-formerr_db}"
db_user = "$DB_USER"
db_password = "$DB_PASSWORD"
EOF
fi

echo ""
echo "⚠️  terraform.tfvars created with auto-detected settings and placeholder secrets"
echo "   Update with real values before production deployment!"

# Plan deployment
echo ""
echo "📋 Planning deployment..."
if ! terraform plan -detailed-exitcode; then
    PLAN_EXIT_CODE=$?
    if [ $PLAN_EXIT_CODE -eq 1 ]; then
        echo -e "${RED}❌ Terraform plan failed${NC}"
        exit 1
    elif [ $PLAN_EXIT_CODE -eq 2 ]; then
        echo -e "${YELLOW}⚠️  Changes detected in plan${NC}"
    fi
fi

# Apply changes (skip confirmation in non-interactive mode)
echo ""
if [[ -t 0 && -z "$SKIP_CONFIRM" ]]; then
    read -p "🚀 Apply these changes? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Deployment cancelled${NC}"
        exit 1
    fi
    
    echo "✨ Applying Terraform configuration..."
    terraform apply -auto-approve
else
    echo -e "${GREEN}✨ Auto-applying Terraform configuration (non-interactive mode)${NC}"
    terraform apply -auto-approve
fi

# Configure kubectl and deploy monitoring
echo ""
echo "🔧 Configuring kubectl for cluster access..."
if doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" 2>/dev/null; then
    echo -e "${GREEN}✅ kubectl configured successfully${NC}"
    
    # Deploy Prometheus monitoring
    echo ""
    echo "📊 Deploying Prometheus monitoring..."
    cd "$SCRIPT_DIR/.."
    
    if [[ -f "k8s/monitoring/prometheus-simple.yaml" ]]; then
        # Remove any existing Helm releases first (idempotent)
        if command -v helm &> /dev/null; then
            echo "🧹 Cleaning up any existing Helm Prometheus releases..."
            helm uninstall prometheus -n monitoring 2>/dev/null || true
            helm uninstall kube-prometheus-stack -n monitoring 2>/dev/null || true
        fi
        
        echo "📋 Applying Prometheus manifests..."
        if kubectl apply -f k8s/monitoring/prometheus-simple.yaml; then
            echo -e "${GREEN}✅ Prometheus monitoring deployed successfully${NC}"
            
            # Wait for Prometheus to be ready
            echo "⏳ Waiting for Prometheus to be ready..."
            kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s 2>/dev/null || true
            
            # Show monitoring status
            echo ""
            echo "📊 Monitoring Status:"
            kubectl get pods -n monitoring 2>/dev/null || echo "   (monitoring namespace not ready yet)"
            kubectl get services -n monitoring 2>/dev/null || echo "   (services not ready yet)"
        else
            echo -e "${YELLOW}⚠️  Failed to deploy Prometheus monitoring (non-critical)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Prometheus manifests not found at k8s/monitoring/prometheus-simple.yaml${NC}"
    fi
    
    cd "$INFRA_DIR"
else
    echo -e "${YELLOW}⚠️  Could not configure kubectl automatically${NC}"
    echo "   Run manually: doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
fi
    
echo ""
echo -e "${GREEN}✅ Smart deployment completed successfully!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Update GitHub repository secrets with real values"
echo "2. Push code to trigger CI/CD pipeline"
echo "3. Monitor deployment in GitHub Actions"
echo ""
echo "🔗 Useful commands:"
echo "   # Kubernetes access:"
echo "   doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
echo "   kubectl get pods -n formerr"
echo "   kubectl get services -n formerr"
echo ""
echo "   # Monitoring access:"
echo "   kubectl get pods -n monitoring"
echo "   kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "   # Then access Prometheus at http://localhost:9090"

if [[ "$USE_EXISTING_CLUSTER" == "false" ]]; then
    echo ""
    echo "🎉 New cluster created! Configure kubectl:"
    echo "   doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
fi

echo ""
echo -e "${GREEN}🎉 Smart deployment script completed!${NC}"
