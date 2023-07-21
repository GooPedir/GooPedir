unit uModulo;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Comp.UI, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt;

type
  TdmModulo = class(TDataModule)
    BANCO: TFDConnection;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDSchemaAdapter1: TFDSchemaAdapter;
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
  // Banco.Params.SaveToFile('CONFIGURACAO\Confi.dados');
   BANCO.Params.LoadFromFile('CONFIGURACAO\Confi.dados');
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
