################################################################################
# terraform-azurerm-munkirepo/outputs.tf
################################################################################

output "cdn_hostname" {
  description = "Front Door endpoint hostname - use this as the CNAME target for your custom domain"
  value       = module.frontdoor.endpoint_hostname
}

output "storage_account_name" {
  description = "Name of the Azure Storage Account hosting the Munki repository"
  value       = module.storage.account_name
}

output "storage_blob_endpoint" {
  description = "Primary blob endpoint URL for the storage account"
  value       = module.storage.primary_blob_endpoint
}

output "sas_token_expiry" {
  description = "Expiry date of the SAS token (run terraform apply annually to renew)"
  value       = module.storage.sas_token_expiry
}

output "repo_container_name" {
  description = "Name of the private container for Munki repository files"
  value       = module.storage.repo_container_name
}

output "public_container_name" {
  description = "Name of the public container for bootstrap files and health probes"
  value       = module.storage.public_container_name
}

output "key_vault_name" {
  description = "Name of the Key Vault storing secrets"
  value       = azurerm_key_vault.munki.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.munki.vault_uri
}

output "frontdoor_profile_id" {
  description = "ID of the Front Door profile (for custom domain setup)"
  value       = module.frontdoor.profile_id
}
