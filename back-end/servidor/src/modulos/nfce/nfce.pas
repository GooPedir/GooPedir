unit nfce;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer, uGlobais,
  uRequisicao, System.RegularExpressions, REST.Client, REST.Types;

procedure Registry;

procedure DeletarNFCe(CNPJ, Chave: String);

function BuscaDadosFornecedor(DataIni, DataFim: String): String;

implementation

uses FireDAC.Stan.Option, token, conexao, JOSE.Types.JSON, System.Classes,
  Data.DB, IdWinsock2, Vcl.Dialogs, Vcl.ExtCtrls, Horse.Upload, System.Types,
  Winapi.Windows, uMain, System.StrUtils, Vcl.StdCtrls, util, uSite;

function BuscaDadosFornecedor(DataIni, DataFim: String): String;
var
  conexao: TConexao;
  Retorno: TJSONArray;
  Fornecedor: TJSONObject;
  NotasFiscais: TJSONArray;
  Notafiscal: TJSONObject;
  Itens: TJSONArray;
  Item: TJSONObject;

  Dados: TFDMemTable;
  DadosNotas: TFDMemTable;
  DadosNotasItem: TFDMemTable;
begin

  conexao := TConexao.Create('Notas');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from fornecedor');
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  Retorno := TJSONArray.Create;
  while not Dados.Eof do
  begin

    Fornecedor := TJSONObject.Create;
    Fornecedor.AddPair('id', Dados.FieldByName('id').AsString);
    Fornecedor.AddPair('cnpj', Dados.FieldByName('cnpj').AsString);
    Fornecedor.AddPair('nome', UpperCase(Dados.FieldByName('nome').AsString));

    conexao.SQL.Add
      ('select id, serie, numero, chave,modelo,tipo,data_emissao as emissao, vNF, status_importacao from nota_fiscal where fornecedor_id = :fornecedor');
    if DataIni <> '' then
    begin
      conexao.SQL.Add(' AND data_emissao >= "' + DataIni + '"');
    end;
    if DataFim <> '' then
    begin
      conexao.SQL.Add(' AND data_emissao <= "' + DataFim + '"');
    end;
    conexao.Parametros('fornecedor', Dados.FieldByName('id').AsString);
    DadosNotas := TFDMemTable.Create(nil);
    DadosNotas.LoadFromJSON(conexao.ConsultaSQL);
    NotasFiscais := TJSONArray.Create;
    while not DadosNotas.Eof do
    begin
      Notafiscal := TJSONObject.Create;
      Notafiscal.AddPair('chave', DadosNotas.FieldByName('chave').AsString);
      Notafiscal.AddPair('serie', DadosNotas.FieldByName('serie').AsString);
      Notafiscal.AddPair('numero', DadosNotas.FieldByName('numero').AsString);
      Notafiscal.AddPair('modelo', DadosNotas.FieldByName('modelo').AsString);
      Notafiscal.AddPair('tipo', DadosNotas.FieldByName('tipo').AsString);
      Notafiscal.AddPair('emissao', DadosNotas.FieldByName('emissao').AsString);
      Notafiscal.AddPair('valor', DadosNotas.FieldByName('vNF').AsString);
      Notafiscal.AddPair('status', DadosNotas.FieldByName('status_importacao')
        .AsString);

      DadosNotasItem := TFDMemTable.Create(nil);
