unit conexao;

interface

uses Winapi.Windows, uDM, FireDAC.Comp.Client, DataSet.Serialize,
  System.Classes,
  uRequisicao,
  Data.DB,
  JOSE.Types.JSON, Winapi.TlHelp32, Winapi.ShellAPI, Vcl.Controls, Vcl.Forms,
  Vcl.ExtCtrls, System.Hash, System.IOUtils, System.Variants, uGlobais;

type

  TLogThread1 = class(TThread)
  private
    FComputerName: string;
    FErro: string;
    FBanco: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const ComputerName, Erro, Banco: string);
  end;

  TConexao = class
  private
    FSQL: TStringlist;
    Fcache: boolean;
    procedure Zerar;
    procedure SetSQL(const Value: TStringlist);
    function MapaErro(Erro: String): String;
    procedure AbrirExe(Nome: String);
    procedure FecharExe(ExeFileName: String);

    procedure AplicarCharsetConexao;
    function GetComputerName: string;
    procedure OnTimer(Sender: TObject);
    procedure UpdateLastActivityTime;
    procedure Setcache(const Value: boolean);
    function HashSQL(const ASQL: string): string;
    function GetCache(Hash: String): TJSONArray;
    procedure SaveCache(Hash: String; Result: TJSONArray; ValidadeMinutos: Integer = 5);
    procedure AplicarCharsetCache;

  var

    DataModulo: TDM;
    FParametros: Array of String;
    FValores: Array of Variant;
    CodigoConexao: Integer;
    FTimer: TTimer;
    FLastActivityTime: TDateTime;
    FNome: String;
    ErrorGerado: String;
  public
    constructor Create(Nome: String);

    destructor Destroy; override;
    function VersaoMYSQL: String;
    function ValidaVersao: string;
    function CriaQRY: TFDQuery;
    function Charset: String;
    function ExecuteSQL(SQL: String): boolean; overload;
    procedure ExecuteSQL; overload;
    function ConsultaSQL(SQL: String): TJSONArray; overload;
    function ConsultaSQL: TJSONArray; overload;
    procedure Parametros(Parametro: String; Valor: Variant);
    property SQL: TStringlist read FSQL write SetSQL;
    function GerarID(Tabela, Campo: String): Integer;
    function Servidor: String;
    function Porta: String;

    function GenID(Campo: String): Integer;

    function FieldByName(Campo: String): Variant;

    function Insert(Tabela, CampoID: String; ID: Variant;
      DadoBody: String): boolean;

    function GetAll(Tabela: String): String;
    function GetParametro(Campo: String): Variant;
    procedure SalvarParametro(Campo, Valor: String);
    function NomeBanco: String;
    function Usuario: String;
    function Senha: String;

    function ExecutarSQLAtualizacao(SQlText, Versao: String): boolean;

    procedure GerarLog(Erro: String);
    function SoNumero(fField: String): String;
    function UltimoCodigo(Tabela: String): Integer;

    procedure EnviaGlitchtip(DSN, Tipo, Identificacao, Mensagem: String);
    function GenerateUUID: string;
    procedure DisconectBanco;
    procedure ConectaBanco(Banco: String);
    function LoadMemory(Dados: TFDMemTable): TFDMemTable;
    property cache: boolean read Fcache write Setcache;

    function BuscarCache(Hash: String): TJSONArray;
    procedure SalvarCache(Hash: String; Result: TJSONArray; ValidadeMinutos: Integer = 5);
    procedure CriarParticoesHistoricasPedidoAll;

    function GetConfiguracao(Parametro: String): String;

  end;

implementation

uses
  System.SysUtils, System.SyncObjs, Vcl.Dialogs, uPerformanceMetrics;

const
  CACHE_DATABASE = 'goopedir_cache';
  CACHE_TABLE = 'cache';
  CACHE_VALIDADE_PADRAO_MINUTOS = 5;

var
  SetNamesExecutado: Integer = 0;

{ TConexao }

function TConexao.ConsultaSQL(SQL: String): TJSONArray;
var
  QRY: TFDQuery;
  I: Integer;
  InicioSQL: UInt64;
  InicioJSON: UInt64;
  Linhas: Integer;
  TamanhoJSON: Integer;
begin
  Result := nil;
  UpdateLastActivityTime;
  QRY := CriaQRY;
  try
    try
      QRY.Close;
      QRY.SQL.Clear;
      QRY.SQL.Add(SQL);
      for I := 0 to length(FParametros) - 1 do
      begin
        QRY.ParamByName(FParametros[I]).Value := FValores[I];
      end;

      InicioSQL := GetTickCount64;
      QRY.Open;
      Linhas := QRY.RecordCount;
      PerformanceSQL(HashSQL(SQL), SQL, GetTickCount64 - InicioSQL, Linhas, True);

      InicioJSON := GetTickCount64;
      Result := QRY.ToJSONArray;
      TamanhoJSON := Length(TEncoding.UTF8.GetBytes(Result.ToJSON));
      PerformanceJSON(GetTickCount64 - InicioJSON, Result.Count, TamanhoJSON);

      if cache then
      begin
        SaveCache(HashSQL(SQL), Result);
      end;
    except
      on E: Exception do
      begin
        PerformanceSQL(HashSQL(SQL), SQL, 0, 0, False, E.Message);
        GerarLog('ConsultaSQL: ' + E.message);
        FreeAndNil(Result);
        raise;
      end;
    end;
  finally
    QRY.Free;
    Zerar;
  end;
end;
procedure TConexao.AbrirExe(Nome: String);
var
  Handle: HWND;
