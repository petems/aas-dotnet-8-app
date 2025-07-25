#!/bin/bash

# Azure App Service .NET 8 Web App - Code Deployment Script
# This script builds and deploys the application code to an existing Azure Web App

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Get web app name from parameters, Terraform state, or azure-resources.json
get_web_app_name() {
    if [ -n "$1" ]; then
        WEB_APP_NAME="$1"
        log_info "Using web app name from parameter: ${WEB_APP_NAME}"
    elif [ -d "terraform" ]; then
        # Try to get from Terraform state first
        cd terraform
        WEB_APP_NAME=$(terraform state show azurerm_linux_web_app.main 2>/dev/null | grep '^[[:space:]]*name[[:space:]]*=' | sed 's/.*name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
        cd ..
        
        if [ -n "${WEB_APP_NAME}" ] && [ "${WEB_APP_NAME}" != "null" ]; then
            log_info "Using web app name from Terraform state: ${WEB_APP_NAME}"
        else
            # Fall back to azure-resources.json
            if [ -f "azure-resources.json" ]; then
                WEB_APP_NAME=$(jq -r '.webAppName' azure-resources.json 2>/dev/null || echo "")
                if [ -n "${WEB_APP_NAME}" ] && [ "${WEB_APP_NAME}" != "null" ]; then
                    log_info "Using web app name from azure-resources.json: ${WEB_APP_NAME}"
                else
                    log_error "Could not read web app name from azure-resources.json"
                    echo "Usage: $0 <web-app-name>"
                    echo "Or run './scripts/create-azure-resources.sh' first to create resources"
                    exit 1
                fi
            else
                log_error "No web app name provided and no configuration found"
                echo "Usage: $0 <web-app-name>"
                echo "Or run './scripts/create-azure-resources.sh' first to create resources"
                exit 1
            fi
        fi
    elif [ -f "azure-resources.json" ]; then
        WEB_APP_NAME=$(jq -r '.webAppName' azure-resources.json 2>/dev/null || echo "")
        if [ -n "${WEB_APP_NAME}" ] && [ "${WEB_APP_NAME}" != "null" ]; then
            log_info "Using web app name from azure-resources.json: ${WEB_APP_NAME}"
        else
            log_error "Could not read web app name from azure-resources.json"
            echo "Usage: $0 <web-app-name>"
            echo "Or run './scripts/create-azure-resources.sh' first to create resources"
            exit 1
        fi
    else
        log_error "No web app name provided and no configuration found"
        echo "Usage: $0 <web-app-name>"
        echo "Or run './scripts/create-azure-resources.sh' first to create resources"
        exit 1
    fi
}

# Get resource group name from Terraform state or azure-resources.json
get_resource_group() {
    if [ -d "terraform" ]; then
        # Try to get from Terraform state first
        cd terraform
        RESOURCE_GROUP_NAME=$(terraform state show azurerm_resource_group.main 2>/dev/null | grep '^[[:space:]]*name[[:space:]]*=' | sed 's/.*name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
        cd ..
        
        if [ -n "${RESOURCE_GROUP_NAME}" ] && [ "${RESOURCE_GROUP_NAME}" != "null" ]; then
            log_info "Using resource group from Terraform state: ${RESOURCE_GROUP_NAME}"
        else
            # Fall back to azure-resources.json
            if [ -f "azure-resources.json" ]; then
                RESOURCE_GROUP_NAME=$(jq -r '.resourceGroup' azure-resources.json 2>/dev/null || echo "")
                if [ -n "${RESOURCE_GROUP_NAME}" ] && [ "${RESOURCE_GROUP_NAME}" != "null" ]; then
                    log_info "Using resource group from azure-resources.json: ${RESOURCE_GROUP_NAME}"
                else
                    RESOURCE_GROUP_NAME="aas-dotnet-8-webapp-rg"
                    log_warning "Could not read resource group from azure-resources.json, using default: ${RESOURCE_GROUP_NAME}"
                fi
            else
                RESOURCE_GROUP_NAME="aas-dotnet-8-webapp-rg"
                log_warning "No configuration found, using default resource group: ${RESOURCE_GROUP_NAME}"
            fi
        fi
    elif [ -f "azure-resources.json" ]; then
        RESOURCE_GROUP_NAME=$(jq -r '.resourceGroup' azure-resources.json 2>/dev/null || echo "")
        if [ -n "${RESOURCE_GROUP_NAME}" ] && [ "${RESOURCE_GROUP_NAME}" != "null" ]; then
            log_info "Using resource group from azure-resources.json: ${RESOURCE_GROUP_NAME}"
        else
            RESOURCE_GROUP_NAME="aas-dotnet-8-webapp-rg"
            log_warning "Could not read resource group from azure-resources.json, using default: ${RESOURCE_GROUP_NAME}"
        fi
    else
        RESOURCE_GROUP_NAME="aas-dotnet-8-webapp-rg"
        log_warning "azure-resources.json not found, using default resource group: ${RESOURCE_GROUP_NAME}"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET 8 SDK is not installed. Please install it first: https://dotnet.microsoft.com/download/dotnet/8.0"
        exit 1
    fi
    
    # Check .NET version
    DOTNET_VERSION=$(dotnet --version)
    if [[ ! "${DOTNET_VERSION}" =~ ^8\. ]]; then
        log_error "Expected .NET 8 SDK, but found version: ${DOTNET_VERSION}"
        log_error "Please ensure .NET 8 SDK is installed and global.json is configured correctly"
        exit 1
    fi
    log_info "Using .NET version: ${DOTNET_VERSION}"
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check for jq (used for JSON parsing)
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Please install it:"
        log_error "  macOS: brew install jq"
        log_error "  Ubuntu/Debian: sudo apt-get install jq"
        log_error "  CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
    
    # Check for zip command
    if ! command -v zip &> /dev/null; then
        log_error "zip command is not available. Please install it:"
        log_error "  macOS: brew install zip"
        log_error "  Ubuntu/Debian: sudo apt-get install zip"
        log_error "  CentOS/RHEL: sudo yum install zip"
        exit 1
    fi
    
    log_success "All prerequisites met!"
}

# Verify web app exists
verify_web_app() {
    log_info "Verifying web app exists: ${WEB_APP_NAME}"
    
    if ! az webapp show --name "${WEB_APP_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" &> /dev/null; then
        log_error "Web app '${WEB_APP_NAME}' not found in resource group '${RESOURCE_GROUP_NAME}'"
        echo "Please run './scripts/create-azure-resources.sh' first to create the web app"
        exit 1
    fi
    
    log_success "Web app verified successfully"
}

# Build the application
build_application() {
    log_info "Building application..."
    
    # Clean previous builds and output directories manually
    rm -rf bin/Release
    rm -rf obj/Release
    
    # Restore packages first
    dotnet restore
    
    # Build the application
    dotnet build --configuration Release
    
    log_success "Application built successfully"
}

# Publish the application
publish_application() {
    log_info "Publishing application..."
    
    # Clean previous publish
    rm -rf ./publish
    
    # Publish the application for Linux x64 runtime
    dotnet publish --configuration Release --runtime linux-x64 --output ./publish --self-contained false
    
    log_success "Application published successfully"
}

# Create deployment package
create_deployment_package() {
    log_info "Creating deployment package..."
    
    # Create zip file
    cd publish
    zip -r ../app.zip .
    cd ..
    
    log_success "Deployment package created successfully"
}

# Deploy to Azure
deploy_to_azure() {
    log_info "Deploying to Azure Web App: ${WEB_APP_NAME}"
    log_info "🕐 Deployment started at: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "⏱️  Expected deployment time: ~2 minutes (can take up to 5 minutes on initial deploy)"
    echo
    
    az webapp deploy \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --name "${WEB_APP_NAME}" \
        --src-path app.zip \
        --type zip
    
    log_success "Application deployed successfully!"
}

# Clean up deployment files
cleanup() {
    log_info "Cleaning up deployment files..."
    
    rm -f app.zip
    rm -rf ./publish
    
    log_success "Cleanup completed"
}

# Display deployment information
show_deployment_info() {
    log_info "Deployment completed successfully!"
    echo
    echo "=== Deployment Information ==="
    echo "Web App: ${WEB_APP_NAME}"
    echo "Resource Group: ${RESOURCE_GROUP_NAME}"
    echo
    echo "=== Web App URLs ==="
    echo "Base URL: https://${WEB_APP_NAME}.azurewebsites.net"
    echo "Index Page: https://${WEB_APP_NAME}.azurewebsites.net/"
    echo "Swagger UI: https://${WEB_APP_NAME}.azurewebsites.net/swagger"
    echo "Hello endpoint: https://${WEB_APP_NAME}.azurewebsites.net/api/v1/hello"
    echo "Random endpoint: https://${WEB_APP_NAME}.azurewebsites.net/api/v1/random"
    echo "Error endpoint: https://${WEB_APP_NAME}.azurewebsites.net/api/v1/error"
    echo
    echo "=== Next Steps ==="
    echo "1. Test your endpoints using './scripts/test-endpoints.sh ${WEB_APP_NAME}'"
    echo "2. Monitor your application in Azure Portal"
    echo "3. View logs in Application Insights"
    echo
    echo "=== Future Deployments ==="
    echo "Subsequent deployments will be faster (~2 minutes) as the infrastructure is already set up."
}

# Main function
main() {
    echo "🚀 Deploying .NET 8 Web App to Azure"
    echo "===================================="
    echo
    
    get_web_app_name "$1"
    get_resource_group
    check_prerequisites
    verify_web_app
    build_application
    publish_application
    create_deployment_package
    deploy_to_azure
    cleanup
    show_deployment_info
}

# Run the main function
main "$@" 