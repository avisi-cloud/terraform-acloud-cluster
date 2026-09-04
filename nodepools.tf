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
# ---------------------------------------------------------------------------

variable "node_pools" {
  description = "Map of node pool name to per-pool overrides. Keys become the AME node pool names and are used for the Kubernetes node role label. Supported override keys are `node_size`, `node_count`, `labels`, `annotations`, `enable_auto_healing`, `enable_multi_availability_zones` and `availability_zone`; any key a pool omits falls back to the matching `default_*` variable. Set this to `{}` to create a cluster with no node pools."
  type        = any
  default = {
    ingress = {}
    worker  = {}
    data    = {}
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

variable "default_availablity_zone" {
  description = "Availability zone used by single-zone node pools that do not set `availability_zone`, for example `eu-west-1a`. Only has an effect on pools where multi-AZ is off; multi-zone pools always fan out over every zone in the region. The empty default lets AME place the pool. Note: the misspelling is preserved for backwards compatibility."
  type        = string
  default     = ""
}

# One `avisi-cloud/nodepool/acloud` module instance per entry in `node_pools`.
#
# That child module fans out internally: with multi-AZ enabled it creates one
# `acloud_nodepool` per availability zone in the region, otherwise a single
# pool in `availability_zone`. It also pins `min_size` and `max_size` to
# `node_count`, so pools created through this module do not autoscale.
#
# Resulting state addresses look like:
#   module.nodepool["worker"].acloud_nodepool.pool["eu-west-1a"]
module "nodepool" {
  source            = "avisi-cloud/nodepool/acloud"
  version           = "0.1.0"
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
  availability_zone               = try(each.value.availability_zone, var.default_availablity_zone, "")
}
