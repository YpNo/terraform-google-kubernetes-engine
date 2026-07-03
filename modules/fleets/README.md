
# Terraform Kubernetes Engine Fleet submodule

GKE submodule to manage GKE's fleets

With the two mandatory parameters, the module will create a fleet on the specified project. it requires `gkehub.googleapis.com` api only.
The other parameters are Anthos service features. So, if you set or enable any of them, the `anthos.googleapis.com` api will be enabled.

### Scope: fleet defaults vs per-cluster settings

`security_posture_mode`, `security_posture_vulnerability_mode` and
`binary_authorization_*` here configure the fleet's `default_cluster_config` —
**fleet-wide defaults** inherited by member clusters that don't set their own
value. They are a *different scope* from the main GKE module's per-cluster
`security_posture_*` / `enable_binary_authorization` inputs, which always take
precedence for that specific cluster. Leave any of these `null` (the default) to
omit it from the fleet config entirely; each feature is gated independently, so
configuring one never emits a `DISABLED` stub of the other.

This submodule creates the **fleet host** (`google_gke_hub_fleet`) and grants the
GKE Hub service agent `roles/gkehub.serviceAgent`. It is meant to be applied
**once per fleet host project**, independently of the cluster module. Clusters
then join this fleet by setting `fleet_project` on the main GKE module — do not
call this submodule per cluster.

## Usage

Minimal fleet host:

```hcl
module "fleet" {
  source = "github.com/YpNo/terraform-google-kubernetes-engine//modules/fleets?ref=v0.1.0"

  project_id   = "fleet-host-project"
  display_name = "GKE Fleet - Staging"
}
```

With fleet-wide default Security Posture and Binary Authorization (enables
`anthos.googleapis.com`):

```hcl
module "fleet" {
  source = "github.com/YpNo/terraform-google-kubernetes-engine//modules/fleets?ref=v0.1.0"

  project_id   = "fleet-host-project"
  display_name = "GKE Fleet - Production"

  security_posture_mode                = "ENTERPRISE"
  security_posture_vulnerability_mode  = "VULNERABILITY_ENTERPRISE"
  binary_authorization_evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.39.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 7.39.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 7.39.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 7.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google-beta_google_gke_hub_fleet.this](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_gke_hub_fleet) | resource |
| [google-beta_google_project_service_identity.gkehub](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_project_service_identity) | resource |
| [google_project_iam_member.gkehub_service_agent](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.anthos](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.container](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.gkeconnect](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.gkehub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_binary_authorization_evaluation_mode"></a> [binary\_authorization\_evaluation\_mode](#input\_binary\_authorization\_evaluation\_mode) | Fleet-wide default Binary Authorization evaluation mode for member clusters. null omits it. Values: "DISABLED", "PROJECT\_SINGLETON\_POLICY\_ENFORCE". | `string` | `null` | no |
| <a name="input_binary_authorization_policy_bindings"></a> [binary\_authorization\_policy\_bindings](#input\_binary\_authorization\_policy\_bindings) | Fleet-wide default Binary Authorization policy bindings for member clusters. Each binding has a 'name' attribute. | <pre>list(object({<br/>    name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | A user-assigned display name of the Fleet. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the Fleet resource belongs. If it is not provided, the provider project is used. | `string` | n/a | yes |
| <a name="input_security_posture_mode"></a> [security\_posture\_mode](#input\_security\_posture\_mode) | Fleet-wide default Security Posture mode for member clusters. null omits it. Values: "DISABLED", "BASIC", "ENTERPRISE". | `string` | `null` | no |
| <a name="input_security_posture_vulnerability_mode"></a> [security\_posture\_vulnerability\_mode](#input\_security\_posture\_vulnerability\_mode) | Fleet-wide default Vulnerability Scanning mode for member clusters. null omits it. Values: "VULNERABILITY\_DISABLED", "VULNERABILITY\_BASIC", "VULNERABILITY\_ENTERPRISE". | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_fleet_id"></a> [fleet\_id](#output\_fleet\_id) | the Fleet identifier |
| <a name="output_fleet_state"></a> [fleet\_state](#output\_fleet\_state) | The state of the fleet resource |
| <a name="output_fleet_uid"></a> [fleet\_uid](#output\_fleet\_uid) | Unique UID across all Fleet resources |
<!-- END_TF_DOCS -->
