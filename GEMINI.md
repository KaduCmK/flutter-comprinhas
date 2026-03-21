# Projeto Comprinhas - Diretrizes Gemini CLI

## Contexto Supabase
- **Project ID:** `dvjsrjuhslwtwhgceymg` (Comprinhas)
- **Organization ID:** `vjlrzcpyrqmssrgbdcsl`
- **Region:** `sa-east-1`

## Arquitetura de Dados (Backend)
- **Notas Fiscais:** Utilizar as tabelas `public.notas_fiscais`, `public.itens_nota_fiscal`, `public.mercados` e `public.produtos`.
- **Idioma das Colunas:** Priorizar nomes em português (ex: `nome`, `quantidade`, `valor_total`) conforme mapeado via MCP.
- **Embeddings:** A inteligência de similaridade reside na coluna `embedding` (tipo `vector`) das tabelas `produtos` e `list_items`, consolidada na tabela `list_item_product_matches`.

## Instruções de Uso do MCP
- Sempre utilize o `project_id: dvjsrjuhslwtwhgceymg` em chamadas de ferramentas Supabase MCP.
- Em caso de erro de permissão, validar se o `supabase login` foi realizado com um token de Admin/Owner.
