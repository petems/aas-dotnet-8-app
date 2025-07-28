# Resource naming variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aas-dotnet-8-webapp-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US 2"
}

variable "web_app_name" {
  description = "Name of the web app (must be globally unique)"
  type        = string
  default     = "aas-dotnet-8-webapp"
}

variable "app_insights_name" {
  description = "Name of Application Insights"
  type        = string
  default     = "aas-dotnet-8-insights"
}

variable "service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "aas-dotnet-8-plan"
}

# Configuration variables
variable "dotnet_version" {
  description = ".NET version to use"
  type        = string
  default     = "8.0"
}

variable "service_plan_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"

  validation {
    condition     = contains(["F1", "B1", "B2", "B3", "S1", "S2", "S3", "P1V2", "P2V2", "P3V2"], var.service_plan_sku)
    error_message = "Service plan SKU must be one of: F1, B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Production"

  validation {
    condition     = contains(["Development", "Staging", "Production"], var.environment)
    error_message = "Environment must be one of: Development, Staging, Production."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "AAS-DotNet-8-App"
    ManagedBy   = "Terraform"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Monitoring and alerting variables
variable "enable_alerts" {
  description = "Enable monitoring alerts"
  type        = bool
  default     = true
}

variable "alert_email_addresses" {
  description = "Email addresses to send alerts to"
  type        = list(string)
  default     = []
}