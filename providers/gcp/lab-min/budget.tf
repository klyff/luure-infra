resource "google_billing_budget" "lab" {
  count           = var.billing_account != "" && var.gcp_project_id != "" ? 1 : 0
  billing_account = var.billing_account
  display_name    = "${local.name}-min"

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  budget_filter {
    projects = ["projects/${var.gcp_project_id}"]
  }
}
