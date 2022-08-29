unit cFrameCombo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.ListBox, FMX.Controls.Presentation;

type
  TFrameCombo = class(TFrame)
    cItem: TComboBox;
    lTitulo: TLabel;
    procedure cItemClick(Sender: TObject);
    procedure cItemChange(Sender: TObject);
  private
    FDescricao: String;
    FCampo: String;
    FSomaUm: Boolean;
    procedure SetCampo(const Value: String);
    procedure SetDescricao(const Value: String);
    procedure SetSomaUm(const Value: Boolean);
    { Private declarations }
  public
    { Public declarations }
    property Campo: String read FCampo write SetCampo;
    property Descricao: String read FDescricao write SetDescricao;
    procedure AdicionaValor(Valor: String);
    property SomaUm: Boolean read FSomaUm write SetSomaUm;
  end;

implementation

{$R *.fmx}

uses uDM, util;

{ TFrameCombo }

procedure TFrameCombo.AdicionaValor(Valor: String);
begin

  cItem.Items.Add(Valor);
  try
    cItem.ItemIndex := Dm.DADOS_WHATSAPP.FindField(Campo).AsInteger;
    if SomaUm then
      cItem.ItemIndex := Dm.DADOS_WHATSAPP.FindField(Campo).AsInteger - 1;

  except

  end;

end;

procedure TFrameCombo.cItemChange(Sender: TObject);
var
  Valor: Integer;
begin
  Valor := cItem.ItemIndex;
  if SomaUm then
    Valor := Valor + 1;

  Dm.AtualizaParametro(Campo, Valor.ToString);
  Dm.DADOS_WHATSAPP.Edit;
  Dm.DADOS_WHATSAPP.FieldByName(Campo).AsVariant := Valor;
  Dm.DADOS_WHATSAPP.Post;
end;

procedure TFrameCombo.cItemClick(Sender: TObject);
var
  Valor: Integer;
begin
  Valor := cItem.ItemIndex;
  if SomaUm then
    Valor := Valor + 1;

  Dm.AtualizaParametro(Campo, Valor.ToString);
  Dm.DADOS_WHATSAPP.Edit;
  Dm.DADOS_WHATSAPP.FieldByName(Campo).AsVariant := Valor;
  Dm.DADOS_WHATSAPP.Post;
end;

procedure TFrameCombo.SetCampo(const Value: String);
begin
  Dm.GetNomeEmpresa;
  FCampo := Value;

  if Assigned(Dm.DADOS_WHATSAPP.FindField(Value)) then
  begin
    if Dm.DADOS_WHATSAPP.FieldByName(Value).IsNull then
    begin
      Dm.CriaCampo(Campo + ' integer');
    end;
    cItem.Items.Clear;
    // if length(ValorTrue) = 0 then
    // ValorTrue := '1';
    //
    // try
    // sSelecao.IsChecked := (ValorTrue = Dm.DADOS_WHATSAPP.FieldByName(Value)
    // .AsVariant);
    // except
    // sSelecao.IsChecked := False;
    // end;
    //
    // Valor := sSelecao.IsChecked;
    /// /    btnSalvar.Visible := False;
    Descricao := Dm.DADOS_WHATSAPP.FindField(Value).DisplayName;

  end
  else
  begin
    ShowMessage('campo "' + Value +
      '" não foi declarado na memorytable "DADOS_WHATSAPP" no datamodule!');
  end;
end;

procedure TFrameCombo.SetDescricao(const Value: String);
begin
  FDescricao := Value;
  if Value <> '' then
    lTitulo.Text := FormataNome(Value);

end;

procedure TFrameCombo.SetSomaUm(const Value: Boolean);
begin
  FSomaUm := Value;
end;

end.
