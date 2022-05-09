resource "azurerm_resource_group" "boundery_infra" {
  location = var.location
  name     = "rg-vnet-boundary"
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}

resource "azurerm_virtual_network" "boundery_infra_vnet" {
  name                = "vnet-boundary"
  resource_group_name = azurerm_resource_group.boundery_infra.name
  location            = azurerm_resource_group.boundery_infra.location
  address_space       = var.address_space
  tags                = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}

resource "azurerm_subnet" "boundery_infra_subnet" {
  count                                          = length(var.subnet_names)
  name                                           = var.subnet_names[count.index]
  resource_group_name                            = azurerm_resource_group.boundery_infra.name
  virtual_network_name                           = azurerm_virtual_network.boundery_infra_vnet.name
  address_prefixes                               = [var.subnet_prefixes[count.index]]
  service_endpoints                              = lookup(local.subnet_service_endpoints, var.subnet_names[count.index], null)
  enforce_private_link_endpoint_network_policies = lookup(var.subnet_enforce_private_link_endpoint_network_policies, var.subnet_names[count.index], false)
  enforce_private_link_service_network_policies  = lookup(var.subnet_enforce_private_link_service_network_policies, var.subnet_names[count.index], false)

  dynamic "delegation" {
    for_each = lookup(var.subnet_delegation, var.subnet_names[count.index], {})
    content {
      name = delegation.key
      service_delegation {
        name    = lookup(delegation.value, "service_name")
        actions = lookup(delegation.value, "service_actions", [])
      }
    }
  }
}
