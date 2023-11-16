terraform {
  required_providers {
    acloud = {
      source  = "avisi-cloud/acloud"
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

  # AWS specific settings
  region         = "eu-central-1"
  cloud_provider = "aws"

  enable_multi_availability_zones = true
  ingress_node_size               = "t3.medium"
  ingress_node_count              = 1

  worker_node_size  = "t3.medium"
  worker_node_count = 1

  data_node_size  = "t3.medium"
  data_node_count = 1
}
