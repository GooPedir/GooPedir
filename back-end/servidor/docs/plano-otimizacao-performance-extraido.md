# Ajustes adicionais de performance identificados no log

## Objetivo

Aplicar correções objetivas com base na nova instrumentação de performance.

Não alterar contratos das APIs sem compatibilidade e não fazer grandes refatorações de uma vez.

Executar cada ajuste separadamente e comparar logs antes e depois.

# Prioridade 1 — Remover o campo site do polling completo de /v2/status

## Evidência

O endpoint /v2/status retorna aproximadamente 662 KB.

A instrumentação mostrou:

field=site bytes=636453
response bytes=661667

Em chamadas posteriores:

site=636493 bytes
site=636533 bytes
site=636573 bytes
site=636613 bytes

O campo site representa aproximadamente 96% da resposta.

## Problema

O endpoint /v2/status está sendo usado como polling recorrente, mas envia novamente todo o objeto site, mesmo quando nada relevante mudou.

Isso causa:

serialização pesada
cópias grandes de strings
compressão
tráfego de rede
JSON.parse no React
atualização de estado
renderizações desnecessárias

## Ajuste obrigatório

Separar site do endpoint /v2/status.

O /v2/status deve retornar apenas um identificador ou versão:

{
  "siteVersion": 12345
}

O frontend deve buscar o conteúdo completo do site somente quando essa versão mudar:

GET /v2/site

Quando nada mudar, não deve baixar novamente os 636 KB.

## Alternativa compatível

Caso não seja possível alterar o frontend imediatamente, adicionar uma query opcional:

GET /v2/status?includeSite=0

Por padrão no polling do frontend:

includeSite=0

Durante inicialização ou atualização específica:

includeSite=1

## Outra alternativa

Usar ETag:

ETag: "site-12345"

Se o frontend já possui a versão:

If-None-Match: "site-12345"

Responder:

304 Not Modified

## Critério de aceite

Quando não houver mudança no site:

/v2/status abaixo de 25 KB
idealmente abaixo de 5 KB
tempo abaixo de 100 ms

O campo site completo não pode continuar sendo enviado em todo polling.

# Prioridade 2 — Instrumentar internamente GetParametros

## Evidência

O endpoint /v2/parametros apresentou:

parametros_get_parametros=747ms
parametros_json_size=0ms
parametros_send=0ms
total=766ms

Outro caso:

parametros_get_parametros=913ms
total=922ms

Portanto, o gargalo está dentro do método que obtém ou monta os parâmetros.

## Ação

Localizar o método executado na etapa:

parametros_get_parametros

Adicionar medições internas para cada parte.

Registrar pelo menos:

connection_create_ms
connection_open_ms
cache_lookup_ms
file_read_ms
ini_read_ms
database_read_ms
dataset_load_ms
json_build_ms
lock_wait_ms
parameter_loop_ms
total_ms

## Procurar por

criação repetida de TConexao
leitura repetida de arquivo INI
leitura de todos os parâmetros
loops chamando GetParametro individualmente
JSON para dataset e dataset para JSON
lock global
critical section
Synchronize
consulta fora da instrumentação
cache armazenado em arquivo
cópias de TStringList
parsing repetido de JSON

## Suspeita de N+1 de parâmetros

Verificar se o método faz algo semelhante a:

GetParametro('a');
GetParametro('b');
GetParametro('c');
GetParametro('d');

onde cada chamada lê conexão, arquivo ou cache separadamente.

Substituir por uma única leitura:

Parametros := CarregarTodosParametros;

e acessar em memória.

## Cache recomendado

Criar cache em memória por empresa ou banco.

Estrutura sugerida:

TDictionary<string, string>

com controle de:

empresa
versão
data de carregamento
invalidação

Não recarregar todos os parâmetros em cada request.

## Critério de aceite

Com cache quente:

/v2/parametros abaixo de 50 ms

O método GetParametros não deve consumir 700 a 900 ms.

# Prioridade 3 — Eliminar impressão duplicada

## Evidência

Para o mesmo pedido foram observadas chamadas praticamente simultâneas:

POST /v1/imprimir/1/507577/0
POST /impressao/pedido/produto/507577
POST /impressao/pedido/produto/507577

Duas chamadas do endpoint de impressão processaram o mesmo pedido:

enviar_impressao_go=581ms
total=750ms

e:

enviar_impressao_go=351ms
total=453ms

## Ação

Mapear todos os pontos que iniciam impressão:

React
/v1/atualiza/dados/pedido
/v1/imprimir
/impressao/pedido/produto
eventos internos
callbacks

Garantir que apenas um deles seja responsável pela impressão.

## Implementar idempotência

Cada trabalho de impressão deve possuir uma chave única, por exemplo:

pedido_id + tipo_impressao + tentativa_funcional

Antes de criar outro trabalho, verificar se já existe um em:

PENDENTE
PROCESSANDO
CONCLUIDO recentemente

Exemplo de chave:

507577:PRODUTO:1

## Critério de aceite

Uma ação do usuário deve gerar exatamente uma impressão, salvo quando o usuário solicitar explicitamente reimpressão.

