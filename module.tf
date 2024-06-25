terraform {
  required_providers {
    acloud = {
      version = ">= 0.5.0"
      source  = "avisi-cloud/acloud"
    }
  }
}

data "acloud_cloud_account" "account" {
  organisation   = var.organisation_slug
  display_name   = var.cloud_account_name
  cloud_provider = var.cloud_provider
}

data "acloud_cloud_provider_availability_zones" "zones" {
  organisation   = var.organisation_slug
  cloud_provider = var.cloud_provider
  region         = var.region
}

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
  value = {
    id      = acloud_cluster.cluster.id
    version = acloud_cluster.cluster.version
  }
}
