-- ⚠️ NÃO CORRER NESTE PROJETO.
-- O esquema já foi criado via Prisma (ver tabela _prisma_migrations), logo
-- estas instruções falham com "already exists". Mantido apenas como referência
-- do esquema para uma base de dados vazia.
-- Para o projeto actual, correr 0003_adaptar_prisma_para_supabase_auth.sql.
--
-- Esquema de domínio da app (tudo excepto "utilizador", que é criada em
-- 0002_utilizador_auth.sql ligada ao Supabase Auth).

-- CreateEnum
CREATE TYPE "Gravidade" AS ENUM ('baixa', 'media', 'alta', 'critica');

-- CreateEnum
CREATE TYPE "EstadoOcorrencia" AS ENUM ('pendente', 'em_analise', 'resolvida', 'reaberta');

-- CreateEnum
CREATE TYPE "ModoClassificacao" AS ENUM ('gemini', 'tflite', 'manual');

-- CreateEnum
CREATE TYPE "ModoIA" AS ENUM ('gemini', 'tflite');

-- CreateEnum
CREATE TYPE "TipoFotografia" AS ENUM ('denuncia', 'verificacao');

-- CreateEnum
CREATE TYPE "ResultadoVerificacao" AS ENUM ('resolvida', 'nao_resolvida');

-- CreateEnum
CREATE TYPE "EstadoPonto" AS ENUM ('activo', 'inactivo');

-- CreateTable
CREATE TABLE "ocorrencia" (
    "id_ocorrencia" UUID NOT NULL,
    "id_utilizador" UUID NOT NULL,
    "id_categoria" UUID NOT NULL,
    "id_ponto_recolha" UUID,
    "id_classificacao" UUID,
    "descricao" TEXT,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "gravidade" "Gravidade" NOT NULL,
    "estado" "EstadoOcorrencia" NOT NULL DEFAULT 'pendente',
    "modo_classificacao" "ModoClassificacao" NOT NULL,
    "sincronizado" BOOLEAN NOT NULL DEFAULT false,
    "data_hora_registo" TIMESTAMP(3) NOT NULL,
    "data_hora_sync" TIMESTAMP(3),

    CONSTRAINT "ocorrencia_pkey" PRIMARY KEY ("id_ocorrencia")
);

-- CreateTable
CREATE TABLE "fotografia" (
    "id_fotografia" UUID NOT NULL,
    "id_ocorrencia" UUID NOT NULL,
    "caminho_ficheiro" TEXT NOT NULL,
    "tipo" "TipoFotografia" NOT NULL,
    "data_hora" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fotografia_pkey" PRIMARY KEY ("id_fotografia")
);

-- CreateTable
CREATE TABLE "categoria_residuo" (
    "id_categoria" UUID NOT NULL,
    "nome" VARCHAR(80) NOT NULL,
    "descricao" TEXT,
    "icone" VARCHAR(50),

    CONSTRAINT "categoria_residuo_pkey" PRIMARY KEY ("id_categoria")
);

-- CreateTable
CREATE TABLE "classificacao_ia" (
    "id_classificacao" UUID NOT NULL,
    "id_fotografia" UUID NOT NULL,
    "id_categoria" UUID NOT NULL,
    "confianca" DECIMAL(5,2) NOT NULL,
    "gravidade_sugerida" "Gravidade" NOT NULL,
    "modo" "ModoIA" NOT NULL,
    "tempo_resposta_ms" INTEGER NOT NULL,
    "data_hora" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "classificacao_ia_pkey" PRIMARY KEY ("id_classificacao")
);

-- CreateTable
CREATE TABLE "verificacao_resolucao" (
    "id_verificacao" UUID NOT NULL,
    "id_ocorrencia" UUID NOT NULL,
    "id_utilizador" UUID NOT NULL,
    "id_foto_verificacao" UUID NOT NULL,
    "resultado" "ResultadoVerificacao" NOT NULL,
    "confianca_comparacao" DECIMAL(5,2) NOT NULL,
    "observacoes" TEXT,
    "data_hora" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "verificacao_resolucao_pkey" PRIMARY KEY ("id_verificacao")
);

