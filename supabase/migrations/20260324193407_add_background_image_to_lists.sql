-- Adiciona a coluna background_image na tabela lists
ALTER TABLE "public"."lists" ADD COLUMN IF NOT EXISTS "background_image" text;

-- Cria o bucket publico list_backgrounds (caso não exista)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'list_backgrounds',
    'list_backgrounds',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET 
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Políticas de segurança para o bucket (RLS)
-- Qualquer pessoa pode visualizar as imagens (leitura pública)
CREATE POLICY "Imagens de fundo de listas são de leitura pública"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'list_backgrounds');

-- Apenas usuários autenticados podem fazer upload de imagens
CREATE POLICY "Usuários autenticados podem fazer upload de imagens"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'list_backgrounds');

-- Usuários podem atualizar e deletar suas próprias imagens
CREATE POLICY "Usuários podem atualizar suas próprias imagens"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'list_backgrounds' AND auth.uid() = owner);

CREATE POLICY "Usuários podem deletar suas próprias imagens"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'list_backgrounds' AND auth.uid() = owner);
