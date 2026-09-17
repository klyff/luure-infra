# luure-infra

Infrastructure as Code for **Luure** — organizado por **provider** e parametrizado por **environment**.

## Layout

```text
luure-infra/
├── providers/
│   ├── gcp/lab-min/  # vigente — 1 VM compose + Cloud Run (menor custo funcional)
│   ├── gcp/          # terraform-vm / helm / cloudrun = legado
│   ├── oci/          # stub — plano docs/OCI_IAC_PLAN.md
│   ├── vercel/       # stub — site/agent/frontends
│   ├── aws/          # stub — plano docs/AWS_IAC_PLAN.md
│   └── redshift/     # stub
├── environments/     # lab|mvp|dev|test|prod.tfvars
├── modules/          # módulos compartilhados (futuro)
├── scripts/          # ops compartilhados (ex.: dehydrate-vm)
├── docs/             # GCP_LUURE_MIGRATION + planos OCI/AWS
└── inventory.md      # matriz artefato × env × provider
```

## Ambientes

`lab` · `mvp` · `dev` · `test` · `prod` — ver `environments/*.tfvars`.

## Defaults GCP (lab-min)

- Região: `southamerica-east1` / zona `southamerica-east1-b`
- Máquina: `e2-standard-4` (piso funcional; não `e2-medium`)
- Disco: `pd-balanced` 40 GB boot + 50 GB dados
- Agent: Cloud Run min=0, Postgres na VM, Direct VPC
- Apply **bloqueado** até existir `gcp_project_id` Luure

Planos OCI / AWS (só documentos; Terraform ainda stub): [`docs/OCI_IAC_PLAN.md`](docs/OCI_IAC_PLAN.md), [`docs/AWS_IAC_PLAN.md`](docs/AWS_IAC_PLAN.md). Apply só com tenancy/conta Luure.

## Quick start

```bash
cd providers/gcp/lab-min
terraform init
terraform validate
# terraform apply  # só depois do project_id Luure — ver README local
```

Matriz completa: [`inventory.md`](inventory.md). Legado GCP: [`providers/gcp/LEGACY.md`](providers/gcp/LEGACY.md).

## VM dehydration (migração Luure)

Scripts em `scripts/dehydrate-vm.sh` — ver histórico do README anterior / agentic IaC.
