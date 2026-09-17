output "vm_name" {
  value = google_compute_instance.ledger.name
}

output "zone" {
  value = var.zone
}

output "external_ip" {
  value       = google_compute_address.external.address
  description = "Public IP: DIDComm :8000/:8010, genesis :9000 or :80, tails :6543"
}

output "internal_ip" {
  value       = google_compute_address.internal.address
  description = "Private IP: Postgres :5432, PgBouncer :6432, ACA-Py admin :8001/:8011"
}

output "genesis_url" {
  value = "http://${google_compute_address.external.address}/genesis"
}

output "issuer_didcomm" {
  value = "http://${google_compute_address.external.address}:8000"
}

output "verifier_didcomm" {
  value = "http://${google_compute_address.external.address}:8010"
}

output "agent_url" {
  value       = google_cloud_run_v2_service.agent.uri
  description = "Set agent_base_url to this and re-apply so OID4VC issuer metadata is correct."
}

output "agent_image" {
  value = local.agent_image
}

output "dashday_url" {
  value       = google_cloud_run_v2_service.dashday.uri
  description = "Ops dashboard. APIs besides /api/health need Bearer DASH_TOKEN."
}

output "dash_image" {
  value = local.dash_image
}

output "idle_schedule" {
  value = var.enable_idle_schedule ? "weekdays 08:00-21:00 America/Sao_Paulo" : "disabled"
}

output "stop_when_idle" {
  value = "gcloud compute instances stop ${google_compute_instance.ledger.name} --zone ${var.zone} --project ${var.gcp_project_id}"
}

output "apply_gate" {
  value = "Do not apply until gcloud is on the Luure project and gcp_project_id is set. Current CLI project must not be Predix."
}
