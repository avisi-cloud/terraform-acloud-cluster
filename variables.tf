
variable "organisation_slug" {
  description = "Slug of the Avisi Cloud organisation that owns the environment and cluster."
  type        = string
  nullable    = false
}

variable "environment_slug" {
  description = "Slug of the Avisi Cloud environment where the cluster is created. An environment groups clusters inside an organisation."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  type        = string
  description = "Display name for the AME Kubernetes cluster."
}

variable "region" {
  type        = string
  description = "Cloud provider region slug where the cluster is provisioned. The region must be valid for the selected cloud provider and cloud account."
}

variable "update_channel_name" {
  type        = string
  description = "Name of the AME update channel used to resolve the Kubernetes version when kubernetes_version is null."
  default     = "v1.28"
}

variable "kubernetes_version" {
  description = "Explicit AME Kubernetes version to deploy. When null, the module resolves the version from update_channel_name."
  type        = string
  default     = null
}

variable "cloud_provider" {
  type        = string
  description = "Avisi Cloud provider slug used for provisioning the cluster. This must match the selected cloud account and region."
}

variable "cloud_account_name" {
  type        = string
  description = "Display name of an enabled Avisi Cloud cloud account for the selected cloud provider. The account must have primary credentials to create new clusters."
}

variable "enable_multi_availability_zones" {
  type        = bool
  default     = true
  description = "Whether the cluster and default node pools may use multiple availability zones. AME product docs note that this cannot be changed after cluster creation."
}

variable "enable_high_available_control_plane" {
  type        = bool
  default     = false
  description = "Whether to request a highly available Kubernetes control plane. AME determines the concrete HA model from platform and region capabilities."
}

variable "enable_private_cluster" {
  type        = bool
  default     = false
  description = "Whether to create a private cluster when supported by the cloud provider."
}

variable "enable_network_encryption" {
  type        = bool
  default     = true
  description = "Whether to enable network-layer encryption in the cluster CNI when supported."
}
