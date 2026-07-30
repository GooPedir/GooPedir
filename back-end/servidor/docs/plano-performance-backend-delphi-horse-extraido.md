# Plano de ajustes de performance do backend Delphi/Horse

## Objetivo

Analisar e corrigir os gargalos identificados nos logs de performance do backend Delphi com Horse e FireDAC, preservando o contrato atual das APIs.

As alterações devem ser feitas em etapas pequenas, com medição antes e depois.

Não alterar formatos de resposta, nomes de campos, status HTTP ou comportamento funcional sem necessidade.

# Diagnóstico atual

## 1. Índice da tabela caixa_movimento

Foi identificado um gargalo na consulta:

SELECT *
FROM caixa_movimento
JOIN tipo_pagamento
    ON tipo_pagamento.codigo = caixa_movimento.id_tipo_pagamento
WHERE caixa_movimento.tipo = 1
  AND caixa_movimento.id_pedido = :pedido

Antes do índice, o EXPLAIN mostrava:

caixa_movimento
type = ALL
rows = aproximadamente 97 mil
Using where
Using join buffer (Block Nested Loop)

Foi criado o índice:

CREATE INDEX idx_caixa_pedido_tipo
ON caixa_movimento (id_pedido, tipo);

Após isso, o endpoint de pagamento caiu de aproximadamente 610 ms para valores entre 31 e 47 ms.

Exemplos atuais:

GET /v1/pedido/pagamento/507575
total_ms=31
sql_ms=31
queries=1

GET /v1/pedido/pagamento/507572
total_ms=47
sql_ms=32
queries=1

Isso confirma que o índice resolveu esse gargalo.

## Ação

Manter o índice:

idx_caixa_pedido_tipo (id_pedido, tipo)

Também revisar se o índice comum abaixo é redundante:

PRIMARY KEY (id)
INDEX id (id)

Como a chave primária já indexa id, avaliar remover o índice redundante:

DROP INDEX id ON caixa_movimento;

Somente remover após confirmar que nenhuma rotina depende especificamente do nome do índice.

# Prioridade 1 — Instrumentar /v1/atualiza/dados/pedido

Foi registrado:

POST /v1/atualiza/dados/pedido/
total_ms=14500
sql_ms=78
queries=3
rows=3

O endpoint demorou 14,5 segundos, mas o banco consumiu apenas 78 ms.

Isso significa que aproximadamente 14,4 segundos estão sendo gastos fora do MySQL.

## O que deve ser feito

Localizar a implementação completa desse endpoint e instrumentar cada etapa interna individualmente.

Registrar pelo menos:

validacao_ms
connection_ms
select_ms
update_ms
commit_ms
cache_ms
impressao_ms
http_externo_ms
arquivo_ms
serial_ms
sleep_ms
finalizacao_ms
total_ms

Exemplo de instrumentação:

uses
  System.Diagnostics,
  System.SysUtils;

procedure LogEtapa(
  const RequestId: string;
  const Endpoint: string;
  const Etapa: string;
  const TempoMS: Int64
);
begin
  GerarLog(
    Format(
      '[STEP] request_id=%s endpoint=%s step=%s duration_ms=%d',
      [
        RequestId,
        Endpoint,
        Etapa,
        TempoMS
      ]
    )
  );
end;

Uso:

SW := TStopwatch.StartNew;

ValidarDados;

SW.Stop;
LogEtapa(RequestId, Endpoint, 'validacao', SW.ElapsedMilliseconds);

SW := TStopwatch.StartNew;

AtualizarBanco;

SW.Stop;
LogEtapa(RequestId, Endpoint, 'atualizar_banco', SW.ElapsedMilliseconds);

SW := TStopwatch.StartNew;

ExecutarImpressao;

SW.Stop;
LogEtapa(RequestId, Endpoint, 'impressao', SW.ElapsedMilliseconds);

## Procurar explicitamente por

Sleep;

TThread.Sleep;

espera ativa com while;

chamadas HTTP externas;

comunicação com impressora;

leitura ou escrita em arquivo;

comunicação serial;

