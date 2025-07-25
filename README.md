# Azure App Service .NET 8 Web App

A modern ASP.NET Core web application built with .NET 8 and deployed to Azure App Service. This project demonstrates REST API endpoints with logging, error handling, and Application Insights integration.

## Features

- **.NET 8** with ASP.NET Core
- **REST API** with multiple endpoints
- **Swagger/OpenAPI** documentation
- **Application Insights** integration for monitoring and telemetry
- **Structured Logging** with Serilog-style formatting
- **Error Handling** with dedicated error endpoint for testing

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Visual Studio Code](https://code.visualstudio.com/) (recommended) or Visual Studio

**Note**: This project is pinned to .NET 8 using `global.json`. Even if you have .NET 9 installed, the project will use .NET 8.

## Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd aas-dotnet-8-app
```

### 2. Local Development

```bash
# Quick setup for new users
./scripts/setup-local.sh

# Or manually:
# Install dependencies
dotnet restore

# Run locally
dotnet run
```

The app will be available at:
- `http://localhost:5000/` - Home page with API documentation
- `http://localhost:5000/api/v1/hello` - Welcome message
- `http://localhost:5000/api/v1/random` - Random number generator
- `http://localhost:5000/api/v1/error` - Error testing endpoint
- `http://localhost:5000/swagger` - Swagger UI documentation

### 3. Azure Deployment

You have several deployment options:

#### Option A: Complete Deployment (Resources + Code)
```bash
# Deploy to Azure (creates all resources and deploys code)
./scripts/deploy.sh
```

#### Option B: Create Resources Only
```bash
# Create Azure resources only
./scripts/create-azure-resources.sh
```

#### Option C: Deploy Code Only (to existing web app)
```bash
# Deploy code to existing web app
./scripts/deploy-code.sh <your-web-app-name>

# Or if you have azure-resources.json from create-azure-resources.sh:
./scripts/deploy-code.sh
```

**⏱️ Deployment Times:**
- **Initial deployment**: ~5 minutes (includes infrastructure setup)
- **Code updates**: ~2 minutes (infrastructure already exists)

#### Test the deployed endpoints
```bash
./scripts/test-endpoints.sh <your-web-app-name>
```

Or follow the manual deployment steps in the [Deployment Guide](#deployment-guide).

## Project Structure

```
├── Controllers/
│   └── ApiController.cs    # REST API controller
├── Program.cs             # Application entry point
├── appsettings.json       # Application configuration
├── appsettings.Development.json  # Development settings
├── local.settings.json.example  # Example settings template
├── scripts/
│   ├── deploy.sh          # Azure deployment script
│   ├── setup-local.sh     # Local development setup
│   └── test-endpoints.sh  # Endpoint testing script
└── README.md              # This file
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Home page with API documentation |
| `/api/v1/hello` | GET, POST | Returns a welcome message |
| `/api/v1/random` | GET | Returns a random number (1-100) |
| `/api/v1/error` | GET | Throws an exception for testing |
| `/swagger` | GET | Swagger UI documentation |

## Configuration

### Environment Variables

- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Application Insights connection string

### Local Development

Copy `local.settings.json.example` to `local.settings.json` and update values:

```json
{
  "IsEncrypted": false,
  "Values": {
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "your-connection-string"
  }
}
```

## Deployment Guide

### Automated Deployment

The `scripts/deploy.sh` script handles the complete deployment process:

1. Azure resource group creation
2. Application Insights creation
3. App Service Plan setup
4. Web App deployment
5. Configuration updates

### Manual Deployment

If you prefer manual deployment, see the [Manual Deployment Steps](#manual-deployment-steps) section.

## Scripts

The project includes several helpful scripts:

### `scripts/setup-local.sh`
Quick setup for new users. Checks prerequisites, restores packages, builds the project, and creates local settings.

### `scripts/deploy.sh`
Complete deployment wrapper that runs both resource creation and code deployment.

### `scripts/create-azure-resources.sh`
Creates Azure resources only:
- Resource group
- Application Insights
- App Service Plan
- Web App with proper configuration
- Saves resource information to `azure-resources.json`

### `scripts/deploy-code.sh`
Deploys application code to existing web app:
- Builds and publishes the application
- Creates deployment package
- Deploys to Azure using the modern `az webapp deploy` command
- Cleans up temporary files
- Can read web app name from `azure-resources.json` or accept as parameter

### `scripts/test-endpoints.sh`
Tests all deployed endpoints to verify they're working correctly.

## Development

### Adding New Endpoints

1. Add new actions to the `ApiController` class
2. Use appropriate HTTP method attributes (e.g., `[HttpGet]`, `[HttpPost]`)
3. Add any dependencies to the DI container in `Program.cs` if needed

### Testing

```bash
# Run tests (if you add them)
dotnet test

# Test locally
curl http://localhost:5000/api/v1/hello
```

### Logging

The application uses structured logging with Application Insights integration. Log levels are configurable in `appsettings.json`.

## Troubleshooting

### Common Issues

1. **Port conflicts**: Change the port in `launchSettings.json` or kill conflicting processes
2. **Application Insights**: Verify connection string is correct

### Debug Mode

```bash
# Run with debug logging
dotnet run --environment Development
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally
4. Submit a pull request

## License

See [LICENSE](LICENSE) file for details. 