###############################################################################
# Core — project, naming and placement attributes shared by all four submodules.
###############################################################################

variable "project_id" {
  description = "Project ID where the cluster and its supporting resources will live."
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
}

variable "description" {
  description = "Optional human-readable description applied to the GKE cluster."
  type        = string
  default     = ""
}

variable "region" {
  description = "The region where the GKE cluster and its resources will be created."
  type        = string
}

variable "regional" {
  description = "Create a regional cluster (control plane and nodes spread across the region's zones). When false, a zonal cluster is created and 'zones' must be set."
  type        = bool
  default     = true
}

variable "zones" {
  description = "Zones to host the cluster in. Required for a zonal cluster (regional = false); for a regional cluster, restricts node placement to these zones when set."
  type        = list(string)
  default     = []

  validation {
    condition     = var.regional || length(var.zones) > 0
    error_message = "zones must contain at least one zone when regional is false."
  }
}

variable "cluster_resource_labels" {
  description = "Labels to apply to the cluster resource itself."
  type        = map(string)
  default     = {}
}
