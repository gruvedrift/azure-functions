# ============================================
# Storage Account
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
# Store item images in .png format
# ============================================

# Store items
resource "azurerm_storage_container" "item_uploads" {
  name                  = "item-uploads"
  storage_account_id    = azurerm_storage_account.functions-storage.id
  container_access_type = "private" # Not accessible for public, only open for internal infrastructure
}