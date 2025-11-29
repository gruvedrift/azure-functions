# ============================================
# Provider & Core Configuration
# ============================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}

# ============================================
# Resource group
# ============================================

resource "azurerm_resource_group" "functions-group" {
  location = var.location
  name     = var.resource_group_name
}

# Random suffix for globally unique names
resource "random_string" "postfix" {
  length  = 6
  upper   = false
  special = false
}
