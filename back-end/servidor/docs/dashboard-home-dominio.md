# Dashboard/Home - mapeamento inicial do dominio

Este modulo usa as entidades ja existentes do backend, sem criar tabelas novas.

- Pedido principal: `pedido`
- Itens do pedido: `pedido_produtos`
- Produtos: `produto`
- Clientes: `cliente`
- Status cancelado: `pedido.status = 0`
- Pedido valido para indicadores operacionais: `pedido.status <> 0`
- Status finalizado/faturado: `pedido.status = 6`
- Pedidos do dia operacional: `pedido.codigo_pedido_dia > 0`
- Caixa/faturamento: os indicadores da home nao filtram por `pedido.id_caixa` e nao exigem `status = 6`; pedidos abertos entram enquanto nao estiverem cancelados.
- Data/hora do pedido: preferencialmente `pedido.data_hora`; historicamente tambem existem `data_pedido` e `hora_pedido`
- Janela operacional usada pelo dashboard atual: 02:00 do dia atual ate 02:00 do dia seguinte
- Valor bruto/subtotal: `pedido.valor_pedido`
- Desconto: `pedido.valor_desconto`
- Taxa de entrega: `pedido.valor_taxa_entrega`
- Valor real considerado em indicadores: `pedido.valor_total_pedido`
- Cliente identificado: `pedido.codigo_cliente > 0`
- Delivery: `pedido.id_ficha` vazio/zero e `pedido.codigo_cliente_endereco > 0`
- Retirada/balcao: `pedido.id_ficha` vazio/zero e `pedido.codigo_cliente_endereco = 0`
- Mesa/salao: `pedido.id_ficha > 0`
- Integracoes/marketplaces: `pedido.origem`, `pedido.partner`, `pedido.pedido_site` e rotinas iFood existentes no modulo `v2`

Decisoes da primeira versao:

- Comparativos historicos usam dias equivalentes por dia da semana, com ate 12 semanas anteriores e media ponderada com peso maior para semanas recentes.
- Outliers sao reduzidos por media aparada simples quando ha amostra suficiente.
- Previsoes sao heuristicas explicaveis: combinam media historica ponderada do dia equivalente com o ritmo atual ate o horario corrente.
- Quando houver pouco historico, endpoints preditivos retornam `available: false` ou confianca menor, em vez de inventar precisao.
- Ficha tecnica/insumos nao foi incluida nesta primeira versao porque exige validacao separada de confiabilidade do estoque/ficha tecnica.
