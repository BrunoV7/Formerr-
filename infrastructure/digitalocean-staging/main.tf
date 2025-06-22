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
  name     = "formerr-staging-vpc"
  region   = var.region
  ip_range = "10.1.0.0/16"
}

# Create the Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "formerr_cluster" {
  name     = "formerr-staging-cluster"
  region   = var.region
  version  = var.k8s_version
  vpc_uuid = digitalocean_vpc.formerr_vpc.id

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb" # Smaller nodes for staging
    node_count = var.node_count

    tags = ["staging", "formerr", "worker"]
  }

  tags = ["staging", "formerr", "k8s"]
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
  registry_name     = var.create_registry ? digitalocean_container_registry.formerr_registry[0].name : data.digitalocean_container_registry.existing_registry[0].name
  registry_endpoint = var.create_registry ? digitalocean_container_registry.formerr_registry[0].endpoint : data.digitalocean_container_registry.existing_registry[0].endpoint
}

# Kubernetes Namespace - Use existing or create new
data "kubernetes_namespace" "existing_namespace" {
  count = var.use_existing_namespace ? 1 : 0
  metadata {
    name = var.namespace_name
  }
}

# Note: PostgreSQL will be deployed via Kubernetes manifests in the CI/CD pipeline
# This keeps the infrastructure simpler and uses the in-cluster database approach

# Create a LoadBalancer for external access
resource "digitalocean_loadbalancer" "formerr_lb" {
  name     = "formerr-staging-lb"
  region   = var.region
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
    protocol                 = "http"
    port                     = 80
    path                     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    healthy_threshold        = 3
    unhealthy_threshold      = 3
  }
}

# Note: Prometheus monitoring will be deployed via Kubernetes manifests
# This approach is more reliable and faster than Helm in CI/CD
# Use: kubectl apply -f k8s/monitoring/prometheus-simple.yaml

# Local values for resource references
locals {
  namespace_name = var.use_existing_namespace ? data.kubernetes_namespace.existing_namespace[0].metadata[0].name : (length(kubernetes_namespace.formerr) > 0 ? kubernetes_namespace.formerr[0].metadata[0].name : var.namespace_name)
}

# Create namespace for the application
resource "kubernetes_namespace" "formerr" {
  count = var.use_existing_namespace ? 0 : 1
  metadata {
    name = var.namespace_name
    labels = {
      name        = var.namespace_name
      environment = "staging"
    }
  }

  depends_on = [digitalocean_kubernetes_cluster.formerr_cluster]
}

# Note: Database secret will be created by the CI/CD pipeline
# after PostgreSQL deployment with generated passwords

# Create secret for container registry
resource "kubernetes_secret" "registry_secret" {
  metadata {
    name      = "formerr-registry-secret"
    namespace = local.namespace_name
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
