
variable "data_node_count" {
  type        = number
  description = "Number of machines per data node pool"
  default     = 1
}

variable "data_node_size" {
  type        = string
  description = "Node Size for nodes in the data pool"
}

variable "node_pool_data_labels" {
  description = "Custom node labels for nodes per of the data node pool"
  default     = {}
}

variable "node_pool_data_annotations" {
  description = "Custom node annotations for nodes per of the data node pool"
  default     = {}
}

variable "node_pool_data_auto_healing" {
  description = "Enable node auto healing for the data node pool"
  default     = true
}

resource "acloud_nodepool" "data" {
  organisation          = var.organisation_slug
  environment           = var.environment_slug
  cluster               = acloud_cluster.cluster.slug
  name                  = "data"
  node_size             = var.data_node_size
  node_count            = var.data_node_count
  min_size              = var.data_node_count
  max_size              = var.data_node_count
  labels                = var.node_pool_data_labels
  annotations           = var.node_pool_data_annotations
  node_auto_replacement = var.node_pool_data_auto_healing
  for_each              = var.enable_multi_availability_zones ? toset(data.acloud_cloud_provider_availability_zones.zones.availability_zones) : [""]
  availability_zone     = each.key
}
