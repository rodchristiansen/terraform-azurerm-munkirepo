################################################################################
# FUNCTION MODULE
################################################################################

resource "azurerm_service_plan" "this" {
  name                = "${var.name_prefix}-munki-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "${var.name_prefix}-munki-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                       = "${var.name_prefix}-munki-functions"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_primary_access_key
  https_only                 = true

  site_config {
    always_on     = true
    ftps_state    = "Disabled"
    http2_enabled = true
    application_stack { python_version = "3.11" }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME            = "python"
    FUNCTIONS_EXTENSION_VERSION         = "~4"
    WEBSITE_RUN_FROM_PACKAGE            = "1"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE     = "true"
    APPINSIGHTS_INSTRUMENTATIONKEY      = azurerm_application_insights.this.instrumentation_key
    BLOB_STORAGE_URL                    = "${var.blob_url_base}${var.repo_container_name}/"
    AZURE_STORAGE_ACCOUNT               = var.storage_account_name
    AZURE_STORAGE_CONTAINER             = var.repo_container_name
    AZURE_STORAGE_CONNECTION_STRING     = var.storage_connection_string
    AZURE_TENANT_ID                     = var.azure_tenant_id
    DEVICES_GRAPH_ID                    = var.devices_graph_id
    DEVICES_GRAPH_SECRET                = var.devices_graph_secret
    MUNKI_USERNAME                      = var.munki_username
    MUNKI_PASSWORD                      = var.munki_password
  }

  identity { type = "SystemAssigned" }
  tags     = var.tags
}

output "default_hostname" {
  value = azurerm_linux_function_app.this.default_hostname
}
