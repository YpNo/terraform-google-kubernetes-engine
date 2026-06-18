###############################################################################
# Networking — VPC, subnetwork, secondary ranges and tags shared by all modes.
###############################################################################

variable "network" {
  description = "The VPC network name or self_link the cluster will use."
  type        = string
}

variable "network_project_id" {
  description = "Project ID of the Shared VPC host project, when the network lives in a different project. Empty string uses the cluster project."
  type        = string
  default     = ""
}

variable "subnetwork" {
  description = "The subnetwork name or self_link the cluster will use."
  type        = string
}

variable "ip_range_pods" {
  description = "The secondary IP range name for pods within the subnetwork."
  type        = string
}

variable "ip_range_services" {
  description = "The secondary IP range name for services within the subnetwork."
  type        = string
  default     = ""
}

variable "network_tags" {
  description = "Additional network tags applied to cluster nodes. The module always prepends 'gke-nodes'."
  type        = list(string)
  default     = []
}

variable "enable_fqdn_network_policy" {
  description = "Enable FQDN-based network policies on the cluster. Null leaves it at the provider default."
  type        = bool
  default     = null
}

variable "enable_cilium_clusterwide_network_policy" {
  description = "Enable Cilium cluster-wide network policies (requires Dataplane V2)."
  type        = bool
  default     = false
}
