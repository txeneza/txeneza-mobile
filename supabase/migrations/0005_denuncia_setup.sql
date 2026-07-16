-- Pré-requisitos para o pipeline de denúncia na app móvel.
-- Correr no SQL Editor do Supabase. Idempotente: pode correr mais que uma vez.
--
-- As tabelas são do owner "postgres" (criadas via Prisma), por isso o painel web
-- que liga como postgres ignora o RLS abaixo e não é afetado (igual ao 0004).

-- 1. Categorias de resíduo (o formulário de denúncia lista estas opções).
INSERT INTO "categoria_residuo" (id_categoria, nome, descricao, icone) VALUES
    (gen_random_uuid(), 'Orgânico',    'Restos de comida, vegetação, matéria biodegradável', 'leaf'),
    (gen_random_uuid(), 'Plástico',    'Garrafas, sacos e embalagens de plástico',           'recycle'),
    (gen_random_uuid(), 'Entulho',     'Resíduos de construção e demolição',                 'hammer'),
    (gen_random_uuid(), 'Vidro',       'Garrafas e cacos de vidro',                          'wine'),
    (gen_random_uuid(), 'Metal',       'Latas e sucata metálica',                            'bolt'),
    (gen_random_uuid(), 'Papel',       'Papel, cartão e embalagens de cartão',               'file-text'),
    (gen_random_uuid(), 'Eletrónico',  'Equipamentos e componentes eletrónicos',             'cpu'),
    (gen_random_uuid(), 'Outro',       'Resíduo não classificado nas categorias acima',      'circle-help')
ON CONFLICT (nome) DO NOTHING;

-- 2. RLS: categoria_residuo — leitura pública (o formulário precisa da lista).
ALTER TABLE "categoria_residuo" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Todos veem categorias" ON "categoria_residuo";
CREATE POLICY "Todos veem categorias"
    ON "categoria_residuo" FOR SELECT
    USING (true);

-- 3. RLS: ocorrencia — todos os autenticados veem (mapa partilhado); cada um só
--    insere as suas próprias. A resolução (UPDATE) fica para o painel web.
ALTER TABLE "ocorrencia" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Autenticados veem ocorrencias" ON "ocorrencia";
CREATE POLICY "Autenticados veem ocorrencias"
    ON "ocorrencia" FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Utilizador cria as suas ocorrencias" ON "ocorrencia";
CREATE POLICY "Utilizador cria as suas ocorrencias"
    ON "ocorrencia" FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id_utilizador);

-- 4. RLS: fotografia — autenticados veem; autenticados inserem fotos das suas
--    próprias ocorrências.
ALTER TABLE "fotografia" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Autenticados veem fotografias" ON "fotografia";
CREATE POLICY "Autenticados veem fotografias"
    ON "fotografia" FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Utilizador cria fotografias das suas ocorrencias" ON "fotografia";
CREATE POLICY "Utilizador cria fotografias das suas ocorrencias"
    ON "fotografia" FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM "ocorrencia" o
            WHERE o.id_ocorrencia = fotografia.id_ocorrencia
              AND o.id_utilizador = auth.uid()
        )
    );

-- 5. Storage: bucket "denuncias" para as fotos. Leitura pública (as fotos são
--    mostradas no mapa a todos); upload apenas para autenticados.
INSERT INTO storage.buckets (id, name, public)
VALUES ('denuncias', 'denuncias', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Fotos de denuncia sao publicas" ON storage.objects;
CREATE POLICY "Fotos de denuncia sao publicas"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'denuncias');

DROP POLICY IF EXISTS "Autenticados enviam fotos de denuncia" ON storage.objects;
CREATE POLICY "Autenticados enviam fotos de denuncia"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'denuncias');
