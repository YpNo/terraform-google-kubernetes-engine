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
