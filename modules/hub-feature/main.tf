resource "google_gke_hub_feature" "this" {
  provider = google-beta

  name     = var.feature_name
  location = "global"
  project  = var.project_id
}
