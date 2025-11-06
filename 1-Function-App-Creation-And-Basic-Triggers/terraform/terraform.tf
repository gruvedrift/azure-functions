terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.49.0"
    }
  }
}

# Configure azure rm provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "8f9aed58-aa08-45bd-960a-2c15d4449132"
}

# Random string resource, names must be unique for Storage Account
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Create Resource Group
resource "azurerm_resource_group" "functions-group" {
  location = "West Europe"
  name     = "azure-functions-resource-group"
}

# Create Storage Account ( needed for all Function Apps )
resource "azurerm_storage_account" "functions-storage" {
  name                     = "funcstorage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.functions-group.name
  location                 = azurerm_resource_group.functions-group.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Local Redundant Storage
}

# Create Service Plan
resource "azurerm_service_plan" "functions-plan" {
  name                = "functions-service-plan"
  location            = azurerm_resource_group.functions-group.location
  resource_group_name = azurerm_resource_group.functions-group.name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

# Add Application Insights
resource "azurerm_application_insights" "functions_insights" {
  name                = "func-insights-${random_string.suffix.result}"
  location            = azurerm_resource_group.functions-group.location
  resource_group_name = azurerm_resource_group.functions-group.name
  application_type    = "web"
}

# Create Function App (this is the container which holds our azure functions)
resource "azurerm_linux_function_app" "functions-apps" {
  name                       = "linux-function-app-${random_string.suffix.result}"
  location                   = azurerm_resource_group.functions-group.location
  resource_group_name        = azurerm_resource_group.functions-group.name
  service_plan_id            = azurerm_service_plan.functions-plan.id
  storage_account_name       = azurerm_storage_account.functions-storage.name
  storage_account_access_key = azurerm_storage_account.functions-storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
  # Enable Application Insights integration
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.functions_insights.connection_string
  }
}
