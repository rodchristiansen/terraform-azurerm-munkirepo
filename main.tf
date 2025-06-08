######################################
# terraform-azurerm-munkirepo/main.tf
######################################
terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.92"
    }
  }
}

provider "azurerm" {
  features {}
}

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

# Note: local.rg_name always uses var.resource_group_name.
# If create_resource_group = false, the RG must exist.
locals {
  rg_name = var.resource_group_name

  secrets_map = {
    MunkiUsername      = var.munki_username
    MunkiPassword      = var.munki_password
    DevicesGraphId     = var.devices_graph_id
    DevicesGraphSecret = var.devices_graph_secret
  }
}

# ─────────────────────── Key Vault + secrets ───────────────────────
resource "azurerm_key_vault" "munki" {
  name                        = "${var.name_prefix}-munki-secrets"
  location                    = var.location
  resource_group_name         = local.rg_name
  sku_name                    = "standard"
  tenant_id                   = var.azure_tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enable_rbac_authorization   = true

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
  principal_id         = var.devops_resource_infrasec_group_object_id
}

# Adding Secrets to Azure Key Vault
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = local.secrets_map
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.munki.id
}

# Note: location defaults to "Canada Central" unless overridden.

# Storage
module "storage" {
  source = "./modules/storage"

  location            = var.location
  resource_group_name = local.rg_name
  name_prefix         = var.name_prefix

  storage_account_name = var.storage_account_name
  repo_container_name  = var.repo_container_name
  log_container_name   = var.log_container_name
  log_retention_days   = var.log_retention_days

  tags = var.tags
  devops_resource_infrasec_group_object_id = var.devops_resource_infrasec_group_object_id
}

# Function
module "function" {
  source = "./modules/function"

  location                    = var.location
  resource_group_name         = local.rg_name
  name_prefix                 = var.name_prefix

  storage_account_name        = module.storage.account_name
  storage_primary_access_key  = module.storage.primary_access_key
  blob_url_base               = module.storage.repo_container_url
  repo_container_name         = var.repo_container_name

  munki_username              = var.munki_username
  munki_password              = var.munki_password
  app_service_plan_sku        = var.app_service_plan_sku

  tags = var.tags

  azure_tenant_id           = var.azure_tenant_id
  devices_graph_id          = var.devices_graph_id
  devices_graph_secret      = var.devices_graph_secret
  storage_connection_string = module.storage.primary_connection_string
}

# FrontDoor
module "frontdoor" {
  source = "./modules/frontdoor"

  location            = var.location
  resource_group_name = local.rg_name
  name_prefix         = var.name_prefix

  origin_hostname     = module.function.default_hostname
  munki_username      = var.munki_username
  munki_password      = var.munki_password
  repo_path_patterns  = ["/deployment/*", "/packages/*", "/profiles/*", "/provisioning/*"]

  tags = var.tags
}

output "cdn_hostname" {
  description = "Front Door endpoint to CNAME."
  value       = module.frontdoor.endpoint_hostname
}

output "storage_account_name" {
  description = "Azure Storage Account name hosting Munki repo."
  value       = module.storage.account_name
}
