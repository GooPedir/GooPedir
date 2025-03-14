unit nfce;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, REST.Client, REST.Types;

procedure Registry;

procedure DeletarNFCe(CNPJ, Chave: String);

implementation

uses FireDAC.Stan.Option, token, conexao, JOSE.Types.JSON, System.Classes,
  Data.DB, IdWinsock2, Vcl.Dialogs, Vcl.ExtCtrls, Horse.Upload, System.Types,
  Winapi.Windows, uMain, System.StrUtils, Vcl.StdCtrls, util, uSite;

procedure DoGetPedidoOutros(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  SQL: String;
begin

  conexao := TConexao.Create('nfce');
  SQL := 'select pedido.servico, pedido.valor_desconto as discont, pedido.cpf, pedido.nome, ';
  SQL := SQL + 'pedido.valor_taxa_entrega as entrega ';
  SQL := SQL + 'FROM pedido where codigo = ' + Req.Params['codigo'];
  // conexao.Parametros('codigo', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL(SQL));
  conexao.Free;
  // Res.Send(SQL);
end;

procedure DoGetProdutosPedido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('nfce');
  conexao.SQL.Add
    ('SELECT upper(produto.nome_produto) as name, produto.codigo_barra as bar, produto.codigo_interno as code, ');
  conexao.SQL.Add
    ('TRUNCATE((pedido_produtos.valor_total / pedido_produtos.quantidade), 2)  as value,');
  conexao.SQL.Add
    ('pedido_produtos.quantidade as quanty, un,ncm,cest,cfop,cstipi,csticms,cstpis,cstcofins,csosn,icms,ipi,pis,cofins,frete,');
  conexao.SQL.Add
    ('(select group_concat(upper(pedido_produto_sap.descricao)) from pedido_produto_sap where pedido_produto_sap.codigo_pedido_produto = pedido_produtos.codigo and pedido_produto_sap.valor > 0) as additional');
  conexao.SQL.Add('FROM pedido');
  conexao.SQL.Add
    ('join pedido_produtos on pedido_produtos.codigo_pedido = pedido.codigo');
  conexao.SQL.Add
    ('join produto on produto.codigo = pedido_produtos.codigo_produto');
  conexao.SQL.Add('where pedido.codigo = :codigo');
  conexao.Parametros('codigo', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoGetPedidoPagamento(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('nfce');
  conexao.SQL.Add('SELECT tipo_pagamento.descricao, TRUNCATE(caixa_movimento.valor, 2) as valor FROM caixa_movimento');
  conexao.SQL.Add('join tipo_pagamento on tipo_pagamento.codigo = caixa_movimento.id_tipo_pagamento');
  conexao.SQL.Add('where id_pedido = :codigo and caixa_movimento.tipo = 1');
  conexao.Parametros('codigo', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;
//

procedure DoGetNumeroNota(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
begin
  conexao := TConexao.Create('nfce');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select numero,0 as zero from nfce_numeracao where lote = (select max(lote) from nfce_numeracao)');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    Res.Send(IntToStr(Dados.FieldByName('numero').AsInteger + 1));
    conexao.SQL.Add
      ('UPDATE nfce_numeracao SET numero = numero + 1 WHERE lote = (SELECT lote FROM (SELECT MAX(lote) AS lote FROM nfce_numeracao) AS Temp);')
  end
  else
  begin
    conexao.SQL.Add('insert into nfce_numeracao (numero,lote) values (1,1)');

    Res.Send(IntToStr(1));
  end;
  conexao.ExecuteSQL;

  Dados.Free;
  conexao.Free;

end;

procedure DoGetNumeroLote(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('nfce');
  conexao.SQL.Add('select max(lote) as lote, 0 as zero from nfce_numeracao');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DOGetNFCeEmissao(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('nfce');

  conexao.SQL.Add
    ('update pedido set nfce_emite = 1 where data_pedido = curdate() and nfce_chave = "CONTINGÊNCIA"');
  conexao.ExecuteSQL;

  // conexao.SQL.Add('SELECT * FROM pedido WHERE nfce_emite = 1 AND status > 0  AND data_pedido > DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) and codigo_pedido_dia > 0');
  conexao.SQL.Add('SELECT * FROM pedido WHERE nfce_emite = 1 and id_caixa > 0  AND status > 0  AND data_pedido >= '+ QuotedStr('2024-09-01') + ' and codigo_pedido_dia > 0');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostNotaSinc(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  DadosNF: TFDMemTable;
  Codigo: Integer;
begin
  DadosNF := TFDMemTable.Create(nil);
  conexao := TConexao.Create('nfce');
  conexao.SQL.Add
    ('update pedido set nfce_sinc_contabilidade = 1 where nfce_chave = :nfce_chave');
  conexao.Parametros('nfce_chave', Req.Params['chave']);
  conexao.ExecuteSQL;

  conexao.SQL.Add('select * from pedido where nfce_chave = :nfce_chave');
  conexao.Parametros('nfce_chave', Req.Params['chave']);
  DadosNF.LoadFromJSON(conexao.ConsultaSQL);

  if DadosNF.RecordCount > 0 then
  begin
    conexao.SQL.Add('delete from pedido_nfce where id_pedido = :pedido');
    conexao.Parametros('pedido', DadosNF.FieldByName('codigo').AsInteger);
    conexao.ExecuteSQL;

    Codigo := conexao.GerarID('pedido_nfce', 'id');
    conexao.SQL.Add
      ('insert into pedido_nfce (id,id_pedido,chave,protocolo,caminho) values (:id,:id_pedido,:chave,:protocolo,:caminho)');
    conexao.Parametros('id', Codigo);
    conexao.Parametros('id_pedido', DadosNF.FieldByName('codigo').AsInteger);
    conexao.Parametros('chave', DadosNF.FieldByName('nfce_chave').AsString);
    conexao.Parametros('protocolo', DadosNF.FieldByName('nfce_protocolo')
      .AsString);
    conexao.Parametros('caminho', Req.Body);
    conexao.ExecuteSQL;

  end;

  DadosNF.Free;

  conexao.Free;
end;

procedure DoPostEmissaoNFCe(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Chave: String;
begin
  conexao := TConexao.Create('nfce');

  if (Req.Params['chave'] = 'CANCELADA') then
  begin
    conexao.SQL.Add
      ('select 0 as zero, nfce_chave from pedido where codigo = :codigo');
    conexao.Parametros('codigo', Req.Params['codigo']);
    Chave := conexao.FieldByName('nfce_chave');
    DeletarNFCe(frmServidor.Configuracoes.FieldByName('cnpj').AsString, Chave);
  end else begin
    conexao.SQL.Add('select 0, nfce_imprimir from pedido where codigo = :codigo');
    conexao.Parametros('codigo', Req.Params['codigo']);
    try
    if conexao.FieldByName('nfce_imprimir') = '1' then
    begin
    conexao.SQL.Add('insert into impressao_pedido_nfce (id_pedido) values (:codigo)');
    conexao.Parametros('codigo', Req.Params['codigo']);
    conexao.ExecuteSQL;
    end;

    except

    end;
  end;

  conexao.SQL.Add
    ('update pedido set nfce_hora = current_time, nfce_data = current_date, nfce_chave = :nfce_chave, nfce_protocolo = :nfce_protocolo, nfce_ambiente = :nfce_ambiente, nfce_numero = :nfce_numero, nfce_emite = 2 where codigo = :codigo');
  conexao.Parametros('codigo', Req.Params['codigo']);
  conexao.Parametros('nfce_chave', Req.Params['chave']);
  conexao.Parametros('nfce_protocolo', Req.Params['protocolo']);
  conexao.Parametros('nfce_ambiente', Req.Params['ambiente']);
  conexao.Parametros('nfce_numero', Req.Params['numero']);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoGetNotas(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('nfce');
  conexao.SQL.Add
    ('SELECT codigo, nfce_chave as chave FROM pedido where nfce_emite = 2 and DATE_FORMAT(data_pedido, "%Y%m") = "'
    + Req.Params['mes'] + '"');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  // Res.Send(conexao.SQL.Text);
  conexao.Free;
end;

procedure DoGetNFceContabilidade(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Codigo: Integer;
begin
  conexao := TConexao.Create('nfce');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from contabilidade where data = :data');
  conexao.Parametros('data', FormatDateTime('yyyymm', IncMonth(date, -1)));
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount = 0 then
  begin
    Codigo := conexao.GerarID('contabilidade', 'id');
    conexao.SQL.Add
      ('insert into contabilidade (id,data_envio,data,status) values (:id,current_date,:data,0)');
    conexao.Parametros('data', FormatDateTime('yyyymm', IncMonth(date, -1)));
    conexao.Parametros('id', Codigo);
    conexao.ExecuteSQL;
  end;
  conexao.SQL.Add('select * from contabilidade where data = :data');
  conexao.Parametros('data', FormatDateTime('yyyymm', IncMonth(date, -1)));
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  Dados.Free;

end;

procedure DoGetNotasPendentesSinc(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('nfce');
  conexao.SQL.Add('select * from pedido where nfce_chave <> ' +
    QuotedStr('CANCELADA') +
    ' and nfce_sinc_contabilidade = 0 and nfce_ambiente = 1 and data_pedido > '
    + QuotedStr('2024-08-01'));
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  // Res.Send(conexao.SQL.Text);
  conexao.Free;
end;

procedure DoGetCode(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONArray>(frmServidor.EventNFC.ToJSONArray());

  frmServidor.EventNFC.Close;
end;

procedure DoPostCodeMotivo(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Objec: TJSONObject;
  conexao: TConexao;
  Chave: String;
  Motivo: String;
begin
  conexao := TConexao.Create('nfce');
  Objec := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Chave := Objec.GetValue('chave').Value;
  Motivo := Objec.GetValue('motivo').Value;
  conexao.SQL.Add
    ('update pedido set motivo_cancelamento = :motivo where nfce_chave = :chave');
  conexao.Parametros('motivo', Objec.GetValue('motivo').Value);
  conexao.Parametros('chave', Objec.GetValue('chave').Value);
  conexao.ExecuteSQL;
  conexao.Free;
  Objec.Free;
end;

procedure DoPostCode(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Objec: TJSONObject;
  conexao: TConexao;
begin
  if not frmServidor.EventNFC.Active then
  begin
    frmServidor.EventNFC.Open;
  end;

  Objec := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

  if Objec.GetValue('code').Value = '1' then
  begin
    conexao := TConexao.Create('nfce');
    conexao.SQL.Add
      ('insert into impressao_pedido_nfce (id_pedido) values (:codigo)');
    conexao.Parametros('codigo', Objec.GetValue('id').Value);
    conexao.ExecuteSQL;
    conexao.Free;
    exit;
  end;

  frmServidor.EventNFC.Insert;
  frmServidor.EventNFC.FieldByName('CODE').AsString :=
    Objec.GetValue('code').Value;
  frmServidor.EventNFC.FieldByName('id').AsString := Objec.GetValue('id').Value;
  frmServidor.EventNFC.FieldByName('CHAVE').AsString :=
    Objec.GetValue('chave').Value;
  frmServidor.EventNFC.FieldByName('OBS').AsString :=
    Objec.GetValue('obs').Value;
  frmServidor.EventNFC.Post;

end;

procedure DoPostNFceContabilidade(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('nfce');
  conexao.SQL.Add
    ('update contabilidade set status = :status, erro = :erro where data = :data');
  conexao.Parametros('data', FormatDateTime('yyyymm', IncMonth(date, -1)));
  conexao.Parametros('status', Req.Params['status']);
  conexao.Parametros('erro', Req.Params['msg']);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DeletarNFCe(CNPJ, Chave: String);
var
  RESTClient: TRESTClient;
  RESTRequest: TRESTRequest;
  RESTResponse: TRESTResponse;
begin
  RESTClient := TRESTClient.Create('https://nfce.goopedir.com/deletar.php');
  RESTRequest := TRESTRequest.Create(nil);
  RESTResponse := TRESTResponse.Create(nil);
  try
    RESTRequest.Client := RESTClient;
    RESTRequest.Response := RESTResponse;
    RESTRequest.Method := TRESTRequestMethod.rmPOST;
    // Adiciona os parâmetros ao corpo da requisição
    RESTRequest.AddParameter('cnpj', CNPJ,
      TRESTRequestParameterKind.pkGETorPOST);
    RESTRequest.AddParameter('chaveNFCe', Chave,
      TRESTRequestParameterKind.pkGETorPOST);
    // Executa a requisição
    RESTRequest.Execute;
    // Verifica a resposta
    if RESTResponse.StatusCode = 200 then
    begin
      // //showmessage1('Resposta do servidor: ' + RESTResponse.Content);
    end
    else
    begin
      // //showmessage1('Erro na requisição. Código: ' + RESTResponse.StatusCode.ToString);
    end;
  finally
    RESTRequest.Free;
    RESTResponse.Free;
    RESTClient.Free;
  end;
end;

procedure Registry;
begin
  THorse.Get('/nfce/pedido/outras/:codigo', DoGetPedidoOutros);
  THorse.Get('/nfce/pedido/produtos/:codigo', DoGetProdutosPedido);
  THorse.Get('/nfce/pedido/pagamento/:codigo', DoGetPedidoPagamento);
  THorse.Get('/nfce/numero', DoGetNumeroNota);
  THorse.Get('/nfce/lote', DoGetNumeroLote);
  THorse.Get('/nfce/emissao', DOGetNFCeEmissao);
  THorse.Post('/nfce/emissao/:codigo/:numero/:chave/:protocolo/:ambiente',DoPostEmissaoNFCe);

  THorse.Get('/nfce/contabilidade', DoGetNFceContabilidade);
  THorse.Post('/nfce/contabilidade/:status/:msg', DoPostNFceContabilidade);
  THorse.Get('/nfce/contabilidade/notas/:mes', DoGetNotas);

  THorse.Post('/nfce/code/motivo', DoPostCodeMotivo);
  THorse.Post('/nfce/code', DoPostCode);
  THorse.Get('/nfce/code', DoGetCode);

  THorse.Get('/nfce/notas/sinc', DoGetNotasPendentesSinc);
  THorse.Post('/nfce/nota/sinc/:chave', DoPostNotaSinc);

end;

end.
