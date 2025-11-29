# ==================================================================
# Event Grid Topic
# Note: Event Grid Subscriptions will be created after Function app.
#       so we can reference the webhook endpoints
# ==================================================================

resource "azurerm_eventgrid_topic" "item_inventory_events" {
  resource_group_name = azurerm_resource_group.functions-group.name
  location            = azurerm_resource_group.functions-group.location
  name                = "${var.event_grid_prefix}${random_string.postfix.result}"
}