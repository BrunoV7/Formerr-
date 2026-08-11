#!/bin/bash

# Enhanced Smart Deploy Script - Addresses all deployment issues
# This script performs idempotent deployment with comprehensive error handling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-production}"
NAMESPACE="formerr"
MONITORING_NAMESPACE="monitoring"
TRAEFIK_NAMESPACE="traefik"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v doctl &> /dev/null; then
        warn "doctl is not installed - some features may not work"
    fi
    
    # Check kubectl connectivity
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Clean up orphaned resources
cleanup_orphaned_resources() {
    log "Cleaning up orphaned resources..."
    
    # Clean up orphaned webhooks
    if [[ -f "scripts/clean-orphaned-webhooks.sh" ]]; then
        log "Running webhook cleanup..."
        bash scripts/clean-orphaned-webhooks.sh || warn "Webhook cleanup failed but continuing..."
    fi
    
    # Remove old NGINX ingress resources if they exist
    kubectl delete validatingwebhookconfiguration ingress-nginx-admission --ignore-not-found=true || true
    kubectl delete mutatingwebhookconfiguration ingress-nginx-admission --ignore-not-found=true || true
    kubectl delete ingressclass nginx --ignore-not-found=true || true
    
    # Clean up any stuck finalizers
    kubectl patch namespace cert-manager --type json --patch='[{"op": "remove", "path": "/metadata/finalizers"}]' --ignore-not-found=true || true
    kubectl patch namespace ingress-nginx --type json --patch='[{"op": "remove", "path": "/metadata/finalizers"}]' --ignore-not-found=true || true
    
    success "Cleanup completed"
}

# Install/Update Traefik
install_traefik() {
    log "Installing/Updating Traefik..."
    
    # Apply the enhanced Traefik configuration
    if [[ -f "k8s/ingress/traefik-production-complete.yaml" ]]; then
        log "Applying enhanced Traefik configuration..."
        kubectl apply -f k8s/ingress/traefik-production-complete.yaml
        
        # Wait for Traefik deployment to be ready
        log "Waiting for Traefik deployment to be ready..."
        kubectl wait --namespace=$TRAEFIK_NAMESPACE \
            --for=condition=ready pod \
            --selector=app=traefik \
            --timeout=300s || {
            error "Traefik deployment failed"
            kubectl describe pods -n $TRAEFIK_NAMESPACE -l app=traefik
            exit 1
        }
        
        # Check Traefik LoadBalancer status
        log "Checking Traefik LoadBalancer status..."
        for i in {1..30}; do
            EXTERNAL_IP=$(kubectl get svc traefik -n $TRAEFIK_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
            if [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "null" ]]; then
                success "Traefik LoadBalancer ready with IP: $EXTERNAL_IP"
                break
            fi
            log "Waiting for LoadBalancer IP... (attempt $i/30)"
            sleep 10
        done
        
        if [[ -z "$EXTERNAL_IP" || "$EXTERNAL_IP" == "null" ]]; then
            warn "LoadBalancer IP not ready yet, but continuing deployment"
        fi
        
    else
        error "Traefik configuration file not found: k8s/ingress/traefik-production-complete.yaml"
        exit 1
    fi
    
    success "Traefik installation completed"
}

# Create namespace and base resources
setup_namespace() {
    log "Setting up namespace and base resources..."
    
    # Apply namespace and secrets configuration
    if [[ -f "k8s/production/namespace-and-secrets.yaml" ]]; then
        kubectl apply -f k8s/production/namespace-and-secrets.yaml
    else
        # Fallback: create namespace manually
        kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
        kubectl label namespace $NAMESPACE monitoring=enabled --overwrite
    fi
    
    success "Namespace setup completed"
}

# Deploy monitoring
deploy_monitoring() {
    log "Deploying monitoring stack..."
    
    if [[ -f "k8s/monitoring/production-monitoring-complete.yaml" ]]; then
        log "Applying enhanced monitoring configuration..."
        kubectl apply -f k8s/monitoring/production-monitoring-complete.yaml
        
        # Wait for monitoring pods to be ready
        log "Waiting for monitoring pods to be ready..."
        kubectl wait --namespace=$MONITORING_NAMESPACE \
            --for=condition=ready pod \
            --selector=app=prometheus \
            --timeout=300s || warn "Prometheus startup timed out"
            
        kubectl wait --namespace=$MONITORING_NAMESPACE \
            --for=condition=ready pod \
            --selector=app=grafana \
            --timeout=300s || warn "Grafana startup timed out"
            
    elif [[ -f "k8s/monitoring/simple-monitoring.yaml" ]]; then
        log "Applying simple monitoring configuration..."
        kubectl apply -f k8s/monitoring/simple-monitoring.yaml
    else
        warn "No monitoring configuration found, skipping monitoring deployment"
    fi
    
    success "Monitoring deployment completed"
}

