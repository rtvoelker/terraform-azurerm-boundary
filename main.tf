terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=2.0"
    }
  }
}

data "http" "my_ip" {
  url = "http://ifconfig.me"
}

provider "azurerm" {
  subscription_id = ""
  tenant_id       = "gst"
  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

resource "azurerm_resource_group" "keyvault" {
  location = var.location
  name     = var.resource_group_name
}