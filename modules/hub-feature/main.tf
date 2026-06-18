locals {
  services_map = {
    servicemesh = "mesh.googleapis.com"
  }
}

data "google_project_service" "this" {
  service = local.services_map[var.feature_name]
}

resource "google_gke_hub_feature" "this" {
  provider = google-beta

  name     = var.feature_name
  location = "global"
  project  = var.project_id

  depends_on = [
    data.google_project_service.this
  ]
}
