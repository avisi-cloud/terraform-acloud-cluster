# ---------------------------------------------------------------------------
# Node pools
#
# `node_pools` is a map of pool name to per-pool overrides. Every key is
# optional: whatever a pool does not set falls back to the matching
# `default_*` variable below, which keeps a homogeneous cluster to a single
# `node_pools = { worker = {} }` entry.
#
# The map is typed `any` on purpose, so that different pools can override
# different subsets of keys without having to spell out a full object type.
# A typed `map(object({...optional()}))` would not be an improvement here:
# Terraform's type conversion silently *drops* object attributes that are not
# part of the declared type, so a misspelled key would still disappear without
# an error. The validation below is what actually catches typos, and it has to
# list the supported keys inline because a validation condition cannot read a
# local value.
# ---------------------------------------------------------------------------

variable "node_pools" {
  description = "Map of node pool name to per-pool overrides. Keys become the AME node pool names and are used for the Kubernetes node role label. Supported override keys are `node_size`, `node_count`, `labels`, `annotations`, `enable_auto_healing`, `enable_multi_availability_zones`, `availability_zone`, `enable_auto_scaling`, `min_size`, `max_size`, `taints`, `upgrade_strategy` and `security_updates_on_join`; any key a pool omits falls back to the matching `default_*` variable. Unsupported keys are rejected at plan time rather than silently ignored. Set this to `{}` to create a cluster with no node pools."
  type        = any
  default = {
    ingress = {}
    worker  = {}
    data    = {}
  }

  validation {
    condition = alltrue([
      for name, pool in var.node_pools : length(setsubtract(keys(pool), [
        "node_size",
        "node_count",
        "labels",
        "annotations",
        "enable_auto_healing",
        "enable_multi_availability_zones",
        "availability_zone",
        "enable_auto_scaling",
        "min_size",
        "max_size",
        "taints",
        "upgrade_strategy",
        "security_updates_on_join",
      ])) == 0
    ])
    error_message = "Each node_pools entry may only use the keys node_size, node_count, labels, annotations, enable_auto_healing, enable_multi_availability_zones, availability_zone, enable_auto_scaling, min_size, max_size, taints, upgrade_strategy and security_updates_on_join."
  }
}

variable "default_node_size" {
  description = "Cloud provider machine type used by node pools that do not set `node_size`, for example `t3.medium` (AWS), `cx33` (Hetzner) or `s5.small` (Cyso Cloud AMS2). The type must be offered in `region` for the selected cloud account. Run `acloud cloud-providers get` to list the available types."
  type        = string
}

variable "default_node_count" {
  description = "Number of nodes per node pool for pools that do not set `node_count`. With `enable_multi_availability_zones` on, this is the count *per availability zone*, so the pool provisions this many nodes in every zone of the region."
  type        = number
  default     = 1
}

variable "default_node_labels" {
  description = "Kubernetes node labels applied by node pools that do not set `labels`. Labels are set on every node in the pool and can be used for scheduling with `nodeSelector` or node affinity."
  type        = map(string)
  default     = {}
}

variable "default_node_annotations" {
  description = "Kubernetes node annotations applied by node pools that do not set `annotations`. Annotations are set on every node in the pool and are typically consumed by automation rather than by the scheduler."
  type        = map(string)
  default     = {}
}

variable "default_node_pool_auto_healing" {
  description = "Auto-healing setting for node pools that do not set `enable_auto_healing`. When enabled, AME automatically replaces nodes it detects as unhealthy. Maps to `node_auto_replacement` on the underlying `acloud_nodepool` resource."
  type        = bool
  default     = true
}

variable "default_availability_zone" {
  description = "Availability zone used by single-zone node pools that do not set `availability_zone`, for example `eu-west-1a`. Only has an effect on pools where multi-AZ is off; multi-zone pools always fan out over every zone in the region. Leave null to let AME place the pool. This is the correctly spelled replacement for `default_availablity_zone`; when both are set, this one wins."
  type        = string
  default     = null
}

variable "default_availablity_zone" {
  description = "DEPRECATED, and misspelled - use `default_availability_zone` instead, which does the same thing. Kept so that existing configurations keep working; it is only consulted when `default_availability_zone` is null, and it will be removed in a future major release."
  type        = string
  default     = ""
}

variable "default_node_pool_auto_scaling" {
  description = "Autoscaling setting for node pools that do not set `enable_auto_scaling`. When enabled, AME's cluster autoscaler sizes the pool on utilisation between `min_size` and `max_size` instead of holding it at `node_count`. Note that with multi-AZ on, those bounds apply to each zone's pool, so the cluster-wide totals are multiplied by the number of zones."
  type        = bool
  default     = false
}

