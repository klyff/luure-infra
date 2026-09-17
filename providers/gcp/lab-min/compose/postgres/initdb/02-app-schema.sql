-- Prisma migration 20260708162519_init (copied for first-boot initdb).
CREATE TABLE "Servidor" (
    "id" TEXT NOT NULL,
    "cpf" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "matricula" TEXT NOT NULL,
    "cargo" TEXT NOT NULL,
    "orgao" TEXT NOT NULL,
    "secretaria" TEXT NOT NULL,
    "vinculoAtivo" BOOLEAN NOT NULL,
    "dataAdmissao" TIMESTAMP(3) NOT NULL,
    "fotoHash" TEXT NOT NULL,
    "margemDisponivelCentavos" INTEGER NOT NULL,
    "nivelContaGovbr" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Servidor_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "CredentialOffer" (
    "id" TEXT NOT NULL,
    "preAuthorizedCode" TEXT NOT NULL,
    "txCode" TEXT NOT NULL,
    "vct" TEXT NOT NULL,
    "servidorCpf" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CredentialOffer_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "CredentialIssued" (
    "id" TEXT NOT NULL,
    "vct" TEXT NOT NULL,
    "servidorCpf" TEXT NOT NULL,
    "statusListIndex" INTEGER NOT NULL,
    "revoked" BOOLEAN NOT NULL DEFAULT false,
    "sdJwtHash" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CredentialIssued_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "EphemeralEntry" (
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "EphemeralEntry_pkey" PRIMARY KEY ("key")
);

CREATE TABLE "VerificationSession" (
    "id" TEXT NOT NULL,
    "nonce" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "vct" TEXT NOT NULL,
    "requestedClaims" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "resultClaims" TEXT,
    "reason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "VerificationSession_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "Servidor_cpf_key" ON "Servidor"("cpf");
CREATE UNIQUE INDEX "Servidor_matricula_key" ON "Servidor"("matricula");
CREATE INDEX "Servidor_matricula_idx" ON "Servidor"("matricula");
CREATE INDEX "Servidor_orgao_idx" ON "Servidor"("orgao");
CREATE UNIQUE INDEX "CredentialOffer_preAuthorizedCode_key" ON "CredentialOffer"("preAuthorizedCode");
CREATE INDEX "CredentialOffer_servidorCpf_idx" ON "CredentialOffer"("servidorCpf");
CREATE INDEX "CredentialOffer_status_idx" ON "CredentialOffer"("status");
CREATE UNIQUE INDEX "CredentialIssued_statusListIndex_key" ON "CredentialIssued"("statusListIndex");
CREATE INDEX "CredentialIssued_servidorCpf_idx" ON "CredentialIssued"("servidorCpf");
CREATE INDEX "CredentialIssued_vct_idx" ON "CredentialIssued"("vct");
CREATE INDEX "EphemeralEntry_expiresAt_idx" ON "EphemeralEntry"("expiresAt");
CREATE UNIQUE INDEX "VerificationSession_state_key" ON "VerificationSession"("state");
CREATE INDEX "VerificationSession_status_idx" ON "VerificationSession"("status");
