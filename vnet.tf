# Name: vnet.tf
# Owner: Saurav Mitra
# Description: This terraform config will create a Azure VNET with following resources:
#   3 Private Subnets
#   3 Public Subnets
#   2 Network Security Group (for Public and Private subnet for Network Traffic Filtering)

# Resource Group
resource "azurerm_resource_group" "azure_infra" {
  name     = "${var.prefix}-rg"
  location = var.rg_location
}

# VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.azure_infra.name
  address_space       = [var.vnet_cidr_block]
  tags = {
    Name  = "${var.prefix}-vnet"
    Owner = var.owner
  }
}

# Public Subnet
resource "azurerm_subnet" "public_subnet" {
  count                = length(var.public_subnets)
  name                 = "${var.prefix}-public-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.azure_infra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.public_subnets[count.index]]
}

# Private Subnet
resource "azurerm_subnet" "private_subnet" {
  count                = length(var.private_subnets)
  name                 = "${var.prefix}-private-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.azure_infra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.private_subnets[count.index]]
}

# Public Network Security Group
resource "azurerm_network_security_group" "public_security_group" {
  name                = "${var.prefix}-public-nsg"
  location            = azurerm_resource_group.azure_infra.location
  resource_group_name = azurerm_resource_group.azure_infra.name

  security_rule {
    name                       = "AllowInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*" # "Internet"
    destination_address_prefix = "*"
  }
}

# Public Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc" {
  count                     = length(var.public_subnets)
  subnet_id                 = azurerm_subnet.public_subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.public_security_group.id
}

# Private Network Security Group
resource "azurerm_network_security_group" "private_security_group" {
  name                = "${var.prefix}-private-nsg"
  location            = azurerm_resource_group.azure_infra.location
  resource_group_name = azurerm_resource_group.azure_infra.name

  security_rule {
    name                       = "AllowInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Private Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "private_nsg_assoc" {
  count                     = length(var.private_subnets)
  subnet_id                 = azurerm_subnet.private_subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.private_security_group.id
}
