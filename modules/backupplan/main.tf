resource "google_gke_backup_backup_plan" "this" {
  for_each = var.backup_plans != null ? { for bp in var.backup_plans : bp.name => bp } : {}

  name     = each.value.name
  project  = var.project_id
  cluster  = var.cluster_id
  location = each.value.location != null ? each.value.location : var.location
  retention_policy {
    backup_delete_lock_days = each.value.backup_delete_lock_days
    backup_retain_days      = each.value.backup_retain_days
  }
  backup_schedule {
    cron_schedule = each.value.cron_schedule
  }
  backup_config {
    include_volume_data = true
    include_secrets     = true
    all_namespaces      = true
    permissive_mode     = each.value.permissive_mode
  }

  labels = each.value.labels
}