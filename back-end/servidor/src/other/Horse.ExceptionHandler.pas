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
      JsonObject := TJsonObject.Create;
      JsonObject.AddPair('url', Req.RawWebRequest.PathInfo);
      JsonObject.AddPair('metodo', Req.RawWebRequest.Method);
      JsonObject.AddPair('host', Req.RawWebRequest.Host);
      JsonObject.AddPair('erro', E.Message);

      Res.Status(500).Send(JsonObject.ToString);

      // Cria e configura a requisição
      Requisicao := iRequisicao.Create(nil);
      Requisicao.BaseURL := 'https://ws.goopedir.com/error.php';
      Requisicao.BODY(JsonObject);
      Requisicao.Metodo := mPost;
      try
        try
          Requisicao.Execute;
        except

        end;
      finally
        Requisicao.Free;
      end;

    end;
  end;
end;

end.
