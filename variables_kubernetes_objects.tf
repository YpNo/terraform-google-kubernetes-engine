###############################################################################
# In-cluster Kubernetes objects — applied via the terraform-kubernetes-objects
# child modules. NOTE: these require a configured `kubernetes` provider (TBD).
# Schemas mirror github.com/YpNo/terraform-kubernetes-objects @ v0.1.0.
###############################################################################

variable "storage_classes" {
  description = "StorageClass objects to create."
  type = list(object({
    name                = string
    storage_provisioner = optional(string, "kubernetes.io/gce-pd")
    reclaim_policy      = optional(string, "Delete")
    storage_type        = optional(string, "pd-standard")
    mount_options       = optional(list(string), null)
  }))
  default = []
}

variable "priority_classes" {
  description = "PriorityClass objects to create."
  type = list(object({
    name              = string
    labels            = optional(map(string))
    annotations       = optional(map(string))
    value             = number
    description       = optional(string)
    global_default    = optional(bool, false)
    preemption_policy = optional(string, "PreemptLowerPriority")
  }))
  default = []
}

variable "cluster_roles" {
  description = "ClusterRole objects to create."
  type = list(object({
    name = string
    rules = list(object({
      api_groups     = optional(list(string))
      resources      = optional(list(string))
      resource_names = optional(list(string), [])
      verbs          = list(string)
    }))
  }))
  default = []
}

variable "cluster_role_bindings" {
  description = "ClusterRoleBinding objects to create."
  type = list(object({
    name = string
    role_ref = object({
      api_group = string
      kind      = string
      name      = string
    })
    subjects = list(object({
      kind      = string
      name      = string
      api_group = optional(string)
      namespace = optional(string)
    }))
  }))
  default = []
}
