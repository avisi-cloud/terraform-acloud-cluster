terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
      version = ">= 0.5.0"
    }
  }
}

variable "acloud_token" {
  description = "Avisi Cloud Personal Access Token."
  type        = string
  sensitive   = true
}

variable "acloud_api" {
  description = "Avisi Cloud API base URL."
  type        = string
}

provider "acloud" {
  token      = var.acloud_token
  acloud_api = var.acloud_api
}

variable "organisation_slug" {
  description = "Slug of the Avisi Cloud organisation that owns the example environment."
  type        = string
  nullable    = false
}

variable "environment_slug" {
  description = "Slug of the Avisi Cloud environment where the example cluster is created."
  type        = string
  nullable    = false
}

variable "cloud_account_name" {
  description = "Display name of the Hetzner cloud account in Avisi Cloud Console."
  type        = string
}

variable "cluster_name" {
  description = "Display name for the example cluster."
  type        = string
  default     = "example"
}

variable "region" {
  default     = "fsn1"
  description = "Hetzner region for the example cluster."
}

variable "cloud_provider" {
  default     = "hetzner"
  description = "Avisi Cloud provider slug for Hetzner."
}

module "cluster" {
  source             = "../../"
  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = var.cluster_name
  cloud_account_name = var.cloud_account_name

  region         = var.region
  cloud_provider = var.cloud_provider

  enable_multi_availability_zones = false
  default_node_size               = "cx33"
  default_node_count              = 1

  node_pools = {
    data          = {}
    app           = {}
    "custom-pool" = {}
  }
}
