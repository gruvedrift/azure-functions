# ========================================================
# Event Grid Subscriptions
# Note: These connect Event Grid to Function App webhooks
# ========================================================

# Subscription: Item needs review -> Admin Notification Function
resource "azurerm_eventgrid_event_subscription" "item_needs_review" {
  name                 = "item-needs-review-notification"
  scope                = azurerm_eventgrid_topic.item_inventory_events.id
  included_event_types = ["Inventory.ItemNeedsReview"]

  event_delivery_schema = "CloudEventSchemaV1_0" # Adhere to EventGrid event type

  # Route to Azure Function through webhook.
  # This is a direct URL -> to the running function within the Function Application.
  webhook_endpoint {
    url = "https://${azurerm_linux_function_app.functions-app.default_hostname}/runtime/webhooks/eventgrid?functionName=SendAdminNotification"
  }
  depends_on = [azurerm_linux_function_app.functions-app]
}

# TODO create a two step deployment script so that azure functions are published BEFORE we create the event grid subscription!
