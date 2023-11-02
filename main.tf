terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # >= 3.61 for Workload Identity Federation
    }
  }
  required_version = ">= 0.13"
  backend "gcs" {
    bucket = "devops-368714-tfstate"
    prefix = "terraform-in-action-360508"
  }
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
  for_each = toset([
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
  ])
  service                    = each.key
  disable_dependent_services = true
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "example_dataset"
  friendly_name               = "test"
  description                 = "This is a test description"
  location                    = "EU"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }
}
