program ServicosGoopedir;

uses
  Vcl.Forms,
  Windows,
  Messages,
  SysUtils,
  uPrincipalServicos in 'uPrincipalServicos.pas' {frmServicosGoopedir},
  conexao in '..\servidor\src\modulo\conexao.pas',
  uDM in '..\servidor\src\modulo\uDM.pas' {dm: TDataModule},
  Data.FireDACJSONReflect in '..\servidor\src\other\Data.FireDACJSONReflect.pas',
  DataSet.Serialize.Config in '..\servidor\src\other\DataSet.Serialize.Config.pas',
  DataSet.Serialize.Consts in '..\servidor\src\other\DataSet.Serialize.Consts.pas',
  DataSet.Serialize.Export in '..\servidor\src\other\DataSet.Serialize.Export.pas',
  DataSet.Serialize.Import in '..\servidor\src\other\DataSet.Serialize.Import.pas',
  DataSet.Serialize.Language in '..\servidor\src\other\DataSet.Serialize.Language.pas',
  DataSet.Serialize in '..\servidor\src\other\DataSet.Serialize.pas',
  DataSet.Serialize.UpdatedStatus in '..\servidor\src\other\DataSet.Serialize.UpdatedStatus.pas',
  DataSet.Serialize.Utils in '..\servidor\src\other\DataSet.Serialize.Utils.pas',
  Horse.BasicAuthentication in '..\servidor\src\other\Horse.BasicAuthentication.pas',
  Horse.Commons in '..\servidor\src\other\Horse.Commons.pas',
  Horse.Constants in '..\servidor\src\other\Horse.Constants.pas',
  Horse.Core.Group.Contract in '..\servidor\src\other\Horse.Core.Group.Contract.pas',
  Horse.Core.Group in '..\servidor\src\other\Horse.Core.Group.pas',
  Horse.Core in '..\servidor\src\other\Horse.Core.pas',
  Horse.Core.Route.Contract in '..\servidor\src\other\Horse.Core.Route.Contract.pas',
  Horse.Core.Route in '..\servidor\src\other\Horse.Core.Route.pas',
  Horse.Core.RouterTree in '..\servidor\src\other\Horse.Core.RouterTree.pas',
  Horse.Etag in '..\servidor\src\other\Horse.Etag.pas',
  Horse.Exception in '..\servidor\src\other\Horse.Exception.pas',
  Horse.ExceptionHandler in '..\servidor\src\other\Horse.ExceptionHandler.pas',
  Horse.HTTP in '..\servidor\src\other\Horse.HTTP.pas',
  Horse.Jhonson in '..\servidor\src\other\Horse.Jhonson.pas',
  Horse.JWT in '..\servidor\src\other\Horse.JWT.pas',
  Horse.Paginate in '..\servidor\src\other\Horse.Paginate.pas',
  Horse in '..\servidor\src\other\Horse.pas',
  Horse.Proc in '..\servidor\src\other\Horse.Proc.pas',
  Horse.Provider.Abstract in '..\servidor\src\other\Horse.Provider.Abstract.pas',
  Horse.Provider.Apache in '..\servidor\src\other\Horse.Provider.Apache.pas',
  Horse.Provider.CGI in '..\servidor\src\other\Horse.Provider.CGI.pas',
  Horse.Provider.Console in '..\servidor\src\other\Horse.Provider.Console.pas',
  Horse.Provider.Daemon in '..\servidor\src\other\Horse.Provider.Daemon.pas',
  Horse.Provider.FPC.Apache in '..\servidor\src\other\Horse.Provider.FPC.Apache.pas',
  Horse.Provider.FPC.CGI in '..\servidor\src\other\Horse.Provider.FPC.CGI.pas',
  Horse.Provider.FPC.Daemon in '..\servidor\src\other\Horse.Provider.FPC.Daemon.pas',
  Horse.Provider.FPC.FastCGI in '..\servidor\src\other\Horse.Provider.FPC.FastCGI.pas',
  Horse.Provider.FPC.HTTPApplication in '..\servidor\src\other\Horse.Provider.FPC.HTTPApplication.pas',
  Horse.Provider.ISAPI in '..\servidor\src\other\Horse.Provider.ISAPI.pas',
  Horse.Provider.VCL in '..\servidor\src\other\Horse.Provider.VCL.pas',
  Horse.WebModule in '..\servidor\src\other\Horse.WebModule.pas' {HorseWebModule: TWebModule},
  JOSE.Builder in '..\servidor\src\other\JOSE.Builder.pas',
  JOSE.Consumer in '..\servidor\src\other\JOSE.Consumer.pas',
  JOSE.Consumer.Validators in '..\servidor\src\other\JOSE.Consumer.Validators.pas',
  JOSE.Context in '..\servidor\src\other\JOSE.Context.pas',
  JOSE.Core.Base in '..\servidor\src\other\JOSE.Core.Base.pas',
  JOSE.Core.Builder in '..\servidor\src\other\JOSE.Core.Builder.pas',
  JOSE.Core.JWA.Compression in '..\servidor\src\other\JOSE.Core.JWA.Compression.pas',
  JOSE.Core.JWA.Encryption in '..\servidor\src\other\JOSE.Core.JWA.Encryption.pas',
  JOSE.Core.JWA.Factory in '..\servidor\src\other\JOSE.Core.JWA.Factory.pas',
  JOSE.Core.JWA in '..\servidor\src\other\JOSE.Core.JWA.pas',
  JOSE.Core.JWA.Signing in '..\servidor\src\other\JOSE.Core.JWA.Signing.pas',
  JOSE.Core.JWE in '..\servidor\src\other\JOSE.Core.JWE.pas',
  JOSE.Core.JWK in '..\servidor\src\other\JOSE.Core.JWK.pas',
  JOSE.Core.JWS in '..\servidor\src\other\JOSE.Core.JWS.pas',
  JOSE.Core.JWT in '..\servidor\src\other\JOSE.Core.JWT.pas',
  JOSE.Core.Parts in '..\servidor\src\other\JOSE.Core.Parts.pas',
  JOSE.Encoding.Base64 in '..\servidor\src\other\JOSE.Encoding.Base64.pas',
  JOSE.Hashing.HMAC in '..\servidor\src\other\JOSE.Hashing.HMAC.pas',
  JOSE.OpenSSL.Headers in '..\servidor\src\other\JOSE.OpenSSL.Headers.pas',
  JOSE.Signing.Base in '..\servidor\src\other\JOSE.Signing.Base.pas',
  JOSE.Signing.ECDSA in '..\servidor\src\other\JOSE.Signing.ECDSA.pas',
  JOSE.Signing.RSA in '..\servidor\src\other\JOSE.Signing.RSA.pas',
  JOSE.Types.Arrays in '..\servidor\src\other\JOSE.Types.Arrays.pas',
  JOSE.Types.Bytes in '..\servidor\src\other\JOSE.Types.Bytes.pas',
  JOSE.Types.JSON in '..\servidor\src\other\JOSE.Types.JSON.pas',
  JOSE.Types.Utils in '..\servidor\src\other\JOSE.Types.Utils.pas',
  ThirdParty.Posix.Syslog in '..\servidor\src\other\ThirdParty.Posix.Syslog.pas',
  Web.WebConst in '..\servidor\src\other\Web.WebConst.pas',
  uSQL in '..\servidor\src\sql\uSQL.pas',
  uGlobais in '..\servidor\uGlobais.pas',
  uControllCaches in '..\servidor\src\controller\uControllCaches.pas',
  uCacheControl in '..\servidor\src\controller\uCacheControl.pas',
  uControlerProduto in '..\servidor\src\controller\uControlerProduto.pas',
  financeiro in '..\servidor\src\modulos\financeiro\financeiro.pas';

{$R *.res}

const
  MutexName = 'ServicosGoopedir';

var
  hMutex: THandle;

begin
  hMutex := CreateMutex(nil, True, MutexName);
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin

    Halt; // Encerra a aplicação
    if hMutex <> 0 then
      CloseHandle(hMutex);
  end;

  Application.Initialize;
  Application.ShowMainForm := False;

  Application.CreateForm(TfrmServicosGoopedir, frmServicosGoopedir);
  Application.Run;

end.
