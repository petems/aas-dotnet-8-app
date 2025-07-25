#!/bin/bash

# Test Endpoints Script
# This script tests the deployed Azure Functions endpoints

set -e

# Configuration
FUNCTION_APP_NAME=${1:-"aas-dotnet-8-functions"}
BASE_URL="https://$FUNCTION_APP_NAME.azurewebsites.net"

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
    body=$(echo "$response" | head -n -1)
    
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
    echo "🧪 Testing Azure Functions Endpoints"
    echo "===================================="
    echo "Function App: $FUNCTION_APP_NAME"
    echo "Base URL: $BASE_URL"
    echo
    
    # Test hello endpoint
    test_endpoint "/api/hello" "Welcome to Azure Functions Worker!" "Hello endpoint"
    
    # Test random endpoint
    test_endpoint "/api/random" "^[0-9]+$" "Random endpoint"
    
    # Test error endpoint (should return 500)
    log_info "Testing Error endpoint..."
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/error" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "500" ]; then
        log_success "Error endpoint: OK (HTTP $http_code) - Exception thrown as expected"
    else
        log_warning "Error endpoint: Unexpected status (HTTP $http_code)"
    fi
    echo "  Response: $body"
    echo
    
    echo "✅ Endpoint testing completed!"
    echo
    echo "Next steps:"
    echo "1. Check Application Insights for telemetry data"
    echo "2. Monitor function execution in Azure Portal"
    echo "3. Review logs for any issues"
}

# Check if function app name is provided
if [ -z "$1" ]; then
    log_warning "No function app name provided. Using default: $FUNCTION_APP_NAME"
    echo "Usage: $0 <function-app-name>"
    echo
fi

main "$@" 