# Deploy application
deploy_application() {
    log "Deploying application..."
    
    local deployment_dir="k8s/$ENVIRONMENT"
    
    # Check if enhanced manifests exist, otherwise use regular ones
    if [[ -f "$deployment_dir/backend-deployment-enhanced.yaml" ]]; then
        log "Using enhanced backend deployment..."
        kubectl apply -f "$deployment_dir/backend-deployment-enhanced.yaml"
    elif [[ -f "$deployment_dir/backend-deployment.yaml" ]]; then
        log "Using regular backend deployment..."
        kubectl apply -f "$deployment_dir/backend-deployment.yaml"
    else
        error "No backend deployment file found in $deployment_dir"
        exit 1
    fi
    
    if [[ -f "$deployment_dir/frontend-deployment-enhanced.yaml" ]]; then
        log "Using enhanced frontend deployment..."
        kubectl apply -f "$deployment_dir/frontend-deployment-enhanced.yaml"
    elif [[ -f "$deployment_dir/frontend-deployment.yaml" ]]; then
        log "Using regular frontend deployment..."
        kubectl apply -f "$deployment_dir/frontend-deployment.yaml"
    else
        error "No frontend deployment file found in $deployment_dir"
        exit 1
    fi
    
    # Apply ingress configuration
    if [[ -f "$deployment_dir/ingress-enhanced.yaml" ]]; then
        log "Using enhanced ingress configuration..."
        kubectl apply -f "$deployment_dir/ingress-enhanced.yaml"
    elif [[ -f "$deployment_dir/ingress.yaml" ]]; then
        log "Using regular ingress configuration..."
        kubectl apply -f "$deployment_dir/ingress.yaml"
    else
        error "No ingress file found in $deployment_dir"
        exit 1
    fi
    
    # Apply secrets if they exist
    if [[ -f "$deployment_dir/secrets.yaml" ]]; then
        log "Applying secrets..."
        kubectl apply -f "$deployment_dir/secrets.yaml"
    fi
    
    # Apply PostgreSQL for staging
    if [[ "$ENVIRONMENT" == "staging" && -f "$deployment_dir/postgresql.yaml" ]]; then
        log "Applying PostgreSQL for staging..."
        kubectl apply -f "$deployment_dir/postgresql.yaml"
    fi
    
    success "Application deployment completed"
}

# Wait for deployments to be ready
wait_for_deployments() {
    log "Waiting for deployments to be ready..."
    
    local timeout=600  # 10 minutes
    
    # Wait for backend
    log "Waiting for backend deployment..."
    kubectl wait --namespace=$NAMESPACE \
        --for=condition=available deployment/formerr-backend \
        --timeout=${timeout}s || {
        error "Backend deployment failed"
        kubectl describe deployment formerr-backend -n $NAMESPACE
        kubectl logs -l app=formerr-backend -n $NAMESPACE --tail=50
        exit 1
    }
    
    # Wait for frontend
    log "Waiting for frontend deployment..."
    kubectl wait --namespace=$NAMESPACE \
        --for=condition=available deployment/formerr-frontend \
        --timeout=${timeout}s || {
        error "Frontend deployment failed"
        kubectl describe deployment formerr-frontend -n $NAMESPACE
        kubectl logs -l app=formerr-frontend -n $NAMESPACE --tail=50
        exit 1
    }
    
    success "All deployments are ready"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check pod status
    log "Pod status:"
    kubectl get pods -n $NAMESPACE -o wide
    kubectl get pods -n $TRAEFIK_NAMESPACE -o wide
    kubectl get pods -n $MONITORING_NAMESPACE -o wide
    
    # Check services
    log "Service status:"
    kubectl get svc -n $NAMESPACE
    kubectl get svc -n $TRAEFIK_NAMESPACE
    kubectl get svc -n $MONITORING_NAMESPACE
    
    # Check ingress
    log "Ingress status:"
    kubectl get ingress -n $NAMESPACE
    kubectl get ingress -n $MONITORING_NAMESPACE
    
    # Check Traefik IngressRoutes
    if kubectl get ingressroute -n $NAMESPACE &>/dev/null; then
        log "IngressRoute status:"
        kubectl get ingressroute -n $NAMESPACE
    fi
    
    # Get LoadBalancer IP
    EXTERNAL_IP=$(kubectl get svc traefik -n $TRAEFIK_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "null" ]]; then
        success "LoadBalancer IP: $EXTERNAL_IP"
        log "Update your DNS records:"
        if [[ "$ENVIRONMENT" == "production" ]]; then
            log "  formerr.tech → $EXTERNAL_IP"
            log "  api.formerr.tech → $EXTERNAL_IP"
            log "  prometheus.formerr.tech → $EXTERNAL_IP"
            log "  grafana.formerr.tech → $EXTERNAL_IP"
            log "  traefik.formerr.tech → $EXTERNAL_IP"
        else
            log "  staging.formerr.tech → $EXTERNAL_IP"
            log "  api-staging.formerr.tech → $EXTERNAL_IP"
        fi
    else
        warn "LoadBalancer IP not available yet"
    fi
    
    success "Deployment verification completed"
}

