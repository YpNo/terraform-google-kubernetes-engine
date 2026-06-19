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

# Autopilot cluster with private nodes and a private control-plane endpoint.
module "gke" {
  source = "../../"

  cluster_type            = "autopilot"
  enable_private_nodes    = true
  enable_private_endpoint = true
  master_ipv4_cidr_block  = "172.16.0.0/28"

  project_id   = var.project_id
  region       = var.region
  cluster_name = "example-autopilot-private"

  network           = "default"
  subnetwork        = "default"
  ip_range_pods     = "pods"
  ip_range_services = "services"

  master_authorized_networks = [{
    cidr_block   = "10.0.0.0/8"
    display_name = "internal"
  }]
}

output "cluster_name" {
  description = "Name of the created cluster."
  value       = module.gke.gke_cluster_name
}
