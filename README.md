# Azure Functions .NET 8 App

A modern Azure Functions application built with .NET 8 and the isolated worker process model. This project demonstrates HTTP triggers with logging, error handling, and Application Insights integration.

## Features

- **.NET 8** with Azure Functions v4
- **Isolated Worker Process** model for better performance and flexibility
- **HTTP Triggers** with multiple endpoints
- **Application Insights** integration for monitoring and telemetry
- **Structured Logging** with Serilog-style formatting
- **Error Handling** with dedicated error endpoint for testing

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools)
- [Visual Studio Code](https://code.visualstudio.com/) (recommended) or Visual Studio

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
func start
```

The app will be available at:
- `http://localhost:7071/api/hello` - Welcome message
- `http://localhost:7071/api/random` - Random number generator
- `http://localhost:7071/api/error` - Error testing endpoint

### 3. Azure Deployment

Use the provided deployment script:

```bash
# Deploy to Azure (creates all resources)
./scripts/deploy.sh

# Test the deployed endpoints
./scripts/test-endpoints.sh <your-function-app-name>
```

Or follow the manual deployment steps in the [Deployment Guide](#deployment-guide).

## Project Structure

```
├── HttpTriggerFunction.cs    # HTTP trigger functions
├── Program.cs               # Application entry point
├── host.json               # Functions host configuration
├── local.settings.json     # Local development settings
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
| `/api/hello` | GET, POST | Returns a welcome message |
| `/api/random` | GET | Returns a random number (1-100) |
| `/api/error` | GET, POST | Throws an exception for testing |

## Configuration

### Environment Variables

- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Application Insights connection string
- `AzureWebJobsStorage` - Azure Storage connection string (auto-configured)

### Local Development

Copy `local.settings.json.example` to `local.settings.json` and update values:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "your-connection-string"
  }
}
```

## Deployment Guide

### Automated Deployment

The `scripts/deploy.sh` script handles the complete deployment process:

1. Azure resource group creation
2. Storage account setup
3. Application Insights creation
4. Function App deployment
5. Configuration updates

### Manual Deployment

If you prefer manual deployment, see the [Manual Deployment Steps](#manual-deployment-steps) section.

## Scripts

The project includes several helpful scripts:

### `scripts/setup-local.sh`
Quick setup for new users. Checks prerequisites, restores packages, builds the project, and creates local settings.

### `scripts/deploy.sh`
Complete Azure deployment script that:
- Creates resource group, storage account, and Application Insights
- Sets up Function App with proper configuration
- Deploys the application
- Provides deployment information and URLs

### `scripts/test-endpoints.sh`
Tests all deployed endpoints to verify they're working correctly.

## Development

### Adding New Functions

1. Create a new class in the project
2. Add the `[Function]` attribute with a unique name
3. Use the appropriate trigger attribute (e.g., `[HttpTrigger]`)
4. Register any dependencies in `Program.cs` if needed

### Testing

```bash
# Run tests (if you add them)
dotnet test

# Test locally
curl http://localhost:7071/api/hello
```

### Logging

The application uses structured logging with Application Insights integration. Log levels are configurable in `Program.cs`.

## Troubleshooting

### Common Issues

1. **Port conflicts**: Change the port in `host.json` or kill conflicting processes
2. **Storage emulator**: Ensure Azure Storage Emulator is running for local development
3. **Application Insights**: Verify connection string is correct

### Debug Mode

```bash
# Run with debug logging
func start --verbose
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally
4. Submit a pull request

## License

See [LICENSE](LICENSE) file for details. 