output "vm_ids" {
  value = azurerm_linux_virtual_machine.vm.*.id
}
