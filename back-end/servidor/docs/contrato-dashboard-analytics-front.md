# Contrato Front-End - Dashboard Analytics

## Visao Geral

Os endpoints abaixo alimentam a home analitica do dashboard.

- Todos os endpoints deste grupo usam metodo `GET`.
- Nenhum endpoint recebe body.
- A janela operacional atual e calculada automaticamente pelo backend.
- Dia operacional: `02:00` ate `02:00` do dia seguinte.
- Comparativo historico: ultimas 12 semanas, mesmo dia da semana.
- Indicadores consideram pedidos lancados e nao cancelados (`pedido.status <> 0`), sem exigir caixa vinculado ou faturamento final (`status = 6`).

Exemplo: se hoje for terca-feira as 15:30, o backend compara o periodo atual de terca, das 02:00 ate 15:30, contra tercas-feiras anteriores no mesmo intervalo de horario.

## Rotas

```http
GET /dashboard/home
GET /dashboard/today
GET /dashboard/hourly
GET /dashboard/channels
GET /dashboard/forecast
GET /dashboard/peak-hours
GET /dashboard/products
GET /dashboard/alerts
GET /dashboard/insights
GET /dashboard/opportunities
```

## GET /dashboard/home

Retorna todos os blocos da home em uma unica resposta.

```json
{
  "generatedAt": "2026-08-26T20:30:00",
  "today": {
    "generatedAt": "2026-08-26T20:30:00",
    "revenue": {
      "current": 1250.75,
      "expectedUntilNow": 980.5,
      "variationPercent": 27.56
    },
    "orders": {
      "current": 42,
      "expectedUntilNow": 35.5,
      "variationPercent": 18.31
    },
    "averageTicket": {
      "current": 29.78,
      "historical": 27.62,
      "variationPercent": 7.82
    },
    "cancellations": {
      "count": 2,
      "percent": 4.55
    },
    "customers": 31
  },
  "forecast": {
    "available": true,
    "revenue": {
      "estimated": 1850.25,
      "minimum": 1702.23,
      "maximum": 1998.27
    },
    "orders": {
      "estimated": 61.5,
      "minimum": 56.58,
      "maximum": 66.42
    },
    "averageTicket": {
      "estimated": 30.09
    },
    "confidence": 0.75,
    "method": "weighted_weekday_history_plus_current_day_pace"
  },
  "peakHours": {
    "overall": {
      "start": "19:00",
      "end": "20:00",
      "expectedOrders": 12.4
    },
    "channels": []
  },
  "hourly": [
    {
      "orders": 3,
      "revenue": 92.5,
      "expectedOrders": 2.8,
      "expectedRevenue": 80.25,
      "hour": "11:00"
    }
  ],
  "channels": [
    {
      "channel": "delivery",
      "orders": 18,
      "revenue": 650.4,
      "averageTicket": 36.13,
      "sharePercent": 52.0,
      "forecastAvailable": true,
      "estimatedOrdersToday": 28.4,
      "estimatedRevenueToday": 1010.75
    },
    {
      "channel": "pickup",
      "orders": 10,
      "revenue": 250.0,
      "averageTicket": 25.0,
      "sharePercent": 20.0,
      "forecastAvailable": true,
      "estimatedOrdersToday": 14.2,
      "estimatedRevenueToday": 355.0
    },
    {
      "channel": "table",
      "orders": 14,
      "revenue": 350.35,
      "averageTicket": 25.02,
      "sharePercent": 28.0,
      "forecastAvailable": true,
      "estimatedOrdersToday": 19.5,
      "estimatedRevenueToday": 487.89
    }
  ],
  "products": {
    "topToday": [
      {
        "productId": 123,
        "name": "X-Burger",
        "quantity": 15.0,
        "revenue": 375.0
      }
    ],
    "expectedToday": [],
    "aboveExpected": [],
    "belowExpected": []
  },
  "alerts": [
    {
      "type": "positive",
      "code": "REVENUE_ABOVE_EXPECTED",
      "title": "Faturamento acima do esperado",
      "category": "revenue",
      "message": "Faturamento esta 27.56% em relacao ao esperado para este horario.",
      "variationPercent": 27.56
    },
    {
      "type": "positive",
      "code": "CATEGORY_QUANTITY_ABOVE_EXPECTED",
      "title": "Categoria acima do esperado",
      "category": "product_category",
      "message": "A categoria Lanches vendeu 34.25% acima do esperado hoje para este horario.",
      "variationPercent": 34.25,
      "categoryId": 10,
      "categoryName": "Lanches",
      "currentQuantity": 47.0,
      "expectedQuantity": 35.01
    }
  ],
  "insights": [
    {
      "type": "performance",
      "priority": 80,
      "title": "Faturamento acima do esperado",
      "message": "Faturamento esta 27.56% em relacao ao esperado para este horario.",
      "metadata": {}
    }
  ],
  "opportunities": {
    "available": false,
    "reason": "OPPORTUNITIES_REQUIRE_DEEPER_PRODUCT_PAIR_AND_CUSTOMER_ANALYSIS",
    "items": []
  }
}
```

