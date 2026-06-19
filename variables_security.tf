###############################################################################
# Security & encryption — KMS key material for application-layer (etcd) secret
# encryption.
#
# By default the module creates a CMEK keyring/key (kms.tf) and grants the GKE
# service agent encrypt/decrypt. To bring your own key, set
# database_encryption_key_name to an existing crypto key's full resource name;
# the module then skips key creation and uses it directly. In that case you are
# responsible for granting the GKE service agent roles/cloudkms.cryptoKeyEncrypterDecrypter
# on that key.
###############################################################################

variable "database_encryption_key_name" {
  description = "Full resource name of an existing KMS crypto key (projects/.../locations/.../keyRings/.../cryptoKeys/...) to use for database encryption. When null, the module creates and manages its own key."
  type        = string
  default     = null

  validation {
    condition     = var.database_encryption_key_name == null || can(regex("^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", var.database_encryption_key_name))
    error_message = "database_encryption_key_name must be a full crypto key resource name: projects/<p>/locations/<l>/keyRings/<r>/cryptoKeys/<k>."
  }
}

variable "anonymous_authentication_config_mode" {
  description = "Restrict or enable anonymous access to the cluster. One of ENABLED or LIMITED; null leaves it at the provider default."
  type        = string
  default     = null

  validation {
    condition     = var.anonymous_authentication_config_mode == null || contains(["ENABLED", "LIMITED"], coalesce(var.anonymous_authentication_config_mode, "null"))
    error_message = "anonymous_authentication_config_mode must be ENABLED, LIMITED or null."
  }
}

variable "boot_disk_kms_key" {
  description = "CMEK crypto key (full resource name) used to encrypt node boot disks, unless overridden per node pool. Null uses Google-managed encryption."
  type        = string
  default     = null
}

variable "enable_binary_authorization" {
  description = "Enable the Binary Authorization admission controller."
  type        = bool
  default     = false
}

variable "enable_confidential_nodes" {
  description = "Enable Confidential GKE Nodes (memory encryption)."
  type        = bool
  default     = false
}

variable "enable_secret_manager_addon" {
  description = "Enable the Secret Manager add-on for the cluster."
  type        = bool
  default     = false
}

variable "in_transit_encryption_config" {
  description = "Inter-node in-transit encryption. One of IN_TRANSIT_ENCRYPTION_DISABLED or IN_TRANSIT_ENCRYPTION_INTER_NODE_TRANSPARENT; null leaves it at the provider default."
  type        = string
  default     = null

  validation {
    condition     = var.in_transit_encryption_config == null || contains(["IN_TRANSIT_ENCRYPTION_DISABLED", "IN_TRANSIT_ENCRYPTION_INTER_NODE_TRANSPARENT"], coalesce(var.in_transit_encryption_config, "null"))
    error_message = "in_transit_encryption_config must be IN_TRANSIT_ENCRYPTION_DISABLED, IN_TRANSIT_ENCRYPTION_INTER_NODE_TRANSPARENT or null."
  }
}

variable "kms_key_ring_name" {
  description = "The name for the KMS key ring used for GKE database encryption."
  type        = string
  default     = "gke-keyring"
}

variable "kms_key_name" {
  description = "The name for the KMS crypto key used for GKE database encryption."
  type        = string
  default     = "gke-db-encryption-key"
}
