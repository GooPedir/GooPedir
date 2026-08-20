unit uStressTesterMain;

interface

procedure RunStressTester;

implementation

uses
  System.SysUtils, System.Classes, System.IniFiles, System.IOUtils, System.Math,
  System.JSON, System.Generics.Collections, System.Diagnostics,
  System.Net.HttpClient, System.SyncObjs, Horse;

type
  TRouteMetric = class
  public
    Route: string;
    Total: Int64;
    Success: Int64;
    Errors: Int64;
    MinMS: Int64;
    MaxMS: Int64;
    TotalMS: Int64;
    LastStatus: Integer;
    LastError: string;
    LastAt: TDateTime;
    constructor Create(const ARoute: string);
    function AvgMS: Double;
  end;

  TStressConfig = record
    TargetBaseURL: string;
    MonitorPort: Integer;
    RequestsPerRoute: Integer;
    BatchSize: Integer;
    TimeoutMS: Integer;
    PauseBetweenBatchesMS: Integer;
    RepeatForever: Boolean;
    AutoStart: Boolean;
  end;

  TStressRunner = class(TThread)
  private
    FConfig: TStressConfig;
    FRoutes: TArray<string>;
    FStopRequested: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const AConfig: TStressConfig; const ARoutes: TArray<string>);
    procedure ExecuteOne(const ARoute: string);
    procedure RequestStop;
  end;

  TRequestWorker = class(TThread)
  private
    FRunner: TStressRunner;
    FRoute: string;
  protected
    procedure Execute; override;
  public
    constructor Create(ARunner: TStressRunner; const ARoute: string);
  end;

var
  GConfig: TStressConfig;
  GRoutes: TArray<string>;
  GMetrics: TObjectDictionary<string, TRouteMetric>;
  GLock: TCriticalSection;
  GRunner: TStressRunner;
  GStartedAt: TDateTime;

function RemoveTrailingSlash(const S: string): string; forward;

constructor TRouteMetric.Create(const ARoute: string);
begin
  inherited Create;
  Route := ARoute;
  MinMS := MaxInt;
end;

function TRouteMetric.AvgMS: Double;
begin
  if Total = 0 then
    Result := 0
  else
    Result := TotalMS / Total;
end;

constructor TStressRunner.Create(const AConfig: TStressConfig;
  const ARoutes: TArray<string>);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FConfig := AConfig;
  FRoutes := ARoutes;
end;

procedure TStressRunner.RequestStop;
begin
  FStopRequested := True;
end;

constructor TRequestWorker.Create(ARunner: TStressRunner; const ARoute: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FRunner := ARunner;
  FRoute := ARoute;
end;

procedure TRequestWorker.Execute;
begin
  FRunner.ExecuteOne(FRoute);
end;

procedure TStressRunner.ExecuteOne(const ARoute: string);
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  SW: TStopwatch;
  URL: string;
  Status: Integer;
  Err: string;
  MS: Int64;
  Metric: TRouteMetric;
begin
  Status := 0;
  Err := '';
  URL := RemoveTrailingSlash(FConfig.TargetBaseURL) + ARoute;
  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := FConfig.TimeoutMS;
    Client.ResponseTimeout := FConfig.TimeoutMS;
    SW := TStopwatch.StartNew;
    try
      Response := Client.Get(URL);
      Status := Response.StatusCode;
    except
      on E: Exception do
        Err := E.ClassName + ': ' + E.Message;
    end;
    SW.Stop;
    MS := SW.ElapsedMilliseconds;
  finally
    Client.Free;
  end;

  GLock.Enter;
  try
    Metric := GMetrics.Items[ARoute];
    Inc(Metric.Total);
    Metric.LastStatus := Status;
    Metric.LastError := Err;
    Metric.LastAt := Now;
    Inc(Metric.TotalMS, MS);
    if MS < Metric.MinMS then
      Metric.MinMS := MS;
    if MS > Metric.MaxMS then
      Metric.MaxMS := MS;
    if (Err = '') and (Status >= 200) and (Status < 500) then
      Inc(Metric.Success)
    else
      Inc(Metric.Errors);
  finally
    GLock.Leave;
  end;
end;

procedure TStressRunner.Execute;
var
  Route: string;
  I: Integer;
  Sent: Integer;
  Workers: TObjectList<TRequestWorker>;
  Worker: TRequestWorker;
begin
  repeat
    for Route in FRoutes do
    begin
      Sent := 0;
      while (not FStopRequested) and (Sent < FConfig.RequestsPerRoute) do
      begin
        Workers := TObjectList<TRequestWorker>.Create;
        try
          for I := 1 to FConfig.BatchSize do
          begin
            if FStopRequested or (Sent >= FConfig.RequestsPerRoute) then
              Break;
            Worker := TRequestWorker.Create(Self, Route);
            Workers.Add(Worker);
            Worker.Start;
            Inc(Sent);
          end;
          for Worker in Workers do
            Worker.WaitFor;
        finally
          Workers.Free;
        end;
        Sleep(FConfig.PauseBetweenBatchesMS);
      end;
      if FStopRequested then
        Break;
    end;
  until FStopRequested or (not FConfig.RepeatForever);
end;

function AppPath(const FileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), FileName);
end;

