-- RLS para "conversacao_xeni": cada utilizador só vê e grava as suas próprias
-- conversas com a assistente. A tabela é do owner postgres, por isso o painel
-- web (Prisma) não é afetado (mesmo raciocínio do 0004/0005).
--
-- Correr no SQL Editor. Idempotente.

ALTER TABLE "conversacao_xeni" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Utilizador vê as suas conversas" ON "conversacao_xeni";
CREATE POLICY "Utilizador vê as suas conversas"
    ON "conversacao_xeni" FOR SELECT
    TO authenticated
    USING (auth.uid() = id_utilizador);

DROP POLICY IF EXISTS "Utilizador grava as suas conversas" ON "conversacao_xeni";
CREATE POLICY "Utilizador grava as suas conversas"
    ON "conversacao_xeni" FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id_utilizador);
