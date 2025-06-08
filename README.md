# terraform-azurerm-munkirepo

Terraform module that provisions an **Azure**-backed [Munki](https://github.com/munki/munki) repository with global CDN and Basic Authentication—functionally similar to [`terraform-aws-munki-repo`](https://github.com/grahamgilbert/terraform-aws-munki-repo).

## Features

* **Azure Storage** (Blob) to host repo content and logs  
* **Azure CDN Front Door (Standard)** for global content delivery  
* **Azure Functions (Linux)** stub to enable/extend Basic Auth  
* Configurable retention and fully tagged resources  

## Usage

```hcl
module "munki_repo" {
  source = "github.com/your-org/terraform-azurerm-munkirepo"

  munki_username = "admin"
  munki_password = "s3cret"
  location       = "Canada Central"
  name_prefix    = "prod"

  tags = {
    project = "munki"
    env     = "production"
  }
}
```

After `terraform apply`, configure a CNAME (or Apex ALIAS) pointing to the output **cdn_hostname**.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_resource_group | Create RG if true | `bool` | `true` |
| resource_group_name | Existing or new RG name | `string` | `"munki"` |
| location | Azure region (default: "Canada Central") | `string` | `"Canada Central"` |
| name_prefix | Prefix for all resource names | `string` | `""` |
| storage_account_name | Base Storage Account name | `string` | `"munkirepo"` |
| repo_container_name | Blob container for repo | `string` | `"repo"` |
| log_container_name | Blob container for logs | `string` | `"logs"` |
| log_retention_days | Soft‑delete retention days | `number` | `30` |
| munki_username | **Required** Basic Auth user | `string` | n/a |
| munki_password | **Required** Basic Auth pass | `string` | n/a |
| app_service_plan_sku | App Service Plan SKU | `string` | `"B1"` |
| tags | Resource tags | `map(string)` | `{}` |

> **Note:** If `create_resource_group = false`, the resource group specified by `resource_group_name` must already exist.

## Outputs

| Name | Description |
|------|-------------|
| cdn_hostname | CDN endpoint to publish |
| storage_account_name | Storage account hosting the repo |

## License

MIT
