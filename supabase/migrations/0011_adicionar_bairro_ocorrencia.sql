-- ============================================================================
-- 0011_adicionar_bairro_ocorrencia.sql
-- Adiciona a coluna "bairro" na tabela "ocorrencia" para registrar o local
-- real da denúncia (baseado em GPS/espacial), desvinculando do bairro de
-- residência do munícipe cadastrado em "utilizador".
-- ============================================================================

-- 1. Adiciona a coluna "bairro" à tabela de ocorrências
ALTER TABLE public.ocorrencia
ADD COLUMN IF NOT EXISTS "bairro" VARCHAR(80);

-- 2. Função de apoio no banco para calcular o bairro oficial da Beira mais próximo por coordenadas
CREATE OR REPLACE FUNCTION public.fn_calcular_bairro_beira(lat NUMERIC, lng NUMERIC)
RETURNS VARCHAR(80)
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    bairros JSONB := '[
        {"nome": "Alto da Manga", "lat": -19.7950, "lng": 34.8800},
        {"nome": "Alvalade", "lat": -19.8280, "lng": 34.8620},
        {"nome": "Central", "lat": -19.8350, "lng": 34.8390},
        {"nome": "Chaimite", "lat": -19.8342, "lng": 34.8362},
        {"nome": "Chingussura", "lat": -19.7480, "lng": 34.8720},
        {"nome": "Chipangara", "lat": -19.8322, "lng": 34.8445},
        {"nome": "Chota", "lat": -19.8200, "lng": 34.8250},
        {"nome": "Estoril", "lat": -19.8480, "lng": 34.8820},
        {"nome": "Esturro", "lat": -19.8250, "lng": 34.8560},
        {"nome": "Goto", "lat": -19.8312, "lng": 34.8442},
        {"nome": "Inhamizua", "lat": -19.7252, "lng": 34.8141},
        {"nome": "Macurungo", "lat": -19.8372, "lng": 34.8803},
        {"nome": "Macuti", "lat": -19.8435, "lng": 34.8928},
        {"nome": "Manga", "lat": -19.7890, "lng": 34.8750},
        {"nome": "Manga Mascarenha", "lat": -19.7950, "lng": 34.8900},
        {"nome": "Maraza", "lat": -19.8080, "lng": 34.8685},
        {"nome": "Matacuane", "lat": -19.8318, "lng": 34.8583},
        {"nome": "Matadouro", "lat": -19.8120, "lng": 34.8420},
        {"nome": "Matope", "lat": -19.7620, "lng": 34.8550},
        {"nome": "Muave", "lat": -19.7350, "lng": 34.8300},
        {"nome": "Mungassa", "lat": -19.7780, "lng": 34.8950},
        {"nome": "Munhava", "lat": -19.8150, "lng": 34.8450},
        {"nome": "Ndunda", "lat": -19.7520, "lng": 34.8380},
        {"nome": "Nhaconjo", "lat": -19.7688, "lng": 34.8690},
        {"nome": "Nhangau", "lat": -19.7050, "lng": 34.9150},
        {"nome": "Nhangoma", "lat": -19.7400, "lng": 34.8900},
        {"nome": "Pioneiros", "lat": -19.8260, "lng": 34.8480},
        {"nome": "Ponta Gêa", "lat": -19.8446, "lng": 34.8472},
        {"nome": "Tchondja", "lat": -19.7820, "lng": 34.8600},
        {"nome": "Vaz Manga", "lat": -19.7900, "lng": 34.8710},
        {"nome": "Vila Massane", "lat": -19.8180, "lng": 34.8590}
    ]'::JSONB;
    b RECORD;
    closest_name VARCHAR(80) := 'Beira';
    min_dist NUMERIC := 999999999;
    cur_dist NUMERIC;
    b_lat NUMERIC;
    b_lng NUMERIC;
