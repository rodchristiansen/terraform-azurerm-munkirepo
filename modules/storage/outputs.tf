output "account_name" {
  value = azurerm_storage_account.repo.name
}

output "primary_access_key" {
  value     = azurerm_storage_account.repo.primary_access_key
  sensitive = true
}

output "repo_container_url" {
  value = azurerm_storage_account.repo.primary_blob_endpoint
}
