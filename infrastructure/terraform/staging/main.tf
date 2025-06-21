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

provider "digitalocean" {
  token = var.do_token
}

# Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "formerr_staging" {
  name     = "formerr-staging"
  region   = var.region
  version  = var.k8s_version
  
  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
  }

  tags = ["formerr", "staging", "kubernetes"]
}

# Configure Kubernetes provider
provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.formerr_staging.endpoint
  token = digitalocean_kubernetes_cluster.formerr_staging.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.formerr_staging.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = digitalocean_kubernetes_cluster.formerr_staging.endpoint
    token = digitalocean_kubernetes_cluster.formerr_staging.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.formerr_staging.kube_config[0].cluster_ca_certificate
    )
  }
}

# Namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  depends_on = [digitalocean_kubernetes_cluster.formerr_staging]
}

# Namespace for application
resource "kubernetes_namespace" "formerr" {
  metadata {
    name = "formerr"
  }
  depends_on = [digitalocean_kubernetes_cluster.formerr_staging]
}

# Prometheus Helm release
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/prometheus-values.yaml")
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Load Balancer for external access
resource "digitalocean_loadbalancer" "formerr_lb" {
  name   = "formerr-staging-lb"
  region = var.region

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }

  healthcheck {
    protocol = "http"
    port     = 80
    path     = "/health"
  }

  droplet_tag = "formerr-staging"
}
