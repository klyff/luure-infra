# Provider: GCP

Lab funcional de menor custo: [`lab-min/`](lab-min/) — 1 VM compose (`e2-standard-4`, `pd-balanced`) + Cloud Run `luure-agent-server` (`min=0`). Região `southamerica-east1`.

| Path | Purpose |
|------|---------|
| `lab-min/` | **Vigente.** Terraform do lab (VPC, VM, secrets, Cloud Run, budget) |
| `terraform-vm/` | **Legado.** VM voce-br / pd-ssd / VPC default |
| `ledger-vm/` | **Legado.** Script e2-medium sem Postgres |
| `cloudrun/` | **Legado.** FastAPI + portais Vite |
| `helm/` | **Legado.** Charts k8s |
| `nginx/` | Reverse proxy histórico do hub VM |

Caminhos legado: [`LEGACY.md`](LEGACY.md). Scripts compartilhados: `../../scripts/`.
