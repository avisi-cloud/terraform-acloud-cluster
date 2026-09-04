# ---------------------------------------------------------------------------
# Placement
#
# Where the cluster is created. Everything in this block refers to objects that
# must already exist in Avisi Cloud: the module looks them up, it does not
# create them.
# ---------------------------------------------------------------------------

variable "organisation_slug" {
  description = "Slug of the Avisi Cloud organisation that owns the environment and the cluster. This is the short identifier used in Console URLs and API paths, not the display name. Run `acloud config get-organisations` to list the slugs you have access to."
  type        = string
  nullable    = false
}

variable "environment_slug" {
  description = "Slug of the AME environment the cluster is created in. An environment groups clusters inside an organisation (for example `production` or `staging`) and is the boundary for cluster access. The environment must already exist; create it in the Console, with `acloud environments create`, or with an `acloud_environment` resource and pass its `slug` here."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Display name of the cluster in the Avisi Cloud Console. AME derives the cluster slug from this name, and the slug is what node pools and `acloud` commands address. Changing the name after creation is not handled by this module and forces a new cluster."
  type        = string
}

variable "cloud_provider" {
  description = "Slug of the AME cloud provider the cluster is provisioned on. Must match the cloud provider of the cloud account named in `cloud_account_name`, and the region must be offered by that provider. Common slugs are `aws`, `azure`, `hetzner`, `cyso-cloud-ams2`, `leafcloud`, `openstack` and `vsphere`; the exact set depends on your organisation. Run `acloud cloud-providers get` to list them."
  type        = string
}

variable "cloud_account_name" {
  description = "Display name of the AME cloud account used to provision the cluster, exactly as shown on the Cloud Accounts page in the Console (for example `Cyso Cloud AMS2`). Only cloud accounts that are enabled and have primary cloud credentials can be used for new clusters."
  type        = string
}

variable "region" {
  description = "Slug of the cloud provider region the cluster is provisioned in, for example `eu-west-1` (AWS), `fsn1` (Hetzner) or `ams2` (Cyso Cloud AMS2). The region also determines which availability zones node pools can be spread over. Can only be set at creation time."
  type        = string
}

# ---------------------------------------------------------------------------
# Kubernetes version
#
# Exactly one of the two paths below decides the version AME provisions:
# a pinned version, or a version resolved from an update channel at plan time.
# ---------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Exact AME Kubernetes version to run, for example `v1.35.6-u-ame.4`. Leave this `null` (the default) to resolve the version from `update_channel_name` instead. Setting it pins the cluster: the version only changes when you change this value."
  type        = string
  default     = null
}

variable "update_channel_name" {
  description = "Name of the AME update channel used to resolve the Kubernetes version when `kubernetes_version` is null. Channels are either rolling (`stable`, `regular`, `preview`) or pinned to a Kubernetes minor series (`v1.34`, `v1.35`, ...). AME recommends `regular` for production. Note: the module default `v1.28` is an end-of-life series - set this explicitly for new clusters."
  type        = string
  default     = "v1.28"
}

# ---------------------------------------------------------------------------
# Cluster options
#
# These map onto the advanced options of the AME create-cluster form. Support
# differs per cloud provider, and several of them cannot be changed later.
# ---------------------------------------------------------------------------

variable "enable_multi_availability_zones" {
  description = "Spread the cluster and its node pools over every availability zone in `region`. This also drives node pool fan-out: with this enabled the module creates one node pool per availability zone, so a pool with `node_count = 2` in a three-zone region provisions six nodes. Cannot be changed after the cluster is created, and may increase cost (for example when combined with a NAT gateway)."
  type        = bool
  default     = true
}

variable "enable_high_available_control_plane" {
  description = "Run the Kubernetes control plane in high-availability mode, removing the single points of failure in `kube-apiserver` and `etcd`. AME picks the concrete model - Single-Zone HA or Multi-Zone HA - from the capabilities of the AME cluster pool the control plane lands in; Multi-Zone HA is only available in multi-zone pools."
  type        = bool
  default     = false
}

variable "enable_private_cluster" {
  description = "Provision the cluster without public IP addresses on its nodes, routing outbound traffic through a NAT gateway so nodes share a static egress IP. Availability and exact behaviour are cloud-provider specific, and it makes provisioning slower because extra cloud resources are created. Can only be set at creation time."
  type        = bool
  default     = false
}

variable "enable_network_encryption" {
  description = "Enable encryption of pod-to-pod traffic at the cluster network layer. This is a CNI feature and is only supported by Calico; it has a measurable performance impact."
  type        = bool
  default     = true
}
