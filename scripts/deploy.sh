#!/bin/bash

# Azure App Service .NET 8 Web App - Complete Deployment Script
# This script creates Azure resources and deploys the application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if scripts exist
check_scripts() {
    if [ ! -f "scripts/create-azure-resources.sh" ]; then
        log_error "create-azure-resources.sh script not found"
        exit 1
    fi
    
    if [ ! -f "scripts/deploy-code.sh" ]; then
        log_error "deploy-code.sh script not found"
        exit 1
    fi
    
    # Make scripts executable
    chmod +x scripts/create-azure-resources.sh
    chmod +x scripts/deploy-code.sh
}

# Main deployment function
main() {
    echo "🚀 Complete Azure App Service .NET 8 Web App Deployment"
    echo "======================================================"
    echo
    
    check_scripts
    
    log_info "Step 1: Creating Azure resources..."
    ./scripts/create-azure-resources.sh
    
    echo
    log_info "Step 2: Deploying application code..."
    log_info "⏱️  Expected deployment time: ~2 minutes (can take up to 5 minutes on initial deploy)"
    ./scripts/deploy-code.sh
    
    echo
    log_success "Complete deployment finished successfully!"
    echo
    echo "=== Summary ==="
    echo "✅ Azure resources created"
    echo "✅ Application deployed"
    echo
    echo "=== Next Steps ==="
    echo "1. Test your endpoints using './scripts/test-endpoints.sh <web-app-name>'"
    echo "2. Monitor your application in Azure Portal"
    echo "3. View logs in Application Insights"
    echo
    echo "=== Future Deployments ==="
    echo "For code updates only, run: './scripts/deploy-code.sh <web-app-name>'"
    echo "For new resources, run: './scripts/create-azure-resources.sh'"
}

# Run the main function
main "$@" 