begin

  if length(trim(Nome)) = 0 then
    exit;
  ShellExecute(Handle, 'open', PChar(Nome), '', '', SW_SHOWNORMAL);
end;

function TConexao.BuscarCache(Hash: String): TJSONArray;
begin
  Result := GetCache(Hash);
end;

function TConexao.Charset: String;
begin
  Result := DataModulo.Banco.Params.Values['CharacterSet'];
end;

procedure TConexao.ConectaBanco(Banco: String);
var
  InicioOpen: UInt64;
begin
  InicioOpen := GetTickCount64;
  DataModulo.Banco.Connected := False;
  DataModulo.Banco.Params.Values['CharacterSet'] := 'utf8mb4';
  DataModulo.Banco.Params.Database := Banco;
  DataModulo.Banco.Connected := true;
  AplicarCharsetConexao;
  PerformanceDBConnection(FNome, 0, GetTickCount64 - InicioOpen, False);
end;

procedure TConexao.AplicarCharsetConexao;
var
  Qry: TFDQuery;
  Inicio: UInt64;
begin
  if TInterlocked.CompareExchange(SetNamesExecutado, 1, 0) <> 0 then
    Exit;

  Inicio := GetTickCount64;
  try
    if not DataModulo.Banco.Connected then
      DataModulo.Banco.Connected := True;

    Qry := DataModulo.CriaQRY;
    try
      Qry.ExecSQL('SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci');
      PerformanceStep('db_session_set_names_once', GetTickCount64 - Inicio);
    finally
      Qry.Free;
    end;
  except
    TInterlocked.Exchange(SetNamesExecutado, 0);
  end;
end;

procedure TConexao.AplicarCharsetCache;
begin
  // Charset ja e configurado na conexao FireDAC. Evita SET NAMES repetido.
end;

function TConexao.ConsultaSQL: TJSONArray;
begin
  if SQL.Text <> '' then
  begin
    if cache then
    begin

      try
        Result := GetCache(HashSQL(SQL.Text));
        if Result.Count > 0 then
        begin
          exit;
        end;
      except

      end;
    end;
    Result := ConsultaSQL(SQL.Text);
  end;
end;

constructor TConexao.Create(Nome: String);
var
  InicioCreate: UInt64;
  CreateMS: UInt64;
  InicioOpen: UInt64;
begin
  FNome := Nome;
  InicioCreate := GetTickCount64;
  DataModulo := TDM.Create(nil);
  CreateMS := GetTickCount64 - InicioCreate;
  InicioOpen := GetTickCount64;
  AplicarCharsetConexao;
  PerformanceDBConnection(FNome, CreateMS, GetTickCount64 - InicioOpen,
    DataModulo.Banco.Connected);
  FLastActivityTime := Now; // Inicia com a hora atual

  SQL := TStringlist.Create;
  Zerar;
  // try
  // CodigoConexao := GerarID('conexao', 'id');
  // except
  //
  // end;
  //
  // ExecuteSQL('insert into conexao (id,datahora, mysql) values (' +
  // CodigoConexao.ToString + ',current_timestamp,' + QuotedStr(FNome) + ')');

  FTimer := TTimer.Create(nil);
  FTimer.Interval := 10 * 1000;
  // 60000 ms = 1 minuto
  FTimer.OnTimer := OnTimer;
  FTimer.Enabled := true;

end;

function TConexao.CriaQRY: TFDQuery;
begin
  Result := DataModulo.CriaQRY;
end;

procedure TConexao.CriarParticoesHistoricasPedidoAll;
var
  Q: TFDQuery;
  DataInicial, DataFinal: TDate;
  AnoI, MesI, DiaI: Word;
  AnoF, MesF, DiaF: Word;
  DataLoop: TDate;
  NomePart: string;
  SQLParticoes: TStringlist;
begin
  SQLParticoes := TStringlist.Create;
  try
    Q := CriaQRY;

    // pega menor e maior data_pedido
    Q.SQL.Text :=
      'SELECT MIN(data_pedido) AS di, MAX(data_pedido) AS df FROM pedido';
    Q.Open;

    DataInicial := Q.FieldByName('di').AsDateTime;
    DataFinal := Q.FieldByName('df').AsDateTime;

    // garante dia = 1
    DecodeDate(DataInicial, AnoI, MesI, DiaI);
    DataInicial := EncodeDate(AnoI, MesI, 1);

    // garante dia = 1 do mês final
    DecodeDate(DataFinal, AnoF, MesF, DiaF);
    DataFinal := EncodeDate(AnoF, MesF, 1);

    // monta início do comando
    SQLParticoes.Add('ALTER TABLE pedido');
    SQLParticoes.Add('PARTITION BY RANGE (TO_DAYS(data_pedido)) (');

    DataLoop := DataInicial;

    while DataLoop <= DataFinal do
    begin
      NomePart := FormatDateTime('"p"yyyymm', DataLoop);

      SQLParticoes.Add('  PARTITION ' + NomePart +
        ' VALUES LESS THAN (TO_DAYS("' + FormatDateTime('yyyy-mm-01',
        IncMonth(DataLoop)) + '")),');

      DataLoop := IncMonth(DataLoop);
    end;

    // remover vírgula da última partição
    SQLParticoes[SQLParticoes.Count - 1] :=
      TrimRight(SQLParticoes[SQLParticoes.Count - 1]).TrimRight([',']);

    SQLParticoes.Add(');');

    ExecuteSQL(SQLParticoes.Text);
  finally
    SQLParticoes.Free;
  end;
end;

