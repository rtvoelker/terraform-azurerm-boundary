# Generate key pair for all VMs
resource "tls_private_key" "boundary" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

# Create User Identities for Controller VMs and Worker VMs
# Could probably do this with a loop
resource "azurerm_user_assigned_identity" "controller" {
  resource_group_name = azurerm_resource_group.keyvault.name
  location            = var.location

  name = local.controller_user_id
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}

resource "azurerm_user_assigned_identity" "worker" {
  resource_group_name = azurerm_resource_group.keyvault.name
  location            = var.location

  name = local.worker_user_id
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}

##################### CONTROLLER VM RESOURCES ###################################
resource "azurerm_availability_set" "controller" {
  name                         = local.controller_vm
  location                     = var.location
  resource_group_name          = azurerm_resource_group.keyvault.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 2
  managed                      = true
  tags                         = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}


resource "azurerm_network_interface" "controller" {
  depends_on          = [azurerm_key_vault.boundary]
  count               = var.controller_vm_count
  name                = "${local.controller_vm}-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.keyvault.name

  ip_configuration {
    name                          = "internal"
#    subnet_id                     = var.controller_subnet_id
    subnet_id                     = azurerm_subnet.boundery_infra_subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}

# Associate the network interfaces from the controllers with the controller NSG
resource "azurerm_network_interface_security_group_association" "controller" {
  depends_on                = [azurerm_key_vault.boundary]
  count                     = var.controller_vm_count
  network_interface_id      = azurerm_network_interface.controller[count.index].id
  network_security_group_id = azurerm_network_security_group.controller_nics.id
}

# Associate the network interfaces from the controllers with the controller ASG for NSG rules
resource "azurerm_network_interface_application_security_group_association" "controller" {
  depends_on                    = [azurerm_key_vault.boundary]
  count                         = var.controller_vm_count
  network_interface_id          = azurerm_network_interface.controller[count.index].id
  application_security_group_id = azurerm_application_security_group.controller_asg.id
}

resource "azurerm_linux_virtual_machine" "controller" {
  depends_on          = [azurerm_key_vault.boundary]
  count               = var.controller_vm_count
  name                = "${local.controller_vm}-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.keyvault.name
  size                = var.controller_vm_size
  admin_username      = "azureuser"
  computer_name       = "controller-${count.index}"
  availability_set_id = azurerm_availability_set.controller.id
  network_interface_ids = [
    azurerm_network_interface.controller[count.index].id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.boundary.public_key_openssh
  }

  # Using Standard SSD tier storage
  # Accepting the standard disk size from image
  # No data disk is being used
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  #Source image is hardcoded b/c I said so
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.controller.id]
  }

  # This makes the Key Vault and TLS certificate available to the VM
  secret {
    key_vault_id = azurerm_key_vault.boundary.id

    certificate {
      url = azurerm_key_vault_certificate.boundary.secret_id
    }
  }

  #Custom data from the boundary.tmpl file
  custom_data = base64encode(
    templatefile("${path.module}/templates/boundary.tmpl", {
      vault_name       = local.vault_name
      type             = "controller"
      name             = "boundary"
      boundary_version = var.boundary_version
      tenant_id        = data.azurerm_client_config.current.tenant_id
      public_ip        = azurerm_public_ip.boundary.ip_address
      controller_ips   = azurerm_network_interface.controller.*.private_ip_address
      db_username      = var.db_username
      db_password      = local.db_password
      db_name          = local.pg_name
      db_endpoint      = azurerm_postgresql_server.boundary.fqdn
    })
  )
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}

##################### WORKER VM RESOURCES ###################################

resource "azurerm_network_interface" "worker" {
  depends_on          = [azurerm_network_interface.controller]
  count               = var.worker_vm_count
  name                = "${local.worker_vm}-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.keyvault.name

  ip_configuration {
    name                          = "internal"
#    subnet_id                     = var.worker_subnet_id
    subnet_id                     = azurerm_subnet.boundery_infra_subnet[1].id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}

# Associate the network interfaces from the workers with the worker NSG
resource "azurerm_network_interface_security_group_association" "worker" {
  depends_on                = [azurerm_network_interface_security_group_association.controller]
  count                     = var.worker_vm_count
  network_interface_id      = azurerm_network_interface.worker[count.index].id
  network_security_group_id = azurerm_network_security_group.worker_nics.id
}

# Associate the network interfaces from the workers with the worker ASG for NSG rules
resource "azurerm_network_interface_application_security_group_association" "worker" {
  depends_on                    = [azurerm_network_interface_application_security_group_association.controller]
  count                         = var.worker_vm_count
  network_interface_id          = azurerm_network_interface.worker[count.index].id
  application_security_group_id = azurerm_application_security_group.worker_asg.id
}

resource "azurerm_linux_virtual_machine" "worker" {
  count               = var.worker_vm_count
  name                = "${local.worker_vm}-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.keyvault.name
  size                = var.worker_vm_size
  admin_username      = "azureuser"
  computer_name       = "worker-${count.index}"
  availability_set_id = azurerm_availability_set.controller.id
  network_interface_ids = [
    azurerm_network_interface.worker[count.index].id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.boundary.public_key_openssh
  }

  # Using Standard SSD tier storage
  # Accepting the standard disk size from image
  # No data disk is being used
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  #Source image is hardcoded b/c I said so
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.worker.id]
  }

  secret {
    key_vault_id = azurerm_key_vault.boundary.id

    certificate {
      url = azurerm_key_vault_certificate.boundary.secret_id
    }
  }

  custom_data = base64encode(
    templatefile("${path.module}/templates/boundary.tmpl", {
      vault_name       = local.vault_name
      type             = "worker"
      name             = "boundary"
      boundary_version = var.boundary_version
      tenant_id        = data.azurerm_client_config.current.tenant_id
      public_ip        = azurerm_public_ip.boundary.ip_address
      controller_ips   = azurerm_network_interface.controller[*].private_ip_address
      db_username      = var.db_username
      db_password      = local.db_password
      db_name          = local.pg_name
      db_endpoint      = azurerm_postgresql_server.boundary.fqdn
    })
  )

  depends_on = [azurerm_linux_virtual_machine.controller]
  tags       = local.tags
  lifecycle {
    ignore_changes = [
      tags["creator"],
      tags["created"],
    ]
  }
}