# Workflow de gestão do projeto

Este repositório adota um fluxo leve para não perder ideias no meio do desenvolvimento.

## Funil

### 1. Captura

Durante implementação, registre qualquer ideia no `docs/backlog.md`, na seção `Inbox`.

A captura deve ser rápida. Se estiver escrevendo demais, você já saiu da fase de captura.

### 2. Refinamento

Quando uma ideia parecer recorrente ou importante, mova para `docs/ideas/` e complete o contexto.

### 3. Decisão

Se houver impacto amplo ou trade-offs relevantes, abra uma RFC em `docs/rfcs/`.

### 4. Execução

Depois de refinada ou decidida, a ideia pode virar issue, tarefa de sprint ou implementação direta.

## Critérios simples de priorização

Dê nota de 1 a 3 para cada item:
- impacto no usuário
- urgência
- confiança na solução
- custo de implementação

Uma ideia com alto impacto, alta urgência e custo baixo normalmente deve subir no funil.

## Regra prática

- `backlog.md`: captura e triagem
- `ideas/`: pensamento estruturado
- `rfcs/`: decisões maiores

Se um item não justificar um documento próprio, ele ainda não precisa sair do backlog.
