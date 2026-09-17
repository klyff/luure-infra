# Inventário deployável — artefato × env × provider

| Artefato | lab | mvp | dev | test | prod | Provider(s) |
|----------|-----|-----|------|------|------|-------------|
| `luure-site` | — | Vercel | Vercel | Vercel | Vercel | **vercel** |
| `luure-agent` | local | Vercel | Vercel | Vercel | Vercel | **vercel** (+ Postgres managed) |
| `luure-wallet` | EAS lab | EAS | EAS | EAS | stores | — (mobile) |
| `luure-frontends` | local/GCP | Vercel/GCP | Vercel | Vercel | Vercel/GCP | **vercel**, **gcp** |
| `luure-ledger` | Docker local | GCP VM | GCP VM | GCP VM | OCI/GCP | **gcp**, **oci** (alvo CloudSP) |
| Helm ACA-Py / von-network | — | GCP | GCP | GCP | OCI/GCP | **gcp**, **oci** |
| Analytics warehouse | — | — | — | — | stub | **redshift** (só se houver workload) |
| AWS workloads | plano lab-min | — | — | — | stub | **aws** — plano em `docs/AWS_IAC_PLAN.md`; Terraform stub |
| OCI lab-min | plano lab-min | — | — | — | alvo CloudSP | **oci** — plano em `docs/OCI_IAC_PLAN.md`; Terraform stub |

## Ambientes

| Env | Papel |
|-----|--------|
| `lab` | Experimentos P&D / PoC |
| `mvp` | Demo entregável atual |
| `dev` | Desenvolvimento contínuo |
| `test` | QA / integração |
| `prod` | Produção |

## Nota

Providers sem linha ativa na matriz permanecem como stub (`providers/*/README.md`) — não inventar Terraform vazio.

OCI e AWS: workload lab-min **planejado** (`docs/OCI_IAC_PLAN.md`, `docs/AWS_IAC_PLAN.md`). Terraform ainda stub. Apply só com tenancy/conta Luure.
