# Changelog

All notable changes to this module are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-06-19

### Added

- Opinionated wrapper over the community
  `terraform-google-modules/kubernetes-engine` module (`~> 44.x`), provisioning
  any of four cluster shapes from **two** count-gated blocks:
  - `cluster_type` (`standard` | `autopilot`) selects the data-plane model.
  - `enable_private_nodes` toggles public vs private on each family's private
    update-variant (a superset that also produces public clusters).
- Enforced org best-practices as non-overridable locals (Dataplane V2, Shielded
  Nodes, GKE Security Posture, Workload Identity, default-pool taint/tags,
  restricted webhook firewall ports, `disable_default_snat`).
- Customer-managed (CMEK) database encryption with an in-module KMS key, plus a
  bring-your-own-key path via `database_encryption_key_name` (skips key + Cloud
  KMS API creation).
- Grouped input surface across `variables_*.tf` with cross-field validations and
  an Autopilot guard rejecting standard-only inputs.
- Pass-through inputs incl. version/maintenance, Shared VPC (`network_project_id`),
  VPA, node-pool metadata, service-account management, and network/security
  feature toggles (`enable_fqdn_network_policy`,
  `enable_cilium_clusterwide_network_policy`, `gcp_public_cidrs_access_enabled`,
  `anonymous_authentication_config_mode`, `enable_tpu`,
  `enable_binary_authorization`, `enable_confidential_nodes`,
  `enable_secret_manager_addon`, `in_transit_encryption_config`,
  `boot_disk_kms_key`).
- Mode-agnostic outputs (`gke_cluster_name`, `gke_cluster_endpoint`,
  `gke_cluster_endpoint_dns`, `gke_cluster_ca_certificate`, `service_account`).
- Submodules: `fleets` (fleet host + fleet-wide defaults), `hub-feature`,
  `mesh` (Cloud Service Mesh), `backupplan`, `restoreplan`.
- Optional in-cluster objects (`storage_classes`, `priority_classes`,
  `cluster_roles`, `cluster_role_bindings`) via the caller-configured
  `kubernetes` provider (inherited by the module).
- Runnable examples for all four cluster shapes.
- Plan-mode `terraform test` unit suite (selector, guards, validations, BYO-KMS,
  feature toggles) and CI (fmt, validate, tflint, test, Trivy, terraform-docs).

### Fixed

- Routed private-only arguments only to the private submodules (the starting
  point fed them to the public submodule).
- Bumped the community module pin from `~> 4.1` to `~> 44.x`.
- `resource_usage_export_dataset_id` exposed so the resource-usage/egress export
  flags are no longer inert.
- Fleet/CSM submodule fixes: duplicate `google_project_service`, authoritative
  `google_project_iam_binding` switched to `google_project_iam_member`,
  computed-`count`/`||`-on-strings wiring, and null-based gating of the fleet
  `default_cluster_config`.

[Unreleased]: https://github.com/YpNo/terraform-google-kubernetes-engine/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/YpNo/terraform-google-kubernetes-engine/releases/tag/v0.1.0
