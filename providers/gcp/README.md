# Provider: GCP

Implementação atual de demonstração / MVP (southamerica-east1).

| Path | Purpose |
|------|---------|
| `terraform-vm/` | GCE VM + disco + firewall (host do ledger) |
| `ledger-vm/` | Indy von-network em VM dedicada |
| `cloudrun/` | Deploy demo Cloud Run (API + frontends) |
| `helm/` | Charts K8s (ACA-Py, postgres, redis, von-network) |
| `nginx/` | Reverse proxy do hub VM |

Scripts compartilhados: `../../scripts/`.
