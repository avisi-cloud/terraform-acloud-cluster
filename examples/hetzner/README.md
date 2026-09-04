# Hetzner cluster in a single region

A compact Hetzner Cloud cluster. Hetzner regions in AME are single-zone, so this example turns
multi-AZ off and every entry in `node_pools` becomes exactly one AME node pool - which makes the
node counts the literal number of machines you get.

Useful as a cost-conscious development or staging cluster, and as the clearest illustration of the
module without availability-zone fan-out in the way.

## What it creates

| Pool | `node_size` | `node_count` | Machines |
| --- | --- | --- | --- |
| `system` | `cx33` | 1 | 1 |
| `apps` | `cx33` | 2 | 2 |
| `batch-jobs` | `cx43` | 1 | 1 |
| | | | **4 machines total** |

Plus one `acloud_cluster` in `fsn1` (Falkenstein). Compare with
[`examples/aws`](../aws) or [`examples/cyso`](../cyso) to see the difference multi-zone fan-out makes.

## The interesting bits

```hcl
# Hetzner regions are single-zone: one AME node pool per entry below.
enable_multi_availability_zones = false

default_node_size  = "cx33"
default_node_count = 1

# Applied to every pool that does not override `labels`.
default_node_labels = {
  "topology.avisi.cloud/managed-by" = "terraform"
}

node_pools = {
  system = {}
  apps   = { node_count = 2 }

  # Pool names may contain hyphens; quote them so they stay valid map keys.
  "batch-jobs" = {
    node_size  = "cx43"
    node_count = 1
    labels     = { "role" = "batch" }
  }
}
```

Note that `batch-jobs` overrides `labels`, so it does **not** inherit `default_node_labels` -
overrides replace the default, they do not merge with it.

## Prerequisites

A [Hetzner cloud account](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/hetzner) that is
enabled and has primary credentials (a Hetzner project API token with **Read & Write** permissions),
an existing environment, and a
[Personal Access Token](https://docs.avisi.cloud/docs/product/tasks/how-to/personal-access-tokens).

## Running it

```sh
export TF_VAR_acloud_token="acpat_..."

terraform init
terraform apply \
  -var organisation_slug=example-org \
  -var environment_slug=staging \
  -var cloud_account_name="Hetzner Project"
```

<!-- BEGIN_TF_DOCS -->
## Reference

Generated from the `.tf` files in this directory with [terraform-docs](https://terraform-docs.io).
Run `make docs` after changing any variable, output, resource or module block.

### Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_acloud"></a> [acloud](#requirement\_acloud) | >= 0.10.0 |



### Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ../../ | n/a |



### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acloud_token"></a> [acloud\_token](#input\_acloud\_token) | Avisi Cloud Personal Access Token. Create one under API Access in the Console. | `string` | n/a | yes |
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of the Hetzner cloud account in the Avisi Cloud Console. | `string` | n/a | yes |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of an existing AME environment to create the cluster in. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of the Avisi Cloud organisation that owns the environment. | `string` | n/a | yes |
| <a name="input_acloud_api"></a> [acloud\_api](#input\_acloud\_api) | Avisi Cloud API base URL. Leave null to use the public API at https://api.avisi.cloud. | `string` | `null` | no |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Cloud provider slug for Hetzner. | `string` | `"hetzner"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name for the cluster. | `string` | `"hetzner"` | no |
| <a name="input_region"></a> [region](#input\_region) | Hetzner region for the cluster, for example `fsn1` (Falkenstein) or `nbg1` (Nuremberg). | `string` | `"fsn1"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | Identity and provisioned AME version of the created cluster. |
<!-- END_TF_DOCS -->
