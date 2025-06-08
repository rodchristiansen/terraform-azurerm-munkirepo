variable "location" {}
variable "resource_group_name" {}
variable "name_prefix" {}
variable "origin_hostname" {}
variable "munki_username" { sensitive = true }
variable "munki_password" { sensitive = true }
variable "repo_path_patterns" { type = list(string) }
variable "tags" { type = map(string) }
