# terraform-azurerm-munkirepo

Terraform module that provisions an **Azure**-backed [Munki](https://github.com/munki/munki) repository with global CDN and edge-based authentication.

## Architecture

```
                     Internet
                        │
                        ▼
        ┌───────────────────────────────────┐
        │  Azure Front Door (CDN Standard)  │
        │  - Global content delivery        │
        │  - Edge-based authentication      │
        │  - SAS token injection            │
        └────────────────┬──────────────────┘
                         │ HTTPS
                         ▼
        ┌───────────────────────────────────┐
        │      Azure Storage Account        │
        │  - "repo" container               │
        │  - "public" container             │
        │  - "logs" container               │
        └───────────────────────────────────┘
```

**Key Features of this infra:**
- **No Function App required** - Authentication happens at the Front Door edge
- **Cost-effective** - No compute costs, just storage and CDN
- **Simple** - No code to maintain or deploy
- **Secure** - Private blob storage with SAS token access
- **Two authentication methods** - Basic Auth and token-based auth

## How Authentication Works

1. Client sends request to Front Door with `Authorization: Basic <credentials>` header (or `X-Munki-Token` header)
2. Front Door Rules Engine validates the header value
3. If valid: Authorization header is stripped, SAS token is appended to URL, request routes to blob
4. If invalid: Request goes to blob without SAS token, returns 403/404

## Usage

```hcl
module "munki_repo" {
  source = "github.com/your-org/terraform-azurerm-munkirepo"

  # Required
  azure_tenant_id        = "your-tenant-id"
  devops_group_object_id = "security-group-object-id"
  munki_username         = "admin"
  munki_password         = "s3cret"

  # Optional
  location           = "East US"
  name_prefix        = "prod"
  munki_client_token = "optional-token-for-cert-auth"

  tags = {
    project = "munki"
    env     = "production"
  }
}
```

After `terraform apply`:
1. Create a CNAME record pointing your custom domain to the `cdn_hostname` output
2. Upload a `health.txt` file to the `public` container for health probes
3. Upload your Munki repository files to the `repo` container

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `azure_tenant_id` | Azure AD tenant ID | `string` | - | Yes |
| `devops_group_object_id` | Security group for admin access | `string` | - | Yes |
| `munki_username` | Basic Auth username | `string` | - | Yes |
| `munki_password` | Basic Auth password | `string` | - | Yes |
| `munki_client_token` | Token for X-Munki-Token auth | `string` | `""` | No |
| `create_resource_group` | Create RG or use existing | `bool` | `true` | No |
| `resource_group_name` | Resource group name | `string` | `"munki"` | No |
| `location` | Azure region | `string` | `"East US"` | No |
| `name_prefix` | Prefix for resource names | `string` | `""` | No |
| `storage_account_name` | Base storage account name | `string` | `"munkirepo"` | No |
| `repo_container_name` | Private repo container | `string` | `"repo"` | No |
| `log_container_name` | Logs container | `string` | `"logs"` | No |
| `soft_delete_retention_days` | Blob soft delete days | `number` | `7` | No |
| `log_retention_days` | Log retention days | `number` | `30` | No |
| `repo_path_patterns` | URL paths to protect | `list(string)` | `["/catalogs/*", "/icons/*", "/manifests/*", "/pkgs/*", "/pkgsinfo/*"]` | No |
| `enable_monitoring` | Enable Log Analytics | `bool` | `false` | No |
| `tags` | Resource tags | `map(string)` | `{}` | No |

## Outputs

| Name | Description |
|------|-------------|
| `cdn_hostname` | Front Door hostname (CNAME target) |
| `storage_account_name` | Storage account name |
| `storage_blob_endpoint` | Blob storage endpoint |
| `sas_token_expiry` | When the SAS token expires |
| `repo_container_name` | Private container name |
| `public_container_name` | Public container name |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI |
| `frontdoor_profile_id` | Front Door profile ID |

## SAS Token Renewal

The SAS token is valid for 1 year. Run `terraform apply` annually to generate a new token. The token expiry date is available in the `sas_token_expiry` output.

## Custom Domain Setup

1. Add a CNAME record: `munki.yourdomain.com` → `<cdn_hostname>`
2. Add custom domain in Azure Front Door (via Azure Portal or additional Terraform)
3. Enable managed TLS certificate

## Migration from Function-Based Architecture

If migrating from the previous Function App architecture:

1. Run `terraform apply` to deploy the new infrastructure
2. The Function App and Service Plan will be destroyed
3. Update any DNS records if needed
4. Test authentication works with your Munki clients

## License

MIT
