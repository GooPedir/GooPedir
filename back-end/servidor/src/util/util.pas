unit util;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, v2, SysUtils, IOUtils,
  System.Variants, conexao, uCacheControl, uControllCaches,
  System.Generics.Collections, System.DateUtils, uNewConsultas,
  uControlerProduto, uGlobais;

type
  TValoresPizza = record
    ValorProduto: Real;
    ValorAdicional: Real;
    Sabores: String;
  end;

procedure Registry;
procedure AtualizaStatus(Pedido, Status: Integer);
function GetBuildInfo: string;
function TransformaData(Data: String): TDate;
function TransformaHora(Hora: String): TTime;
function TrocaVirgula(Resultado: String): String;
function MovimentoCaixa(Caixa, Pedido, TipoPagamento, Tipo: Integer;
  Valor: Real; Descricao: String; Cliente: Integer): Integer;
procedure GerarReceber(Caixa, Pedido, TipoPagamento: Integer; Valor: Real;
  CodigoCliente, Movimento: Integer);
function SQLFormatdaDataMysql(Campo: String): String;
function SQLFormatdaHoraMysql(Campo: String): String;
function SQLFormatdaValorMysql(Campo: String): String;
function ValidaQuantidadeSabores(Sabores, Codigo: String): Integer;
procedure MovimentacaoProduto(Codigo, Tipo: Integer; Quantidade: Real);
procedure MovimentacaoInsulmo(CodigoInsulmo, Tipo: Integer;
  Quantidade, CustoTotal, Custo: Real; EntradaEstoque: Boolean);
function AtualizacaoCustoIngrediente(CodigoIngrediente: Integer): TJSONArray;
procedure MovimentacaoProdutoAdicional(Codigo: Integer; Adicional: String;
  Valor, Quantidade: Real);
procedure MovimentacaoProdutoAdicionalExtorno(Codigo: Integer;
  Adicional: String; Valor, Quantidade: Real);
function ExtractNumberFromURL(const URL: string): string;
procedure ApagarProduto(ID: Integer; Motivo: String; CodigoUsuario: Integer);

procedure SalvarImagenBase64(base64, Caminho: String);

function NonoDigito(Celular: String): String;
function GeraCodigoPorDiaPedido(Pedido: Integer): Integer;
function RemoveAcento(const pText: string): string;
procedure FaturarPedido(Codigo, Caixa: Integer);

procedure GravaMarketing(Cliente: Integer; Valor: Real; Validade: Integer);
procedure GerarCupom;
function DiaAtualAbreviado: string;
procedure EnviarCupom;

procedure LimparCacheProduto;
procedure LimparPastas(const Caminho: string);

function UnionPedio(Tabela, Tipo: String): String;

function GetDadosProdutoPedido(Pedido: Integer): TJSONArray;
procedure LogTempoExecucaoPedido(const Texto: string);





// processamento dos produtos do pedido

procedure AdicionaProduto(Body: String; Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
function AdicionaPizza(Pizza: string; QRY, QRYINSERT: TFDQuery;
  CodigoPedidoItem: Integer; conexao: Tconexao): TValoresPizza;
function Adiciona(Adicionais: Variant; QRY, QRYINSERT: TFDQuery;
  CodigoPedidoProduto: Integer; conexao: Tconexao): Real;
function NovoPedido(CodigoPedido, mesa: Integer; QRY: TFDQuery): Integer;
function CapitalizeFirstLetter(const Input: string): string;

implementation

uses FireDAC.Stan.Option, token, JOSE.Types.JSON, System.Classes,
  Data.DB, IdWinsock2, Vcl.Dialogs, Vcl.ExtCtrls, Horse.Upload, System.Types,
  Winapi.Windows, uMain, System.StrUtils, Vcl.StdCtrls, uSite,
  ADRIFood.Component;

procedure LogTempoExecucaoPedido(const Texto: string);
var
  LogPath: string;
  Arquivo: TextFile;
begin
  try
    LogPath := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'log_tempo_pedido.txt');

    AssignFile(Arquivo, LogPath);
    if FileExists(LogPath) then
      Append(Arquivo)
    else
      Rewrite(Arquivo);

    Writeln(Arquivo, FormatDateTime('[dd/mm/yyyy hh:nn:ss] ', Now) + Texto);

    CloseFile(Arquivo);
  except
  end;
end;

function GetDadosProdutoPedido(Pedido: Integer): TJSONArray;
var
  conexao: Tconexao;

  Origem: String;
  Dados: TFDMemTable;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from index_pedido where id = :codigo');
  conexao.Parametros('codigo', Pedido);
  Origem := conexao.FieldByName('referencia');
  if Origem = '0' then
    Origem := '';

  if Origem <> '' then
  begin
    Origem := '_' + Origem;
  end;
  // Dados := TFDMemTable.Create(nil);
  // conexao.SQL.Add
  // ('SELECT pp.*,((p.valor_venda * pp.quantidade)+pp.valor_adicional) as valor_ajustado, p.valor_venda as pro FROM pedido_produtos'
  // + Origem + ' as pp');
  // conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  // conexao.SQL.Add('where pp.codigo_pedido = :codigo');
  // conexao.Parametros('codigo', Pedido);
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  // while not Dados.Eof do
  // begin
  // if Dados.FieldByName('valor_total').AsFloat <>
  // Dados.FieldByName('valor_ajustado').AsFloat then
  // begin
  // conexao.SQL.Add('update pedido_produtos' + Origem +
  // ' set valor_total = :valor_total where codigo = :codigo');
  // conexao.Parametros('valor_total',
  // Dados.FieldByName('valor_ajustado').AsFloat);
  // conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
  // conexao.ExecuteSQL;
  // end;
  // Dados.Next;
  // end;

  conexao.SQL.Add
    ('SELECT pp.codigo_pedido, pp.impresso as impressao, pp.hora, p.id_site as site, p.foto_ifood as ifood, pp.codigo,p.nome_produto,pp.quantidade,(pp.valor_total / pp.quantidade) as unitario,pp.valor_total,p.valor_embalagem_delivery as entrega, ');
  conexao.SQL.Add('group_concat(' + QuotedStr(' ') + ',upper(pps.nomeclatura),'
    + QuotedStr(' ') + ', upper(pps.descricao)) as obs, pp.selecionado,');
  conexao.SQL.Add
    ('sum(cmp.quantidade) as paga, sum(cmp.valor) as paga_tot, u.nome as usuario,');
  conexao.SQL.Add('max(ppsO.descricao) as observacao');
  conexao.SQL.Add('FROM pedido_produtos' + Origem + ' as pp');
  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  conexao.SQL.Add('left join pedido_produto_sap' + Origem +
    ' as pps on pps.codigo_pedido_produto = pp.codigo and pps.descricao <> ' +
    QuotedStr(' ') + ' and upper(pps.nomeclatura) not like "%ATENÇ%"');
  conexao.SQL.Add
    ('left join caixa_movimento_produto as cmp on cmp.id_pedido_produto = pp.codigo');
  conexao.SQL.Add('left join usuario as u on u.codigo = pp.usuario');
  // left join pedido_produto_sap as ppsO on ppsO.codigo_pedido_produto = pp.codigo and upper(ppsO.nomeclatura) like '%OBS%'
  conexao.SQL.Add('left join pedido_produto_sap' + Origem +
    ' as ppsO on ppsO.codigo_pedido_produto = pp.codigo and upper(ppsO.nomeclatura) like "%OBS%"');
  conexao.SQL.Add('where pp.codigo_pedido = :codigo');
  conexao.SQL.Add('group by pp.codigo');

  conexao.Parametros('codigo', Pedido);
  Result := conexao.ConsultaSQL;

  conexao.Free;
end;

procedure AtualizaStatus(Pedido, Status: Integer);
var
  conexao: Tconexao;
  StatusDescricao: String;
  CodigoSite: Integer;

  Requisicao: iRequisicao;
  ID: Integer;
  Objeto: TJSONObject;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('update pedido set status = :status where codigo = :codigo');
  conexao.Parametros('codigo', Pedido);
  conexao.Parametros('status', Status);
  conexao.ExecuteSQL;

  conexao.SQL.Add('delete from pedido_motoboy where codigo = :codigo');
  conexao.Parametros('codigo', Pedido);
  conexao.ExecuteSQL;

  ID := conexao.GerarID('pedido_status', 'id');
  conexao.SQL.Add
    ('insert into pedido_status (id,id_pedido,id_status,horario) values (:id,:pedido,:status,current_timestamp())');
  conexao.Parametros('pedido', Pedido);
  conexao.Parametros('status', Status);
  conexao.Parametros('id', ID);
  conexao.ExecuteSQL;

  try
    conexao.SQL.Add('select * from pedido where codigo = :codigo');
    conexao.Parametros('codigo', Pedido);
    CodigoSite := conexao.FieldByName('id_pedido_site');
  except
    CodigoSite := 0;
  end;

  conexao.SQL.Add('SELECT * FROM status_pedido where id = ' + Status.ToString);
  StatusDescricao := conexao.FieldByName('descricao');

  if CodigoSite > 0 then
  begin
    try
      Requisicao := iRequisicao.Create(nil);
      Requisicao.BaseURL := API_BASE_URL;
      Requisicao.URL := 'api/pedido/legacy/status';
      Objeto := TJSONObject.Create;
      Objeto.AddPair('codigo', CodigoSite);
      Objeto.AddPair('status', StatusDescricao);
      Requisicao.Body(Objeto);
      Requisicao.Metodo := mPost;
      // Requisicao.BaseURL :=
      // 'https://ws.goopedir.com/v1/atualiza_status_pedido.php?codigo=' +
      // CodigoSite.ToString + '&status=' + StatusDescricao;
      Requisicao.Execute;
    except

    end;
    Requisicao.Free;
  end;
  conexao.Free;
end;

procedure AtualizaValorPedido(Codigo: Integer);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  // conexao.SQL.Add
  // ('select 0 as codigo, sum(valor_total) as total from pedido_produtos where codigo_pedido = :codigo');
  // conexao.Parametros('codigo', Codigo);
  // try
  // Valor := conexao.FieldByName('total');
  // except
  // Valor := 0;
  // end;

  // conexao.SQL.Add
  // ('update pedido set valor_pedido = :pedido, valor_total_pedido = ((:pedido + valor_taxa_entrega) - valor_desconto) where codigo = :codigo');

  conexao.SQL.Add
    ('update pedido set valor_pedido = (select sum(pp.valor_total) from pedido_produtos as pp where pp.codigo_pedido = :codigo)');
  conexao.SQL.Add
    (', valor_total_pedido = (((select sum(pp.valor_total) from pedido_produtos as pp where pp.codigo_pedido = :codigo) + valor_taxa_entrega) - valor_desconto) where codigo = :codigo');
  conexao.Parametros('codigo', Codigo);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetMesas(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  mesa: Integer;
  SQL: String;
begin
  try
    mesa := Req.Params['mesa'].ToInteger;
  except
    mesa := 0;
  end;

  // if length(SQL) > 0 then
  // begin
  // conexao.SQL.Add(SQL);
  // conexao.ExecuteSQL;
  // end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('SELECT TIMESTAMPDIFF(SECOND, hora, NOW()) as tempo, ');
  conexao.SQL.Add
    ('m.id_mesa, m.descricao, mt.descricao as descricao1, m.nr_mesa, m.selecionada, m.tot_mesa, m.sts_mesa FROM mesa as m');
  conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
  conexao.SQL.Add('where m.ativo = 1 and mt.ativo = 1');
  if mesa > 0 then
  begin
    conexao.SQL.Add('and nr_mesa = ' + mesa.ToString);
  end;
  conexao.SQL.Add('order by mt.id_mesa_tipo, m.nr_mesa');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  Delivery: Integer;
begin
  try
    ID := Req.Params['categoria'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;
  try
    Delivery := Req.Params['delivery'].ToInteger;
  except
    Delivery := 0;
  end;

  conexao := Tconexao.Create('Util');
  // conexao.SQL.Add('select * from produto where codigo_grupo = :ID order by codigo_interno asc');

  conexao.SQL.Add('select ');
  conexao.SQL.Add('p.codigo,');
  conexao.SQL.Add('p.codigo_grupo,');
  conexao.SQL.Add('p.codigo_interno,');
  conexao.SQL.Add('p.controle_estoque,');
  conexao.SQL.Add('p.nome_produto,');
  conexao.SQL.Add('p.descricao,');
  conexao.SQL.Add('p.valor_custo,');
  conexao.SQL.Add('p.valor_lucro,');
  conexao.SQL.Add('p.observacao,');
  conexao.SQL.Add('p.id_site,');
  conexao.SQL.Add('p.valor_embalagem_delivery,');
  conexao.SQL.Add('CASE');
  conexao.SQL.Add('    WHEN ' + Delivery.ToString + ' = 1 THEN ');
  conexao.SQL.Add('		CASE');
  conexao.SQL.Add
    ('			WHEN pp.valor > 0 THEN pp.valor+p.valor_embalagem_delivery');
  conexao.SQL.Add('			ELSE p.valor_venda+p.valor_embalagem_delivery');
  conexao.SQL.Add('			END    ');
  conexao.SQL.Add('    ELSE ');
  conexao.SQL.Add('			CASE');
  conexao.SQL.Add('			WHEN pp.valor > 0 THEN pp.valor');
  conexao.SQL.Add('			ELSE p.valor_venda');
  conexao.SQL.Add('			END ');
  conexao.SQL.Add('END as valor_venda');
  conexao.SQL.Add('from produto  p');
  conexao.SQL.Add
    ('left join produto_preco pp on pp.id_produto = p.codigo and ');
  conexao.SQL.Add('CASE');
  conexao.SQL.Add('    WHEN WEEKDAY(current_date) = 0 THEN pp.segunda = 1');
  conexao.SQL.Add('    WHEN WEEKDAY(current_date) = 1 THEN pp.terca = 1');
  conexao.SQL.Add('    WHEN WEEKDAY(current_date) = 2 THEN pp.quarta = 1');
  conexao.SQL.Add('    WHEN WEEKDAY(current_date) = 3 THEN pp.quinta = 1');
  conexao.SQL.Add('    WHEN WEEKDAY(current_date) = 5 THEN pp.sexta = 1');
  conexao.SQL.Add('    WHEN WEEKDAY(current_date) = 6 THEN pp.sabado = 1');
  conexao.SQL.Add('    ELSE pp.domingo = 1');
  conexao.SQL.Add('END');
  conexao.SQL.Add('where p.codigo_grupo = :ID ');
  conexao.SQL.Add('order by p.codigo_interno asc');
  conexao.Parametros('ID', ID);
  Res.Send((conexao.ConsultaSQL.ToString));

  conexao.Free;
end;

procedure DoGetProdutoBusca(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: Tconexao;
  Busca: String;
begin

  try
    Busca := UpperCase(Req.Params['busca']);
  except
    // Res.Send('').Status(500);
    // exit;
  end;

  conexao := Tconexao.Create('Util');
  if length(Busca) > 0 then
  begin
    conexao.SQL.Add
      ('select * from produto where ativo = 1 and upper(nome_produto) like ' +
      QuotedStr('%' + Busca + '%') + ' order by codigo_grupo, codigo_interno');
  end
  else
  begin
    conexao.SQL.Add
      ('select * from produto where ativo = 1 order by codigo_grupo, codigo_interno');
  end;

  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoGetProdutoAdiciona(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  Resultado: TJSONArray;
begin

  try
    ID := Req.Params['produto'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;
  Res.Send<TJSONArray>(GetProdutoAdiciona(Req.Params['produto']));

end;

procedure DoGetTest(Req: THorseRequest; Res: THorseResponse; Next: TProc);

begin
  Res.Send('OK');
end;

procedure DoGetMesa(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  mesa: Integer;

begin
  try
    mesa := Req.Params['mesa'].ToInteger;
  except
    mesa := 0;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('SELECT mt.descricao as descricao_mesa, m.nr_mesa, m.tot_mesa, m.selecionada as pedido, TIMESTAMPDIFF(SECOND, m.hora, NOW()) as tempo FROM mesa as m');
  conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
  conexao.SQL.Add('where m.ativo = 1 and mt.ativo = 1');
  conexao.SQL.Add('and id_mesa = ' + mesa.ToString);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostPedidoProduto(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

begin

  AdicionaProduto(Req.Body, Req, Res, Next);

end;

procedure DoGetProdutoPedido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: Tconexao;
  Codigo: Integer;
  Tipo: Integer;
begin
  try
    Codigo := Req.Params['mesa'].ToInteger;
  except
    Codigo := 0;
    Res.Send('').Status(500);
    exit;
  end;
  try
    Tipo := Req.Params['tipo'].ToInteger;
  except
    Tipo := 0;
    Res.Send('').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('SELECT pp.codigo, p.nome_produto, pp.quantidade, ');
  conexao.SQL.Add('REPLACE(pp.valor_total, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as valor_total');
  conexao.SQL.Add('FROM pedido_produtos as pp');
  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');

  case Tipo of
    1:
      begin
        // Mesa
        conexao.SQL.Add('join mesa as m on pp.codigo_pedido = m.selecionada');
        conexao.SQL.Add('where m.id_mesa = :id and m.selecionada > 0');
      end;
    2:
      begin
        // Pedido
        conexao.SQL.Add('where pp.codigo_pedido = :id ');
      end;
  end;

  conexao.Parametros('id', Codigo);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoGetProdutoPedidoItens(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    ID := 0;
    Res.Send('').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('select CONCAT(nomeclatura,' + QuotedStr(' - ') +
    ',group_concat(descricao),' + QuotedStr(', ') +
    ') as dados, 0 as zero from pedido_produto_sap where codigo_pedido_produto = :id and descricao <> '
    + QuotedStr('') + ' group by nomeclatura');
  conexao.Parametros('id', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoDeletPedidoPagamento(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('delete from caixa_movimento where id = :codigo');
  conexao.Parametros('codigo', Req.Params['id'].ToInteger);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('delete from caixa_movimento_produto where id_caixa_movimento = :codigo');
  conexao.Parametros('codigo', Req.Params['id'].ToInteger);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetPedidoPagamento(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('SELECT * FROM caixa_movimento');
  conexao.SQL.Add
    ('join tipo_pagamento on tipo_pagamento.codigo = caixa_movimento.id_tipo_pagamento');
  conexao.SQL.Add
    ('where caixa_movimento.tipo = 1 and caixa_movimento.id_pedido = :pedido ');
  conexao.Parametros('pedido', Req.Params['pedido'].ToInteger);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPutPagamento(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  retorno: Integer;
begin
  retorno := MovimentoCaixa(Req.Params['caixa'].ToInteger,
    Req.Params['pedido'].ToInteger, Req.Params['tipo'].ToInteger, 1,
    strtofloat(StringReplace(Req.Params['total'], '.', ',', [])), '', 0);
  Res.Send('{"codigo":' + retorno.ToString + '}');
end;

procedure DoPutPagamentoPIX(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  // THorse.Put('/v1/pedido/pagamento/pix/:caixa/:pedido/:tipo/:total',
  MovimentoCaixa(Req.Params['caixa'].ToInteger, Req.Params['pedido'].ToInteger,
    Req.Params['tipo'].ToInteger, 1,
    strtofloat(StringReplace(Req.Params['total'], '.', ',', [])),
    'Recebimento PIX', 0);
end;

procedure DoPutFinalizaPedido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: Tconexao;
  mesa: Integer;
  Impressao: Integer;
  Desconto: Real;
  Acrecimo: Real;
  TipoPagamento: Integer;
  Taxa: Real;
  Caixa: Integer;
  Motoboy: Integer;

  DadosMesa: TFDMemTable;
  DadosCliente: TFDMemTable;
  CodigoCliente: Integer;
  Total: Real;
  CodigoPedido: Integer;
  Aux: Integer;
  CodigoPedidoDia: Integer;
  CodigoSite: Integer;

  DadosPagamento: TFDMemTable;
  Descricao: String;
  CodigoAux: Integer;
  Emitir: Integer;
  Requisicao: iRequisicao;

begin
  try
    CodigoPedido := Req.Params['pedido'].ToInteger;
  except

    exit;
  end;
  try
    Emitir := Req.Params['nota'].ToInteger;
  except
    Emitir := 0;
  end;

  try
    mesa := Req.Params['mesa'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    TipoPagamento := Req.Params['tipopagamento'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Impressao := Req.Params['impressao'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Desconto := Req.Params['desconto'].ToDouble / 100;

  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Acrecimo := Req.Params['acrecimo'].ToDouble;
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Taxa := Req.Params['taxaentrega'].ToDouble;
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Motoboy := Req.Params['motoboy'].ToInteger;
  except
    Motoboy := 0;
  end;

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('SELECT * FROM mesa where selecionada = :selecionada');
  conexao.Parametros('selecionada', CodigoPedido);
  try
    mesa := conexao.FieldByName('id_mesa');
  except
    mesa := 0;
  end;

  if mesa > 0 then
  begin

    DadosMesa := TFDMemTable.Create(nil);
    DadosCliente := TFDMemTable.Create(nil);
    conexao.SQL.Add
      ('SELECT m.tot_mesa,m.selecionada, m.id_mesa, concat(mt.descricao,' +
      QuotedStr(' ') + ',m.nr_mesa) as mesa FROM mesa as m');
    conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
    conexao.SQL.Add('where id_mesa = :id');
    conexao.Parametros('id', mesa);
    DadosMesa.LoadFromJSON(conexao.ConsultaSQL);

    Total := DadosMesa.FieldByName('tot_mesa').AsFloat;
    CodigoPedido := DadosMesa.FieldByName('selecionada').AsInteger;

    conexao.SQL.Add('SELECT * FROM cliente where celular = :id');
    conexao.Parametros('id', DadosMesa.FieldByName('id_mesa').AsString);
    DadosCliente.LoadFromJSON(conexao.ConsultaSQL);

    if DadosCliente.RecordCount = 0 then
    begin
      // conexao.SQL.Add('select max(codigo)+1 as id, 0 as zero from cliente');
      CodigoCliente := conexao.GerarID('cliente', 'codigo');

      conexao.SQL.Add
        ('insert into cliente (codigo, nome, celular,ativo,bloqueado) values (:codigo,:nome,:celular,1,1)');
      conexao.Parametros('codigo', CodigoCliente);
      conexao.Parametros('nome', DadosMesa.FieldByName('mesa').AsString);
      conexao.Parametros('celular', DadosMesa.FieldByName('id_mesa').AsInteger);
      conexao.ExecuteSQL;

    end
    else
    begin
      CodigoCliente := DadosCliente.FieldByName('codigo').AsInteger;
    end;
    Total := (Total - Desconto) + Taxa + Acrecimo;

    // conexao.SQL.Add
    // ('SELECT max(codigo_pedido_dia)+1 as max, 0 as zero FROM pedido where data_pedido = curdate()');
    //
    // try
    // CodigoPedidoDia := conexao.FieldByName('max');
    // except
    // CodigoPedidoDia := 1;
    // end;
    CodigoPedidoDia := 1;

    conexao.SQL.Add
      ('update pedido set hora_entregue = CURRENT_TIME(),codigo_pedido_dia = :pedidodia, status = 6, codigo_cliente = :cliente, valor_desconto = :desconto,');
    conexao.SQL.Add
      ('valor_taxa_entrega = :taxa, servico = :servico, valor_total_pedido = :total,valor_pedido = :vlpedido, tipo_pagamento = :pag, id_ficha = :ficha, ficha_faturada = :fichafaturada, desc_ficha = :desc, pedido_site = desc_ficha');
    conexao.SQL.Add('where codigo = :codigo');
    conexao.Parametros('cliente', CodigoCliente);
    conexao.Parametros('desconto', Desconto);
    conexao.Parametros('taxa', Taxa);
    conexao.Parametros('total', Total);
    conexao.Parametros('vlpedido', Total);
    conexao.Parametros('pag', TipoPagamento);
    conexao.Parametros('ficha', DadosMesa.FieldByName('id_mesa').AsInteger);
    conexao.Parametros('pedidodia', CodigoPedidoDia);
    conexao.Parametros('servico', Acrecimo);

    conexao.Parametros('fichafaturada', DadosMesa.FieldByName('id_mesa')
      .AsInteger);
    conexao.Parametros('desc', DadosMesa.FieldByName('mesa').AsString);
    conexao.Parametros('codigo', CodigoPedido);
    conexao.ExecuteSQL;

    conexao.SQL.Add
      ('update mesa set sts_mesa = 0, tot_mesa = 0, selecionada = 0, descricao = null where selecionada = :id');
    conexao.Parametros('id', CodigoPedido);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add
    ('update pedido set status = 6, nfce_imprimir = :nfce_imprimir where codigo =:codigo');
  conexao.Parametros('codigo', CodigoPedido);
  conexao.Parametros('nfce_imprimir', Impressao);
  conexao.ExecuteSQL;

  DadosPagamento := TFDMemTable.Create(NIL);
  DadosPagamento.LoadFromJSON(Req.Body);
  TipoPagamento := DadosPagamento.RecordCount;
  while not DadosPagamento.Eof do
  begin

    Descricao := '#' + FormatFloat('000000', CodigoPedido) + ' - ';
    if Assigned(DadosMesa) then
    begin
      Descricao := Descricao + ' - ' + DadosMesa.FieldByName('mesa').AsString;
    end;

    if TipoPagamento > 1 then
    begin
      Descricao := Descricao + ' PAGAMENTO PARCIAL ' +
        DadosPagamento.FieldByName('DESCRICAO_TIPO_PAG').AsString;
    end
    else
    begin
      Descricao := Descricao + ' PAGAMENTO TOTAL ' + DadosPagamento.FieldByName
        ('DESCRICAO_TIPO_PAG').AsString;
    end;
    Total := DadosPagamento.FieldByName('VALOR').AsFloat;
    try

      CodigoCliente := DadosPagamento.FieldByName('cliente').AsInteger;
    except
      conexao.SQL.Clear;
    end;

    if DadosPagamento.FieldByName('tipo').AsInteger = 2 then
    begin
      conexao.SQL.Clear;
      conexao.SQL.Add('delete from caixa_movimento where id = :id');
      conexao.Parametros('id', DadosPagamento.FieldByName('id').AsInteger);
      conexao.ExecuteSQL;
      DadosPagamento.Edit;
      DadosPagamento.FieldByName('id').AsInteger := 0;
      DadosPagamento.Post;

    end;

    if DadosPagamento.FieldByName('id').AsInteger = 0 then
    begin
      MovimentoCaixa(Caixa, CodigoPedido,
        DadosPagamento.FieldByName('ID_TIPO_PAGAMENTO').AsInteger, 1, Total,
        Descricao, CodigoCliente);
    end;

    // CodigoAux := conexao.GerarID('pedido_tipo_pagamento', 'codigo');
    // conexao.SQL.Clear;
    // conexao.SQL.Add
    // ('insert pedido_tipo_pagamento into (codigo,codigo_pedido,tipo_pagamento,troco_para,valor_pago)');
    // conexao.SQL.Add('value (:codigo,:pedido,:pagamento,0,:pago)');
    // conexao.Parametros('codigo', CodigoAux);
    // conexao.Parametros('pedido', CodigoPedido);
    // conexao.Parametros('pagamento',
    // DadosPagamento.FieldByName('ID_TIPO_PAGAMENTO').AsInteger);
    // conexao.Parametros('pago', Total);
    // conexao.ExecuteSQL;

    DadosPagamento.Next;
  end;

  try
    if Emitir = 1 then
    begin
      if frmServidor.Configuracoes.FieldByName('nfce').AsInteger > 0 then
      begin
        conexao.SQL.Clear;
        conexao.SQL.Add
          ('update pedido set nfce_emite = 1 where codigo = :pedido');
        conexao.Parametros('pedido', CodigoPedido);
        conexao.ExecuteSQL;
      end;
    end;
  except

  end;

  if Motoboy > 0 then
  begin
    conexao.SQL.Clear;
    conexao.SQL.Add('delete from pedido_motoboy where codigo_pedido = :id');
    conexao.Parametros('id', CodigoPedido);
    conexao.ExecuteSQL;

    CodigoAux := conexao.GerarID('pedido_motoboy', 'codigo');
    conexao.SQL.Add
      ('insert into pedido_motoboy (codigo,codigo_motoboy,codigo_pedido,hora_pego_motoboy,hora_entrega,status) values');
    conexao.SQL.Add('(:codigo,:motoboy,:pedido,curtime(),curtime(),1)');
    conexao.Parametros('codigo', CodigoAux);
    conexao.Parametros('pedido', CodigoPedido);
    conexao.Parametros('motoboy', Motoboy);;
    conexao.ExecuteSQL;
  end;

  if Assigned(DadosMesa) then
    DadosMesa.Free;

  if Assigned(DadosCliente) then
    DadosCliente.Free;
  conexao.SQL.Clear;
  conexao.SQL.Add
    ('update mesa set tot_mesa = 0, selecionada = 0 where selecionada = :codigo');
  conexao.Parametros('codigo', CodigoPedido);
  conexao.ExecuteSQL;

  try
    conexao.SQL.Add('select * from pedido where codigo = :codigo');
    conexao.Parametros('codigo', CodigoPedido);
    CodigoSite := conexao.FieldByName('id_pedido_site');
  except
    CodigoSite := 0;
  end;

  if CodigoSite > 100000 then
  begin
    TThread.CreateAnonymousThread(
      procedure
      var
        Requisicao: iRequisicao;
      begin
        try
          Requisicao := iRequisicao.Create(nil);
          try
            Requisicao.BaseURL :=
              'https://ws.goopedir.com/v1/atualiza_status_pedido.php?codigo=' +
              CodigoSite.ToString + '&status=Finalizado';
            Requisicao.Execute;
          finally
            Requisicao.Free; // Libere o recurso adequadamente
          end;
        except

        end;
      end).start; // Inicie a Thread1
  end;

  if Impressao = 1 then
  begin
    conexao.SQL.Add
      ('insert into impressao_pedido_nfce (id_pedido) values (:codigo)');
    conexao.Parametros('codigo', CodigoPedido);
    conexao.ExecuteSQL;
  end;

  // DadosPagamento.Free;
  conexao.Free;
end;

procedure DoGetProdutoSabores(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  ID: Integer;
begin

  try
    ID := Req.Params['produto'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  Res.Send<TJSONArray>(GetProdutoSabores(Req.Params['produto']));
end;

procedure DoDeletePedidoProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin

  try
    // ID := Req.Params['id'].ToInteger;
    ApagarProduto(Req.Params['id'].ToInteger, '', 0);
  except
    Res.Send('').Status(500);
    exit;
  end;
end;

procedure DoGetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Usuario: String;
  Senha: String;
begin
  try
    Usuario := Req.Params['usuario'];
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Senha := Req.Params['senha'];
  except
    Res.Send('').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('SELECT * FROM usuario where nome = :usuario and senha = md5(:senha);');
  conexao.Parametros('usuario', Usuario);
  conexao.Parametros('senha', Senha);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

// DoGetTotalMotoboy

procedure DoGetTotal(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Origem: Integer;

  DataInicial: TDate;
  DataFinal: TDate;
  HoraInicial: TTime;
  HoraFinal: TTime;

  Pedidos: Integer;
  PedidosWhatsapp: Integer;
  PedidosWhatsappVemBuscar: Integer;
  PedidosWhatsappDelivery: Integer;
  PedidoSite: Integer;
  PedidoSiteDelivery: Integer;
  PedidoSiteVemBuscar: Integer;
  PedidosFicha: Integer;

  TotalGeral: Real;
  TotalWhatsapp: Real;
  TotalSite: Real;
  TotalFichaFechada: Real;
  TotalFichaAberta: Real;

  WhatsappDelivery: Real;
  WhatsappVemBuscar: Real;
  SiteDelivery: Real;
  SiteVemBuscar: Real;

  DadosJSON: TJSONObject;

begin
  conexao := Tconexao.Create('Util');
  DadosJSON := TJSONObject.Create;
  PedidosWhatsapp := 0;
  TotalWhatsapp := 0;

  PedidoSite := 0;
  TotalSite := 0;

  TotalFichaFechada := 0;
  TotalFichaAberta := 0;

  WhatsappDelivery := 0;
  WhatsappVemBuscar := 0;
  SiteDelivery := 0;
  SiteVemBuscar := 0;

  PedidosWhatsappVemBuscar := 0;
  PedidosWhatsappDelivery := 0;

  try
    DataInicial := TransformaData(Req.Params['dataini']);
  except
    DataInicial := Date;
  end;
  try
    DataFinal := TransformaData(Req.Params['datafim']);
  except
    DataFinal := Date;
  end;
  try
    HoraInicial := TransformaHora(Req.Params['horaini']);
  except
    HoraInicial := StrToTime('00:00:00');
  end;
  try
    HoraFinal := TransformaHora(Req.Params['horafim']);
  except
    HoraInicial := StrToTime('23:59:59');
  end;

  {
    Origem 1 - Whatsapp
    Origem 2 - Site
    Origem 3 - Ficha
  }
  // Whatsapp
  // Delivery
  Origem := 1;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select REPLACE(valor_total_pedido, ' + QuotedStr('.') + ', '
    + QuotedStr(',') + ') as valor, 0 as total from pedido');
  conexao.SQL.Add('where data_pedido between :datainicio and :datafim');
  conexao.SQL.Add('and hora_pedido >= :horainicio and hora_pedido <= :horafim');
  conexao.SQL.Add
    ('and status > 0 and origem = :origem and codigo_cliente_endereco > :cliente');
  conexao.Parametros('datainicio', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('datafim', FormatDateTime('yyyy-mm-dd', DataFinal));
  conexao.Parametros('horainicio', FormatDateTime('hh:mm:ss', HoraInicial));
  conexao.Parametros('horafim', FormatDateTime('hh:mm:ss', HoraFinal));
  conexao.Parametros('origem', Origem);
  conexao.Parametros('cliente', 0);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  PedidosWhatsapp := PedidosWhatsapp + Dados.RecordCount;
  PedidosWhatsappDelivery := Dados.RecordCount;
  while not Dados.Eof do
  begin
    TotalWhatsapp := TotalWhatsapp + Dados.FieldByName('valor').AsFloat;
    WhatsappVemBuscar := WhatsappVemBuscar + Dados.FieldByName('valor').AsFloat;
    Dados.Next;
  end;
  Dados.Free;

  // VemBuscar
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select REPLACE(valor_total_pedido, ' + QuotedStr('.') + ', '
    + QuotedStr(',') + ') as valor, 0 as total from pedido');
  conexao.SQL.Add('where data_pedido between :datainicio and :datafim');
  conexao.SQL.Add('and hora_pedido >= :horainicio and hora_pedido <= :horafim');
  conexao.SQL.Add
    ('and status > 0 and origem = :origem and codigo_cliente_endereco = :cliente');
  conexao.Parametros('datainicio', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('datafim', FormatDateTime('yyyy-mm-dd', DataFinal));
  conexao.Parametros('horainicio', FormatDateTime('hh:mm:ss', HoraInicial));
  conexao.Parametros('horafim', FormatDateTime('hh:mm:ss', HoraFinal));
  conexao.Parametros('origem', Origem);
  conexao.Parametros('cliente', 0);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  PedidosWhatsappVemBuscar := Dados.RecordCount;
  PedidosWhatsapp := PedidosWhatsapp + Dados.RecordCount;
  while not Dados.Eof do
  begin
    TotalWhatsapp := TotalWhatsapp + Dados.FieldByName('valor').AsFloat;
    WhatsappDelivery := WhatsappDelivery + Dados.FieldByName('valor').AsFloat;
    Dados.Next;
  end;
  Dados.Free;

  // Site
  // Delivery
  Origem := 2;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select REPLACE(valor_total_pedido, ' + QuotedStr('.') + ', '
    + QuotedStr(',') + ') as valor, 0 as total from pedido');
  conexao.SQL.Add('where data_pedido between :datainicio and :datafim');
  conexao.SQL.Add('and hora_pedido >= :horainicio and hora_pedido <= :horafim');
  conexao.SQL.Add
    ('and status > 0 and origem = :origem and codigo_cliente_endereco > :cliente');
  conexao.Parametros('datainicio', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('datafim', FormatDateTime('yyyy-mm-dd', DataFinal));
  conexao.Parametros('horainicio', FormatDateTime('hh:mm:ss', HoraInicial));
  conexao.Parametros('horafim', FormatDateTime('hh:mm:ss', HoraFinal));
  conexao.Parametros('origem', Origem);
  conexao.Parametros('cliente', 0);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  PedidoSite := PedidoSite + Dados.RecordCount;
  PedidoSiteDelivery := Dados.RecordCount;
  while not Dados.Eof do
  begin
    TotalSite := TotalSite + Dados.FieldByName('valor').AsFloat;
    SiteVemBuscar := SiteVemBuscar + Dados.FieldByName('valor').AsFloat;
    Dados.Next;
  end;
  Dados.Free;

  // VemBuscar
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select REPLACE(valor_total_pedido, ' + QuotedStr('.') + ', '
    + QuotedStr(',') + ') as valor, 0 as total from pedido');
  conexao.SQL.Add('where data_pedido between :datainicio and :datafim');
  conexao.SQL.Add('and hora_pedido >= :horainicio and hora_pedido <= :horafim');
  conexao.SQL.Add
    ('and status > 0 and origem = :origem and codigo_cliente_endereco = :cliente');
  conexao.Parametros('datainicio', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('datafim', FormatDateTime('yyyy-mm-dd', DataFinal));
  conexao.Parametros('horainicio', FormatDateTime('hh:mm:ss', HoraInicial));
  conexao.Parametros('horafim', FormatDateTime('hh:mm:ss', HoraFinal));
  conexao.Parametros('origem', Origem);
  conexao.Parametros('cliente', 0);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  PedidoSiteVemBuscar := Dados.RecordCount;
  PedidoSite := PedidoSite + Dados.RecordCount;
  while not Dados.Eof do
  begin
    TotalSite := TotalSite + Dados.FieldByName('valor').AsFloat;
    SiteDelivery := SiteDelivery + Dados.FieldByName('valor').AsFloat;
    Dados.Next;
  end;
  Dados.Free;

  // Ficha
  Origem := 3;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select REPLACE(valor_total_pedido, ' + QuotedStr('.') + ', '
    + QuotedStr(',') + ') as valor, 0 as total from pedido');
  conexao.SQL.Add('where data_pedido between :datainicio and :datafim');
  conexao.SQL.Add('and hora_pedido >= :horainicio and hora_pedido <= :horafim');
  conexao.SQL.Add
    ('and status > 0 and origem = :origem and codigo_cliente_endereco > :cliente');
  conexao.Parametros('datainicio', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('datafim', FormatDateTime('yyyy-mm-dd', DataFinal));
  conexao.Parametros('horainicio', FormatDateTime('hh:mm:ss', HoraInicial));
  conexao.Parametros('horafim', FormatDateTime('hh:mm:ss', HoraFinal));
  conexao.Parametros('origem', Origem);
  conexao.Parametros('cliente', 0);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  while not Dados.Eof do
  begin
    TotalFichaFechada := TotalFichaFechada + Dados.FieldByName('valor').AsFloat;
    SiteVemBuscar := SiteVemBuscar + Dados.FieldByName('valor').AsFloat;
    Dados.Next;
  end;
  Dados.Free;

  Pedidos := PedidosWhatsapp + PedidoSite + PedidosFicha;
  DadosJSON.AddPair('pedidos', Pedidos.ToString);
  DadosJSON.AddPair('pedidowhatsapp', PedidosWhatsapp.ToString);
  DadosJSON.AddPair('pedidossite', PedidoSite.ToString);
  DadosJSON.AddPair('pedidosficha', PedidosFicha.ToString);
  TotalGeral := TotalWhatsapp + TotalSite + TotalFichaFechada +
    TotalFichaAberta;
  DadosJSON.AddPair('total', FormatFloat('#0.00', TotalGeral));
  DadosJSON.AddPair('totalwhatsapp', FormatFloat('#0.00', TotalWhatsapp));
  DadosJSON.AddPair('totalsite', FormatFloat('#0.00', TotalSite));
  DadosJSON.AddPair('totalfichafechada', FormatFloat('#0.00',
    TotalFichaFechada));
  DadosJSON.AddPair('totalfichaaberta', FormatFloat('#0.00', TotalFichaAberta));
  DadosJSON.AddPair('totalficha', FormatFloat('#0.00',
    TotalFichaFechada + TotalFichaAberta));

  DadosJSON.AddPair('whatsappdelivery', FormatFloat('#0.00', WhatsappDelivery));
  DadosJSON.AddPair('whatsappvembuscar', FormatFloat('#0.00',
    WhatsappVemBuscar));
  DadosJSON.AddPair('sitedelivery', FormatFloat('#0.00', SiteDelivery));
  DadosJSON.AddPair('sitevembuscar', FormatFloat('#0.00', SiteVemBuscar));
  DadosJSON.AddPair('pedidoswhatsappvembuscar',
    PedidosWhatsappVemBuscar.ToString);
  DadosJSON.AddPair('pedidoswhatsappdelivery',
    PedidosWhatsappDelivery.ToString);
  DadosJSON.AddPair('pedidositedelivery', PedidoSiteDelivery.ToString);
  DadosJSON.AddPair('pedidositevembuscar', PedidoSiteVemBuscar.ToString);

  Res.Send(DadosJSON.ToString);

  DadosJSON.Free;
  conexao.Free;

end;

procedure DoGetTotalMotoboy(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;

  DataInicial: TDate;
  DataFinal: TDate;
  HoraInicial: TTime;
  HoraFinal: TTime;

begin
  conexao := Tconexao.Create('Util');

  try
    DataInicial := TransformaData(Req.Params['dataini']);
  except
    DataInicial := Date;
  end;
  try
    DataFinal := TransformaData(Req.Params['datafim']);
  except
    DataFinal := Date;
  end;
  try
    HoraInicial := TransformaHora(Req.Params['horaini']);
  except
    HoraInicial := StrToTime('00:00:00');
  end;
  try
    HoraFinal := TransformaHora(Req.Params['horafim']);
  except
    HoraInicial := StrToTime('23:59:59');
  end;

  conexao.SQL.Add
    ('select pm.codigo_motoboy, upper(m.nome) as motoboy, ce.bairro, group_concat(p.codigo_pedido_dia) as pedidos,');
  conexao.SQL.Add('group_concat(CONCAT(' + QuotedStr(' [') +
    ',p.codigo_pedido_dia,' + QuotedStr('] ') +
    ',tp.descricao)) as pagamento, valor_taxa_entrega as taxa, sum(valor_taxa_entrega) as taxa_total, valor_total_pedido as pedido, sum(valor_total_pedido) as pedido_total, count(p.codigo_pedido_dia)*10 as percentual from pedido as p');
  conexao.SQL.Add('join pedido_motoboy as pm on pm.codigo_pedido = p.codigo');
  conexao.SQL.Add('join motoboy as m on pm.codigo_motoboy = m.codigo');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add
    ('join cliente_endereco as ce on ce.codigo = p.codigo_cliente_endereco');
  conexao.SQL.Add('where p.data_pedido between :datainicio and :datafim');
  conexao.SQL.Add('and p.hora_pedido between :horainicio and :horafim');
  conexao.SQL.Add('group by ce.bairro, pm.codigo_motoboy');
  conexao.SQL.Add('order by pm.codigo_motoboy');
  conexao.Parametros('datainicio', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('datafim', FormatDateTime('yyyy-mm-dd', DataFinal));
  conexao.Parametros('horainicio', FormatDateTime('hh:mm:ss', HoraInicial));
  conexao.Parametros('horafim', FormatDateTime('hh:mm:ss', HoraFinal));

  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;

end;

procedure DoGetPedidos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  DataInicial: TDate;
  DataFinal: TDate;
  HoraInicial: TTime;
  HoraFinal: TTime;
  Tipo: String;
  Faturado: String;
  SQL: String;
  MesesAno: TArray<string>;
  MesAno: string;
  Dados: TFDMemTable;
begin
  try
    DataInicial := TransformaData(Req.Params['dataini']);
  except
    DataInicial := Date;
  end;
  try
    DataFinal := TransformaData(Req.Params['datafim']);
  except
    DataFinal := Date;
  end;
  try
    HoraInicial := TransformaHora(Req.Params['horaini']);
  except
    HoraInicial := StrToTime('00:00:00');
  end;
  try
    HoraFinal := TransformaHora(Req.Params['horafim']);
  except
    HoraInicial := StrToTime('23:59:59');
  end;

  try
    HoraFinal := TransformaHora(Req.Params['horafim']);
  except
    HoraInicial := StrToTime('23:59:59');
  end;

  try
    Tipo := (Req.Params['tipo']) + ',4';
  except
    Tipo := '1,2,3,4';
  end;

  try
    Faturado := (Req.Params['faturado']);
  except
    Faturado := '';
  end;

  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  MesesAno := GerarArrayMesesAno(DataInicial, DataFinal);
  for MesAno in MesesAno do
  begin
    SQL := UnionPedio('pedido_' + MesAno, Tipo);
    conexao.SQL.Add(SQL);
    conexao.Parametros('inicial', FormatDateTime('yyyy-mm-dd', DataInicial));
    conexao.Parametros('final', FormatDateTime('yyyy-mm-dd', DataFinal));
    Dados.LoadFromJSON(conexao.ConsultaSQL);
  end;

  SQL := UnionPedio('pedido', Tipo);
  SQL := SQL + ' order by data, hora desc,codigo_dia';
  conexao.SQL.Add(SQL);
  conexao.Parametros('inicial', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('final', FormatDateTime('yyyy-mm-dd', DataFinal));
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  Res.Send<TJSONArray>(Dados.ToJSONArray());
  Dados.Free;
  conexao.Free;
end;

procedure DoGetCaixa(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Usuario: Integer;
begin

  try
    Usuario := Req.Params['usuario'].ToInteger;
  except
    Res.Send('Usuário não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('SELECT * FROM caixa where id_usuario = :caixa and status = 1');
  conexao.Parametros('caixa', Usuario);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostAberturaCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Usuario: Integer;
  Valor: Real;
  Codigo: Integer;
  Dados: TFDMemTable;
begin

  try
    Usuario := Req.Params['usuario'].ToInteger;
  except
    Res.Send('Usuário não informado').Status(500);
    exit;
  end;

  try
    Valor := Req.Params['valor'].ToDouble;
  except
    Res.Send('valor não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT * FROM caixa where id_usuario = :caixa and status = 1');
  conexao.Parametros('caixa', Usuario);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount = 0 then
  begin
    Codigo := conexao.GerarID('caixa', 'id');
    conexao.SQL.Add
      ('insert into caixa (id,id_usuario,data_abertura,hora_abertura,valor_abertura,status) values (:id,:usuario,current_date,current_time,:valor,1)');
    conexao.Parametros('id', Codigo);
    conexao.Parametros('usuario', Usuario);
    conexao.Parametros('valor', Valor);
    conexao.ExecuteSQL;

  end;
  Dados.Free;
  conexao.Free;
end;

procedure DoGetTipoPagamento(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('select * from tipo_pagamento where ativo = 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostFechamentoPedido(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Caixa: Integer;
  SQL: String;
  ValorTotal: Real;
  Descricao: String;
  Pedido: Integer;
begin
  try
    Pedido := Req.Params['pedido'].ToInteger;
  except
    Res.Send('Pedido não informado').Status(500);
    exit;
  end;

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa não informado').Status(500);
    exit;
  end;
  Dados := TFDMemTable.Create(nil);

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from pedido as p');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add('where p.codigo = :id');
  conexao.Parametros('id', Pedido);

  Dados.LoadFromJSON(conexao.ConsultaSQL);
  if Dados.RecordCount > 0 then
  begin
    Dados.First;

    while not Dados.Eof do
    begin
      Descricao := '#' + FormatFloat('000000', Dados.FieldByName('codigo')
        .AsInteger) + ' - ';
      Descricao := Descricao + 'PAGAMENTO TOTAL ' +
        Dados.FieldByName('descricao').AsString + ' AUTOMÁTICO';
      MovimentoCaixa(Caixa, Dados.FieldByName('codigo').AsInteger,
        Dados.FieldByName('tipo_pagamento').AsInteger, 1,
        Dados.FieldByName('valor_total_pedido').AsFloat, Descricao, 0);

      conexao.SQL.Add('update pedido set status = 6 where codigo = :codigo');
      conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
      conexao.ExecuteSQL;

      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;
end;

procedure DoGetFechamentoCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;

  if frmServidor.FaturarEmAberto then
    JSON.AddPair('status', false)
  else
    JSON.AddPair('status', true);

  Res.Send<TJSONObject>(JSON);

end;

procedure DoPostFaturarPeido(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Caixa: Integer;
  SQL: String;
  ValorTotal: Real;
  Descricao: String;
begin
  if frmServidor.FaturarEmAberto then
    exit;

  frmServidor.FaturarEmAberto := true;

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa não informado').Status(500);
    exit;
  end;
  Dados := TFDMemTable.Create(nil);

  conexao := Tconexao.Create('Util');
  // conexao.SQL.Add('select * from pedido as p');
  // conexao.SQL.Add('join caixa as c on p.data_pedido >= c.data_abertura');
  // conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  // conexao.SQL.Add('where p.status > 0 and p.tipo_pagamento > 0 and id_caixa is null');
  // conexao.SQL.Add('and c.id = :id');
  conexao.SQL.Add('select p.*, tp.*');
  conexao.SQL.Add('from caixa as c');
  conexao.SQL.Add
    ('join pedido as p on (p.data_pedido >= c.data_abertura and p.status > 0 and p.id_caixa is null) or p.id_caixa = c.id');
  conexao.SQL.Add('join cliente as cc on cc.codigo = p.codigo_cliente');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add('where c.id = :id');
  conexao.Parametros('id', Caixa);

  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    Dados.First;

    while not Dados.Eof do
    begin

      FaturarPedido(Dados.FieldByName('codigo').AsInteger, Caixa);

      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;
  frmServidor.FaturarEmAberto := false;
end;

procedure DoPostFechamentoCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Caixa: Integer;
  SQL: String;
  ValorTotal: Real;
  ID: Integer;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa não informado').Status(500);
    exit;
  end;
  try
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(Req.Body);

    if Dados.RecordCount = 0 then
    begin
      Dados.Free;
      Res.Send('Pagamento não informado').Status(500);
      exit;
    end;

    conexao := Tconexao.Create('Util');

    ValorTotal := 0;
    while not Dados.Eof do
    begin
      try
        MovimentoCaixa(Caixa, 0, Dados.FieldByName('id_tipo_pagamento')
          .AsInteger, 226, Dados.FieldByName('total').AsFloat, 'Computado', 0);
      except

      end;

      try
        MovimentoCaixa(Caixa, 0, Dados.FieldByName('id_tipo_pagamento')
          .AsInteger, 262626, Dados.FieldByName('informado').AsFloat,
          'Informado', 0);
        ValorTotal := ValorTotal + Dados.FieldByName('informado').AsFloat;
      except

      end;
      Dados.Next;
    end;

    conexao.SQL.Add
      ('update caixa set data_fechamento = current_date, hora_fechamento = current_time, status = 2, valor_fechamento = :valor where id = :codigo');
    conexao.Parametros('valor', ValorTotal);
    conexao.Parametros('codigo', Caixa);
    conexao.ExecuteSQL;

    conexao.SQL.Add
      ('update pedido_produtos set codigo_pedido = 0, id_caixa = :codigo where codigo_pedido = -1');
    conexao.Parametros('codigo', Caixa);
    conexao.ExecuteSQL;

    Dados.Free;

    frmServidor.SincronizaCaixa(Caixa);

    // Sincronizar o Caixa

  except
  end;

  conexao.Free;

end;

procedure DoGetAReceber(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Cliente: Integer;
begin
  // codigo
  try
    Cliente := Req.Params['codigo'].ToInteger;
  except
    Cliente := 0;

  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select ');
  conexao.SQL.Add('cr.*,');
  conexao.SQL.Add
    ('cr.id as codigo, c.nome, c.celular, (select sum(valor) from caixa_receber where id_cliente = cr.id_cliente and status = 1) as a_receber,');
  conexao.SQL.Add
    ('caixa.id, caixa.data_abertura, caixa.data_fechamento, caixa.data_fechamento, caixa.hora_fechamento, caixa.valor_fechamento,');
  conexao.SQL.Add('u.nome as usuario, tp.descricao as tipo_pagamento');
  conexao.SQL.Add('from caixa_receber as cr');
  conexao.SQL.Add('join cliente as c on c.codigo = cr.id_cliente');
  conexao.SQL.Add('join caixa on caixa.id = cr.id_caixa');
  conexao.SQL.Add('join usuario as u on u.codigo = caixa.id_usuario');
  conexao.SQL.Add
    ('join tipo_pagamento as tp on tp.codigo = cr.id_tipo_pagamento and tp.movimentacao = 2');
  if Cliente > 0 then
  begin
    conexao.SQL.Add('where cr.id_cliente = :cliente');
    conexao.Parametros('cliente', Cliente);
  end;
  conexao.SQL.Add('order by cr.data, cr.hora desc');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetHistoricoCaixaUltimos7Dias(Req: THorseRequest;
Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;

begin

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select c.id, c.data_abertura,c.hora_abertura, c.data_fechamento, c.hora_fechamento, c.status, c.valor_abertura, c.valor_fechamento, u.nome  from caixa as c');
  conexao.SQL.Add('join usuario as u on c.id_usuario = u.codigo');
  conexao.SQL.Add('where c.status = 2');
  conexao.SQL.Add('order by c.data_abertura desc limit 7');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetHistoricoCaixaTodos(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;

begin

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select c.id, c.data_abertura,c.hora_abertura, c.data_fechamento, c.hora_fechamento, c.status, c.valor_abertura, c.valor_fechamento, u.nome  from caixa as c');
  conexao.SQL.Add('join usuario as u on c.id_usuario = u.codigo');
  conexao.SQL.Add('where c.status = 2');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetPagamentoCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select sum(cm.valor) as total, tp.descricao, cm.id_tipo_pagamento, 0 as informado from caixa_movimento as cm');
  conexao.SQL.Add
    ('join tipo_pagamento as tp on tp.codigo = cm.id_tipo_pagamento');
  conexao.SQL.Add('where cm.id_caixa = :codigo and cm.tipo = 1');
  conexao.SQL.Add('group by cm.id_tipo_pagamento, tp.descricao');
  conexao.Parametros('codigo', Caixa);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetHistoricoCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add
    ('SELECT id,data,hora,CONVERT(descricao USING utf8) as historico, valor, tipo FROM caixa_movimento');
  conexao.SQL.Add('where id_caixa = :codigo');
  conexao.SQL.Add('order by data,hora');
  conexao.Parametros('codigo', Caixa);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetPedidosCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select ');
  conexao.SQL.Add
    ('(select sum(valor) from caixa_movimento where tipo = 2 and id_caixa = :codigo) as sangria,p.codigo, p.codigo_pedido_dia, p.data_pedido,p.hora_pedido, p.valor_pedido,p.valor_desconto,p.valor_taxa_entrega,p.valor_total_pedido,p.id_caixa,cc.nome');
  conexao.SQL.Add('from caixa as c ');
  conexao.SQL.Add
    ('join pedido as p on (p.data_pedido >= c.data_abertura and p.status > 0 and p.id_caixa is null) or p.id_caixa = c.id');
  conexao.SQL.Add('join cliente as cc on cc.codigo = p.codigo_cliente');
  conexao.SQL.Add('where c.id = :codigo');

  conexao.Parametros('codigo', Caixa);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetCaixaDados(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');

  SQL := SQLFormatdaDataMysql('data_abertura') + SQLFormatdaHoraMysql
    ('hora_abertura') + SQLFormatdaValorMysql('valor_abertura') +
    SQLFormatdaDataMysql('data') + SQLFormatdaHoraMysql('hora') +
    SQLFormatdaValorMysql('valor');

  conexao.SQL.Add('SELECT ' + SQL +
    'c.id,cm.tipo , CONVERT(cm.descricao USING utf8) as descricao FROM caixa as c');
  conexao.SQL.Add('left join caixa_movimento as cm on cm.id_caixa = c.id');
  conexao.SQL.Add
    ('left join tipo_pagamento as tp on tp.codigo = cm.id_tipo_pagamento');
  conexao.SQL.Add('where c.id = :codigo');
  conexao.Parametros('codigo', Caixa);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostSangria(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Caixa: Integer;
  Valor: Real;
  Descricao: String;
  JSON: TJSONObject;
begin
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Caixa := JSON.GetValue('caixa').Value.ToInteger;

  Valor := JSON.GetValue('valor').Value.ToDouble;

  Descricao := UpperCase(JSON.GetValue('descricao').Value);

  MovimentoCaixa(Caixa, 0, 0, 2, Valor, 'SANGRIA - ' + UpperCase(Descricao), 0);

end;

procedure DoGetCategoria(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONArray>(GetCategoria(''));
end;

procedure DoGetAllCategoria(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin
  Res.Send<TJSONArray>(GetAllCategoria(''));
end;

procedure DoPostProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  DadosProduto: TFDMemTable;
  SQL: String;
  CodigoAux: Integer;
  Novo: Boolean;

begin

  Dados := TFDMemTable.Create(nil);
  try
    Dados.LoadFromJSON(Req.Body);
  except
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');
  Dados.Edit;
  if Dados.FieldByName('CODIGO').AsInteger = 0 then
  begin
    // Insert
    Dados.FieldByName('CODIGO').AsInteger := conexao.GerarID('produto',
      'codigo');

    if Dados.FieldByName('INTERNO').AsInteger = 0 then
    begin
      Dados.FieldByName('INTERNO').AsInteger :=
        conexao.GerarID('produto', 'codigo_interno');
    end;

    SQL := 'insert into produto (codigo,codigo_interno,data_cadastro,nome_produto,descricao,codigo_grupo,valor_venda';
    SQL := SQL +
      ',ativo,observacao,adicional_personalizado,valor_embalagem_delivery,valor_embalagem_vembusca,usa_tabela_preco,atualizado,modificado_site,valor_ifood) values ';
    SQL := SQL +
      '(:codigo,:interno,current_date,:nome,:descricao,:grupo,:venda,:ativo,1,1,:delivery,:vb,1,0,1,:valor_ifood)';
    Novo := true;
  end
  else
  begin
    DadosProduto := TFDMemTable.Create(nil);
    conexao.SQL.Add('select * from produto where codigo = :id');
    conexao.Parametros('id', Dados.FieldByName('CODIGO').AsInteger);

    DadosProduto.LoadFromJSON(conexao.ConsultaSQL);

    SQL := 'update produto_preco set valor = :valor where id_produto = :produto and valor = :valorold';

    conexao.SQL.Add(SQL);
    conexao.Parametros('valor', Dados.FieldByName('VENDA').AsCurrency);
    conexao.Parametros('produto', Dados.FieldByName('CODIGO').AsInteger);
    conexao.Parametros('valorold', DadosProduto.FieldByName('valor_venda')
      .AsCurrency);
    conexao.ExecuteSQL;

    SQL := 'update produto set codigo_interno = :interno, nome_produto = :nome, descricao = :descricao, codigo_grupo = :grupo, valor_venda = :venda, ativo = :ativo,';
    SQL := SQL +
      'valor_embalagem_delivery = :delivery, valor_embalagem_vembusca = :vb, atualizado = 0, modificado_site = 0, valor_ifood = :valor_ifood where codigo = :codigo';
  end;
  conexao.SQL.Add(SQL);
  conexao.Parametros('codigo', Dados.FieldByName('CODIGO').AsInteger);
  conexao.Parametros('interno', FormatFloat('000000',
    Dados.FieldByName('INTERNO').AsInteger));
  conexao.Parametros('ativo', Dados.FieldByName('ATIVO').AsInteger);
  conexao.Parametros('nome', Dados.FieldByName('NOME').AsString);
  conexao.Parametros('descricao', Dados.FieldByName('DESCRICAO').AsString);
  conexao.Parametros('grupo', Dados.FieldByName('CATEGORIA').AsInteger);
  conexao.Parametros('venda', Dados.FieldByName('VENDA').AsCurrency);
  conexao.Parametros('valor_ifood', Dados.FieldByName('VENDA').AsCurrency +
    ((Dados.FieldByName('VENDA').AsCurrency * frmServidor.TaxaiFood) / 100));
  conexao.Parametros('delivery', Dados.FieldByName('DELIVERY').AsCurrency);
  conexao.Parametros('vb', Dados.FieldByName('VEMBUSCAR').AsCurrency);
  conexao.ExecuteSQL;

  CodigoAux := conexao.GerarID('produto_preco', 'id');
  if Novo then
  begin
    conexao.SQL.Add
      ('insert into produto_preco values (:id,:produto,1,1,1,1,1,1,1,:valor,:inicial,:final)');
    conexao.Parametros('id', CodigoAux);
    conexao.Parametros('produto', Dados.FieldByName('CODIGO').AsInteger);
    conexao.Parametros('valor', Dados.FieldByName('VENDA').AsCurrency);
    conexao.Parametros('inicial', StrToTime('00:00:00'));
    conexao.Parametros('final', StrToTime('23:59:59'));
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add('delete from produto_pizza where codigo_produto = :codigo');
  conexao.Parametros('codigo', Dados.FieldByName('CODIGO').AsInteger);
  conexao.ExecuteSQL;

  if Dados.FieldByName('QTD').AsInteger > 0 then
  begin
    CodigoAux := conexao.GerarID('produto_pizza', 'codigo');
    conexao.SQL.Add
      ('insert into produto_pizza (codigo,codigo_produto,quantidade_sabores,ativo,borda) values (:codigo,:codigo_produto,:quantidade_sabores,:ativo,0)');
    conexao.Parametros('codigo', CodigoAux);
    conexao.Parametros('codigo_produto', Dados.FieldByName('CODIGO').AsInteger);
    conexao.Parametros('quantidade_sabores', Dados.FieldByName('QTD')
      .AsInteger);
    conexao.Parametros('ativo', 0);
    conexao.ExecuteSQL;
  end;

  //

  //

  Dados.Free;
  conexao.Free;
end;

procedure DoGetAllProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  where: String;
begin
  try
    if where = 'all' then
    begin
      where := '';
    end
    else
    begin
      where := Req.Params['busca'];
      // where := 'where lower(concat(p.codigo_interno,tp.descricao,p.nome_produto,p.descricao,p.valor_venda)) like "%'
      // + where + '%"';
      where := 'where upper(concat(CTE.concateno,CTE.concateno2,CTE.categoria,CTE.nome,CTE.descricao,CTE.observacaopro)) like "%'
        + UpperCase(where) +
        '%" or upper(concat(CTE.descricao,CTE.nome,CTE.descricao,CTE.observacaopro)) like "%'
        + UpperCase(where) + '%"';
    end;
  except
    where := '';
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('WITH CTE AS (');
  conexao.SQL.Add('SELECT p.codigo as id, ');
  conexao.SQL.Add
    ('max(p.descricao) as observacaopro, max(p.ativo) as ativo, max(p.codigo_interno) as interno, max(tp.descricao) as descricao, max(p.nome_produto) as nome, max(p.valor_venda) as venda, max(p.id_site) as site,');
  conexao.SQL.Add
    (' (select sum(produto_estoque.quantidade) from produto_estoque where produto_estoque.codigo_produto = p.codigo) as estoque,');
  conexao.SQL.Add
    ('max(p.modificado_site) as modificado, max(p.valor_embalagem_delivery) as delivery, max(p.valor_embalagem_vembusca) as vb, max(p.descricao) as descpro, max(p.codigo_grupo) as categoria, max(pp.codigo) as pizza,  max(pp.quantidade_sabores) as quantidade ,');
  conexao.SQL.Add
    ('upper(concat(pro_adi_personalizado_sabores.descricao,p.descricao)) as concateno,');
  conexao.SQL.Add
    ('upper(group_concat(pro_adi_personalizado_sabores.nome)) as concateno2');
  conexao.SQL.Add('FROM produto as p');
  conexao.SQL.Add('join tipo_produto as tp on tp.codigo = p.codigo_grupo');
  conexao.SQL.Add
    ('left join produto_pizza as pp on pp.codigo_produto = p.codigo');
  conexao.SQL.Add
    ('left join pro_adi_personalizado on pro_adi_personalizado.id_produto = p.codigo');
  conexao.SQL.Add
    ('left join pro_adi_personalizado_sabores on pro_adi_personalizado_sabores.id_pro_adi_personalizado =  pro_adi_personalizado.id');
  conexao.SQL.Add('group by p.codigo, pro_adi_personalizado_sabores.id');
  conexao.SQL.Add('order by p.codigo_interno)');
  conexao.SQL.Add('select ');
  conexao.SQL.Add
    ('CTE.id,CTE.observacaopro,CTE.ativo,CTE.interno,CTE.descricao,CTE.nome,CTE.venda,CTE.site,CTE.modificado,CTE.delivery,CTE.vb,CTE.descpro,CTE.categoria,CTE.quantidade, CTE.estoque');
  conexao.SQL.Add('from CTE');
  conexao.SQL.Add(where);
  conexao.SQL.Add
    ('group by CTE.id,CTE.observacaopro,CTE.ativo,CTE.interno,CTE.descricao,CTE.nome,CTE.venda,CTE.site,CTE.modificado,CTE.delivery,CTE.vb,CTE.descpro,CTE.categoria,CTE.quantidade, CTE.estoque');
  conexao.SQL.Add('order by  CTE.interno, CTE.ativo');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostIngredientes(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  ID: Integer;
  Aux: Integer;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
    exit;
  conexao := Tconexao.Create('Util');

  ID := conexao.GerarID('pro_adi_personalizado', 'id');

  conexao.SQL.Add
    ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,modificado_site) values (:id,:id_produto,:descricao,1,0,:qtd_maxima,0)');
  conexao.Parametros('id', ID);
  conexao.Parametros('id_produto', Dados.FieldByName('IDPRODUTO').AsInteger);
  conexao.Parametros('descricao', 'INGREDIENTES');
  conexao.Parametros('qtd_maxima', Dados.RecordCount);
  conexao.ExecuteSQL;
  Dados.First;

  while not Dados.Eof do
  begin
    Aux := conexao.GerarID('pro_adi_personalizado_sabores', 'id');
    conexao.SQL.Add
      ('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,modificado_site,ativo) values (:id,:id_pro_adi_personalizado,:nome,:descricao,:valor,:modificado_site,:ativo)');
    conexao.Parametros('id', Aux);
    conexao.Parametros('id_pro_adi_personalizado', ID);
    conexao.Parametros('nome', Dados.FieldByName('DESCRICAO').AsString);
    conexao.Parametros('descricao', '');
    conexao.Parametros('valor', 0);
    conexao.Parametros('modificado_site', 0);
    conexao.Parametros('ativo', 1);
    conexao.ExecuteSQL;
    //
    Dados.Next;
  end;

  Dados.Free;
  conexao.Free;
end;

procedure DoPostExtra(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Descricao: String;
  Min: Integer;
  Max: Integer;
  ID: Integer;
  IDITEN: Integer;

  Dados: TFDMemTable;
begin
  try
    Descricao := Req.Params['categoria'];
  except
    Res.Send('Descricao não informado').Status(500);
    exit;
  end;

  try
    Min := Req.Params['min'].ToInteger;
  except
    Res.Send('Min não informado').Status(500);
    exit;
  end;

  try
    Max := Req.Params['max'].ToInteger;
  except
    Res.Send('Max não informado').Status(500);
    exit;
  end;

  try
    ID := Req.Params['id'].ToInteger;
  except
    ID := 0;
  end;

  try
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(Req.Body);
  except
    on E: Exception do
    begin
      // Writeln(E.Message);
      Dados.Free;
      exit;
    end;
  end;

  conexao := Tconexao.Create('Util');
  if ID = 0 then
  begin
    ID := conexao.GerarID('extra', 'id');
    // conexao.SQL.Add('insert into extra values (:id,:descricao,:max,:min,1)');
  end
  else
  begin
    conexao.SQL.Add
      ('update extra set descricao = :descricao, max = :max, min = :min where id = :id');
  end;

  conexao.Parametros('id', ID);
  conexao.Parametros('descricao', Descricao);
  conexao.Parametros('max', Max);
  conexao.Parametros('min', Min);
  conexao.ExecuteSQL;

  // conexao.SQL.Add('delete from extra_iten where id_extra = ' + ID.ToString);
  // conexao.ExecuteSQL;

  while not Dados.Eof do
  begin
    IDITEN := conexao.GerarID('extra_iten', 'id');
    conexao.SQL.Add
      ('insert into extra_iten values (:id,:idextra,:nome,:descricao,:valor,1)');
    conexao.Parametros('id', IDITEN);
    conexao.Parametros('idextra', ID);
    conexao.Parametros('descricao', Dados.FieldByName('DESCRICAO').AsString);
    conexao.Parametros('nome', Dados.FieldByName('NOME').AsString);
    conexao.Parametros('valor', Dados.FieldByName('VALOR').AsFloat);
    conexao.ExecuteSQL;
    Dados.Next;
  end;

  conexao.Free;
  // create table extra ( id integer not null, descricao varchar(255),max integer, min integer, status integer);
end;

//

procedure DoPostProdutoExtra(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Produto: Integer;
  conexao: Tconexao;
  Codigo: Integer;
begin
  try
    Produto := Req.Params['id'].ToInteger;
  except
    Produto := 0;
  end;
  conexao := Tconexao.Create('Util');
  with conexao do
  begin
    Codigo := GerarID('pro_adi_personalizado', 'id');
    SQL.Add('insert into pro_adi_personalizado (id,id_produto,ativo,qtd_minima,qtd_maxima,modificado_site) values  (:id,:id_produto,0,0,0,1)');
    Parametros('id', Codigo);
    Parametros('id_produto', Produto);
    ExecuteSQL;
  end;
  conexao.Free;
end;

procedure DoGetExtraProdutoItens(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Produto: Integer;
  conexao: Tconexao;
begin
  try
    Produto := Req.Params['id'].ToInteger;
  except
    Produto := 0;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('SELECT * FROM pro_adi_personalizado_sabores where id_pro_adi_personalizado = :id');
  conexao.Parametros('id', Produto);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetExtraProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Produto: Integer;
  conexao: Tconexao;
begin
  try
    Produto := Req.Params['id'].ToInteger;
  except
    Produto := 0;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from pro_adi_personalizado where id_produto = :id');
  conexao.Parametros('id', Produto);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetAllExtra(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Produto: Integer;
  Dados: TFDMemTable;
  CodigoExtra: Integer;
  Codigo: Integer;
  Codigo2: Integer;
  Separado: TStringDynArray;
  I: Integer;
  Item: String;
  Adicional: String;
  ValorSelecionado: String;
  Valor: TStringDynArray;
  Min: TStringDynArray;
  Max: TStringDynArray;
begin
  try
    Produto := Req.Params['id'].ToInteger;
  except
    Produto := 0;
  end;
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select ');
  conexao.SQL.Add('group_concat(DISTINCT iten.nome SEPARATOR  ' + QuotedStr('|')
    + ') as item, ');
  conexao.SQL.Add('group_concat(iten.valor SEPARATOR  ' + QuotedStr('|') +
    ') as valor, ');
  conexao.SQL.Add('group_concat(DISTINCT extra.descricao SEPARATOR  ' +
    QuotedStr('|') + ') as descricao, ');
  conexao.SQL.Add('group_concat(DISTINCT extra.id SEPARATOR  ' + QuotedStr('|')
    + ') as id, ');
  conexao.SQL.Add('group_concat(DISTINCT extra.qtd_minima SEPARATOR  ' +
    QuotedStr('|') + ') as min,');
  conexao.SQL.Add('group_concat(DISTINCT extra.qtd_maxima SEPARATOR  ' +
    QuotedStr('|') + ') as max ');
  conexao.SQL.Add('from pro_adi_personalizado as extra');
  conexao.SQL.Add
    ('join pro_adi_personalizado_sabores as iten on iten.id_pro_adi_personalizado = extra.id');
  conexao.SQL.Add('where extra.id_extra is null');
  conexao.SQL.Add('group by extra.id');
  conexao.SQL.Add('order by extra.descricao ');

  Dados.LoadFromJSON(conexao.ConsultaSQL);

  while not Dados.Eof do
  begin
    if (CodigoExtra <> Dados.FieldByName('id').AsInteger) or
      ((Item <> Dados.FieldByName('item').AsString) and
      (Adicional <> Dados.FieldByName('descricao').AsString)) and
      (ValorSelecionado <> Dados.FieldByName('valor').AsString) then
    begin
      Min := SplitString(Dados.FieldByName('min').AsString, '|');
      Max := SplitString(Dados.FieldByName('max').AsString, '|');

      CodigoExtra := Dados.FieldByName('id').AsInteger;
      Codigo := conexao.GerarID('extra', 'id');
      conexao.SQL.Add
        ('insert into extra (id,descricao,min,max,status) values (:id,:descricao,:min,:max,:status)');
      conexao.Parametros('id', Codigo);
      conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);

      try
        StrToInt(Min[0]);
        conexao.Parametros('min', Min[0]);
      except
        conexao.Parametros('min', 0);
      end;

      try
        StrToInt(Max[0]);
        conexao.Parametros('max', Max[0]);
      except
        conexao.Parametros('max', 0);
      end;

      conexao.Parametros('status', 1);
      Valor := SplitString(Dados.FieldByName('valor').AsString, '|');
      Separado := SplitString(Dados.FieldByName('item').AsString, '|');
      Item := Dados.FieldByName('item').AsString;
      ValorSelecionado := Dados.FieldByName('valor').AsString;
      Adicional := Dados.FieldByName('descricao').AsString;
      conexao.ExecuteSQL;

      for I := 0 to length(Separado) - 1 do
      begin
        Codigo2 := conexao.GerarID('extra_iten', 'id');
        conexao.SQL.Add
          ('insert into extra_iten (id,id_extra,nome,valor,status) values (:id,:id_extra,:nome,:valor,:status)');
        conexao.Parametros('id', Codigo2);
        conexao.Parametros('id_extra', Codigo);
        conexao.Parametros('nome', Separado[I]);
        conexao.Parametros('valor', Valor[I]);
        conexao.Parametros('status', 1);
        conexao.ExecuteSQL;
      end;

    end;
    conexao.SQL.Add
      ('update pro_adi_personalizado set id_extra = :extra where id = :id');
    conexao.Parametros('extra', Codigo);
    conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
    conexao.ExecuteSQL;

    Dados.Next;
  end;

  Dados.Free;

  conexao.SQL.Add('select e.id,e.descricao, group_concat(concat(es.nome,' +
    QuotedStr(' R$ ') + ',CONVERT(es.valor, DECIMAL(4,2))) SEPARATOR  ' +
    QuotedStr(' | ') + ') as grupo');

  if Produto > 0 then
    conexao.SQL.Add
      (', (SELECT id FROM pro_adi_personalizado where id_extra = e.id and id_produto = '
      + Produto.ToString + ' limit 1) as produto')
  else
  begin
    conexao.SQL.Add(', 0 as produto');
  end;
  conexao.SQL.Add
    (',(select count(*) as total from pro_adi_personalizado where id_extra = e.id) as qtd');
  conexao.SQL.Add('from extra as e');
  conexao.SQL.Add('join extra_iten as es on es.id_extra = e.id');
  conexao.SQL.Add('where e.status = 1 group by e.id order by qtd desc');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostExtraProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Produto: Integer;
  Extra: Integer;
  Codigo: Integer;
  CodigoAux: Integer;

  Dados: TFDMemTable;
  DadosExtra: TFDMemTable;
begin
  try
    Produto := Req.Params['produto'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;

  try
    Extra := Req.Params['extra'].ToInteger;
  except
    Res.Send('Extra não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  DadosExtra := TFDMemTable.Create(nil);

  conexao.SQL.Add('select * from extra where id = :id');
  conexao.Parametros('id', Extra);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  conexao.SQL.Add('select * from extra_iten where id_extra = :id');
  conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
  DadosExtra.LoadFromJSON(conexao.ConsultaSQL);

  Codigo := conexao.GerarID('pro_adi_personalizado', 'id');
  conexao.SQL.Add
    ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,id_site,modificado_site,id_extra) values (:id,:produto,:descricao,1,:min,:max,null,0,:extra);');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('produto', Produto);
  conexao.Parametros('extra', Extra);
  conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
  conexao.Parametros('min', Dados.FieldByName('max').AsInteger);
  conexao.Parametros('max', Dados.FieldByName('min').AsInteger);
  conexao.ExecuteSQL;

  while not DadosExtra.Eof do
  begin
    CodigoAux := conexao.GerarID('pro_adi_personalizado_sabores', 'id');
    conexao.SQL.Add
      ('insert into pro_adi_personalizado_sabores (id, id_pro_adi_personalizado,nome,descricao,valor,id_site,ativo,modificado_site,id_extra_iten) values (:id,:produto,:nome,:descricao,:valor,0,1,0,:extra)');

    // :,:nome,:descricao,:valor,0,null,1,:)
    conexao.Parametros('id', CodigoAux);
    conexao.Parametros('produto', Codigo);
    conexao.Parametros('extra', Extra);
    conexao.Parametros('nome', DadosExtra.FieldByName('nome').AsString);
    conexao.Parametros('descricao', DadosExtra.FieldByName('descricao')
      .AsString);
    conexao.Parametros('valor', DadosExtra.FieldByName('valor').AsFloat);
    conexao.ExecuteSQL;
    DadosExtra.Next;
  end;

  DadosExtra.Free;
  Dados.Free;
  conexao.Free;
end;

procedure DoGetTabelaProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin

  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('SELECT * FROM produto_preco where id_produto = :id');
  conexao.Parametros('id', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostTabelaProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Codigo: Integer;
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  conexao := Tconexao.Create('Util');

  Codigo := conexao.GerarID('produto_preco', 'id');
  Dados.First;
  while not Dados.Eof do
  begin

    if Dados.FieldByName('id').AsInteger = 0 then
    begin
      conexao.SQL.Add
        ('insert into produto_preco (id,id_produto,segunda,terca,quarta,quinta,sexta,sabado,domingo,valor,hora_inicial,hora_final) values (:id,:produto,:segunda,:terca,:quarta,:quinta,:sexta,:sabado,:domingo,:valor,:inicial,:final)');
      conexao.Parametros('id', Codigo);
      conexao.Parametros('produto', Dados.FieldByName('ID_PRODUTO').AsInteger);
      conexao.Parametros('valor', Dados.FieldByName('VALOR').AsCurrency);
      conexao.Parametros('inicial',
        StrToDateTime(COPY(Dados.FieldByName('HORA_INICIO').AsString, 0, 8)));
      conexao.Parametros('final',
        StrToDateTime(COPY(Dados.FieldByName('HORA_FIM').AsString, 0, 8)));
      conexao.Parametros('segunda', Dados.FieldByName('SEGUNDA').AsInteger);
      conexao.Parametros('terca', Dados.FieldByName('TERCA').AsInteger);
      conexao.Parametros('quarta', Dados.FieldByName('QUARTA').AsInteger);
      conexao.Parametros('quinta', Dados.FieldByName('QUINTA').AsInteger);
      conexao.Parametros('sexta', Dados.FieldByName('SEXTA').AsInteger);
      conexao.Parametros('sabado', Dados.FieldByName('SABADO').AsInteger);
      conexao.Parametros('domingo', Dados.FieldByName('DOMINGO').AsInteger);

      conexao.ExecuteSQL;

    end;

    Dados.Next;
  end;

  conexao.Free;
end;

procedure DoPutTabelaPreco(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('delete from produto_preco where id = :id');
  conexao.Parametros('id', ID);

  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoGetProdutoCodigo(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  ID: Integer;
  conexao: Tconexao;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from produto where codigo_interno like ' +
    QuotedStr('%' + ID.ToString) + ' or codigo like ' +
    QuotedStr('%' + ID.ToString));

  Res.Send(conexao.ConsultaSQL.ToString);
  conexao.Free;
end;

procedure DoDadosProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  DadosConsulta: TFDMemTable;
  Dados: TFDMemTable;

  CampoOrdem: TIntegerField;
  CampoTipo: TStringField;
  CampoExtra: TStringField;
  CampoDescricao: TStringField;
  CampoValor: TStringField;

  Sequencial: Integer;
  DIASEMANA: String;
  I: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;

  Dados := TFDMemTable.Create(nil);
  DadosConsulta := TFDMemTable.Create(nil);
  conexao := Tconexao.Create('Util');

  CampoOrdem := TIntegerField.Create(nil);
  CampoOrdem.FieldName := 'ordem';
  CampoOrdem.FieldKind := fkData;
  CampoOrdem.Dataset := Dados;

  CampoOrdem := TIntegerField.Create(nil);
  CampoOrdem.FieldName := 'id';
  CampoOrdem.FieldKind := fkData;
  CampoOrdem.Dataset := Dados;

  CampoOrdem := TIntegerField.Create(nil);
  CampoOrdem.FieldName := 'tipo_id';
  CampoOrdem.FieldKind := fkData;
  CampoOrdem.Dataset := Dados;

  CampoTipo := TStringField.Create(nil);
  CampoTipo.FieldName := 'tipo';
  CampoTipo.FieldKind := fkData;
  CampoTipo.Dataset := Dados;
  CampoTipo.Size := 200;

  CampoExtra := TStringField.Create(nil);
  CampoExtra.FieldName := 'extra';
  CampoExtra.FieldKind := fkData;
  CampoExtra.Dataset := Dados;
  CampoExtra.Size := 200;

  CampoDescricao := TStringField.Create(nil);
  CampoDescricao.FieldName := 'descricao';
  CampoDescricao.FieldKind := fkData;
  CampoDescricao.Dataset := Dados;
  CampoDescricao.Size := 200;

  CampoValor := TStringField.Create(nil);
  CampoValor.FieldName := 'valor';
  CampoValor.FieldKind := fkData;
  CampoValor.Dataset := Dados;
  Sequencial := 0;
  Dados.Open;

  conexao.SQL.Add
    ('SELECT pap.descricao, paps.nome, paps.valor, paps.id FROM pro_adi_personalizado as pap');
  conexao.SQL.Add
    ('join pro_adi_personalizado_sabores as paps on paps.id_pro_adi_personalizado = pap.id');
  conexao.SQL.Add('where pap.id_produto = :id');
  conexao.SQL.Add('order by pap.id, paps.id');
  conexao.Parametros('id', ID);
  DadosConsulta.Close;
  DadosConsulta.LoadFromJSON(conexao.ConsultaSQL);

  while not DadosConsulta.Eof do
  begin
    inc(Sequencial);
    Dados.Insert;
    Dados.FieldByName('id').AsInteger := DadosConsulta.FieldByName('id')
      .AsInteger;
    Dados.FieldByName('tipo_id').AsInteger := 1;
    Dados.FieldByName('ordem').AsInteger := Sequencial;
    Dados.FieldByName('tipo').AsString := 'Extra';
    Dados.FieldByName('extra').AsString := DadosConsulta.FieldByName
      ('descricao').AsString;
    Dados.FieldByName('descricao').AsString :=
      DadosConsulta.FieldByName('nome').AsString;
    Dados.FieldByName('valor').AsFloat := DadosConsulta.FieldByName
      ('valor').AsFloat;
    Dados.Post;
    DadosConsulta.Next;
  end;

  conexao.SQL.Add
    ('SELECT ts.nome as descricao, sc.nome as nome, sc.vl_venda as valor, sc.id FROM tipo_sabor as ts');
  conexao.SQL.Add('join sabores_completo as sc on sc.id_tipo_sabor = ts.id');
  conexao.SQL.Add('where sc.id_produto = :id order by ts.id');
  conexao.Parametros('id', ID);
  DadosConsulta.Close;
  DadosConsulta.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    if Dados.FieldByName('tipo').AsString <> '*' then
    begin
      inc(Sequencial);
      Dados.Insert;
      Dados.FieldByName('id').AsInteger := 0;
      Dados.FieldByName('tipo_id').AsInteger := 0;
      Dados.FieldByName('ordem').AsInteger := Sequencial;
      Dados.FieldByName('tipo').AsString := '*';
      Dados.FieldByName('extra').AsString := '*';
      Dados.FieldByName('descricao').AsString := '';
      Dados.FieldByName('valor').AsFloat := 0;
      Dados.Post;
    end;
  end;

  while not DadosConsulta.Eof do
  begin
    inc(Sequencial);
    Dados.Insert;
    Dados.FieldByName('id').AsInteger := DadosConsulta.FieldByName('id')
      .AsInteger;
    Dados.FieldByName('tipo_id').AsInteger := 2;
    Dados.FieldByName('ordem').AsInteger := Sequencial;
    Dados.FieldByName('tipo').AsString := 'Sabor';
    Dados.FieldByName('extra').AsString := DadosConsulta.FieldByName
      ('descricao').AsString;
    Dados.FieldByName('descricao').AsString :=
      DadosConsulta.FieldByName('nome').AsString;
    Dados.FieldByName('valor').AsFloat := DadosConsulta.FieldByName
      ('valor').AsFloat;
    Dados.Post;
    DadosConsulta.Next;
  end;

  DadosConsulta.Free;

  DadosConsulta := TFDMemTable.Create(nil);

  conexao.SQL.Add
    ('select * from produto_preco where id_produto = :id order by id');
  conexao.Parametros('id', ID);
  DadosConsulta.Close;
  DadosConsulta.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    if Dados.FieldByName('tipo').AsString <> '*' then
    begin
      inc(Sequencial);
      Dados.Insert;
      Dados.FieldByName('id').AsInteger := 0;
      Dados.FieldByName('tipo_id').AsInteger := 0;
      Dados.FieldByName('ordem').AsInteger := Sequencial;
      Dados.FieldByName('tipo').AsString := '*';
      Dados.FieldByName('extra').AsString := '*';
      Dados.FieldByName('descricao').AsString := '';
      Dados.FieldByName('valor').AsFloat := 0;
      Dados.Post;
    end;
  end;

  while not DadosConsulta.Eof do
  begin
    DIASEMANA := '';
    for I := 2 to 8 do
    begin

      case DadosConsulta.FieldByName(DadosConsulta.Fields[I].FieldName)
        .AsInteger of
        1:
          begin
            if length(DIASEMANA) = 0 then
              DIASEMANA :=
                COPY(UpperCase(DadosConsulta.Fields[I].FieldName), 0, 3)
            else
              DIASEMANA := DIASEMANA + ', ' +
                COPY(UpperCase(DadosConsulta.Fields[I].FieldName), 0, 3);
          end;
      end;

    end;

    inc(Sequencial);
    Dados.Insert;
    Dados.FieldByName('id').AsInteger := 0;
    Dados.FieldByName('tipo_id').AsInteger := 3;
    Dados.FieldByName('ordem').AsInteger := Sequencial;
    Dados.FieldByName('tipo').AsString := 'Preço';
    Dados.FieldByName('extra').AsString := DIASEMANA;
    Dados.FieldByName('descricao').AsString :=
      COPY(DadosConsulta.FieldByName('hora_inicial').AsString, 0, 8) + ' até ' +
      COPY(DadosConsulta.FieldByName('hora_final').AsString, 0, 8);
    Dados.FieldByName('valor').AsFloat := DadosConsulta.FieldByName
      ('valor').AsFloat;
    Dados.Post;
    DadosConsulta.Next;
  end;

  Res.Send(Dados.ToJSONArrayString);

  Dados.Close;
  CampoOrdem.Free;
  CampoTipo.Free;
  CampoExtra.Free;
  CampoDescricao.Free;
  CampoValor.Free;
  DadosConsulta.Free;
  Dados.Free;
  conexao.Free;
end;

procedure DoPostImgProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  LocalImagem: String;
  Memo: TMemo;
  Arquivo: String;

begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;

  try
    Arquivo := Req.Params['arquivo'];
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;

  frmServidor.memoImagem.Lines.Clear;
  LocalImagem := Caminho + '\produto\imagem\';
  Memo := TMemo.Create(nil);

  ForceDirectories(LocalImagem);
  LocalImagem := LocalImagem + ID.ToString + '.txt';


  {
    try

    conexao := TConexao.Create('Util');
    conexao.SQL.Add
    ('update produto set caminho_imagem = :img where codigo = :id');
    conexao.Parametros('img', Req.Body);
    conexao.Parametros('id', ID);
    conexao.ExecuteSQL;
    conexao.Free;
    except
    on ex: Exception do
    begin

    end;
    end;
    JSONObject.Free; }
end;

procedure DoGetImgProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  LocalImagem: String;

begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;
  frmServidor.memoImagem.Lines.Clear;
  LocalImagem := Caminho + '\produto\imagem\' + ID.ToString + '.txt';

  if FileExists(LocalImagem) then
  begin
    frmServidor.memoImagem.Lines.LoadFromFile(LocalImagem);
  end;
  Res.Send(frmServidor.memoImagem.Lines.Text);
end;

procedure DoGetAllExtraAlteracao(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('Util');

  with conexao do
  begin
    SQL.Add('SELECT e.*, count(pap.id) as tot FROM extra as e');
    SQL.Add('join pro_adi_personalizado as pap on pap.id_extra = e.id');
    SQL.Add('group by e.id');
    SQL.Add('order by tot desc,e.descricao');
  end;

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetExtraItens(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');

  with conexao do
  begin
    SQL.Add('SELECT * FROM extra_iten where id_extra = :id');
    Parametros('id', ID);
  end;

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPutExtraAlteracao(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;

  ID: Integer;
  Min: Integer;
  Max: Integer;
  Descricao: String;
  Dados: TFDMemTable;
  DadosReplica: TFDMemTable;
  CodigoExtra: Integer;
  ItenExtra: Integer;
  CodigoAux: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto não informado').Status(500);
    exit;
  end;
  try
    Descricao := Req.Params['categoria'];
  except
    Res.Send('Descricao não informado').Status(500);
    exit;
  end;

  try
    Min := Req.Params['min'].ToInteger;
  except
    Res.Send('Min não informado').Status(500);
    exit;
  end;

  try
    Max := Req.Params['max'].ToInteger;
  except
    Res.Send('Max não informado').Status(500);
    exit;
  end;
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  DadosReplica := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  with conexao do
  begin
    SQL.Add('update extra set descricao = :descricao, max = :max, min = :min where id = :id');
    Parametros('id', ID);
    Parametros('descricao', Descricao);
    Parametros('max', Max);
    Parametros('min', Min);
    ExecuteSQL;

    SQL.Add('update pro_adi_personalizado set descricao = :descricao, qtd_maxima = :max, qtd_minima = :min, modificado_site = 0 where id_extra = :id');
    Parametros('id', ID);
    Parametros('descricao', Descricao);
    Parametros('max', Max);
    Parametros('min', Min);
    ExecuteSQL;

    SQL.Add('SELECT * FROM pro_adi_personalizado where id_extra = :id');
    Parametros('id', ID);
    DadosReplica.LoadFromJSON(ConsultaSQL);
  end;

  Dados.First;
  while not Dados.Eof do
  begin

    case Dados.FieldByName('id').AsInteger of
      0:
        begin
          with conexao do
          begin
            ItenExtra := GerarID('extra_iten', 'id');
            SQL.Add('insert into extra_iten values (:id,:idextra,:nome,:descricao,:valor,1)');
            Parametros('id', ItenExtra);
            Parametros('idextra', ID);
            Parametros('descricao', Dados.FieldByName('DESCRICAO').AsString);
            Parametros('nome', Dados.FieldByName('NOME').AsString);
            Parametros('valor', Dados.FieldByName('VALOR').AsFloat);
            ExecuteSQL;
          end;

          DadosReplica.First;

          while not DadosReplica.Eof do
          begin

            with conexao do
            begin
              CodigoAux := GerarID('pro_adi_personalizado_sabores', 'id');
              SQL.Add('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo,id_extra_iten,modificado_site) values');
              SQL.Add('(:id,:produto,:nome,:descricao,:valor,1,:extra,0)');
              Parametros('id', CodigoAux);
              Parametros('produto', DadosReplica.FieldByName('id').AsInteger);
              Parametros('descricao', Dados.FieldByName('DESCRICAO').AsString);
              Parametros('nome', Dados.FieldByName('NOME').AsString);
              Parametros('valor', Dados.FieldByName('VALOR').AsFloat);
              Parametros('extra', ID);
              ExecuteSQL;
            end;

            DadosReplica.Next;
          end;

        end
    else
      begin
        with conexao do
        begin
          SQL.Add('update extra_iten set nome = :nome, descricao = :descricao, valor = :valor, status = :status where id = :id');
          Parametros('id', Dados.FieldByName('id').AsInteger);
          Parametros('descricao', Dados.FieldByName('DESCRICAO').AsString);
          Parametros('nome', Dados.FieldByName('NOME').AsString);
          Parametros('valor', Dados.FieldByName('VALOR').AsFloat);
          Parametros('status', Dados.FieldByName('status').AsInteger);
          ExecuteSQL;

        end;
      end;
    end;

    Dados.Next;
  end;

  Dados.Free;
  DadosReplica.Free;
  conexao.Free;
end;

procedure DoGetCategoriaAll(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Busca: String;
begin
  try
    Busca := Req.Params['all'];
  except
    Busca := '';
  end;
  if UpperCase(Busca) = 'ALL' then
    Busca := '';
  conexao := Tconexao.Create('Util');

  // all

  with conexao do
  begin
    SQL.Add('SELECT codigo,descricao,pizza,visivel_vem_buscar,visivel_delivery,id_site,impressora,ordem,modificado_site,(SELECT CONCAT(upper(descricao),'
      + QuotedStr(' (') + ',upper(driver),' + QuotedStr(')') +
      ') FROM impressoras where codigo = impressora) as descricao_impressora');
    SQL.Add('FROM tipo_produto');
    if Busca <> '' then
    begin
      SQL.Add('WHERE upper(descricao) LIKE ' +
        QuotedStr('%' + UpperCase(Busca) + '%'))
    end;

  end;
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetPedidoProdutoStatus(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add
    ('SELECT pp.codigo_pedido, pp.impresso as impressao, pp.hora, p.id_site as site, p.foto_ifood as ifood, pp.codigo,p.nome_produto,pp.quantidade,(pp.valor_total / pp.quantidade) as unitario,pp.valor_total,p.valor_embalagem_delivery as entrega, ');
  conexao.SQL.Add('pp.html as obs, pp.selecionado,');
  conexao.SQL.Add('0 as paga,');
  conexao.SQL.Add('0 as paga_tot');
  conexao.SQL.Add('FROM pedido_produtos as pp');
  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  conexao.SQL.Add('where pp.codigo = :codigo');
  conexao.SQL.Add('group by pp.codigo');
  conexao.Parametros('codigo', Req.Params['produto']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetPedidoProdutoMesa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add
    ('SELECT pp.codigo_pedido, pp.impresso as impressao, pp.hora, p.id_site as site, p.foto_ifood as ifood, pp.codigo,p.nome_produto,pp.quantidade,(pp.valor_total / pp.quantidade) as unitario,pp.valor_total,p.valor_embalagem_delivery as entrega, ');
  conexao.SQL.Add
    ('IF(pp.id_pedido > 0, pp.observacao,pp.html) as obs, pp.selecionado,');
  // conexao.SQL.Add('(select nome from usuario where codigo = pp.usuario) as usuario,');
  conexao.SQL.Add
    ('IF(pp.id_pedido > 0, concat((select nome from usuario where codigo = pp.usuario)," cancelado por ",(select nome from usuario where codigo = pp.usuario_deletado)),(select nome from usuario where codigo = pp.usuario)) as usuario,');
  conexao.SQL.Add('0 as paga,');
  conexao.SQL.Add('0 as paga_tot,');
  conexao.SQL.Add('IF(pp.id_pedido > 0, 1,0) as cancelado');
  conexao.SQL.Add('FROM pedido_produtos as pp');
  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  conexao.SQL.Add
    ('where pp.codigo_pedido = :codigo or (pp.id_pedido = :codigo and pp.observacao <> "")');
  conexao.SQL.Add('group by pp.codigo');
  conexao.Parametros('codigo', Req.Params['pedido']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetPedidoProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin
  Res.Send<TJSONArray>(GetDadosProdutoPedido(Req.Params['pedido'].ToInteger));
end;

procedure DoPostImprimir(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Tipo: Integer;
  Codigo: Integer;
  Aux: Integer;
  Servico: Real;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    Res.Send('Código Não Informado').Status(500);
    exit;
  end;

  try
    Tipo := Req.Params['tipo'].ToInteger;
  except
    Res.Send('Tipo Não Informado').Status(500);
    exit;
  end;
  try
    Servico := Req.Params['servico'].ToDouble;
  except
    Servico := 0;
  end;

  conexao := Tconexao.Create('Util');

  if Servico > 0 then
  begin
    conexao.SQL.Add
      ('UPDATE pedido SET servico_percentual = :percentual, valor_total_pedido = TRUNCATE((('
      + '(SELECT SUM(valor_total) FROM pedido_produtos WHERE pedido_produtos.codigo_pedido = :cod) * '
      + FloatToStr(Servico) +
      ') / 100) + (SELECT SUM(valor_total) FROM pedido_produtos WHERE pedido_produtos.codigo_pedido = :cod), 2),');

    conexao.SQL.Add
      ('servico = TRUNCATE((SELECT SUM(valor_total) FROM pedido_produtos WHERE pedido_produtos.codigo_pedido = :cod) * '
      + FloatToStr(Servico) + ' / 100, 2)');

    conexao.SQL.Add('WHERE codigo = :cod AND id_ficha > 0');
    conexao.Parametros('percentual', Servico);
  end
  else
  begin
    conexao.SQL.Add
      ('update pedido set servico_percentual = 0, servico = 0, valor_total_pedido = (select sum(valor_total) from pedido_produtos where pedido_produtos.codigo_pedido = :cod) where codigo = :cod and id_ficha > 0');
  end;
  conexao.Parametros('cod', Codigo);
  conexao.ExecuteSQL;

  case Tipo of
    1:
      begin
        // Pedido

        Aux := conexao.GerarID('impressao_pedido', 'id');
        conexao.SQL.Add
          ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
        conexao.Parametros('pedido', Codigo);
        conexao.Parametros('id', Aux);
        conexao.ExecuteSQL;


        // Pegar os produtos que não foram impresso e colocar aqui

      end;
    2:
      begin
        // Pedido Produto

        Aux := conexao.GerarID('impressao_pedido_produto', 'id');
        conexao.SQL.Add
          ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date,current_time,:pedido,0,0,-6);');
        conexao.Parametros('pedido', Codigo);
        conexao.Parametros('id', Aux);
        conexao.ExecuteSQL;

      end;
    3:
      begin
        // Caixa Completo
        Aux := conexao.GerarID('impressao_caixa', 'id');
        conexao.SQL.Add
          ('insert into impressao_caixa (id,data_solicitacao,hora_solicitacao,id_caixa,status,tipo) values (:id,current_date,current_time,:caixa,0,:tipo)');
        conexao.Parametros('caixa', Codigo);
        conexao.Parametros('id', Aux);
        conexao.Parametros('tipo', Tipo);
        conexao.ExecuteSQL;
      end;
    4:
      begin
        // Caixa Resumo
        Aux := conexao.GerarID('impressao_caixa', 'id');
        conexao.SQL.Add
          ('insert into impressao_caixa (id,data_solicitacao,hora_solicitacao,id_caixa,status,tipo) values (:id,current_date,current_time,:caixa,0,:tipo)');
        conexao.Parametros('caixa', Codigo);
        conexao.Parametros('id', Aux);
        conexao.Parametros('tipo', Tipo);
        conexao.ExecuteSQL;
      end;
    5:
      begin
        // Caixa Produto
        { Antigo Gerencial }
        Aux := conexao.GerarID('impressao_caixa', 'id');
        conexao.SQL.Add
          ('insert into impressao_caixa (id,data_solicitacao,hora_solicitacao,id_caixa,status,tipo) values (:id,current_date,current_time,:caixa,0,:tipo)');
        conexao.Parametros('caixa', Codigo);
        conexao.Parametros('id', Aux);
        conexao.Parametros('tipo', Tipo);
        conexao.ExecuteSQL;
      end;
    6:
      begin
        // Caixa Motoboy
        { Antigo Gerencial }
        Aux := conexao.GerarID('impressao_caixa', 'id');
        conexao.SQL.Add
          ('insert into impressao_caixa (id,data_solicitacao,hora_solicitacao,id_caixa,status,tipo) values (:id,current_date,current_time,:caixa,0,:tipo)');
        conexao.Parametros('caixa', Codigo);
        conexao.Parametros('id', Aux);
        conexao.Parametros('tipo', Tipo);
        conexao.ExecuteSQL;
      end;

  end;

  conexao.Free;
end;

procedure DoGetMotboyAtivo(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('SELECT * FROM motoboy where ativo = 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPutPedidoMotoboy(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Pedido: Integer;
  Motoboy: Integer;
  Codigo: Integer;
begin
  try
    Pedido := Req.Params['pedido'].ToInteger;
  except
    Res.Send('Pedido Não Informado').Status(500);
    exit;
  end;

  try
    Motoboy := Req.Params['motoboy'].ToInteger;
  except
    Res.Send('Motoboy Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('delete from pedido_motoboy where codigo_pedido = :pedido');
  conexao.Parametros('pedido', Pedido);
  conexao.ExecuteSQL;

  Codigo := conexao.GerarID('pedido_motoboy', 'codigo');

  conexao.SQL.Add
    ('insert into pedido_motoboy (codigo,codigo_motoboy,codigo_pedido,hora_pego_motoboy,status) values (:codigo,:motoboy,:pedido,current_time,1)');
  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('motoboy', Motoboy);
  conexao.Parametros('pedido', Pedido);
  conexao.ExecuteSQL;

  conexao.Free;
end;

procedure DoPutPedidoStatus(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  StatusDescricao: String;
  CodigoSite: Integer;

  Requisicao: iRequisicao;
  ID: Integer;
  Pedido: Integer;
  Status: Integer;

begin
  try
    Pedido := Req.Params['pedido'].ToInteger;
  except
    Res.Send('Pedido Não Informado').Status(500);
    exit;
  end;

  try
    Status := Req.Params['status'].ToInteger;
  except
    Res.Send('Status Não Informado').Status(500);
    exit;
  end;
  AtualizaStatus(Pedido, Status);

end;

procedure DoGetTodosCliente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Cliente: String;
begin

  try
    Cliente := Req.Params['cliente'];
  except
    Cliente := '';
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select *, ');
  conexao.SQL.Add('upper((select concat(ce.rua,' + QuotedStr(' Nº') +
    ',ce.numero,' + QuotedStr(' / ') + ',ce.bairro, ' + QuotedStr(' ') +
    ', ce.cidade,' + QuotedStr('-') +
    ',ce.estado) from cliente_endereco as ce where ce.codigo_cliente = c.codigo order by codigo desc limit 1 )) as endereco from cliente as c');
  conexao.SQL.Add
    ('join cliente_endereco on cliente_endereco.codigo =  (select codigo from cliente_endereco as ce where ce.codigo_cliente = c.codigo order by codigo desc limit 1 )');
  if length(Cliente) > 0 then
  begin
    conexao.SQL.Add
      ('where c.celular > 99999 and concat(upper(c.nome),c.celular) like ' +
      QuotedStr('%' + UpperCase(Cliente) + '%') +
      '  order by c.codigo desc limit 50');
  end
  else
  begin
    conexao.SQL.Add('where c.celular > 99999 order by c.codigo desc limit 50 ');
  end;

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  // Res.Send(conexao.SQL.Text);

  conexao.Free;
end;

procedure DoGetConsultaTodos(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Tabela: String;
begin

  try
    Tabela := Req.Params['tabela'];
  except
    Res.Send('Tabela Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('SELECT * FROM ' + Tabela);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostCategoriaAll(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  MySQL: String;
  Ordem: Integer;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;
  conexao := Tconexao.Create('Util');
  Dados.Edit;
  case Dados.FieldByName('ordem').AsInteger of
    0:
      begin
        Dados.FieldByName('ordem').AsInteger :=
          conexao.GerarID('tipo_produto', 'ordem');
      end;
  end;
  with conexao do
  begin
    case Dados.FieldByName('codigo').AsInteger of
      0:
        begin
          MySQL := 'insert into tipo_produto (codigo,descricao,impressora,pizza,visivel_vem_buscar,visivel_delivery,ordem,modificado_site) ';
          MySQL := MySQL +
            ' values (:codigo,:descricao,:impressora,:pizza,:visivel_vem_buscar,:visivel_delivery,:ordem,:modificado_site)';

          Dados.FieldByName('codigo').AsInteger :=
            GerarID('tipo_produto', 'codigo');
        end
    else
      begin
        MySQL := 'update tipo_produto set descricao = :descricao, impressora = :impressora, pizza = :pizza, visivel_vem_buscar = :visivel_vem_buscar, ';
        MySQL := MySQL +
          'visivel_delivery = :visivel_delivery, ordem = :ordem, modificado_site = :modificado_site where codigo = :codigo';
      end;
    end;
    SQL.Add(MySQL);
    Dados.Edit;
    if Dados.FieldByName('pizza').IsNull then
    begin

      Dados.FieldByName('pizza').AsInteger := 0;
    end;

    Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
    Parametros('descricao', Dados.FieldByName('descricao').AsString);
    Parametros('impressora', Dados.FieldByName('impressora').AsInteger);
    Parametros('pizza', Dados.FieldByName('pizza').AsInteger);
    Parametros('visivel_vem_buscar', Dados.FieldByName('visivel_vem_buscar')
      .AsInteger);
    Parametros('visivel_delivery', Dados.FieldByName('visivel_delivery')
      .AsInteger);
    // Parametros('id_site', Dados.FieldByName('id_site').AsInteger);
    Parametros('ordem', Dados.FieldByName('ordem').AsInteger);
    Parametros('modificado_site', Dados.FieldByName('modificado_site')
      .AsInteger);
    ExecuteSQL;
  end;

  Dados.Free;
  conexao.Free;

end;

procedure DoPostGenerico(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Tabela: String;
  CampoID: String;
  I: Integer;
  ID: Integer;

  SQLInsert: String;
  SQLInsertValues: String;
  SQLUpdate: String;
  Insert: Boolean;
begin

  try
    Tabela := Req.Params['tabela'];
  except
    Res.Send('Tabela Não Informado').Status(500);
    exit;
  end;

  try
    CampoID := Req.Params['id'];
  except
    Res.Send('Campo PK Não Informado').Status(500);
    exit;
  end;

  Dados := TFDMemTable.Create(nil);
  try
    Dados.LoadFromJSON(Req.Body);
  except
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');
  Insert := Dados.FieldByName(CampoID).AsInteger = 0;

  if Insert then
    ID := conexao.GerarID(Tabela, CampoID)
  else
    ID := Dados.FieldByName(CampoID).AsInteger;

  for I := 0 to Dados.FieldCount - 1 do
  begin

    if not Dados.FieldByName(CampoID).IsNull then
    begin
      if UpperCase(Dados.Fields[I].FieldName) = UpperCase(CampoID) then
      begin
        conexao.Parametros(CampoID, ID);

      end
      else
      begin
        conexao.Parametros(Dados.Fields[I].FieldName,
          Dados.FieldByName(Dados.Fields[I].FieldName).AsVariant);
        if length(SQLUpdate) > 0 then
        begin
          SQLUpdate := SQLUpdate + ', ' + Dados.Fields[I].FieldName + ' = :' +
            Dados.Fields[I].FieldName;
        end
        else
        begin
          SQLUpdate := Dados.Fields[I].FieldName + ' = :' + Dados.Fields[I]
            .FieldName;
        end;
      end;

      if length(SQLInsert) > 0 then
      begin
        SQLInsert := SQLInsert + ', ' + Dados.Fields[I].FieldName;
        SQLInsertValues := SQLInsertValues + ', :' + Dados.Fields[I].FieldName;
      end
      else
      begin
        SQLInsert := Dados.Fields[I].FieldName;
        SQLInsertValues := ':' + Dados.Fields[I].FieldName;
      end;

    end;

  end;

  if Insert then
  begin
    // Insert
    SQLInsert := 'insert into ' + Tabela + ' (' + SQLInsert + ') values (' +
      SQLInsertValues + ')';
    conexao.SQL.Add(SQLInsert);
  end
  else
  begin
    // Update
    SQLUpdate := 'update ' + Tabela + ' set ' + SQLUpdate + ' where ' + CampoID
      + ' = :' + CampoID;
    conexao.SQL.Add(SQLUpdate);
    // Writeln(SQLUpdate);

  end;
  conexao.ExecuteSQL;
  Dados.Free;
  conexao.Free;
end;

procedure DoGetClienteCelular(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Celular: String;
begin
  try
    Celular := Req.Params['celular'];
  except
    Res.Send('Celular Não Informado').Status(500);
    exit;
  end;
  conexao := Tconexao.Create('Util');

  conexao.SQL.Add
    ('SELECT c.codigo,ce.codigo as endereco, c.nome, upper(ce.rua) as rua, ce.bairro, ce.cidade, ce.estado, ce.complemento, te.valor_taxa FROM cliente as c');
  conexao.SQL.Add
    ('left join cliente_endereco as ce on ce.codigo_cliente = c.codigo left join taxa_entrega as te on te.bairro = ce.bairro');
  conexao.SQL.Add('where c.celular like ' + QuotedStr('%' + Celular + '%') +
    ' or c.celular_wpp like ' + QuotedStr('%' + Celular + '%') +
    ' and c.ativo = 1');
  conexao.SQL.Add('group by c.codigo order by ce.codigo desc');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetMediaPedido(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Test: String;
  JsonObject: TJSONObject;
  MesesAno: TArray<string>;
  MesAno: string;
  SQL: String;
begin
  conexao := Tconexao.Create('Util');
  try
    JsonObject := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

    Test := JsonObject.GetValue('datas').Value;
  except
    Test := Req.Params['datas'];
  end;

  SQL := ' SELECT ';
  SQL := SQL + ' COUNT(*) AS total, ';
  SQL := SQL + ' SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS cancelado, ';
  SQL := SQL + ' SUM(CASE WHEN status > 0 THEN 1 ELSE 0 END) AS todos ';
  SQL := SQL + ' from pedido ';
  SQL := SQL + 'WHERE origem IN (1, 2,4)';
  SQL := SQL + 'AND data_pedido IN (' + Test + ')';

  conexao.SQL.Add(CriaSubQueryCampos(SQL,
    'SUM(total) AS total, SUM(cancelado) AS cancelado, SUM(todos) AS todos, ROUND(SUM(todos) DIV 4,2) as media, ROUND((SUM(cancelado) / SUM(total)) * 100,2) AS media_cancelado, ROUND((SUM(todos) / SUM(total)) * 100,2) AS media_concluido ',
    FormatDateTime('yyyy-mm-dd', IncMonth(Date, -2)),
    FormatDateTime('yyyy-mm-dd', Date)));

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetDashBoard(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('select ');
  conexao.SQL.Add('DATE_FORMAT(current_date, ' + QuotedStr('%Y-%m-01') +
    ') as primeiro,');
  conexao.SQL.Add('current_date as atual,');
  conexao.SQL.Add('DATE_FORMAT(current_date- INTERVAL(30) DAY,  ' +
    QuotedStr('%Y-%m-01') + ') as anterior,');
  conexao.SQL.Add('LAST_DAY(current_date- INTERVAL(30) DAY) as ultimo,');
  conexao.SQL.Add
    (' (select count(*) from produto where ativo = 0 ) as pausado, ');
  conexao.SQL.Add('(select count(*) from motoboy) as motoboy,');
  conexao.SQL.Add('(select count(*) from tipo_produto) as categoria,');
  conexao.SQL.Add('(select count(*) from taxa_entrega) as taxa,');
  conexao.SQL.Add('(select count(*) from mesa) as mesa,');
  conexao.SQL.Add('(select count(*) from tipo_pagamento) as pagamento,');
  conexao.SQL.Add('(select count(*) from impressoras) as impressora,');
  conexao.SQL.Add
    ('(select count(*) from pedido where status > 0  and origem in (1,2)');
  conexao.SQL.Add('and data_pedido between DATE_FORMAT(current_date, ' +
    QuotedStr('%Y-%m-01') + ') and current_date');
  conexao.SQL.Add(') as pedidos_mes_atual,');
  conexao.SQL.Add
    ('(select count(*) from pedido where status > 0  and origem in (1,2)');
  conexao.SQL.Add('and data_pedido between anterior and ultimo ');
  conexao.SQL.Add(') as pedidos_mes_anterior');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetDashBoardPrevisao(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select curdate() as atual,');
  conexao.SQL.Add
    ('(select count(*) from pedido where origem in (1,2) and status  > 0 and data_pedido in ('
    + Req.Body + ')) as previsao,');
  conexao.SQL.Add
    ('(select count(*) from pedido where origem in (1,2) and status  > 0 and data_pedido = current_date()) as atual');
  // ////showmessage1(conexao.SQL.text);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostReImpressaoApp(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  CodigoAux: Integer;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Pedido Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  CodigoAux := conexao.GerarID('impressao_pedido_produto', 'id');

  conexao.SQL.Add
    ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:pedido,0,0,-7)');
  conexao.Parametros('pedido', ID);
  conexao.Parametros('id', CodigoAux);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoPostTransferenciaMesa(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  IDMesaAtual: Integer;

  Dados: TFDMemTable;
  TotalProduto: Real;
  CodigoProduto: String;
  CodigoPedido: Integer;
  DescricaoMesaDe: String;
  DescricaoMesaPara: String;
  DescricaoTransferencia: String;
  CodigoAux: Integer;
begin

  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Pedido Não Informado').Status(500);
    exit;
  end;

  try
    IDMesaAtual := Req.Params['mesa'].ToInteger;
  except
    Res.Send('Pedido Não Informado').Status(500);
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select concat(tp.descricao,' + QuotedStr(' ') +
    ',m.nr_mesa) as descricao, 0 as zero from mesa as m');
  conexao.SQL.Add('join mesa_tipo as tp on tp.id_mesa_tipo = m.fk_tipo_mesa');
  conexao.SQL.Add('where m.id_mesa = :id');
  conexao.Parametros('id', ID);
  DescricaoMesaPara := conexao.FieldByName('descricao');

  conexao.SQL.Add('select concat(tp.descricao,' + QuotedStr(' ') +
    ',m.nr_mesa) as descricao, 0 as zero from mesa as m');
  conexao.SQL.Add('join mesa_tipo as tp on tp.id_mesa_tipo = m.fk_tipo_mesa');
  conexao.SQL.Add('where m.id_mesa = :id');
  conexao.Parametros('id', IDMesaAtual);
  DescricaoMesaDe := conexao.FieldByName('descricao');

  DescricaoTransferencia := 'Transferência de ' + DescricaoMesaDe + ' para ' +
    DescricaoMesaPara;

  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  CodigoProduto := '';
  TotalProduto := 0;
  Dados.First;
  while not Dados.Eof do
  begin

    if not Dados.FieldByName('sl').IsNull then
      if Dados.FieldByName('sl').AsInteger = 1 then
      begin

        if length(CodigoProduto) = 0 then
          CodigoProduto := Dados.FieldByName('codigo').AsString
        else
          CodigoProduto := CodigoProduto + ',' +
            Dados.FieldByName('codigo').AsString;

        CodigoAux := conexao.GerarID('pedido_produto_sap', 'id');
        conexao.SQL.Add
          ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor,tipo_valor) value (:id,:codigo_pedido_produto,0,:nomeclatura,:descricao,:valor,:tipo_valor)');
        conexao.Parametros('id', CodigoAux);
        conexao.Parametros('codigo_pedido_produto', Dados.FieldByName('codigo')
          .AsString);
        conexao.Parametros('nomeclatura', 'TRANSFERÊNCIA');
        conexao.Parametros('descricao', DescricaoTransferencia);
        conexao.Parametros('valor', 0);
        conexao.Parametros('tipo_valor', 0);
        conexao.ExecuteSQL;

        TotalProduto := TotalProduto + Dados.FieldByName('valor_total').AsFloat;
      end;

    Dados.Next;
  end;

  conexao.SQL.Add
    ('update mesa set tot_mesa = tot_mesa - :total where id_mesa = :id');
  conexao.Parametros('total', TotalProduto);
  conexao.Parametros('id', IDMesaAtual);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('update mesa set tot_mesa = tot_mesa + :total where id_mesa = :id');
  conexao.Parametros('total', TotalProduto);
  conexao.Parametros('id', ID);
  conexao.ExecuteSQL;

  conexao.SQL.Add('select * from mesa where id_mesa = :id');
  conexao.Parametros('id', ID);
  CodigoPedido := conexao.FieldByName('selecionada');

  if CodigoPedido = 0 then
  begin
    // CodigoPedido := conexao.FieldByName('selecionada');
    conexao.SQL.Clear;
    CodigoPedido := conexao.GerarID('pedido', 'codigo');

    conexao.SQL.Add
      ('insert into pedido (codigo,codigo_pedido_dia,codigo_cliente,codigo_cliente_endereco,data_pedido,hora_pedido,status,valor_pedido,valor_desconto,valor_taxa_entrega,valor_total_pedido,observacao_geral,troco,tipo_pagamento,');
    conexao.SQL.Add
      ('pedido_impresso,origem,desc_ficha,id_ficha,ficha_faturada)');
    conexao.SQL.Add
      ('values (:codigo,:codigo_pedido_dia,:codigo_cliente,:codigo_endereco,:data_pedido,:hora_pedido,:status,:valor_pedido,:valor_desconto,:valor_taxa_entrega,:valor_total_pedido,:observacao_geral,:troco,:tipo_pagamento,');
    conexao.SQL.Add
      (':pedido_impresso,:origem,:desc_ficha,:id_ficha,:ficha_faturada)');
    conexao.Parametros('codigo', CodigoPedido);
    conexao.Parametros('codigo_pedido_dia', '0');
    conexao.Parametros('codigo_cliente', '0');
    conexao.Parametros('codigo_endereco', '0');
    conexao.Parametros('data_pedido', FormatDateTime('yyyy-mm-dd', Now));
    conexao.Parametros('hora_pedido', FormatDateTime('hh:mm:ss', Now));
    conexao.Parametros('status', '-1');
    conexao.Parametros('valor_pedido', '0');
    conexao.Parametros('valor_taxa_entrega', '0');
    conexao.Parametros('valor_desconto', '0');
    conexao.Parametros('valor_total_pedido', '0');
    conexao.Parametros('observacao_geral', '');
    conexao.Parametros('troco', '0');
    conexao.Parametros('tipo_pagamento', '0');
    conexao.Parametros('pedido_impresso', '0');
    conexao.Parametros('origem', '3');
    conexao.Parametros('desc_ficha', DescricaoMesaPara);
    conexao.Parametros('id_ficha', ID);
    conexao.Parametros('ficha_faturada', ID);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add
    ('update mesa set selecionada = :codigo, sts_mesa = 1  where id_mesa = :id');
  conexao.Parametros('codigo', CodigoPedido);
  conexao.Parametros('id', ID);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('update pedido_produtos set codigo_pedido = :codigo where codigo in (' +
    CodigoProduto + ')');
  conexao.Parametros('codigo', CodigoPedido);
  conexao.ExecuteSQL;

  conexao.SQL.Add('update mesa set sts_mesa = 0 where tot_mesa = 0;');
  conexao.ExecuteSQL;

  Dados.Free;
  conexao.Free;
end;

procedure DoPostImprimirNaoImpresso(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  conexao := Tconexao.Create('Util');
  while not Dados.Eof do
  begin
    // codigo
    conexao.SQL.Add
      ('update impressao_pedido_produto set status = 0, data_solicitacao = curdate(), hora_solicitacao = curtime() where id_pedido = :codigo and data_impressao is null');
    conexao.Parametros('codigo', Dados.FieldByName('codigo').AsString);
    conexao.ExecuteSQL;
    Dados.Next;
  end;

  Dados.Free;
  conexao.Free;
end;

procedure DoGetMesasAll(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('SELECT * FROM mesa as m');
  conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostSenhaGerente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Senha: String;
begin

  try
    Senha := Req.Params['senha'];
  except
    Res.Send('Senha Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('update dados_whatsapp set senha_gerencia = md5(:senha)');

  conexao.Parametros('senha', Senha);
  conexao.ExecuteSQL;

  conexao.Free;
end;

procedure DoGetSenhaGerente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Senha: String;
  Dados: TFDMemTable;
begin

  try
    Senha := Req.Params['senha'];
  except
    Res.Send('Senha Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select * from dados_whatsapp where senha_gerencia = md5(:senha)');
  conexao.Parametros('senha', Senha);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
    Res.Send('True')
  else
    Res.Send('False');

  Dados.Free;
  conexao.Free;
end;

procedure DoPostZeraMesa(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin

  try
    ID := Req.Params['mesa'].ToInteger;
  except
    Res.Send('Mesa Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('update mesa set tot_mesa = 0, sts_mesa = 0, selecionada = 0 where id_mesa = :id');
  conexao.Parametros('id', ID);
  conexao.ExecuteSQL;

  conexao.Free;
end;

procedure DoPostDeletaMesa(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin

  try
    ID := Req.Params['mesa'].ToInteger;
  except
    Res.Send('Mesa Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('delete from mesa where id_mesa = :id');
  conexao.Parametros('id', ID);
  conexao.ExecuteSQL;

  conexao.Free;
end;

procedure DoGetFileTest(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  ArqStream: TStream;
  Body: TJSONValue;
  arq: string;
begin
  Body := TJSONObject.ParseJSONValue(TEncoding.UTF8.Getbytes(Req.Body), 0)
    as TJSONValue;
  arq := 'C:\Temp\Files\' + Body.GetValue<string>('arquivo');
  // {"arquivo": "arquivo.pdf"}
  Body.DisposeOf;

  if FileExists(arq) then
  begin
    ArqStream := TFileStream.Create(arq, fmOpenRead);
    Res.Send<TStream>(ArqStream);
    // Writeln('Arquivo enviado: ' + arq);
  end
  else
    Res.Send('Arquivo não encontrado: ' + arq).Status(404);
end;

procedure DoPostTest(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  LUploadConfig: TUploadConfig;
begin
  LUploadConfig := TUploadConfig.Create('c:\serverfiles');
  LUploadConfig.ForceDir := true;
  LUploadConfig.OverrideFiles := true;

  // Optional: Callback for each file received
  LUploadConfig.UploadFileCallBack :=
      procedure(Sender: TObject; AFile: TUploadFileInfo)
    begin
      // Writeln('');
      // Writeln('Upload file: ' + AFile.filename + ' ' + AFile.Size.ToString);
    end;

  // Optional: Callback on end of all files
  LUploadConfig.UploadsFishCallBack :=
      procedure(Sender: TObject; AFiles: TUploadFiles)
    begin
      // Writeln('');
      // Writeln('Finish ' + AFiles.Count.ToString + ' files.');
    end;

  Res.Send<TUploadConfig>(LUploadConfig);
end;

procedure DoGetDadosPedido(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  ID, Usuario: Integer;
  Origem: String;
  DadosObjeto: TJSONObject;
  t0, t1, t2, t3, t4, t5, t6: Int64;
  VendaDireta: Boolean;
begin
  t0 := GetTickCount64;
  VendaDireta := false;
  try
    ID := Req.Params['codigo'].ToInteger;
  except
    ID := 0;
  end;
  try
    Usuario := Req.Params['usuario'].ToInteger;
  except
    Usuario := 0;
  end;
  try
    VendaDireta := (Req.Params['completo'].ToInteger = 1);
  except

  end;

  conexao := Tconexao.Create('Util');

  if Usuario > 0 then
  begin
    if ID = 0 then
    begin
      conexao.SQL.Add
        ('select max(codigo) as codigo from pedido where usuario = :usuario and codigo_pedido_dia = 0 and status = -1 and id_caixa is null');
      conexao.Parametros('usuario', Usuario);
      try
        ID := conexao.FieldByName('codigo');
      except
      end;
    end;
  end;

  t1 := GetTickCount64;

  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from index_pedido where id = :codigo');
  conexao.Parametros('codigo', ID);
  Origem := conexao.FieldByName('referencia');
  if Origem = '0' then
    Origem := '';
  if Origem <> '' then
    Origem := '_' + Origem;

  t2 := GetTickCount64;

  conexao.SQL.Add
    ('select m.id_mesa as mesa, concat(mt.descricao," ",m.nr_mesa) as descricao, p.id_ficha, m.tot_mesa as valor_total_pedido from pedido as p');
  conexao.SQL.Add('join mesa as m on m.selecionada = p.codigo');
  conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
  conexao.SQL.Add
    ('where p.codigo = :codigo and (p.id_ficha <> m.id_mesa or p.id_ficha is null)');
  conexao.Parametros('codigo', ID);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  t3 := GetTickCount64;

  if Dados.RecordCount > 0 then
  begin
    conexao.SQL.Add
      ('update pedido set id_ficha = :mesa, desc_ficha = :descricao, valor_total_pedido = :valor_total_pedido where codigo = :codigo');
    conexao.Parametros('mesa', Dados.FieldByName('mesa').AsInteger);
    conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
    conexao.Parametros('valor_total_pedido',
      Dados.FieldByName('valor_total_pedido').AsFloat);
    conexao.Parametros('codigo', ID);
    conexao.ExecuteSQL;
  end;

  Dados.Free;
  Dados := TFDMemTable.Create(nil);

  t4 := GetTickCount64;

  conexao.SQL.Add('SELECT * FROM pedido' + Origem + ' where codigo = :codigo');
  conexao.Parametros('codigo', ID);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  t5 := GetTickCount64;

  if Dados.RecordCount > 0 then
  begin
    DadosObjeto := Dados.ToJSONObject;
    DadosObjeto.AddPair('productList', GetDadosProdutoPedido(ID));
    Res.Send<TJSONObject>(DadosObjeto);
  end
  else
  begin
    if ID = 0 then
      ID := conexao.GerarID('pedido', 'codigo');

    conexao.SQL.Add
      ('insert into pedido (codigo,codigo_pedido_dia,status,origem,codigo_cliente,codigo_cliente_endereco,valor_pedido,valor_desconto,valor_total_pedido,valor_taxa_entrega,taxa_servico,data_pedido,hora_pedido,usuario,pedido_impresso)');
    conexao.SQL.Add
      ('values (:codigo,0,-1,4,0,0,0,0,0,0,0,current_date, current_time,:usuario,:pedido_impresso)');
    conexao.Parametros('codigo', ID);
    conexao.Parametros('usuario', Usuario);
    // if VendaDireta then
    // conexao.Parametros('pedido_impresso', 1)
    // else
    conexao.Parametros('pedido_impresso', 0);

    conexao.ExecuteSQL;
    conexao.SQL.Add
      ('SELECT * FROM pedido where status = -1 and origem = 4 and codigo = ' +
      ID.ToString + ' order by codigo desc');
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Res.Send<TJSONObject>(Dados.ToJSONObject);
  end;

  t6 := GetTickCount64;

  // Log dos tempos
  LogTempoExecucaoPedido('Tempo total: ' + IntToStr(t6 - t0) + ' ms');
  LogTempoExecucaoPedido('  ▸ Busca ID/Codigo: ' + IntToStr(t1 - t0) + ' ms');
  LogTempoExecucaoPedido('  ▸ Busca index_pedido: ' + IntToStr(t2 - t1)
    + ' ms');
  LogTempoExecucaoPedido('  ▸ Consulta mesa: ' + IntToStr(t3 - t2) + ' ms');
  LogTempoExecucaoPedido('  ▸ Update pedido: ' + IntToStr(t4 - t3) + ' ms');
  LogTempoExecucaoPedido('  ▸ Consulta pedido: ' + IntToStr(t5 - t4) + ' ms');
  LogTempoExecucaoPedido('  ▸ Final + GetDadosProdutoPedido: ' +
    IntToStr(t6 - t5) + ' ms');
  LogTempoExecucaoPedido('-------------------------');

  Dados.Free;
  conexao.Free;
end;

// procedure DoGetDadosPedido(Req: THorseRequest; Res: THorseResponse;
//
// Next: TProc);
// var
// conexao: Tconexao;
// Dados: TFDMemTable;
// ID: Integer;
// Usuario: Integer;
// Origem: String;
// DadosObjeto : TJSONObject;
// begin
//
// try
// ID := Req.Params['codigo'].ToInteger;
// except
// ID := 0;
// end;
//
// try
// Usuario := Req.Params['usuario'].ToInteger;
// except
// Usuario := 0;
// end;
//
// conexao := Tconexao.Create('Util');
// if Usuario > 0 then
// begin
//
// if ID = 0 then
// begin
// conexao.SQL.Add
// ('select max(codigo) as codigo, 0 as zero from pedido where usuario = :usuario and codigo_pedido_dia = 0 and status = -1 and id_caixa is null');
// conexao.Parametros('usuario', Usuario);
// try
// ID := conexao.FieldByName('codigo')
// except
//
// end;
// end;
//
// end;
//
// Dados := TFDMemTable.Create(nil);
// conexao.SQL.Add('select * from index_pedido where id = :codigo');
// conexao.Parametros('codigo', ID);
// Origem := conexao.FieldByName('referencia');
// if Origem = '0' then
// Origem := '';
//
// if Origem <> '' then
// begin
// Origem := '_' + Origem;
// end;
//
// conexao.SQL.Add
// ('select m.id_mesa as mesa, concat(mt.descricao," ",m.nr_mesa) as descricao, p.id_ficha, m.tot_mesa as valor_total_pedido from pedido as p');
// conexao.SQL.Add('join mesa as m on m.selecionada = p.codigo');
// conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
// conexao.SQL.Add
// ('where p.codigo = :codigo and (p.id_ficha <> m.id_mesa or p.id_ficha is null)');
// conexao.Parametros('codigo', ID);
// Dados.LoadFromJSON(conexao.ConsultaSQL);
//
// if Dados.RecordCount > 0 then
// begin
//
// conexao.SQL.Add
// ('update pedido set id_ficha = :mesa, desc_ficha = :descricao, valor_total_pedido = :valor_total_pedido where codigo = :codigo');
// conexao.Parametros('mesa', Dados.FieldByName('mesa').AsInteger);
// conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
// conexao.Parametros('valor_total_pedido',
// Dados.FieldByName('valor_total_pedido').AsFloat);
// conexao.Parametros('codigo', ID);
// conexao.ExecuteSQL;
// end;
// Dados.Free;
// Dados := TFDMemTable.Create(nil);
// conexao.SQL.Add('SELECT * FROM pedido' + Origem + ' where codigo = :codigo');
// conexao.Parametros('codigo', ID);
// Dados.LoadFromJSON(conexao.ConsultaSQL);
//
// if Dados.RecordCount > 0 then
// begin
// DadosObjeto := TJSONObject.Create;
// DadosObjeto := Dados.ToJSONObject();
// DadosObjeto.AddPair('productList',GetDadosProdutoPedido(ID));
// Res.Send<TJSONObject>(DadosObjeto);
// end
// else
// begin
// if ID = 0 then
// begin
//
// ID := conexao.GerarID('pedido', 'codigo');
// // conexao.SQL.Add('SELECT * FROM pedido where status = -1 and origem = 4 order by codigo desc');
// end
// else
// begin
//
// end;
//
// conexao.SQL.Add
// ('insert into pedido (codigo,codigo_pedido_dia,status,origem,codigo_cliente,codigo_cliente_endereco,valor_pedido,valor_desconto,valor_total_pedido,valor_taxa_entrega,taxa_servico,data_pedido,hora_pedido,usuario)');
// conexao.SQL.Add
// ('values (:codigo,0,-1,4,0,0,0,0,0,0,0,current_date, current_time,:usuario)');
// conexao.Parametros('codigo', ID);
// conexao.Parametros('usuario', Usuario);
// conexao.ExecuteSQL;
//
// conexao.SQL.Add
// ('SELECT * FROM pedido where status = -1 and origem = 4 and codigo = ' +
// ID.ToString + ' order by codigo desc');
// Dados.LoadFromJSON(conexao.ConsultaSQL);
// Res.Send<TJSONObject>(Dados.ToJSONObject());
// end;
//
// Dados.Free;
// conexao.Free;
// end;

function FormatarTelefone(Numero: String): String;
begin
  // Remove qualquer caractere não numérico
  Numero := StringReplace(Numero, '(', '', [rfReplaceAll]);
  Numero := StringReplace(Numero, ')', '', [rfReplaceAll]);
  Numero := StringReplace(Numero, '-', '', [rfReplaceAll]);
  Numero := StringReplace(Numero, ' ', '', [rfReplaceAll]);
  // Verifica se o número possui 11 dígitos
  if length(Numero) = 11 then
    Result := Format('(%s) %s-%s', [COPY(Numero, 1, 2), COPY(Numero, 3, 5),
      COPY(Numero, 8, 4)])
  else
    Result := Numero; // Retorna o número original se não tiver 11 dígitos
end;

procedure DoGetConsultaClienteCelular(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Celular: String;
begin

  try
    Celular := Req.Params['celular'];
  except
    Res.Send('celular Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('select * from cliente as c');
  conexao.SQL.Add
    ('left join cliente_endereco as ce on ce.codigo_cliente = c.codigo');
  conexao.SQL.Add
    ('left join taxa_entrega as te on te.bairro = ce.bairro and te.cidade = ce.cidade');
  conexao.SQL.Add('where (c.celular like "%' + Celular +
    '%" or c.celular_wpp like "%' + Celular + '%" or c.celular_wpp like "%' +
    FormatarTelefone(Celular) + '%") order by ce.codigo desc limit 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetConsultaCliente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin

  try
    ID := Req.Params['codigo'].ToInteger;
  except
    Res.Send('Código Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from cliente where codigo = :codigo');
  conexao.Parametros('codigo', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetConsultaClienteEndereco(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin

  try
    ID := Req.Params['codigo'].ToInteger;
  except
    Res.Send('Código Não Informado').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select c.*, t.valor_taxa from cliente_endereco as c');
  conexao.SQL.Add
    ('left join taxa_entrega as t on t.bairro = c.bairro and c.cidade = t.cidade and c.estado = t.estado ');
  conexao.SQL.Add('where c.codigo = :codigo');
  conexao.Parametros('codigo', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetAtualizacaoApp(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  form: String;
begin

  Res.Send('{"versao_app":"1", "versao_servidor":"1", "versao_minima":"1", "origem_donwload":""}');

end;

procedure DoPostAtualizaDadosPedido(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  CodigoPedido: Integer;
  Troco: Real;
  Cliente: Integer;
  // tipo
  Tipo: Boolean;
  Entrega: Integer;
  DadosEntrega: TFDMemTable;
  TotalProduto: Real;
  ClienteNome: String;
  Usuario: Integer;
begin

  try
    Tipo := (Req.Params['tipo'].ToInteger > 0);
  except
    Tipo := false;
  end;
  {

    memDadosPedido.FieldByName('codigo').AsInteger := CodigoPedido;
    memDadosPedido.FieldByName('data').AsDateTime := edtData.Date;
    memDadosPedido.FieldByName('hora').AsDateTime := edtHora.Time;
    memDadosPedido.FieldByName('produto').AsFloat := ValorProduto;
    memDadosPedido.FieldByName('acrecimo').AsFloat := ValorAcrescimo;
    memDadosPedido.FieldByName('entrega').AsFloat := ValorEntrega;
    memDadosPedido.FieldByName('desconto').AsFloat := ValorDesconto;
    memDadosPedido.FieldByName('total').AsFloat := ValorTotal;
    memDadosPedido.FieldByName('cliente').AsInteger := CodigoCliente;


  }
  Entrega := 0;
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount > 0 then
  begin
    if Dados.FieldByName('produto').AsInteger = 0 then
    begin
      Dados.Free;
      exit;
    end;

    conexao := Tconexao.Create('Util');
    Dados.Edit;
    if Dados.FieldByName('cliente').AsInteger = 0 then
    begin
      conexao.SQL.Add('select * from cliente where celular = :celular');
      conexao.Parametros('celular', Dados.FieldByName('celular').AsString);
      try
        Cliente := conexao.FieldByName('codigo');
        Dados.FieldByName('cliente').AsInteger := Cliente;
      except
        Cliente := 0;
      end;
      if Cliente = 0 then
      begin
        Dados.FieldByName('cliente').AsInteger :=
          conexao.GerarID('cliente', 'codigo');

        conexao.SQL.Add
          ('insert into cliente (codigo,nome,celular,celular_wpp,ativo,cpf) values  (:codigo,:nome,:celular,:celular_wpp,1,:cpf)');
        conexao.Parametros('codigo', Dados.FieldByName('cliente').AsInteger);
        conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
        conexao.Parametros('celular', Dados.FieldByName('celular').AsString);
        conexao.Parametros('cpf', Dados.FieldByName('cpf').AsString);
        conexao.Parametros('celular_wpp',
          NonoDigito(Dados.FieldByName('celular').AsString));
        conexao.ExecuteSQL;
      end;

    end;
    try
      ClienteNome := Dados.FieldByName('balcao').AsString;
    except
      ClienteNome := '';
    end;

    try
      Usuario := Dados.FieldByName('usuario').AsInteger;
    except
      Usuario := 0;
    end;

    if Dados.FieldByName('endereco').AsInteger = 0 then
    begin

      Dados.FieldByName('endereco').AsInteger :=
        conexao.GerarID('cliente_endereco', 'codigo');
      conexao.SQL.Add
        ('insert into cliente_endereco (codigo,codigo_cliente,descricao,tipo,numero,rua,bairro,cidade,estado,complemento,ativo,km) values');
      conexao.SQL.Add
        ('(:codigo,:codigo_cliente,:descricao,:tipo,:numero,:rua,:bairro,:cidade,:estado,:complemento,1,0)');
      conexao.Parametros('codigo', Dados.FieldByName('endereco').AsInteger);
      conexao.Parametros('codigo_cliente', Dados.FieldByName('cliente')
        .AsString);
      conexao.Parametros('descricao', 'Principal');
      conexao.Parametros('tipo', 1);
      conexao.Parametros('rua', Dados.FieldByName('rua').AsString);
      conexao.Parametros('bairro', Dados.FieldByName('bairro').AsString);
      conexao.Parametros('cidade', Dados.FieldByName('cidade').AsString);
      conexao.Parametros('estado', Dados.FieldByName('estado').AsString);
      conexao.Parametros('complemento', Dados.FieldByName('complemento')
        .AsString);
      conexao.Parametros('numero', Dados.FieldByName('numero').AsString);
      conexao.Parametros('codigo', Dados.FieldByName('endereco').AsString);
      conexao.ExecuteSQL;
    end;
    if Dados.FieldByName('endereco').AsInteger < 0 then
      Dados.FieldByName('endereco').AsInteger := 0;

    Entrega := Dados.FieldByName('endereco').AsInteger;

    if not Tipo then
    begin

      conexao.SQL.Add
        ('select codigo_pedido_dia as dia, 0 as zero from pedido where codigo = :codigo');
      conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
      try
        CodigoPedido := conexao.FieldByName('dia');
      except
        CodigoPedido := 0
      end;
      if CodigoPedido = 0 then
      begin
        CodigoPedido := GeraCodigoPorDiaPedido(Dados.FieldByName('codigo')
          .AsInteger);
        conexao.SQL.Add
          ('update pedido set codigo_pedido_dia = :codigo_pedido_dia, status = 1, usuario = :usuario, data_pedido = curdate(), hora_pedido = curtime() where codigo = :codigo');
        conexao.Parametros('usuario', Usuario);
        conexao.Parametros('codigo_pedido_dia', CodigoPedido);
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        conexao.ExecuteSQL;
        conexao.SQL.Add
          ('update pedido_produtos set tempo_liberacao = 0 where codigo_pedido = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        conexao.ExecuteSQL;
      end;
      if Dados.FieldByName('endereco').AsInteger > 0 then
      begin
        conexao.SQL.Add
          ('select pp.*, p.valor_embalagem_delivery from pedido_produtos as pp');
        conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
        conexao.SQL.Add('where pp.codigo_pedido = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        DadosEntrega := TFDMemTable.Create(nil);
        DadosEntrega.LoadFromJSON(conexao.ConsultaSQL);

        if DadosEntrega.RecordCount > 0 then
        begin
          while not DadosEntrega.Eof do
          begin
            // conexao.SQL.Add('update pedido_produtos set vl_delivery = :adicional, valor_total = (valor_unitario + valor_adicional + vl_delivery) * quantidade where codigo = :codigo');
            conexao.SQL.Add('UPDATE pedido_produtos ');
            conexao.SQL.Add('SET vl_delivery = COALESCE(:adicional, 0),');
            conexao.SQL.Add
              ('    valor_total = (valor_unitario + COALESCE(valor_adicional, 0) + COALESCE(vl_delivery, 0)) * quantidade ');
            conexao.SQL.Add('WHERE codigo = :codigo;');
            conexao.Parametros('adicional',
              DadosEntrega.FieldByName('valor_embalagem_delivery').AsFloat);
            conexao.Parametros('codigo', DadosEntrega.FieldByName('codigo')
              .AsInteger);
            conexao.ExecuteSQL;
            DadosEntrega.Next;
          end;
        end;
        DadosEntrega.Free;
      end;

    end;

    conexao.SQL.Add
      ('update cliente set nome = :nome, celular = :celular, celular_wpp = :celular, cpf = :cpf where codigo = :codigo');
    conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
    conexao.Parametros('celular', Dados.FieldByName('celular').AsString);
    try
      conexao.Parametros('cpf', Dados.FieldByName('cpf').AsString);
    except
      conexao.Parametros('cpf', '');
    end;

    conexao.Parametros('codigo', Dados.FieldByName('cliente').AsString);
    conexao.ExecuteSQL;

    if Dados.FieldByName('endereco').AsInteger > 0 then
    begin

      conexao.SQL.Add
        ('update cliente_endereco set rua = :rua, bairro = :bairro, cidade = :cidade, estado = :estado, complemento = :complemento, numero = :numero where codigo = :codigo');
      conexao.Parametros('rua', Dados.FieldByName('rua').AsString);
      conexao.Parametros('bairro', Dados.FieldByName('bairro').AsString);
      conexao.Parametros('cidade', Dados.FieldByName('cidade').AsString);
      conexao.Parametros('estado', Dados.FieldByName('estado').AsString);
      conexao.Parametros('complemento', Dados.FieldByName('complemento')
        .AsString);
      conexao.Parametros('numero', Dados.FieldByName('numero').AsString);
      conexao.Parametros('codigo', Dados.FieldByName('endereco').AsString);
      conexao.ExecuteSQL;

    end;

    try
      Troco := Dados.FieldByName('troco').AsFloat;
    except
      Troco := 0;
    end;

    // select sum(valor_total) as total, 0 as zero from pedido_produtos where codigo_pedido = 669

    conexao.SQL.Add
      ('select sum(valor_total) as total, 0 as zero from pedido_produtos where codigo_pedido = :codigo');
    conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
    try
      TotalProduto := conexao.FieldByName('total');
    except

    end;

    conexao.SQL.Add
      ('update pedido set codigo_cliente = :cliente, codigo_cliente_endereco = :endereco, data_pedido = :data, origem = 5,');
    conexao.SQL.Add
      ('nome = :nome, cpf = :cpf, hora_pedido = :hora,tipo_pagamento = :tipo_pagamento, status = :status, valor_pedido = :produto, troco = :troco, valor_desconto = :desconto, ');
    conexao.SQL.Add
      ('valor_taxa_entrega = :entrega, valor_total_pedido = :total, taxa_servico = :acrecimo, usuario = :usuario, nome = :nome where codigo = :codigo');

    conexao.Parametros('cliente', Dados.FieldByName('cliente').AsInteger);
    conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
    try
      conexao.Parametros('cpf', Dados.FieldByName('cpf').AsString);
    except
      conexao.Parametros('cpf', '');
    end;
    conexao.Parametros('endereco', Dados.FieldByName('endereco').AsInteger);
    conexao.Parametros('usuario', Usuario);
    conexao.Parametros('data', Dados.FieldByName('data').AsString);
    conexao.Parametros('hora', (Dados.FieldByName('hora').AsString));
    conexao.Parametros('status', Dados.FieldByName('status').AsInteger);
    conexao.Parametros('produto', TotalProduto);
    conexao.Parametros('desconto', Dados.FieldByName('desconto').AsFloat);
    conexao.Parametros('entrega', Dados.FieldByName('entrega').AsFloat);
    conexao.Parametros('total', (TotalProduto + Dados.FieldByName('entrega')
      .AsFloat + Dados.FieldByName('acrecimo').AsFloat) -
      Dados.FieldByName('desconto').AsFloat);
    conexao.Parametros('acrecimo', Dados.FieldByName('acrecimo').AsFloat);
    conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
    conexao.Parametros('tipo_pagamento', Dados.FieldByName('tipo_pagamento')
      .AsInteger);
    conexao.Parametros('troco', Troco);
    conexao.Parametros('nome', ClienteNome);

    conexao.ExecuteSQL;

    conexao.Free;
  end;

end;

procedure DoGetConsultaGenerica(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  Tabela: String;
  Campos: String;
  Condicao: String;
  OrderBy: String;
begin

  try
    Tabela := Req.Params['tabela'];
  except
    Res.Send('Tabela Não Informado').Status(500);
    exit;
  end;
  try
    Campos := Req.Params['campo'];
  except
    Campos := '*';
  end;
  try
    Condicao := 'and ' + Req.Params['condicao'];
    if Req.Params['condicao'] = '*' then
      Condicao := '';
  except
    Condicao := '';
  end;
  try
    OrderBy := ' order by ' + Req.Params['orderby'];
    if Req.Params['orderby'] = '*' then
      OrderBy := '';
  except
    OrderBy := '';

  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select ' + Campos + ' from ' + Tabela + ' where 1 = 1 ' +
    Condicao + OrderBy);

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetSaboresPreco(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select group_concat(sc.id) as codigo, group_concat(sc.id_produto) as produto, group_concat(sc.vl_venda) as venda, sc.nome, group_concat(p.nome_produto) as nome_produto from sabores_completo as sc');
  conexao.SQL.Add('join produto as p on p.codigo = sc.id_produto');
  conexao.SQL.Add('group by nome');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostSaboresPreco(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin

  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');

  Dados.First;
  while not Dados.Eof do
  begin
    conexao.SQL.Add
      ('update sabores_completo set vl_venda = :novo, modificado_site = 0 where id = :codigo');
    conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
    conexao.Parametros('novo', Dados.FieldByName('novo').AsFloat);

    if Dados.FieldByName('novo').AsFloat <> Dados.FieldByName('valor').AsFloat
    then
      conexao.ExecuteSQL;
    Dados.Next;
  end;
  conexao.Free;
end;

procedure DoGetVersao(Req: THorseRequest; Res: THorseResponse;

Next: TProc);

begin
  Res.Send('');
  // conexao := Tconexao.Create('Util');
  // Dados := TFDMemTable.Create(nil);
  //
  // conexao.SQL.Add('SELECT * FROM ATUALIZACAOAPP');
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  //
  // if Dados.RecordCount = 0 then
  // begin
  // conexao.SQL.Add('INSERT INTO ATUALIZACAOAPP VALUES (' + QuotedStr('1.0') +
  // ',' + QuotedStr('1.0') + ',' + QuotedStr('') + ');');
  // end;
  //
  // conexao.SQL.Add('SELECT * FROM ATUALIZACAOAPP');
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  //
  // Res.Send('{"versao_app":"' + Dados.FieldByName('VERSAOAPP').AsString +
  // '", "versao_servidor":"' + GetBuildInfo + '", "versao_minima":"' +
  // Dados.FieldByName('VERSAOMINIMA').AsString + '", "origem_donwload":"' +
  // Dados.FieldByName('ORIGEMDOWNLOAD').AsString + '"}');
  //
  // conexao.Free;
  // Dados.Free;
end;

procedure DoPostMovimentacaoCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    exit;
  end;

  if Dados.FieldByName('tipo').AsInteger = 0 then
  begin
    // 3 - Entrada
    MovimentoCaixa(Dados.FieldByName('caixa').AsInteger, 0, 0, 3,
      Dados.FieldByName('valor').AsFloat, Dados.FieldByName('descricao')
      .AsString, 0);
  end
  else
  begin
    // 2 - Saida
    MovimentoCaixa(Dados.FieldByName('caixa').AsInteger, 0, 0, 2,
      Dados.FieldByName('valor').AsFloat, Dados.FieldByName('descricao')
      .AsString, 0);
  end;

end;

procedure DoGetHistoricoMotoboyCompleto(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;

  Codigo: String;
begin
  try
    Codigo := (Req.Params['codigo']);
  except
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select p.codigo,p.codigo_pedido_dia, c.nome, ce.bairro, p.valor_taxa_entrega, p.valor_total_pedido from pedido as p');
  conexao.SQL.Add
    ('join cliente_endereco as ce on ce.codigo = p.codigo_cliente_endereco');
  conexao.SQL.Add('join cliente as c on c.codigo = p.codigo_cliente');
  conexao.SQL.Add('where p.codigo in (' + Codigo + ')');
  conexao.SQL.Add('order by p.codigo,p.codigo_pedido_dia,ce.bairro');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetHistoricoMotoboy(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  DataInicial: TDate;
begin

  try
    DataInicial := TransformaData(Req.Params['dataini']);
  except
    DataInicial := Date;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select group_concat(p.codigo) as codigo,group_concat(p.codigo_pedido_dia) as dia, sum(p.valor_taxa_entrega) as taxa, sum(p.valor_total_pedido) as total, upper(m.nome) as nome from pedido as p');
  conexao.SQL.Add('join pedido_motoboy as pm on pm.codigo_pedido = p.codigo');
  conexao.SQL.Add('join motoboy as m on m.codigo = pm.codigo_motoboy');
  conexao.SQL.Add('where p.data_pedido >= :data');
  conexao.SQL.Add('group by m.codigo');
  conexao.Parametros('data', FormatDateTime('yyyy-mm-dd', DataInicial));
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoUpdateGeral(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add(Req.Body);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoGetImpressoraServidor(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
begin

  Res.Send<TJSONArray>(frmServidor.memImpressora.ToJSONArray());
end;

procedure DoPostAlteracao(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  ValorAntigo: Real;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;
  conexao := Tconexao.Create('Util');
  while not Dados.Eof do
  begin
    case Dados.FieldByName('tipo_id').AsInteger of
      1:
        begin
          // Extra
          conexao.SQL.Add
            ('select * from pro_adi_personalizado_sabores where id = :id');
          conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
          ValorAntigo := conexao.FieldByName('valor');

          if ValorAntigo <> Dados.FieldByName('valor').AsFloat then
          begin

            conexao.SQL.Add
              ('update pro_adi_personalizado_sabores set valor = :valor, modificado_site = 0 where upper(nome) = upper(:nome) and valor = :valorantigo');
            conexao.Parametros('nome', Dados.FieldByName('descricao').AsString);
            conexao.Parametros('valor', Dados.FieldByName('valor').AsFloat);
            conexao.Parametros('valorantigo', ValorAntigo);
            conexao.ExecuteSQL;
          end;
          // extra - De
        end;
      2:
        begin
          // Sabor
          conexao.SQL.Add
            ('update sabores_completo set modificado_site = 0, vl_venda = :valor where id = :id');
          conexao.Parametros('valor', Dados.FieldByName('valor').AsFloat);
          conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
          conexao.ExecuteSQL;
        end;
      3:
        begin
          // Tabela de Preço
        end;
    end;

    Dados.Next;
  end;

  Dados.Free;
  conexao.Free;
end;

procedure DoPostAtualizaProdutoExtra(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');

  with conexao do
  begin
    SQL.Add('update pro_adi_personalizado set descricao = :descricao, qtd_minima = :min, qtd_maxima = :max, ativo =:status where id = :id');
    Parametros('descricao', Dados.FieldByName('descricao').AsString);
    Parametros('min', Dados.FieldByName('min').AsString);
    Parametros('max', Dados.FieldByName('max').AsString);
    Parametros('status', Dados.FieldByName('status').AsString);
    Parametros('id', Dados.FieldByName('id').AsString);
    ExecuteSQL;
    SQL.Add('update pro_adi_personalizado_sabores set modificado_site = 0 where id_pro_adi_personalizado = :id');
    Parametros('id', Dados.FieldByName('id').AsString);
    ExecuteSQL;
  end;

  conexao.Free;
end;

procedure DoPostAtualizaExtraItens(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Codigo: Integer;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');

  with conexao do
  begin
    SQL.Add('update pro_adi_personalizado_sabores set modificado_site = 0, ativo = 0 where id_pro_adi_personalizado = :id');
    Parametros('id', Dados.FieldByName('id_pro_adi_personalizado').AsString);
    ExecuteSQL;
    SQL.Add('update pro_adi_personalizado set modificado_site = 0 where id = :id');
    Parametros('id', Dados.FieldByName('id_pro_adi_personalizado').AsString);
    ExecuteSQL;
  end;

  while not Dados.Eof do
  begin
    if (Dados.FieldByName('id').AsInteger = 0) then
    begin
      //
      Codigo := conexao.GerarID('pro_adi_personalizado_sabores', 'id');
      with conexao do
      begin

        SQL.Add('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo,modificado_site,id_site,id_ingredientes,quantidade_ingredientes)');
        SQL.Add('values (:id,:extra,:nome,:descricao,:valor,:ativo,0,0,:id_ingredientes,:quantidade_ingredientes)');
        Parametros('id', Codigo);
        Parametros('extra', Dados.FieldByName('id_pro_adi_personalizado')
          .AsString);
        Parametros('nome', Dados.FieldByName('nome').AsString);
        Parametros('descricao', Dados.FieldByName('descricao').AsString);
        Parametros('valor', Dados.FieldByName('valor').AsString);
        Parametros('ativo', Dados.FieldByName('ativo').AsString);
        Parametros('id_ingredientes', Dados.FieldByName('ingredientes')
          .AsString);
        Parametros('quantidade_ingredientes',
          StringReplace(Dados.FieldByName('quantidade').AsString, ',', '.',
          [rfReplaceAll]));
        ExecuteSQL;
      end;

    end
    else
    begin
      with conexao do
      begin
        SQL.Add('update pro_adi_personalizado_sabores  set nome = :nome, descricao = :descricao, valor = :valor, ativo = :ativo, id_ingredientes = :id_ingredientes,quantidade_ingredientes = :quantidade_ingredientes,  modificado_site = 0 where id = :id');
        Parametros('nome', Dados.FieldByName('nome').AsString);
        Parametros('descricao', Dados.FieldByName('descricao').AsString);
        Parametros('valor', Dados.FieldByName('valor').AsString);
        Parametros('ativo', Dados.FieldByName('ativo').AsString);
        Parametros('id', Dados.FieldByName('id').AsString);
        Parametros('id_ingredientes', Dados.FieldByName('ingredientes')
          .AsString);
        Parametros('quantidade_ingredientes',
          StringReplace(Dados.FieldByName('quantidade').AsString, ',', '.',
          [rfReplaceAll]));
        ExecuteSQL;
      end;
    end;
    Dados.Next;
  end;

  conexao.Free;
end;


//

{ procedure DoPostAtualizaProdutoExtra(Req: THorseRequest; Res: THorseResponse;

  Next: TProc);
  var
  conexao : TConexao;
  ID: Integer;
  begin

  try
  ID := Req.Params['id'].ToInteger;
  except
  Res.Send('Pedido Não Informado').Status(500);
  exit;
  end;

  conexao := TConexao.Create('Util');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  end;
}

procedure DoGetLimpaBanco(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Banco: String;
  Chave: String;
  Dados: TFDMemTable;
begin

  try
    Banco := LowerCase(Req.Params['banco']);
  except
    Res.Send('Banco Não Informado').Status(500);
    exit;
  end;

  try
    Chave := Req.Params['chave'];
  except
    Res.Send('Chave Não Informado').Status(500);
    exit;
  end;

  if Chave <> FormatDateTime('ddmmyyyy', Now) then
  begin
    Res.Send('Chave Errada').Status(500);
    exit;
  end;

  conexao := Tconexao.Create('Util');
  if conexao.NomeBanco <> Banco then
  begin
    Res.Send('Banco não conectado! Banco atual: ' + conexao.NomeBanco)
      .Status(500);
    conexao.Free;
    exit;
  end;

  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT TABLE_NAME AS tabela, 0 AS ZERO FROM information_schema.tables where table_schema = :banco and TABLE_NAME not in ('
    + QuotedStr('usuario') + ',' + QuotedStr('bairros_cidade') + ',' +
    QuotedStr('sql_banco') + ',' + QuotedStr('impressoras') + ',' +
    QuotedStr('dados_whatsapp') + ',' + QuotedStr('status_pedido') + ')');
  conexao.Parametros('banco', Banco);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  while not Dados.Eof do
  begin
    conexao.SQL.Add('delete from ' + Dados.FieldByName('tabela').AsString);
    conexao.ExecuteSQL;

    Dados.Next;
  end;

  Res.Send('Banco limpo com sucesso!');
  conexao.Free;
end;

//

procedure DoPostTipoPagamento(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Codigo: Integer;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');
  Codigo := Dados.FieldByName('codigo').AsInteger;
  if Codigo = 0 then
  begin
    Codigo := conexao.GerarID('tipo_pagamento', 'codigo');
    conexao.SQL.Add('insert into tipo_pagamento (codigo) values (:codigo)');
    conexao.Parametros('codigo', Codigo);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add
    ('update tipo_pagamento set descricao = :descricao, troco_delivery = :troco_delivery, ativo = :ativo, movimentacao = :movimentacao, tipo_chave_pix = :tipo_chave_pix, chave_pix = :chave_pix, chave_recebedor = :chave_recebedor where codigo = :codigo');

  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
  conexao.Parametros('troco_delivery', Dados.FieldByName('troco_delivery')
    .AsInteger);
  conexao.Parametros('ativo', Dados.FieldByName('ativo').AsInteger);
  conexao.Parametros('movimentacao', Dados.FieldByName('movimentacao')
    .AsInteger);
  conexao.Parametros('chave_recebedor', Dados.FieldByName('chave_recebedor')
    .AsString);
  conexao.Parametros('chave_pix', Dados.FieldByName('chave_pix').AsString);
  conexao.Parametros('tipo_chave_pix', Dados.FieldByName('tipo_chave_pix')
    .AsString);
  conexao.ExecuteSQL;
  Dados.Free;
  conexao.Free;
end;

procedure DoPostImpressora(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Codigo: Integer;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');
  Codigo := Dados.FieldByName('codigo').AsInteger;
  if Codigo = 0 then
  begin
    Codigo := conexao.GerarID('impressoras', 'codigo');
    conexao.SQL.Add
      ('insert into impressoras (codigo,data,ativo,impressora_padrao,tipo_impressao) values (:codigo,current_date,0,0,0)');
    conexao.Parametros('codigo', Codigo);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add
    ('update impressoras set descricao = :descricao, driver = :driver, ativo =:ativo, impressora_padrao = :impressora_padrao, tipo_impressao = :tipo_impressao where codigo = :codigo');
  conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
  conexao.Parametros('driver', Dados.FieldByName('driver').AsString);
  conexao.Parametros('ativo', Dados.FieldByName('ativo').AsString);
  conexao.Parametros('impressora_padrao', Dados.FieldByName('impressora_padrao')
    .AsString);
  conexao.Parametros('tipo_impressao', Dados.FieldByName('tipo_impressao')
    .AsString);
  conexao.Parametros('codigo', Codigo);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoGetRelatorioFinanceiro(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
  Tipo: Integer;
  iDia: String;
  iMes: String;
  iAno: String;
  fDia: String;
  fMes: String;
  fAno: String;
  DataInicio: String;
  DataFim: String;

begin

  try
    Tipo := LowerCase(Req.Params['tipo']).ToInteger;
  except
    Res.Send('Tipo Não Informado').Status(500);
    exit;
  end;
  try
    iDia := Req.Params.Items['idia'];
  except
    Res.Status(THTTPStatus.NotFound);
    exit;
  end;
  try
    iMes := Req.Params.Items['imes'];
  except
    Res.Status(THTTPStatus.NotFound);
    exit;
  end;
  try
    iAno := Req.Params.Items['iano'];
  except
    Res.Status(THTTPStatus.NotFound);
    exit;
  end;
  try
    fDia := Req.Params.Items['fdia'];
  except
    Res.Status(THTTPStatus.NotFound);
    exit;
  end;
  try
    fMes := Req.Params.Items['fmes'];
  except
    Res.Status(THTTPStatus.NotFound);
    exit;
  end;
  try
    fAno := Req.Params.Items['fano'];
  except
    Res.Status(THTTPStatus.NotFound);
    exit;
  end;
  DataInicio := iAno + '-' + iMes + '-' + iDia;
  DataFim := fAno + '-' + fMes + '-' + fDia;

  conexao := Tconexao.Create('Util');
  case Tipo of
    1:
      begin
        // Todos pedido por periodo, agrupado por status e data
        conexao.SQL.Add
          ('select count(p.valor_total_pedido) as qtd, sum(p.valor_total_pedido) as total, sum(p.valor_taxa_entrega) as taxa, sum(p.valor_pedido) as pedido, sum(p.valor_desconto) as desconto, p.data_pedido, p.status, ss.descricao from pedido as p');
        conexao.SQL.Add('join status_pedido as ss on ss.id = p.status');
        conexao.SQL.Add
          ('where p.status >= 0 and p.data_pedido between :ini and :fim');
        conexao.SQL.Add('group by p.status');
        conexao.SQL.Add('order by p.data_pedido');
        conexao.Parametros('ini', DataInicio);
        conexao.Parametros('fim', DataFim);
      end;
    2:
      begin
        // todos produtos no periodo
        conexao.SQL.Add
          ('select count(p.codigo) as total, upper(pro.nome_produto) as produto, (count(p.codigo)*pro.valor_venda) as venda from pedido as p');
        conexao.SQL.Add('join status_pedido as ss on ss.id = p.status');
        conexao.SQL.Add
          ('join pedido_produtos as pp on pp.codigo_pedido = p.codigo');
        conexao.SQL.Add
          ('join produto as pro on pro.codigo = pp.codigo_produto');
        conexao.SQL.Add
          ('join tipo_produto as tp on tp.codigo = pro.codigo_grupo');
        conexao.SQL.Add
          ('where p.status > 0 and p.data_pedido between :ini and :fim');
        conexao.SQL.Add('group by pro.codigo');
        conexao.SQL.Add('order by (count(p.codigo)*pro.valor_venda) desc');
        conexao.Parametros('ini', DataInicio);
        conexao.Parametros('fim', DataFim);

      end;
    3:
      begin
        // todos os extras que forem maior que zero
        conexao.SQL.Add
          ('select count(p.codigo) as qtd, upper(concat(pps.nomeclatura,' +
          QuotedStr(' - ') +
          ',pps.descricao)) as nome, sum(pps.valor) as total from pedido as p');
        conexao.SQL.Add('join status_pedido as ss on ss.id = p.status');
        conexao.SQL.Add
          ('join pedido_produtos as pp on pp.codigo_pedido = p.codigo');
        conexao.SQL.Add
          ('join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp.codigo');
        conexao.SQL.Add
          ('where p.status >= 0 and pps.valor > 0 and p.data_pedido between :ini and :fim');
        conexao.SQL.Add('group by pp.codigo_produto, pps.descricao');
        conexao.SQL.Add('order by sum(pps.valor) desc, count(p.codigo) desc');
        conexao.Parametros('ini', DataInicio);
        conexao.Parametros('fim', DataFim);

      end;
    4:
      begin
        conexao.SQL.Add
          ('select count(p.valor_total_pedido) as qtd, sum(p.valor_total_pedido) as total, sum(p.valor_taxa_entrega) as taxa, sum(p.valor_pedido) as pedido, sum(p.valor_desconto) as desconto, p.data_pedido, p.status, ss.descricao from pedido as p');
        conexao.SQL.Add('join status_pedido as ss on ss.id = p.status');
        conexao.SQL.Add
          ('where p.status > 0 and p.data_pedido between :ini and :fim');
        conexao.SQL.Add('group by p.data_pedido');
        conexao.SQL.Add('order by p.data_pedido');
        conexao.Parametros('ini', DataInicio);
        conexao.Parametros('fim', DataFim);
      end;
    5:
      begin
        conexao.SQL.Add
          ('select count(*) as qtd, sum(pedido.valor_desconto) as desconto, sum(pedido.valor_pedido) as pedido, sum(pedido.valor_taxa_entrega) as taxa, sum(pedido.valor_total_pedido) as total, ');
        conexao.SQL.Add('pedido.origem, status_pedido.descricao,');
        conexao.SQL.Add('    CASE ');
        conexao.SQL.Add('        WHEN pedido.id_ficha > 0 THEN ''mesa''');
        conexao.SQL.Add('        ELSE ''''');
        conexao.SQL.Add('    END as mesa');
        conexao.SQL.Add('from pedido');
        conexao.SQL.Add
          ('join status_pedido on status_pedido.id = pedido.status ');
        conexao.SQL.Add('where pedido.data_pedido between :ini and :fim ');
        conexao.SQL.Add('group by origem, descricao, mesa');
        conexao.SQL.Add('order by origem');
        conexao.Parametros('ini', DataInicio);
        conexao.Parametros('fim', DataFim);

      end;
  end;
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetExtraAll(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  // conexao.SQL.Add
  // ('select p.codigo, pap.id as extra_id, upper(CONCAT(p.nome_produto,' +
  // QuotedStr(' -> ') +
  // ',pap.descricao)) as juncao, upper(p.nome_produto) as produto, upper(pap.descricao) as extra, upper(GROUP_CONCAT(paps.nome)) as itens from produto as p');
  // conexao.SQL.Add
  // ('join pro_adi_personalizado as pap on pap.id_produto = p.codigo');
  // conexao.SQL.Add
  // ('join pro_adi_personalizado_sabores as paps on paps.id_pro_adi_personalizado = pap.id');
  // conexao.SQL.Add('where paps.valor > 0');
  // conexao.SQL.Add('group by pap.id_produto');
  // conexao.SQL.Add('order by p.codigo');
  conexao.SQL.Add('SET SESSION group_concat_max_len = 1000000;');
  conexao.ExecuteSQL;
  conexao.SQL.Add('WITH CTE AS (');
  conexao.SQL.Add
    ('select max(pap.qtd_minima) as min, max(pap.qtd_maxima) as max,  p.codigo, pap.id as extra_id, upper(CONCAT(pap.descricao)) as juncao, upper(p.nome_produto) as produto,');
  conexao.SQL.Add
    ('upper(pap.descricao) as extra, upper(GROUP_CONCAT(paps.descricao SEPARATOR "||")) as descricao, GROUP_CONCAT(id_prod_estoque SEPARATOR "||") as stock,');
  conexao.SQL.Add
    ('upper(GROUP_CONCAT(paps.nome SEPARATOR "||")) as itens, GROUP_CONCAT(paps.valor SEPARATOR "||") as valores from produto as p');
  conexao.SQL.Add
    ('join pro_adi_personalizado as pap on pap.id_produto = p.codigo');
  conexao.SQL.Add
    ('join pro_adi_personalizado_sabores as paps on paps.id_pro_adi_personalizado = pap.id');
  // conexao.SQL.Add('where paps.valor > 0');
  conexao.SQL.Add('group by pap.id');
  conexao.SQL.Add('order by p.codigo)');
  conexao.SQL.Add
    ('select CTE.codigo,CTE.extra_id,CTE.juncao,CTE.produto,CTE.extra,CTE.codigo,CTE.itens,CTE.valores,CTE.min,CTE.max, CTE.descricao, CTE.stock');
  conexao.SQL.Add('from CTE');
  // conexao.SQL.Add('GROUP BY CTE.ITENS');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

// THorse.Post('/v1/util/extra/produtos/:extra/:produto', DoPostExtraAll);

procedure DoPostExtraAll(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Produto: Integer;
  Extra: Integer;
  Dados: TFDMemTable;
  Codigo: Integer;
  CodigoExtra: Integer;
begin
  try
    Extra := Req.Params['extra'].ToInteger;
  except
    Res.Send('Extra Não Informado').Status(500);
    exit;
  end;
  try
    Produto := Req.Params['produto'].ToInteger;
  except
    Res.Send('Extra Não Informado').Status(500);
    exit;
  end;
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('select * from pro_adi_personalizado as p');
  conexao.SQL.Add
    ('join pro_adi_personalizado_sabores as ps on ps.id_pro_adi_personalizado = p.id');
  conexao.SQL.Add('where p.id = :id');
  conexao.Parametros('id', Extra);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount = 0 then
  begin
    conexao.Free;
    Dados.Free;
    exit;
  end;

  conexao.SQL.Add
    ('select * from pro_adi_personalizado where id_produto = :id_produto and descricao = :descricao');
  conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
  conexao.Parametros('id_produto', Produto);
  try
    Codigo := conexao.FieldByName('id');
  except
    Codigo := 0;
  end;

  if Codigo = 0 then
  begin
    Codigo := conexao.GerarID('pro_adi_personalizado', 'id');
    conexao.SQL.Add
      ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,modificado_site) values (:id,:id_produto,:descricao,:ativo,:qtd_minima,:qtd_maxima,1)');
    conexao.Parametros('id', Codigo);
    conexao.Parametros('id_produto', Produto);
    conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
    conexao.Parametros('ativo', Dados.FieldByName('ativo').AsInteger);
    conexao.Parametros('qtd_minima', Dados.FieldByName('qtd_minima').AsInteger);
    conexao.Parametros('qtd_maxima', Dados.FieldByName('qtd_maxima').AsInteger);
    conexao.ExecuteSQL;
  end;

  while not Dados.Eof do
  begin
    CodigoExtra := conexao.GerarID('pro_adi_personalizado_sabores', 'id');
    conexao.SQL.Add
      ('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo,modificado_site) values (:id,:id_pro_adi_personalizado,:nome,:descricao,:valor,:ativo,1)');
    conexao.Parametros('id', CodigoExtra);
    conexao.Parametros('id_pro_adi_personalizado', Codigo);
    conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
    conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
    conexao.Parametros('valor', Dados.FieldByName('valor').AsFloat);
    conexao.Parametros('ativo', Dados.FieldByName('ativo').AsInteger);
    conexao.ExecuteSQL;
    Dados.Next;
  end;
  conexao.Free;
  Dados.Free;
  exit;
end;

procedure DoGetSaborCodigo(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
begin
  try
    ID := Req.Params['codigo'].ToInteger;
  except
    Res.Send('ID Não Informado').Status(500);
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('SELECT * FROM sabores_completo where id_produto = :id order by id');
  conexao.Parametros('id', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetTipoSabor(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Codigo: Integer;
  Tipos: Array of String;
  I: Integer;
begin
  SetLength(Tipos, 4);
  Tipos[0] := 'Promoção';
  Tipos[1] := 'Tradicional';
  Tipos[2] := 'Especial';
  Tipos[3] := 'Doce';
  conexao := Tconexao.Create('Util');

  for I := 0 to length(Tipos) - 1 do
  begin
    Dados := TFDMemTable.Create(nil);
    conexao.SQL.Add
      ('select * from tipo_sabor where nome = :nome and ativo = 1');
    conexao.Parametros('nome', Tipos[I]);
    Dados.LoadFromJSON(conexao.ConsultaSQL);

    if Dados.RecordCount = 0 then
    begin

      Codigo := conexao.GerarID('tipo_sabor', 'id');
      conexao.SQL.Add
        ('insert into tipo_sabor (id,nome,ativo) values (:id,:nome,1) ');
      conexao.Parametros('id', Codigo);
      conexao.Parametros('nome', Tipos[I]);
      conexao.ExecuteSQL;
    end;

    Dados.Free;
  end;

  conexao.SQL.Add('select * from tipo_sabor where nome in (' +
    QuotedStr('Promoção') + ',' + QuotedStr('Tradicional') + ',' +
    QuotedStr('Especial') + ',' + QuotedStr('Doce') + ') and ativo = 1');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

//
procedure DoPostSaborProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  Codigo: Integer;
  Min: Integer;
  Dados: TFDMemTable;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    if length(Req.Body) > 0 then
    begin
      Dados := TFDMemTable.Create(nil);
      Dados.LoadFromJSON(Req.Body);

      if Dados.RecordCount > 0 then
      begin
        conexao := Tconexao.Create('Util');
        conexao.SQL.Add
          ('update sabores_completo set ativo = :ativo, id_tipo_sabor = :sabor, nome = :nome, descricao = :descricao, vl_venda = :venda, modificado_site = 0 where id = :id');
        conexao.Parametros('sabor', Dados.FieldByName('tipo').AsInteger);
        conexao.Parametros('nome', Dados.FieldByName('sabor').AsString);
        conexao.Parametros('ativo', Dados.FieldByName('status').AsString);
        conexao.Parametros('descricao', Dados.FieldByName('descricao')
          .AsString);
        conexao.Parametros('venda', Dados.FieldByName('valor').AsFloat);
        conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
        conexao.ExecuteSQL;
        conexao.Free;
      end;

      Dados.Free;
    end;

    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('SELECT min(id) as id, 0 as zero FROM tipo_sabor where ativo = 1');
  Min := conexao.FieldByName('min');
  Codigo := conexao.GerarID('sabores_completo', 'id');
  conexao.SQL.Add
    ('insert into sabores_completo (id,id_produto,id_tipo_sabor,dt_cadastro,nome,descricao,vl_venda,ativo,modificado_site) values');
  conexao.SQL.Add
    ('(:id,:id_produto,:id_tipo_sabor,current_date,:nome,:descricao,:vl_venda,:ativo,:modificado_site)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('id_produto', ID);
  conexao.Parametros('id_tipo_sabor', Min);
  conexao.Parametros('nome', '');
  conexao.Parametros('descricao', '');
  conexao.Parametros('vl_venda', 0);
  conexao.Parametros('ativo', 0);
  conexao.Parametros('modificado_site', 0);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetBuscaBairro(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Busca: String;
begin
  try
    Busca := UpperCase(Req.Params['busca']);
  except
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select  * from taxa_entrega where upper(bairro) like "%' +
    Busca + '%" limit 3');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostRecebimentoCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Dados: TFDMemTable;
  conexao: Tconexao;
  Codigo: Integer;
  Caixa: Integer;
  OBS: String;
  Pedido: Integer;
begin
  try
    Codigo := Req.Params['id'].ToInteger;
  except
    exit;
  end;
  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    exit;
  end;
  try
    Pedido := Req.Params['pedido'].ToInteger;
  except
    exit;
  end;
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit
  end;
  OBS := 'RECEBIDO EM ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('update caixa_receber set status = 2, observacao =:obs where id = :id');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('obs', OBS);
  conexao.ExecuteSQL;

  while not Dados.Eof do
  begin
    OBS := 'RECEBIMENTO DE PAGAMENTO EM ABERTO PEDIDO #' + Pedido.ToString;
    MovimentoCaixa(Caixa, Pedido, Dados.FieldByName('ID_TIPO_PAGAMENTO')
      .AsInteger, 1, Dados.FieldByName('valor').AsFloat, OBS, 0);
    Dados.Next;
  end;

  Dados.Free;
  conexao.Free;
end;

procedure DoPostPedidoExtorno(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: Tconexao;
begin
  try
    Pedido := Req.Params['id'].ToInteger;
  except
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('delete from caixa_movimento where id_pedido = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.SQL.Add('delete from caixa_receber where id_pedido = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.SQL.Add('update pedido set id_caixa = null where codigo = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;

  conexao.SQL.Add('update pedido set status = 1 where codigo = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;

  conexao.Free;

end;

{ THorse.Post('/v1/util/grava/ingrediente/:id/:descricao/:unidade',
  ); }

procedure DoGetFichaProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Codigo: Integer;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  Res.Send<TJSONArray>(GetFichaProduto(Req.Params['codigo']));

end;

procedure DoGetDadosIngredientes(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select *, (select custo from ingredientes_estoque where ingredientes_estoque.id_ingredientes = ingredientes.id order by id desc limit 1) as custo,');
  conexao.SQL.Add
    (' (select sum(quantidade) from ingredientes_estoque where id_ingredientes = ingredientes.id) as estoque from ingredientes');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostEstoqueIngrediente(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ingrediente: Integer;
  Tipo: Integer;
  qtd: Real;
  Custo: Real;
  ID: Integer;
begin
  try
    ingrediente := Req.Params['ingrediente'].ToInteger;
  except
    exit;
  end;
  try
    Tipo := Req.Params['tipo'].ToInteger;
  except
    exit;
  end;
  try
    qtd := Req.Params['qtd'].ToDouble;
    if Tipo <> 1 then
      qtd := qtd * -1;
  except
    exit;
  end;
  try
    Custo := Req.Params['custo'].ToDouble;
  except
    exit;
  end;

  MovimentacaoInsulmo(ingrediente, Tipo, qtd, Custo, Custo / qtd, false);

end;

procedure DoPostFichaProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
Var
  Dados: TFDMemTable;
  conexao: Tconexao;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('delete from produto_ingredientes where id_produto = :produto');
  conexao.Parametros('produto', Dados.FieldByName('id_produto').AsInteger);
  conexao.ExecuteSQL;
  while not Dados.Eof do
  begin
    if Dados.FieldByName('id').AsInteger = 0 then
    begin
      Dados.Edit;
      Dados.FieldByName('id').AsInteger :=
        conexao.GerarID('produto_ingredientes', 'id');
      Dados.Post;
    end;
    conexao.SQL.Add
      ('insert into produto_ingredientes (id,id_produto,id_ingredientes,quantidade) values (:id,:id_produto,:id_ingredientes,:quantidade)');
    conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
    conexao.Parametros('id_produto', Dados.FieldByName('id_produto').AsInteger);
    conexao.Parametros('id_ingredientes', Dados.FieldByName('id_ingredientes')
      .AsInteger);
    conexao.Parametros('quantidade', Dados.FieldByName('quantidade').AsFloat);
    conexao.ExecuteSQL;
    Dados.Next;
  end;

  GetAllProduto(Dados.FieldByName('id_produto').AsInteger);
  conexao.Free;
  Dados.Free;
end;

procedure DoPostIngredientesFicha(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ID: Integer;
  Descricao: String;
  Unidade: String;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    exit;
  end;
  try
    Descricao := Req.Params['descricao'];
  except
    exit;
  end;
  try
    Unidade := Req.Params['unidade'];
  except
    exit;
  end;
  conexao := Tconexao.Create('Util');
  if ID > 0 then
  begin
    conexao.SQL.Add
      ('update ingredientes set descricao = :descricao, unidade = :unidade where id = :id');
  end
  else
  begin
    ID := conexao.GerarID('ingredientes', 'id');
    conexao.SQL.Add
      ('insert into ingredientes (id,descricao,unidade) values (:id,:descricao,:unidade)');
  end;
  conexao.Parametros('id', ID);
  conexao.Parametros('descricao', Descricao);
  conexao.Parametros('unidade', Unidade);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoPostGravaMesas(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Tipo: String;
  Min: Integer;
  Max: Integer;
  CodigoTipo: Integer;
  I: Integer;
  Codigo: Integer;
begin
  try
    Min := Req.Params['min'].ToInteger;
  except
    exit;
  end;
  try
    Max := Req.Params['max'].ToInteger;
  except
    exit;
  end;
  try
    Tipo := UpperCase(Req.Params['tipo']);
  except
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from mesa_tipo where upper(descricao) = :tipo');
  conexao.Parametros('tipo', Tipo);

  try
    CodigoTipo := conexao.FieldByName('id_mesa_tipo');
  except
    CodigoTipo := 0;
  end;

  if CodigoTipo = 0 then
  begin
    CodigoTipo := conexao.GerarID('mesa_tipo', 'id_mesa_tipo');
    conexao.SQL.Add
      ('insert into mesa_tipo (id_mesa_tipo,descricao,ativo) values (:id_mesa_tipo,:descricao,1)');
    conexao.Parametros('id_mesa_tipo', CodigoTipo);
    conexao.Parametros('descricao', Tipo);
    conexao.ExecuteSQL;
  end;

  for I := Min to Max do
  begin
    conexao.SQL.Add
      ('select count(*) as total, 0 as zero from mesa where fk_tipo_mesa = :fk_tipo_mesa and nr_mesa = :nr_mesa');
    conexao.Parametros('nr_mesa', I);
    conexao.Parametros('fk_tipo_mesa', CodigoTipo);

    if conexao.FieldByName('total') = 0 then
    begin
      Codigo := conexao.GerarID('mesa', 'id_mesa');
      conexao.SQL.Add
        ('insert into mesa (id_mesa,nr_mesa,sts_mesa,qtd_mesa,tot_mesa,fk_tipo_mesa,ativo,selecionada) values (:id_mesa,:nr_mesa,0,0,0,:fk_tipo_mesa,1,0)');
      conexao.Parametros('id_mesa', Codigo);
      conexao.Parametros('nr_mesa', I);
      conexao.Parametros('fk_tipo_mesa', CodigoTipo);
      conexao.ExecuteSQL;
    end;
    //
  end;

  conexao.Free;
end;

procedure DoPostLiberaImpressaoPedidoProduto(Req: THorseRequest;
Res: THorseResponse; Next: TProc);
var
  Codigo: Integer;
  conexao: Tconexao;
  CodigoAux: String;
  Dados: TFDMemTable;
  Imprimir: Integer;
  CodigoMesa: Integer;
  NumeroMesa: Integer;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from dados_whatsapp');
  Imprimir := conexao.FieldByName('impressaotipopro');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('select * from mesa where mesa.selecionada = :codigo');
  conexao.Parametros('codigo', Codigo);
  try
    CodigoMesa := conexao.FieldByName('id_mesa');
    conexao.SQL.Add('select * from mesa where mesa.id_mesa = :codigo');
    conexao.Parametros('codigo', CodigoMesa);
    NumeroMesa := conexao.FieldByName('id_mesa');;
    conexao.SQL.Add('update pedido set id_ficha = :ficha, desc_ficha = ' +
      QuotedStr('MESA ' + NumeroMesa.ToString) + ' where codigo = :codigo');
    conexao.Parametros('ficha', CodigoMesa);
    conexao.Parametros('codigo', Codigo);
    conexao.ExecuteSQL;

  except
    CodigoMesa := 0;
  end;
  if Imprimir = 1 then
  begin
    if CodigoMesa = 0 then
    begin
      conexao.SQL.Add
        ('select * from pedido_produtos where codigo_pedido = :codigo');
      conexao.Parametros('codigo', Codigo);
      Dados.LoadFromJSON(conexao.ConsultaSQL);
    end
    else
    begin
      conexao.SQL.Add('SELECT pp.*');
      conexao.SQL.Add('FROM pedido_produtos pp');
      conexao.SQL.Add
        ('LEFT JOIN impressao_pedido_produto ipp ON pp.codigo = ipp.id_pedido');
      conexao.SQL.Add('WHERE pp.codigo_pedido = :codigo');
      conexao.SQL.Add('AND ipp.status = 2');
      conexao.Parametros('codigo', Codigo);
      Dados.LoadFromJSON(conexao.ConsultaSQL);
    end;

    if Dados.RecordCount > 0 then
    begin
      Dados.First;
      while not Dados.Eof do
      begin
        if length(CodigoAux) = 0 then
        begin
          CodigoAux := Dados.FieldByName('codigo').AsString;
        end
        else
          CodigoAux := CodigoAux + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;

    conexao.SQL.Add
      ('update impressao_pedido_produto set status = 0 where id_pedido in (' +
      CodigoAux + ')');
    conexao.ExecuteSQL;

    // CodigoAux := conexao.GerarID('impressao_pedido_produto','id');
    // conexao.SQL.Add
    // ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:pedido,:status,0,:usuario)');
    // conexao.Parametros('pedido', Codigo);
    // conexao.Parametros('id', CodigoAux);
    // conexao.Parametros('status', 1);
    // conexao.Parametros('usuario', 0);
    // conexao.ExecuteSQL;
  end;
  Dados.Free;
  conexao.Free;

end;

procedure DoPostAguardaImpressaoPedidoProduto(Req: THorseRequest;
Res: THorseResponse; Next: TProc);
var
  Codigo: Integer;
  conexao: Tconexao;
  CodigoAux: Integer;
  Usuario: Integer;
  mesa: Integer;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  try
    mesa := Req.Params['mesa'].ToInteger;
  except
    mesa := 1;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select * from usuario');
  Usuario := conexao.FieldByName('codigo');
  CodigoAux := conexao.GerarID('impressao_pedido_produto', 'id');
  conexao.SQL.Add
    ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:pedido,:status,0,:usuario)');
  conexao.Parametros('pedido', Codigo);
  conexao.Parametros('id', CodigoAux);
  conexao.Parametros('status', mesa);
  conexao.Parametros('usuario', Usuario);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetDadosPedidoProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: Tconexao;
begin
  try
    Pedido := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select * from pedido_produto_sap as pps join pedido_produtos as pp on pp.codigo = pps.codigo_pedido_produto where codigo_pedido_produto = :id');
  conexao.Parametros('id', Pedido);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostWhatsappStatus(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: Tconexao;
begin
  try
    Pedido := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('update pedido set wpp_status = status where codigo = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoPostWhatsappPix(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: Tconexao;
begin
  try
    Pedido := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('update pedido set wpp_pix = 1 where codigo = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetWhatsappStatusAlterado(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select p.codigo, p.codigo_pedido_dia, c.nome, c.celular, c.celular_wpp, tp.tipo_chave_pix, tp.chave_pix, tp.chave_recebedor, p.valor_total_pedido, p.wpp_status, p.status,');
  conexao.SQL.Add
    ('(select descricao from status_pedido where id = p.status) as status_atual,(select descricao from status_pedido where id = p.wpp_status) as status_anterior from pedido as p');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add('join cliente as c on c.codigo = p.codigo_cliente ');
  conexao.SQL.Add
    ('where p.data_pedido >= current_date - 1 and (p.status <> p.wpp_status or p.wpp_status is null)');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetWhatsappstatus(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select p.codigo, p.codigo_pedido_dia, c.nome, c.celular, c.celular_wpp, tp.tipo_chave_pix, tp.chave_pix, tp.chave_recebedor, p.valor_total_pedido, p.wpp_status, p.status from pedido as p');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add('join cliente as c on c.codigo = p.codigo_cliente');
  conexao.SQL.Add
    ('where p.data_pedido >= current_date - 1 and p.origem = 2 and p.status = 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetWhatsappPix(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select p.codigo, p.codigo_pedido_dia, c.nome, c.celular, c.celular_wpp, tp.tipo_chave_pix, tp.chave_pix, tp.chave_recebedor, p.valor_total_pedido from pedido as p');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add('join cliente as c on c.codigo = p.codigo_cliente');
  conexao.SQL.Add
    ('where tp.tipo_chave_pix > 0 and p.wpp_pix is null and p.status > 0 and data_pedido >= current_date-1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetEstoqueGeral(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Sequencial: Integer;
begin
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  frmServidor.memEstoque.Close;
  frmServidor.memEstoque.Open;
  Sequencial := 0;
  conexao.SQL.Add
    ('select *, saldo_atual as estoque from produto where controle_estoque = 1');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  while not Dados.Eof do
  begin
    inc(Sequencial);
    frmServidor.memEstoque.Insert;
    frmServidor.memEstoque.FieldByName('SEQUENCIAL').AsInteger := Sequencial;
    frmServidor.memEstoque.FieldByName('ID').AsInteger :=
      Dados.FieldByName('codigo').AsInteger;
    frmServidor.memEstoque.FieldByName('TIPO').AsInteger := 1;
    frmServidor.memEstoque.FieldByName('NOME').AsString :=
      UpperCase(RemoveAcento(Dados.FieldByName('nome_produto').AsString));
    frmServidor.memEstoque.FieldByName('UN').AsString := 'UN';
    if not Dados.FieldByName('estoque').IsNull then
      frmServidor.memEstoque.FieldByName('QTD').AsString :=
        StringReplace(Dados.FieldByName('estoque').AsString, '.', ',', []);
    if not Dados.FieldByName('estoque_min').IsNull then
      frmServidor.memEstoque.FieldByName('MIN').AsString :=
        StringReplace(Dados.FieldByName('estoque_min').AsString, '.', ',', []);
    frmServidor.memEstoque.Post;

    Dados.Next;
  end;

  Dados.Free;
  if frmServidor.Configuracoes.FieldByName('ficha_tecnica').AsInteger = 1 then
  begin

    Dados := TFDMemTable.Create(nil);
    conexao.SQL.Add('SELECT *, saldo as estoque FROM ingredientes');
    Dados.LoadFromJSON(conexao.ConsultaSQL);

    while not Dados.Eof do
    begin
      frmServidor.memEstoque.Insert;
      inc(Sequencial);
      frmServidor.memEstoque.FieldByName('SEQUENCIAL').AsInteger := Sequencial;
      frmServidor.memEstoque.FieldByName('ID').AsInteger :=
        Dados.FieldByName('id').AsInteger;
      frmServidor.memEstoque.FieldByName('TIPO').AsInteger := 2;
      frmServidor.memEstoque.FieldByName('NOME').AsString :=
        UpperCase(RemoveAcento(Dados.FieldByName('descricao').AsString));
      frmServidor.memEstoque.FieldByName('UN').AsString :=
        Dados.FieldByName('unidade').AsString;
      if not Dados.FieldByName('estoque').IsNull then
        frmServidor.memEstoque.FieldByName('QTD').AsString :=
          StringReplace(Dados.FieldByName('estoque').AsString, '.', ',', []);
      frmServidor.memEstoque.Post;

      Dados.Next;
    end;
    Dados.Free;
  end;
  Res.Send<TJSONArray>(frmServidor.memEstoque.ToJSONArray);
  conexao.Free;
end;

procedure DoPostEstoqueProdutoInsulmos(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Dados: TFDMemTable;
  conexao: Tconexao;
  ID: Integer;
  Fator: Real;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := Tconexao.Create('Util');

  while not Dados.Eof do
  begin
    case Dados.FieldByName('TIPO').AsInteger of
      1:
        begin
          // Produto
          MovimentacaoProduto(Dados.FieldByName('ID').AsInteger, 1,
            Dados.FieldByName('QTD').AsFloat);
          // Atualizar custo do produto
          Res.Send('[]');
        end
    else
      begin
        conexao.SQL.Add('select * from conversao where un_de = ' +
          QuotedStr(Dados.FieldByName('UN').AsString) +
          ' and un_para = (SELECT unidade FROM ingredientes where id = ' +
          Dados.FieldByName('ID').AsString + ')');
        try
          Fator := conexao.FieldByName('valor');
        except
          Fator := 1;
        end;
        if Fator = 0 then
          Fator := 1;

        // Consultar Fator de Conversão antes de fazer a entrada

        MovimentacaoInsulmo(Dados.FieldByName('ID').AsInteger, 1,
          Dados.FieldByName('QTD').AsFloat * Fator,
          Dados.FieldByName('CUSTOTOTAL').AsFloat, Dados.FieldByName('CUSTOUN')
          .AsFloat, true);
        // Fazer Atualização do custo dos ingredientes cujo são sub-produtos;
        Res.Send<TJSONArray>(AtualizacaoCustoIngrediente(Dados.FieldByName('ID')
          .AsInteger));

      end;
    end;

    Dados.Next;
  end;

  Dados.Free;
  conexao.Free;
end;

procedure DoPostBaixaEstoqueProdutoAdicional(Req: THorseRequest;
Res: THorseResponse; Next: TProc);
begin
  MovimentacaoProdutoAdicional(Req.Params['produto'].ToInteger,
    Req.Params['adicional'], Req.Params['valor'].ToDouble,
    Req.Params['quantidade'].ToDouble);
end;

procedure DoPostBaixaEstoqueInsulmo(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Dados: TFDMemTable;
  conexao: Tconexao;
  Codigo: Integer;
begin
  Codigo := Req.Params['codigo'].ToInteger;
  conexao := Tconexao.Create('DoPostBaixaEstoqueProduto');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add
    ('select produto_ingredientes.id_ingredientes, (produto_ingredientes.quantidade * pedido_produtos.quantidade) as quantidade, produto_ingredientes.id_produto as produto  from pedido');
  conexao.SQL.Add
    ('join pedido_produtos on pedido_produtos.codigo_pedido = pedido.codigo and pedido_produtos.codigo = :codigo');
  conexao.SQL.Add
    ('join produto_ingredientes on produto_ingredientes.id_produto = pedido_produtos.codigo_produto');
  conexao.Parametros('codigo', Codigo);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin

      MovimentacaoInsulmo(Dados.FieldByName('id_ingredientes').AsInteger, 2,
        Dados.FieldByName('quantidade').AsFloat, 0, 0, false);

      Dados.Next;
    end;
  end;
  Dados.Free;
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add
    ('select pro_adi_personalizado_sabores.id_ingredientes as ingredientes, pro_adi_personalizado_sabores.quantidade_ingredientes as quantidade from pedido');
  conexao.SQL.Add
    ('join pedido_produtos on pedido_produtos.codigo_pedido = pedido.codigo and pedido_produtos.codigo = :codigo');
  conexao.SQL.Add
    ('join pedido_produto_sap on pedido_produto_sap.codigo_pedido_produto = pedido_produtos.codigo');
  conexao.SQL.Add
    ('join pro_adi_personalizado on pro_adi_personalizado.id_produto = pedido_produtos.codigo_produto and upper(pro_adi_personalizado.descricao) = upper(pedido_produto_sap.nomeclatura)');
  conexao.SQL.Add
    ('join pro_adi_personalizado_sabores on pro_adi_personalizado_sabores.id_pro_adi_personalizado = pro_adi_personalizado.id and');
  conexao.SQL.Add
    ('upper(pro_adi_personalizado_sabores.nome) = upper(pedido_produto_sap.descricao) and pro_adi_personalizado_sabores.id_ingredientes <> 0');
  conexao.SQL.Add
    ('and pro_adi_personalizado_sabores.quantidade_ingredientes <> 0');
  conexao.Parametros('codigo', Codigo);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin

      MovimentacaoInsulmo(Dados.FieldByName('ingredientes').AsInteger, 2,
        Dados.FieldByName('quantidade').AsFloat, 0, 0, false);

      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;
  MovimentoProduto(Codigo, 1);

end;

procedure DoPostBaixaEstoqueProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Codigo: Integer;
begin
  Codigo := Req.Params['codigo'].ToInteger;
  MovimentacaoProduto(Codigo, 2, Req.Params['qtd'].ToInteger);

end;

// -
procedure DoTesteImpressao(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin
  if not frmServidor.memTesteImpressao.Active then
    frmServidor.memTesteImpressao.Open;
  try
    Req.Params['id'].ToInteger;
    frmServidor.memTesteImpressao.Insert;
    frmServidor.memTesteImpressao.FieldByName('IMPRESSORA').AsInteger :=
      Req.Params['id'].ToInteger;
    frmServidor.memTesteImpressao.FieldByName('ID').AsInteger :=
      Req.Params['id'].ToInteger;
    frmServidor.memTesteImpressao.Post;
    exit;
  except
    on E: Exception do
    begin
      Res.Send<TJSONArray>(frmServidor.memTesteImpressao.ToJSONArray);
      frmServidor.memTesteImpressao.Close;

    end;
  end;

end;

procedure DoPostTaxaEntrega(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;
  conexao := Tconexao.Create('Util');
  if Dados.FieldByName('codigo').AsInteger = 0 then
  begin
    Dados.Edit;
    // codigo,cidade,bairro,valor_taxa,ativo,estado
    Dados.FieldByName('codigo').AsInteger := conexao.GerarID('taxa_entrega',
      'codigo');
    conexao.SQL.Add
      ('insert into taxa_entrega (codigo,cidade,bairro,valor_taxa,ativo,estado) values (:codigo,:cidade,:bairro,:valor_taxa,:ativo,:estado)');

  end
  else
  begin
    conexao.SQL.Add
      ('update taxa_entrega set cidade = :cidade, bairro = :bairro, valor_taxa = :valor_taxa, ativo = :ativo, estado = :estado where codigo = :codigo');
  end;
  conexao.Parametros('codigo', Dados.FieldByName('codigo').AsString);
  conexao.Parametros('cidade', UpperCase(Dados.FieldByName('cidade').AsString));
  conexao.Parametros('bairro', UpperCase(Dados.FieldByName('bairro').AsString));
  conexao.Parametros('valor_taxa', Dados.FieldByName('valor_taxa').AsString);
  conexao.Parametros('ativo', Dados.FieldByName('ativo').AsString);
  conexao.Parametros('estado', UpperCase(Dados.FieldByName('estado').AsString));
  conexao.ExecuteSQL;
  conexao.Free;
  Dados.Free;
end;

procedure DoGetStatusPedido(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Codigo: String;
begin
  conexao := Tconexao.Create('Util');

  try
    conexao.SQL.Add
      ('update pedido set wpp_status = status where codigo = :codigo');
    conexao.Parametros('codigo', Req.Params['codigo'].ToInteger);
    conexao.ExecuteSQL;
  except
    conexao.SQL.Clear;
    conexao.SQL.Add('SELECT ');
    conexao.SQL.Add('    p.*,');
    conexao.SQL.Add('    c.celular,');
    conexao.SQL.Add('    c.celular_wpp,');
    conexao.SQL.Add
      ('    (select descricao from tipo_pagamento where codigo = p.tipo_pagamento) as pagamento');
    conexao.SQL.Add('FROM ');
    conexao.SQL.Add('    pedido p');
    conexao.SQL.Add('LEFT JOIN ');
    conexao.SQL.Add('    cliente c ON p.codigo_cliente = c.codigo');
    conexao.SQL.Add('WHERE ');
    conexao.SQL.Add('    p.data_pedido = CURRENT_DATE() ');
    conexao.SQL.Add('    AND p.status > 0 ');
    conexao.SQL.Add
      ('    AND (p.status <> p.wpp_status OR p.wpp_status IS NULL) ');
    conexao.SQL.Add
      ('    AND p.codigo_pedido_dia > 0 AND (id_ficha = 0 or id_ficha is null) and id_ifood is null limit 10');

    Res.Send<TJSONArray>(conexao.ConsultaSQL);

  end;
  //

  conexao.Free;
end;

procedure DoFinalizarServico(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin
  case Req.Params['tipo'].ToInteger of
    1:
      begin
        // Whatsapp
        if not frmServidor.FechouWhatsapp then
        begin
          frmServidor.FecharExe(frmServidor.WHATSAPP);
          frmServidor.FechouWhatsapp := true
        end
        else
        begin
          frmServidor.FechouWhatsapp := false;
          frmServidor.AbrirExe(frmServidor.WHATSAPP);
        end;
      end;
    2:
      begin
        // Site
        if not frmServidor.FechouSite then
        begin
          frmServidor.FecharExe(frmServidor.SITE(frmServidor.NomeExeSite));
          frmServidor.FechouSite := true
        end
        else
        begin
          frmServidor.FechouSite := false;
          frmServidor.AbrirExe(frmServidor.SITE(frmServidor.NomeExeSite));
        end;
      end;
  end;
end;

// THorse.Post('v1/util/fator/conversao/:unde/:unpara/:valor/:tipo/:codigo', DoPostFatorConversao);
procedure DoPostFatorConversao(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  UnidadeDe: String;
  UnidadePara: String;
  Valor: Real;
  Tipo: Integer;
  Codigo: Integer;
  CodigoAux: Integer;
  conexao: Tconexao;
begin
  try
    UnidadeDe := Req.Params['unde'];
  except
    exit;
  end;
  try
    UnidadePara := Req.Params['unpara'];
  except
    exit;
  end;
  try
    Valor := Req.Params['valor'].ToDouble;
  except
    exit;
  end;
  try

    Tipo := Req.Params['tipo'].ToInteger;
  except
    exit;
  end;
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('delete from conversao where un_de = :un and tipo = :tipo and codigo_tipo = :codigo');
  conexao.Parametros('un', UnidadeDe);
  conexao.Parametros('tipo', Tipo);
  conexao.Parametros('codigo', Codigo);
  conexao.ExecuteSQL;

  CodigoAux := conexao.GerarID('conversao', 'id');

  conexao.SQL.Add
    ('insert into conversao (id,tipo,codigo_tipo,un_de,un_para,valor) values (:id,:tipo,:codigo_tipo,:un_de,:un_para,:valor)');
  conexao.Parametros('id', CodigoAux);
  conexao.Parametros('tipo', Tipo);
  conexao.Parametros('codigo_tipo', Codigo);
  conexao.Parametros('un_de', UnidadeDe);
  conexao.Parametros('un_para', UnidadePara);
  conexao.Parametros('valor', Valor);
  conexao.ExecuteSQL;

  conexao.Free;
end;

procedure DoGetFatorConversao(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Unidade: String;
  Tipo: Integer;
  Codigo: Integer;
  conexao: Tconexao;
begin
  try
    Unidade := Req.Params['un'];
  except
    exit;
  end;
  try
    Tipo := Req.Params['tipo'].ToInteger;
  except
    exit;
  end;
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select * from conversao where un_de = :un and tipo = :tipo and codigo_tipo = :codigo');
  conexao.Parametros('un', Unidade);
  conexao.Parametros('tipo', Tipo);
  conexao.Parametros('codigo', Codigo);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetGerador(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Tabela: String;
  Campo: String;
  Dados: TFDMemTable;
  Valor: Integer;
begin
  try
    Tabela := Req.Params['tabela'];
  except
    exit;
  end;
  try
    Campo := Req.Params['campo'];
  except
    exit;
  end;
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add
    ('update geradores set sequencial = sequencial + 1 where tabela = :tabela');
  conexao.Parametros('tabela', Tabela);
  conexao.ExecuteSQL;

  conexao.SQL.Add('select * from geradores where tabela = :tabela');
  conexao.Parametros('tabela', Tabela);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount = 1 then
  begin
    Valor := Dados.FieldByName('sequencial').AsInteger;
  end
  else
  begin
    // conexao.SQL.Add('select max(' + Campo + ') as codigo, 0 as zero from '+ tabela);

    try
      Valor := conexao.GerarID(Tabela, Campo);
    except
      Valor := 99;
    end;

    conexao.SQL.Add
      ('insert into geradores (tabela,sequencial) values (:tabela,:sequencial)');
    conexao.Parametros('tabela', Tabela);
    conexao.Parametros('sequencial', Valor);
    conexao.ExecuteSQL;
  end;

  Res.Send(Valor.ToString);
  Dados.Free;
  conexao.Free;
end;

procedure DoPostEstoqueProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var

  Produto: Integer;
  Tipo: Integer;
  Quantidade: Integer;
begin

  try
    Produto := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;
  try
    Tipo := Req.Params['tipo'].ToInteger;
  except
    exit;
  end;
  try
    Quantidade := Req.Params['quantidade'].ToInteger;
  except
    exit;
  end;

  if Tipo <> 1 then
  begin
    Tipo := 1;
    Quantidade := Quantidade * -1;
  end;
  MovimentacaoProduto(Produto, Tipo, Quantidade);

end;

//

procedure DoPostGeraPix(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  token: String;
  Valor: String;
  Pedido: String;
  ID: Integer;
  MP: String;
  RequisicaoPIX: iRequisicao;
  JSonValue: TJSONValue;
  Dados: TFDMemTable;
  JsonObj: TJSONObject;
  Status: Integer;
begin
  try
    token := Req.Params['token'];
  except
    exit;
  end;

  try
    Valor := Req.Params['valor'];
  except
    exit;
  end;

  try
    Pedido := Req.Params['pedido'];
  except
    exit;
  end;
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select * from pix where id_pedido = :id_pedido and valor = :valor and expdatahora >= Now()');
  conexao.Parametros('id_pedido', Pedido);
  conexao.Parametros('valor', Valor);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  RequisicaoPIX := iRequisicao.Create(nil);

  if Dados.RecordCount = 0 then
  begin
    RequisicaoPIX.BaseURL := 'https://goopedir.com/produto/pix.php?token=' +
      token + '&pedido=' + Pedido + '&valor=' + Valor;
    RequisicaoPIX.Metodo := mPost;
    RequisicaoPIX.Execute;

    if RequisicaoPIX.Status = 200 then
    begin
      JSonValue := TJSONObject.ParseJSONValue(RequisicaoPIX.retorno);

      ID := conexao.GerarID('pix', 'id');
      conexao.SQL.Add
        ('insert into pix (id,id_pedido,valor,creatdatahora,expdatahora,transacao_mp) values (:id,:pedido,:valor,now(),date_add(now(), interval 1 day),:transacao_mp)');
      conexao.Parametros('id', ID);
      conexao.Parametros('pedido', Pedido);
      conexao.Parametros('valor', Valor);
      try
        MP := ExtractNumberFromURL(JSonValue.GetValue<string>('ticket_url'));
        conexao.Parametros('transacao_mp', MP);
        conexao.ExecuteSQL;
      except

      end;
    end;
  end
  else
  begin
    MP := Dados.FieldByName('transacao_mp').AsString;
  end;

  RequisicaoPIX.BaseURL := 'https://goopedir.com/produto/pixstatus.php?token=' +
    token + '&id=' + MP;
  RequisicaoPIX.Metodo := mPost;
  RequisicaoPIX.Execute;

  JSonValue := TJSONObject.ParseJSONValue(RequisicaoPIX.retorno) as TJSONObject;
  try
    conexao.SQL.Add('select * from qrcod_pix where base64 = :base64');
    conexao.Parametros('base64', JSonValue.GetValue<string>('qrcod'));
    Status := conexao.FieldByName('status');
  except
    Status := 0;
  end;

  if Status = 0 then
  begin
    conexao.SQL.Add
      ('insert into qrcod_pix (base64,status,valor) values (:base64,1,:valor)');
    conexao.Parametros('base64', JSonValue.GetValue<string>('qrcod'));
    conexao.Parametros('valor', Valor);
    conexao.ExecuteSQL;
  end;

  JSonValue.Free;

  Res.Status(RequisicaoPIX.Status);
  Res.Send(RequisicaoPIX.retorno);
  RequisicaoPIX.Free;
  conexao.Free;
  Dados.Free;
end;

procedure DoPostClonaSabor(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  De: String;
  Para: String;
  conexao: Tconexao;
  Dados: TFDMemTable;
begin
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from sabores_completo where id_produto = :de');
  conexao.Parametros('de', Req.Params['de']);

  try
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    while not Dados.Eof do
    begin
      Dados.Edit;
      Dados.FieldByName('id').AsInteger :=
        conexao.GerarID('sabores_completo', 'id');
      conexao.SQL.Add
        ('insert into sabores_completo (id,id_produto,id_tipo_sabor,dt_cadastro,nome,descricao,vl_venda,ativo,modificado_site) values (:id,:id_produto,:id_tipo_sabor,curdate(),:nome,:descricao,:vl_venda,:ativo,0)');
      conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
      conexao.Parametros('id_produto', Req.Params['para']);
      conexao.Parametros('id_tipo_sabor', Dados.FieldByName('id_tipo_sabor')
        .AsInteger);
      conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
      conexao.Parametros('descricao', Dados.FieldByName('descricao').AsString);
      conexao.Parametros('vl_venda', Dados.FieldByName('vl_venda').AsFloat);
      conexao.Parametros('ativo', Dados.FieldByName('ativo').AsInteger);
      conexao.ExecuteSQL;
      Dados.Next;
    end;
  except

  end;
  conexao.Free;
  Dados.Free;
end;

procedure DoPostCadastroCliente(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Codigo: Integer;
  Celular: string;
  nome: string;
  rua: string;
  Numero: string;
  complemento: string;
  bairro: string;
  cidade: string;
  estado: string;
  cpf: string;
  conexao: Tconexao;
  CodigoEndereco: Integer;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    Codigo := 0;
  end;
  conexao := Tconexao.Create('Util');
  Celular := Req.Params['celular'];
  nome := Req.Params['nome'];
  rua := Req.Params['rua'];
  Numero := Req.Params['numero'];
  complemento := Req.Params['complemento'];
  bairro := Req.Params['bairro'];
  cidade := Req.Params['cidade'];
  estado := Req.Params['estado'];
  cpf := Req.Params['cpf'];

  if Codigo = 0 then
  begin
    Codigo := conexao.GerarID('cliente', 'codigo');
    conexao.SQL.Add
      ('insert into cliente (codigo,nome,celular,celular_wpp,ativo) values  (:codigo,:nome,:celular,:celular_wpp,1)');
    conexao.Parametros('codigo', Codigo);
    conexao.Parametros('nome', UpperCase(RemoveAcento(nome)));
    conexao.Parametros('celular', Celular);
    conexao.Parametros('celular_wpp', NonoDigito(Celular));
    conexao.ExecuteSQL;

  end;
  conexao.SQL.Add
    ('update cliente set nome = :nome, cpf = :cpf, celular = :celular, celular_wpp = :celular_wpp where codigo = :codigo');
  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('cpf', cpf);
  conexao.Parametros('nome', UpperCase(RemoveAcento(nome)));
  conexao.Parametros('celular', Celular);
  conexao.Parametros('celular_wpp', NonoDigito(Celular));
  conexao.ExecuteSQL;
  if length(rua) > 0 then
  begin
    // Cadastra Endereço
    conexao.SQL.Add
      ('select max(codigo) as codigo, 0 as zero from cliente_endereco where  cliente_endereco.codigo_cliente = :cliente');
    conexao.Parametros('cliente', Codigo);
    try
      CodigoEndereco := conexao.FieldByName('codigo');
    finally
      CodigoEndereco := conexao.GerarID('cliente_endereco', 'codigo');
      conexao.SQL.Add
        ('insert into cliente_endereco (codigo,codigo_cliente,descricao,tipo,numero,rua,bairro,cidade,estado,complemento,ativo,km) values');
      conexao.SQL.Add
        ('(:codigo,:codigo_cliente,:descricao,:tipo,:numero,:rua,:bairro,:cidade,:estado,:complemento,1,0)');
      conexao.Parametros('codigo', CodigoEndereco);
      conexao.Parametros('codigo_cliente', Codigo);
      conexao.Parametros('descricao', 'Principal');
      conexao.Parametros('tipo', 1);
      conexao.Parametros('rua', UpperCase(RemoveAcento(rua)));
      conexao.Parametros('bairro', UpperCase(RemoveAcento(bairro)));
      conexao.Parametros('cidade', UpperCase(RemoveAcento(cidade)));
      conexao.Parametros('estado', UpperCase(RemoveAcento(estado)));
      conexao.Parametros('complemento', UpperCase(RemoveAcento(complemento)));
      conexao.Parametros('numero', Numero);
      conexao.ExecuteSQL;

    end;
    conexao.SQL.Add
      ('update cliente_endereco set numero = :numero, rua = :rua, bairro = :bairro, cidade = :cidade, estado = :estado, complemento = :complemento where codigo = :codigo');
    conexao.Parametros('codigo', CodigoEndereco);
    conexao.Parametros('rua', UpperCase(RemoveAcento(rua)));
    conexao.Parametros('bairro', UpperCase(RemoveAcento(bairro)));
    conexao.Parametros('cidade', UpperCase(RemoveAcento(cidade)));
    conexao.Parametros('estado', UpperCase(RemoveAcento(estado)));
    conexao.Parametros('complemento', UpperCase(RemoveAcento(complemento)));
    conexao.Parametros('numero', Numero);

  end;

  conexao.Free;
end;

procedure DoPostUrlAutenticacao(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  autenticador: String;
  conexao: Tconexao;
begin

  try
    autenticador := Req.Params['autenticador'];
    conexao := Tconexao.Create('DoPostUrlAutenticacao');
    conexao.SQL.Add
      ('update ifood_connect set autenticacao = :autenticacao where id = :id');
    conexao.Parametros('autenticacao', autenticador);
    conexao.Parametros('id', Req.Params['id']);
    conexao.ExecuteSQL;
    conexao.Free;
    frmServidor.GetADRIFoodByTag(Req.Params['id'].ToInteger())
      .AuthorizationCode(autenticador);
  except
    on E: Exception do
    begin
      // frmServidor.ifood.AuthorizationCode(Req.Params['id']);
      Res.Send(E.Message);
    end;
  end;

end;

procedure DoGetAutenticacaoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  URL: String;
  conexao: Tconexao;
  MerchantID: String;
  JsonObj: TJSONObject;
begin
  JsonObj := TJSONObject.Create;
  conexao := Tconexao.Create('DoGetAutenticacaoiFood');

  if not Assigned(frmServidor.GetADRIFoodByTag(Req.Params['id'].ToInteger()))
  then
  begin
    conexao.SQL.Add('select * from ifood_connect where id = :id');
    conexao.Parametros('id', Req.Params['id']);
    try
      MerchantID := conexao.FieldByName('merchantid');
    except
      MerchantID := '';
    end;

    if MerchantID = '' then
    begin
      JsonObj.AddPair('status', 'error');
      JsonObj.AddPair('msg', 'MerchantID não configurado!');
      Res.Status(200).Send(JsonObj);

    end
    else
    begin

    end;

  end
  else
  begin
    conexao.SQL.Add('select * from ifood_connect where id = :id');
    conexao.Parametros('id', Req.Params['id']);
    try
      MerchantID := conexao.FieldByName('merchantid');
    except
      MerchantID := '';
    end;
  end;
  try
    if MerchantID <> '' then
    begin
      URL := frmServidor.GetADRIFoodByTag(Req.Params['id'].ToInteger())
        .GetURLVerification(false);

      conexao.SQL.Add('update ifood_connect set link = :link where id = :id');
      conexao.Parametros('link', URL);
      conexao.Parametros('id', Req.Params['id']);
      conexao.ExecuteSQL;

      // URL := frmServidor.ifood.GetURLVerification(True);
      JsonObj.AddPair('status', 'sucesso');
      JsonObj.AddPair('msg', URL);
      Res.Status(200).Send(JsonObj);
    end;
  except
    JsonObj.AddPair('status', 'error');
    JsonObj.AddPair('msg',
      'Não foi possivel localizar a integração com o iFood, verificar com o suporte técnico!');
    Res.Status(200).Send(JsonObj);
  end;
  conexao.Free;
end;

procedure DoGetStatusiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin
  try
    Req.Params['id'].ToInteger();
    frmServidor.GetADRIFoodByTag(Req.Params['id'].ToInteger())
      .Merchant.List(frmServidor.dataSetMerchants1);
    Res.Send<TJSONArray>(frmServidor.GetADRIFoodByTag(Req.Params['id']
      .ToInteger()).MerchantStatus.DataSource.Dataset.ToJSONArray());
  except
    Res.Send<TJSONArray>(frmServidor.dataSetMerchantStatus.ToJSONArray());
  end;

end;

procedure DoPostConfirmarPedidoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  Codigo: Integer;
  Pedido: Integer;
  ifood: TADRIFood;
begin

  ifood := frmServidor.GetADRIFoodByTag
    (frmServidor.GetInstancia(Req.Params['id']));
  ifood.Order.Confirmation(Req.Params['id']);

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('update pedido set status_ifood = "CFM" where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', Req.Params['id']);
  conexao.ExecuteSQL;

  conexao.SQL.Add('select * from pedido where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', Req.Params['id']);

  Pedido := conexao.FieldByName('codigo');

  Codigo := conexao.GerarID('impressao_pedido', 'id');
  conexao.SQL.Add
    ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('pedido', Pedido);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoPostPrepararPedidoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ifood: TADRIFood;
begin

  ifood := frmServidor.GetADRIFoodByTag
    (frmServidor.GetInstancia(Req.Params['id']));
  ifood.Order.StartPreparation(Req.Params['id']);
  conexao := Tconexao.Create('Util');

  conexao.SQL.Add
    ('update pedido set status_ifood = "PRS" where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', Req.Params['id']);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoPostDespacharPedidoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ifood: TADRIFood;
begin

  ifood := frmServidor.GetADRIFoodByTag
    (frmServidor.GetInstancia(Req.Params['id']));
  ifood.Order.DispatchOrder(Req.Params['id']);

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('update pedido set status_ifood = "DSP" where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', Req.Params['id']);
  conexao.ExecuteSQL;

  try
    // if frmServidor.Configuracoes.FieldByName('nfce_ifood').AsInteger > 0 then
    // begin
    // conexao.SQL.Add
    // ('update pedido set nfce_emite = 1 where id_ifood = :id_ifood');
    // conexao.Parametros('id_ifood', Req.Params['id']);
    // conexao.ExecuteSQL;
    //
    // end;

  except

  end;

  conexao.Free;
  //
end;

procedure DoPostRetirarPedidoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  ifood: TADRIFood;
begin
  ifood := frmServidor.GetADRIFoodByTag
    (frmServidor.GetInstancia(Req.Params['id']));
  ifood.Order.ReadyToPickup(Req.Params['id']);

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('update pedido set status_ifood = "CON" where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', Req.Params['id']);
  conexao.ExecuteSQL;

  try
    // if frmServidor.Configuracoes.FieldByName('nfce_ifood').AsInteger > 0 then
    // begin
    // conexao.SQL.Add
    // ('update pedido set nfce_emite = 1 where id_ifood = :id_ifood');
    // conexao.Parametros('id_ifood', Req.Params['id']);
    // conexao.ExecuteSQL;
    //
    // end;

  except

  end;

  conexao.Free;
  // nfce_ifood
end;

procedure DoGetProdutoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin

  if frmServidor.IntegracaoiFood then
  begin
    frmServidor.BuscaDadosiFood;
  end;

end;

procedure DoPostCancelarPedidoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Text: String;
  conexao: Tconexao;
  ifood: TADRIFood;
begin
  ifood := frmServidor.GetADRIFoodByTag
    (frmServidor.GetInstancia(Req.Params['id']));

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('update pedido set motivo_cancelamento = :motivo_cancelamento where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', Req.Params['id']);
  conexao.Parametros('motivo_cancelamento', Req.Params['motivo']);
  conexao.ExecuteSQL;
  conexao.Free;

  ifood.Order.CancellationRequested(Req.Params['id'], Req.Params['cancel']);

end;

procedure DoPostListarMotivoPedidoiFood(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Dados: TFDMemTable;
  ifood: TADRIFood;
begin
  ifood := frmServidor.GetADRIFoodByTag
    (frmServidor.GetInstancia(Req.Params['id']));
  Dados := TFDMemTable.Create(nil);
  ifood.Order.CancelReasons(Req.Params['id'], Dados);
  Res.Send<TJSONArray>(Dados.ToJSONArray);
  Dados.Free;
end;

procedure DoGetCodigoPedido(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: Tconexao;
  mesa: Integer;
begin
  try
    mesa := Req.Params['mesa'].ToInteger;
  except
    mesa := 0;
  end;

  conexao := Tconexao.Create('Util');
  Pedido := NovoPedido(conexao.GerarID('pedido', 'codigo'), mesa,
    conexao.CriaQRY);
  conexao.Free;
  Res.Send('{"codigo":' + Pedido.ToString + '}');

end;

procedure DoGetCodigoPedidoDia(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Codigo: Integer;
begin
  Codigo := frmServidor.GerarCodigoPedidoDia;
  Res.Send(Codigo.ToString);
end;

procedure DoGetTesteFDB(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  frmServidor.QueryFDB.Close;
  frmServidor.QueryFDB.SQL.Clear;
  frmServidor.QueryFDB.SQL.Add('select * from ' + Req.Params['tabela']);
  frmServidor.QueryFDB.Open;
  Res.Send<TJSONArray>(frmServidor.QueryFDB.ToJSONArray);
end;

procedure DoPostMensagem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: Tconexao;
  Codigo: Integer;
begin

  conexao := Tconexao.Create('Util');
  Codigo := conexao.GerarID('mensagem_massa', 'id');
  conexao.SQL.Add
    ('insert into mensagem_massa (id,celular,datahora,dia_da_semana) values (:id,:celular,current_timestamp(),:dia)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('dia', Req.Params['dia']);
  conexao.Parametros('celular', Req.Params['celular']);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetRelatorioVenda(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  JSONObjeto: TJSONObject;
  DataInicial: String;
  DataFinal: String;
  Dados: TFDMemTable;
  JSONArrayHorario: TJSONArray;
  JSONObjetoHorario: TJSONObject;

  I: Integer;

  HoraInicial: Integer;
  HoraFinal: Integer;
begin
  DataInicial := '01/07/2023';
  DataFinal := '31/07/2023';

  JSONObjeto := TJSONObject.Create;
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select count(*) as quantidade, sum(pedido.valor_total_pedido) as total,');
  conexao.SQL.Add('(sum(pedido.valor_total_pedido) / count(*)) as ticket');
  conexao.SQL.Add('from pedido');
  conexao.SQL.Add
    ('where pedido.codigo_pedido_dia > 0 and pedido.id_ficha is null');
  conexao.SQL.Add('and pedido.data_pedido between :ini and :fim');
  conexao.Parametros('ini', StrToDate(DataInicial));
  conexao.Parametros('fim', StrToDate(DataFinal));
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  JSONObjeto.AddPair('sales_quanty', Dados.FieldByName('quantidade').AsInteger);
  JSONObjeto.AddPair('sales_tot', Dados.FieldByName('total').AsFloat);
  JSONObjeto.AddPair('sales_ticket', Dados.FieldByName('ticket').AsFloat);

  Dados.Free;
  HoraInicial := 0;
  HoraFinal := 1;
  JSONArrayHorario := TJSONArray.Create;
  for I := 1 to 12 do
  begin
    Dados := TFDMemTable.Create(nil);
    conexao.SQL.Add
      ('select count(*) as quantidade, sum(pedido.valor_total_pedido) as total,');
    conexao.SQL.Add('(sum(pedido.valor_total_pedido) / count(*)) as ticket');
    conexao.SQL.Add('from pedido');
    conexao.SQL.Add
      ('where pedido.codigo_pedido_dia > 0 and pedido.id_ficha is null');
    conexao.SQL.Add('and pedido.data_pedido between :ini and :fim');
    conexao.SQL.Add('and pedido.hora_pedido between :horai and :horaf');
    conexao.Parametros('ini', StrToDate(DataInicial));
    conexao.Parametros('fim', StrToDate(DataFinal));
    conexao.Parametros('horai', StrToTime(FormatFloat('00', HoraInicial)
      + ':00'));
    conexao.Parametros('horaf', StrToTime(FormatFloat('00', HoraFinal)
      + ':59'));
    Dados.LoadFromJSON(conexao.ConsultaSQL);

    if Dados.RecordCount > 0 then
    begin
      if (Dados.FieldByName('quantidade').AsInteger > 0) then
      begin
        JSONObjetoHorario := TJSONObject.Create;
        JSONObjetoHorario.AddPair('time_start',
          FormatFloat('00', HoraInicial) + ':00');
        JSONObjetoHorario.AddPair('time_end',
          FormatFloat('00', HoraFinal + 1) + ':00');
        JSONObjetoHorario.AddPair('quanty', Dados.FieldByName('quantidade')
          .AsInteger);
        JSONObjetoHorario.AddPair('tot', Dados.FieldByName('total').AsFloat);
        JSONObjetoHorario.AddPair('ticket', Dados.FieldByName('ticket')
          .AsFloat);
        JSONArrayHorario.Add(JSONObjetoHorario);
      end;
    end;

    HoraInicial := HoraInicial + 2;
    HoraFinal := HoraFinal + 2;
    Dados.Free;
  end;
  JSONObjeto.AddPair('request_time', JSONArrayHorario);
  Res.Send<TJSONObject>(JSONObjeto);
  conexao.Free;
end;

procedure DoPostAtualizaProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  JsonObject: TJSONObject;
  Campo: String;
  Valor: String;
  Codigo: String;
begin

  try
    JsonObject := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

    Campo := JsonObject.GetValue<String>('campo');
    Valor := JsonObject.GetValue<String>('valor');
    Codigo := JsonObject.GetValue<String>('codigo');
  except
    Campo := Req.Params['campo'];
    Valor := Req.Params['value'];
    Codigo := Req.Params['codigo'];
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('update produto set ' + Campo + ' = :' + Campo +
    ', modificado_site = 0 where codigo = :codigo');
  conexao.Parametros(Campo, Valor);
  conexao.Parametros('codigo', Codigo);
  conexao.ExecuteSQL;

  if Campo = 'ativo' then
  begin
    conexao.SQL.Add
      ('update pro_adi_personalizado_sabores set ativo = :ativo, modificado_site = 0 where id_prod_estoque = :codigo');
    conexao.Parametros('ativo', Valor);
    conexao.Parametros('codigo', Codigo);
    conexao.ExecuteSQL;
  end;

  EnviaProduto(Codigo.ToInteger, '');

  conexao.Free;

end;

procedure DoGetAdicionalProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin
  Res.Send<TJSONArray>(frmServidor.ObjetoProdutoAdicional
    (Req.Params['codigo']));
end;

procedure DoGetProdutoCategoria(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
begin
  Res.Send<TJSONArray>(GetProdutoCategoria(Req.Params['categoria']));
end;

procedure DoGetProdutoBuscaP(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  SQL: String;
begin
  // Res.Send<TJSONArray>(frmServidor.ObjetoProduto('select * from produto where upper(nome_produto) like "%' +UpperCase(Req.Params['nome'])+'%" collate utf8mb4_general_ci order by nome_produto'));

  // SQL := 'SELECT *';
  // SQL := SQL + ' FROM produto';
  // SQL := SQL + ' WHERE upper(nome_produto) LIKE CONCAT(' + QuotedStr('%') +
  // ', REPLACE(' + QuotedStr(UpperCase(Req.Params['nome']) + '%') + ', ' +
  // QuotedStr(' ') + ', ' + QuotedStr('%') + '), ' + QuotedStr('') + ')';
  // SQL := SQL + ' ORDER BY nome_produto;';

  SQL := ' SELECT * FROM produto WHERE ativo = 1 and upper(nome_produto) COLLATE utf8_general_ci LIKE "%'
    + UpperCase(Req.Params['nome']) + '%" ORDER BY position';

  Res.Send<TJSONArray>(ObjetoProduto(SQL));
end;

procedure DoGetDashBoardDados(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select (select count(*) from mesa where mesa.tot_mesa > 0) as emuso,');
  conexao.SQL.Add
    ('count(*) as todas, (((select count(*) from mesa where mesa.tot_mesa > 0) / count(*) )*100 ) as percentual');
  conexao.SQL.Add('from mesa');
  Res.Send(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure Registry;
begin
  THorse.Get('v1/util/limpa/banco/:banco/:chave', DoGetLimpaBanco);

  THorse.Get('v1/versao/app', DoGetVersao);

  THorse.Get('/v1/mesas/', DoGetMesas);
  THorse.Get('/v1/mesas/:mesa', DoGetMesas);
  THorse.Get('/v1/mesa/:mesa', DoGetMesa);
  THorse.Get('/v1/test/', DoGetTest);

  THorse.Get('/v1/categorias', DoGetCategoria);

  THorse.Get('/v1/produtos/4:categoria/:delivery', DoGetProduto);

  THorse.Get('/v1/produtos/nome/:busca', DoGetProdutoBusca);
  THorse.Get('/v1/produtos/nome/', DoGetProdutoBusca);

  THorse.Get('/v1/produtos/adicional/:produto', DoGetProdutoAdiciona);
  THorse.Get('/v1/produtos/sabores/:produto', DoGetProdutoSabores);

  THorse.Post('/v2/grava/varios/produtos', DoPostPedidoProduto);
  THorse.Post('/v1/pedido/produto/:usuario', DoPostPedidoProduto);
  THorse.Delete('/v1/pedido/produto/:id', DoDeletePedidoProduto);
  THorse.Post('/v1/delete/pedido/produto/:id', DoDeletePedidoProduto);

  THorse.Get('/v1/produtos/pedido/:tipo/:mesa', DoGetProdutoPedido);
  THorse.Get('/v1/produtos/pedido/itens/:id', DoGetProdutoPedidoItens);

  THorse.Put
    ('/v1/pedido/finaliza/:mesa/:impressao/:desconto/:acrecimo/:tipopagamento/:taxaentrega/:caixa/:pedido/:nota',
    DoPutFinalizaPedido);

  THorse.Put
    ('/v1/pedido/finaliza/:mesa/:impressao/:desconto/:acrecimo/:tipopagamento/:taxaentrega/:caixa/:pedido/:nota/:motoboy',
    DoPutFinalizaPedido);

  THorse.Put('/v1/pedido/pagamento/pix/:caixa/:pedido/:tipo/:total',
    DoPutPagamentoPIX);
  THorse.Put('/v1/pedido/pagamento/:caixa/:pedido/:tipo/:total',
    DoPutPagamento);

  THorse.Get('/v1/pedido/pagamento/:pedido', DoGetPedidoPagamento);
  THorse.Delete('/v1/pedido/pagamento/delete/movimentacao/:id',
    DoDeletPedidoPagamento);

  THorse.Get('/v1/pedido/produtos/:pedido', DoGetPedidoProduto);
  THorse.Get('/v1/pedido/produtos/mesa/:pedido', DoGetPedidoProduto);
  THorse.Get('/v1/produtos/validacao/:produto', DoGetPedidoProdutoStatus);

  THorse.Get('/v1/usuario/:usuario/:senha', DoGetUsuario);

  THorse.Get('/v1/total/:dataini/:datafim/:horaini/:horafim', DoGetTotal);
  THorse.Get('/v1/total/motoboy/:dataini/:datafim/:horaini/:horafim',
    DoGetTotalMotoboy);

  THorse.Get('/v1/pedidos/:dataini/:datafim/:horaini/:horafim/:tipo/:faturado',
    DoGetPedidos);

  THorse.Get('/v1/tipo/pagamento/', DoGetTipoPagamento);

  THorse.Get('/v1/caixa/aberto/:usuario', DoGetCaixa);
  THorse.Post('/v1/caixa/abertura/:usuario/:valor', DoPostAberturaCaixa);

  THorse.Post('/v1/caixa/sangria', DoPostSangria);
  THorse.Post('/v1/caixa/movimentacao/', DoPostMovimentacaoCaixa);

  THorse.Get('/v1/caixa/dados/:caixa', DoGetCaixaDados);

  THorse.Get('/v1/caixa/pedidos/dados/:caixa', DoGetPedidosCaixa);
  THorse.Get('/v1/caixa/pedidos/historico/:caixa', DoGetHistoricoCaixa);
  THorse.Get('/v1/caixa/pedidos/pagamento/:caixa', DoGetPagamentoCaixa);
  THorse.Get('/v1/caixa/historico/', DoGetHistoricoCaixaTodos);
  THorse.Get('/v1/caixa/historico/ultimos/7/dias',
    DoGetHistoricoCaixaUltimos7Dias);
  THorse.Get('/v1/caixa/receber/:codigo', DoGetAReceber);

  THorse.Post('/v1/caixa/fechamento/:caixa', DoPostFechamentoCaixa);
  THorse.Post('/v1/caixa/fechamento/pedido/automatico/:caixa',
    DoPostFaturarPeido);
  THorse.Get('/v1/caixa/fechamento/pedido/automatico', DoGetFechamentoCaixa);
  // frmServidor.FaturarEmAberto := true;

  THorse.Post('/v1/fechamento/pedido/automatico/:pedido/:caixa',
    DoPostFechamentoPedido);

  THorse.Post('/v1/caixa/recebimento/pedido/:caixa/:id/:pedido',
    DoPostRecebimentoCaixa);
  /// v1/caixa/fechamento/pedido/automatico/



  // Gerenciador Project X

  THorse.Get('/v1/consulta/generica/:tabela/:campo/:condicao/:orderby',
    DoGetConsultaGenerica);

  THorse.Get('/v1/categoria/all', DoGetAllCategoria);

  THorse.Post('/v1/produto', DoPostProduto);

  THorse.Get('/v1/produto/all', DoGetAllProduto);
  THorse.Get('/v1/produto/:busca', DoGetAllProduto);

  THorse.Post('/v1/extra/:categoria/:min/:max', DoPostExtra);
  THorse.Post('/v1/ingredientes/', DoPostIngredientes);

  THorse.Get('/v1/extra/all', DoGetAllExtra);

  THorse.Get('/v1/extra/all/:id', DoGetAllExtra);

  THorse.Post('/v1/extra/produto/:produto/:extra', DoPostExtraProduto);

  THorse.Get('/v1/tabela/produto/:id', DoGetTabelaProduto);

  THorse.Post('/v1/tabela/produto/', DoPostTabelaProduto);

  THorse.Put('/v1/tabela/produto/:id', DoPutTabelaPreco);

  THorse.Get('/v1/dados/produto/:id', DoDadosProduto);

  THorse.Post('/v1/produto/alteracao', DoPostAlteracao);

  THorse.Get('/v1/dados/produto/codigo/:id', DoGetProdutoCodigo);

  THorse.Get('/v1/extra/alteracao/all', DoGetAllExtraAlteracao);
  THorse.Get('/v1/extra/itens/:id', DoGetExtraItens);

  THorse.Put('/v1/extra/alteracao/:id/:categoria/:min/:max',
    DoPutExtraAlteracao);

  THorse.Post('/v1/imagem/produto/:id/:arquivo', DoPostImgProduto);
  THorse.Get('/v1/imagem/produto/:id', DoGetImgProduto);

  THorse.Post('/v1/imprimir/:tipo/:codigo/:servico', DoPostImprimir);
  THorse.Post('/v1/imprimir/:tipo/:codigo', DoPostImprimir);

  // Cadastros
  THorse.Get('/v1/categoria/:all/', DoGetCategoriaAll);
  THorse.Post('/v1/categoria/post/', DoPostCategoriaAll);

  THorse.Get('/v1/consulta/todos/:tabela', DoGetConsultaTodos);
  THorse.Get('/v1/consulta/todos/clientes', DoGetTodosCliente);
  THorse.Get('/v1/consulta/cliente/:nome', DoGetTodosCliente);

  // Motoboy
  THorse.Get('/v1/motoboy/ativo/all/', DoGetMotboyAtivo);

  THorse.Put('/v1/pedido/motoboy/:pedido/:motoboy/', DoPutPedidoMotoboy);
  THorse.Put('/v1/pedido/status/:pedido/:status/', DoPutPedidoStatus);
  THorse.Post('/v1/pedido/reimpressao/app/:id', DoPostReImpressaoApp);

  THorse.Post('/v1/insert/generico/:tabela/:id', DoPostGenerico);

  THorse.Get('/v1/cliente/celular/:celular', DoGetClienteCelular);

  THorse.Get('/v1/media/pedido', DoGetMediaPedido);
  THorse.Post('/v1/media/pedido', DoGetMediaPedido);
  THorse.Get('/v1/media/pedido/:datas', DoGetMediaPedido);
  THorse.Get('/v1/dashboard/', DoGetDashBoard);
  THorse.Get('/v1/dashboard/previsao/', DoGetDashBoardPrevisao);

  THorse.Post('/v1/transferencia/mesa/:id/:mesa', DoPostTransferenciaMesa);

  THorse.Post('/v1/imprimir', DoPostImprimirNaoImpresso);

  //
  THorse.Get('/v1/mesas/all/', DoGetMesasAll);

  THorse.Post('/v1/gerente/senha/:senha', DoPostSenhaGerente);
  THorse.Get('/v1/gerente/senha/:senha', DoGetSenhaGerente);

  THorse.Post('/v1/mesa/zera/:id', DoPostZeraMesa);
  THorse.Post('/v1/mesa/deleta/:id', DoPostDeletaMesa);

  THorse.Get('/getfile', DoGetFileTest);

  THorse.Get('/upload', DoPostTest);

  THorse.Get('v1/versao/app', DoGetAtualizacaoApp);

  // Pedido Local

  THorse.Get('/v1/dados/pedido/:codigo', DoGetDadosPedido);
  THorse.Get('/v1/dados/pedido/:codigo/:usuario', DoGetDadosPedido);
  THorse.Get('/v1/dados/pedido/:codigo/:usuario/:completo', DoGetDadosPedido);
  // THorse.Get('/v1/dados/consulta/cliente/:codigo', DoGetDadosPedido);
  THorse.Get('/v1/dados/consulta/cliente/:codigo', DoGetConsultaCliente);
  THorse.Get('/v1/dados/consulta/cliente/endereco/:codigo',
    DoGetConsultaClienteEndereco);
  THorse.Get('/v1/dados/consulta/cliente/celular/:celular',
    DoGetConsultaClienteCelular);

  THorse.Post('/v1/atualiza/dados/pedido/', DoPostAtualizaDadosPedido);
  THorse.Post('/v1/atualiza/dados/pedido/:tipo', DoPostAtualizaDadosPedido);

  THorse.Get('/v1/sabores/preco/', DoGetSaboresPreco);
  THorse.Post('/v1/sabores/preco/', DoPostSaboresPreco);

  THorse.Get('/v1/motoboy/historico/:dataini', DoGetHistoricoMotoboy);
  THorse.Get('/v1/motoboy/historico/completo/:codigo',
    DoGetHistoricoMotoboyCompleto);

  THorse.Post('/v1/sql/update', DoUpdateGeral);

  THorse.Get('/v1/impressora/servidor/', DoGetImpressoraServidor);
  THorse.Post('/v1/impressora/servidor/', DoPostImpressora);

  THorse.Post('/v1/tipopagamento/', DoPostTipoPagamento);

  // Cadastro do Produto Novo
  THorse.Get('/v1/extra/produto/:id', DoGetExtraProduto);
  THorse.Get('/v1/extra/produto/itens/:id', DoGetExtraProdutoItens);
  THorse.Post('/v1/extra/produto/atualiza', DoPostAtualizaProdutoExtra);
  THorse.Post('/v1/extra/produto/itens', DoPostAtualizaExtraItens);
  THorse.Post('/v1/extra/produto/:id', DoPostProdutoExtra);

  // Relatorio

  THorse.Get
    ('/v1/util/relatorio/financeiro/:tipo/:idia/:imes/:iano/:fdia/:fmes/:fano',
    DoGetRelatorioFinanceiro);

  // Extra
  THorse.Get('/v1/util/extra/produtos/', DoGetExtraAll);
  THorse.Post('/v1/util/extra/produtos/:extra/:produto', DoPostExtraAll);

  // Sabores
  THorse.Get('/v1/util/tipo/sabor/', DoGetTipoSabor);
  THorse.Get('/v1/util/sabor/:codigo', DoGetSaborCodigo);
  THorse.Post('/v1/sabor/produto/:id', DoPostSaborProduto);
  THorse.Post('/v1/sabor/produto/', DoPostSaborProduto);

  // Bairro
  THorse.Get('/v1/util/busca/bairro/:busca', DoGetBuscaBairro);

  // Estorno
  THorse.Post('/v1/util/pedido/caixa/extorno/:id', DoPostPedidoExtorno);

  // Whatsapp
  THorse.Get('/v1/util/whatsapp/pix', DoGetWhatsappPix);
  THorse.Post('/v1/util/whatsapp/pix/:codigo', DoPostWhatsappPix);
  THorse.Post('/v1/util/whatsapp/status/:codigo', DoPostWhatsappStatus);
  THorse.Get('/v1/util/whatsapp/status', DoGetWhatsappstatus);
  THorse.Get('/v1/util/whatsapp/status/alterado', DoGetWhatsappStatusAlterado);

  THorse.Get('/v1/util/dados/pedido/produtos/:codigo', DoGetDadosPedidoProduto);

  THorse.Post('/v1/util/impressao/aguarda/pedido/produtos/:codigo',
    DoPostAguardaImpressaoPedidoProduto);
  THorse.Post('/v1/util/impressao/aguarda/pedido/produtos/:codigo/:mesa',
    DoPostAguardaImpressaoPedidoProduto);
  THorse.Post('/v1/util/impressao/pedido/produtos/:codigo',
    DoPostLiberaImpressaoPedidoProduto);

  // Cadastro Mesa
  THorse.Post('/v1/util/grava/mesa/:tipo/:min/:max', DoPostGravaMesas);

  THorse.Get('/v1/util/gerador/:tabela/:campo', DoGetGerador);

  // Estoque
  THorse.Post('/v1/estoque/produto/:codigo/:tipo/:quantidade',
    DoPostEstoqueProduto);
  // Ingredientes
  THorse.Post('/v1/util/grava/ingrediente/:id/:descricao/:unidade',
    DoPostIngredientesFicha);

  THorse.Post('/v1/util/grava/ingrediente/ficha/produto', DoPostFichaProduto);
  THorse.Get('/v1/util/grava/ingrediente/ficha/produto/:codigo',
    DoGetFichaProduto);

  THorse.Post
    ('/v1/util/estoque/ingrediente/produto/:ingrediente/:tipo/:qtd/:custo',
    DoPostEstoqueIngrediente);

  THorse.Get('/v1/consulta/todos/ingredientes', DoGetDadosIngredientes);

  THorse.Post('/v1/gera/pix/:token/:valor/:pedido', DoPostGeraPix);

  THorse.Get('v1/util/gerador/:tabela/:campo', DoGetGerador);

  THorse.Get('v1/util/estoque/geral', DoGetEstoqueGeral);

  THorse.Get('v1/util/fator/conversao/:un/:tipo/:codigo', DoGetFatorConversao);
  THorse.Post('v1/util/fator/conversao/:unde/:unpara/:valor/:tipo/:codigo',
    DoPostFatorConversao);

  THorse.Post('v1/util/estoque/produto/insumos', DoPostEstoqueProdutoInsulmos);

  THorse.Post('v1/util/finalizar/servico/:tipo', DoFinalizarServico);

  THorse.Post('v1/util/teste/impressao/:id', DoTesteImpressao);

  THorse.Post('v1/baixa/estoque/produto/:codigo/:qtd',
    DoPostBaixaEstoqueProduto);
  THorse.Post('v1/baixa/estoque/insulmo/:codigo', DoPostBaixaEstoqueInsulmo);
  THorse.Post
    ('v1/baixa/estoque/produto/adicional/:produto/:adicional/:quantidade/:valor',
    DoPostBaixaEstoqueProdutoAdicional);

  THorse.Get('v1/util/teste/impressao', DoTesteImpressao);

  // whatsapp
  THorse.Get('v1/util/status/pedido', DoGetStatusPedido);
  THorse.Post('v1/util/status/pedido/:codigo', DoGetStatusPedido);
  THorse.Post('v1/util/taxa/entrega', DoPostTaxaEntrega);

  THorse.Post
    ('v1/cliente/cadastro/:codigo/:celular/:nome/:rua/:numero/:complemento/:bairro/:cidade/:estado/:cpf',
    DoPostCadastroCliente);

  THorse.Post('v1/util/clona/sabor/pizza/:de/:para', DoPostClonaSabor);

  // Integração iFood
  THorse.Get('v1/util/ifood/status', DoGetStatusiFood);
  THorse.Get('v1/util/ifood/status/:id', DoGetStatusiFood);
  THorse.Get('v1/util/ifood/autenticacao/:id', DoGetAutenticacaoiFood);
  THorse.Post('v1/util/ifood/autenticacao/:id', DoPostUrlAutenticacao);
  THorse.Post('v1/util/ifood/autenticacao/:id/:autenticador',
    DoPostUrlAutenticacao);

  THorse.Post('v1/util/ifood/confirmar/:id', DoPostConfirmarPedidoiFood);
  THorse.Post('v1/util/ifood/preparar/:id', DoPostPrepararPedidoiFood);
  THorse.Post('v1/util/ifood/despachar/:id', DoPostDespacharPedidoiFood);
  THorse.Post('v1/util/ifood/retirar/:id', DoPostRetirarPedidoiFood);
  THorse.Get('v1/util/ifood/lista/motivo/:id', DoPostListarMotivoPedidoiFood);
  THorse.Post('v1/util/ifood/cancelar/:id/:cancel/:motivo',
    DoPostCancelarPedidoiFood);
  THorse.Get('v1/util/ifood/importa/produto', DoGetProdutoiFood);
  // THorse.Get('v1/util/ifood/status/cancelamento', DoGetStatusiFoodCancelamento);

  // Dashboard
  THorse.Get('v1/util/dashboard/ocupacao', DoGetDashBoardDados);

  THorse.Get('v1/produto/categoria/:categoria', DoGetProdutoCategoria);
  THorse.Get('v1/produto/busca/:nome', DoGetProdutoBuscaP);
  THorse.Get('v1/produto/adicional/:codigo', DoGetAdicionalProduto);

  // Produto

  THorse.Post('v1/atualiza/produto/:codigo/:campo/:value',
    DoPostAtualizaProduto);
  THorse.Post('v1/atualiza/produto', DoPostAtualizaProduto);

  THorse.Get('v1/relatorio/venda/:dataini/:datafim', DoGetRelatorioVenda);

  THorse.Get('v1/testefdb/:tabela', DoGetTesteFDB);

  THorse.Get('v1/codigo/pedido/dia', DoGetCodigoPedidoDia);
  THorse.Get('v1/codigo/pedido', DoGetCodigoPedido);
  THorse.Get('v1/codigo/pedido/:mesa', DoGetCodigoPedido);

  THorse.Post('v1/mensagem/:dia/:celular', DoPostMensagem);

end;

function TransformaData(Data: String): TDate;
begin
  Data := StringReplace(Data, '"', '', [rfReplaceAll]);
  Data := COPY(Data, 0, 2) + '/' + COPY(Data, 3, 2) + '/' + COPY(Data, 5, 4);
  Result := StrToDate(Data);
end;

function TransformaHora(Hora: String): TTime;
begin
  Hora := COPY(Hora, 0, 2) + ':' + COPY(Hora, 3, 2) + ':' + COPY(Hora, 5, 4);
  Result := StrToTime(Hora);
end;

function TrocaVirgula(Resultado: String): String;
begin
  Result := Resultado;
  Result := StringReplace(Result, '.0', ',0', [rfReplaceAll]);
  Result := StringReplace(Result, '.1', ',1', [rfReplaceAll]);
  Result := StringReplace(Result, '.2', ',2', [rfReplaceAll]);
  Result := StringReplace(Result, '.3', ',3', [rfReplaceAll]);
  Result := StringReplace(Result, '.4', ',4', [rfReplaceAll]);
  Result := StringReplace(Result, '.5', ',5', [rfReplaceAll]);
  Result := StringReplace(Result, '.6', ',6', [rfReplaceAll]);
  Result := StringReplace(Result, '.7', ',7', [rfReplaceAll]);
  Result := StringReplace(Result, '.8', ',8', [rfReplaceAll]);
  Result := StringReplace(Result, '.9', ',9', [rfReplaceAll]);
end;

function MovimentoCaixa(Caixa, Pedido, TipoPagamento, Tipo: Integer;
Valor: Real; Descricao: String; Cliente: Integer): Integer;
var
  conexao: Tconexao;
  Codigo: Integer;
  DadosTipoPagamento: TFDMemTable;
begin
  Descricao := RemoveAcento(Descricao);
  Descricao := UpperCase(Descricao);

  conexao := Tconexao.Create('Util');
  Codigo := conexao.GerarID('caixa_movimento', 'id');
  conexao.SQL.Add
    ('insert into caixa_movimento (id,id_caixa,id_pedido,tipo,id_tipo_pagamento,data,hora,valor,descricao,id_cliente) values (:id,:caixa,:pedido,:tipo,:pagamento,current_date,current_time,:valor,:descricao,:cliente)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('caixa', Caixa);
  conexao.Parametros('pedido', Pedido);
  conexao.Parametros('tipo', Tipo);
  conexao.Parametros('pagamento', TipoPagamento);
  conexao.Parametros('valor', Valor);
  conexao.Parametros('descricao', Descricao);
  conexao.Parametros('cliente', Cliente);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('update pedido set id_caixa = :caixa where codigo = :pedido and (id_caixa is null or id_caixa = 0)');
  conexao.Parametros('caixa', Caixa);
  conexao.Parametros('pedido', Pedido);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('update pedido_produtos set selecionado = 0 where codigo_pedido =:pedido');
  conexao.Parametros('pedido', Pedido);
  conexao.ExecuteSQL;

  DadosTipoPagamento := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from tipo_pagamento where codigo = :codigo');
  conexao.Parametros('codigo', TipoPagamento);
  DadosTipoPagamento.LoadFromJSON(conexao.ConsultaSQL);

  if DadosTipoPagamento.RecordCount > 0 then
  begin
    if DadosTipoPagamento.FieldByName('movimentacao').AsInteger = 2 then
    begin
      // Gerar A Receber
      GerarReceber(Caixa, Pedido, TipoPagamento, Valor, Cliente, Codigo);

    end;

  end;

  conexao.Free;
  Result := Codigo;
end;

procedure GerarReceber(Caixa, Pedido, TipoPagamento: Integer; Valor: Real;
CodigoCliente, Movimento: Integer);
var
  conexao: Tconexao;

  Codigo: Integer;
  nome: String;
begin

  if CodigoCliente = 0 then
  begin
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('SELECT * FROM CLIENTE WHERE CODIGO = :CODIGO');
  conexao.Parametros('CODIGO', CodigoCliente);
  try
    nome := conexao.FieldByName('nome');
  except

  end;

  if nome <> '' then
  begin
    conexao.SQL.Add('update caixa_movimento set descricao = concat(descricao,' +
      QuotedStr(' (' + UpperCase(nome) + ')') + ')  where id = :id');
    conexao.Parametros('id', Movimento);
    conexao.ExecuteSQL;
  end;

  Codigo := conexao.GerarID('caixa_receber', 'id');
  conexao.SQL.Add
    ('insert into caixa_receber (id,id_caixa,id_cliente,id_pedido,id_tipo_pagamento,data,hora,valor,status) values (:id,:id_caixa,:id_cliente,:id_pedido,:id_tipo_pagamento,current_date,current_time,:valor,1) ');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('id_caixa', Caixa);
  conexao.Parametros('id_cliente', CodigoCliente);
  conexao.Parametros('id_pedido', Pedido);
  conexao.Parametros('id_tipo_pagamento', TipoPagamento);
  conexao.Parametros('valor', Valor);
  conexao.ExecuteSQL;
  conexao.Free;

end;

function SQLFormatdaDataMysql(Campo: String): String;
begin
  Result := 'DATE_FORMAT(' + Campo + ',' + QuotedStr('%d/%m/%Y') + ') as ' +
    Campo + ',';
end;

function SQLFormatdaHoraMysql(Campo: String): String;
begin
  Result := 'DATE_FORMAT(' + Campo + ',' + QuotedStr('%h:%i:%s') + ') as ' +
    Campo + ',';
end;

function SQLFormatdaValorMysql(Campo: String): String;
begin
  Result := 'REPLACE(' + Campo + ', ' + QuotedStr('.') + ', ' + QuotedStr(',') +
    ') as ' + Campo + ',';
end;

function ValidaQuantidadeSabores(Sabores, Codigo: String): Integer;
begin
  Result := 0;
  while pos(Codigo, Sabores) > 0 do
  begin
    inc(Result);
    Sabores := StringReplace(Sabores, Codigo, '', []);
  end;
end;

{
  function BitmapFromBase64(const base64: string): TBitmap;
  var
  Input: TStringStream;
  Output: TBytesStream;
  begin
  Input := TStringStream.Create(base64, TEncoding.ASCII);
  try
  Output := TBytesStream.Create;
  try
  Soap.EncdDecd.DecodeStream(Input, Output);
  Output.Position := 0;
  Result := TBitmap.Create;
  Output.SaveToFile('C:\papaleguas\img\test.bmp');
  try
  Result.LoadFromStream(Output);
  except
  on E: Exception do
  begin
  ////showmessage1(E.Message);
  Result.Free;
  // raise;
  end;
  end;
  finally
  Output.Free;
  end;
  finally
  Input.Free;
  end;
  end; }

procedure SalvarImagenBase64(base64, Caminho: String);
var
  Input: TStringStream;
  Output: TBytesStream;
begin
  Input := TStringStream.Create(base64, TEncoding.ASCII);
  try
    Output := TBytesStream.Create;
    try
      Soap.EncdDecd.DecodeStream(Input, Output);
      Output.Position := 0;

      Output.SaveToFile(Caminho);
      try

      except
        on E: Exception do
        begin

        end;
      end;
    finally
      Output.Free;
    end;
  finally
    Input.Free;
  end;
end;

function NonoDigito(Celular: String): String;
begin
  Result := Celular;
end;

function GeraCodigoPorDiaPedido(Pedido: Integer): Integer;
var
  Insert: Tconexao;
  HoraAtual: Word;
  DifHoras: Double;
begin
  Insert := Tconexao.Create('Util');
  try
    Insert.SQL.Add
      ('select codigo_pedido_dia from pedido where codigo = :codigo');
    Insert.Parametros('codigo', Pedido);
    Result := Insert.FieldByName('codigo_pedido_dia');

    HoraAtual := HourOf(Now);
    if (HoraAtual >= 15) then
    begin
      // Estamos no segundo turno
      DifHoras := (Now - frmServidor.UltimoHorarioPedidoTurnoTarde) * 24;

      if (DifHoras >= 2) then
      begin
        // Passaram-se mais de 2 horas desde o último pedido do segundo turno

        frmServidor.CodigoPedido := 0;

      end;

      // Atualiza o último horário usado para gerar pedidos no turno da tarde
      frmServidor.UltimoHorarioPedidoTurnoTarde := Now;
    end;
  finally
    Insert.Free;
  end;
  Result := frmServidor.GerarCodigoPedidoDia;
end;

{
  function GeraCodigoPorDiaPedido(Pedido: Integer): Integer;
  var
  Data: TDate;
  Insert: Tconexao;
  Dados: TFDMemTable;
  SQL: String;
  begin
  Insert := Tconexao.Create('Util');
  Insert.SQL.Add('select * from pedido where codigo = :codigo');
  Insert.Parametros('codigo', Pedido);
  Result := Insert.FieldByName('codigo_pedido_dia');
  if Result > 0 then
  begin
  Insert.Free;
  exit;
  end;

  Result := frmServidor.GerarCodigoPedidoDia;
  Insert.Free;
  exit;

  if time > StrToTime('04:59:59') then
  begin
  SQL := 'SELECT max(codigo_pedido_dia) as maior, 0 as id FROM pedido where status > -1 and data_pedido ='
  + QuotedStr(FormatDateTime('yyyy-mm-dd', Date)) + ' and hora_pedido > ' +
  QuotedStr('05:00:00');
  try
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
  except
  Insert.Free;
  Result := 1;
  Dados.Free;
  exit;
  end;

  end
  else
  begin

  SQL := 'SELECT max(codigo_pedido_dia) as maior, 0 as id FROM pedido where status > -1 and data_pedido ='
  + QuotedStr(FormatDateTime('yyyy-mm-dd', Date)) + ' and hora_pedido > ' +
  QuotedStr('00:00:00');
  try
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
  except
  Insert.Free;
  Result := 1;
  Dados.Free;
  exit;
  end;

  if Dados.RecordCount > 0 then
  begin
  try
  Result := Dados.FieldByName('maior').AsInteger + 1;
  except
  Result := 1;
  end;
  end;

  if Result > 1 then
  begin
  Insert.Free;;
  Dados.Free;
  exit;
  end;
  SQL := 'SELECT max(codigo_pedido_dia) as maior, 0 as id FROM pedido where status > 0 and data_pedido ='
  + QuotedStr(FormatDateTime('yyyy-mm-dd', Date - 1)) +
  ' and hora_pedido > ' + QuotedStr('05:00:00');
  try
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
  except
  Insert.Free;
  Result := 1;
  Dados.Free;
  exit;
  end;

  end;
  try
  Result := Dados.FieldByName('maior').AsInteger + 1;
  except
  Result := 1;
  end;

  if Dados.RecordCount = 0 then
  Result := 1;

  Dados.Free;
  Insert.Free;

  end; }

function RemoveAcento(const pText: string): string;
const
  ComAcento = 'àâêôûãõáéíóúçüñýÀÂÊÔÛÃÕÁÉÍÓÚÇÜÑÝ';
  SemAcento = 'aaeouaoaeioucunyAAEOUAOAEIOUCUNY';
var
  x: Cardinal;
  aText: String;
begin;
  aText := pText;
  for x := 1 to length(aText) do
    try
      if (pos(aText[x], ComAcento) <> 0) then
        aText[x] := SemAcento[pos(aText[x], ComAcento)];
    except
      on E: Exception do
        raise Exception.Create('Erro no processo.');
    end;

  Result := aText;
end;

function GetBuildInfo: string;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
begin
  VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
  GetMem(VerInfo, VerInfoSize);
  GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
  VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
  with VerValue^ do
  begin
    Result := IntToStr(dwFileVersionMS shr 16);
    Result := Result + '.' + IntToStr(dwFileVersionMS and $FFFF);
    Result := Result + '.' + IntToStr(dwFileVersionLS shr 16);
    Result := Result + '.' + IntToStr(dwFileVersionLS and $FFFF);
  end;
  FreeMem(VerInfo, VerInfoSize);
end;

procedure MovimentacaoProdutoAdicionalExtorno(Codigo: Integer;
Adicional: String; Valor, Quantidade: Real);
var
  conexao: Tconexao;
  CodigoProduto: Integer;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select paps.id_prod_estoque as produto, 0 as zero from pro_adi_personalizado_sabores as paps');
  conexao.SQL.Add
    ('join pro_adi_personalizado as pap on pap.id = paps.id_pro_adi_personalizado');
  conexao.SQL.Add
    ('where pap.id_produto = :codigo and upper(paps.nome) = :nome and paps.valor = :valor');
  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('nome', UpperCase(Adicional));
  conexao.Parametros('valor', Valor);

  try
    CodigoProduto := conexao.FieldByName('produto');
  except
    CodigoProduto := 0;
  end;

  if CodigoProduto > 0 then
  begin
    MovimentacaoProduto(CodigoProduto, 1, Quantidade);
  end;
  conexao.Free;
end;

procedure MovimentacaoProdutoAdicional(Codigo: Integer; Adicional: String;
Valor, Quantidade: Real);
var
  conexao: Tconexao;
  CodigoProduto: Integer;
begin
  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select paps.id_prod_estoque as produto, 0 as zero from pro_adi_personalizado_sabores as paps');
  conexao.SQL.Add
    ('join pro_adi_personalizado as pap on pap.id = paps.id_pro_adi_personalizado');
  conexao.SQL.Add
    ('where pap.id_produto = :codigo and upper(paps.nome) = :nome and paps.valor = :valor');
  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('nome', UpperCase(Adicional));
  conexao.Parametros('valor', Valor);

  try
    CodigoProduto := conexao.FieldByName('produto');
  except
    CodigoProduto := 0;
  end;

  if CodigoProduto > 0 then
  begin
    MovimentacaoProduto(CodigoProduto, 2, Quantidade);
  end;
  conexao.Free;
end;

function AtualizacaoCustoIngrediente(CodigoIngrediente: Integer): TJSONArray;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  DadosIngrediente: TFDMemTable;
  Ingredientes: String;
  Objeto: TJSONObject;
  CustoIndireto: Real;
  Custo: Real;
  ValorImposto: Real;
  ValorCartao: Real;
  ValorIfood: Real;
  ValorLucro: Real;
  ValorSugerido: Real;
  Valor: Real;

begin
  Result := TJSONArray.Create;
  Dados := TFDMemTable.Create(nil);
  conexao := Tconexao.Create('AtualizacaoCustoIngrediente');
  Ingredientes := CodigoIngrediente.ToString;

  conexao.SQL.Add
    ('SELECT 0 as zero, id_ingrediente as ingredientes FROM ingredientes_ficha where id_composicao = :codigo');
  conexao.Parametros('codigo', CodigoIngrediente);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      DadosIngrediente := TFDMemTable.Create(nil);
      conexao.SQL.Add
        ('SELECT ing_f.id_ingrediente, sum(ing_f.quantidade * ing.custo) / ing_ficha.quantidade  as new_custo, ing_ficha.custo as old_custo, ing_ficha.quantidade, ing_ficha.descricao  FROM ingredientes_ficha as ing_f');
      conexao.SQL.Add
        ('join ingredientes as ing on ing.id = ing_f.id_composicao');
      conexao.SQL.Add
        ('join ingredientes as ing_ficha on ing_ficha.id = ing_f.id_ingrediente');
      conexao.SQL.Add('where ing_f.id_ingrediente = :id');
      conexao.SQL.Add
        ('GROUP BY ing_f.id_ingrediente, ing_ficha.quantidade, ing_ficha.descricao, ing_ficha.custo;');
      conexao.Parametros('id', Dados.FieldByName('ingredientes').AsInteger);
      DadosIngrediente.LoadFromJSON(conexao.ConsultaSQL);
      if DadosIngrediente.RecordCount > 0 then
      begin
        if DadosIngrediente.FieldByName('old_custo').AsFloat <>
          DadosIngrediente.FieldByName('new_custo').AsFloat then
        begin

          Objeto := TJSONObject.Create;
          Objeto.AddPair('id', DadosIngrediente.FieldByName('id_ingrediente')
            .AsInteger);
          Objeto.AddPair('old',
            DadosIngrediente.FieldByName('old_custo').AsFloat);
          Objeto.AddPair('new',
            DadosIngrediente.FieldByName('new_custo').AsFloat);
          Objeto.AddPair('economy', DadosIngrediente.FieldByName('old_custo')
            .AsFloat - DadosIngrediente.FieldByName('new_custo').AsFloat);
          Objeto.AddPair('name', DadosIngrediente.FieldByName('descricao')
            .AsString);
          Objeto.AddPair('qtd',
            DadosIngrediente.FieldByName('quantidade').AsFloat);
          Objeto.AddPair('type', 'Ingrediente');

          conexao.SQL.Add
            ('update ingredientes set custo = :custo, custo_ultimo = :old where id = :id');
          conexao.Parametros('id',
            DadosIngrediente.FieldByName('id_ingrediente').AsInteger);
          conexao.Parametros('old',
            DadosIngrediente.FieldByName('old_custo').AsFloat);
          conexao.Parametros('custo',
            DadosIngrediente.FieldByName('new_custo').AsFloat);
          conexao.ExecuteSQL;

          Result.Add(Objeto);
          Ingredientes := Ingredientes + ',' + DadosIngrediente.FieldByName
            ('id_ingrediente').AsString;
        end;
      end;

      DadosIngrediente.Free;
      Dados.Next;
    end;

  end;
  Dados.Free;

  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT pi.id_produto as id, prod.nome_produto as nome, prod.valor_custo as custo_old, (pi.quantidade * ingre.custo) as custo_new FROM produto_ingredientes as pi');
  conexao.SQL.Add
    ('join ingredientes as ingre on ingre.id = pi.id_ingredientes');
  conexao.SQL.Add('join produto as prod on prod.codigo = pi.id_produto');
  conexao.SQL.Add('where pi.id_ingredientes in (' + Ingredientes + ')');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      Custo := Dados.FieldByName('custo_new').AsFloat;
      conexao.SQL.Add
        ('SELECT * FROM cmv where codigo_produto = :id and data_final is null');
      conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
      DadosIngrediente := TFDMemTable.Create(nil);
      DadosIngrediente.LoadFromJSON(conexao.ConsultaSQL);

      if Dados.FieldByName('custo_old').AsFloat <>
        Dados.FieldByName('custo_new').AsFloat then
      begin

        Objeto := TJSONObject.Create;
        Objeto.AddPair('id', Dados.FieldByName('id').AsInteger);
        Objeto.AddPair('old', Dados.FieldByName('custo_old').AsFloat);
        Objeto.AddPair('new', Dados.FieldByName('custo_new').AsFloat);
        Objeto.AddPair('economy', Dados.FieldByName('custo_old').AsFloat -
          Dados.FieldByName('custo_new').AsFloat);
        Objeto.AddPair('name', Dados.FieldByName('nome').AsString);
        Objeto.AddPair('qtd', 1);
        Objeto.AddPair('type', 'Produto');
        Result.Add(Objeto);

        CustoIndireto := DadosIngrediente.FieldByName
          ('custo_indiretos').AsFloat;
        Custo := Custo + CustoIndireto;

        Valor := ((Custo * DadosIngrediente.FieldByName('percentual_lucro')
          .AsFloat) / 100) + Custo;
        ValorCartao :=
          ((Valor * DadosIngrediente.FieldByName('percentual_cartao')
          .AsFloat) / 100);
        ValorImposto :=
          (((Valor + ValorCartao) * DadosIngrediente.FieldByName
          ('percentual_imposto').AsFloat) / 100);
        ValorIfood :=
          (((Valor + ValorCartao + ValorImposto) * DadosIngrediente.FieldByName
          ('percentual_ifood').AsFloat) / 100);
        ValorSugerido := Valor + ValorCartao + ValorImposto;
        ValorLucro := ValorSugerido - Custo;

        conexao.SQL.Add
          ('update cmv set data_final = current_timestamp where codigo_produto = :produto and data_final is null');
        conexao.Parametros('produto', Dados.FieldByName('id').AsInteger);
        conexao.ExecuteSQL;

        conexao.SQL.Add
          ('insert into cmv (codigo_produto,custo_ingrediente,custo_indiretos,percentual_imposto,percentual_cartao,percentual_ifood,percentual_lucro,valor_imposto,valor_cartao,valor_ifood,valor_lucro,preco_sugerido)');
        conexao.SQL.Add
          ('values (:produto,:ingrediente,:indiretos,:imposto,:cartao,:ifood,:lucro,:valorimposto,:valorcartao,:valorifood,:valorlucro,:precosugerido)');
        conexao.Parametros('produto', Dados.FieldByName('id').AsInteger);
        conexao.Parametros('ingrediente', Custo);
        conexao.Parametros('indiretos', CustoIndireto);
        conexao.Parametros('imposto',
          DadosIngrediente.FieldByName('percentual_imposto').AsFloat);
        conexao.Parametros('cartao',
          DadosIngrediente.FieldByName('percentual_cartao').AsFloat);
        conexao.Parametros('ifood',
          DadosIngrediente.FieldByName('percentual_ifood').AsFloat);
        conexao.Parametros('lucro',
          DadosIngrediente.FieldByName('percentual_lucro').AsFloat);
        conexao.Parametros('valorimposto', ValorImposto);
        conexao.Parametros('valorcartao', ValorCartao);
        conexao.Parametros('valorifood', ValorIfood);
        conexao.Parametros('valorlucro', ValorLucro);
        conexao.Parametros('precosugerido', ValorSugerido);
        conexao.ExecuteSQL;

        conexao.SQL.Add
          ('update produto ser valor_custo = :custo where codigo = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('id').AsInteger);
        conexao.Parametros('custo', Custo);
        conexao.ExecuteSQL;

      end;

      Dados.Next;
    end;
  end;

  conexao.Free;
end;

procedure MovimentacaoInsulmo(CodigoInsulmo, Tipo: Integer;
Quantidade, CustoTotal, Custo: Real; EntradaEstoque: Boolean);
var
  conexao: Tconexao;
  DadosFicha: TFDMemTable;
  QuantidadeFicha: Real;
  PercentualFicha: Real;
  ID: Integer;
  Ultimo: Real;
  Media: Real;
  TipoInsulmo: Integer;
begin
  conexao := Tconexao.Create('MovimentacaoInsulmo');
  DadosFicha := TFDMemTable.Create(nil);

  conexao.SQL.Add('select * from ingredientes where id = :id');
  conexao.Parametros('id', CodigoInsulmo);
  QuantidadeFicha := conexao.FieldByName('quantidade');

  try
    PercentualFicha := (Quantidade / QuantidadeFicha) * 100;
  except

  end;
  TipoInsulmo := 2;
  if Tipo = 2 then
  begin
    Quantidade := Quantidade * -1;
    TipoInsulmo := 1;
  end;

  if not EntradaEstoque then
    TipoInsulmo := Tipo;

  ID := conexao.GerarID('ingredientes_estoque', 'id');

  conexao.SQL.Add
    ('update ingredientes set saldo = COALESCE(saldo, 0) + :saldo where id = :id_ingredientes');
  conexao.Parametros('id_ingredientes', CodigoInsulmo);
  conexao.Parametros('saldo', Quantidade);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('insert into ingredientes_estoque (id,id_ingredientes,data,hora,tipo,quantidade,custo_total,custo) values (:id,:id_ingredientes,current_date,current_time,:tipo,:quantidade,:custo_total,:custo)');
  conexao.Parametros('id', ID);
  conexao.Parametros('id_ingredientes', CodigoInsulmo);
  conexao.Parametros('tipo', Tipo);
  conexao.Parametros('quantidade', Quantidade);
  conexao.Parametros('custo_total', CustoTotal);
  conexao.Parametros('custo', Custo);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('select 0 as zero, sum(custo) / count(custo) as media from ingredientes_estoque where tipo = 1 and id_ingredientes = :id_ingredientes and custo > 0');
  conexao.Parametros('id_ingredientes', CodigoInsulmo);
  Media := conexao.FieldByName('media');

  conexao.SQL.Add
    ('select 0 as zero, custo from ingredientes_estoque where tipo = 1 and id_ingredientes = :id_ingredientes order by data desc, hora desc limit 1');
  conexao.Parametros('id_ingredientes', CodigoInsulmo);
  Ultimo := conexao.FieldByName('custo');

  if Tipo = 1 then
  begin
    if Custo = 0 then
    begin
      conexao.SQL.Add
        ('update ingredientes set custo_medio = :medio, custo_ultimo = :ultimo where id = :id');
    end
    else
    begin
      conexao.SQL.Add
        ('update ingredientes set custo = :custo, custo_medio = :medio, custo_ultimo = :ultimo where id = :id');
      conexao.Parametros('custo', Custo);
    end;

    conexao.Parametros('medio', Media);
    conexao.Parametros('ultimo', Ultimo);
    conexao.Parametros('id', CodigoInsulmo);
    conexao.ExecuteSQL;
  end;

  if PercentualFicha > 0 then
  begin
    conexao.SQL.Add
      ('select id_composicao, (quantidade * :percentual)/100 as quantidade from ingredientes_ficha where id_ingrediente = :id');
    conexao.Parametros('id', CodigoInsulmo);
    conexao.Parametros('percentual', PercentualFicha);
    DadosFicha.LoadFromJSON(conexao.ConsultaSQL);
    while not DadosFicha.Eof do
    begin
      MovimentacaoInsulmo(DadosFicha.FieldByName('id_composicao').AsInteger,
        TipoInsulmo, DadosFicha.FieldByName('quantidade').AsFloat, 0, 0, false);
      DadosFicha.Next;
    end;

  end;
  DadosFicha.Free;
  conexao.Free;
end;

procedure MovimentacaoProduto(Codigo, Tipo: Integer; Quantidade: Real);
var
  conexao: Tconexao;
  ID: Integer;
  SaldoAtual: Integer;
  SaldoNovo: Integer;
  Status: Integer;
  Dados: TFDMemTable;
begin
  conexao := Tconexao.Create('Util');
  SaldoAtual := 0;
  SaldoNovo := 0;
  if (Tipo <> 1) and (Quantidade > 0) then
  begin
    Quantidade := Quantidade * -1;

    // Subtrai
    conexao.SQL.Add
      ('update produto set saldo_atual = IFNULL(saldo_atual, 0) + :qtd where codigo = :codigo');
    conexao.Parametros('codigo', Codigo);
    conexao.Parametros('qtd', Quantidade);
    conexao.ExecuteSQL;

  end
  else
  begin
    // Adiciona
    conexao.SQL.Add
      ('update produto set saldo_atual = IFNULL(saldo_atual, 0) + :qtd where codigo = :codigo');
    conexao.Parametros('codigo', Codigo);
    conexao.Parametros('qtd', Quantidade);
    conexao.ExecuteSQL;

  end;

  // Fazer ativar/pausar produto aki

  ID := conexao.GerarID('produto_estoque', 'codigo');
  conexao.SQL.Add
    ('insert into produto_estoque (codigo,data,hora,operacao,codigo_produto,quantidade,saldo_novo,saldo_atual) values (:codigo,current_date,current_time,:operacao,:codigo_produto,:quantidade,:saldo_novo,:saldo_atual)');
  conexao.Parametros('codigo', ID);
  conexao.Parametros('operacao', Tipo);
  conexao.Parametros('quantidade', Quantidade);
  conexao.Parametros('codigo_produto', Codigo);
  conexao.Parametros('saldo_novo', SaldoNovo);
  conexao.Parametros('saldo_atual', SaldoAtual);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('select codigo, saldo_atual from produto where codigo = :codigo');
  conexao.Parametros('codigo', Codigo);

  try
    Quantidade := conexao.FieldByName('saldo_atual');
  except
    Quantidade := 0;
  end;

  if Quantidade > 0 then
  begin
    // Ativa
    Status := 1;
  end
  else
  begin
    // Inativa
    Status := 0;

  end;

  Dados := TFDMemTable.Create(nil);

  if (Codigo > 0) then
  begin
    conexao.SQL.Add
      ('update pro_adi_personalizado_sabores set ativo = :status, modificado_site = 0 where id_prod_estoque = :codigo');
    conexao.Parametros('codigo', Codigo);
    conexao.Parametros('status', Status);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add
    ('select p.codigo, p.controle_estoque from pro_adi_personalizado_sabores as paps');
  conexao.SQL.Add
    ('join pro_adi_personalizado as pap on pap.id = paps.id_pro_adi_personalizado');
  conexao.SQL.Add('join produto as p on p.codigo = pap.id_produto');
  conexao.SQL.Add('where paps.id_prod_estoque = :codigo');
  conexao.Parametros('codigo', Codigo);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      if Dados.FieldByName('controle_estoque').AsInteger = 1 then
      begin
        conexao.SQL.Add
          ('update produto set ativo = :status, modificado_site = 0 where codigo = :codigo');
        conexao.Parametros('codigo', Codigo);
        conexao.Parametros('status', Status);
        conexao.ExecuteSQL;
        conexao.SQL.Add
          ('update produto set modificado_site = 0 where codigo = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        conexao.ExecuteSQL;
      end;
      Dados.Next;
    end;
  end;

  Dados.Free;

  conexao.Free;
  LimpaCacheGeral;
end;

procedure ApagarProduto(ID: Integer; Motivo: String; CodigoUsuario: Integer);
var
  conexao: Tconexao;
  Dados: TFDMemTable;

  Codigo: Integer;
  Valor: Real;

  ValorTotal: Real;
  ValorSubTotal: Real;
  Produto: Integer;
  Pedido: Integer;
  Quantidade: Real;
begin
  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('SELECT * FROM pedido_produtos where codigo = :codigo');
  conexao.Parametros('codigo', ID);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  Valor := Dados.FieldByName('valor_total').AsFloat;
  Codigo := Dados.FieldByName('codigo_pedido').AsInteger;

  conexao.SQL.Add('select * from mesa where selecionada = :codigo');
  conexao.Parametros('codigo', Codigo);

  ValorTotal := conexao.FieldByName('tot_mesa');
  ValorTotal := ValorTotal - Valor;

  conexao.SQL.Add
    ('update mesa set tot_mesa = :valor where selecionada = :codigo');
  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('valor', ValorTotal);
  conexao.ExecuteSQL;

  if not(ValorTotal > 0) then
  begin
    conexao.SQL.Add
      ('update mesa set tot_mesa = 0, sts_mesa = 0, selecionada = 0 where selecionada = :codigo');
    conexao.Parametros('codigo', Codigo);
    conexao.ExecuteSQL;
  end;

  Produto := Dados.FieldByName('codigo_produto').AsInteger;
  Pedido := ID;
  Quantidade := Dados.FieldByName('quantidade').AsFloat;
  Dados.Free;
  TThread.CreateAnonymousThread(
    procedure
    begin

      MovimentacaoProduto(Produto, 1, Quantidade);

      Dados := TFDMemTable.Create(nil);
      conexao.SQL.Add
        ('select produto_ingredientes.id_ingredientes, (produto_ingredientes.quantidade * pedido_produtos.quantidade) as quantidade, produto_ingredientes.id_produto as produto  from pedido');
      conexao.SQL.Add
        ('join pedido_produtos on pedido_produtos.codigo_pedido = pedido.codigo and pedido_produtos.codigo = :codigo');
      conexao.SQL.Add
        ('join produto_ingredientes on produto_ingredientes.id_produto = pedido_produtos.codigo_produto');
      conexao.Parametros('codigo', Pedido);
      Dados.LoadFromJSON(conexao.ConsultaSQL);

      if Dados.RecordCount > 0 then
      begin
        while not Dados.Eof do
        begin

          MovimentacaoInsulmo(Dados.FieldByName('id_ingredientes').AsInteger, 1,
            Dados.FieldByName('quantidade').AsFloat, 0, 0, false);

          Dados.Next;
        end;
      end;
      Dados.Free;
      Dados := TFDMemTable.Create(nil);

      conexao.SQL.Add
        ('select pro_adi_personalizado_sabores.id_ingredientes as ingredientes, pro_adi_personalizado_sabores.quantidade_ingredientes as quantidade from pedido');
      conexao.SQL.Add
        ('join pedido_produtos on pedido_produtos.codigo_pedido = pedido.codigo and pedido_produtos.codigo = :codigo');
      conexao.SQL.Add
        ('join pedido_produto_sap on pedido_produto_sap.codigo_pedido_produto = pedido_produtos.codigo');
      conexao.SQL.Add
        ('join pro_adi_personalizado on pro_adi_personalizado.id_produto = pedido_produtos.codigo_produto and upper(pro_adi_personalizado.descricao) = upper(pedido_produto_sap.nomeclatura)');
      conexao.SQL.Add
        ('join pro_adi_personalizado_sabores on pro_adi_personalizado_sabores.id_pro_adi_personalizado = pro_adi_personalizado.id and');
      conexao.SQL.Add
        ('upper(pro_adi_personalizado_sabores.nome) = upper(pedido_produto_sap.descricao) and pro_adi_personalizado_sabores.id_ingredientes <> 0');
      conexao.SQL.Add
        ('and pro_adi_personalizado_sabores.quantidade_ingredientes <> 0');
      conexao.Parametros('codigo', Pedido);
      Dados.LoadFromJSON(conexao.ConsultaSQL);

      if Dados.RecordCount > 0 then
      begin
        while not Dados.Eof do
        begin

          MovimentacaoInsulmo(Dados.FieldByName('ingredientes').AsInteger, 1,
            Dados.FieldByName('quantidade').AsFloat, 0, 0, false);

          Dados.Next;
        end;
      end;
      Dados.Free;

      conexao.SQL.Add
        ('update pedido_produtos set id_pedido = codigo_pedido, usuario_deletado = :usuario where codigo = :codigo');
      conexao.Parametros('codigo', ID);
      conexao.Parametros('usuario', CodigoUsuario);
      conexao.ExecuteSQL;

      conexao.SQL.Add
        ('update pedido_produtos set codigo_pedido = -1, datahora_deletado = current_timestamp, observacao = :obs where codigo = :codigo');
      conexao.Parametros('codigo', ID);
      conexao.Parametros('obs', Motivo);
      conexao.ExecuteSQL;
      conexao.Free;

    end).start();

end;

function ExtractNumberFromURL(const URL: string): string;
var
  Pattern: string;
  RegEx: TRegEx;
  Match: TMatch;
begin
  // Defina o padrão de expressão regular para encontrar o número na URL
  Pattern := '\/payments\/(\d+)\/';

  // Inicialize a expressão regular e busque a correspondência na URL
  RegEx := TRegEx.Create(Pattern);
  Match := RegEx.Match(URL);

  // Se houver uma correspondência, retorne o número encontrado
  if Match.Success then
    Result := Match.Groups[1].Value
  else
    Result := '';
  // Ou você pode lançar uma exceção ou definir uma mensagem de erro
end;


//
// function EnviaProduto(Codigo: Integer): Integer;
// var
//
// SQL: String;
// // codigo: Integer;
// Dados: TFDMemTable;
//
// Descricao: String;
// conexao: TConexao;
// begin
// conexao := TConexao.Create('Util');
// Dados := TFDMemTable.Create(nil);
//
// SQL := 'SELECT p.saldo_atual as estoque, p.foto_ifood, p.codigo,p.codigo_interno, p.nome_produto as produto, p.descricao, p.valor_venda as venda, p.id_site, p.ativo,p.valor_embalagem_delivery as vl_embalagem_delivery, ';
// SQL := SQL +
// 'tipo_produto.id_site as categoria,produto_pizza.quantidade_sabores, pessoas, valor_desconto, percentual_desconto ';
// SQL := SQL +
// 'FROM produto as p join tipo_produto on tipo_produto.codigo = p.codigo_grupo ';
// SQL := SQL +
// ' left join produto_pizza on produto_pizza.codigo_produto = p.codigo ';
// SQL := SQL + ' where p.codigo = ' + Codigo.ToString;
// Dados.LoadFromJSON(conexao.ConsultaSQL(SQL));
//
// if Dados.RecordCount = 0 then
// begin
// Dados.Free;
// exit;
// end;
// Dados.First;
//
// while not Dados.Eof do
// begin
// Descricao := Dados.FieldByName('descricao').AsString;
// if not Dados.FieldByName('quantidade_sabores').IsNull then
// begin
// case Dados.FieldByName('quantidade_sabores').AsInteger of
// 1:
// begin
// Descricao := '1 Sabor - ' + Dados.FieldByName('descricao').AsString;
// end
// else
// Descricao := Dados.FieldByName('quantidade_sabores').AsString +
// ' Sabores - ' + Dados.FieldByName('descricao').AsString;
// end;
// //
//
// Dados.Edit;
// Dados.FieldByName('venda').AsInteger := 0;
// Dados.Post;
// end;
//
// try
// // foto_ifood        > img_ifood
//
// case Dados.FieldByName('id_site').AsInteger of
// 0:
// begin
// Codigo := InserirUpdate('ws_itens', frmServidor.UserID.ToString,
// ['id', 'user_id', 'img_item', 'config_total_s', 'dia_semana',
// 'number_adicional', 'number_adicional_pago', 'posicao', 'id_cat',
// 'nome_item', 'descricao_item', 'preco_item', 'disponivel',
// 'valor_delivery', 'estoque', 'img_ifood', 'pessoas',
// 'promo_valor', 'promo_percentual'],
// [Dados.FieldByName('id_site').AsString,
// frmServidor.UserID.ToString, 'false', '0',
// 'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado', '0', '0',
// Dados.FieldByName('codigo_interno').AsString,
// Dados.FieldByName('categoria').AsString,
// Dados.FieldByName('produto').AsString, Descricao,
// Dados.FieldByName('venda').AsString, Dados.FieldByName('ativo')
// .AsString, Dados.FieldByName('vl_embalagem_delivery').AsString,
// Dados.FieldByName('estoque').AsString,
// Dados.FieldByName('foto_ifood').AsString,
// Dados.FieldByName('pessoas').AsString,
// Dados.FieldByName('valor_desconto').AsString,
// Dados.FieldByName('percentual_desconto').AsString]);
// end
// else
// begin
// Codigo := InserirUpdate('ws_itens', frmServidor.UserID.ToString,
// ['id', 'user_id', 'config_total_s', 'number_adicional',
// 'number_adicional_pago', 'posicao', 'id_cat', 'nome_item',
// 'descricao_item', 'preco_item', 'disponivel', 'valor_delivery',
// 'estoque', 'img_ifood', 'pessoas', 'promo_valor',
// 'promo_percentual'], [Dados.FieldByName('id_site').AsString,
// frmServidor.UserID.ToString, '0', '0', '0',
// Dados.FieldByName('codigo_interno').AsString,
// Dados.FieldByName('categoria').AsString,
// Dados.FieldByName('produto').AsString, Descricao,
// Dados.FieldByName('venda').AsString, Dados.FieldByName('ativo')
// .AsString, Dados.FieldByName('vl_embalagem_delivery').AsString,
// Dados.FieldByName('estoque').AsString,
// Dados.FieldByName('foto_ifood').AsString,
// Dados.FieldByName('pessoas').AsString,
// Dados.FieldByName('valor_desconto').AsString,
// Dados.FieldByName('percentual_desconto').AsString]);
// end;
// end;
// except
// Codigo := InserirUpdate('ws_itens', frmServidor.UserID.ToString,
// ['id', 'user_id', 'img_item', 'config_total_s', 'dia_semana',
// 'number_adicional', 'number_adicional_pago', 'posicao', 'id_cat',
// 'nome_item', 'descricao_item', 'preco_item', 'disponivel',
// 'valor_delivery', 'estoque', 'img_ifood', 'pessoas', 'promo_valor',
// 'promo_percentual'], [Dados.FieldByName('id_site').AsString,
// frmServidor.UserID.ToString, 'false', '0',
// 'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado', '0', '0',
// Dados.FieldByName('codigo_interno').AsString,
// Dados.FieldByName('categoria').AsString, Dados.FieldByName('produto')
// .AsString, Descricao, Dados.FieldByName('venda').AsString,
// Dados.FieldByName('ativo').AsString,
// Dados.FieldByName('vl_embalagem_delivery').AsString,
// Dados.FieldByName('estoque').AsString, Dados.FieldByName('foto_ifood')
// .AsString, Dados.FieldByName('pessoas').AsString,
// Dados.FieldByName('valor_desconto').AsString,
// Dados.FieldByName('percentual_desconto').AsString]);
// end;
//
// if Codigo > 0 then
// begin
// SQL := 'update produto set modificado_site = 1 where codigo = ' +
// Dados.FieldByName('codigo').AsString;
// conexao.ExecuteSQL(SQL);
// // Insert.ExecutaSQL(SQL);
// SQL := 'update produto set id_site = ' + Codigo.ToString +
// ' where codigo = ' + Dados.FieldByName('codigo').AsString;
// // Insert.ExecutaSQL(SQL);
// if not Dados.FieldByName('quantidade_sabores').IsNull then
// begin
//
// SQL := 'update from ws_sabores where id_itens = ' + Codigo.ToString +
// ' and user_id = ' + frmServidor.UserID.ToString + ' and qtd_sabor = '
// + Dados.FieldByName('quantidade_sabores').AsString;
// conexao.ExecuteSQL(SQL);
// end;
// end
// else
// begin
// // // tabLog.Visible := True;
// // frmPrincipal.AdicionaLog('Produto ' + Dados.FieldByName('codigo_interno')
// // .AsString + ' - ' + Dados.FieldByName('produto').AsString +
// // ', não foi enviado!');
// // SQL := 'update produto set modificado_site = 1 where codigo = ' +
// // Dados.FieldByName('codigo').AsString;
// // Insert.ExecutaSQL(SQL);
// end;
//
// Dados.Next;
// end;
// Dados.Free;
// conexao.Free;
// end;

procedure FaturarPedido(Codigo, Caixa: Integer);
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Descricao: String;
begin
  Dados := TFDMemTable.Create(nil);

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add('select p.*, tp.*');
  conexao.SQL.Add('from pedido as p');
  conexao.SQL.Add('join cliente as cc on cc.codigo = p.codigo_cliente');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add('where p.codigo = :id');
  conexao.Parametros('id', Codigo);

  Dados.LoadFromJSON(conexao.ConsultaSQL);
  if Dados.RecordCount > 0 then
  begin
    Dados.First;

    while not Dados.Eof do
    begin
      if Dados.FieldByName('id_caixa').AsString = '0' then
      begin
        Descricao := '#' + FormatFloat('000000', Dados.FieldByName('codigo')
          .AsInteger) + ' - ';
        Descricao := Descricao + 'PAGAMENTO TOTAL ' +
          Dados.FieldByName('descricao').AsString + ' AUTOMÁTICO';
        MovimentoCaixa(Caixa, Dados.FieldByName('codigo').AsInteger,
          Dados.FieldByName('tipo_pagamento').AsInteger, 1,
          Dados.FieldByName('valor_total_pedido').AsFloat, Descricao, 0);

        conexao.SQL.Add('update pedido set status = 6 where codigo = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        conexao.ExecuteSQL;

        try
          {
            if frmServidor.Configuracoes.FieldByName('nfce').AsInteger > 0 then
            begin
            conexao.SQL.Add
            ('update pedido set nfce_emite = 1 where codigo = :pedido');
            conexao.Parametros('pedido', Dados.FieldByName('codigo').AsInteger);
            conexao.ExecuteSQL;
            end; }
        except

        end;

      end;

      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;

end;

procedure GravaMarketing(Cliente: Integer; Valor: Real; Validade: Integer);
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('insert into marketing (data,validade,cupom,valor,pedido,status,id_cliente) values (current_date,:validade,upper(md5(concat(current_time,'
    + Cliente.ToString + FloatToStr(Valor) + '))),:valor,0,0,:id_cliente)');
  conexao.Parametros('id_cliente', Cliente);
  conexao.Parametros('valor', Valor);
  conexao.Parametros('validade', FormatDateTime('yyyy-mm-dd', Date + Validade));
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure GerarCupom;
var
  I: Integer;
  conexao: Tconexao;
  Dados: TFDMemTable;
begin
  try

    if frmServidor.Configuracoes.FieldByName('marketin').AsInteger = 0 then
      exit;

    if frmServidor.Configuracoes.FieldByName('marketin_' + DiaAtualAbreviado)
      .AsInteger = 0 then
      exit;
  except
    exit;
  end;

  conexao := Tconexao.Create('Util');
  conexao.SQL.Add
    ('select count(*) as tot, 0 as zero from marketing where data = current_date');
  try
    if conexao.FieldByName('tot') > 0 then
    begin
      conexao.Free;
      exit;
    end;
  except

  end;

  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('WITH MediaPedidos AS (');
  conexao.SQL.Add('  SELECT COUNT(*) / COUNT(*) AS media ');
  conexao.SQL.Add('  FROM pedido ');
  conexao.SQL.Add
    ('  WHERE data_pedido BETWEEN DATE_SUB(CURDATE(), INTERVAL 3 MONTH) AND CURDATE() ');
  conexao.SQL.Add('  AND status > 0 ');
  conexao.SQL.Add('  AND id_ficha IS NULL');
  conexao.SQL.Add(')');
  conexao.SQL.Add(', OrdenadoPorQuantidade AS (');
  conexao.SQL.Add('  SELECT ');
  conexao.SQL.Add('    COUNT(*) AS quantidade, ');
  conexao.SQL.Add('    SUM(valor_total_pedido) AS tot, ');
  conexao.SQL.Add('    codigo_cliente');
  conexao.SQL.Add('  FROM pedido ');
  conexao.SQL.Add
    ('  WHERE data_pedido BETWEEN DATE_SUB(CURDATE(), INTERVAL 3 MONTH) AND CURDATE() ');
  conexao.SQL.Add('  AND status > 0 ');
  conexao.SQL.Add('  AND id_ficha IS NULL');
  conexao.SQL.Add('  GROUP BY codigo_cliente');
  // conexao.sql.add('  HAVING COUNT(*) > (SELECT media FROM MediaPedidos)');

  if (frmServidor.Configuracoes.FieldByName('marketin_segmento').AsInteger = 1)
  then
  begin
    conexao.SQL.Add('HAVING COUNT(*) > (SELECT media FROM MediaPedidos)');
  end;

  if (frmServidor.Configuracoes.FieldByName('marketin_segmento').AsInteger = 2)
  then
  begin
    conexao.SQL.Add('HAVING COUNT(*) < (SELECT media FROM MediaPedidos)');
  end;

  conexao.SQL.Add('  ORDER BY COUNT(*) DESC');
  conexao.SQL.Add(')');
  conexao.SQL.Add('SELECT * ');
  conexao.SQL.Add('FROM (');
  conexao.SQL.Add('  SELECT * ');
  conexao.SQL.Add('  FROM OrdenadoPorQuantidade ');
  conexao.SQL.Add('  ORDER BY RAND()');
  conexao.SQL.Add(') AS Aleatorio');
  conexao.SQL.Add('LIMIT ' + frmServidor.Configuracoes.FieldByName
    ('marketin_qtd').AsString);

  Dados.LoadFromJSON(conexao.ConsultaSQL);

  while not Dados.Eof do
  begin
    // GravaMarketing(Cliente: Integer; Valor: Real; Validade: Integer);
    GravaMarketing(Dados.FieldByName('codigo_cliente').AsInteger,
      frmServidor.Configuracoes.FieldByName('marketin_desc').AsFloat, 1);
    Dados.Next;
  end;

  Dados.Free;
  conexao.Free;

  // for I := 0 to frmServidor.Configuracoes.FieldByName('marketin_qtd')
  // .AsInteger do
  // begin
  //
  // case frmServidor.Configuracoes.FieldByName('marketin_segmento').AsInteger of
  // 0:
  // begin
  // // Ambos
  //
  // end;
  // 1:
  // begin
  // // Mais Pedidos
  // end;
  // // Menos Pedidos
  // end;
  //
  // end;

end;

function DiaAtualAbreviado: string;
var
  Dia: Integer;
begin
  Dia := DayOfWeek(Now);
  case Dia of
    1:
      Result := 'dom'; // Domingo
    2:
      Result := 'seg'; // Segunda-feira
    3:
      Result := 'ter'; // Terça-feira
    4:
      Result := 'qua'; // Quarta-feira
    5:
      Result := 'qui'; // Quinta-feira
    6:
      Result := 'sex'; // Sexta-feira
    7:
      Result := 'sab'; // Sábado
  else
    Result := '';
  end;
end;

procedure EnviarCupom;
var
  Requisicao: iRequisicao;
  Body: String;
  conexao: Tconexao;
  Dados: TFDMemTable;
begin

  conexao := Tconexao.Create('Util');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT * FROM marketing where validade > current_date() and status = 0');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    conexao.Free;
    exit;
  end;
  try
    Requisicao := iRequisicao.Create(nil);

    Requisicao.BaseURL := 'https://ws.goopedir.com/v1/';
    Requisicao.URL := 'insert/cupom_desconto/' +
      frmServidor.UserID.ToString + '/a';
    Requisicao.Metodo := mPost;

    while not Dados.Eof do
    begin
      Body := '{"id_cupom":"0", "user_id":"' + frmServidor.UserID.ToString +
        '", "ativacao":"' + Dados.FieldByName('cupom').AsString +
        '", "type_discount":"2", "porcentagem":"0", "fixed_value":"' +
        Dados.FieldByName('valor').AsString + '", "data_validade":"' +
        COPY(Dados.FieldByName('validade').AsString, 0, 10) +
        '", "total_vezes":"1", "mostrar_site":"1", "valor_min":"' +
        frmServidor.Configuracoes.FieldByName('marketin_min').AsString + '" }';
      Requisicao.Body(Body);
      Requisicao.TempoExpiracao := 30 * 1000;
      Requisicao.Execute;

      if Requisicao.Status = 200 then
      begin
        conexao.SQL.Add('update marketing set status = 1 where id = :id');
        conexao.Parametros('id', Dados.FieldByName('id').AsString);
        conexao.ExecuteSQL;
      end;
      Dados.Next;
    end;
  except

  end;

  Dados.Free;
  conexao.Free;

end;

procedure LimparPastas(const Caminho: string);
var
  pastas: TStringDynArray;
  pasta: string;
begin
  try
    pastas := TDirectory.GetDirectories(Caminho);
    for pasta in pastas do
    begin
      TDirectory.Delete(pasta, true);
      // O segundo parâmetro indica que deve excluir todos os arquivos e subpastas
    end;
  except

  end;
end;

procedure LimparCacheProduto;
var
  conexao: Tconexao;
  Caminho: String;
  SearchRec: TSearchRec;
  Arquivo: string;
  Requisicao: iRequisicao;
begin
  conexao := Tconexao.Create('Util');

  conexao.SQL.Add('select 0 as zero, caminho_cache from dados_whatsapp');
  try
    Caminho := conexao.FieldByName('caminho_cache');
  except

  end;
  if Caminho <> '' then
  begin
    LimparPastas(Caminho);
  end;
  conexao.Free;
end;

procedure AdicionaProduto(Body: String; Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: Tconexao;
  JSONArray: TJSONArray;
  JsonObj: TJSONObject;
  I: Integer;
  mesa: Integer;
  Produto: Integer;
  qtd: Real;
  Adicionais: string;
  Pizza: string; // Usando Variant para aceitar null
  Observacao: string;
  Pedido: Integer;
  ValorProduto: Double;
  ValoresPizza: TValoresPizza;

  CodigoPedidoProduto: Integer;
  ValorAdicional: Real;

  QRY: TFDQuery;
  CodigoAux: Integer;
  ImprimirInsta: Boolean;
  Html: String;
  Usuario: Integer;
  CampoHora: String;
  UUID: String;
  ID: TGUID;

begin
  try
    ImprimirInsta := false;
    conexao := Tconexao.Create('Util');
    QRY := conexao.CriaQRY;

    JSONArray := TJSONObject.ParseJSONValue(Body) as TJSONArray;
    if Assigned(JSONArray) then
    begin
      for I := 0 to JSONArray.Count - 1 do
      begin
        CodigoPedidoProduto := conexao.GerarID('pedido_produtos', 'codigo');

        JsonObj := JSONArray.Items[I] as TJSONObject;

        mesa := JsonObj.GetValue<Integer>('mesa');
        try
          Usuario := JsonObj.GetValue<Integer>('usuario');
        except
          Usuario := -8;
        end;
        Produto := JsonObj.GetValue<Integer>('produto');
        qtd := JsonObj.GetValue<Real>('qtd');
        Adicionais := JsonObj.GetValue<string>('adicionais');
        try
          UUID := JsonObj.GetValue<string>('uuid');
        except

        end;
        try
          Pizza := JsonObj.GetValue<string>('pizza'); // Pode ser null
        except

        end;

        Observacao := JsonObj.GetValue<string>('observacao');
        Pedido := JsonObj.GetValue<Integer>('pedido');
        ValorProduto := JsonObj.GetValue<Double>('valorProduto');
        ValorAdicional := JsonObj.GetValue<Double>('valorAdicional');
        Html := JsonObj.GetValue<string>('html');

        if Pizza <> '' then
        begin

          ValoresPizza := AdicionaPizza(Pizza, conexao.CriaQRY, conexao.CriaQRY,
            CodigoPedidoProduto, conexao);

          if ValoresPizza.ValorProduto > 0 then
            ValorProduto := ValoresPizza.ValorProduto;

        end
        else
        begin
          conexao.SQL.Add
            ('select codigo, valor_venda from produto where codigo = :codigo');
          conexao.Parametros('codigo', Produto);
          try
            ValorProduto := conexao.FieldByName('valor_venda');
          except

          end;
        end;

        if Pedido = 0 then
        begin
          if mesa > 0 then
          begin
            QRY.Close;
            QRY.SQL.Clear;
            QRY.SQL.Add('select * from mesa where id_mesa = :id');
            QRY.ParamByName('id').AsInteger := mesa;
            QRY.Open;
            if QRY.RecordCount > 0 then
            begin
              Pedido := QRY.FieldByName('selecionada').AsInteger;
              if QRY.FieldByName('selecionada').AsFloat > 0 then
              begin
                CampoHora := 'hora';
              end
              else
              begin
                CampoHora := 'current_timestamp()';
              end;

            end;
          end;

          if Pedido = 0 then
          begin
            Pedido := NovoPedido(conexao.GerarID('pedido', 'codigo'), mesa,
              conexao.CriaQRY);
          end;

        end;

        if UUID = '' then
        begin
          CreateGUID(ID);
          UUID := GUIDToString(ID);
        end;

        conexao.SQL.Add('select * from pedido_produtos where uuid = :uuid');
        conexao.Parametros('uuid', UUID);
        CodigoAux := conexao.FieldByName('codigo');
        if CodigoAux = 0 then
        begin
          conexao.SQL.Clear;
          conexao.SQL.Add
            ('insert into pedido_produtos (codigo,codigo_pedido,codigo_produto,valor_unitario,quantidade,valor_total,valor_adicional,impresso,html,usuario,uuid)');
          conexao.SQL.Add
            ('values (:codigo,:codigo_pedido,:codigo_produto,:valor_unitario,:quantidade,:valor_total,:valor_adicional,:impresso,:html,:usuario,:uuid)');
          conexao.Parametros('codigo', CodigoPedidoProduto);
          conexao.Parametros('codigo_pedido', Pedido);
          conexao.Parametros('codigo_produto', Produto);
          conexao.Parametros('valor_unitario', ValorProduto);
          conexao.Parametros('quantidade', qtd);
          conexao.Parametros('valor_total',
            (ValorProduto + ValorAdicional) * qtd);
          conexao.Parametros('valor_adicional', ValorAdicional * qtd);
          conexao.Parametros('usuario', Usuario);
          conexao.Parametros('impresso', '0');
          conexao.Parametros('html', Html);
          conexao.Parametros('uuid', UUID);
          conexao.ExecuteSQL;

          if Observacao <> '' then
          begin
            CodigoAux := conexao.GerarID('pedido_produto_sap', 'id');
            conexao.SQL.Add
              ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor,tipo_valor) value (:id,:codigo_pedido_produto,0,:nomeclatura,:descricao,:valor,:tipo_valor)');
            conexao.Parametros('id', CodigoAux);
            conexao.Parametros('codigo_pedido_produto', CodigoPedidoProduto);
            conexao.Parametros('nomeclatura', 'OBSERVAÇÃO');
            conexao.Parametros('descricao', Observacao);
            conexao.Parametros('valor', 0);
            conexao.Parametros('tipo_valor', '0');
            conexao.ExecuteSQL;
          end;

          TThread.CreateAnonymousThread(
            procedure
            var

              I: Integer;
              conexao: Tconexao;
            begin
              conexao := Tconexao.Create('Util');
              if Adicionais <> '' then
              begin
                ValorAdicional := Adiciona(Adicionais, conexao.CriaQRY,
                  conexao.CriaQRY, CodigoPedidoProduto, conexao);
              end;

              try
                if mesa > 0 then
                begin
                  if CampoHora = '' then
                    CampoHora := 'current_timestamp()';
                  conexao.SQL.Add
                    ('update mesa set sts_mesa = 1, tot_mesa = tot_mesa + :tot, hora = '
                    + CampoHora + ' where id_mesa = :id');
                  conexao.Parametros('tot',
                    (ValorProduto + ValorAdicional) * qtd);
                  conexao.Parametros('id', mesa);
                  conexao.ExecuteSQL;
                end;

                conexao.SQL.Add
                  ('select 0 as zero, codigo_pedido_dia as codigo from pedido where codigo = :codigo');
                conexao.Parametros('codigo', Pedido);
                ImprimirInsta := conexao.FieldByName('codigo') > 0;

                CodigoAux := conexao.GerarID('impressao_pedido_produto', 'id');
                conexao.SQL.Add
                  ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:pedido,:status,0,:usuario)');
                conexao.Parametros('id', CodigoAux);
                conexao.Parametros('pedido', CodigoPedidoProduto);

                if ImprimirInsta then
                begin
                  conexao.Parametros('status', 0);
                end
                else
                begin
                  conexao.Parametros('status',
                    frmServidor.Configuracoes.FieldByName('impressao_agrupada')
                    .AsInteger);
                end;
                conexao.Parametros('usuario', Usuario);
                conexao.ExecuteSQL;
                AtualizaValorPedido(Pedido);
                MovimentoProduto(CodigoPedidoProduto, 1);
              except
                on E: Exception do
                begin
                  conexao.GerarLog(E.Message);
                end;
              end;
              conexao.Free;
            end).start();
        end;
        JsonObj.Free;
      end;
    end;
    try
      conexao.Free;
    except

    end;
  except
    on E: Exception do
    begin
      Res.Send(E.Message)
    end;

  end;
end;

function CapitalizeFirstLetter(const Input: string): string;
var
  I: Integer;
  ToUpper: Boolean;
begin
  Result := LowerCase(Input); // Primeiro, colocamos tudo em minúsculas
  ToUpper := true;
  for I := 1 to length(Result) do
  begin
    if ToUpper and (Result[I] <> ' ') then
    begin
      Result[I] := UpCase(Result[I]); // Converte para maiúscula
      ToUpper := false;
    end
    else if Result[I] = ' ' then
    begin
      ToUpper := true; // Ativa para maiúscula a próxima letra após o espaço
    end;
  end;
end;

function AdicionaPizza(Pizza: string; QRY, QRYINSERT: TFDQuery;
CodigoPedidoItem: Integer; conexao: Tconexao): TValoresPizza;
var
  Adicionais: TArray<string>;
  I: Integer;
  ValorProduto, ValorPizza, ValorAux: Real;
  QuantidadeSabores: Integer;
  Descricao: string;
  CodigoAux: Integer;
  TipoPreco: Integer;
begin

  if VarIsEmpty(Pizza) or (VarToStr(Pizza) = 'null') then
    exit;

  Adicionais := SplitString(VarToStr(Pizza), ',');

  Result.Sabores := '<p><b>Sabores:<b></p>';
  ValorProduto := 0;
  ValorAux := 0;
  for I := 0 to length(Adicionais) - 1 do
  begin
    QRY.Close;
    QRY.SQL.Text :=
      'SELECT pp.quantidade_sabores, sc.nome, sc.vl_venda, sc.id, ' +
      '(SELECT tipo_preco_pizza FROM dados_whatsapp LIMIT 1) as tipo_preco ' +
      'FROM produto_pizza AS pp ' +
      'JOIN sabores_completo AS sc ON sc.id_produto = pp.codigo_produto ' +
      'WHERE sc.id IN (' + Adicionais[I] + ') ' +
      'ORDER BY sc.id_tipo_sabor, sc.nome';
    QRY.Open;

    while not QRY.Eof do
    begin
      QuantidadeSabores := ValidaQuantidadeSabores(Pizza,
        QRY.FieldByName('id').AsString);
      Descricao := '1/' + IntToStr(QRY.RecordCount) + ' - ';

      TipoPreco := QRY.FieldByName('tipo_preco').AsInteger;

      case TipoPreco of
        0:
          begin
            // Media
            ValorPizza := (QRY.FieldByName('vl_venda').AsFloat /
              length(Adicionais));
          end;
        1:
          begin
            // Maior
            if QRY.FieldByName('vl_venda').AsFloat > ValorProduto then
              ValorProduto := QRY.FieldByName('vl_venda').AsFloat;

            ValorPizza := 0;
          end;
        2:
          begin
            // Soma
            ValorPizza := QRY.FieldByName('vl_venda').AsFloat;
          end;
      end;

      ValorAux := ValorAux + ValorPizza;
      CodigoAux := conexao.GerarID('pedido_produto_sap', 'id');

      QRYINSERT.SQL.Text :=
        'INSERT INTO pedido_produto_sap (id, codigo_pedido_produto, tipo, nomeclatura, descricao, valor, tipo_valor) '
        + 'VALUES (:id, :codigo_pedido_produto, 0, :nomeclatura, :descricao, :valor, :tipo_valor)';
      QRYINSERT.ParamByName('id').AsInteger := CodigoAux;
      QRYINSERT.ParamByName('codigo_pedido_produto').AsInteger :=
        CodigoPedidoItem;
      QRYINSERT.ParamByName('nomeclatura').AsString := 'SABORES';
      QRYINSERT.ParamByName('descricao').AsString :=
        QRY.FieldByName('nome').AsString;
      QRYINSERT.ParamByName('valor').AsFloat := ValorPizza;
      QRYINSERT.ParamByName('tipo_valor').AsInteger := TipoPreco;
      QRYINSERT.ExecSQL;

      Result.Sabores := Result.Sabores + '<i>' + QRY.FieldByName('nome')
        .AsString + '</i><br>';

      QRY.Next;
    end;

    Result.ValorAdicional := ValorAux;
    case TipoPreco of
      1:
        begin
          // Logic for TipoPreco 1 if needed
        end
    else
      begin
        ValorProduto := ValorAux;
        Result.ValorProduto := ValorProduto;
        Result.ValorAdicional := 0;
      end;
    end;

    // QRY.SQL.Text := 'UPDATE pedido_produtos SET valor_total = :valor_total WHERE codigo = :codigo';
    // QRY.ParamByName('valor_total').AsFloat := (ValorProduto + ValorAdicional) * Quantidade;
    // QRY.ParamByName('codigo').AsString := CodigoPedidoItem;
    // QRY.ExecSQL;
  end;

  QRY.Free;
  QRYINSERT.Free;

end;

function Adiciona(Adicionais: Variant; QRY, QRYINSERT: TFDQuery;
CodigoPedidoProduto: Integer; conexao: Tconexao): Real;
var
  I: Integer;
  ValorAdicional: Real;
  IDs: TArray<string>;
  Codigo: Integer;
begin
  ValorAdicional := 0;
  try
    IDs := SplitString(Adicionais, ',');
    for I := 0 to High(IDs) do
    begin
      QRY.SQL.Text := 'SELECT paps.id, paps.nome, pap.descricao, paps.valor ' +
        'FROM pro_adi_personalizado_sabores as paps ' +
        'JOIN pro_adi_personalizado as pap ON pap.id = paps.id_pro_adi_personalizado '
        + 'WHERE paps.id in (:AdicionalId)';
      QRY.ParamByName('AdicionalId').AsString := IDs[I];

      try

        QRY.Open;

        QRY.First;
        while not QRY.Eof do
        begin
          Codigo := conexao.GerarID('pedido_produto_sap', 'id');
          // Inserir os dados do adicional no pedido
          with QRYINSERT do
            try

              SQL.Text :=
                'INSERT INTO pedido_produto_sap (id,codigo_pedido_produto, tipo, nomeclatura, descricao, valor, tipo_valor) '
                + 'VALUES (:id,:codigo_pedido_produto, 0, :nomeclatura, :descricao, :valor, :tipo_valor)';
              ParamByName('id').AsInteger := Codigo;
              ParamByName('codigo_pedido_produto').AsInteger :=
                CodigoPedidoProduto;
              ParamByName('nomeclatura').AsString :=
                QRY.FieldByName('descricao').AsString;
              ParamByName('descricao').AsString :=
                QRY.FieldByName('nome').AsString;
              ParamByName('valor').AsFloat := QRY.FieldByName('valor').AsFloat;
              ParamByName('tipo_valor').AsInteger := 0;

              ExecSQL;

            finally

            end;

          // Atualizar o valor adicional
          ValorAdicional := ValorAdicional + QRY.FieldByName('valor').AsFloat;
          QRY.Next;
        end;

      except
        on E: Exception do
        begin
          // //showmessage1(e.Message)
        end;
      end;

      QRY.Close;
    end;

  finally
    QRY.Free;
    QRYINSERT.Free;
  end;
  Result := ValorAdicional;
end;

function NovoPedido(CodigoPedido, mesa: Integer; QRY: TFDQuery): Integer;
var
  DescricaoMesa: String;
begin
  QRY.SQL.Text := 'select concat(mt.descricao, ' + QuotedStr(' ') +
    ', m.nr_mesa) as descricao, 0 as zero ' +
    'from mesa as m join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa ' +
    'where m.id_mesa = :codigo';

  QRY.ParamByName('codigo').AsInteger := mesa;
  QRY.Open;
  DescricaoMesa := QRY.FieldByName('descricao').AsString;
  QRY.Close;

  // Inserção do pedido
  QRY.SQL.Text :=
    'insert into pedido (codigo, codigo_pedido_dia, codigo_cliente, codigo_cliente_endereco, '
    + 'data_pedido, hora_pedido, status, valor_pedido, valor_desconto, valor_taxa_entrega, '
    + 'valor_total_pedido, observacao_geral, troco, tipo_pagamento, pedido_impresso, origem, '
    + 'desc_ficha, id_ficha, ficha_faturada) ' +
    'values (:codigo, :codigo_pedido_dia, :codigo_cliente, :codigo_endereco, :data_pedido, '
    + ':hora_pedido, :status, :valor_pedido, :valor_desconto, :valor_taxa_entrega, :valor_total_pedido, '
    + ':observacao_geral, :troco, :tipo_pagamento, :pedido_impresso, :origem, :desc_ficha, '
    + ':id_ficha, :ficha_faturada)';
  QRY.ParamByName('codigo').AsInteger := CodigoPedido;
  QRY.ParamByName('codigo_pedido_dia').AsInteger := 0;
  QRY.ParamByName('codigo_cliente').AsInteger := 0;
  QRY.ParamByName('codigo_endereco').AsInteger := 0;
  QRY.ParamByName('data_pedido').AsDate := Date;
  QRY.ParamByName('hora_pedido').AsTime := time;
  QRY.ParamByName('status').AsInteger := -1;
  QRY.ParamByName('valor_pedido').AsFloat := 0;
  QRY.ParamByName('valor_taxa_entrega').AsFloat := 0;
  QRY.ParamByName('valor_desconto').AsFloat := 0;
  QRY.ParamByName('valor_total_pedido').AsFloat := 0;
  QRY.ParamByName('observacao_geral').AsString := '';
  QRY.ParamByName('troco').AsFloat := 0;
  QRY.ParamByName('tipo_pagamento').AsInteger := 0;
  QRY.ParamByName('pedido_impresso').AsInteger := 0;

  if mesa > 0 then
    QRY.ParamByName('origem').AsInteger := 3
  else
    QRY.ParamByName('origem').AsInteger := 4;

  QRY.ParamByName('desc_ficha').AsString := DescricaoMesa;
  QRY.ParamByName('id_ficha').AsInteger := mesa;
  QRY.ParamByName('ficha_faturada').AsInteger := mesa;
  QRY.ExecSQL;

  // Atualização da mesa

  if mesa > 0 then
  begin
    QRY.SQL.Text :=
      'update mesa set hora = current_timestamp(), tot_mesa = 0, selecionada = :pedido where id_mesa = :mesa';
    QRY.ParamByName('pedido').AsInteger := CodigoPedido;
    QRY.ParamByName('mesa').AsInteger := mesa;
    QRY.ExecSQL;
    // update mesa set hora = current_timestamp(), tot_mesa = 0
  end;

  QRY.Free;
  Result := CodigoPedido;
end;

function UnionPedio(Tabela, Tipo: String): String;
var
  SQL: String;
begin
  SQL := ' select p.troco,';
  SQL := SQL + ' p.codigo as codigo, p.id_caixa as id_caixa,';
  SQL := SQL + ' codigo_pedido_dia as codigo_dia,';
  SQL := SQL + ' codigo_cliente,';
  SQL := SQL + ' CASE';
  SQL := SQL +
    '  WHEN (SELECT nome FROM cliente WHERE codigo = codigo_cliente) = ' +
    QuotedStr('BALCÃO') + ' AND p.nome <> ''''';
  SQL := SQL + '  THEN p.nome';
  SQL := SQL +
    '  ELSE (SELECT nome FROM cliente WHERE codigo = codigo_cliente)';
  SQL := SQL + ' END AS cliente,';
  SQL := SQL +
    ' (select celular from cliente where codigo = codigo_cliente) as celular,';
  SQL := SQL +
    ' (select cpf from cliente where codigo = codigo_cliente) as documento,';
  SQL := SQL + ' codigo_cliente_endereco as cliente_endereco,';
  SQL := SQL + ' (SELECT ';
  SQL := SQL + ' upper(concat(rua,' + QuotedStr(' - ') + ',numero,' +
    QuotedStr(' [ ') + ',bairro,' + QuotedStr(' / ') + ',cidade,' +
    QuotedStr(' ] ') + ')) ';
  SQL := SQL +
    ' FROM cliente_endereco where codigo = codigo_cliente_endereco) as endereco_completo,';
  SQL := SQL + ' DATE_FORMAT(data_pedido,' + QuotedStr('%d/%m/%Y') +
    ') as data,';
  SQL := SQL + ' (hora_pedido) as hora,';
  SQL := SQL + ' cast(timediff(current_timestamp,concat(data_pedido,' +
    QuotedStr(' ') + ',hora_pedido)) as char) as tempo,';
  SQL := SQL + ' p.status,';
  SQL := SQL +
    ' (select descricao from status_pedido where id = p.status) status_descricao,';
  SQL := SQL + ' REPLACE(valor_pedido, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as valor,';
  SQL := SQL + ' REPLACE(valor_taxa_entrega, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as taxa,';
  SQL := SQL + ' REPLACE(valor_desconto, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as desconto,';
  SQL := SQL + ' REPLACE(valor_total_pedido, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as total,';
  SQL := SQL + ' tipo_pagamento as pagamento,';
  SQL := SQL + ' motivo_cancelamento,';
  SQL := SQL +
    ' pedido_site as pedidosite, id_caixa as caixa, id_ficha as ficha,';
  SQL := SQL + ' origem,';
  SQL := SQL + ' CASE';
  SQL := SQL + '     WHEN codigo_cliente_endereco = 0 THEN "Vem Buscar"';
  SQL := SQL + '      WHEN id_ficha > 0 THEN "Ficha"';
  SQL := SQL + '     ELSE "Delivery"';
  SQL := SQL + '     END as tipo,';
  SQL := SQL + ' upper(m.nome) as motoboy,';
  SQL := SQL + ' p.id_ifood,';
  SQL := SQL + ' p.status_ifood,';
  SQL := SQL + ' p.status_ifood_descricao,';
  SQL := SQL + ' p.order_ifood,';
  SQL := SQL + '  p.desc_desconto_ifood,';
  SQL := SQL + '  p.estimada_ifood as estimada_ifood,';
  SQL := SQL + '  p.agendada_ifood as agendada_ifood,';
  SQL := SQL + '  p.order_ifood,';
  SQL := SQL +
    '  (select descricao from tipo_pagamento where codigo = p.tipo_pagamento limit 1) as pagamento';
  SQL := SQL + ' from ' + Tabela + ' as p';
  SQL := SQL + ' left join pedido_motoboy as pm on pm.codigo_pedido = p.codigo';
  SQL := SQL + ' left join motoboy as m on m.codigo = pm.codigo_motoboy';
  SQL := SQL +
    ' where data_pedido between :inicial and :final and p.status > -1 and origem in ('
    + Tipo + ')';
  // SQL := SQL + ' order by data_pedido desc,codigo_pedido_dia';
  Result := SQL;
end;

end.
