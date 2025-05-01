unit token;

interface

uses FireDAC.Comp.Client;

procedure Registry;

implementation

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, JSON, uDM, conexao,
  Data.DB, DataSet.Serialize, EncdDecd, Horse.BasicAuthentication,
  System.Classes, Horse.Commons, System.NetEncoding, DateUtils;

function ChaveEnviar: Integer;
begin
  Result := 650;
end;

function EnDecryptString(parstring: string; parchave: Word): string;
var
  I, TamanhoString, Pos, PosLetra, TamanhoChave: Integer;
  chave: string;
begin
  chave := inttostr(parchave);
  Result := parstring;
  TamanhoString := Length(parstring);
  TamanhoChave := Length(chave);
  for I := 1 to TamanhoString do
  begin
    Pos := (I mod TamanhoChave);
    if Pos = 0 then
      Pos := TamanhoChave;
    PosLetra := ord(Result[I]) xor ord(chave[Pos]);
    if PosLetra = 0 then
      PosLetra := ord(Result[I]);
    Result[I] := Chr(PosLetra);
  end;
end;

function DescripEnvio(Valor: String): String;
var
  I: Integer;
begin
  Result := Valor;
  for I := 1 to 3 do
  begin
    Result := DecodeString(Result);
    Result := EnDecryptString(Result, ChaveEnviar);
  end;
end;

function CripEnvio(Valor: String): String;
var
  I: Integer;
begin
  Result := Valor;
  for I := 1 to 3 do
  begin
    Result := EnDecryptString(Result, ChaveEnviar);
    Result := EncodeString(Result);
  end;

end;

function DescriptBasicAuth(Valor: String): String;
var
  I: Integer;
begin
  Result := Valor;
  for I := 1 to 3 do
  begin
    Result := DecodeString(Result);
  end;
end;

