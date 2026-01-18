################################################################################
# FRONT DOOR MODULE
# Routes directly to Azure Blob Storage with edge-based authentication
# Auth validated via Front Door Rules Engine
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

# ==============================================================================
# ORIGIN GROUPS
# ==============================================================================

# Origin group for authenticated access to private blob storage
resource "azurerm_cdn_frontdoor_origin_group" "private_storage" {
  name                     = "${var.name_prefix}-private-storage-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  # Health probe uses public container (no SAS needed)
  health_probe {
    path                = "/public/health.txt"
    protocol            = "Https"
    interval_in_seconds = 60
    request_type        = "GET"
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 2
    additional_latency_in_milliseconds = 0
  }
}

# Origin group for public container (bootstrap files, health probes)
resource "azurerm_cdn_frontdoor_origin_group" "public_storage" {
  name                     = "${var.name_prefix}-public-storage-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  health_probe {
    path                = "/public/health.txt"
    protocol            = "Https"
    interval_in_seconds = 60
    request_type        = "GET"
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 1
    additional_latency_in_milliseconds = 0
  }
}

# ==============================================================================
# ORIGINS - Direct to Blob Storage
# ==============================================================================

# Private storage origin
resource "azurerm_cdn_frontdoor_origin" "private_storage" {
  name                          = "${var.name_prefix}-private-storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.private_storage.id

  host_name                      = var.storage_blob_host
  priority                       = 1
  weight                         = 1000
  enabled                        = true
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.storage_blob_host
  certificate_name_check_enabled = true
}

# Public storage origin
resource "azurerm_cdn_frontdoor_origin" "public_storage" {
  name                          = "${var.name_prefix}-public-storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.public_storage.id

  host_name                      = var.storage_blob_host
  priority                       = 1
  weight                         = 1000
  enabled                        = true
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.storage_blob_host
  certificate_name_check_enabled = true
}

# ==============================================================================
# RULE SETS
# ==============================================================================

# Security headers rule set (applied to public routes)
resource "azurerm_cdn_frontdoor_rule_set" "security" {
  name                     = "${var.name_prefix}securityrules"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

# Authentication rule set for private blob access
resource "azurerm_cdn_frontdoor_rule_set" "blob_auth" {
  name                     = "${var.name_prefix}blobauthentication"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

# ==============================================================================
# AUTHENTICATION RULES
# Validates auth headers at edge and appends SAS token for blob access
# ==============================================================================

# Rule: Validate Basic Auth and append SAS token
# Matches: Authorization: Basic <base64(username:password)>
resource "azurerm_cdn_frontdoor_rule" "auth_basic" {
  name                      = "basicauth"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.blob_auth.id
  order                     = 1
  behavior_on_match         = "Stop" # Stop processing if Basic Auth matches

  conditions {
    request_header_condition {
      header_name      = "Authorization"
      operator         = "Equal"
      negate_condition = false
      match_values     = ["Basic ${base64encode("${var.munki_username}:${var.munki_password}")}"]
      transforms       = []
    }
  }

  actions {
    # Strip the Authorization header before forwarding to blob storage
    request_header_action {
      header_action = "Delete"
      header_name   = "Authorization"
    }

    # Append SAS token as query string for blob access
    url_rewrite_action {
      source_pattern          = "/"
      destination             = "/{url_path}?${trimprefix(var.sas_token, "?")}"
      preserve_unmatched_path = false
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.private_storage,
    azurerm_cdn_frontdoor_origin_group.private_storage
  ]
}

# Rule: Validate Token Auth (for certificate-based devices)
# Matches: X-Munki-Token: <token>
resource "azurerm_cdn_frontdoor_rule" "auth_token" {
  count = var.munki_client_token != "" ? 1 : 0

  name                      = "tokenauth"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.blob_auth.id
  order                     = 2
  behavior_on_match         = "Stop"

  conditions {
    request_header_condition {
      header_name      = "X-Munki-Token"
      operator         = "Equal"
      negate_condition = false
      match_values     = [var.munki_client_token]
      transforms       = []
    }
  }

  actions {
    # Strip the token header before forwarding
    request_header_action {
      header_action = "Delete"
      header_name   = "X-Munki-Token"
    }

    # Append SAS token as query string for blob access
    url_rewrite_action {
      source_pattern          = "/"
      destination             = "/{url_path}?${trimprefix(var.sas_token, "?")}"
      preserve_unmatched_path = false
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.private_storage,
    azurerm_cdn_frontdoor_origin_group.private_storage
  ]
}

# Note: No explicit deny rule needed.
# Unauthenticated requests proceed without SAS token and receive 403/404 from Azure Blob Storage.

# Security headers rule
resource "azurerm_cdn_frontdoor_rule" "security_headers" {
  name                      = "securityheaders"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.security.id
  order                     = 1
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Append"
      header_name   = "X-Content-Type-Options"
      value         = "nosniff"
    }
  }

  conditions {
    request_scheme_condition {
      match_values = ["HTTPS"]
      operator     = "Equal"
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.public_storage,
    azurerm_cdn_frontdoor_origin_group.public_storage
  ]
}

# Cache headers for catalogs/manifests (short TTL - these change frequently)
resource "azurerm_cdn_frontdoor_rule" "cache_headers" {
  name                      = "cacheheaders"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.security.id
  order                     = 2
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Overwrite"
      header_name   = "Cache-Control"
      value         = "public, max-age=300, stale-while-revalidate=60"
    }
  }

  conditions {
    url_path_condition {
      operator         = "BeginsWith"
      negate_condition = false
      match_values     = ["/catalogs/", "/manifests/"]
      transforms       = ["Lowercase"]
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.public_storage,
    azurerm_cdn_frontdoor_origin_group.public_storage
  ]
}

# ==============================================================================
# ROUTES
# ==============================================================================

# Main route for Munki repository paths - DIRECT TO BLOB STORAGE
resource "azurerm_cdn_frontdoor_route" "munki_blob" {
  name                          = "${var.name_prefix}-munki-blob-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.private_storage.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.private_storage.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.blob_auth.id]
  enabled                       = true

  forwarding_protocol       = "HttpsOnly"
  https_redirect_enabled    = true
  patterns_to_match         = var.repo_path_patterns
  supported_protocols       = ["Http", "Https"]
  cdn_frontdoor_origin_path = "/${var.repo_container_name}" # Map to the repo container

  cache {
    query_string_caching_behavior = "UseQueryString" # Include SAS token in cache key
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "application/javascript", "application/json", "text/plain", "application/xml", "text/xml"]
  }
}

# Public route for bootstrap files
resource "azurerm_cdn_frontdoor_route" "bootstrap_public" {
  name                          = "${var.name_prefix}-bootstrap-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.public_storage.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.public_storage.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.security.id]
  enabled                       = true

  forwarding_protocol       = "HttpsOnly"
  https_redirect_enabled    = true
  patterns_to_match         = ["/bootstrap/*"]
  supported_protocols       = ["Http", "Https"]
  cdn_frontdoor_origin_path = "/public/bootstrap"

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["application/json", "text/plain", "application/xml"]
  }
}

# General public blob route
resource "azurerm_cdn_frontdoor_route" "public_blob" {
  name                          = "${var.name_prefix}-public-blob-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.public_storage.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.public_storage.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.security.id]
  enabled                       = true

  forwarding_protocol       = "HttpsOnly"
  https_redirect_enabled    = true
  patterns_to_match         = ["/public/*"]
  supported_protocols       = ["Http", "Https"]
  cdn_frontdoor_origin_path = "" # Pass through /public/... to storage

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["application/json", "text/plain", "application/xml"]
  }
}
