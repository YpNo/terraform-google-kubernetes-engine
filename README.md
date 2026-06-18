# terraform-google-kubernetes-engine (wrapper)

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
| `variables_features.tf` | Add-ons, exports, fleet |

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

## Security

- Customer-managed (CMEK) KMS key for database (etcd) encryption, with the GKE
  service agent granted encrypt/decrypt. Set `database_encryption_key_name` to
  bring your own key — the module then skips key creation (and the Cloud KMS API
  enablement) and you grant the GKE service agent
  `roles/cloudkms.cryptoKeyEncrypterDecrypter` on that key yourself.
- Enforced: Dataplane V2, Shielded Nodes, Workload Identity, GKE Security
  Posture, `disable_default_snat`, restricted webhook firewall ports.
- Private clusters disable the public control-plane endpoint by default.

### No kubernetes provider required

The module never creates in-cluster (`kubernetes_*`) resources: `configure_ip_masq`
is pinned to `false` on the Standard submodules (ip-masq-agent is redundant with
Dataplane V2 + alias IPs + `disable_default_snat`), and the Autopilot submodules
have no such resource. Consumers therefore do **not** need to configure a
`kubernetes` provider, avoiding the usual create-cluster-then-configure-provider
chicken-and-egg. (A deprecation warning for `kubernetes_config_map` may appear
during `validate`/`plan`; it originates from the upstream module source and is
inert because the resource count is zero.)

## Contributing

Branch per concern (`feat/…`, `fix/…`), one concern per PR, run `terraform fmt`
and `terraform validate` before opening.
