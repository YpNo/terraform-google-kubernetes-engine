output "project_id" {
  description = "Project in which the Service Mesh feature membership is managed (the fleet host project)."
  value       = var.project_id
}

output "membership_id" {
  description = "Short fleet membership id passed to google_gke_hub_feature_membership."
  value       = local.membership_id
}

output "membership_location" {
  description = "Fleet membership location passed to google_gke_hub_feature_membership."
  value       = local.membership_location
}
