# Contexto do projeto para Codex

## Fiscal / DFe / Nota fiscal

Endpoint revisado:
- `/dfe/manifestar/:CHAVE/confirmacao`
- `/v2/fornecedores/:fornecedor/dossie/:data_inicio/:data_fim`

Fluxo DFe:
- `dfe_documento` armazena os documentos/resumos recebidos da SEFAZ.
- Depois da manifestacao e download do XML completo, a nota deve ser importada para `nota_fiscal` e seus itens para `nota_fiscal_item`.
- XML completo fica em `dfe_documento.xml_base64`, com `tipo = 'nfe'`.
- Resumo fica com `tipo = 'resumo'`.

Tabelas fiscais principais:

### nota_fiscal
- `id char(36) PK`
- `fornecedor_id char(36)`
- `serie varchar(10)`
- `numero varchar(20)`
- `chave varchar(44)`
- `modelo varchar(5)`
- `tipo enum('NF','NFCe')`
- `data_emissao datetime`
- `data_entrada datetime`
- `vNF decimal(15,2)`
- `vFrete decimal(15,2)`
- `vDesc decimal(15,2)`
- `vOutro decimal(15,2)`
- `xml_original longtext`
- `status_importacao enum('pendente','processada','erro')`
- `criado_em datetime`

### nota_fiscal_item
- `id char(36) PK`
- `nota_fiscal_id char(36)`
- `fornecedor_item_id char(36)`
- `cProd varchar(60)`
- `xProd varchar(255)`
- `NCM varchar(20)`
- `CFOP varchar(10)`
- `qCom decimal(15,6)`
- `uCom varchar(10)`
- `vUnCom decimal(15,6)`
- `vProd decimal(15,2)`
- `vDesc decimal(15,2)`
- `vFrete decimal(15,2)`
- `vOutro decimal(15,2)`
- `vTotal decimal(15,2)`
- `uTrib varchar(10)`
- `criado_em datetime`
- `entrada_estoque tinyint`
- `entrada_estoque_em datetime`
- `entrada_estoque_msg varchar(255)`

### fornecedor
- `id char(36) PK`
- `cnpj varchar(20)`
- `nome varchar(255)`
- `inscricao_estadual varchar(30)`
- `endereco varchar(255)`
- `municipio varchar(100)`
- `uf char(2)`
- `email varchar(150)`
- `telefone varchar(50)`
- `tipo_fornecedor enum('PJ','PF')`
- `criado_em datetime`

### fornecedor_item
- `id char(36) PK`
- `fornecedor_id char(36)`
- `cprod varchar(60)`
- `cEAN varchar(20)`
- `xProd varchar(255)`
- `NCM varchar(20)`
- `CEST varchar(10)`
- `CFOP varchar(10)`
- `uCom varchar(10)`
- `ultimo tinyint(1)`
- `tabela_vinculo enum('produto','ingrediente')`
- `campo_vinculo varchar(100)`
- `codigo_vinculo char(36)`
- `ativo tinyint(1)`
- `criado_em datetime`
- `fator float`

### dfe_documento
- `id int AI PK`
- `id_consulta int`
- `nsu varchar(15)`
- `chave varchar(44)`
- `cnpj_emitente varchar(18)`
- `nome_emitente varchar(150)`
- `valor decimal(15,2)`
- `data_emissao datetime`
- `situacao varchar(30)`
- `xml_base64 longtext`
- `tipo enum('nfe','evento','resumo')`
- `criado_em timestamp`
- `manifestada tinyint(1)`
- `manifestacao_tipo varchar(30)`
- `manifestacao_status varchar(40)`
- `manifestacao_origem varchar(20)`
- `manifestacao_data datetime`

Notas de implementacao:
- O dossie de fornecedor deve calcular resumo a partir de `nota_fiscal` e `nota_fiscal_item`.
- `total_comprado` deve preferir `nota_fiscal.vNF`, porque `nota_fiscal_item.vTotal` pode estar nulo em importacoes antigas/atuais.
- Datas vindas de rota podem chegar como `dd-mm-yyyy`; normalizar para `yyyy-mm-dd` antes de passar ao SQL.
- Em `/v2/fornecedores/:fornecedor/dossie/:data_inicio/:data_fim`, cada item deve ajudar o front a montar curva de preco:
  - metricas do periodo: quantidade, desconto, frete, total, menor/maior/media de `vUnCom`;
  - metricas historicas: primeira/ultima compra, primeiro/ultimo valor, menor/maior/media historica;
  - comparativos percentuais: ultimo valor vs primeiro valor, media do periodo vs media anterior ao periodo;
  - `historico_precos`: lista cronologica das compras daquele `fornecedor_item_id`.
  - `comprado_periodo`, `notas_periodo` e `compras_periodo` indicam se aquele item apareceu nas notas filtradas.
  - A resposta tambem deve conter `dossie_versao = 2` e um array top-level `historico_precos` para facilitar graficos agrupados no front.

