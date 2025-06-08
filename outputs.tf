######################################
# terraform-azurerm-munkirepo/outputs.tf
######################################
output "cdn_hostname" {
  value       = module.frontdoor.endpoint_hostname
  description = "CNAME target for Munki repo."
}

output "storage_account_name" {
  value = module.storage.account_name
}
