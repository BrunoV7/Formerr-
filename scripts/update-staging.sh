#!/bin/bash

# Apply the same smart resource detection to staging environment
# This script updates the staging Terraform configuration

echo "🔧 Updating Staging Environment with Smart Resource Detection"
echo "============================================================"

# Navigate to staging directory
cd infrastructure/digitalocean-staging

# Create a backup of the current main.tf
cp main.tf main.tf.backup

echo "📝 Updating staging main.tf with resource detection logic..."

# Create the updated main.tf with the same patterns as production
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  host  = local.cluster_endpoint
  token = local.cluster_token
  cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    host  = local.cluster_endpoint
    token = local.cluster_token
    cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
  }
}

# VPC - Use existing or create new
data "digitalocean_vpc" "existing_vpc" {
  count = var.use_existing_vpc ? 1 : 0
  name  = var.vpc_name
}

resource "digitalocean_vpc" "formerr_vpc" {
  count    = var.use_existing_vpc ? 0 : 1
  name     = var.vpc_name
  region   = var.region
  ip_range = "10.1.0.0/16"
}

locals {
  vpc_id = var.use_existing_vpc ? data.digitalocean_vpc.existing_vpc[0].id : digitalocean_vpc.formerr_vpc[0].id
}

# Kubernetes Cluster - Use existing or create new
data "digitalocean_kubernetes_cluster" "existing_cluster" {
  count = var.use_existing_cluster ? 1 : 0
  name  = var.cluster_name
}

resource "digitalocean_kubernetes_cluster" "formerr_cluster" {
  count    = var.use_existing_cluster ? 0 : 1
  name     = var.cluster_name
  region   = var.region
  version  = var.k8s_version
  vpc_uuid = local.vpc_id

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"  # Smaller nodes for staging
    node_count = var.node_count
    
    tags = ["staging", "formerr", "worker"]
  }

  tags = ["staging", "formerr", "k8s"]
}

locals {
  cluster_id = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].id : digitalocean_kubernetes_cluster.formerr_cluster[0].id
  cluster_name = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].name : digitalocean_kubernetes_cluster.formerr_cluster[0].name
  cluster_endpoint = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].endpoint : digitalocean_kubernetes_cluster.formerr_cluster[0].endpoint
  cluster_token = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].kube_config[0].token : digitalocean_kubernetes_cluster.formerr_cluster[0].kube_config[0].token
  cluster_ca_certificate = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].kube_config[0].cluster_ca_certificate : digitalocean_kubernetes_cluster.formerr_cluster[0].kube_config[0].cluster_ca_certificate
}

# Use existing container registry (shared with production)
# Note: DigitalOcean allows only one registry per account
data "digitalocean_container_registry" "existing_registry" {
  count = var.create_registry ? 0 : 1
  name  = var.registry_name
}

# If registry doesn't exist, create it
resource "digitalocean_container_registry" "formerr_registry" {
  count                  = var.create_registry ? 1 : 0
  name                   = var.registry_name
  subscription_tier_slug = "basic"
}

locals {
  registry_name = var.create_registry ? digitalocean_container_registry.formerr_registry[0].name : data.digitalocean_container_registry.existing_registry[0].name
  registry_endpoint = var.create_registry ? digitalocean_container_registry.formerr_registry[0].endpoint : data.digitalocean_container_registry.existing_registry[0].endpoint
}

# Note: PostgreSQL will be deployed via Kubernetes manifests in the CI/CD pipeline
# This keeps the infrastructure simpler and uses the in-cluster database approach

# Load Balancer - Use existing or create new
data "digitalocean_loadbalancer" "existing_lb" {
  count = var.use_existing_loadbalancer ? 1 : 0
  name  = var.loadbalancer_name
}

resource "digitalocean_loadbalancer" "formerr_lb" {
  count    = var.use_existing_loadbalancer ? 0 : 1
  name     = var.loadbalancer_name
  region   = var.region
  vpc_uuid = local.vpc_id

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }

  forwarding_rule {
    entry_protocol  = "https"
    entry_port      = 443
    target_protocol = "https"
    target_port     = 443
    tls_passthrough = true
  }

  healthcheck {
    protocol                 = "http"
    port                     = 80
    path                     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    healthy_threshold        = 3
    unhealthy_threshold      = 3
  }
}

locals {
  loadbalancer_id = var.use_existing_loadbalancer ? data.digitalocean_loadbalancer.existing_lb[0].id : (length(digitalocean_loadbalancer.formerr_lb) > 0 ? digitalocean_loadbalancer.formerr_lb[0].id : null)
  loadbalancer_ip = var.use_existing_loadbalancer ? data.digitalocean_loadbalancer.existing_lb[0].ip : (length(digitalocean_loadbalancer.formerr_lb) > 0 ? digitalocean_loadbalancer.formerr_lb[0].ip : null)
}

# Install Prometheus using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "55.5.0"

  create_namespace = true

  values = [
    file("${path.module}/prometheus-values.yaml")
  ]

  depends_on = [
    digitalocean_kubernetes_cluster.formerr_cluster,
    data.digitalocean_kubernetes_cluster.existing_cluster
  ]
}

# Create namespace for the application
resource "kubernetes_namespace" "formerr" {
  metadata {
    name = "formerr"
    labels = {
      name        = "formerr"
      environment = "staging"
    }
  }

  depends_on = [
    digitalocean_kubernetes_cluster.formerr_cluster,
    data.digitalocean_kubernetes_cluster.existing_cluster
  ]
}

# Note: Database secret will be created by the CI/CD pipeline
# after PostgreSQL deployment with generated passwords

# Create secret for container registry
resource "kubernetes_secret" "registry_secret" {
  metadata {
    name      = "formerr-registry-secret"
    namespace = kubernetes_namespace.formerr.metadata[0].name
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.digitalocean.com" = {
          auth = base64encode("${local.registry_name}:${var.do_token}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}
EOF

echo "✅ Staging main.tf updated with smart resource detection"

# Update outputs.tf for staging
echo "📝 Updating staging outputs.tf..."

cat > outputs.tf <<'EOF'
output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = local.cluster_endpoint
  sensitive   = true
}

output "cluster_token" {
  description = "Kubernetes cluster token"
  value       = local.cluster_token
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = local.cluster_ca_certificate
  sensitive   = true
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = local.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = local.registry_endpoint
}

output "registry_name" {
  description = "Container registry name"
  value       = local.registry_name
}

output "loadbalancer_ip" {
  description = "Load balancer IP"
  value       = local.loadbalancer_ip
}

output "postgresql_host" {
  description = "PostgreSQL service host (in-cluster)"
  value       = "postgresql.formerr.svc.cluster.local"
}

output "postgresql_port" {
  description = "PostgreSQL service port"
  value       = "5432"
}

output "postgresql_database" {
  description = "PostgreSQL database name"
  value       = "formerr_staging"
}

output "postgresql_secret_name" {
  description = "PostgreSQL secret name (created by CI/CD)"
  value       = "postgresql-secret"
}
EOF

echo "✅ Staging outputs.tf updated"

echo ""
echo "🎉 Staging environment updated with smart resource detection!"
echo ""
echo "Next steps:"
echo "1. Run: ./scripts/smart-deploy.sh"
echo "2. Choose 'staging' when prompted"
echo "3. Script will auto-detect existing resources"
echo ""
echo "Files updated:"
echo "- infrastructure/digitalocean-staging/main.tf"
echo "- infrastructure/digitalocean-staging/outputs.tf"
echo "- infrastructure/digitalocean-staging/variables.tf (already updated)"