## Configuracoes

- A tabela `configuracoes` pode nao existir em bancos que ainda nao passaram pela atualizacao 146.
- `GetParametros` deve garantir a existencia da tabela antes de consultar `select * from configuracoes`.
- Se `configuracoes` nao existir, criar com:
  - `chave VARCHAR(100) PRIMARY KEY`
  - `valor TEXT`
  - charset/collation `utf8mb4` / `utf8mb4_unicode_ci`
- Depois de criar, migrar os dados da tabela antiga `dados_whatsapp` para `configuracoes`, usando a mesma ideia de `MigrarDadosWhatsappParaConfig`.

## Dashboard de venda

- Endpoint principal: `/v2/dashboard/venda/:dataini/:datafim`.
- Implementacao principal: `BuscarDashBoardVenda` em `src/modulos/v2/v2.pas`.
- Cache principal usa `goopedir_cache.cache` com origem `DoGetDashBoardVenda` e chave `yyyy-mm-dd_yyyy-mm-dd`.
- Cache diario fechado usa `goopedir_cache.dashboard_venda_dia`, com `data_ref`, `dados` e `gerado_em`.
- Antes de calcular o dashboard pesado, `BuscarDashBoardVenda` tenta montar o periodo somando os JSONs diarios fechados; se algum dia fechado faltar, cai no cache antigo por periodo e depois no calculo normal.
- Dia atual nao fica no cache diario fechado: quando o periodo inclui hoje, junta os dias fechados do cache diario com o resultado vivo de hoje.
- No startup, o preenchimento diario deve varrer do primeiro dia do ano ate ontem; dias existentes em `dashboard_venda_dia` sao pulados, e dias ausentes sao gerados para corrigir buracos antigos.
- Ao consultar um periodo fechado, se um dia estiver ausente em `dashboard_venda_dia`, a consulta deve gerar esse dia sob demanda e continuar montando o objeto a partir do cache diario.
- Quando o periodo solicitado tiver uma linha em `dashboard_venda_referencia`, o JSON do dashboard deve destacar isso com `cache_origem`, `cache_referencia`, `cache_chave`, `cache_data_inicio` e `cache_data_fim`.
- A referencia do mes corrente nao deve usar o ultimo dia do mes, porque o mes ainda esta aberto; usar o dia atual como `data_fim`. Meses anteriores podem usar `EndOfTheMonth`.
- No startup das rotas v2, iniciar aquecimento assincrono de cache para:
  - ano atual ate hoje;
  - meses de janeiro ate o mes corrente;
  - mes anterior;
  - ultimos 3 meses;
  - dias fechados desde o primeiro dia do ano ate ontem.
- Referencias do dashboard ficam em `goopedir_cache.dashboard_venda_referencia` com `referencia`, `data_inicio`, `data_fim`, `chave` e `gerado_em`.
- Periodos que incluem hoje devem ter validade curta; periodos fechados podem ter validade longa.

## Pedidos NFCe

- Rota de consulta por periodo: `GET /v2/pedidos/nfce/:dataini/:datafim`.
- Rota com filtro de status: `GET /v2/pedidos/nfce/:dataini/:datafim/:status`.
- Retorna pedidos com situacao fiscal relevante no periodo: emitida, pendente/processando, cancelada ou erro.
- Campos principais do retorno: `codigo`, `codigo_pedido_dia`, `data`, `horario`, `chave`, `protocolo`, `cliente`, `valor`, `numero`, `nfce_emite`, `nfce_status`, `status_nota` e `status`.
- `status_nota` normaliza a situacao para `EMITIDA`, `PENDENTE`, `CANCELADA`, `ERRO` ou `SEM_NOTA`.
- Status aceitos no filtro: `EMITIDA`, `PENDENTE`, `CANCELADA`, `ERRO` e `SEM_NOTA`.
- No envio de e-mail da NFCe, validar primeiro o XML local padrao (`Docs/<chave>-nfe.xml`); se nao existir, consultar `pedido_nfce.path` como caminho local alternativo e `pedido_nfce.caminho` como link externo do XML ja enviado ao site.
- Se existir XML local, anexar no e-mail. Se existir apenas link externo, enviar e-mail sem anexo, mas com botao para baixar o XML.