ACBr;

socket;

espera de thread;

Synchronize;

WaitFor;

mutex;

critical section;

processamento de imagens;

conversão de Base64;

repetição de tentativas;

polling interno;

bloqueio aguardando impressão;

chamadas síncronas para outros endpoints.

## Critério de aceite

Após instrumentar, o log deve indicar claramente qual etapa consome os 14 segundos.

O endpoint não deve continuar apresentando apenas:

total_ms=14500
sql_ms=78

Deve gerar algo semelhante a:

[STEP] step=validacao duration_ms=5
[STEP] step=sql duration_ms=78
[STEP] step=impressao duration_ms=13800
[STEP] step=cache duration_ms=4

# Prioridade 2 — Tornar a impressão assíncrona

Foram identificadas chamadas de impressão com tempos elevados:

POST /v1/imprimir/1/507575/0
total_ms=3844

POST /impressao/pedido/produto/507575
total_ms=3953

Também ocorreram chamadas entre aproximadamente 500 e 641 ms.

O endpoint HTTP não deve ficar esperando a impressora física concluir todo o processo.

## Arquitetura desejada

Fluxo atual provável:

React
→ endpoint Horse
→ prepara impressão
→ envia para impressora
→ espera impressora
→ retorna HTTP 200

Fluxo desejado:

React
→ endpoint Horse
→ valida pedido
→ adiciona trabalho na fila
→ retorna HTTP 200 ou 202 rapidamente
→ thread em segundo plano processa a impressão

## Requisitos da fila

Criar uma fila thread-safe para trabalhos de impressão.

Cada item deve conter pelo menos:

id do pedido
tipo de impressão
impressora
número de cópias
data e hora
tentativas
status
mensagem de erro

Status sugeridos:

PENDENTE
PROCESSANDO
CONCLUIDO
ERRO

## Cuidados

não compartilhar TFDConnection entre threads;

não compartilhar TFDQuery entre threads;

cada thread deve obter sua própria conexão;

proteger a fila com estrutura thread-safe;

impedir duas impressões simultâneas do mesmo trabalho;

limitar tentativas;

registrar erros;

não bloquear a thread HTTP;

garantir que falha na impressão não desfaça a gravação do pedido;

evitar perda de trabalho caso o processo seja encerrado.

Se uma fila apenas em memória puder causar perda de impressão após reiniciar o servidor, criar uma tabela persistente, por exemplo:

CREATE TABLE fila_impressao (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pedido_id BIGINT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    impressora VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    tentativas INT NOT NULL DEFAULT 0,
    erro TEXT,
    criado_em DATETIME NOT NULL,
    processado_em DATETIME NULL,
    PRIMARY KEY (id),
    INDEX idx_fila_status_criado (status, criado_em)
);

## Resposta da API

Quando o trabalho for aceito:

{
  "success": true,
  "queued": true,
  "jobId": 123
}

Preservar o contrato atual sempre que possível.

Caso o frontend só valide o status HTTP, manter o corpo compatível.

## Critério de aceite

O endpoint de impressão deve normalmente responder em menos de:

100 ms a 300 ms

A impressão física pode continuar levando segundos, mas não deve bloquear a requisição.

# Prioridade 3 — Reduzir o endpoint /v2/status

O endpoint continua devolvendo aproximadamente 661 KB:

GET /v2/status
total_ms=1656
sql_ms=62
queries=8
bytes=661391

Outro exemplo:

GET /v2/status
total_ms=750
sql_ms=16
queries=6
bytes=661838

A maior parte do tempo não está no banco.

## Problema

Esse endpoint aparentemente retorna um snapshot grande e completo do sistema em chamadas recorrentes.

O custo envolve:

montagem de objetos
serialização JSON
cópias de string
compressão
envio
rede
JSON.parse no navegador
atualização de estado React
renderização

## Primeira ação

Registrar o tamanho individual de cada propriedade retornada por /v2/status.

Exemplo:

procedure LogJSONFieldSize(
  const RequestId: string;
  const FieldName: string;
  Value: TJSONValue
);
var
  JSONText: string;
  SizeBytes: Integer;
