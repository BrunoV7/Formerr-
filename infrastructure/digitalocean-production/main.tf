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
  host                   = local.cluster_endpoint
  token                  = local.cluster_token
  cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    token                  = local.cluster_token
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
  ip_range = "10.0.0.0/16"
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
    size       = "s-2vcpu-4gb"
    node_count = var.node_count

    tags = ["production", "formerr", "worker"]
  }

  tags = ["production", "formerr", "k8s"]
}

locals {
  cluster_id             = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].id : digitalocean_kubernetes_cluster.formerr_cluster[0].id
  cluster_name           = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].name : digitalocean_kubernetes_cluster.formerr_cluster[0].name
  cluster_endpoint       = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].endpoint : digitalocean_kubernetes_cluster.formerr_cluster[0].endpoint
  cluster_token          = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].kube_config[0].token : digitalocean_kubernetes_cluster.formerr_cluster[0].kube_config[0].token
  cluster_ca_certificate = var.use_existing_cluster ? data.digitalocean_kubernetes_cluster.existing_cluster[0].kube_config[0].cluster_ca_certificate : digitalocean_kubernetes_cluster.formerr_cluster[0].kube_config[0].cluster_ca_certificate
}

# Use existing container registry or create new one
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

# Note: Using existing Digital Ocean database configured via GitHub secrets
# Database connection details are provided through pipeline secrets:
# - DATABASE_URL, DB_HOST, DB_NAME, DB_PASSWORD, DB_PORT, DB_USER

# Load Balancer - Use existing or create new (optional)
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
  namespace_name  = var.use_existing_namespace ? data.kubernetes_namespace.existing_namespace[0].metadata[0].name : (length(kubernetes_namespace.formerr) > 0 ? kubernetes_namespace.formerr[0].metadata[0].name : var.namespace_name)
}

# Note: Prometheus monitoring will be deployed via Kubernetes manifests
# This approach is more reliable and faster than Helm in CI/CD

# Create namespace for the application
resource "kubernetes_namespace" "formerr" {
  count = var.use_existing_namespace ? 0 : 1
  metadata {
    name = var.namespace_name
    labels = {
      name        = var.namespace_name
      environment = "production"
    }
  }

  depends_on = [
    digitalocean_kubernetes_cluster.formerr_cluster,
    data.digitalocean_kubernetes_cluster.existing_cluster
  ]
}

# Kubernetes Namespace - Use existing or create new
data "kubernetes_namespace" "existing_namespace" {
  count = var.use_existing_namespace ? 1 : 0
  metadata {
    name = var.namespace_name
  }
}

# Kubernetes Secrets - Use existing or create new
data "kubernetes_secret" "existing_db_secret" {
  count = var.use_existing_db_secret ? 1 : 0
  metadata {
    name      = "formerr-db-secret"
    namespace = local.namespace_name
  }
}

data "kubernetes_secret" "existing_registry_secret" {
  count = var.use_existing_registry_secret ? 1 : 0
  metadata {
    name      = "formerr-registry-secret"
    namespace = local.namespace_name
  }
}

# Create secret for database connection (uses GitHub secrets)
resource "kubernetes_secret" "db_secret" {
  count = var.use_existing_db_secret ? 0 : 1
  metadata {
    name      = "formerr-db-secret"
    namespace = local.namespace_name
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
  count = var.use_existing_registry_secret ? 0 : 1
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
