output "cosmos_db_connection_string" {
  sensitive   = true
  description = "Connection string for read / write to cosmos DB document database"
  value       = azurerm_cosmosdb_account.bindings_cosmos_account.primary_sql_connection_string
}

output "storage_connection_string" {
  sensitive   = true
  description = "Connection string for function trigger on image upload to blob storage"
  value       = azurerm_storage_account.functions-storage.primary_connection_string
}

output "storage_account_name" {
  sensitive   = false
  description = "Azure storage account name, used for Azure CLI to upload images"
  value       = azurerm_storage_account.functions-storage.name
}

# Event grid related outputs, used for local testing
output "eventgrid_topic_endpoint" {
  sensitive   = false
  description = "Webhook endpoint on which to publish events"
  value       = azurerm_eventgrid_topic.item_inventory_events.endpoint
}

output "eventgrid_topic_key" {
  sensitive   = true
  description = "Access key for pushing topics to Event Grid"
  value       = azurerm_eventgrid_topic.item_inventory_events.primary_access_key
}

