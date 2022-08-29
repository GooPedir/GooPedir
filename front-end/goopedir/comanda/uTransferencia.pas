unit uTransferencia;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uMemTable, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox,
  Data.Bind.Components, Data.Bind.DBScope, System.Rtti, System.Bindings.Outputs,
  FMX.Bind.Editors, Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Edit, uButton,
  FMX.Grid.Style, FMX.Bind.Grid, Data.Bind.Grid, FMX.ScrollBox, FMX.Grid;

type
  TCallback = procedure of object;

  TfrmTransferenciaItem = class(TForm)
    Layout1: TLayout;
    rect_login: TRectangle;
    lTransfMesa: TLabel;
    Rectangle1: TRectangle;
    Layout2: TLayout;
    Rectangle2: TRectangle;
    ComboBox1: TComboBox;
    BindingsList1: TBindingsList;
    edtValor: TEdit;
    btnSim: iButton;
    PRODUTOS: iMemTable;
    PRODUTOScodigo: TIntegerField;
    PRODUTOSnome_produto: TStringField;
    PRODUTOSquantidade: TIntegerField;
    PRODUTOSvalor_total: TFloatField;
    PRODUTOSobs: TStringField;
    BDSPRODUTOS: TBindSourceDB;
    Lista: TStringGrid;
    LinkGridToDataSourceBDSPRODUTOS: TLinkGridToDataSource;
    lValorSelecionado: TLabel;
    Layout3: TLayout;
    Label1: TLabel;
    Layout4: TLayout;
    Label2: TLabel;
    Layout5: TLayout;
    Label4: TLabel;
    edtTotal: TEdit;
    EdtPago: TEdit;
    EdtDiferenca: TEdit;
    btnFinalizar: iButton;
    StringGrid1: TStringGrid;
    edtDividir: TEdit;
    Label5: TLabel;
    iButton1: iButton;
    Image1: TImage;
    MESA: iMemTable;
    MESAid_mesa: TIntegerField;
    MESAnr_mesa: TIntegerField;
    MESAdescricao: TStringField;
    MESAsts_mesa: TIntegerField;
    MESAtot_mesa: TFloatField;
    BDSMESA: TBindSourceDB;
    LinkGridToDataSourceBDSMESA: TLinkGridToDataSource;
    PRODUTOSselecionado: TIntegerField;
    PRODUTOSsl: TIntegerField;
    procedure ListaCellDblClick(const Column: TColumn; const Row: Integer);
    procedure ListaDrawColumnCell(Sender: TObject; const Canvas: TCanvas;
      const Column: TColumn; const Bounds: TRectF; const Row: Integer;
      const Value: TValue; const State: TGridDrawStates);
    procedure edtDividirExit(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure iButton1Click(Sender: TObject);
  private
    FCodigoPedido: Integer;
    FSomaSelecionado: Real;
    FValor: Real;
    FPago: Real;
    FCodigo: Integer;
    FDescricaoMesa: String;
    FID: Integer;
    procedure SetCodigoPedido(const Value: Integer);
    procedure SetSomaSelecionado(const Value: Real);
    procedure SetValor(const Value: Real);
    procedure SetPago(const Value: Real);
    procedure SetDescricaoMesa(const Value: String);
    procedure SetID(const Value: Integer);
    { Private declarations }
    //
    property SomaSelecionado: Real read FSomaSelecionado
      write SetSomaSelecionado;
    function GerarCodigo: Integer;
    procedure SomarPagamento;

    procedure Concluir;
  public
    { Public declarations }
    Executar: TCallback;
    Cancelar: TCallback;
    property DescricaoMesa: String read FDescricaoMesa write SetDescricaoMesa;
    property Valor: Real read FValor write SetValor;
    property CodigoPedido: Integer read FCodigoPedido write SetCodigoPedido;

    property ID: Integer read FID write SetID;

  end;

var
  frmTransferenciaItem: TfrmTransferenciaItem;

implementation

{$R *.fmx}

uses Funcoes, FMXTee.Canvas, uSimNao;

procedure TfrmTransferenciaItem.Concluir;
begin
  PostSimples('/v1/transferencia/mesa/' + BDSMESA.DataSet.FieldByName('id_mesa')
    .AsString + '/' + ID.ToString, PRODUTOS);
  Executar;

end;

procedure TfrmTransferenciaItem.edtDividirExit(Sender: TObject);
begin
  try
    case StrToInt((Sender as TEdit).Text) of
      0:
        begin
          (Sender as TEdit).Text := '1';
        end;
    end;

    SomaSelecionado := SomaSelecionado;
  except
    (Sender as TEdit).SetFocus;
  end;
end;

function TfrmTransferenciaItem.GerarCodigo: Integer;
begin
  Result := FCodigo + 1;
end;

procedure TfrmTransferenciaItem.iButton1Click(Sender: TObject);
begin
  frmSimNao.titulo := 'Transferência';
  frmSimNao.descricao := 'Confirma a transferencia?';
  frmSimNao.Sim := Concluir;
  frmSimNao.Show;

end;

procedure TfrmTransferenciaItem.Image1Click(Sender: TObject);
begin
  hide;
end;

procedure TfrmTransferenciaItem.ListaCellDblClick(const Column: TColumn;
  const Row: Integer);
var
  Valor: Integer;
begin

  if PRODUTOS.FieldByName(PRODUTOS.Fields[5].FieldName).IsNull then
  begin
    Valor := 1;
    SomaSelecionado := SomaSelecionado + PRODUTOS.FieldByName
      (PRODUTOS.Fields[3].FieldName).AsFloat;
  end
  else
  begin
    case PRODUTOS.FieldByName(PRODUTOS.Fields[5].FieldName).AsInteger of
      0:
        begin
          Valor := 1;
          SomaSelecionado := SomaSelecionado + PRODUTOS.FieldByName
            (PRODUTOS.Fields[3].FieldName).AsFloat;
        end
    else
      begin
        Valor := 0;
        SomaSelecionado := SomaSelecionado - PRODUTOS.FieldByName
          (PRODUTOS.Fields[3].FieldName).AsFloat;
      end;
    end;

  end;
  PRODUTOS.Edit;
  PRODUTOS.FieldByName(PRODUTOS.Fields[5].FieldName).AsInteger := Valor;
  PRODUTOS.FieldByName('sl').AsInteger := Valor;
  PRODUTOS.Post;
end;

procedure TfrmTransferenciaItem.ListaDrawColumnCell(Sender: TObject;
  const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF;
  const Row: Integer; const Value: TValue; const State: TGridDrawStates);
var
  Cor: TColor;
begin
  case Column.Index of
    0:
      begin
        if Value.ToString = '1' then
        begin
          Cor := RGB(165, 218, 232);
        end
        else
        begin
          Cor := RGB(255, 255, 255);
        end;
        Canvas.Fill.Color := Cor;
        Canvas.Stroke.Color := Cor;
        Canvas.FillRect(Bounds, 0, 0, [], 1);
        Canvas.Fill.Color := Cor;
        Canvas.FillText(Bounds, Value.ToString, False, 1,
          [ { TFillTextFlag.RightToLef } ], TTextAlign.Center,
          TTextAlign.Center);
      end;
  end;
end;

procedure TfrmTransferenciaItem.SetCodigoPedido(const Value: Integer);
begin
  FCodigoPedido := Value;
  getsimples('/v1/pedido/produtos/' + CodigoPedido.ToString, PRODUTOS);
  getsimples('/v1/mesas', MESA);
  if MESA.Locate('id_mesa', ID, []) then
  begin
    MESA.Delete;
  end;
  MESA.First;
end;

procedure TfrmTransferenciaItem.SetDescricaoMesa(const Value: String);
begin
  FDescricaoMesa := Value;

  lTransfMesa.Text := 'Transferência de Produto - ' + Value;
end;

procedure TfrmTransferenciaItem.SetID(const Value: Integer);
begin
  FID := Value;
end;

procedure TfrmTransferenciaItem.SetPago(const Value: Real);
begin
  FPago := Value;
  EdtPago.Text := FormatFloat('R$ ###,###,##0.00', FPago);
  EdtDiferenca.Text := FormatFloat('R$ ###,###,##0.00', FValor - FPago);
end;

procedure TfrmTransferenciaItem.SetSomaSelecionado(const Value: Real);
begin
  FSomaSelecionado := Value;
  if edtDividir.Text.ToInteger = 1 then
  begin
    lValorSelecionado.Text := 'Valor R$ ' + FormatFloat('#0.00',
      Value / edtDividir.Text.ToInteger);
  end
  else
  begin
    lValorSelecionado.Text := 'Valor R$ ' + FormatFloat('#0.00', Value) +
      ' / Cada R$ ' + FormatFloat('#0.00', Value / edtDividir.Text.ToInteger);
  end;
end;

procedure TfrmTransferenciaItem.SetValor(const Value: Real);
begin
  FValor := Value;
  edtTotal.Text := FormatFloat('R$ ###,###,##0.00', Value);
end;

procedure TfrmTransferenciaItem.SomarPagamento;

begin

end;

end.