destructor TConexao.Destroy;
begin
  // ExecuteSQL('delete from conexao where id = ' + CodigoConexao.ToString);
  if Assigned(DataModulo) then
  begin
    DataModulo.Banco.Connected := False;
    FreeAndNil(DataModulo); // libera tudo corretamente
  end;
  FreeAndNil(SQL);
  FreeAndNil(FTimer);
  inherited;
end;

procedure TConexao.DisconectBanco;
begin
  DataModulo.Banco.Connected := False;
  DataModulo.Banco.Params.Database := '';
  DataModulo.Banco.Connected := true;
end;

procedure TConexao.EnviaGlitchtip(DSN, Tipo, Identificacao, Mensagem: String);
var
  JsonObjec, JSONBody, ExceptionObj, ExceptionVal, Tags: TJSONObject;
  ExceptionArr: TJSONArray;
  Chave, API, URL: string;
  iGlitchtip: iRequisicao;
begin
  exit;
  iGlitchtip := iRequisicao.Create(nil);

  // Extrai a chave e a URL da DSN
  Chave := Copy(DSN, pos('//', DSN) + 2, pos('@', DSN) - pos('//', DSN) - 2);
  URL := Copy(DSN, pos('@', DSN) + 1, length(DSN));
  URL := StringReplace(URL, '/api/', '/api/' + Chave + '/store/', []);
  API := Copy(URL, pos('/', URL) + 1, length(URL));
  URL := StringReplace(URL, '/' + API, '', []);

  // Monta JSON
  JSONBody := TJSONObject.Create;
  JSONBody.AddPair('event_id', GenerateUUID);
  JSONBody.AddPair('timestamp',
    FormatDateTime('yyyy-mm-dd"T"hh":"nn":"ss"Z"', Now));
  JSONBody.AddPair('level', Tipo);
  JSONBody.AddPair('platform', 'delphi');
  JSONBody.AddPair('message', Identificacao);

  // exception
  ExceptionObj := TJSONObject.Create;
  ExceptionVal := TJSONObject.Create;
  ExceptionVal.AddPair('type', UpperCase(Tipo));
  ExceptionVal.AddPair('value', Mensagem);

  ExceptionArr := TJSONArray.Create;
  ExceptionArr.AddElement(ExceptionVal);
  ExceptionObj.AddPair('values', ExceptionArr);
  JSONBody.AddPair('exception', ExceptionObj);

  // tags
  Tags := TJSONObject.Create;
  if (GetComputerName = 'ALLAN-PC') then
  begin
    Tags.AddPair('environment', 'desenvolvimento');
  end
  else
  begin
    Tags.AddPair('environment', 'produ??o');
  end;

  Tags.AddPair('user', GetComputerName);
  JSONBody.AddPair('tags', Tags);

  // wrapper para envio
  JsonObjec := TJSONObject.Create;
  JsonObjec.AddPair('url', 'https://' + URL + '/api/' + API + '/store/');
  JsonObjec.AddPair('autorizacao', Chave);
  JsonObjec.AddPair('body', JSONBody);

  iGlitchtip.URL := 'https://old.goopedir.com/glitchtip/index.php';
  iGlitchtip.BODY(JsonObjec);

  try
    iGlitchtip.Metodo := mPost;
    iGlitchtip.Execute;
  except
    on E: Exception do
    begin
      // tratamento
    end;
  end;

  iGlitchtip.Free;
end;

function TConexao.ExecutarSQLAtualizacao(SQlText, Versao: String): boolean;
var
  QRY: TFDQuery;
  Tipo: String;
  Erro: String;
  ID: Integer;
begin
  UpdateLastActivityTime;
  QRY := DataModulo.CriaQRY;
  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add(SQlText);
  Tipo := 'SUCESSO';
  Erro := '';
  try
    Result := true;
    QRY.ExecSQL;
  except
    on E: Exception do
    begin
      Tipo := 'ERRO';
      // Erro := e.Message;
      Result := False;
      Erro := MapaErro(E.message);
    end;
  end;
  QRY.Free;
  ID := GerarID('MEU_SQL', 'IDSQL');

  SQL.Add('INSERT INTO MEU_SQL (IDSQL,VERSAOSQL,SQLUSADOSQL,ERROSQL,DATASQL,HORASQL,STATUSSQL) VALUES (:IDSQL,:VERSAOSQL,:SQLUSADOSQL,:ERROSQL,current_date,current_time,:STATUSSQL)');
  Parametros('IDSQL', ID);
  Parametros('VERSAOSQL', Versao);
  Parametros('SQLUSADOSQL', SQlText);
  Parametros('ERROSQL', Erro);
  Parametros('STATUSSQL', Tipo);
  ExecuteSQL;

end;

procedure TConexao.ExecuteSQL;
begin

  if SQL.Text <> '' then
    ExecuteSQL(SQL.Text);
end;

procedure TConexao.FecharExe(ExeFileName: String);
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  ExeFileName := ExtractFileName(ExeFileName);

  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile))
      = UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile)
      = UpperCase(ExeFileName))) then
      TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0),
        FProcessEntry32.th32ProcessID), 0);
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function TConexao.FieldByName(Campo: String): Variant;
var
  Dados: TFDMemTable;
  Dado: String;
begin
  Dados := TFDMemTable.Create(nil);
  Dado := ConsultaSQL.ToString;
  try
    Dados.LoadFromJSON(Dado);
    Result := Dados.FieldByName(Campo).AsVariant;
  except
    Result := 0;
  end;
  Dados.Free;
end;

function TConexao.GenerateUUID: string;
var
  GUID: TGUID;
