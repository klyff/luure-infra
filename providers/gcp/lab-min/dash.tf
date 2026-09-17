resource "google_project_iam_member" "run_monitoring" {
  project = var.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.run.email}"
}

resource "google_cloud_run_v2_service" "dashday" {
  name         = "${local.name}-dashday"
  location     = var.region
  ingress      = "INGRESS_TRAFFIC_ALL"
  launch_stage = "GA"
  labels       = local.labels

  template {
    service_account = google_service_account.run.email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = google_compute_network.lab.id
        subnetwork = google_compute_subnetwork.lab.id
      }
    }

    containers {
      image = local.dash_image

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
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
        name  = "GCP_PROJECT"
        value = var.gcp_project_id
      }
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
      env {
        name  = "AGENT_SERVICE"
        value = "${local.name}-agent"
      }
      env {
        name  = "DASH_SERVICE"
        value = "${local.name}-dashday"
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
        name = "DASH_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.lab["dash-token"].secret_id
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
    google_project_iam_member.run_monitoring,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "dash_public" {
  name     = google_cloud_run_v2_service.dashday.name
  location = google_cloud_run_v2_service.dashday.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
