resource "azuread_application" "recovery_sp" {
  display_name = local.sp_name
  owners       = [data.azuread_client_config.current.object_id]
}

# This service principal is used to access the recovery key in Azure
# key vault. The recovery key is used to perform initial setup of
# Boundary. After an authentication method has been enabled, you will
# no longer need a recovery key to access Boundary.
resource "azuread_service_principal" "recovery_sp" {
  application_id = azuread_application.recovery_sp.application_id
  owners         = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "recovery_sp" {
  service_principal_id = azuread_service_principal.recovery_sp.id
}


locals {
  boundary_group_ops_name = "boundary-operations-team"
  boundary_group_db_name  = "boundary-database-team"
}

resource "random_password" "operators" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "database_admins" {
  length           = 16
  special          = true
  override_special = "_%@"
}
#
#resource "azuread_user" "operator" {
#  for_each            = var.operators
#  user_principal_name = each.value.user_principal_name
#  display_name        = each.value.display_name
#  mail_nickname       = each.value.mail_nickname
#  password            = random_password.operators.result
#}
#
#resource "azuread_group" "operator" {
#  display_name     = local.boundary_group_ops_name
#  security_enabled = true
#  owners           = [data.azuread_client_config.current.object_id]
#  members          = [for name, metadata in azuread_user.operator : metadata.object_id]
#}
#
#resource "azuread_user" "database" {
#  for_each            = var.database_admins
#  user_principal_name = each.value.user_principal_name
#  display_name        = each.value.display_name
#  mail_nickname       = each.value.mail_nickname
#  password            = random_password.database_admins.result
#}
#
#resource "azuread_group" "database" {
#  display_name     = local.boundary_group_db_name
#  security_enabled = true
#  owners           = [data.azuread_client_config.current.object_id]
#  members          = [for name, metadata in azuread_user.database : metadata.object_id]
#}
