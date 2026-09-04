terraform {
  required_providers {
    acloud = {
      version = ">= 0.10.1"
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

# NOTE: this data source is not referenced anywhere in the root module. The
# node pool fan-out over availability zones happens inside the
# `avisi-cloud/nodepool/acloud` child module, which resolves the zones itself.
# It is kept for backwards compatibility; see "Known rough edges" in README.md.
data "acloud_cloud_provider_availability_zones" "zones" {
  organisation   = var.organisation_slug
  cloud_provider = var.cloud_provider
  region         = var.region
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
  description = "The created AME cluster: `id` is the cluster UUID used by the API and the Console, `version` is the AME Kubernetes version that was actually provisioned (useful when the version came from an update channel)."

  value = {
    id      = acloud_cluster.cluster.id
    version = acloud_cluster.cluster.version
  }
}
