output "endpoint_hostname" {
  description = "Front Door endpoint hostname (CNAME target)"
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "profile_id" {
  description = "Front Door profile ID"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "endpoint_id" {
  description = "Front Door endpoint ID"
  value       = azurerm_cdn_frontdoor_endpoint.this.id
}
