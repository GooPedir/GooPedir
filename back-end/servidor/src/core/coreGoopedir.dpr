program coreGoopedir;

uses
  Vcl.Forms,
  ufrmCore in 'ufrmCore.pas' {frmCore},
  conexao in '..\modulo\conexao.pas',
  uDM in '..\modulo\uDM.pas' {dm: TDataModule},
  uGlobais in '..\..\uGlobais.pas',
  JOSE.Builder in '..\other\JOSE.Builder.pas',
  JOSE.Consumer in '..\other\JOSE.Consumer.pas',
  JOSE.Consumer.Validators in '..\other\JOSE.Consumer.Validators.pas',
  JOSE.Context in '..\other\JOSE.Context.pas',
  JOSE.Core.Base in '..\other\JOSE.Core.Base.pas',
  JOSE.Core.Builder in '..\other\JOSE.Core.Builder.pas',
  JOSE.Core.JWA.Compression in '..\other\JOSE.Core.JWA.Compression.pas',
  JOSE.Core.JWA.Encryption in '..\other\JOSE.Core.JWA.Encryption.pas',
  JOSE.Core.JWA.Factory in '..\other\JOSE.Core.JWA.Factory.pas',
  JOSE.Core.JWA in '..\other\JOSE.Core.JWA.pas',
  JOSE.Core.JWA.Signing in '..\other\JOSE.Core.JWA.Signing.pas',
  JOSE.Core.JWE in '..\other\JOSE.Core.JWE.pas',
  JOSE.Core.JWK in '..\other\JOSE.Core.JWK.pas',
  JOSE.Core.JWS in '..\other\JOSE.Core.JWS.pas',
  JOSE.Core.JWT in '..\other\JOSE.Core.JWT.pas',
  JOSE.Core.Parts in '..\other\JOSE.Core.Parts.pas',
  JOSE.Encoding.Base64 in '..\other\JOSE.Encoding.Base64.pas',
  JOSE.Hashing.HMAC in '..\other\JOSE.Hashing.HMAC.pas',
  JOSE.OpenSSL.Headers in '..\other\JOSE.OpenSSL.Headers.pas',
  JOSE.Signing.Base in '..\other\JOSE.Signing.Base.pas',
  JOSE.Signing.ECDSA in '..\other\JOSE.Signing.ECDSA.pas',
  JOSE.Signing.RSA in '..\other\JOSE.Signing.RSA.pas',
  JOSE.Types.Arrays in '..\other\JOSE.Types.Arrays.pas',
  JOSE.Types.Bytes in '..\other\JOSE.Types.Bytes.pas',
  JOSE.Types.JSON in '..\other\JOSE.Types.JSON.pas',
  JOSE.Types.Utils in '..\other\JOSE.Types.Utils.pas',
  uProcessamentoiFood in '..\uProcessamentoiFood.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmCore, frmCore);
  Application.CreateForm(Tdm, dm);
  Application.Run;
end.
