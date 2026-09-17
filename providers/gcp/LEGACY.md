# GCP — caminhos legado

O stack atual de laboratório é [`lab-min/`](lab-min/). Os paths abaixo **não** devem receber apply novo. Não apagados: ainda documentam a demo antiga e podem ser lidos no cutover.

| Path | Por que é legado |
|------|------------------|
| `terraform-vm/` | VM `voce-br`, `pd-ssd` 200 GB, VPC `default`, DNS `smartecm.io` |
| `ledger-vm/deploy-ledger-vm.sh` | `e2-medium` sem Postgres; admin público; compose sqlite |
| `cloudrun/deploy-cloudrun.sh` | FastAPI / portais Vite, `MOCK_ACAPY`, projeto `sp-identity-trust` |
| `helm/` | Charts k8s. Lab-min usa compose na VM, não GKE |

Quando o projeto Luure existir, o único `terraform apply` previsto é em `lab-min/`.
