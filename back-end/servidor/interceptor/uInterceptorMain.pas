unit uInterceptorMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.Winsock, System.SysUtils,
  System.Classes, System.IniFiles, System.JSON, System.IOUtils, System.DateUtils,
  System.Generics.Collections, System.Diagnostics, System.Net.URLClient,
  System.Net.HttpClient, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Menus, Horse;

type
  TBackendInstance = class
  public
    Port: Integer;
    ProcessId: Cardinal;
    Failures: Integer;
    Errors500: Integer;
    SlowRequests: Integer;
    Requests: Int64;
    Healthy: Boolean;
    LastError: string;
    LastLatencyMS: Int64;
    RestartingUntil: TDateTime;
    Restarting: Boolean;
    LastRestartAt: TDateTime;
    constructor Create(APort: Integer);
  end;

  TInterceptorConfig = record
    Configured: Boolean;
    AutoStart: Boolean;
    PublicPort: Integer;
    InstanceCount: Integer;
    StartPort: Integer;
    EndPort: Integer;
    MaxErrors: Integer;
    TimeoutMS: Integer;
    SlowMS: Integer;
    ServerExe: string;
  end;

  TfrmInterceptor = class(TForm)
    lblStatus: TLabel;
    lblStats: TLabel;
    grpConfig: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    edtPublicPort: TEdit;
    edtInstances: TEdit;
    edtMaxErrors: TEdit;
    edtStartPort: TEdit;
    edtEndPort: TEdit;
    edtTimeout: TEdit;
    chkAutoStart: TCheckBox;
    btnSave: TButton;
    btnStart: TButton;
    btnStop: TButton;
    memInstances: TMemo;
    memLog: TMemo;
    TrayIcon1: TTrayIcon;
    tHealth: TTimer;
    PopupMenuTray: TPopupMenu;
    mAbrirInterceptor: TMenuItem;
    mOcultarInterceptor: TMenuItem;
    mFecharInterceptor: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSaveClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure tHealthTimer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure mAbrirInterceptorClick(Sender: TObject);
    procedure mOcultarInterceptorClick(Sender: TObject);
    procedure mFecharInterceptorClick(Sender: TObject);
  private
    FConfig: TInterceptorConfig;
    FInstances: TObjectList<TBackendInstance>;
    FNextIndex: Integer;
    FRunning: Boolean;
    FTotalRequests: Int64;
    FTotalErrors: Int64;
    FTotalSlow: Int64;
    FCritical: TRTLCriticalSection;
    FLogCritical: TRTLCriticalSection;
    function ConfigFile: string;
    function LogDir: string;
    function DefaultServerExe: string;
    function LoadConfig: Boolean;
    procedure SaveConfig;
    procedure ConfigToScreen;
    procedure ScreenToConfig;
    procedure StartInterceptor;
    procedure StopInstances;
    procedure StartInstances;
    procedure StartBackend(Instance: TBackendInstance);
    procedure RestartBackend(Instance: TBackendInstance; const Reason: string);
    procedure StopBackend(Instance: TBackendInstance);
    function IsProcessRunning(ProcessId: Cardinal): Boolean;
    function IsPortAvailable(Port: Integer): Boolean;
    function IsPortManaged(Port: Integer): Boolean;
    function BackendSocketIOPort(Port: Integer): Integer;
    function IsBackendPortAvailable(Port: Integer): Boolean;
    function NextAvailablePort(var Port: Integer): Boolean;
    function BackendBaseURL(Instance: TBackendInstance): string;
    function RequestQuery(Req: THorseRequest): string;
    function ResponseHeaderValue(const Headers: TNetHeaders;
      const Name: string): string;
    function SelectBackend: TBackendInstance; overload;
    function SelectBackend(ATried: TList<TBackendInstance>): TBackendInstance; overload;
    function MaxManagedInstances: Integer;
    function RunningInstanceCount: Integer;
    procedure EnsureSpareCapacity(const Reason: string);
    function CheckBackend(Instance: TBackendInstance; out Detail: string): Boolean;
    procedure RegisterFailure(Instance: TBackendInstance; const Detail: string);
    procedure RegisterSuccess(Instance: TBackendInstance);
    procedure ProxyRequest(Req: THorseRequest; Res: THorseResponse);
    procedure RegisterRoutes;
    procedure Log(const Kind, Msg: string);
    procedure RefreshUI;
    procedure HideIfConfigured;
    procedure ShowInterceptor;
  public
    destructor Destroy; override;
  end;

