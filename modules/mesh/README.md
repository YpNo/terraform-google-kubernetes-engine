# Terraform Kubernetes Engine Mesh (Cloud Service Mesh) submodule

Provisions **managed Cloud Service Mesh (CSM)** on a fleet-registered cluster. It:

- enables `mesh.googleapis.com`,
- turns on the fleet `servicemesh` feature (via the [`hub-feature`](../hub-feature) submodule),
- configures the per-membership mesh management (`google_gke_hub_feature_membership`), and
- grants the Service Mesh service agent `roles/anthosservicemesh.serviceAgent`
  on the project (and on the Shared VPC host project when `network_project_id` differs).

With `mesh_management = "MANAGEMENT_AUTOMATIC"` (default), Google manages the
control plane and data plane (auto sidecar/ambient injection per channel).

## Prerequisites

1. The cluster **must already be registered to a fleet** — set `fleet_project` on
   the main GKE module, which produces the `fleet_membership` used here.
2. Workload Identity must be enabled on the cluster (the main module enables it).

The main module wires this automatically when `csm_enabled = true` (which requires
`fleet_project` to be set).

## Usage

Standalone:

```hcl
module "mesh" {
  source = "github.com/YpNo/terraform-google-kubernetes-engine//modules/mesh?ref=v0.1.0"

  project_id    = "my-project"
  membership_id = module.gke.fleet_membership # from a fleet-registered cluster
  # network_project_id = "host-project"       # only for Shared VPC
  # mesh_management    = "MANAGEMENT_AUTOMATIC"
}
```

> **Membership format (known caveat):** `membership_id` /`membership_location`
> map directly to the `google_gke_hub_feature_membership` arguments. A GKE
> cluster's `fleet_membership` output is a full resource path
> (`projects/.../locations/.../memberships/NAME`); depending on provider version
> you may need to pass the **short** membership id with `membership_location` set
> separately. Verify against a real apply for your setup.

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
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.15.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 6.15.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_hub_feature"></a> [hub\_feature](#module\_hub\_feature) | ../hub-feature//. | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [google-beta_google_gke_hub_feature_membership.mesh](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_gke_hub_feature_membership) | resource |
| [google_project_iam_member.anthosservicemesh_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.anthosservicemesh_network_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.mesh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_membership_id"></a> [membership\_id](#input\_membership\_id) | The ID of the GKE Hub Membership to which this Service Mesh feature will be enabled. This typically follows the format 'projects/{project}/locations/{location}/memberships/{membership\_id}'. | `string` | n/a | yes |
| <a name="input_membership_location"></a> [membership\_location](#input\_membership\_location) | The location of the membership. | `string` | `"global"` | no |
| <a name="input_mesh_management"></a> [mesh\_management](#input\_mesh\_management) | Specifies how the Service Mesh control plane is managed. 'MANAGEMENT\_AUTOMATIC' indicates Google-managed control plane, while 'MANAGEMENT\_MANUAL' indicates customer-managed control plane. | `string` | `"MANAGEMENT_AUTOMATIC"` | no |
| <a name="input_network_project_id"></a> [network\_project\_id](#input\_network\_project\_id) | The ID of the VPC host project (Shared VPC) in which the network resources belong | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project where the Service Mesh feature and related GKE Hub resources will be managed. If not provided, the provider's default project will be used. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->