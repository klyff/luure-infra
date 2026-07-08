# luure-infra

Infrastructure for [Luure](https://luure.io): GCP VM (Terraform), ledger VM, Cloud Run deploy scripts, Helm charts, and Nginx reverse-proxy config.

## Layout

| Path | Purpose |
|------|---------|
| `terraform-vm/` | Single GCE VM + data disk + firewall (ledger stack host) |
| `ledger-vm/` | Indy von-network on a dedicated VM |
| `cloudrun/` | Public Cloud Run demo deploy (API + frontends) |
| `helm/` | Kubernetes charts (ACA-Py, postgres, redis, von-network, ingress) |
| `nginx/` | `*.smartecm.io` reverse proxy for the VM hub |

## Defaults

- Ledger / VM clone URL: `https://github.com/klyff/luure-ledger` (see `terraform-vm/variables.tf` `repo_url`)
- GCP project examples still use `sp-identity-trust` where wired to existing resources; override via env/`terraform.tfvars` as needed.

## Quick start

See comments in each subdirectory’s deploy scripts (`deploy-cloudrun.sh`, `deploy-ledger-vm.sh`, `terraform-vm/`).