var
  frmInterceptor: TfrmInterceptor;

implementation

{$R *.dfm}

procedure InterceptorStatusHandler(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('ok', True);
  Obj.AddPair('requests', TJSONNumber.Create(frmInterceptor.FTotalRequests));
  Obj.AddPair('errors', TJSONNumber.Create(frmInterceptor.FTotalErrors));
  Obj.AddPair('slow', TJSONNumber.Create(frmInterceptor.FTotalSlow));
  Obj.AddPair('instances', TJSONNumber.Create(frmInterceptor.FInstances.Count));
  Res.Send<TJSONObject>(Obj);
end;

procedure ProxyMiddlewareHandler(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
begin
  if Pos('/interceptor/', LowerCase(Req.RawWebRequest.RawPathInfo)) = 1 then
    Next
  else
  begin
    frmInterceptor.ProxyRequest(Req, Res);
    raise EHorseCallbackInterrupted.Create;
  end;
end;

constructor TBackendInstance.Create(APort: Integer);
begin
  inherited Create;
  Port := APort;
  Healthy := False;
  ProcessId := 0;
end;

function TfrmInterceptor.ConfigFile: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'interceptor.ini');
end;

function TfrmInterceptor.LogDir: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs');
  TDirectory.CreateDirectory(Result);
end;

function TfrmInterceptor.DefaultServerExe: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'ServidorGooPedir.exe');
end;

function TfrmInterceptor.LoadConfig: Boolean;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ConfigFile);
  try
    FConfig.Configured := Ini.ReadBool('interceptor', 'configured', False);
    FConfig.AutoStart := Ini.ReadBool('interceptor', 'autostart', True);
    FConfig.PublicPort := Ini.ReadInteger('interceptor', 'public_port', 2121);
    FConfig.InstanceCount := Ini.ReadInteger('interceptor', 'instances', 2);
    FConfig.StartPort := Ini.ReadInteger('interceptor', 'start_port', 2122);
    FConfig.EndPort := Ini.ReadInteger('interceptor', 'end_port', 2125);
    FConfig.MaxErrors := Ini.ReadInteger('interceptor', 'max_errors', 5);
    FConfig.TimeoutMS := Ini.ReadInteger('interceptor', 'timeout_ms', 5000);
    FConfig.SlowMS := Ini.ReadInteger('interceptor', 'slow_ms', 3000);
    FConfig.ServerExe := Ini.ReadString('interceptor', 'server_exe',
      DefaultServerExe);
    Result := FConfig.Configured;
  finally
    Ini.Free;
  end;
end;

procedure TfrmInterceptor.SaveConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ConfigFile);
  try
    Ini.WriteBool('interceptor', 'configured', True);
    Ini.WriteBool('interceptor', 'autostart', FConfig.AutoStart);
    Ini.WriteInteger('interceptor', 'public_port', FConfig.PublicPort);
    Ini.WriteInteger('interceptor', 'instances', FConfig.InstanceCount);
    Ini.WriteInteger('interceptor', 'start_port', FConfig.StartPort);
    Ini.WriteInteger('interceptor', 'end_port', FConfig.EndPort);
    Ini.WriteInteger('interceptor', 'max_errors', FConfig.MaxErrors);
    Ini.WriteInteger('interceptor', 'timeout_ms', FConfig.TimeoutMS);
    Ini.WriteInteger('interceptor', 'slow_ms', FConfig.SlowMS);
    Ini.WriteString('interceptor', 'server_exe', FConfig.ServerExe);
  finally
    Ini.Free;
  end;
end;

procedure TfrmInterceptor.ConfigToScreen;
begin
  edtPublicPort.Text := FConfig.PublicPort.ToString;
  edtInstances.Text := FConfig.InstanceCount.ToString;
  edtMaxErrors.Text := FConfig.MaxErrors.ToString;
  edtStartPort.Text := FConfig.StartPort.ToString;
  edtEndPort.Text := FConfig.EndPort.ToString;
  edtTimeout.Text := FConfig.TimeoutMS.ToString;
  chkAutoStart.Checked := FConfig.AutoStart;
