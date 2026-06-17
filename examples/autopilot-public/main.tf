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

# Autopilot cluster with public nodes. Google manages the data plane, so no
# node_pools / cluster_autoscaling inputs are provided.
module "gke" {
  source = "../../"

  cluster_type         = "autopilot"
  enable_private_nodes = false

  project_id   = var.project_id
  region       = var.region
  cluster_name = "example-autopilot-public"

  network           = "default"
  subnetwork        = "default"
  ip_range_pods     = "pods"
  ip_range_services = "services"
}

output "cluster_name" {
  description = "Name of the created cluster."
  value       = module.gke.gke_cluster_name
}
