# Configure the Microsoft Azure Provider
provider "azurerm" {
    version = "~> 2.1.0" 
    features {}
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
    name = "${var.resource-prefix}-rg"
    location = var.pool-location
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
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
        platform = var.tag-platform
        stage = var.tag-stage
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
resource "azurerm_public_ip" "corepip" {
    name                         = "${var.resource-prefix}-corepip"
    location                     = var.pool-location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

resource "azurerm_public_ip" "relay0pip" {
    name                         = "${var.resource-prefix}-relay0pip"
    location                     = var.pool-location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

resource "azurerm_public_ip" "relay1pip" {
    name                         = "${var.resource-prefix}-relay1pip"
    location                     = var.pool-location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
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
        source_address_prefixes    = [azurerm_public_ip.relay0pip.ip_address,azurerm_public_ip.relay1pip.ip_address]
        destination_address_prefix = "*"
    }
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
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
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

# Create Network interfaces
resource "azurerm_network_interface" "corenic" {
    name                      = "${var.resource-prefix}-corenic"
    location                  = var.pool-location
    resource_group_name       = azurerm_resource_group.rg.name
    enable_accelerated_networking = var.corevm-nic-accelerated-networking
    ip_configuration {
        name                          = "corenic-ipconfig"
        subnet_id                     = azurerm_subnet.coresnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.corepip.id
    }
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

resource "azurerm_network_interface" "relay0nic" {
    name                      = "${var.resource-prefix}-relay0nic"
    location                  = var.pool-location
    resource_group_name       = azurerm_resource_group.rg.name
    enable_accelerated_networking = var.relayvm-nic-accelerated-networking
    ip_configuration {
        name                          = "relay0nic-ipconfig"
        subnet_id                     = azurerm_subnet.relaysnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.relay0pip.id
    }
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

resource "azurerm_network_interface" "relay1nic" {
    name                      = "${var.resource-prefix}-relay1nic"
    location                  = var.pool-location
    resource_group_name       = azurerm_resource_group.rg.name
    enable_accelerated_networking = var.relayvm-nic-accelerated-networking
    ip_configuration {
        name                          = "relay1nic-ipconfig"
        subnet_id                     = azurerm_subnet.relaysnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.relay1pip.id
    }
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

# Connect Network Security Groups to the Network Interfaces
resource "azurerm_network_interface_security_group_association" "corenicnsg" {
    network_interface_id      = azurerm_network_interface.corenic.id
    network_security_group_id = azurerm_network_security_group.corensg.id
}

resource "azurerm_network_interface_security_group_association" "relay0nicnsg" {
    network_interface_id      = azurerm_network_interface.relay0nic.id
    network_security_group_id = azurerm_network_security_group.relaynsg.id
}

resource "azurerm_network_interface_security_group_association" "relay1nicnsg" {
    network_interface_id      = azurerm_network_interface.relay1nic.id
    network_security_group_id = azurerm_network_security_group.relaynsg.id
}

# Network Watcher
resource "azurerm_network_watcher" "example" {
  name                = "${var.resource-prefix}-nwatcher"
  location            = var.pool-location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storage" {
    name                        = "${var.storage-prefix}stor"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = var.pool-location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

# Create (and display) an SSH key 
resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Create virtual machines
resource "azurerm_linux_virtual_machine" "corevm" {
    name                  = "${var.resource-prefix}-corevm"
    location              = var.pool-location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.corenic.id]
    size                  = var.corevm-size

    os_disk {
        name              = "${var.resource-prefix}-corevm-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb = "256"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = var.corevm-comp-name
    admin_username = var.vm-username
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.vm-username
        public_key     = tls_private_key.sshkey.public_key_openssh
    }
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
    }
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

resource "azurerm_linux_virtual_machine" "relay0vm" {
    name                  = "${var.resource-prefix}-relay0vm"
    location              = var.pool-location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.relay0nic.id]
    size                  = var.relayvm-size

    os_disk {
        name              = "${var.resource-prefix}-relay0vm-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb = "128"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "${var.relayvm-comp-name}0"
    admin_username = var.vm-username
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.vm-username
        public_key     = tls_private_key.sshkey.public_key_openssh
    }
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
    }
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

resource "azurerm_linux_virtual_machine" "relay1vm" {
    name                  = "${var.resource-prefix}-relay1vm"
    location              = var.pool-location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.relay1nic.id]
    size                  = var.relayvm-size

    os_disk {
        name              = "${var.resource-prefix}-relay1vm-osdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb = "128"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "${var.relayvm-comp-name}1"
    admin_username = var.vm-username
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = var.vm-username
        public_key     = tls_private_key.sshkey.public_key_openssh
    }
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
    }
    tags = {
        platform = var.tag-platform
        stage = var.tag-stage
        data-classification = var.tag-data-classification
    }
}

# resource "azurerm_virtual_machine_extension" "corevminitscript" {
#     name                 = "${azurerm_linux_virtual_machine.corevm.name}-initscript-ext"
#     virtual_machine_id   = azurerm_linux_virtual_machine.corevm.id
#     publisher            = "Microsoft.Azure.Extensions"
#     type                 = "CustomScript"
#     type_handler_version = "2.0"
#     settings = <<SETTINGS
#     {
#         "script": "${base64encode(file("../init/common.sh"))}"
#     }
#     SETTINGS
#     tags = {
#         platform = var.tag-platform
#         stage = var.tag-stage
#         data-classification = var.tag-data-classification
#     }
# }

# resource "azurerm_virtual_machine_extension" "relayvminitscript" {
#     name                 = "${azurerm_linux_virtual_machine.relayvm.name}-initscript-ext"
#     virtual_machine_id   = azurerm_linux_virtual_machine.relayvm.id
#     publisher            = "Microsoft.Azure.Extensions"
#     type                 = "CustomScript"
#     type_handler_version = "2.0"
#     settings = <<SETTINGS
#     {
#         "script": "${base64encode(file("../init/common.sh"))}"
#     }
#     SETTINGS
#     tags = {
#         platform = var.tag-platform
#         stage = var.tag-stage
#         data-classification = var.tag-data-classification
#     }
# }

output "sshpvk" { 
    value = "${tls_private_key.sshkey.private_key_pem}" 
    description = "SSH private key"
    sensitive   = false
}

output "cpip" {
  value       = azurerm_public_ip.corepip.ip_address
  description = "Core VM Public IP Address"
  sensitive   = false
}

output "r0pip" {
  value       = azurerm_public_ip.relay0pip.ip_address
  description = "Relay VM Public IP Address"
  sensitive   = false
}

output "r1pip" {
  value       = azurerm_public_ip.relay1pip.ip_address
  description = "Relay VM Public IP Address"
  sensitive   = false
}