end;

procedure TfrmInterceptor.ScreenToConfig;
begin
  FConfig.PublicPort := StrToIntDef(edtPublicPort.Text, 2121);
  FConfig.InstanceCount := StrToIntDef(edtInstances.Text, 2);
  FConfig.MaxErrors := StrToIntDef(edtMaxErrors.Text, 5);
  FConfig.StartPort := StrToIntDef(edtStartPort.Text, 2122);
  FConfig.EndPort := StrToIntDef(edtEndPort.Text, 2125);
  FConfig.TimeoutMS := StrToIntDef(edtTimeout.Text, 5000);
  FConfig.SlowMS := 3000;
  FConfig.AutoStart := chkAutoStart.Checked;
  FConfig.ServerExe := DefaultServerExe;
  if FConfig.InstanceCount < 1 then
    FConfig.InstanceCount := 1;
  if FConfig.EndPort < FConfig.StartPort then
    FConfig.EndPort := FConfig.StartPort;
end;

procedure TfrmInterceptor.FormCreate(Sender: TObject);
var
  IconPath: string;
begin
  InitializeCriticalSection(FCritical);
  InitializeCriticalSection(FLogCritical);
  IconPath := TPath.Combine(ExtractFilePath(ParamStr(0)),
    'ServidorGooPedir_Icon.ico');
  if not FileExists(IconPath) then
    IconPath := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'servidor_Icon1.ico');
  if FileExists(IconPath) then
  begin
    Application.Icon.LoadFromFile(IconPath);
    TrayIcon1.Icon.Assign(Application.Icon);
  end;
  TrayIcon1.Visible := True;
  FInstances := TObjectList<TBackendInstance>.Create(True);
  LoadConfig;
  ConfigToScreen;
  RegisterRoutes;
  if FConfig.Configured and FConfig.AutoStart then
  begin
    StartInterceptor;
    HideIfConfigured;
  end
  else
    lblStatus.Caption := 'Configure o Interceptor';
end;

destructor TfrmInterceptor.Destroy;
begin
  StopInstances;
  FInstances.Free;
  DeleteCriticalSection(FLogCritical);
  DeleteCriticalSection(FCritical);
  inherited;
end;

procedure TfrmInterceptor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FRunning then
  begin
    Action := caNone;
    Hide;
  end;
end;

procedure TfrmInterceptor.HideIfConfigured;
begin
  if FConfig.Configured then
  begin
    WindowState := wsMinimized;
    Hide;
  end;
end;

procedure TfrmInterceptor.ShowInterceptor;
begin
  Show;
  WindowState := wsNormal;
  Application.BringToFront;
  BringToFront;
end;

procedure TfrmInterceptor.mAbrirInterceptorClick(Sender: TObject);
begin
  ShowInterceptor;
end;

procedure TfrmInterceptor.mOcultarInterceptorClick(Sender: TObject);
begin
  Hide;
end;

procedure TfrmInterceptor.mFecharInterceptorClick(Sender: TObject);
begin
  FRunning := False;
  Close;
end;

procedure TfrmInterceptor.btnSaveClick(Sender: TObject);
begin
  ScreenToConfig;
  FConfig.Configured := True;
  SaveConfig;
  Log('info', 'Configuracao salva');
end;

procedure TfrmInterceptor.btnStartClick(Sender: TObject);
begin
  ScreenToConfig;
  FConfig.Configured := True;
  SaveConfig;
  StartInterceptor;
end;

procedure TfrmInterceptor.btnStopClick(Sender: TObject);
begin
  StopInstances;
  FRunning := False;
  tHealth.Enabled := False;
  lblStatus.Caption := 'Parado';
end;

procedure TfrmInterceptor.StartInterceptor;
begin
  if FRunning then
    Exit;

  if not FileExists(FConfig.ServerExe) then
  begin
    Log('erro', 'Servidor nao encontrado: ' + FConfig.ServerExe);
    Exit;
  end;

  try
    THorse.Listen(FConfig.PublicPort);
  except
    on E: Exception do
    begin
      Log('erro', 'Falha ao abrir porta publica ' + FConfig.PublicPort.ToString
        + ': ' + E.Message);
      Exit;
    end;
  end;
  StartInstances;
  FRunning := True;
  tHealth.Interval := 5000;
  tHealth.Enabled := True;
  lblStatus.Caption := 'Rodando na porta ' + FConfig.PublicPort.ToString;
  Log('info', 'Interceptor iniciado na porta ' + FConfig.PublicPort.ToString);
