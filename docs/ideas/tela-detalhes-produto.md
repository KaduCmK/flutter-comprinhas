# Tela de detalhes do produto

## Contexto

Hoje a navegação do app está centrada em mercado e nota fiscal. Isso funciona para inspeção de compras passadas, mas não responde bem perguntas orientadas a produto.

## Problema

Falta uma visão consolidada para entender:
- evolução de preço ao longo do tempo
- último preço registrado
- mercados em que o produto apareceu
- melhor custo observado

## Hipótese

Uma tela de detalhes do produto, alimentada pelo histórico real de `itens_nota_fiscal` e `notas_fiscais`, melhora análise de compra e cria base para futuras recomendações.

## Impacto esperado

- melhora da descoberta de preço no app
- reutilização do histórico fiscal já persistido
- base para comparação entre mercados e futuras sugestões

## Restrições

- não usar apenas `produtos.valor_unitario`, porque esse campo representa o último valor observado e não o histórico completo
- a modelagem precisa considerar o relacionamento entre `produtos`, `itens_nota_fiscal`, `notas_fiscais` e `mercados`

## Próxima ação

Definir escopo inicial de UI e listar queries ou RPCs necessárias para montar a tela.

## Referências

- `docs/backlog.md`
- `public.produtos`
- `public.itens_nota_fiscal`
- `public.notas_fiscais`
- `public.mercados`
