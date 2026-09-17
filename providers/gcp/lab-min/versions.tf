terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.31, < 7"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }

  # State is local until the Luure GCP project exists.
  # Then: backend "gcs" { bucket = "luure-lab-tfstate" prefix = "lab-min" }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
}
