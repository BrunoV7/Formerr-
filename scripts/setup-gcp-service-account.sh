#!/bin/bash
# Script para criar Service Account do GCP com todas as permissões necessárias
# Usage: ./setup-gcp-service-account.sh YOUR_PROJECT_ID

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if project ID is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <GCP_PROJECT_ID>"
    print_warning "Example: $0 meu-projeto-formerr-123"
    exit 1
fi

PROJECT_ID="$1"
SA_NAME="formerr-ci-cd"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="formerr-gcp-sa-key.json"

echo "🚀 Setting up GCP Service Account for Formerr CI/CD"
echo "================================================="
echo "Project ID: $PROJECT_ID"
echo "SA Name: $SA_NAME"
echo "SA Email: $SA_EMAIL"
echo ""

# Set the project
print_status "Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
print_status "Enabling required APIs..."
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com

print_success "APIs enabled successfully"

# Check if service account already exists
if gcloud iam service-accounts describe $SA_EMAIL >/dev/null 2>&1; then
    print_warning "Service Account $SA_EMAIL already exists. Skipping creation."
else
    # Create service account
    print_status "Creating Service Account..."
    gcloud iam service-accounts create $SA_NAME \
        --display-name="Formerr CI/CD Service Account" \
        --description="Service Account para deploy automatizado do Formerr"
    
    print_success "Service Account created successfully"
fi

# Required roles for the service account
REQUIRED_ROLES=(
    "roles/container.admin"        # Kubernetes Engine Admin
    "roles/compute.admin"          # Compute Admin
    "roles/storage.admin"          # Storage Admin
    "roles/iam.serviceAccountUser" # Service Account User
    "roles/compute.securityAdmin"  # Security Admin
)

print_status "Adding required roles to Service Account..."

for role in "${REQUIRED_ROLES[@]}"; do
    print_status "Adding role: $role"
    
    if gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role" >/dev/null 2>&1; then
        print_success "✅ Role $role added successfully"
    else
        print_warning "⚠️ Role $role might already be assigned or failed to add"
    fi
done

# Generate service account key
print_status "Generating Service Account key..."

if [ -f "$KEY_FILE" ]; then
    print_warning "Key file $KEY_FILE already exists. Creating backup..."
    mv "$KEY_FILE" "${KEY_FILE}.backup.$(date +%s)"
fi

gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SA_EMAIL

print_success "Service Account key generated: $KEY_FILE"

# Verify the setup
print_status "Verifying Service Account setup..."

# Test authentication
gcloud auth activate-service-account --key-file=$KEY_FILE
gcloud config set project $PROJECT_ID

# Test permissions
print_status "Testing permissions..."

if gcloud container clusters list >/dev/null 2>&1; then
    print_success "✅ Kubernetes Engine permissions working"
else
    print_error "❌ Kubernetes Engine permissions failed"
fi

if gcloud compute networks list >/dev/null 2>&1; then
    print_success "✅ Compute permissions working"
else
    print_error "❌ Compute permissions failed"
fi

if gcloud storage buckets list >/dev/null 2>&1; then
    print_success "✅ Storage permissions working"
else
    print_error "❌ Storage permissions failed"
fi

# Display results
echo ""
echo "🎉 Setup completed successfully!"
echo "================================="
echo ""
echo "📋 GitHub Secrets to configure:"
echo "--------------------------------"
echo "GCP_PROJECT_ID = $PROJECT_ID"
echo "GCP_SA_KEY = $(cat $KEY_FILE | tr -d '\n')"
echo "GCP_CLUSTER_ZONE = us-central1-a"
echo ""
echo "📁 Files created:"
echo "- $KEY_FILE (Service Account key)"
echo ""
echo "🔒 Security notes:"
echo "- Keep the $KEY_FILE file secure"
echo "- Don't commit it to version control"
echo "- Add it to .gitignore"
echo ""
echo "🚀 Next steps:"
echo "1. Copy the GCP_SA_KEY content to GitHub Secrets"
echo "2. Add GCP_PROJECT_ID and GCP_CLUSTER_ZONE to GitHub Secrets"
echo "3. Test the staging pipeline"
echo ""

# Add to gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "$KEY_FILE" .gitignore; then
        echo "$KEY_FILE" >> .gitignore
        print_success "Added $KEY_FILE to .gitignore"
    fi
else
    echo "$KEY_FILE" > .gitignore
    print_success "Created .gitignore with $KEY_FILE"
fi

print_success "🎯 Service Account setup completed successfully!"
print_warning "Remember to configure the GitHub Secrets with the values shown above."
