unit uPerformanceMetrics;

interface

uses
  Horse;

type
  TPerformanceScope = class
  private
    FStep: string;
    FInicio: UInt64;
  public
    constructor Create(const AStep: string);
    destructor Destroy; override;
  end;

procedure PerformanceMetricsMiddleware(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
procedure PerformanceSQL(const SQLHash, SQLText: string; DurationMS: UInt64;
  Rows: Integer; Success: Boolean; const ErrorMessage: string = '');
procedure PerformanceJSON(DurationMS: UInt64; Rows: Integer; Bytes: Integer);
procedure PerformanceStep(const StepName: string; DurationMS: Int64);
procedure PerformanceCacheStep(const CacheName, StepName: string;
  DurationMS: Int64);
procedure PerformanceLockWait(const LockName: string; DurationMS: Int64);
procedure PerformanceLockHold(const LockName: string; DurationMS: Int64);
procedure PerformanceDBConnection(const ConnectionName: string; CreateMS,
  OpenMS: UInt64; Reused: Boolean);
procedure PerformanceStatusField(const FieldName: string; Bytes: Integer);
procedure PerformanceParamSlow(const Parametro: string; DurationMS: Int64);
procedure PerformanceSyncMesas(Empresa: Integer; ClientVersion,
  ServerVersion: Int64; Changed: Boolean; VersionQueryMS, DataQueryMS,
  SerializeMS: Int64; Bytes: Integer; TotalMS: Int64);

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  System.SyncObjs, System.Generics.Collections;

type
  TPerformanceLogThread = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

  TRequestMetrics = record
    Active: Boolean;
    RequestId: string;
    Metodo: string;
    Endpoint: string;
    AcceptedAt: UInt64;
    HandlerStartedAt: UInt64;
    Inicio: UInt64;
    ActiveStart: Int64;
    QueueMS: UInt64;
    MiddlewareMS: UInt64;
    CacheMS: UInt64;
    LockWaitMS: UInt64;
    LoggerMS: UInt64;
    DBConnectionMS: UInt64;
    ProcessingMS: UInt64;
    ResponseMS: UInt64;
    TempoSQLMS: UInt64;
    TempoJSONMS: UInt64;
    QuantidadeQueries: Integer;
    QuantidadeLinhas: Integer;
    TamanhoRespostaBytes: Integer;
    StatusHTTP: Integer;
    Erro: string;
  end;

threadvar
  CurrentMetrics: TRequestMetrics;

var
  LogInitLock: TCriticalSection;
  LogQueue: TThreadedQueue<string>;
  LogThread: TPerformanceLogThread;
  RequestCounter: Int64;
  RequestsActive: Int64;
  RequestsTotal: Int64;
  RequestsPeak: Int64;
  LoggerDropped: Int64;

function MetricsEnabled: Boolean;
begin
  {$IFDEF DEBUG}
  Result := True;
  {$ENDIF}
  Result := False;
end;

function LogDirectory: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'log\performance');
end;

function TimestampISO: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now);
end;

