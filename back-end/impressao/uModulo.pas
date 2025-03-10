unit uModulo;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Comp.UI, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Stan.Param, ppCtrls, ppBands, Vcl.Imaging.pngimage, ppStrtch,
  ppRichTx, ppPrnabl, ppClass, ppBarCode2D, ppDB, ppDBPipe, ppDBBDE,
  FireDAC.Comp.DataSet, ppParameter, ppDesignLayer, ppCache, ppComm, ppRelatv,
  ppProd, ppReport;

type
  TdmModulo = class(TDataModule)
    BANCO: TFDConnection;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDSchemaAdapter1: TFDSchemaAdapter;
    ppMesaR: TppReport;
    ppHeaderBand17: TppHeaderBand;
    ppDetailBand19: TppDetailBand;
    ppFooterBand17: TppFooterBand;
    ppDesignLayers19: TppDesignLayers;
    ppDesignLayer19: TppDesignLayer;
    ppParameterList17: TppParameterList;
    qryMesas: TFDQuery;
    ppMesa: TppBDEPipeline;
    dsMesa: TDataSource;
    ppDB2DBarCode1: TppDB2DBarCode;
    ppRichText1: TppRichText;
    ppImage1: TppImage;
    ppColumnHeaderBand1: TppColumnHeaderBand;
    ppColumnFooterBand1: TppColumnFooterBand;
    ppShape1: TppShape;
    procedure DataModuleDestroy(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function CriaQRY(Nome: String): TFDQuery;
    function GerarCodigo(txTabela, txCampo: String): Integer;
  end;

var
  dmModulo: TdmModulo;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
{ TdmModulo }

function TdmModulo.CriaQRY(Nome: String): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := BANCO;
end;

procedure TdmModulo.DataModuleCreate(Sender: TObject);
begin

  BANCO.Params.LoadFromFile('CONFIGURACAO\Confi.dados');

  try

  except

  end;

end;

procedure TdmModulo.DataModuleDestroy(Sender: TObject);
begin
  BANCO.CloneConnection;
end;

function TdmModulo.GerarCodigo(txTabela, txCampo: String): Integer;
var
  QRYAux001: TFDQuery;
begin
  QRYAux001 := CriaQRY('');

  QRYAux001.close;
  QRYAux001.SQL.Clear;
  QRYAux001.SQL.Add('select max(' + txCampo + ')+1 as codigo from ' + txTabela);
  QRYAux001.Open;
  if QRYAux001.FieldByName('codigo').IsNull then
    Result := 1
  else
    Result := QRYAux001.FieldByName('codigo').AsInteger;

  QRYAux001.Free;
end;

end.
