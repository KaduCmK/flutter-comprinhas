# Backlog

## Tela de detalhes do produto

### Objetivo
Criar uma visão orientada a produto, complementar à visão atual orientada a mercado.

### Motivação
Hoje a navegação parte do mercado e depois chega nas NF-es e nos itens. Falta uma perspectiva consolidada para responder perguntas como:
- qual foi a evolução de preço de um produto ao longo do tempo
- em quais mercados ele apareceu
- qual foi o último preço registrado
- qual mercado costuma oferecer melhor custo

### Escopo inicial sugerido
- tela acessada a partir de um produto listado no detalhe do mercado ou da NF-e
- cabeçalho com nome do produto e último preço conhecido
- linha do tempo de preços com data e mercado
- resumo com menor preço, maior preço e preço mais recente
- lista de mercados onde o produto já apareceu

### Dados prováveis
- `produtos`
- `itens_nota_fiscal`
- `notas_fiscais`
- `mercados`

### Observações
- a tela deve usar o histórico real em `itens_nota_fiscal + notas_fiscais`, não apenas `produtos.valor_unitario`
- pode virar a base para comparação entre mercados e sugestões de compra no futuro
