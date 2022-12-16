terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0" # >= 3.61 for Workload Identity Federation
    }
  }
  required_version = ">= 0.13"
}

provider "google" {
  project = "terraform-in-action-360508"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

resource "google_compute_network" "vpc_network" {
  name = "terraformed-network"
}

resource "google_project_service" "project" {
  project = var.project_id
  for_each = toset([
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
  ])
  service                    = each.key
  disable_dependent_services = true
}
