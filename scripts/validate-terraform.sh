#!/bin/bash

# Terraform Validation Script
# This script validates the Terraform configuration without applying changes

set -e

echo "🔍 Terraform Configuration Validation"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate a Terraform configuration
validate_config() {
    local env_name=$1
    local dir_path=$2
    
    echo ""
    echo "📁 Validating $env_name environment..."
    
    cd "$dir_path"
    
    # Initialize
    echo "   📥 Initializing..."
    if terraform init -input=false > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Init successful${NC}"
    else
        echo -e "   ${RED}❌ Init failed${NC}"
        return 1
    fi
    
    # Validate syntax
    echo "   🔍 Validating syntax..."
    if terraform validate > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Syntax valid${NC}"
    else
        echo -e "   ${RED}❌ Syntax errors found${NC}"
        terraform validate
        return 1
    fi
    
    # Format check
    echo "   📝 Checking format..."
    if terraform fmt -check > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Format OK${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Format issues (auto-fixable)${NC}"
        terraform fmt
    fi
    
    cd - > /dev/null
    return 0
}

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    echo -e "${RED}❌ Please run this script from the Formerr project root directory${NC}"
    exit 1
fi

# Validate production configuration
if validate_config "Production" "infrastructure/digitalocean-production"; then
    echo -e "${GREEN}✅ Production configuration is valid${NC}"
else
    echo -e "${RED}❌ Production configuration has issues${NC}"
    PROD_VALID=false
fi

# Validate staging configuration
if validate_config "Staging" "infrastructure/digitalocean-staging"; then
    echo -e "${GREEN}✅ Staging configuration is valid${NC}"
else
    echo -e "${RED}❌ Staging configuration has issues${NC}"
    STAGING_VALID=false
fi

echo ""
echo "📋 Validation Summary:"
echo "====================="

if [[ "$PROD_VALID" != "false" ]]; then
    echo -e "${GREEN}✅ Production: Ready for deployment${NC}"
else
    echo -e "${RED}❌ Production: Needs fixes${NC}"
fi

if [[ "$STAGING_VALID" != "false" ]]; then
    echo -e "${GREEN}✅ Staging: Ready for deployment${NC}"
else
    echo -e "${RED}❌ Staging: Needs fixes${NC}"
fi

if [[ "$PROD_VALID" != "false" && "$STAGING_VALID" != "false" ]]; then
    echo ""
    echo -e "${GREEN}🎉 All configurations are valid!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./scripts/quick-deploy.sh"
    echo "2. Or deploy via GitHub Actions"
    echo "3. Or manual terraform apply in infrastructure directories"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️  Please fix the configuration issues above${NC}"
    exit 1
fi
