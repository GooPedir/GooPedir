unit uPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Effects,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    Layout1: TLayout;
    Layout2: TLayout;
    Image1: TImage;
    Rectangle1: TRectangle;
    ShadowEffect1: TShadowEffect;
    rStatus: TRectangle;
    ShadowEffect2: TShadowEffect;
    lStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    function StatusConexao: Boolean; (*

    *)
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses conexao, Data.FireDACJSONReflect, DataSet.Serialize.Config,
  DataSet.Serialize.Consts, DataSet.Serialize.Export, DataSet.Serialize.Import,
  DataSet.Serialize.Language, DataSet.Serialize,
  DataSet.Serialize.UpdatedStatus, DataSet.Serialize.Utils,
  Horse.BasicAuthentication, Horse.Commons, Horse.Constants,
  Horse.Core.Group.Contract, Horse.Core.Group, Horse.Core,
  Horse.Core.Route.Contract, Horse.Core.Route, Horse.Core.RouterTree,
  Horse.Etag, Horse.Exception, Horse.HTTP, Horse.Jhonson, Horse.JWT,
  Horse.OctetStream, Horse.Paginate, Horse, Horse.Proc, Horse.Provider.Abstract,
  Horse.Provider.Apache, Horse.Provider.CGI, Horse.Provider.Console,
  Horse.Provider.Daemon, Horse.Provider.FPC.Apache, Horse.Provider.FPC.CGI,
  Horse.Provider.FPC.Daemon, Horse.Provider.FPC.FastCGI,
  Horse.Provider.FPC.HTTPApplication, Horse.Provider.ISAPI, Horse.Provider.VCL,
  Horse.WebModule, JOSE.Builder, JOSE.Consumer, JOSE.Consumer.Validators,
  JOSE.Context, JOSE.Core.Base, JOSE.Core.Builder, JOSE.Core.JWA.Compression,
  JOSE.Core.JWA.Encryption, JOSE.Core.JWA.Factory, JOSE.Core.JWA,
  JOSE.Core.JWA.Signing, JOSE.Core.JWE, JOSE.Core.JWK, JOSE.Core.JWS,
  JOSE.Core.JWT, JOSE.Core.Parts, JOSE.Encoding.Base64, JOSE.Hashing.HMAC,
  JOSE.OpenSSL.Headers, JOSE.Signing.Base, JOSE.Signing.ECDSA, JOSE.Signing.RSA,
  JOSE.Types.Arrays, JOSE.Types.Bytes, JOSE.Types.JSON, JOSE.Types.Utils,
  RESTRequest4D, RESTRequest4D.Request.Client, RESTRequest4D.Request.Contract,
  RESTRequest4D.Response.Client, RESTRequest4D.Response.Contract,
  RESTRequest4D.Response.Indy, RESTRequest4D.Response.NetHTTP,
  RESTRequest4D.Utils, ThirdParty.Posix.Syslog, token.autorizacao, token, uDM,
  util.backup, util, Web.WebConst;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
Action := TCloseAction.caNone;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Declaração dos Middlewares utilizados
  THorse.Use(Jhonson);
  THorse.Use(Etag);
  THorse.Use(OctetStream);
  // Declaração das URI da API
  token.Registry;
  util.Registry;

  // util.backup.Registry;

  // Inicialização do Console
  THorse.Listen(2121,
    procedure(Horse: THorse)
    begin
      // Writeln('Server is runing on port ' + THorse.Port.ToString);
      // Writeln('');
      if StatusConexao then
      begin
       rStatus.Fill.Color := TAlphaColors.Green;
       lStatus.Text := 'Servidor Online';
      end else begin
       rStatus.Fill.Color := TAlphaColors.Red;
       lStatus.Text := 'Servidor Ofiline';
      end;
    end);
end;

function TForm1.StatusConexao: Boolean;
var
  conexao: Tconexao;
begin
  try
  conexao := Tconexao.create;
  conexao.SQL.Add('select curdate() as hoje,  curdate() as amanha');

  Result := conexao.FieldByName('hoje') = date;

  conexao.Free;
  except
     Result := False;
  end;

end;

end.
