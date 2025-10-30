unit uControllerSite;

interface

uses Conexao, FireDAC.Comp.Client, uInserirUpdate, System.SysUtils,
  uRequisicao, System.DateUtils, System.JSON, JOSE.Core.JWT, JOSE.Core.Builder,
  System.NetEncoding, System.Hash, DataSet.Serialize,
  REST.Client, Data.Bind.Components, Data.Bind.ObjectScope, uGlobais;

function SiteCategoria(codigo, user: Integer): Integer;
function SiteSabores(codigoGrupo, user: Integer): String;
procedure SiteEnviaFotoProduto(codigo: Integer; Base64: String; user: Integer);
function EnviaImagem(codigo, Base64: String): String;

function GerarTokenJWT(userId: Integer): string;
function PostCategoriaTipoProdutoExpress(userId, codigo: Integer): Integer;
function PostProdutoExpress(userId, codigo: Integer): Integer;
function PostAdicionalCategoriaExpress(userId, idItem, codigo: Integer)
  : Integer;
function PostAdicionalItemExpress(userId, idAdicionalCat,
  codigo: Integer): Integer;

implementation

function PostAdicionalItemExpress(userId, idAdicionalCat,
  codigo: Integer): Integer;
var
  Requisicao: iRequisicao;
  Conexao: TConexao;
  A: String;
  JSONResp: TJSONObject;
begin
  Result := -1;
  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := API_BASE_URL;
  Requisicao.TempoExpiracao := 30 * 1000;

  Requisicao.URL := 'api/interno/adicional/item';
  Requisicao.Metodo := mPost;

  Conexao := TConexao.Create('uSite');
  Conexao.SQL.Add
    ('select * from pro_adi_personalizado_sabores where id = :codigo');
  Conexao.Parametros('codigo', codigo);

  try
    Requisicao.AddHEader('user', userId.ToString);
    Requisicao.AddHEader('idadicionalcat', idAdicionalCat.ToString);
    A := Conexao.ConsultaSQL.ToJSON;
    A := StringReplace(A, 'Null', '', []);
    A := StringReplace(A, 'null', '""', [rfReplaceAll]);
    Requisicao.BODY(A);
    Requisicao.Execute;

    if Requisicao.Status = 200 then
    begin
      JSONResp := TJSONObject.ParseJSONValue(Requisicao.Retorno) as TJSONObject;
      try
        if JSONResp.GetValue<Boolean>('sucesso') then
          Result := JSONResp.GetValue<Integer>('id');
      finally
        JSONResp.Free;
      end;
    end;
  finally
    Conexao.Free;
    Requisicao.Free;
  end;
end;

function PostAdicionalCategoriaExpress(userId, idItem, codigo: Integer)
  : Integer;
var
  Requisicao: iRequisicao;
  Conexao: TConexao;
  A: String;
  JSONResp: TJSONObject;
begin
  Result := -1;
  Requisicao := iRequisicao.Create(nil);

  Requisicao.BaseURL := API_BASE_URL;

  Requisicao.TempoExpiracao := 30 * 1000;

  Requisicao.URL := 'api/interno/adicional/categoria';
  Requisicao.Metodo := mPost;

  Conexao := TConexao.Create('uSite');
  Conexao.SQL.Add('select * from pro_adi_personalizado where id = :codigo');
  Conexao.Parametros('codigo', codigo);

  try
    Requisicao.AddHEader('user', userId.ToString);
    Requisicao.AddHEader('iditem', idItem.ToString);
    A := Conexao.ConsultaSQL.ToJSON;
    A := StringReplace(A, 'null', '""', [rfReplaceAll]);

    Requisicao.BODY(A);
    Requisicao.Execute;

    if Requisicao.Status = 200 then
    begin
      JSONResp := TJSONObject.ParseJSONValue(Requisicao.Retorno) as TJSONObject;
      try
        if JSONResp.GetValue<Boolean>('sucesso') then
          Result := JSONResp.GetValue<Integer>('id');
      finally
        JSONResp.Free;
      end;
    end;
  finally
    Conexao.Free;
    Requisicao.Free;
  end;
end;

function PostProdutoExpress(userId, codigo: Integer): Integer;
var
  Requisicao: iRequisicao;
  Conexao: TConexao;
  A: String;
  JSONResp: TJSONObject;
  Dados: TFDMemTable;
  Categoria: Integer;
