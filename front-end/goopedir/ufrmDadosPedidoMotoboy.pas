unit ufrmDadosPedidoMotoboy;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.Objects;

type
  TfrmDadosPedidoMotoboy = class(TFrame)
    edtNome: TEdit;
    Label3: TLabel;
    edtPedidos: TEdit;
    Label1: TLabel;
    edtTaxa: TEdit;
    Label7: TLabel;
    EdtTotal: TEdit;
    Label2: TLabel;
    rBottom: TRectangle;
    rLateral: TRectangle;
  private
    FTaxa: Real;
    FPedido: String;
    FTotal: Real;
    FNome: String;
    procedure SetNome(const Value: String);
    procedure SetPedido(const Value: String);
    procedure SetTaxa(const Value: Real);
    procedure SetTotal(const Value: Real);
    var
    ArrayPedido : Array of Integer;
    { Private declarations }
  public
    { Public declarations }
    property Nome : String read FNome write SetNome;
    property Pedido : String read FPedido write SetPedido;
    property Taxa : Real read FTaxa write SetTaxa;
    property Total : Real read FTotal write SetTotal;

    procedure Gravar(Codigo,CodigoDia:Integer;Taxa,Total:Real);
  end;

implementation

{$R *.fmx}

{ TfrmDadosPedidoMotoboy }

procedure TfrmDadosPedidoMotoboy.Gravar(Codigo, CodigoDia: Integer; Taxa,
  Total: Real);
begin
//
end;

procedure TfrmDadosPedidoMotoboy.SetNome(const Value: String);
begin
  FNome := Value;
  edtNome.Text := Value;
end;

procedure TfrmDadosPedidoMotoboy.SetPedido(const Value: String);
begin
  FPedido := Value;
  edtPedidos.Text := Value;
end;

procedure TfrmDadosPedidoMotoboy.SetTaxa(const Value: Real);
begin
  FTaxa := Value;
  edtTaxa.Text := FormatFloat('R$ ###,##0.00', Value);
end;

procedure TfrmDadosPedidoMotoboy.SetTotal(const Value: Real);
begin
  FTotal := Value;
  EdtTotal.Text := FormatFloat('R$ ###,##0.00', Value);
end;

end.
