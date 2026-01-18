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

variable "storage_blob_host" {
  description = "Blob storage host (e.g., mystorageaccount.blob.core.windows.net)"
  type        = string
}

variable "repo_container_name" {
  description = "Name of the private repo container in blob storage"
  type        = string
  default     = "repo"
}

variable "sas_token" {
  description = "SAS token for read-only blob access (from storage module)"
  type        = string
  sensitive   = true
}

variable "munki_username" {
  description = "Username for Basic Auth"
  type        = string
  sensitive   = true
}

variable "munki_password" {
  description = "Password for Basic Auth"
  type        = string
  sensitive   = true
}

variable "munki_client_token" {
  description = "Token for certificate-based auth (X-Munki-Token header)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "repo_path_patterns" {
  description = "URL path patterns for Munki repository access (standard Munki folders)"
  type        = list(string)
  default     = ["/catalogs/*", "/icons/*", "/manifests/*", "/pkgs/*", "/pkgsinfo/*"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
