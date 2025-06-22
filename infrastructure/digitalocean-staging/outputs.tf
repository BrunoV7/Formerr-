output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = digitalocean_kubernetes_cluster.formerr_cluster.endpoint
  sensitive   = true
}

output "cluster_token" {
  description = "Kubernetes cluster token"
  value       = digitalocean_kubernetes_cluster.formerr_cluster.kube_config[0].token
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = digitalocean_kubernetes_cluster.formerr_cluster.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = digitalocean_kubernetes_cluster.formerr_cluster.name
}

output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = digitalocean_container_registry.formerr_registry.endpoint
}

output "registry_name" {
  description = "Container registry name"
  value       = digitalocean_container_registry.formerr_registry.name
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
  value       = "formerr_db"
}

output "postgresql_user" {
  description = "PostgreSQL user"
  value       = "formerr_user"
}

output "loadbalancer_ip" {
  description = "Load balancer IP"
  value       = digitalocean_loadbalancer.formerr_lb.ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.formerr_vpc.id
}
