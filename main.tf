################################################################################
# terraform-azurerm-munkirepo
# 
# Azure infrastructure for hosting a Munki repository with:
# - Azure Front Door for CDN and edge-based authentication
# - Azure Blob Storage for repository files
# - Direct blob access from Front Door using SAS token injection
# 
# Architecture:
#   Client -> Front Door (auth rules + SAS injection) -> Blob Storage
################################################################################

terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ==============================================================================
# RESOURCE GROUP
# ==============================================================================

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  rg_name     = var.resource_group_name
  rg_location = var.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location

  # Secrets to store in Key Vault
  secrets_map = {
    MunkiUsername    = var.munki_username
    MunkiPassword    = var.munki_password
    MunkiClientToken = var.munki_client_token
  }
}

# ==============================================================================
# KEY VAULT
# ==============================================================================

resource "azurerm_key_vault" "munki" {
  name                       = "${var.name_prefix}-munki-secrets"
  location                   = var.location
  resource_group_name        = local.rg_name
  sku_name                   = "standard"
  tenant_id                  = var.azure_tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  enable_rbac_authorization  = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "kv_admin_group" {
  scope                = azurerm_key_vault.munki.id
  role_definition_name = "Key Vault Administrator"
  principal_type       = "Group"
  principal_id         = var.devops_group_object_id
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each     = { for k, v in local.secrets_map : k => v if v != "" }
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.munki.id
}

# ==============================================================================
# STORAGE MODULE
# ==============================================================================

module "storage" {
  source = "./modules/storage"

  location            = var.location
  resource_group_name = local.rg_name
  name_prefix         = var.name_prefix

  storage_account_name       = var.storage_account_name
  repo_container_name        = var.repo_container_name
  log_container_name         = var.log_container_name
  soft_delete_retention_days = var.soft_delete_retention_days
  log_retention_days         = var.log_retention_days
  devops_group_object_id     = var.devops_group_object_id

  tags = var.tags
}

# ==============================================================================
# FRONT DOOR MODULE
# ==============================================================================

module "frontdoor" {
  source = "./modules/frontdoor"

  location            = var.location
  resource_group_name = local.rg_name
  name_prefix         = var.name_prefix

  storage_blob_host   = module.storage.primary_blob_host
  repo_container_name = var.repo_container_name
  sas_token           = module.storage.sas_token
  munki_username      = var.munki_username
  munki_password      = var.munki_password
  munki_client_token  = var.munki_client_token
  repo_path_patterns  = var.repo_path_patterns

  tags = var.tags
}

# ==============================================================================
# LOG ANALYTICS & APPLICATION INSIGHTS (Optional monitoring)
# ==============================================================================

resource "azurerm_log_analytics_workspace" "munki" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.name_prefix}-munki-logs"
  location            = var.location
  resource_group_name = local.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

resource "azurerm_application_insights" "munki" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.name_prefix}-munki-insights"
  location            = var.location
  resource_group_name = local.rg_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.munki[0].id

  tags = var.tags
}
