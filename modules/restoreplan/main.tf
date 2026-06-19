resource "google_gke_backup_restore_plan" "this" {
  for_each = var.restore_plans != null ? { for rp in var.restore_plans : rp.name => rp } : {}

  name        = each.value.name
  project     = var.project_id
  location    = each.value.location != null ? each.value.location : var.location
  backup_plan = each.value.backup_plan
  cluster     = var.cluster_id
  restore_config {
    all_namespaces = length(each.value.excluded_namespaces) > 0 ? null : true
    excluded_namespaces {
      namespaces = each.value.excluded_namespaces
    }
    namespaced_resource_restore_mode = each.value.namespaced_resource_restore_mode
    volume_data_restore_policy       = "RESTORE_VOLUME_DATA_FROM_BACKUP"
    cluster_resource_restore_scope {
      all_group_kinds = length(each.value.excluded_group_kinds) > 0 ? null : true

      dynamic "excluded_group_kinds" {
        for_each = each.value.excluded_group_kinds

        content {
          resource_group = excluded_group_kinds.value.resource_group
          resource_kind  = excluded_group_kinds.value.resource_kind
        }
      }
    }
    dynamic "transformation_rules" {
      for_each = each.value.restoreplan_transformation_rules

      content {
        dynamic "field_actions" {
          for_each = transformation_rules.value.field_actions
          content {
            op    = field_actions.value.op
            path  = try(field_actions.value.path, null)
            value = try(field_actions.value.value, null)
          }
        }
        dynamic "resource_filter" {
          for_each = transformation_rules.value.resource_filter
          content {
            namespaces = try(resource_filter.value.namespaces, [])
            dynamic "group_kinds" {
              for_each = resource_filter.value.group_kinds

              content {
                resource_group = try(group_kinds.value.resource_group, null)
                resource_kind  = try(group_kinds.value.resource_kind, null)
              }
            }
          }
        }
      }
    }
    cluster_resource_conflict_policy = "USE_BACKUP_VERSION"
  }

  labels = each.value.labels
}
