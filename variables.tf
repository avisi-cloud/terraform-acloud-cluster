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
  description = "Name of the AME update channel used to resolve the Kubernetes version when `kubernetes_version` is null. Rolling channels (`stable`, `regular`, `preview`) follow a Kubernetes minor series that AME advances over time; pinned channels (`v1.34`, `v1.35`, ...) stay on one minor series and only receive patch releases. The default is `regular`, the channel AME recommends for production workloads, so a cluster gets a supported version without configuring anything. Because the channel resolves to a concrete version at plan time, a channel that has advanced shows up as a version diff on the next plan."
  type        = string
  default     = "regular"
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

# ---------------------------------------------------------------------------
# Cluster metadata and policy
#
# All optional and defaulting to null, which leaves the AME default in place
# and keeps existing callers' plans clean.
# ---------------------------------------------------------------------------

variable "description" {
  description = "Human-readable description of the cluster, shown in the Avisi Cloud Console. Useful for telling Avisi Cloud support what the cluster is for."
  type        = string
  default     = null
}

variable "cni" {
  description = "Container Network Interface plugin for the cluster: `calico` (the AME default), `cilium`, or `custom` to bring your own. Cilium uses eBPF and adds Layer 7 load balancing and richer observability; Calico is required if you want `enable_network_encryption`. Values are case-insensitive. Leave null to use the AME default."
  type        = string
  default     = null

  validation {
    condition     = var.cni == null || contains(["calico", "cilium", "custom"], lower(coalesce(var.cni, "calico")))
    error_message = "cni must be one of calico, cilium, custom, or null."
  }
}

variable "pod_security_standards_profile" {
  description = "Default Kubernetes Pod Security Standards profile enforced in the cluster: `privileged` (unrestricted), `baseline` (blocks known privilege escalations) or `restricted` (least privilege, recommended). Namespaces can relax or tighten this individually with `pod-security.kubernetes.io/*` labels. Values are case-insensitive. Leave null to use the AME default."
  type        = string
  default     = null

  validation {
    condition     = var.pod_security_standards_profile == null || contains(["privileged", "baseline", "restricted"], lower(coalesce(var.pod_security_standards_profile, "baseline")))
    error_message = "pod_security_standards_profile must be one of privileged, baseline, restricted, or null."
  }
}

variable "delete_protection" {
  description = "Block deletion of the cluster until the protection is lifted. Note that Terraform can still remove the resource from state; this guards against the cluster being deleted in AME. Leave null to use the AME default. Requires provider >= 0.10.0."
  type        = bool
  default     = null
}

variable "cluster_state_wait_seconds" {
  description = "How long the provider waits for the cluster to reach its desired state before timing out. Raise it when provisioning is slow, for example on a private cluster where extra cloud resources are created first. Leave null to use the provider default."
  type        = number
  default     = null
}

# ---------------------------------------------------------------------------
# Version tracking and automatic upgrades
#
# `update_channel_name` above only resolves a version at plan time.
# `update_channel` below makes AME follow the channel server-side, which is
# what auto-upgrade acts on.
# ---------------------------------------------------------------------------

variable "update_channel" {
  description = "Update channel the cluster follows inside AME, for example `regular`. This is different from `update_channel_name`, which only resolves a version when Terraform plans: setting this records the channel on the cluster so AME itself knows what to upgrade towards, which is what `enable_auto_upgrade` acts on. Set it to the same value as `update_channel_name` unless you deliberately want them to differ. Leave null to leave the cluster's channel unset."
  type        = string
  default     = null
}

variable "enable_auto_upgrade" {
  description = "Let AME upgrade the cluster automatically towards its `update_channel`, inside the window of `maintenance_schedule_id`. Without a maintenance schedule there is no window for an upgrade to run in, so set both together. Leave null to use the AME default. Requires provider >= 0.6.0."
  type        = bool
  default     = null
}

variable "maintenance_schedule_id" {
  description = "Identity of the AME maintenance schedule that defines when automatic upgrades may run. Maintenance schedules are managed organisation-wide; create one in the Console or with an `acloud_maintenance_schedule` resource and pass its `id` here. Leave null for no schedule. Requires provider >= 0.6.0."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Add-ons
#
# Managed components AME installs and keeps up to date inside the cluster.
# Keyed by add-on name; only `ingressController` takes custom values.
# ---------------------------------------------------------------------------

variable "addons" {
  description = "Managed AME add-ons to configure, keyed by add-on name. Available names are `certManager`, `cloudNativePG`, `defaultNetworkPolicies`, `fluxOperator`, `gpu`, `ingressController`, `kured`, `logging`, `monitoring`, `nfs` and `sealedSecrets`. Each entry takes `enabled` (defaults to true) and `custom_values`, a string map that only `ingressController` currently uses, with the key `type` selecting the ingress implementation. Leave that key unset: the implementations it currently accepts are all being superseded, and an unset value follows whatever AME's current default is. Add-ons are managed by AME rather than by you, so do not also install them yourself. Requires provider >= 0.10.0."
  type = map(object({
    enabled       = optional(bool, true)
    custom_values = optional(map(string))
  }))
  default = {}
}
