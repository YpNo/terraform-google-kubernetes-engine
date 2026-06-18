###############################################################################
# Release & maintenance — version pinning, release channel and upgrade windows.
# Gateway API channel is enforced in locals.tf.
###############################################################################

variable "release_channel" {
  description = "The GKE release channel to subscribe to."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "EXTENDED"], var.release_channel)
    error_message = "release_channel must be one of RAPID, REGULAR, STABLE or EXTENDED."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version of the control plane. 'latest' pulls the newest available in the region."
  type        = string
  default     = "latest"
}

variable "maintenance_start_time" {
  description = "Maintenance window start. For a daily window use 'HH:MM' (e.g. '05:00'); for a recurring window (maintenance_recurrence/maintenance_end_time set) use a full RFC3339 datetime (e.g. '2024-01-01T05:00:00Z')."
  type        = string
  default     = "05:00"

  validation {
    condition     = (var.maintenance_recurrence == "" && var.maintenance_end_time == "") || can(regex("T", var.maintenance_start_time))
    error_message = "For a recurring maintenance window (maintenance_recurrence or maintenance_end_time set), maintenance_start_time must be a full RFC3339 datetime (e.g. '2024-01-01T05:00:00Z'), not 'HH:MM'."
  }
}

variable "maintenance_end_time" {
  description = "End of a recurring maintenance window, RFC3339. Empty string for a daily window."
  type        = string
  default     = ""
}

variable "maintenance_recurrence" {
  description = "Recurrence of the maintenance window, RFC5545 RRULE. Empty string for a daily window."
  type        = string
  default     = ""
}

variable "maintenance_exclusions" {
  description = "Up to three maintenance exclusion windows."
  type = list(object({
    name            = string
    start_time      = string
    end_time        = string
    exclusion_scope = string
  }))
  default = []
}
