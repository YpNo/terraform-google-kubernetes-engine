###############################################################################
# Control-plane access — endpoint visibility and authorized networks.
# The endpoint/CIDR settings are consumed only by the private submodules and
# ignored when enable_private_nodes = false.
###############################################################################

variable "master_authorized_networks" {
  description = "List of CIDR blocks allowed to reach the cluster control plane. Each entry requires 'cidr_block' and 'display_name'."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_private_endpoint" {
  description = "When true, the cluster's control plane is reachable only on its private endpoint (no public control-plane IP). Only applies to private clusters."
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "The /28 CIDR range for the hosted control plane. Required for private clusters. Must not overlap with any other range in use."
  type        = string
  default     = null

  validation {
    condition     = !(var.enable_private_nodes && var.enable_private_endpoint) || var.master_ipv4_cidr_block != null
    error_message = "master_ipv4_cidr_block is required when enable_private_nodes and enable_private_endpoint are both true."
  }
}
