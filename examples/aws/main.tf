# Production-shaped AWS cluster: a highly available control plane, node pools
# spread over every availability zone in the region, and one pool pinned to a
# single zone for workloads that should not be scheduled cross-zone.

terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
      version = ">= 0.10.1"
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
  description = "Display name of the AWS cloud account in the Avisi Cloud Console."
  type        = string
}

variable "cluster_name" {
  description = "Display name for the cluster."
  type        = string
  default     = "aws-production"
}

variable "cloud_provider" {
  description = "Cloud provider slug for AWS."
  type        = string
  default     = "aws"
}

variable "region" {
  description = "AWS region for the cluster."
  type        = string
  default     = "eu-west-1"
}

variable "single_zone_availability_zone" {
  description = "Availability zone the `data` node pool is pinned to. Must be a zone within `region`."
  type        = string
  default     = "eu-west-1a"
}

# Automatic upgrades need a window to run in. Maintenance schedules are managed
# organisation-wide, so one schedule is typically shared by many clusters.
resource "acloud_maintenance_schedule" "nightly" {
  name         = "${var.cluster_name}-nightly"
  organisation = var.organisation_slug

  windows {
    day        = "SUNDAY"
    start_time = "02:00"
    duration   = 180 # minutes
  }
}

module "cluster" {
  source = "../../"

  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = var.cluster_name
  cloud_provider     = var.cloud_provider
  cloud_account_name = var.cloud_account_name
  region             = var.region

  # Kubernetes version comes from the module default: the "regular" update
  # channel, which is what AME recommends for production workloads.

  # Multi-AZ cannot be changed after the cluster is created, so decide it here.
  # It also fans every multi-zone node pool out across all zones in the region.
  enable_multi_availability_zones     = true
  enable_high_available_control_plane = true
  enable_network_encryption           = true

  # `cni` is left unset, so the cluster uses the AME default, Calico. That is
  # what makes enable_network_encryption above valid - it is a Calico-only
  # feature. See examples/cyso for the Cilium alternative.
  #
  # Least-privilege pod defaults; namespaces can relax the profile individually
  # with pod-security.kubernetes.io/* labels.
  pod_security_standards_profile = "restricted"

  description       = "Production order processing"
  delete_protection = true

  # Record the channel on the cluster so AME knows what to upgrade towards,
  # then let it act on that inside the maintenance window above.
  update_channel          = "regular"
  enable_auto_upgrade     = true
  maintenance_schedule_id = acloud_maintenance_schedule.nightly.id

  # Managed add-ons: AME installs and updates these, so do not also deploy them
  # yourself.
  #
  # `ingressController` deliberately sets no custom_values. The ingress
  # implementations available today are all being superseded, so pinning
  # custom_values.type would pin the cluster to something on its way out.
  # Unset means "follow AME's current default".
  addons = {
    certManager       = {}
    ingressController = {}
    monitoring        = {}
    logging           = {}
  }

  default_node_size  = "t3.medium"
  default_node_count = 1

  node_pools = {
    # Spread over every zone in the region: 1 node per zone.
    system = {
      labels = {
        "role" = "system"
      }
    }

    # Two nodes per zone for application workloads.
    apps = {
      node_count = 2
      node_size  = "t3.large"
      labels = {
        "role" = "apps"
      }
    }

    # Stateful workloads that should stay in one zone, close to their volumes.
    # Turning multi-AZ off for this pool makes `availability_zone` meaningful.
    data = {
      enable_multi_availability_zones = false
      availability_zone               = var.single_zone_availability_zone
      node_size                       = "t3.large"
      node_count                      = 3
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
