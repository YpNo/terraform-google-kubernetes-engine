###############################################################################
# In-cluster Kubernetes objects (StorageClasses, PriorityClasses, RBAC).
# Mode-agnostic: depends on whichever cluster block is active.
# NOTE: requires a configured `kubernetes` provider — see README (TBD).
###############################################################################

module "storage_class" {
  source = "github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/storageclass?ref=v0.1.0"

  storage_classes = var.storage_classes

  depends_on = [module.standard, module.autopilot]
}

module "priority_class" {
  source = "github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/priorityclass_v1?ref=v0.1.0"

  priority_classes = var.priority_classes

  depends_on = [module.standard, module.autopilot]
}

module "cluster_roles" {
  source = "github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/clusterrole_v1?ref=v0.1.0"

  cluster_roles = var.cluster_roles

  depends_on = [module.standard, module.autopilot]
}

module "cluster_role_bindings" {
  source = "github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/clusterrolebinding_v1?ref=v0.1.0"

  cluster_role_bindings = var.cluster_role_bindings

  depends_on = [module.standard, module.autopilot]
}
