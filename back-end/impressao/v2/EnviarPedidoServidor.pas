unit EnviarPedidoServidor;

interface

uses
  Vcl.Forms;

function EnviarPedido(JSON, Token: String; Form : TForm): Boolean;
procedure EnviaConfirmacaoSite(Body, Token: String);
function StatusAPI : Boolean;

implementation

uses
  System.IniFiles, uRequisicao, System.SysUtils, URL;

function EnviarPedido(JSON, Token: String; Form : TForm): Boolean;
var
  IniFile: TIniFile;
  BaseURL: String;

  Req: iRequisicao;

begin
  IniFile := TIniFile.Create('./goopedir.ini');
  BaseURL := IniFile.ReadString('server', 'baseurl', 'http://localhost:2121/');
  IniFile.Free;

  Req := iRequisicao.Create(nil);
  Req.BaseURL := BaseURL;
  Req.URL := 'v2/site/grava/pedido';
  Req.TempoExpiracao := 30 * 1000;

  Req.Metodo := mPost;
  Req.Body(JSON);

  try
    Req.Execute;

    Result := Req.Status = 200;
    EnviaConfirmacaoSite(Req.Retorno, Token);

  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;

  Req.Free;

end;

procedure EnviaConfirmacaoSite(Body, Token: String);
var
  Req: iRequisicao;
begin
  Req := iRequisicao.Create(nil);
  Req.BaseURL := UrlGoopedir;
  Req.URL := 'api/goopedir/pedidos/importado';
  Req.TempoExpiracao := 30 * 1000;
  Req.Token(Token);

  Req.Metodo := mPost;
  Req.Body(Body);

  try
    Req.Execute;
  except
    on E: Exception do
    begin

    end;
  end;

  Req.Free;
end;

function StatusAPI : Boolean;
var
  IniFile: TIniFile;
  BaseURL: String;

  Req: iRequisicao;

begin
  IniFile := TIniFile.Create('./goopedir.ini');
  BaseURL := IniFile.ReadString('server', 'baseurl', 'http://localhost:2121/');
  IniFile.Free;

  Req := iRequisicao.Create(nil);
  Req.BaseURL := BaseURL;
  Req.URL := 'v1/versao/app';
  Req.TempoExpiracao := 3 * 1000;

  Req.Metodo := mGet;


  try
    Req.Execute;

    Result := Req.Status = 200;


  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;

  Req.Free;

end;


end.
