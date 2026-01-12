unit Horse.ExceptionHandler;

{$IF DEFINED(FPC)}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
{$IF DEFINED(FPC)}
  SysUtils, HTTPDefs,
{$ELSE}
  System.SysUtils, Web.HTTPApp,
{$ENDIF}
  Horse, Horse.Commons, Vcl.Dialogs, System.JSON, uRequisicao;
procedure ExceptionMiddleware(Req: THorseRequest; Res: THorseResponse; Next:
{$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});

procedure EnviaGlitchtip(DSN, Tipo, Identificacao, Mensagem: String);
function GenerateUUID: string;

implementation

procedure ExceptionMiddleware(Req: THorseRequest; Res: THorseResponse; Next:
{$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
var
  Rota, Metodo: string;
  JsonObject: TJsonObject;

  Requisicao: iRequisicao;

begin

  try
    Next; // Executa a próxima ação ou middleware
  except
    on E: Exception do
    begin
      exit;
      JsonObject := TJsonObject.Create;
      JsonObject.AddPair('url', Req.RawWebRequest.PathInfo);
      JsonObject.AddPair('metodo', Req.RawWebRequest.Method);
      JsonObject.AddPair('host', Req.RawWebRequest.Host);
      JsonObject.AddPair('erro', E.Message);

      Res.Status(500).Send(JsonObject.ToString);

      EnviaGlitchtip('https://070641a91ca74f3c8b3f1cec9d5ca962@nginx-glitchtip.l1p88w.easypanel.host/4', 'Erro', Req.RawWebRequest.Host +Req.RawWebRequest.PathInfo, E.Message);

    end;
  end;
end;

procedure EnviaGlitchtip(DSN, Tipo, Identificacao, Mensagem: String);
var
  JsonObjec, JSONBody, ExceptionObj, ExceptionVal, Tags: TJSONObject;
  ExceptionArr: TJSONArray;
  Chave, API, URL: string;
  iGlitchtip: iRequisicao;
begin
  iGlitchtip := iRequisicao.Create(nil);

  // Extrai a chave e a URL da DSN
  Chave := Copy(DSN, pos('//', DSN) + 2, pos('@', DSN) - pos('//', DSN) - 2);
  URL := Copy(DSN, pos('@', DSN) + 1, length(DSN));
  URL := StringReplace(URL, '/api/', '/api/' + Chave + '/store/', []);
  API := Copy(URL, pos('/', URL) + 1, length(URL));
  URL := StringReplace(URL, '/' + API, '', []);

  // Monta JSON
  JSONBody := TJSONObject.Create;
  JSONBody.AddPair('event_id', GenerateUUID);
  JSONBody.AddPair('timestamp',
    FormatDateTime('yyyy-mm-dd"T"hh":"nn":"ss"Z"', Now));
  JSONBody.AddPair('level', Tipo);
  JSONBody.AddPair('platform', 'delphi');
  JSONBody.AddPair('message', Identificacao);

  // exception
  ExceptionObj := TJSONObject.Create;
  ExceptionVal := TJSONObject.Create;
  ExceptionVal.AddPair('type', UpperCase(Tipo));
  ExceptionVal.AddPair('value', Mensagem);

  ExceptionArr := TJSONArray.Create;
  ExceptionArr.AddElement(ExceptionVal);
  ExceptionObj.AddPair('values', ExceptionArr);
  JSONBody.AddPair('exception', ExceptionObj);

  // tags
  Tags := TJSONObject.Create;
  if (GetEnvironmentVariable('COMPUTERNAME') = 'ALLAN-PC') then
  begin
    Tags.AddPair('environment', 'desenvolvimento');
  end
  else
  begin
    Tags.AddPair('environment', 'produção');
  end;

  Tags.AddPair('user', GetEnvironmentVariable('COMPUTERNAME'));
  JSONBody.AddPair('tags', Tags);

  // wrapper para envio
  JsonObjec := TJSONObject.Create;
  JsonObjec.AddPair('url', 'https://' + URL + '/api/' + API + '/store/');
  JsonObjec.AddPair('autorizacao', Chave);
  JsonObjec.AddPair('body', JSONBody);

  iGlitchtip.URL := 'https://old.goopedir.com/glitchtip/index.php';
  iGlitchtip.BODY(JsonObjec);

  try
    iGlitchtip.Metodo := mPost;
    iGlitchtip.Execute;
  except
    on E: Exception do
    begin
      // tratamento
    end;
  end;

  iGlitchtip.Free;
end;

function GenerateUUID: string;
var
  GUID: TGUID;
begin
  // Gera um novo GUID
  if CreateGUID(GUID) = 0 then
    // Converte o GUID para string no formato padrão
    Result := GUIDToString(GUID)
  else
    Result := ''; // Retorna uma string vazia em caso de erro
end;

end.
