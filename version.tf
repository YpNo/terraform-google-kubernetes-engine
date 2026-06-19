terraform {
  required_version = ">= 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.15.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.15.0"
    }
    # Used only by the optional in-cluster object modules (kubernetes_objects.tf).
    # The caller must configure `provider "kubernetes"` in its root; it is
    # inherited by this module and its children. No config is needed when the
    # storage_classes / priority_classes / cluster_roles / cluster_role_bindings
    # inputs are left empty.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.1"
    }
  }
}
