# Avisi Cloud Multi-tiered Kubernetes Cluster

This module is designed to simplify the provisioning of a Kubernetes cluster using the Avisi Cloud platform with a tiered node pool architecture, on any Cloud Provider supported by [Avisi Cloud Kubernetes](https://docs.avisi.cloud/product/kubernetes/).

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
| <a name="module_data_nodepool"></a> [data\_nodepool](#module\_data\_nodepool) | avisi-cloud/nodepool/acloud | 0.0.3 |
| <a name="module_ingress_nodepool"></a> [ingress\_nodepool](#module\_ingress\_nodepool) | avisi-cloud/nodepool/acloud | 0.0.3 |
| <a name="module_worker_nodepool"></a> [worker\_nodepool](#module\_worker\_nodepool) | avisi-cloud/nodepool/acloud | 0.0.3 |

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
| <a name="input_data_node_count"></a> [data\_node\_count](#input\_data\_node\_count) | Number of machines per data node pool | `number` | `1` | no |
| <a name="input_data_node_size"></a> [data\_node\_size](#input\_data\_node\_size) | Node Size for nodes in the data pool | `string` | n/a | yes |
| <a name="input_enable_high_available_control_plane"></a> [enable\_high\_available\_control\_plane](#input\_enable\_high\_available\_control\_plane) | Enable HA control plane | `bool` | `false` | no |
| <a name="input_enable_multi_availability_zones"></a> [enable\_multi\_availability\_zones](#input\_enable\_multi\_availability\_zones) | Enable multi availability zones for the cluster | `bool` | `true` | no |
| <a name="input_enable_network_encryption"></a> [enable\_network\_encryption](#input\_enable\_network\_encryption) | Enable Network Encryption at the node level (if supported by the CNI) | `bool` | `true` | no |
| <a name="input_enable_private_cluster"></a> [enable\_private\_cluster](#input\_enable\_private\_cluster) | Enable Private networking Cluster Mode | `bool` | `false` | no |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | A unique identifier for the environment within the organisation. Required. | `string` | n/a | yes |
| <a name="input_ingress_node_count"></a> [ingress\_node\_count](#input\_ingress\_node\_count) | Number of machines per ingress node pool | `number` | `1` | no |
| <a name="input_ingress_node_size"></a> [ingress\_node\_size](#input\_ingress\_node\_size) | Node Size for nodes in the ingress pool | `string` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Optional Kubernetes version used for deploying the cluster | `string` | `null` | no |
| <a name="input_node_pool_data_annotations"></a> [node\_pool\_data\_annotations](#input\_node\_pool\_data\_annotations) | Custom node annotations for nodes per of the data node pool | `map` | `{}` | no |
| <a name="input_node_pool_data_auto_healing"></a> [node\_pool\_data\_auto\_healing](#input\_node\_pool\_data\_auto\_healing) | Enable node auto healing for the data node pool | `bool` | `true` | no |
| <a name="input_node_pool_data_labels"></a> [node\_pool\_data\_labels](#input\_node\_pool\_data\_labels) | Custom node labels for nodes per of the data node pool | `map` | `{}` | no |
| <a name="input_node_pool_ingress_annotations"></a> [node\_pool\_ingress\_annotations](#input\_node\_pool\_ingress\_annotations) | Custom node annotations for nodes per of the ingress node pool | `map` | `{}` | no |
| <a name="input_node_pool_ingress_auto_healing"></a> [node\_pool\_ingress\_auto\_healing](#input\_node\_pool\_ingress\_auto\_healing) | Enable node auto healing for the ingress node pool | `bool` | `true` | no |
| <a name="input_node_pool_ingress_labels"></a> [node\_pool\_ingress\_labels](#input\_node\_pool\_ingress\_labels) | Custom node labels for nodes per of the ingress node pool | `map` | `{}` | no |
| <a name="input_node_pool_worker_annotations"></a> [node\_pool\_worker\_annotations](#input\_node\_pool\_worker\_annotations) | Custom node annotations for nodes per of the worker node pool | `map` | `{}` | no |
| <a name="input_node_pool_worker_auto_healing"></a> [node\_pool\_worker\_auto\_healing](#input\_node\_pool\_worker\_auto\_healing) | Enable node auto healing for the worker node pool | `bool` | `true` | no |
| <a name="input_node_pool_worker_labels"></a> [node\_pool\_worker\_labels](#input\_node\_pool\_worker\_labels) | Custom node labels for nodes per of the worker node pool | `map` | `{}` | no |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | A unique identifier for the organisation. This is used to distinguish resources across different organisations. Required. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Cloud Region | `string` | n/a | yes |
| <a name="input_update_channel_name"></a> [update\_channel\_name](#input\_update\_channel\_name) | Name of the Update Channel used for discovering the Kubernetes version | `string` | `"v1.28"` | no |
| <a name="input_worker_node_count"></a> [worker\_node\_count](#input\_worker\_node\_count) | Number of machines per worker node pool | `number` | `1` | no |
| <a name="input_worker_node_size"></a> [worker\_node\_size](#input\_worker\_node\_size) | Node Size for nodes in the worker pool | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | n/a |
