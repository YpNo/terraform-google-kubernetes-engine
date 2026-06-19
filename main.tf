###############################################################################
# GKE wrapper — two count-gated submodule instantiations.
#
# `source` cannot be interpolated in Terraform, so the two data-plane models
# (standard / autopilot) are separate module blocks, each gated by `count` on
# the selector. Public vs private is NOT a separate source: each family's
# *private* update-variant is a superset that produces a public cluster when
# enable_private_nodes = false (see locals.tf), so it serves both shapes.
#
# Shared inputs come from variables; org best-practices come from locals.
# Private-only inputs collapse to no-ops for public clusters via locals.
###############################################################################

# --- Standard (public or private nodes) --------------------------------------
module "standard" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster-update-variant"
  version = "~> 44.2"

  count = local.is_standard ? 1 : 0

  project_id        = var.project_id
  name              = var.cluster_name
  description       = var.description
  region            = var.region
  regional          = var.regional
  zones             = var.zones
  network           = var.network
  subnetwork        = var.subnetwork
  ip_range_pods     = var.ip_range_pods
  ip_range_services = var.ip_range_services

  cluster_resource_labels = var.cluster_resource_labels
  database_encryption     = local.database_encryption
  release_channel         = var.release_channel
  deletion_protection     = false

  # Control plane: private settings collapse to public when enable_private_nodes = false
  enable_private_nodes          = var.enable_private_nodes
  enable_private_endpoint       = local.enable_private_endpoint
  deploy_using_private_endpoint = local.enable_private_endpoint
  master_ipv4_cidr_block        = local.master_ipv4_cidr_block
  master_global_access_enabled  = var.enable_private_nodes

  # Data plane (standard-only)
  datapath_provider         = "ADVANCED_DATAPATH"
  remove_default_node_pool  = true
  enable_shielded_nodes     = true
  enable_gcfs               = true
  default_max_pods_per_node = 64

  # ip-masq-agent is unnecessary with Dataplane V2 + alias IPs + disable_default_snat.
  # Keeping this false guarantees the module never requires a kubernetes provider.
  configure_ip_masq = false

  # DNS
  cluster_dns_provider       = var.cluster_dns_provider
  cluster_dns_scope          = var.cluster_dns_scope
  dns_cache                  = true
  dns_allow_external_traffic = true

  # Observability
  logging_enabled_components              = var.logging_enabled_components
  monitoring_enabled_components           = var.monitoring_enabled_components
  monitoring_enable_managed_prometheus    = true
  monitoring_enable_observability_metrics = true
  monitoring_enable_observability_relay   = true

  # Security & identity
  master_authorized_networks          = var.master_authorized_networks
  authenticator_security_group        = local.authenticator_security_group
  identity_namespace                  = "enabled"
  workload_config_audit_mode          = "BASIC"
  workload_vulnerability_mode         = var.workload_vulnerability_mode
  security_posture_mode               = "BASIC"
  security_posture_vulnerability_mode = "VULNERABILITY_BASIC"

  # Networking & firewall
  network_tags                      = local.network_tags
  disable_default_snat              = true
  add_cluster_firewall_rules        = false
  add_master_webhook_firewall_rules = false
  firewall_inbound_ports            = local.firewall_inbound_ports
  gateway_api_channel               = "CHANNEL_STANDARD"

  # Network policy, control-plane access & feature toggles
  enable_fqdn_network_policy               = var.enable_fqdn_network_policy
  enable_cilium_clusterwide_network_policy = var.enable_cilium_clusterwide_network_policy
  gcp_public_cidrs_access_enabled          = var.gcp_public_cidrs_access_enabled
  anonymous_authentication_config_mode     = var.anonymous_authentication_config_mode
  enable_tpu                               = var.enable_tpu

  # Cluster lifecycle
  kubernetes_version     = var.kubernetes_version
  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time
  maintenance_recurrence = var.maintenance_recurrence
  maintenance_exclusions = var.maintenance_exclusions

  # Shared VPC
  network_project_id = var.network_project_id

  # Workload add-ons (VPA set per-block to preserve each submodule's default)
  http_load_balancing = var.http_load_balancing

  # Security
  boot_disk_kms_key            = var.boot_disk_kms_key
  enable_binary_authorization  = var.enable_binary_authorization
  enable_confidential_nodes    = var.enable_confidential_nodes
  enable_secret_manager_addon  = var.enable_secret_manager_addon
  in_transit_encryption_config = var.in_transit_encryption_config

  # Resource usage export (no-op unless a BigQuery dataset id is supplied)
  resource_usage_export_dataset_id = var.resource_usage_export_dataset_id

  # Node service account
  create_service_account = var.create_service_account
  service_account        = var.service_account
  service_account_name   = var.service_account_name
  grant_registry_access  = var.grant_registry_access
  registry_project_ids   = var.registry_project_ids

  # Scaling
  horizontal_pod_autoscaling      = true
  cluster_autoscaling             = var.cluster_autoscaling
  enable_vertical_pod_autoscaling = coalesce(var.enable_vertical_pod_autoscaling, false)

  # Add-ons & exports
  config_connector                   = var.config_connector
  notification_config_topic          = var.notification_config_topic
  enable_cost_allocation             = var.enable_cost_allocation
  enable_resource_consumption_export = var.enable_resource_consumption_export
  enable_network_egress_export       = false
  gke_backup_agent_config            = local.gke_backup_agent_config

  # Fleet
  fleet_project                     = var.fleet_project
  fleet_project_grant_service_agent = var.fleet_project_grant_service_agent

  # Node pools
  node_pools                            = var.node_pools
  node_pools_cgroup_mode                = var.nodepools_cgroup_mode
  node_pools_linux_node_configs_sysctls = var.node_pools_linux_node_configs_sysctls
  node_pools_labels                     = var.node_pools_labels
  node_pools_metadata                   = var.node_pools_metadata
  node_pools_resource_labels            = var.node_pools_resource_labels
  node_pools_resource_manager_tags      = var.node_pools_resource_manager_tags
  node_pools_oauth_scopes               = local.node_pools_oauth_scopes
  node_pools_taints                     = local.node_pools_taints
  node_pools_tags                       = local.node_pools_tags

  depends_on = [google_project_service.container]
}

