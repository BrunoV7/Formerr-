#!/bin/bash
# =============================================================================
# Development Scripts for Formerr Project
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    echo "Formerr Development Scripts"
    echo ""
    echo "Usage: ./scripts/dev.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Initial project setup"
    echo "  dev       - Start development environment"
    echo "  build     - Build all containers"
    echo "  test      - Run tests"
    echo "  clean     - Clean up containers and volumes"
    echo "  logs      - Show application logs"
    echo "  help      - Show this help message"
    echo ""
}

# Setup function
setup_project() {
    log_info "Setting up Formerr development environment..."
    
    # Check if .env exists
    if [ ! -f .env ]; then
        log_warning ".env file not found. Copying from .env.example..."
        cp .env.example .env
        log_warning "Please edit .env file with your actual values before continuing."
        return 1
    fi
    
    # Build containers
    log_info "Building Docker containers..."
    docker-compose build
    
    log_success "Setup completed! Run './scripts/dev.sh dev' to start development."
}

# Development function
start_dev() {
    log_info "Starting development environment..."
    
    # Check if .env exists
    if [ ! -f .env ]; then
        log_error ".env file not found. Run './scripts/dev.sh setup' first."
        return 1
    fi
    
    # Start containers
    docker-compose up -d
    
    log_success "Development environment started!"
    log_info "Services:"
    log_info "  - Frontend: http://localhost:3000"
    log_info "  - Backend API: http://localhost:8000"
    log_info "  - API Docs: http://localhost:8000/docs"
    log_info "  - PostgreSQL: localhost:5432"
    
    # Show logs
    docker-compose logs -f
}

# Build function
build_containers() {
    log_info "Building all containers..."
    
    # Build with no cache
    docker-compose build --no-cache
    
    log_success "All containers built successfully!"
}

# Test function
run_tests() {
    log_info "Running tests..."
    
    # Backend tests
    log_info "Running backend tests..."
    docker-compose exec backend python -m pytest tests/ -v
    
    # Frontend tests
    log_info "Running frontend tests..."
    docker-compose exec frontend npm test
    
    log_success "All tests completed!"
}

# Clean function
clean_environment() {
    log_warning "This will remove all containers, images, and volumes. Continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Cleaning up environment..."
        
        # Stop and remove containers
        docker-compose down -v --remove-orphans
        
        # Remove images
        docker images | grep formerr | awk '{print $3}' | xargs -r docker rmi -f
        
        # Remove volumes
        docker volume prune -f
        
        log_success "Environment cleaned up!"
    else
        log_info "Cleanup cancelled."
    fi
}

# Logs function
show_logs() {
    log_info "Showing application logs..."
    docker-compose logs -f --tail=100
}

# Main script logic
case "${1:-help}" in
    setup)
        setup_project
        ;;
    dev)
        start_dev
        ;;
    build)
        build_containers
        ;;
    test)
        run_tests
        ;;
    clean)
        clean_environment
        ;;
    logs)
        show_logs
        ;;
    help|*)
        show_help
        ;;
esac
