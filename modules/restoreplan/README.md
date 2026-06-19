# Terraform Kubernetes Engine Restore Plan submodule

Creates one or more **Backup for GKE** restore plans
(`google_gke_backup_restore_plan`) — one per entry in `restore_plans` (keyed by
`name`). Pass `null` (the default) to create none.

Each restore plan targets a backup plan (`backup_plan`) which may live on the
**same or a different project/cluster**, enabling cross-project/cross-cluster
restore. The `cluster_id` is the cluster the data is restored *into*. Requires the
`gkebackup.googleapis.com` API.

The main GKE module wires this automatically from its `restore_plans` input.

## Usage

```hcl
module "restore_plan" {
  source = "github.com/YpNo/terraform-google-kubernetes-engine//modules/restoreplan?ref=v0.1.0"

  project_id = "my-project"
  location   = "europe-west1"
  cluster_id = module.gke.cluster_id # cluster to restore into

  restore_plans = [{
    name = "restore-daily"
    # Full backup plan id; may live in another project/cluster:
    backup_plan = "projects/my-project/locations/europe-west1/backupPlans/daily"
    # ...restore scope / transformation rules...
  }]
}
```

See [`variables.tf`](variables.tf) for the full `restore_plans` object schema.

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
| [google_gke_backup_restore_plan.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_backup_restore_plan) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The GKE cluster ID | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Backup plan storage location | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID | `string` | n/a | yes |
| <a name="input_restore_plans"></a> [restore\_plans](#input\_restore\_plans) | List of restore plans to setup | <pre>list(object(<br/>    {<br/>      name                             = string<br/>      location                         = optional(string)<br/>      backup_plan                      = string<br/>      excluded_namespaces              = optional(list(string), ["default", "istio-system", "kube-admission-hooks", "gitlab-agent"])<br/>      namespaced_resource_restore_mode = optional(string, "FAIL_ON_CONFLICT")<br/>      transformation_rules = optional(list(object({<br/>        field_actions = list(object({<br/>          op    = string<br/>          path  = optional(string)<br/>          value = optional(string)<br/>        })),<br/>        resource_filter = optional(list(object({<br/>          namespaces = optional(list(string))<br/>          group_kinds = optional(list(object({<br/>            resource_group = optional(string),<br/>            resource_kind  = optional(string)<br/>          })))<br/>        })))<br/>      })), [])<br/>      excluded_group_kinds = optional(list(object({<br/>        resource_group = string<br/>        resource_kind  = string<br/>      })), [])<br/><br/>      labels = map(string)<br/>    }<br/>  ))</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->