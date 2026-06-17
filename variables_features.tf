###############################################################################
# Features, add-ons, exports and fleet — applies to all modes unless noted.
###############################################################################

variable "config_connector" {
  description = "Enable the Config Connector add-on. Standard clusters only (Autopilot manages this)."
  type        = bool
  default     = false
}

variable "workload_vulnerability_mode" {
  description = "Workload vulnerability scanning mode. One of '', 'VULNERABILITY_DISABLED', 'VULNERABILITY_BASIC'."
  type        = string
  default     = "VULNERABILITY_BASIC"

  validation {
    condition     = contains(["", "VULNERABILITY_DISABLED", "VULNERABILITY_BASIC"], var.workload_vulnerability_mode)
    error_message = "workload_vulnerability_mode must be '', 'VULNERABILITY_DISABLED' or 'VULNERABILITY_BASIC'."
  }
}

variable "notification_config_topic" {
  description = "Pub/Sub topic (full resource name) to publish GKE cluster upgrade notifications to. Empty string disables notifications."
  type        = string
  default     = ""
}

variable "enable_cost_allocation" {
  description = "Enable GKE cost allocation, attributing cluster resource usage to namespaces and labels."
  type        = bool
  default     = false
}

variable "enable_resource_consumption_export" {
  description = "Whether to enable resource consumption metering export to BigQuery."
  type        = bool
  default     = true
}

variable "backup_plans" {
  description = "Backup-for-GKE plans. When set (non-null), the GKE Backup agent add-on is enabled automatically."
  type        = any
  default     = null
}

variable "restore_plans" {
  description = "Backup-for-GKE restore plans. When set (non-null), the GKE Backup agent add-on is enabled automatically."
  type        = any
  default     = null
}

# --- Fleet -------------------------------------------------------------------

variable "fleet_project" {
  description = "Fleet host project ID to register the cluster to. Null leaves the cluster unregistered."
  type        = string
  default     = null
}

variable "fleet_project_grant_service_agent" {
  description = "Grant the GKE service agent 'roles/gkehub.serviceAgent' on the fleet project. Only used when fleet_project is set."
  type        = bool
  default     = false
}
