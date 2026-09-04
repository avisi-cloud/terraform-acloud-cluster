# Minimal cluster

The smallest configuration that produces a running AME cluster: **one cluster with one node pool
holding one node**. Cloud-provider neutral - every placement value is a variable without a default,
so the same directory works against AWS, Hetzner, Cyso Cloud or anything else your organisation has
a cloud account for.

Start here when you want to confirm that your token, organisation, environment and cloud account
line up before adding node pools and cluster options.

## What it creates

| | |
| --- | --- |
| `acloud_cluster` | 1 |
| Node pools | 1 (`worker`) |
| Machines | **1** |

`enable_multi_availability_zones` is set to `false`, which is what keeps this to a single node pool.
Left at the module default (`true`) the `worker` pool would be created once per availability zone in
the region, so a three-zone region would give you three nodes instead of one.

## The interesting bits

```hcl
module "cluster" {
  source = "../../"          # use "avisi-cloud/cluster/acloud" outside this repo

  # Track the channel AME recommends for production instead of the module's
  # end-of-life v1.28 default.
  update_channel_name = "regular"

  enable_multi_availability_zones = false

  default_node_size  = var.node_size
  default_node_count = 1

  node_pools = {
    worker = {}
  }
}
```

`node_pools = { worker = {} }` is the empty-override form: the pool inherits `default_node_size`,
`default_node_count` and every other `default_*` value from the module.

## Prerequisites

An Avisi Cloud organisation, an existing environment, an enabled cloud account with primary
credentials, and a [Personal Access Token](https://docs.avisi.cloud/docs/product/tasks/how-to/personal-access-tokens).

## Running it

```sh
export TF_VAR_acloud_token="acpat_..."

terraform init
terraform apply \
  -var organisation_slug=example-org \
  -var environment_slug=sandbox \
  -var cloud_account_name="Production AWS" \
  -var cloud_provider=aws \
  -var region=eu-west-1 \
  -var node_size=t3.medium
```

Then fetch credentials with `acloud kubeconfig install`, and clean up with `terraform destroy`.

<!-- BEGIN_TF_DOCS -->
## Reference

Generated from the `.tf` files in this directory with [terraform-docs](https://terraform-docs.io).
Run `make docs` after changing any variable, output, resource or module block.

### Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_acloud"></a> [acloud](#requirement\_acloud) | >= 0.10.1 |



### Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ../../ | n/a |



### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acloud_token"></a> [acloud\_token](#input\_acloud\_token) | Avisi Cloud Personal Access Token. Create one under API Access in the Console. | `string` | n/a | yes |
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of an enabled cloud account with primary credentials. | `string` | n/a | yes |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Cloud provider slug the cloud account belongs to, for example `aws` or `hetzner`. | `string` | n/a | yes |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of an existing AME environment to create the cluster in. | `string` | n/a | yes |
| <a name="input_node_size"></a> [node\_size](#input\_node\_size) | Machine type for the single worker node pool. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of your Avisi Cloud organisation. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Cloud provider region slug to provision the cluster in. | `string` | n/a | yes |
| <a name="input_acloud_api"></a> [acloud\_api](#input\_acloud\_api) | Avisi Cloud API base URL. Leave null to use the public API at https://api.avisi.cloud. | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name for the cluster. | `string` | `"minimal"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | Identity and provisioned AME version of the created cluster. |
<!-- END_TF_DOCS -->
