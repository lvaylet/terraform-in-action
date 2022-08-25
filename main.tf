terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
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
