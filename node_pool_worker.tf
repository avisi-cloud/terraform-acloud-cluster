
variable "worker_node_count" {
  type        = number
  description = "Number of machines per worker node pool"
  default     = 1
}

variable "worker_node_size" {
  type        = string
  description = "Node Size for nodes in the worker pool"
}

variable "node_pool_worker_labels" {
  description = "Custom node labels for nodes per of the worker node pool"
  default     = {}
}

variable "node_pool_worker_annotations" {
  description = "Custom node annotations for nodes per of the worker node pool"
  default     = {}
}

variable "node_pool_worker_auto_healing" {
  description = "Enable node auto healing for the worker node pool"
  default     = true
}

module "worker_nodepool" {
  source                          = "avisi-cloud/nodepool/acloud"
  version                         = "0.0.3"
  name                            = "worker"
  organisation_slug               = var.organisation_slug
  environment_slug                = var.environment_slug
  cluster_slug                    = acloud_cluster.cluster.slug
  region                          = var.region
  cloud_provider                  = var.cloud_provider
  node_size                       = var.worker_node_size
  node_count                      = var.worker_node_count
  labels                          = var.node_pool_worker_labels
  annotations                     = var.node_pool_worker_annotations
  enable_auto_healing             = var.node_pool_worker_auto_healing
  enable_multi_availability_zones = var.enable_multi_availability_zones
}
