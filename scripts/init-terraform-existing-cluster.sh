#!/bin/bash
# Initialize Terraform for existing DigitalOcean cluster
# This script configures Terraform to manage an existing cluster

set -e

echo "🔧 Initializing Terraform for existing DigitalOcean cluster"
echo "========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
INFRA_DIR="$PROJECT_ROOT/infrastructure/digitalocean-production"

cd "$INFRA_DIR"

# Check if we're in the right directory
if [[ ! -f "main.tf" ]]; then
    print_error "main.tf not found. Are you in the right directory?"
    exit 1
fi

print_success "Found Terraform configuration"

# Check if terraform.tfvars exists
if [[ ! -f "terraform.tfvars" ]]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    if [[ -f "terraform.tfvars.example" ]]; then
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your values before continuing"
    else
        print_error "terraform.tfvars.example not found"
        exit 1
    fi
fi

# Check for required environment variables
print_status "Checking environment variables..."

if [[ -z "$DO_TOKEN" ]]; then
    print_error "DO_TOKEN environment variable is required"
    echo "Set it with: export DO_TOKEN=your-digitalocean-token"
    exit 1
fi

if [[ -z "$GITHUB_CLIENT_ID" ]]; then
    print_warning "GITHUB_CLIENT_ID not set"
fi

if [[ -z "$GITHUB_CLIENT_SECRET" ]]; then
    print_warning "GITHUB_CLIENT_SECRET not set"
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Create a workspace for production (optional)
print_status "Selecting/creating production workspace..."
terraform workspace select production 2>/dev/null || terraform workspace new production

# Validate configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan with existing cluster
print_status "Planning Terraform (using existing cluster)..."
terraform plan \
    -var="do_token=$DO_TOKEN" \
    -var="use_existing_cluster=true" \
    -var="cluster_name=formerr-production-cluster" \
    -var="create_registry=false" \
    -var="registry_name=formerr-registry" \
    -var="use_existing_vpc=true" \
    -var="vpc_name=default-nyc1" \
    -var="GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID:-placeholder}" \
    -var="github_client_secret=${GITHUB_CLIENT_SECRET:-placeholder}" \
    -var="jwt_secret=${JWT_SECRET:-placeholder-jwt-secret}" \
    -var="session_secret=${SESSION_SECRET:-placeholder-session-secret}" \
    -out=tfplan

print_success "Terraform plan created successfully!"

echo ""
print_status "📋 Summary:"
echo "✅ Terraform initialized"
echo "✅ Configuration validated"
echo "✅ Plan created for existing cluster: formerr-production-cluster"
echo ""

print_status "🚀 Next steps:"
echo "1. Review the plan: terraform show tfplan"
echo "2. Apply if everything looks good: terraform apply tfplan"
echo ""

print_warning "⚠️  Important: This will import your existing cluster into Terraform state"
print_warning "Make sure all variables in terraform.tfvars are correct before applying!"

echo ""
print_status "🔧 Quick commands:"
echo "• Review plan: terraform show tfplan"
echo "• Apply plan: terraform apply tfplan"
echo "• Show outputs: terraform output"
echo "• Import state: terraform apply (will detect existing resources)"
echo ""

print_success "🎉 Terraform is ready to manage your existing cluster!"
