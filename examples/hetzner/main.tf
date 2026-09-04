# Hetzner cluster in a single region. Hetzner regions in AME are single-zone,
# so multi-AZ is turned off and every node pool becomes exactly one AME node
# pool - which makes the node counts below the literal number of machines.

terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
      version = ">= 0.12.0"
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
  description = "Slug of the Avisi Cloud organisation that owns the environment."
  type        = string
  nullable    = false
}

variable "environment_slug" {
  description = "Slug of an existing AME environment to create the cluster in."
  type        = string
  nullable    = false
}

variable "cloud_account_name" {
  description = "Display name of the Hetzner cloud account in the Avisi Cloud Console."
  type        = string
}

variable "cluster_name" {
  description = "Display name for the cluster."
  type        = string
  default     = "hetzner"
}

variable "cloud_provider" {
  description = "Cloud provider slug for Hetzner."
  type        = string
  default     = "hetzner"
}

variable "region" {
  description = "Hetzner region for the cluster, for example `fsn1` (Falkenstein) or `nbg1` (Nuremberg)."
  type        = string
  default     = "fsn1"
}

module "cluster" {
  source = "../../"

  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = var.cluster_name
  cloud_provider     = var.cloud_provider
  cloud_account_name = var.cloud_account_name
  region             = var.region

  # Kubernetes version comes from the module default: the "regular" channel.

  # Single zone: one AME node pool per entry in `node_pools`.
  enable_multi_availability_zones = false

  default_node_size  = "cx33"
  default_node_count = 1

  # Labels applied to every pool that does not override them. Use your own
  # label keys here: the `avisi.cloud` namespaces are used by the platform
  # itself, so do not invent keys under them.
  default_node_labels = {
    "managed-by" = "terraform"
  }

  node_pools = {
    system = {}

    apps = {
      node_count = 2
    }

    # Pool names may contain hyphens; quote them so they stay valid map keys.
    "batch-jobs" = {
      node_size  = "cx43"
      node_count = 1
      labels = {
        "role" = "batch"
      }
    }
  }
}

output "cluster" {
  description = "Identity and provisioned AME version of the created cluster."
  value       = module.cluster.cluster
}
