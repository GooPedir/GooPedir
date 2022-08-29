program SiteGooPedir;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  requisicao in 'util\requisicao.pas',
  uModulo in 'uModulo.pas' {dmModulo: TDataModule},
  metodo.api in 'util\metodo.api.pas',
  uSenha in 'util\uSenha.pas' {frmSenha},
  XSuperJSON in 'outros\XSuperJSON.pas',
  XSuperObject in 'outros\XSuperObject.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TdmModulo, dmModulo);
  Application.CreateForm(TfrmSenha, frmSenha);
  Application.Run;
end.
