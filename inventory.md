# Inventário deployável — artefato × env × provider

| Artefato | lab | mvp | dev | test | prod | Provider(s) |
|----------|-----|-----|-----|------|------|-------------|
| `luure-site` | — | Vercel | Vercel | Vercel | Vercel | **vercel** |
| `luure-agent` | local | Vercel | Vercel | Vercel | Vercel | **vercel** (+ Postgres managed) |
| `luure-wallet` | EAS lab | EAS | EAS | EAS | stores | — (mobile) |
| `luure-frontends` | local/GCP | Vercel/GCP | Vercel | Vercel | Vercel/GCP | **vercel**, **gcp** |
| `luure-ledger` | Docker local | GCP VM | GCP VM | GCP VM | OCI/GCP | **gcp**, **oci** (alvo CloudSP) |
| Helm ACA-Py / von-network | — | GCP | GCP | GCP | OCI/GCP | **gcp**, **oci** |
| Analytics warehouse | — | — | — | — | stub | **redshift** (só se houver workload) |
| AWS workloads | — | — | — | — | stub | **aws** (só se houver workload) |

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
