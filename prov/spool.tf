# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "~> 2.1.0"
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource-prefix}-rg"
  location = var.pool-location
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

# Create Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource-prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.pool-location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

# Create Subnets
resource "azurerm_subnet" "coresnet" {
  name                 = "${var.resource-prefix}-vnet-core-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet" "relaysnet" {
  name                 = "${var.resource-prefix}-vnet-relays-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.0.2.0/24"
}

# Create Public IPs
resource "azurerm_public_ip" "core0pip" {
  name                = "${var.resource-prefix}-core0pip"
  location            = var.pool-location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

resource "azurerm_public_ip" "relay0pip" {
  name                = "${var.resource-prefix}-relay0pip"
  location            = var.pool-location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

# Create Network Security Groups
resource "azurerm_network_security_group" "corensg" {
  name                = "${var.resource-prefix}-core-nsg"
  location            = var.pool-location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh-whitelist
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "relay-in"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.core-node-port
    source_address_prefixes    = [azurerm_public_ip.relay0pip.ip_address]
    destination_address_prefix = "*"
  }
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

resource "azurerm_network_security_group" "relaynsg" {
  name                = "${var.resource-prefix}-relay-nsg"
  location            = var.pool-location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh-whitelist
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "relay-in"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.relay-node-port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

# Create Network interfaces
resource "azurerm_network_interface" "core0nic" {
  name                          = "${var.resource-prefix}-core0nic"
  location                      = var.pool-location
  resource_group_name           = azurerm_resource_group.rg.name
  enable_accelerated_networking = var.corevm-nic-accelerated-networking
  ip_configuration {
    name                          = "core0nic-ipconfig"
    subnet_id                     = azurerm_subnet.coresnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.core0pip.id
  }
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

resource "azurerm_network_interface" "relay0nic" {
  name                          = "${var.resource-prefix}-relay0nic"
  location                      = var.pool-location
  resource_group_name           = azurerm_resource_group.rg.name
  enable_accelerated_networking = var.relayvm-nic-accelerated-networking
  ip_configuration {
    name                          = "relay0nic-ipconfig"
    subnet_id                     = azurerm_subnet.relaysnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.relay0pip.id
  }
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

# Connect Network Security Groups to the Network Interfaces
resource "azurerm_network_interface_security_group_association" "core0nicnsg" {
  network_interface_id      = azurerm_network_interface.core0nic.id
  network_security_group_id = azurerm_network_security_group.corensg.id
}

resource "azurerm_network_interface_security_group_association" "relay0nicnsg" {
  network_interface_id      = azurerm_network_interface.relay0nic.id
  network_security_group_id = azurerm_network_security_group.relaynsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "corestorage" {
  name                     = "${var.storage-prefix}cstor"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.pool-location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

resource "azurerm_storage_account" "relaystorage" {
  name                     = "${var.storage-prefix}rstor"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.pool-location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

# Create (and display) an SSH key 
resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machines
resource "azurerm_linux_virtual_machine" "core0vm" {
  name                            = "${var.resource-prefix}-core0vm"
  location                        = var.pool-location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.core0nic.id]
  size                            = var.corevm-size
  computer_name                   = "${var.corevm-comp-name}0"
  admin_username                  = var.vm-username
  disable_password_authentication = true
  zone                            = "1"
  os_disk {
    name                 = "${var.resource-prefix}-core0vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = "256"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = var.vm-username
    public_key = tls_private_key.sshkey.public_key_openssh
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.corestorage.primary_blob_endpoint
  }
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

resource "azurerm_linux_virtual_machine" "relay0vm" {
  name                            = "${var.resource-prefix}-relay0vm"
  location                        = var.pool-location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.relay0nic.id]
  size                            = var.relayvm-size
  computer_name                   = "${var.relayvm-comp-name}0"
  admin_username                  = var.vm-username
  disable_password_authentication = true
  zone                            = "1"
  os_disk {
    name                 = "${var.resource-prefix}-relay0vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = "128"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = var.vm-username
    public_key = tls_private_key.sshkey.public_key_openssh
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.relaystorage.primary_blob_endpoint
  }
  tags = {
    platform            = var.tag-platform
    stage               = var.tag-stage
    data-classification = var.tag-data-classification
  }
}

output "sshpvk" {
  value       = "${tls_private_key.sshkey.private_key_pem}"
  description = "SSH private key"
  sensitive   = false
}

output "c0pip" {
  value       = azurerm_public_ip.core0pip.ip_address
  description = "Core VM 0 Active Public IP Address"
  sensitive   = false
}

output "r0pip" {
  value       = azurerm_public_ip.relay0pip.ip_address
  description = "Relay VM Public IP Address"
  sensitive   = false
}

