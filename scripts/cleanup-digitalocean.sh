#!/bin/bash

echo "🧹 FORMERR - Complete DigitalOcean Cleanup Script"
echo "=================================================="
echo ""
echo "⚠️  WARNING: This will clean up remaining DigitalOcean resources for Formerr!"
echo "🗄️  Database will be preserved to avoid data loss!"
echo ""

# Check if we have the token
if [ -z "$DO_TOKEN_PROD" ]; then
    echo "❌ Error: DO_TOKEN_PROD environment variable not set"
    echo "Please set your DigitalOcean token:"
    echo "export DO_TOKEN_PROD=your_token_here"
    exit 1
fi

# Confirmation unless SKIP_CONFIRM is set
if [ -z "$SKIP_CONFIRM" ]; then
    echo "Type 'DELETE' to confirm you want to destroy all resources:"
    read -r confirmation
    if [ "$confirmation" != "DELETE" ]; then
        echo "❌ Cleanup cancelled"
        exit 0
    fi
fi

echo ""
echo "🔍 Discovering resources to clean up..."

# Set doctl token
export DIGITALOCEAN_ACCESS_TOKEN="$DO_TOKEN_PROD"

# Authenticate doctl
doctl auth init -t "$DO_TOKEN_PROD"

echo ""
echo "📋 Current DigitalOcean Resources:"
echo "===================================="

# List current resources
echo "🖥️  Kubernetes Clusters:"
doctl kubernetes cluster list

echo ""
echo "🗃️  Container Registries:"
doctl registry list

echo ""
echo "🗄️  Databases:"
doctl databases list

echo ""
echo "🌐 Load Balancers:"
doctl compute load-balancer list

echo ""
echo "💾 Volumes:"
doctl compute volume list

echo ""
echo "🔗 VPCs:"
doctl vpcs list

echo ""
echo "🧹 Starting cleanup process..."
echo "=============================="

# 1. Delete Kubernetes Cluster (this will also delete associated Load Balancers)
echo "🖥️  Deleting Kubernetes cluster..."
CLUSTER_ID=$(doctl kubernetes cluster list --output json | jq -r '.[] | select(.name == "formerr-production-cluster") | .id')
if [ -n "$CLUSTER_ID" ]; then
    echo "Found cluster: $CLUSTER_ID"
    doctl kubernetes cluster delete "$CLUSTER_ID" --force || echo "⚠️  Cluster deletion failed or already deleted"
    
    # Wait for cluster to be fully deleted
    echo "⏳ Waiting for cluster deletion to complete..."
    while doctl kubernetes cluster get "$CLUSTER_ID" &>/dev/null; do
        echo "⏳ Cluster still deleting..."
        sleep 30
    done
    echo "✅ Cluster deleted"
else
    echo "✅ No cluster found to delete"
fi

# 2. Delete Container Registry
echo ""
echo "🗃️  Deleting container registry..."
REGISTRY_NAME=$(doctl registry list --output json | jq -r '.[] | select(.name == "formerr-production" or .name == "formerr-registry") | .name')
if [ -n "$REGISTRY_NAME" ]; then
    echo "Found registry: $REGISTRY_NAME"
    doctl registry delete "$REGISTRY_NAME" --force || echo "⚠️  Registry deletion failed or already deleted"
    echo "✅ Registry deletion initiated"
else
    echo "✅ No registry found to delete"
fi

# 3. Skip Database (keeping existing database)
echo ""
echo "🗄️  Skipping database deletion (keeping existing data)..."
DB_ID=$(doctl databases list --output json | jq -r '.[] | select(.name == "db-postgresql-nyc1-67289") | .id')
if [ -n "$DB_ID" ]; then
    echo "✅ Database found and will be preserved: $DB_ID"
    echo "💡 The pipeline will configure network access for the existing database"
else
    echo "⚠️  Database db-postgresql-nyc1-67289 not found!"
    echo "📋 Available databases:"
    doctl databases list
fi

# 4. Clean up any remaining Load Balancers
echo ""
echo "🌐 Cleaning up remaining load balancers..."
LB_IDS=$(doctl compute load-balancer list --output json | jq -r '.[] | select(.name | contains("formerr") or contains("nginx")) | .id')
if [ -n "$LB_IDS" ]; then
    echo "Found load balancers to delete:"
    echo "$LB_IDS"
    for lb_id in $LB_IDS; do
        doctl compute load-balancer delete "$lb_id" --force || echo "⚠️  Load balancer $lb_id deletion failed"
    done
    echo "✅ Load balancers cleanup initiated"
else
    echo "✅ No load balancers found to delete"
fi

# 5. Clean up Volumes
echo ""
echo "💾 Cleaning up volumes..."
VOLUME_IDS=$(doctl compute volume list --output json | jq -r '.[] | select(.name | contains("formerr") or contains("pvc")) | .id')
if [ -n "$VOLUME_IDS" ]; then
    echo "Found volumes to delete:"
    echo "$VOLUME_IDS"
    for volume_id in $VOLUME_IDS; do
        doctl compute volume delete "$volume_id" --force || echo "⚠️  Volume $volume_id deletion failed"
    done
    echo "✅ Volumes cleanup initiated"
else
    echo "✅ No volumes found to delete"
fi

# 6. Clean up VPCs (be careful - only delete our specific VPC)
echo ""
echo "🔗 Cleaning up VPC..."
VPC_ID=$(doctl vpcs list --output json | jq -r '.[] | select(.name == "formerr-production-vpc") | .id')
if [ -n "$VPC_ID" ]; then
    echo "Found VPC: $VPC_ID"
    # Wait a bit for resources to be freed
    echo "⏳ Waiting for resources to be freed before deleting VPC..."
    sleep 60
    doctl vpcs delete "$VPC_ID" --force || echo "⚠️  VPC deletion failed - may have dependencies"
    echo "✅ VPC deletion attempted"
else
    echo "✅ No Formerr VPC found to delete"
fi

# 7. Clean up Terraform state
echo ""
echo "🏗️  Cleaning up Terraform state..."
cd infrastructure/digitalocean-production
if [ -f "terraform.tfstate" ]; then
    echo "Backing up current state..."
    cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
    
    # Remove the state file to start fresh
    rm -f terraform.tfstate terraform.tfstate.backup
    rm -rf .terraform .terraform.lock.hcl
    echo "✅ Terraform state cleaned"
else
    echo "✅ No Terraform state to clean"
fi

echo ""
echo "🎉 CLEANUP COMPLETED!"
echo "===================="
echo ""
echo "📋 Summary:"
echo "✅ Kubernetes cluster deletion initiated"
echo "✅ Container registry deletion initiated"
echo "✅ Database deletion initiated"
echo "✅ Load balancers cleanup initiated"
echo "✅ Volumes cleanup initiated"
echo "✅ VPC cleanup attempted"
echo "✅ Terraform state cleaned"
echo ""
echo "⏳ Note: Some resources may take a few minutes to fully delete."
echo "🔄 You can now run the deployment pipeline to recreate everything fresh!"
echo ""
echo "📝 Next steps:"
echo "1. Wait 5-10 minutes for all resources to be fully deleted"
echo "2. Push changes to trigger the deployment pipeline"
echo "3. Monitor the GitHub Actions for successful deployment"
echo "4. Update DNS records with the new Load Balancer IP"
echo ""
