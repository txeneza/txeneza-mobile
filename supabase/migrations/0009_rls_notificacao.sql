-- RLS para "notificacao".
--
-- Contexto: exactamente o mesmo problema encontrado em "ponto_recolha"
-- (0004_rls_ponto_recolha.sql) — tabelas criadas pelo Prisma não ficam
-- automaticamente com políticas RLS configuradas, e sem elas a tabela ou
-- fica totalmente inacessível (se RLS estiver ligado sem políticas) ou
-- totalmente aberta a qualquer pessoa com a publishable key (se RLS
-- estiver desligado). Nenhum dos dois é aceitável para notificações
-- pessoais.
--
-- Resultado deste script:
--   - Cada utilizador só LÊ (SELECT) as suas próprias notificações.
--   - Cada utilizador só ACTUALIZA (UPDATE) as suas próprias notificações
--     (usado para marcar como lida).
--   - Sem política de INSERT: a criação de notificações é exclusiva do
--     backend web (Prisma com service role, que ignora RLS). O mobile
--     nunca cria notificações.
--   - Sem política de DELETE: ninguém apaga notificações a partir do
--     mobile.
--
-- Idempotente: pode ser corrido mais do que uma vez.

ALTER TABLE "notificacao" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Utilizador vê as suas notificações" ON "notificacao";
CREATE POLICY "Utilizador vê as suas notificações"
    ON "notificacao" FOR SELECT
    TO authenticated
    USING (auth.uid() = id_utilizador);

DROP POLICY IF EXISTS "Utilizador marca as suas notificações como lidas" ON "notificacao";
CREATE POLICY "Utilizador marca as suas notificações como lidas"
    ON "notificacao" FOR UPDATE
    TO authenticated
    USING (auth.uid() = id_utilizador)
    WITH CHECK (auth.uid() = id_utilizador);

-- Sem isto, a subscrição Realtime do mobile (passo 3 do plano de
-- notificações) nunca recebe eventos: por omissão, o Supabase só
-- transmite alterações de tabelas explicitamente adicionadas à
-- publicação "supabase_realtime". As políticas RLS acima continuam a
-- aplicar-se também aos eventos Realtime (cada utilizador só recebe
-- eventos das suas próprias notificações).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'notificacao'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE "notificacao";
    END IF;
END $$;
