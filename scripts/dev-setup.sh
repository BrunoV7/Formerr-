#!/bin/bash

# Formerr - Local Development Setup Script
# This script helps configure your local environment for development

set -e

echo "🚀 Formerr - Local Development Setup"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."
    
    local missing_tools=()
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v doctl &> /dev/null; then
        missing_tools+=("doctl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Please install the missing tools:"
        echo "- Docker: https://docs.docker.com/get-docker/"
        echo "- kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "- Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli"
        echo "- doctl: https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
    fi
    
    print_success "All required tools are installed"
}

# Setup local environment files
setup_env_files() {
    print_status "Setting up environment files..."
    
    # Copy example files if they don't exist
    if [ ! -f infrastructure/digitalocean-production/terraform.tfvars ]; then
        cp infrastructure/digitalocean-production/terraform.tfvars.example infrastructure/digitalocean-production/terraform.tfvars
        print_warning "Created terraform.tfvars for production. Please edit it with your values."
    fi
    
    if [ ! -f infrastructure/digitalocean-staging/terraform.tfvars ]; then
        cp infrastructure/digitalocean-staging/terraform.tfvars.example infrastructure/digitalocean-staging/terraform.tfvars
        print_warning "Created terraform.tfvars for staging. Please edit it with your values."
    fi
    
    if [ ! -f .env.local ]; then
        cat > .env.local << EOF
# Local Development Environment Variables
DATABASE_URL=postgresql://formerr_user:formerr_password@localhost:5432/formerr_db
GITHUB_CLIENT_ID=your_GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=your_github_client_secret
JWT_SECRET=your_jwt_secret_key_here_minimum_32_characters
SESSION_SECRET=your_session_secret_key_here_minimum_32_characters
FRONTEND_SUCCESS_URL=http://localhost:3000/auth/success
FRONTEND_ERROR_URL=http://localhost:3000/auth/error
OAUTH_CALLBACK_URL=http://localhost:8000/auth/github/callback
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF
        print_warning "Created .env.local. Please edit it with your values."
    fi
    
    print_success "Environment files setup complete"
}

# Start local development environment
start_local() {
    print_status "Starting local development environment..."
    
    if [ ! -f docker-compose.yml ]; then
        print_error "docker-compose.yml not found!"
        exit 1
    fi
    
    # Load environment variables
    if [ -f .env.local ]; then
        export $(cat .env.local | grep -v '^#' | xargs)
    fi
    
    # Start services
    docker-compose up -d
    
    print_success "Local environment started!"
    echo ""
    echo "Services available at:"
    echo "- Frontend: http://localhost:3000"
    echo "- Backend API: http://localhost:8000"
    echo "- PostgreSQL: localhost:5432"
    echo ""
    echo "To view logs: docker-compose logs -f"
    echo "To stop: docker-compose down"
}

# Stop local development environment
stop_local() {
    print_status "Stopping local development environment..."
    docker-compose down
    print_success "Local environment stopped!"
}

# Connect to remote clusters
connect_cluster() {
    local env=$1
    
    if [ -z "$env" ]; then
        echo "Usage: $0 connect [staging|production]"
        exit 1
    fi
    
    print_status "Connecting to $env cluster..."
    
    case $env in
        staging)
            doctl kubernetes cluster kubeconfig save formerr-staging-cluster
            ;;
        production)
            doctl kubernetes cluster kubeconfig save formerr-production-cluster
            ;;
        *)
            print_error "Invalid environment. Use 'staging' or 'production'"
            exit 1
            ;;
    esac
    
    print_success "Connected to $env cluster!"
    echo ""
    echo "You can now use kubectl to interact with the cluster:"
    echo "kubectl get pods -n formerr"
    echo "kubectl get services -n formerr"
}

# Deploy infrastructure
deploy_infra() {
    local env=$1
    
    if [ -z "$env" ]; then
        echo "Usage: $0 deploy [staging|production]"
        exit 1
    fi
    
    print_status "Deploying infrastructure to $env..."
    
    cd infrastructure/digitalocean-$env
    
    if [ ! -f terraform.tfvars ]; then
        print_error "terraform.tfvars not found! Please copy from terraform.tfvars.example and configure it."
        exit 1
    fi
    
    terraform init
    terraform plan
    
    echo ""
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply
        print_success "Infrastructure deployed to $env!"
    else
        print_warning "Deployment cancelled"
    fi
    
    cd - > /dev/null
}

# Show help
show_help() {
    echo "Formerr Development Helper Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  check          Check if all required tools are installed"
    echo "  setup          Setup local environment files"
    echo "  start          Start local development environment with Docker Compose"
    echo "  stop           Stop local development environment"
    echo "  connect <env>  Connect kubectl to remote cluster (staging|production)"
    echo "  deploy <env>   Deploy infrastructure using Terraform (staging|production)"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup                    # Setup environment files"
    echo "  $0 start                    # Start local development"
    echo "  $0 connect staging          # Connect to staging cluster"
    echo "  $0 deploy production        # Deploy to production"
}

# Main script logic
case "$1" in
    check)
        check_requirements
        ;;
    setup)
        check_requirements
        setup_env_files
        ;;
    start)
        check_requirements
        setup_env_files
        start_local
        ;;
    stop)
        stop_local
        ;;
    connect)
        connect_cluster "$2"
        ;;
    deploy)
        deploy_infra "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
