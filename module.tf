terraform {
  required_providers {
    acloud = {
      version = ">= 0.5.0"
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
  version                             = var.kubernetes_version != null ? var.kubernetes_version : data.acloud_update_channel.channel[0].version
  region                              = var.region
  enable_multi_availability_zones     = var.enable_multi_availability_zones
  enable_high_available_control_plane = var.enable_high_available_control_plane
  enable_private_cluster              = var.enable_private_cluster
  enable_network_encryption           = var.enable_network_encryption
}

output "cluster" {
  description = "The created AME cluster: `id` is the cluster UUID used by the API and the Console, `version` is the AME Kubernetes version that was actually provisioned (useful when the version came from an update channel)."

  value = {
    id      = acloud_cluster.cluster.id
    version = acloud_cluster.cluster.version
  }
}