//      conexao.SQL.Add('select * from nota_fiscal_item where nota_fiscal_id = :nota');
      conexao.SQL.Add('select nfi.*, fi.codigo_vinculo, fi.fator, fi.tabela_vinculo from nota_fiscal_item nfi');
      conexao.SQL.Add('join fornecedor_item fi on fi.id = nfi.fornecedor_item_id');
      conexao.SQL.Add('where nfi.nota_fiscal_id = :nota');

      conexao.Parametros('nota', DadosNotas.FieldByName('id').AsString);
      DadosNotasItem.LoadFromJSON(conexao.ConsultaSQL);
      Itens := TJSONArray.Create;
      while not DadosNotasItem.Eof do
      begin
        Item := TJSONObject.Create;
        Item.AddPair('cProd', DadosNotasItem.FieldByName('cProd').AsString);
        Item.AddPair('xProd', DadosNotasItem.FieldByName('xProd').AsString);
        Item.AddPair('NCM', DadosNotasItem.FieldByName('NCM').AsString);
        Item.AddPair('qCom', DadosNotasItem.FieldByName('qCom').AsString);
        Item.AddPair('valor', DadosNotasItem.FieldByName('vTotal').AsString);
        Item.AddPair('UN', DadosNotasItem.FieldByName('uTrib').AsString);
        Item.AddPair('fator', DadosNotasItem.FieldByName('fator').AsString);
        Item.AddPair('vinculo', DadosNotasItem.FieldByName('codigo_vinculo').AsString);
        if DadosNotasItem.FieldByName('tabela_vinculo').AsString = 'ingrediente' then
          Item.AddPair('tipo', 2)
        else
          Item.AddPair('tipo', 1);
        Itens.AddElement(Item);
        DadosNotasItem.Next;
      end;

      DadosNotasItem.Free;

      Notafiscal.AddPair('itens', Itens);
      NotasFiscais.AddElement(Notafiscal);
      DadosNotas.Next;
    end;
    DadosNotas.Free;

    Fornecedor.AddPair('notas', NotasFiscais);
    Retorno.AddElement(Fornecedor);
    Dados.Next;
  end;
  Result := Retorno.ToString;
  Retorno.Free;
  conexao.Free;
  Dados.Free;
end;

