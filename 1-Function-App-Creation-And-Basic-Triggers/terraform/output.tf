output "function_app_name" {
  value = azurerm_linux_function_app.functions-apps.name
}

output "function_app_url" {
  value = "https://${azurerm_linux_function_app.functions-apps.default_hostname}"
}

output "resource_group_name" {
  value = azurerm_resource_group.functions-group.name
}
