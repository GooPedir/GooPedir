unit Consulta;

interface

uses
  uRequisicao, System.SysUtils, URL;

function ExecutaConsulta(URL, ClientID, ClienteSecurity, Token: String): String;

implementation

uses
  uPrincipal;

function ExecutaConsulta(URL, ClientID, ClienteSecurity, Token: String): String;
var
  Req: iRequisicao;
begin
  Req := iRequisicao.Create(nil);
  Req.BaseURL := UrlGoopedir;
  Req.URL := URL;
  Req.TempoExpiracao := 30 * 1000;
  Req.AddHEader('client-id', ClientID);
  Req.AddHEader('client-security', ClienteSecurity);
  Req.Token(Token);

  try
    Req.Execute;
    Result := Req.Retorno;
    // ShowMessage(Result)
  except
    on E: Exception do
    begin
      Result := '[]';
      // ShowMessage(e.Message)
      frmPrincipal.Memo1.lines.add(E.Message);
    end;
  end;

  Req.Free;

end;

end.
