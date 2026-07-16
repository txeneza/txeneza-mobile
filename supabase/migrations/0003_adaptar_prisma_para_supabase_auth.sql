-- Adapta o esquema já existente (criado via Prisma) ao Supabase Auth.
-- NÃO correr 0001_init_schema.sql nem 0002_utilizador_auth.sql: as tabelas e
-- os enums já foram criados pelo Prisma. Este script só faz o delta.
--
-- Idempotente: pode ser corrido mais do que uma vez sem erro.

-- 1. Remover a coluna de password.
--    O Supabase Auth já guarda o hash da password em auth.users e trata da
--    sessão e do login Google. Manter uma password aqui seria uma segunda
--    fonte de verdade, dessincronizada e insegura.
ALTER TABLE "utilizador" DROP COLUMN IF EXISTS "palavra_passe";

-- 2. Ligar o perfil à conta do Auth.
--    ON DELETE CASCADE: apagar a conta no Auth apaga o perfil.
ALTER TABLE "utilizador"
    DROP CONSTRAINT IF EXISTS "utilizador_id_utilizador_fkey";

ALTER TABLE "utilizador"
    ADD CONSTRAINT "utilizador_id_utilizador_fkey"
    FOREIGN KEY ("id_utilizador") REFERENCES auth.users(id) ON DELETE CASCADE;

-- 3. Row Level Security: cada utilizador só vê/edita o seu próprio perfil.
ALTER TABLE "utilizador" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Utilizador vê o próprio perfil" ON "utilizador";
CREATE POLICY "Utilizador vê o próprio perfil"
    ON "utilizador" FOR SELECT
    USING (auth.uid() = id_utilizador);

DROP POLICY IF EXISTS "Utilizador actualiza o próprio perfil" ON "utilizador";
CREATE POLICY "Utilizador actualiza o próprio perfil"
    ON "utilizador" FOR UPDATE
    USING (auth.uid() = id_utilizador)
    WITH CHECK (auth.uid() = id_utilizador);

-- 4. Criar automaticamente o perfil quando alguém se regista via Supabase Auth
--    (email/password ou Google), a partir dos metadados de signUp(data: {...})
--    ou dos devolvidos pelo provider OAuth.
--    SECURITY DEFINER: corre com privilégios do dono, logo ignora o RLS acima.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.utilizador (id_utilizador, nome, email, telefone, bairro)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'nome',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.email,
    NULLIF(NEW.raw_user_meta_data->>'telefone', ''),
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'bairro', ''), 'Não definido')
  )
  ON CONFLICT (id_utilizador) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Criar o perfil para contas que já existam no Auth mas ainda não o tenham
--    (ex.: o utilizador de teste que já lá está).
INSERT INTO public.utilizador (id_utilizador, nome, email, telefone, bairro)
SELECT
    a.id,
    COALESCE(
      a.raw_user_meta_data->>'nome',
      a.raw_user_meta_data->>'full_name',
      a.raw_user_meta_data->>'name',
      split_part(a.email, '@', 1)
    ),
    a.email,
    NULLIF(a.raw_user_meta_data->>'telefone', ''),
    COALESCE(NULLIF(a.raw_user_meta_data->>'bairro', ''), 'Não definido')
FROM auth.users a
WHERE NOT EXISTS (
    SELECT 1 FROM public.utilizador u WHERE u.id_utilizador = a.id
)
ON CONFLICT (id_utilizador) DO NOTHING;