function RemoveTrailingSlash(const S: string): string;
begin
  Result := S;
  while (Result <> '') and CharInSet(Result[Length(Result)], ['/', '\']) do
    Delete(Result, Length(Result), 1);
end;

function RouteFilePath: string;
begin
  Result := AppPath('routes-get-sem-parametro.txt');
  if FileExists(Result) then
    Exit;
  Result := TPath.Combine(GetCurrentDir, 'routes-get-sem-parametro.txt');
  if FileExists(Result) then
    Exit;
  Result := TPath.Combine(GetCurrentDir,
    'stress-tester\routes-get-sem-parametro.txt');
  if FileExists(Result) then
    Exit;
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)),
    'stress-tester\routes-get-sem-parametro.txt');
end;

function LoadConfig: TStressConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AppPath('stress-tester.ini'));
  try
    Result.TargetBaseURL := Ini.ReadString('stress', 'target_base_url',
      'http://localhost:2121');
    Result.MonitorPort := Ini.ReadInteger('stress', 'monitor_port', 2130);
    Result.RequestsPerRoute := Ini.ReadInteger('stress', 'requests_per_route',
      1000);
    Result.BatchSize := Ini.ReadInteger('stress', 'batch_size', 10);
    Result.TimeoutMS := Ini.ReadInteger('stress', 'timeout_ms', 10000);
    Result.PauseBetweenBatchesMS := Ini.ReadInteger('stress',
      'pause_between_batches_ms', 0);
    Result.RepeatForever := Ini.ReadBool('stress', 'repeat_forever', True);
    Result.AutoStart := Ini.ReadBool('stress', 'autostart', True);

    Ini.WriteString('stress', 'target_base_url', Result.TargetBaseURL);
    Ini.WriteInteger('stress', 'monitor_port', Result.MonitorPort);
    Ini.WriteInteger('stress', 'requests_per_route', Result.RequestsPerRoute);
    Ini.WriteInteger('stress', 'batch_size', Result.BatchSize);
    Ini.WriteInteger('stress', 'timeout_ms', Result.TimeoutMS);
    Ini.WriteInteger('stress', 'pause_between_batches_ms',
      Result.PauseBetweenBatchesMS);
    Ini.WriteBool('stress', 'repeat_forever', Result.RepeatForever);
    Ini.WriteBool('stress', 'autostart', Result.AutoStart);
  finally
    Ini.Free;
  end;
end;

function LoadRoutes: TArray<string>;
var
  Lines: TStringList;
  OutRoutes: TList<string>;
  Line: string;
  I: Integer;
begin
  Lines := TStringList.Create;
  OutRoutes := TList<string>.Create;
  try
    Lines.LoadFromFile(RouteFilePath);
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      Line := Trim(Line);
      if (Line = '') or Line.StartsWith('#') then
        Continue;
      if not Line.StartsWith('/') then
        Line := '/' + Line;
      if not OutRoutes.Contains(Line) then
        OutRoutes.Add(Line);
    end;
    Result := OutRoutes.ToArray;
  finally
    OutRoutes.Free;
    Lines.Free;
  end;
end;

procedure StartRunner;
begin
  if Assigned(GRunner) and (not GRunner.Finished) then
    Exit;
  GRunner := TStressRunner.Create(GConfig, GRoutes);
end;

procedure StopRunner;
begin
  if Assigned(GRunner) then
    GRunner.RequestStop;
end;

function MetricsJSON: TJSONObject;
var
  Arr: TJSONArray;
  Metric: TRouteMetric;
  Obj: TJSONObject;
  Running: Boolean;
