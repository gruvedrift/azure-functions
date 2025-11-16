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

# Create random string for unique name postfix
resource "random_string" "postfix" {
  length  = 6
  upper   = false
  special = false
}

# Create Resource Group
resource "azurerm_resource_group" "functions-group" {
  location = "North Europe" # EU West is cooked
  name     = "azure-bindings-resource-group"
}

# Create Storage Account
resource "azurerm_storage_account" "functions-storage" {
  name                     = "funcstorage${random_string.postfix.result}"
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
  sku_name            = "Y1"
}

# Create Application Insights (for inspecting logs)
resource "azurerm_application_insights" "functions_insights" {
  name                = "function-insights-${random_string.postfix.result}"
  location            = azurerm_resource_group.functions-group.location
  resource_group_name = azurerm_resource_group.functions-group.name
  application_type    = "web"
}


# Create Azure Service Bus Namespace
resource "azurerm_servicebus_namespace" "functions-service-bus" {
  location            = azurerm_resource_group.functions-group.location
  name                = "sb-functions-${random_string.postfix.result}"
  resource_group_name = azurerm_resource_group.functions-group.name
  sku                 = "Standard"
}

# Create Azure Service Bus Queue
resource "azurerm_servicebus_queue" "hero-analytics-queue" {
  name         = "hero-analytics-queue"
  namespace_id = azurerm_servicebus_namespace.functions-service-bus.id

  # Retry configuration
  max_delivery_count                   = 10   # Try 10 times before dead lettered
  dead_lettering_on_message_expiration = true # Move expired messages to dead letter

  default_message_ttl = "P1D" # Messages expire after 1 Day
}

# Create Table storage for Hero Statistics
resource "azurerm_storage_table" "hero-statistics" {
  name                 = "HeroQueryStatistics"
  storage_account_name = azurerm_storage_account.functions-storage.name
}


# Create Function App
resource "azurerm_linux_function_app" "functions-apps" {
  name                       = "linux-function-app-${random_string.postfix.result}"
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
    "CosmosDBConnectionString"              = azurerm_cosmosdb_account.bindings_cosmos_account.primary_sql_connection_string
    "AzureWebJobsStorage"                   = azurerm_storage_account.functions-storage.primary_connection_string

    # Service Bus connection
    "ServiceBusConnection" = azurerm_servicebus_namespace.functions-service-bus.default_primary_connection_string

  }
}


# Cosmos DB account (top level)
resource "azurerm_cosmosdb_account" "bindings_cosmos_account" {
  location            = azurerm_resource_group.functions-group.location
  name                = "cosmosdb-${random_string.postfix.result}"
  offer_type          = "Standard"
  resource_group_name = azurerm_resource_group.functions-group.name
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    failover_priority = 0
    location          = azurerm_resource_group.functions-group.location
    zone_redundant    = false
  }

  capabilities {
    name = "EnableServerless"
  }

  backup {
    type                = "Periodic"
    storage_redundancy  = "Zone"
    interval_in_minutes = 240
    retention_in_hours  = 8
  }

  free_tier_enabled = true

}

# Database within the account
resource "azurerm_cosmosdb_sql_database" "bindings_cosmos_database" {
  name                = "herodb"
  account_name        = azurerm_cosmosdb_account.bindings_cosmos_account.name
  resource_group_name = azurerm_resource_group.functions-group.name
}

# Container within the database (this is where data is stored)
resource "azurerm_cosmosdb_sql_container" "hero_information_container" {
  name                = "hero-information"
  resource_group_name = azurerm_resource_group.functions-group.name
  account_name        = azurerm_cosmosdb_account.bindings_cosmos_account.name
  database_name       = azurerm_cosmosdb_sql_database.bindings_cosmos_database.name
  partition_key_paths = ["/heroId"] # MUST HAVE: Partition key!!

  indexing_policy {
    indexing_mode = "consistent"
  }
}

# Blob Storage Container for Audit Trail
resource "azurerm_storage_container" "hero_archive_audit" {
  name                  = "hero-archive-audit"
  storage_account_id    = azurerm_storage_account.functions-storage.id
  container_access_type = "private" # not accessible for public, only used internally
}

