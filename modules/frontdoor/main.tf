################################################################################
# FRONT DOOR MODULE
################################################################################
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "${var.name_prefix}-munki-frontdoor"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "${var.name_prefix}-munki-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "${var.name_prefix}-munki-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  health_probe {
    path     = "/"
    protocol = "Https"
    interval_in_seconds = 30
    request_type        = "GET"
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 2
    additional_latency_in_milliseconds = 0
  }
}

resource "azurerm_cdn_frontdoor_origin" "function" {
  name                           = "${var.name_prefix}-munki-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  host_name                      = var.origin_hostname
  http_port                      = 80
  https_port                     = 443
  enabled                        = true
  priority                       = 1
  weight                         = 1000
  origin_host_header             = var.origin_hostname
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_rule_set" "this" {
  name                     = "${var.name_prefix}-munki-frontdoor-rules"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_rule" "basic_auth" {
  name                      = "${var.name_prefix}-munki-basic-auth"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this.id
  order                     = 1
  behavior_on_match         = "Continue"

  actions {
    request_header_action {
      header_action = "Overwrite"
      header_name   = "Authorization"
      value         = "Basic ${base64encode("${var.munki_username}:${var.munki_password}")}"
    }
  }

  conditions {
    request_scheme_condition {
      match_values = ["HTTPS"]
      operator     = "Equal"
    }
  }

  depends_on = [azurerm_cdn_frontdoor_origin.function]
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "${var.name_prefix}-munki-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.function.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.this.id]
  forwarding_protocol           = "HttpsOnly"
  https_redirect_enabled        = true
  enabled                       = true
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "application/javascript", "application/json"]
  }
}

output "endpoint_hostname" { value = azurerm_cdn_frontdoor_endpoint.this.host_name }
