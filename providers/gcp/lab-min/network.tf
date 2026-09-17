locals {
  name = "luure-${var.environment}"
  labels = {
    projeto    = "luure"
    ambiente   = var.environment
    stack      = "lab-min"
    managed-by = "terraform"
  }
  apis = [
    "compute.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each           = var.gcp_project_id == "" ? toset([]) : toset(local.apis)
  project            = var.gcp_project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "lab" {
  name                    = "${local.name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.apis]

  lifecycle {
    precondition {
      condition     = var.gcp_project_id != "" && var.gcp_project_id != "starlit-torus-492916-d7"
      error_message = "Set gcp_project_id to the Luure project. Predix (starlit-torus-492916-d7) is forbidden."
    }
  }
}

resource "google_compute_subnetwork" "lab" {
  name          = "${local.name}-app"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.lab.id

  private_ip_google_access = true
}

resource "google_compute_address" "external" {
  name   = "${local.name}-ledger-ip"
  region = var.region
}

resource "google_compute_address" "internal" {
  name         = "${local.name}-ledger-int"
  address_type = "INTERNAL"
  address      = var.internal_ip
  subnetwork   = google_compute_subnetwork.lab.id
  region       = var.region
}

resource "google_service_account" "vm" {
  account_id   = "${local.name}-ledger-vm"
  display_name = "Luure lab-min ledger VM"
}

resource "google_service_account" "run" {
  account_id   = "${local.name}-agent-run"
  display_name = "Luure lab-min Cloud Run agent"
}

resource "google_compute_firewall" "iap_ssh" {
  name    = "${local.name}-iap-ssh"
  network = google_compute_network.lab.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["luure-lab"]
}

resource "google_compute_firewall" "public_ssi" {
  name    = "${local.name}-public-ssi"
  network = google_compute_network.lab.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8000", "8010", "9000", "6543"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["luure-lab"]
}

resource "google_compute_firewall" "vpc_private" {
  name    = "${local.name}-vpc-private"
  network = google_compute_network.lab.name

  allow {
    protocol = "tcp"
    ports    = ["5432", "6432", "8001", "8011"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["luure-lab"]
}

resource "google_project_iam_member" "vm_log" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_project_iam_member" "vm_metric" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_compute_subnetwork_iam_member" "run_network" {
  project    = var.gcp_project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.lab.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${google_service_account.run.email}"
}