procedure DoGetPedidoOutros(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  SQL: String;
begin

  conexao := TConexao.Create('nfce');
  // SQL := 'select pedido.servico, pedido.valor_desconto as discont, pedido.cpf, pedido.nome, ';
  // SQL := SQL + 'pedido.valor_taxa_entrega as entrega ';
  // SQL := SQL + 'FROM pedido where codigo = ' + Req.Params['codigo'];
  SQL := ' select pedido.servico, pedido.valor_desconto as discont, pedido.cpf, pedido.nome, pedido.valor_taxa_entrega as entrega, impressoras.driver';
  SQL := SQL + ' FROM pedido';
  SQL := SQL + ' left join usuario on usuario.codigo = pedido.usuario';
  SQL := SQL +
    ' left join impressoras on impressoras.codigo = usuario.impressora or impressoras.impressora_padrao = 1';
  SQL := SQL + ' where pedido.codigo = :codigo ';
  conexao.SQL.Add(SQL);
  conexao.Parametros('codigo', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL());
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
  conexao.SQL.Add
    ('SELECT tipo_pagamento.descricao, TRUNCATE(caixa_movimento.valor, 2) as valor FROM caixa_movimento');
  conexao.SQL.Add
    ('join tipo_pagamento on tipo_pagamento.codigo = caixa_movimento.id_tipo_pagamento');
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
  conexao.SQL.Add
    ('SELECT * FROM pedido WHERE nfce_emite = 1 and id_caixa > 0  AND status > 0  AND data_pedido >= '
    + QuotedStr('2024-09-01') + ' and codigo_pedido_dia > 0');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoPostNotaSinc(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  DadosNF: TFDMemTable;
  Codigo: Integer;
  JSON: TJSONObject;
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

  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

  if Assigned(JSON) then
  begin

    if DadosNF.RecordCount > 0 then
    begin
      conexao.SQL.Add('delete from pedido_nfce where id_pedido = :pedido');
      conexao.Parametros('pedido', DadosNF.FieldByName('codigo').AsInteger);
      conexao.ExecuteSQL;

      Codigo := conexao.GerarID('pedido_nfce', 'id');
      conexao.SQL.Add
        ('insert into pedido_nfce (id,id_pedido,chave,protocolo,caminho,path) values (:id,:id_pedido,:chave,:protocolo,:caminho,:path)');
      conexao.Parametros('id', Codigo);
      conexao.Parametros('id_pedido', DadosNF.FieldByName('codigo').AsInteger);
      conexao.Parametros('chave', DadosNF.FieldByName('nfce_chave').AsString);
      conexao.Parametros('protocolo', DadosNF.FieldByName('nfce_protocolo')
        .AsString);
      conexao.Parametros('path', JSON.GetValue('path').Value);
      conexao.Parametros('caminho', JSON.GetValue('caminho').Value);
      conexao.ExecuteSQL;

    end;

  end;

  DadosNF.Free;

  conexao.Free;
end;

procedure DoPostEmissaoNFCe(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Chave: String;

  path: String;
begin
  conexao := TConexao.Create('nfce');

  if (Req.Params['chave'] = 'CANCELADA') then
  begin
    conexao.SQL.Add
      ('select 0 as zero, nfce_chave from pedido where codigo = :codigo');
    conexao.Parametros('codigo', Req.Params['codigo']);
    Chave := conexao.FieldByName('nfce_chave');
    DeletarNFCe(frmServidor.Configuracoes.FieldByName('cnpj').AsString, Chave);
  end
  else
  begin
    frmServidor.memErrosNFCE.Close;
    frmServidor.memErrosNFCE.Open;

    if frmServidor.memErrosNFCE.RecordCount > 0 then
    begin
      if frmServidor.memErrosNFCE.Locate('pedido', Req.Params['codigo']) then
      begin
        frmServidor.memErrosNFCE.Delete;
        frmServidor.memErrosNFCE.Last;
      end;
    end;

    conexao.SQL.Add
      ('select 0, nfce_imprimir from pedido where codigo = :codigo');
    conexao.Parametros('codigo', Req.Params['codigo']);
    try
      if conexao.FieldByName('nfce_imprimir') = '1' then
      begin
        conexao.SQL.Add
          ('insert into impressao_pedido_nfce (id_pedido) values (:codigo)');
        conexao.Parametros('codigo', Req.Params['codigo']);
        conexao.ExecuteSQL;
      end;

    except

    end;

  end;



  // alter table pedido_nfce add path varchar(255);

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
      ('delete from impressao_pedido_nfce where id_pedido = :codigo');
    conexao.Parametros('codigo', Objec.GetValue('id').Value);
    conexao.ExecuteSQL;
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
  RESTClient := TRESTClient.Create(API_NFCE + 'deletar.php');
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
      // ////showmessage1('Resposta do servidor: ' + RESTResponse.Content);
    end
    else
    begin
      // ////showmessage1('Erro na requisição. Código: ' + RESTResponse.StatusCode.ToString);
    end;
  finally
    RESTRequest.Free;
    RESTResponse.Free;
    RESTClient.Free;
  end;
end;

procedure DoPostDFESincronizar(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  JSONBody, JSONConsulta, JSONDocs, JSONDoc: TJSONObject;
  JSONArray: TJSONArray;
  idConsulta, idDoc: Integer;
  i: Integer;
begin
  conexao := TConexao.Create('nfce'); // usa o mesmo alias que tu já tens
  try
    JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    if not Assigned(JSONBody) then
      raise Exception.Create('JSON inválido.');

    // --- Bloco "consulta" ---
    JSONConsulta := JSONBody.GetValue('consulta') as TJSONObject;
    idConsulta := conexao.GerarID('dfe_consulta', 'id');
    conexao.SQL.Add
      ('INSERT INTO dfe_consulta (id, cnpj_empresa, data_consulta, hora_consulta, ultimo_nsu, qtd_documentos, ambiente) '
      + 'VALUES (:id, :cnpj_empresa, curdate(), curtime(), :ultimo_nsu, :qtd_documentos, :ambiente)');
    conexao.Parametros('id', idConsulta);
    conexao.Parametros('cnpj_empresa', Req.Params['cnpj']);
    conexao.Parametros('ultimo_nsu', JSONConsulta.GetValue('ultimo_nsu').Value);
    conexao.Parametros('qtd_documentos',
      JSONConsulta.GetValue('qtd_documentos').Value);
    conexao.Parametros('ambiente', 'producao');
    conexao.ExecuteSQL;

    // --- Bloco "documentos" ---
    JSONArray := JSONBody.GetValue('documentos') as TJSONArray;
    if Assigned(JSONArray) then
    begin
      for i := 0 to JSONArray.Count - 1 do
      begin
        JSONDoc := JSONArray.Items[i] as TJSONObject;
        idDoc := conexao.GerarID('dfe_documento', 'id');
        conexao.SQL.Add
          ('INSERT INTO dfe_documento (id, id_consulta, nsu, chave, cnpj_emitente, nome_emitente, valor, data_emissao, situacao, tipo) '
          + 'VALUES (:id, :id_consulta, :nsu, :chave, :cnpj_emitente, :nome_emitente, :valor, :data_emissao, :situacao, :tipo)');
        conexao.Parametros('id', idDoc);
        conexao.Parametros('id_consulta', idConsulta);
        conexao.Parametros('nsu', JSONDoc.GetValue('nsu')
          .ToString.Replace('"', ''));
        conexao.Parametros('chave', JSONDoc.GetValue('chave')
          .ToString.Replace('"', ''));
        conexao.Parametros('cnpj_emitente', JSONDoc.GetValue('cnpj_emitente')
          .ToString.Replace('"', ''));
        conexao.Parametros('nome_emitente', JSONDoc.GetValue('emitente')
          .ToString.Replace('"', ''));
        conexao.Parametros('valor', JSONDoc.GetValue('valor')
          .ToString.Replace('"', ''));
        conexao.Parametros('data_emissao', JSONDoc.GetValue('data_emissao')
          .ToString.Replace('"', ''));
        conexao.Parametros('situacao', JSONDoc.GetValue('situacao')
          .ToString.Replace('"', ''));

        conexao.Parametros('tipo', 'nfe');
        conexao.ExecuteSQL;
      end;
    end;

    Res.Send('Registros sincronizados com sucesso!');
  finally
    conexao.Free;
  end;
end;

procedure DoGetUltimoNSU(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
begin
  conexao := TConexao.Create('nfce');
  Dados := TFDMemTable.Create(nil);
  try
    conexao.SQL.Add
      ('SELECT ultimo_nsu FROM dfe_consulta WHERE cnpj_empresa = :cnpj ORDER BY id DESC LIMIT 1');
    conexao.Parametros('cnpj', Req.Params['cnpj']);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    if Dados.RecordCount > 0 then
      Res.Send(Dados.FieldByName('ultimo_nsu').AsString)
    else
      Res.Send('0');
  finally
    Dados.Free;
    conexao.Free;
  end;
end;

procedure DoGetNotasDFe(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  DataInicio, DataFim: string;
  SQL: string;
begin
  conexao := TConexao.Create('nfce'); // ou 'erp', se for outro alias
  try
    DataInicio := Req.Params['data_inicio'];
    DataFim := Req.Params['data_fim'];

    SQL := 'SELECT ' + '  dfe.id, ' + '  dfe.nsu, ' + '  dfe.chave, ' +
      '  dfe.cnpj_emitente, ' + '  dfe.nome_emitente, ' + '  dfe.valor AS vNF, '
      + '  dfe.data_emissao, ' +
      '  CASE WHEN nf.id IS NOT NULL THEN "sim" ELSE "nao" END AS importada ' +
      'FROM dfe_documento dfe ' +
      'LEFT JOIN nota_fiscal nf ON nf.chave COLLATE utf8mb4_general_ci = dfe.chave COLLATE utf8mb4_general_ci '
      + 'WHERE DATE(dfe.data_emissao) BETWEEN :data_inicio AND :data_fim ' +
      'ORDER BY dfe.data_emissao DESC';
    conexao.SQL.Add(SQL);
    conexao.Parametros('data_inicio', DataInicio);
    conexao.Parametros('data_fim', DataFim);

    Res.Send<TJSONArray>(conexao.ConsultaSQL);
  finally
    conexao.Free;
  end;
end;

procedure DoVerificaConsulta(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  ambiente: string;
begin
  ambiente := Req.Params['ambiente'];

  conexao := TConexao.Create(''); // ou o database correto
  try
    conexao.SQL.Add('SELECT ' + '   dc.id, ' + '   dc.ultimo_nsu, ' +
      '   dc.data_consulta, ' + '   dc.hora_consulta, ' + '   CASE ' +
      '       WHEN TIMESTAMP(dc.data_consulta, dc.hora_consulta) <= NOW() - INTERVAL 1 HOUR '
      + '       THEN 1 ELSE 0 ' + '   END AS status ' + 'FROM dfe_consulta dc '
      + 'WHERE dc.ambiente =  ' + ambiente + ' ORDER BY dc.id DESC ' +
      'LIMIT 1');

    Res.Send(conexao.ConsultaSQL);
  finally
    conexao.Free;
  end;
end;

procedure DoGetNotasFiscais(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexaoNotas, conexaoItens: TConexao;
  Notas, Itens: TFDMemTable;
  JSONNotas, JSONItens, JSONNota: TJSONArray;
  NotaObj, Retorno: TJSONObject;
  DataInicio, DataFim: string;
begin
  Res.Send(BuscaDadosFornecedor(Req.Params['data_inicio'],
    Req.Params['data_fim']));
  // conexaoNotas := TConexao.Create('nfce');
  // conexaoItens := TConexao.Create('nfce');
  // Notas := TFDMemTable.Create(nil);
  // Itens := TFDMemTable.Create(nil);
  // try
  // // Pega parâmetros
  // DataInicio := Req.Params['data_inicio'];
  // DataFim := Req.Params['data_fim'];
  //
  // // Consulta notas
  // conexaoNotas.SQL.Add
  // ('SELECT nf.id, nf.fornecedor_id, nf.serie, nf.numero, nf.chave, nf.tipo, '
  // + 'nf.data_emissao, nf.data_entrada, nf.vNF, nf.vFrete, nf.vDesc, nf.vOutro, '
  // + 'CASE WHEN dfe.id IS NOT NULL THEN "sim" ELSE "nao" END AS de_dfe ' +
  // 'FROM nota_fiscal nf ' +
  // 'LEFT JOIN dfe_documento dfe ON dfe.chave COLLATE utf8mb4_general_ci = nf.chave COLLATE utf8mb4_general_ci '
  // + 'WHERE nf.data_emissao BETWEEN :data_inicio AND :data_fim ' +
  // 'ORDER BY nf.data_emissao DESC');
  //
  // conexaoNotas.Parametros('data_inicio', DataInicio);
  // conexaoNotas.Parametros('data_fim', DataFim);
  // Notas.LoadFromJSON(conexaoNotas.ConsultaSQL);
  //
  // JSONNotas := TJSONArray.Create;
  //
  // // Para cada nota, busca os itens
  // while not Notas.Eof do
  // begin
  // NotaObj := TJSONObject.Create;
  // NotaObj.AddPair('id', Notas.FieldByName('id').AsString);
  // NotaObj.AddPair('fornecedor_id', Notas.FieldByName('fornecedor_id')
  // .AsString);
  // NotaObj.AddPair('serie', Notas.FieldByName('serie').AsString);
  // NotaObj.AddPair('numero', Notas.FieldByName('numero').AsString);
  // NotaObj.AddPair('chave', Notas.FieldByName('chave').AsString);
  // NotaObj.AddPair('tipo', Notas.FieldByName('tipo').AsString);
  // NotaObj.AddPair('data_emissao', Notas.FieldByName('data_emissao').AsString);
  // NotaObj.AddPair('data_entrada', Notas.FieldByName('data_entrada').AsString);
  // NotaObj.AddPair('vNF', TJSONNumber.Create(Notas.FieldByName('vNF').AsFloat));
  // NotaObj.AddPair('vFrete', TJSONNumber.Create(Notas.FieldByName('vFrete').AsFloat));
  // NotaObj.AddPair('vDesc', TJSONNumber.Create(Notas.FieldByName('vDesc').AsFloat));
  // NotaObj.AddPair('vOutro', TJSONNumber.Create(Notas.FieldByName('vOutro').AsFloat));
  // NotaObj.AddPair('de_dfe', Notas.FieldByName('de_dfe').AsString);
  //
  // // Busca itens dessa nota
  // conexaoItens.SQL.Clear;
  // conexaoItens.SQL.Add
  // ('SELECT id, nota_fiscal_id, cProd, xProd, NCM, CFOP, qCom, uCom, vUnCom, vProd, vDesc, vFrete, vOutro, vTotal, uTrib '
  // + 'FROM nota_fiscal_item WHERE nota_fiscal_id = :id');
  // conexaoItens.Parametros('id', Notas.FieldByName('id').AsString);
  // Itens.LoadFromJSON(conexaoItens.ConsultaSQL);
  //
  // JSONItens := TJSONArray.Create;
  // while not Itens.Eof do
  // begin
  // JSONItens.AddElement(TJSONObject.Create.AddPair('id',
  // Itens.FieldByName('id').AsString).AddPair('cProd',
  // Itens.FieldByName('cProd').AsString).AddPair('xProd',
  // Itens.FieldByName('xProd').AsString).AddPair('NCM',
  // Itens.FieldByName('NCM').AsString).AddPair('CFOP',
  // Itens.FieldByName('CFOP').AsString).AddPair('qCom',
  // TJSONNumber.Create(Itens.FieldByName('qCom').AsFloat)).AddPair('uCom',
  // Itens.FieldByName('uCom').AsString).AddPair('vUnCom',
  // TJSONNumber.Create(Itens.FieldByName('vUnCom').AsFloat))
  // .AddPair('vProd', TJSONNumber.Create(Itens.FieldByName('vProd')
  // .AsFloat)).AddPair('vDesc',
  // TJSONNumber.Create(Itens.FieldByName('vDesc').AsFloat))
  // .AddPair('vFrete', TJSONNumber.Create(Itens.FieldByName('vFrete')
  // .AsFloat)).AddPair('vOutro',
  // TJSONNumber.Create(Itens.FieldByName('vOutro').AsFloat))
  // .AddPair('vTotal', TJSONNumber.Create(Itens.FieldByName('vTotal')
  // .AsFloat)).AddPair('uTrib', Itens.FieldByName('uTrib').AsString));
  // Itens.Next;
  // end;
  // NotaObj.AddPair('itens', JSONItens);
  //
  // JSONNotas.AddElement(NotaObj);
  // Notas.Next;
  // end;
  //
  // //BuscaDadosFornecedor
  //
  // Res.Send<TJSONArray>(JSONNotas);
  //
  // finally
  // Notas.Free;
  // Itens.Free;
  // conexaoNotas.Free;
  // conexaoItens.Free;
  // end;
end;

procedure Registry;
begin
  THorse.Get('/nfce/pedido/outras/:codigo', DoGetPedidoOutros);
  THorse.Get('/nfce/pedido/produtos/:codigo', DoGetProdutosPedido);
  THorse.Get('/nfce/pedido/pagamento/:codigo', DoGetPedidoPagamento);
  THorse.Get('/nfce/numero', DoGetNumeroNota);
  THorse.Get('/nfce/lote', DoGetNumeroLote);
  THorse.Get('/nfce/emissao', DOGetNFCeEmissao);
  THorse.Post('/nfce/emissao/:codigo/:numero/:chave/:protocolo/:ambiente',
    DoPostEmissaoNFCe);

  THorse.Get('/nfce/contabilidade', DoGetNFceContabilidade);
  THorse.Post('/nfce/contabilidade/:status/:msg', DoPostNFceContabilidade);
  THorse.Get('/nfce/contabilidade/notas/:mes', DoGetNotas);

  THorse.Post('/nfce/code/motivo', DoPostCodeMotivo);
  THorse.Post('/nfce/code', DoPostCode);
  THorse.Get('/nfce/code', DoGetCode);

  THorse.Get('/nfce/notas/sinc', DoGetNotasPendentesSinc);
  THorse.Post('/nfce/nota/sinc/:chave', DoPostNotaSinc);

  THorse.Post('/dfe/sincronizar/:cnpj', DoPostDFESincronizar);
  THorse.Get('/dfe/ultimo/:cnpj', DoGetUltimoNSU);
  THorse.Get('/dfe/notas/:data_inicio/:data_fim', DoGetNotasDFe);
  THorse.Get('/notas-fiscais/:data_inicio/:data_fim', DoGetNotasFiscais);
  THorse.Get('/dfe/verifica/:ambiente', DoVerificaConsulta);

end;

end.
