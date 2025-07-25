#!/bin/bash

# Terraform deployment script for Azure App Service
# This script handles both infrastructure and code deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Default values
TERRAFORM_DIR="terraform"
WEB_APP_NAME=""
RESOURCE_GROUP_NAME=""
DEPLOY_INFRASTRUCTURE=true
DEPLOY_CODE=true
SKIP_CONFIRM=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --web-app-name)
            WEB_APP_NAME="$2"
            shift 2
            ;;
        --resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        --terraform-dir)
            TERRAFORM_DIR="$2"
            shift 2
            ;;
        --infrastructure-only)
            DEPLOY_INFRASTRUCTURE=true
            DEPLOY_CODE=false
            shift
            ;;
        --code-only)
            DEPLOY_INFRASTRUCTURE=false
            DEPLOY_CODE=true
            shift
            ;;
        --skip-confirm)
            SKIP_CONFIRM=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Show help
show_help() {
    echo "Terraform Deployment Script for Azure App Service"
    echo "================================================"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --web-app-name NAME     Web app name (required if not in terraform.tfvars)"
    echo "  --resource-group NAME   Resource group name (required if not in terraform.tfvars)"
    echo "  --terraform-dir DIR     Terraform directory (default: terraform)"
    echo "  --infrastructure-only   Deploy only infrastructure, skip code deployment"
    echo "  --code-only            Deploy only code, skip infrastructure deployment"
    echo "  --skip-confirm         Skip confirmation prompts"
    echo "  --help, -h             Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --web-app-name my-app --resource-group my-rg"
    echo "  $0 --infrastructure-only"
    echo "  $0 --code-only"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first: https://www.terraform.io/downloads"
        exit 1
    fi
    
    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "Using Terraform version: $TERRAFORM_VERSION"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if .NET is installed
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET 8 SDK is not installed. Please install it first: https://dotnet.microsoft.com/download/dotnet/8.0"
        exit 1
    fi
    
    # Check .NET version
    DOTNET_VERSION=$(dotnet --version)
    if [[ ! "$DOTNET_VERSION" =~ ^8\. ]]; then
        log_error "Expected .NET 8 SDK, but found version: $DOTNET_VERSION"
        exit 1
    fi
    log_info "Using .NET version: $DOTNET_VERSION"
    
    # Check if Terraform directory exists
    if [ ! -d "$TERRAFORM_DIR" ]; then
        log_error "Terraform directory '$TERRAFORM_DIR' not found"
        exit 1
    fi
    
    log_success "All prerequisites met!"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init
    
    log_success "Terraform initialized successfully"
}

# Plan Terraform deployment
plan_terraform() {
    log_info "Planning Terraform deployment..."
    
    # Build terraform plan arguments
    PLAN_ARGS=""
    if [ -n "$WEB_APP_NAME" ]; then
        PLAN_ARGS="$PLAN_ARGS -var=\"web_app_name=$WEB_APP_NAME\""
    fi
    if [ -n "$RESOURCE_GROUP_NAME" ]; then
        PLAN_ARGS="$PLAN_ARGS -var=\"resource_group_name=$RESOURCE_GROUP_NAME\""
    fi
    
    # Run terraform plan
    if [ -n "$PLAN_ARGS" ]; then
        terraform plan $PLAN_ARGS
    else
        terraform plan
    fi
    
    log_success "Terraform plan completed"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    # Build terraform apply arguments
    APPLY_ARGS="-auto-approve"
    if [ -n "$WEB_APP_NAME" ]; then
        APPLY_ARGS="$APPLY_ARGS -var=\"web_app_name=$WEB_APP_NAME\""
    fi
    if [ -n "$RESOURCE_GROUP_NAME" ]; then
        APPLY_ARGS="$APPLY_ARGS -var=\"resource_group_name=$RESOURCE_GROUP_NAME\""
    fi
    
    # Run terraform apply
    if [ -n "$APPLY_ARGS" ]; then
        terraform apply $APPLY_ARGS
    else
        terraform apply -auto-approve
    fi
    
    log_success "Infrastructure deployed successfully"
}

# Get deployment information from Terraform
get_deployment_info() {
    log_info "Getting deployment information..."
    
    # Get outputs from Terraform
    WEB_APP_NAME=$(terraform output -raw web_app_name)
    RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)
    WEB_APP_URL=$(terraform output -raw web_app_url)
    
    log_info "Web App: $WEB_APP_NAME"
    log_info "Resource Group: $RESOURCE_GROUP_NAME"
    log_info "URL: $WEB_APP_URL"
    
    # Save deployment info for code deployment
    cd ..
    cat > terraform-deployment.json << EOF
{
  "webAppName": "$WEB_APP_NAME",
  "resourceGroup": "$RESOURCE_GROUP_NAME",
  "webAppUrl": "$WEB_APP_URL"
}
EOF
    
    log_success "Deployment information saved to terraform-deployment.json"
}

# Deploy application code
deploy_code() {
    log_info "Deploying application code..."
    
    cd ..
    
    # Use deployment info from Terraform
    if [ -f "terraform-deployment.json" ]; then
        WEB_APP_NAME=$(jq -r '.webAppName' terraform-deployment.json)
        RESOURCE_GROUP_NAME=$(jq -r '.resourceGroup' terraform-deployment.json)
    fi
    
    if [ -z "$WEB_APP_NAME" ] || [ -z "$RESOURCE_GROUP_NAME" ]; then
        log_error "Could not determine web app name or resource group"
        exit 1
    fi
    
    # Run the code deployment script
    ./scripts/deploy-code.sh "$WEB_APP_NAME"
    
    log_success "Application code deployed successfully"
}

# Show deployment information
show_deployment_info() {
    log_info "Deployment completed successfully!"
    echo
    echo "=== Deployment Information ==="
    
    if [ -f "terraform-deployment.json" ]; then
        WEB_APP_NAME=$(jq -r '.webAppName' terraform-deployment.json)
        WEB_APP_URL=$(jq -r '.webAppUrl' terraform-deployment.json)
        
        echo "Web App: $WEB_APP_NAME"
        echo "Base URL: $WEB_APP_URL"
        echo "Index Page: $WEB_APP_URL/"
        echo "Swagger UI: $WEB_APP_URL/swagger"
        echo "Hello endpoint: $WEB_APP_URL/api/v1/hello"
        echo "Random endpoint: $WEB_APP_URL/api/v1/random"
        echo "Error endpoint: $WEB_APP_URL/api/v1/error"
    fi
    
    echo
    echo "=== Next Steps ==="
    echo "1. Test your endpoints using './scripts/test-endpoints.sh $WEB_APP_NAME'"
    echo "2. Monitor your application in Azure Portal"
    echo "3. View logs in Application Insights"
    echo
    echo "=== Cleanup ==="
    echo "To destroy all resources: cd $TERRAFORM_DIR && terraform destroy"
}

# Main function
main() {
    echo "🏗️  Terraform Deployment for Azure App Service"
    echo "=============================================="
    echo
    
    check_prerequisites
    
    if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
        init_terraform
        plan_terraform
        
        if [ "$SKIP_CONFIRM" = false ]; then
            echo
            read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Deployment cancelled"
                exit 0
            fi
        fi
        
        deploy_infrastructure
        get_deployment_info
    fi
    
    if [ "$DEPLOY_CODE" = true ]; then
        deploy_code
    fi
    
    show_deployment_info
}

# Run the main function
main "$@" 