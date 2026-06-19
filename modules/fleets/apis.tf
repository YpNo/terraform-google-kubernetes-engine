# --- Enable GKE HUB API ---

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "gkehub" {
  project = var.project_id
  service = "gkehub.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "gkeconnect" {
  project = var.project_id
  service = "gkeconnect.googleapis.com"

  disable_on_destroy = false
}

# --- Enable Anthos API ---

resource "google_project_service" "anthos" {
  count = local.default_cluster_config_enabled ? 1 : 0

  project = var.project_id
  service = "anthos.googleapis.com"

  disable_on_destroy = false
}
