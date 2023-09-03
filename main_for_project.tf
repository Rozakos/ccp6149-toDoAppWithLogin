# Configure the Microsoft Azure Provider.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

# Using Azure CLI for authentication
provider "azurerm" {
  features {}
}

# Define Variables
variable "client_id" {
  description = "The Azure AD Application Client ID"
  type        = string
}

variable "client_secret" {
  description = "The Azure AD Application Client Secret"
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
  default     = "East US"
}

# Outputs
output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Name of the resource group"
}

output "public_ip_address" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "Public IP of VM"
}

# Resources
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-Group"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-VirtualNetwork"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-NetSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "JenkinsPort"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "${var.prefix}-Jenkins"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-public_ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-IPConfig"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-Jenkins-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B1s"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-Jenkins_Disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = JenkinsCredentials('AZ_USERNAME')
    admin_password = JenkinsCredentials('AZ_PASSWORD')
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "${var.prefix}-Jenkins"
  }

  provisioner "file" {
    connection {
      type     = "ssh"
      user     = JenkinsCredentials('AZ_USERNAME')
      password = JenkinsCredentials('AZ_PASSWORD')
      host     = azurerm_public_ip
