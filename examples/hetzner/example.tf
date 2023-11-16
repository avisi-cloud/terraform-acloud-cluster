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
}

module "cluster" {
  source             = "../../"
  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = "provider-example"
  cloud_account_name = var.cloud_account_name

  region         = "fsn1"
  cloud_provider = "hetzner"

  ingress_node_size  = "cx21"
  ingress_node_count = 1

  worker_node_size  = "cx21"
  worker_node_count = 1

  data_node_size  = "cx21"
  data_node_count = 1
}
