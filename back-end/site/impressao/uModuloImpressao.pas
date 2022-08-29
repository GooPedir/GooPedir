unit uModuloImpressao;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, ppVar, ppBarCode2D,
  ppCtrls, ppBands, ppDB, ppClass, ppPrnabl, ppStrtch, ppRichTx, ppCache,
  ppDesignLayer, ppParameter, Data.DB, ppDBPipe, ppDBBDE, ppComm, ppRelatv,
  ppProd, ppReport, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TdmImpressaoV2 = class(TDataModule)
    DADOS: TFDQuery;
    dsDados: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function ImprimirComanda(Relatorio: TppReport;
      CodigoPedido, Vias: Integer): Boolean;

    procedure LogMemo(Mensagem: String);
  end;

var
  dmImpressaoV2: TdmImpressaoV2;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses uModulo;

{$R *.dfm}
{ TdmImpressaoV2 }

procedure TdmImpressaoV2.DataModuleCreate(Sender: TObject);
begin
  ImprimirComanda(COMANDA80MM, 1100, 0);
end;

function TdmImpressaoV2.ImprimirComanda(Relatorio: TppReport;
  CodigoPedido, Vias: Integer): Boolean;
var
  Impressora: Array of String;
  AuxImpressora: String;
  I: Integer;
begin
  DADOS.Close;
  DADOS.ParamByName('codigo_pedido').AsInteger := CodigoPedido;
  DADOS.Open;


  for I := 1 to length(DADOS.FieldByName('impressora_delivery').AsString) do
  begin
    if DADOS.FieldByName('impressora_delivery').AsString[I] = ',' then
    begin

      SetLength(Impressora, length(Impressora) + 1);
      Impressora[length(Impressora) - 1] := AuxImpressora;
      AuxImpressora := '';
    end
    else
    begin
      AuxImpressora := AuxImpressora + DADOS.FieldByName('impressora_delivery').AsString [I];
    end;
  end;

  Relatorio.ShowCancelDialog := False;
  Relatorio.ShowPrintDialog := False;
  Relatorio.DeviceType := 'Printer';

  for I := 0 to length(Impressora) - 1 do
  begin
    Relatorio.PrinterSetup.PrinterName := Impressora[I];
    try
      if Vias = 0 then
        Relatorio.PrintReport
      else
      begin
        Vias := Vias - 1;
        if (I < Vias) or (I = Vias) then
          Relatorio.PrintReport;
      end;
    except
      on E: Exception do
      begin
        LogMemo('Erro Na Impressão');
        LogMemo('Data: '+FormatDateTime('dd/mm/yyyy hh:nn:ss',now));
        LogMemo('Código Pedido: ' + CodigoPedido.ToString);
        LogMemo('Driver: ' + Impressora[I]);
        LogMemo('Erro: '+E.Message);
        LogMemo('');
      end;
    end;
  end;


end;

procedure TdmImpressaoV2.LogMemo(Mensagem: String);
begin
  //
end;

end.
