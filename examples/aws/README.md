# AWS cluster, multi-AZ with an HA control plane

A production-shaped AWS cluster: the control plane runs in high-availability mode, workload pools
are spread across every availability zone in the region, and one pool is deliberately pinned to a
single zone for workloads that should stay close to their volumes.

Use this as the starting point for a real cluster, and read the machine count below before you apply.

## What it creates

`eu-west-1` exposes three availability zones in AME (confirm yours with `acloud cloud-providers get`).
Because multi-AZ is enabled, each multi-zone pool is created **once per zone**:

| Pool | Zones | `node_count` | Machines |
| --- | --- | --- | --- |
| `system` | all three | 1 per zone | 3 × `t3.medium` |
| `apps` | all three | 2 per zone | 6 × `t3.large` |
| `data` | `eu-west-1a` only | 3 | 3 × `t3.large` |
| | | | **12 machines total** |

Plus one `acloud_cluster` with a highly available control plane and network encryption enabled.

> [!NOTE]
> `node_count` is nodes **per availability zone** for multi-zone pools. Halve the counts, or pin a
> pool to one zone as `data` does, if that is more capacity than you want.

## The interesting bits

```hcl
# Neither of these can be changed after the cluster is created.
enable_multi_availability_zones     = true
enable_high_available_control_plane = true

node_pools = {
  system = { labels = { "role" = "system" } }        # 1 node per zone
  apps   = { node_count = 2, node_size = "t3.large" } # 2 nodes per zone

  # Turning multi-AZ off for a single pool is what makes availability_zone
  # meaningful - the cluster stays multi-zone, this pool does not.
  data = {
    enable_multi_availability_zones = false
    availability_zone               = var.single_zone_availability_zone
    node_size                       = "t3.large"
    node_count                      = 3
  }
}
```

The control plane's HA model - Single-Zone HA or Multi-Zone HA - is chosen by AME based on the
cluster pool the control plane lands in; Multi-Zone HA needs a multi-zone AME pool.
See [Why AME](https://docs.avisi.cloud/docs/product/why-ame).

## Prerequisites

An [AWS cloud account](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/aws) that is enabled
and has primary credentials, an existing environment, and a
[Personal Access Token](https://docs.avisi.cloud/docs/product/tasks/how-to/personal-access-tokens).

## Running it

```sh
export TF_VAR_acloud_token="acpat_..."

terraform init
terraform apply \
  -var organisation_slug=example-org \
  -var environment_slug=production \
  -var cloud_account_name="Production AWS"
```

`region`, `cluster_name` and `single_zone_availability_zone` have defaults; override them as needed.

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
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of the AWS cloud account in the Avisi Cloud Console. | `string` | n/a | yes |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of an existing AME environment to create the cluster in. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of the Avisi Cloud organisation that owns the environment. | `string` | n/a | yes |
| <a name="input_acloud_api"></a> [acloud\_api](#input\_acloud\_api) | Avisi Cloud API base URL. Leave null to use the public API at https://api.avisi.cloud. | `string` | `null` | no |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Cloud provider slug for AWS. | `string` | `"aws"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name for the cluster. | `string` | `"aws-production"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the cluster. | `string` | `"eu-west-1"` | no |
| <a name="input_single_zone_availability_zone"></a> [single\_zone\_availability\_zone](#input\_single\_zone\_availability\_zone) | Availability zone the `data` node pool is pinned to. Must be a zone within `region`. | `string` | `"eu-west-1a"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | Identity and provisioned AME version of the created cluster. |
<!-- END_TF_DOCS -->
