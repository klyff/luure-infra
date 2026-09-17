variable "gcp_project_id" {
  type        = string
  default     = ""
  description = "GCP project (ex.: luure-lab). Required for apply. Do not use the Predix project."
}

variable "billing_account" {
  type        = string
  default     = ""
  description = "Billing account ID for a budget alert. Empty skips google_billing_budget."
}

variable "budget_usd" {
  type        = number
  default     = 80
  description = "Monthly budget alert in USD for this project."
}

variable "environment" {
  type    = string
  default = "lab"
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
  type        = string
  default     = "e2-standard-4"
  description = "Functional floor is e2-standard-4 (4 vCPU / 16 GB). e2-medium is too small for 4 Indy nodes + ACA-Py + Postgres."
}

variable "boot_disk_gb" {
  type    = number
  default = 40
}

variable "data_disk_gb" {
  type    = number
  default = 50
}

variable "network_cidr" {
  type    = string
  default = "10.80.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.80.20.0/24"
}

variable "internal_ip" {
  type    = string
  default = "10.80.20.10"
}

variable "enable_idle_schedule" {
  type        = bool
  default     = true
  description = "Stop 21:00 / start 08:00 America/Sao_Paulo on weekdays."
}

variable "allow_expo_redirect" {
  type        = bool
  default     = true
  description = "ALLOW_EXPO_REDIRECT=1 on Cloud Run (lab wallet via Expo Go)."
}

variable "agent_image" {
  type        = string
  default     = ""
  description = "Artifact Registry image for luure-agent-server. Empty uses the local AR path :lab."
}

variable "dash_image" {
  type        = string
  default     = ""
  description = "Artifact Registry image for luure-dashday. Empty uses the local AR path :lab."
}

variable "agent_base_url" {
  type        = string
  default     = ""
  description = "Public BASE_URL / ISSUER_ID. Set after first apply from terraform output agent_url."
}

variable "issuer_jwk" {
  type        = string
  default     = ""
  sensitive   = true
  description = "ES256 private JWK JSON. Empty reads .secrets/issuer.jwk.json or a pending placeholder."
}

variable "govbr_jwk" {
  type        = string
  default     = ""
  sensitive   = true
  description = "ES256 private JWK JSON for the gov.br mock. Empty reads .secrets/govbr.jwk.json or a pending placeholder."
}

variable "db_user" {
  type    = string
  default = "luure"
}

variable "db_app_name" {
  type    = string
  default = "app_data"
}