## GET /dashboard/today

Resumo do dia ate agora, comparado com o historico do mesmo dia da semana ate o mesmo horario.

```json
{
  "generatedAt": "2026-08-26T20:30:00",
  "revenue": {
    "current": 1250.75,
    "expectedUntilNow": 980.5,
    "variationPercent": 27.56
  },
  "orders": {
    "current": 42,
    "expectedUntilNow": 35.5,
    "variationPercent": 18.31
  },
  "averageTicket": {
    "current": 29.78,
    "historical": 27.62,
    "variationPercent": 7.82
  },
  "cancellations": {
    "count": 2,
    "percent": 4.55
  },
  "customers": 31
}
```

## GET /dashboard/hourly

Movimento por hora do dia operacional atual, com esperado por hora.

```json
[
  {
    "orders": 3,
    "revenue": 92.5,
    "expectedOrders": 2.8,
    "expectedRevenue": 80.25,
    "hour": "11:00"
  },
  {
    "orders": 8,
    "revenue": 240.0,
    "expectedOrders": 6.3,
    "expectedRevenue": 190.8,
    "hour": "12:00"
  }
]
```

Observacao: entram apenas horas que possuem venda atual ou historico esperado.

## GET /dashboard/channels

Distribuicao por canal.

```json
[
  {
    "channel": "delivery",
    "orders": 18,
    "revenue": 650.4,
    "averageTicket": 36.13,
    "sharePercent": 52.0,
    "forecastAvailable": true,
    "estimatedOrdersToday": 28.4,
    "estimatedRevenueToday": 1010.75
  },
  {
    "channel": "pickup",
    "orders": 10,
    "revenue": 250.0,
    "averageTicket": 25.0,
    "sharePercent": 20.0,
    "forecastAvailable": true,
    "estimatedOrdersToday": 14.2,
    "estimatedRevenueToday": 355.0
  },
  {
    "channel": "table",
    "orders": 14,
    "revenue": 350.35,
    "averageTicket": 25.02,
    "sharePercent": 28.0,
    "forecastAvailable": true,
    "estimatedOrdersToday": 19.5,
    "estimatedRevenueToday": 487.89
  }
]
```

Observacao: o endpoint sempre retorna os tres canais principais para permitir a frase/resumo "previsao de hoje: X delivery, Y retirada, Z mesa", mesmo quando algum canal ainda esta zerado.

Mapeamento atual:

```text
table: pedido com id_ficha > 0
delivery: pedido com codigo_cliente_endereco > 0
pickup: demais pedidos
```

## GET /dashboard/forecast

Previsao de fechamento do dia.

Quando existe historico suficiente:

```json
{
  "available": true,
  "revenue": {
    "estimated": 1850.25,
    "minimum": 1702.23,
    "maximum": 1998.27
  },
  "orders": {
    "estimated": 61.5,
    "minimum": 56.58,
    "maximum": 66.42
  },
  "averageTicket": {
    "estimated": 30.09
  },
  "confidence": 0.75,
  "method": "weighted_weekday_history_plus_current_day_pace"
}
```

