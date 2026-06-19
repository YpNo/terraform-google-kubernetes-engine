module "restore_plan" {
  source = "./modules/restoreplan"

  project_id    = var.project_id
  restore_plans = var.restore_plans
  location      = var.region
  cluster_id    = local.cluster_id
}