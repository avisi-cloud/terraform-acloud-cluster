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

  default_node_size = "t3.medium"

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
- [Add-ons](#add-ons)
- [Cloud providers](#cloud-providers)
- [Examples](#examples)
- [What this module does not cover](#what-this-module-does-not-cover)
- [Known rough edges](#known-rough-edges)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
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
| `addons` blocks on the cluster | one per `addons` entry | Managed components AME installs into the cluster |

The module does **not** create the organisation, the environment or the cloud account. Those must
already exist, and the module looks them up.

## When to use this module

**Use it when** the organisation, environment and cloud account already exist, and you want a
standard cluster with a handful of similarly configured node pools managed as one unit. It is the
fastest path from nothing to a running AME cluster in Terraform.

Every cluster-level attribute the provider supports is an input here: add-ons, CNI choice, Pod
Security Standards, auto-upgrade with a maintenance schedule and the rest. Some of those inputs are
only as good as the provider behind them - see [known rough edges](#known-rough-edges) before
relying on `delete_protection`, or on the defaults for `cni` and `pod_security_standards_profile`.

**Reach for the [provider resources](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs)
directly when** you need node pool autoscaling, taints, per-pool upgrade strategies, security updates
on join, or distinct pool names per availability zone. Those are node pool settings, and the pinned
node pool module does not accept them yet - see
[what this module does not cover](#what-this-module-does-not-cover). The two approaches mix freely in
the same configuration.

## Requirements

### Tooling

| | Version |
| --- | --- |
| Terraform | **`>= 1.3.0`**, declared by the module. The binding constraint is `optional()` in the `addons` variable type |
| `avisi-cloud/acloud` provider | **`>= 0.10.0`** - the release that added the `addons` block |

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

> **Warning:**
> A PAT is a long-lived credential with your full user permissions and no scope narrowing. Never
> commit one, and never expose it to a tool or agent that does not need it.

## Quick start

```hcl
terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
      version = ">= 0.10.0"
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

  # Multi-AZ cannot be changed after the cluster is created. The HA control
  # plane can be turned on later, but deciding both up front is simpler.
  enable_multi_availability_zones     = true
  enable_high_available_control_plane = true

  # Set these explicitly rather than relying on defaults: an unset profile
  # gets you `privileged`, and an unset CNI does not reliably mean Calico.
  pod_security_standards_profile = "restricted"
  cni                            = "calico"

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

AME documents a control plane as typically ready in around two minutes, and a full cluster including
its nodes usually finishing within seven; treat those as the platform's own guidance rather than a
guarantee. Enabling a private cluster adds time because extra cloud resources are provisioned. Afterwards, fetch credentials with `acloud kubeconfig install` or the *Download
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

> **Important:**
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
| `availability_zone` | `default_availability_zone` | Zone for a single-zone pool. The older, misspelled `default_availablity_zone` still works as a fallback |

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
default_availability_zone       = "eu-west-1a"

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
| **Autoscaling** | Effectively off. The pinned child module (0.1.0) fixes `min_size` and `max_size` to `node_count` and never sets `auto_scaling`. |
| **Upgrade strategy** | Not sent at all - which is currently a **bug that blocks new node pools**, see the warning below. |
| **Security updates on join** | Provider default, `OFF` - nodes join with the packages from their base image. AME recommends `INSTALL_AND_REBOOT`, a beta feature; see the [reference docs](https://docs.avisi.cloud/docs/product/overview/kubernetes/security-updates-on-join) and the [announcement blog](https://docs.avisi.cloud/blog/security-updates-on-join). Supported by the node pool module, but not reachable through this one until the pin is bumped. |
| **Taints** | None. |
| **Automatic node reboots** | Configured on the cluster's *Patching* page, not through Terraform. |

> **Warning:**
> **Creating node pools through this module currently fails against provider 0.8.0 and newer.**
> The pinned node pool module (0.1.0) never sets `upgrade_strategy` on the `acloud_nodepool`
> resource. From provider 0.8.0 onwards the provider parses that attribute unconditionally when it
> creates a pool, and rejects the empty string an unset value produces, so `apply` stops with:
>
> ```
> cannot parse upgradeStrategy: unsupported upgrade strategy:
> ```
>
> Because this module's provider floor resolves to a current release, a fresh `apply` hits it.
> Node pool module 0.2.0 fixes this by always sending a valid strategy, and this module picks the
> fix up when its pin moves to 0.2.0 - it cannot be worked around from here. Until then, create the
> cluster with `node_pools = {}` and declare `acloud_nodepool` resources directly, setting
> `upgrade_strategy` explicitly on each.

> **Caution:**
> **Do not combine autoscaling with automatic node reboots while nodes join unpatched.** A node joins,
> is patched the next morning, and is drained to reboot; the evicted pods make the autoscaler add
> another unpatched node, and the rebooted node comes back empty and is scaled down again. The pool
> then recycles every node, every day. Setting security updates on join to `INSTALL_AND_REBOOT`
> removes the cause. Neither is reachable through this module today, so the combination only arises
> if you enable them elsewhere - but it is the failure mode to recognise.
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
| `regular` | Rolling | **The module default, and what AME recommends for production workloads** |
| `stable` | Rolling, trailing `regular` | Trail the recommendation deliberately |
| `preview` | Rolling, ahead of `regular` | Try the next Kubernetes version on staging first |
| `v1.34`, `v1.35`, ... | Pinned to one Kubernetes minor series, still receiving patch releases | Adopt minor versions on your own schedule |

Which Kubernetes minor each rolling channel currently points at is published in the
[release notes](https://docs.avisi.cloud/docs/product/overview/release-notes) - `stable` trails
`regular`, which trails `preview`. How far apart they are is not fixed, so read the release notes
rather than assuming a constant offset.

Each channel is a separate thing you ask for **by name**. If you have written raw provider
configuration before, `update_channel_name` is the module's equivalent of the data source lookup you
would otherwise do yourself:

```hcl
# Raw provider configuration
data "acloud_update_channel" "channel" {
  name = "preview"
}

resource "acloud_cluster" "example" {
  version = data.acloud_update_channel.channel.version
  # ...
}

# The same thing through this module
update_channel_name = "preview"
```

That is also why a test suite covering all three channels needs one configuration per channel -
asking for `preview` gets you `preview` and nothing else.

The default is `regular`, so a cluster you create without touching this input runs the version AME
recommends for production - there is no Kubernetes version to fill in at all.

> **Note:**
> A rolling channel means the version is not frozen. When AME advances `regular` to the next minor
> series, the next `terraform plan` shows a version diff and `apply` performs a **minor** upgrade,
> which recycles nodes. If you would rather adopt minor versions on your own schedule, pin the
> channel to a series (`update_channel_name = "v1.35"`) or pin the version outright with
> `kubernetes_version`. See [how upgrades show up in Terraform](#how-upgrades-show-up-in-terraform).

#### Migrating from the old `v1.28` default

> **Note:**
> Update channels are managed by AME, and an end-of-life channel can stop being offered. If step 1
> below fails with `update channel not found`, that channel is gone: pin `kubernetes_version` to the
> version the cluster is running right now instead, then step forward through the channels that do
> still exist.

Earlier versions of this module defaulted `update_channel_name` to `v1.28`. If your configuration
never set the input, bumping the module moves the target from Kubernetes 1.28 to whatever `regular`
points at today - several minor versions ahead. **AME only supports upgrading one minor version at a
time**, so do not apply that as a single step:

```hcl
# 1. Bump the module and keep the old behaviour, so the plan is a no-op.
update_channel_name = "v1.28"

# 2. Then step forward one series per apply: "v1.29", "v1.30", ...
#    checking the release notes for each target version.

# 3. Once you reach the series `regular` points at, drop the input entirely
#    and let the default take over.
```

Configurations that already set `update_channel_name` or `kubernetes_version` are unaffected.

### How upgrades show up in Terraform

The module resolves a channel to a **concrete version string** and writes that to state. So a channel
that has moved forward appears as an ordinary diff on the `version` attribute at the next `plan`, and
the upgrade happens on `apply` - it is not a background auto-upgrade. Expect nodes to be replaced or
upgraded in place depending on the pool's upgrade strategy, and read the
[release notes](https://docs.avisi.cloud/docs/product/overview/release-notes) for the target version
before applying.

Note that this cuts both ways depending on which channel you are on. A **pinned** channel (`v1.35`)
or a pinned `kubernetes_version` only ever moves when you change the value, so minor upgrades are
always an explicit act. A **rolling** channel moves on its own: when AME advances `regular` to the
next minor series, the next plan proposes that minor upgrade without you editing anything. Either
way the upgrade itself happens on `apply`, and AME supports one minor version at a time.

### Letting AME do the upgrading

Everything above describes Terraform proposing upgrades at plan time. AME can also upgrade the
cluster on its own, which needs three inputs together:

```hcl
# 1. Record the channel on the cluster, so AME knows what to upgrade towards.
update_channel = "regular"

# 2. Allow AME to act on it.
enable_auto_upgrade = true

# 3. Give it a window to act in. Without a schedule there is no window, and
#    nothing will happen.
maintenance_schedule_id = acloud_maintenance_schedule.nightly.id
```

with the schedule itself declared through the provider:

```hcl
resource "acloud_maintenance_schedule" "nightly" {
  name         = "nightly"
  organisation = "example-org"

  windows {
    day        = "SUNDAY"   # java.time.DayOfWeek, uppercase
    start_time = "02:00"
    duration   = 180        # minutes
  }
}
```

> **Note:**
> `update_channel` and `update_channel_name` are different things, and the similar names are
> unfortunate. `update_channel_name` is used **by Terraform, at plan time**, to resolve a version.
> `update_channel` is written **to the cluster**, so AME knows what to upgrade towards. Set both to
> the same value unless you deliberately want them to differ.

Maintenance schedules are managed organisation-wide, so one schedule is usually shared by many
clusters. See [auto upgrade](https://docs.avisi.cloud/docs/product/overview/kubernetes/auto-upgrade).

## Cluster options

### Topology and networking

| Input | Default | Changeable later | Notes |
| --- | --- | --- | --- |
| `enable_multi_availability_zones` | `true` | **No** | Spreads the cluster over the zones of the region, and fans node pools out per zone. May increase cost, for example combined with a NAT gateway. |
| `enable_high_available_control_plane` | `false` | Yes | Removes the single points of failure in `kube-apiserver` and `etcd`. AME selects Single-Zone HA or Multi-Zone HA automatically, based on the cluster pool the control plane lands in. |
| `enable_private_cluster` | `false` | **No** | Nodes get no public IP; egress goes through a NAT gateway with a static outbound address. Availability is cloud-provider specific and provisioning takes longer. With a private cluster, reach nodes by their internal IP. |
| `cni` | `null` - see the warning below | Not reliably | `calico`, `cilium` or `custom`. Cilium uses eBPF and adds Layer 7 load balancing and richer observability. The provider omits `cni` from its update payload, so treat it as a creation-time choice. |
| `enable_network_encryption` | `true` | Yes | Encrypts pod-to-pod traffic at the CNI layer. Implemented by **Calico only**, and it has a measurable performance impact. It silently does nothing on a Cilium cluster, so set `cni = "calico"` alongside it. |

### Policy and metadata

| Input | Default | Notes |
| --- | --- | --- |
| `pod_security_standards_profile` | `null`, which the provider turns into **`privileged`** | `privileged`, `baseline` or `restricted`. AME recommends `restricted`, relaxing it per namespace with `pod-security.kubernetes.io/*` labels. Set it explicitly - see the warning below. |
| `delete_protection` | `null` | **Currently inert.** The provider has the attribute but never sends it, so this does not protect anything today. Use the Console. |
| `description` | `null` | Free text shown in the Console. Only sent when the cluster is created; later edits do not reach AME. |
| `cluster_state_wait_seconds` | `null` (provider default: `600`) | How long the provider waits for the cluster to become ready. Raise it when provisioning is slow, such as a private cluster. |

Values for `cni` and `pod_security_standards_profile` are matched case-insensitively by AME, so
`cilium` and `CILIUM` are equivalent. The Kubernetes API server IP allowlist remains a Console-only
setting.

> **Warning:**
> **Two defaults here are not what "leave it unset" suggests, and both are security-relevant.**
>
> `pod_security_standards_profile` looks like it falls back to an AME-chosen default. It does not:
> the provider substitutes its own default of `privileged` - the *least* restrictive profile - and
> sends that explicitly. AME would fall back to `baseline` if nothing were sent, but the provider
> never lets that happen. Set `restricted` unless you know you need otherwise.
>
> `cni` is genuinely ambiguous today. AME's product documentation states Calico is the default,
> while the platform API has defaulted an omitted CNI to Cilium since early 2024. Since
> `enable_network_encryption` only does anything on Calico, and it defaults to `true`, an unset
> `cni` can leave you with a cluster that looks encrypted in your configuration and is not. Set
> `cni` explicitly whenever encryption matters.

## Add-ons

Add-ons are components **AME installs and keeps up to date inside your cluster** - that management is
what makes something an add-on rather than just a workload you deploy. Do not also install these
yourself; you will end up fighting the platform.

The `addons` input is keyed by add-on name:

```hcl
addons = {
  certManager = {}                       # enabled defaults to true
  monitoring  = {}
  logging     = {}
  nfs         = { enabled = false }      # explicitly disabled

  ingressController = {}                 # see the warning below - do not pin a type
}
```

| Add-on name | What it manages | State |
| --- | --- | --- |
| `defaultNetworkPolicies` | A baseline set of Kubernetes NetworkPolicies | Stable |
| `logging` | Log shipping into the AME observability stack (Loki) | Stable |
| `monitoring` | In-cluster Prometheus, forwarding metrics to AME's long-term storage | Stable |
| `certManager` | cert-manager, for issuing and renewing TLS certificates | Beta |
| `cloudNativePG` | The CloudNativePG operator for running PostgreSQL | Beta |
| `fluxOperator` | The Flux operator, for GitOps delivery | Beta |
| `gpu` | GPU device drivers and runtime configuration | Beta |
| `ingressController` | A managed ingress controller and its load balancer | Beta - **in flux, see below** |
| `kured` | Coordinated node reboots after OS patches | Beta |
| `nfs` | An NFS provisioner for shared storage | Beta |
| `sealedSecrets` | The Sealed Secrets controller | Beta |

Most add-ons take no `custom_values` at all. Two do: `ingressController` accepts a single key,
`type`, which selects the ingress implementation (today `ingress-nginx` or `traefik` - but see the
warning below), and `kured` accepts reboot-window settings (`forceReboot`, `rebootDays`,
`startTime`, `endTime`, `timeZone`). The `kured` keys are read from the platform's add-on service
rather than from published documentation, so confirm them in the Console before depending on them.

### The ingress controller add-on is changing

> **Warning:**
> **Do not pin `custom_values.type` on the ingress controller add-on.**
>
> Both implementations currently on offer are on their way out. `ingress-nginx` is being deprecated,
> with restrictions on enabling it being introduced - so enabling it on a new cluster may already be
> refused. `traefik` is the current default, but it is being superseded too: Avisi Cloud is working
> on a newer, improved managed ingress controller.
>
> Leave `custom_values` unset and the cluster follows whatever AME's current default is, which is the
> only choice that carries forward on its own:
>
> ```hcl
> addons = {
>   ingressController = {}
> }
> ```
>
> Clusters already running one of these keep working. Before pinning anything explicitly, check the
> [managed ingress controller documentation](https://docs.avisi.cloud/docs/product/overview/add-ons/managed-ingress-controller)
> or the Console for what is current - this module intentionally does not validate the value, since
> a hard block would break clusters legitimately still running an older implementation.

Enabling the ingress controller provisions a cloud load balancer through a Kubernetes Service, and
the cluster needs at least one node pool first. Disabling the add-on removes that LoadBalancer
service, which releases its cloud IP address - so if anything points DNS at that address, move it
before you disable.

## Cloud providers

`cloud_provider` takes an AME cloud provider **slug**, which must match the cloud account named in
`cloud_account_name`. Run `acloud cloud-providers get` to list the providers, regions and machine
types available to your organisation - what follows is orientation, not an availability guarantee.

| Provider | Slug | Example region | Example machine type |
| --- | --- | --- | --- |
| Amazon Web Services | `aws` | `eu-west-1` | `t3.medium` |
| Hetzner Cloud | `hetzner` | `fsn1` | `cx33` |
| Cyso Cloud AMS2 | `cyso-cloud-ams2` | `ams2` | `s5.small` |
| Leafcloud | `leafcloud` | `europe-nl` | `cn1.medium` |
| Azure | `azure` | - | - |
| OpenStack | `openstack` | - | - |
| vSphere | `vsphere` | - | - |

Multi-zone behaviour differs per provider and region: Cyso `ams2` exposes three availability zones,
while Hetzner regions are single-zone. This directly changes how many machines `node_count` produces
- see [availability zones multiply your node count](#availability-zones-multiply-your-node-count).

Do not assume a region has zones just because the underlying cloud provider offers them. AME
publishes availability zones against a specific region slug, and a provider's multi-zone region may
be published under a slug of its own rather than under the plain cloud provider name. `acloud
cloud-providers get` is the authority on which slug to use.

## Examples

| Example | Provider | Shows |
| --- | --- | --- |
| [`examples/minimal`](https://github.com/avisi-cloud/terraform-acloud-cluster/tree/main/examples/minimal) | any | The smallest working configuration: one cluster, one pool, one node |
| [`examples/aws`](https://github.com/avisi-cloud/terraform-acloud-cluster/tree/main/examples/aws) | AWS | Multi-AZ with an HA control plane, three differently sized pools, one pinned to a single zone |
| [`examples/hetzner`](https://github.com/avisi-cloud/terraform-acloud-cluster/tree/main/examples/hetzner) | Hetzner | Single-zone region, default labels, a hyphenated pool name |
| [`examples/cyso`](https://github.com/avisi-cloud/terraform-acloud-cluster/tree/main/examples/cyso) | Cyso Cloud AMS2 | Private cluster with a NAT gateway, three-zone fan-out worked through |

Each example is a standalone root module. To run one:

```sh
cd examples/aws
export TF_VAR_acloud_token="acpat_..."
terraform init
terraform apply -var organisation_slug=... -var environment_slug=... -var cloud_account_name=...
```

## What this module does not cover

Every cluster-level attribute of the `acloud_cluster` resource is now passed through. What is left:

| Area | Provider attribute | Why not |
| --- | --- | --- |
| Node pool autoscaling | `auto_scaling`, `min_size`, `max_size` | Not reachable yet - see below |
| Node taints | `taints { key, value, effect }` | Not reachable yet - see below |
| Per-pool upgrade strategy | `upgrade_strategy` | Not reachable yet - see below |
| Security updates on join | `security_updates_on_join` | Not reachable yet - see below |
| Stop / start a cluster | `stopped` | **Deprecated** in the provider. Do not build new configuration on it |
| Working delete protection | `delete_protection` | The input exists here, but the provider never sends the attribute, so it does nothing today |
| Kubernetes API server IP allowlist | - | A Console-only setting, not exposed by the provider |
| Creating environments, cloud accounts, maintenance schedules | `acloud_environment`, `acloud_cloud_account`, `acloud_maintenance_schedule` | Separate resources - compose them alongside this module |

### Why node pool settings are not reachable yet

The four node pool settings above are attributes of `acloud_nodepool`, and this module never creates
that resource - it delegates every pool to
[`avisi-cloud/nodepool/acloud`](https://registry.terraform.io/modules/avisi-cloud/nodepool/acloud/latest),
pinned here at **0.1.0**. That version does not accept them, so there is nothing for `node_pools` to
forward.

The node pool module has since gained all four. Once a release carrying them is published, this
module can bump its pin and expose them as additional `node_pools` override keys. That same pin bump
is also what fixes the create-time failure described [above](#what-the-module-does-not-set-on-a-node-pool),
which is why it is a release blocker rather than a nice-to-have.

Until then, declare the pools you need directly. Note that `upgrade_strategy` is not optional in
practice: leave it out and the provider rejects the create.

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

  # The module outputs the slug AME derived from cluster_name, so the pool can
  # be wired to the cluster without hardcoding it.
  cluster   = module.cluster.cluster.slug
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

Mixing the two is fine: the module manages the cluster and its standard pools, and hand-written
`acloud_nodepool` resources sit alongside them.

## Known rough edges

Honest list of things that are true of the current module and worth knowing before you adopt it.

| | Impact | Workaround |
| --- | --- | --- |
| `update_channel_name` defaults to the rolling `regular` channel | Version is not frozen: when AME advances the channel, the next plan proposes a minor upgrade that recycles nodes | Pin a series (`v1.35`) or a version (`kubernetes_version`) if you want to control when that happens |
| **Node pools cannot be created at all against provider 0.8.0+** | The pinned node pool module never sends `upgrade_strategy`, which the provider rejects. `apply` fails with `cannot parse upgradeStrategy` | Use `node_pools = {}` and declare `acloud_nodepool` directly until the pin moves to node pool module 0.2.0 |
| `delete_protection` does nothing | The provider never sends the attribute, so a cluster you believe is protected is not | Set delete protection in the Console |
| An unset `pod_security_standards_profile` means `privileged` | The provider defaults it to the least restrictive profile rather than letting AME choose `baseline` | Always set it explicitly; `restricted` is AME's recommendation |
| An unset `cni` has an ambiguous meaning | Product docs say Calico, the platform API defaults to Cilium. Combined with `enable_network_encryption = true` this can silently produce an unencrypted cluster | Set `cni` explicitly |
| `default_availablity_zone` is misspelled | The name is wrong, and easy to mistype as the correct spelling | Use `default_availability_zone`, which now exists and takes precedence. The misspelled input still works |
| Node pools created through this module cannot autoscale, be tainted, or set an upgrade strategy | The pinned node pool module (0.1.0) does not accept those inputs, even though the module now supports them upstream | Declare `acloud_nodepool` directly, or wait for the pin to be bumped |
| Multi-zone fan-out reuses the pool name for every zone | Each zone's pool is submitted with the same name and differs only by `availability_zone`. The provider's own multi-AZ examples instead use distinct names per zone (`workers-a`, `workers-b`, `workers-c`) | If you need per-zone names, declare `acloud_nodepool` directly |
| The `cluster` output carries no node pool details | `id`, `slug`, `version` and `status` are exposed, but nothing about the pools themselves | Read them back with the `acloud_nodepool` data source |
| Provider floor raised to `>= 0.10.0` | Required by the `addons` block. Configurations pinned to an older provider will not resolve | Upgrade the provider; 0.10.0 is from January 2026 |

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

## Contributing

Development setup, the `make` workflow, how the generated README blocks work, and the release
process live in [CONTRIBUTING.md](https://github.com/avisi-cloud/terraform-acloud-cluster/blob/main/CONTRIBUTING.md).

One consequence is worth repeating here, because it catches people out: **the Registry's Inputs tab
is generated from the `variable` blocks, not from this README.** Improving how an input is
documented means editing its `description` in the `.tf` file and running `make docs`.

## Related documentation

**Avisi Cloud**

- [Product documentation](https://docs.avisi.cloud/) · [Why AME](https://docs.avisi.cloud/docs/product/why-ame) · [Feature overview](https://docs.avisi.cloud/docs/product/overview/features-quickview)
- [Terraform provider guide](https://docs.avisi.cloud/docs/development/terraform/terraform) · [Announcing the provider](https://docs.avisi.cloud/blog/announcing-our-terraform-provider)
- [Create a cluster](https://docs.avisi.cloud/docs/product/tasks/kubernetes/create-a-new-cluster) · [Create a node pool](https://docs.avisi.cloud/docs/product/tasks/kubernetes/create-a-new-nodepool) · [Update a cluster](https://docs.avisi.cloud/docs/product/tasks/kubernetes/update-a-cluster)
- [Node pools](https://docs.avisi.cloud/docs/product/overview/kubernetes/node-pool) · [Upgrades](https://docs.avisi.cloud/docs/product/overview/kubernetes/upgrades) · [Autoscaling](https://docs.avisi.cloud/docs/product/overview/kubernetes/autoscaler) · [Node recycling](https://docs.avisi.cloud/docs/product/overview/kubernetes/node-recycling)
- [Security updates on join](https://docs.avisi.cloud/docs/product/overview/kubernetes/security-updates-on-join) · [announcement blog](https://docs.avisi.cloud/blog/security-updates-on-join) · [Networking](https://docs.avisi.cloud/docs/product/overview/kubernetes/networking) · [Pod Security Standards](https://docs.avisi.cloud/docs/product/overview/kubernetes/pod-security-standards-profile)
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_acloud"></a> [acloud](#requirement\_acloud) | >= 0.10.0 |

### Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_acloud"></a> [acloud](#provider\_acloud) | >= 0.10.0 |

### Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_nodepool"></a> [nodepool](#module\_nodepool) | avisi-cloud/nodepool/acloud | 0.1.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [acloud_cluster.cluster](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/resources/cluster) | resource |
| [acloud_cloud_account.account](https://registry.terraform.io/providers/avisi-cloud/acloud/latest/docs/data-sources/cloud_account) | data source |
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
| <a name="input_addons"></a> [addons](#input\_addons) | Managed AME add-ons to configure, keyed by add-on name. Available names are `certManager`, `cloudNativePG`, `defaultNetworkPolicies`, `fluxOperator`, `gpu`, `ingressController`, `kured`, `logging`, `monitoring`, `nfs` and `sealedSecrets`. Each entry takes `enabled` (defaults to true) and `custom_values`, a string map whose accepted keys depend on the add-on: `ingressController` takes `type`, which selects the ingress implementation, and `kured` takes reboot-window settings. Leave `ingressController`'s `type` unset: the implementations it currently accepts are all being superseded, and an unset value follows whatever AME's current default is. Add-ons are managed by AME rather than by you, so do not also install them yourself. Requires provider >= 0.10.0. | <pre>map(object({<br/>    enabled       = optional(bool, true)<br/>    custom_values = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_cluster_state_wait_seconds"></a> [cluster\_state\_wait\_seconds](#input\_cluster\_state\_wait\_seconds) | How long the provider waits for the cluster to reach its desired state before timing out. Raise it when provisioning is slow, for example on a private cluster where extra cloud resources are created first. Leave null to use the provider default of 600 seconds. | `number` | `null` | no |
| <a name="input_cni"></a> [cni](#input\_cni) | Container Network Interface plugin for the cluster: `calico`, `cilium`, or `custom` to bring your own. Cilium uses eBPF and adds Layer 7 load balancing and richer observability; Calico is the only plugin that supports `enable_network_encryption`. Values are case-insensitive. Leave null to let AME choose, but be aware that which plugin that gets you is currently ambiguous: the AME product documentation states Calico is the default, while the platform API has defaulted an omitted CNI to Cilium since early 2024. Set this explicitly whenever the choice matters to you - in particular when you rely on network encryption. Note also that the provider does not send this attribute when it updates an existing cluster, so changing it afterwards may not take effect. | `string` | `null` | no |
| <a name="input_default_availability_zone"></a> [default\_availability\_zone](#input\_default\_availability\_zone) | Availability zone used by single-zone node pools that do not set `availability_zone`, for example `eu-west-1a`. Only has an effect on pools where multi-AZ is off; multi-zone pools always fan out over every zone in the region. Leave null to let AME place the pool. This is the correctly spelled replacement for `default_availablity_zone`; when both are set, this one wins. | `string` | `null` | no |
| <a name="input_default_availablity_zone"></a> [default\_availablity\_zone](#input\_default\_availablity\_zone) | DEPRECATED, and misspelled - use `default_availability_zone` instead, which does the same thing. Kept so that existing configurations keep working; it is only consulted when `default_availability_zone` is null, and it will be removed in a future major release. | `string` | `""` | no |
| <a name="input_default_node_annotations"></a> [default\_node\_annotations](#input\_default\_node\_annotations) | Kubernetes node annotations applied by node pools that do not set `annotations`. Annotations are set on every node in the pool and are typically consumed by automation rather than by the scheduler. | `map(string)` | `{}` | no |
| <a name="input_default_node_count"></a> [default\_node\_count](#input\_default\_node\_count) | Number of nodes per node pool for pools that do not set `node_count`. With `enable_multi_availability_zones` on, this is the count *per availability zone*, so the pool provisions this many nodes in every zone of the region. | `number` | `1` | no |
| <a name="input_default_node_labels"></a> [default\_node\_labels](#input\_default\_node\_labels) | Kubernetes node labels applied by node pools that do not set `labels`. Labels are set on every node in the pool and can be used for scheduling with `nodeSelector` or node affinity. | `map(string)` | `{}` | no |
| <a name="input_default_node_pool_auto_healing"></a> [default\_node\_pool\_auto\_healing](#input\_default\_node\_pool\_auto\_healing) | Auto-healing setting for node pools that do not set `enable_auto_healing`. When enabled, AME automatically replaces nodes it detects as unhealthy. Maps to `node_auto_replacement` on the underlying `acloud_nodepool` resource. | `bool` | `true` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Intended to block deletion of the cluster in AME until the protection is lifted. **Currently inert: do not rely on it.** The attribute exists in the provider's schema from 0.10.0 onwards, but the provider does not send it when creating a cluster, does not read it back, and does not send it on update - so setting it here changes nothing on the platform. It is exposed so that configurations are ready for a provider release that implements it. Set delete protection in the Console if you need it today. Note that Terraform can remove the resource from state regardless; this was only ever a guard on the AME side. | `bool` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Human-readable description of the cluster, shown in the Avisi Cloud Console. Note that the provider only sends this when the cluster is created; it is not part of the update payload, so editing it later has no effect until the cluster is replaced. | `string` | `null` | no |
| <a name="input_enable_auto_upgrade"></a> [enable\_auto\_upgrade](#input\_enable\_auto\_upgrade) | Let AME upgrade the cluster automatically towards its `update_channel`, inside the window of `maintenance_schedule_id`. Without a maintenance schedule there is no window for an upgrade to run in, so set both together. Leave null to send nothing, which the provider turns into `false`. Requires provider >= 0.6.0. | `bool` | `null` | no |
| <a name="input_enable_high_available_control_plane"></a> [enable\_high\_available\_control\_plane](#input\_enable\_high\_available\_control\_plane) | Run the Kubernetes control plane in high-availability mode, removing the single points of failure in `kube-apiserver` and `etcd`. AME picks the concrete model - Single-Zone HA or Multi-Zone HA - from the capabilities of the AME cluster pool the control plane lands in; Multi-Zone HA is only available in multi-zone pools. | `bool` | `false` | no |
| <a name="input_enable_multi_availability_zones"></a> [enable\_multi\_availability\_zones](#input\_enable\_multi\_availability\_zones) | Spread the cluster and its node pools over every availability zone in `region`. This also drives node pool fan-out: with this enabled the module creates one node pool per availability zone, so a pool with `node_count = 2` in a three-zone region provisions six nodes. Cannot be changed after the cluster is created, and may increase cost (for example when combined with a NAT gateway). | `bool` | `true` | no |
| <a name="input_enable_network_encryption"></a> [enable\_network\_encryption](#input\_enable\_network\_encryption) | Enable encryption of pod-to-pod traffic at the cluster network layer. This is a CNI feature that **only Calico implements**, and it has a measurable performance impact. It has no effect on a Cilium cluster, and because an unset `cni` does not reliably resolve to Calico, leaving this at its default of `true` is not by itself enough to get encrypted traffic: set `cni = "calico"` explicitly as well. The default is `true` to match the provider's own default and to avoid silently turning encryption off for existing clusters. | `bool` | `true` | no |
| <a name="input_enable_private_cluster"></a> [enable\_private\_cluster](#input\_enable\_private\_cluster) | Provision the cluster without public IP addresses on its nodes, routing outbound traffic through a NAT gateway so nodes share a static egress IP. Availability and exact behaviour are cloud-provider specific, and it makes provisioning slower because extra cloud resources are created. Can only be set at creation time. | `bool` | `false` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Exact AME Kubernetes version to run, for example `v1.35.6-u-ame.4`. Leave this `null` (the default) to resolve the version from `update_channel_name` instead. Setting it pins the cluster: the version only changes when you change this value. | `string` | `null` | no |
| <a name="input_maintenance_schedule_id"></a> [maintenance\_schedule\_id](#input\_maintenance\_schedule\_id) | Identity of the AME maintenance schedule that defines when automatic upgrades may run. Maintenance schedules are managed organisation-wide; create one in the Console or with an `acloud_maintenance_schedule` resource and pass its `id` here. Leave null for no schedule. Requires provider >= 0.6.0. | `string` | `null` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of node pool name to per-pool overrides. Keys become the AME node pool names and are used for the Kubernetes node role label. Supported override keys are `node_size`, `node_count`, `labels`, `annotations`, `enable_auto_healing`, `enable_multi_availability_zones` and `availability_zone`; any key a pool omits falls back to the matching `default_*` variable. Unsupported keys are rejected at plan time rather than silently ignored. Set this to `{}` to create a cluster with no node pools. | `any` | <pre>{<br/>  "data": {},<br/>  "ingress": {},<br/>  "worker": {}<br/>}</pre> | no |
| <a name="input_pod_security_standards_profile"></a> [pod\_security\_standards\_profile](#input\_pod\_security\_standards\_profile) | Default Kubernetes Pod Security Standards profile enforced in the cluster: `privileged` (unrestricted), `baseline` (blocks known privilege escalations) or `restricted` (least privilege, and what AME recommends for all clusters). Namespaces can relax or tighten this individually with `pod-security.kubernetes.io/*` labels. Values are case-insensitive. **Leaving this null does not give you an AME-chosen default**: the provider substitutes its own default of `privileged`, the least restrictive profile, and sends that. AME would fall back to `baseline` if nothing were sent at all, but the provider never lets that happen. Set this explicitly - `restricted` unless you know you need otherwise. | `string` | `null` | no |
| <a name="input_update_channel"></a> [update\_channel](#input\_update\_channel) | Update channel the cluster follows inside AME, for example `regular`. This is different from `update_channel_name`, which only resolves a version when Terraform plans: setting this records the channel on the cluster so AME itself knows what to upgrade towards, which is what `enable_auto_upgrade` acts on. Set it to the same value as `update_channel_name` unless you deliberately want them to differ. Leave null to leave the cluster's channel unset. | `string` | `null` | no |
| <a name="input_update_channel_name"></a> [update\_channel\_name](#input\_update\_channel\_name) | Name of the AME update channel used to resolve the Kubernetes version when `kubernetes_version` is null. Rolling channels (`stable`, `regular`, `preview`) follow a Kubernetes minor series that AME advances over time; pinned channels (`v1.34`, `v1.35`, ...) stay on one minor series and only receive patch releases. The default is `regular`, the channel AME recommends for production workloads, so a cluster gets a supported version without configuring anything. Because the channel resolves to a concrete version at plan time, a channel that has advanced shows up as a version diff on the next plan. | `string` | `"regular"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster"></a> [cluster](#output\_cluster) | The created AME cluster. `id` is the cluster UUID used by the API and the Console; `slug` is the identifier that node pools, `acloud` commands and the `acloud_nodepool` resource address the cluster by; `version` is the AME Kubernetes version that was actually provisioned, which is the value to read when the version came from an update channel; `status` is the cluster's lifecycle state as AME last reported it. |
<!-- END_TF_DOCS -->
