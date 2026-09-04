# Smallest working configuration: one cluster, one node pool, everything else
# left at the module defaults. Provider-neutral, so every placement value is a
# variable without a default - supply them through a .tfvars file or TF_VAR_*.

terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
      version = ">= 0.10.0"
    }
  }
}

variable "acloud_token" {
  description = "Avisi Cloud Personal Access Token. Create one under API Access in the Console."
  type        = string
  sensitive   = true
}

variable "acloud_api" {
  description = "Avisi Cloud API base URL. Leave null to use the public API at https://api.avisi.cloud."
  type        = string
  default     = null
}

provider "acloud" {
  token      = var.acloud_token
  acloud_api = var.acloud_api
}

variable "organisation_slug" {
  description = "Slug of your Avisi Cloud organisation."
  type        = string
  nullable    = false
}

variable "environment_slug" {
  description = "Slug of an existing AME environment to create the cluster in."
  type        = string
  nullable    = false
}

variable "cloud_account_name" {
  description = "Display name of an enabled cloud account with primary credentials."
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider slug the cloud account belongs to, for example `aws` or `hetzner`."
  type        = string
}

variable "region" {
  description = "Cloud provider region slug to provision the cluster in."
  type        = string
}

variable "node_size" {
  description = "Machine type for the single worker node pool."
  type        = string
}

variable "cluster_name" {
  description = "Display name for the cluster."
  type        = string
  default     = "minimal"
}

module "cluster" {
  source = "../../"

  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = var.cluster_name
  cloud_provider     = var.cloud_provider
  cloud_account_name = var.cloud_account_name
  region             = var.region

  # No update_channel_name here on purpose: the module default, "regular",
  # is the channel AME recommends for production workloads.

  # Single zone keeps this example to exactly one node pool with one node.
  enable_multi_availability_zones = false

  default_node_size  = var.node_size
  default_node_count = 1

  node_pools = {
    worker = {}
  }
}

output "cluster" {
  description = "Identity and provisioned AME version of the created cluster."
  value       = module.cluster.cluster
}