end;

procedure TfrmInterceptor.StartInstances;
var
  I: Integer;
  Port: Integer;
  Instance: TBackendInstance;
begin
  FInstances.Clear;
  Port := FConfig.StartPort;
  for I := 1 to FConfig.InstanceCount do
  begin
    if not NextAvailablePort(Port) then
    begin
      Log('erro', 'Sem porta disponivel no range configurado');
      Break;
    end;
    Instance := TBackendInstance.Create(Port);
    FInstances.Add(Instance);
    StartBackend(Instance);
    Inc(Port);
  end;
  RefreshUI;
end;

procedure TfrmInterceptor.StopInstances;
var
  Instance: TBackendInstance;
begin
  for Instance in FInstances do
    StopBackend(Instance);
end;

procedure TfrmInterceptor.StartBackend(Instance: TBackendInstance);
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  Cmd: string;
begin
  FillChar(SI, SizeOf(SI), 0);
  FillChar(PI, SizeOf(PI), 0);
  SI.cb := SizeOf(SI);
  Cmd := '"' + FConfig.ServerExe + '" --port=' + Instance.Port.ToString;

  if CreateProcess(PChar(FConfig.ServerExe), PChar(Cmd), nil, nil, False,
    CREATE_NEW_PROCESS_GROUP, nil, PChar(ExtractFilePath(FConfig.ServerExe)), SI,
    PI) then
  begin
    Instance.ProcessId := PI.dwProcessId;
    Instance.RestartingUntil := IncSecond(Now, 20);
    CloseHandle(PI.hThread);
    CloseHandle(PI.hProcess);
    Log('info', Format('Instancia porta %d iniciada pid=%d',
      [Instance.Port, Instance.ProcessId]));
  end
  else
    Log('erro', Format('Falha ao iniciar porta %d erro=%d',
      [Instance.Port, GetLastError]));
end;

procedure TfrmInterceptor.StopBackend(Instance: TBackendInstance);
var
  Handle: THandle;
begin
  if Instance.ProcessId = 0 then
    Exit;
  Handle := OpenProcess(PROCESS_TERMINATE, False, Instance.ProcessId);
  if Handle <> 0 then
  begin
    TerminateProcess(Handle, 0);
    CloseHandle(Handle);
    Log('info', 'Instancia finalizada porta ' + Instance.Port.ToString);
  end;
  Instance.ProcessId := 0;
  Instance.Healthy := False;
end;

procedure TfrmInterceptor.RestartBackend(Instance: TBackendInstance;
  const Reason: string);
begin
  EnterCriticalSection(FCritical);
  try
    if Instance.Restarting then
      Exit;
    if SecondsBetween(Now, Instance.LastRestartAt) < 10 then
      Exit;
    Instance.Restarting := True;
    Instance.LastRestartAt := Now;
  finally
    LeaveCriticalSection(FCritical);
  end;

  try
    Log('erro', Format('Reiniciando porta %d motivo=%s',
      [Instance.Port, Reason]));
    StopBackend(Instance);
    Sleep(1000);
    Instance.Failures := 0;
    Instance.Errors500 := 0;
    Instance.LastError := '';
    StartBackend(Instance);
  finally
    Instance.Restarting := False;
  end;
end;

function TfrmInterceptor.IsProcessRunning(ProcessId: Cardinal): Boolean;
var
  Handle: THandle;
  Code: Cardinal;
begin
  Result := False;
  if ProcessId = 0 then
    Exit;
  Handle := OpenProcess(PROCESS_QUERY_INFORMATION, False, ProcessId);
  if Handle = 0 then
    Exit;
  try
    if GetExitCodeProcess(Handle, Code) then
      Result := Code = STILL_ACTIVE;
  finally
    CloseHandle(Handle);
  end;
end;

function TfrmInterceptor.IsPortAvailable(Port: Integer): Boolean;
var
  Wsa: TWSAData;
  Sock: TSocket;
  Addr: TSockAddrIn;
