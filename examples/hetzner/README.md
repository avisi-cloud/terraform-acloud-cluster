# Full Example: Hetzner

This example deploys an Avisi Cloud Kubernetes cluster using Hetzner.

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acloud_api"></a> [acloud\_api](#input\_acloud\_api) | n/a | `any` | n/a | yes |
| <a name="input_acloud_token"></a> [acloud\_token](#input\_acloud\_token) | n/a | `any` | n/a | yes |
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | n/a | `any` | n/a | yes |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | A unique identifier for the environment within the organisation. Required. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | A unique identifier for the organisation. This is used to distinguish resources across different organisations. Required. | `string` | n/a | yes |

## Outputs

No outputs.
