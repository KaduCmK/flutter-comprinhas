# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the Flutter app, organized by feature: `auth/`, `home/`, `listas/`, `list_details/`, `mercado/`, and `global_cart/`. Shared code lives in `lib/core/` and `lib/shared/`. Entry points and app-wide setup are in `lib/main.dart`, `lib/app_theme.dart`, and `lib/core/config/`.

Tests live under `test/` and mirror feature paths where practical, for example `test/listas/presentation/bloc/listas_bloc_test.dart`. Backend-related assets are split between `supabase/functions/` and `supabase/migrations/`. Root-level `.ts` and `.sql` files are maintenance scripts; keep them isolated from app code.

## Supabase Backend Overview
O projeto Supabase ativo deste repositório é `dvjsrjuhslwtwhgceymg` (`Comprinhas`), na região `sa-east-1`, com URL `https://dvjsrjuhslwtwhgceymg.supabase.co` e Postgres 17. O estado consultado via MCP em 2026-03-27 está saudável (`ACTIVE_HEALTHY`).

### Estrutura do banco (`public`)
- `users`: espelho público de `auth.users`; guarda `email`, `phone`, `user_metadata` e `fcm_token`.
- `lists`: listas de compra; campos principais `name`, `owner_id`, `cart_mode`, `price_forecast_enabled`, `background_image`.
- `list_members`: relação N:N entre usuários e listas; PK composta (`list_id`, `user_id`).
- `list_items`: itens da lista; inclui `name`, `amount`, `unit_id`, `created_by_id`, `embedding`, `preco_sugerido` e `unidade_preco_sugerido`.
- `cart_items`: itens marcados no carrinho global por usuário.
- `purchase_history` e `purchase_history_items`: histórico de compras confirmadas.
- `units`: catálogo de unidades de medida usadas no parsing e cadastro manual.
- `mercados`: mercados identificados por `cnpj` único.
- `produtos`: catálogo de produtos por mercado; tem `embedding`, `valor_unitario` e `unidade_medida`, com unicidade em (`codigo`, `mercado_id`).
- `notas_fiscais`: notas importadas pelo usuário; `chave_acesso` é única.
- `itens_nota_fiscal`: itens persistidos por nota fiscal.
- `list_item_product_matches`: associa itens de lista a produtos similares retornados por embedding.

### Relacionamentos relevantes
- `users.id` referencia `auth.users.id` e é usado amplamente pelo schema público.
- `lists.owner_id` referencia tanto `auth.users.id` quanto `public.users.id`.
- `list_members`, `list_items`, `cart_items` e `purchase_history_items` encadeiam o domínio principal de colaboração em listas.
- `notas_fiscais -> itens_nota_fiscal -> produtos -> mercados` modela o domínio fiscal/preço.
- Há `ON DELETE CASCADE` nos vínculos principais de listas, itens, memberships e matches; em histórico, alguns vínculos usam `SET NULL`.

### Functions, RPCs e triggers
- `handle_public_user_sync()`:
  sincroniza `auth.users` com `public.users` em `INSERT` e `UPDATE`, copiando `email`, `phone` e `raw_user_meta_data`.
- `add_owner_as_member()`:
  trigger `AFTER INSERT` em `lists`; insere automaticamente o dono em `list_members`.
- `notify_new_list_item()`:
  trigger `AFTER INSERT` em `list_items`; chama a edge function `notify-on-new-item` e, quando `lists.price_forecast_enabled = true`, também chama `sugerir-preco` usando `pg_net`.
- `get_cart_items_for_list(list_id_param uuid)`:
  RPC que retorna itens do carrinho com payload JSON de usuário, item e lista.
- `match_product_by_embedding(query_embedding vector, match_threshold double precision, match_count integer)`:
  RPC SQL para busca vetorial em `produtos.embedding`, ordenada por similaridade.
- Trigger adicional:
  `handle_updated_at` em `produtos`, usando `moddatetime('updated_at')`.

### RLS e acesso
Todas as tabelas de negócio em `public` estão com RLS habilitado. Regras principais:
- `lists`:
  leitura para dono ou membro; criação pelo próprio usuário autenticado; update/delete apenas pelo dono.
- `list_members`:
  leitura liberada para autenticados; insert permite o próprio usuário entrar; delete permite remover a si mesmo.
