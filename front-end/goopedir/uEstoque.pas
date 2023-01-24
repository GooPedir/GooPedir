unit uEstoque;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uFrmClonePadrao, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FMX.TabControl, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uMemTable,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, System.Rtti,
  FMX.Grid.Style, Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Bind.Grid,
  System.Bindings.Outputs, FMX.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.DBScope, FMX.ScrollBox, FMX.Grid, FMXTee.Canvas,
  FMX.ListBox, FMX.Edit;

type
  TfrmEstoque = class(TfrmPadrao)
    tabPrincipal: TTabItem;
    TabEntradaEstoque: TTabItem;
    DADOS: TFDMemTable;
    Layout1: TLayout;
    Grid1: TGrid;
    DADOSID: TIntegerField;
    DADOSTIPO: TIntegerField;
    DADOSNOME: TStringField;
    DADOSUN: TStringField;
    DADOSQTD: TFloatField;
    DADOSENTRADA: TFloatField;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBindSourceDB1: TLinkGridToDataSource;
    Layout2: TLayout;
    edtPesquisa: TEdit;
    Label1: TLabel;
    EdtNome: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    edtQuantidade: TEdit;
    Label4: TLabel;
    edtFator: TEdit;
    Label5: TLabel;
    cUnidade: TComboBox;
    layUltimos2: TLayout;
    rProd1: TRectangle;
    lUn1: TLabel;
    lNome1: TLabel;
    rProd2: TRectangle;
    lUn2: TLabel;
    lNome2: TLabel;
    DADOSSEQUENCIAL: TIntegerField;
    edtValorUnitario: TEdit;
    Label6: TLabel;
    edtValorTotal: TEdit;
    Label7: TLabel;
    memEntradaEstoque: iMemTable;
    memEntradaEstoqueSEQUENCIAL: TIntegerField;
    memEntradaEstoqueID: TIntegerField;
    memEntradaEstoqueTIPO: TIntegerField;
    memEntradaEstoqueNOME: TStringField;
    memEntradaEstoqueUN: TStringField;
    memEntradaEstoqueQTD: TFloatField;
    memEntradaEstoqueCUSTOUN: TFloatField;
    memEntradaEstoqueCUSTOTOTAL: TFloatField;
    memEntradaEstoqueSEQLOCAL: TIntegerField;
    Grid2: TGrid;
    Button1: TButton;
    BindSourceDB2: TBindSourceDB;
    LinkGridToDataSourceBindSourceDB2: TLinkGridToDataSource;
    Layout3: TLayout;
    Label8: TLabel;
    lQuantidade: TLabel;
    Label10: TLabel;
    lTotal: TLabel;
    memFatorConversao: TFDMemTable;
    memFatorConversaovalor: TFloatField;
    lDescFator: TLabel;
    lQtdEntrada: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Grid1DrawColumnCell(Sender: TObject; const Canvas: TCanvas;
      const Column: TColumn; const Bounds: TRectF; const Row: Integer;
      const Value: TValue; const State: TGridDrawStates);
    procedure edtPesquisaKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure rProd1Click(Sender: TObject);
    procedure edtQuantidadeExit(Sender: TObject);
    procedure edtValorUnitarioExit(Sender: TObject);
    procedure edtValorTotalExit(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Grid2DrawColumnCell(Sender: TObject; const Canvas: TCanvas;
      const Column: TColumn; const Bounds: TRectF; const Row: Integer;
      const Value: TValue; const State: TGridDrawStates);
    procedure cUnidadeChange(Sender: TObject);
    procedure edtFatorExit(Sender: TObject);
  private
    FTipoSelecionado: Integer;
    FDescricaoSelecionado: String;
    FIdSelecionado: Integer;
    procedure SetDescricaoSelecionado(const Value: String);
    procedure SetIdSelecionado(const Value: Integer);
    procedure SetTipoSelecionado(const Value: Integer);
    procedure CalculaValores(Tipo: Integer);
    procedure Adicionar;
    procedure Deletar;
    procedure AtualizaLabelEntrada;
    { Private declarations }
  public
    { Public declarations }
    property TipoSelecionado: Integer read FTipoSelecionado
      write SetTipoSelecionado;
    property IdSelecionado: Integer read FIdSelecionado write SetIdSelecionado;
    property DescricaoSelecionado: String read FDescricaoSelecionado
      write SetDescricaoSelecionado;
  end;

var
  frmEstoque: TfrmEstoque;
  Sequencial: Integer;

implementation

{$R *.fmx}

uses Funcoes;

procedure TfrmEstoque.Adicionar;
var
  Total: Real;
  Quantidade: Real;
begin
  if not memEntradaEstoque.Active then
  begin
    memEntradaEstoque.Open;
  end;

  if edtFator.Visible then
  begin
    PostSimples('v1/util/fator/conversao/' + cUnidade.Items[cUnidade.ItemIndex]
      + '/' + DADOS.FieldByName('UN').AsString + '/' + edtFator.text + '/' +
      DADOS.FieldByName('TIPO').AsString + '/' + DADOS.FieldByName('ID')
      .AsString, nil);
  end;

  if memEntradaEstoque.Locate('SEQLOCAL', DADOS.FieldByName('SEQUENCIAL')
    .AsInteger) then
  begin
    exit;
  end;

  try
    Quantidade := StrToFloat(edtQuantidade.text);
    if edtFator.Visible then
      Quantidade := StrToFloat(edtQuantidade.text) * StrToFloat(edtFator.text);

  except
    Quantidade := 0;
  end;

  try
    Total := StrToFloat(lTotal.text);
  except
    Total := 0;
  end;

  inc(Sequencial);
  memEntradaEstoque.insert;
  memEntradaEstoque.FieldByName('SEQUENCIAL').AsInteger := Sequencial;
  memEntradaEstoque.FieldByName('ID').AsInteger := DADOS.FieldByName('ID')
    .AsInteger;
  memEntradaEstoque.FieldByName('TIPO').AsInteger := DADOS.FieldByName('TIPO')
    .AsInteger;
  memEntradaEstoque.FieldByName('NOME').AsString :=
    DADOS.FieldByName('NOME').AsString;
  memEntradaEstoque.FieldByName('UN').AsString :=
    DADOS.FieldByName('UN').AsString;
  memEntradaEstoque.FieldByName('QTD').AsFloat := Quantidade;
  memEntradaEstoque.FieldByName('CUSTOUN').AsString := edtValorUnitario.text;
  memEntradaEstoque.FieldByName('CUSTOTOTAL').AsString := edtValorTotal.text;
  memEntradaEstoque.FieldByName('SEQLOCAL').AsInteger :=
    DADOS.FieldByName('SEQUENCIAL').AsInteger;
  memEntradaEstoque.Post;

  Total := Total + memEntradaEstoque.FieldByName('CUSTOTOTAL').AsFloat;
  Quantidade := StrToFloat(lQuantidade.text) + Quantidade;

  lQuantidade.text := FormatFloat('#0.000', Quantidade);
  lTotal.text := FormatFloat('#0.000', Total);

  edtQuantidade.text := '0,000';
  edtValorUnitario.text := '0,000';
  edtValorTotal.text := '0,000';
  cUnidade.ItemIndex := 0;
  EdtNome.text := '';
  edtPesquisa.SetFocus;
  edtFator.Visible := False;
  DADOS.Filtered := False;
  lDescFator.Visible := False;
  lQtdEntrada.Visible := False;

end;

procedure TfrmEstoque.AtualizaLabelEntrada;
var
  Quantidade: Real;
begin
  Quantidade := StrToFloat(edtFator.text) * StrToFloat(edtQuantidade.text);
  lQtdEntrada.text := FormatFloat('#0.000', Quantidade) +
    DADOS.FieldByName('UN').AsString;
end;

procedure TfrmEstoque.Button1Click(Sender: TObject);
begin
  inherited;
  Adicionar;
end;

procedure TfrmEstoque.CalculaValores(Tipo: Integer);
var
  Quantidade: Real;
  ValorUnitario: Real;
  ValorTotal: Real;
begin
  try
    Quantidade := StrToFloat(edtQuantidade.text);
  except

  end;
  try
    ValorUnitario := StrToFloat(edtValorUnitario.text);
  except

  end;
  try
    ValorTotal := StrToFloat(edtValorTotal.text);
  except

  end;
  if Tipo = 1 then
  begin
    ValorTotal := Quantidade * ValorUnitario;
  end
  else if Tipo = 2 then
  begin
    ValorUnitario := ValorTotal / Quantidade;
  end
  else
  begin
    ValorTotal := Quantidade * ValorUnitario;
  end;
  edtQuantidade.text := FormatFloat('#0.000', Quantidade);
  edtValorUnitario.text := FormatFloat('#0.000', ValorUnitario);
  edtValorTotal.text := FormatFloat('#0.000', ValorTotal);

end;

procedure TfrmEstoque.cUnidadeChange(Sender: TObject);
begin
  inherited;
  edtFator.Visible := (cUnidade.Items[cUnidade.ItemIndex] <>
    DADOS.FieldByName('UN').AsString);
  lDescFator.Visible := edtFator.Visible;
  lQtdEntrada.Visible := edtFator.Visible;
  if edtFator.Visible then
  begin

    memFatorConversao.Close;
    GetSimples2('v1/util/fator/conversao/' + cUnidade.Items[cUnidade.ItemIndex]
      + '/' + DADOS.FieldByName('TIPO').AsString + '/' + DADOS.FieldByName('ID')
      .AsString, memFatorConversao);

    if memFatorConversao.RecordCount > 0 then
    begin
      try
        edtFator.text := FormatFloat('#0.000',
          memFatorConversao.FieldByName('valor').AsFloat);
      except

      end;
    end;

    AtualizaLabelEntrada;
    lDescFator.text := 'A cada 1,000' + cUnidade.Items[cUnidade.ItemIndex] +
      ' converte em ' + edtFator.text + DADOS.FieldByName('UN').AsString;
  end;

end;

procedure TfrmEstoque.Deletar;
var
  Total: Real;
  Quantidade: Real;
begin
  try
    Quantidade := StrToFloat(lQuantidade.text);
  except
    Quantidade := 0;
  end;

  try
    Total := StrToFloat(lTotal.text);
  except
    Total := 0;
  end;
  if memEntradaEstoque.RecordCount = 0 then
    exit;

  Total := Total - memEntradaEstoque.FieldByName('CUSTOTOTAL').AsFloat;
  Quantidade := Quantidade - memEntradaEstoque.FieldByName('QTD').AsFloat;
  memEntradaEstoque.Delete;
  lQuantidade.text := FormatFloat('#0.000', Quantidade);
  lTotal.text := FormatFloat('#0.000', Total);
end;

procedure TfrmEstoque.edtFatorExit(Sender: TObject);
begin
  inherited;
  try
    edtFator.text := FormatFloat('#0.000', StrToFloat(edtFator.text));
  except
    edtFator.SetFocus;
    exit;
  end;
  lDescFator.text := 'A cada 1,000' + cUnidade.Items[cUnidade.ItemIndex] +
    ' converte em ' + edtFator.text + DADOS.FieldByName('UN').AsString;
  AtualizaLabelEntrada;
end;

procedure TfrmEstoque.edtPesquisaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  inherited;

  if Key = 13 then
  begin
    try
      DADOS.Filter := 'NOME LIKE ' +
        QuotedStr('%' + UpperCase(edtPesquisa.text) + '%');
      DADOS.Filtered := Length(edtPesquisa.text) > 0;
    except
      DADOS.Filtered := False;
    end;

    layUltimos2.Visible := DADOS.RecordCount > 0;
    lNome1.text := DADOS.FieldByName('NOME').AsString;
    lUn1.text := DADOS.FieldByName('UN').AsString;
    rProd1.Tag := DADOS.FieldByName('SEQUENCIAL').AsInteger;

    DADOS.Next;
    lNome2.text := DADOS.FieldByName('NOME').AsString;
    lUn2.text := DADOS.FieldByName('UN').AsString;
    rProd2.Visible := NOT DADOS.RecordCount = 1;
    rProd2.Tag := DADOS.FieldByName('SEQUENCIAL').AsInteger;

    lNome2.text := DADOS.FieldByName('NOME').AsString;
    lUn2.text := DADOS.FieldByName('UN').AsString;

    {
      Id1 : Integer;
      Id2 : Integer;
      Tipo1 : Integer;
      Tipo2 : Integer;
      Nome1 : String;
      Nome2 : String;
      Unidade1 : String;
      Unidade2 : String;
    }

  end;

end;

procedure TfrmEstoque.edtQuantidadeExit(Sender: TObject);
begin
  inherited;
  CalculaValores(0);
  AtualizaLabelEntrada;
end;

procedure TfrmEstoque.edtValorTotalExit(Sender: TObject);
begin
  inherited;
  CalculaValores(2);
end;

procedure TfrmEstoque.edtValorUnitarioExit(Sender: TObject);
begin
  inherited;
  CalculaValores(1);
end;

procedure TfrmEstoque.FormCreate(Sender: TObject);
begin
  inherited;
  GetSimples2('v1/util/estoque/geral', DADOS);
  layUltimos2.Visible := False;
  edtFator.Visible := False;
  lDescFator.Visible := False;
  lQtdEntrada.Visible := False;
end;

procedure TfrmEstoque.Grid1DrawColumnCell(Sender: TObject;
  const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF;
  const Row: Integer; const Value: TValue; const State: TGridDrawStates);
var
  Estoque: Real;
  Cor: TColor;
begin

  case Column.Index of
    0:
      begin
        // Status

        if (Value.ToString = '1') then
        begin
          Canvas.Fill.Color := RGB(109, 178, 253);
          Canvas.Stroke.Color := RGB(109, 178, 253);

          Canvas.FillRect(Bounds, 0, 0, [], 1);
          Canvas.Fill.Color := RGB(255, 255, 255);
          Canvas.FillText(Bounds, 'PRODUTO', False, 1,
            [ { TFillTextFlag.RightToLef } ], TTextAlign.Center,
            TTextAlign.Center);
        end
        else
        begin
          Canvas.Fill.Color := RGB(144, 11, 250);
          Canvas.Stroke.Color := RGB(144, 11, 250);

          Canvas.FillRect(Bounds, 0, 0, [], 1);
          Canvas.Fill.Color := RGB(255, 255, 255);
          Canvas.FillText(Bounds, 'INSULMOS', False, 1,
            [ { TFillTextFlag.RightToLef } ], TTextAlign.Center,
            TTextAlign.Center);
        end;
      end;
    3:
      begin
        try
          Estoque := StrToFloat(Value.ToString);
        except
          Estoque := 0;
        end;
        Cor := RGB(253, 128, 0);
        if Estoque > 10 then
        begin
          Cor := RGB(49, 204, 175);
        end;
        if Estoque < 0 then
        begin
          Cor := RGB(247, 114, 115);
        end;

        Canvas.Fill.Color := Cor;
        Canvas.Stroke.Color := Cor;

        Canvas.FillRect(Bounds, 0, 0, [], 1);
        Canvas.Fill.Color := RGB(255, 255, 255);
        Canvas.FillText(Bounds, FormatFloat('#0.000', Estoque), False, 1,
          [ { TFillTextFlag.RightToLef } ], TTextAlign.Center,
          TTextAlign.Center);
      end;
  end;
end;

procedure TfrmEstoque.Grid2DrawColumnCell(Sender: TObject;
  const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF;
  const Row: Integer; const Value: TValue; const State: TGridDrawStates);
var
  Estoque: Real;
  Cor: TColor;
begin

  case Column.Index of
    0:
      begin
        // Status

        if (Value.ToString = '1') then
        begin
          Canvas.Fill.Color := RGB(109, 178, 253);
          Canvas.Stroke.Color := RGB(109, 178, 253);

          Canvas.FillRect(Bounds, 0, 0, [], 1);
          Canvas.Fill.Color := RGB(255, 255, 255);
          Canvas.FillText(Bounds, 'PRODUTO', False, 1,
            [ { TFillTextFlag.RightToLef } ], TTextAlign.Center,
            TTextAlign.Center);
        end
        else
        begin
          Canvas.Fill.Color := RGB(144, 11, 250);
          Canvas.Stroke.Color := RGB(144, 11, 250);

          Canvas.FillRect(Bounds, 0, 0, [], 1);
          Canvas.Fill.Color := RGB(255, 255, 255);
          Canvas.FillText(Bounds, 'INSULMOS', False, 1,
            [ { TFillTextFlag.RightToLef } ], TTextAlign.Center,
            TTextAlign.Center);
        end;
      end;
    3:
      begin
        // try
        // Estoque := StrToFloat(Value.ToString);
        // except
        // Estoque := 0;
        // end;
        // Cor := RGB(253, 128, 0);
        // if Estoque > 10 then
        // begin
        // Cor := RGB(49, 204, 175);
        // end;
        // if Estoque < 0 then
        // begin
        // Cor := RGB(247, 114, 115);
        // end;
        //
        // Canvas.Fill.Color := Cor;
        // Canvas.Stroke.Color := Cor;
        //
        // Canvas.FillRect(Bounds, 0, 0, [], 1);
        // Canvas.Fill.Color := RGB(255, 255, 255);
        // Canvas.FillText(Bounds, FormatFloat('#0.000', Estoque), False, 1,
        // [ { TFillTextFlag.RightToLef } ], TTextAlign.Center,
        // TTextAlign.Center);
      end;
  end;
end;

procedure TfrmEstoque.rProd1Click(Sender: TObject);
var
  I: Integer;
begin
  inherited;
  edtPesquisa.text := '';
  DADOS.Filtered := False;
  if (DADOS.Locate('SEQUENCIAL', (Sender AS TRectangle).Tag, [])) then
  begin
    EdtNome.text := DADOS.FieldByName('NOME').AsString;
    for I := 0 to cUnidade.Items.Count - 1 do
    begin
      if (cUnidade.Items[I] = DADOS.FieldByName('UN').AsString) then
        cUnidade.ItemIndex := I;
    end;
  end;
  edtQuantidade.text := '0,000';
  edtValorUnitario.text := '0,000';
  edtValorTotal.text := '0,000';
  layUltimos2.Visible := False;
  edtQuantidade.SetFocus;
  edtQuantidade.SelectAll;
end;

procedure TfrmEstoque.SetDescricaoSelecionado(const Value: String);
begin
  FDescricaoSelecionado := Value;
end;

procedure TfrmEstoque.SetIdSelecionado(const Value: Integer);
begin
  FIdSelecionado := Value;
end;

procedure TfrmEstoque.SetTipoSelecionado(const Value: Integer);
begin
  FTipoSelecionado := Value;
end;

initialization

RegisterClass(TfrmEstoque);

end.
