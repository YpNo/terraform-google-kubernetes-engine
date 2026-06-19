# Terraform Kubernetes Engine Backup Plan submodule

Creates one or more **Backup for GKE** backup plans (`google_gke_backup_backup_plan`)
for a cluster — one per entry in `backup_plans` (keyed by `name`). Pass `null`
(the default) to create none.

The main GKE module wires this automatically from its `backup_plans` input; the
cluster's GKE Backup agent add-on is enabled whenever `backup_plans` (or
`restore_plans`) is set. Requires the `gkebackup.googleapis.com` API.

## Usage

```hcl
module "backup_plan" {
  source = "github.com/YpNo/terraform-google-kubernetes-engine//modules/backupplan?ref=v0.1.0"

  project_id = "my-project"
  location   = "europe-west1"
  cluster_id = module.gke.cluster_id # full cluster resource id

  backup_plans = [{
    name          = "daily"
    cron_schedule = "0 3 * * *"
    labels        = { tier = "prod" }
    # backup_retain_days / backup_delete_lock_days / permissive_mode have defaults
  }]
}
```

See [`variables.tf`](variables.tf) for the full `backup_plans` object schema.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.15.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_gke_backup_backup_plan.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_backup_backup_plan) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_backup_plans"></a> [backup\_plans](#input\_backup\_plans) | List of backup plans to setup | <pre>list(object(<br/>    {<br/>      name                    = string<br/>      location                = optional(string)<br/>      backup_delete_lock_days = optional(number, 7)<br/>      backup_retain_days      = optional(number, 3)<br/>      cron_schedule           = optional(string, "")<br/>      permissive_mode         = optional(bool, true)<br/>      labels                  = map(string)<br/>    }<br/>  ))</pre> | `null` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The GKE cluster ID | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Backup plan storage location | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->