# Inventário deployável — artefato × env × provider

| Artefato | lab | mvp | dev | test | prod | Provider(s) |
|----------|-----|-----|------|------|------|-------------|
| `luure-site` | — | Vercel | Vercel | Vercel | Vercel | **vercel** |
| `luure-agent-server` | GCP Cloud Run (lab-min) | Vercel (atual) | Vercel | Vercel | Vercel | **gcp** (lab), **vercel** |
| `luure-wallet` | EAS lab | EAS | EAS | EAS | stores | — (mobile) |
| `luure-frontends` | local/GCP | Vercel/GCP | Vercel | Vercel | Vercel/GCP | **vercel**, **gcp** |
| `luure-ledger` | GCP VM compose (lab-min) | GCP VM | GCP VM | GCP VM | OCI/GCP | **gcp**, **oci** (alvo CloudSP) |
| `luure-dashday` | GCP Cloud Run (lab-min) | — | — | — | — | **gcp** |
| Helm ACA-Py / von-network | — | legado | legado | legado | OCI/GCP | **gcp** Helm é legado; lab usa compose |
| Analytics warehouse | — | — | — | — | stub | **redshift** (só se houver workload) |
| AWS workloads | plano lab-min | — | — | — | stub | **aws** — plano em `docs/AWS_IAC_PLAN.md`; Terraform stub |
| OCI lab-min | plano lab-min | — | — | — | alvo CloudSP | **oci** — plano em `docs/OCI_IAC_PLAN.md`; Terraform stub |

## Ambientes

| Env | Papel |
|-----|--------|
| `lab` | Experimentos P&D / PoC — stack **lab-min** (`providers/gcp/lab-min`) |
| `mvp` | Demo entregável atual (agent ainda na Vercel até paridade) |
| `dev` | Desenvolvimento contínuo |
| `test` | QA / integração |
| `prod` | Produção |

## Nota

Providers sem linha ativa na matriz permanecem como stub (`providers/*/README.md`) — não inventar Terraform vazio.

Lab GCP: uma VM `e2-standard-4` + Cloud Run scale-to-zero. Sem Cloud SQL, GKE, Cloud NAT. Apply só com `gcp_project_id` Luure — ver `providers/gcp/lab-min/README.md`.

OCI e AWS: workload lab-min **planejado** (`docs/OCI_IAC_PLAN.md`, `docs/AWS_IAC_PLAN.md`). Terraform ainda stub. Apply só com tenancy/conta Luure.
