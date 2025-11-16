# Iteration 1:
output "function_app_name" {
  value = azurerm_linux_function_app.functions-apps.name
}
output "function_app_url" {
  value = "https://${azurerm_linux_function_app.functions-apps.default_hostname}"
}
output "resource_group_name" {
  value = azurerm_resource_group.functions-group.name
}
output "cosmos_database_name" {
  value = azurerm_cosmosdb_sql_database.bindings_cosmos_database.name
}
output "cosmos_container_name" {
  value = azurerm_cosmosdb_sql_container.hero_information_container.name
}
output "cosmos_db_connection_string" {
  sensitive = true # Hide from terminal
  value     = azurerm_cosmosdb_account.bindings_cosmos_account.primary_sql_connection_string
}

# Iteration 2:
output "storage_connection_string" {
  sensitive = true # Hide from terminal
  value     = azurerm_storage_account.functions-storage.primary_connection_string
}
output "blob_audit_archive_container_name" {
  value = azurerm_storage_container.hero_archive_audit.name
}

# Iteration 3 + 4:
output "servicebus_namespace_name" {
  value = azurerm_servicebus_namespace.functions-service-bus.name
}
output "servicebus_connection_string" {
  sensitive = true # Hide from terminal
  value     = azurerm_servicebus_namespace.functions-service-bus.default_primary_connection_string
}
output "analytics_queue_name" {
  value = azurerm_servicebus_queue.hero-analytics-queue.name
}
output "hero_statistics_table_name" {
  value = azurerm_storage_table.hero-statistics.name
}
