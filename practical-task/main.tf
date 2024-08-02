provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

## Create Overall Resource Group for VPC and Subnet
resource "azurerm_resource_group" "network_rg" {
  name     = "${var.environment}-network-rg"
  location = var.rg_location
}

## Create Virtual Network and Subnet
#IMPROVEMENT: CIDRs could come from elsewhere (pipeline, specialized CIDR module, etc.)
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

## Spin up VMs
module "vm" {
  source      = "modules/vm"
  environment = var.environment
  location_rg = var.rg_location
  subnet_id   = azurerm_subnet.subnet.id
  vm_count    = 2
  vm_config = {
    vm_size        = "Standard_D2a_v4"
    admin_username = "adminuser"
    admin_password = var.admin_password
    ssh_key_path   = var.ssh_key_path
  }
  security_rules = [
    {
      name                       = "Allow-SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-DNS-HTTP-HTTPS"
      priority                   = 1002
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["53", "80", "443"]
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}
