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
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.formerr_cluster.endpoint
  token = digitalocean_kubernetes_cluster.formerr_cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.formerr_cluster.kube_config[0].cluster_ca_certificate
  )
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    host  = digitalocean_kubernetes_cluster.formerr_cluster.endpoint
    token = digitalocean_kubernetes_cluster.formerr_cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.formerr_cluster.kube_config[0].cluster_ca_certificate
    )
  }
}

# Create a VPC for the cluster
resource "digitalocean_vpc" "formerr_vpc" {
  name     = "formerr-production-vpc"
  region   = var.region
  ip_range = "10.0.0.0/16"
}

# Create the Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "formerr_cluster" {
  name    = "formerr-production-cluster"
  region  = var.region
  version = var.k8s_version
  vpc_uuid = digitalocean_vpc.formerr_vpc.id

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-4gb"
    node_count = var.node_count
    
    tags = ["production", "formerr", "worker"]
  }

  tags = ["production", "formerr", "k8s"]
}

# Use existing container registry or create new one
# Note: DigitalOcean allows only one registry per account
data "digitalocean_container_registry" "existing_registry" {
  name = var.registry_name
}

# If registry doesn't exist, create it
resource "digitalocean_container_registry" "formerr_registry" {
  count                  = var.create_registry ? 1 : 0
  name                   = var.registry_name
  subscription_tier_slug = "basic"
}

locals {
  registry_name = var.create_registry ? digitalocean_container_registry.formerr_registry[0].name : data.digitalocean_container_registry.existing_registry.name
}

# Note: Using existing Digital Ocean database configured via GitHub secrets
# Database connection details are provided through pipeline secrets:
# - DATABASE_URL, DB_HOST, DB_NAME, DB_PASSWORD, DB_PORT, DB_USER

# Note: LoadBalancer will be managed by NGINX Ingress Controller
# Remove this resource if you prefer to use only Ingress
# Keep it if you want a separate LB for direct access

# Create a LoadBalancer for external access (optional)
resource "digitalocean_loadbalancer" "formerr_lb" {
  name   = "formerr-production-lb"
  region = var.region
  vpc_uuid = digitalocean_vpc.formerr_vpc.id

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
    protocol               = "http"
    port                   = 80
    path                   = "/health"
    check_interval_seconds = 10
    response_timeout_seconds = 5
    healthy_threshold      = 3
    unhealthy_threshold    = 3
  }
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

  depends_on = [digitalocean_kubernetes_cluster.formerr_cluster]
}

# Create namespace for the application
resource "kubernetes_namespace" "formerr" {
  metadata {
    name = "formerr"
    labels = {
      name = "formerr"
      environment = "production"
    }
  }

  depends_on = [digitalocean_kubernetes_cluster.formerr_cluster]
}

# Create secret for database connection (uses GitHub secrets)
resource "kubernetes_secret" "db_secret" {
  metadata {
    name      = "formerr-db-secret"
    namespace = kubernetes_namespace.formerr.metadata[0].name
  }

  data = {
    # These values will be provided by the CI/CD pipeline from GitHub secrets
    DATABASE_URL = var.database_url
    DB_HOST      = var.db_host
    DB_PORT      = var.db_port
    DB_NAME      = var.db_name
    DB_USER      = var.db_user
    DB_PASSWORD  = var.db_password
  }

  type = "Opaque"
}

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
