# Backlog do Comprinhas

Este arquivo é a porta de entrada de ideias e oportunidades do projeto.

Use este fluxo:
- capture no `Inbox` em menos de 30 segundos
- refine depois, quando houver contexto suficiente
- mova para `Próximos candidatos` quando a ideia já estiver clara
- crie uma RFC em `docs/rfcs/` quando a decisão envolver arquitetura, produto ou trade-offs maiores

## Como registrar uma ideia no inbox

Copie este bloco:

```md
### Título curto
- contexto: onde a ideia surgiu
- problema: qual dor, risco ou oportunidade apareceu
- hipótese: o que pode resolver ou melhorar
- próxima ação: investigar | prototipar | implementar depois
- tipo: produto | ux | backend | dados | dívida técnica | observabilidade
```

## Inbox

Ideias capturadas rapidamente, ainda sem compromisso de execução.

### Validar autorização no fechamento de compra com NF
- contexto: surgiu na análise da feature que une fechamento de compra com escaneamento de nota fiscal
- problema: as edge functions usam `service_role` para carregar `cart_items`, mas hoje não validam explicitamente se o usuário autenticado pertence à lista e pode operar sobre aqueles itens
- hipótese: adicionar validação de membership e escopo dos itens antes de qualquer operação evita fechamento indevido de compra e endurece a segurança do fluxo
- próxima ação: investigar
- tipo: backend

### Exigir revisão explícita de matches ambíguos
- contexto: surgiu ao revisar o comportamento da tela de confirmação com nota fiscal
- problema: o frontend marca certos itens como revisão obrigatória, mas hoje é possível confirmar a compra sem escolher correspondência nem rejeitar explicitamente o item
- hipótese: exigir resolução explícita para matches ambíguos reduz confirmações silenciosas e melhora a confiabilidade do histórico
- próxima ação: investigar
- tipo: ux

### Congelar o snapshot entre preview e confirmação da NF
- contexto: surgiu na análise do fluxo ponta a ponta de revisão e confirmação da compra com nota
- problema: o usuário revisa um conjunto de itens e um matching, mas a confirmação recompõe `cart_items`, refaz scraping e recalcula matches, o que pode divergir do que foi revisado
- hipótese: confirmar em cima do snapshot aprovado pelo usuário evita discrepâncias entre preview e confirmação em listas colaborativas
- próxima ação: investigar
- tipo: backend

### Corrigir inconsistência entre item da lista e item da nota no histórico
- contexto: surgiu na revisão da persistência em `purchase_history_items`
- problema: o histórico atual salva nome e quantidade do item da lista, mas preço unitário e total do item correspondente da nota, podendo gerar registros semanticamente inconsistentes
- hipótese: separar melhor os dados de origem da lista e da nota ou redefinir o modelo de histórico melhora precisão e legibilidade da compra confirmada
- próxima ação: investigar
- tipo: dados

### Tornar atômico ou idempotente o fechamento de compra com NF
- contexto: surgiu ao analisar a ordem de persistência da nota, do histórico e da limpeza da cesta/lista
- problema: a nota fiscal pode ser gravada antes de o histórico e a remoção dos itens serem concluídos, o que deixa espaço para estados parciais e retries problemáticos
- hipótese: usar transação, compensação ou idempotência explícita reduz inconsistências operacionais nesse fluxo
- próxima ação: investigar
- tipo: backend

### Permitir correção manual também para itens sem match
- contexto: surgiu na análise da experiência de revisão de nota fiscal
- problema: hoje o usuário só consegue corrigir manualmente itens ambíguos; itens sem match automático ficam sem alternativa de reconciliação e podem virar extra na nota enquanto permanecem abertos na cesta
- hipótese: permitir seleção manual também para itens sem match automático reduz duplicidade semântica e melhora a taxa de reconciliação da compra
- próxima ação: investigar
- tipo: produto

### Idempotência no envio de NFC-e
- contexto: surgiu ao observar que o reenvio da mesma chave tende a falhar por unicidade em `notas_fiscais.chave_acesso`
- problema: o usuário pode reenviar uma nota já importada e receber erro fatal sem tratamento amigável
- hipótese: tratar reenvio como operação idempotente melhora UX e reduz retrabalho
- próxima ação: investigar
- tipo: backend

### Reconciliação das edge functions entre produção e Git
- contexto: parte das functions em produção não está versionada no repositório
- problema: o código-fonte local não representa todo o backend real, aumentando risco de manutenção
- hipótese: reconciliar inventário e versionamento reduz débito técnico e melhora previsibilidade
- próxima ação: investigar
- tipo: dívida técnica

### Histórico de preço orientado a produto
- contexto: surgiu durante evolução das telas de mercado e NF-e
- problema: hoje o app facilita análise por mercado, mas não por produto ao longo do tempo
- hipótese: uma visão orientada a produto melhora comparação de preço e percepção de valor para o usuário
- próxima ação: prototipar
- tipo: produto

## Próximos candidatos

Itens que já têm problema claro e algum direcionamento.

### Tela de detalhes do produto
- contexto: surgiu da limitação da navegação atual, que parte do mercado e só depois chega nas NF-es e itens
- problema: falta uma visão orientada a produto para responder histórico de preço, presença por mercado e melhor custo
- hipótese: uma tela própria de produto complementa a visão orientada a mercado e melhora análise de compra
- próxima ação: transformar em ideia refinada em `docs/ideas/tela-detalhes-produto.md`
- tipo: produto

## Em observação

Itens promissores, mas que ainda dependem de mais dados, validação ou timing.

## Dívida técnica

Problemas técnicos relevantes que merecem acompanhamento explícito.

### Divergência entre edge functions em produção e no repositório
- contexto: o runtime produtivo possui funções que não estão versionadas em `supabase/functions/`
- problema: manutenção e debugging ficam menos confiáveis porque o Git não representa todo o backend real
- hipótese: versionar ou documentar totalmente as functions reduz risco operacional e acelera mudanças futuras
- próxima ação: levantar inventário e decidir estratégia de reconciliação
- tipo: dívida técnica
