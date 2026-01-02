# ========================================================
# Event Grid Subscriptions
# Note: These connect Event Grid to Function App webhooks
# ========================================================

# Get the Event Grid system key from Function App
data "azurerm_function_app_host_keys" "functions_keys" {
  name                = azurerm_linux_function_app.functions-app.name
  resource_group_name = azurerm_resource_group.functions-group.name
}

# Subscription 1: ItemNeedsReview -> Admin Notification Function
resource "azurerm_eventgrid_event_subscription" "item_needs_review" {
  name                 = "item-needs-review-notification"
  scope                = azurerm_eventgrid_topic.item_inventory_events.id
  included_event_types = ["Inventory.ItemNeedsReview"]

  event_delivery_schema = "CloudEventSchemaV1_0" # Adhere to EventGrid event type

  # Route to Azure Function through webhook.
  # This is a direct URL -> to the running function within the Function Application.
  # Must also provide the System Key for authenticated connection!
  webhook_endpoint {
    url = "https://${azurerm_linux_function_app.functions-app.name}.azurewebsites.net/runtime/webhooks/EventGrid?functionName=SendAdminNotification&code=${data.azurerm_function_app_host_keys.functions_keys.event_grid_extension_config_key}"
  }
  depends_on = [azurerm_linux_function_app.functions-app]
}


# Subscription 2: ItemApproved -> Store Catalog
resource "azurerm_eventgrid_event_subscription" "item_approved_store_catalog" {
  name                 = "item-approved-catalog-update"
  scope                = azurerm_eventgrid_topic.item_inventory_events.id
  included_event_types = ["Inventory.ItemApproved"]

  event_delivery_schema = "CloudEventSchemaV1_0" # Adhere to EventGrid event type
  webhook_endpoint {
    url = "https://${azurerm_linux_function_app.functions-app.name}.azurewebsites.net/runtime/webhooks/EventGrid?functionName=UpdateStoreCatalog&code=${data.azurerm_function_app_host_keys.functions_keys.event_grid_extension_config_key}"
  }
  depends_on = [azurerm_linux_function_app.functions-app]
}

# Subscription 3: ItemApproved -> Price History
resource "azurerm_eventgrid_event_subscription" "item_approved_price_history" {
  name                 = "item-approved-price-history"
  scope                = azurerm_eventgrid_topic.item_inventory_events.id
  included_event_types = ["Inventory.itemApproved"]

  event_delivery_schema = "CloudEventSchemaV1_0" # Adhere to EventGrid event type
  webhook_endpoint {
    url = "https://${azurerm_linux_function_app.functions-app.name}.azurewebsites.net/runtime/webhooks/EventGrid?functionName=RecordPriceHistory&code=${data.azurerm_function_app_host_keys.functions_keys.event_grid_extension_config_key}"
  }
  depends_on = [azurerm_linux_function_app.functions-app]
}
