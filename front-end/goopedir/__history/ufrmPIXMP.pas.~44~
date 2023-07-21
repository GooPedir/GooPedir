unit ufrmPIXMP;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, uRequisicao,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uMemTable;

type
  TfrmPIXMP = class(TForm)
    Layout1: TLayout;
    img_qrcod: TImage;
    Rectangle1: TRectangle;
    Label1: TLabel;
    Label2: TLabel;
    lValor: TLabel;
    tVerificaStatus: TTimer;
    procedure lValorClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tVerificaStatusTimer(Sender: TObject);
  private
    FValor: Real;
    FPedido: Integer;
    FCodigoPagamento: Integer;
    FPago: Boolean;
    FIDMP: String;
    FTransacao: String;

    procedure SetPedido(const Value: Integer);
    procedure SetValor(const Value: Real);
    { Private declarations }
    procedure GetPix;
    procedure SetCodigoPagamento(const Value: Integer);
    procedure SetPago(const Value: Boolean);
    procedure SetIDMP(const Value: String);
    procedure SetTransacao(const Value: String);
    function ValorPix : String;

  public
    { Public declarations }
    property CodigoPagamento: Integer read FCodigoPagamento
      write SetCodigoPagamento;
    property Valor: Real read FValor write SetValor;
    property Pedido: Integer read FPedido write SetPedido;
    procedure Load;
    property Pago: Boolean read FPago write SetPago;
    property IDMP: String read FIDMP write SetIDMP;
    property Transacao: String read FTransacao write SetTransacao;

  var
    PAGAMENTO: iMemTable;
  end;

var
  frmPIXMP: TfrmPIXMP;

implementation

{$R *.fmx}

uses uDM, System.JSON, util;

{ TfrmPIXMP }

procedure TfrmPIXMP.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not Pago then
    PAGAMENTO.Cancel
  else
  begin
    PAGAMENTO.FieldByName('TRANSACAO_MP').AsString := Transacao;
  end;
end;

procedure TfrmPIXMP.GetPix;
var
  JSonValue: TJSonValue;
  Retorno: String;
begin


  TThread.CreateAnonymousThread(
    procedure
    begin
      Retorno := dm.PostSimplesComRetorno('/v1/gera/pix/:token_mp/' + ValorPix +
        '/' + Pedido.ToString);

      try
        JSonValue := TJSonObject.ParseJSONValue(Retorno);

        img_qrcod.Bitmap := dm.BitmapFromBase64(JSonValue.GetValue<string>('base64'));
        IDMP := Pedido.ToString;
      except
      on E : Exception do
      begin
      ShowMessage(e.Message);
        ShowMessageToast(nil, 'Erro ao gerar o pix!', 1);
        Close;
      end;
      end;

    end).Start;

end;

procedure TfrmPIXMP.Load;
begin
  GetPix;
end;

procedure TfrmPIXMP.lValorClick(Sender: TObject);
begin
  Pago := True;
end;

procedure TfrmPIXMP.SetCodigoPagamento(const Value: Integer);
begin
  FCodigoPagamento := Value;
end;

procedure TfrmPIXMP.SetIDMP(const Value: String);
begin
  FIDMP := Value;
end;

procedure TfrmPIXMP.SetPago(const Value: Boolean);
begin
  FPago := Value;
end;

procedure TfrmPIXMP.SetPedido(const Value: Integer);
begin
  FPedido := Value;

end;

procedure TfrmPIXMP.SetTransacao(const Value: String);
begin
  FTransacao := Value;
end;

procedure TfrmPIXMP.SetValor(const Value: Real);
begin
  FValor := Value;
  lValor.Text := FormatFloat('#0.00', Value);
end;

procedure TfrmPIXMP.tVerificaStatusTimer(Sender: TObject);
var
  JSonValue: TJSonValue;
  Retorno: String;
begin
  // tVerificaStatus.Enabled := False;
  if length(IDMP) > 0 then
  begin
     Retorno := dm.PostSimplesComRetorno('/v1/gera/pix/:token_mp/' + ValorPix +
        '/' + Pedido.ToString);

    try
     JSonValue := TJSonObject.ParseJSONValue(Retorno);
     if (Length(JSonValue.GetValue<string>('transaction_id'))>1) then
     begin
        tVerificaStatus.Enabled := False;
        Transacao := JSonValue.GetValue<string>('transaction_id');
        Pago := True;
        Close;
     end;

    except

    end;
  end;

end;

function TfrmPIXMP.ValorPix: String;
begin
  Result := FloatToStr(Valor);
  Result := StringReplace(Result, ',', '.', []);

end;

end.