Quando nao existe historico suficiente:

```json
{
  "available": false,
  "reason": "INSUFFICIENT_HISTORY"
}
```

## GET /dashboard/peak-hours

Melhor faixa horaria esperada, baseada no historico.

```json
{
  "overall": {
    "start": "19:00",
    "end": "20:00",
    "expectedOrders": 12.4
  },
  "channels": []
}
```

Quando nao houver dados:

```json
{
  "overall": {},
  "channels": []
}
```

## GET /dashboard/products

Produtos mais vendidos hoje.

```json
{
  "topToday": [
    {
      "productId": 123,
      "name": "X-Burger",
      "quantity": 15.0,
      "revenue": 375.0
    },
    {
      "productId": 456,
      "name": "Batata Frita",
      "quantity": 10.0,
      "revenue": 120.0
    }
  ],
  "expectedToday": [],
  "aboveExpected": [],
  "belowExpected": []
}
```

Observacao: atualmente apenas `topToday` esta implementado com dados reais. Os arrays `expectedToday`, `aboveExpected` e `belowExpected` sao placeholders.

## GET /dashboard/alerts

Alertas objetivos para interface.

```json
[
  {
    "type": "positive",
    "code": "REVENUE_ABOVE_EXPECTED",
    "title": "Faturamento acima do esperado",
    "category": "revenue",
    "message": "Faturamento esta 27.56% em relacao ao esperado para este horario.",
    "variationPercent": 27.56
  }
]
```

Codigos atuais:

```text
REVENUE_ABOVE_EXPECTED
REVENUE_BELOW_EXPECTED
CATEGORY_QUANTITY_ABOVE_EXPECTED
```

Regra atual: gera alerta quando a variacao absoluta do faturamento for maior ou igual a `12%`.
Tambem gera alerta positivo quando uma categoria vender `20%` ou mais em quantidade acima do historico esperado para o mesmo dia da semana e horario.

## GET /dashboard/insights

Insights derivados dos alertas.

```json
[
  {
    "type": "performance",
    "priority": 80,
    "title": "Faturamento acima do esperado",
    "message": "Faturamento esta 27.56% em relacao ao esperado para este horario.",
    "metadata": {}
  },
  {
    "type": "opportunity",
    "priority": 70,
    "title": "Produto relevante pausado",
    "message": "X-Burger esta pausado hoje, mas representou 12.45% do faturamento em dias equivalentes recentes.",
    "metadata": {
      "productId": 123,
      "productName": "X-Burger",
      "historicalRevenue": 1540.0,
      "historicalTotalRevenue": 12370.0,
      "revenueSharePercent": 12.45,
      "quantity": 88.0,
      "pausedToday": true
    }
  }
]
```

Oportunidade de produto pausado: entra quando `produto.ativo = 0` e o produto representou pelo menos `8%` do faturamento historico em dias equivalentes recentes.

## GET /dashboard/opportunities

Endpoint reservado para oportunidades comerciais.

```json
{
  "available": false,
  "reason": "OPPORTUNITIES_REQUIRE_DEEPER_PRODUCT_PAIR_AND_CUSTOMER_ANALYSIS",
  "items": []
}
```

## Dashboard De Venda Por Periodo

Endpoints existentes para consulta consolidada por periodo escolhido:

```http
GET  /v2/dashboard/venda/:dataini/:datafim
POST /v2/dashboard/venda/:dataini/:datafim
```

Formato dos parametros:

```text
:dataini = YYYY-MM-DD
:datafim = YYYY-MM-DD
```

Exemplos:

```http
GET /v2/dashboard/venda/2026-08-01/2026-08-26
POST /v2/dashboard/venda/2026-08-01/2026-08-26
```

Uso recomendado:

- Use `/dashboard/home` para a home analitica do dia atual.
- Use `/v2/dashboard/venda/:dataini/:datafim` para dashboard/relatorio consolidado por periodo escolhido.
