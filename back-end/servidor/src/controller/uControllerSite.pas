unit uControllerSite;

interface

uses Conexao, FireDAC.Comp.Client, uInserirUpdate, System.SysUtils,
  uRequisicao, System.DateUtils, System.JSON, JOSE.Core.JWT, JOSE.Core.Builder, System.NetEncoding, System.Hash;

function SiteCategoria(codigo, user: Integer): Integer;
procedure SiteSabores(codigoGrupo, user: Integer);
procedure SiteEnviaFotoProduto(codigo: Integer; Base64: String);
function EnviaImagem(Codigo,Base64 : String):String;

function GerarTokenJWT(userId: Integer): string;

implementation

function SiteCategoria(codigo, user: Integer): Integer;
var
  Conexao: TConexao;
  Query: TFDQuery;
begin
  Conexao := TConexao.Create('uSite');
  Query := Conexao.CriaQRY;
  try
    Query.SQL.Text := 'select * from tipo_produto where codigo = :codigo';
    Query.ParamByName('codigo').AsInteger := codigo;
    Query.Open;

    Result := InserirUpdate('ws_cat', user.ToString,
      ['id', 'user_id', 'dias_semana', 'nome_cat', 'desc_cat', 'icon_cat',
      'ordem', 'descricao', 'borda_topo_direito', 'borda_topo_esquerdo',
      'borda_inferior_direito', 'borda_inferior_esquerdo', 'espacamento',
      'fonte_nome', 'fonte_descricao', 'cor_fundo', 'cor_nome',
      'cor_descricao','altura','opacidade','local','pizza'], [Query.FieldByName('id_site').AsString, user.ToString,
      'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado',
      Query.FieldByName('descricao').AsWideString, '', Query.FieldByName('url').AsWideString,
      Query.FieldByName('ordem').AsString, Query.FieldByName('descricao_cat')
      .AsWideString, Query.FieldByName('borda_topo_direito').AsWideString,
      Query.FieldByName('borda_topo_esquerdo').AsWideString,
      Query.FieldByName('borda_inferior_direito').AsWideString,
      Query.FieldByName('borda_inferior_esquerdo').AsWideString,
      Query.FieldByName('espacamento').AsWideString,
      Query.FieldByName('fonte_nome').AsWideString,
      Query.FieldByName('fonte_descricao').AsWideString,
      Query.FieldByName('cor_fundo').AsWideString, Query.FieldByName('cor_nome')
      .AsWideString, Query.FieldByName('cor_descricao').AsWideString,Query.FieldByName('espacamento').AsString, Query.FieldByName('opacidade').AsString,Query.FieldByName('local').AsString,Query.FieldByName('pizza').AsString]);

    if Result > 0 then
    begin
      Query.SQL.Text :=
        'update tipo_produto set modificado_site = 1, id_site = :site where codigo = :codigo';
      Query.ParamByName('site').AsInteger := Result;
      Query.ParamByName('codigo').AsInteger := codigo;
      Query.ExecSQL;
    end;

  finally
    Query.Free;
    Conexao.Free;
  end;
end;

procedure SiteSabores(codigoGrupo, user: Integer);
var
  Conexao: TConexao;
  Query: TFDQuery;
  codigo: Integer;
  SQL: String;
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
      while not Query.Eof do
      begin
        codigo := InserirUpdate('ws_sabores', user.ToString,
          ['id', 'user_id', 'id_itens', 'qtd_sabor', 'ativo', 'tipo_valor',
          'valor', 'tipo', 'sabor', 'descricao'],
          [Query.FieldByName('id_site').AsWideString, user.ToString,
          Query.FieldByName('id_itens').AsWideString,
          Query.FieldByName('qtd_sabor').AsWideString,
          Query.FieldByName('ativo').AsWideString,
          Query.FieldByName('tipo_valor').AsWideString,
          Query.FieldByName('valor').AsWideString, Query.FieldByName('tipo')
          .AsWideString, Trim(Query.FieldByName('nome').AsWideString),
          Trim(Query.FieldByName('descricao').AsWideString)]);

        if codigo > 0 then
        begin
          SQL := 'update sabores_completo set modificado_site = 1 where id = ' +
            Query.FieldByName('id').AsWideString;
          Conexao.ExecuteSQL(SQL);

          SQL := 'update sabores_completo set id_site = ' + codigo.ToString +
            ' where id = ' + Query.FieldByName('id').AsWideString;
          Conexao.ExecuteSQL(SQL);
        end;

        Query.Next;
      end;
    end;

  finally
    Query.Free;
    Conexao.Free;
  end;
end;

procedure SiteEnviaFotoProduto(codigo: Integer; Base64: String);
var
  Conexao: TConexao;
begin

 EnviaImagem(Codigo.ToString,Base64);
  Conexao := TConexao.Create('uSite');
  Conexao.SQL.Add('update produto set caminho_imagem = concat(' +
    QuotedStr('https://fotos.goopedir.com/fotos/') +
    ',TO_BASE64(:img)) where id_site = :codigo');
  Conexao.Parametros('img', codigo);
  Conexao.Parametros('codigo', codigo);
  Conexao.ExecuteSQL;
  Conexao.Free;



end;

function EnviaImagem(Codigo, Base64: string): string;
var
  Requisicao: iRequisicao;
  JsonRetorno: TJSONObject;
begin
  Requisicao := iRequisicao.Create(nil);
  try
    Requisicao.BaseURL := 'https://fotos.goopedir.com/';
    Requisicao.AddHeader('nome', Codigo);
    Requisicao.AddHeader('Content-Type', 'application/json');
    Requisicao.Metodo := mPost;
    Requisicao.Body(Base64);
    Requisicao.TempoExpiracao := 15 * 1000;

    Requisicao.Execute;

    // Extrai a URL do JSON retornado
    JsonRetorno := TJSONObject.ParseJSONValue(Requisicao.Retorno) as TJSONObject;
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
  payload := Format('{"userId":%d,"iat":%d,"exp":%d}', [
    userId,
    DateTimeToUnix(Now),
    DateTimeToUnix(IncSecond(Now, 11000)) // 60 segundos
  ]);
  payloadBase64 := TNetEncoding.Base64URL.Encode(payload);

  // 3. Assinatura (CRÍTICO)
  signatureBytes := THashSHA2.GetHMACAsBytes(
    headerBase64 + '.' + payloadBase64,
    CHAVE_SECRETA,
    THashSHA2.TSHA2Version.SHA256
  );
  signatureBase64 := TNetEncoding.Base64URL.EncodeBytesToString(signatureBytes);

  // 4. Token final
  Result := headerBase64 + '.' + payloadBase64 + '.' + signatureBase64;
end;

end.
