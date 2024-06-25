
variable "node_pools" {
  default = {
    ingress = {}
    worker  = {}
    data    = {}
  }
  type        = any
  description = "Definition of the Cluster node pools"
}

variable "default_node_size" {
  type        = string
  description = "Deafult Node Size for nodes"

}
variable "default_node_count" {
  type        = number
  description = "Default number of machines in a node pool"
  default     = 1
}

variable "default_node_labels" {
  description = "Default custom node labels for nodes within a node pool"
  default     = {}
}

variable "default_node_annotations" {
  description = "Default custom node annotations for nodes within a node pool"
  default     = {}
}

variable "default_node_pool_auto_healing" {
  description = "Default node auto healing setting"
  default     = true
}

variable "default_availablity_zone" {
  description = "The default availability zone for node pools"
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
