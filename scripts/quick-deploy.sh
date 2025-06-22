#!/bin/bash

# Quick Fix Deployment Script for Formerr
# This script addresses the common Terraform deployment issues

set -e

echo "🔧 Formerr Deployment Quick Fix"
echo "================================"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "📋 Checking dependencies..."
if ! command_exists terraform; then
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

if ! command_exists doctl; then
    echo "❌ doctl not found. Please install DigitalOcean CLI first."
    exit 1
fi

echo "✅ Dependencies OK"

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    echo "❌ Please run this script from the Formerr project root directory"
    exit 1
fi

# Get environment choice
echo ""
read -p "🌍 Which environment? (production/staging): " environment
environment=${environment:-staging}

if [[ "$environment" != "production" && "$environment" != "staging" ]]; then
    echo "❌ Invalid environment. Choose 'production' or 'staging'"
    exit 1
fi

# Check for existing registry
echo ""
echo "🔍 Checking for existing DigitalOcean container registry..."
if doctl registry get 2>/dev/null; then
    echo "✅ Found existing registry, will use it"
    USE_EXISTING_REGISTRY=true
    REGISTRY_NAME=$(doctl registry get --format Name --no-header)
else
    echo "📦 No existing registry found, will create one"
    USE_EXISTING_REGISTRY=false
    REGISTRY_NAME="formerr-registry"
fi

# Set up variables based on environment
if [[ "$environment" == "production" ]]; then
    INFRA_DIR="infrastructure/digitalocean-production"
    TOKEN_VAR="DO_TOKEN_PROD"
    echo "🏭 Production deployment selected"
else
    INFRA_DIR="infrastructure/digitalocean-staging"
    TOKEN_VAR="DO_STAGING_TOKEN"
    echo "🧪 Staging deployment selected"
fi

# Check for DigitalOcean token
if [[ -z "${!TOKEN_VAR}" ]]; then
    echo ""
    read -p "🔑 Enter your DigitalOcean API token: " -s DO_TOKEN
    echo ""
    export ${TOKEN_VAR}="$DO_TOKEN"
fi

# Navigate to infrastructure directory
cd "$INFRA_DIR"

echo ""
echo "🚀 Starting Terraform deployment..."

# Initialize Terraform
echo "📥 Initializing Terraform..."
terraform init

# Create terraform.tfvars file with current settings
echo "📝 Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
# DigitalOcean Configuration
do_token = "${!TOKEN_VAR}"
region = "nyc1"

# Kubernetes Configuration
k8s_version = "1.31.1-do.3"
node_count = 2

# Registry Configuration
registry_name = "$REGISTRY_NAME"
create_registry = $([[ "$USE_EXISTING_REGISTRY" == "true" ]] && echo "false" || echo "true")

# Application Secrets (use placeholder values for now)
GITHUB_CLIENT_ID = "placeholder_GITHUB_CLIENT_ID"
github_client_secret = "placeholder_github_client_secret"
jwt_secret = "placeholder_jwt_secret_$(openssl rand -hex 16)"
session_secret = "placeholder_session_secret_$(openssl rand -hex 16)"
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

echo "⚠️  Note: terraform.tfvars contains placeholder values."
echo "   Update with real values before production deployment!"

# Plan deployment
echo ""
echo "📋 Planning deployment..."
terraform plan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Applying Terraform configuration..."
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Infrastructure deployment completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update GitHub repository secrets with real values"
    echo "2. Push code to trigger CI/CD pipeline"
    echo "3. Monitor deployment in GitHub Actions"
    echo ""
    echo "🔗 Useful commands:"
    echo "   doctl kubernetes cluster kubeconfig save formerr-${environment}-cluster"
    echo "   kubectl get pods -n formerr"
    echo "   kubectl get services -n formerr"
    
    if [[ "$environment" == "production" ]]; then
        echo ""
        echo "🏭 Production-specific notes:"
        echo "   - Update database connection details in terraform.tfvars"
        echo "   - Configure DNS to point to load balancer IP"
        echo "   - Set up monitoring alerts"
    fi
    
else
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🎉 Deployment script completed!"
