# ============================================
# Cosmos DB Account
# ============================================

# Cosmos DB account (top level)
resource "azurerm_cosmosdb_account" "bindings_cosmos_account" {
  name                = "${var.cosmos_account_prefix}${random_string.postfix.result}"
  location            = azurerm_resource_group.functions-group.location
  resource_group_name = azurerm_resource_group.functions-group.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    failover_priority = 0
    location          = azurerm_resource_group.functions-group.location
    zone_redundant    = false
  }

  capabilities {
    name = "EnableServerless"
  }

  backup {
    type                = "Periodic"
    storage_redundancy  = "Zone"
    interval_in_minutes = 240
    retention_in_hours  = 8
  }

  free_tier_enabled = true
}

# ============================================
# Database: Inventory
# ============================================

# Database within the account
resource "azurerm_cosmosdb_sql_database" "inventory_db" {
  name                = "inventorydb"
  resource_group_name = azurerm_resource_group.functions-group.name
  account_name        = azurerm_cosmosdb_account.bindings_cosmos_account.name
}

# Items container
resource "azurerm_cosmosdb_sql_container" "items_container" {
  name                = "items"
  resource_group_name = azurerm_resource_group.functions-group.name
  account_name        = azurerm_cosmosdb_account.bindings_cosmos_account.name
  database_name       = azurerm_cosmosdb_sql_database.inventory_db.name
  partition_key_paths = ["/id"] # Partition key
}

# Leases container for progress tracking
resource "azurerm_cosmosdb_sql_container" "leases" {
  name                = "leases"
  resource_group_name = azurerm_resource_group.functions-group.name
  account_name        = azurerm_cosmosdb_account.bindings_cosmos_account.name
  database_name       = azurerm_cosmosdb_sql_database.inventory_db.name
  partition_key_paths = ["/id"]
}
