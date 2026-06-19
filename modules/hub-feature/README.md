# Terraform Kubernetes Engine Hub Feature submodule

Enables a single **fleet-level GKE Hub feature** (`google_gke_hub_feature`) at the
`global` location for the given project. This is a thin building block: it turns a
feature on for the fleet but does not configure per-membership settings.

Common `feature_name` values: `servicemesh`, `configmanagement`,
`policycontroller`, `multiclusteringress`, `servicedirectory`.

The caller is responsible for **enabling the feature's API** before use (for
example `mesh.googleapis.com` for `servicemesh`) and for registering clusters to
the fleet. The [`mesh`](../mesh) submodule uses this module internally and wires
up the API + per-membership configuration for Cloud Service Mesh.

## Usage

```hcl
module "servicemesh_feature" {
  source = "github.com/YpNo/terraform-google-kubernetes-engine//modules/hub-feature?ref=v0.1.0"

  project_id   = "fleet-host-project"
  feature_name = "servicemesh"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.15.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.15.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 6.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google-beta_google_gke_hub_feature.this](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_gke_hub_feature) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_feature_name"></a> [feature\_name](#input\_feature\_name) | GKE hub feature to enable | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The unique id to identify the GCP project. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_name"></a> [name](#output\_name) | The activated feature name |
<!-- END_TF_DOCS -->