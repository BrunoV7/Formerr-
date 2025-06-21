variable "do_token" {
  description = "Digital Ocean API Token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Digital Ocean region"
  type        = string
  default     = "fra1"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27.2-do.0"
}

variable "node_size" {
  description = "Size of worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}
