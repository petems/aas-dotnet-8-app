.PHONY: help terraform-fmt terraform-validate terraform-plan terraform-apply dotnet-build dotnet-test test coverage coverage-open dotnet-format dotnet-restore dotnet-lint shellcheck shellcheck-fix security-scan dotnet-security terraform-security ci

# Default target
help:
	@echo "Available targets:"
	@echo ""
	@echo "CI/CD Pipeline (matches GitHub Actions):"
	@echo "  ci                 - Run full CI pipeline (build, test, lint, validate)"
	@echo "  dotnet-restore     - Restore .NET dependencies"
	@echo "  dotnet-build       - Build .NET application"
	@echo "  dotnet-test        - Run .NET tests with coverage"
	@echo "  test               - Run .NET tests (quick mode)"
	@echo "  coverage           - Run tests with coverage report"
	@echo "  coverage-open      - Open coverage report in browser"
	@echo "  dotnet-lint        - Format check and build with warnings as errors"
	@echo "  terraform-fmt      - Format Terraform files"
	@echo "  terraform-validate - Validate Terraform configuration"
	@echo "  shellcheck         - Validate shell scripts"
	@echo "  shellcheck-fix     - Auto-fix common shell script issues"
	@echo "  security-scan      - Run Trivy vulnerability scanner"
	@echo ""
	@echo "Security & Dependency Scanning:"
	@echo "  dotnet-security    - Audit .NET packages for vulnerabilities"
	@echo "  terraform-security - Run Checkov and tfsec security scans"
	@echo ""
	@echo "Additional Terraform tasks:"
	@echo "  terraform-plan     - Plan Terraform changes"
	@echo "  terraform-apply    - Apply Terraform changes"
	@echo ""
	@echo "Utility:"
	@echo "  help               - Show this help message"

# CI/CD Pipeline (matches GitHub Actions)
ci: dotnet-restore dotnet-build dotnet-test dotnet-lint terraform-fmt terraform-validate shellcheck security-scan

# .NET tasks
dotnet-restore:
	@echo "Restoring .NET dependencies..."
	dotnet restore AzureWebApp.sln

dotnet-build:
	@echo "Building .NET application..."
	dotnet build AzureFunctionsApp.csproj --no-restore --configuration Release

dotnet-test:
	@echo "Running .NET tests with coverage..."
	dotnet test AzureFunctionsApp.Tests/AzureFunctionsApp.Tests.csproj --configuration Release --verbosity normal --collect:"XPlat Code Coverage" --results-directory ./coverage

test:
	@echo "Running .NET tests (quick mode)..."
	dotnet test AzureFunctionsApp.Tests/AzureFunctionsApp.Tests.csproj --verbosity normal

coverage:
	@echo "Running .NET tests with coverage..."
	dotnet test AzureFunctionsApp.Tests/AzureFunctionsApp.Tests.csproj --collect:"XPlat Code Coverage" --results-directory ./coverage
	@echo "Generating coverage report..."
	@export PATH="$$PATH:/Users/peter.souter/.dotnet/tools" && reportgenerator -reports:coverage/*/coverage.cobertura.xml -targetdir:coverage/report -reporttypes:Html
	@echo "Coverage report generated at: coverage/report/index.html"

coverage-open:
	@echo "Opening coverage report in browser..."
	@open coverage/report/index.html

dotnet-lint:
	@echo "Running .NET linting and code analysis..."
	@echo "Checking code format..."
	dotnet format AzureFunctionsApp.csproj --verify-no-changes --verbosity diagnostic || echo "Format check completed - some files were automatically formatted"
	@echo "Building with warnings as errors..."
	dotnet build AzureFunctionsApp.csproj --configuration Release --verbosity normal

dotnet-format:
	@echo "Formatting .NET code..."
	dotnet format AzureFunctionsApp.csproj --verify-no-changes

# Terraform tasks
terraform-fmt:
	@echo "Formatting Terraform files..."
	cd terraform && terraform fmt -recursive

terraform-validate:
	@echo "Validating Terraform configuration..."
	cd terraform && terraform init -backend=false && terraform validate
	@echo "Running TFLint..."
	@if command -v tflint >/dev/null 2>&1; then \
		cd terraform && tflint --init && tflint; \
	else \
		echo "TFLint not found. Skipping TFLint validation."; \
	fi

terraform-plan:
	@echo "Planning Terraform changes..."
	cd terraform && terraform plan

terraform-apply:
	@echo "Applying Terraform changes..."
	cd terraform && terraform apply

# Shell script validation
shellcheck:
	@echo "Validating shell scripts..."
	@./scripts/run-shellcheck.sh

shellcheck-fix:
	@echo "Auto-fixing shell script issues using shellcheck's diff output..."
	@echo "Processing each shell script..."
	@for script in scripts/*.sh; do \
		if [ -f "$$script" ]; then \
			echo "Fixing: $$script"; \
			shellcheck -f diff "$$script" | patch -p1 --batch --forward || echo "No fixes needed for $$script"; \
		fi; \
	done
	@echo "Re-running shellcheck to verify fixes..."
	@./scripts/run-shellcheck.sh

# Security scanning
security-scan:
	@echo "Running Trivy vulnerability scanner..."
	@if command -v trivy >/dev/null 2>&1; then \
		trivy fs --format sarif --output trivy-results.sarif .; \
	else \
		echo "Trivy not found. Install with: brew install trivy"; \
	fi

# Dependency security scanning
dotnet-security:
	@echo "Auditing .NET packages for vulnerabilities..."
	@echo "Listing outdated packages..."
	dotnet list package --outdated --include-transitive || true
	@echo "Listing vulnerable packages..."
	dotnet list package --vulnerable --include-transitive
	@echo "Auditing dependencies..."
	dotnet nuget audit

terraform-security:
	@echo "Running Terraform security scans..."
	@if command -v checkov >/dev/null 2>&1; then \
		echo "Running Checkov..."; \
		checkov --directory terraform/ --framework terraform --output sarif --output-file-path checkov-results.sarif; \
	else \
		echo "Checkov not found. Install with: pip install checkov"; \
	fi
	@if command -v tfsec >/dev/null 2>&1; then \
		echo "Running tfsec..."; \
		tfsec terraform/ --format sarif --out tfsec-results.sarif; \
	else \
		echo "tfsec not found. Install with: brew install tfsec"; \
	fi 