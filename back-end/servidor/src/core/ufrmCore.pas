unit ufrmCore;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

type
  TfrmCore = class(TForm)
    tMinimiza: TTimer;
    procedure tMinimizaTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCore: TfrmCore;

implementation

{$R *.dfm}
{
  Mapa dos Tipos
  1 - Atualizador Banco De Dados
  2 - Backup Banco de Dados
  3 -
  4 -
  5 -

}

procedure TfrmCore.FormCreate(Sender: TObject);
var
  tipo: String;
begin
  if ParamCount > 0 then
  begin
    tipo := ParamStr(1);
  end;
end;

procedure TfrmCore.tMinimizaTimer(Sender: TObject);
begin
  tMinimiza.Enabled := false;
  self.Hide();
  self.WindowState := wsMinimized;
end;

end.
