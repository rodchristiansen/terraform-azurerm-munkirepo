variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Base name for storage account (will be prefixed and sanitized)"
  type        = string
  default     = "munkirepo"
}

variable "repo_container_name" {
  description = "Name of the private container for Munki repository"
  type        = string
  default     = "repo"
}

variable "log_container_name" {
  description = "Name of the container for logs"
  type        = string
  default     = "logs"
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted blobs"
  type        = number
  default     = 7
}

variable "log_retention_days" {
  description = "Number of days to retain logs before auto-deletion"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "devops_group_object_id" {
  description = "Object ID of the security group granted admin access to storage"
  type        = string
  sensitive   = true
}