begin
  Result := False;
  if WSAStartup($0202, Wsa) <> 0 then
    Exit;
  try
    Sock := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if Sock = INVALID_SOCKET then
      Exit;
    try
      FillChar(Addr, SizeOf(Addr), 0);
      Addr.sin_family := AF_INET;
      Addr.sin_addr.S_addr := INADDR_ANY;
      Addr.sin_port := htons(Port);
      Result := bind(Sock, Addr, SizeOf(Addr)) = 0;
    finally
      closesocket(Sock);
    end;
  finally
    WSACleanup;
  end;
end;

function TfrmInterceptor.IsPortManaged(Port: Integer): Boolean;
var
  Instance: TBackendInstance;
begin
  Result := False;
  for Instance in FInstances do
  begin
    if Instance.Port = Port then
      Exit(True);
  end;
end;

function TfrmInterceptor.BackendSocketIOPort(Port: Integer): Integer;
begin
  Result := Port + 8000;
  if Result > 65535 then
    Result := Port + 1;
end;

function TfrmInterceptor.IsBackendPortAvailable(Port: Integer): Boolean;
begin
  Result := (Port <> FConfig.PublicPort) and (not IsPortManaged(Port)) and
    IsPortAvailable(Port) and IsPortAvailable(BackendSocketIOPort(Port));
end;

function TfrmInterceptor.NextAvailablePort(var Port: Integer): Boolean;
begin
  while Port <= FConfig.EndPort do
  begin
    if IsBackendPortAvailable(Port) then
      Exit(True);
    Inc(Port);
  end;
  Result := False;
end;

function TfrmInterceptor.BackendBaseURL(Instance: TBackendInstance): string;
begin
  Result := 'http://127.0.0.1:' + Instance.Port.ToString;
end;

function TfrmInterceptor.RequestQuery(Req: THorseRequest): string;
begin
  Result := Req.RawWebRequest.Query;
end;

function TfrmInterceptor.ResponseHeaderValue(const Headers: TNetHeaders;
  const Name: string): string;
var
  Header: TNetHeader;
begin
  Result := '';
  for Header in Headers do
  begin
    if SameText(Header.Name, Name) then
      Exit(Header.Value);
  end;
end;

function TfrmInterceptor.SelectBackend: TBackendInstance;
begin
  Result := SelectBackend(nil);
end;

function TfrmInterceptor.SelectBackend(ATried: TList<TBackendInstance>)
  : TBackendInstance;
var
  I: Integer;
  Index: Integer;
begin
  Result := nil;
  EnterCriticalSection(FCritical);
  try
    if FInstances.Count = 0 then
      Exit;
    for I := 0 to FInstances.Count - 1 do
    begin
      Index := (FNextIndex + I) mod FInstances.Count;
      if FInstances[Index].Healthy and
        ((ATried = nil) or not ATried.Contains(FInstances[Index])) then
      begin
        FNextIndex := (Index + 1) mod FInstances.Count;
        Exit(FInstances[Index]);
      end;
    end;
    for I := 0 to FInstances.Count - 1 do
    begin
      Index := (FNextIndex + I) mod FInstances.Count;
      if ((ATried = nil) or not ATried.Contains(FInstances[Index])) and
        IsProcessRunning(FInstances[Index].ProcessId) then
      begin
        FNextIndex := (Index + 1) mod FInstances.Count;
        Exit(FInstances[Index]);
      end;
    end;
  finally
    LeaveCriticalSection(FCritical);
  end;
end;

function TfrmInterceptor.MaxManagedInstances: Integer;
begin
  Result := FConfig.InstanceCount + ((FConfig.InstanceCount + 1) div 2);
end;

function TfrmInterceptor.RunningInstanceCount: Integer;
var
  Instance: TBackendInstance;
begin
  Result := 0;
  for Instance in FInstances do
    if Instance.Healthy and IsProcessRunning(Instance.ProcessId) then
      Inc(Result);
end;

procedure TfrmInterceptor.EnsureSpareCapacity(const Reason: string);
var
  Port: Integer;
  Instance: TBackendInstance;
