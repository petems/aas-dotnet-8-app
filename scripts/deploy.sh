#!/bin/bash

# Azure Functions .NET 8 App Deployment Script
# This script creates all necessary Azure resources and deploys the function app

set -e  # Exit on any error

# Configuration
RESOURCE_GROUP_NAME="aas-dotnet-8-functions-rg"
LOCATION="westus2"
STORAGE_ACCOUNT_NAME="aasdotnet8storage$(date +%s | tail -c 4)"
FUNCTION_APP_NAME="aas-dotnet-8-functions-$(date +%s | tail -c 4)"
APP_INSIGHTS_NAME="aas-dotnet-8-insights-$(date +%s | tail -c 4)"
SERVICE_PLAN_NAME="aas-dotnet-8-plan"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    if ! command -v func &> /dev/null; then
        log_error "Azure Functions Core Tools is not installed. Please install it first: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools"
        exit 1
    fi
    
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET 8 SDK is not installed. Please install it first: https://dotnet.microsoft.com/download/dotnet/8.0"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    log_success "All prerequisites met!"
}

# Create resource group
create_resource_group() {
    log_info "Creating resource group: $RESOURCE_GROUP_NAME"
    
    if az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
        log_warning "Resource group $RESOURCE_GROUP_NAME already exists"
    else
        az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
        log_success "Resource group created successfully"
    fi
}

# Create storage account
create_storage_account() {
    log_info "Creating storage account: $STORAGE_ACCOUNT_NAME"
    
    az storage account create \
        --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --sku Standard_LRS \
        --kind StorageV2
    
    log_success "Storage account created successfully"
}

# Create Application Insights
create_app_insights() {
    log_info "Creating Application Insights: $APP_INSIGHTS_NAME"
    
    az monitor app-insights component create \
        --app $APP_INSIGHTS_NAME \
        --location $LOCATION \
        --resource-group $RESOURCE_GROUP_NAME \
        --application-type web
    
    # Get the connection string
    APP_INSIGHTS_CONNECTION_STRING=$(az monitor app-insights component show \
        --app $APP_INSIGHTS_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --query connectionString \
        --output tsv)
    
    log_success "Application Insights created successfully"
}

# Create App Service Plan
create_app_service_plan() {
    log_info "Creating App Service Plan: $SERVICE_PLAN_NAME"
    
    az appservice plan create \
        --name $SERVICE_PLAN_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --sku B1 \
        --is-linux
    
    log_success "App Service Plan created successfully"
}

# Create Function App
create_function_app() {
    log_info "Creating Function App: $FUNCTION_APP_NAME"
    
    az functionapp create \
        --name $FUNCTION_APP_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --plan $SERVICE_PLAN_NAME \
        --runtime dotnet-isolated \
        --runtime-version 8.0 \
        --functions-version 4 \
        --storage-account $STORAGE_ACCOUNT_NAME \
        --app-insights $APP_INSIGHTS_NAME \
        --os-type Linux
    
    log_success "Function App created successfully"
}

# Configure Function App settings
configure_function_app() {
    log_info "Configuring Function App settings..."
    
    # Set Application Insights connection string
    az functionapp config appsettings set \
        --name $FUNCTION_APP_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_CONNECTION_STRING"
    
    # Set other required settings
    az functionapp config appsettings set \
        --name $FUNCTION_APP_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --settings \
        "FUNCTIONS_WORKER_RUNTIME=dotnet-isolated" \
        "WEBSITE_RUN_FROM_PACKAGE=1"
    
    log_success "Function App configured successfully"
}

# Build and deploy the application
deploy_application() {
    log_info "Building and deploying application..."
    
    # Build the application
    dotnet build --configuration Release
    
    # Publish the application
    dotnet publish --configuration Release --output ./publish
    
    # Deploy to Azure
    func azure functionapp publish $FUNCTION_APP_NAME
    
    log_success "Application deployed successfully!"
}

# Display deployment information
show_deployment_info() {
    log_info "Deployment completed successfully!"
    echo
    echo "=== Deployment Information ==="
    echo "Resource Group: $RESOURCE_GROUP_NAME"
    echo "Function App: $FUNCTION_APP_NAME"
    echo "Storage Account: $STORAGE_ACCOUNT_NAME"
    echo "Application Insights: $APP_INSIGHTS_NAME"
    echo "Location: $LOCATION"
    echo
    echo "=== Function App URLs ==="
    echo "Base URL: https://$FUNCTION_APP_NAME.azurewebsites.net"
    echo "Hello endpoint: https://$FUNCTION_APP_NAME.azurewebsites.net/api/hello"
    echo "Random endpoint: https://$FUNCTION_APP_NAME.azurewebsites.net/api/random"
    echo "Error endpoint: https://$FUNCTION_APP_NAME.azurewebsites.net/api/error"
    echo
    echo "=== Next Steps ==="
    echo "1. Test your endpoints using the URLs above"
    echo "2. Monitor your application in Azure Portal"
    echo "3. View logs in Application Insights"
    echo
    echo "=== Cleanup ==="
    echo "To delete all resources: az group delete --name $RESOURCE_GROUP_NAME --yes"
}

# Main deployment function
main() {
    echo "🚀 Starting Azure Functions .NET 8 App Deployment"
    echo "=================================================="
    echo
    
    check_prerequisites
    create_resource_group
    create_storage_account
    create_app_insights
    create_app_service_plan
    create_function_app
    configure_function_app
    deploy_application
    show_deployment_info
}

# Run the main function
main "$@" 