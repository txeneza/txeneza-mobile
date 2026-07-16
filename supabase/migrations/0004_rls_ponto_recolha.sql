-- RLS para "ponto_recolha".
--
-- Contexto: as tabelas criadas pelo Prisma ficaram com RLS DESLIGADO. No
-- Supabase isso significa que qualquer pessoa com a publishable key (que vai
-- dentro do APK, e portanto é pública) pode ler E escrever na tabela. Sem isto,
-- um terceiro consegue apagar todos os pontos de recolha.
--
-- Resultado deste script:
--   - Toda a gente pode LER os pontos (são informação pública, como paragens).
--   - Só administradores podem criar/alterar/apagar.
--
-- ATENÇÃO ao painel admin web:
--   - Se ele usa a service_role key, o RLS é ignorado e continua a funcionar.
--   - Se ele usa a anon/publishable key autenticado como um utilizador, esse
--     utilizador TEM de ter tipo = 'administrador' na tabela "utilizador",
--     senão deixa de conseguir escrever.
--
-- Idempotente: pode ser corrido mais do que uma vez.

ALTER TABLE "ponto_recolha" ENABLE ROW LEVEL SECURITY;

-- Leitura pública: a app móvel mostra os pontos no mapa a todos os utilizadores.
DROP POLICY IF EXISTS "Todos vêem pontos de recolha" ON "ponto_recolha";
CREATE POLICY "Todos vêem pontos de recolha"
    ON "ponto_recolha" FOR SELECT
    USING (true);

-- Escrita apenas para administradores (o painel web).
-- A subconsulta a "utilizador" respeita o RLS dessa tabela, mas a política
-- "Utilizador vê o próprio perfil" permite ler a própria linha, que é o que
-- aqui é preciso — não há recursão.
DROP POLICY IF EXISTS "Admins gerem pontos de recolha" ON "ponto_recolha";
CREATE POLICY "Admins gerem pontos de recolha"
    ON "ponto_recolha" FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM "utilizador" u
            WHERE u.id_utilizador = auth.uid()
              AND u.tipo = 'administrador'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "utilizador" u
            WHERE u.id_utilizador = auth.uid()
              AND u.tipo = 'administrador'
        )
    );