begin
  EnterCriticalSection(FCritical);
  try
    if FInstances.Count >= MaxManagedInstances then
      Exit;
    if RunningInstanceCount >= FConfig.InstanceCount then
      Exit;

    Port := FConfig.StartPort;
    while Port <= FConfig.EndPort do
    begin
      if IsBackendPortAvailable(Port) then
      begin
        Instance := TBackendInstance.Create(Port);
        FInstances.Add(Instance);
        Log('info', Format('Abrindo instancia reserva porta=%d motivo=%s',
          [Port, Reason]));
        StartBackend(Instance);
        Exit;
      end;
      Inc(Port);
    end;
    Log('erro', 'Sem porta disponivel para instancia reserva: ' + Reason);
  finally
    LeaveCriticalSection(FCritical);
  end;
end;

function TfrmInterceptor.CheckBackend(Instance: TBackendInstance;
  out Detail: string): Boolean;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  SW: TStopwatch;
  Json: TJSONValue;
  OkValue: Boolean;
begin
  Result := False;
  Detail := '';
  if not IsProcessRunning(Instance.ProcessId) then
  begin
    Detail := 'processo nao esta rodando';
    Exit;
  end;
  if Now < Instance.RestartingUntil then
    Exit(True);

  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := FConfig.TimeoutMS;
    Client.ResponseTimeout := FConfig.TimeoutMS;
    SW := TStopwatch.StartNew;
    Response := Client.Get(BackendBaseURL(Instance) + '/v2/health');
    SW.Stop;
    Instance.LastLatencyMS := SW.ElapsedMilliseconds;
    if SW.ElapsedMilliseconds >= FConfig.SlowMS then
    begin
      Detail := 'health lento ' + SW.ElapsedMilliseconds.ToString + 'ms';
      Exit;
    end;
    if Response.StatusCode >= 500 then
    begin
      Detail := 'health retornou ' + Response.StatusCode.ToString;
      Exit;
    end;
    Json := TJSONObject.ParseJSONValue(Response.ContentAsString);
    try
      if Assigned(Json) and (Json is TJSONObject) then
      begin
        OkValue := False;
        TJSONObject(Json).TryGetValue<Boolean>('ok', OkValue);
        Result := OkValue;
      end
      else
        Detail := 'health nao retornou json';
    finally
      Json.Free;
    end;
  except
    on E: Exception do
      Detail := E.ClassName + ': ' + E.Message;
  end;
  Client.Free;
end;

procedure TfrmInterceptor.RegisterFailure(Instance: TBackendInstance;
  const Detail: string);
var
  ShouldRestart: Boolean;
begin
  EnterCriticalSection(FCritical);
  try
    Inc(Instance.Failures);
    Instance.Healthy := False;
    Instance.LastError := Detail;
    Inc(FTotalErrors);
    ShouldRestart := (Instance.Failures >= FConfig.MaxErrors) and
      (Pos('proxy recebeu HTTP 500', Detail) = 0) and
      (Pos('proxy recebeu HTTP 5', Detail) = 0);
  finally
    LeaveCriticalSection(FCritical);
  end;

  Log('erro', Format('porta=%d falha=%d detalhe=%s',
    [Instance.Port, Instance.Failures, Detail]));
  if ShouldRestart then
    RestartBackend(Instance, Detail);
end;

procedure TfrmInterceptor.RegisterSuccess(Instance: TBackendInstance);
begin
  EnterCriticalSection(FCritical);
  try
    Instance.Failures := 0;
    Instance.Healthy := True;
  finally
    LeaveCriticalSection(FCritical);
  end;
end;

procedure TfrmInterceptor.tHealthTimer(Sender: TObject);
var
  Instance: TBackendInstance;
  Instances: TArray<TBackendInstance>;
  Detail: string;
begin
  EnterCriticalSection(FCritical);
  try
    Instances := FInstances.ToArray;
  finally
    LeaveCriticalSection(FCritical);
  end;

  for Instance in Instances do
  begin
    if CheckBackend(Instance, Detail) then
      RegisterSuccess(Instance)
    else
      RegisterFailure(Instance, Detail);
  end;
  RefreshUI;
end;

procedure TfrmInterceptor.RegisterRoutes;
begin
  THorse.Get('/interceptor/status', InterceptorStatusHandler);
  THorse.Use(ProxyMiddlewareHandler);
