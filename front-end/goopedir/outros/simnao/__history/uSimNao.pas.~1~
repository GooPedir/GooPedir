unit uSimNao;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  uButton, FMX.Layouts, FMX.Controls.Presentation, FMX.Effects, FMX.Objects;

type
  TCallback = procedure of object;

  TfrmSimNao = class(TForm)
    rConfirmacao: TRectangle;
    lTitulo: TLabel;
    lDescricao: TLabel;
    Layout1: TLayout;
    rPreto: TRectangle;
    Layout2: TLayout;
    GridPanelLayout1: TGridPanelLayout;
    btnNao: iButton;
    btnSim: iButton;
    Rectangle1: TRectangle;
    procedure btnSimClick(Sender: TObject);
    procedure btnNaoClick(Sender: TObject);
  private
    FTitulo: String;
    FDescricao: String;
    procedure SetDescricao(const Value: String);
    procedure SetTitulo(const Value: String);
    { Private declarations }
  public
    { Public declarations }
    property Titulo: String read FTitulo write SetTitulo;
    property Descricao: String read FDescricao write SetDescricao;

  var
    Sim: TCallback;
    Nao: TCallback;
  end;

var
  frmSimNao: TfrmSimNao;

implementation

{$R *.fmx}
{ TfrmSimNao }

procedure TfrmSimNao.btnSimClick(Sender: TObject);
begin
  Hide;
  if Assigned(Sim) then
    Sim;
end;

procedure TfrmSimNao.btnNaoClick(Sender: TObject);
begin
  Hide;
  if Assigned(Nao) then
    Nao;
end;

procedure TfrmSimNao.SetDescricao(const Value: String);
begin
  FDescricao := Value;
  lDescricao.Text := Value;
end;

procedure TfrmSimNao.SetTitulo(const Value: String);
begin
  FTitulo := Value;
  if Value = '' then
    FTitulo := 'iCep';
  lTitulo.Text := FTitulo;
end;

end.
