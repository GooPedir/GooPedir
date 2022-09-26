unit uModulo;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Comp.UI, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, uRequisicao;

type
  TdmModulo = class(TDataModule)
    BANCO: TFDConnection;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDSchemaAdapter1: TFDSchemaAdapter;
    getCodigo: iRequisicao;
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
  Valor: Integer;
begin
  getCodigo.URL := '/' + txTabela + '/' + txCampo;
  getCodigo.Execute;
  try
    Result := getCodigo.Retorno.ToInteger;
  except
    Result := GerarCodigo(txTabela, txCampo);
  end;
  { QRYAux001 := CriaQRY('');


    QRYAux001.SQL.Add
    ('update geradores set sequencial = sequencial + 1 where tabela = :tabela');
    QRYAux001.ParamByName('tabela').AsString := txTabela;
    QRYAux001.ExecSQL;
    QRYAux001.Close;
    QRYAux001.SQL.Clear;
    QRYAux001.SQL.Add('select * from geradores where tabela = :tabela');
    QRYAux001.ParamByName('tabela').AsString := txTabela;
    QRYAux001.Open;

    if QRYAux001.RecordCount = 1 then
    begin
    Valor := QRYAux001.FieldByName('sequencial').AsInteger;
    end
    else
    begin
    QRYAux001.Close;
    QRYAux001.SQL.Clear;
    QRYAux001.SQL.Add('select max(' + txCampo + ')+100 as codigo from ' +
    txTabela);
    QRYAux001.Open;

    if QRYAux001.FieldByName('codigo').IsNull then
    Valor := 1
    else
    Valor := QRYAux001.FieldByName('codigo').AsInteger;

    QRYAux001.Close;
    QRYAux001.SQL.Clear;
    QRYAux001.SQL.Add
    ('insert into geradores (tabela,sequencial) values (:tabela,:sequencial)');
    QRYAux001.ParamByName('tabela').AsString := txTabela;
    QRYAux001.ParamByName('sequencial').AsInteger := Valor;
    QRYAux001.ExecSQL;
    end;

    Result := Valor;

    QRYAux001.Free; }
end;

end.