- `list_items` e `cart_items`:
  acesso restrito a membros da lista relacionada.
- `notas_fiscais` e `itens_nota_fiscal`:
  acesso ao próprio usuário autenticado.
- `produtos`, `mercados` e `list_item_product_matches`:
  leitura para autenticados; escrita autenticada em mercados/produtos.
- `purchase_history`:
  política `ALL` vinculada a `auth.uid() = user_id`.
- Atenção:
  a policy atual de leitura em `purchase_history_items` só verifica a existência do `purchase_history` relacionado e merece revisão futura se o objetivo for isolar estritamente por usuário.

### Storage
- Bucket ativo: `list_backgrounds`.
- Configuração:
  público, limite de 5 MB, MIME types permitidos `image/jpeg`, `image/png`, `image/webp`.
- Policies em `storage.objects`:
  leitura pública do bucket `list_backgrounds`; upload para autenticados; update/delete apenas do próprio `owner`.

### Edge Functions em produção
Funções deployadas atualmente:
- `join-list`:
  adiciona o usuário autenticado em `list_members`; `verify_jwt = false`, mas a função valida manualmente o usuário via header `Authorization`.
- `notify-on-new-item`:
  envia push via Firebase Cloud Messaging para membros da lista quando um item é criado.
- `confirm-purchase`:
  consolida itens do carrinho em `purchase_history` e `purchase_history_items`, depois remove `cart_items` e `list_items`.
- `scrape-nfce`:
  raspa a SEFAZ-RJ via Browserless, persiste mercado/produtos/nota/itens e dispara `batch-embed`.
- `batch-embed`:
  gera embeddings pendentes para até 20 registros de `produtos` por execução.
- `sugerir-preco`:
  gera embedding para `list_items`, consulta `match_product_by_embedding`, persiste matches e preenche preço sugerido.
- `parse-item-nlp`:
  extrai `name`, `amount` e `unit_id` a partir de linguagem natural, usando Gemini ou fallback Warmind.

### Edge Functions versionadas no repositório
Diretórios locais presentes em `supabase/functions/`:
- `parse-item-nlp`
- `scrape-nfce`
- `sugerir-preco`

Funções que existem em produção mas não estão versionadas em `supabase/functions/` neste repositório:
- `join-list`
- `notify-on-new-item`
- `confirm-purchase`
- `batch-embed`

Ao mexer em backend, trate essa divergência como débito técnico: nem todo o runtime produtivo está representado no Git.

### Fluxo detalhado da feature de envio de NF-e (`scrape-nfce`)
Essa é a principal pipeline de ingestão de dados de mercado do app. O fluxo atual é:

1. Entrada pelo app
- O app chama `supabase.functions.invoke('scrape-nfce', body: {'chave_acesso': nfe})`.
- Ponto de entrada no Flutter: `lib/mercado/data/mercado_repository.dart`.
- O payload esperado pela edge function é apenas `chave_acesso`.

2. Autenticação da chamada
- A function recebe o `Authorization` do usuário logado e cria um client Supabase com `SUPABASE_ANON_KEY` e esse header.
- Em seguida chama `supabase.auth.getUser()` para validar a sessão.
- Se não houver usuário autenticado, a execução falha antes de qualquer scraping ou escrita no banco.
- Isso faz com que os `insert` e `upsert` respeitem as policies RLS do usuário chamador.

3. Abertura da página e scraping remoto
- A function não usa browser embutido no runtime do Supabase; ela terceiriza a navegação para o Browserless via `BROWSERLESS_API_KEY`.
- O alvo atual é a consulta pública da SEFAZ-RJ:
  `https://consultadfe.fazenda.rj.gov.br/consultaDFe/paginas/consultaChaveAcesso.faces`
- O código Puppeteer é enviado como string para o Browserless.
- O script:
  define user agent de desktop; abre a página com `waitUntil: 'domcontentloaded'`; localiza o campo `chaveAcesso`; digita a chave; clica no submit; aguarda `#tabResult`.
- Se `#tabResult` não aparecer:
  tenta ler mensagens de erro do DOM (`.rf-msgs-sum`, `.textoErro`, `.alert-danger`); se ainda assim não houver contexto suficiente, tira screenshot em base64 e falha com timeout.

