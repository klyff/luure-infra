# Plano IaC OCI — lab-min (documentação)

**Público:** Tex, Klyff, Alex, Fagner  
**Data:** 2026-09-17  
**Repo:** `iac/luure-infra` (`klyff/luure-infra`)  
**Escopo desta rodada:** plano escrito. Sem Terraform, sem apply, sem tenancy.

Espelho do lab GCP vigente: **1 VM compose + agent serverless scale-to-zero**, Postgres na VM. Não é o PoC de 3 VMs / k3s e não é o BOM de Dedicated KMS.

Referência viva: [`../providers/gcp/lab-min/`](../providers/gcp/lab-min/) e [`GCP_LUURE_MIGRATION.md`](GCP_LUURE_MIGRATION.md). Compose e correções R1/R2/R5 (admin API key, senha no secret store, imagem por digest) são o contrato a espelhar.

---

## 1. Workload concreto

Paridade **lab-min**:

| Papel | Onde |
| --- | --- |
| Ledger Indy (4 nós) + tails + ACA-Py issuer/verifier | uma VM, Docker Compose |
| Postgres 16 + PgBouncer session + Redis | mesma VM, IP privado |
| `luure-agent-server` + `luure-dashday` | serverless `min=0` até `:5432` na VCN |
| URL pública do agent | **não** `agent.luure.com.br` (Vercel continua no ar) |

Isso satisfaz a regra do [`inventory.md`](../inventory.md): não inventar Terraform vazio — o workload já está nomeado. O Terraform em `providers/oci/` permanece stub até a próxima rodada.

CloudSP DC-B / HA 2 DC / HSM institucional ficam no canônico (`documentacao/sou-doc-canonica/docs/V1.1/infrastructure/CLOUDSP_TOPOLOGIA_REDE.md` no umbrella) e no plano de 120 dias. Este documento é lab.

---

## 2. Recorte (o que entra / o que não entra)

**Entra**

- Região `sa-saopaulo-1` (1 AD + 3 Fault Domains).
- Uma `VM.Standard.E5.Flex` **2 OCPU / 16 GB** — piso ≈ `e2-standard-4`. Disco Block Volume balanced (boot ~40 GB + dados ~50 GB), não Dense I/O.
- VCN `10.80.0.0/16`, subnet app `10.80.20.0/24`, IP interno `10.80.20.10`.
- Um IP público só para DIDComm / genesis / tails (nginx na VM). SSH via Bastion OCI, nunca `0.0.0.0/0`.
- OCI Vault **compartilhado** para senha Postgres, JWKs, `ACAPY_ADMIN_API_KEY`.
- Agent: Container Instances **ou** Functions com a imagem de `luure-agent-server`; acesso privado à VCN em `:5432`. Preferir o que permitir `min=0`.
- Budget alert no compartment. Schedule stop/start em horário de laboratório (espelho 21:00 / 08:00 `America/Sao_Paulo`).

**Não entra (nem no plano de Terraform futuro deste recorte)**

- 3 VMs, k3s, OKE.
- PostgreSQL gerenciado OCI, Redis gerenciado, LB pago, NAT pago.
- Dedicated KMS (SKU B99597) e Private Vault (B90328). O rollup `documentacao/entregaveis/POC_INFRA_MINIMA_OCI.md` no umbrella é custo do PoC 3 VMs + KMS (~88% da lista) — **não é o BOM deste lab**.
- Cutover de `agent.luure.com.br`.
- Publicar este repo em `luure-sou2-sp/luure-infra`.

---

## 3. Fases (texto; sem código nesta rodada)

### Fase 0 — Landing

- Tenancy e compartment Luure (`luure-lab`). IAM por grupo. Nada de chave de API em usuário solto.
- Bucket de state em Object Storage (criar só quando houver apply).
- Budget no compartment.
- Gate de apply: `tenancy_ocid` + `compartment_ocid` Luure preenchidos. Sem isso, só `terraform validate` na rodada futura.

### Fase 1 — Rede e secrets

- VCN dedicada (não a VCN default da tenancy).
- Vault compartilhado: `DATABASE_URL`, `ISSUER_JWK`, `GOVBR_JWK`, admin ACA-Py, wallet keys.
- Registry de imagens pinadas por digest (OCIR). Reusar os mesmos pins do compose GCP.

### Fase 2 — VM compose

- Uma VM E5 Flex. Startup: Docker, monta `/data`, sobe o compose de [`../providers/gcp/lab-min/compose/`](../providers/gcp/lab-min/compose/) — **reusar, não duplicar**.
- Admin ACA-Py e Postgres só na VCN. DIDComm/genesis no IP público.
- Critério de saída: genesis estável + quórum Indy 4/4.

### Fase 3 — Agent / dashday serverless

- `min=0` até o Postgres privado da VM.
- Flags: `OTP_EXPOSE_DEV_CODE=0`; `ALLOW_EXPO_REDIRECT` só em lab.
- URL do serviço OCI ≠ `agent.luure.com.br`.

Provider futuro: `hashicorp/oci`. State: Object Storage. Apply bloqueado até existir tenancy Luure.

---

## 4. Mapa GCP lab-min → OCI

| GCP lab-min | OCI lab-min (alvo) |
| --- | --- |
| `southamerica-east1-b` | `sa-saopaulo-1` (1 AD) |
| `e2-standard-4` | `VM.Standard.E5.Flex` 2 OCPU / 16 GB |
| `pd-balanced` 40+50 | Block Volume balanced 40+50 |
| VPC + subnet `10.80.20.0/24` | VCN + subnet iguais |
| IAP SSH | Bastion OCI |
| Secret Manager | Vault compartilhado |
| Artifact Registry | OCIR |
| Cloud Run `min=0` + Direct VPC | Functions ou Container Instances + VCN private access |
| Cloud SQL / GKE / Cloud NAT | não usar (PostgreSQL OCI / OKE / NAT gateway) |
| Budget `google_billing_budget` | budget no compartment |

---

## 5. Relação com outros docs

- Contrato de compose e segurança: [`../providers/gcp/lab-min/README.md`](../providers/gcp/lab-min/README.md).
- Migração GCP e Vercel no ar: [`GCP_LUURE_MIGRATION.md`](GCP_LUURE_MIGRATION.md).
- Alvo de programa DC-B (só link, não implementar): plano MVP 120 dias no umbrella, §2.
- Topologia CloudSP (só link): canônico V1.1. Não copiar ADR para este repo.

---

## Fora desta rodada

- PoC 3 VMs / k3s (`documentacao/entregaveis/diagrams/drawio/poc-infra-rede.yaml` no umbrella).
- Cutover DNS de `agent.luure.com.br` (Vercel continua no ar).
- OCI/AWS stubs, GKE, Cloud SQL, publicar `luure-infra` na org.
- Reset de `org/luure-gov` ou dos agentics dirty.