begin
  // Gera um novo GUID
  if CreateGUID(GUID) = 0 then
    // Converte o GUID para string no formato padr?o
    Result := GUIDToString(GUID)
  else
    Result := '';
  // Retorna uma string vazia em caso de erro
end;

function TConexao.GenID(Campo: String): Integer;
var
  lSQL: String;

  QRY: TFDQuery;
begin

  QRY := DataModulo.CriaQRY;

  lSQL := 'SELECT GEN_ID(' + Campo + ', 1) as id, 0 as zero FROM RDB$DATABASE';
  QRY.SQL.Add(lSQL);
  try
    QRY.Open;
  except
    on E: Exception do
    begin
      Writeln(E.message);
      Result := 1;
      exit;
    end;
  end;

  Result := QRY.FieldByName('id').AsInteger;
  QRY.Free;

end;

function TConexao.GerarID(Tabela, Campo: String): Integer;
var
  QRY: TFDQuery;
  MaxID: Integer;
begin
  QRY := CriaQRY;
  try
    // Tenta atualizar o contador e usar LAST_INSERT_ID
    QRY.SQL.Text :=
      'UPDATE geradores SET sequencial = LAST_INSERT_ID(sequencial + 1) WHERE tabela = :tabela';
    QRY.ParamByName('tabela').AsString := Tabela;
    QRY.ExecSQL;

    // Verifica se a tabela existe em `geradores`
    if QRY.RowsAffected = 0 then
    begin
      // Pega o ?ltimo c?digo da tabela real
      QRY.SQL.Text := 'SELECT MAX(' + Campo + ') AS max_id FROM ' + Tabela;
      QRY.Open;
      MaxID := QRY.FieldByName('max_id').AsInteger;
      if MaxID = 0 then
        MaxID := 1
      else
        Inc(MaxID);

      QRY.Close;
      QRY.SQL.Text :=
        'INSERT INTO geradores (tabela, sequencial) VALUES (:tabela, :valor)';
      QRY.ParamByName('tabela').AsString := Tabela;
      QRY.ParamByName('valor').AsInteger := MaxID;
      QRY.ExecSQL;

      Result := MaxID;
      exit;
    end;

    // Retorna o novo ID gerado
    QRY.Close;
    QRY.SQL.Text := 'SELECT LAST_INSERT_ID() AS novo_id';
    QRY.Open;
    Result := QRY.FieldByName('novo_id').AsInteger;
  finally
    QRY.Free;
  end;
end;

