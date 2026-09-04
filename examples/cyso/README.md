# Cyso Cloud AMS2 private cluster

A Cyso Cloud AMS2 (OpenStack) cluster with a private network layout: nodes get no public IP address
and reach the internet through a NAT gateway with a stable outbound address. AMS2 is a multi-zone
region, so this example also works the availability-zone fan-out through end to end.

Use it when nodes must not be directly reachable from the internet, or when an upstream system needs
a predictable egress IP to allowlist.

## What it creates

AMS2 exposes three availability zones - `ams2-a`, `ams2-b` and `ams2-c`. With multi-AZ enabled, each
multi-zone pool is created **once per zone**:

| Pool | Zones | `node_count` | Machines |
| --- | --- | --- | --- |
| `system` | all three | 1 per zone | 3 × `s5.small` |
| `apps` | all three | 2 per zone | 6 × `s5.small` |
| `data` | `ams2-a` only | 2 | 2 × `s5.small` |
| | | | **11 machines total** |

Plus one `acloud_cluster` with a highly available control plane, Cilium networking, the `restricted`
Pod Security Standards profile, the cert-manager and NFS add-ons, and a NAT gateway instead of public
node IPs.

## The interesting bits

```hcl
# Multi-AZ and private cluster cannot be changed after creation.
enable_multi_availability_zones     = true
enable_high_available_control_plane = true
enable_private_cluster              = true

# Cilium instead of the Calico default. Network encryption is Calico-only, so
# it is switched off rather than silently ignored.
cni                       = "cilium"
enable_network_encryption = false

pod_security_standards_profile = "restricted"

addons = {
  certManager = {}
  nfs         = {}
}

node_pools = {
  system = { labels = { "role" = "system" } }  # 1 per zone  -> 3 machines
  apps   = { node_count = 2 }                  # 2 per zone  -> 6 machines

  data = {
    enable_multi_availability_zones = false
    availability_zone               = "ams2-a"
    node_count                      = 2        # exactly 2, both in ams2-a
  }
}
```

> **Note:**
> Cilium and network encryption do not combine: `enable_network_encryption` configures the CNI to
> encrypt node-to-node traffic and is only supported by Calico. Compare with
> [`examples/aws`](../aws), which keeps Calico and turns encryption on.

> **Note:**
> On a private cluster there is no public IP on the nodes, so a NodePort has to be reached through
> the node's **internal** address. Provisioning also takes longer, because AME creates the NAT
> gateway and its networking first. See
> [cluster networking](https://docs.avisi.cloud/docs/product/overview/kubernetes/networking).

## Prerequisites

A [Cyso cloud account](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/cyso) built from
Cyso application credentials for the `ams` region, enabled and holding primary credentials, an
existing environment, and a
[Personal Access Token](https://docs.avisi.cloud/docs/product/tasks/how-to/personal-access-tokens).

The `cloud_account_name` default is `Cyso Cloud AMS2`; change it if you named your cloud account
after the Cyso team instead, as the cloud account guide suggests.

## Running it

```sh
export TF_VAR_acloud_token="acpat_..."

terraform init
terraform apply \
  -var organisation_slug=example-org \
  -var environment_slug=production
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
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of an existing AME environment to create the cluster in. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of the Avisi Cloud organisation that owns the environment. | `string` | n/a | yes |
| <a name="input_acloud_api"></a> [acloud\_api](#input\_acloud\_api) | Avisi Cloud API base URL. Leave null to use the public API at https://api.avisi.cloud. | `string` | `null` | no |
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of the Cyso Cloud AMS2 cloud account in the Avisi Cloud Console. | `string` | `"Cyso Cloud AMS2"` | no |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Cloud provider slug for Cyso Cloud AMS2. | `string` | `"cyso-cloud-ams2"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name for the cluster. | `string` | `"cyso-ams2"` | no |
| <a name="input_region"></a> [region](#input\_region) | Cyso Cloud region for the cluster. | `string` | `"ams2"` | no |
| <a name="input_single_zone_availability_zone"></a> [single\_zone\_availability\_zone](#input\_single\_zone\_availability\_zone) | Availability zone the `data` node pool is pinned to. AMS2 offers `ams2-a`, `ams2-b` and `ams2-c`. | `string` | `"ams2-a"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | Identity and provisioned AME version of the created cluster. |
<!-- END_TF_DOCS -->
