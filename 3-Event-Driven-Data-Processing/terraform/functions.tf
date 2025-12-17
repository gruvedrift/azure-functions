# ============================================
# Application Insights
# ============================================

resource "azurerm_application_insights" "functions_insights" {
  name                = "function-insights-${random_string.postfix.result}"
  location            = azurerm_resource_group.functions-group.location
  resource_group_name = azurerm_resource_group.functions-group.name
  application_type    = "web"
}

# ============================================
# App Service Plan (Linux)
# ============================================

resource "azurerm_service_plan" "functions_service_plan" {
  name                = "functions-service-plan-${random_string.postfix.result}"
  location            = azurerm_resource_group.functions-group.location
  resource_group_name = azurerm_resource_group.functions-group.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# ============================================
# Function App
# ============================================

# Function App to host the Azure Functions
resource "azurerm_linux_function_app" "functions-app" {
  name                       = "linux-function-app-${random_string.postfix.result}"
  location                   = azurerm_resource_group.functions-group.location
  resource_group_name        = azurerm_resource_group.functions-group.name
  service_plan_id            = azurerm_service_plan.functions_service_plan.id
  storage_account_name       = azurerm_storage_account.functions-storage.name
  storage_account_access_key = azurerm_storage_account.functions-storage.primary_access_key


  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.functions_insights.connection_string

    # Storage and CosmosDB
    "AzureWebJobsStorage"      = azurerm_storage_account.functions-storage.primary_connection_string
    "CosmosDBConnectionString" = azurerm_cosmosdb_account.bindings_cosmos_account.primary_sql_connection_string

    # Event Grid Configuration
    "EventGridTopicEndpoint" = azurerm_eventgrid_topic.item_inventory_events.endpoint
    "EventGridTopicKey"      = azurerm_eventgrid_topic.item_inventory_events.primary_access_key
  }
}
