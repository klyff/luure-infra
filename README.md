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

## VM dehydration (Luure migration)

After PoC frontends move from `voce-br-vm` to Vercel (`*.luure.com.br`), reduce the VM’s public surface and cost:

1. **Dehydrate on the VM** — stops host nginx and portal Docker services; keeps ledger (Indy), ACA-Py, Postgres, Redis, and API running:

   ```bash
   GCP_PROJECT_ID=sp-identity-trust ZONE=southamerica-east1-b \
     gcloud compute ssh voce-br-vm --zone="$ZONE" --project="$GCP_PROJECT_ID" \
     --tunnel-through-iap --command 'sudo bash -s' < scripts/dehydrate-vm.sh
   ```

   Use `DRY_RUN=1` piped the same way to preview actions.

2. **Resize from your workstation** — downsize to `e2-small` after dehydration:

   ```bash
   ./scripts/resize-vm.sh
   ```

   Override `TARGET_MACHINE_TYPE`, `VM_NAME`, or `GCP_PROJECT_ID` as needed. Requires IAM: `compute.instances.stop`, `setMachineType`, `start`.

3. **Validate** — run `validate-luure-migration.sh` in the `sovereignID.io` repo; ledger/API should still answer on the static IP (`34.39.174.212`) with `Host: ledger.smartecm.io` / `api.smartecm.io`.