begin
  if not Assigned(Value) then
    Exit;

  JSONText := Value.ToJSON;
  SizeBytes := TEncoding.UTF8.GetByteCount(JSONText);

  GerarLog(
    Format(
      '[STATUS_FIELD] request_id=%s field=%s bytes=%d',
      [
        RequestId,
        FieldName,
        SizeBytes
      ]
    )
  );
end;

Aplicar para todos os campos principais:

LogJSONFieldSize(RequestId, 'pedidos', JSON.GetValue('pedidos'));
LogJSONFieldSize(RequestId, 'parametros', JSON.GetValue('parametros'));
LogJSONFieldSize(RequestId, 'empresa', JSON.GetValue('empresa'));
LogJSONFieldSize(RequestId, 'impressao', JSON.GetValue('impressao'));
LogJSONFieldSize(RequestId, 'produtos', JSON.GetValue('produtos'));
LogJSONFieldSize(RequestId, 'configuracoes', JSON.GetValue('configuracoes'));

## Procurar dentro da resposta

imagens em Base64;

logotipo em Base64;

XML;

HTML;

listas completas de produtos;

listas completas de parâmetros;

configurações repetidas;

objetos duplicados;

campos que nunca mudam;

conteúdo acumulativo;

listas globais não limpas;

logs internos;

strings JSON dentro de strings JSON.

## Arquitetura recomendada

O endpoint deve retornar apenas versões ou indicadores de alteração.

Exemplo:

{
  "pedidoVersion": 18271,
  "parametroVersion": 45,
  "produtoVersion": 320,
  "impressaoVersion": 917
}

O frontend compara com os valores anteriores e chama somente o endpoint correspondente quando uma versão mudar.

Outra opção:

{
  "changed": true,
  "changes": {
    "pedidos": true,
    "parametros": false,
    "produtos": false,
    "impressao": true
  }
}

Quando nada mudar:

{
  "changed": false
}

## ETag

Avaliar também suporte a:

ETag: "status-18271"

O frontend envia:

If-None-Match: "status-18271"

Se não houver mudança:

304 Not Modified

## Critério de aceite

Quando nada mudou:

resposta abaixo de 1 KB
tempo abaixo de 50 ms

Quando houver alteração:

retornar apenas os dados alterados

Não continuar enviando 661 KB em cada polling.

# Prioridade 4 — Instrumentar /v2/parametros

Foram registrados casos como:

GET /v2/parametros
total_ms=1734
sql_ms=0
queries=0
bytes=6675

Também existem variações de 609 ms, 688 ms e valores menores.

Como não há SQL registrado, o tempo pode estar em:

cache;

leitura de arquivo;

criação de conexão;

lock;

serialização;

compressão;

espera entre threads;

objeto global;

processamento de configuração;

acesso a INI;

acesso a registro do Windows;

espera por recurso compartilhado.

## Instrumentar as etapas

Registrar:

auth_ms
connection_create_ms
connection_open_ms
cache_lookup_ms
file_read_ms
config_build_ms
json_build_ms
json_serialize_ms
compression_ms
send_ms
handler_total_ms

## Critério de aceite

O log precisa explicar integralmente o tempo.

Exemplo:

total_ms=688
file_read_ms=5
cache_ms=2
json_build_ms=10
compression_ms=640
send_ms=15

Não aceitar mais um endpoint com:

total_ms=1734
sql_ms=0
json_ms=0

sem saber onde o tempo foi gasto.

# Prioridade 5 — Melhorar a instrumentação global

Atualmente os logs possuem:

total_ms
sql_ms
json_ms
queries
rows
bytes

Isso ainda não permite identificar grande parte do tempo fora do banco.

## Adicionar ao contexto da requisição

request_id
endpoint
method
middleware_ms
auth_ms
connection_ms
cache_ms
sql_ms
build_object_ms
serialize_ms
compression_ms
send_ms
external_ms
printing_ms
total_ms
queries
sql_rows_total
response_items
response_bytes
slowest_query_ms
slowest_query_hash