Não devem existir duas chamadas simultâneas para o mesmo pedido e mesmo tipo de impressão.

# Prioridade 4 — Tornar enviar_impressao_go assíncrono

## Evidência

Tempos identificados:

581ms
351ms
165ms

Esse tempo corresponde à comunicação com o serviço de impressão.

## Ação

O endpoint HTTP não deve esperar a comunicação completa com o serviço de impressão.

Fluxo recomendado:

endpoint recebe solicitação
valida os dados
cria trabalho na fila
responde imediatamente
worker envia para Impressao Go
worker atualiza status

## Fila persistente recomendada

CREATE TABLE fila_impressao (
    id BIGINT NOT NULL AUTO_INCREMENT,
    chave_idempotencia VARCHAR(150) NOT NULL,
    pedido_id BIGINT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    tentativas INT NOT NULL DEFAULT 0,
    proxima_tentativa DATETIME NULL,
    erro TEXT NULL,
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    finalizado_em DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_fila_impressao_chave (chave_idempotencia),
    INDEX idx_fila_status_data (status, criado_em)
);

## Cuidados

não compartilhar TFDConnection entre threads
cada worker usa sua própria conexão
limitar quantidade de workers
limitar tentativas
registrar erros
usar backoff entre tentativas
evitar dupla execução
não perder trabalhos ao reiniciar

## Critério de aceite

Endpoint HTTP:

abaixo de 100 ms a 200 ms

O envio físico pode continuar levando mais tempo em segundo plano.

# Prioridade 5 — Colocar parametro_nova_impressao em cache

## Evidência

A etapa consumiu:

100ms
87ms
110ms

Consultar um parâmetro de configuração não deveria levar esse tempo.

## Ação

Descobrir como esse parâmetro é obtido.

Se estiver usando:

GetParametro('nova_impressao')

e isso cria conexão ou carrega todos os parâmetros, substituir por cache em memória.

Exemplo conceitual:

function GetParametroCache(
  const Empresa: string;
  const Nome: string
): string;

O cache deve ser invalidado quando o parâmetro for alterado.

## Critério de aceite

parametro_nova_impressao abaixo de 2 ms em cache quente

# Prioridade 6 — Melhorar pedido_inicial_embalagem

## Evidência

A etapa consumiu:

pedido_inicial_embalagem=197ms

Ela é a segunda etapa mais cara de /v1/atualiza/dados/pedido.

## Ação

Instrumentar internamente:

consulta
regra de embalagem
loop de produtos
atualização
commit
serialização

Verificar:

queries em loop
consulta de embalagem por produto
carregamento repetido de configurações
uso de JSON intermediário
criação repetida de conexão

## Critério de aceite

Meta inicial:

abaixo de 50 ms

Se depender de muitos produtos, a quantidade de queries deve ser fixa, não proporcional à quantidade de itens.

# Prioridade 7 — Revisar concorrência durante impressão

## Evidência

Durante os picos de impressão, outras requisições simples ficaram mais lentas.

Exemplos no mesmo período:

/v1/dados/pedido total=875ms sql=110ms
/v1/pedidos total=515ms sql=94ms
/v1/caixa/aberto total=313ms sql=109ms

Isso pode indicar contenção de CPU, lock, conexão ou recurso compartilhado durante a impressão.

## Investigar

critical section global
lock da fila
conexão global
TDataModule compartilhado
TStringList global
log síncrono
Synchronize
uso da thread principal
quantidade limitada de conexões
mutex da impressora

## Regra

A impressão não pode bloquear consultas normais da API.

# Prioridade 8 — Reduzir logs detalhados após diagnóstico

Os logs STATUS_FIELD são úteis agora, mas geram várias linhas por chamada.

Após identificar e corrigir o campo site, manter esses logs somente quando:

modo_debug=true
ou
response_bytes > limite
ou
total_ms > limite

Exemplo:

if ResponseBytes > 100000 then
  LogStatusFieldSizes;

Isso evita crescimento excessivo do arquivo de log.

# Resultado atual positivo

O endpoint /v1/atualiza/dados/pedido caiu de um caso anterior de 14,5 segundos para:

860ms

A nova instrumentação mostrou claramente:

impressao=601ms
pedido_inicial_embalagem=197ms

A instrumentação deve ser mantida até concluir as correções.

# Ordem exata de implementação

Retirar site do polling completo de /v2/status.

Instrumentar internamente GetParametros.

Eliminar chamadas duplicadas de impressão.

Implementar idempotência na impressão.

Criar fila assíncrona persistente.

Colocar parametro_nova_impressao em cache.

Otimizar pedido_inicial_embalagem.

Validar se impressão bloqueia outras requisições.

Comparar os logs antes e depois.

# Entrega esperada

Para cada ajuste, informar:

arquivo alterado
método alterado
problema encontrado
alteração feita
riscos
testes executados
tempo antes
tempo depois
queries antes
queries depois
bytes antes
bytes depois

Não considerar concluído apenas porque compilou.

A tarefa só estará concluída quando os logs confirmarem redução real e não houver alteração funcional indesejada.