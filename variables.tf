################################################################################
# terraform-azurerm-munkirepo/variables.tf
################################################################################

# ==============================================================================
# RESOURCE GROUP
# ==============================================================================

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "munki"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "name_prefix" {
  description = "Prefix for resource names (will be sanitized for storage accounts)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# AZURE TENANT & SECURITY
# ==============================================================================

variable "azure_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  sensitive   = true
}

variable "devops_group_object_id" {
  description = "Object ID of the security group granted admin access to Key Vault and Storage"
  type        = string
  sensitive   = true
}

# ==============================================================================
# STORAGE
# ==============================================================================

variable "storage_account_name" {
  description = "Base name for storage account (will be prefixed and sanitized to 24 chars)"
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
  description = "Number of days to retain logs (both blob lifecycle and Log Analytics)"
  type        = number
  default     = 30
}

# ==============================================================================
# AUTHENTICATION
# ==============================================================================

variable "munki_username" {
  description = "Username for Basic Auth to Munki repository"
  type        = string
  sensitive   = true
}

variable "munki_password" {
  description = "Password for Basic Auth to Munki repository"
  type        = string
  sensitive   = true
}

variable "munki_client_token" {
  description = "Token for certificate-based auth (sent via X-Munki-Token header). Leave empty to disable."
  type        = string
  sensitive   = true
  default     = ""
}

# ==============================================================================
# FRONT DOOR
# ==============================================================================

variable "repo_path_patterns" {
  description = "URL path patterns for Munki repository (standard Munki folders)"
  type        = list(string)
  default     = ["/catalogs/*", "/icons/*", "/manifests/*", "/pkgs/*", "/pkgsinfo/*"]
}

# ==============================================================================
# MONITORING (Optional)
# ==============================================================================

variable "enable_monitoring" {
  description = "Enable Log Analytics and Application Insights"
  type        = bool
  default     = false
}
