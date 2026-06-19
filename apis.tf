# --- Enable Cloud KMS API ---

resource "google_project_service" "cloudkms" {
  # Only needed when the module creates its own KMS key.
  count = var.database_encryption_key_name == null ? 1 : 0

  project = var.project_id
  service = "cloudkms.googleapis.com"

  disable_on_destroy = false
}

# --- Enable Google Kubernetes Engine API ---

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}
