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

echo "🔧 Setting up Azure Functions .NET 8 App for local development"
echo "=============================================================="
echo

# Check if .NET 8 is installed
if ! command -v dotnet &> /dev/null; then
    log_warning ".NET 8 SDK not found. Please install it from: https://dotnet.microsoft.com/download/dotnet/8.0"
    exit 1
fi

# Check .NET version
DOTNET_VERSION=$(dotnet --version)
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

# Check if Azure Functions Core Tools is installed
if ! command -v func &> /dev/null; then
    log_warning "Azure Functions Core Tools not found."
    echo "Please install it using one of these methods:"
    echo "  - npm: npm install -g azure-functions-core-tools@4 --unsafe-perm true"
    echo "  - Homebrew (macOS): brew tap azure/functions && brew install azure-functions-core-tools@4"
    echo "  - Windows: Download from https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools"
    echo
    echo "After installation, you can run: func start"
else
    log_success "Azure Functions Core Tools found"
    echo
    echo "🎉 Setup complete! You can now run:"
    echo "  func start"
    echo
    echo "The function app will be available at:"
    echo "  - http://localhost:7071/api/hello"
    echo "  - http://localhost:7071/api/random"
    echo "  - http://localhost:7071/api/error"
fi 