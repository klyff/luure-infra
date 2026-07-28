variable "project_id" {
  type        = string
  description = "ID do projeto GCP (ex.: sp-identity-trust)"
}

variable "region" {
  type    = string
  default = "southamerica-east1"
}

variable "zone" {
  type    = string
  default = "southamerica-east1-b"
}

variable "machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "data_disk_gb" {
  type    = number
  default = 200
}

variable "service_account_email" {
  type        = string
  default     = null
  description = "SA da VM (default: SA padrão do Compute)"
}

variable "repo_url" {
  type    = string
  default = "https://github.com/klyff/luure-ledger"
}

# ── DNS opcional ──
variable "manage_dns" {
  type        = bool
  default     = false
  description = "Se true, cria registros A no Cloud DNS (requer zona existente)"
}

variable "dns_domain" {
  type    = string
  default = "smartecm.io"
}

variable "dns_zone_name" {
  type        = string
  default     = ""
  description = "Nome da managed zone Cloud DNS de smartecm.io (se manage_dns=true)"
}
