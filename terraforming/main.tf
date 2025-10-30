# Variables
variable "resource_group_name" { default = "rg-openfast" }
variable "location" { default = "westeurope" }
variable "vm_name" { default = "openfast-vm" }
# Ensure your SSH public key is available
variable "public_key_path" { default = "~/.ssh/id_rsa.pub" }
variable "ssh_username" { default = "azurepauljn" }

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-${var.vm_name}"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Public IP
resource "azurerm_public_ip" "example" {
  name                = "pip-${var.vm_name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "example" {
  name                = "nsg-${var.vm_name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "example" {
  name                = "nic-${var.vm_name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# VM Configuration
resource "azurerm_linux_virtual_machine" "example" {
  name                = var.vm_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  size                = "Standard_F4s_v2"
  admin_username      = "azurepauljn"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
/*
#  Other good small VM size options you could consider:
# Standard_B1s - 1 vCPU, 1 GB RAM (smallest/cheapest)
# Standard_B1ms - 1 vCPU, 2 GB RAM
# Standard_B2s - 2 vCPUs, 4 GB RAM
# Standard_D2s_v3 - 2 vCPUs, 8 GB RAM 

# Compute optimized VM sizes
Size Name	vCPUs (Qty.)	Memory (GB) 
Standard_F2s_v2	2	4
Standard_F4s_v2	4	8 (current choice)
Standard_F8s_v2	8	16
Standard_F16s_v2	16	32
Standard_F1as_v7	1	4 RequestDisallowedByPolicy
Standard_F2as_v7	2	8
Standard_F4as_v7	4	16
Standard_F8as_v7	8	32 
Standard_FX2ms_v2	2	42
Standard_FX4ms_v2	4	84
Standard_FX8ms_v2	8	168
*/

  # Installation script for Conda/OpenFAST
  custom_data = filebase64("${path.module}/install_conda_openfast.sh")

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  computer_name = var.vm_name

  # SSH Key Authentication
  admin_ssh_key {
    username   = var.ssh_username
    public_key = file(var.public_key_path)
  }
}

# Output Public IP for SSH
output "public_ip_address" {
  value = azurerm_public_ip.example.ip_address
}
