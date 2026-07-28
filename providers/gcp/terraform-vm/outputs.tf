output "vm_ip" {
  value       = google_compute_address.voce_br_ip.address
  description = "IP externo estático da VM — aponte os A records de *.smartecm.io para cá"
}

output "vm_name" {
  value = google_compute_instance.voce_br_vm.name
}

output "zone" {
  value = var.zone
}

output "dns_records_needed" {
  description = "Registros A a criar (se DNS não for gerenciado pelo Terraform)"
  value = {
    for s in local.subdomains : "${s}.${var.dns_domain}" => google_compute_address.voce_br_ip.address
  }
}