function Sanitize(const Value: string; MaxLen: Integer): string;
begin
  Result := StringReplace(Value, sLineBreak, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #9, ' ', [rfReplaceAll]);
  Result := Trim(Result);
  if Length(Result) > MaxLen then
    Result := Copy(Result, 1, MaxLen) + '...';
end;

function NextRequestId: string;
var
  Counter: Int64;
begin
  Counter := TInterlocked.Increment(RequestCounter);
  Result := FormatDateTime('yyyymmddhhnnsszzz', Now) + '-' +
    Format('%.6d', [Counter]);
end;

constructor TPerformanceScope.Create(const AStep: string);
begin
  inherited Create;
  FStep := AStep;
  FInicio := GetTickCount64;
end;

destructor TPerformanceScope.Destroy;
begin
  PerformanceStep(FStep, GetTickCount64 - FInicio);
  inherited;
end;

procedure EnsureLoggerStarted;
begin
  if LogThread <> nil then
    Exit;

  LogInitLock.Acquire;
  try
    if LogQueue = nil then
      LogQueue := TThreadedQueue<string>.Create(10000, 10, 10);

    if LogThread = nil then
      LogThread := TPerformanceLogThread.Create;
  finally
    LogInitLock.Release;
  end;
end;

procedure AppendLog(const Line: string);
var
  EnqueueStart: UInt64;
  QueueResult: TWaitResult;
  QueueSize: Integer;
  Dropped: Int64;
  EnqueueMS: UInt64;
begin
  if not MetricsEnabled then
    Exit;

  EnsureLoggerStarted;

  EnqueueStart := GetTickCount64;
  QueueResult := LogQueue.PushItem(Line);
  EnqueueMS := GetTickCount64 - EnqueueStart;
  if CurrentMetrics.Active then
    Inc(CurrentMetrics.LoggerMS, EnqueueMS);
  if QueueResult <> wrSignaled then
    Dropped := TInterlocked.Increment(LoggerDropped)
  else
    Dropped := LoggerDropped;

  QueueSize := LogQueue.QueueSize;
  if (EnqueueMS >= 5) or (Dropped > 0) then
    LogQueue.PushItem(Format('[LOGGER] timestamp=%s enqueue_ms=%d queue_size=%d dropped=%d',
      [TimestampISO, EnqueueMS, QueueSize, Dropped]));
end;

constructor TPerformanceLogThread.Create;
begin
  inherited Create(False);
  FreeOnTerminate := False;
end;

procedure TPerformanceLogThread.Execute;
var
  FileName: string;
  Line: string;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    while not Terminated do
    begin
      Lines.Clear;
      if LogQueue.PopItem(Line) = wrSignaled then
      begin
        Lines.Add(Line);
        while (Lines.Count < 200) and (LogQueue.QueueSize > 0) and
          (LogQueue.PopItem(Line) = wrSignaled) do
          Lines.Add(Line);

        ForceDirectories(LogDirectory);
        FileName := TPath.Combine(LogDirectory,
          FormatDateTime('yyyy-mm-dd', Date) + '.log');
        TFile.AppendAllText(FileName, Lines.Text, TEncoding.UTF8);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure ClearCurrentMetrics;
begin
  CurrentMetrics.Active := False;
  CurrentMetrics.RequestId := '';
  CurrentMetrics.Metodo := '';
  CurrentMetrics.Endpoint := '';
  CurrentMetrics.Inicio := 0;
  CurrentMetrics.AcceptedAt := 0;
  CurrentMetrics.HandlerStartedAt := 0;
  CurrentMetrics.ActiveStart := 0;
  CurrentMetrics.QueueMS := 0;
  CurrentMetrics.MiddlewareMS := 0;
  CurrentMetrics.CacheMS := 0;
  CurrentMetrics.LockWaitMS := 0;
  CurrentMetrics.LoggerMS := 0;
  CurrentMetrics.DBConnectionMS := 0;
  CurrentMetrics.ProcessingMS := 0;
  CurrentMetrics.ResponseMS := 0;
  CurrentMetrics.TempoSQLMS := 0;
  CurrentMetrics.TempoJSONMS := 0;
  CurrentMetrics.QuantidadeQueries := 0;
  CurrentMetrics.QuantidadeLinhas := 0;
  CurrentMetrics.TamanhoRespostaBytes := 0;
  CurrentMetrics.StatusHTTP := 0;
  CurrentMetrics.Erro := '';
end;

procedure PerformanceSQL(const SQLHash, SQLText: string; DurationMS: UInt64;
  Rows: Integer; Success: Boolean; const ErrorMessage: string);
var
  Line: string;
begin
  if not CurrentMetrics.Active then
    Exit;

  Inc(CurrentMetrics.QuantidadeQueries);
  Inc(CurrentMetrics.QuantidadeLinhas, Rows);
  Inc(CurrentMetrics.TempoSQLMS, DurationMS);

  AppendLog(Format('[SQL] timestamp=%s request_id=%s query_id=%d sql_hash=%s execute_ms=%d rows=%d success=%s',
    [TimestampISO, CurrentMetrics.RequestId, CurrentMetrics.QuantidadeQueries,
     SQLHash, DurationMS, Rows, BoolToStr(Success, True)]));

  if (DurationMS >= 100) or (not Success) then
  begin
    Line := Format('[SLOW_SQL] timestamp=%s request_id=%s endpoint=%s duration_ms=%d rows=%d sql_hash=%s success=%s sql="%s" error="%s"',
      [TimestampISO, CurrentMetrics.RequestId, CurrentMetrics.Endpoint, DurationMS, Rows,
       SQLHash, BoolToStr(Success, True), Sanitize(SQLText, 500),
       Sanitize(ErrorMessage, 300)]);
    AppendLog(Line);
  end;
end;

procedure PerformanceJSON(DurationMS: UInt64; Rows: Integer; Bytes: Integer);
begin
  if not CurrentMetrics.Active then
    Exit;

  Inc(CurrentMetrics.TempoJSONMS, DurationMS);
  if Bytes > CurrentMetrics.TamanhoRespostaBytes then
    CurrentMetrics.TamanhoRespostaBytes := Bytes;

  AppendLog(Format('[SERIALIZATION] timestamp=%s request_id=%s json_serialize_ms=%d records_processed=%d bytes=%d',
    [TimestampISO, CurrentMetrics.RequestId, DurationMS, Rows, Bytes]));
end;

procedure PerformanceStep(const StepName: string; DurationMS: Int64);
begin
  if not CurrentMetrics.Active then
    Exit;

  if SameText(StepName, 'db_connection') then
    Inc(CurrentMetrics.DBConnectionMS, DurationMS)
  else if SameText(StepName, 'response_write') then
    Inc(CurrentMetrics.ResponseMS, DurationMS)
  else
    Inc(CurrentMetrics.ProcessingMS, DurationMS);

  AppendLog(Format('[STEP] timestamp=%s request_id=%s endpoint=%s step=%s duration_ms=%d',
    [TimestampISO, CurrentMetrics.RequestId, CurrentMetrics.Endpoint,
     Sanitize(StepName, 100), DurationMS]));
end;

procedure PerformanceCacheStep(const CacheName, StepName: string;
  DurationMS: Int64);
begin
  if not CurrentMetrics.Active then
    Exit;

  Inc(CurrentMetrics.CacheMS, DurationMS);
  AppendLog(Format('[CACHE_STEP] timestamp=%s request_id=%s cache=%s step=%s duration_ms=%d thread_id=%d',
    [TimestampISO, CurrentMetrics.RequestId, Sanitize(CacheName, 100),
     Sanitize(StepName, 100), DurationMS, GetCurrentThreadId]));
end;

procedure PerformanceLockWait(const LockName: string; DurationMS: Int64);
begin
  if not CurrentMetrics.Active then
    Exit;

  Inc(CurrentMetrics.LockWaitMS, DurationMS);
  AppendLog(Format('[LOCK_WAIT] timestamp=%s request_id=%s lock=%s wait_ms=%d thread_id=%d',
    [TimestampISO, CurrentMetrics.RequestId, Sanitize(LockName, 100),
     DurationMS, GetCurrentThreadId]));
end;

procedure PerformanceLockHold(const LockName: string; DurationMS: Int64);
begin
  if not CurrentMetrics.Active then
    Exit;

  AppendLog(Format('[LOCK_HOLD] timestamp=%s request_id=%s lock=%s hold_ms=%d thread_id=%d',
    [TimestampISO, CurrentMetrics.RequestId, Sanitize(LockName, 100),
     DurationMS, GetCurrentThreadId]));
end;

procedure PerformanceDBConnection(const ConnectionName: string; CreateMS,
  OpenMS: UInt64; Reused: Boolean);
begin
  if not CurrentMetrics.Active then
    Exit;

  Inc(CurrentMetrics.DBConnectionMS, CreateMS + OpenMS);
  AppendLog(Format('[DB_CONNECTION] timestamp=%s request_id=%s connection=%s create_ms=%d open_ms=%d reused=%s',
    [TimestampISO, CurrentMetrics.RequestId, Sanitize(ConnectionName, 100),
     CreateMS, OpenMS, BoolToStr(Reused, True)]));
end;

procedure PerformanceStatusField(const FieldName: string; Bytes: Integer);
begin
  if not CurrentMetrics.Active then
    Exit;

  AppendLog(Format('[STATUS_FIELD] timestamp=%s request_id=%s field=%s bytes=%d',
    [TimestampISO, CurrentMetrics.RequestId, Sanitize(FieldName, 100), Bytes]));
end;

procedure PerformanceParamSlow(const Parametro: string; DurationMS: Int64);
begin
  if not CurrentMetrics.Active then
    Exit;

  AppendLog(Format('[PARAM_SLOW] request_id=%s parametro=%s duration_ms=%d',
    [CurrentMetrics.RequestId, Sanitize(Parametro, 150), DurationMS]));
end;

procedure PerformanceSyncMesas(Empresa: Integer; ClientVersion,
  ServerVersion: Int64; Changed: Boolean; VersionQueryMS, DataQueryMS,
  SerializeMS: Int64; Bytes: Integer; TotalMS: Int64);
begin
  if not CurrentMetrics.Active then
    Exit;

  AppendLog(Format('[SYNC_MESAS] request_id=%s empresa=%d client_version=%d server_version=%d changed=%s version_query_ms=%d data_query_ms=%d serialize_ms=%d bytes=%d total_ms=%d',
    [CurrentMetrics.RequestId, Empresa, ClientVersion, ServerVersion,
     BoolToStr(Changed, True), VersionQueryMS, DataQueryMS, SerializeMS,
     Bytes, TotalMS]));
end;

procedure PerformanceMetricsMiddleware(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  TempoTotal: UInt64;
  AccountedMS: UInt64;
  UnaccountedMS: Int64;
  ActiveNow: Int64;
  ResponseText: string;
  HeaderRequestId: string;
begin
  if not MetricsEnabled then
  begin
    Next;
    Exit;
  end;

  ClearCurrentMetrics;
  CurrentMetrics.Active := True;
  CurrentMetrics.AcceptedAt := GetTickCount64;
  CurrentMetrics.HandlerStartedAt := CurrentMetrics.AcceptedAt;
  CurrentMetrics.QueueMS := CurrentMetrics.HandlerStartedAt - CurrentMetrics.AcceptedAt;

  HeaderRequestId := Req.Headers['X-Request-ID'];
  if HeaderRequestId <> '' then
    CurrentMetrics.RequestId := Sanitize(HeaderRequestId, 100)
  else
    CurrentMetrics.RequestId := NextRequestId;

  CurrentMetrics.Metodo := Req.RawWebRequest.Method;
  CurrentMetrics.Endpoint := Req.RawWebRequest.RawPathInfo;
  CurrentMetrics.Inicio := CurrentMetrics.HandlerStartedAt;
  CurrentMetrics.ActiveStart := TInterlocked.Increment(RequestsActive);
  TInterlocked.Increment(RequestsTotal);
  if CurrentMetrics.ActiveStart > RequestsPeak then
    TInterlocked.Exchange(RequestsPeak, CurrentMetrics.ActiveStart);

  Res.RawWebResponse.SetCustomHeader('X-Request-ID', CurrentMetrics.RequestId);

  AppendLog(Format('[REQUEST_START] timestamp=%s request_id=%s method=%s endpoint=%s accepted_at=%d handler_started_at=%d queue_ms=%d thread_id=%d',
    [TimestampISO, CurrentMetrics.RequestId, CurrentMetrics.Metodo,
     Sanitize(CurrentMetrics.Endpoint, 500), CurrentMetrics.AcceptedAt,
     CurrentMetrics.HandlerStartedAt, CurrentMetrics.QueueMS, GetCurrentThreadId]));
  AppendLog(Format('[CONCURRENCY] timestamp=%s request_id=%s active=%d waiting=%d peak=%d total=%d thread_id=%d',
    [TimestampISO, CurrentMetrics.RequestId, CurrentMetrics.ActiveStart, 0,
     RequestsPeak, RequestsTotal, GetCurrentThreadId]));

  try
    try
      Next;
    except
      on E: Exception do
      begin
        CurrentMetrics.Erro := Sanitize(E.ClassName + ': ' + E.Message, 300);
        raise;
      end;
    end;
  finally
    TempoTotal := GetTickCount64 - CurrentMetrics.Inicio;
    ActiveNow := TInterlocked.Decrement(RequestsActive);
    CurrentMetrics.StatusHTTP := Res.Status;
    try
      ResponseText := Res.RawWebResponse.Content;
      CurrentMetrics.TamanhoRespostaBytes := Length(TEncoding.UTF8.GetBytes(ResponseText));
    except
    end;
    if (CurrentMetrics.StatusHTTP >= 500) and (CurrentMetrics.Erro = '') then
      CurrentMetrics.Erro := Sanitize(Res.RawWebResponse.Content, 300);

    CurrentMetrics.MiddlewareMS := 0;
    AccountedMS := CurrentMetrics.QueueMS + CurrentMetrics.MiddlewareMS +
      CurrentMetrics.CacheMS + CurrentMetrics.LockWaitMS +
      CurrentMetrics.DBConnectionMS + CurrentMetrics.TempoSQLMS +
      CurrentMetrics.ProcessingMS + CurrentMetrics.TempoJSONMS +
      CurrentMetrics.ResponseMS + CurrentMetrics.LoggerMS;
    UnaccountedMS := Int64(TempoTotal) - Int64(AccountedMS);
    if UnaccountedMS < 0 then
      UnaccountedMS := 0;

    if SameText(GetEnvironmentVariable('DEBUG_PERFORMANCE'), 'true') then
      Res.RawWebResponse.SetCustomHeader('Server-Timing',
        Format('queue;dur=%d, middleware;dur=%d, cache;dur=%d, lock;dur=%d, db;dur=%d, sql;dur=%d, app;dur=%d, json;dur=%d, logger;dur=%d',
          [CurrentMetrics.QueueMS, CurrentMetrics.MiddlewareMS,
           CurrentMetrics.CacheMS, CurrentMetrics.LockWaitMS,
           CurrentMetrics.DBConnectionMS, CurrentMetrics.TempoSQLMS,
           CurrentMetrics.ProcessingMS, CurrentMetrics.TempoJSONMS,
           CurrentMetrics.LoggerMS]));

    AppendLog(Format('[REQUEST_END] timestamp=%s request_id=%s method=%s endpoint=%s status=%d thread_id=%d active_start=%d active_peak=%d queue_ms=%d middleware_ms=%d cache_ms=%d lock_wait_ms=%d db_connection_ms=%d sql_ms=%d processing_ms=%d json_ms=%d response_write_ms=%d logger_ms=%d total_ms=%d unaccounted_ms=%d active_end=%d queries=%d rows=%d bytes=%d error="%s"',
      [TimestampISO, CurrentMetrics.RequestId, CurrentMetrics.Metodo,
       Sanitize(CurrentMetrics.Endpoint, 500), CurrentMetrics.StatusHTTP,
       GetCurrentThreadId, CurrentMetrics.ActiveStart, RequestsPeak,
       CurrentMetrics.QueueMS, CurrentMetrics.MiddlewareMS,
       CurrentMetrics.CacheMS, CurrentMetrics.LockWaitMS,
       CurrentMetrics.DBConnectionMS, CurrentMetrics.TempoSQLMS,
       CurrentMetrics.ProcessingMS, CurrentMetrics.TempoJSONMS,
       CurrentMetrics.ResponseMS, CurrentMetrics.LoggerMS, TempoTotal,
       UnaccountedMS, ActiveNow, CurrentMetrics.QuantidadeQueries,
       CurrentMetrics.QuantidadeLinhas,
       CurrentMetrics.TamanhoRespostaBytes, CurrentMetrics.Erro]));
    if UnaccountedMS > 30 then
      AppendLog(Format('[UNACCOUNTED_TIME] timestamp=%s request_id=%s duration_ms=%d',
        [TimestampISO, CurrentMetrics.RequestId, UnaccountedMS]));
    ClearCurrentMetrics;
  end;
end;

initialization
  LogInitLock := TCriticalSection.Create;

finalization
  if Assigned(LogThread) then
  begin
    LogThread.Terminate;
    if Assigned(LogQueue) then
      LogQueue.DoShutDown;
    LogThread.WaitFor;
    LogThread.Free;
  end;
  LogQueue.Free;
  LogInitLock.Free;

end.
