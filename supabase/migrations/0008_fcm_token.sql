-- Adiciona a coluna fcm_token à tabela "utilizador", para guardar o token
-- de registo do Firebase Cloud Messaging do dispositivo atual do
-- utilizador. Usado pelo backend (painel admin / função servidor) para
-- enviar notificações push direcionadas (ex: mudança de estado de uma
-- ocorrência) mesmo com a app fechada.
--
-- Limitação conhecida: uma coluna por utilizador só suporta um dispositivo
-- de cada vez (o token mais recente substitui o anterior). Se no futuro for
-- necessário suportar múltiplos dispositivos por conta em simultâneo, isto
-- deve migrar para uma tabela "dispositivo_utilizador" (id_utilizador,
-- fcm_token, plataforma, atualizado_em) em vez desta coluna única.
--
-- Correr no SQL Editor. Idempotente.

ALTER TABLE "utilizador" ADD COLUMN IF NOT EXISTS "fcm_token" TEXT;

-- A política "Utilizador actualiza o próprio perfil" (criada em
-- 0002/0003, FOR UPDATE USING/WITH CHECK auth.uid() = id_utilizador) já
-- cobre esta nova coluna automaticamente — não é preciso política adicional.
