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
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "Project ID for the cluster."
  type        = string
}

variable "region" {
  description = "Region for the cluster."
  type        = string
  default     = "europe-west1"
}

# Standard cluster with public nodes.
module "gke" {
  source = "../../"

  cluster_type         = "standard"
  enable_private_nodes = false

  project_id   = var.project_id
  region       = var.region
  cluster_name = "example-standard-public"

  network           = "default"
  subnetwork        = "default"
  ip_range_pods     = "pods"
  ip_range_services = "services"

  node_pools = [{
    name         = "default-pool"
    machine_type = "e2-standard-4"
    min_count    = 1
    max_count    = 3
  }]
}

output "cluster_name" {
  description = "Name of the created cluster."
  value       = module.gke.gke_cluster_name
}
