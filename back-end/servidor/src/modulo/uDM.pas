unit uDM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, FireDAC.ConsoleUI.Wait, Data.DB, FireDAC.Comp.Client,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.Phys.IBBase, FireDAC.Stan.StorageBin, FireDAC.Comp.UI,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs;

type
  Tdm = class(TDataModule)
    SQLite: TFDConnection;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDStanStorageBinLink1: TFDStanStorageBinLink;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    Banco: TFDConnection;
    dados: TFDMemTable;
    procedure SQLiteError(ASender, AInitiator: TObject;
      var AException: Exception);
    procedure DataModuleCreate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    function GerarID(Tabela, ID: String): integer;
    function CriaTablea(Tabela: String): TFDTable;
    function CriaQry: TFDQuery;
    // constructor Create; reintroduce;

    // SQlite Conversao
    function CriaQryConversao: TFDQuery;

  var
    EmUso: Boolean;
    Hora: TTime;
  end;

const
  CHAVE_SECRETA =
    '&F4iHG$N&F4iHG$N50gQ2ptsJMj%e^3NONjSy^XUo@UpclZK%9ucHiHI4T50gQ2pt&F4iHG$N50gQ2ptsJMj%e^3NONjSy^XUo@UpclZK%9ucHiHI4TsJMj%e^3NONjSy^XUo@UpclZK%9ucHiHI4T';

var
  dm: Tdm;
  Caminho: String;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

uses uMain;
{$R *.dfm}
{ Tdm }

procedure Tdm.SQLiteError(ASender, AInitiator: TObject;
  var AException: Exception);
begin
  Writeln(datetostr(date) + ' - ' + timetostr(time) +
    ' : Erro na conexão com a base de dados -> ' + AException.Message);
end;

// constructor Tdm.Create;
// begin
// inherited Create(nil);
// end;

function Tdm.CriaQry: TFDQuery;
begin
  Result := TFDQuery.Create(self);
  Result.Connection := Banco;
end;

function Tdm.CriaQryConversao: TFDQuery;
begin
  Result := TFDQuery.Create(self);
  Result.Connection := SQLite;
end;

function Tdm.CriaTablea(Tabela: String): TFDTable;
begin
  Result := TFDTable.Create(self);
  Result.Connection := Banco;
  Result.TableName := Tabela;
  Result.Open;
end;

procedure Tdm.DataModuleCreate(Sender: TObject);
begin

  Caminho := ExtractFileDir(ParamStr(0));
  // Banco.Params.a
  // Banco.Params.DataBase := Caminho + '\database\database.db';   ,

  if FileExists('CONFIGURACAO\Confi.dados') then
  begin
    Banco.Params.LoadFromFile('configuracao\Confi.dados');
  end
  else begin
    ForceDirectories(frmServidor.PathExe+'configuracao');

    Banco.Params.SaveToFile('configuracao\Confi.dados');
  end;


end;

function Tdm.GerarID(Tabela, ID: String): integer;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(self);
  try
    Query.Connection := Banco;
    Query.SQL.Clear;
    Query.SQL.Add('select max(' + ID + ') as id from ' + Tabela);
    Query.Open;
    Result := Query.FieldByName('id').AsInteger + 1;
  finally
    Query.Free;
  end;

end;

end.
