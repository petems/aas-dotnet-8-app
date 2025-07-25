#!/bin/bash

# Local Development Setup Script
# This script helps new users set up the project for local development

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

echo "🔧 Setting up Azure App Service .NET 8 Web App for local development"
echo "===================================================================="
echo

# Check if .NET 8 is installed
if ! command -v dotnet &> /dev/null; then
    log_warning ".NET 8 SDK not found. Please install it from: https://dotnet.microsoft.com/download/dotnet/8.0"
    exit 1
fi

# Check .NET version
DOTNET_VERSION=$(dotnet --version)
if [[ ! "$DOTNET_VERSION" =~ ^8\. ]]; then
    log_warning "Expected .NET 8 SDK, but found version: $DOTNET_VERSION"
    log_warning "Please ensure .NET 8 SDK is installed and global.json is configured correctly"
    exit 1
fi
log_info "Found .NET version: $DOTNET_VERSION"

# Restore dependencies
log_info "Restoring NuGet packages..."
dotnet restore

# Build the project
log_info "Building the project..."
dotnet build

# Check if local.settings.json exists
if [ ! -f "local.settings.json" ]; then
    log_info "Creating local.settings.json from template..."
    cp local.settings.json.example local.settings.json
    log_success "local.settings.json created. Please update the Application Insights connection string if needed."
else
    log_info "local.settings.json already exists"
fi

log_success "Setup complete!"
echo
echo "🎉 You can now run:"
echo "  dotnet run"
echo
echo "The web app will be available at:"
echo "  - http://localhost:5000/api/v1/hello"
echo "  - http://localhost:5000/api/v1/random"
echo "  - http://localhost:5000/api/v1/error"
echo "  - http://localhost:5000/swagger (Swagger UI)" 