// function TConexao.GerarID(Tabela, Campo: String): Integer;
// var
// lSQL: String;
// Dados: TFDMemTable;
// Valor: Integer;
// conexao: TConexao;
// QRY: TFDQuery;
// begin
// QRY := CriaQRY;
//
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add
// ('update geradores set sequencial = sequencial + 1 where tabela = :tabela');
// QRY.ParamByName('tabela').AsString := Tabela;
// QRY.ExecSQL;
//
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add('select * from geradores where tabela = :tabela');
// QRY.ParamByName('tabela').AsString := Tabela;
// QRY.Open;
//
// if QRY.RecordCount > 0 then
// begin
// Result := QRY.FieldByName('sequencial').AsInteger;
//
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add('select ' + Campo + ' from ' + Tabela + ' where ' + Campo +
// ' = :' + Campo);
// QRY.ParamByName(Campo).AsInteger := Result;
// QRY.Open;
//
// if QRY.RecordCount > 0 then
// begin
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add('delete from geradores where tabela = :tabela');
// QRY.ParamByName('tabela').AsString := Tabela;
// QRY.ExecSQL;
// Result := 0;
// end;
//
// if Result = 0 then
// begin
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add('select max(' + Campo + ')+1 as codigo,0 as zero from '
// + Tabela);
// QRY.Open;
// try
// if QRY.FieldByName('codigo').IsNull then
// Valor := 1
// else
// Valor := QRY.FieldByName('codigo').AsInteger;
// except
//
// end;
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add
// ('insert into geradores (tabela,sequencial) values (:tabela,:sequencial)');
// QRY.ParamByName('tabela').AsString := Tabela;
// QRY.ParamByName('sequencial').AsInteger := Valor;
// QRY.ExecSQL;
// Result := Valor;
// end;
//
// QRY.Free;
// exit;
// end
// else
// begin
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add('select max(' + Campo + ')+1 as codigo,0 as zero from '
// + Tabela);
// QRY.Open;
//
// try
// if QRY.FieldByName('codigo').IsNull then
// Valor := 1
// else
// Valor := QRY.FieldByName('codigo').AsInteger;
// except
//
// end;
// QRY.Close;
// QRY.SQL.Clear;
// QRY.SQL.Add
// ('insert into geradores (tabela,sequencial) values (:tabela,:sequencial)');
// QRY.ParamByName('tabela').AsString := Tabela;
// QRY.ParamByName('sequencial').AsInteger := Valor;
// QRY.ExecSQL;
// end;
//
// Result := Valor;
// QRY.Free;
//
// end;

procedure TConexao.GerarLog(Erro: String);
var
  LogPath, LogFile, MsgLog: string;
  LogStream: TFileStream;
begin

  if not Desenvolvimento then
    exit;
    // Ignora erros de chave duplicada, como j? fazia
  if pos('Duplicate entry', Erro) > 0 then
    exit;

  if pos('Duplicate column name', Erro) > 0 then
    exit;


  // Caminho da pasta de log (na mesma pasta do execut?vel)
  LogPath := ExtractFilePath(ParamStr(0)) + 'log\';
  if not DirectoryExists(LogPath) then
    ForceDirectories(LogPath);

  // Arquivo de log do dia
  LogFile := LogPath + FormatDateTime('yyyy-mm-dd', Now) + '.log';

  // Mensagem de log
  MsgLog := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + Erro + ' - ' +
    SQL.Text + sLineBreak;

  // Escreve no arquivo
  try
    if FileExists(LogFile) then
      LogStream := TFileStream.Create(LogFile, fmOpenReadWrite or
        fmShareDenyNone)
    else
      LogStream := TFileStream.Create(LogFile, fmCreate or fmShareDenyNone);

    try
      LogStream.Seek(0, soEnd);
      LogStream.WriteBuffer(Pointer(MsgLog)^, length(MsgLog) * sizeof(Char));
    finally
      LogStream.Free;
    end;
  except
    // Se nem salvar log conseguimos, s? desiste
  end;

end;


// procedure TConexao.GerarLog(Erro: String);
// begin
// if pos('Duplicate entry', Erro) > 0 then
// begin
// exit;
// end;
//
// EnviaGlitchtip
// ('https://aeb22e97438d453c9a5651422ad3c0f4@nginx-glitchtip.l1p88w.easypanel.host/3',
// DataModulo.Banco.Params.Database, DataModulo.Banco.Params.Database,
// Erro + ' - ' + SQL.Text);
//
// end;

function TConexao.GetAll(Tabela: String): String;
begin
  UpdateLastActivityTime;
  Tabela := 'select * from ' + Tabela;

  Result := ConsultaSQL(Tabela).ToString;
end;

function TConexao.GetCache(Hash: String): TJSONArray;
var
  Qry: TFDQuery;
  JSONText: String;
  ValorJSON: TJSONValue;
begin
  Result := TJSONArray.Create;
  try
    AplicarCharsetCache;
    ExecuteSQL('CREATE DATABASE IF NOT EXISTS ' + CACHE_DATABASE +
      ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    ExecuteSQL('ALTER DATABASE ' + CACHE_DATABASE +
      ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    ExecuteSQL('CREATE TABLE IF NOT EXISTS ' + CACHE_DATABASE + '.' +
      CACHE_TABLE + ' (' +
      'origem VARCHAR(100) NOT NULL, ' +
      'chave VARCHAR(255) NOT NULL, ' +
      'dados LONGTEXT NOT NULL, ' +
      'criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, ' +
      'expira_em DATETIME NULL, ' +
      'atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, '
      + 'PRIMARY KEY (origem, chave), ' +
      'INDEX idx_cache_expira (expira_em), ' +
      'INDEX idx_cache_atualizado (atualizado_em)' +
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
    Qry := CriaQRY;
    try
      Qry.SQL.Text := 'SELECT dados FROM ' + CACHE_DATABASE + '.' +
        CACHE_TABLE + ' WHERE origem = :origem AND chave = :chave' +
        ' AND (expira_em IS NULL OR expira_em > CURRENT_TIMESTAMP)';
      Qry.ParamByName('origem').AsString := 'TConexao';
      Qry.ParamByName('chave').AsString := Hash;
      Qry.Open;
      if not Qry.Eof then
      begin
        JSONText := Qry.FieldByName('dados').AsWideString;
        ValorJSON := TJSONObject.ParseJSONValue(JSONText);
        if ValorJSON is TJSONArray then
        begin
          Result.Free;
          Result := TJSONArray(ValorJSON);
        end
        else
          ValorJSON.Free;
      end;
      if Result.Count = 0 then
      begin
        Qry.Close;
        Qry.SQL.Text := 'DELETE FROM ' + CACHE_DATABASE + '.' + CACHE_TABLE +
          ' WHERE origem = :origem AND chave = :chave' +
          ' AND expira_em <= CURRENT_TIMESTAMP';
        Qry.ParamByName('origem').AsString := 'TConexao';
        Qry.ParamByName('chave').AsString := Hash;
        Qry.ExecSQL;
      end;
    finally
      Qry.Free;
    end;
  except
    Result.Free;
    Result := TJSONArray.Create;
  end;
end;
function TConexao.GetComputerName: string;
begin
  Result := GetEnvironmentVariable('COMPUTERNAME');
end;

function TConexao.GetConfiguracao(Parametro: String): String;
begin
  Result := GetParametro(Parametro);
end;

function TConexao.GetParametro(Campo: String): Variant;
var
  QRY: TFDQuery;
  InicioSQL: UInt64;
begin
  UpdateLastActivityTime;
  try
    QRY := CriaQRY;

    QRY.Close;
    QRY.SQL.Clear;
    QRY.SQL.Add('select valor from configuracoes where chave = :chave');
    QRY.ParamByName('chave').AsString := Campo;
    InicioSQL := GetTickCount64;
    QRY.Open;
    PerformanceSQL(HashSQL(QRY.SQL.Text), QRY.SQL.Text,
      GetTickCount64 - InicioSQL, QRY.RecordCount, True);

    Result := QRY.FieldByName('valor').AsVariant;
  except
    on E: Exception do
    begin
      QRY.Close;
      QRY.SQL.Clear;
      QRY.SQL.Add('CREATE TABLE configuracoes (');
      QRY.SQL.Add('  chave VARCHAR(100) PRIMARY KEY,');
      QRY.SQL.Add('  valor TEXT');
      QRY.SQL.Add(') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
      QRY.ExecSQL;
    end;

  end;

  QRY.Free;

  // FieldByName
end;
procedure TConexao.SalvarParametro(Campo, Valor: String);
var
  QRY: TFDQuery;
begin
  UpdateLastActivityTime;
  QRY := CriaQRY;
  try
    try
      QRY.SQL.Text := 'INSERT INTO configuracoes (chave, valor) ' +
        'VALUES (:chave, :valor) ' +
        'ON DUPLICATE KEY UPDATE valor = VALUES(valor)';
      QRY.ParamByName('chave').AsString := Campo;
      QRY.ParamByName('valor').AsString := Valor;
      QRY.ExecSQL;
    except
      QRY.Close;
      QRY.SQL.Clear;
      QRY.SQL.Add('CREATE TABLE configuracoes (');
      QRY.SQL.Add('  chave VARCHAR(100) PRIMARY KEY,');
      QRY.SQL.Add('  valor TEXT');
      QRY.SQL.Add(') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
      QRY.ExecSQL;
      QRY.SQL.Text := 'INSERT INTO configuracoes (chave, valor) ' +
        'VALUES (:chave, :valor) ' +
        'ON DUPLICATE KEY UPDATE valor = VALUES(valor)';
      QRY.ParamByName('chave').AsString := Campo;
      QRY.ParamByName('valor').AsString := Valor;
      QRY.ExecSQL;
    end;
  finally
    QRY.Free;
  end;
end;
function TConexao.HashSQL(const ASQL: string): string;
begin
  Result := THashMD5.GetHashString(ASQL);
end;

function TConexao.Insert(Tabela, CampoID: String; ID: Variant;
  DadoBody: String): boolean;
var
  Dados: TFDMemTable;
  DadosQry: TFDMemTable;
  Codigo: Integer;
  I: Integer;

  Campos: String;
  CamposParametro: String;

  lSQL: String;
begin
  try
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(DadoBody);

    if Dados.RecordCount = 0 then
    begin
      Result := False;
      Dados.Free;
      exit;
    end;

    DadosQry := TFDMemTable.Create(nil);

    Campos := '';
    CamposParametro := '';

    for I := 0 to Dados.FieldCount - 1 do
    begin
      if I = 0 then
      begin
        Campos := Dados.Fields[I].FieldName;
        CamposParametro := ':' + Dados.Fields[I].FieldName;
      end
      else
      begin
        Campos := Campos + ',' + Dados.Fields[I].FieldName;
        CamposParametro := CamposParametro + ',:' + Dados.Fields[I].FieldName;
      end;
    end;
    Dados.first;
    while not Dados.Eof do
    begin
      Codigo := 0;
      try
        DadosQry.Close;
        DadosQry.LoadFromJSON(ConsultaSQL('SELECT GEN_ID(' + ID +
          ', 1) as ID, 0 as zero FROM RDB$DATABASE'));
        Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName).AsInteger;
      except
        // N?o foi dessa vez
      end;

      if Codigo = 0 then
      begin
        try
          DadosQry.Close;
          DadosQry.LoadFromJSON
            (ConsultaSQL('SELECT MAX(' + ID + ')+1 as ID, 0 as zero FROM '
            + Tabela));

          Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName)
            .AsInteger;
        except

        end;
      end;

      // if Codigo = 0 then
      // begin
      // try
      // DadosQry.Close;
      // DadosQry.LoadFromJSON(ConsultaSQL(ID));
      // Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName)
      // .AsInteger;
      // except
      //
      // end;
      // end;

      if Codigo = 0 then
      begin
        try
          DadosQry.Close;
          DadosQry.LoadFromJSON(ConsultaSQL('SELECT MAX(' + CampoID +
            ')+1 as ID, 0 as zero FROM ' + Tabela));
          Writeln('SELECT MAX(' + CampoID + ')+1 as ID, 0 as zero FROM '
            + Tabela);
          Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName)
            .AsInteger;
        except

        end;
      end;
      lSQL := 'insert into ' + Tabela + ' (' + Campos + ') values (' +
        CamposParametro + ')';
      SQL.Add(lSQL);

      for I := 0 to Dados.FieldCount - 1 do
      begin
        if Dados.Fields[I].FieldName = CampoID then
          Parametros(Dados.Fields[I].FieldName, Codigo)
        else
          Parametros(Dados.Fields[I].FieldName,
            Dados.FieldByName(Dados.Fields[I].FieldName).AsVariant);
      end;
      Codigo := 0;

      ExecuteSQL(SQL.Text);

      Dados.Next;
    end;
  except
    on E: Exception do
    begin
      Writeln('1');
      Writeln(E.message);
    end;

  end;

end;

function TConexao.LoadMemory(Dados: TFDMemTable): TFDMemTable;
begin
  if not Assigned(Dados) then
    Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(ConsultaSQL);
end;

function TConexao.MapaErro(Erro: String): String;
begin
  Erro := UpperCase(Erro);
  Result := Erro;
  if pos('TOKEN UNKNOWN', Erro) > 0 then
  begin
    Result := 'Tabela Não Localizada';
  end;

  if pos('TABLE SQL ALREADY EXISTS', Erro) > 0 then
  begin
    Result := 'Tabela já Existente';
  end;
end;

function TConexao.NomeBanco: String;
begin
  Result := LowerCase(DataModulo.Banco.Params.Database);
end;

procedure TConexao.OnTimer(Sender: TObject);
begin
  if (Now - FLastActivityTime) * 24 * 60 > 1 then
  begin
    FTimer.Enabled := False;

    try
      if Assigned(DataModulo) then
      begin
        if DataModulo.Banco.Connected then
          DataModulo.Banco.Connected := False;
      end;
    except
    end;
  end;
end;

function TConexao.ExecuteSQL(SQL: String): boolean;
var
  QRY: TFDQuery;
  I: Integer;
  New: String;
  Update: boolean;
  SqlUpdate: String;
  QryUpdate: TFDQuery;
  InicioSQL: UInt64;
begin
  UpdateLastActivityTime;
  QryUpdate := DataModulo.CriaQRY;
  try
    // Update := UpperCase(Copy(trim(UpperCase(SQL)), 0, 6)) = 'UPDATE';
    if Update then
    begin
      SqlUpdate := Copy(SQL, 1, pos('SET', SQL) + length('SET')) +
        ' modificado_site = 0 ' + Copy(SQL, pos('WHERE', SQL), length(SQL));
      QryUpdate := DataModulo.CriaQRY;
      QryUpdate.SQL.Add(SqlUpdate);

    end;
    if (Pos('CREATE TABLE', UpperCase(SQL)) > 0) and
      (Pos('CREATE TABLE IF NOT EXISTS', UpperCase(SQL)) = 0) then
      SQL := StringReplace(SQL, 'CREATE TABLE',
        'CREATE TABLE IF NOT EXISTS', [rfIgnoreCase]);

    QRY := DataModulo.CriaQRY;
    Result := true;
    QRY.Close;
    QRY.SQL.Clear;
    QRY.SQL.Add(SQL);
    for I := 0 to length(FParametros) - 1 do
    begin
      if (FValores[I]) = null then
      begin
        QRY.ParamByName(FParametros[I]).DataType := ftInteger;
        QRY.ParamByName(FParametros[I]).Clear();
      end
      else
      begin
        if VarIsStr(FValores[I]) then
        begin
          if Length(VarToStr(FValores[I])) > 32767 then
            QRY.ParamByName(FParametros[I]).DataType := ftWideMemo
          else
            QRY.ParamByName(FParametros[I]).DataType := ftWideString;
          QRY.ParamByName(FParametros[I]).Size := Length(VarToStr(FValores[I]));
          QRY.ParamByName(FParametros[I]).AsWideString := VarToStr(FValores[I]);
        end
        else
          QRY.ParamByName(FParametros[I]).Value := FValores[I];
      end;

      try
        if Update then
        begin

          // if IsInteger(FValores[I]) then
          // begin
          // QryUpdate.ParamByName(FParametros[I]).Value := StrToInt(FValores[I]);
          // end else begin
          try
            QryUpdate.ParamByName(FParametros[I]).AsFloat :=
              StrToFloat(FValores[I]);
          except
            QryUpdate.ParamByName(FParametros[I]).Value := FValores[I];
          end;
          // end;
        end;
      except

      end;
    end;

    if Update then
    begin
      try
        QryUpdate.ExecSQL;
      except
      end;

    end;
    QryUpdate.Free;
    InicioSQL := GetTickCount64;
    try
      QRY.ExecSQL;
      PerformanceSQL(HashSQL(SQL), SQL, GetTickCount64 - InicioSQL,
        QRY.RowsAffected, True);
    except
      on E: Exception do
      begin
        PerformanceSQL(HashSQL(SQL), SQL, GetTickCount64 - InicioSQL, 0,
          False, E.Message);
        raise;
      end;
    end;

  except
    on E: Exception do
    begin
      GerarLog(E.message);
      Zerar;

      Result := False;
    end;
  end;

  // if pos('insert into conexao (id,datahora)', LowerCase(SQL)) = 0 then
  // begin
  // QRY.SQL.Text := 'update conexao set mysql = "' + Copy(FNome + '-' + SQL, 1,
  // 253) + '", datahora = current_timestamp where id = ' +
  // CodigoConexao.ToString;
  // try
  // QRY.ExecSQL;
  // except
  //
  // end;
  // end;

  QRY.Free;
  Zerar;

end;

procedure TConexao.Parametros(Parametro: String; Valor: Variant);
var
  I: Integer;
  Achou: boolean;
begin
  Achou := False;
  for I := 0 to length(FParametros) - 1 do
  begin
    if FParametros[I] = Parametro then
    begin
      Achou := true;
      break;
    end;
  end;

  if Achou then
  begin
    FValores[I] := Valor;
  end
  else
  begin
    I := length(FParametros);
    SetLength(FParametros, I + 1);
    SetLength(FValores, I + 1);
    FParametros[I] := Parametro;
    FValores[I] := Valor;
  end;

end;

function TConexao.Porta: String;
begin
  Result := LowerCase(DataModulo.Banco.Params.Values['Port']);
end;

function NormalizaValidadeCache(ValidadeMinutos: Integer): Integer;
begin
  Result := ValidadeMinutos;
  if Result <= 0 then
    Result := CACHE_VALIDADE_PADRAO_MINUTOS;
end;

procedure TConexao.SalvarCache(Hash: String; Result: TJSONArray; ValidadeMinutos: Integer);
begin
  SaveCache(Hash, Result, ValidadeMinutos);
end;

procedure TConexao.SaveCache(Hash: String; Result: TJSONArray; ValidadeMinutos: Integer);
begin
  try
    AplicarCharsetCache;
    ExecuteSQL('CREATE DATABASE IF NOT EXISTS ' + CACHE_DATABASE +
      ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    ExecuteSQL('ALTER DATABASE ' + CACHE_DATABASE +
      ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    ExecuteSQL('CREATE TABLE IF NOT EXISTS ' + CACHE_DATABASE + '.' +
      CACHE_TABLE + ' (' +
      'origem VARCHAR(100) NOT NULL, ' +
      'chave VARCHAR(255) NOT NULL, ' +
      'dados LONGTEXT NOT NULL, ' +
      'criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, ' +
      'expira_em DATETIME NULL, ' +
      'atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, '
      + 'PRIMARY KEY (origem, chave), ' +
      'INDEX idx_cache_expira (expira_em), ' +
      'INDEX idx_cache_atualizado (atualizado_em)' +
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
    ExecuteSQL('ALTER TABLE ' + CACHE_DATABASE + '.' + CACHE_TABLE +
      ' CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    ExecuteSQL('ALTER TABLE ' + CACHE_DATABASE + '.' + CACHE_TABLE +
      ' MODIFY dados LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL');
    SQL.Add('INSERT INTO ' + CACHE_DATABASE + '.' + CACHE_TABLE);
    SQL.Add('(origem, chave, dados, expira_em)');
    SQL.Add('VALUES (:origem, :chave, :dados, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL ' +
      NormalizaValidadeCache(ValidadeMinutos).ToString + ' MINUTE))');
    SQL.Add('ON DUPLICATE KEY UPDATE dados = VALUES(dados),');
    SQL.Add('expira_em = VALUES(expira_em),');
    SQL.Add('atualizado_em = CURRENT_TIMESTAMP');
    Parametros('origem', 'TConexao');
    Parametros('chave', Hash);
    Parametros('dados', Result.ToJSON);
    ExecuteSQL;
  except
  end;
end;
function TConexao.Senha: String;
begin
  Result := LowerCase(DataModulo.Banco.Params.Password);
end;

function TConexao.Servidor: String;
begin
  Result := LowerCase(DataModulo.Banco.Params.Values['Server']);
end;

procedure TConexao.Setcache(const Value: boolean);
begin
  Fcache := Value;
end;

procedure TConexao.SetSQL(const Value: TStringlist);
begin
  FSQL := Value;
end;

function TConexao.SoNumero(fField: String): String;
var
  I: Byte;
begin
  Result := '';
  for I := 1 To length(fField) do
    if fField[I] In ['0' .. '9'] Then
      Result := Result + fField[I];
end;

function TConexao.UltimoCodigo(Tabela: String): Integer;
var
  QRY: TFDQuery;
begin
  QRY := DataModulo.CriaQRY;
  QRY.SQL.Add
    ('SELECT AUTO_INCREMENT as codigo, 0 as zero FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = "'
    + DataModulo.Banco.Params.Database + '" AND TABLE_NAME = "' +
    Tabela + '";');
  QRY.Open;

  Result := QRY.FieldByName('codigo').AsInteger;

  QRY.Free;

end;

procedure TConexao.UpdateLastActivityTime;
begin
  FLastActivityTime := Now;
  // Atualiza a ?ltima hora de atividade
end;

function TConexao.Usuario: String;
begin
  Result := LowerCase(DataModulo.Banco.Params.UserName);
end;

function TConexao.ValidaVersao: string;
Var
  MYSQL: String;
  VersaoNumber: Integer;
begin
  MYSQL := SoNumero(VersaoMYSQL);
  // MYSQL := SoNumero('5.7.37-log');
  // ////////showmessage1(MYSQL);

  VersaoNumber := StrToInt(StringReplace(MYSQL, '.', '', [rfReplaceAll]));

  if VersaoNumber = 8027 then
  begin
    Result := '';
  end
  else
  begin
    // Result := 'A sua vers?o do mysql (' + VersaoMYSQL +
    // ') est? desatualizada, para o funcionamento do sistema deve-se instalar a vers?o (8.0.27)';
    Result := '';
  end;

end;

function TConexao.VersaoMYSQL: String;
Var
  Banco: String;
  Query: TFDQuery;
begin
  try
    Banco := DataModulo.Banco.Params.Database;
    DataModulo.Banco.Close;
    DataModulo.Banco.Params.Database := 'sys';
    DataModulo.Banco.Open;
    Query := DataModulo.CriaQRY;
    Query.SQL.Add('SELECT * FROM version');
    Query.Open;

    Result := Query.FieldByName('mysql_version').AsString;

    DataModulo.Banco.Close;
    DataModulo.Banco.Params.Database := Banco;
    DataModulo.Banco.Open;

    Query.Free;
  except
    Result := '8027';
  end;

end;

procedure TConexao.Zerar;
begin
  SetLength(FParametros, 0);
  SetLength(FValores, 0);
  try
    SQL.Clear;
  except

  end;
end;

{ TLogThread1 }

constructor TLogThread1.Create(const ComputerName, Erro, Banco: string);
begin
  inherited Create(true); // Cria a Thread1 suspensa
  FormatSettings.DecimalSeparator := ',';
  FComputerName := ComputerName;
  FErro := Erro;
  FBanco := Banco;
  FreeOnTerminate := true; // Libera a mem?ria automaticamente ao t?rmino
  Start;
end;

procedure TLogThread1.Execute;
var
  JSON: TJSONObject;
  Requisicao: iRequisicao;
begin
  try
    JSON := TJSONObject.Create;
    try
      // Configura o JSON com os valores
      JSON.AddPair('computer_name', FComputerName);
      JSON.AddPair('error_message', FErro);
      JSON.AddPair('banco', FBanco);

      // Cria e configura a requisi??o
      Requisicao := iRequisicao.Create(nil);
      try
        Requisicao.BaseURL := 'https://old.goopedir.com/logger.php';
        Requisicao.BODY(JSON);
        Requisicao.Metodo := mPost;
        Requisicao.Execute;
      finally
        Requisicao.Free;
      end;
    finally
      JSON.Free;
    end;
  except
    on E: Exception do
    begin

    end;
  end;
end;

end.
