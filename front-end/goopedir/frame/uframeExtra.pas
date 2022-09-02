unit uframeExtra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, uFrameDescricaoAdicional, FMX.Layouts;

type
  TCallback = procedure of object;
  Tipo = (Extra, Pizza);

  TframeExtra = class(TFrame)
    img_un: TImage;
    img_check: TImage;
    Layout1: TLayout;
    Layout2: TLayout;
    Image1: TImage;
    imgMenos: TImage;
    lQuantidade: TLabel;
    lAdicional: TLayout;
    lDescricao: TLabel;
    lValor: TLabel;
    lSabor: TLayout;
    LValorSabor: TLabel;
    Layout4: TLayout;
    lNomeSabor: TLabel;
    LTipoSabor: TLabel;
    Rectangle1: TRectangle;
    procedure FrameClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure imgMenosClick(Sender: TObject);
    procedure lNomeSaborClick(Sender: TObject);

  private
    FCheckbox: Boolean;
    FPai: TFrameDescricaoAdicional;
    FDescricao: String;
    FQuantidade: Integer;
    FValor: Real;
    FValorTotal: Real;
    FCodigo: Integer;
    FTipoValor: Integer;
    FTipo: Tipo;
    FSabor: String;
    FCategoriaSabor: String;
    FCategoria: String;
    procedure SetCheckbox(const Value: Boolean);
    procedure SetDescricao(const Value: String);
    procedure SetPai(const Value: TFrameDescricaoAdicional);
    procedure SetQuantidade(const Value: Integer);
    { Private declarations }

    procedure Menos;
    procedure SetValor(const Value: Real);
    procedure AtualizaValor;
    procedure SetValorTotal(const Value: Real);
    procedure SetCodigo(const Value: Integer);
    procedure SetTipo(const Value: Tipo);
    procedure SetTipoValor(const Value: Integer);
    procedure SetCategoriaSabor(const Value: String);
    procedure SetSabor(const Value: String);
    procedure SetCategoria(const Value: String);
  public
    { Public declarations }
    property Categoria : String read FCategoria write SetCategoria;
    property Quantidade: Integer read FQuantidade write SetQuantidade;
    property Descricao: String read FDescricao write SetDescricao;
    property Valor: Real read FValor write SetValor;
    property Pai: TFrameDescricaoAdicional read FPai write SetPai;
    property ValorTotal: Real read FValorTotal write SetValorTotal;
    property Codigo: Integer read FCodigo write SetCodigo;

    property Tipo: Tipo read FTipo write SetTipo;
    property TipoValor: Integer read FTipoValor write SetTipoValor;
    property Sabor: String read FSabor write SetSabor;
    property CategoriaSabor: String read FCategoriaSabor
      write SetCategoriaSabor;
    procedure Mais;
  var
    AtualizaValo: TCallback;
  end;

implementation

{$R *.fmx}

uses util, uMain;
{ TFrame2 }

procedure TframeExtra.AtualizaValor;
begin
  case Tipo of
    Extra:
      begin
        ValorTotal := Valor * Quantidade;
      end;
    Pizza:
      begin
        case TipoValor of
          0:
            begin
              // 0 Media
              if Assigned(Pai) then
                ValorTotal := (Valor * Quantidade) / Pai.Maximo;
            end;
          1:
            begin
              if Assigned(Pai) then
                ValorTotal := (Valor / Pai.Maximo) * Quantidade;
            end;
          2:
            begin

              ValorTotal := Valor * Quantidade;
            end;
        end;

        // 1 Maior
        // 2 Soma
      end;
  end;

  if ValorTotal = 0 then
    ValorTotal := Valor;

  lValor.Text := '+R$ ' + FormatFloat('#0.00', ValorTotal);
  if ValorTotal = 0 then
    lValor.Text := '';

  LValorSabor.Text := lValor.Text;
  LValorSabor.Text := StringReplace(LValorSabor.Text, '+', '', [rfReplaceAll]);

  if Assigned(AtualizaValo) then
    AtualizaValo;
end;

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

procedure TframeExtra.imgMenosClick(Sender: TObject);
begin
  Menos;
end;

procedure TframeExtra.lNomeSaborClick(Sender: TObject);
begin
  Mais;
end;



procedure TframeExtra.Mais;
begin
  if Pai.Valida then
  begin
    exit;
  end;
  Pai.Mais;

  Quantidade := Quantidade + 1;
  AtualizaValor;
end;

procedure TframeExtra.Menos;
begin
  if Pai.ValidaMenos then
  begin
    exit;
  end;
  Pai.Menos;
  Quantidade := Quantidade - 1;
  AtualizaValor;
end;

procedure TframeExtra.SetCategoria(const Value: String);
begin
  FCategoria := Value;
end;

procedure TframeExtra.SetCategoriaSabor(const Value: String);
begin
  FCategoriaSabor := Value;
  LTipoSabor.Text := FormataNome(Value);
{$IFDEF Android}
  LTipoSabor.TextSettings.Font.Size := 8;
{$ENDIF}
end;

procedure TframeExtra.SetCheckbox(const Value: Boolean);
begin

end;

procedure TframeExtra.SetCodigo(const Value: Integer);
begin
  FCodigo := Value;
end;

procedure TframeExtra.SetDescricao(const Value: String);
begin
  FDescricao := Value;
  lDescricao.Text := FormataNome(Value);
  Tipo := Extra;
{$IFDEF Android}
  lDescricao.TextSettings.Font.Size := 10;
{$ENDIF}
end;

procedure TframeExtra.SetPai(const Value: TFrameDescricaoAdicional);
begin
  FPai := Value;
  FPai.ZerarSelecionado;
end;

procedure TframeExtra.SetQuantidade(const Value: Integer);
begin
  FQuantidade := Value;
  lQuantidade.Text := Value.ToString;

  imgMenos.Visible := (Quantidade > 0);
  lQuantidade.Visible := (Quantidade > 0);
  AtualizaValor;
end;

procedure TframeExtra.SetSabor(const Value: String);
begin
  FSabor := Value;
  lNomeSabor.Text := FormataNome(Value);
{$IFDEF Android}
  lNomeSabor.TextSettings.Font.Size := 16;
{$ENDIF}
end;

procedure TframeExtra.SetTipo(const Value: Tipo);
begin
  FTipo := Value;
  case FTipo of
    Extra:
      begin
        lAdicional.Visible := True;
        lSabor.Visible := False;
      end;
    Pizza:
      begin
        lAdicional.Visible := False;
        lSabor.Visible := True;
      end;
  end;
end;

procedure TframeExtra.SetTipoValor(const Value: Integer);
begin
  FTipoValor := Value;
end;

procedure TframeExtra.SetValor(const Value: Real);
begin
  FValor := Value;
  AtualizaValor;
end;

procedure TframeExtra.SetValorTotal(const Value: Real);
begin
  FValorTotal := Value;

end;

end.
