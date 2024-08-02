variable "environment" {
  description = "The environment to deploy (dev, stage, production)"
  type        = string
}

variable "vm_count" {
  description = "Number of VMs per environment"
  type        = number
  default     = 2
}

variable "rg_location" {
  description = "location of resource group"
  type        = string
}

variable "ssh_key_path" {
  description = "path of local ssh key"
  type        = string
}

##SECRET VARS
#IMPROVEMENT: would normally pipe these in via CICD pipeline or secret service
variable "subscription_id" {
  description = "Subscription ID for the Azure account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "client_id" {
  description = "client ID for the Azure account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "client_secret" {
  description = "client secret for the Azure account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tenant_id" {
  description = "tenant ID for the Azure account"
  type        = string
  sensitive   = true
  default     = ""
}

#IMPROVEMENT: would be azure secrets
variable "admin_password" {
  description = "Admin password for the VMs"
  type        = string
  sensitive   = true
  default     = ""
}