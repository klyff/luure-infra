resource "random_password" "db" {
  length  = 32
  special = false
}

resource "random_password" "acapy_admin" {
  length  = 48
  special = false
}

resource "random_password" "issuer_wallet" {
  length  = 32
  special = false
}

resource "random_password" "verifier_wallet" {
  length  = 32
  special = false
}

resource "random_password" "dash_token" {
  length  = 48
  special = false
}

locals {
  issuer_jwk = var.issuer_jwk != "" ? var.issuer_jwk : (
    fileexists("${path.module}/.secrets/issuer.jwk.json")
    ? file("${path.module}/.secrets/issuer.jwk.json")
    : "{\"kty\":\"EC\",\"crv\":\"P-256\",\"x\":\"pending\",\"y\":\"pending\",\"d\":\"pending\",\"alg\":\"ES256\",\"use\":\"sig\",\"kid\":\"pending\"}"
  )
  govbr_jwk = var.govbr_jwk != "" ? var.govbr_jwk : (
    fileexists("${path.module}/.secrets/govbr.jwk.json")
    ? file("${path.module}/.secrets/govbr.jwk.json")
    : "{\"kty\":\"EC\",\"crv\":\"P-256\",\"x\":\"pending\",\"y\":\"pending\",\"d\":\"pending\",\"alg\":\"ES256\",\"use\":\"sig\",\"kid\":\"pending\"}"
  )
  database_url = "postgres://${var.db_user}:${random_password.db.result}@${var.internal_ip}:5432/${var.db_app_name}?sslmode=disable"
  secret_ids = {
    db-password         = random_password.db.result
    database-url        = local.database_url
    acapy-admin-api-key = random_password.acapy_admin.result
    issuer-wallet-key   = random_password.issuer_wallet.result
    verifier-wallet-key = random_password.verifier_wallet.result
    issuer-jwk          = local.issuer_jwk
    govbr-jwk           = local.govbr_jwk
    dash-token          = random_password.dash_token.result
  }
}

resource "google_secret_manager_secret" "lab" {
  for_each  = local.secret_ids
  secret_id = "${local.name}-${each.key}"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "lab" {
  for_each    = local.secret_ids
  secret      = google_secret_manager_secret.lab[each.key].id
  secret_data = each.value
}

resource "google_secret_manager_secret_iam_member" "vm" {
  for_each  = google_secret_manager_secret.lab
  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_secret_manager_secret_iam_member" "run" {
  for_each  = google_secret_manager_secret.lab
  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run.email}"
}
