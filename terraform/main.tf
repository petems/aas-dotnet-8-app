terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Merge tags
locals {
  common_tags = merge(var.tags, var.additional_tags)
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.app_insights_name}-workspace"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  tags                = local.common_tags
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
  tags                = local.common_tags
}

# Web App
resource "azurerm_linux_web_app" "main" {
  name                    = var.web_app_name
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  service_plan_id         = azurerm_service_plan.main.id
  client_affinity_enabled = false
  tags                    = local.common_tags

  site_config {
    application_stack {
      dotnet_version = var.dotnet_version
    }

    always_on                         = true
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    ip_restriction_default_action     = "Allow"
    scm_ip_restriction_default_action = "Allow"
  }

  # Application logging configuration
  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 30
        retention_in_mb   = 35
      }
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
    "DOTNET_ENVIRONMENT"                    = var.environment
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "XDT_MicrosoftApplicationInsights_Mode" = "Recommended"
    "WEBSITE_ENABLE_APP_LOGS"               = "true"
    "WEBSITE_ENABLE_DETAILED_ERROR_LOGGING" = "true"
    "WEBSITE_ENABLE_FAILED_REQUEST_TRACING" = "true"
  }
}



# Diagnostic Settings for App Service
resource "azurerm_monitor_diagnostic_setting" "web_app" {
  name                       = "${var.web_app_name}-diagnostics"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Alert Rule for HTTP 5xx errors
resource "azurerm_monitor_activity_log_alert" "http_5xx" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.web_app_name}-http-5xx-alert"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes               = [azurerm_linux_web_app.main.id]
  description          = "Alert when HTTP 5xx errors occur"

  criteria {
    resource_id    = azurerm_linux_web_app.main.id
    operation_name = "Microsoft.Web/sites/Write"
    category       = "Administrative"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.web_app_name}-action-group"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "webapp-alert"
  tags                = local.common_tags

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name                    = "email-${email_receiver.key}"
      email_address          = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# Metric Alert for Memory usage
resource "azurerm_monitor_metric_alert" "memory_usage" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.web_app_name}-memory-usage-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes               = [azurerm_linux_web_app.main.id]
  description          = "Alert when memory usage is high"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "MemoryWorkingSet"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000000000  # 1GB in bytes
  }

  window_size        = "PT15M"
  frequency          = "PT5M"

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }
}

 