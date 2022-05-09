# Create Network Security Groups for subnets
resource "azurerm_network_security_group" "controller_net" {
  name                = local.controller_net_nsg
  location            = var.location
  resource_group_name = azurerm_resource_group.boundery_infra.name
}

resource "azurerm_network_security_group" "worker_net" {
  name                = local.worker_net_nsg
  location            = var.location
  resource_group_name = azurerm_resource_group.boundery_infra.name
}

# Create NSG associations
resource "azurerm_subnet_network_security_group_association" "controller" {
  subnet_id                 = azurerm_subnet.boundery_infra_subnet[0].id # Controller Subnet
  network_security_group_id = azurerm_network_security_group.controller_net.id
}

resource "azurerm_subnet_network_security_group_association" "worker" {
  depends_on = [
    azurerm_subnet_network_security_group_association.controller
  ]
  subnet_id                 = azurerm_subnet.boundery_infra_subnet[1].id # Worker Subnet
  network_security_group_id = azurerm_network_security_group.worker_net.id
}

# Create Network Security Groups for NICs
# The associations are in the vm.tf file.
resource "azurerm_network_security_group" "controller_nics" {
  name                = local.controller_nic_nsg
  location            = var.location
  resource_group_name = azurerm_resource_group.boundery_infra.name
}

resource "azurerm_network_security_group" "worker_nics" {
  name                = local.worker_nic_nsg
  location            = var.location
  resource_group_name = azurerm_resource_group.boundery_infra.name
}

# Create application security groups for controllers, workers, and backend
# The associations are in the vm.tf file and remotehosts.tf file
resource "azurerm_application_security_group" "controller_asg" {
  name                = local.controller_asg
  location            = var.location
  resource_group_name = azurerm_resource_group.boundery_infra.name
}

resource "azurerm_application_security_group" "worker_asg" {
  name                = local.worker_asg
  location            = var.location
  resource_group_name = azurerm_resource_group.boundery_infra.name
}

# Inbound rules for controller subnet nsg
resource "azurerm_network_security_rule" "controller_9200" {
  name                                       = "allow_9200"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9200"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.controller_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.controller_net.name
}

resource "azurerm_network_security_rule" "controller_9201" {
  name                                       = "allow_9201"
  priority                                   = 110
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9201"
  source_application_security_group_ids      = [azurerm_application_security_group.worker_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.controller_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.controller_net.name
}

resource "azurerm_network_security_rule" "controller_ssh" {
  name                                       = "allow_ssh"
  priority                                   = 120
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.controller_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.controller_net.name
}

# Inbound rules for controller nic nsg

resource "azurerm_network_security_rule" "controller_nic_9200" {
  name                                       = "allow_9200"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9200"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.controller_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.controller_nics.name
}

resource "azurerm_network_security_rule" "controller_nic_9201" {
  name                                       = "allow_9201"
  priority                                   = 110
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9201"
  source_application_security_group_ids      = [azurerm_application_security_group.worker_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.controller_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.controller_nics.name
}

resource "azurerm_network_security_rule" "controller_nic_ssh" {
  name                                       = "allow_ssh"
  priority                                   = 120
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.controller_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.controller_nics.name
}

# Inbound rules for worker subnet nsg

resource "azurerm_network_security_rule" "worker_9202" {
  name                                       = "allow_9202"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9202"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.worker_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.worker_net.name
}

resource "azurerm_network_security_rule" "worker_ssh" {
  name                                       = "allow_ssh"
  priority                                   = 110
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.worker_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.worker_net.name
}

# Inbound rules for worker nic nsg

resource "azurerm_network_security_rule" "worker_nic_9202" {
  name                                       = "allow_9202"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9202"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.worker_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.worker_nics.name
}

resource "azurerm_network_security_rule" "worker_nic_ssh" {
  name                                       = "allow_ssh"
  priority                                   = 110
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.worker_asg.id]
  resource_group_name                        = azurerm_resource_group.boundery_infra.name
  network_security_group_name                = azurerm_network_security_group.worker_nics.name
}