variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "location" {
  description = "Backup plan storage location"
  type        = string
}

variable "cluster_id" {
  description = "The GKE cluster ID"
  type        = string
}

variable "restore_plans" {
  description = "List of restore plans to setup"
  type = list(object(
    {
      name                             = string
      location                         = optional(string)
      backup_plan                      = string
      excluded_namespaces              = optional(list(string), ["default", "istio-system", "kube-admission-hooks", "gitlab-agent"])
      namespaced_resource_restore_mode = optional(string, "FAIL_ON_CONFLICT")
      transformation_rules = optional(list(object({
        field_actions = list(object({
          op    = string
          path  = optional(string)
          value = optional(string)
        })),
        resource_filter = optional(list(object({
          namespaces = optional(list(string))
          group_kinds = optional(list(object({
            resource_group = optional(string),
            resource_kind  = optional(string)
          })))
        })))
      })), [])
      excluded_group_kinds = optional(list(object({
        resource_group = string
        resource_kind  = string
      })), [])

      labels = map(string)
    }
  ))
}
