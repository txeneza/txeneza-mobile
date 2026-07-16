-- ⚠️ NÃO CORRER NESTE PROJETO.
-- A tabela "utilizador" já existe (criada via Prisma). Este script assume uma
-- base vazia e falha com "already exists". Substituído, para o projeto actual,
-- por 0003_adaptar_prisma_para_supabase_auth.sql, que faz apenas o delta.
--
-- Tabela "utilizador" como perfil ligado ao Supabase Auth (auth.users).
-- Sem coluna de password: o Supabase Auth já trata do hash da password,
-- da sessão e do login com Google — duplicar isso aqui seria redundante e inseguro.

-- CreateEnum
CREATE TYPE "TipoUtilizador" AS ENUM ('morador', 'administrador');

-- CreateEnum
CREATE TYPE "EstadoConta" AS ENUM ('activo', 'inactivo');

-- CreateTable
CREATE TABLE "utilizador" (
    "id_utilizador" UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    "nome" VARCHAR(100) NOT NULL,
    "email" VARCHAR(150) NOT NULL,
    "telefone" VARCHAR(20),
    "bairro" VARCHAR(80) NOT NULL,
    "tipo" "TipoUtilizador" NOT NULL DEFAULT 'morador',
    "foto_perfil" TEXT,
    "data_registo" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estado" "EstadoConta" NOT NULL DEFAULT 'activo',

    CONSTRAINT "utilizador_pkey" PRIMARY KEY ("id_utilizador")
);

-- CreateIndex
CREATE UNIQUE INDEX "utilizador_email_key" ON "utilizador"("email");

-- CreateIndex
CREATE UNIQUE INDEX "utilizador_telefone_key" ON "utilizador"("telefone");

-- AddForeignKey (colunas que referenciam "utilizador" nas tabelas de domínio)
ALTER TABLE "ocorrencia" ADD CONSTRAINT "ocorrencia_id_utilizador_fkey" FOREIGN KEY ("id_utilizador") REFERENCES "utilizador"("id_utilizador") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "verificacao_resolucao" ADD CONSTRAINT "verificacao_resolucao_id_utilizador_fkey" FOREIGN KEY ("id_utilizador") REFERENCES "utilizador"("id_utilizador") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "conversacao_xeni" ADD CONSTRAINT "conversacao_xeni_id_utilizador_fkey" FOREIGN KEY ("id_utilizador") REFERENCES "utilizador"("id_utilizador") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "notificacao" ADD CONSTRAINT "notificacao_id_utilizador_fkey" FOREIGN KEY ("id_utilizador") REFERENCES "utilizador"("id_utilizador") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Row Level Security: cada utilizador só vê/edita o seu próprio perfil.
ALTER TABLE "utilizador" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Utilizador vê o próprio perfil"
    ON "utilizador" FOR SELECT
    USING (auth.uid() = id_utilizador);

CREATE POLICY "Utilizador actualiza o próprio perfil"
    ON "utilizador" FOR UPDATE
    USING (auth.uid() = id_utilizador)
    WITH CHECK (auth.uid() = id_utilizador);

-- Cria automaticamente a linha em "utilizador" quando alguém se regista
-- via Supabase Auth (email/password ou Google), usando os metadados
-- passados em signUp(data: {...}) ou devolvidos pelo provider OAuth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.utilizador (id_utilizador, nome, email, telefone, bairro)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nome', NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    NULLIF(NEW.raw_user_meta_data->>'telefone', ''),
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'bairro', ''), 'Não definido')
  )
  ON CONFLICT (id_utilizador) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