begin
  Result := -1;
  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := API_BASE_URL;
  Requisicao.TempoExpiracao := 30 * 1000;
  Requisicao.URL := 'api/interno/produto'; // rota no Node
  Requisicao.Metodo := mPost;
  Conexao := TConexao.Create('uSite');
  Conexao.SQL.Add('select * from produto where codigo = :codigo');
  Conexao.Parametros('codigo', codigo);

  Dados := TFDMemTable.Create(nil);

  try
    A := Conexao.ConsultaSQL.ToJSON;
    Dados.LoadFromJSON(A);
    Requisicao.AddHEader('user', userId.ToString);
    Requisicao.AddHEader('codigo', codigo.ToString);
    Categoria := SiteCategoria(Dados.FieldByName('codigo_grupo')
      .AsInteger, userId);
    if Categoria > 0 then
    begin
      Requisicao.AddHEader('categoria', Categoria.ToString);
      A := StringReplace(A, 'null', '""', [rfReplaceAll]);
      Requisicao.BODY(A);
      Requisicao.Execute;

      if Requisicao.Status = 200 then
      begin
        JSONResp := TJSONObject.ParseJSONValue(Requisicao.Retorno)
          as TJSONObject;
        try
          if JSONResp.GetValue<Boolean>('sucesso') then
            Result := JSONResp.GetValue<Integer>('id');
        finally
          JSONResp.Free;
        end;
      end;
    end;
  finally
    Conexao.Free;
    Requisicao.Free;
    Dados.Free;
  end;
end;

function PostCategoriaTipoProdutoExpress(userId, codigo: Integer): Integer;
var

  Requisicao: iRequisicao;
  Conexao: TConexao;
  Query: TFDQuery;
  A: String;
begin
  Result := -1; // valor padrão em caso de erro
  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := API_BASE_URL;
  Requisicao.TempoExpiracao := 30 * 1000;
  Requisicao.URL := 'api/interno/categoria/tipo/produto';
  Requisicao.Metodo := mPost;

  Conexao := TConexao.Create('uSite');
  Conexao.SQL.Add('select * from tipo_produto where codigo = :codigo');
  Conexao.Parametros('codigo', codigo);

  try
    Requisicao.AddHEader('user', userId.ToString);
    Requisicao.AddHEader('codigo', codigo.ToString);
    A := Conexao.ConsultaSQL.ToJSON;
    Requisicao.BODY(A);
    A := StringReplace(A, 'null', '""', [rfReplaceAll]);
    Requisicao.Execute;

    if Requisicao.Status = 200 then
    begin
      var
      JSONResp := TJSONObject.ParseJSONValue(Requisicao.Retorno) as TJSONObject;
      try
        if (JSONResp.GetValue<Boolean>('sucesso')) then
          Result := JSONResp.GetValue<Integer>('id');
      finally
        JSONResp.Free;
      end;
    end

  finally
    Requisicao.Free;
  end;
end;

function SiteCategoria(codigo, user: Integer): Integer;
var
  Conexao: TConexao;
  Query: TFDQuery;
begin
  Result := PostCategoriaTipoProdutoExpress(user, codigo);
  if Result > 0 then
  begin
    Conexao := TConexao.Create('uSite');
    Conexao.SQL.Add
      ('update tipo_produto set modificado_site = 1, id_site = :site where codigo = :codigo');
    Conexao.Parametros('site', Result);
    Conexao.Parametros('codigo', codigo);
    Conexao.ExecuteSQL;
    Conexao.Free;
  end;
end;

function SiteSabores(codigoGrupo, user: Integer): String;
var
  Conexao: TConexao;
  Query: TFDQuery;
  Requisicao: iRequisicao;
  Sabores: TJsonArray;
  I: Integer;
begin
  Conexao := TConexao.Create('uSite');
  Query := Conexao.CriaQRY;
  try
    Query.SQL.Text :=
      'SELECT cs.id, cs.id_site, cs.nome, cs.descricao, cs.vl_venda as valor, cs.ativo, ts.nome as tipo, '
      + 'p.id_site as id_itens, pp.quantidade_sabores as qtd_sabor, ' +
      '(SELECT tipo_preco_pizza FROM dados_whatsapp limit 1) as tipo_valor ' +
      'FROM sabores_completo as cs ' +
      'join tipo_sabor as ts on ts.id = cs.id_tipo_sabor ' +
      'join produto as p on p.codigo = cs.id_produto ' +
      'join produto_pizza as pp on pp.codigo_produto = p.codigo ' +
      'where p.codigo_grupo = :codigo';
    Query.ParamByName('codigo').AsInteger := codigoGrupo;
    Query.Open;
    if Query.RecordCount > 0 then
    begin

      Result := Query.ToJSONArray().ToString;
      Requisicao := iRequisicao.Create(nil);
      Requisicao.BaseURL := API_BASE_URL;
      Requisicao.URL := 'api/sabores';
      Requisicao.Metodo := mPost;
      Requisicao.BODY(Result);
      Requisicao.TempoExpiracao := (60 * 1000);
      Requisicao.Execute;

      Sabores := TJsonArray.ParseJSONValue(Requisicao.Retorno) as TJsonArray;
      for I := 0 to Sabores.Count - 1 do
      begin
        if Sabores[I].GetValue<Integer>('idSite') > 0 then
        begin
          Conexao.SQL.Add('update sabores_completo set modificado_site = 1, id_site = :site where id = :id');
          Conexao.Parametros('site',Sabores[I].GetValue<Integer>('idSite'));
          Conexao.Parametros('id',Sabores[I].GetValue<Integer>('id'));
          Conexao.ExecuteSQL;
        end;

      end;
      Sabores.Free;
    end;

  except
  on E : Exception do
  begin
    Result := E.Message;
  end;

  end;
  Query.Free;
  Conexao.Free;
  //
  // try

  //
  // if Query.RecordCount > 0 then
  // begin
  //
  // while not Query.Eof do
  // begin
  // codigo := InserirUpdate('ws_sabores', user.ToString,
  // ['id', 'user_id', 'id_itens', 'qtd_sabor', 'ativo', 'tipo_valor',
  // 'valor', 'tipo', 'sabor', 'descricao'],
  // [Query.FieldByName('id_site').AsWideString, user.ToString,
  // Query.FieldByName('id_itens').AsWideString,
  // Query.FieldByName('qtd_sabor').AsWideString,
  // Query.FieldByName('ativo').AsWideString,
  // Query.FieldByName('tipo_valor').AsWideString,
  // Query.FieldByName('valor').AsWideString, Query.FieldByName('tipo')
  // .AsWideString, Trim(Query.FieldByName('nome').AsWideString),
  // Trim(Query.FieldByName('descricao').AsWideString)]);
  //
  // if codigo > 0 then
  // begin
  // SQL := 'update sabores_completo set modificado_site = 1 where id = ' +
  // Query.FieldByName('id').AsWideString;
  // Conexao.ExecuteSQL(SQL);
  //
  // SQL := 'update sabores_completo set id_site = ' + codigo.ToString +
  // ' where id = ' + Query.FieldByName('id').AsWideString;
  // Conexao.ExecuteSQL(SQL);
  // end;
  //
  // Query.Next;
  // end;
  // end;
  //
  // finally
  // Query.Free;
  // Conexao.Free;
  // end;
