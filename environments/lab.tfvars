# Luure infra — environment: lab
# Stack vigente: providers/gcp/lab-min
# Copy the values you need into providers/gcp/lab-min/terraform.tfvars
# Apply is gated: gcp_project_id must be the Luure project, never Predix.

environment    = "lab"
project_name   = "luure"
gcp_project_id = ""
region         = "southamerica-east1"
zone           = "southamerica-east1-b"
machine_type   = "e2-standard-4"
enable_idle_schedule = true
# billing_account = ""
