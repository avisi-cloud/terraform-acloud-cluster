
variable "ingress_node_count" {
  type        = number
  description = "Number of machines per ingress node pool"
  default     = 1
}

variable "ingress_node_size" {
  type        = string
  description = "Node Size for nodes in the ingress pool"
}

variable "node_pool_ingress_labels" {
  description = "Custom node labels for nodes per of the ingress node pool"
  default     = {}
}

variable "node_pool_ingress_annotations" {
  description = "Custom node annotations for nodes per of the ingress node pool"
  default     = {}
}

variable "node_pool_ingress_auto_healing" {
  description = "Enable node auto healing for the ingress node pool"
  default     = true
}

resource "acloud_nodepool" "ingress" {
  organisation          = var.organisation_slug
  environment           = var.environment_slug
  cluster               = acloud_cluster.cluster.slug
  name                  = "ingress"
  node_count            = var.ingress_node_count
  node_size             = var.ingress_node_size
  min_size              = var.ingress_node_count
  max_size              = var.ingress_node_count
  labels                = var.node_pool_ingress_labels
  annotations           = var.node_pool_ingress_annotations
  node_auto_replacement = var.node_pool_ingress_auto_healing
  for_each              = var.enable_multi_availability_zones ? toset(data.acloud_cloud_provider_availability_zones.zones.availability_zones) : [""]
  availability_zone     = each.key
}
