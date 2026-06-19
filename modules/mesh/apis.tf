# --- Enable GKE HUB API ---

resource "google_project_service" "mesh" {
  project = var.project_id
  service = "mesh.googleapis.com"

  disable_on_destroy = false
}
