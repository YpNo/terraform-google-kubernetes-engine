# Plan-mode unit tests for the selector, guards and input validations.
# Mock providers keep these credential-free and fast.

mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

variables {
  project_id           = "test-project"
  region               = "europe-west1"
  cluster_name         = "test-cluster"
  network              = "test-vpc"
  subnetwork           = "test-subnet"
  ip_range_pods        = "pods"
  ip_range_services    = "services"
  cluster_type         = "standard"
  enable_private_nodes = false
}

# --- Positive: a valid standard public config plans cleanly ------------------
run "valid_standard_public" {
  command = plan
}

# --- Guard: Autopilot rejects node_pools ------------------------------------
run "autopilot_rejects_node_pools" {
  command = plan

  variables {
    cluster_type = "autopilot"
    node_pools = [{
      name = "should-not-be-allowed"
    }]
  }

  expect_failures = [var.cluster_type]
}

# --- Guard: Autopilot rejects config_connector ------------------------------
run "autopilot_rejects_config_connector" {
  command = plan

  variables {
    cluster_type     = "autopilot"
    config_connector = true
  }

  expect_failures = [var.cluster_type]
}

# --- Guard: Autopilot rejects cluster_autoscaling ---------------------------
run "autopilot_rejects_cluster_autoscaling" {
  command = plan

  variables {
    cluster_type = "autopilot"
    cluster_autoscaling = {
      enabled = true
    }
  }

  expect_failures = [var.cluster_type]
}

# --- Validation: private + private endpoint requires master CIDR ------------
run "private_requires_master_cidr" {
  command = plan

  variables {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = null
  }

  expect_failures = [var.master_ipv4_cidr_block]
}

# --- Validation: zonal cluster requires zones -------------------------------
run "zonal_requires_zones" {
  command = plan

  variables {
    regional = false
    zones    = []
  }

  expect_failures = [var.zones]
}

# --- Validation: unknown release channel is rejected ------------------------
run "invalid_release_channel" {
  command = plan

  variables {
    release_channel = "BOGUS"
  }

  expect_failures = [var.release_channel]
}

# --- Validation: unknown cluster_type is rejected ---------------------------
run "invalid_cluster_type" {
  command = plan

  variables {
    cluster_type = "hybrid"
  }

  expect_failures = [var.cluster_type]
}

# --- BYO KMS: a supplied key is used and the managed key is skipped ----------
run "byo_kms_key_is_used" {
  command = plan

  variables {
    database_encryption_key_name = "projects/p/locations/europe-west1/keyRings/r/cryptoKeys/k"
  }

  assert {
    condition     = length(module.kms) == 0
    error_message = "Module-managed KMS key should not be created when a BYO key is supplied."
  }

  assert {
    condition     = output.gke_database_encryption_key_name == "projects/p/locations/europe-west1/keyRings/r/cryptoKeys/k"
    error_message = "The supplied BYO key should be used for database encryption."
  }
}

# --- BYO KMS: malformed key resource name is rejected -----------------------
run "byo_kms_key_invalid_format" {
  command = plan

  variables {
    database_encryption_key_name = "not-a-valid-key"
  }

  expect_failures = [var.database_encryption_key_name]
}

# --- Validation: unknown anonymous_authentication_config_mode is rejected ----
run "invalid_anonymous_auth_mode" {
  command = plan

  variables {
    anonymous_authentication_config_mode = "BOGUS"
  }

  expect_failures = [var.anonymous_authentication_config_mode]
}

# --- Feature toggles plan cleanly when set ----------------------------------
run "feature_toggles_plan" {
  command = plan

  variables {
    enable_fqdn_network_policy               = true
    enable_cilium_clusterwide_network_policy = true
    gcp_public_cidrs_access_enabled          = false
    anonymous_authentication_config_mode     = "LIMITED"
    enable_tpu                               = true
  }
}

# --- Validation: unknown in_transit_encryption_config is rejected -----------
run "invalid_in_transit_encryption" {
  command = plan

  variables {
    in_transit_encryption_config = "BOGUS"
  }

  expect_failures = [var.in_transit_encryption_config]
}

# --- Validation: recurring maintenance window needs RFC3339 start ----------
run "recurring_maintenance_requires_rfc3339_start" {
  command = plan

  variables {
    maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    maintenance_end_time   = "2024-01-01T09:00:00Z"
    # maintenance_start_time left at the "05:00" daily-format default
  }

  expect_failures = [var.maintenance_start_time]
}

# --- Dedicated universe: plans cleanly with a universe prefix set -----------
run "universe_plan" {
  command = plan

  variables {
    universe = { prefix = "u1" }
  }
}

# --- Groups A-G plan cleanly when set (Standard) ----------------------------
run "extended_inputs_plan" {
  command = plan

  variables {
    network_project_id               = "host-project"
    kubernetes_version               = "1.30"
    maintenance_start_time           = "2024-01-01T05:00:00Z"
    maintenance_recurrence           = "FREQ=WEEKLY;BYDAY=SA,SU"
    maintenance_end_time             = "2024-01-01T09:00:00Z"
    resource_usage_export_dataset_id = "gke_usage"
    boot_disk_kms_key                = "projects/p/locations/europe-west1/keyRings/r/cryptoKeys/k"
    enable_binary_authorization      = true
    enable_confidential_nodes        = true
    enable_secret_manager_addon      = true
    in_transit_encryption_config     = "IN_TRANSIT_ENCRYPTION_INTER_NODE_TRANSPARENT"
    enable_vertical_pod_autoscaling  = true
    http_load_balancing              = true
    create_service_account           = true
    grant_registry_access            = true
    node_pools_labels = {
      all = { team = "platform" }
    }
  }
}