# --- Autopilot (public or private nodes) -------------------------------------
# Autopilot manages the data plane: no node_pools, cluster_autoscaling,
# shielded-nodes, datapath, gcfs or DNS-provider inputs are accepted.
module "autopilot" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  version = "~> 44.2"

  count = local.is_autopilot ? 1 : 0

  project_id        = var.project_id
  name              = var.cluster_name
  description       = var.description
  region            = var.region
  regional          = var.regional
  zones             = var.zones
  network           = var.network
  subnetwork        = var.subnetwork
  ip_range_pods     = var.ip_range_pods
  ip_range_services = var.ip_range_services

  cluster_resource_labels = var.cluster_resource_labels
  database_encryption     = local.database_encryption
  release_channel         = var.release_channel
  deletion_protection     = false

  # Control plane: private settings collapse to public when enable_private_nodes = false
  enable_private_nodes          = var.enable_private_nodes
  enable_private_endpoint       = local.enable_private_endpoint
  deploy_using_private_endpoint = local.enable_private_endpoint
  master_ipv4_cidr_block        = local.master_ipv4_cidr_block
  master_global_access_enabled  = var.enable_private_nodes

  horizontal_pod_autoscaling      = true
  enable_vertical_pod_autoscaling = coalesce(var.enable_vertical_pod_autoscaling, true)
  dns_cache                       = true
  dns_allow_external_traffic      = true

  # Observability
  logging_enabled_components    = var.logging_enabled_components
  monitoring_enabled_components = var.monitoring_enabled_components

  # Security & identity
  master_authorized_networks          = var.master_authorized_networks
  authenticator_security_group        = local.authenticator_security_group
  identity_namespace                  = "enabled"
  workload_config_audit_mode          = "BASIC"
  workload_vulnerability_mode         = var.workload_vulnerability_mode
  security_posture_mode               = "BASIC"
  security_posture_vulnerability_mode = "VULNERABILITY_BASIC"

  # Networking & firewall
  network_tags                      = local.network_tags
  disable_default_snat              = true
  add_cluster_firewall_rules        = false
  add_master_webhook_firewall_rules = false
  firewall_inbound_ports            = local.firewall_inbound_ports
  gateway_api_channel               = "CHANNEL_STANDARD"

  # Network policy, control-plane access & feature toggles
  enable_fqdn_network_policy               = var.enable_fqdn_network_policy
  enable_cilium_clusterwide_network_policy = var.enable_cilium_clusterwide_network_policy
  gcp_public_cidrs_access_enabled          = var.gcp_public_cidrs_access_enabled
  anonymous_authentication_config_mode     = var.anonymous_authentication_config_mode
  enable_tpu                               = var.enable_tpu

  # Cluster lifecycle
  kubernetes_version     = var.kubernetes_version
  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time
  maintenance_recurrence = var.maintenance_recurrence
  maintenance_exclusions = var.maintenance_exclusions

  # Shared VPC
  network_project_id = var.network_project_id

  # Workload add-ons (VPA set per-block to preserve each submodule's default)
  http_load_balancing = var.http_load_balancing

  # Security
  boot_disk_kms_key            = var.boot_disk_kms_key
  enable_binary_authorization  = var.enable_binary_authorization
  enable_confidential_nodes    = var.enable_confidential_nodes
  enable_secret_manager_addon  = var.enable_secret_manager_addon
  in_transit_encryption_config = var.in_transit_encryption_config

  # Resource usage export (no-op unless a BigQuery dataset id is supplied)
  resource_usage_export_dataset_id = var.resource_usage_export_dataset_id

  # Node service account
  create_service_account = var.create_service_account
  service_account        = var.service_account
  service_account_name   = var.service_account_name
  grant_registry_access  = var.grant_registry_access
  registry_project_ids   = var.registry_project_ids

  # Add-ons & exports
  notification_config_topic          = var.notification_config_topic
  enable_cost_allocation             = var.enable_cost_allocation
  enable_resource_consumption_export = var.enable_resource_consumption_export
  enable_network_egress_export       = false
  gke_backup_agent_config            = local.gke_backup_agent_config

  # Fleet
  fleet_project                     = var.fleet_project
  fleet_project_grant_service_agent = var.fleet_project_grant_service_agent

  depends_on = [google_project_service.container]
}

module "mesh" {
  count  = var.csm_enabled ? 1 : 0
  source = "./modules/mesh"

  project_id          = var.project_id
  network_project_id  = var.network_project_id != "" ? var.network_project_id : null
  membership_id       = coalesce(one(module.standard[*].fleet_membership), one(module.autopilot[*].fleet_membership))
  membership_location = var.membership_location
}