BEGIN
    IF lat IS NULL OR lng IS NULL THEN
        RETURN 'Beira';
    END IF;

    FOR b IN SELECT * FROM jsonb_array_elements(bairros)
    LOOP
        b_lat := (b.value->>'lat')::NUMERIC;
        b_lng := (b.value->>'lng')::NUMERIC;
        cur_dist := ((lat - b_lat) * (lat - b_lat)) + ((lng - b_lng) * (lng - b_lng));
        IF cur_dist < min_dist THEN
            min_dist := cur_dist;
            closest_name := (b.value->>'nome');
        END IF;
    END LOOP;

    RETURN closest_name;
END;
$$;

-- 3. Atualiza retroativamente ocorrências existentes com o bairro calculado a partir de suas coordenadas
UPDATE public.ocorrencia
SET bairro = public.fn_calcular_bairro_beira(latitude, longitude)
WHERE bairro IS NULL OR bairro = '';

-- 4. Trigger BEFORE INSERT/UPDATE para garantir que ocorrências sem bairro tenham o bairro preenchido automaticamente
CREATE OR REPLACE FUNCTION public.fn_auto_preencher_bairro_ocorrencia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.bairro IS NULL OR TRIM(NEW.bairro) = '' THEN
        NEW.bairro := public.fn_calcular_bairro_beira(NEW.latitude, NEW.longitude);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_preencher_bairro_ocorrencia ON public.ocorrencia;
CREATE TRIGGER trg_auto_preencher_bairro_ocorrencia
    BEFORE INSERT OR UPDATE ON public.ocorrencia
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_auto_preencher_bairro_ocorrencia();

-- 5. Atualiza o trigger de notificação para administradores
CREATE OR REPLACE FUNCTION public.fn_notificar_admins_nova_ocorrencia()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    admin_rec RECORD;
    cat_nome TEXT;
    municipe_bairro TEXT;
    ocorrencia_bairro TEXT;
    msg_texto TEXT;
    gravidade_formatada TEXT;
BEGIN
    -- Busca o nome da categoria do resíduo
    SELECT nome INTO cat_nome
    FROM public.categoria_residuo
    WHERE id_categoria = NEW.id_categoria;
    
    IF cat_nome IS NULL THEN
        cat_nome := 'Resíduo';
    END IF;

    -- Busca o bairro onde o munícipe reside
    SELECT bairro INTO municipe_bairro
    FROM public.utilizador
    WHERE id_utilizador = NEW.id_utilizador;

    IF municipe_bairro IS NULL OR municipe_bairro = '' THEN
        municipe_bairro := 'Não especificado';
    END IF;

    -- Determina o bairro real da ocorrência
    ocorrencia_bairro := NEW.bairro;
    IF ocorrencia_bairro IS NULL OR ocorrencia_bairro = '' THEN
        ocorrencia_bairro := public.fn_calcular_bairro_beira(NEW.latitude, NEW.longitude);
    END IF;

    -- Formata a gravidade
    gravidade_formatada := INITCAP(COALESCE(NEW.gravidade::text, 'normal'));

    -- Mensagem informativa: exibe o bairro do foco e, caso divirja, informa a residência do munícipe
    IF ocorrencia_bairro <> municipe_bairro AND municipe_bairro <> 'Não especificado' THEN
        msg_texto := format('Nova denúncia de %s no bairro %s (Gravidade: %s) · Munícipe residente em: %s', cat_nome, ocorrencia_bairro, gravidade_formatada, municipe_bairro);
    ELSE
        msg_texto := format('Nova denúncia de %s no bairro %s (Gravidade: %s)', cat_nome, ocorrencia_bairro, gravidade_formatada);
    END IF;

    -- Insere uma notificação para cada administrador activo no sistema
    FOR admin_rec IN
        SELECT id_utilizador
        FROM public.utilizador
        WHERE tipo = 'administrador' AND estado = 'activo'
    LOOP
        INSERT INTO public.notificacao (
            id_notificacao,
            id_utilizador,
            id_ocorrencia,
            tipo,
            mensagem,
            lida,
            data_hora
        ) VALUES (
            gen_random_uuid(),
            admin_rec.id_utilizador,
            NEW.id_ocorrencia,
            'nova_denuncia',
            msg_texto,
            false,
            NOW()
        );
    END LOOP;

    RETURN NEW;
END;
$$;
