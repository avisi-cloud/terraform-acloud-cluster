# Avisi Cloud Kubernetes Cluster

This Terraform module provisions an [Avisi Managed Environment (AME)](https://docs.avisi.cloud/docs/product) Kubernetes cluster and its node pools with the [Avisi Cloud Terraform provider](https://docs.avisi.cloud/docs/development/terraform/terraform).

It is intended for users who want a single Terraform module for the common AME cluster workflow: select an organisation, environment, cloud account, cloud provider, region, Kubernetes version policy, and node pool layout.

## Overview

The module:

- looks up an existing AME cloud account by organisation, cloud provider, and display name;
- creates one `acloud_cluster`;
- uses `kubernetes_version` when set, or looks up `update_channel_name` when the version is not set;
- creates one `avisi-cloud/nodepool/acloud` module instance for each entry in `node_pools`.

Use this module when the organisation, environment, and cloud account already exist in Avisi Cloud and you want Terraform to manage the cluster and its standard node pools. Use the lower-level provider resources directly if you need provider features that this module does not expose, such as cluster add-ons, node pool autoscaling bounds, taints, or custom upgrade strategies.

## AME Concepts

AME groups resources as `organisation -> environment -> cluster -> node pool -> node`. In this module, `organisation_slug` and `environment_slug` choose where the cluster record is created, while `node_pools` describes the workload nodes attached to that cluster.

In AME terminology, a node pool is a group of customer cluster nodes that share a configuration such as node size, labels, annotations, and availability-zone behavior. The provided AME notes also mention cluster pools as a separate platform concept, but mark the exact definition as needing confirmation. This module configures cluster node pools only.

For broader product context, see the [Avisi Cloud documentation](https://docs.avisi.cloud/), the [AME product overview](https://docs.avisi.cloud/docs/product), and the Kubernetes task guides for [creating clusters](https://docs.avisi.cloud/docs/product/tasks/kubernetes/create-a-new-cluster) and [creating node pools](https://docs.avisi.cloud/docs/product/tasks/kubernetes/create-a-new-nodepool).

## Prerequisites

Before applying this module:

- the Avisi Cloud organisation must exist;
- the target environment must exist inside that organisation;
- the cloud account must already be configured, enabled, and have primary credentials for new clusters;
- the selected `cloud_provider`, `region`, and node size must be available for that cloud account;
- the `acloud` provider must be configured with credentials, typically a Personal Access Token.

See the Avisi Cloud docs for [cloud accounts](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts), [Personal Access Tokens](https://docs.avisi.cloud/docs/product/tasks/how-to/personal-access-tokens), and [Terraform provider usage](https://docs.avisi.cloud/docs/development/terraform/terraform).

## Basic Usage

```hcl
terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
      version = ">= 0.5.0"
    }
  }
}

variable "acloud_token" {
  description = "Avisi Cloud Personal Access Token."
  type        = string
  sensitive   = true
}

provider "acloud" {
  token = var.acloud_token
}

module "cluster" {
  source = "avisi-cloud/cluster/acloud"

  organisation_slug  = "example-org"
  environment_slug   = "production"
  cluster_name       = "production-apps"
  cloud_provider     = "aws"
  cloud_account_name = "production-aws"
  region             = "eu-west-1"

  default_node_size  = "t3.medium"
  default_node_count = 2

  node_pools = {
    ingress = {
      node_count = 2
      labels = {
        role = "ingress"
      }
    }

    worker = {}

    data = {
      node_size         = "t3.large"
      node_count        = 3
      availability_zone = "eu-west-1a"
    }
  }
}
```

When using this repository locally, the examples use `source = "../../"` instead of the Registry source.

## Important Inputs

The required placement inputs are `organisation_slug`, `environment_slug`, `cluster_name`, `cloud_provider`, `cloud_account_name`, `region`, and `default_node_size`.

By default, the module creates three node pools named `ingress`, `worker`, and `data`. Each pool inherits `default_node_size`, `default_node_count`, `default_node_labels`, `default_node_annotations`, `default_node_pool_auto_healing`, `enable_multi_availability_zones`, and `default_availablity_zone` unless the pool entry overrides that setting.

The `default_availablity_zone` input name is misspelled for compatibility with existing callers. Use a per-pool `availability_zone` value when only one node pool should be pinned to a zone.

If `kubernetes_version` is set, that exact version is passed to AME. If it is `null`, the module looks up the version from `update_channel_name`. Choose an update channel that exists for your organisation and matches your upgrade policy.

`enable_multi_availability_zones`, `enable_high_available_control_plane`, `enable_private_cluster`, and `enable_network_encryption` map to AME cluster settings. Provider and region support can differ. The product docs note that multi availability zones cannot be changed after cluster creation, private cluster behavior is cloud-provider specific, and network encryption depends on CNI support.

## Examples

- [`examples/full`](examples/full) creates an AWS cluster with multi availability zones enabled and multiple node pools.
- [`examples/hetzner`](examples/hetzner) creates a Hetzner cluster with provider-specific defaults.

## Terraform Registry Documentation

The Terraform Registry README tab is rendered from this `README.md`. The generated reference below is produced by `terraform-docs` from the `.tf` files and must stay inside the `BEGIN_TF_DOCS` / `END_TF_DOCS` markers.

The Registry Inputs tab is generated primarily from the root module `variable` blocks. When changing an input, update the variable description in Terraform first, then regenerate this README.

## Updating Terraform Documentation

Preview the generated root module documentation:

```sh
make docs-preview
```

Update all generated README blocks in place:

```sh
make docs
```

Check whether the generated blocks are up to date without modifying files:

```sh
make docs-check
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_acloud"></a> [acloud](#requirement\_acloud) | >= 0.5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_acloud"></a> [acloud](#provider\_acloud) | >= 0.5.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_nodepool"></a> [nodepool](#module\_nodepool) | avisi-cloud/nodepool/acloud | 0.1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [acloud_cluster.cluster](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/resources/cluster) | resource |
| [acloud_cloud_account.account](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/cloud_account) | data source |
| [acloud_cloud_provider_availability_zones.zones](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/cloud_provider_availability_zones) | data source |
| [acloud_update_channel.channel](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/update_channel) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of an enabled Avisi Cloud cloud account for the selected cloud provider. The account must have primary credentials to create new clusters. | `string` | n/a | yes |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Avisi Cloud provider slug used for provisioning the cluster. This must match the selected cloud account and region. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name for the AME Kubernetes cluster. | `string` | n/a | yes |
| <a name="input_default_availablity_zone"></a> [default\_availablity\_zone](#input\_default\_availablity\_zone) | Default availability zone for node pools that do not set availability\_zone. The variable name is misspelled for compatibility. | `string` | `""` | no |
| <a name="input_default_node_annotations"></a> [default\_node\_annotations](#input\_default\_node\_annotations) | Default Kubernetes annotations applied to nodes in node pools that do not set annotations. | `map(string)` | `{}` | no |
| <a name="input_default_node_count"></a> [default\_node\_count](#input\_default\_node\_count) | Default number of machines in node pools that do not set node\_count. | `number` | `1` | no |
| <a name="input_default_node_labels"></a> [default\_node\_labels](#input\_default\_node\_labels) | Default Kubernetes labels applied to nodes in node pools that do not set labels. | `map(string)` | `{}` | no |
| <a name="input_default_node_pool_auto_healing"></a> [default\_node\_pool\_auto\_healing](#input\_default\_node\_pool\_auto\_healing) | Default auto-healing setting for node pools that do not set enable\_auto\_healing. | `bool` | `true` | no |
| <a name="input_default_node_size"></a> [default\_node\_size](#input\_default\_node\_size) | Default cloud provider node type or instance size for node pools that do not set node\_size. | `string` | n/a | yes |
| <a name="input_enable_high_available_control_plane"></a> [enable\_high\_available\_control\_plane](#input\_enable\_high\_available\_control\_plane) | Whether to request a highly available Kubernetes control plane. AME determines the concrete HA model from platform and region capabilities. | `bool` | `false` | no |
| <a name="input_enable_multi_availability_zones"></a> [enable\_multi\_availability\_zones](#input\_enable\_multi\_availability\_zones) | Whether the cluster and default node pools may use multiple availability zones. AME product docs note that this cannot be changed after cluster creation. | `bool` | `true` | no |
| <a name="input_enable_network_encryption"></a> [enable\_network\_encryption](#input\_enable\_network\_encryption) | Whether to enable network-layer encryption in the cluster CNI when supported. | `bool` | `true` | no |
| <a name="input_enable_private_cluster"></a> [enable\_private\_cluster](#input\_enable\_private\_cluster) | Whether to create a private cluster when supported by the cloud provider. | `bool` | `false` | no |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of the Avisi Cloud environment where the cluster is created. An environment groups clusters inside an organisation. | `string` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Explicit AME Kubernetes version to deploy. When null, the module resolves the version from update\_channel\_name. | `string` | `null` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of node pool names to per-pool overrides. Supported override keys are node\_size, node\_count, labels, annotations, enable\_auto\_healing, enable\_multi\_availability\_zones, and availability\_zone. | `any` | <pre>{<br/>  "data": {},<br/>  "ingress": {},<br/>  "worker": {}<br/>}</pre> | no |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of the Avisi Cloud organisation that owns the environment and cluster. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Cloud provider region slug where the cluster is provisioned. The region must be valid for the selected cloud provider and cloud account. | `string` | n/a | yes |
| <a name="input_update_channel_name"></a> [update\_channel\_name](#input\_update\_channel\_name) | Name of the AME update channel used to resolve the Kubernetes version when kubernetes\_version is null. | `string` | `"v1.28"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | Identifier and resolved Kubernetes version of the created AME cluster. |
<!-- END_TF_DOCS -->