begin
  Result := TJSONObject.Create;
  Arr := TJSONArray.Create;
  Running := Assigned(GRunner) and (not GRunner.Finished);
  Result.AddPair('running', TJSONBool.Create(Running));
  Result.AddPair('target', GConfig.TargetBaseURL);
  Result.AddPair('startedAt', DateTimeToStr(GStartedAt));
  Result.AddPair('routes', TJSONNumber.Create(Length(GRoutes)));
  GLock.Enter;
  try
    for Metric in GMetrics.Values do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('route', Metric.Route);
      Obj.AddPair('total', TJSONNumber.Create(Metric.Total));
      Obj.AddPair('success', TJSONNumber.Create(Metric.Success));
      Obj.AddPair('errors', TJSONNumber.Create(Metric.Errors));
      Obj.AddPair('successRate', TJSONNumber.Create(Metric.Success * 100.0 /
        Max(1, Metric.Total)));
      if Metric.MinMS = MaxInt then
        Obj.AddPair('minMS', TJSONNumber.Create(0))
      else
        Obj.AddPair('minMS', TJSONNumber.Create(Metric.MinMS));
      Obj.AddPair('avgMS', TJSONNumber.Create(Metric.AvgMS));
      Obj.AddPair('maxMS', TJSONNumber.Create(Metric.MaxMS));
      Obj.AddPair('lastStatus', TJSONNumber.Create(Metric.LastStatus));
      Obj.AddPair('lastError', Metric.LastError);
      Arr.AddElement(Obj);
    end;
  finally
    GLock.Leave;
  end;
  Result.AddPair('items', Arr);
end;

function HtmlPage: string;
begin
  Result :=
    '<!doctype html><html><head><meta charset="utf-8"><title>GooPedir Stress</title>' +
    '<style>body{font-family:Segoe UI,Arial;margin:20px;background:#f6f7f9;color:#1f2937}' +
    'table{border-collapse:collapse;width:100%;background:white}td,th{padding:7px;border-bottom:1px solid #e5e7eb;text-align:left}' +
    'th{background:#111827;color:white;position:sticky;top:0}.ok{color:#047857}.bad{color:#b91c1c}' +
    '.bar{display:flex;gap:8px;margin-bottom:12px}button{padding:8px 12px}</style></head><body>' +
    '<h2>GooPedir Stress Tester</h2><div class="bar"><button onclick="fetch(''/start'')">Start</button>' +
    '<button onclick="fetch(''/stop'')">Stop</button><button onclick="fetch(''/reset'')">Reset</button></div>' +
    '<div id="summary"></div><table><thead><tr><th>Rota</th><th>Total</th><th>Sucesso</th><th>Erro</th><th>%</th><th>Min</th><th>Media</th><th>Max</th><th>Status</th><th>Ultimo erro</th></tr></thead><tbody id="rows"></tbody></table>' +
    '<script>async function load(){const d=await (await fetch("/status")).json();' +
    'summary.innerHTML=`Rodando: <b>${d.running}</b> | Target: <b>${d.target}</b> | Rotas: <b>${d.routes}</b>`;' +
    'rows.innerHTML=d.items.map(x=>`<tr><td>${x.route}</td><td>${x.total}</td>' +
    '<td class="ok">${x.success}</td><td class="bad">${x.errors}</td>' +
    '<td>${x.successRate.toFixed(2)}</td><td>${x.minMS}</td><td>${x.avgMS.toFixed(1)}</td>' +
    '<td>${x.maxMS}</td><td>${x.lastStatus}</td><td>${x.lastError||""}</td></tr>`).join("")}' +
    'setInterval(load,1000);load()</script></body></html>';
end;

procedure ResetMetrics;
var
  Route: string;
begin
  GLock.Enter;
  try
    GMetrics.Clear;
    for Route in GRoutes do
      GMetrics.Add(Route, TRouteMetric.Create(Route));
  finally
    GLock.Leave;
  end;
end;

procedure DoGetHome(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.ContentType('text/html; charset=utf-8').Send(HtmlPage);
end;

procedure DoGetStatus(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.Send<TJSONObject>(MetricsJSON);
end;

procedure DoGetStart(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  StartRunner;
  Res.Send('started');
end;

procedure DoGetStop(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  StopRunner;
  Res.Send('stopping');
end;

procedure DoGetReset(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  StopRunner;
  ResetMetrics;
  Res.Send('reset');
end;

procedure RegisterRoutes;
begin
  THorse.Get('/', DoGetHome);
  THorse.Get('/status', DoGetStatus);
  THorse.Get('/start', DoGetStart);
  THorse.Get('/stop', DoGetStop);
  THorse.Get('/reset', DoGetReset);
end;

procedure RunStressTester;
begin
  GLock := TCriticalSection.Create;
  GMetrics := TObjectDictionary<string, TRouteMetric>.Create([doOwnsValues]);
  try
    GStartedAt := Now;
    GConfig := LoadConfig;
    GRoutes := LoadRoutes;
    ResetMetrics;
    RegisterRoutes;
    if GConfig.AutoStart then
      StartRunner;
    Writeln('Stress tester monitor: http://localhost:' +
      GConfig.MonitorPort.ToString);
    Writeln('Target: ' + GConfig.TargetBaseURL);
    Writeln('Rotas carregadas: ' + Length(GRoutes).ToString);
    THorse.Listen(GConfig.MonitorPort);
  finally
    StopRunner;
    GMetrics.Free;
    GLock.Free;
  end;
end;

end.
