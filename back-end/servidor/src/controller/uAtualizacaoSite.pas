unit uAtualizacaoSite;

interface

uses uRequisicao, JOSE.Types.JSON, Conexao, FireDAC.Comp.Client,
  DataSet.Serialize,
  System.SysUtils, Dialogs;

procedure SincronizaTaxaEntrega(UserId: integer);
procedure SincronizaFormaPagamento(UserId: integer);
procedure SincronizaMotoboy(UserId: integer);
function SomenteNumeros(const Texto: string): string;

implementation

procedure SincronizaTaxaEntrega(UserId: integer);
var
  Conexao: TConexao;
  Dados: TFDMemTable;
  JsonObject: TJSONObject;
  JsonObjectCampo: TJSONObject;
  Requisicao: iRequisicao;

  ResultObj: TJSONObject;
  Success: Boolean;
  InsertId: integer;
begin

  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := 'https://api.goopedir.com.br/';
  Requisicao.URL := 'api/interno/insert/geral';
  Requisicao.Metodo := mPost;
  Conexao := TConexao.Create('SincronizaTaxaEntrega');
  Dados := TFDMemTable.Create(nil);
  Conexao.SQL.Add('SELECT * FROM taxa_entrega where modificado_site = 0');
  Dados.LoadFromJSON(Conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      JsonObject := TJSONObject.Create;
      JsonObjectCampo := TJSONObject.Create;
      JsonObject.AddPair('table', 'bairros_delivery');
      JsonObjectCampo.AddPair('id', Dados.FieldByName('id_site').AsInteger);
      JsonObjectCampo.AddPair('user_id', UserId);
      JsonObjectCampo.AddPair('uf', Dados.FieldByName('estado').AsString);
      JsonObjectCampo.AddPair('cidade', Dados.FieldByName('cidade').AsString);
      JsonObjectCampo.AddPair('bairro', Dados.FieldByName('bairro').AsString);
      JsonObjectCampo.AddPair('taxa', Dados.FieldByName('valor_taxa').AsFloat);
      JsonObjectCampo.AddPair('ativo', Dados.FieldByName('ativo').AsString);
      JsonObjectCampo.AddPair('tempo', Dados.FieldByName('tempo').AsString);
      JsonObject.AddPair('data', JsonObjectCampo);

      Requisicao.BODY(JsonObject);
      try
        Requisicao.Execute;
        JsonObject.Free;

        JsonObject := TJSONObject.ParseJSONValue(Requisicao.Retorno)
          as TJSONObject;
        try
          Success := JsonObject.GetValue<Boolean>('success');
          ResultObj := JsonObject.GetValue<TJSONObject>('result');
          InsertId := ResultObj.GetValue<integer>('insertId');

          if InsertId > 0 then
          begin
            Conexao.SQL.Add
              ('update taxa_entrega set modificado_site = 1, id_site = :site where codigo = :codigo');
            Conexao.Parametros('site', InsertId);
          end
          else
          begin
            Conexao.SQL.Add
              ('update taxa_entrega set modificado_site = 1 where codigo = :codigo');
          end;

          Conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
          Conexao.ExecuteSQL;

        finally
          JsonObject.Free;
        end;
      except
        JsonObject.Free;
      end;

      Dados.Next;
    end;
  end;

  if Assigned(Conexao) then
    Conexao.Free;
  if Assigned(Requisicao) then
    Requisicao.Free;
  if Assigned(Dados) then
    Dados.Free;
end;

procedure SincronizaFormaPagamento(UserId: integer);
var
  Conexao: TConexao;
  Dados: TFDMemTable;
  JsonObject: TJSONObject;
  JsonObjectCampo: TJSONObject;
  Requisicao: iRequisicao;

  ResultObj: TJSONObject;
  Success: Boolean;
  InsertId: integer;
begin

  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := 'https://api.goopedir.com.br/';
  Requisicao.URL := 'api/interno/insert/geral';
  Requisicao.Metodo := mPost;
  Conexao := TConexao.Create('SincronizaFormaPagamento');
  Dados := TFDMemTable.Create(nil);
  Conexao.SQL.Add('SELECT * FROM tipo_pagamento where modificado_site = 0');
  Dados.LoadFromJSON(Conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      if (Dados.FieldByName('chave_recebedor').AsString = 'null') then
      begin
        Dados.Edit;
        Dados.FieldByName('chave_recebedor').AsString := '';
        Dados.FieldByName('chave_pix').AsString := '';
        Dados.FieldByName('tipo_chave_pix').AsString := '';
      end;

      JsonObject := TJSONObject.Create;
      JsonObjectCampo := TJSONObject.Create;
      JsonObject.AddPair('table', 'ws_formas_pagamento');
      JsonObject.AddPair('id', 'id_f_pagamento');

      JsonObjectCampo.AddPair('id_f_pagamento', Dados.FieldByName('id_site')
        .AsInteger);
      JsonObjectCampo.AddPair('user_id', UserId);
      JsonObjectCampo.AddPair('f_pagamento', Dados.FieldByName('descricao')
        .AsString);
      JsonObjectCampo.AddPair('ativo', Dados.FieldByName('ativo').AsString);
      JsonObjectCampo.AddPair('tipo', Dados.FieldByName('tipo_chave_pix')
        .AsString);
      JsonObjectCampo.AddPair('chave', Dados.FieldByName('chave_pix').AsString);
      JsonObjectCampo.AddPair('recebedor', Dados.FieldByName('chave_recebedor')
        .AsString);
      JsonObject.AddPair('data', JsonObjectCampo);

      Requisicao.BODY(JsonObject.ToString);
      try
        Requisicao.Execute;
        JsonObject.Free;

        JsonObject := TJSONObject.ParseJSONValue(Requisicao.Retorno)
          as TJSONObject;
        try
          Success := JsonObject.GetValue<Boolean>('success');
          ResultObj := JsonObject.GetValue<TJSONObject>('result');
          InsertId := ResultObj.GetValue<integer>('insertId');

          if InsertId > 0 then
          begin
            Conexao.SQL.Add
              ('update tipo_pagamento set modificado_site = 1, id_site = :site where codigo = :codigo');
            Conexao.Parametros('site', InsertId);
          end
          else
          begin
            Conexao.SQL.Add
              ('update tipo_pagamento set modificado_site = 1 where codigo = :codigo');
          end;

          Conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
          Conexao.ExecuteSQL;

        finally
          JsonObject.Free;
        end;
      except
        on E: Exception do
        begin

          JsonObject.Free;
        end;
      end;

      Dados.Next;
    end;
  end;
  if Assigned(Conexao) then
    Conexao.Free;
  if Assigned(Requisicao) then
    Requisicao.Free;
  if Assigned(Dados) then
    Dados.Free;
end;

procedure SincronizaMotoboy(UserId: integer);
var
  Conexao: TConexao;
  Dados: TFDMemTable;
  JsonObject: TJSONObject;
  JsonObjectCampo: TJSONObject;
  Requisicao: iRequisicao;

  ResultObj: TJSONObject;
  Success: Boolean;
  InsertId: integer;
begin

  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := 'https://api.goopedir.com.br/';
  Requisicao.URL := 'api/interno/insert/geral';
  Requisicao.Metodo := mPost;
  Conexao := TConexao.Create('SincronizaTaxaEntrega');
  Dados := TFDMemTable.Create(nil);
  Conexao.SQL.Add('SELECT * FROM motoboy where modificado_site = 0');
  Dados.LoadFromJSON(Conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin

      JsonObject := TJSONObject.Create;
      JsonObjectCampo := TJSONObject.Create;
      JsonObject.AddPair('table', 'ws_motoboys');
      JsonObjectCampo.AddPair('id', Dados.FieldByName('id_site').AsInteger);
      JsonObjectCampo.AddPair('user_id', UserId);
      JsonObjectCampo.AddPair('deliveryman_name', Dados.FieldByName('nome')
        .AsString);
      JsonObjectCampo.AddPair('deliveryman_phone_number',
        SomenteNumeros(Dados.FieldByName('celular_wpp').AsString));
      JsonObjectCampo.AddPair('senha', Dados.FieldByName('codigo').AsString);
      JsonObjectCampo.AddPair('id_local', Dados.FieldByName('codigo')
        .AsInteger);

      JsonObject.AddPair('data', JsonObjectCampo);

      Requisicao.BODY(JsonObject);
      try
        Requisicao.Execute;
        JsonObject.Free;

        JsonObject := TJSONObject.ParseJSONValue(Requisicao.Retorno)
          as TJSONObject;
        try
          Success := JsonObject.GetValue<Boolean>('success');
          ResultObj := JsonObject.GetValue<TJSONObject>('result');
          InsertId := ResultObj.GetValue<integer>('insertId');

          if InsertId > 0 then
          begin
            Conexao.SQL.Add
              ('update motoboy set modificado_site = 1, id_site = :site where codigo = :codigo');
            Conexao.Parametros('site', InsertId);
          end
          else
          begin
            Conexao.SQL.Add
              ('update motoboy set modificado_site = 1 where codigo = :codigo');
          end;

          Conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
          Conexao.ExecuteSQL;

        finally
          JsonObject.Free;
        end;
      except
        JsonObject.Free;
      end;

      Dados.Next;
    end;
  end;

  if Assigned(Conexao) then
    Conexao.Free;
  if Assigned(Requisicao) then
    Requisicao.Free;
  if Assigned(Dados) then
    Dados.Free;
end;

function SomenteNumeros(const Texto: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 1 to Length(Texto) do
    if Texto[I] in ['0' .. '9'] then
      Result := Result + Texto[I];
end;

end.
