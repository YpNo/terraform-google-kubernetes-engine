###############################################################################
# Node management — Standard clusters only. These inputs are NOT passed to the
# Autopilot submodules (Google manages the data plane there); setting them with
# cluster_type = "autopilot" raises a validation error (see locals.tf).
###############################################################################

variable "cluster_autoscaling" {
  description = "Node auto-provisioning (cluster autoscaler) configuration. See the community beta-public-cluster submodule docs for field semantics."
  type = object({
    enabled                     = bool
    autoscaling_profile         = optional(string, "BALANCED")
    enable_integrity_monitoring = optional(bool, true)
    enable_secure_boot          = optional(bool, true)
    min_nodes                   = optional(number, 0)
    min_cpu_cores               = optional(number, 0)
    max_cpu_cores               = optional(number, 0)
    min_memory_gb               = optional(number, 0)
    max_memory_gb               = optional(number, 0)
    strategy                    = optional(string, "SURGE")
    max_surge                   = optional(number, 1)
    max_unavailable             = optional(number, 0)
    disk_size                   = optional(number, 100)
    disk_type                   = optional(string, "pd-standard")
    image_type                  = optional(string, "COS_CONTAINERD")
    gpu_resources = optional(list(object({
      resource_type = string
      minimum       = number
      maximum       = number
    })), [])
    location_policy        = optional(string, "BALANCED")
    auto_repair            = optional(bool, true)
    auto_upgrade           = optional(bool, true)
    cpu_utilization_target = optional(number)
  })
  default = {
    enabled = false
  }

  validation {
    condition     = contains(["BALANCED", "OPTIMIZE_UTILIZATION"], var.cluster_autoscaling.autoscaling_profile)
    error_message = "cluster_autoscaling.autoscaling_profile must be BALANCED or OPTIMIZE_UTILIZATION."
  }
}

variable "node_pools" {
  description = "List of node pools to create. See the community beta-public-cluster submodule docs for the full field list."
  type = list(object({
    name                         = string
    machine_type                 = optional(string, "e2-medium")
    node_locations               = optional(string, "")
    initial_node_count           = optional(number, 0)
    min_count                    = optional(number, 0)
    max_count                    = optional(number, 0)
    total_min_count              = optional(number, 0)
    total_max_count              = optional(number, 6)
    local_ssd_count              = optional(number, 0)
    local_ssd_ephemeral_count    = optional(number, 0)
    disk_size_gb                 = optional(number, 100)
    disk_type                    = optional(string, "pd-standard")
    image_type                   = optional(string, "COS_CONTAINERD")
    enable_gcfs                  = optional(bool, false)
    enable_gvnic                 = optional(bool, false)
    autoscaling                  = optional(bool, true)
    auto_repair                  = optional(bool, true)
    auto_upgrade                 = optional(bool, true)
    preemptible                  = optional(bool, false)
    spot                         = optional(bool, false)
    enable_private_nodes         = optional(bool, true)
    enable_secure_boot           = optional(bool, true)
    enable_nested_virtualization = optional(bool, false)
    queued_provisioning          = optional(bool, false)
    service_account              = optional(string)
  }))
  default = []
}

variable "node_pools_taints" {
  description = "Map of lists of node taints by node-pool name. The module always adds a default-node-pool taint."
  type = map(list(object({
    key    = string
    value  = string
    effect = string
  })))
  default = {}
}

variable "node_pools_tags" {
  description = "Map of lists of network tags by node-pool name. The module always adds 'gke-nodes'."
  type        = map(list(string))
  default     = {}
}

variable "node_pools_linux_node_configs_sysctls" {
  description = "Map of maps of Linux node sysctls by node-pool name."
  type        = map(map(string))
  default     = {}
}

variable "nodepools_cgroup_mode" {
  description = "Map of cgroup mode (e.g. 'CGROUP_MODE_V2') by node-pool name."
  type        = map(string)
  default     = {}
}