end;

procedure SiteEnviaFotoProduto(codigo: Integer; Base64: String; user: Integer);
var
  Conexao: TConexao;
  URL: String;
  CodigoImagem: String;
begin
  CodigoImagem := codigo.ToString;
  if user > 0 then
    CodigoImagem := user.ToString + '-' + codigo.ToString;
  URL := EnviaImagem(CodigoImagem, Base64);
  Conexao := TConexao.Create('uSite');
  Conexao.SQL.Add
    ('update produto set caminho_imagem = :img, foto_ifood = :img where codigo = :codigo');
  Conexao.Parametros('img', URL);
  Conexao.Parametros('codigo', codigo);
  Conexao.ExecuteSQL;
  Conexao.Free;

end;

function EnviaImagem(codigo, Base64: string): string;
var
  Requisicao: iRequisicao;
  JsonRetorno: TJSONObject;
begin
  Requisicao := iRequisicao.Create(nil);
  try
    Requisicao.BaseURL := API_FOTO;
    Requisicao.AddHEader('nome', codigo);
    Requisicao.AddHEader('Content-Type', 'application/json');
    Requisicao.Metodo := mPost;
    Requisicao.BODY(Base64);
    Requisicao.TempoExpiracao := 15 * 1000;

    Requisicao.Execute;

    // Extrai a URL do JSON retornado
    JsonRetorno := TJSONObject.ParseJSONValue(Requisicao.Retorno)
      as TJSONObject;
    try
      if Assigned(JsonRetorno) then
      begin
        if JsonRetorno.GetValue('url') <> nil then
          Result := JsonRetorno.GetValue('url').Value
        else if JsonRetorno.GetValue('success') <> nil then
          Result := '' // Ou tratar como erro, conforme sua necessidade
        else
          Result := ''; // Caso o JSON não tenha a estrutura esperada
      end
      else
        Result := ''; // Caso o retorno não seja um JSON válido
    finally
      JsonRetorno.Free;
    end;
  except
    on E: Exception do
    begin
      // Você pode querer registrar o erro em algum log aqui
      Result := ''; // Retorna vazio em caso de erro
    end;
  end;
  Requisicao.Free;
end;

function GerarTokenJWT(userId: Integer): string;
const
  CHAVE_SECRETA = 'ALLAN@GOOPEDIR.COM.BR2023'; // Mesma chave usada no Node.js
var
  header, payload, signature: string;
  headerBase64, payloadBase64, signatureBase64: string;
  signatureBytes: TBytes;
begin
  // 1. Header
  header := '{"alg":"HS256","typ":"JWT"}';
  headerBase64 := TNetEncoding.Base64URL.Encode(header);

  // 2. Payload
  payload := Format('{"userId":%d,"iat":%d,"exp":%d}',
    [userId, DateTimeToUnix(Now), DateTimeToUnix(IncSecond(Now, 11000))
    // 60 segundos
    ]);
  payloadBase64 := TNetEncoding.Base64URL.Encode(payload);

  // 3. Assinatura (CRÍTICO)
  signatureBytes := THashSHA2.GetHMACAsBytes(headerBase64 + '.' + payloadBase64,
    CHAVE_SECRETA, THashSHA2.TSHA2Version.SHA256);
  signatureBase64 := TNetEncoding.Base64URL.EncodeBytesToString(signatureBytes);

  // 4. Token final
  Result := headerBase64 + '.' + payloadBase64 + '.' + signatureBase64;
end;

end.
