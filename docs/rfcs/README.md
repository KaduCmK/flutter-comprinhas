# RFCs

RFC significa `Request for Comments`.

Neste projeto, uma RFC é um documento curto usado para propor uma mudança importante antes da implementação. O objetivo não é burocracia. O objetivo é evitar decisões grandes tomadas só na memória ou espalhadas em conversas.

Use uma RFC quando a mudança:
- alterar arquitetura, modelagem ou integração importante
- envolver trade-offs relevantes
- afetar várias áreas do app ou backend
- precisar registrar por que uma opção foi escolhida e outras foram descartadas

Exemplos no contexto do Comprinhas:
- tornar o envio de NFC-e idempotente
- redefinir a estratégia de embeddings e sugestão de preço
- reconciliar functions em produção com as versionadas no Git
- criar uma visão orientada a produto com novas queries e contratos

Fluxo sugerido:
1. a ideia nasce no `docs/backlog.md`
2. se ganhar corpo, vira documento em `docs/ideas/`
3. se exigir decisão maior, vira RFC em `docs/rfcs/`
4. depois da decisão, a execução pode virar issue, tarefa ou implementação direta

Template:

```md
# RFC: Título

## Status
Proposta | Em discussão | Aceita | Rejeitada | Substituída

## Contexto

## Problema

## Objetivo

## Fora de escopo

## Opções consideradas

## Decisão proposta

## Impactos

## Plano inicial
```
