# Plano IaC AWS — lab-min (documentação)

**Público:** Tex, Klyff, Alex, Fagner  
**Data:** 2026-09-17  
**Repo:** `iac/luure-infra` (`klyff/luure-infra`)  
**Escopo desta rodada:** plano escrito. Sem Terraform, sem apply, sem conta AWS Luure.

Espelho do lab GCP vigente: **1 VM compose + agent serverless scale-to-zero**, Postgres na VM. Não é o PoC de 3 VMs / k3s e não é EKS/RDS.

Referência viva: [`../providers/gcp/lab-min/`](../providers/gcp/lab-min/) e [`GCP_LUURE_MIGRATION.md`](GCP_LUURE_MIGRATION.md). Compose e correções R1/R2/R5 (admin API key, senha no secret store, imagem por digest) são o contrato a espelhar.

---

## 1. Workload concreto

Paridade **lab-min** — o workload que tira AWS de “stub sem workload”:

| Papel | Onde |
| --- | --- |
| Ledger Indy (4 nós) + tails + ACA-Py issuer/verifier | uma EC2, Docker Compose |
| Postgres 16 + PgBouncer session + Redis | mesma EC2, IP privado |
| `luure-agent-server` + `luure-dashday` | serverless `min=0` até `:5432` na VPC |
| URL pública do agent | **não** `agent.luure.com.br` (Vercel continua no ar) |

O Terraform em `providers/aws/` permanece stub até a próxima rodada. Redshift / analytics continua stub à parte: [`../providers/redshift/README.md`](../providers/redshift/README.md).

CloudSP / multi-AZ de produção / CloudHSM institucional não são este lab. Packboard Nilo: offer code CloudHSM em `sa-east-1` ainda `PUBLIC PRICE NOT FOUND` — fora do BOM.

---

## 2. Recorte (o que entra / o que não entra)

**Entra**

- Região `sa-east-1`, **uma** AZ.
- Uma instância `m6i.xlarge` **ou** `t3.xlarge` (4 vCPU / 16 GB) — piso ≈ `e2-standard-4`. Discos `gp3` ~40 GB boot + ~50 GB dados.
- VPC dedicada `10.80.0.0/16`, subnet app `10.80.20.0/24`, IP interno `10.80.20.10`. Não usar a VPC `default`.
- Um EIP só para DIDComm / genesis / tails (nginx na VM). SSH só SSM Session Manager, nunca `0.0.0.0/0` em `:22`.
- AWS Secrets Manager para senha Postgres, JWKs, `ACAPY_ADMIN_API_KEY`.
- Agent: App Runner **ou**, se o custo não couber, Lambda Function URL / ECS Fargate com `desired=0`. Egress privado até o Postgres da EC2. Sem NAT Gateway se o EIP da VM bastar (paridade Direct VPC).
- Budget alert na conta. Instance Scheduler (stop 21:00 / start 08:00 `America/Sao_Paulo` nos dias úteis).

**Não entra (nem no plano de Terraform futuro deste recorte)**

- 3 VMs, k3s, EKS.
- RDS, ElastiCache, ALB/NLB pago, NAT Gateway (salvo se o egress privado do serverless exigir — decidir na rodada de Terraform, default é sem).
- CloudHSM.
- Cutover de `agent.luure.com.br`.
- Publicar este repo em `luure-sou2-sp/luure-infra`.

---

## 3. Fases (texto; sem código nesta rodada)

### Fase 0 — Landing

- Conta AWS Luure (não conta pessoal, não Predix). IAM Identity Center por grupo.
- Bucket S3 + lock de state (criar só quando houver apply).
- AWS Budgets na conta.
- Gate de apply: `aws_account_id` Luure preenchido. Sem isso, só `terraform validate` na rodada futura.

### Fase 1 — Rede e secrets

- VPC dedicada, uma subnet pública mínima (EIP da VM) + caminho privado para o serverless.
- Secrets Manager: `DATABASE_URL`, `ISSUER_JWK`, `GOVBR_JWK`, admin ACA-Py, wallet keys.
- ECR com imagens pinadas por digest. Reusar os mesmos pins do compose GCP.

### Fase 2 — VM compose

- Uma EC2. Startup: Docker, monta `/data`, sobe o compose de [`../providers/gcp/lab-min/compose/`](../providers/gcp/lab-min/compose/) — **reusar, não duplicar**.
- Admin ACA-Py e Postgres só na VPC. DIDComm/genesis no EIP.
- Critério de saída: genesis estável + quórum Indy 4/4.

### Fase 3 — Agent / dashday serverless

- `min=0` (ou `desired=0`) até o Postgres privado da EC2.
- Flags: `OTP_EXPOSE_DEV_CODE=0`; `ALLOW_EXPO_REDIRECT` só em lab.
- URL do serviço AWS ≠ `agent.luure.com.br`.

Provider futuro: `hashicorp/aws`. State: S3 + lock. Apply bloqueado até existir conta Luure.

---

## 4. Mapa GCP lab-min → AWS

| GCP lab-min | AWS lab-min (alvo) |
| --- | --- |
| `southamerica-east1-b` | `sa-east-1` / uma AZ |
| `e2-standard-4` | `m6i.xlarge` ou `t3.xlarge` |
| `pd-balanced` 40+50 | `gp3` 40+50 |
| VPC + subnet `10.80.20.0/24` | VPC dedicada + subnet iguais |
| IAP SSH | SSM Session Manager |
| Secret Manager | Secrets Manager |
| Artifact Registry | ECR |
| Cloud Run `min=0` + Direct VPC | App Runner ou Lambda URL / Fargate `desired=0` + egress privado |
| Cloud SQL / GKE / Cloud NAT | não usar (RDS / EKS / NAT Gateway) |
| Budget `google_billing_budget` | AWS Budgets |

---

## 5. Relação com outros docs

- Contrato de compose e segurança: [`../providers/gcp/lab-min/README.md`](../providers/gcp/lab-min/README.md).
- Migração GCP e Vercel no ar: [`GCP_LUURE_MIGRATION.md`](GCP_LUURE_MIGRATION.md).
- Plano irmão OCI: [`OCI_IAC_PLAN.md`](OCI_IAC_PLAN.md).
- Ranking / preço AWS do packboard (Nilo) é evidência comercial no umbrella — não fecha SKU neste lab.

---

## Fora desta rodada

- PoC 3 VMs / k3s (`documentacao/entregaveis/diagrams/drawio/poc-infra-rede.yaml` no umbrella).
- Cutover DNS de `agent.luure.com.br` (Vercel continua no ar).
- OCI/AWS stubs, GKE, Cloud SQL, publicar `luure-infra` na org.
- Reset de `org/luure-gov` ou dos agentics dirty.
