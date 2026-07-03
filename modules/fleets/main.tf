locals {
  # null = "not configured" -> omit the block. Each inner block is gated
  # independently so configuring one feature never emits a DISABLED stub of the
  # other; the outer block renders only when at least one feature is configured.
  binauthz_enabled               = var.binary_authorization_evaluation_mode != null || length(var.binary_authorization_policy_bindings) > 0
  security_posture_enabled       = var.security_posture_mode != null || var.security_posture_vulnerability_mode != null
  default_cluster_config_enabled = local.binauthz_enabled || local.security_posture_enabled
}

resource "google_gke_hub_fleet" "this" {
  provider = google-beta

  project      = var.project_id
  display_name = var.display_name

  dynamic "default_cluster_config" {
    for_each = local.default_cluster_config_enabled ? [1] : []

    content {
      dynamic "binary_authorization_config" {
        for_each = local.binauthz_enabled ? [1] : []
        content {
          evaluation_mode = var.binary_authorization_evaluation_mode
          dynamic "policy_bindings" {
            for_each = var.binary_authorization_policy_bindings
            content {
              name = policy_bindings.value.name
            }
          }
        }
      }

      dynamic "security_posture_config" {
        for_each = local.security_posture_enabled ? [1] : []
        content {
          mode               = var.security_posture_mode
          vulnerability_mode = var.security_posture_vulnerability_mode
        }
      }
    }
  }

  depends_on = [
    google_project_service.gkehub
  ]
}

# Creates the GKE Hub service agent (and returns its member) at apply time,
# instead of reading data.google_project at plan time. This avoids the failure
# when the project is created in the same run, and guarantees the agent exists
# before the IAM grant below.
resource "google_project_service_identity" "gkehub" {
  provider = google-beta

  project = var.project_id
  service = "gkehub.googleapis.com"

  depends_on = [google_project_service.gkehub]
}

resource "google_project_iam_member" "gkehub_service_agent" {
  project = var.project_id
  role    = "roles/gkehub.serviceAgent"
  member  = google_project_service_identity.gkehub.member
}
