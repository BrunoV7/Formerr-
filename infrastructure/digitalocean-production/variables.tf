variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31.1-do.3"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "github_client_id" {
  description = "GitHub OAuth Client ID"
  type        = string
  sensitive   = true
}

variable "github_client_secret" {
  description = "GitHub OAuth Client Secret"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT Secret for authentication"
  type        = string
  sensitive   = true
}

variable "session_secret" {
  description = "Session Secret"
  type        = string
  sensitive   = true
}

# Database configuration (using existing Digital Ocean database)
variable "database_url" {
  description = "Complete database URL"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "formerr_db"
}

variable "db_user" {
  description = "Database user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "registry_name" {
  description = "Name of the container registry"
  type        = string
  default     = "formerr-registry"
}

variable "create_registry" {
  description = "Whether to create a new registry or use existing one"
  type        = bool
  default     = false
}

# Infrastructure existence checks
variable "vpc_name" {
  description = "Name of the VPC to create or use existing"
  type        = string
  default     = "formerr-production-vpc"
}

variable "use_existing_vpc" {
  description = "Whether to use an existing VPC instead of creating new one"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "formerr-production-cluster"
}

variable "use_existing_cluster" {
  description = "Whether to use an existing Kubernetes cluster"
  type        = bool
  default     = false
}

variable "loadbalancer_name" {
  description = "Name of the load balancer"
  type        = string
  default     = "formerr-production-lb"
}

variable "use_existing_loadbalancer" {
  description = "Whether to use an existing load balancer"
  type        = bool
  default     = false
}