## Exemplo de log final

[REQUEST]
request_id=20260723215450450-182
method=GET
endpoint=/v2/status
status=200
middleware_ms=2
auth_ms=1
connection_ms=8
cache_ms=0
sql_ms=16
build_object_ms=130
serialize_ms=170
compression_ms=210
send_ms=190
external_ms=0
printing_ms=0
total_ms=750
queries=6
sql_rows_total=8
response_items=8
bytes=661838
slowest_query_ms=8
slowest_query_hash=abc123
error=""

## SQL individual

Registrar cada SQL lenta:

[SLOW_SQL]
request_id=...
endpoint=...
duration_ms=...
rows=...
sql_hash=...
success=True
sql="..."

Além disso, registrar a query mais lenta mesmo quando nenhuma ultrapassar o limite:

slowest_query_ms
slowest_query_hash

## Resolução de tempo

Os tempos aparecem frequentemente como:

15
16
31
32
47
62
78
94

Isso indica baixa resolução ou arredondamento próximo de 15,6 ms.

Garantir que todas as medições usem:

TStopwatch

Evitar usar apenas:

GetTickCount
GetTickCount64
TTimer
Now
MilliSecondsBetween

Para diagnóstico detalhado, permitir registro em microssegundos:

ElapsedUS :=
  Stopwatch.ElapsedTicks * 1000000 div TStopwatch.Frequency;

# Prioridade 6 — Corrigir chamadas duplicadas no React

O log mostra várias requisições idênticas próximas umas das outras.

Exemplo de /v2/parametros disparado repetidamente:

duas ou mais chamadas simultâneas
mesmo payload
mesmo endpoint

Também foram observadas duplicidades em:

/v1/caixa/aberto/1
/v1/dados/consulta/cliente/celular/...
/v1/pedido/produtos/...

## Procurar no React

useEffect duplicado;

dependências com objetos recriados em cada render;

chamada no componente pai e no filho;

React Strict Mode em desenvolvimento;

chamada na montagem e outra após atualização de estado;

dois componentes solicitando o mesmo recurso;

interceptadores repetindo requisição;

React Query refazendo busca no foco;

ausência de cache ou deduplicação;

componentes desmontando e montando novamente.

## Exemplo problemático

const filtros = {
  empresa: empresaId
};

useEffect(() => {
  carregarParametros();
}, [filtros]);

Como filtros é recriado, o efeito pode disparar novamente.

Preferir:

useEffect(() => {
  carregarParametros();
}, [empresaId]);

## Deduplicação

Se usar TanStack Query:

useQuery({
  queryKey: ['parametros'],
  queryFn: carregarParametros,
  staleTime: 5 * 60 * 1000,
  refetchOnWindowFocus: false
});

Ou criar um cache simples por Promise para impedir duas chamadas simultâneas iguais.

## Critério de aceite

Durante a abertura de uma tela, cada endpoint de dados compartilhados deve ser chamado apenas uma vez, salvo quando houver motivo funcional.

# Prioridade 7 — Rever endpoints de produto por categoria

Foi identificado anteriormente um padrão N+1 em:

/v1/produto/categoria/:id

Exemplos:

categoria 1
queries=111
rows=539

categoria 136
queries=23
rows=90

categoria 152
queries=8
rows=21

A quantidade de queries cresce junto com a quantidade de produtos.

## Objetivo

A quantidade de queries não pode crescer linearmente conforme o número de produtos.

## Refatoração desejada

Em vez de:

1 query para produtos
1 query para cada produto
1 query para cada adicional

usar:

1 query para produtos
1 query para adicionais de todos os produtos
1 query para sabores de todos os produtos
1 query para configurações necessárias

Depois agrupar em memória.

## Estrutura sugerida

Buscar produtos:

SELECT
    p.codigo,
    p.nome,
    p.valor,
    p.codigo_grupo
FROM produto p
WHERE p.codigo_grupo = :categoria;

Buscar adicionais em lote:

SELECT
    pa.codigo_produto,
    pa.codigo,
    pa.descricao,
    pa.valor
