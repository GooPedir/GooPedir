unit uDM;

interface

uses
  System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
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
    function PathExe: String;

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

uses  System.SysUtils, Vcl.Forms;
{$R *.dfm}
{ Tdm }




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
    ForceDirectories(PathExe+'configuracao');
    Banco.Params.SaveToFile('configuracao\Confi.dados');
  end;
    Banco.Params.Values['CharacterSet'] := 'utf8mb4';
    Banco.Params.Values['Pooled'] := 'True';
    Banco.Params.Values['POOL_MaximumItems'] := '50';
    Banco.Params.Values['POOL_ExpireTimeout'] := '90000';
    Banco.Params.Values['POOL_CleanupTimeout'] := '30000';
    if Banco.Params.IndexOfName('SSLProtocol') < 0 then
      Banco.Params.Add('SSLProtocol=TLSv1.2')
    else
      Banco.Params.Values['SSLProtocol'] := 'TLSv1.2';

    Banco.Params.Values['Reconnect'] := 'True';
    Banco.Params.Values['Compress'] := 'false';
    Banco.Params.Values['SSLMode'] := 'DISABLED';  // ou 'REQUIRED' se o SSL for necessário


    Banco.ResourceOptions.SilentMode := True;
    Banco.ResourceOptions.AutoReconnect := True;

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

function Tdm.PathExe: String;
begin
 Result := ExtractFilePath(Application.ExeName);
end;

end.
