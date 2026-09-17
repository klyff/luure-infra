-- Synthetic seed only. Same CPFs as mvp/luure-agent-server/prisma/seed.ts.
INSERT INTO "Servidor" (
  "id", "cpf", "nome", "matricula", "cargo", "orgao", "secretaria",
  "vinculoAtivo", "dataAdmissao", "fotoHash", "margemDisponivelCentavos",
  "nivelContaGovbr", "createdAt", "updatedAt"
) VALUES
  ('clabmin000000000000000001', '12345678901', 'Ana Paula Ferreira', 'SEFAZ-118234',
   'Agente Fiscal de Rendas', 'SEFAZ-SP', 'Secretaria da Fazenda e Planejamento',
   TRUE, '2012-03-15T00:00:00.000Z',
   '61d0c3bd8e81be95cb947de81829704826bea5b5f88b65a1a1293fee434bb070',
   285000, 'ouro', NOW(), NOW()),
  ('clabmin000000000000000002', '23456789012', 'Carlos Eduardo Souza', 'SEDUC-407551',
   'Professor de Educação Básica II', 'SEDUC-SP', 'Secretaria da Educação',
   TRUE, '2016-02-01T00:00:00.000Z',
   'a76a980cde2c8c7a9590a19baa468db8080acc4ce3382282e9e296555b1b1138',
   92000, 'ouro', NOW(), NOW()),
  ('clabmin000000000000000003', '34567890123', 'Mariana Oliveira Costa', 'SES-229876',
   'Enfermeira', 'SES-SP', 'Secretaria da Saúde',
   TRUE, '2019-08-12T00:00:00.000Z',
   '34bd9673ded2520187bc937968fa452bdc2a7c82b43b8684e45f1935e2290a47',
   38000, 'prata', NOW(), NOW()),
  ('clabmin000000000000000004', '45678901234', 'João Batista Ramos', 'PRODESP-88123',
   'Analista de Tecnologia da Informação', 'PRODESP', 'Secretaria de Gestão e Governo Digital',
   FALSE, '2008-11-03T00:00:00.000Z',
   '25f1fe03777889c5195280bf031419d5461a1d206d9a3e44134b7d7f08ea7b85',
   0, 'ouro', NOW(), NOW()),
  ('clabmin000000000000000005', '56789012345', 'Regina Célia Almeida', 'SPPREV-51439',
   'Técnico Previdenciário', 'SPPREV', 'São Paulo Previdência',
   TRUE, '2010-06-21T00:00:00.000Z',
   '4b67593ef3a49ef4b9bc7762392ba311f31d4243deb560250987e31b83e9c7b3',
   176500, 'ouro', NOW(), NOW())
ON CONFLICT ("cpf") DO NOTHING;
