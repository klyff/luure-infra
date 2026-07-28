# luure-infra

Infrastructure as Code for **Luure** — organizado por **provider** e parametrizado por **environment**.

## Layout

```text
luure-infra/
├── providers/
│   ├── gcp/          # implementação atual (VM, Helm, Cloud Run, nginx)
│   ├── oci/          # stub — alvo CloudSP
│   ├── vercel/       # stub — site/agent/frontends
│   ├── aws/          # stub
│   └── redshift/     # stub
├── environments/     # lab|mvp|dev|test|prod.tfvars
├── modules/          # módulos compartilhados (futuro)
├── scripts/          # ops compartilhados (ex.: dehydrate-vm)
└── inventory.md      # matriz artefato × env × provider
```

## Ambientes

`lab` · `mvp` · `dev` · `test` · `prod` — ver `environments/*.tfvars`.

## Defaults GCP

- Região típica: `southamerica-east1`
- Ledger clone: `https://github.com/klyff/luure-ledger`
- Paths migrados: o que era `terraform-vm/`, `helm/`, etc. agora está em `providers/gcp/`.

## Quick start

```bash
# Exemplo VM ledger (GCP)
cd providers/gcp/terraform-vm
# ver variables.tf / README local
```

Matriz completa: [`inventory.md`](inventory.md).

## VM dehydration (migração Luure)

Scripts em `scripts/dehydrate-vm.sh` — ver histórico do README anterior / agentic IaC.
