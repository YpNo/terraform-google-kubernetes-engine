# Plan-mode unit tests for modules/mesh membership normalisation.

mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

variables {
  project_id    = "fleet-host"
  membership_id = "//gkehub.googleapis.com/projects/123456789012/locations/europe-west1/memberships/test-cluster"
}

# --- Full resource name: short id and location are derived -------------------
run "mesh_withFullMembershipName_derivesIdAndLocation" {
  command = plan

  module {
    source = "./modules/mesh"
  }

  assert {
    condition     = google_gke_hub_feature_membership.mesh.membership == "test-cluster"
    error_message = "membership should be the short id taken from the full resource name."
  }

  assert {
    condition     = google_gke_hub_feature_membership.mesh.membership_location == "europe-west1"
    error_message = "membership_location should be taken from the full resource name."
  }

  assert {
    condition     = google_gke_hub_feature_membership.mesh.project == "fleet-host"
    error_message = "The feature membership should be created in project_id."
  }
}

# --- Short id: passed through, location falls back to the provider default ---
run "mesh_withShortMembershipId_defaultsLocationToGlobal" {
  command = plan

  module {
    source = "./modules/mesh"
  }

  variables {
    membership_id = "test-cluster"
  }

  assert {
    condition     = google_gke_hub_feature_membership.mesh.membership == "test-cluster"
    error_message = "A short membership id should be passed through unchanged."
  }

  assert {
    condition     = google_gke_hub_feature_membership.mesh.membership_location == "global"
    error_message = "Without a location in the id, membership_location should default to global."
  }
}

# --- Explicit location wins over the derived one ------------------------------
run "mesh_withExplicitLocation_overridesDerivedLocation" {
  command = plan

  module {
    source = "./modules/mesh"
  }

  variables {
    membership_location = "us-central1"
  }

  assert {
    condition     = google_gke_hub_feature_membership.mesh.membership_location == "us-central1"
    error_message = "An explicit membership_location should override the derived one."
  }
}
