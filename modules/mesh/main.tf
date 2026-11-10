locals {
  network_project_id = var.network_project_id != null ? var.network_project_id : var.project_id

  # membership_id may be the short id ("my-cluster") or the full resource name a
  # fleet-registered cluster reports
  # ("//gkehub.googleapis.com/projects/<fleet>/locations/<loc>/memberships/<id>").
  # google_gke_hub_feature_membership wants the short id plus membership_location,
  # so normalise here. Both locals stay unknown-safe for plan-time values.
  membership_is_resource_name = can(regex("memberships/", var.membership_id))
  membership_id               = local.membership_is_resource_name ? regex("memberships/([^/]+)$", var.membership_id)[0] : var.membership_id
  membership_name_location    = local.membership_is_resource_name ? regex("locations/([^/]+)/memberships/", var.membership_id)[0] : null

  # Explicit input wins; otherwise the location embedded in the resource name;
  # "global" only as the provider default when a bare short id is given.
  membership_location = coalesce(var.membership_location, local.membership_name_location, "global")
}

# Creates the Service Mesh service agent (and returns its member) at apply time,
# instead of reading data.google_project at plan time. This avoids the failure
# when the project is created in the same run, and guarantees the agent exists
# before the IAM grants below.
# NOTE: verify at apply that generateServiceIdentity is supported for
# mesh.googleapis.com in your provider version; if not, swap to a project_number
# input + constructed email.
resource "google_project_service_identity" "servicemesh" {
  provider = google-beta

  project = var.project_id
  service = "mesh.googleapis.com"

  depends_on = [google_project_service.mesh]
}

module "hub_feature" {
  source = "../hub-feature//."

  project_id   = var.project_id
  feature_name = "servicemesh"

  depends_on = [google_project_service.mesh]
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
  membership          = local.membership_id
  membership_location = local.membership_location
  mesh {
    management = var.mesh_management # "MANAGEMENT_AUTOMATIC"
  }

  depends_on = [
    google_project_service.mesh
  ]
}

resource "google_project_iam_member" "anthosservicemesh_network_binding" {
  count = local.network_project_id != var.project_id ? 1 : 0

  project = local.network_project_id
  role    = "roles/anthosservicemesh.serviceAgent"
  member  = google_project_service_identity.servicemesh.member
}

resource "google_project_iam_member" "anthosservicemesh_binding" {
  project = var.project_id
  role    = "roles/anthosservicemesh.serviceAgent"
  member  = google_project_service_identity.servicemesh.member
}