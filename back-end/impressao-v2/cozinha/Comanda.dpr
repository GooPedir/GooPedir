program Comanda;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  uModuloImpressao in '..\..\impressao\impressao\uModuloImpressao.pas' {dmImpressaoV2: TDataModule},
  uModulo in '..\..\impressao\uModulo.pas' {dmModulo: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TdmImpressaoV2, dmImpressaoV2);
//  Application.CreateForm(TdmModulo, dmModulo);
  Application.Run;
end.
