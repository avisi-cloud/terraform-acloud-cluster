# AWS Multi-AZ Example

This example provisions an AME Kubernetes cluster on AWS with multi availability zones enabled and three node pools: `database`, `apps`, and `ingress`.

Use it as a starting point when you want the module to manage both the AME cluster and a small set of standard node pools. The `database` node pool shows how to override the default availability-zone behavior for one pool while the other pools inherit the module defaults.

```hcl
module "cluster" {
  source = "../../"

  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = var.cluster_name
  cloud_account_name = var.cloud_account_name

  region         = var.region
  cloud_provider = var.cloud_provider

  enable_multi_availability_zones = true
  default_node_size               = "t3.medium"
  default_node_count              = 1

  node_pools = {
    database = {
      enable_multi_availability_zones = false
      availability_zone               = "eu-central-1b"
    }

    apps    = {}
    ingress = {}
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
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of the AWS cloud account in Avisi Cloud Console. | `string` | n/a | yes |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Avisi Cloud provider slug for AWS. | `string` | `"aws"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name for the example cluster. | `string` | `"example"` | no |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of the Avisi Cloud environment where the example cluster is created. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of the Avisi Cloud organisation that owns the example environment. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the example cluster. | `string` | `"eu-central-1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