end;

procedure TfrmInterceptor.ProxyRequest(Req: THorseRequest; Res: THorseResponse);
const
  HeaderNames: array [0 .. 14] of string = ('Authorization', 'Content-Type',
    'Accept', 'user', 'usuario', 'inicio', 'fim', 'dtinicio', 'dtfim',
    'hrinicio', 'hrfim', 'If-None-Match', 'X-Request-ID', 'X-Real-IP',
    'X-Forwarded-For');
var
  Instance: TBackendInstance;
  Client: THTTPClient;
  RequestBody: TStringStream;
  ResponseBody: TStringStream;
  Headers: TNetHeaders;
  HeaderCount: Integer;
  HeaderName: string;
  HeaderValue: string;
  Response: IHTTPResponse;
  TargetURL: string;
  Query: string;
  SW: TStopwatch;
  H: TNetHeader;
  Tried: TList<TBackendInstance>;
  StartedAt: TDateTime;
  Detail: string;
  LastError: string;
begin
  Query := RequestQuery(Req);

  SetLength(Headers, Length(HeaderNames));
  HeaderCount := 0;
  for HeaderName in HeaderNames do
  begin
    HeaderValue := Req.Headers[HeaderName];
    if HeaderValue <> '' then
    begin
      Headers[HeaderCount].Name := HeaderName;
      Headers[HeaderCount].Value := HeaderValue;
      Inc(HeaderCount);
    end;
  end;
  SetLength(Headers, HeaderCount);

  RequestBody := TStringStream.Create(Req.Body, TEncoding.UTF8);
  Tried := TList<TBackendInstance>.Create;
  StartedAt := Now;
  LastError := '';
  try
    while SecondsBetween(Now, StartedAt) < 60 do
    begin
      Instance := SelectBackend(Tried);
      if not Assigned(Instance) then
      begin
        EnsureSpareCapacity('sem instancia elegivel para ' +
          Req.RawWebRequest.RawPathInfo);
        Tried.Clear;
        Sleep(500);
        Continue;
      end;

      if not CheckBackend(Instance, Detail) then
      begin
        LastError := Detail;
        RegisterFailure(Instance, Detail);
        if not Tried.Contains(Instance) then
          Tried.Add(Instance);
        EnsureSpareCapacity('health falhou porta=' + Instance.Port.ToString);
        Sleep(300);
        Continue;
      end;

      TargetURL := BackendBaseURL(Instance) + Req.RawWebRequest.RawPathInfo;
      if Query <> '' then
        TargetURL := TargetURL + '?' + Query;

      Client := THTTPClient.Create;
      ResponseBody := TStringStream.Create('', TEncoding.UTF8);
      try
        try
          Client.ConnectionTimeout := FConfig.TimeoutMS;
          Client.ResponseTimeout := FConfig.TimeoutMS;
          RequestBody.Position := 0;
          SW := TStopwatch.StartNew;
          if SameText(Req.RawWebRequest.Method, 'GET') then
            Response := Client.Get(TargetURL, ResponseBody, Headers)
          else if SameText(Req.RawWebRequest.Method, 'POST') then
            Response := Client.Post(TargetURL, RequestBody, ResponseBody,
              Headers)
          else if SameText(Req.RawWebRequest.Method, 'PUT') then
            Response := Client.Put(TargetURL, RequestBody, ResponseBody,
              Headers)
          else if SameText(Req.RawWebRequest.Method, 'PATCH') then
            Response := Client.Patch(TargetURL, RequestBody, ResponseBody,
              Headers)
          else if SameText(Req.RawWebRequest.Method, 'DELETE') then
            Response := Client.Delete(TargetURL, ResponseBody, Headers)
          else if SameText(Req.RawWebRequest.Method, 'OPTIONS') then
          begin
            Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Origin',
              '*');
            Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Methods',
              'DELETE, POST, GET, OPTIONS, PUT, PATCH');
            Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Headers',
              'Content-Type, Authorization, inicio, fim, x-server-time, dtfim, dtinicio, hrfim, hrinicio, user, usuario');
            Res.Status(204).Send('');
            Exit;
          end
          else
            Response := Client.Get(TargetURL, ResponseBody, Headers);
          SW.Stop;

          Inc(FTotalRequests);
          Inc(Instance.Requests);
          Instance.LastLatencyMS := SW.ElapsedMilliseconds;
          if SW.ElapsedMilliseconds >= FConfig.SlowMS then
          begin
            Inc(FTotalSlow);
            Inc(Instance.SlowRequests);
            Log('lento', Format('porta=%d path=%s ms=%d',
              [Instance.Port, Req.RawWebRequest.RawPathInfo,
              SW.ElapsedMilliseconds]));
          end;

          if Response.StatusCode >= 500 then
          begin
            Inc(Instance.Errors500);
            LastError := 'HTTP ' + Response.StatusCode.ToString;
            RegisterFailure(Instance, 'proxy recebeu ' + LastError);
          end;

          Res.Status(Response.StatusCode);
          if ResponseHeaderValue(Response.Headers, 'Content-Type') <> '' then
            Res.ContentType(ResponseHeaderValue(Response.Headers,
              'Content-Type'));

          for H in Response.Headers do
          begin
            if SameText(H.Name, 'Content-Length') or SameText(H.Name,
              'Transfer-Encoding') or SameText(H.Name, 'Connection') then
              Continue;
            if H.Name <> '' then
              Res.RawWebResponse.SetCustomHeader(H.Name, H.Value);
          end;

          Res.RawWebResponse.SetCustomHeader('X-GooPedir-Interceptor-Port',
            FConfig.PublicPort.ToString);
          Res.RawWebResponse.SetCustomHeader('X-GooPedir-Backend-Port',
            Instance.Port.ToString);
          Res.RawWebResponse.SetCustomHeader('X-GooPedir-Backend-URL',
            BackendBaseURL(Instance));

          RegisterSuccess(Instance);
          Res.Send(ResponseBody.DataString);
          Exit;
        except
          on E: Exception do
          begin
            LastError := E.ClassName + ': ' + E.Message;
            RegisterFailure(Instance, LastError);
            if not Tried.Contains(Instance) then
              Tried.Add(Instance);
            EnsureSpareCapacity('excecao porta=' + Instance.Port.ToString);
            Sleep(300);
          end;
        end;
      finally
        ResponseBody.Free;
        Client.Free;
      end;
    end;

    Res.Status(503).Send('Servico temporariamente indisponivel. Tentativas esgotadas. Ultimo erro: ' + LastError);
  finally
    Tried.Free;
    RequestBody.Free;
  end;
