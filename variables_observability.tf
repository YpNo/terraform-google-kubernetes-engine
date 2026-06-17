###############################################################################
# Observability — Cloud Logging and Cloud Monitoring component selection.
# Managed Prometheus and observability metrics/relay are enforced in locals.tf.
###############################################################################

variable "logging_enabled_components" {
  description = "Cloud Logging components to enable. Empty list falls back to the GKE default."
  type        = list(string)
  default = [
    "SYSTEM_COMPONENTS",
    "WORKLOADS",
  ]

  validation {
    condition = alltrue([
      for c in var.logging_enabled_components :
      contains([
        "SYSTEM_COMPONENTS",
        "APISERVER",
        "CONTROLLER_MANAGER",
        "SCHEDULER",
        "KCP_CONNECTION",
        "KCP_SSHD",
        "KCP_HPA",
        "WORKLOADS",
      ], c)
    ])
    error_message = "Valid values are SYSTEM_COMPONENTS, APISERVER, CONTROLLER_MANAGER, SCHEDULER, KCP_CONNECTION, KCP_SSHD, KCP_HPA and WORKLOADS."
  }
}

variable "monitoring_enabled_components" {
  description = "Cloud Monitoring components to enable. KUBELET/CADVISOR require GKE 1.29.3-gke.1093000+, JOBSET requires 1.32.1-gke.1357001+. Empty list falls back to the GKE default."
  type        = list(string)
  default = [
    "SYSTEM_COMPONENTS",
    "STORAGE",
    "POD",
    "DEPLOYMENT",
    "STATEFULSET",
    "DAEMONSET",
    "HPA",
    "KUBELET",
    "CADVISOR",
  ]

  validation {
    condition = alltrue([
      for c in var.monitoring_enabled_components :
      contains([
        "SYSTEM_COMPONENTS",
        "APISERVER",
        "SCHEDULER",
        "CONTROLLER_MANAGER",
        "STORAGE",
        "HPA",
        "POD",
        "DAEMONSET",
        "DEPLOYMENT",
        "STATEFULSET",
        "WORKLOADS",
        "KUBELET",
        "CADVISOR",
        "DCGM",
        "JOBSET",
      ], c)
    ])
    error_message = "Valid values are SYSTEM_COMPONENTS, APISERVER, SCHEDULER, CONTROLLER_MANAGER, STORAGE, HPA, POD, DAEMONSET, DEPLOYMENT, STATEFULSET, WORKLOADS, KUBELET, CADVISOR, DCGM and JOBSET."
  }
}