4. Extração bruta de dados da página
- O `page.evaluate()` retorna um objeto bruto com quatro blocos:
- `mercado`:
  `nome`, `cnpj`, `endereco`.
- `produtos`:
  uma linha por item da nota, com `nome`, `codigo`, `qtd`, `unidade`, `valor_unitario`, `valor_total`.
- `totais`:
  `qtdItens` e `valorPagar`.
- `data_emissao`:
  extraída do bloco `#infos`, procurando o label `Emissão:`.

5. Normalização e limpeza (`cleanUpData`)
- O CNPJ é sanitizado para conter apenas dígitos.
- O endereço é normalizado removendo espaços duplicados.
- Cada item é transformado para estrutura numérica consistente:
  `quantidade` vira `float`, `valor_unitario` vira `float`, `valor_total_item` vira `float`.
- O código do produto é limpo removendo o wrapper textual `(Código: ...)`.
- A unidade textual é limpa removendo o prefixo `UN:`.
- Os totais são convertidos para `qtd_itens` (`int`) e `valor_total` (`float`).
- `parseDate()` converte a emissão de `dd/MM/yyyy HH:mm:ss` para ISO-like sem timezone explícito.

6. Persistência de mercado
- A tabela `mercados` recebe `upsert` por `cnpj`.
- Campos atualizados/inseridos:
  `cnpj`, `nome`, `endereco`.
- Efeito prático:
  o mesmo mercado é reutilizado entre múltiplas notas, e nome/endereço podem ser atualizados com o último valor extraído.

7. Persistência de produtos
- Antes do `upsert`, a function deduplica os itens da nota em memória por chave composta `${codigo}_${mercado_id}`.
- O `upsert` em `produtos` usa `onConflict: 'codigo, mercado_id'`.
- Campos persistidos:
  `codigo`, `nome`, `valor_unitario`, `unidade_medida`, `mercado_id`.
- Efeito prático:
  o catálogo de produtos é consolidado por mercado, e o último `valor_unitario` observado sobrescreve o anterior para aquele produto/mercado.
- O retorno do `upsert` (`id, codigo`) é usado para montar um mapa `codigo -> produto_id`, necessário para gravar os itens da nota.

8. Persistência da nota fiscal
- A tabela `notas_fiscais` recebe `insert`, não `upsert`.
- Campos gravados:
  `chave_acesso`, `data_de_emissao`, `valor_total`, `qtd_total_itens`, `mercado_id`, `user_id`.
- Como `chave_acesso` é única, o reenvio da mesma nota tende a falhar por constraint, o que hoje é tratado como erro fatal da operação.

9. Persistência dos itens da nota
- Para cada produto extraído, a function insere uma linha em `itens_nota_fiscal` com:
  `nota_fiscal_id`, `produto_id`, `quantidade`, `valor_total_item`.
- O `produto_id` vem do mapa retornado no passo de `upsert` dos produtos.
- Esse vínculo é a base do histórico de preços consultado pelo app.

10. Disparo da vetorização de catálogo
- Após gravar mercado, produtos, nota e itens, a function dispara `batch-embed` em modo fire-and-forget.
- Esse disparo é assíncrono e a resposta da `scrape-nfce` não espera a vetorização terminar.
- O header `Authorization` do usuário é repassado para a chamada da edge function.

### Como funciona a vetorização após o envio da nota
- Objetivo:
  enriquecer `produtos.embedding` para que itens de lista possam ser pareados por similaridade semântica depois.
- A edge function `batch-embed`:
  busca até 20 produtos em `produtos` com `embedding IS NULL`.
- Para cada produto encontrado:
  envia `produtos.nome` para a API Gemini Embeddings (`models/gemini-embedding-001`) com dimensionalidade `768`.
- Quando a geração dá certo:
  faz `update` em `produtos.embedding`.
- O processo é tolerante a falhas por item:
  usa `Promise.allSettled`, então alguns produtos podem ser vetorizados e outros não na mesma execução.
- Impacto funcional:
  a vetorização do catálogo de notas fiscais abastece a RPC `match_product_by_embedding`, usada depois pela edge function `sugerir-preco`.

