# Plan-mode unit tests for the fleet membership outputs and the Cloud Service
# Mesh wiring. Mock providers keep these credential-free and fast; the upstream
# cluster modules are overridden so the (apply-time) membership name is known
# during plan.

mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

# Sample of what google_container_cluster.fleet[0].membership returns. It is
# written literally below because override blocks only see root variables:
#   //gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster

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

# --- No fleet: all fleet outputs are null --------------------------------------
run "fleet_membership_withoutFleetProject_isNull" {
  command = plan

  assert {
    condition     = output.fleet_membership == null
    error_message = "fleet_membership should be null when fleet_project is null."
  }

  assert {
    condition     = output.fleet_membership_id == null
    error_message = "fleet_membership_id should be null when fleet_project is null."
  }

  assert {
    condition     = output.fleet_membership_location == null
    error_message = "fleet_membership_location should be null when fleet_project is null."
  }
}

# --- Standard: name is passed through, id/location are derived ---------------
run "fleet_membership_withFleetProjectStandard_exposesNameIdLocation" {
  command = plan

  variables {
    fleet_project = "fleet-host"
  }

  override_module {
    target          = module.standard[0]
    override_during = plan
    outputs = {
      fleet_membership = "//gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster"
    }
  }

  assert {
    condition     = output.fleet_membership == "//gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster"
    error_message = "fleet_membership should expose the upstream membership resource name unchanged."
  }

  assert {
    condition     = output.fleet_membership_id == "test-cluster"
    error_message = "fleet_membership_id should be the last segment of the membership name."
  }

  assert {
    condition     = output.fleet_membership_location == "europe-west1"
    error_message = "fleet_membership_location should be the locations/<loc> segment of the membership name."
  }
}

# --- Autopilot: same outputs, other submodule ---------------------------------
run "fleet_membership_withFleetProjectAutopilot_exposesNameIdLocation" {
  command = plan

  variables {
    cluster_type  = "autopilot"
    fleet_project = "fleet-host"
  }

  override_module {
    target          = module.autopilot[0]
    override_during = plan
    outputs = {
      fleet_membership = "//gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster"
    }
  }

  assert {
    condition     = output.fleet_membership == "//gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster"
    error_message = "fleet_membership should be mode-agnostic."
  }

  assert {
    condition     = output.fleet_membership_id == "test-cluster"
    error_message = "fleet_membership_id should be derived for Autopilot too."
  }

  assert {
    condition     = output.fleet_membership_location == "europe-west1"
    error_message = "fleet_membership_location should be derived for Autopilot too."
  }
}

# --- CSM: feature membership targets the fleet host project -------------------
run "mesh_withCsmEnabled_targetsFleetProjectAndDerivedLocation" {
  command = plan

  variables {
    fleet_project = "fleet-host"
    csm_enabled   = true
  }

  override_module {
    target          = module.standard[0]
    override_during = plan
    outputs = {
      fleet_membership = "//gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster"
    }
  }

  assert {
    condition     = module.mesh[0].project_id == "fleet-host"
    error_message = "The Service Mesh feature membership must be managed in the fleet host project."
  }

  assert {
    condition     = module.mesh[0].membership_id == "test-cluster"
    error_message = "The mesh submodule should receive the short membership id."
  }

  assert {
    condition     = module.mesh[0].membership_location == "europe-west1"
    error_message = "The mesh submodule should use the location embedded in the membership name."
  }
}

# --- CSM: an explicit membership_location overrides the derived one ----------
run "mesh_withExplicitLocation_overridesDerivedLocation" {
  command = plan

  variables {
    fleet_project       = "fleet-host"
    csm_enabled         = true
    membership_location = "global"
  }

  override_module {
    target          = module.standard[0]
    override_during = plan
    outputs = {
      fleet_membership = "//gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster"
    }
  }

  assert {
    condition     = module.mesh[0].membership_location == "global"
    error_message = "An explicit membership_location should win over the derived location."
  }
}
