variable "resource_group_name" {}

variable "vm" {}

variable "disks" {}

variable "location" {}

variable "vm_name" {}

resource "azurerm_resource_group" "example" {
    name  = var.resource_group_name
    location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name              = var.vm_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = var.vm["size"]

  disable_password_authentication = false
  admin_username      = var.vm["admin_user"]
  admin_password      = var.vm["admin_password"]
  network_interface_ids = [
    azurerm_network_interface.example.id
  ]

  # admin_ssh_key {
  #   username   = "adminuser"
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "example" {
  count       = length(var.vm["disks"])
  name        = "datadisk-${count.index}"
  location    = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb    = element(var.vm["disks"], count.index)
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  count              = length(var.vm["disks"])
  managed_disk_id    = element(azurerm_managed_disk.example.*.id, count.index)
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = count.index
  caching            = "ReadWrite"
}