variable "default_node_pool_min_size" {
  description = "Lower autoscaler bound for node pools that do not set `min_size`. Only used where autoscaling is on. Leave null to fall back to the pool's `node_count`."
  type        = number
  default     = null
}

variable "default_node_pool_max_size" {
  description = "Upper autoscaler bound for node pools that do not set `max_size`. Only used where autoscaling is on. Leave null to fall back to the pool's `node_count`."
  type        = number
  default     = null
}

variable "default_node_pool_taints" {
  description = "Kubernetes taints applied to node pools that do not set `taints`, so that only pods with a matching toleration are scheduled onto them. Each entry takes `key`, `value` and an `effect` of `NoSchedule`, `PreferNoSchedule` or `NoExecute`."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "default_node_pool_upgrade_strategy" {
  description = "Upgrade strategy for node pools that do not set `upgrade_strategy`: `REPLACE`, `REPLACE_MINOR_INPLACE_PATCH`, `REPLACE_MINOR_INPLACE_PATCH_WITHOUT_DRAIN`, `INPLACE` or `INPLACE_WITHOUT_DRAIN`. Leave null to use the node pool module's default, which matches AME's default for normal clusters. On Bring Your Own Node clusters AME defaults to `INPLACE` instead, so set that explicitly there."
  type        = string
  default     = null
}

variable "default_node_pool_security_updates_on_join" {
  description = "Security updates on join for node pools that do not set `security_updates_on_join`: `OFF`, `INSTALL` or `INSTALL_AND_REBOOT`. AME recommends `INSTALL_AND_REBOOT` so that nodes join fully patched, which also stops the daily recycle loop you get from combining autoscaling with automatic node reboots. Beta feature: its values and defaults can still change, and it needs an AME release that supports it. Leave null for the AME default of `OFF`."
  type        = string
  default     = null
}

locals {
  # The correctly spelled input wins; the misspelled one remains the fallback
  # so that callers written against earlier versions keep working unchanged.
  default_availability_zone = var.default_availability_zone != null ? var.default_availability_zone : var.default_availablity_zone
}

# One `avisi-cloud/nodepool/acloud` module instance per entry in `node_pools`.
#
# That child module fans out internally: with multi-AZ enabled it creates one
# `acloud_nodepool` per availability zone in the region, otherwise a single
# pool in `availability_zone`.
#
# Resulting state addresses look like:
#   module.nodepool["worker"].acloud_nodepool.pool["eu-west-1a"]
module "nodepool" {
  source            = "avisi-cloud/nodepool/acloud"
  version           = "0.2.0"
  organisation_slug = var.organisation_slug
  environment_slug  = var.environment_slug
  cluster_slug      = acloud_cluster.cluster.slug
  region            = var.region
  cloud_provider    = var.cloud_provider

  for_each = { for k, v in var.node_pools : k => v }

  name                            = each.key
  node_size                       = try(each.value.node_size, var.default_node_size, "")
  node_count                      = try(each.value.node_count, var.default_node_count, 0)
  labels                          = try(each.value.labels, var.default_node_labels, {})
  annotations                     = try(each.value.annotations, var.default_node_annotations, {})
  enable_auto_healing             = try(each.value.enable_auto_healing, var.default_node_pool_auto_healing, false)
  enable_multi_availability_zones = try(each.value.enable_multi_availability_zones, var.enable_multi_availability_zones, true)
  availability_zone               = try(each.value.availability_zone, local.default_availability_zone, "")

  # Reachable from 0.2.0 of the child module onwards.
  #
  # `upgrade_strategy` is declared `nullable = false` there with a default, so a
  # null passed here resolves to that default rather than to an empty value -
  # which matters, because the provider rejects an empty upgrade strategy when
  # it creates a pool.
  enable_auto_scaling      = try(each.value.enable_auto_scaling, var.default_node_pool_auto_scaling, false)
  min_size                 = try(each.value.min_size, var.default_node_pool_min_size, null)
  max_size                 = try(each.value.max_size, var.default_node_pool_max_size, null)
  taints                   = try(each.value.taints, var.default_node_pool_taints, [])
  upgrade_strategy         = try(each.value.upgrade_strategy, var.default_node_pool_upgrade_strategy, null)
  security_updates_on_join = try(each.value.security_updates_on_join, var.default_node_pool_security_updates_on_join, null)
}
