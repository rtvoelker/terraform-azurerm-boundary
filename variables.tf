variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group."
}

variable "location" {
  type        = string
  description = "Location of Azure resource group."
}

variable "controller_subnet_id" {
  type        = string
  description = "Azure subnet ID for Boundary controllers."
}

variable "worker_subnet_id" {
  type        = string
  description = "Azure subnet ID for Boundary workers."
}

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

variable "tags" {
  type        = map(string)
  default     = {}
  description = "List of tags to add to Boundary resources. Merged with module tags."
}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

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

locals {
  tags = merge({
    module = "joatmon08/terraform-azurerm-boundary"
  }, var.tags)

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
}
