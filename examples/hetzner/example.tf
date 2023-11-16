terraform {
  required_providers {
    acloud = {
      source = "avisi-cloud/acloud"
    }
  }
}

variable "acloud_token" {
  sensitive = true
}
variable "acloud_api" {
}

provider "acloud" {
  token      = var.acloud_token
  acloud_api = var.acloud_api
}

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

variable "cloud_account_name" {
  description = "name of the cloud account within the Avisi Cloud Console used for provisioning the cluster. Required."
}

variable "cluster_name" {
  default = "example"
}

variable "region" {
  default     = "fsn1"
  description = "Hetzner region"
}

variable "cloud_provider" {
  default     = "hetzner"
  description = "Slug of the Hetzner Cloud Provider"
}

module "cluster" {
  source             = "../../"
  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = "provider-example"
  cloud_account_name = var.cloud_account_name

  region         = var.region
  cloud_provider = var.cloud_provider

  enable_multi_availability_zones = true
  default_node_size               = "t3.medium"
  default_node_count              = 1

  node_pools = {
    data          = {}
    app           = {}
    "custom-pool" = {}
  }
}
