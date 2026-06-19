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

variable "backup_plans" {
  description = "List of backup plans to setup"
  type = list(object(
    {
      name                    = string
      location                = optional(string)
      backup_delete_lock_days = optional(number, 7)
      backup_retain_days      = optional(number, 3)
      cron_schedule           = optional(string, "")
      permissive_mode         = optional(bool, true)
      labels                  = map(string)
    }
  ))
  default = null
}
