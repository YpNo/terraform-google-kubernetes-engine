# --- Get Project Number for GKE Service Agent ---

data "google_project" "this" {
  project_id = var.project_id
}

# --- Configure KMS Key Ring and Key for GKE Database Encryption ---

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 4.1"

  # Skip key creation entirely when a key is supplied (BYO CMEK).
  count = var.database_encryption_key_name == null ? 1 : 0

  project_id = var.project_id
  location   = var.region
  keyring    = var.kms_key_ring_name
  keys       = [var.kms_key_name]
  purpose    = "ENCRYPT_DECRYPT"

  # Universe-aware GKE service-agent email (see locals.tf).
  encrypters = [local.gke_service_agent]
  decrypters = [local.gke_service_agent]

  set_encrypters_for = [var.kms_key_name]
  set_decrypters_for = [var.kms_key_name]

  # Ensure KMS API is enabled before trying to create KMS resources
  depends_on = [
    google_project_service.cloudkms
  ]
}
