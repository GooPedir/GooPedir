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
  JsonObjec: TJsonObject;
  Chave, API, JSONBody: string;
  URL: String;
  iGlitchtip: iRequisicao;
begin
  iGlitchtip := iRequisicao.Create(nil);
  JsonObjec := TJsonObject.Create;
  // Extrai a chave e a URL da DSN
  Chave := Copy(DSN, Pos('//', DSN) + 2, Pos('@', DSN) - Pos('//', DSN) - 2);
  URL := Copy(DSN, Pos('@', DSN) + 1, length(DSN));
  URL := StringReplace(URL, '/api/', '/api/' + Chave + '/store/', []);
  API := Copy(URL, Pos('/', URL) + 1, length(URL));
  URL := StringReplace(URL, '/' + API, '', []);

  JSONBody := '';
  JSONBody := JSONBody + '{';
  JSONBody := JSONBody + '  "event_id": "' + GenerateUUID + '",';
  JSONBody := JSONBody + '  "timestamp": "' +
    FormatDateTime('yyyy-mm-dd"T"hh":"nn":"ss"Z"', now) + '",';
  JSONBody := JSONBody + '  "level": "' + Tipo + '",';
  JSONBody := JSONBody + '  "platform": "delphi",';
  JSONBody := JSONBody + '  "message": "' + Identificacao + '",';
  JSONBody := JSONBody + '  "exception": {';
  JSONBody := JSONBody + '    "values": [';
  JSONBody := JSONBody + '      {';
  JSONBody := JSONBody + '        "type": "' + UpperCase(Tipo) + '",';
  JSONBody := JSONBody + '        "value": "' + Mensagem + '"';
  JSONBody := JSONBody + '      }';
  JSONBody := JSONBody + '    ]';
  JSONBody := JSONBody + '  },';
  JSONBody := JSONBody + '  "tags": {';
  JSONBody := JSONBody + '    "environment": "production",';
  JSONBody := JSONBody + '    "user": "0"';
  JSONBody := JSONBody + '  }';
  JSONBody := JSONBody + '}';
  JsonObjec.AddPair('url', 'https://' + URL + '/api/' + API + '/store/');
  JsonObjec.AddPair('autorizacao', Chave);
  JsonObjec.AddPair('body', JSONBody);

  iGlitchtip.URL := 'https://ws.goopedir.com/glitchtip/index.php';
  iGlitchtip.BODY(JsonObjec);

  try
    iGlitchtip.Metodo := mPost;

    iGlitchtip.Execute;


  except
    on E: Exception do
    begin
       //showmessage(E.Message);
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
