# Terraform Kubernetes Engine Backup Plan submodule

This submodule allows setuping a backup plan for "Backup for GKE" feature

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_gke_backup_backup_plan.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_backup_backup_plan) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_plans"></a> [backup\_plans](#input\_backup\_plans) | value | <pre>list(object(<br>    {<br>      name                    = string<br>      backup_delete_lock_days = optional(number, 7)<br>      backup_retain_days      = optional(number, 3)<br>      cron_schedule           = optional(string, "")<br>      permissive_mode         = optional(bool, true)<br>      labels                  = map(string)<br>    }<br>  ))</pre> | `null` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The GKE cluster ID | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Backup plan storage location | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->