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
