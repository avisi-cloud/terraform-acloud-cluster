# Avisi Cloud Kubernetes Cluster

This module is designed to simplify the provisioning of a Kubernetes cluster using the Avisi Cloud platform, on any Cloud Provider supported by [Avisi Cloud Kubernetes](https://docs.avisi.cloud/product/kubernetes/).

## Notes
- Make sure you have your cloud account configured. See [how-to docs](https://docs.avisi.cloud/docs/how-to/cloud-accounts/)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_acloud"></a> [acloud](#requirement\_acloud) | >= 0.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_acloud"></a> [acloud](#provider\_acloud) | 0.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nodepool"></a> [nodepool](#module\_nodepool) | avisi-cloud/nodepool/acloud | 0.0.3 |

## Resources

| Name | Type |
|------|------|
| [acloud_cluster.cluster](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/resources/cluster) | resource |
| [acloud_cloud_account.account](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/cloud_account) | data source |
| [acloud_cloud_provider_availability_zones.zones](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/cloud_provider_availability_zones) | data source |
| [acloud_update_channel.channel](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/update_channel) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Cloud account name | `string` | n/a | yes |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Slug of the cloud provider used for provisioning the cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster | `string` | n/a | yes |
| <a name="input_default_node_annotations"></a> [default\_node\_annotations](#input\_default\_node\_annotations) | Default custom node annotations for nodes within a node pool | `map` | `{}` | no |
| <a name="input_default_node_count"></a> [default\_node\_count](#input\_default\_node\_count) | Default number of machines in a node pool | `number` | `1` | no |
| <a name="input_default_node_labels"></a> [default\_node\_labels](#input\_default\_node\_labels) | Default custom node labels for nodes within a node pool | `map` | `{}` | no |
| <a name="input_default_node_pool_auto_healing"></a> [default\_node\_pool\_auto\_healing](#input\_default\_node\_pool\_auto\_healing) | Default node auto healing setting | `bool` | `true` | no |
| <a name="input_default_node_size"></a> [default\_node\_size](#input\_default\_node\_size) | Deafult Node Size for nodes | `string` | n/a | yes |
| <a name="input_enable_high_available_control_plane"></a> [enable\_high\_available\_control\_plane](#input\_enable\_high\_available\_control\_plane) | Enable HA control plane | `bool` | `false` | no |
| <a name="input_enable_multi_availability_zones"></a> [enable\_multi\_availability\_zones](#input\_enable\_multi\_availability\_zones) | Enable multi availability zones for the cluster | `bool` | `true` | no |
| <a name="input_enable_network_encryption"></a> [enable\_network\_encryption](#input\_enable\_network\_encryption) | Enable Network Encryption at the node level (if supported by the CNI) | `bool` | `true` | no |
| <a name="input_enable_private_cluster"></a> [enable\_private\_cluster](#input\_enable\_private\_cluster) | Enable Private networking Cluster Mode | `bool` | `false` | no |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | A unique identifier for the environment within the organisation. Required. | `string` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Optional Kubernetes version used for deploying the cluster | `string` | `null` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Definition of the Cluster node pools | `any` | <pre>{<br>  "data": {},<br>  "ingress": {},<br>  "worker": {}<br>}</pre> | no |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | A unique identifier for the organisation. This is used to distinguish resources across different organisations. Required. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Cloud Region | `string` | n/a | yes |
| <a name="input_update_channel_name"></a> [update\_channel\_name](#input\_update\_channel\_name) | Name of the Update Channel used for discovering the Kubernetes version | `string` | `"v1.28"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | n/a |
