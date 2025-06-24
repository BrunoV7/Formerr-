# Production Terraform configuration - uses existing cluster
# Set these variables to use your existing DigitalOcean infrastructure

# Use existing cluster instead of creating new one
use_existing_cluster = true

# Existing cluster configuration
cluster_name = "formerr-production-cluster"

# Use existing VPC (set to false if you want Terraform to create it)
use_existing_vpc = true
vpc_name = "default-nyc1"  # Adjust if your VPC has a different name

# Registry configuration (DigitalOcean allows only one registry per account)
create_registry = false  # Set to true if you don't have a registry yet
registry_name = "formerr"

# Region where your cluster exists
region = "nyc1"  # Adjust if your cluster is in a different region

# Node configuration (for reference, not used when using existing cluster)
node_count = 3

# Environment
environment = "production"

# LoadBalancer configuration (set to true if you want to use existing LB)
use_existing_loadbalancer = false
loadbalancer_name = "formerr-production-lb"
