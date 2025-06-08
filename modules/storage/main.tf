################################################################################
# STORAGE MODULE
################################################################################
locals {
  storage_account_name = lower(replace(substr("${var.name_prefix}${var.storage_account_name}",0,24), "/[^a-z0-9]/", ""))
}

resource "azurerm_storage_account" "repo" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      days = var.log_retention_days
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "repo" {
  name                 = var.repo_container_name
  storage_account_id   = azurerm_storage_account.repo.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                 = var.log_container_name
  storage_account_id   = azurerm_storage_account.repo.id
  container_access_type = "private"
}

# File-share + RBAC
resource "azurerm_storage_share" "fileshare" {
  name                 = var.repo_container_name
  storage_account_name = azurerm_storage_account.repo.name
  quota                = 500
}

resource "azurerm_role_assignment" "smb_contributor" {
  scope                = "${azurerm_storage_account.repo.id}/fileServices/default/shares/${azurerm_storage_share.fileshare.name}"
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_type       = "Group"
  principal_id         = var.devops_resource_infrasec_group_object_id
}

resource "azurerm_role_assignment" "blob_contributor_group" {
  scope                = azurerm_storage_account.repo.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_type       = "Group"
  principal_id         = var.devops_resource_infrasec_group_object_id
}

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
