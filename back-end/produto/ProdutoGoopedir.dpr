program ProdutoGoopedir;

uses
  Vcl.Forms,
  Windows,
  Messages,
  SysUtils,
  uProdutoSite in 'uProdutoSite.pas' {frmProdutoSite},
  conexao in '..\servidor\src\modulo\conexao.pas',
  uDM in '..\servidor\src\modulo\uDM.pas' {dm: TDataModule},
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
  uControlerProduto in '..\servidor\src\controller\uControlerProduto.pas',
  uControllCaches in '..\servidor\src\controller\uControllCaches.pas',
  uCacheControl in '..\servidor\src\controller\uCacheControl.pas',
  uInserirUpdate in '..\servidor\src\modulos\Controller\uInserirUpdate.pas',
  uControllerSite in '..\servidor\src\controller\uControllerSite.pas',
  uGlobais in '..\servidor\uGlobais.pas',
  uSQL in '..\servidor\src\sql\uSQL.pas';

{$R *.res}

const
  MutexName = 'psSincProduto';

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
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmProdutoSite, frmProdutoSite);
  Application.Run;

end.
