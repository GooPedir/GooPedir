unit util;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer;

procedure Registry;
function GetBuildInfo: string;
function TransformaData(Data: String): TDate;
function TransformaHora(Hora: String): TTime;
function TrocaVirgula(Resultado: String): String;
procedure MovimentoCaixa(Caixa, Pedido, TipoPagamento, Tipo: Integer;
  Valor: Real; Descricao: String);
procedure GerarReceber(Caixa, Pedido, TipoPagamento: Integer; Valor: Real);
function SQLFormatdaDataMysql(Campo: String): String;
function SQLFormatdaHoraMysql(Campo: String): String;
function SQLFormatdaValorMysql(Campo: String): String;
function ValidaQuantidadeSabores(Sabores, Codigo: String): Integer;

procedure SalvarImagenBase64(base64, Caminho: String);

function NonoDigito(Celular: String): String;
function GeraCodigoPorDiaPedido(Pedido: Integer): Integer;
function RemoveAcento(const pText: string): string;

implementation

uses FireDAC.Stan.Option, token, conexao, JOSE.Types.JSON, System.Classes,
  Data.DB, IdWinsock2, Vcl.Dialogs, Vcl.ExtCtrls, Horse.Upload, System.Types,
  Winapi.Windows, uMain, System.StrUtils, Vcl.StdCtrls;

