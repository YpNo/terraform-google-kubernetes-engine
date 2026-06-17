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
