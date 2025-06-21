output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.formerr_staging.id
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.formerr_staging.endpoint
}

output "cluster_token" {
  description = "Token for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.formerr_staging.kube_config[0].token
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.formerr_staging.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

# output "load_balancer_ip" {
#   description = "Load balancer IP address"  
#   value       = digitalocean_loadbalancer.formerr_lb.ip
# }
