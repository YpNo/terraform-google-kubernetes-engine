# --- KMS ---------------------------------------------------------------------

output "gke_database_encryption_key_name" {
  description = "The KMS crypto key used for GKE database encryption (the BYO key when supplied, otherwise the module-managed key)."
  value       = local.database_encryption_key
}

# --- GKE cluster (mode-agnostic) ---------------------------------------------

output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = local.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster."
  value       = local.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_endpoint_dns" {
  description = "The DNS endpoint of the GKE cluster."
  value       = local.cluster_endpoint_dns
}

output "service_account" {
  description = "The service account used by cluster nodes."
  value       = local.service_account
}
