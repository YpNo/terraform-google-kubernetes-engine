variable "project_id" {
  description = "The ID of the project in which the Fleet resource belongs. If it is not provided, the provider project is used."
  type        = string
}

variable "display_name" {
  description = "A user-assigned display name of the Fleet."
  type        = string
}

# --- Fleet-wide default_cluster_config ---------------------------------------
# These set FLEET-LEVEL DEFAULTS inherited by member clusters that do not specify
# their own value. They are a different scope from the main GKE module's
# per-cluster security_posture_* / enable_binary_authorization inputs: the
# per-cluster settings always win for that cluster. Leave any of these null to
# omit it from the fleet default_cluster_config entirely.

variable "binary_authorization_evaluation_mode" {
  description = "Fleet-wide default Binary Authorization evaluation mode for member clusters. null omits it. Values: \"DISABLED\", \"PROJECT_SINGLETON_POLICY_ENFORCE\"."
  type        = string
  default     = null
  validation {
    condition     = var.binary_authorization_evaluation_mode == null || can(regex("^(DISABLED|PROJECT_SINGLETON_POLICY_ENFORCE)$", var.binary_authorization_evaluation_mode))
    error_message = "Invalid binary_authorization_evaluation_mode. Must be one of: DISABLED, PROJECT_SINGLETON_POLICY_ENFORCE, or null."
  }
}

variable "binary_authorization_policy_bindings" {
  description = "Fleet-wide default Binary Authorization policy bindings for member clusters. Each binding has a 'name' attribute."
  type = list(object({
    name = string
  }))
  default = []
}

variable "security_posture_mode" {
  description = "Fleet-wide default Security Posture mode for member clusters. null omits it. Values: \"DISABLED\", \"BASIC\", \"ENTERPRISE\"."
  type        = string
  default     = null
  validation {
    condition     = var.security_posture_mode == null || can(regex("^(DISABLED|BASIC|ENTERPRISE)$", var.security_posture_mode))
    error_message = "Invalid security_posture_mode. Must be one of: DISABLED, BASIC, ENTERPRISE, or null."
  }
}

variable "security_posture_vulnerability_mode" {
  description = "Fleet-wide default Vulnerability Scanning mode for member clusters. null omits it. Values: \"VULNERABILITY_DISABLED\", \"VULNERABILITY_BASIC\", \"VULNERABILITY_ENTERPRISE\"."
  type        = string
  default     = null
  validation {
    condition     = var.security_posture_vulnerability_mode == null || can(regex("^(VULNERABILITY_DISABLED|VULNERABILITY_BASIC|VULNERABILITY_ENTERPRISE)$", var.security_posture_vulnerability_mode))
    error_message = "Invalid security_posture_vulnerability_mode. Must be one of: VULNERABILITY_DISABLED, VULNERABILITY_BASIC, VULNERABILITY_ENTERPRISE, or null."
  }
}
