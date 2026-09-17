# GCP lab-min — menor custo funcional

Uma AZ (`southamerica-east1-b`). **1 VM compose** (`e2-standard-4`, `pd-balanced`) + **Cloud Run** `luure-agent-server` com `min_instance_count = 0`. Sem GKE, Cloud SQL, Cloud NAT, Helm ou LB pago.

Postgres mora na VM (IP privado `10.80.20.10`). Cloud Run chega via Direct VPC egress. SSH só IAP.

## Apply gate

Não rode `terraform apply` até:

1. `gcloud` autenticado na conta Luure (não Predix / `starlit-torus-492916-d7`)
2. `gcp_project_id` preenchido (ex.: `luure-lab`) e billing ligado
3. JWKs gerados: `./scripts/generate-jwks.sh`

Até lá: `terraform fmt` e `terraform validate`.

Prova da migração (3 fases; para se a CLI estiver no Predix):

```bash
./tests/run-phases.sh
# Fase 1 landing+VM · Fase 2 ledger · Fase 3 agent+dashday
```

```bash
cd providers/gcp/lab-min
cp terraform.tfvars.example terraform.tfvars
# edite gcp_project_id
terraform init
terraform validate
# terraform apply   # só depois do gate
```

Depois do primeiro apply: build da imagem e `agent_base_url`:

```bash
PROJECT=luure-lab ./scripts/build-agent.sh
PROJECT=luure-lab ./scripts/build-dashday.sh
terraform apply -var=agent_base_url="$(terraform output -raw agent_url)"
./tests/run-phases.sh
```

## Custo

- Evitado: Cloud SQL, GKE, Cloud NAT (~USD 32/mês), LB, 3 VMs do PoC.
- Always-on: ~USD 170/mês (VM + disco). Schedule weekday 08:00–21:00 corta a noite.
- Parar na mão: `terraform output -raw stop_when_idle`

Default de máquina é o piso funcional da Lia (`e2-standard-4`). `e2-medium` cabe na variável mas não sobe 4 nós Indy + ACA-Py + Postgres com folga.

## Segurança lab (R1 / R2 / R5)

- ACA-Py admin com `ACAPY_ADMIN_API_KEY`; portas 8001/8011 só na VPC
- Senha Postgres no Secret Manager; `:5432` só `10.80.20.0/24`
- Imagens pinadas por digest (exceto `bitnami/pgbouncer:1.24.1`)
- `OTP_EXPOSE_DEV_CODE=0` no Cloud Run

## Legado

Não use este stack junto com `../terraform-vm` (voce-br) nem `../cloudrun/deploy-cloudrun.sh` (FastAPI antigo). Ver [`../LEGACY.md`](../LEGACY.md).
