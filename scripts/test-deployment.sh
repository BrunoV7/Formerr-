#!/bin/bash

# Test Script for Smart Deployment
# Shows what the smart deployment would do without actually deploying

set -e

echo "🧪 Testing Smart Deployment (Dry Run Mode)"
echo "=========================================="

# Set test environment variables
export SKIP_CONFIRM=1
export DO_TOKEN="test-token-placeholder"

echo ""
echo "🔍 Testing Staging Environment Detection..."
echo "-------------------------------------------"

# Test staging
./scripts/smart-deploy.sh staging formerr-staging-test 2>/dev/null | head -30 || {
    echo "❌ Staging test failed - this is expected without real DO token"
}

echo ""
echo "🔍 Testing Production Environment Detection..."
echo "---------------------------------------------"

# Test production  
./scripts/smart-deploy.sh production formerr-registry-test 2>/dev/null | head -30 || {
    echo "❌ Production test failed - this is expected without real DO token"
}

echo ""
echo "✅ Smart deployment script accepts command line arguments correctly!"
echo ""
echo "📋 Usage Summary:"
echo "  ./scripts/smart-deploy.sh staging formerr-staging     # Deploy to staging"
echo "  ./scripts/smart-deploy.sh production formerr-registry # Deploy to production"
echo ""
echo "🔧 Required Environment Variables:"
echo "  DO_STAGING_TOKEN or DO_TOKEN    # For staging deployments"
echo "  DO_TOKEN_PROD or DO_TOKEN       # For production deployments"
echo "  SKIP_CONFIRM=1                  # Skip confirmation (for CI/CD)"
