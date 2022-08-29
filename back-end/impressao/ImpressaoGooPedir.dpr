program ImpressaoGooPedir;

uses
  Vcl.Forms,
  requisicao in 'util\requisicao.pas',
  uModulo in 'uModulo.pas' {dmModulo: TDataModule},
  metodo.api in 'util\metodo.api.pas',
  uModuloImpressao in 'impressao\uModuloImpressao.pas' {dmImpressaoV2: TDataModule},
  uMain in 'util\uMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
//  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TdmModulo, dmModulo);
  Application.CreateForm(TdmImpressaoV2, dmImpressaoV2);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
