## Create Resource Group for each VM
resource "azurerm_resource_group" "rg" {
  count    = var.vm_count
  name     = "${var.environment}-vm-rg-${count.index}"
  location = var.location_rg

  lifecycle {
    prevent_destroy = true
  }
}

## Create security group
resource "azurerm_network_security_group" "nsg" {
  count               = var.vm_count
  name                = "${var.environment}-nsg-${count.index}"
  location            = var.location_rg
  resource_group_name = azurerm_resource_group.rg[count.index].name

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = lookup(security_rule.value, "destination_port_range", null)
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      destination_port_ranges    = lookup(security_rule.value, "destination_port_ranges", null)
    }
  }
}

## Create network interface for vm
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.environment}-nic-${count.index}"
  location            = var.location_rg
  resource_group_name = azurerm_resource_group.rg[count.index].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

## Create VM
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.environment}-vm-${count.index}"
  location            = var.location_rg
  resource_group_name = azurerm_resource_group.rg[count.index].name
  size                = var.vm_config.vm_size
  admin_username      = var.vm_config.admin_username
  admin_password      = var.vm_config.admin_password

  admin_ssh_key {
    username   = var.vm_config.admin_username
    public_key = file(var.vm_config.ssh_key_path)
  }

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

## Create deletion lock for the VM
resource "azurerm_management_lock" "vm_lock" {
  count = var.vm_count
  name               = "vm-delete-lock-${count.index}"
  scope              = azurerm_linux_virtual_machine.vm[count.index].id
  lock_level         = "CanNotDelete"
  notes              = "This lock protects the VM from accidental deletion."
}

## Create backup
resource "azurerm_recovery_services_vault" "vault" {
  count               = var.vm_count
  name                = "${var.environment}-vault-${count.index}"
  location            = var.location_rg
  resource_group_name = azurerm_resource_group.rg[count.index].name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "policy" {
  count               = var.vm_count
  name                = "${var.environment}-policy-${count.index}"
  resource_group_name = azurerm_resource_group.rg[count.index].name
  recovery_vault_name = azurerm_recovery_services_vault.vault[count.index].name

  backup {
    frequency = var.backup_frequency
    time      = var.backup_time
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "backup" {
  count                = var.vm_count
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  recovery_vault_name  = azurerm_recovery_services_vault.vault[count.index].name
  source_vm_id         = azurerm_linux_virtual_machine.vm[count.index].id
  backup_policy_id     = azurerm_backup_policy_vm.policy[count.index].id
}