FROM produto_adicional pa
WHERE pa.codigo_produto IN (...);

Buscar sabores em lote:

SELECT
    ps.codigo_produto,
    ps.codigo_sabor,
    s.descricao,
    ps.valor
FROM produto_sabor ps
JOIN sabor s
    ON s.codigo = ps.codigo_sabor
WHERE ps.codigo_produto IN (...);

Agrupar usando:

TDictionary<Integer, TJSONArray>

ou estrutura própria tipada.

## Critério de aceite

Uma categoria com 10 produtos e uma com 200 produtos devem executar aproximadamente a mesma quantidade fixa de queries.

Meta:

até 4 ou 5 queries por endpoint

# Prioridade 8 — Revisar operações fora do SQL

Existem endpoints com diferença muito grande entre:

total_ms

e:

sql_ms

Exemplos:

/v1/dados/pedido
total_ms=4093
sql_ms=156

/v1/pedidos
total_ms=859
sql_ms=15

/v2/status
total_ms=1656
sql_ms=62

## Investigar

espera por impressora;

cache global bloqueado;

lista global protegida por critical section;

leitura de arquivo;

criação repetida de conexão;

serialização tardia pelo Horse;

compressão;

Res.Send;

log síncrono;

lock de fila;

execução no thread principal;

Synchronize;

cópia repetida de JSON;

chamada interna de outro endpoint;

antivirus bloqueando arquivo;

rede com impressora;

chamadas externas.

# Regras para implementação

## Não fazer

não reescrever todo o backend de uma vez;

não compartilhar TFDConnection entre threads;

não compartilhar TFDQuery;

não mudar contrato JSON sem compatibilidade;

não remover logs antes de concluir o diagnóstico;

não adicionar Sleep;

não usar fila sem tratamento de erro;

não ocultar exceções;

não engolir erros com except vazio;

não aumentar max_connections como solução;

não criar índices aleatoriamente;

não usar SELECT * em endpoints críticos quando poucas colunas bastarem.

## Fazer

criar alterações pequenas;

medir antes e depois;

preservar comportamento;

registrar tempo por etapa;

adicionar tratamento de exceção;

garantir liberação de objetos;

validar ownership de JSON;

validar concorrência;

registrar erros de impressão;

garantir rollback em falha;

testar com múltiplas requisições simultâneas.

# Ordem de execução

## Etapa 1

Instrumentar completamente:

/v1/atualiza/dados/pedido

Objetivo: descobrir onde estão os 14,5 segundos.

## Etapa 2

Instrumentar:

/v1/imprimir/*
/impressao/pedido/produto/*

Separar:

montagem
fila
impressora
espera
retorno

## Etapa 3

Implementar fila assíncrona de impressão.

## Etapa 4

Medir campos e reduzir:

/v2/status

## Etapa 5

Instrumentar:

/v2/parametros

## Etapa 6

Corrigir requisições duplicadas no React.

## Etapa 7

Eliminar N+1 de:

/v1/produto/categoria/:id

## Etapa 8

Comparar logs antes e depois.

# Metas de performance

## Consultas simples

abaixo de 100 ms

## Busca de pagamento

abaixo de 50 ms

## Atualização de pedido sem impressão síncrona

abaixo de 300 ms

## Enfileiramento de impressão

abaixo de 200 ms

## /v2/parametros

abaixo de 100 ms em cache

## /v2/status sem alterações

abaixo de 50 ms
resposta abaixo de 1 KB

## Produtos por categoria

quantidade fixa de queries
preferencialmente até 5

# Entrega esperada do Codex

Para cada alteração, informar:

arquivo alterado;

método alterado;

problema encontrado;

alteração realizada;

riscos;

teste executado;

tempo antes;

tempo depois;

quantidade de queries antes;

quantidade de queries depois;

tamanho da resposta antes;

tamanho da resposta depois.

Não considerar a tarefa concluída apenas porque o código compilou.

A tarefa só estará concluída quando os logs mostrarem claramente a redução do tempo e quando o comportamento funcional permanecer compatível.