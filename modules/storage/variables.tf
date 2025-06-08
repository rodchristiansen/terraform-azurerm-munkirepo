variable "location" {}
variable "resource_group_name" {}
variable "name_prefix" {}
variable "storage_account_name" {}
variable "repo_container_name" {}
variable "log_container_name" {}
variable "log_retention_days" {}
variable "tags" { type = map(string) }
variable "devops_resource_infrasec_group_object_id" {
  type      = string
  sensitive = true
}
