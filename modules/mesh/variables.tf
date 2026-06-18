variable "project_id" {
  description = "The ID of the Google Cloud project where the Service Mesh feature and related GKE Hub resources will be managed. If not provided, the provider's default project will be used."
  type        = string
}

variable "network_project_id" {
  description = "The ID of the VPC host project (Shared VPC) in which the network resources belong"
  type        = string
  default     = null
}

variable "membership_id" {
  description = "The ID of the GKE Hub Membership to which this Service Mesh feature will be enabled. This typically follows the format 'projects/{project}/locations/{location}/memberships/{membership_id}'."
  type        = string
}

variable "membership_location" {
  description = "The location of the membership."
  type        = string
  default     = "global"
}

variable "mesh_management" {
  description = "Specifies how the Service Mesh control plane is managed. 'MANAGEMENT_AUTOMATIC' indicates Google-managed control plane, while 'MANAGEMENT_MANUAL' indicates customer-managed control plane."
  type        = string
  default     = "MANAGEMENT_AUTOMATIC"

  validation {
    condition     = can(regex("^(MANAGEMENT_AUTOMATIC|MANAGEMENT_MANUAL)$", var.mesh_management))
    error_message = "Invalid mesh_management value. Allowed values are 'MANAGEMENT_AUTOMATIC' or 'MANAGEMENT_MANUAL'."
  }
}
