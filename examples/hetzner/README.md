# Hetzner Example

This example provisions an AME Kubernetes cluster on Hetzner with three node pools: `data`, `app`, and `custom-pool`.

Use it when you want a compact provider-specific example that shows the same module interface with Hetzner region and node-size values. The example disables multi availability zones because the provider example pins the cluster to the single configured region.

```hcl
module "cluster" {
  source = "../../"

  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = var.cluster_name
  cloud_account_name = var.cloud_account_name

  region         = var.region
  cloud_provider = var.cloud_provider

  enable_multi_availability_zones = false
  default_node_size               = "cx33"
  default_node_count              = 1

  node_pools = {
    data          = {}
    app           = {}
    "custom-pool" = {}
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_acloud"></a> [acloud](#requirement\_acloud) | >= 0.5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acloud_api"></a> [acloud\_api](#input\_acloud\_api) | Avisi Cloud API base URL. | `string` | n/a | yes |
| <a name="input_acloud_token"></a> [acloud\_token](#input\_acloud\_token) | Avisi Cloud Personal Access Token. | `string` | n/a | yes |
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of the Hetzner cloud account in Avisi Cloud Console. | `string` | n/a | yes |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Avisi Cloud provider slug for Hetzner. | `string` | `"hetzner"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name for the example cluster. | `string` | `"example"` | no |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of the Avisi Cloud environment where the example cluster is created. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of the Avisi Cloud organisation that owns the example environment. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Hetzner region for the example cluster. | `string` | `"fsn1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
