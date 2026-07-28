# infra/terraform-vm/main.tf — VM única GCP para o Luure.
# Provisiona: IP estático + disco de dados 200GB + VM e2-standard-4 + firewall.
# DNS de *.smartecm.io é OPCIONAL (var.manage_dns) pois o domínio pode ser
# gerenciado fora do Cloud DNS deste projeto.

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── IP estático ───────────────────────────────────────────────────────────
resource "google_compute_address" "voce_br_ip" {
  name   = "voce-br-static-ip"
  region = var.region
}

# ── Disco de dados (ledger + bancos) ──────────────────────────────────────
resource "google_compute_disk" "data_disk" {
  name = "voce-br-data"
  type = "pd-ssd"
  zone = var.zone
  size = var.data_disk_gb
}

# ── VM principal ──────────────────────────────────────────────────────────
resource "google_compute_instance" "voce_br_vm" {
  name         = "voce-br-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.data_disk.self_link
    device_name = "data-disk"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.voce_br_ip.address
    }
  }

  tags = ["http-server", "https-server", "voce-br"]

  metadata = {
    enable-oslogin = "TRUE"
    GCP_PROJECT    = var.project_id
    REPO_URL       = var.repo_url
  }

  metadata_startup_script = file("${path.module}/scripts/startup.sh")

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  labels = {
    projeto     = "voce-br"
    ambiente    = "poc"
    responsavel = "prodesp"
  }

  allow_stopping_for_update = true
}

# ── Firewall ──────────────────────────────────────────────────────────────
resource "google_compute_firewall" "allow_web" {
  name    = "voce-br-allow-web"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["voce-br"]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "voce-br-allow-ssh-iap"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  # Apenas Google IAP — nunca SSH direto da internet
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["voce-br"]
}

# ── DNS (OPCIONAL) ─────────────────────────────────────────────────────────
# Só cria se var.manage_dns = true E a zona Cloud DNS existir neste projeto.
locals {
  subdomains = [
    "voce", "api", "ledger",
    "efolha.sp", "gestao.sp", "wallet",
    "licencas.sp", "conselhos.sp", "licitacoes.sp",
    "cidadao.sp", "cras.sp",
    "esocial.sp", "rh.sp",
  ]
}

resource "google_dns_record_set" "subdomains" {
  for_each     = var.manage_dns ? toset(local.subdomains) : toset([])
  name         = "${each.value}.${var.dns_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone_name
  rrdatas      = [google_compute_address.voce_br_ip.address]
}
