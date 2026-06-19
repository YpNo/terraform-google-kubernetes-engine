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