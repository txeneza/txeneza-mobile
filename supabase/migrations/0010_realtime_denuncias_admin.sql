-- ============================================================================
-- 0010_realtime_denuncias_admin.sql
-- Habilita Realtime e Notificações automáticas para Administradores
-- quando uma nova denúncia/ocorrência é criada via mobile ou sincronização.
-- ============================================================================

-- 1. Garante que "ocorrencia" e "notificacao" estão na publicação supabase_realtime
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'ocorrencia'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE "ocorrencia";
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'notificacao'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE "notificacao";
    END IF;
END $$;

-- 2. Função disparada após inserção de uma nova ocorrência
CREATE OR REPLACE FUNCTION public.fn_notificar_admins_nova_ocorrencia()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    admin_rec RECORD;
    cat_nome TEXT;
    municipe_bairro TEXT;
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

    -- Busca o bairro do munícipe que denunciou
    SELECT bairro INTO municipe_bairro
    FROM public.utilizador
    WHERE id_utilizador = NEW.id_utilizador;

    IF municipe_bairro IS NULL OR municipe_bairro = '' THEN
        municipe_bairro := 'Não especificado';
    END IF;

    -- Formata a gravidade
    gravidade_formatada := INITCAP(COALESCE(NEW.gravidade::text, 'normal'));

    -- Mensagem amigável para os administradores
    msg_texto := format('🚨 Nova denúncia de %s no bairro %s (Gravidade: %s)', cat_nome, municipe_bairro, gravidade_formatada);

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

-- 3. Trigger na tabela "ocorrencia"
DROP TRIGGER IF EXISTS trg_notificar_admins_nova_ocorrencia ON public.ocorrencia;
CREATE TRIGGER trg_notificar_admins_nova_ocorrencia
    AFTER INSERT ON public.ocorrencia
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_notificar_admins_nova_ocorrencia();
