
variable "organisation_slug" {
  description = "A unique identifier for the organisation. This is used to distinguish resources across different organisations. Required."
  type        = string
  nullable    = false
}

variable "environment_slug" {
  description = "A unique identifier for the environment within the organisation. Required."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "region" {
  type        = string
  description = "Cloud Region"
}

variable "update_channel_name" {
  type        = string
  description = "Name of the Update Channel used for discovering the Kubernetes version"
  default     = "v1.28"
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version used for deploying the cluster"
  type        = string
  default     = null
}

variable "cloud_provider" {
  type        = string
  description = "Slug of the cloud provider used for provisioning the cluster"
}

variable "cloud_account_name" {
  type        = string
  description = "Cloud account name"
}

variable "enable_multi_availability_zones" {
  type        = bool
  default     = true
  description = "Enable multi availability zones for the cluster"
}

variable "enable_high_available_control_plane" {
  type        = bool
  default     = false
  description = "Enable HA control plane"
}

variable "enable_private_cluster" {
  type        = bool
  default     = false
  description = "Enable Private networking Cluster Mode"
}

variable "enable_network_encryption" {
  type        = bool
  default     = true
  description = "Enable Network Encryption at the node level (if supported by the CNI)"
}
