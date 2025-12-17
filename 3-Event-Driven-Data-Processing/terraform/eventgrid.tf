# =============================================================================
# Event Grid Topic
# Note: Event Grid Subscriptions will be created before the Function app
#       so we can reference the webhook endpoints within our Function config.
# =============================================================================

resource "azurerm_eventgrid_topic" "item_inventory_events" {
  name                = "${var.event_grid_prefix}${random_string.postfix.result}"
  location            = azurerm_resource_group.functions-group.location
  resource_group_name = azurerm_resource_group.functions-group.name

  input_schema = "CloudEventSchemaV1_0" # This is the modern standard for Events.

  tags = {
    Purpose = "Event routing for item inventory system"
  }
}
