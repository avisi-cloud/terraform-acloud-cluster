
variable "node_pools" {
  default = {
    ingress = {}
    worker  = {}
    data    = {}
  }
  type        = any
  description = "Map of node pool names to per-pool overrides. Supported override keys are node_size, node_count, labels, annotations, enable_auto_healing, enable_multi_availability_zones, and availability_zone."
}

variable "default_node_size" {
  type        = string
  description = "Default cloud provider node type or instance size for node pools that do not set node_size."
}

variable "default_node_count" {
  type        = number
  description = "Default number of machines in node pools that do not set node_count."
  default     = 1
}

variable "default_node_labels" {
  description = "Default Kubernetes labels applied to nodes in node pools that do not set labels."
  type        = map(string)
  default     = {}
}

variable "default_node_annotations" {
  description = "Default Kubernetes annotations applied to nodes in node pools that do not set annotations."
  type        = map(string)
  default     = {}
}

variable "default_node_pool_auto_healing" {
  description = "Default auto-healing setting for node pools that do not set enable_auto_healing."
  type        = bool
  default     = true
}

variable "default_availablity_zone" {
  description = "Default availability zone for node pools that do not set availability_zone. The variable name is misspelled for compatibility."
  type        = string
  default     = ""
}

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
