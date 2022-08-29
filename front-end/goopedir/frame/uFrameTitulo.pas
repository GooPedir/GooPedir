unit uFrameTitulo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation;

type
  TFrameTitulo = class(TFrame)
    lTitulo: TLabel;
  private
    FTitulo: String;
    procedure SetTitulo(const Value: String);
    { Private declarations }
  public
    { Public declarations }
    property Titulo : String read FTitulo write SetTitulo;

  end;

implementation

{$R *.fmx}

uses util;

{ TFrameTitulo }

procedure TFrameTitulo.SetTitulo(const Value: String);
begin
  FTitulo := Value;
  lTitulo.Text := FormataNome(Value);
end;

end.
