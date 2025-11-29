# ============================================
# Input Variables
# ============================================

variable "subscription_id" {
  description = "Azure Subsciption ID"
  type        = string
  default     = "8f9aed58-aa08-45bd-960a-2c15d4449132"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "azure-functions-resource-group"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "North Europe" # EU west is overrun by traffic
}

variable "storage_account_prefix" {
  description = "Prefix for storage account"
  type        = string
  default     = "funcstorage"
}

variable "cosmos_account_prefix" {
  description = "Prefix for Cosmos DB account name"
  type        = string
  default     = "cosmosdb"
}

variable "event_grid_prefix" {
  description = "Prefix for the Event Grid"
  type        = string
  default     = "item-inventory-events-"
}

variable "function_app_name_prefix" {
  description = "Prefix for Function App name"
  type        = string
  default     = "linux-function-app"
}