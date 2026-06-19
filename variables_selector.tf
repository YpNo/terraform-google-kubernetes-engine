###############################################################################
# Selector — resolves which of the four community submodules is instantiated.
#
#   cluster_type + enable_private_nodes  ->  one of:
#     standard  + public   -> beta-public-cluster-update-variant
#     standard  + private  -> beta-private-cluster-update-variant
#     autopilot + public   -> beta-autopilot-public-cluster
#     autopilot + private  -> beta-autopilot-private-cluster
###############################################################################

variable "cluster_type" {
  description = "Data-plane management model. 'standard' lets you manage node pools and cluster autoscaling; 'autopilot' delegates node management to Google."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "autopilot"], var.cluster_type)
    error_message = "cluster_type must be either 'standard' or 'autopilot'."
  }

  # --- Autopilot guard: standard-only inputs must be left at defaults -------
  validation {
    condition     = var.cluster_type == "standard" || length(var.node_pools) == 0
    error_message = "node_pools is not supported with cluster_type = 'autopilot' (Google manages the data plane). Leave it empty."
  }

  validation {
    condition     = var.cluster_type == "standard" || !var.cluster_autoscaling.enabled
    error_message = "cluster_autoscaling is not supported with cluster_type = 'autopilot'. Set cluster_autoscaling.enabled = false (the default)."
  }

  validation {
    condition     = var.cluster_type == "standard" || !var.config_connector
    error_message = "config_connector is not supported with cluster_type = 'autopilot'. Leave it false."
  }

  validation {
    condition     = var.cluster_type == "standard" || (length(var.node_pools_linux_node_configs_sysctls) == 0 && length(var.nodepools_cgroup_mode) == 0)
    error_message = "node_pools_linux_node_configs_sysctls and nodepools_cgroup_mode are not supported with cluster_type = 'autopilot'."
  }
}

variable "enable_private_nodes" {
  description = "When true, nodes have private (RFC1918) IPs only and the private submodule is used. When false, the public submodule is used. Secure default is true."
  type        = bool
  default     = true
}
