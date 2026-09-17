resource "google_compute_disk" "data" {
  name   = "${local.name}-data"
  type   = "pd-balanced"
  zone   = var.zone
  size   = var.data_disk_gb
  labels = local.labels
}

resource "google_compute_resource_policy" "weekday" {
  count  = var.enable_idle_schedule ? 1 : 0
  name   = "${local.name}-weekday-hours"
  region = var.region

  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 8 * * 1-5"
    }
    vm_stop_schedule {
      schedule = "0 21 * * 1-5"
    }
    time_zone = "America/Sao_Paulo"
  }
}

resource "google_compute_instance" "ledger" {
  name         = "${local.name}-ledger"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["luure-lab"]
  labels       = local.labels

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.boot_disk_gb
      type  = "pd-balanced"
    }
  }

  attached_disk {
    source      = google_compute_disk.data.self_link
    device_name = "data-disk"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.lab.id
    network_ip = google_compute_address.internal.address
    access_config {
      nat_ip = google_compute_address.external.address
    }
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
    project-id     = var.gcp_project_id
    environment    = var.environment
    db-user        = var.db_user
    db-app-name    = var.db_app_name
    compose-b64    = filebase64("${path.module}/compose/docker-compose.yml")
    nginx-b64      = filebase64("${path.module}/compose/nginx/nginx.conf")
    initdb-01-b64  = filebase64("${path.module}/compose/postgres/initdb/01-create-logical-databases.sh")
    initdb-02-b64  = filebase64("${path.module}/compose/postgres/initdb/02-app-schema.sql")
    initdb-03-b64  = filebase64("${path.module}/compose/postgres/initdb/03-app-seed.sql")
  }

  metadata_startup_script = file("${path.module}/scripts/startup.sh")

  resource_policies = var.enable_idle_schedule ? [google_compute_resource_policy.weekday[0].id] : []

  depends_on = [
    google_secret_manager_secret_version.lab,
    google_secret_manager_secret_iam_member.vm,
  ]
}
