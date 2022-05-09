output "key_vault_name" {
  value = local.vault_name
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "url" {
  value = "https://${azurerm_public_ip.boundary.fqdn}:9200"
}

output "client_id" {
  value = azuread_service_principal.recovery_sp.application_id
}

output "client_secret" {
  value = azuread_service_principal_password.recovery_sp.value
  sensitive = true
}

output "public_dns_name" {
  value = azurerm_public_ip.boundary.fqdn
}

output "public_key" {
  value = tls_private_key.boundary.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.boundary.private_key_pem
  sensitive = true
}

output "boundary_database_password" {
  value     = local.db_password
  sensitive = true
}

output "worker_security_group_id" {
  value = azurerm_application_security_group.worker_asg.id
}