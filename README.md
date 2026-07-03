# terraform-google-kubernetes-engine (wrapper)

[![CI](https://github.com/YpNo/terraform-google-kubernetes-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/YpNo/terraform-google-kubernetes-engine/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/YpNo/terraform-google-kubernetes-engine?sort=semver&logo=github)](https://github.com/YpNo/terraform-kubernetes-objects/releases)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/YpNo/kubernetes-engine/google/latest)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.3-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Provider: kubernetes](https://img.shields.io/badge/hashicorp%2Fkubernetes-%3E%3D2.37.1-326CE5?logo=kubernetes&logoColor=white)](https://registry.terraform.io/providers/hashicorp/kubernetes/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-FAB040?logo=pre-commit&logoColor=white)](https://pre-commit.com/)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-FE5196?logo=conventionalcommits&logoColor=white)](https://www.conventionalcommits.org)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

## Overview

An opinionated wrapper around the community
[terraform-google-modules/kubernetes-engine](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine)
module. A single module interface provisions any of **four** cluster shapes from
**two** module blocks, enforcing a fixed set of organisation
security/operational defaults plus a customer-managed (CMEK) KMS key for
database encryption.

| `cluster_type` | `enable_private_nodes` | Community submodule used |
|----------------|------------------------|--------------------------|
| `standard`     | `false`                | `beta-private-cluster-update-variant` (public via `enable_private_nodes = false`) |
| `standard`     | `true`                 | `beta-private-cluster-update-variant` |
| `autopilot`    | `false`                | `beta-autopilot-private-cluster` (public via `enable_private_nodes = false`)      |
| `autopilot`    | `true`                 | `beta-autopilot-private-cluster`      |

## Architecture

Terraform cannot interpolate a module `source`, so the two data-plane models
(standard / autopilot) are two separate `module` blocks in [main.tf](main.tf),
each gated by `count` on `cluster_type`. Public vs private is **not** a separate
source: each family's *private* update-variant is a superset that produces a
public cluster when `enable_private_nodes = false`, so it serves both shapes.
Exactly one block is active for any input set.

```
cluster_type ──► count on 2 module blocks (standard | autopilot)
enable_private_nodes ──► private_cluster_config toggles (collapse to public when false)
            │
            ▼
   one(concat(module.standard[*], module.autopilot[*])) per attribute ──► outputs
            ▲
  shared variables  +  enforced org defaults (locals.tf)
```

- **Shared inputs** (project, network, ranges, release channel, observability,
  …) feed both blocks.
- **Private inputs** (`enable_private_endpoint`, `master_ipv4_cidr_block`, …)
  collapse to no-ops in [locals.tf](locals.tf) when `enable_private_nodes = false`.
- **Standard-only inputs** (`node_pools`, `cluster_autoscaling`,
  `config_connector`, sysctls, cgroup mode) feed only the standard block and
  are rejected for Autopilot via `cluster_type` validation.
- **Enforced defaults** (Dataplane V2, Shielded Nodes, Security Posture,
  Workload Identity, default-pool taint, firewall ports, `disable_default_snat`,
  …) live in [locals.tf](locals.tf) and are intentionally not exposed.

### Files

| File | Contents |
|------|----------|
| `main.tf` | The two count-gated submodule blocks |
| `locals.tf` | Selector resolution, enforced defaults, mode-agnostic attribute locals |
| `kms.tf` | CMEK keyring/key for database encryption |
| `apis.tf` | Enables `container` and `cloudkms` APIs |
| `outputs.tf` | Mode-agnostic outputs |
| `variables_selector.tf` | `cluster_type`, `enable_private_nodes` + Autopilot guards |
| `variables_core.tf` | Project, naming, placement |
| `variables_network.tf` | VPC, subnetwork, secondary ranges, tags |
| `variables_private.tf` | Control-plane access (authorized networks, endpoint) |
| `variables_security.tf` | KMS key naming |
| `variables_observability.tf` | Logging / monitoring components |
| `variables_dns.tf` | Cloud DNS provider/scope |
| `variables_release.tf` | Release channel |
| `variables_nodepools.tf` | Node pools & autoscaling (Standard only) |
| `variables_features.tf` | Add-ons, exports, fleet, CSM |
| `variables_serviceaccount.tf` | Node service-account management |
| `variables_kubernetes_objects.tf` | Inputs for the in-cluster object submodules |
| `backup_plan.tf` / `restore_plan.tf` | Calls the `backupplan` / `restoreplan` submodules |
| `kubernetes_objects.tf` | Calls the in-cluster object modules (needs a `kubernetes` provider) |
| [`modules/`](modules) | Shipped submodules — see [Submodules](#submodules) |

## Prerequisites

- Terraform `>= 1.14`
- `hashicorp/google` provider `>= 6.15.0`
- The `container.googleapis.com` and `cloudkms.googleapis.com` APIs (enabled by
  the module)
- An existing VPC, subnetwork, and pods/services secondary ranges

## Usage

```hcl
module "gke" {
  source = "git::https://<your-host>/terraform-google-kubernetes-engine.git"

  cluster_type            = "standard"   # or "autopilot"
  enable_private_nodes    = true
  enable_private_endpoint = true
  master_ipv4_cidr_block  = "172.16.0.0/28"   # required for private

  project_id   = "my-project"
  region       = "europe-west1"
  cluster_name = "my-cluster"

  network           = "my-vpc"
  subnetwork        = "my-subnet"
  ip_range_pods     = "pods"
  ip_range_services = "services"

  # Standard-only:
  node_pools = [{
    name         = "default-pool"
    machine_type = "e2-standard-4"
    min_count    = 1
    max_count    = 5
  }]
}
```

Runnable examples for all four shapes are in [`examples/`](examples).

## Configuration

| Key inputs | Type | Default | Notes |
|------------|------|---------|-------|
| `cluster_type` | string | `standard` | `standard` \| `autopilot` |
| `enable_private_nodes` | bool | `true` | selects public vs private submodule |
| `enable_private_endpoint` | bool | `true` | private clusters only |
| `master_ipv4_cidr_block` | string | `null` | **required** when private + private endpoint |
| `node_pools` | list(object) | `[]` | Standard only |
| `cluster_autoscaling` | object | `{enabled=false}` | Standard only |
| `database_encryption_key_name` | string | `null` | BYO CMEK; `null` = module-managed key |
| `network_project_id` | string | `""` | Set for Shared VPC (network in a host project) |
| `kubernetes_version` | string | `"latest"` | Control-plane version pin |
| `resource_usage_export_dataset_id` | string | `""` | **Required** for the export flags to take effect |
| `enable_vertical_pod_autoscaling` | bool | `null` | `null` keeps submodule default (Std off / AP on) |
| `boot_disk_kms_key` | string | `null` | CMEK for node boot disks |

> **Resource usage export:** `enable_resource_consumption_export` /
> `enable_network_egress_export` only take effect when
> `resource_usage_export_dataset_id` is set to a BigQuery dataset.

See the `variables_*.tf` files for the full, grouped input list and per-field
descriptions/validations.

## Submodules

This repository ships optional submodules under [`modules/`](modules) for fleet,
Cloud Service Mesh and Backup-for-GKE management. Each has its own README with a
usage example and generated input/output tables. They can be used standalone; the
Backup/Mesh ones are also wired into the root module automatically from the inputs
noted below.

| Submodule | Purpose | Root wiring |
|-----------|---------|-------------|
| [`fleets`](modules/fleets) | Creates the **fleet host** (`google_gke_hub_fleet`) and grants the GKE Hub service agent. Apply **once per fleet host project**. | Standalone. Clusters join by setting `fleet_project` on this module. |
| [`hub-feature`](modules/hub-feature) | Enables a single fleet-level GKE Hub feature (e.g. `servicemesh`, `configmanagement`, `policycontroller`). Thin building block. | Used internally by `mesh`. |
| [`mesh`](modules/mesh) | Provisions **managed Cloud Service Mesh** on a fleet-registered cluster (mesh feature + per-membership config + service-agent IAM). | Auto-applied when `csm_enabled = true` (which requires `fleet_project`). |
| [`backupplan`](modules/backupplan) | Creates **Backup-for-GKE** backup plans for the cluster. | Auto-applied from `backup_plans`. |
| [`restoreplan`](modules/restoreplan) | Creates **Backup-for-GKE** restore plans (supports cross-project/cluster restore). | Auto-applied from `restore_plans`. |

**External modules** (not in this repo) are also composed by the root: the
community [`terraform-google-modules/kubernetes-engine`](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine)
cluster submodules and `terraform-google-modules/kms` for the cluster and CMEK
key, and the [`terraform-kubernetes-objects`](https://github.com/YpNo/terraform-kubernetes-objects)
modules for optional in-cluster objects — the latter require a caller-configured
`kubernetes` provider (see [Kubernetes provider](#kubernetes-provider-in-cluster-objects)).

## Testing

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

`terraform validate` checks the input contract of both submodule blocks
regardless of which is active. `terraform test` runs plan-mode unit tests
(mock providers, no credentials) covering the selector, the Autopilot guards
and the input validations.

## Dedicated / sovereign universes

The module works in **Google Cloud Dedicated** (and other non-`googleapis.com`
universes). API endpoints are handled by the provider — the **caller** sets
`universe_domain` on the `google`/`google-beta` providers (this module configures
no providers):

```hcl
provider "google"      { universe_domain = "my-universe.goog" }
provider "google-beta" { universe_domain = "my-universe.goog" }
```

Service-agent email **domains** also differ in a universe. The `fleets` and
`mesh` submodules already read their agents from `google_project_service_identity`
(provider-computed, so universe-correct automatically). The one email the root
module constructs itself — the GKE agent granted CMEK access — is made
universe-aware by setting `universe`:

```hcl
module "gke" {
  # ...
  universe = { prefix = "my-universe" } # -> ...@container-engine-robot.my-universe-system.iam.gserviceaccount.com
}
```

Leave `universe = null` (default) for the public `googleapis.com` universe.
Requires a provider version that supports `universe_domain` (satisfied by the
pinned `>= 6.15.0`).

## Security

- Customer-managed (CMEK) KMS key for database (etcd) encryption, with the GKE
  service agent granted encrypt/decrypt. Set `database_encryption_key_name` to
  bring your own key — the module then skips key creation (and the Cloud KMS API
  enablement) and you grant the GKE service agent
  `roles/cloudkms.cryptoKeyEncrypterDecrypter` on that key yourself.
- Enforced: Dataplane V2, Shielded Nodes, Workload Identity, GKE Security
  Posture, `disable_default_snat`, restricted webhook firewall ports.
- Private clusters disable the public control-plane endpoint by default.

### Kubernetes provider (in-cluster objects)

The cluster itself needs **no** `kubernetes` provider — `configure_ip_masq` is
pinned to `false` (ip-masq-agent is redundant with Dataplane V2 + alias IPs +
`disable_default_snat`) and Autopilot has no such resource. A deprecation warning
for `kubernetes_config_map` may appear during `validate`/`plan`; it comes from the
upstream module source and is inert (resource count is zero).

The **optional** in-cluster object inputs (`storage_classes`, `priority_classes`,
`cluster_roles`, `cluster_role_bindings`) DO require a `kubernetes` provider.
Following Terraform's guidance, this module does **not** configure one — the
**caller configures `provider "kubernetes"` in its own root** and it is inherited
by this module and its child modules. No configuration is needed while those
inputs are empty.

```hcl
module "gke" {
  source = "..."
  # ...cluster inputs...
  storage_classes = [{ name = "fast", storage_type = "pd-ssd" }]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.gke_cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.gke.gke_cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}
```

Caveats the caller owns:
- **Private endpoint reachability** — this module defaults to a *private* control
  plane, so the machine running Terraform must have a network path to it (private
  CI runner, VPN, bastion, or Connect Gateway). A public runner cannot reach it.
- **Apply ordering** — a provider configured from these outputs depends on the
  cluster existing; first-time runs may need a targeted apply of the cluster, or
  split the cluster and the in-cluster objects into separate states/stages.
- **Token lifetime** — `google_client_config.access_token` is ~1h; for long runs
  prefer an `exec`/`gke-gcloud-auth-plugin` auth block.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) (Keep a Changelog / SemVer).

## Contributing

Branch per concern (`feat/…`, `fix/…`), one concern per PR, run `terraform fmt`
and `terraform validate` before opening. CI (fmt, validate, tflint, `terraform test`,
Trivy, terraform-docs) must be green.

## Reference

The tables below are generated by [terraform-docs](https://terraform-docs.io)
(`terraform-docs markdown table --output-file README.md --output-mode inject .`).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.15.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.15.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.37.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.37.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_autopilot"></a> [autopilot](#module\_autopilot) | terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster | ~> 44.2 |
| <a name="module_backup_plan"></a> [backup\_plan](#module\_backup\_plan) | ./modules/backupplan | n/a |
| <a name="module_cluster_role_bindings"></a> [cluster\_role\_bindings](#module\_cluster\_role\_bindings) | github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/clusterrolebinding_v1 | v0.1.0 |
| <a name="module_cluster_roles"></a> [cluster\_roles](#module\_cluster\_roles) | github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/clusterrole_v1 | v0.1.0 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-google-modules/kms/google | ~> 4.1 |
| <a name="module_mesh"></a> [mesh](#module\_mesh) | ./modules/mesh | n/a |
| <a name="module_priority_class"></a> [priority\_class](#module\_priority\_class) | github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/priorityclass_v1 | v0.1.0 |
| <a name="module_restore_plan"></a> [restore\_plan](#module\_restore\_plan) | ./modules/restoreplan | n/a |
| <a name="module_standard"></a> [standard](#module\_standard) | terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster-update-variant | ~> 44.2 |
| <a name="module_storage_class"></a> [storage\_class](#module\_storage\_class) | github.com/YpNo/terraform-kubernetes-objects//modules/kubernetes-objects/storageclass | v0.1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_project_service.cloudkms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.container](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_anonymous_authentication_config_mode"></a> [anonymous\_authentication\_config\_mode](#input\_anonymous\_authentication\_config\_mode) | Restrict or enable anonymous access to the cluster. One of ENABLED or LIMITED; null leaves it at the provider default. | `string` | `null` | no |
| <a name="input_backup_plans"></a> [backup\_plans](#input\_backup\_plans) | Backup-for-GKE plans. When set (non-null), the GKE Backup agent add-on is enabled automatically. | `any` | `null` | no |
| <a name="input_boot_disk_kms_key"></a> [boot\_disk\_kms\_key](#input\_boot\_disk\_kms\_key) | CMEK crypto key (full resource name) used to encrypt node boot disks, unless overridden per node pool. Null uses Google-managed encryption. | `string` | `null` | no |
| <a name="input_cluster_autoscaling"></a> [cluster\_autoscaling](#input\_cluster\_autoscaling) | Node auto-provisioning (cluster autoscaler) configuration. See the community beta-public-cluster submodule docs for field semantics. | <pre>object({<br/>    enabled                     = bool<br/>    autoscaling_profile         = optional(string, "BALANCED")<br/>    enable_integrity_monitoring = optional(bool, true)<br/>    enable_secure_boot          = optional(bool, true)<br/>    min_nodes                   = optional(number, 0)<br/>    min_cpu_cores               = optional(number, 0)<br/>    max_cpu_cores               = optional(number, 0)<br/>    min_memory_gb               = optional(number, 0)<br/>    max_memory_gb               = optional(number, 0)<br/>    strategy                    = optional(string, "SURGE")<br/>    max_surge                   = optional(number, 1)<br/>    max_unavailable             = optional(number, 0)<br/>    disk_size                   = optional(number, 100)<br/>    disk_type                   = optional(string, "pd-standard")<br/>    image_type                  = optional(string, "COS_CONTAINERD")<br/>    gpu_resources = optional(list(object({<br/>      resource_type = string<br/>      minimum       = number<br/>      maximum       = number<br/>    })), [])<br/>    location_policy        = optional(string, "BALANCED")<br/>    auto_repair            = optional(bool, true)<br/>    auto_upgrade           = optional(bool, true)<br/>    cpu_utilization_target = optional(number)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_cluster_dns_provider"></a> [cluster\_dns\_provider](#input\_cluster\_dns\_provider) | DNS provider for the cluster. One of PROVIDER\_UNSPECIFIED, PLATFORM\_DEFAULT, CLOUD\_DNS. | `string` | `"PROVIDER_UNSPECIFIED"` | no |
| <a name="input_cluster_dns_scope"></a> [cluster\_dns\_scope](#input\_cluster\_dns\_scope) | DNS scope for the cluster. One of DNS\_SCOPE\_UNSPECIFIED, CLUSTER\_SCOPE, VPC\_SCOPE. | `string` | `"DNS_SCOPE_UNSPECIFIED"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the GKE cluster. | `string` | n/a | yes |
| <a name="input_cluster_resource_labels"></a> [cluster\_resource\_labels](#input\_cluster\_resource\_labels) | Labels to apply to the cluster resource itself. | `map(string)` | `{}` | no |
| <a name="input_cluster_role_bindings"></a> [cluster\_role\_bindings](#input\_cluster\_role\_bindings) | ClusterRoleBinding objects to create. | <pre>list(object({<br/>    name = string<br/>    role_ref = object({<br/>      api_group = string<br/>      kind      = string<br/>      name      = string<br/>    })<br/>    subjects = list(object({<br/>      kind      = string<br/>      name      = string<br/>      api_group = optional(string)<br/>      namespace = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_roles"></a> [cluster\_roles](#input\_cluster\_roles) | ClusterRole objects to create. | <pre>list(object({<br/>    name = string<br/>    rules = list(object({<br/>      api_groups     = optional(list(string))<br/>      resources      = optional(list(string))<br/>      resource_names = optional(list(string), [])<br/>      verbs          = list(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_type"></a> [cluster\_type](#input\_cluster\_type) | Data-plane management model. 'standard' lets you manage node pools and cluster autoscaling; 'autopilot' delegates node management to Google. | `string` | `"standard"` | no |
| <a name="input_config_connector"></a> [config\_connector](#input\_config\_connector) | Enable the Config Connector add-on. Standard clusters only (Autopilot manages this). | `bool` | `false` | no |
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | Create a cluster-specific node service account. Set false to use an existing SA via service\_account. | `bool` | `true` | no |
| <a name="input_csm_enabled"></a> [csm\_enabled](#input\_csm\_enabled) | Enable Cloud Service Mesh (CSM). Requires fleet\_project to be set so the cluster is registered to a fleet (CSM is provisioned via fleet membership). | `bool` | `false` | no |
| <a name="input_database_encryption_key_name"></a> [database\_encryption\_key\_name](#input\_database\_encryption\_key\_name) | Full resource name of an existing KMS crypto key (projects/.../locations/.../keyRings/.../cryptoKeys/...) to use for database encryption. When null, the module creates and manages its own key. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Optional human-readable description applied to the GKE cluster. | `string` | `""` | no |
| <a name="input_enable_binary_authorization"></a> [enable\_binary\_authorization](#input\_enable\_binary\_authorization) | Enable the Binary Authorization admission controller. | `bool` | `false` | no |
| <a name="input_enable_cilium_clusterwide_network_policy"></a> [enable\_cilium\_clusterwide\_network\_policy](#input\_enable\_cilium\_clusterwide\_network\_policy) | Enable Cilium cluster-wide network policies (requires Dataplane V2). | `bool` | `false` | no |
| <a name="input_enable_confidential_nodes"></a> [enable\_confidential\_nodes](#input\_enable\_confidential\_nodes) | Enable Confidential GKE Nodes (memory encryption). | `bool` | `false` | no |
| <a name="input_enable_cost_allocation"></a> [enable\_cost\_allocation](#input\_enable\_cost\_allocation) | Enable GKE cost allocation, attributing cluster resource usage to namespaces and labels. | `bool` | `false` | no |
| <a name="input_enable_fqdn_network_policy"></a> [enable\_fqdn\_network\_policy](#input\_enable\_fqdn\_network\_policy) | Enable FQDN-based network policies on the cluster. Null leaves it at the provider default. | `bool` | `null` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | When true, the cluster's control plane is reachable only on its private endpoint (no public control-plane IP). Only applies to private clusters. | `bool` | `true` | no |
| <a name="input_enable_private_nodes"></a> [enable\_private\_nodes](#input\_enable\_private\_nodes) | When true, nodes have private (RFC1918) IPs only and the private submodule is used. When false, the public submodule is used. Secure default is true. | `bool` | `true` | no |
| <a name="input_enable_resource_consumption_export"></a> [enable\_resource\_consumption\_export](#input\_enable\_resource\_consumption\_export) | Whether to enable resource consumption metering export to BigQuery. | `bool` | `true` | no |
| <a name="input_enable_secret_manager_addon"></a> [enable\_secret\_manager\_addon](#input\_enable\_secret\_manager\_addon) | Enable the Secret Manager add-on for the cluster. | `bool` | `false` | no |
| <a name="input_enable_tpu"></a> [enable\_tpu](#input\_enable\_tpu) | Enable Cloud TPU resources in the cluster. WARNING: changing this after creation is destructive. | `bool` | `false` | no |
| <a name="input_enable_vertical_pod_autoscaling"></a> [enable\_vertical\_pod\_autoscaling](#input\_enable\_vertical\_pod\_autoscaling) | Enable Vertical Pod Autoscaling. Null preserves the submodule default (Standard: off, Autopilot: on). | `bool` | `null` | no |
| <a name="input_fleet_project"></a> [fleet\_project](#input\_fleet\_project) | Fleet host project ID to register the cluster to. Null leaves the cluster unregistered. | `string` | `null` | no |
| <a name="input_fleet_project_grant_service_agent"></a> [fleet\_project\_grant\_service\_agent](#input\_fleet\_project\_grant\_service\_agent) | Grant the GKE service agent 'roles/gkehub.serviceAgent' on the fleet project. Only used when fleet\_project is set. | `bool` | `false` | no |
| <a name="input_gcp_public_cidrs_access_enabled"></a> [gcp\_public\_cidrs\_access\_enabled](#input\_gcp\_public\_cidrs\_access\_enabled) | Allow control-plane access from Google Cloud public IP ranges. Null leaves it at the provider default. | `bool` | `null` | no |
| <a name="input_grant_registry_access"></a> [grant\_registry\_access](#input\_grant\_registry\_access) | Grant the created node SA storage.objectViewer and artifactregistry.reader. Only used when create\_service\_account = true. | `bool` | `false` | no |
| <a name="input_http_load_balancing"></a> [http\_load\_balancing](#input\_http\_load\_balancing) | Enable the HTTP (L7) load balancing add-on. | `bool` | `true` | no |
| <a name="input_in_transit_encryption_config"></a> [in\_transit\_encryption\_config](#input\_in\_transit\_encryption\_config) | Inter-node in-transit encryption. One of IN\_TRANSIT\_ENCRYPTION\_DISABLED or IN\_TRANSIT\_ENCRYPTION\_INTER\_NODE\_TRANSPARENT; null leaves it at the provider default. | `string` | `null` | no |
| <a name="input_ip_range_pods"></a> [ip\_range\_pods](#input\_ip\_range\_pods) | The secondary IP range name for pods within the subnetwork. | `string` | n/a | yes |
| <a name="input_ip_range_services"></a> [ip\_range\_services](#input\_ip\_range\_services) | The secondary IP range name for services within the subnetwork. | `string` | `""` | no |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | The name for the KMS crypto key used for GKE database encryption. | `string` | `"gke-db-encryption-key"` | no |
| <a name="input_kms_key_ring_name"></a> [kms\_key\_ring\_name](#input\_kms\_key\_ring\_name) | The name for the KMS key ring used for GKE database encryption. | `string` | `"gke-keyring"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version of the control plane. 'latest' pulls the newest available in the region. | `string` | `"latest"` | no |
| <a name="input_logging_enabled_components"></a> [logging\_enabled\_components](#input\_logging\_enabled\_components) | Cloud Logging components to enable. Empty list falls back to the GKE default. | `list(string)` | <pre>[<br/>  "SYSTEM_COMPONENTS",<br/>  "WORKLOADS"<br/>]</pre> | no |
| <a name="input_maintenance_end_time"></a> [maintenance\_end\_time](#input\_maintenance\_end\_time) | End of a recurring maintenance window, RFC3339. Empty string for a daily window. | `string` | `""` | no |
| <a name="input_maintenance_exclusions"></a> [maintenance\_exclusions](#input\_maintenance\_exclusions) | Up to three maintenance exclusion windows. | <pre>list(object({<br/>    name            = string<br/>    start_time      = string<br/>    end_time        = string<br/>    exclusion_scope = string<br/>  }))</pre> | `[]` | no |
| <a name="input_maintenance_recurrence"></a> [maintenance\_recurrence](#input\_maintenance\_recurrence) | Recurrence of the maintenance window, RFC5545 RRULE. Empty string for a daily window. | `string` | `""` | no |
| <a name="input_maintenance_start_time"></a> [maintenance\_start\_time](#input\_maintenance\_start\_time) | Maintenance window start. For a daily window use 'HH:MM' (e.g. '05:00'); for a recurring window (maintenance\_recurrence/maintenance\_end\_time set) use a full RFC3339 datetime (e.g. '2024-01-01T05:00:00Z'). | `string` | `"05:00"` | no |
| <a name="input_master_authorized_networks"></a> [master\_authorized\_networks](#input\_master\_authorized\_networks) | List of CIDR blocks allowed to reach the cluster control plane. Each entry requires 'cidr\_block' and 'display\_name'. | <pre>list(object({<br/>    cidr_block   = string<br/>    display_name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#input\_master\_ipv4\_cidr\_block) | The /28 CIDR range for the hosted control plane. Required for private clusters. Must not overlap with any other range in use. | `string` | `null` | no |
| <a name="input_membership_location"></a> [membership\_location](#input\_membership\_location) | The location of the membership. | `string` | `"global"` | no |
| <a name="input_monitoring_enabled_components"></a> [monitoring\_enabled\_components](#input\_monitoring\_enabled\_components) | Cloud Monitoring components to enable. KUBELET/CADVISOR require GKE 1.29.3-gke.1093000+, JOBSET requires 1.32.1-gke.1357001+. Empty list falls back to the GKE default. | `list(string)` | <pre>[<br/>  "SYSTEM_COMPONENTS",<br/>  "STORAGE",<br/>  "POD",<br/>  "DEPLOYMENT",<br/>  "STATEFULSET",<br/>  "DAEMONSET",<br/>  "HPA",<br/>  "KUBELET",<br/>  "CADVISOR"<br/>]</pre> | no |
| <a name="input_network"></a> [network](#input\_network) | The VPC network name or self\_link the cluster will use. | `string` | n/a | yes |
| <a name="input_network_project_id"></a> [network\_project\_id](#input\_network\_project\_id) | Project ID of the Shared VPC host project, when the network lives in a different project. Empty string uses the cluster project. | `string` | `""` | no |
| <a name="input_network_tags"></a> [network\_tags](#input\_network\_tags) | Additional network tags applied to cluster nodes. The module always prepends 'gke-nodes'. | `list(string)` | `[]` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | List of node pools to create. See the community beta-public-cluster submodule docs for the full field list. | <pre>list(object({<br/>    name                         = string<br/>    machine_type                 = optional(string, "e2-medium")<br/>    node_locations               = optional(string, "")<br/>    initial_node_count           = optional(number, 0)<br/>    min_count                    = optional(number, 0)<br/>    max_count                    = optional(number, 0)<br/>    total_min_count              = optional(number, 0)<br/>    total_max_count              = optional(number, 6)<br/>    local_ssd_count              = optional(number, 0)<br/>    local_ssd_ephemeral_count    = optional(number, 0)<br/>    disk_size_gb                 = optional(number, 100)<br/>    disk_type                    = optional(string, "pd-standard")<br/>    image_type                   = optional(string, "COS_CONTAINERD")<br/>    enable_gcfs                  = optional(bool, false)<br/>    enable_gvnic                 = optional(bool, false)<br/>    autoscaling                  = optional(bool, true)<br/>    auto_repair                  = optional(bool, true)<br/>    auto_upgrade                 = optional(bool, true)<br/>    preemptible                  = optional(bool, false)<br/>    spot                         = optional(bool, false)<br/>    enable_private_nodes         = optional(bool, true)<br/>    enable_secure_boot           = optional(bool, true)<br/>    enable_nested_virtualization = optional(bool, false)<br/>    queued_provisioning          = optional(bool, false)<br/>    service_account              = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_node_pools_labels"></a> [node\_pools\_labels](#input\_node\_pools\_labels) | Map of maps of Kubernetes node labels by node-pool name. | `map(map(string))` | <pre>{<br/>  "all": {},<br/>  "default-node-pool": {}<br/>}</pre> | no |
| <a name="input_node_pools_linux_node_configs_sysctls"></a> [node\_pools\_linux\_node\_configs\_sysctls](#input\_node\_pools\_linux\_node\_configs\_sysctls) | Map of maps of Linux node sysctls by node-pool name. | `map(map(string))` | `{}` | no |
| <a name="input_node_pools_metadata"></a> [node\_pools\_metadata](#input\_node\_pools\_metadata) | Map of maps of node metadata by node-pool name. | `map(map(string))` | <pre>{<br/>  "all": {},<br/>  "default-node-pool": {}<br/>}</pre> | no |
| <a name="input_node_pools_resource_labels"></a> [node\_pools\_resource\_labels](#input\_node\_pools\_resource\_labels) | Map of maps of GCE resource labels by node-pool name. | `map(map(string))` | <pre>{<br/>  "all": {},<br/>  "default-node-pool": {}<br/>}</pre> | no |
| <a name="input_node_pools_resource_manager_tags"></a> [node\_pools\_resource\_manager\_tags](#input\_node\_pools\_resource\_manager\_tags) | Map of maps of Resource Manager tags by node-pool name. | `map(map(string))` | <pre>{<br/>  "all": {},<br/>  "default-node-pool": {}<br/>}</pre> | no |
| <a name="input_node_pools_tags"></a> [node\_pools\_tags](#input\_node\_pools\_tags) | Map of lists of network tags by node-pool name. The module always adds 'gke-nodes'. | `map(list(string))` | `{}` | no |
| <a name="input_node_pools_taints"></a> [node\_pools\_taints](#input\_node\_pools\_taints) | Map of lists of node taints by node-pool name. The module always adds a default-node-pool taint. | <pre>map(list(object({<br/>    key    = string<br/>    value  = string<br/>    effect = string<br/>  })))</pre> | `{}` | no |
| <a name="input_nodepools_cgroup_mode"></a> [nodepools\_cgroup\_mode](#input\_nodepools\_cgroup\_mode) | Map of cgroup mode (e.g. 'CGROUP\_MODE\_V2') by node-pool name. | `map(string)` | `{}` | no |
| <a name="input_notification_config_topic"></a> [notification\_config\_topic](#input\_notification\_config\_topic) | Pub/Sub topic (full resource name) to publish GKE cluster upgrade notifications to. Empty string disables notifications. | `string` | `""` | no |
| <a name="input_priority_classes"></a> [priority\_classes](#input\_priority\_classes) | PriorityClass objects to create. | <pre>list(object({<br/>    name              = string<br/>    labels            = optional(map(string))<br/>    annotations       = optional(map(string))<br/>    value             = number<br/>    description       = optional(string)<br/>    global_default    = optional(bool, false)<br/>    preemption_policy = optional(string, "PreemptLowerPriority")<br/>  }))</pre> | `[]` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID where the cluster and its supporting resources will live. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region where the GKE cluster and its resources will be created. | `string` | n/a | yes |
| <a name="input_regional"></a> [regional](#input\_regional) | Create a regional cluster (control plane and nodes spread across the region's zones). When false, a zonal cluster is created and 'zones' must be set. | `bool` | `true` | no |
| <a name="input_registry_project_ids"></a> [registry\_project\_ids](#input\_registry\_project\_ids) | Projects whose Container/Artifact Registries the node SA may read. Empty uses the cluster project. | `list(string)` | `[]` | no |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | The GKE release channel to subscribe to. | `string` | `"REGULAR"` | no |
| <a name="input_resource_usage_export_dataset_id"></a> [resource\_usage\_export\_dataset\_id](#input\_resource\_usage\_export\_dataset\_id) | BigQuery dataset ID for resource usage export. REQUIRED for enable\_resource\_consumption\_export / enable\_network\_egress\_export to take effect; empty string disables export. | `string` | `""` | no |
| <a name="input_restore_plans"></a> [restore\_plans](#input\_restore\_plans) | Backup-for-GKE restore plans. When set (non-null), the GKE Backup agent add-on is enabled automatically. | `any` | `null` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Existing service account email for nodes (used when create\_service\_account = false). Empty string defers to the module. | `string` | `""` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name for the service account created when create\_service\_account = true. Empty string uses the module default. | `string` | `""` | no |
| <a name="input_storage_classes"></a> [storage\_classes](#input\_storage\_classes) | StorageClass objects to create. | <pre>list(object({<br/>    name                = string<br/>    storage_provisioner = optional(string, "kubernetes.io/gce-pd")<br/>    reclaim_policy      = optional(string, "Delete")<br/>    storage_type        = optional(string, "pd-standard")<br/>    mount_options       = optional(list(string), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | The subnetwork name or self\_link the cluster will use. | `string` | n/a | yes |
| <a name="input_workload_vulnerability_mode"></a> [workload\_vulnerability\_mode](#input\_workload\_vulnerability\_mode) | Workload vulnerability scanning mode. One of '', 'VULNERABILITY\_DISABLED', 'VULNERABILITY\_BASIC'. | `string` | `"VULNERABILITY_BASIC"` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Zones to host the cluster in. Required for a zonal cluster (regional = false); for a regional cluster, restricts node placement to these zones when set. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_gke_cluster_ca_certificate"></a> [gke\_cluster\_ca\_certificate](#output\_gke\_cluster\_ca\_certificate) | Base64-encoded public CA certificate of the cluster. Use with gke\_cluster\_endpoint to configure a kubernetes provider in the calling root. |
| <a name="output_gke_cluster_endpoint"></a> [gke\_cluster\_endpoint](#output\_gke\_cluster\_endpoint) | The endpoint of the GKE cluster. |
| <a name="output_gke_cluster_endpoint_dns"></a> [gke\_cluster\_endpoint\_dns](#output\_gke\_cluster\_endpoint\_dns) | The DNS endpoint of the GKE cluster. |
| <a name="output_gke_cluster_name"></a> [gke\_cluster\_name](#output\_gke\_cluster\_name) | The name of the GKE cluster. |
| <a name="output_gke_database_encryption_key_name"></a> [gke\_database\_encryption\_key\_name](#output\_gke\_database\_encryption\_key\_name) | The KMS crypto key used for GKE database encryption (the BYO key when supplied, otherwise the module-managed key). |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The service account used by cluster nodes. |
<!-- END_TF_DOCS -->

## License

This module is licensed under the **Apache License 2.0** — see the
[LICENSE](LICENSE) file for details.

```
Copyright 2026 - YpNo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
