#!/bin/bash

# Azure App Service .NET 8 Web App - Resource Creation Script
# This script creates all necessary Azure resources for the web app

set -e  # Exit on any error

# Configuration
RESOURCE_GROUP_NAME="aas-dotnet-8-webapp-rg"
LOCATION="westus2"
WEB_APP_NAME="aas-dotnet-8-webapp-$(date +%s | tail -c 4)"
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

# Create Web App
create_web_app() {
    log_info "Creating Web App: $WEB_APP_NAME"
    
    az webapp create \
        --name $WEB_APP_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --plan $SERVICE_PLAN_NAME \
        --runtime "DOTNETCORE:8.0" \
        --deployment-local-git
    
    log_success "Web App created successfully"
}

# Configure Web App settings
configure_web_app() {
    log_info "Configuring Web App settings..."
    
    # Set Application Insights connection string
    az webapp config appsettings set \
        --name $WEB_APP_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_CONNECTION_STRING"
    
    # Set other required settings
    az webapp config appsettings set \
        --name $WEB_APP_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --settings \
        "WEBSITE_RUN_FROM_PACKAGE=1" \
        "DOTNET_ENVIRONMENT=Production"
    
    log_success "Web App configured successfully"
}

# Save resource information to file
save_resource_info() {
    log_info "Saving resource information..."
    
    cat > azure-resources.json << EOF
{
  "resourceGroup": "$RESOURCE_GROUP_NAME",
  "webAppName": "$WEB_APP_NAME",
  "appInsightsName": "$APP_INSIGHTS_NAME",
  "servicePlanName": "$SERVICE_PLAN_NAME",
  "location": "$LOCATION",
  "baseUrl": "https://$WEB_APP_NAME.azurewebsites.net",
  "swaggerUrl": "https://$WEB_APP_NAME.azurewebsites.net/swagger",
  "helloEndpoint": "https://$WEB_APP_NAME.azurewebsites.net/api/v1/hello",
  "randomEndpoint": "https://$WEB_APP_NAME.azurewebsites.net/api/v1/random",
  "errorEndpoint": "https://$WEB_APP_NAME.azurewebsites.net/api/v1/error"
}
EOF
    
    log_success "Resource information saved to azure-resources.json"
}

# Display resource information
show_resource_info() {
    log_info "Azure resources created successfully!"
    echo
    echo "=== Resource Information ==="
    echo "Resource Group: $RESOURCE_GROUP_NAME"
    echo "Web App: $WEB_APP_NAME"
    echo "Application Insights: $APP_INSIGHTS_NAME"
    echo "Location: $LOCATION"
    echo
    echo "=== Web App URLs ==="
    echo "Base URL: https://$WEB_APP_NAME.azurewebsites.net"
    echo "Swagger UI: https://$WEB_APP_NAME.azurewebsites.net/swagger"
    echo "Hello endpoint: https://$WEB_APP_NAME.azurewebsites.net/api/v1/hello"
    echo "Random endpoint: https://$WEB_APP_NAME.azurewebsites.net/api/v1/random"
    echo "Error endpoint: https://$WEB_APP_NAME.azurewebsites.net/api/v1/error"
    echo
    echo "=== Next Steps ==="
    echo "1. Run './scripts/deploy-code.sh' to deploy your application"
    echo "2. Test your endpoints using './scripts/test-endpoints.sh $WEB_APP_NAME'"
    echo "3. Monitor your application in Azure Portal"
    echo "4. View logs in Application Insights"
    echo
    echo "=== Cleanup ==="
    echo "To delete all resources: az group delete --name $RESOURCE_GROUP_NAME --yes"
}

# Main function
main() {
    echo "🏗️  Creating Azure Resources for .NET 8 Web App"
    echo "=============================================="
    echo
    
    check_prerequisites
    create_resource_group
    create_app_insights
    create_app_service_plan
    create_web_app
    configure_web_app
    save_resource_info
    show_resource_info
}

# Run the main function
main "$@" 