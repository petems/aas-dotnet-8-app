# Terraform Deployment for Azure App Service

This directory contains Terraform configuration files for deploying the Azure App Service infrastructure as code.

## Prerequisites

1. **Terraform** (>= 1.0) - [Download here](https://www.terraform.io/downloads)
2. **Azure CLI** - [Install here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **Azure Subscription** - Active Azure subscription
4. **Azure CLI Authentication** - Run `az login` to authenticate

## Quick Start

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your desired values:

```hcl
resource_group_name = "my-app-rg"
location            = "East US"
web_app_name        = "my-unique-app-name"  # Must be globally unique
app_insights_name   = "my-app-insights"
service_plan_name   = "my-app-plan"
```

### 2. Deploy Infrastructure

Use the deployment script for a complete deployment:

```bash
# Deploy infrastructure and code
./scripts/deploy-terraform.sh --web-app-name my-unique-app-name

# Deploy infrastructure only
./scripts/deploy-terraform.sh --infrastructure-only --web-app-name my-unique-app-name

# Deploy code only (after infrastructure exists)
./scripts/deploy-terraform.sh --code-only
```

### 3. Manual Terraform Commands

Alternatively, you can run Terraform commands manually:

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# View outputs
terraform output
```

## Configuration Options

### Service Plan SKUs

Available SKUs for the App Service Plan:

- **Free**: `F1` (shared, limited features)
- **Basic**: `B1`, `B2`, `B3` (dedicated, good for development)
- **Standard**: `S1`, `S2`, `S3` (production workloads)
- **Premium**: `P1V2`, `P2V2`, `P3V2` (high-performance)

### Environments

Supported environment values:

- `Development` - Development environment
- `Staging` - Staging environment  
- `Production` - Production environment

### .NET Versions

Currently supports:
- `8.0` - .NET 8 (recommended)

## File Structure

```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── terraform.tfvars.example  # Example variables file
└── README.md            # This file
```

## Resources Created

The Terraform configuration creates the following Azure resources:

1. **Resource Group** - Container for all resources
2. **Application Insights** - Monitoring and telemetry
3. **App Service Plan** - Hosting plan for the web app
4. **Linux Web App** - The actual web application

## Outputs

After deployment, Terraform provides these outputs:

- `web_app_url` - Main application URL
- `swagger_url` - Swagger UI URL
- `api_endpoints` - All API endpoint URLs
- `app_insights_connection_string` - Application Insights connection string
- `deployment_info` - Information for deployment scripts

## Security

### Sensitive Data

The following outputs are marked as sensitive:
- Application Insights connection string
- Application Insights instrumentation key

### State Management

Terraform state files contain sensitive information and should be:
- Stored securely (consider using Azure Storage backend)
- Never committed to version control
- Backed up regularly

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

**Warning**: This will permanently delete all resources and data.

## Troubleshooting

### Common Issues

1. **Name Conflicts**: Web app names must be globally unique
2. **Authentication**: Ensure `az login` completed successfully
3. **Permissions**: Verify your Azure account has sufficient permissions
4. **State Lock**: If deployment fails, check for state locks

### Getting Help

- Check Terraform logs: `terraform plan -detailed-exitcode`
- Verify Azure CLI: `az account show`
- Check resource status: `az webapp list --resource-group <rg-name>`

## Integration with Scripts

The Terraform deployment integrates with existing scripts:

- **Code Deployment**: Uses `scripts/deploy-code.sh`
- **Testing**: Use `scripts/test-endpoints.sh` after deployment
- **Monitoring**: Application Insights automatically configured

## Best Practices

1. **Use Variables**: Always customize `terraform.tfvars` for your environment
2. **Tag Resources**: Add meaningful tags for cost tracking and organization
3. **State Management**: Consider using remote state storage for team environments
4. **Version Control**: Keep Terraform configurations in version control
5. **Testing**: Test deployments in non-production environments first 