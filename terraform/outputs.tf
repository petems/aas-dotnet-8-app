# Resource information outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "web_app_name" {
  description = "Name of the web app"
  value       = azurerm_linux_web_app.main.name
}

output "app_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

# URL outputs
output "web_app_url" {
  description = "URL of the web app"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "swagger_url" {
  description = "URL of the Swagger UI"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}/swagger"
}

output "index_url" {
  description = "URL of the index page"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}/"
}

# API endpoint outputs
output "api_endpoints" {
  description = "API endpoint URLs"
  value = {
    hello  = "https://${azurerm_linux_web_app.main.default_hostname}/api/v1/hello"
    random = "https://${azurerm_linux_web_app.main.default_hostname}/api/v1/random"
    error  = "https://${azurerm_linux_web_app.main.default_hostname}/api/v1/error"
  }
}

# Application Insights outputs
output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

# Deployment information
output "deployment_info" {
  description = "Deployment information for scripts"
  value = {
    resource_group = azurerm_resource_group.main.name
    web_app_name   = azurerm_linux_web_app.main.name
    location       = azurerm_resource_group.main.location
    environment    = var.environment
  }
} 