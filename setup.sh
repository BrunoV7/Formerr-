#!/bin/bash

# =============================================================================
# Formerr Multi-Cloud Setup Script
# =============================================================================

set -e

echo "🚀 Formerr Multi-Cloud Infrastructure Setup"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    print_step "Checking requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_warning "Terraform is not installed. You'll need it for infrastructure deployment."
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl is not installed. You'll need it to manage Kubernetes clusters."
    fi
    
    print_status "Requirements check completed!"
}

# Setup local environment
setup_local() {
    print_step "Setting up local environment..."
    
    # Copy .env.example to .env if it doesn't exist
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_status "Created .env file from .env.example"
            print_warning "Please edit .env file with your actual values"
        else
            print_error ".env.example not found"
        fi
    else
        print_status ".env file already exists"
    fi
    
    # Create necessary directories
    mkdir -p logs
    mkdir -p data/postgres
    
    print_status "Local environment setup completed!"
}

# Test local Docker setup
test_docker() {
    print_step "Testing Docker setup..."
    
    # Build images
    print_status "Building backend image..."
    docker build -t formerr-backend ./Formerr-FastAPI
    
    print_status "Building frontend image..."
    docker build -t formerr-frontend ./formerr-frontend
    
    print_status "Docker images built successfully!"
}

# Deploy infrastructure to production
deploy_infrastructure() {
    local env=$1
    
    print_step "Deploying infrastructure to $env..."
    
    if [ -z "$DO_TOKEN" ]; then
        print_error "DO_TOKEN environment variable is not set"
        exit 1
    fi
    
    cd infrastructure/terraform/$env
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -var="do_token=$DO_TOKEN"
    
    # Ask for confirmation
    read -p "Do you want to apply this plan? (y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        terraform apply -auto-approve -var="do_token=$DO_TOKEN"
        print_status "Infrastructure deployed successfully to $env!"
    else
        print_warning "Deployment cancelled"
    fi
    
    cd ../../..
}

# Main menu
main_menu() {
    echo ""
    print_step "Choose an option:"
    echo "1. Check requirements"
    echo "2. Setup local environment"
    echo "3. Test Docker build"
    echo "4. Deploy to production (requires DO_TOKEN)"
    echo "5. Deploy to staging (requires DO_TOKEN)"
    echo "6. Run local development"
    echo "7. Run local production"
    echo "8. Exit"
    echo ""
    
    read -p "Enter your choice [1-8]: " choice
    
    case $choice in
        1)
            check_requirements
            main_menu
            ;;
        2)
            setup_local
            main_menu
            ;;
        3)
            test_docker
            main_menu
            ;;
        4)
            deploy_infrastructure "production"
            main_menu
            ;;
        5)
            deploy_infrastructure "staging"
            main_menu
            ;;
        6)
            print_status "Starting local development environment..."
            docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
            ;;
        7)
            print_status "Starting local production environment..."
            docker-compose up --build
            ;;
        8)
            print_status "Goodbye! 👋"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose 1-8."
            main_menu
            ;;
    esac
}

# Welcome message
echo ""
print_status "Welcome to the Formerr Multi-Cloud Setup!"
print_status "This script will help you deploy the infrastructure and application."
echo ""

# Start main menu
main_menu