### Relação entre NF-e, catálogo vetorizado e sugestão de preço
- `scrape-nfce` popula e atualiza `mercados`, `produtos`, `notas_fiscais` e `itens_nota_fiscal`.
- `batch-embed` transforma `produtos.nome` em embedding vetorial.
- Quando um usuário cria item de lista com previsão de preço ativada, `notify_new_list_item()` pode chamar `sugerir-preco`.
- `sugerir-preco` gera embedding do `list_item`, consulta `match_product_by_embedding(...)` contra `produtos.embedding`, grava matches em `list_item_product_matches` e define `preco_sugerido` no item da lista.
- Em termos de negócio:
  o envio de NF-e é a fonte primária que constrói a base de produtos e preços usada nas sugestões futuras.

### Tabelas afetadas diretamente pela `scrape-nfce`
- `mercados`:
  `upsert` por `cnpj`.
- `produtos`:
  `upsert` por (`codigo`, `mercado_id`).
- `notas_fiscais`:
  `insert` por envio de nota.
- `itens_nota_fiscal`:
  `insert` de todos os itens da nota.

### Tabelas afetadas indiretamente depois da ingestão
- `produtos.embedding`:
  preenchido pela `batch-embed`.
- `list_item_product_matches`:
  alimentado depois por `sugerir-preco`.
- `list_items.preco_sugerido` e `list_items.unidade_preco_sugerido`:
  preenchidos depois por `sugerir-preco`.

### Dependências externas da pipeline
- Browserless:
  executa o Puppeteer remoto para a consulta da SEFAZ.
- SEFAZ-RJ:
  origem dos dados HTML raspados.
- Gemini Embeddings API:
  usada pela `batch-embed` e também pela `sugerir-preco`.

### Propriedades operacionais e limitações atuais
- O scraping está acoplado ao HTML e seletores da página da SEFAZ-RJ; mudanças no markup podem quebrar a extração.
- A function consulta explicitamente a SEFAZ-RJ; não há abstração multi-UF no código atual.
- O envio da mesma `chave_acesso` provavelmente falha por unicidade em `notas_fiscais.chave_acesso`; não existe tratamento idempotente explícito.
- A vetorização é eventual, não transacional:
  a nota pode ser salva com sucesso mesmo se o `batch-embed` falhar depois.
- O `batch-embed` processa no máximo 20 produtos por execução; se o backlog crescer, múltiplas execuções serão necessárias.
- O catálogo `produtos` é atualizado pelo último valor observado em nota para o mesmo (`codigo`, `mercado_id`); isso simplifica o modelo, mas perde histórico de preço diretamente na linha do produto.
- O histórico real de preços fica preservado em `itens_nota_fiscal` + `notas_fiscais`, não em `produtos.valor_unitario`.
- A function não usa `service_role`; ela opera com o contexto do usuário e depende das policies atuais permitirem toda a cadeia de escrita.

### Authentication
- O app Flutter usa Supabase Auth com login Google via `signInWithIdToken` (`OAuthProvider.google`).
- Não há fluxo local de email/senha implementado no app atual.
- O schema `auth` está ativo com as tabelas padrão do Supabase (`users`, `sessions`, `identities`, MFA, OAuth etc.).
- O sincronismo entre `auth.users` e `public.users` depende da função `handle_public_user_sync()`.
- O app atual também atualiza `public.users.fcm_token` ao carregar as listas do usuário.

### Extensões e recursos de plataforma relevantes
- Extensões instaladas e em uso direto:
  `pg_net`, `vector`, `moddatetime`, `pgcrypto`, `uuid-ossp`, `supabase_vault`, `pg_graphql`.
- O domínio de recomendação/preço depende de embeddings com `vector(768)` e da RPC `match_product_by_embedding`.
- O domínio de automação assíncrona depende de `pg_net` para disparar edge functions a partir de trigger SQL.

### Migrations versionadas
- `20260323190728_add_unidade_to_produtos.sql`
- `20260324193407_add_background_image_to_lists.sql`

Essas migrations locais não representam todo o histórico do schema atual. Antes de alterar banco, confirme sempre o estado real via MCP.

## Build, Test, and Development Commands
Run the standard Flutter workflow from the repo root:

- `flutter pub get` installs Dart and Flutter dependencies.
- `flutter run` launches the app on the selected device or simulator.
- `flutter analyze` runs static analysis using `analysis_options.yaml`.
- `flutter test` runs the full unit and bloc test suite.
- `dart format lib test` formats source and test files before review.

