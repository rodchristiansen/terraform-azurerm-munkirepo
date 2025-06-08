variable "location" {}
variable "resource_group_name" {}
variable "name_prefix" {}
variable "storage_account_name" {}
variable "blob_url_base" {}
variable "repo_container_name" {}
variable "app_service_plan_sku" {}
variable "munki_username" { sensitive = true }
variable "munki_password" { sensitive = true }
variable "storage_primary_access_key" { sensitive = true }

variable "tags" {
  type = map(string)
}

variable "azure_tenant_id" {
  type      = string
  sensitive = true
}

variable "devices_graph_id" {
  type      = string
  sensitive = true
}

variable "devices_graph_secret" {
  type      = string
  sensitive = true
}

variable "storage_connection_string" {
  type      = string
  sensitive = true
}