end;

procedure TfrmInterceptor.Log(const Kind, Msg: string);
var
  Line: string;
  FileName: string;
begin
  Line := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' [' + Kind + '] ' +
    Msg;
  FileName := TPath.Combine(LogDir, 'interceptor-' + Kind + '-' +
    FormatDateTime('yyyymmdd', Now) + '.log');
  EnterCriticalSection(FLogCritical);
  try
    TFile.AppendAllText(FileName, Line + sLineBreak, TEncoding.UTF8);
  finally
    LeaveCriticalSection(FLogCritical);
  end;
  try
    memLog.Lines.Add(Line);
  except
  end;
end;

procedure TfrmInterceptor.RefreshUI;
var
  Instance: TBackendInstance;
  Instances: TArray<TBackendInstance>;
begin
  EnterCriticalSection(FCritical);
  try
    Instances := FInstances.ToArray;
  finally
    LeaveCriticalSection(FCritical);
  end;

  lblStats.Caption := Format('Requisicoes: %d | Erros: %d | Lentas: %d',
    [FTotalRequests, FTotalErrors, FTotalSlow]);
  memInstances.Lines.BeginUpdate;
  try
    memInstances.Clear;
    for Instance in Instances do
      memInstances.Lines.Add(Format
        ('porta=%d pid=%d healthy=%s falhas=%d http500=%d req=%d ms=%d erro=%s',
        [Instance.Port, Instance.ProcessId, BoolToStr(Instance.Healthy, True),
        Instance.Failures, Instance.Errors500, Instance.Requests,
        Instance.LastLatencyMS, Instance.LastError]));
  finally
    memInstances.Lines.EndUpdate;
  end;
end;

procedure TfrmInterceptor.TrayIcon1DblClick(Sender: TObject);
begin
  ShowInterceptor;
end;

end.
