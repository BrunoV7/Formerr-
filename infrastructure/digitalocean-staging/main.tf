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
  name    = "formerr-staging-cluster"
  region  = var.region
  version = var.k8s_version
  vpc_uuid = digitalocean_vpc.formerr_vpc.id

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"  # Smaller nodes for staging
    node_count = var.node_count
    
    tags = ["staging", "formerr", "worker"]
  }

  tags = ["staging", "formerr", "k8s"]
}

# Create a container registry
resource "digitalocean_container_registry" "formerr_registry" {
  name                   = "formerr-staging"
  subscription_tier_slug = "basic"
}

# Note: PostgreSQL will be deployed via Kubernetes manifests in the CI/CD pipeline
# This keeps the infrastructure simpler and uses the in-cluster database approach

# Create a LoadBalancer for external access
resource "digitalocean_loadbalancer" "formerr_lb" {
  name   = "formerr-staging-lb"
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
    target_protocol = "http"
    target_port     = 80
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
    namespace = kubernetes_namespace.formerr.metadata[0].name
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.digitalocean.com" = {
          auth = base64encode("${digitalocean_container_registry.formerr_registry.name}:${var.do_token}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}
