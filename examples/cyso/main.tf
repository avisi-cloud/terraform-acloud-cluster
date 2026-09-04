# Cyso Cloud AMS2 (OpenStack) cluster with a private network layout: nodes get
# no public IP address and reach the internet through a NAT gateway. AMS2 is a
# multi-zone region, so this example also shows what node pool fan-out looks
# like in practice.

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
  description = "Display name of the Cyso Cloud AMS2 cloud account in the Avisi Cloud Console."
  type        = string
  default     = "Cyso Cloud AMS2"
}

variable "cluster_name" {
  description = "Display name for the cluster."
  type        = string
  default     = "cyso-ams2"
}

variable "cloud_provider" {
  description = "Cloud provider slug for Cyso Cloud AMS2."
  type        = string
  default     = "cyso-cloud-ams2"
}

variable "region" {
  description = "Cyso Cloud region for the cluster."
  type        = string
  default     = "ams2"
}

variable "single_zone_availability_zone" {
  description = "Availability zone the `data` node pool is pinned to. AMS2 offers `ams2-a`, `ams2-b` and `ams2-c`."
  type        = string
  default     = "ams2-a"
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

  # AMS2 exposes three availability zones. With multi-AZ on, each multi-zone
  # node pool below is created once per zone, so `system` provisions three
  # machines and `apps` six.
  enable_multi_availability_zones     = true
  enable_high_available_control_plane = true

  # Cilium's eBPF data plane, with Layer 7 load balancing and richer flow
  # observability. Network encryption is a Calico-only feature, so it is
  # switched off here rather than silently ignored.
  cni                       = "cilium"
  enable_network_encryption = false

  # No public IPs on the nodes; egress leaves through a NAT gateway with a
  # stable outbound address. Cannot be changed after creation.
  enable_private_cluster = true

  # Worth setting explicitly: leaving it unset gets you the provider's own
  # default of `privileged`, not a least-privilege one.
  pod_security_standards_profile = "restricted"

  addons = {
    certManager = {}
    nfs         = {}
  }

  default_node_size  = "s5.small"
  default_node_count = 1

  node_pools = {
    system = {
      labels = {
        "role" = "system"
      }
    }

    apps = {
      node_count = 2
      labels = {
        "role" = "apps"
      }
    }

    # Pinned to one zone: exactly two machines, both in `ams2-a`.
    data = {
      enable_multi_availability_zones = false
      availability_zone               = var.single_zone_availability_zone
      node_count                      = 2
      labels = {
        "role" = "data"
      }
    }
  }
}

output "cluster" {
  description = "Identity and provisioned AME version of the created cluster."
  value       = module.cluster.cluster
}
