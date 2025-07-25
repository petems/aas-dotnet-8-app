#!/bin/bash

# Script to run shellcheck against all shell scripts in the scripts folder
# Exits with code 1 if any issues are found

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if shellcheck is installed
if ! command -v shellcheck >/dev/null 2>&1; then
    log_error "shellcheck is not installed. Please install it first:"
    echo "  macOS: brew install shellcheck"
    echo "  Ubuntu/Debian: sudo apt-get install shellcheck"
    echo "  CentOS/RHEL: sudo yum install shellcheck"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

log_info "Running shellcheck against all shell scripts..."

# Initialize exit code
EXIT_CODE=0
ISSUES_FOUND=0

# Find all shell scripts in the scripts directory
while IFS= read -r -d '' script; do
    log_info "Checking: $(basename "${script}")"
    
    # Run shellcheck and capture the exit code
    if ! shellcheck "${script}"; then
        log_error "Issues found in: $(basename "${script}")"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        EXIT_CODE=1
    fi
done < <(find "${SCRIPT_DIR}" -name "*.sh" -type f -print0)

# Check script permissions
log_info "Checking script permissions..."
PERMISSION_ISSUES=0

while IFS= read -r -d '' script; do
    if [ ! -x "${script}" ]; then
        log_warning "Script is not executable: $(basename "${script}")"
        PERMISSION_ISSUES=$((PERMISSION_ISSUES + 1))
        EXIT_CODE=1
    fi
done < <(find "${SCRIPT_DIR}" -name "*.sh" -type f -print0)

# Summary
echo
if [ "${ISSUES_FOUND}" -eq 0 ] && [ "${PERMISSION_ISSUES}" -eq 0 ]; then
    log_info "✅ All shell scripts passed validation!"
    log_info "No issues found in ${ISSUES_FOUND} scripts"
    log_info "All scripts are executable"
else
    log_error "❌ Shell script validation failed!"
    if [ "${ISSUES_FOUND}" -gt 0 ]; then
        log_error "Found issues in ${ISSUES_FOUND} script(s)"
    fi
    if [ "${PERMISSION_ISSUES}" -gt 0 ]; then
        log_error "Found ${PERMISSION_ISSUES} script(s) with permission issues"
    fi
fi

exit "${EXIT_CODE}" 
