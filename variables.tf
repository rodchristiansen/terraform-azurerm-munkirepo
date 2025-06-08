#######################################
# terraform-azurerm-munkirepo/variables.tf
#######################################
variable "create_resource_group" {
  type        = bool
  default     = true
  description = "Whether to create an RG."
}

variable "resource_group_name" {
  type        = string
  default     = "munki"
  description = "Name of the RG."
}

variable "location" {
  type        = string
  default     = "Canada Central"
  description = "Azure region."
}

variable "name_prefix" {
  type        = string
  default     = ""
  description = "Optional resource-name prefix."
}

variable "storage_account_name" {
  type        = string
  default     = "munkirepo"
}

variable "repo_container_name" {
  type        = string
  default     = "repo"
}

variable "log_container_name" {
  type        = string
  default     = "logs"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "munki_username" {
  type      = string
  sensitive = true
}

variable "munki_password" {
  type      = string
  sensitive = true
}

variable "app_service_plan_sku" {
  type    = string
  default = "B1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID hosting the resources"
  type        = string
  sensitive   = true
}

variable "devops_resource_infrasec_group_object_id" {
  description = "Security-group object ID granted admin on Key Vault + Storage"
  type        = string
  sensitive   = true
}

variable "devices_graph_id" {
  description = "Service-principal client ID for Intune device Graph access"
  type        = string
  sensitive   = true
}

variable "devices_graph_secret" {
  description = "Service-principal secret for Graph"
  type        = string
  sensitive   = true
}
