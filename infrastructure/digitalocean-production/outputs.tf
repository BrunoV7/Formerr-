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
