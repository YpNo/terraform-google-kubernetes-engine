###############################################################################
# Node service account — controls the SA used by cluster nodes.
# By default the submodule creates a cluster-specific SA.
###############################################################################

variable "create_service_account" {
  description = "Create a cluster-specific node service account. Set false to use an existing SA via service_account."
  type        = bool
  default     = true
}

variable "service_account" {
  description = "Existing service account email for nodes (used when create_service_account = false). Empty string defers to the module."
  type        = string
  default     = ""
}

variable "service_account_name" {
  description = "Name for the service account created when create_service_account = true. Empty string uses the module default."
  type        = string
  default     = ""
}

variable "grant_registry_access" {
  description = "Grant the created node SA storage.objectViewer and artifactregistry.reader. Only used when create_service_account = true."
  type        = bool
  default     = false
}

variable "registry_project_ids" {
  description = "Projects whose Container/Artifact Registries the node SA may read. Empty uses the cluster project."
  type        = list(string)
  default     = []
}
