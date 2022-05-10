variable "resource_group_name" {
  default = "rg-boundary-poc"
  type        = string
  description = "Name of Azure resource group."
}

variable "location" {
  default = "westeurope"
  type        = string
  description = "Location of Azure resource group."
}

#variable "controller_subnet_id" {
#  type        = string
#  description = "Azure subnet ID for Boundary controllers."
#}
#
#variable "worker_subnet_id" {
#  type        = string
#  description = "Azure subnet ID for Boundary workers."
#}

variable "controller_vm_size" {
  type        = string
  default     = "Standard_D2as_v4"
  description = "Size of controller VMs for Boundary. Default is `Standard_D2as_v4`."
}

variable "controller_vm_count" {
  type        = number
  default     = 1
  description = "Number of controller VMs for Boundary. Default is `1`."
}

variable "worker_vm_size" {
  type        = string
  default     = "Standard_D2as_v4"
  description = "Size of worker VMs for Boundary. Default is `Standard_D2as_v4`."
}

variable "worker_vm_count" {
  type        = number
  default     = 1
  description = "Number of worker VMs for Boundary. Default is `1`."
}

variable "db_username" {
  type        = string
  default     = "sqladmin"
  description = "PostgreSQL admin username for Boundary. Default is `sqladmin`."
}

variable "cert_cn" {
  type        = string
  default     = "boundary-azure"
  description = "Certificate common name for Boundary. Default is `boundary-azure`."
}

variable "boundary_version" {
  type        = string
  default     = "0.7.5"
  description = "Version of Boundary to install. Default is `0.7.5`."
}

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "random_id" "id" {
  byte_length = 4
}

resource "random_password" "database" {
  length  = 16
  special = false
}

resource "random_string" "vault" {
  length      = 14
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
  special     = false
}

variable "creator" {
  type = string
  description = "name of original creator of the resource"
}
locals {
  tags = {
    "managed"     = "terraformed"
    "creator"     = var.creator
    "created"     = timestamp()
    "part-of" = "boundary-infra"
    "purpose" = "hashicorp-azure-zero-trust"
  }
  controller_net_nsg = "controller-net-${random_id.id.hex}"
  worker_net_nsg     = "worker-net-${random_id.id.hex}"

  controller_nic_nsg = "controller-nic-${random_id.id.hex}"
  worker_nic_nsg     = "worker-nic-${random_id.id.hex}"

  controller_asg = "controller-asg-${random_id.id.hex}"
  worker_asg     = "worker-asg-${random_id.id.hex}"

  controller_vm = "controller-${random_id.id.hex}"
  worker_vm     = "worker-${random_id.id.hex}"

  controller_user_id = "controller-userid-${random_id.id.hex}"
  worker_user_id     = "worker-userid-${random_id.id.hex}"

  pip_name = "boundary-${random_id.id.hex}"
  lb_name  = "boundary-${random_id.id.hex}"

  vault_name = "boundary-${random_string.vault.result}"

  pg_name = "boundary-${random_id.id.hex}"

  sp_name = "boundary-${random_id.id.hex}"

  cert_san = ["boundary-${random_id.id.hex}.${var.location}.cloudapp.azure.com"]

  db_password = random_password.database.result

  subnet_service_endpoints = {
    (var.subnet_names[0]) = ["Microsoft.KeyVault", "Microsoft.Sql"]
    (var.subnet_names[1]) = ["Microsoft.KeyVault", "Microsoft.Sql"]
    (var.subnet_names[2]) = ["Microsoft.Sql"]
    (var.subnet_names[3]) = ["Microsoft.Sql"]
  }

  subnet_enforce_private_link_endpoint_network_policies = {
    (var.subnet_names[1]) = true
    (var.subnet_names[2]) = true
    (var.subnet_names[3]) = true
  }
}

## For Virtual Network
variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  type    = list(string)
  default = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "subnet_names" {
  type    = list(string)
  default = [
    "controllers",
    "workers",
    "targets",
    "vault"
  ]
}

variable "subnet_delegation" {
  description = "A map of subnet name to delegation block on the subnet"
  type        = map(map(any))
  default     = {}
}

variable "subnet_enforce_private_link_endpoint_network_policies" {
  description = "A map of subnet name to enable/disable private link endpoint network policies on the subnet."
  type        = map(bool)
  default     = {}
}

variable "subnet_enforce_private_link_service_network_policies" {
  description = "A map of subnet name to enable/disable private link service network policies on the subnet."
  type        = map(bool)
  default     = {}
}

## Azure AD Users
#variable "operators" {
#  type = map(object({
#    user_principal_name = string
#    display_name        = string
#    mail_nickname       = string
#  }))
#  description = "List of Boundary operator's Azure AD user attributes"
#}
#
#variable "database_admins" {
#  type = map(object({
#    user_principal_name = string
#    display_name        = string
#    mail_nickname       = string
#  }))
#  description = "List of Boundary database admin's Azure AD user attributes"
#}

#variable "device_status_subscriptions" {
#  type = map(object({
#    message_retention          = number
#    connection-state-condition = string
#    twin-change-condition      = string
#  }))
#}

#variable "database_name" {
#  type        = string
#  description = "Name of database for application"
#  default = "boundary_configuration"
#}