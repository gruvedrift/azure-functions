# ========================================================
# Event Grid Subscriptions
# Note: These connect Event Grid to Function App webhooks
# ========================================================

# Subscription: Item needs review -> Admin notification
# resource "azurerm_eventgrid_event_subscription" "item_needs_review" {
#   name  = "item-needs-review-notification"
#   scope = azurerm_eventgrid_topic.item_inventory_events.id
#
#   included_event_types = ["Inventory.ItemNeedsReview"]
# }
#
