variable "environment" {
  description = "The environment name"
  type        = string
}

variable "vm_count" {
  description = "number of VMs to create"
  type        = number
}

variable "location_rg" {
  description = "Resource Group location"
  type        = string
}

variable "vm_config" {
  description = "VM configuration"
  type = object({
    vm_size            = string
    admin_username     = string
    admin_password     = string
    ssh_key_path       = string
  })
}

variable "security_rules" {
  description = "Security rules to apply to NSG"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = optional(string)
    source_address_prefix      = string
    destination_address_prefix = string
    destination_port_ranges    = optional(list(string))
  }))
}

variable "subnet_id" {
  description = "ID of the subnet to be used by the VMs"
  type        = string
}

variable "backup_frequency" {
  description = "the frequency of backups"
  type        = string
  default     = "Daily"
}

variable "backup_time" {
  description = "The time of day to perform the backup"
  type        = string
  default     = "23:00"
}



