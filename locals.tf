locals {
  # --- Mode resolution (selector -> active submodule) ---------------------
  # Each family's *private* update-variant is a superset that also produces a
  # public cluster when enable_private_nodes = false, so we need only two
  # count-gated blocks: one per data-plane model.
  is_standard  = var.cluster_type == "standard"
  is_autopilot = var.cluster_type == "autopilot"

  # Private control-plane settings collapse to no-ops for public clusters.
  enable_private_endpoint = var.enable_private_nodes && var.enable_private_endpoint
  master_ipv4_cidr_block  = var.enable_private_nodes ? var.master_ipv4_cidr_block : null

  # --- Universe-aware service-agent email ---------------------------------
  # Default universe -> "" (…@container-engine-robot.iam.gserviceaccount.com).
  # Dedicated universe -> "<prefix>-system." infix, matching the provider.
  universe_sa_infix = var.universe == null ? "" : "${var.universe.prefix}-system."
  gke_service_agent = "serviceAccount:service-${data.google_project.this.number}@container-engine-robot.${local.universe_sa_infix}iam.gserviceaccount.com"

  # --- Enforced org best-practices (non-overridable on purpose) -----------
  authenticator_security_group = "gke-security-groups@maisonsdumonde.com"
  firewall_inbound_ports       = ["8443", "9443", "15017"]
  network_tags                 = concat(["gke-nodes"], var.network_tags)
  gke_backup_agent_config      = var.backup_plans != null || var.restore_plans != null

  # Effective database-encryption key: a caller-supplied key (BYO) takes
  # precedence; otherwise the module-managed key created in kms.tf. one() yields
  # null when the KMS module is disabled (count = 0), so coalesce falls back.
  managed_kms_key         = one([for k in module.kms : k.keys[var.kms_key_name]])
  database_encryption_key = coalesce(var.database_encryption_key_name, local.managed_kms_key)

  database_encryption = [{
    state    = "ENCRYPTED"
    key_name = local.database_encryption_key
  }]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_taints = merge(var.node_pools_taints, {
    default-node-pool = [{
      key    = "default-node-pool"
      value  = true
      effect = "PREFER_NO_SCHEDULE"
    }]
  })

  node_pools_tags = merge(var.node_pools_tags, {
    all               = ["gke-nodes"]
    default-node-pool = ["default-node-pool"]
  })

  # --- Mode-agnostic cluster attributes -----------------------------------
  # Per-attribute splat across the two count-gated blocks. Exactly one block
  # is active, so one() yields its value. Done per attribute (not on the whole
  # object) so differing output schemas/sensitivity don't bleed across.
  cluster_id = one(concat(
    module.standard[*].cluster_id,
    module.autopilot[*].cluster_id,
  ))

  cluster_name = one(concat(
    module.standard[*].name,
    module.autopilot[*].name,
  ))

  cluster_endpoint = one(concat(
    module.standard[*].endpoint,
    module.autopilot[*].endpoint,
  ))

  cluster_ca_certificate = one(concat(
    module.standard[*].ca_certificate,
    module.autopilot[*].ca_certificate,
  ))

  cluster_endpoint_dns = one(concat(
    module.standard[*].endpoint_dns,
    module.autopilot[*].endpoint_dns,
  ))

  service_account = one(concat(
    module.standard[*].service_account,
    module.autopilot[*].service_account,
  ))
}

locals {
  # --- Fleet membership (mode-agnostic) -----------------------------------
  # The upstream modules return google_container_cluster.fleet[0].membership,
  # i.e. the full resource name
  #   //gkehub.googleapis.com/projects/<fleet>/locations/<loc>/memberships/<id>
  # and null when fleet_project is null. one() over the two count-gated blocks
  # keeps that null instead of erroring the way coalesce() would on two nulls.
  fleet_membership = one(concat(
    module.standard[*].fleet_membership,
    module.autopilot[*].fleet_membership,
  ))

  # google_gke_hub_feature_membership takes the *short* membership id plus its
  # location (see fleet.0.membership_id / fleet.0.membership_location in the
  # google_container_cluster docs), so both are derived here once.
  fleet_membership_id       = local.fleet_membership == null ? null : regex("memberships/([^/]+)$", local.fleet_membership)[0]
  fleet_membership_location = local.fleet_membership == null ? null : regex("locations/([^/]+)/memberships/", local.fleet_membership)[0]
}
