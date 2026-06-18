locals {
  network_project_id = var.network_project_id != null ? var.network_project_id : var.project_id
}

data "google_project" "this" {
  project_id = var.project_id
}

module "hub_feature" {
  source = "../hub-feature//."

  project_id   = var.project_id
  feature_name = "servicemesh"
}

# resource "google_gke_hub_membership" "membership" {
#   membership_id = "my-membership"
#   endpoint {
#     gke_cluster {
#       resource_link = "//container.googleapis.com/${google_container_cluster.cluster.id}"
#     }
#   }
# }

resource "google_gke_hub_feature_membership" "mesh" {
  provider = google-beta

  project             = var.project_id
  location            = "global"
  feature             = module.hub_feature.name
  membership          = var.membership_id
  membership_location = var.membership_location
  mesh {
    management = var.mesh_management # "MANAGEMENT_AUTOMATIC"
  }

  depends_on = [
    google_project_service.mesh
  ]
}

# resource "google_project_iam_binding" "meshconfig_network_binding" {
#   count = local.network_project_id != var.project_id ? 1 : 0

#   project = local.network_project_id
#   role    = "roles/meshconfig.serviceAgent"
#   members = [
#     "serviceAccount:service-${data.google_project.this.number}@gcp-sa-servicemesh.iam.gserviceaccount.com"
#   ]
# }

resource "google_project_iam_member" "anthosservicemesh_network_binding" {
  count = local.network_project_id != var.project_id ? 1 : 0

  project = local.network_project_id
  role    = "roles/anthosservicemesh.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-servicemesh.iam.gserviceaccount.com"
}

# resource "google_project_iam_binding" "meshconfig_binding" {
#   project = var.project_id
#   role    = "roles/meshconfig.serviceAgent"
#   members = [
#     "serviceAccount:service-${data.google_project.this.number}@gcp-sa-servicemesh.iam.gserviceaccount.com"
#   ]
# }

resource "google_project_iam_member" "anthosservicemesh_binding" {
  project = var.project_id
  role    = "roles/anthosservicemesh.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-servicemesh.iam.gserviceaccount.com"
}