procedure DoGetMesas(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  mesa: Integer;
  SQL: String;
begin
  try
    mesa := Req.Params['mesa'].ToInteger;

  except
    mesa := 0;
  end;
  conexao := TConexao.Create;
  if length(SQL) > 0 then
  begin
    conexao.SQL.Add(SQL);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add('SELECT * FROM mesa as m');
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

procedure DoGetCategoria(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;

  // conexao.SQL.Add('SELECT tp.* FROM tipo_produto as tp');
  // conexao.SQL.Add('order by ordem asc');
  conexao.SQL.Add
    ('SELECT tp.* FROM tipo_produto as tp inner join produto as p on p.codigo_grupo = tp.codigo where p.ativo = 1 and p.valor_venda > 0');
  conexao.SQL.Add('GROUP BY tp.codigo order by ordem asc');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoGetProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
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

  conexao := TConexao.Create;
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
  conexao: TConexao;
  Busca: String;
begin

  try
    Busca := UpperCase(Req.Params['busca']);
  except
    // Res.Send('').Status(500);
    // exit;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
  ID: Integer;
begin

  try
    ID := Req.Params['produto'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  // conexao.SQL.Add('select * from produto  as p');
  conexao.SQL.Add
    ('select paps.id as codigo, pap.descricao as categoria, paps.nome, paps.valor, p.observacao, qtd_minima as min, qtd_maxima as max from produto as p');
  conexao.SQL.Add
    ('inner join pro_adi_personalizado as pap on pap.id_produto = p.codigo');
  conexao.SQL.Add
    ('inner join pro_adi_personalizado_sabores as paps on paps.id_pro_adi_personalizado = pap.id');
  conexao.SQL.Add
    ('where p.codigo = :codigo order by paps.id_pro_adi_personalizado');
  conexao.Parametros('codigo', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoGetTest(Req: THorseRequest; Res: THorseResponse; Next: TProc);

begin
  Res.Send('OK');
end;

procedure DoGetMesa(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  mesa: Integer;
  SQL: String;
begin
  try
    mesa := Req.Params['mesa'].ToInteger;
    SQL := 'update mesa set sts_mesa = 1 where nr_mesa = ' + mesa.ToString;
  except
    mesa := 0;
  end;
  conexao := TConexao.Create;
  if length(SQL) > 0 then
  begin
    conexao.SQL.Add(SQL);
    conexao.ExecuteSQL;
  end;
  conexao.SQL.Add
    ('SELECT *, (select codigo from pedido where id_ficha = m.id_mesa and status = -1 order by codigo desc limit 1) as pedido FROM mesa as m');
  conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
  conexao.SQL.Add('where m.ativo = 1 and mt.ativo = 1');
  if mesa > 0 then
  begin
    conexao.SQL.Add('and id_mesa = ' + mesa.ToString);
  end;
  conexao.SQL.Add('order by mt.id_mesa_tipo, m.nr_mesa');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoPostPedidoProduto(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  DadosProdutos: TFDMemTable;
  DadosProdutosAdicionais: TFDMemTable;
  DadosProdutosSabores: TFDMemTable;

  mesa: Integer;
  CodigoPedido: Integer;
  CodigoProduto: Integer;
  CodigoPedidoItem: Integer;
  ValorProduto: Real;
  ValorAdicional: Real;
  Adicional: String;
  Pizza: String;
  Quantidade: Integer;
  Observacao: String;
  CodigoAux: Integer;

  Descricao: String;
  ValorAux: Real;
  ValorSabor: Real;
  DescricaoMesa: String;
  StatusImpressao: Integer;
  QuantidadeSabores: Integer;
  Usuario: Integer;
  I: Integer;
  ValorPizza: Real;

  Adicionais: TStringDynArray;
begin
  Dados := TFDMemTable.Create(nil);
  try
    Dados.LoadFromJSON(Req.Body);
  except
    Res.Send('').Status(500);
    Dados.Free;
    exit;
  end;
  try
    Usuario := Req.Params['usuario'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  mesa := Dados.FieldByName('mesa').AsInteger;
  try
    CodigoPedido := Dados.FieldByName('pedido').AsInteger;
  except
    CodigoPedido := 0;
  end;
  CodigoProduto := Dados.FieldByName('produto').AsInteger;
  Adicional := Dados.FieldByName('adicionais').AsString;
  Quantidade := Dados.FieldByName('qtd').AsInteger;
  Pizza := Dados.FieldByName('pizza').AsString;
  DadosProdutos := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from produto where codigo = :codigo');
  conexao.Parametros('codigo', CodigoProduto);
  DadosProdutos.LoadFromJSON(conexao.ConsultaSQL);
  ValorProduto := DadosProdutos.FieldByName('valor_venda').AsFloat;
  Observacao := Dados.FieldByName('observacao').AsString;

  conexao.SQL.Add('select concat(mt.descricao,' + QuotedStr(' ') +
    ',m.nr_mesa) as descricao, 0 as zero from mesa as m');
  conexao.SQL.Add
    ('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa where m.id_mesa = :codigo');
  conexao.Parametros('codigo', mesa);
  DescricaoMesa := conexao.FieldByName('descricao');

  CodigoPedidoItem := conexao.GerarID('pedido_produtos', 'codigo');

  DadosProdutosAdicionais := TFDMemTable.Create(nil);
  DadosProdutosSabores := TFDMemTable.Create(nil);
  ValorAux := 0;
  if length(Pizza) > 0 then
  begin
    Pizza := Pizza;

    Adicionais := SplitString(Pizza, ',');
    for I := 0 to length(Adicionais) - 1 do
    begin
      DadosProdutosSabores.Close;
      conexao.SQL.Add
        ('SELECT pp.quantidade_sabores, sc.nome, sc.vl_venda, sc.id, (SELECT tipo_preco_pizza FROM dados_whatsapp limit 1) as tipo_preco FROM produto_pizza as pp');
      conexao.SQL.Add
        ('join sabores_completo as sc on sc.id_produto = pp.codigo_produto');
      conexao.SQL.Add('where sc.id in (' + Adicionais[I] + ')');
      conexao.SQL.Add('order by sc.id_tipo_sabor, sc.nome');
      DadosProdutosSabores.LoadFromJSON(conexao.ConsultaSQL);

      ValorProduto := 0;
      while not DadosProdutosSabores.Eof do
      begin
        QuantidadeSabores := ValidaQuantidadeSabores(Pizza,
          DadosProdutosSabores.FieldByName('id').AsString);
        Descricao := '1/' + DadosProdutosSabores.RecordCount.ToString + ' - ';
        case DadosProdutosSabores.FieldByName('tipo_preco').AsInteger of
          0:
            begin
              // Media
              ValorPizza := (DadosProdutosSabores.FieldByName('vl_venda')
                .AsFloat / length(Adicionais));
            end;
          1:
            begin
              // Maior
              ValorAux := 0;
              if DadosProdutosSabores.FieldByName('vl_venda').AsFloat > ValorProduto
              then
                ValorProduto := DadosProdutosSabores.FieldByName
                  ('vl_venda').AsFloat;

            end;
          2:
            begin
              // Soma
              ValorPizza :=
                (DadosProdutosSabores.FieldByName('vl_venda').AsFloat);
            end;

        end;
        ValorAux := ValorAux + ValorPizza;
        conexao.SQL.Add
          ('select max(id)+1 as id, 0 as zero from pedido_produto_sap');
        CodigoAux := conexao.FieldByName('id');

        conexao.SQL.Add
          ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor,tipo_valor) value (:id,:codigo_pedido_produto,0,:nomeclatura,:descricao,:valor,:tipo_valor)');
        conexao.Parametros('id', CodigoAux);
        conexao.Parametros('codigo_pedido_produto', CodigoPedidoItem);
        conexao.Parametros('nomeclatura', 'SABORES');
        conexao.Parametros('descricao',
          Descricao + DadosProdutosSabores.FieldByName('nome').AsString);
        conexao.Parametros('valor', ValorAux);
        conexao.Parametros('tipo_valor',
          DadosProdutosSabores.FieldByName('tipo_preco').AsInteger);
        conexao.ExecuteSQL;

        DadosProdutosSabores.Next;
      end;
    end;
    case DadosProdutosSabores.FieldByName('tipo_preco').AsInteger of
      1:
        begin

        end
    else
      begin
        ValorProduto := ValorAux;
      end;
    end;

  end;

  ValorProduto := Dados.FieldByName('valor_produto').AsFloat;

  while not DadosProdutosAdicionais.Eof do
  begin
    ValorAdicional := ValorAdicional + DadosProdutosAdicionais.FieldByName
      ('valor').AsFloat;
    DadosProdutosAdicionais.Next;
  end;

  if mesa > 0 then
  begin
    conexao.SQL.Add('select * from mesa where id_mesa = :id');
    conexao.Parametros('id', mesa);
    try
      CodigoPedido := conexao.FieldByName('selecionada');
    except
      CodigoPedido := 0;
    end;
  end;

  ValorAdicional := 0;
  Adicionais := SplitString(Adicional, ',');

  for I := 0 to length(Adicionais) - 1 do
  begin
    DadosProdutosAdicionais.Close;
    conexao.SQL.Add
      ('SELECT paps.id, paps.nome, pap.descricao, paps.valor FROM pro_adi_personalizado_sabores as paps join pro_adi_personalizado as pap on pap.id = paps.id_pro_adi_personalizado where paps.id in ('
      + Adicionais[I] + ')');
    try
      DadosProdutosAdicionais.LoadFromJSON(conexao.ConsultaSQL);
    except

    end;
    DadosProdutosAdicionais.First;
    while not DadosProdutosAdicionais.Eof do
    begin
      CodigoAux := conexao.GerarID('pedido_produto_sap', 'id');
      conexao.SQL.Add
        ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor,tipo_valor) value (:id,:codigo_pedido_produto,0,:nomeclatura,:descricao,:valor,:tipo_valor)');
      conexao.Parametros('id', CodigoAux);
      conexao.Parametros('codigo_pedido_produto', CodigoPedidoItem);
      conexao.Parametros('nomeclatura',
        DadosProdutosAdicionais.FieldByName('descricao').AsString);
      conexao.Parametros('descricao',
        DadosProdutosAdicionais.FieldByName('nome').AsString);
      conexao.Parametros('valor', DadosProdutosAdicionais.FieldByName
        ('valor').AsFloat);
      conexao.Parametros('tipo_valor', '0');
      conexao.ExecuteSQL;
      ValorAdicional := ValorAdicional + DadosProdutosAdicionais.FieldByName
        ('valor').AsFloat;
      DadosProdutosAdicionais.Next;
    end;
  end;

  if CodigoPedido = 0 then
  begin

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
    conexao.Parametros('data_pedido', FormatDateTime('yyyy-mm-dd', now));
    conexao.Parametros('hora_pedido', FormatDateTime('hh:mm:ss', now));
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
    conexao.Parametros('desc_ficha', DescricaoMesa);
    conexao.Parametros('id_ficha', mesa);
    conexao.Parametros('ficha_faturada', mesa);

    conexao.ExecuteSQL;

    conexao.SQL.Add
      ('update mesa set selecionada = :pedido where id_mesa = :mesa');
    conexao.Parametros('pedido', CodigoPedido);
    conexao.Parametros('mesa', mesa);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add
    ('insert into pedido_produtos (codigo,codigo_pedido,codigo_produto,valor_unitario,quantidade,valor_total,valor_adicional,impresso)');
  conexao.SQL.Add
    ('values (:codigo,:codigo_pedido,:codigo_produto,:valor_unitario,:quantidade,:valor_total,:valor_adicional,:impresso)');
  conexao.Parametros('codigo', CodigoPedidoItem);
  conexao.Parametros('codigo_pedido', CodigoPedido);
  conexao.Parametros('codigo_produto', CodigoProduto);
  conexao.Parametros('valor_unitario', ValorProduto);
  conexao.Parametros('quantidade', Quantidade);
  conexao.Parametros('valor_total', (ValorProduto + ValorAdicional) *
    Quantidade);
  conexao.Parametros('valor_adicional', ValorAdicional * Quantidade);
  conexao.Parametros('impresso', '0');
  conexao.ExecuteSQL;

  CodigoAux := conexao.GerarID('pedido_produto_sap', 'id');
  conexao.SQL.Add
    ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor,tipo_valor) value (:id,:codigo_pedido_produto,0,:nomeclatura,:descricao,:valor,:tipo_valor)');
  conexao.Parametros('id', CodigoAux);
  conexao.Parametros('codigo_pedido_produto', CodigoPedidoItem);
  conexao.Parametros('nomeclatura', 'OBSERVA«√O');
  conexao.Parametros('descricao', Observacao);
  conexao.Parametros('valor', 0);
  conexao.Parametros('tipo_valor', '0');
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('update mesa set sts_mesa = 1, tot_mesa = tot_mesa + :tot where id_mesa = :id');
  conexao.Parametros('tot', (ValorProduto + ValorAdicional) * Quantidade);
  conexao.Parametros('id', mesa);
  conexao.ExecuteSQL;

  CodigoAux := conexao.GerarID('impressao_pedido_produto', 'id');

  try
    StatusImpressao := conexao.GetParametro('app_impressao');
  except
    StatusImpressao := 1;
  end;

  conexao.SQL.Add
    ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:pedido,:status,0,:usuario)');
  conexao.Parametros('pedido', CodigoPedidoItem);
  conexao.Parametros('id', CodigoAux);
  conexao.Parametros('status', StatusImpressao);
  conexao.Parametros('usuario', Usuario);
  conexao.ExecuteSQL;

  if Assigned(conexao) then
    conexao.Free;
  if Assigned(Dados) then
    Dados.Free;
  if Assigned(DadosProdutos) then
    DadosProdutos.Free;
  if Assigned(DadosProdutosAdicionais) then
    DadosProdutosAdicionais.Free;
  if Assigned(DadosProdutosSabores) then
    DadosProdutosSabores.Free;

end;

procedure DoGetProdutoPedido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
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

  conexao := TConexao.Create;

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
  conexao: TConexao;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    ID := 0;
    Res.Send('').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

  conexao.SQL.Add('select CONCAT(nomeclatura,' + QuotedStr(' - ') +
    ',group_concat(descricao),' + QuotedStr(', ') +
    ') as dados, 0 as zero from pedido_produto_sap where codigo_pedido_produto = :id and descricao <> '
    + QuotedStr('') + ' group by nomeclatura');
  conexao.Parametros('id', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoPutFinalizaPedido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  mesa: Integer;
  Impressao: Integer;
  Desconto: Real;
  Acrecimo: Real;
  TipoPagamento: Integer;
  Taxa: Real;
  Caixa: Integer;

  DadosMesa: TFDMemTable;
  DadosCliente: TFDMemTable;
  CodigoCliente: Integer;
  Total: Real;
  CodigoPedido: Integer;
  Aux: Integer;
  CodigoPedidoDia: Integer;

  DadosPagamento: TFDMemTable;
  Descricao: String;
  CodigoAux: Integer;

begin
  try
    CodigoPedido := Req.Params['pedido'].ToInteger;
  except

    exit;
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
    Desconto := Req.Params['desconto'].ToDouble;
  except
    Res.Send('').Status(500);
    exit;
  end;

  try
    Acrecimo := Req.Params['acrecimo'].ToInteger;
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

  conexao := TConexao.Create;

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

    conexao.SQL.Add
      ('SELECT max(codigo_pedido_dia)+1 as max, 0 as zero FROM pedido where data_pedido = curdate()');

    try
      CodigoPedidoDia := conexao.FieldByName('max');
    except
      CodigoPedidoDia := 1;
    end;

    conexao.SQL.Add
      ('update pedido set hora_entregue = CURRENT_TIME(),codigo_pedido_dia = :pedidodia, status = 6, codigo_cliente = :cliente, valor_desconto = :desconto,');
    conexao.SQL.Add
      ('valor_taxa_entrega = :taxa, valor_total_pedido = :total,valor_pedido = :vlpedido, tipo_pagamento = :pag, id_ficha = :ficha, ficha_faturada = :fichafaturada, desc_ficha = :desc, pedido_site = desc_ficha');
    conexao.SQL.Add('where codigo = :codigo');
    conexao.Parametros('cliente', CodigoCliente);
    conexao.Parametros('desconto', Desconto);
    conexao.Parametros('taxa', Taxa);
    conexao.Parametros('total', Total);
    conexao.Parametros('vlpedido', Total);
    conexao.Parametros('pag', TipoPagamento);
    conexao.Parametros('ficha', DadosMesa.FieldByName('id_mesa').AsInteger);
    conexao.Parametros('pedidodia', CodigoPedidoDia);

    //
    conexao.Parametros('fichafaturada', DadosMesa.FieldByName('id_mesa')
      .AsInteger);
    conexao.Parametros('desc', DadosMesa.FieldByName('mesa').AsString);
    conexao.Parametros('codigo', CodigoPedido);
    conexao.ExecuteSQL;

    conexao.SQL.Add
      ('update mesa set sts_mesa = 0, tot_mesa = 0, selecionada = 0 where selecionada = :id');
    conexao.Parametros('id', CodigoPedido);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add('update pedido set status = 6 where codigo =:codigo');
  conexao.Parametros('codigo', CodigoPedido);
  conexao.ExecuteSQL;

  if Impressao = 1 then
  begin
    CodigoCliente := conexao.GerarID('impressao_pedido', 'id');
    conexao.SQL.Add
      ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
    conexao.Parametros('id', CodigoCliente);
    conexao.Parametros('pedido', CodigoPedido);
    conexao.ExecuteSQL;
  end;
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
    MovimentoCaixa(Caixa, CodigoPedido,
      DadosPagamento.FieldByName('ID_TIPO_PAGAMENTO').AsInteger, 1, Total,
      Descricao);

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

  if Assigned(DadosMesa) then
    DadosMesa.Free;

  if Assigned(DadosCliente) then
    DadosCliente.Free;

  DadosPagamento.Free;
  conexao.Free;
end;

procedure DoGetProdutoSabores(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  ID: Integer;
begin

  try
    ID := Req.Params['produto'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  // conexao.SQL.Add('select * from produto as p');
  conexao.SQL.Add
    ('SELECT pp.quantidade_sabores, sc.nome, sc.vl_venda, sc.id, (SELECT tipo_preco_pizza FROM dados_whatsapp limit 1) as tipo_preco FROM produto_pizza as pp');
  conexao.SQL.Add
    ('join sabores_completo as sc on sc.id_produto = pp.codigo_produto');
  conexao.SQL.Add('where sc.id_produto = :codigo');
  conexao.SQL.Add('order by sc.id_tipo_sabor, sc.nome');

  conexao.Parametros('codigo', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoDeletePedidoProduto(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  ID: Integer;
  Codigo: Integer;
  Valor: Real;

  ValorTotal: Real;
  ValorSubTotal: Real;
begin

  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('').Status(500);
    exit;
  end;
  conexao := TConexao.Create;
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
    ('update pedido_produtos set codigo_pedido = 0 where codigo = :codigo');
  conexao.Parametros('codigo', ID);
  conexao.ExecuteSQL;

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

  Dados.Free;
  conexao.Free;
end;

procedure DoGetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
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

  conexao := TConexao.Create;
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
  conexao: TConexao;
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
  conexao := TConexao.Create;
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
  conexao: TConexao;

  DataInicial: TDate;
  DataFinal: TDate;
  HoraInicial: TTime;
  HoraFinal: TTime;

begin
  conexao := TConexao.Create;

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
  conexao: TConexao;
  DataInicial: TDate;
  DataFinal: TDate;
  HoraInicial: TTime;
  HoraFinal: TTime;
  Tipo: String;
  Faturado: String;
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

  conexao := TConexao.Create;
  conexao.SQL.Add('select ');
  conexao.SQL.Add('p.codigo as codigo, p.id_caixa as id_caixa,');
  conexao.SQL.Add('codigo_pedido_dia as codigo_dia,');
  conexao.SQL.Add('codigo_cliente,');
  conexao.SQL.Add
    ('(select nome from cliente where codigo = codigo_cliente) as cliente,');
  conexao.SQL.Add('codigo_cliente_endereco as cliente_endereco,');
  conexao.SQL.Add('(SELECT ');
  conexao.SQL.Add('upper(concat(rua,' + QuotedStr(' - ') + ',numero,' +
    QuotedStr(' [ ') + ',bairro,' + QuotedStr(' / ') + ',cidade,' +
    QuotedStr(' ] ') + ')) ');
  conexao.SQL.Add
    ('FROM cliente_endereco where codigo = codigo_cliente_endereco) as endereco_completo,');
  conexao.SQL.Add('DATE_FORMAT(data_pedido,' + QuotedStr('%d/%m/%Y') +
    ') as data,');
  conexao.SQL.Add('(hora_pedido) as hora,');
  conexao.SQL.Add('cast(timediff(current_timestamp,concat(data_pedido,' +
    QuotedStr(' ') + ',hora_pedido)) as char) as tempo,');
  conexao.SQL.Add('p.status,');
  conexao.SQL.Add
    ('(select descricao from status_pedido where id = p.status) status_descricao,');
  conexao.SQL.Add('REPLACE(valor_pedido, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as valor,');
  conexao.SQL.Add('REPLACE(valor_taxa_entrega, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as taxa,');
  conexao.SQL.Add('REPLACE(valor_desconto, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as desconto,');
  conexao.SQL.Add('REPLACE(valor_total_pedido, ' + QuotedStr('.') + ', ' +
    QuotedStr(',') + ') as total,');
  conexao.SQL.Add('tipo_pagamento as pagamento,');
  conexao.SQL.Add('motivo_cancelamento,');
  conexao.SQL.Add
    ('pedido_site as pedidosite, id_caixa as caixa, id_ficha as ficha,');
  conexao.SQL.Add('origem,');
  conexao.SQL.Add('CASE');
  conexao.SQL.Add('    WHEN codigo_cliente_endereco = 0 THEN "Vem Buscar"    ');
  conexao.SQL.Add('     WHEN id_ficha > 0 THEN "Ficha"');
  conexao.SQL.Add('    ELSE "Delivery"');
  conexao.SQL.Add('    END as tipo,');
  conexao.SQL.Add('upper(m.nome) as motoboy');
  conexao.SQL.Add('from pedido as p');
  conexao.SQL.Add
    ('left join pedido_motoboy as pm on pm.codigo_pedido = p.codigo');
  conexao.SQL.Add('left join motoboy as m on m.codigo = pm.codigo_motoboy');
  conexao.SQL.Add
    ('where data_pedido between :inicial and :final and p.status > -1 and origem in ('
    + Tipo + ')');
  conexao.SQL.Add('order by data_pedido,codigo_pedido_dia limit 999');
  conexao.Parametros('inicial', FormatDateTime('yyyy-mm-dd', DataInicial));
  conexao.Parametros('final', FormatDateTime('yyyy-mm-dd', DataFinal));
  // ShowMessage(conexao.SQL.Text);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);

  conexao.Free;
end;

procedure DoGetCaixa(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Usuario: Integer;
begin

  try
    Usuario := Req.Params['usuario'].ToInteger;
  except
    Res.Send('Usu·rio n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add
    ('SELECT * FROM caixa where id_usuario = :caixa and status = 1');
  conexao.Parametros('caixa', Usuario);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostAberturaCaixa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Usuario: Integer;
  Valor: Real;
  Codigo: Integer;
  Dados: TFDMemTable;
begin

  try
    Usuario := Req.Params['usuario'].ToInteger;
  except
    Res.Send('Usu·rio n„o informado').Status(500);
    exit;
  end;

  try
    Valor := Req.Params['valor'].ToDouble;
  except
    Res.Send('valor n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  conexao := TConexao.Create;

  conexao.SQL.Add('select * from tipo_pagamento where ativo = 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostFaturarPeido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Caixa: Integer;
  SQL: String;
  ValorTotal: Real;
  Descricao: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa n„o informado').Status(500);
    exit;
  end;
  Dados := TFDMemTable.Create(nil);

  conexao := TConexao.Create;
  conexao.SQL.Add('select * from pedido as p');
  conexao.SQL.Add('join caixa as c on p.data_pedido >= c.data_abertura');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add
    ('where p.status > 0 and p.tipo_pagamento > 0 and id_caixa is null');
  conexao.SQL.Add('and c.id = :id');
  conexao.Parametros('id', Caixa);

  Dados.LoadFromJSON(conexao.ConsultaSQL);
  if Dados.RecordCount > 0 then
  begin
    Dados.First;

    while not Dados.Eof do
    begin
      Descricao := '#' + FormatFloat('000000', Dados.FieldByName('codigo')
        .AsInteger) + ' - ';
      Descricao := Descricao + 'PAGAMENTO TOTAL ' +
        Dados.FieldByName('descricao').AsString + ' AUTOM¡TICO';
      MovimentoCaixa(Caixa, Dados.FieldByName('codigo').AsInteger,
        Dados.FieldByName('tipo_pagamento').AsInteger, 1,
        Dados.FieldByName('valor_total_pedido').AsFloat, Descricao);

      conexao.SQL.Add('update pedido set status = 6 where codigo = :codigo');
      conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
      conexao.ExecuteSQL;

      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;
end;

procedure DoPostFechamentoCaixa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Caixa: Integer;
  SQL: String;
  ValorTotal: Real;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa n„o informado').Status(500);
    exit;
  end;
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    Res.Send('Pagamento n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

  ValorTotal := 0;
  while not Dados.Eof do
  begin

    MovimentoCaixa(Caixa, 0, Dados.FieldByName('id_tipo_pagamento').AsInteger,
      226, Dados.FieldByName('total').AsFloat, 'Computado');

    MovimentoCaixa(Caixa, 0, Dados.FieldByName('id_tipo_pagamento').AsInteger,
      262626, Dados.FieldByName('informado').AsFloat, 'Informado');
    ValorTotal := ValorTotal + Dados.FieldByName('informado').AsFloat;
    Dados.Next;
  end;

  conexao.SQL.Add
    ('update caixa set data_fechamento = current_date, hora_fechamento = current_time, status = 2, valor_fechamento = :valor where id = :codigo');
  conexao.Parametros('valor', ValorTotal);
  conexao.Parametros('codigo', Caixa);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetAReceber(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Cliente: Integer;
begin
  // codigo
  try
    Cliente := Req.Params['codigo'].ToInteger;
  except
    Cliente := 0;

  end;
  conexao := TConexao.Create;
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
    ('join tipo_pagamento as tp on tp.codigo = cr.id_tipo_pagamento');
  if Cliente > 0 then
  begin
    conexao.SQL.Add('where cr.id_cliente = :cliente');
    conexao.Parametros('cliente', Cliente);
  end;
  conexao.SQL.Add('order by cr.data, cr.hora desc');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetHistoricoCaixaTodos(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;

begin

  conexao := TConexao.Create;
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
  conexao: TConexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add
    ('select sum(cm.valor) as total, tp.descricao, cm.id_tipo_pagamento, 0 as informado from caixa_movimento as cm');
  conexao.SQL.Add
    ('join tipo_pagamento as tp on tp.codigo = cm.id_tipo_pagamento');
  conexao.SQL.Add('where cm.id_caixa = :codigo and cm.tipo = 1');
  conexao.SQL.Add('group by cm.id_tipo_pagamento');
  conexao.Parametros('codigo', Caixa);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetHistoricoCaixa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

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
  conexao: TConexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('select ');
  conexao.SQL.Add
    ('p.codigo, p.codigo_pedido_dia, p.data_pedido,p.hora_pedido, p.valor_pedido,p.valor_desconto,p.valor_taxa_entrega,p.valor_total_pedido,p.id_caixa,cc.nome');
  conexao.SQL.Add(' from caixa as c ');
  conexao.SQL.Add
    ('join pedido as p on p.data_pedido >= c.data_abertura and p.hora_pedido >= c.hora_abertura and p.status > 0  or p.id_caixa = c.id');
  conexao.SQL.Add('join cliente as cc on cc.codigo = p.codigo_cliente');
  conexao.SQL.Add('where c.id = :codigo');

  conexao.Parametros('codigo', Caixa);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetCaixaDados(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Caixa: Integer;
  SQL: String;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

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
  conexao: TConexao;
  Caixa: Integer;
  Valor: Real;
begin

  try
    Caixa := Req.Params['caixa'].ToInteger;
  except
    Res.Send('Caixa n„o informado').Status(500);
    exit;
  end;

  try
    Valor := Req.Params['valor'].ToDouble;
  except
    Res.Send('Valor n„o informado').Status(500);
    exit;
  end;

  MovimentoCaixa(Caixa, 0, 0, 2, Valor, 'SANGRIA');

end;

procedure DoGetAllCategoria(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;

  Res.Send(conexao.GetAll('tipo_produto'));
  conexao.Free;
end;

procedure DoPostProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
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

  conexao := TConexao.Create;
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
      ',ativo,observacao,adicional_personalizado,valor_embalagem_delivery,valor_embalagem_vembusca,usa_tabela_preco,atualizado,modificado_site) values ';
    SQL := SQL +
      '(:codigo,:interno,current_date,:nome,:descricao,:grupo,:venda,:ativo,1,1,:delivery,:vb,1,0,0)';
    Novo := True;
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
      'valor_embalagem_delivery = :delivery, valor_embalagem_vembusca = :vb, atualizado = 0, modificado_site = 0 where codigo = :codigo';
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
  conexao: TConexao;
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
      where := 'where lower(concat(p.codigo_interno,tp.descricao,p.nome_produto,p.descricao,p.valor_venda)) like "%'
        + where + '%"';
    end;
  except
    where := '';
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add
    ('SELECT p.codigo as id, p.descricao as observacaopro,p.ativo, p.codigo_interno as interno, tp.descricao, p.nome_produto as nome, p.valor_venda as venda, p.id_site as site,');
  conexao.SQL.Add
    ('p.modificado_site as modificado, p.valor_embalagem_delivery as delivery, p.valor_embalagem_vembusca as vb, p.descricao as descpro,p.codigo_grupo as categoria, pp.codigo as pizza,  pp.quantidade_sabores as quantidade FROM produto as p');
  conexao.SQL.Add('join tipo_produto as tp on tp.codigo = p.codigo_grupo');
  conexao.SQL.Add
    ('left join produto_pizza as pp on pp.codigo_produto = p.codigo');
  conexao.SQL.Add(where);
  conexao.SQL.Add('order by p.codigo_interno');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostIngredientes(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  ID: Integer;
  Aux: Integer;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
    exit;
  conexao := TConexao.Create;

  ID := conexao.GerarID('pro_adi_personalizado', 'id');

  conexao.SQL.Add
    ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima) values (:id,:id_produto,:descricao,1,0,:qtd_maxima)');
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
  conexao: TConexao;
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
    Res.Send('Descricao n„o informado').Status(500);
    exit;
  end;

  try
    Min := Req.Params['min'].ToInteger;
  except
    Res.Send('Min n„o informado').Status(500);
    exit;
  end;

  try
    Max := Req.Params['max'].ToInteger;
  except
    Res.Send('Max n„o informado').Status(500);
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

  conexao := TConexao.Create;
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
  conexao: TConexao;
  Codigo: Integer;
begin
  try
    Produto := Req.Params['id'].ToInteger;
  except
    Produto := 0;
  end;
  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  try
    Produto := Req.Params['id'].ToInteger;
  except
    Produto := 0;
  end;
  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  try
    Produto := Req.Params['id'].ToInteger;
  except
    Produto := 0;
  end;
  conexao := TConexao.Create;
  conexao.SQL.Add('select * from pro_adi_personalizado where id_produto = :id');
  conexao.Parametros('id', Produto);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetAllExtra(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
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
  conexao := TConexao.Create;
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
  conexao: TConexao;
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
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;

  try
    Extra := Req.Params['extra'].ToInteger;
  except
    Res.Send('Extra n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
  ID: Integer;
begin

  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;
  conexao := TConexao.Create;
  conexao.SQL.Add('SELECT * FROM produto_preco where id_produto = :id');
  conexao.Parametros('id', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostTabelaProduto(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Codigo: Integer;
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  conexao := TConexao.Create;

  Codigo := conexao.GerarID('produto_preco', 'id');
  Dados.First;
  while not Dados.Eof do
  begin

    if Dados.FieldByName('id').AsInteger = 0 then
    begin
      conexao.SQL.Add
        ('insert into produto_preco values (:id,:produto,:segunda,:terca,:quarta,:quinta,:sexta,:sabado,:domingo,:valor,:inicial,:final)');
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
  conexao: TConexao;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('delete from produto_preco where id = :id');
  conexao.Parametros('id', ID);

  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoGetProdutoCodigo(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  ID: Integer;
  conexao: TConexao;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;
  conexao := TConexao.Create;
  conexao.SQL.Add('select * from produto where codigo_interno like ' +
    QuotedStr('%' + ID.ToString) + ' or codigo like ' +
    QuotedStr('%' + ID.ToString));

  Res.Send(conexao.ConsultaSQL.ToString);
  conexao.Free;
end;

procedure DoDadosProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
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
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;

  Dados := TFDMemTable.Create(nil);
  DadosConsulta := TFDMemTable.Create(nil);
  conexao := TConexao.Create;

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
    Dados.FieldByName('tipo').AsString := 'PreÁo';
    Dados.FieldByName('extra').AsString := DIASEMANA;
    Dados.FieldByName('descricao').AsString :=
      COPY(DadosConsulta.FieldByName('hora_inicial').AsString, 0, 8) + ' atÈ ' +
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
  conexao: TConexao;
  ID: Integer;
  LocalImagem: String;
  Memo: TMemo;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;

  frmServidor.memoImagem.lines.Clear;
  LocalImagem := Caminho + '\produto\imagem\';
  Memo := TMemo.Create(nil);

  ForceDirectories(LocalImagem);
  LocalImagem := LocalImagem + ID.ToString + '.txt';

  TThread.CreateAnonymousThread(
    procedure
    begin
      Memo.lines.text := Req.Body;
      Memo.lines.SaveToFile(LocalImagem);
      Memo.lines.Clear;
      Memo.Free;
    end).Start;
  {
    try

    conexao := TConexao.Create;
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
  conexao: TConexao;
  ID: Integer;
  LocalImagem: String;

begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;
  frmServidor.memoImagem.lines.Clear;
  LocalImagem := Caminho + '\produto\imagem\' + ID.ToString + '.txt';

  if FileExists(LocalImagem) then
  begin
    frmServidor.memoImagem.lines.LoadFromFile(LocalImagem);
  end;
  Res.Send(frmServidor.memoImagem.lines.text);
end;

procedure DoGetAllExtraAlteracao(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
begin

  conexao := TConexao.Create;

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
  conexao: TConexao;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

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
  conexao: TConexao;

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
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;
  try
    Descricao := Req.Params['categoria'];
  except
    Res.Send('Descricao n„o informado').Status(500);
    exit;
  end;

  try
    Min := Req.Params['min'].ToInteger;
  except
    Res.Send('Min n„o informado').Status(500);
    exit;
  end;

  try
    Max := Req.Params['max'].ToInteger;
  except
    Res.Send('Max n„o informado').Status(500);
    exit;
  end;
  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  conexao := TConexao.Create;

  with conexao do
  begin
    SQL.Add('SELECT codigo,descricao,pizza,visivel_vem_buscar,visivel_delivery,id_site,impressora,ordem,modificado_site,(SELECT CONCAT(upper(descricao),'
      + QuotedStr(' (') + ',upper(driver),' + QuotedStr(')') +
      ') FROM impressoras where codigo = impressora) as descricao_impressora');
    SQL.Add('FROM tipo_produto');

  end;
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetPedidoProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
  Pedido: Integer;
begin
  try
    Pedido := Req.Params['pedido'].ToInteger;
  except
    Res.Send('Produto n„o informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add
    ('SELECT pp.codigo,p.nome_produto,pp.quantidade,pp.valor_total,concat(group_concat(pps.nomeclatura,'
    + QuotedStr(' ') + ',pps.descricao)) as obs, 0 as selecionado');
  conexao.SQL.Add('FROM pedido_produtos as pp');
  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  conexao.SQL.Add
    ('join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp.codigo');
  conexao.SQL.Add('where pp.codigo_pedido = :codigo');
  conexao.SQL.Add('group by pp.codigo');
  conexao.Parametros('codigo', Pedido);

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostImprimir(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Tipo: Integer;
  Codigo: Integer;
  Aux: Integer;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    Res.Send('CÛdigo N„o Informado').Status(500);
    exit;
  end;

  try
    Tipo := Req.Params['tipo'].ToInteger;
  except
    Res.Send('Tipo N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

  case Tipo of
    1:
      begin
        // Pedido
        Aux := conexao.GerarID('impressao_pedido_produto', 'id');
        conexao.SQL.Add
          ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
        conexao.Parametros('pedido', Codigo);
        conexao.Parametros('id', Aux);
        conexao.ExecuteSQL;

      end;
    2:
      begin
        // Pedido Produto

        Aux := conexao.GerarID('impressao_pedido_produto', 'id');
        conexao.SQL.Add
          ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date,current_time,:pedido,0,0);');
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
  conexao: TConexao;
begin

  conexao := TConexao.Create;
  conexao.SQL.Add('SELECT * FROM motoboy where ativo = 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPutPedidoMotoboy(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Pedido: Integer;
  Motoboy: Integer;
  Codigo: Integer;
begin
  try
    Pedido := Req.Params['pedido'].ToInteger;
  except
    Res.Send('Pedido N„o Informado').Status(500);
    exit;
  end;

  try
    Motoboy := Req.Params['motoboy'].ToInteger;
  except
    Res.Send('Motoboy N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

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
  conexao: TConexao;
  Pedido: Integer;
  Status: Integer;

begin
  try
    Pedido := Req.Params['pedido'].ToInteger;
  except
    Res.Send('Pedido N„o Informado').Status(500);
    exit;
  end;

  try
    Status := Req.Params['status'].ToInteger;
  except
    Res.Send('Status N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('update pedido set status = :status where codigo = :codigo');
  conexao.Parametros('codigo', Pedido);
  conexao.Parametros('status', Status);
  conexao.ExecuteSQL;

end;

procedure DoGetTodosCliente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;
  conexao.SQL.Add('select c.*, upper((select concat(ce.rua,' + QuotedStr(' N∫')
    + ',ce.numero,' + QuotedStr(' / ') + ',ce.bairro, ' + QuotedStr(' ') +
    ', ce.cidade,' + QuotedStr('-') +
    ',ce.estado) from cliente_endereco as ce where ce.codigo_cliente = c.codigo order by codigo desc limit 1 )) as endereco from cliente as c');
  conexao.SQL.Add('where c.celular > 99999');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetConsultaTodos(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  tabela: String;
begin

  try
    tabela := Req.Params['tabela'];
  except
    Res.Send('Tabela N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('SELECT * FROM ' + tabela);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostCategoriaAll(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
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
  conexao := TConexao.Create;
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
  conexao: TConexao;
  Dados: TFDMemTable;
  tabela: String;
  CampoID: String;
  I: Integer;
  ID: Integer;

  SQLInsert: String;
  SQLInsertValues: String;
  SQLUpdate: String;
  Insert: Boolean;
begin

  try
    tabela := Req.Params['tabela'];
  except
    Res.Send('Tabela N„o Informado').Status(500);
    exit;
  end;

  try
    CampoID := Req.Params['id'];
  except
    Res.Send('Campo PK N„o Informado').Status(500);
    exit;
  end;

  Dados := TFDMemTable.Create(nil);
  try
    Dados.LoadFromJSON(Req.Body);
  except
    Dados.Free;
    exit;
  end;

  conexao := TConexao.Create;
  Insert := Dados.FieldByName(CampoID).AsInteger = 0;

  if Insert then
    ID := conexao.GerarID(tabela, CampoID)
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
    SQLInsert := 'insert into ' + tabela + ' (' + SQLInsert + ') values (' +
      SQLInsertValues + ')';
    conexao.SQL.Add(SQLInsert);
  end
  else
  begin
    // Update
    SQLUpdate := 'update ' + tabela + ' set ' + SQLUpdate + ' where ' + CampoID
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
  conexao: TConexao;
  Celular: String;
begin
  try
    Celular := Req.Params['celular'];
  except
    Res.Send('Celular N„o Informado').Status(500);
    exit;
  end;
  conexao := TConexao.Create;

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
  conexao: TConexao;
begin
  conexao := TConexao.Create;

  conexao.SQL.Add('SELECT count(*) total, ');
  conexao.SQL.Add('(SELECT count(*)  FROM pedido');
  conexao.SQL.Add('where status = 0 and origem in (1,2) and data_pedido in (' +
    Req.Body + ')');
  conexao.SQL.Add(') as cancelado, ');
  conexao.SQL.Add('(SELECT count(*) FROM pedido');
  conexao.SQL.Add('where status >= 0 and origem in (1,2)and data_pedido in (' +
    Req.Body + ')');
  conexao.SQL.Add(') as todos,');
  conexao.SQL.Add('count(*) div 4 as media,');
  conexao.SQL.Add('(((SELECT count(*) FROM pedido');
  conexao.SQL.Add('where status >= 0 and origem in (1,2) and data_pedido in (' +
    Req.Body + ')');
  conexao.SQL.Add(') - count(*)) * 100 ) / (SELECT count(*) FROM pedido');
  conexao.SQL.Add('where status >= 0 and origem in (1,2)and data_pedido in (' +
    Req.Body + ')');
  conexao.SQL.Add(') as media_cancelado,');
  conexao.SQL.Add('100-(((SELECT count(*) FROM pedido');
  conexao.SQL.Add('where status >= 0 and origem in (1,2) and data_pedido in (' +
    Req.Body + ')');
  conexao.SQL.Add(') - count(*)) * 100 ) / (SELECT count(*) FROM pedido');
  conexao.SQL.Add('where status >= 0 and origem in (1,2) and data_pedido in (' +
    Req.Body + ')');
  conexao.SQL.Add(') as media_concluido');
  conexao.SQL.Add('FROM pedido');
  conexao.SQL.Add('where status > 0 and origem in (1,2)');
  conexao.SQL.Add('and data_pedido in (' + Req.Body + ')');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetDashBoard(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;

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
  conexao: TConexao;
begin
  conexao := TConexao.Create;
  conexao.SQL.Add('select curdate() as atual,');
  conexao.SQL.Add
    ('(select count(*) from pedido where origem in (1,2) and status  > 0 and data_pedido in ('
    + Req.Body + ')) as previsao,');
  conexao.SQL.Add
    ('(select count(*) from pedido where origem in (1,2) and status  > 0 and data_pedido = current_date()) as atual');
  // showmessage(conexao.SQL.text);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostReImpressaoApp(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  CodigoAux: Integer;
  ID: Integer;
begin
  try
    ID := Req.Params['id'].ToInteger;
  except
    Res.Send('Pedido N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  CodigoAux := conexao.GerarID('impressao_pedido_produto', 'id');

  conexao.SQL.Add
    ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
  conexao.Parametros('pedido', ID);
  conexao.Parametros('id', CodigoAux);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoPostTransferenciaMesa(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
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
    Res.Send('Pedido N„o Informado').Status(500);
    exit;
  end;

  try
    IDMesaAtual := Req.Params['mesa'].ToInteger;
  except
    Res.Send('Pedido N„o Informado').Status(500);
    exit;
  end;
  conexao := TConexao.Create;
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

  DescricaoTransferencia := 'TransferÍncia de ' + DescricaoMesaDe + ' para ' +
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
        conexao.Parametros('nomeclatura', 'TRANSFER NCIA');
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

  if CodigoPedido = 0 then
  begin
    CodigoPedido := conexao.FieldByName('selecionada');
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
    conexao.Parametros('data_pedido', FormatDateTime('yyyy-mm-dd', now));
    conexao.Parametros('hora_pedido', FormatDateTime('hh:mm:ss', now));
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
  conexao: TConexao;
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  conexao := TConexao.Create;
  while not Dados.Eof do
  begin
    // codigo

    conexao.SQL.Add
      ('update impressao_pedido_produto set status = 0 where id_pedido = :codigo and data_impressao is null');
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
  conexao: TConexao;
  ID: Integer;
begin

  conexao := TConexao.Create;
  conexao.SQL.Add('SELECT * FROM mesa as m');
  conexao.SQL.Add('join mesa_tipo as mt on mt.id_mesa_tipo = m.fk_tipo_mesa');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostSenhaGerente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Senha: String;
begin

  try
    Senha := Req.Params['senha'];
  except
    Res.Send('Senha N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('update dados_whatsapp set senha_gerencia = md5(:senha)');

  conexao.Parametros('senha', Senha);
  conexao.ExecuteSQL;

  conexao.Free;
end;

procedure DoGetSenhaGerente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Senha: String;
  Dados: TFDMemTable;
begin

  try
    Senha := Req.Params['senha'];
  except
    Res.Send('Senha N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
  ID: Integer;
begin

  try
    ID := Req.Params['mesa'].ToInteger;
  except
    Res.Send('Mesa N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add
    ('update mesa set tot_mesa = 0, sts_mesa = 0, selecionada = 0 where id_mesa = :id');
  conexao.Parametros('id', ID);
  conexao.ExecuteSQL;

  conexao.Free;
end;

procedure DoPostDeletaMesa(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  ID: Integer;
begin

  try
    ID := Req.Params['mesa'].ToInteger;
  except
    Res.Send('Mesa N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
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
    Res.Send('Arquivo n„o encontrado: ' + arq).Status(404);
end;

procedure DoPostTest(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  ID: Integer;
  LUploadConfig: TUploadConfig;
begin
  LUploadConfig := TUploadConfig.Create('c:\serverfiles');
  LUploadConfig.ForceDir := True;
  LUploadConfig.OverrideFiles := True;

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
  conexao: TConexao;
  Dados: TFDMemTable;
  ID: Integer;
begin

  try
    ID := Req.Params['codigo'].ToInteger;
  except
    Res.Send('Pedido N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('SELECT * FROM pedido where codigo = :codigo');
  conexao.Parametros('codigo', ID);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    Res.Send<TJSONObject>(Dados.ToJSONObject());
  end
  else
  begin
    if ID = 0 then
    begin

      ID := conexao.GerarID('pedido', 'codigo');
      conexao.SQL.Add
        ('insert into pedido (codigo,codigo_pedido_dia,status,origem,codigo_cliente,codigo_cliente_endereco,valor_pedido,valor_desconto,valor_total_pedido,valor_taxa_entrega,taxa_servico,data_pedido,hora_pedido)');
      conexao.SQL.Add
        ('values (:codigo,0,-1,4,0,0,0,0,0,0,0,current_date, current_time)');
      conexao.Parametros('codigo', ID);
      conexao.ExecuteSQL;

      conexao.SQL.Add
        ('SELECT * FROM pedido where status = -1 and origem = 4 order by codigo desc');
      Dados.LoadFromJSON(conexao.ConsultaSQL);
      Res.Send<TJSONObject>(Dados.ToJSONObject());

    end
    else
      Res.Send('Pedido n„o localizado').Status(500);

  end;

  Dados.Free;
  conexao.Free;
end;

procedure DoGetConsultaClienteCelular(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Celular: String;
begin

  try
    Celular := Req.Params['celular'];
  except
    Res.Send('celular N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;

  conexao.SQL.Add('select * from cliente as c');
  conexao.SQL.Add
    ('left join cliente_endereco as ce on ce.codigo_cliente = c.codigo');
  conexao.SQL.Add
    ('left join taxa_entrega as te on te.bairro = ce.bairro and te.cidade = ce.cidade');
  conexao.SQL.Add('where (c.celular like "%' + Celular +
    '%" or c.celular_wpp like "%' + Celular +
    '%") order by ce.codigo desc limit 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetConsultaCliente(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  ID: Integer;
begin

  try
    ID := Req.Params['codigo'].ToInteger;
  except
    Res.Send('CÛdigo N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('select * from cliente where codigo = :codigo');
  conexao.Parametros('codigo', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetConsultaClienteEndereco(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
  ID: Integer;
begin

  try
    ID := Req.Params['codigo'].ToInteger;
  except
    Res.Send('CÛdigo N„o Informado').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
  Dados: TFDMemTable;
  form: String;
begin

  Res.Send('{"versao_app":"1", "versao_servidor":"1", "versao_minima":"1", "origem_donwload":""}');

end;

procedure DoPostAtualizaDadosPedido(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  CodigoPedido: Integer;
  Troco: Real;
begin
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

  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount > 0 then
  begin
    conexao := TConexao.Create;
    Dados.Edit;
    if Dados.FieldByName('cliente').AsInteger = 0 then
    begin

      Dados.FieldByName('cliente').AsInteger :=
        conexao.GerarID('cliente', 'codigo');

      conexao.SQL.Add
        ('insert into cliente (codigo,nome,celular,celular_wpp,ativo) values  (:codigo,:nome,:celular,:celular_wpp,1)');
      conexao.Parametros('codigo', Dados.FieldByName('cliente').AsInteger);
      conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
      conexao.Parametros('celular', Dados.FieldByName('celular').AsString);
      conexao.Parametros('celular_wpp',
        NonoDigito(Dados.FieldByName('celular').AsString));
      conexao.ExecuteSQL;

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

    CodigoPedido := GeraCodigoPorDiaPedido(Dados.FieldByName('codigo')
      .AsInteger);

    conexao.SQL.Add
      ('update cliente set nome = :nome, celular = :celular, celular_wpp = :celular where codigo = :codigo');
    conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
    conexao.Parametros('celular', Dados.FieldByName('celular').AsString);
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

    conexao.SQL.Add
      ('update pedido set codigo_pedido_dia = :codigo_pedido_dia,codigo_cliente = :cliente, codigo_cliente_endereco = :endereco, data_pedido = :data,');
    conexao.SQL.Add
      ('hora_pedido = :hora,tipo_pagamento = :tipo_pagamento, status = :status, valor_pedido = :produto, troco = :troco, valor_desconto = :desconto, valor_taxa_entrega = :entrega, valor_total_pedido = :total, taxa_servico = :acrecimo where codigo = :codigo');
    conexao.Parametros('codigo_pedido_dia', CodigoPedido);
    conexao.Parametros('cliente', Dados.FieldByName('cliente').AsInteger);
    conexao.Parametros('endereco', Dados.FieldByName('endereco').AsInteger);
    conexao.Parametros('data', Dados.FieldByName('data').AsString);
    conexao.Parametros('hora', (Dados.FieldByName('hora').AsString));
    conexao.Parametros('status', Dados.FieldByName('status').AsInteger);
    conexao.Parametros('produto', Dados.FieldByName('produto').AsFloat);
    conexao.Parametros('desconto', Dados.FieldByName('desconto').AsFloat);
    conexao.Parametros('entrega', Dados.FieldByName('entrega').AsFloat);
    conexao.Parametros('total', Dados.FieldByName('total').AsFloat);
    conexao.Parametros('acrecimo', Dados.FieldByName('acrecimo').AsFloat);
    conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
    conexao.Parametros('tipo_pagamento', Dados.FieldByName('tipo_pagamento')
      .AsInteger);
    conexao.Parametros('troco', Troco);
    conexao.ExecuteSQL;

    conexao.Free;
  end;

end;

procedure DoGetConsultaGenerica(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  ID: Integer;
  tabela: String;
  Campos: String;
  Condicao: String;
  OrderBy: String;
begin

  try
    tabela := Req.Params['tabela'];
  except
    Res.Send('Tabela N„o Informado').Status(500);
    exit;
  end;
  try
    Campos := Req.Params['campos'];
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

  conexao := TConexao.Create;
  conexao.SQL.Add('select ' + Campos + ' from ' + tabela + ' where 1 = 1 ' +
    Condicao + OrderBy);

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetSaboresPreco(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;
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
  conexao: TConexao;
  Dados: TFDMemTable;
begin

  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := TConexao.Create;

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

end;

procedure DoGetVersao(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  form: String;
begin
  conexao := TConexao.Create;
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('SELECT * FROM ATUALIZACAOAPP');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount = 0 then
  begin
    conexao.SQL.Add('INSERT INTO ATUALIZACAOAPP VALUES (' + QuotedStr('1.0') +
      ',' + QuotedStr('1.0') + ',' + QuotedStr('') + ');');
  end;

  conexao.SQL.Add('SELECT * FROM ATUALIZACAOAPP');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  Res.Send('{"versao_app":"' + Dados.FieldByName('VERSAOAPP').AsString +
    '", "versao_servidor":"' + GetBuildInfo + '", "versao_minima":"' +
    Dados.FieldByName('VERSAOMINIMA').AsString + '", "origem_donwload":"' +
    Dados.FieldByName('ORIGEMDOWNLOAD').AsString + '"}');

  conexao.Free;
  Dados.Free;
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
      .AsString);
  end
  else
  begin
    // 2 - Saida
    MovimentoCaixa(Dados.FieldByName('caixa').AsInteger, 0, 0, 2,
      Dados.FieldByName('valor').AsFloat, Dados.FieldByName('descricao')
      .AsString);
  end;

end;

procedure DoGetHistoricoMotoboyCompleto(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;

  Codigo: String;
begin
  try
    Codigo := (Req.Params['codigo']);
  except
    exit;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
  DataInicial: TDate;
begin

  try
    DataInicial := TransformaData(Req.Params['dataini']);
  except
    DataInicial := Date;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  conexao := TConexao.Create;
  conexao.SQL.Add(Req.Body);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoGetImpressoraServidor(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
begin
  frmServidor.LoadImpressora;
  Res.Send<TJSONArray>(frmServidor.memImpressora.ToJSONArray());
end;

procedure DoPostAlteracao(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
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
  conexao := TConexao.Create;
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
          // Tabela de PreÁo
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
  conexao: TConexao;
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);
  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  conexao := TConexao.Create;

  with conexao do
  begin
    SQL.Add('update pro_adi_personalizado set descricao = :descricao, qtd_minima = :min, qtd_maxima = :max, ativo =:status where id = :id');
    Parametros('descricao', Dados.FieldByName('descricao').AsString);
    Parametros('min', Dados.FieldByName('min').AsString);
    Parametros('max', Dados.FieldByName('max').AsString);
    Parametros('status', Dados.FieldByName('status').AsString);
    Parametros('id', Dados.FieldByName('id').AsString);
    ExecuteSQL;
  end;

  conexao.Free;
end;

procedure DoPostAtualizaExtraItens(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
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

  conexao := TConexao.Create;

  with conexao do
  begin
    SQL.Add('update pro_adi_personalizado_sabores set modificado_site = 0, ativo = 0 where id_pro_adi_personalizado = :id');
    Parametros('id', Dados.FieldByName('id_pro_adi_personalizado').AsString);
    ExecuteSQL;
  end;

  while not Dados.Eof do
  begin
    if Dados.FieldByName('id').AsInteger = 0 then
    begin
      //
      with conexao do
      begin
        Codigo := GerarID('pro_adi_personalizado_sabores', 'id');
        SQL.Add('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo,modificado_site) values (:id,:extra,:nome,:descricao,:valor,:ativo,0)');
        Parametros('id', Codigo);
        Parametros('extra', Dados.FieldByName('id_pro_adi_personalizado')
          .AsString);
        Parametros('nome', Dados.FieldByName('nome').AsString);
        Parametros('descricao', Dados.FieldByName('descricao').AsString);
        Parametros('valor', Dados.FieldByName('valor').AsString);
        Parametros('ativo', Dados.FieldByName('ativo').AsString);
        ExecuteSQL;
      end;

    end
    else
    begin
      with conexao do
      begin
        SQL.Add('update pro_adi_personalizado_sabores  set nome = :nome, descricao = :descricao, valor = :valor, ativo = :ativo, modificado_site = 0 where id = :id');
        Parametros('nome', Dados.FieldByName('nome').AsString);
        Parametros('descricao', Dados.FieldByName('descricao').AsString);
        Parametros('valor', Dados.FieldByName('valor').AsString);
        Parametros('ativo', Dados.FieldByName('ativo').AsString);
        Parametros('id', Dados.FieldByName('id').AsString);
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
  Res.Send('Pedido N„o Informado').Status(500);
  exit;
  end;

  conexao := TConexao.Create;
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  end;
}

procedure DoGetLimpaBanco(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Banco: String;
  Chave: String;
  Dados: TFDMemTable;
begin

  try
    Banco := LowerCase(Req.Params['banco']);
  except
    Res.Send('Banco N„o Informado').Status(500);
    exit;
  end;

  try
    Chave := Req.Params['chave'];
  except
    Res.Send('Chave N„o Informado').Status(500);
    exit;
  end;

  if Chave <> FormatDateTime('ddmmyyyy', now) then
  begin
    Res.Send('Chave Errada').Status(500);
    exit;
  end;

  conexao := TConexao.Create;
  if conexao.NomeBanco <> Banco then
  begin
    Res.Send('Banco n„o conectado! Banco atual: ' + conexao.NomeBanco)
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
  conexao: TConexao;
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

  conexao := TConexao.Create;
  Codigo := Dados.FieldByName('codigo').AsInteger;
  if Codigo = 0 then
  begin
    Codigo := conexao.GerarID('tipo_pagamento', 'codigo');
    conexao.SQL.Add
      ('insert into tipo_pagamento (codigo,descricao,troco_delivery,ativo,movimentacao) values (:codigo,:descricao,:troco_delivery,:ativo,:movimentacao)');
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
  conexao: TConexao;
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

  conexao := TConexao.Create;
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
end;

procedure DoGetRelatorioFinanceiro(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
  Tipo: Integer;

  Dados: TFDMemTable;
begin

  try
    Tipo := LowerCase(Req.Params['tipo']).ToInteger;
  except
    Res.Send('Tipo N„o Informado').Status(500);
    exit;
  end;
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(Req.Body);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;
  conexao := TConexao.Create;
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
        conexao.Parametros('ini', (Dados.FieldByName('data_inicial').AsString));
        conexao.Parametros('fim', (Dados.FieldByName('data_final').AsString));
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
        conexao.Parametros('ini', (Dados.FieldByName('data_inicial').AsString));
        conexao.Parametros('fim', (Dados.FieldByName('data_final').AsString));

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
        conexao.Parametros('ini', (Dados.FieldByName('data_inicial').AsString));
        conexao.Parametros('fim', (Dados.FieldByName('data_final').AsString));

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
        conexao.Parametros('ini', (Dados.FieldByName('data_inicial').AsString));
        conexao.Parametros('fim', (Dados.FieldByName('data_final').AsString));
      end;
  end;
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  Dados.Free;
end;

procedure DoGetExtraAll(Req: THorseRequest; Res: THorseResponse;

Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;
  conexao.SQL.Add
    ('select p.codigo, pap.id as extra_id, upper(CONCAT(p.nome_produto,' +
    QuotedStr(' -> ') +
    ',pap.descricao)) as juncao, upper(p.nome_produto) as produto, upper(pap.descricao) as extra, upper(GROUP_CONCAT(paps.nome)) as itens from produto as p');
  conexao.SQL.Add
    ('join pro_adi_personalizado as pap on pap.id_produto = p.codigo');
  conexao.SQL.Add
    ('join pro_adi_personalizado_sabores as paps on paps.id_pro_adi_personalizado = pap.id');
  conexao.SQL.Add('where paps.valor > 0');
  conexao.SQL.Add('group by pap.id_produto');
  conexao.SQL.Add('order by p.codigo');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

// THorse.Post('/v1/util/extra/produtos/:extra/:produto', DoPostExtraAll);

procedure DoPostExtraAll(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Produto: Integer;
  Extra: Integer;
  Dados: TFDMemTable;
  Codigo: Integer;
  CodigoExtra: Integer;
begin
  try
    Extra := Req.Params['extra'].ToInteger;
  except
    Res.Send('Extra N„o Informado').Status(500);
    exit;
  end;
  try
    Produto := Req.Params['produto'].ToInteger;
  except
    Res.Send('Extra N„o Informado').Status(500);
    exit;
  end;
  conexao := TConexao.Create;
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
      ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima) values (:id,:id_produto,:descricao,:ativo,:qtd_minima,:qtd_maxima)');
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
      ('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo) values (:id,:id_pro_adi_personalizado,:nome,:descricao,:valor,:ativo)');
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
  conexao: TConexao;
  ID: Integer;
begin
  try
    ID := Req.Params['codigo'].ToInteger;
  except
    Res.Send('ID N„o Informado').Status(500);
    exit;
  end;
  conexao := TConexao.Create;
  conexao.SQL.Add
    ('SELECT * FROM sabores_completo where id_produto = :id order by id');
  conexao.Parametros('id', ID);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetTipoSabor(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Codigo: Integer;
  Tipos: Array of String;
  I: Integer;
begin
  SetLength(Tipos, 4);
  Tipos[0] := 'PromoÁ„o';
  Tipos[1] := 'Tradicional';
  Tipos[2] := 'Especial';
  Tipos[3] := 'Doce';
  conexao := TConexao.Create;

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
    QuotedStr('PromoÁ„o') + ',' + QuotedStr('Tradicional') + ',' +
    QuotedStr('Especial') + ',' + QuotedStr('Doce') + ') and ativo = 1');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

//
procedure DoPostSaborProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
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
        conexao := TConexao.Create;
        conexao.SQL.Add
          ('update sabores_completo set id_tipo_sabor = :sabor, nome = :nome, descricao = :descricao, vl_venda = :venda, modificado_site = 0 where id = :id');
        conexao.Parametros('sabor', Dados.FieldByName('tipo').AsInteger);
        conexao.Parametros('nome', Dados.FieldByName('sabor').AsString);
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
  conexao := TConexao.Create;
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
  conexao: TConexao;
  Busca: String;
begin
  try
    Busca := UpperCase(Req.Params['busca']);
  except
    exit;
  end;
  conexao := TConexao.Create;
  conexao.SQL.Add('select  * from taxa_entrega where upper(bairro) like "%' +
    Busca + '%" limit 3');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostRecebimentoCaixa(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Dados: TFDMemTable;
  conexao: TConexao;
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
  OBS := 'RECEBIDO EM ' + FormatDateTime('dd/mm/yyyy hh:nn', now);
  conexao := TConexao.Create;
  conexao.SQL.Add
    ('update caixa_receber set status = 2, observacao =:obs where id = :id');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('obs', OBS);
  conexao.ExecuteSQL;

  while not Dados.Eof do
  begin
    OBS := 'RECEBIMENTO DE PAGAMENTO EM ABERTO PEDIDO #' + Pedido.ToString;
    MovimentoCaixa(Caixa, Pedido, Dados.FieldByName('ID_TIPO_PAGAMENTO')
      .AsInteger, 1, Dados.FieldByName('valor').AsFloat, OBS);
    Dados.Next;
  end;

  Dados.Free;
  conexao.Free;
end;

procedure DoPostPedidoExtorno(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: TConexao;
begin
  try
    Pedido := Req.Params['id'].ToInteger;
  except
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('delete from caixa_movimento where id_pedido = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.SQL.Add('delete from caixa_receber where id_pedido = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.SQL.Add('update pedido set id_caixa = null where codigo = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.Free;

end;

// DoPostGravaMesas
procedure DoPostGravaMesas(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
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
  conexao := TConexao.Create;
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
  conexao: TConexao;
  CodigoAux: String;
  Dados: TFDMemTable;
  Imprimir: Integer;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := TConexao.Create;
  //
  conexao.SQL.Add('select * from dados_whatsapp');
  Imprimir := conexao.FieldByName('impressaotipopro');
  Dados := TFDMemTable.Create(nil);
  if Imprimir = 1 then
  begin
    conexao.SQL.Add
      ('select * from pedido_produtos where codigo_pedido = :codigo');
    conexao.Parametros('codigo', Codigo);
    Dados.LoadFromJSON(conexao.ConsultaSQL);

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
  conexao: TConexao;
  CodigoAux: Integer;
  Usuario: Integer;
begin
  try
    Codigo := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('select * from usuario');
  Usuario := conexao.FieldByName('codigo');
  CodigoAux := conexao.GerarID('impressao_pedido_produto', 'id');
  conexao.SQL.Add
    ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:pedido,:status,0,:usuario)');
  conexao.Parametros('pedido', Codigo);
  conexao.Parametros('id', CodigoAux);
  conexao.Parametros('status', 1);
  conexao.Parametros('usuario', Usuario);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetDadosPedidoProduto(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: TConexao;
begin
  try
    Pedido := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  try
    Pedido := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('update pedido set wpp_status = status where codigo = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoPostWhatsappPix(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  Pedido: Integer;
  conexao: TConexao;
begin
  try
    Pedido := Req.Params['codigo'].ToInteger;
  except
    exit;
  end;

  conexao := TConexao.Create;
  conexao.SQL.Add('update pedido set wpp_pix = 1 where codigo = :id');
  conexao.Parametros('id', Pedido);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetWhatsappStatusAlterado(Req: THorseRequest; Res: THorseResponse;
Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  conexao := TConexao.Create;
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
  conexao: TConexao;
begin
  conexao := TConexao.Create;
  conexao.SQL.Add
    ('select p.codigo, p.codigo_pedido_dia, c.nome, c.celular, c.celular_wpp, tp.tipo_chave_pix, tp.chave_pix, tp.chave_recebedor, p.valor_total_pedido from pedido as p');
  conexao.SQL.Add('join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add('join cliente as c on c.codigo = p.codigo_cliente');
  conexao.SQL.Add
    ('where tp.tipo_chave_pix > 0 and p.wpp_pix is null and p.status > 0 and data_pedido >= current_date-1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;



// THorse.Get('/v1/util/busca/bairro/:busca', DoGetBuscaBairro);

procedure Registry;
begin
  THorse.Get('v1/util/limpa/banco/:banco/:chave', DoGetLimpaBanco);

  THorse.Get('v1/versao/app', DoGetVersao);

  THorse.Get('/v1/mesas/', DoGetMesas);
  THorse.Get('/v1/mesas/:mesa', DoGetMesas);
  THorse.Get('/v1/mesa/:mesa', DoGetMesa);
  THorse.Get('/v1/test/', DoGetTest);

  THorse.Get('/v1/categorias/', DoGetCategoria);

  THorse.Get('/v1/produtos/:categoria/:delivery', DoGetProduto);

  THorse.Get('/v1/produtos/nome/:busca', DoGetProdutoBusca);
  THorse.Get('/v1/produtos/nome/', DoGetProdutoBusca);

  THorse.Get('/v1/produtos/adicional/:produto', DoGetProdutoAdiciona);
  THorse.Get('/v1/produtos/sabores/:produto', DoGetProdutoSabores);

  THorse.Post('/v1/pedido/produto/:usuario', DoPostPedidoProduto);
  THorse.Delete('/v1/pedido/produto/:id', DoDeletePedidoProduto);

  THorse.Get('/v1/produtos/pedido/:tipo/:mesa', DoGetProdutoPedido);
  THorse.Get('/v1/produtos/pedido/itens/:id', DoGetProdutoPedidoItens);

  THorse.Put
    ('/v1/pedido/finaliza/:mesa/:impressao/:desconto/:acrecimo/:tipopagamento/:taxaentrega/:caixa/:pedido',
    DoPutFinalizaPedido);
  THorse.Get('/v1/pedido/produtos/:pedido', DoGetPedidoProduto);

  THorse.Get('/v1/usuario/:usuario/:senha', DoGetUsuario);

  THorse.Get('/v1/total/:dataini/:datafim/:horaini/:horafim', DoGetTotal);
  THorse.Get('/v1/total/motoboy/:dataini/:datafim/:horaini/:horafim',
    DoGetTotalMotoboy);

  THorse.Get('/v1/pedidos/:dataini/:datafim/:horaini/:horafim/:tipo/:faturado',
    DoGetPedidos);

  THorse.Get('/v1/tipo/pagamento/', DoGetTipoPagamento);

  THorse.Get('/v1/caixa/aberto/:usuario', DoGetCaixa);
  THorse.Post('/v1/caixa/abertura/:usuario/:valor', DoPostAberturaCaixa);

  THorse.Post('/v1/caixa/sangria/:caixa/:valor', DoPostSangria);
  THorse.Post('/v1/caixa/movimentacao/', DoPostMovimentacaoCaixa);

  THorse.Get('/v1/caixa/dados/:caixa', DoGetCaixaDados);

  THorse.Get('/v1/caixa/pedidos/dados/:caixa', DoGetPedidosCaixa);
  THorse.Get('/v1/caixa/pedidos/historico/:caixa', DoGetHistoricoCaixa);
  THorse.Get('/v1/caixa/pedidos/pagamento/:caixa', DoGetPagamentoCaixa);
  THorse.Get('/v1/caixa/historico/', DoGetHistoricoCaixaTodos);
  THorse.Get('/v1/caixa/receber/:codigo', DoGetAReceber);

  THorse.Post('/v1/caixa/fechamento/:caixa', DoPostFechamentoCaixa);
  THorse.Post('/v1/caixa/fechamento/pedido/automatico/:caixa',
    DoPostFaturarPeido);
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

  THorse.Post('/v1/imagem/produto/:id', DoPostImgProduto);
  THorse.Get('/v1/imagem/produto/:id', DoGetImgProduto);

  THorse.Post('/v1/imprimir/:tipo/:codigo', DoPostImprimir);

  // Cadastros
  THorse.Get('/v1/categoria/all/', DoGetCategoriaAll);
  THorse.Post('/v1/categoria/post/', DoPostCategoriaAll);

  THorse.Get('/v1/consulta/todos/:tabela', DoGetConsultaTodos);
  THorse.Get('/v1/consulta/todos/clientes', DoGetTodosCliente);

  // Motoboy
  THorse.Get('/v1/motoboy/ativo/all/', DoGetMotboyAtivo);

  THorse.Put('/v1/pedido/motoboy/:pedido/:motoboy/', DoPutPedidoMotoboy);
  THorse.Put('/v1/pedido/status/:pedido/:status/', DoPutPedidoStatus);
  THorse.Post('/v1/pedido/reimpressao/app/:id', DoPostReImpressaoApp);

  THorse.Post('/v1/insert/generico/:tabela/:id', DoPostGenerico);

  THorse.Get('/v1/cliente/celular/:celular', DoGetClienteCelular);

  THorse.Get('/v1/media/pedido', DoGetMediaPedido);
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
  // THorse.Get('/v1/dados/consulta/cliente/:codigo', DoGetDadosPedido);
  THorse.Get('/v1/dados/consulta/cliente/:codigo', DoGetConsultaCliente);
  THorse.Get('/v1/dados/consulta/cliente/endereco/:codigo',
    DoGetConsultaClienteEndereco);
  THorse.Get('/v1/dados/consulta/cliente/celular/:celular',
    DoGetConsultaClienteCelular);

  THorse.Post('/v1/atualiza/dados/pedido/', DoPostAtualizaDadosPedido);

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

  THorse.Get('/v1/util/relatorio/financeiro/:tipo', DoGetRelatorioFinanceiro);

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
  THorse.Post('/v1/util/impressao/pedido/produtos/:codigo',
    DoPostLiberaImpressaoPedidoProduto);

  // Cadastro Mesa
  THorse.Post('/v1/util/grava/mesa/:tipo/:min/:max', DoPostGravaMesas);

end;

function TransformaData(Data: String): TDate;
begin
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

procedure MovimentoCaixa(Caixa, Pedido, TipoPagamento, Tipo: Integer;
Valor: Real; Descricao: String);
var
  conexao: TConexao;
  Codigo: Integer;
  DadosTipoPagamento: TFDMemTable;
begin
  Descricao := RemoveAcento(Descricao);
  Descricao := UpperCase(Descricao);

  conexao := TConexao.Create;
  Codigo := conexao.GerarID('caixa_movimento', 'id');
  conexao.SQL.Add
    ('insert into caixa_movimento (id,id_caixa,id_pedido,tipo,id_tipo_pagamento,data,hora,valor,descricao) values (:id,:caixa,:pedido,:tipo,:pagamento,current_date,current_time,:valor,:descricao)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('caixa', Caixa);
  conexao.Parametros('pedido', Pedido);
  conexao.Parametros('tipo', Tipo);
  conexao.Parametros('pagamento', TipoPagamento);
  conexao.Parametros('valor', Valor);
  conexao.Parametros('descricao', Descricao);
  conexao.ExecuteSQL;

  conexao.SQL.Add('update pedido set id_caixa = :caixa where codigo = :pedido');
  conexao.Parametros('caixa', Caixa);
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
      GerarReceber(Caixa, Pedido, TipoPagamento, Valor);
    end;

  end;

  conexao.Free;
end;

procedure GerarReceber(Caixa, Pedido, TipoPagamento: Integer; Valor: Real);
var
  conexao: TConexao;
  CodigoCliente: Integer;
  Codigo: Integer;
begin
  conexao := TConexao.Create;
  conexao.SQL.Add('select * from pedido where codigo = :codigo');
  conexao.Parametros('codigo', Pedido);
  CodigoCliente := conexao.FieldByName('codigo_cliente');

  if CodigoCliente = 0 then
  begin
    conexao.Free;
    exit;
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
  ShowMessage(E.Message);
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

  Data: TDate;

  Insert: TConexao;
  Dados: TFDMemTable;
  SQL: String;

begin
  Insert := TConexao.Create;
  Dados := TFDMemTable.Create(nil);

  Insert.SQL.Add('select * from pedido where codigo = :codigo');
  Insert.Parametros('codigo', Pedido);

  Result := Insert.FieldByName('codigo_pedido_dia');
  if Result > 0 then
  begin
    Insert.Free;
    exit;
  end;

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

end;

function RemoveAcento(const pText: string): string;
const
  ComAcento = '‡‚ÍÙ˚„ı·ÈÌÛ˙Á¸Ò˝¿¬ ‘€√’¡…Õ”⁄«‹—›';
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

end.
