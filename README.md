# Avisi Cloud Kubernetes Cluster

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/avisi-cloud/cluster/acloud/latest)
[![Provider](https://img.shields.io/badge/provider-avisi--cloud%2Facloud-5C4EE5?logo=terraform&logoColor=white)](https://registry.terraform.io/providers/avisi-cloud/acloud/latest)
[![Product docs](https://img.shields.io/badge/docs-avisi.cloud-0F6FFF)](https://docs.avisi.cloud/)

Terraform module that provisions a managed Kubernetes cluster on
**[Avisi Managed Environments (AME)](https://docs.avisi.cloud/docs/product/why-ame)**, together with
its node pools, using the [Avisi Cloud provider](https://registry.terraform.io/providers/avisi-cloud/acloud/latest).

AME is Avisi Cloud's managed Kubernetes platform: you get clusters you do not have to build or
maintain, on public cloud, private cloud or on-premise, with upgrades, observability and day-2
operations handled by the platform. This module wraps the common create-a-cluster workflow -
pick an organisation, an environment, a cloud account, a region, a version policy and a node pool
layout - into a single `module` block.

```hcl
module "cluster" {
  source  = "avisi-cloud/cluster/acloud"
  version = "0.1.0"

  organisation_slug  = "example-org"
  environment_slug   = "production"
  cluster_name       = "orders"
  cloud_provider     = "aws"
  cloud_account_name = "Production AWS"
  region             = "eu-west-1"

  update_channel_name = "regular"
  default_node_size   = "t3.medium"

  node_pools = {
    worker = { node_count = 2 }
  }
}
```

---

## Contents

- [Overview](#overview)
- [When to use this module](#when-to-use-this-module)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [AME concepts used by this module](#ame-concepts-used-by-this-module)
- [Node pools](#node-pools)
- [Kubernetes versions and upgrades](#kubernetes-versions-and-upgrades)
- [Cluster options](#cluster-options)
- [Cloud providers](#cloud-providers)
- [Examples](#examples)
- [What this module does not cover](#what-this-module-does-not-cover)
- [Known rough edges](#known-rough-edges)
- [Troubleshooting](#troubleshooting)
- [Documentation workflow](#documentation-workflow)
- [Related documentation](#related-documentation)
- [Reference](#reference) *(generated)*

---

## Overview

The module resolves three things AME needs by identity rather than by name, creates one cluster, and
then creates node pools for it:

```
 inputs                            module                                AME objects
 ──────                            ──────                                ───────────

 organisation_slug ──┐
 cloud_account_name ─┼──▶ data.acloud_cloud_account ──── identity ──┐
 cloud_provider ─────┘                                              │
                                                                    ▼
 update_channel_name ──▶ data.acloud_update_channel ─── version ──▶ acloud_cluster
 kubernetes_version ─────────────────────────────────────────────▶  (exactly one)
                                                                    │
                                                                    │ slug
                                                                    ▼
 node_pools ───────────▶ module.nodepool["<name>"] ──────────────▶ acloud_nodepool
 default_node_* ───────▶   one per map entry                        one per availability zone
```

| The module creates | Count | Notes |
| --- | --- | --- |
| `acloud_cluster` | 1 | The cluster record and its control plane |
| `avisi-cloud/nodepool/acloud` module instance | one per `node_pools` entry | Named after the map key |
| `acloud_nodepool` | one per availability zone, per pool | See [node pools](#node-pools) - this is where node counts multiply |

The module does **not** create the organisation, the environment or the cloud account. Those must
already exist, and the module looks them up.

## When to use this module

**Use it when** the organisation, environment and cloud account already exist, and you want a
standard cluster with a handful of similarly configured node pools managed as one unit. It is the
fastest path from nothing to a running AME cluster in Terraform.

**Reach for the [provider resources](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs)
directly when** you need node pool autoscaling, taints, per-pool upgrade strategies, cluster add-ons,
a specific CNI, Pod Security Standards, auto-upgrade with a maintenance schedule, or distinct names
per availability zone. See [what this module does not cover](#what-this-module-does-not-cover) - the
two approaches mix freely in the same configuration.

## Requirements

### Tooling

| | Version |
| --- | --- |
| Terraform | The module declares no `required_version`. Module-level `for_each` needs `>= 0.13`; Terraform 1.x is what it is used with |
| `avisi-cloud/acloud` provider | `>= 0.5.0` is the module's floor; the product docs recommend pinning **`>= 0.10.1`** in your root module |

### In Avisi Cloud

Before the first `terraform apply`:

1. **An organisation.** Its slug is the value for `organisation_slug`.
2. **An environment** inside that organisation - `production`, `staging`, and so on.
   See [How to use environments](https://docs.avisi.cloud/docs/product/tasks/how-to/how-to-environments).
   Create it in the Console, with `acloud environments create`, or with an
   [`acloud_environment`](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/resources/environment)
   resource and feed its `slug` into this module.
3. **A cloud account** for your cloud provider, which is **enabled** and has **primary cloud
   credentials** - AME only provisions new clusters into accounts that satisfy both.
   See [Cloud accounts](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts) and the per-provider
   guides for [AWS](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/aws),
   [Hetzner](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/hetzner),
   [Cyso Cloud](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/cyso),
   [Azure](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/azure) and
   [Leafcloud](https://docs.avisi.cloud/docs/product/tasks/cloud-accounts/leafcloud).
4. **A Personal Access Token (PAT)** for the provider. Create it under *API Access* in the Console.
   A PAT can perform any action your user can, so use one token per environment, store it in a secret
   manager, and optionally restrict it to a CIDR range when you create it.
   See [Using Personal Access Tokens](https://docs.avisi.cloud/docs/product/tasks/how-to/personal-access-tokens).

> [!WARNING]
> A PAT is a long-lived credential with your full user permissions and no scope narrowing. Never
> commit one, and never expose it to a tool or agent that does not need it.

## Quick start

```hcl
terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
      version = ">= 0.10.1"
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
  source  = "avisi-cloud/cluster/acloud"
  version = "0.1.0"

  # Placement - all of these must already exist in Avisi Cloud.
  organisation_slug  = "example-org"
  environment_slug   = "production"
  cluster_name       = "orders"
  cloud_provider     = "aws"
  cloud_account_name = "Production AWS"
  region             = "eu-west-1"

  # Version policy: follow the channel AME recommends for production.
  update_channel_name = "regular"

  # Cluster options that cannot be changed later.
  enable_multi_availability_zones     = true
  enable_high_available_control_plane = true

  # Node pool defaults, inherited by every pool that does not override them.
  default_node_size  = "t3.medium"
  default_node_count = 1

  node_pools = {
    ingress = { node_count = 1 }
    worker  = { node_count = 2, node_size = "t3.large" }

    data = {
      enable_multi_availability_zones = false
      availability_zone               = "eu-west-1a"
      node_count                      = 3
    }
  }
}

output "cluster_id" {
  value = module.cluster.cluster.id
}
```

Then:

```sh
export TF_VAR_acloud_token="acpat_..."
terraform init
terraform plan
terraform apply
```

A control plane is typically ready in about two minutes; a full cluster including nodes usually
finishes within seven. Enabling a private cluster adds time because extra cloud resources are
provisioned. Afterwards, fetch credentials with `acloud kubeconfig install` or the *Download
Credentials* button on the cluster page - see
[cluster access](https://docs.avisi.cloud/docs/product/tasks/kubernetes/cluster-access).

The examples in this repository use `source = "../../"` so they can be run from a checkout. In your
own configuration use the Registry source and pin a `version`, as above.

## AME concepts used by this module

AME nests its objects, and the nesting is what the placement inputs select:

```
Organisation  →  Environment  →  Cluster  →  Node Pool  →  Node
     │                │             │           │
organisation_slug  environment_  cluster_    node_pools
                      slug         name         keys
```

| Term | What it means in AME | Input |
| --- | --- | --- |
| **Organisation** | The customer account: the top of the tree and the boundary for access and billing. Identified by a slug. | `organisation_slug` |
| **Environment** | A grouping of clusters *inside* an organisation, such as `production` or `staging`. It is **not** a Kubernetes namespace. | `environment_slug` |
| **Cluster** | One managed Kubernetes cluster. | `cluster_name` |
| **Node pool** | A group of nodes that share a configuration - machine type, labels, annotations, upgrade behaviour. | `node_pools` |
| **Cloud account** | An account within a cloud provider (an AWS sub-account, a Hetzner project, a Cyso team) that AME provisions infrastructure into. Referenced by display name. | `cloud_account_name` |
| **Update channel** | A named pointer to the AME Kubernetes version a cluster should target. | `update_channel_name` |

> [!IMPORTANT]
> **Node pool is not the same thing as cluster pool.** A *node pool* is a group of **your** machines
> inside your cluster - that is what this module configures. A *cluster pool* (often just "pool") is
> AME's own infrastructure in a region that hosts customer control planes. The distinction matters
> because the HA model of your control plane is decided by the cluster pool it lands in, not by
> anything you set here. Cluster pools are not exposed in Terraform.

## Node pools

`node_pools` is a map from pool name to per-pool overrides. Every key of the value object is
optional, and anything a pool leaves out falls back to the matching `default_*` variable. That is why
a homogeneous cluster is a one-liner and a mixed one is still readable:

```hcl
default_node_size  = "t3.medium"
default_node_count = 1

node_pools = {
  ingress = {}                                      # inherits everything
  worker  = { node_count = 3 }                      # overrides just the count
  data    = { node_size = "t3.large", node_count = 2, labels = { role = "data" } }
}
```

The variable is typed `any` on purpose, so different pools can override different subsets of keys
without you having to spell out an object type.

### Supported override keys

| Key | Falls back to | Meaning |
| --- | --- | --- |
| `node_size` | `default_node_size` | Cloud provider machine type |
| `node_count` | `default_node_count` | Nodes **per availability zone** the pool is created in |
| `labels` | `default_node_labels` | Kubernetes node labels, for `nodeSelector` and affinity |
| `annotations` | `default_node_annotations` | Kubernetes node annotations, usually read by automation |
| `enable_auto_healing` | `default_node_pool_auto_healing` | AME replaces nodes it detects as unhealthy |
| `enable_multi_availability_zones` | `enable_multi_availability_zones` | Whether this pool spreads over all zones |
| `availability_zone` | `default_availablity_zone` | Zone for a single-zone pool *(note the misspelled variable name)* |

Anything else you put in a pool entry is silently ignored, because the module reads these keys
explicitly. There is no error for a typo - if a setting does not take effect, check it against this
table first.

### Availability zones multiply your node count

This is the single most surprising behaviour of the module, and it comes from the underlying
[`avisi-cloud/nodepool/acloud`](https://registry.terraform.io/modules/avisi-cloud/nodepool/acloud/latest)
module: when a pool is multi-zone, it creates **one `acloud_nodepool` per availability zone in the
region**, each sized `node_count`.

For a region with three availability zones and `node_pools = { worker = { node_count = 2 } }`:

| `enable_multi_availability_zones` | `acloud_nodepool` resources | Machines |
| --- | --- | --- |
| `true` (module default) | 3 - one in each zone | **6** |
| `false` | 1 - in `availability_zone` | **2** |

So `node_count` is *nodes per zone*, not nodes per pool. Two ways to control it:

```hcl
# A. Whole cluster in one zone.
enable_multi_availability_zones = false
default_availablity_zone        = "eu-west-1a"

# B. Spread most pools, pin the stateful one.
enable_multi_availability_zones = true

node_pools = {
  worker = { node_count = 2 }   # 2 per zone

  data = {
    enable_multi_availability_zones = false
    availability_zone               = "eu-west-1a"
    node_count                      = 3          # exactly 3, all in eu-west-1a
  }
}
```

Note that `enable_multi_availability_zones` is also a **cluster** setting that
[cannot be changed after creation](https://docs.avisi.cloud/docs/product/tasks/kubernetes/create-a-new-cluster).
Turning it off later only affects the pools, not the cluster.

The resulting Terraform addresses are nested accordingly, which is what you need for
`terraform state` operations and targeted plans:

```
module.cluster.module.nodepool["worker"].acloud_nodepool.pool["eu-west-1a"]
                              └ pool name                            └ availability zone
```

### What the module does not set on a node pool

The child module passes through only the keys in the table above. Everything else is left at the AME
default, which is worth knowing because several of those defaults matter:

| Node pool setting | Result when created through this module |
| --- | --- |
| **Autoscaling** | Effectively off. The child module pins `min_size` and `max_size` to `node_count` and never sets `auto_scaling`. |
| **Upgrade strategy** | AME default, `replaceMinorInplacePatchWithoutDrain` - minor versions replace nodes, patches are applied in place without draining. See [upgrade strategies](https://docs.avisi.cloud/docs/product/overview/kubernetes/upgrades#upgrade-strategies). |
| **Security updates on join** | AME default, `OFF` - nodes join with the packages from their base image. AME recommends `INSTALL_AND_REBOOT`; see [security updates on join](https://docs.avisi.cloud/docs/product/overview/kubernetes/security-updates-on-join). |
| **Taints** | None. |
| **Automatic node reboots** | Configured on the cluster's *Patching* page, not through Terraform. |

> [!CAUTION]
> **Do not combine autoscaling with automatic node reboots while nodes join unpatched.** A node joins,
> is patched the next morning, and is drained to reboot; the evicted pods make the autoscaler add
> another unpatched node, and the rebooted node comes back empty and is scaled down again. The pool
> then recycles every node, every day. Setting security updates on join to `INSTALL_AND_REBOOT`
> removes the cause. This module cannot set either of those, so the combination only arises if you
> enable them elsewhere - but it is the failure mode to recognise.
> See the [runbook](https://docs.avisi.cloud/docs/runbooks/debug/new-nodes-require-reboot-after-join).

To get any of the above, declare the node pool with the provider directly - see
[what this module does not cover](#what-this-module-does-not-cover).

## Kubernetes versions and upgrades

Two mutually exclusive paths decide the version AME provisions:

| You set | Behaviour |
| --- | --- |
| `kubernetes_version = "v1.35.6-u-ame.4"` | Pinned. The cluster runs exactly that version until you change the value. `update_channel_name` is ignored. |
| `kubernetes_version = null` *(default)* | The module reads `update_channel_name` and uses whatever version that channel points at **when the plan runs**. |

AME versions combine the Kubernetes version, the Linux distribution and the AME build - `v1.35.6-u-ame.4`
is Kubernetes 1.35.6 on Ubuntu, AME build 4. See
[AME versioning](https://docs.avisi.cloud/docs/product/overview/kubernetes/upgrades#ame-versioning).

### Update channels

Channels come in two shapes:

| Channel | Shape | Use |
| --- | --- | --- |
| `stable`, `regular`, `preview` | Rolling - follows a Kubernetes minor series that AME moves forward over time | **`regular` is what AME recommends for production workloads** |
| `v1.34`, `v1.35`, ... | Pinned to one Kubernetes minor series, still receiving patch releases | Stay on a minor version and adopt new ones deliberately |

Which Kubernetes minor each rolling channel currently points at is published in the
[release notes](https://docs.avisi.cloud/docs/product/overview/release-notes).

> [!WARNING]
> The module default is `update_channel_name = "v1.28"`, which is an **end-of-life** Kubernetes
> series under the [AME lifecycle policy](https://docs.avisi.cloud/docs/product/overview/kubernetes/lifecycle-policy).
> The default is kept for backwards compatibility with existing callers - always set this input
> explicitly for a new cluster. Every example in this repository sets `update_channel_name = "regular"`.

### How upgrades show up in Terraform

The module resolves a channel to a **concrete version string** and writes that to state. So a channel
that has moved forward appears as an ordinary diff on the `version` attribute at the next `plan`, and
the upgrade happens on `apply` - it is not a background auto-upgrade. Expect nodes to be replaced or
upgraded in place depending on the pool's upgrade strategy, and read the
[release notes](https://docs.avisi.cloud/docs/product/overview/release-notes) for the target version
before applying.

Moving to a new Kubernetes **minor** version always requires an explicit change: either a new pinned
version or a new channel name. Upgrades are supported one minor version at a time.

AME also supports scheduled upgrades and auto-upgrade with a maintenance window. Those are cluster
attributes (`enable_auto_upgrade`, `maintenance_schedule_id`) that this module does not expose -
see [auto upgrade](https://docs.avisi.cloud/docs/product/overview/kubernetes/auto-upgrade).

## Cluster options

Four inputs map onto the advanced options of the AME create-cluster form:

| Input | Default | Changeable later | Notes |
| --- | --- | --- | --- |
| `enable_multi_availability_zones` | `true` | **No** | Spreads the cluster over the zones of the region, and fans node pools out per zone. May increase cost, for example combined with a NAT gateway. |
| `enable_high_available_control_plane` | `false` | Yes | Removes the single points of failure in `kube-apiserver` and `etcd`. AME selects Single-Zone HA or Multi-Zone HA automatically, based on the cluster pool the control plane lands in. |
| `enable_private_cluster` | `false` | **No** | Nodes get no public IP; egress goes through a NAT gateway with a static outbound address. Availability is cloud-provider specific and provisioning takes longer. With a private cluster, reach nodes by their internal IP. |
| `enable_network_encryption` | `true` | Yes | Encrypts pod-to-pod traffic at the CNI layer. Supported by **Calico only**, and it has a measurable performance impact. |

The Kubernetes API server IP allowlist, delete protection, the CNI choice and the Pod Security
Standards profile are all AME cluster settings that this module does not expose.

## Cloud providers

`cloud_provider` takes an AME cloud provider **slug**, which must match the cloud account named in
`cloud_account_name`. Run `acloud cloud-providers get` to list the providers, regions and machine
types available to your organisation - what follows is orientation, not an availability guarantee.

| Provider | Slug | Example region | Example machine type |
| --- | --- | --- | --- |
| Amazon Web Services | `aws` | `eu-west-1` | `t3.medium` |
| Hetzner Cloud | `hetzner` | `fsn1` | `cx33` |
| Cyso Cloud AMS2 | `cyso-cloud-ams2` | `ams2` | `s5.small` |
| Leafcloud | `leafcloud` | - | `cn1.medium` |
| Azure *(beta)* | `azure` | - | - |
| OpenStack | `openstack` | - | - |
| vSphere | `vsphere` | - | - |

Multi-zone behaviour differs per provider and region: AWS `eu-west-1` and Cyso `ams2` expose several
availability zones, while Hetzner regions are single-zone. This directly changes how many machines
`node_count` produces - see [availability zones multiply your node count](#availability-zones-multiply-your-node-count).

## Examples

| Example | Provider | Shows |
| --- | --- | --- |
| [`examples/minimal`](examples/minimal) | any | The smallest working configuration: one cluster, one pool, one node |
| [`examples/aws`](examples/aws) | AWS | Multi-AZ with an HA control plane, three differently sized pools, one pinned to a single zone |
| [`examples/hetzner`](examples/hetzner) | Hetzner | Single-zone region, default labels, a hyphenated pool name |
| [`examples/cyso`](examples/cyso) | Cyso Cloud AMS2 | Private cluster with a NAT gateway, three-zone fan-out worked through |

Each example is a standalone root module. To run one:

```sh
cd examples/aws
export TF_VAR_acloud_token="acpat_..."
terraform init
terraform apply -var organisation_slug=... -var environment_slug=... -var cloud_account_name=...
```

## What this module does not cover

The module exposes a deliberately small surface. Everything below exists in the
[`avisi-cloud/acloud` provider](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs)
but is not passed through:

| Area | Provider attribute | Where |
| --- | --- | --- |
| Cluster add-ons (cert-manager, NFS, ingress, logging, ...) | `addons { name, enabled, custom_values }` | `acloud_cluster` |
| CNI choice (Calico / Cilium) | `cni` | `acloud_cluster` |
| Pod Security Standards profile | `pod_security_standards_profile` | `acloud_cluster` |
| Auto-upgrade and maintenance windows | `enable_auto_upgrade`, `maintenance_schedule_id` | `acloud_cluster` |
| Cluster follows a channel server-side | `update_channel` | `acloud_cluster` |
| Delete protection | `delete_protection` | `acloud_cluster` |
| Stop / start a cluster | `stopped` | `acloud_cluster` |
| Description | `description` | `acloud_cluster` |
| Node pool autoscaling | `auto_scaling`, `min_size`, `max_size` | `acloud_nodepool` |
| Per-pool upgrade strategy | `upgrade_strategy` | `acloud_nodepool` |
| Node taints | `taints { key, value, effect }` | `acloud_nodepool` |
| Security updates on join | `security_updates_on_join` | `acloud_nodepool` |
| Creating environments, cloud accounts, maintenance schedules | `acloud_environment`, `acloud_cloud_account`, `acloud_maintenance_schedule` | resources |

You do not have to choose. Add provider resources alongside the module - the module's `cluster`
output gives you the cluster identity, and the cluster slug is derived from `cluster_name`:

```hcl
module "cluster" {
  source  = "avisi-cloud/cluster/acloud"
  version = "0.1.0"
  # ...
  node_pools = {}   # let the module create the cluster only
}

resource "acloud_nodepool" "workers" {
  organisation = "example-org"
  environment  = "production"

  # AME derives the cluster slug from cluster_name. The module does not output
  # it, so take the slug from the cluster page in the Console.
  cluster   = "orders"
  name      = "workers"
  node_size = "t3.large"

  auto_scaling             = true
  min_size                 = 2
  max_size                 = 6
  node_auto_replacement    = true
  upgrade_strategy         = "REPLACE_MINOR_INPLACE_PATCH_WITHOUT_DRAIN"
  security_updates_on_join = "INSTALL_AND_REBOOT"

  labels = { role = "worker" }

  taints {
    key    = "dedicated"
    value  = "batch"
    effect = "NoSchedule"
  }

  depends_on = [module.cluster]
}
```

## Known rough edges

Honest list of things that are true of the current module and worth knowing before you adopt it.

| | Impact | Workaround |
| --- | --- | --- |
| `update_channel_name` defaults to `v1.28`, an EOL series | A cluster created without setting it targets an unsupported Kubernetes version | Always set `update_channel_name` (or `kubernetes_version`) explicitly |
| `default_availablity_zone` is misspelled | Cosmetic, but easy to mistype as `default_availability_zone` and then silently get no effect | Use the misspelled name; renaming it would be a breaking change |
| `data.acloud_cloud_provider_availability_zones.zones` in `module.tf` is unused | An extra API call on every plan, and a data source on the Registry's resource list that the module never reads | Harmless. Removing it is a one-line change |
| Node pools created through this module cannot autoscale | `min_size` and `max_size` are pinned to `node_count` by the child module | Declare `acloud_nodepool` directly for pools that need autoscaling |
| Multi-zone fan-out reuses the pool name for every zone | Each zone's pool is submitted with the same name and differs only by `availability_zone`. The provider's own multi-AZ examples instead use distinct names per zone (`workers-a`, `workers-b`, `workers-c`) | If you need per-zone names, declare `acloud_nodepool` directly |
| The `cluster` output exposes only `id` and `version` | No `slug`, `status` or node pool details to consume downstream | Read them back with the `acloud_cluster` data source |
| Provider floor is `>= 0.5.0` | Older than the `>= 0.10.1` the product docs recommend | Pin a newer version in your own `required_providers` |

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| `cloud account not found` on the `acloud_cloud_account` lookup | `cloud_account_name` must be the **display name** exactly as shown in the Console, and `cloud_provider` must be that account's provider slug |
| Cluster creation is rejected for the cloud account | The account is disabled, or has no primary cloud credentials. Only accounts with both can back new clusters |
| `update channel not found` | The channel name does not exist for your organisation. Use `acloud update-channels get` to list them |
| More nodes than expected | Multi-zone fan-out - `node_count` is per availability zone. See [above](#availability-zones-multiply-your-node-count) |
| Region or machine type rejected | The value is not offered by that cloud account in that region. Check with `acloud cloud-providers get` |
| `terraform apply` wants to change `version` unexpectedly | The update channel has moved to a newer AME version since the last apply |
| An upgrade takes a very long time | Workloads that shut down gracefully (PostgreSQL waiting for connections to close) or standalone pods delay node drains |
| 401 / 403 from the API | The PAT is invalid, expired, restricted to a different CIDR, or lacks access to the organisation |

## Documentation workflow

This repository keeps hand-written prose and generated reference tables in the same `README.md`.
Everything above the `BEGIN_TF_DOCS` marker is written by hand; everything between the markers is
generated by [terraform-docs](https://terraform-docs.io) from the `.tf` files and is overwritten on
every run. The same split applies to each `examples/*/README.md`.

```sh
make            # list the available targets
make docs       # regenerate every README's generated block, in place
make docs-check # fail if any generated block is stale - use this in CI
make docs-preview  # print the root module's generated reference to stdout
make fmt-check  # terraform fmt -check -recursive
make validate   # terraform init + validate for every example
make check      # fmt-check + docs-check
```

Formatting, section order and table settings live in [`.terraform-docs.yml`](.terraform-docs.yml).
Recursion into `examples/` is passed on the command line by the Makefile, so adding a new example
directory needs no configuration change.

For CI, `make check` is the single gate:

```yaml
- run: make check
```

### How this reaches the Terraform Registry

| Registry tab | Generated from |
| --- | --- |
| **Readme** | This `README.md`, rendered as-is - prose *and* the generated block |
| **Inputs** | The `variable` blocks in `variables.tf` and `nodepools.tf` - name, type, default, and the `description` string |
| **Outputs** | The `output` blocks and their `description` |
| **Dependencies** | `required_providers` in `module.tf`, and the `module` blocks |
| **Resources** | The `resource` and `data` blocks |
| **Examples** | Each subdirectory of `examples/`, with its own README |

The practical consequence: **the Inputs tab does not read this README.** Improving how an input is
documented means editing its `description` in the `.tf` file, then running `make docs` so the README
table matches. Registry pages are rebuilt when a new tag is published, so documentation changes only
become visible on the Registry after a release.

## Related documentation

**Avisi Cloud**

- [Product documentation](https://docs.avisi.cloud/) · [Why AME](https://docs.avisi.cloud/docs/product/why-ame) · [Feature overview](https://docs.avisi.cloud/docs/product/overview/features-quickview)
- [Terraform provider guide](https://docs.avisi.cloud/docs/development/terraform/terraform) · [Announcing the provider](https://docs.avisi.cloud/blog/announcing-our-terraform-provider)
- [Create a cluster](https://docs.avisi.cloud/docs/product/tasks/kubernetes/create-a-new-cluster) · [Create a node pool](https://docs.avisi.cloud/docs/product/tasks/kubernetes/create-a-new-nodepool) · [Update a cluster](https://docs.avisi.cloud/docs/product/tasks/kubernetes/update-a-cluster)
- [Node pools](https://docs.avisi.cloud/docs/product/overview/kubernetes/node-pool) · [Upgrades](https://docs.avisi.cloud/docs/product/overview/kubernetes/upgrades) · [Autoscaling](https://docs.avisi.cloud/docs/product/overview/kubernetes/autoscaler) · [Node recycling](https://docs.avisi.cloud/docs/product/overview/kubernetes/node-recycling)
- [Security updates on join](https://docs.avisi.cloud/docs/product/overview/kubernetes/security-updates-on-join) · [Networking](https://docs.avisi.cloud/docs/product/overview/kubernetes/networking) · [Pod Security Standards](https://docs.avisi.cloud/docs/product/overview/kubernetes/pod-security-standards-profile)
- [Lifecycle policy](https://docs.avisi.cloud/docs/product/overview/kubernetes/lifecycle-policy) · [Release notes](https://docs.avisi.cloud/docs/product/overview/release-notes) · [Runbooks](https://docs.avisi.cloud/docs/runbooks)
- [`acloud` CLI](https://docs.avisi.cloud/docs/cli) · [REST API](https://docs.avisi.cloud/docs/development/rest-api/overview) · [Go SDK](https://docs.avisi.cloud/docs/development/sdk/golang-sdk)

**Terraform**

- [Module on the Registry](https://registry.terraform.io/modules/avisi-cloud/cluster/acloud/latest) · [Node pool module](https://registry.terraform.io/modules/avisi-cloud/nodepool/acloud/latest) · [Provider](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs)
- [Provider source and examples](https://github.com/avisi-cloud/terraform-provider-acloud)

<!-- BEGIN_TF_DOCS -->
## Reference

Generated from the `.tf` files in this directory with [terraform-docs](https://terraform-docs.io).
Run `make docs` after changing any variable, output, resource or module block.

### Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_acloud"></a> [acloud](#requirement\_acloud) | >= 0.5.0 |

### Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_acloud"></a> [acloud](#provider\_acloud) | >= 0.5.0 |

### Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_nodepool"></a> [nodepool](#module\_nodepool) | avisi-cloud/nodepool/acloud | 0.1.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [acloud_cluster.cluster](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/resources/cluster) | resource |
| [acloud_cloud_account.account](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/cloud_account) | data source |
| [acloud_cloud_provider_availability_zones.zones](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/cloud_provider_availability_zones) | data source |
| [acloud_update_channel.channel](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/update_channel) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cloud_account_name"></a> [cloud\_account\_name](#input\_cloud\_account\_name) | Display name of the AME cloud account used to provision the cluster, exactly as shown on the Cloud Accounts page in the Console (for example `Cyso Cloud AMS2`). Only cloud accounts that are enabled and have primary cloud credentials can be used for new clusters. | `string` | n/a | yes |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Slug of the AME cloud provider the cluster is provisioned on. Must match the cloud provider of the cloud account named in `cloud_account_name`, and the region must be offered by that provider. Common slugs are `aws`, `azure`, `hetzner`, `cyso-cloud-ams2`, `leafcloud`, `openstack` and `vsphere`; the exact set depends on your organisation. Run `acloud cloud-providers get` to list them. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Display name of the cluster in the Avisi Cloud Console. AME derives the cluster slug from this name, and the slug is what node pools and `acloud` commands address. Changing the name after creation is not handled by this module and forces a new cluster. | `string` | n/a | yes |
| <a name="input_default_node_size"></a> [default\_node\_size](#input\_default\_node\_size) | Cloud provider machine type used by node pools that do not set `node_size`, for example `t3.medium` (AWS), `cx33` (Hetzner) or `s5.small` (Cyso Cloud AMS2). The type must be offered in `region` for the selected cloud account. Run `acloud cloud-providers get` to list the available types. | `string` | n/a | yes |
| <a name="input_environment_slug"></a> [environment\_slug](#input\_environment\_slug) | Slug of the AME environment the cluster is created in. An environment groups clusters inside an organisation (for example `production` or `staging`) and is the boundary for cluster access. The environment must already exist; create it in the Console, with `acloud environments create`, or with an `acloud_environment` resource and pass its `slug` here. | `string` | n/a | yes |
| <a name="input_organisation_slug"></a> [organisation\_slug](#input\_organisation\_slug) | Slug of the Avisi Cloud organisation that owns the environment and the cluster. This is the short identifier used in Console URLs and API paths, not the display name. Run `acloud config get-organisations` to list the slugs you have access to. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Slug of the cloud provider region the cluster is provisioned in, for example `eu-west-1` (AWS), `fsn1` (Hetzner) or `ams2` (Cyso Cloud AMS2). The region also determines which availability zones node pools can be spread over. Can only be set at creation time. | `string` | n/a | yes |
| <a name="input_default_availablity_zone"></a> [default\_availablity\_zone](#input\_default\_availablity\_zone) | Availability zone used by single-zone node pools that do not set `availability_zone`, for example `eu-west-1a`. Only has an effect on pools where multi-AZ is off; multi-zone pools always fan out over every zone in the region. The empty default lets AME place the pool. Note: the misspelling is preserved for backwards compatibility. | `string` | `""` | no |
| <a name="input_default_node_annotations"></a> [default\_node\_annotations](#input\_default\_node\_annotations) | Kubernetes node annotations applied by node pools that do not set `annotations`. Annotations are set on every node in the pool and are typically consumed by automation rather than by the scheduler. | `map(string)` | `{}` | no |
| <a name="input_default_node_count"></a> [default\_node\_count](#input\_default\_node\_count) | Number of nodes per node pool for pools that do not set `node_count`. With `enable_multi_availability_zones` on, this is the count *per availability zone*, so the pool provisions this many nodes in every zone of the region. | `number` | `1` | no |
| <a name="input_default_node_labels"></a> [default\_node\_labels](#input\_default\_node\_labels) | Kubernetes node labels applied by node pools that do not set `labels`. Labels are set on every node in the pool and can be used for scheduling with `nodeSelector` or node affinity. | `map(string)` | `{}` | no |
| <a name="input_default_node_pool_auto_healing"></a> [default\_node\_pool\_auto\_healing](#input\_default\_node\_pool\_auto\_healing) | Auto-healing setting for node pools that do not set `enable_auto_healing`. When enabled, AME automatically replaces nodes it detects as unhealthy. Maps to `node_auto_replacement` on the underlying `acloud_nodepool` resource. | `bool` | `true` | no |
| <a name="input_enable_high_available_control_plane"></a> [enable\_high\_available\_control\_plane](#input\_enable\_high\_available\_control\_plane) | Run the Kubernetes control plane in high-availability mode, removing the single points of failure in `kube-apiserver` and `etcd`. AME picks the concrete model - Single-Zone HA or Multi-Zone HA - from the capabilities of the AME cluster pool the control plane lands in; Multi-Zone HA is only available in multi-zone pools. | `bool` | `false` | no |
| <a name="input_enable_multi_availability_zones"></a> [enable\_multi\_availability\_zones](#input\_enable\_multi\_availability\_zones) | Spread the cluster and its node pools over every availability zone in `region`. This also drives node pool fan-out: with this enabled the module creates one node pool per availability zone, so a pool with `node_count = 2` in a three-zone region provisions six nodes. Cannot be changed after the cluster is created, and may increase cost (for example when combined with a NAT gateway). | `bool` | `true` | no |
| <a name="input_enable_network_encryption"></a> [enable\_network\_encryption](#input\_enable\_network\_encryption) | Enable encryption of pod-to-pod traffic at the cluster network layer. This is a CNI feature and is only supported by Calico; it has a measurable performance impact. | `bool` | `true` | no |
| <a name="input_enable_private_cluster"></a> [enable\_private\_cluster](#input\_enable\_private\_cluster) | Provision the cluster without public IP addresses on its nodes, routing outbound traffic through a NAT gateway so nodes share a static egress IP. Availability and exact behaviour are cloud-provider specific, and it makes provisioning slower because extra cloud resources are created. Can only be set at creation time. | `bool` | `false` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Exact AME Kubernetes version to run, for example `v1.35.6-u-ame.4`. Leave this `null` (the default) to resolve the version from `update_channel_name` instead. Setting it pins the cluster: the version only changes when you change this value. | `string` | `null` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of node pool name to per-pool overrides. Keys become the AME node pool names and are used for the Kubernetes node role label. Supported override keys are `node_size`, `node_count`, `labels`, `annotations`, `enable_auto_healing`, `enable_multi_availability_zones` and `availability_zone`; any key a pool omits falls back to the matching `default_*` variable. Set this to `{}` to create a cluster with no node pools. | `any` | <pre>{<br/>  "data": {},<br/>  "ingress": {},<br/>  "worker": {}<br/>}</pre> | no |
| <a name="input_update_channel_name"></a> [update\_channel\_name](#input\_update\_channel\_name) | Name of the AME update channel used to resolve the Kubernetes version when `kubernetes_version` is null. Channels are either rolling (`stable`, `regular`, `preview`) or pinned to a Kubernetes minor series (`v1.34`, `v1.35`, ...). AME recommends `regular` for production. Note: the module default `v1.28` is an end-of-life series - set this explicitly for new clusters. | `string` | `"v1.28"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | The created AME cluster: `id` is the cluster UUID used by the API and the Console, `version` is the AME Kubernetes version that was actually provisioned (useful when the version came from an update channel). |
<!-- END_TF_DOCS -->
