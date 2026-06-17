###############################################################################
# Networking — VPC, subnetwork, secondary ranges and tags shared by all modes.
###############################################################################

variable "network" {
  description = "The VPC network name or self_link the cluster will use."
  type        = string
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
