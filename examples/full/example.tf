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
  description = "Display name of the AWS cloud account in Avisi Cloud Console."
  type        = string
}

variable "cluster_name" {
  description = "Display name for the example cluster."
  type        = string
  default     = "example"
}

variable "region" {
  default     = "eu-central-1"
  description = "AWS region for the example cluster."
}

variable "cloud_provider" {
  default     = "aws"
  description = "Avisi Cloud provider slug for AWS."
}

module "cluster" {
  source             = "../../"
  organisation_slug  = var.organisation_slug
  environment_slug   = var.environment_slug
  cluster_name       = var.cluster_name
  cloud_account_name = var.cloud_account_name

  # AWS specific settings
  region         = var.region
  cloud_provider = var.cloud_provider

  enable_multi_availability_zones = true
  default_node_size               = "t3.medium"
  default_node_count              = 1

  node_pools = {
    database = {
      enable_multi_availability_zones = false
      availability_zone               = "eu-central-1b"
    }
    apps    = {}
    ingress = {}
  }
}
