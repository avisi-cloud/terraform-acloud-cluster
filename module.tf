terraform {
  # `optional()` object attributes in the `addons` variable need Terraform 1.3.
  required_version = ">= 1.3.0"

  required_providers {
    acloud = {
      version = ">= 0.12.0"
      source  = "avisi-cloud/acloud"
    }
  }
}

# Resolve the cloud account by display name. AME identifies cloud accounts by
# UUID, so the lookup turns the human-readable name from the Console into the
# identity the cluster resource needs.
data "acloud_cloud_account" "account" {
  organisation   = var.organisation_slug
  display_name   = var.cloud_account_name
  cloud_provider = var.cloud_provider
}

# Only queried when `kubernetes_version` is null: the channel resolves to the
# AME version that is current at plan time. Because the resolved value is
# written to state as a concrete version, a later channel bump shows up as a
# version diff on the next plan rather than as an automatic upgrade.
data "acloud_update_channel" "channel" {
  count        = var.kubernetes_version == null ? 1 : 0
  organisation = var.organisation_slug
  name         = var.update_channel_name
}

resource "acloud_cluster" "cluster" {
  cloud_account_identity              = data.acloud_cloud_account.account.identity
  organisation                        = var.organisation_slug
  environment                         = var.environment_slug
  name                                = var.cluster_name
  description                         = var.description
  version                             = var.kubernetes_version != null ? var.kubernetes_version : data.acloud_update_channel.channel[0].version
  region                              = var.region
  enable_multi_availability_zones     = var.enable_multi_availability_zones
  enable_high_available_control_plane = var.enable_high_available_control_plane
  enable_private_cluster              = var.enable_private_cluster
  enable_network_encryption           = var.enable_network_encryption

  cni                            = var.cni
  pod_security_standards_profile = var.pod_security_standards_profile
  delete_protection              = var.delete_protection
  cluster_state_wait_seconds     = var.cluster_state_wait_seconds

  # `version` above is the target for this apply; `update_channel` is what AME
  # follows on its own, and what auto-upgrade acts on.
  update_channel          = var.update_channel
  enable_auto_upgrade     = var.enable_auto_upgrade
  maintenance_schedule_id = var.maintenance_schedule_id

  dynamic "addons" {
    for_each = var.addons
    content {
      name          = addons.key
      enabled       = addons.value.enabled
      custom_values = addons.value.custom_values
    }
  }
}

output "cluster" {
  description = "The created AME cluster. `id` is the cluster UUID used by the API and the Console; `slug` is the identifier that node pools, `acloud` commands and the `acloud_nodepool` resource address the cluster by; `version` is the AME Kubernetes version that was actually provisioned, which is the value to read when the version came from an update channel; `status` is the cluster's lifecycle state as AME last reported it."

  value = {
    id      = acloud_cluster.cluster.id
    slug    = acloud_cluster.cluster.slug
    version = acloud_cluster.cluster.version
    status  = acloud_cluster.cluster.status
  }
}
