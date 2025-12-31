# ============================================
# Storage Account
# ============================================
resource "azurerm_storage_account" "functions-storage" {
  name                     = "${var.storage_account_prefix}${random_string.postfix.result}"
  resource_group_name      = azurerm_resource_group.functions-group.name
  location                 = azurerm_resource_group.functions-group.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally redundant storage
}

# ============================================
# Blob Container - Item image stored as .png
# ============================================
resource "azurerm_storage_container" "item_uploads" {
  name                  = "item-uploads"
  storage_account_id    = azurerm_storage_account.functions-storage.id
  container_access_type = "private" # Not accessible for public, only open for internal infrastructure
}

# ==========================================================
# Blob Container - Approved item catalog, stored as JSON
# ==========================================================
resource "azurerm_storage_container" "store_catalog" {
  name               = "store-catalog"
  storage_account_id = azurerm_storage_account.functions-storage.id
}

# =================================================
# Table Storage - Table for tracking price history
# =================================================
resource "azurerm_storage_table" "price_history" {
  name                 = "ItemPriceHistory"
  storage_account_name = azurerm_storage_account.functions-storage.name
}
