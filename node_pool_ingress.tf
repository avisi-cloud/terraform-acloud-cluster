
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

module "ingress_nodepool" {
  source                          = "avisi-cloud/nodepool/acloud"
  version                         = "0.0.3"
  name                            = "ingress"
  organisation_slug               = var.organisation_slug
  environment_slug                = var.environment_slug
  cluster_slug                    = acloud_cluster.cluster.slug
  region                          = var.region
  cloud_provider                  = var.cloud_provider
  node_size                       = var.ingress_node_size
  node_count                      = var.ingress_node_count
  labels                          = var.node_pool_ingress_labels
  annotations                     = var.node_pool_ingress_annotations
  enable_auto_healing             = var.node_pool_ingress_auto_healing
  enable_multi_availability_zones = var.enable_multi_availability_zones
}