# Health checks
health_checks() {
    log "Performing health checks..."
    
    # Check if pods are actually running and ready
    local unhealthy_pods=$(kubectl get pods -n $NAMESPACE --no-headers | grep -v Running | grep -v Completed | wc -l)
    if [[ $unhealthy_pods -gt 0 ]]; then
        warn "Found $unhealthy_pods unhealthy pods in $NAMESPACE namespace"
        kubectl get pods -n $NAMESPACE | grep -v Running | grep -v Completed || true
    fi
    
    # Check Traefik health
    log "Checking Traefik health..."
    if kubectl get pods -n $TRAEFIK_NAMESPACE -l app=traefik --no-headers | grep -q Running; then
        success "Traefik is running"
    else
        error "Traefik is not running properly"
        kubectl describe pods -n $TRAEFIK_NAMESPACE -l app=traefik
    fi
    
    success "Health checks completed"
}

# Print access information
print_access_info() {
    log "Access Information:"
    
    EXTERNAL_IP=$(kubectl get svc traefik -n $TRAEFIK_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "null" ]]; then
        if [[ "$ENVIRONMENT" == "production" ]]; then
            log "Production URLs (after DNS setup):"
            log "  Frontend: https://formerr.tech"
            log "  Backend API: https://api.formerr.tech"
            log "  Prometheus: https://prometheus.formerr.tech"
            log "  Grafana: https://grafana.formerr.tech (admin:admin)"
            log "  Traefik Dashboard: https://traefik.formerr.tech (admin:admin)"
        else
            log "Staging URLs (after DNS setup):"
            log "  Frontend: https://staging.formerr.tech"
            log "  Backend API: https://api-staging.formerr.tech"
        fi
        
        log ""
        log "Direct IP access for testing:"
        log "  Frontend: http://$EXTERNAL_IP (add Host: header)"
        log "  Backend API: http://$EXTERNAL_IP (add Host: header)"
        
        log ""
        log "Port-forward access (no DNS required):"
        log "  kubectl port-forward -n $NAMESPACE svc/formerr-frontend-service 3000:3000"
        log "  kubectl port-forward -n $NAMESPACE svc/formerr-backend-service 8000:8000"
        log "  kubectl port-forward -n $MONITORING_NAMESPACE svc/grafana 3001:3000"
        log "  kubectl port-forward -n $MONITORING_NAMESPACE svc/prometheus 9090:9090"
    else
        warn "LoadBalancer IP not available - using port-forward for access"
        log "Port-forward commands:"
        log "  kubectl port-forward -n $NAMESPACE svc/formerr-frontend-service 3000:3000"
        log "  kubectl port-forward -n $NAMESPACE svc/formerr-backend-service 8000:8000"
        log "  kubectl port-forward -n $MONITORING_NAMESPACE svc/grafana 3001:3000"
        log "  kubectl port-forward -n $MONITORING_NAMESPACE svc/prometheus 9090:9090"
    fi
}

# Main deployment flow
main() {
    log "Starting enhanced smart deployment for environment: $ENVIRONMENT"
    
    check_prerequisites
    cleanup_orphaned_resources
    install_traefik
    setup_namespace
    deploy_monitoring
    deploy_application
    wait_for_deployments
    verify_deployment
    health_checks
    print_access_info
    
    success "Deployment completed successfully!"
    log "Remember to:"
    log "1. Update DNS records to point to the LoadBalancer IP"
    log "2. Verify SSL certificates are issued automatically"
    log "3. Import Grafana dashboards from monitoring/grafana-dashboard-formerr.json"
    log "4. Test application functionality"
}

# Handle script arguments
case "${1:-}" in
    production|staging)
        main
        ;;
    *)
        log "Usage: $0 [production|staging]"
        log "Default: production"
        main
        ;;
esac
