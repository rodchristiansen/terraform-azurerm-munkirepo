output "account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.repo.name
}

output "primary_access_key" {
  description = "Primary access key for storage account"
  value       = azurerm_storage_account.repo.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for storage account"
  value       = azurerm_storage_account.repo.primary_connection_string
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.repo.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "Primary blob host (for Front Door origin)"
  value       = azurerm_storage_account.repo.primary_blob_host
}

output "repo_container_name" {
  description = "Name of the repo container"
  value       = azurerm_storage_container.repo.name
}

output "public_container_name" {
  description = "Name of the public container"
  value       = azurerm_storage_container.public.name
}

output "sas_token" {
  description = "SAS token for read-only blob access (1-year validity)"
  value       = data.azurerm_storage_account_sas.blob_read_sas.sas
  sensitive   = true
}

output "sas_token_expiry" {
  description = "Expiry date of the SAS token"
  value       = timeadd(timestamp(), "8760h")
}
