-- Migration to add unidade_medida to produtos table and list_items table
ALTER TABLE public.produtos
ADD COLUMN unidade_medida text;

ALTER TABLE public.list_items
ADD COLUMN unidade_preco_sugerido text;
