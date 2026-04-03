# Handoff: Fechar Compra Com NF

## Objetivo
Unificar os dois pilares do app:
- fechamento de compra via cesta, que gera `purchase_history`
- envio de NF, que alimenta `mercados`, `produtos`, `notas_fiscais` e `itens_nota_fiscal`

A feature nova permite fechar uma compra da cesta com uma NF vinculada, usar a nota para registrar o preço real dos itens conciliados e incluir itens extras da NF no histórico da compra.

## Decisões de produto já fechadas
- NF é opcional, mas incentivada.
- O fluxo começa pela cesta.
- CTA novo: `Fechar compra com nota`.
- Fluxo assistido em 2 etapas:
  1. capturar chave/QR da nota
  2. revisar matches antes de confirmar
- Uma compra com NF vale para uma única lista.
- Apenas quem fecha a compra faz o vínculo da NF.
- Se o processamento da NF falhar, a compra não fecha.
- Itens da cesta ausentes na NF:
  - não bloqueiam
  - são ignorados no fechamento com NF
- Itens da NF ausentes na cesta:
  - entram no histórico como extras da NF
- Só os casos ambíguos exigem revisão manual.
- O histórico da lista deve mostrar que a compra teve NF e abrir `nfe-details`.

## Estado anterior
Antes desta entrega:
- `confirm-purchase` e `scrape-nfce` eram fluxos separados.
- `purchase_history.nota_fiscal_id` já existia, mas não era usado.
- Não havia conciliação entre cesta e nota.
- Não havia tela de revisão.
- `confirm-purchase` existia em produção, mas não estava versionada localmente.

## Implementação atual

### Banco
Migration criada e aplicada:
- `supabase/migrations/20260327170000_add_purchase_history_invoice_reconciliation.sql`

Novos campos em `purchase_history_items`:
- `origin`
- `raw_unit_label`
- `nota_fiscal_item_id`
- `produto_id`
- `recorded_unit_price`
- `recorded_total_price`
- `matching_status`

Também foram adicionados:
- constraints para `origin` e `matching_status`
- FK para `itens_nota_fiscal`
- FK para `produtos`
- índices nos novos vínculos

### Edge functions
Helper compartilhado:
- `supabase/functions/_shared/nfce.ts`

Responsabilidades do helper:
- scraping e limpeza da NF
- persistência da nota
- embeddings para conciliação
- preview dos matches entre cesta e NF

Functions novas:
- `preview-purchase-with-nf`
- `confirm-purchase-with-nf`

Function refatorada:
- `scrape-nfce`

Deploy em produção já realizado:
- `scrape-nfce` v42
- `preview-purchase-with-nf` v1
- `confirm-purchase-with-nf` v1

### Backend: comportamento atual

#### `preview-purchase-with-nf`
Entrada:
- `cart_items_ids`
- `chave_acesso`

Faz:
- autentica usuário
- carrega cesta
- valida lista única
- raspa a NF
- calcula preview por embeddings

Retorna:
- resumo da NF
- itens da cesta com status `matched`, `ambiguous` ou `unmatched`
- candidatos para revisão manual
- itens extras da NF
- resumo quantitativo

#### `confirm-purchase-with-nf`
Entrada:
- `cart_items_ids`
- `chave_acesso`
- `manual_matches`

Faz:
- recarrega a cesta
- valida lista única
- reprocessa a NF
- recalcula preview
- persiste a NF
- cria `purchase_history` com `nota_fiscal_id`
- cria `purchase_history_items`
  - itens conciliados com `origin = cart`
  - itens extras com `origin = invoice_extra`
- salva `recorded_unit_price` e `recorded_total_price`
- remove da cesta e da lista apenas os itens efetivamente conciliados

Comportamento importante:
- itens da cesta sem match não entram no histórico e não são removidos
- itens extras da NF entram no histórico da compra
- NF duplicada é bloqueada na persistência por `chave_acesso`

### Flutter
Pontos principais:
- nova tela:
  - `lib/list_details/presentation/screens/close_purchase_with_nfe_screen.dart`
- scanner reutilizado:
  - `lib/mercado/presentation/enviar_nota_screen.dart`
- novo CTA na cesta:
  - `lib/list_details/presentation/components/cart_bottom_sheet.dart`
- nova rota:
  - `/list/:listId/close-with-nf`
- histórico adaptado para NF vinculada:
  - `lib/shared/entities/purchase_history.dart`
  - `lib/shared/entities/purchase_history_item.dart`
  - `lib/list_details/presentation/screens/list_history_screen.dart`
- modelos de preview:
  - `lib/list_details/domain/entities/purchase_with_nfe_preview.dart`
- repositórios atualizados:
  - `lib/listas/domain/listas_repository.dart`
  - `lib/listas/data/listas_repository_impl.dart`
  - `lib/mercado/data/mercado_repository.dart`

## O que foi validado
- `flutter analyze` passou.
- Migration aplicada com sucesso no Supabase.
- Deploy das edge functions concluído com sucesso no Supabase.

## O que falta fazer

### 1. Validação funcional real
Ainda falta testar o fluxo completo no app:
- abrir cesta
- entrar em `Fechar compra com nota`
- escanear NF real
- revisar item ambíguo
- confirmar compra
- conferir histórico da lista
- abrir NF vinculada

### 2. Observabilidade pós-deploy
Checar logs de:
- `preview-purchase-with-nf`
- `confirm-purchase-with-nf`
- `scrape-nfce`

Confirmar especialmente:
- runtime do helper compartilhado
- `BROWSERLESS_API_KEY`
- `GEMINI_API_KEY`
- latência do preview

### 3. Débitos técnicos ainda em aberto
- Não há transação forte no backend; pode existir persistência parcial se algo falhar no meio.
- Preview e confirmação raspam a NF duas vezes.
- Os thresholds de similaridade ainda precisam de calibração com notas reais.
- `confirm-purchase` antigo continua não versionado no repositório.
- Não foi concluída rodada final de testes automatizados deste fluxo.

## Arquivos principais
- `supabase/migrations/20260327170000_add_purchase_history_invoice_reconciliation.sql`
- `supabase/functions/_shared/nfce.ts`
- `supabase/functions/preview-purchase-with-nf/index.ts`
- `supabase/functions/confirm-purchase-with-nf/index.ts`
- `supabase/functions/scrape-nfce/index.ts`
- `lib/list_details/presentation/screens/close_purchase_with_nfe_screen.dart`
- `lib/list_details/domain/entities/purchase_with_nfe_preview.dart`
- `lib/shared/entities/purchase_history.dart`
- `lib/shared/entities/purchase_history_item.dart`
- `lib/list_details/presentation/screens/list_history_screen.dart`

## Resumo executivo
O repositório agora suporta fechar compra com NF vinculada, com preview de conciliação, revisão de ambiguidades, persistência de preço registrado por item e diferenciação de itens extras da NF no histórico.

Infra entregue:
- schema
- edge functions
- deploy
- integração Flutter

Próximo passo mais útil:
- validar o fluxo real ponta a ponta e observar logs das functions novas.
