module "backup_plan" {
  source = "./modules/backupplan"

  project_id   = var.project_id
  location     = var.region
  cluster_id   = local.cluster_id
  backup_plans = var.backup_plans
}
