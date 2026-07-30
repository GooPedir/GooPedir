# Plano de Performance do Frontend

Origem: `C:\Users\goopedir\Downloads\Plano de Performance do Backend Delphi-Horse.docx`

Este arquivo separa os itens da segunda etapa que dependem do frontend React. O restante do plano permanece como trabalho de backend Delphi/Horse.

## 1. Corrigir chamadas duplicadas no React

### Problema

Os logs mostram varias requisicoes identicas muito proximas umas das outras, incluindo:

- `/v2/parametros`
- `/v1/caixa/aberto/1`
- `/v1/dados/consulta/cliente/celular/...`
- `/v1/pedido/produtos/...`

O sintoma esperado e duas ou mais chamadas simultaneas para o mesmo endpoint, com o mesmo payload, durante abertura ou montagem de uma tela.

### O que procurar no React

- `useEffect` duplicado.
- Dependencias com objetos recriados em cada render.
- Chamada no componente pai e tambem no filho.
- React Strict Mode em desenvolvimento.
- Chamada na montagem e outra apos atualizacao de estado.
- Dois componentes solicitando o mesmo recurso compartilhado.
- Interceptadores repetindo requisicao.
- TanStack Query/React Query refazendo busca no foco.
- Ausencia de cache ou deduplicacao.
- Componentes desmontando e montando novamente.

### Exemplo problematico

```tsx
const filtros = {
  empresa: empresaId,
};

useEffect(() => {
  carregarParametros();
}, [filtros]);
```

Como `filtros` e recriado a cada render, o efeito pode disparar novamente.

### Ajuste recomendado

```tsx
useEffect(() => {
  carregarParametros();
}, [empresaId]);
```

### Deduplicacao com TanStack Query

```tsx
useQuery({
  queryKey: ['parametros'],
  queryFn: carregarParametros,
  staleTime: 5 * 60 * 1000,
  refetchOnWindowFocus: false,
});
```

Se o projeto nao usar TanStack Query, criar um cache simples por Promise para impedir duas chamadas simultaneas iguais.

### Criterio de aceite

Durante a abertura de uma tela, cada endpoint de dados compartilhados deve ser chamado apenas uma vez, salvo quando houver motivo funcional claro.

## 2. Adaptar o frontend ao novo `/v2/status`

### Problema

O endpoint `/v2/status` retorna aproximadamente 661 KB em chamadas recorrentes. Esse custo tambem afeta o frontend:

- download maior;
- descompressao;
- `JSON.parse` no navegador;
- atualizacao de estado React;
- rerenderizacao;
- maior custo em maquinas fracas.

### Arquitetura desejada

O backend deve passar a retornar apenas versoes ou indicadores de alteracao.

Exemplo:

```json
{
  "pedidoVersion": 18271,
  "parametroVersion": 45,
  "produtoVersion": 320,
  "impressaoVersion": 917
}
```

O frontend deve comparar os valores recebidos com os valores anteriores e chamar somente os endpoints correspondentes ao que mudou.

Outra possibilidade:

```json
{
  "changed": true,
  "changes": {
    "pedidos": true,
    "parametros": false,
    "produtos": false,
    "impressao": true
  }
}
```

Quando nada mudar:

```json
{
  "changed": false
}
```

### Criterio de aceite

Quando nada mudou:

- resposta abaixo de 1 KB;
- tempo abaixo de 50 ms no backend;
- frontend nao deve buscar nem renderizar dados completos novamente.

Quando houver alteracao:

- frontend deve buscar apenas os dados alterados;
- nao continuar processando 661 KB em cada polling.

## 3. Suporte a ETag / 304 Not Modified

### Objetivo

Se o backend implementar ETag no `/v2/status`, o frontend deve enviar o identificador da ultima versao conhecida.

Backend pode responder:

```http
ETag: "status-18271"
```

Frontend deve enviar nas proximas chamadas:

```http
If-None-Match: "status-18271"
```

Se nao houver mudanca, backend retorna:

```http
304 Not Modified
```

### Criterio de aceite

- Frontend trata `304` como "sem alteracao".
- Frontend nao tenta fazer `JSON.parse` de corpo vazio.
- Estado React permanece igual quando a resposta for `304`.

## 4. Rever polling

### Problema

Alguns endpoints parecem ser chamados de forma recorrente e com payload grande.

### Acoes no frontend

- Confirmar intervalo de polling das telas.
- Evitar polling em telas fora de foco ou desmontadas.
- Cancelar requisicoes pendentes ao sair da tela.
- Usar cache para dados compartilhados.
- Evitar disparar polling duplicado em componentes pai e filho.
- Suspender polling quando o usuario nao estiver na tela que precisa do dado.

### Criterio de aceite

- Cada tela tem um unico dono para o polling.
- Polling e cancelado ao desmontar a tela.
- Endpoints compartilhados usam cache/deduplicacao.

## 5. Impressao assincrona e contrato com o frontend

### Contexto

O backend deve enfileirar impressao e responder rapidamente, sem esperar a impressora fisica concluir.

Resposta sugerida:

```json
{
  "success": true,
  "queued": true,
  "jobId": 123
}
```

### Acoes no frontend

- Se hoje o frontend valida apenas status HTTP, manter compatibilidade.
- Se o frontend espera a impressao terminar para liberar a tela, ajustar fluxo para aceitar `queued=true`.
- Exibir estado de "impressao enviada" ou equivalente quando o trabalho entrar na fila.
- Se houver consulta de status do job futuramente, buscar pelo `jobId`.

### Criterio de aceite

- A tela nao fica bloqueada esperando a impressora fisica.
- O usuario recebe feedback de que o trabalho foi aceito.
- Erros de enfileiramento continuam sendo tratados como falha.

## 6. Checklist de entrega frontend

- Endpoint chamado apenas uma vez por tela quando for dado compartilhado.
- Sem objetos instaveis em arrays de dependencia de `useEffect`.
- Sem chamadas duplicadas entre pai e filho.
- Cache/deduplicacao aplicado aos endpoints compartilhados.
- `/v2/status` processa versoes/alteracoes, nao snapshot completo recorrente.
- Suporte a `304 Not Modified`, se implementado no backend.
- Polling cancelado ao desmontar tela.
- Polling suspenso quando nao necessario.
- Fluxo de impressao aceita resposta enfileirada sem bloquear UI.
- Medir antes/depois no navegador: quantidade de requests, bytes baixados, tempo de parse e renders.
