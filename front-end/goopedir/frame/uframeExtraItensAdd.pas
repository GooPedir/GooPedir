unit uframeExtraItensAdd;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Edit;

type
  TframeExtraItensAdd = class(TFrame)
    Rectangle1: TRectangle;
    EdtNome: TEdit;
    Label1: TLabel;
    EdtDescricao: TEdit;
    Label2: TLabel;
    edtValor: TEdit;
    Label3: TLabel;
    img_adicionar: TImage;
    sStatus: TSwitch;
    procedure img_adicionarClick(Sender: TObject);
    procedure img_adicionarMouseEnter(Sender: TObject);
    procedure img_adicionarMouseLeave(Sender: TObject);
    procedure edtValorExit(Sender: TObject);
    procedure EdtNomeKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private
    FValor: Real;
    FDescricao: String;
    FCodigo: Integer;
    FNome: String;
    FStatus: Integer;
    Fmodificado: Integer;
    procedure SetCodigo(const Value: Integer);
    procedure SetDescricao(const Value: String);
    procedure SetNome(const Value: String);
    procedure SetValor(const Value: Real);
    procedure Excluir;
    procedure SetStatus(const Value: Integer);
    procedure Setmodificado(const Value: Integer);
    { Private declarations }
  public
    { Public declarations }
    property Codigo: Integer read FCodigo write SetCodigo;
    property Nome: String read FNome write SetNome;
    property Descricao: String read FDescricao write SetDescricao;
    property Valor: Real read FValor write SetValor;
    property Status: Integer read FStatus write SetStatus;
    property modificado: Integer read Fmodificado write Setmodificado;

  end;

implementation

{$R *.fmx}

uses uSimNao,
{$IFDEF Android}
{$ELSE}
  Winapi.Windows,
{$ENDIF}
  FMXTee.Canvas;

{ TframeExtraItensAdd }

procedure TframeExtraItensAdd.EdtNomeKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
{$IFDEF Android}
{$ELSE}
  if Key = vkReturn then
  begin
    keybd_event(VK_TAB, 0, 0, 0);
    keybd_event(VK_TAB, 0, KEYEVENTF_KEYUP, 0);
  end;
{$ENDIF}
end;

procedure TframeExtraItensAdd.edtValorExit(Sender: TObject);
begin
  try
    (Sender as TEdit).Text.ToDouble;
  except
    edtValor.SetFocus;
    ShowMessage('Valor informado invalido!');
    exit;
  end;
end;

procedure TframeExtraItensAdd.Excluir;
begin
  Self.Free;
end;

procedure TframeExtraItensAdd.img_adicionarClick(Sender: TObject);
begin
  frmSimNao.Titulo := 'Confirmação';
  frmSimNao.Descricao := 'Deseja excluir o item "' + Nome + '"';
  frmSimNao.Sim := Excluir;
  frmSimNao.Show;
end;

procedure TframeExtraItensAdd.img_adicionarMouseEnter(Sender: TObject);
begin
  (Sender as TImage).Opacity := 1;
end;

procedure TframeExtraItensAdd.img_adicionarMouseLeave(Sender: TObject);
begin
  (Sender as TImage).Opacity := 0.5;
end;

procedure TframeExtraItensAdd.SetCodigo(const Value: Integer);
begin
  FCodigo := Value;
  if Codigo > 0 then
    Self.Name := 'frameExtraItensAdd' + Codigo.ToString

end;

procedure TframeExtraItensAdd.SetDescricao(const Value: String);
begin
  FDescricao := Value;
  EdtDescricao.Text := Value;
end;

procedure TframeExtraItensAdd.Setmodificado(const Value: Integer);
begin
  Fmodificado := Value;
  if modificado = 1 then
  begin
    Rectangle1.Stroke.Color := RGB(153, 204, 50);
  end
  else
  begin
    Rectangle1.Stroke.Color := RGB(140, 23, 23);
  end;
end;

procedure TframeExtraItensAdd.SetNome(const Value: String);
begin
  FNome := Value;
  EdtNome.Text := Value;
end;

procedure TframeExtraItensAdd.SetStatus(const Value: Integer);
begin
  FStatus := Value;
  sStatus.IsChecked := Value = 1;
end;

procedure TframeExtraItensAdd.SetValor(const Value: Real);
begin
  FValor := Value;
  edtValor.Text := FormatFloat('#0.00', Value);
end;

end.
