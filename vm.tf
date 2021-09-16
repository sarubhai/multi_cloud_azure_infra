# Name: vm.tf
# Owner: Saurav Mitra
# Description: This terraform config will create a Azure Virtual Machine as Nginx Webserver

# Public IP for VM
resource "azurerm_public_ip" "web_public_ip" {
  name                = "${var.prefix}-web-public-ip"
  location            = azurerm_resource_group.azure_infra.location
  resource_group_name = azurerm_resource_group.azure_infra.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name  = "${var.prefix}-web-public-ip"
    Owner = var.owner
  }
}

# Web Network Security Group
resource "azurerm_network_security_group" "web_security_group" {
  name                = "${var.prefix}-web-nsg"
  location            = azurerm_resource_group.azure_infra.location
  resource_group_name = azurerm_resource_group.azure_infra.name

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

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name  = "${var.prefix}-web-nsg"
    Owner = var.owner
  }
}

# Network Interface Card for VM
resource "azurerm_network_interface" "web_nic" {
  name                = "${var.prefix}-web-nic"
  location            = azurerm_resource_group.azure_infra.location
  resource_group_name = azurerm_resource_group.azure_infra.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }

  tags = {
    Name  = "${var.prefix}-web-nic"
    Owner = var.owner
  }
}

# NIC & Security Group Association
resource "azurerm_network_interface_security_group_association" "web_nic_sg_assoc" {
  network_interface_id      = azurerm_network_interface.web_nic.id
  network_security_group_id = azurerm_network_security_group.web_security_group.id
}

# VM
resource "azurerm_virtual_machine" "web_vm" {
  name                             = "${var.prefix}-web-vm"
  location                         = azurerm_resource_group.azure_infra.location
  resource_group_name              = azurerm_resource_group.azure_infra.name
  network_interface_ids            = [azurerm_network_interface.web_nic.id]
  vm_size                          = var.vm_size
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-web-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    #  disable_password_authentication = false
    disable_password_authentication = true

    ssh_keys {
      key_data = var.ssh_public_key
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
    }
  }

  os_profile {
    computer_name  = "${var.prefix}-web-vm"
    admin_username = var.ssh_user
    #  admin_password = "P@ssword1234"
    custom_data = file("webserver.sh")
  }

  tags = {
    Name  = "${var.prefix}-web-vm"
    Owner = var.owner
  }
}
