-- RPC para o utilizador apagar a própria conta a partir da app.
--
-- O SDK cliente não pode apagar linhas de auth.users com a chave pública. Esta
-- função corre com privilégios do owner (SECURITY DEFINER) e limpa, por ordem
-- de dependências, todos os dados do utilizador antes de remover a conta Auth.
-- A remoção de auth.users faz cascade para "utilizador" (ver 0003).
--
-- Correr no SQL Editor. Idempotente (CREATE OR REPLACE).

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Sem sessão ativa.';
  END IF;

  -- Notificações do utilizador ou das suas ocorrências.
  DELETE FROM notificacao
  WHERE id_utilizador = uid
     OR id_ocorrencia IN (
       SELECT id_ocorrencia FROM ocorrencia WHERE id_utilizador = uid);

  -- Verificações de resolução (referem ocorrência e foto de verificação).
  DELETE FROM verificacao_resolucao
  WHERE id_utilizador = uid
     OR id_ocorrencia IN (
       SELECT id_ocorrencia FROM ocorrencia WHERE id_utilizador = uid);

  -- Classificações IA das fotos das suas ocorrências (a FK em ocorrencia
  -- é ON DELETE SET NULL, por isso as referências ficam nulas automaticamente).
  DELETE FROM classificacao_ia
  WHERE id_fotografia IN (
    SELECT id_fotografia FROM fotografia
    WHERE id_ocorrencia IN (
      SELECT id_ocorrencia FROM ocorrencia WHERE id_utilizador = uid));

  -- Fotografias das suas ocorrências.
  DELETE FROM fotografia
  WHERE id_ocorrencia IN (
    SELECT id_ocorrencia FROM ocorrencia WHERE id_utilizador = uid);

  -- Conversas com a assistente.
  DELETE FROM conversacao_xeni WHERE id_utilizador = uid;

  -- Ocorrências do utilizador.
  DELETE FROM ocorrencia WHERE id_utilizador = uid;

  -- Por fim, a conta Auth (cascade apaga a linha em "utilizador").
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
