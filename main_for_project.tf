# Configure the Microsoft Azure Provider.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }  
}

#We will be using Azure CLI to connect
#to change it there is a template code on the relevant webpage (Hashicorp website)
provider "azurerm" {
  features {}
}

#end of configuration for the Microsoft Azure Provider

#VARIABLES
#==================================================================================
variable "prefix" {
  type = string
  default = "Default_prefix"
}

variable "location" {
  type = string
  description = "Location of the resource group and the rest of the resources"
  validation {
    condition = length(var.location) > 4
    error_message = "Location should be above 4 characters."
  }
}
#==================================================================================


#==================================================================================
#OUTPUTS
#==================================================================================
output "resource_group_name" {
  value = azurerm_resource_group.main.name
  description = "Name of the resource group"
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
  description = "Output the assigned public IP address of the newly created VM"  
}

# output "password" {
#   value = "123456789"
#   sensitive = true
# }
#==================================================================================
#OUTPUTS
#==================================================================================


#!!! Create resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-Group"
  location = var.location
}

#!!! 1 of 6 Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-VirtualNetwork"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

#!!! 2 of 6 Network security group
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
  #depends_on          = [azurerm_virtual_machine.main] ####this line was added as in the next attempt the host remains empty when running the provisioner
}

#!!! 3 of 6 network interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-IPConfig"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id ####this line was added as in the first attempt there was no public ip
  }
}

#VIRTUAL MACHINE / OS DISK
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-Jenkins-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B1s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    #publisher = "Canonical"
    #offer     = "UbuntuServer"
    #sku       = "20.04-LTS"
    #version   = "latest"

    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    ####urn       = "Canonical:0001-com-ubuntu-server-focal:20_04-lts:20.04.202010140"
    version   = "20.04.202010140"

  }
  storage_os_disk {
    name              = "${var.prefix}-Jenkins_Disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "vmadmin"
    admin_password = "AthT3chDevOps!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "${var.prefix}-Jenkins"
  }

provisioner "file" {
  connection {
    type="ssh"
    user="vmadmin"
    password="AthT3chDevOps!"
    host=azurerm_public_ip.public_ip.ip_address
  }

  source = "JenkinsGitInstallationVM.sh"
  destination = "/home/vmadmin/JenkinsGitInstallationVM.sh"
}

provisioner "remote-exec" {
    connection {
    type="ssh"
    user="vmadmin"
    password="AthT3chDevOps!"
    host=azurerm_public_ip.public_ip.ip_address
  }
  inline = [
    "ls -a",
    "mkdir thiswascreatedusingtf",
    "sudo chmod +x JenkinsGitInstallationVM.sh",
    "sudo ./JenkinsGitInstallationVM.sh"
  ]
}

provisioner "local-exec" {
  command = "echo ${azurerm_public_ip.public_ip.ip_address} >> publicip.txt"  
}

}