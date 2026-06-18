# Terraform Kubernetes Engine Hub Feature submodule

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.15.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.15.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 6.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_gke_hub_feature.this](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_gke_hub_feature) | resource |
| [google_project_service.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project_service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_feature_name"></a> [feature\_name](#input\_feature\_name) | GKE hub feature to enable | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The unique id to identify the GCP project. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | The activated feature name |
<!-- END_TF_DOCS -->