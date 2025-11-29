# ============================================
# Storage Account & Containers
# ============================================

# Storage account
resource "azurerm_storage_account" "functions-storage" {
  name                     = "${var.storage_account_prefix}${random_string.postfix.result}"
  resource_group_name      = azurerm_resource_group.functions-group.name
  location                 = azurerm_resource_group.functions-group.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally redundant storage
}

# ============================================
# Blob Containers
# ============================================

# Store items
resource "azurerm_storage_container" "item_uploads" {
  name                  = "item-uploads"
  storage_account_id    = azurerm_storage_account.functions-storage.id
  container_access_type = "private" # Not accessible for public, only open for internal infrastructure
}

# Store audit
# TODO check if this is needed
resource "azurerm_storage_container" "item_archive_audit" {
  name                  = "item-archive-audit"
  storage_account_id    = azurerm_storage_account.functions-storage.id
  container_access_type = "private"
}

# ============================================
# Storage Tables
# ============================================

# Item statistics
resource "azurerm_storage_table" "item_statistics" {
  name                 = "ItemQueryStatistics"
  storage_account_name = azurerm_storage_account.functions-storage.name
}

# Search index
resource "azurerm_storage_table" "search_index" {
  name                 = "ItemSerachIndex"
  storage_account_name = azurerm_storage_account.functions-storage.name
}

# Item analytics
# TODO check if this is needed
resource "azurerm_storage_table" "item_analytics" {
  name                 = "ItemAnalytics"
  storage_account_name = azurerm_storage_account.functions-storage.name
}