-- CreateTable
CREATE TABLE "ponto_recolha" (
    "id_ponto" UUID NOT NULL,
    "nome" VARCHAR(100) NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "bairro" VARCHAR(80) NOT NULL,
    "horario" VARCHAR(100),
    "estado" "EstadoPonto" NOT NULL DEFAULT 'activo',

    CONSTRAINT "ponto_recolha_pkey" PRIMARY KEY ("id_ponto")
);

-- CreateTable
CREATE TABLE "conversacao_xeni" (
    "id_mensagem" UUID NOT NULL,
    "id_utilizador" UUID NOT NULL,
    "mensagem_utilizador" TEXT NOT NULL,
    "resposta_xeni" TEXT NOT NULL,
    "modo" "ModoIA" NOT NULL,
    "data_hora" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "conversacao_xeni_pkey" PRIMARY KEY ("id_mensagem")
);

-- CreateTable
CREATE TABLE "notificacao" (
    "id_notificacao" UUID NOT NULL,
    "id_utilizador" UUID NOT NULL,
    "id_ocorrencia" UUID,
    "tipo" VARCHAR(50) NOT NULL,
    "mensagem" TEXT NOT NULL,
    "lida" BOOLEAN NOT NULL DEFAULT false,
    "data_hora" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "notificacao_pkey" PRIMARY KEY ("id_notificacao")
);

-- CreateIndex
CREATE UNIQUE INDEX "categoria_residuo_nome_key" ON "categoria_residuo"("nome");

-- CreateIndex
CREATE UNIQUE INDEX "classificacao_ia_id_fotografia_key" ON "classificacao_ia"("id_fotografia");

-- CreateIndex
CREATE UNIQUE INDEX "verificacao_resolucao_id_foto_verificacao_key" ON "verificacao_resolucao"("id_foto_verificacao");

-- AddForeignKey (as que não dependem de "utilizador", criada em 0002)
ALTER TABLE "ocorrencia" ADD CONSTRAINT "ocorrencia_id_categoria_fkey" FOREIGN KEY ("id_categoria") REFERENCES "categoria_residuo"("id_categoria") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ocorrencia" ADD CONSTRAINT "ocorrencia_id_ponto_recolha_fkey" FOREIGN KEY ("id_ponto_recolha") REFERENCES "ponto_recolha"("id_ponto") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "ocorrencia" ADD CONSTRAINT "ocorrencia_id_classificacao_fkey" FOREIGN KEY ("id_classificacao") REFERENCES "classificacao_ia"("id_classificacao") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "fotografia" ADD CONSTRAINT "fotografia_id_ocorrencia_fkey" FOREIGN KEY ("id_ocorrencia") REFERENCES "ocorrencia"("id_ocorrencia") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "classificacao_ia" ADD CONSTRAINT "classificacao_ia_id_fotografia_fkey" FOREIGN KEY ("id_fotografia") REFERENCES "fotografia"("id_fotografia") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "classificacao_ia" ADD CONSTRAINT "classificacao_ia_id_categoria_fkey" FOREIGN KEY ("id_categoria") REFERENCES "categoria_residuo"("id_categoria") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "verificacao_resolucao" ADD CONSTRAINT "verificacao_resolucao_id_ocorrencia_fkey" FOREIGN KEY ("id_ocorrencia") REFERENCES "ocorrencia"("id_ocorrencia") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "verificacao_resolucao" ADD CONSTRAINT "verificacao_resolucao_id_foto_verificacao_fkey" FOREIGN KEY ("id_foto_verificacao") REFERENCES "fotografia"("id_fotografia") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "notificacao" ADD CONSTRAINT "notificacao_id_ocorrencia_fkey" FOREIGN KEY ("id_ocorrencia") REFERENCES "ocorrencia"("id_ocorrencia") ON DELETE SET NULL ON UPDATE CASCADE;
