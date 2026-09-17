locals {
  ar_repo     = "${var.region}-docker.pkg.dev/${var.gcp_project_id}/luure"
  agent_image = var.agent_image != "" ? var.agent_image : "${local.ar_repo}/luure-agent:lab"
  dash_image  = var.dash_image != "" ? var.dash_image : "${local.ar_repo}/luure-dashday:lab"
}

resource "google_artifact_registry_repository" "luure" {
  location      = var.region
  repository_id = "luure"
  description   = "Luure lab-min images (digest-pinned deploys)"
  format        = "DOCKER"
  labels        = local.labels

  depends_on = [google_project_service.apis]
}

resource "google_artifact_registry_repository_iam_member" "run_reader" {
  location   = google_artifact_registry_repository.luure.location
  repository = google_artifact_registry_repository.luure.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.run.email}"
}

resource "google_cloud_run_v2_service" "agent" {
  name         = "${local.name}-agent"
  location     = var.region
  ingress      = "INGRESS_TRAFFIC_ALL"
  launch_stage = "GA"
  labels       = local.labels

  template {
    service_account = google_service_account.run.email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = google_compute_network.lab.id
        subnetwork = google_compute_subnetwork.lab.id
      }
    }

    containers {
      image = local.agent_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      ports {
        container_port = 8080
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }
      env {
        name  = "PORT"
        value = "8080"
      }
      env {
        name  = "OTP_EXPOSE_DEV_CODE"
        value = "0"
      }
      env {
        name  = "ALLOW_EXPO_REDIRECT"
        value = var.allow_expo_redirect ? "1" : "0"
      }
      env {
        name  = "BASE_URL"
        value = var.agent_base_url
      }
      env {
        name  = "ISSUER_ID"
        value = var.agent_base_url
      }
      env {
        name  = "GOVBR_ISSUER"
        value = var.agent_base_url != "" ? "${var.agent_base_url}/govbr" : ""
      }
      env {
        name  = "ACAPY_ISSUER_ADMIN_URL"
        value = "http://${var.internal_ip}:8001"
      }
      env {
        name  = "ACAPY_VERIFIER_ADMIN_URL"
        value = "http://${var.internal_ip}:8011"
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.lab["database-url"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "ISSUER_JWK"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.lab["issuer-jwk"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "GOVBR_JWK"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.lab["govbr-jwk"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "ACAPY_ADMIN_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.lab["acapy-admin-api-key"].secret_id
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_version.lab,
    google_secret_manager_secret_iam_member.run,
    google_artifact_registry_repository.luure,
    google_compute_subnetwork_iam_member.run_network,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.agent.name
  location = google_cloud_run_v2_service.agent.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
