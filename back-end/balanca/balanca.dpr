program balanca;

uses
  Vcl.Forms,
  uMainBalanca in 'uMainBalanca.pas' {frmMainBalanca};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMainBalanca, frmMainBalanca);
  Application.Run;
end.
