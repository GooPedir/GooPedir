unit uframeCheckboxExtra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, uFrameDescricaoAdicional, FMX.Layouts;

type
  TframeExtra = class(TFrame)
    img_un: TImage;
    img_check: TImage;
    Layout1: TLayout;
    Label1: TLabel;
    Layout2: TLayout;
    Image1: TImage;
    Image2: TImage;
    lQuantidade: TLabel;
    procedure FrameClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
  private
    FCheckbox: Boolean;
    FPai: TFrameDescricaoAdicional;
    FDescricao: String;
    FQuantidade: Integer;
    procedure SetCheckbox(const Value: Boolean);
    procedure SetDescricao(const Value: String);
    procedure SetPai(const Value: TFrameDescricaoAdicional);
    procedure SetQuantidade(const Value: Integer);
    { Private declarations }
    procedure Mais;
    procedure Menos;
  public
    { Public declarations }
    property Quantidade: Integer read FQuantidade write SetQuantidade;
    property Descricao: String read FDescricao write SetDescricao;
    property Pai: TFrameDescricaoAdicional read FPai write SetPai;
  end;

implementation

{$R *.fmx}

uses util, uMain;
{ TFrame2 }

procedure TframeExtra.FrameClick(Sender: TObject);
begin

  if Pai.Valida then
  begin
    ShowMessageToast(frmMain, 'Quantidade máxima selecionada', 1);
  end;

end;

procedure TframeExtra.Image1Click(Sender: TObject);
begin
Mais;
end;

procedure TframeExtra.Image2Click(Sender: TObject);
begin
Menos;
end;

procedure TframeExtra.Mais;
begin
  if Pai.Valida then
  begin
    ShowMessageToast(frmMain, 'Quantidade máxima já selecionada!', 2);
    exit;
  end;
  Pai.Mais;
    Quantidade := Quantidade + 1;
end;

procedure TframeExtra.Menos;
begin
   if Pai.Valida then
  begin

    exit;
  end;
  Pai.Menos;
  Quantidade := Quantidade - 1;
end;

procedure TframeExtra.SetCheckbox(const Value: Boolean);
begin

end;

procedure TframeExtra.SetDescricao(const Value: String);
begin
  FDescricao := Value;
end;

procedure TframeExtra.SetPai(const Value: TFrameDescricaoAdicional);
begin
  FPai := Value;
end;

procedure TframeExtra.SetQuantidade(const Value: Integer);
begin
  FQuantidade := Value;
  lQuantidade.Text := Value.ToString;
end;

end.
