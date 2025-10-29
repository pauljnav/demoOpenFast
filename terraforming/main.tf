# Variables
variable "resource_group_name" { default = "rg-6core-openfast" }
variable "location" { default = "East US" }
variable "vm_name" { default = "openfast-vm" }

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-6core-openfast"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}