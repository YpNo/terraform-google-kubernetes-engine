<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.15.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.15.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 6.15.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hub_feature"></a> [hub\_feature](#module\_hub\_feature) | ../hub-feature//. | n/a |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_gke_hub_feature_membership.mesh](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_gke_hub_feature_membership) | resource |
| [google_project_service.mesh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_membership_id"></a> [membership\_id](#input\_membership\_id) | The ID of the GKE Hub Membership to which this Service Mesh feature will be enabled. This typically follows the format 'projects/{project}/locations/{location}/memberships/{membership\_id}'. | `string` | n/a | yes |
| <a name="input_membership_location"></a> [membership\_location](#input\_membership\_location) | The location of the membership. | `string` | `"global"` | no |
| <a name="input_mesh_management"></a> [mesh\_management](#input\_mesh\_management) | Specifies how the Service Mesh control plane is managed. 'MANAGEMENT\_AUTOMATIC' indicates Google-managed control plane, while 'MANAGEMENT\_MANUAL' indicates customer-managed control plane. | `string` | `"MANAGEMENT_AUTOMATIC"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project where the Service Mesh feature and related GKE Hub resources will be managed. If not provided, the provider's default project will be used. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->