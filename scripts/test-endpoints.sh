#!/bin/bash

# Test Endpoints Script
# This script tests the deployed Azure App Service web app endpoints

set -e

# Configuration
WEB_APP_NAME=${1:-"aas-dotnet-8-webapp"}
BASE_URL="https://$WEB_APP_NAME.azurewebsites.net"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test function
test_endpoint() {
    local endpoint=$1
    local expected_pattern=$2
    local description=$3
    
    log_info "Testing $description..."
    
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        if [[ "$body" =~ $expected_pattern ]]; then
            log_success "$description: OK (HTTP $http_code)"
            echo "  Response: $body"
        else
            log_warning "$description: Unexpected response (HTTP $http_code)"
            echo "  Response: $body"
        fi
    else
        log_error "$description: Failed (HTTP $http_code)"
        echo "  Response: $body"
    fi
    echo
}

# Main test function
main() {
    echo "🧪 Testing Azure App Service Web App Endpoints"
    echo "=============================================="
    echo "Web App: $WEB_APP_NAME"
    echo "Base URL: $BASE_URL"
    echo
    
    # Test hello endpoint
    test_endpoint "/api/v1/hello" "Welcome to Azure App Service!" "Hello endpoint"
    
    # Test random endpoint
    test_endpoint "/api/v1/random" "^[0-9]+$" "Random endpoint"
    
    # Test error endpoint (should return 500)
    log_info "Testing Error endpoint..."
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/v1/error" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "500" ]; then
        log_success "Error endpoint: OK (HTTP $http_code) - Exception thrown as expected"
    else
        log_warning "Error endpoint: Unexpected status (HTTP $http_code)"
    fi
    echo "  Response: $body"
    echo
    
    # Test Swagger UI
    log_info "Testing Swagger UI..."
    response=$(curl -s -L -w "\n%{http_code}" "$BASE_URL/swagger" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Swagger UI: OK (HTTP $http_code)"
    else
        log_warning "Swagger UI: Unexpected status (HTTP $http_code)"
    fi
    echo
    
    # Test Index Page
    log_info "Testing Index Page..."
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL/" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Index Page: OK (HTTP $http_code)"
    else
        log_warning "Index Page: Unexpected status (HTTP $http_code)"
    fi
    echo
    
    echo "✅ Endpoint testing completed!"
    echo
    echo "Next steps:"
    echo "1. Check Application Insights for telemetry data"
    echo "2. Monitor web app in Azure Portal"
    echo "3. Review logs for any issues"
    echo "4. Visit Swagger UI at: $BASE_URL/swagger"
}

# Check if web app name is provided
if [ -z "$1" ]; then
    log_warning "No web app name provided. Using default: $WEB_APP_NAME"
    echo "Usage: $0 <web-app-name>"
    echo
fi

main "$@" 