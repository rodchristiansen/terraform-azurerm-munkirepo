################################################################################
# STORAGE MODULE
# Provides Azure Storage for Munki repository with private and public containers
################################################################################
locals {
  storage_account_name = lower(replace(substr("${var.name_prefix}${var.storage_account_name}", 0, 24), "/[^a-z0-9]/", ""))
}

resource "azurerm_storage_account" "repo" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  tags = var.tags
}

# Private container for Munki repository (packages, manifests, etc.)
resource "azurerm_storage_container" "repo" {
  name                  = var.repo_container_name
  storage_account_id    = azurerm_storage_account.repo.id
  container_access_type = "private"
}

# Private container for logs
resource "azurerm_storage_container" "logs" {
  name                  = var.log_container_name
  storage_account_id    = azurerm_storage_account.repo.id
  container_access_type = "private"
}

# Public container for bootstrap files and health probes
resource "azurerm_storage_container" "public" {
  name                  = "public"
  storage_account_id    = azurerm_storage_account.repo.id
  container_access_type = "blob" # Anonymous read access for blobs
}

# File-share for SMB access (admin/MWA2)
resource "azurerm_storage_share" "fileshare" {
  name               = var.repo_container_name
  storage_account_id = azurerm_storage_account.repo.id
  quota              = 500
}

# Lifecycle management - auto-delete logs after retention period
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.repo.id

  rule {
    name    = "log-lifecycle-management"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.log_retention_days
      }
    }
  }
}

# RBAC: SMB Contributor for admin access to file share
resource "azurerm_role_assignment" "smb_contributor" {
  scope                = "${azurerm_storage_account.repo.id}/fileServices/default/shares/${azurerm_storage_share.fileshare.name}"
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_type       = "Group"
  principal_id         = var.devops_group_object_id
}

# RBAC: Blob Data Contributor for admin access to storage
resource "azurerm_role_assignment" "blob_contributor_group" {
  scope                = azurerm_storage_account.repo.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_type       = "Group"
  principal_id         = var.devops_group_object_id
}

# RBAC: Blob Data Owner for admin full control
resource "azurerm_role_assignment" "blob_owner_group" {
  scope                = azurerm_storage_account.repo.id
  role_definition_name = "Storage Blob Data Owner"
  principal_type       = "Group"
  principal_id         = var.devops_group_object_id
}

# SAS token for read-only blob access (1 year validity, renewed via Terraform)
data "azurerm_storage_account_sas" "blob_read_sas" {
  connection_string = azurerm_storage_account.repo.primary_connection_string
  https_only        = true
  signed_version    = "2022-11-02"

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  # Start from yesterday to account for clock skew
  start = timeadd(timestamp(), "-24h")
  # Valid for 1 year - Terraform apply will renew
  expiry = timeadd(timestamp(), "8760h")

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}