Use `flutter test test/list_details/presentation/bloc/list_details_bloc_test.dart` when iterating on a single area.

## Coding Style & Naming Conventions
Follow Flutter defaults: 2-space indentation, trailing commas where formatter benefits, and `flutter_lints` as the baseline lint set. File names use `snake_case.dart`; classes, enums, and widgets use `PascalCase`; members use `camelCase`.

This codebase is feature-first and BLoC-heavy, so keep events, states, and blocs grouped by feature. Prefer small presentation components under each feature’s `presentation/components/` directory.

User-facing strings, developer-facing comments, and contributor-written guidance should default to Brazilian Portuguese (`pt-BR`). Prompts, labels, and naming context may also appear in Portuguese; preserve that language unless a task explicitly requires another locale.

## Identidade Visual Observada
As telas `Mercados` da home (`lib/mercado/presentation/mercado_screen.dart`) e `mercado_details_screen` (`lib/mercado/presentation/mercado_details_screen.dart`) compartilham uma linguagem visual baseada em Material 3 com superfícies tonais, forte uso de cards e contraste suave entre camadas. A paleta observada no app combina azul profundo como cor estrutural, superfícies azuladas claras e acentos quentes derivados do tema global em `lib/app_theme.dart`.

### Tela `Mercados` na home
- A composição é de dashboard compacto, com bloco de resumo no topo, carrossel horizontal de mercados e lista vertical de histórico.
- O summary card usa gradiente diagonal entre `primaryContainer` e `surfaceContainerHighest`, bordas amplas e tipografia de destaque para o valor do mês.
- Os cards de mercado priorizam leitura rápida: avatar circular com ícone, nome truncado, valor em cor primária e metadado secundário em corpo menor.
- O histórico de notas mantém a mesma família visual, mas com menos protagonismo, reforçando hierarquia entre resumo, navegação e lista cronológica.

### Tela `Mercado Details`
- A tela expande a mesma base visual, mas com tratamento mais premium e editorial.
- O hero card reaproveita o gradiente da home, adiciona bloco inicial com sombra, badge em formato pill para CNPJ e tiles de métricas encapsuladas.
- Quando `specialEffectsEnabled` está ativo, o hero card aplica brilho deslizante e leve resposta ao acelerômetro, reforçando sensação de superfície viva.
- O restante da tela segue o padrão de seções-cartão: mapa, seletor segmentado, lista de produtos e lista de notas, todos com cantos arredondados, contorno leve e boa separação interna.

### Tendências visuais e princípios de design
- Hierarquia por blocos: informação agrupada em módulos visuais claros, com resumo primeiro e detalhe depois.
- Escaneabilidade: uso recorrente de ícones, títulos curtos, metadados discretos e valores financeiros em destaque.
- Consistência de forma: cards grandes, raio alto, avatares e containers internos com cantos arredondados.
- Profundidade suave: gradientes, elevação baixa, sombras controladas e superfícies tonais em vez de contraste agressivo.
- Dados como foco: números de gasto, preço e quantidade recebem maior peso visual que descrições auxiliares.
- Interação guiada: estados de loading/erro são explícitos, o mapa controla bem conflito com scroll, e o segmented button simplifica a navegação de conteúdo.
- Progressão de sofisticação: a home é mais objetiva e navegacional; a tela de detalhes mantém a mesma identidade, mas com mais densidade visual e sensação de refinamento.

## Testing Guidelines
Use `flutter_test`, `bloc_test`, and `mocktail`. Name tests with the `_test.dart` suffix and mirror the production path when possible. Add or update tests for domain entities, bloc transitions, and bug fixes before opening a PR. No coverage threshold is configured, but new logic should not ship untested.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commit prefixes in Portuguese-friendly summaries, for example `feat: adicionar gráfico...` and `fix: resolver overflow...`. Keep the prefix lowercase (`feat`, `fix`, `refactor`, `test`, `chore`) and describe the observable change.

PRs should include a short description, linked issue or task when available, test evidence (`flutter analyze`, `flutter test`), and screenshots or recordings for UI changes.

## Configuration & Secrets
`.env` is loaded as a Flutter asset; do not commit real secrets or ad hoc local overrides. Review `lib/firebase_options.dart`, `firebase.json`, and `supabase/config.toml` before changing environment-specific behavior.