procedure DoGetToken(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  token: TJWT;
  CompactToken: String;
  JasonObj: TJSONObject;
  clientId: String;
  ClientSecurity: String;
  Memory: TFDMemTable;
  I: Integer;
  expirate: TDateTime;
  expirateS: String;

  Index: Integer;
  IDUSU: Array of String;
  IDPERFIL: Array of String;
  IDSETOR: Array of String;
  NOMEUSU: Array of String;
  DATANASCUSU: Array of String;
  ATUALIZANDO: Array of String;
  Data: String;
begin
  JasonObj := Req.Body<TJSONObject>;
  try
    // Aki estou pegando no body o usuario
    clientId := JasonObj.GetValue<string>('client_id');
  except
    Res.Send('client_id not found').Status(THTTPStatus.Unauthorized);
    exit;
  end;
  try
    // Aki estou pegando no body a senha
    ClientSecurity := JasonObj.GetValue<string>('client_security');
  except
    Res.Send('client_security not found').Status(THTTPStatus.Unauthorized);
    exit;
  end;
  try
    // Aki estou pegando no body a data de expiração, padrão 15m
    expirate := StrToDateTime
      (DescripEnvio(JasonObj.GetValue<string>('expiration')));

    if now > expirate then
    begin
      raise Exception.Create('Expiration not found!');
    end;

  except
    Res.Send('Expiration not found!').Status(THTTPStatus.Unauthorized);
    exit;
  end;

  try
    clientId := DescripEnvio(clientId);
  except
    Res.Send('client_id value not found').Status(THTTPStatus.Unauthorized);
    exit;
  end;

  try
    ClientSecurity := DescripEnvio(ClientSecurity);
  except
    Res.Send('client_security value not found')
      .Status(THTTPStatus.Unauthorized);
    exit;
  end;

  SetLength(IDUSU, 2);
  SetLength(IDPERFIL, 2);
  SetLength(IDSETOR, 2);
  SetLength(NOMEUSU, 2);
  SetLength(DATANASCUSU, 2);
  SetLength(ATUALIZANDO, 2);

  Index := 0;
  Data := '';
  for I := 1 to Length(ClientSecurity) do
  begin
    if ClientSecurity[I] = '¢' then
    begin
      inc(Index);
    end
    else
    begin
      case Index of
        0:
          begin
            IDUSU[0] := IDUSU[0] + ClientSecurity[I];
            IDUSU[1] := IDUSU[1] + ClientSecurity[I];
          end;
        1:
          begin
            IDPERFIL[0] := IDPERFIL[0] + ClientSecurity[I];
            IDPERFIL[1] := IDPERFIL[1] + ClientSecurity[I];
          end;
        2:
          begin
            IDSETOR[0] := IDSETOR[0] + ClientSecurity[I];
            IDSETOR[1] := IDSETOR[1] + ClientSecurity[I];
          end;
        3:
          begin
            NOMEUSU[0] := NOMEUSU[0] + ClientSecurity[I];
            NOMEUSU[1] := NOMEUSU[1] + ClientSecurity[I];
          end;
        4:
          begin
            DATANASCUSU[0] := DATANASCUSU[0] + ClientSecurity[I];
            DATANASCUSU[1] := DATANASCUSU[1] + ClientSecurity[I];
          end;
        5:
          begin
            ATUALIZANDO[0] := ATUALIZANDO[0] + ClientSecurity[I];
            ATUALIZANDO[1] := ATUALIZANDO[1] + ClientSecurity[I];
          end
      else
        begin
          Data := Data + ClientSecurity[I];
        end;
      end;
    end;
  end;

  if (IDUSU[0].ToInteger = IDUSU[1].ToInteger) and
    (IDPERFIL[0].ToInteger = IDPERFIL[1].ToInteger) and
    (IDSETOR[0].ToInteger = IDSETOR[1].ToInteger) and (NOMEUSU[0] = NOMEUSU[1])
    and (DATANASCUSU[0] = DATANASCUSU[1]) and (ATUALIZANDO[0] = ATUALIZANDO[1])
  then
  begin
    // Gerar o token
    Memory := TFDMemTable.Create(nil);
    Memory.FieldDefs.Add('IDUSU', ftInteger);
    Memory.FieldDefs.Add('IDPERFIL', ftInteger);
    Memory.FieldDefs.Add('IDSETOR', ftInteger);
    Memory.FieldDefs.Add('ATUALIZANDO', ftInteger);
    Memory.FieldDefs.Add('EXPIRATION', ftTimeStamp);
    Memory.FieldDefs.Add('NOMEUSU', ftString, 50);
    Memory.FieldDefs.Add('DATANASCUSU', ftString, 10);
    Memory.FieldDefs.Add('TOKEN', ftString, 256);
    Memory.Open;

    Memory.Insert;
    Memory.FieldByName('IDUSU').AsString := IDUSU[0];
    Memory.FieldByName('IDPERFIL').AsString := IDPERFIL[0];
    Memory.FieldByName('IDSETOR').AsString := IDSETOR[0];
    Memory.FieldByName('NOMEUSU').AsString := NOMEUSU[0];
    Memory.FieldByName('DATANASCUSU').AsString := DATANASCUSU[0];
     Memory.FieldByName('EXPIRATION').AsString :=
      FormatDateTime('dd/mm/yyyy hh:nn:ss', IncMinute(now, 60));
    if IDUSU[0].ToInteger = 3 then
    begin
    Memory.FieldByName('EXPIRATION').AsString :=
      FormatDateTime('dd/mm/yyyy hh:nn:ss', IncYear(now, 1));
    end;




    Memory.FieldByName('ATUALIZANDO').AsString := ATUALIZANDO[0];

    token := TJWT.Create;
    try
      // Aki é indicado informar o nome da empresa no caso "IFORTH SISTEMAS"
      token.Claims.Issuer := 'IFORTH';
      // Aki é usado para distinguir o token, pode ser informado o código do usuario
      token.Claims.Subject := 'XXXXXXX';
      // Aki é definido o tempo de inspiração do token, pode ser definido em Horas/Dias
      token.Claims.Expiration := Memory.FieldByName('EXPIRATION').AsDateTime;

      // Aki está passando o parametro recebido "usuario" para montar o token
      // token.Claims.SetClaimOfType<string>('usuario', usuario);
      // Aki esta passando o parametro recebido "senha" para montar o token,
      // não é o mais adequado, porem passei por teste
      // token.Claims.SetClaimOfType<string>('senha', senha);

      // Aki é a chave secreta, deve-se utilizar uma chave para a geração do token e validação na uses "token.autorizacao", podendo criar uma variavel global
      CompactToken := TJOSE.SHA256CompactToken(CHAVE_SECRETA, token);
    finally
      token.Free;
    end;
    Memory.FieldByName('TOKEN').AsString := CompactToken;
    Memory.Post;
    Res.Send<TJSONObject>(Memory.ToJSONObject);
    Memory.Free;
  end
  else
  begin
    Res.Send('client_id and client_security are not valid')
      .Status(THTTPStatus.Unauthorized);
  end;

end;

procedure DoBasicAuth(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  JasonObj: TJSONObject;
  user: String;
  passworld: String;
  expirate: TDateTime;
  expirateS: String;

  Conection: TConexao;
  QRY: TFDQuery;

  clientId: String;
  ClientSecurity: String;
  jObject: TJSONObject;
  I: Integer;
begin
  JasonObj := Req.Body<TJSONObject>;
  try
    // Aki estou pegando no body o usuario
    user := DescripEnvio(JasonObj.GetValue<string>('user'));
  except
    Res.Send('User not found!');
    exit;
  end;
  try
    // Aki estou pegando no body a senha
    passworld := DescripEnvio(JasonObj.GetValue<string>('password'));
  except
    Res.Send('Password not found!');
    exit;
  end;
  try
    // Aki estou pegando no body a data de expiração, padrão 15m
    expirate := StrToDateTime
      (DescripEnvio(JasonObj.GetValue<string>('expiration')));

    if now > expirate then
    begin
      raise Exception.Create('Expiration not found!');
    end;

  except
    Res.Send('Expiration not found!').Status(THTTPStatus.Unauthorized);
    exit;
  end;

  {
    ALTER TABLE USUARIO ADD CRIPUSU INTEGER;
    UPDATE USUARIO SET CRIPUSU = 0 WHERE CRIPUSU IS NULL;

  }

  Conection := TConexao.Create('token');

  QRY := Conection.CriaQRY;
  try
    QRY.Close;
    QRY.sql.Clear;
    QRY.sql.Add
      ('SELECT CRIPUSU,SENHAUSU,IDUSU, IDPERFIL, NOMEUSU, DATANASCUSU, IDSETOR FROM USUARIO WHERE USUARIOUSU = :USUARIO AND FLAGUSU = 0');
    QRY.ParamByName('USUARIO').AsString := user;
    // QRY.ParamByName('SENHA').AsString := passworld;
    QRY.Open();
    if QRY.RecordCount > 0 then
    begin
      case QRY.FieldByName('CRIPUSU').AsInteger of
        1:
          begin
            passworld := EnDecryptString(passworld, 650);
            if passworld <> QRY.FieldByName('SENHAUSU').AsString then
            begin
              raise Exception.Create('Password not found');
            end;
          end
      else
        begin
          if passworld = QRY.FieldByName('SENHAUSU').AsString then
          begin
            passworld := EnDecryptString(passworld, 650);
            Conection.ExecuteSQL('UPDATE USUARIO SET SENHAUSU = ' +
              QuotedStr(passworld) + ' WHERE IDUSU = ' +
              QRY.FieldByName('IDUSU').AsString);
            Conection.ExecuteSQL('UPDATE USUARIO SET CRIPUSU = 1 WHERE IDUSU = '
              + QRY.FieldByName('IDUSU').AsString);
          end
          else
          begin
            raise Exception.Create('Password not found');
          end;

        end;
      end;


      // Conection.ExecuteSQL('UPDATE ');

      clientId := QRY.FieldByName('IDUSU').AsString + '¢' +
        QRY.FieldByName('IDPERFIL').AsString + '¢' + QRY.FieldByName('IDSETOR')
        .AsString + '¢' + QRY.FieldByName('NOMEUSU').AsString + '¢' +
        QRY.FieldByName('DATANASCUSU').AsString;

      QRY.Close;
      QRY.sql.Clear;
      QRY.sql.Add('SELECT FIRST 1 * FROM CONFIG');
      QRY.Open;
      clientId := clientId + '¢' + QRY.FieldByName('UPDATECONFIG').AsString;
      ClientSecurity := clientId + '¢' + FormatDateTime('dd/mm/yyyy hh:nn:ss',
        IncMinute(now, 15));
      expirateS := FormatDateTime('dd/mm/yyyy hh:nn:ss', IncMinute(now, 15));
      jObject := TJSONObject.Create;

      expirateS := CripEnvio(expirateS);
      clientId := CripEnvio(clientId);

      clientId := CripEnvio(clientId);
      ClientSecurity := CripEnvio(ClientSecurity);

      jObject.AddPair('client_id', (clientId));
      jObject.AddPair('client_security', (ClientSecurity));
      jObject.AddPair('expiration', (expirateS));

      Res.Send<TJSONObject>(jObject);

    end
    else
    begin
      raise Exception.Create('User not found');
    end;
  except
    on E: Exception do
    begin
      Res.Send(E.Message).Status(THTTPStatus.Unauthorized);
    end;

  end;
Conection.Free;
end;

procedure DoGetCrip(Req: THorseRequest; Res: THorseResponse; Next: TProc);
const
  BASIC_AUTH = 'iforth ';
var
  LBasicAuthenticationEncode: string;
  LBase64String: string;
  LBasicAuthenticationDecode: TStringList;
  LIsAuthenticated: Boolean;
  Header: string;
  RealmMessage: string;
  Authenticate: THorseBasicAuthentication;

  jObject: TJSONObject;
begin
  LIsAuthenticated := False;
  LBasicAuthenticationEncode := Req.Headers['iforth_sistemas'];
  if LBasicAuthenticationEncode.Trim.IsEmpty and
    not Req.Query.TryGetValue(Header, LBasicAuthenticationEncode) then
  begin
    Res.Send('Authorization not found').Status(THTTPStatus.Unauthorized)
      .RawWebResponse
{$IF DEFINED(FPC)}
      .WWWAuthenticate := Format('iForth realm=%s', [RealmMessage]);
{$ELSE}
      .Realm := RealmMessage;
{$ENDIF}
    raise EHorseCallbackInterrupted.Create;
  end;
  if not LBasicAuthenticationEncode.ToLower.StartsWith(BASIC_AUTH) then
  begin
    Res.Send('Invalid authorization type').Status(THTTPStatus.Unauthorized);
    raise EHorseCallbackInterrupted.Create;
  end;
  LBasicAuthenticationDecode := TStringList.Create;
  try
    LBasicAuthenticationDecode.Delimiter := '|';
    LBase64String := LBasicAuthenticationEncode.Replace(BASIC_AUTH, '',
      [rfIgnoreCase]);
    try
      LBasicAuthenticationDecode.DelimitedText :=
        DescriptBasicAuth(LBase64String);
    except
      Res.Send('Value not supported! ').Status(THTTPStatus.Unauthorized);
      exit;
    end;

    // {$IF DEFINED(FPC)}DecodeStringBase64(LBase64String){$ELSE}TBase64Encoding.
    // Base64.Decode(LBase64String){$ENDIF};
    try

      LIsAuthenticated := True;
      // Deve se enviar o que o basic precisa receber

      {
        "usuario":"YHRqX20DUgZUcHNJYXN2bFdxZDVVdwgN",
        "senha":"YHB6R31nc3ZVcEFBVXN2VWxlfHxlBHdoY1kBYFFHUXs="
      }

      // CripEnvio
      try
        jObject := TJSONObject.Create;
        jObject.AddPair('user',
          CripEnvio(LBasicAuthenticationDecode.Strings[0]));
        jObject.AddPair('password',
          CripEnvio(LBasicAuthenticationDecode.Strings[1]));
        jObject.AddPair('expiration',
          CripEnvio(FormatDateTime('dd/mm/yyyy hh:nn:ss', IncMinute(now, 15))));
      except
        Res.Send('Password or User not valid!')
          .Status(THTTPStatus.Unauthorized);
        exit;
      end;

      // DateUtils
      // ////showmessage1(FormatDateTime('dd/mm/yyyy hh:nn:ss', IncMinute(now,15)));

      Res.Send(jObject).Status(THTTPStatus.OK);
    except
      on E: Exception do
      begin
        Res.Send(E.Message).Status(THTTPStatus.InternalServerError);
        raise EHorseCallbackInterrupted.Create;
      end;
    end;

  finally
    LBasicAuthenticationDecode.Free;
  end;
  if not LIsAuthenticated then
  begin
    Res.Send('Unauthorized').Status(THTTPStatus.Unauthorized);
    raise EHorseCallbackInterrupted.Create;
  end;

end;

procedure DoPostValida(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  JasonObj: TJSONObject;

  expirate: TDateTime;
  new : String;
begin
  JasonObj := Req.Body<TJSONObject>;

  expirate := StrToDateTime(JasonObj.GetValue<string>('expirate'));

  if expirate > now then
  begin
    Res.Status(200);
  end
  else
  begin
    Res.Status(201);
  end;
  Res.Send('');
end;

procedure Registry;
begin
  { Versão 1 }

  { Na Crip deve se enviar o seguinte scoop no header da requisição

    KEY              VALUE
    iForth Sistemas  iForth V1ZkU2RHRlhORFphYlZaelpFaEtjR0pxUlQwPQ==

    iForth Sistemas = iForth "Usuario|Senha"
    O usuário e senha devem ser separado pelo "|" e deve-se criptografar
    como base64 3x pro servidor interpretar e retornar o JSON para prossegui pra url "v1/basic"
  }
  THorse.get('/v1/crip', DoGetCrip);

  { No basic deve-se passar o resultado que vier do crip, pois ele faz a criptografia em 2 fatores }
  THorse.Post('/v1/basic', DoBasicAuth);

  { No token deve-se passar o resultado que vier do basic, ele retorna o client_id e client_security
    client_id e client_security tem validade de 1h e devem ser gerado sempre que for fazer login }
  THorse.Post('/v1/token', DoGetToken);

  { No valida é enviado um JSON com os seguintes parametros
    "data" e "hora"
  }
  THorse.Post('/v1/valida', DoPostValida);

end;

{

  Mapeamento dos Erros

  URL GET "/v1/crip"
  - Authorization not found
  - Esta faltando no cabeçalho "iforth_sistemas" com o valor "iForth SENHA_CRIPTOGRAFADA_EM_BASE64_3_VEZES"
  - Invalid authorization type
  - Esta faltando no cabeçalho "iforth_sistemas" com o valor "iForth SENHA_CRIPTOGRAFADA_EM_BASE64_3_VEZES"
  - Value not supported!
  - Esta sendo enviado um valor com uma criptografica diferente

  URL POST "/v1/basic"
  - User not found
  - Não esta sendo passado no body da requisição o valor para "user"
  - Caso tenha o valor "user" e retornar, usuário nao existe

  - Password not found
  - Não esta sendo passado no body da requisição o valor para "password"
  - Caso tenha o valor "password" e retornar, esta dando divergencia na senha.

  - Expiration not found
  - Passou o tempo de expiração da requisição feita no "/v1/crip", tempo maximo de 15m

  URL POST "/v1/token"
  - client_id not found
  - Não foi passado o client_id no body da requisição

  - client_security not found
  - Não foi passado o client_security no body da requisição

  - Expiration not found
  - Passou o tempo de expiração da requisição feita no "/v1/basic", tempo maximo de 15m

  - client_id value not found
  - Passou um valor com a criptografica incorreta ou não suportada

  - client_security	 value not found
  - Passou um valor com a criptografica incorreta ou não suportada


}

end.
