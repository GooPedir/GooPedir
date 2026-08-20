unit uNginxMonitor;

interface

procedure ValidarNginxInicializacao;
procedure RunNginxWatcherService;
function IsNginxWatcherParam: Boolean;

implementation

uses
  Winapi.Windows,
  Winapi.TlHelp32,
  Winapi.WinSvc,
  Winapi.ShellAPI,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Vcl.Forms,
  Vcl.Dialogs;

const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;

  NGINX_SERVICE_NAME = 'GooPedirNginxMonitor';
  NGINX_SERVICE_DISPLAY = 'GooPedir Nginx Monitor';
  NGINX_WATCH_PARAM = '--nginx-watch';
  NGINX_CHECK_INTERVAL_MS = 15000;

function QueryFullProcessImageName(hProcess: THandle; dwFlags: DWORD;
  lpExeName: PChar; var lpdwSize: DWORD): BOOL; stdcall; external kernel32
  name 'QueryFullProcessImageNameW';

var
  ServiceStatus: TServiceStatus;
  ServiceStatusHandle: SERVICE_STATUS_HANDLE = 0;
  StopEvent: THandle = 0;

function AppDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function NginxExePath: string;
begin
  Result := TPath.Combine(TPath.Combine(AppDir, 'nginx'), 'nginx.exe');
end;

function NginxDir: string;
begin
  Result := TPath.GetDirectoryName(NginxExePath);
end;

function NormalizePath(const Value: string): string;
begin
  Result := AnsiLowerCase(ExpandFileName(Value));
end;

function ProcessPathMatches(ProcessID: DWORD; const ExpectedPath: string): Boolean;
var
  H: THandle;
  Buffer: array[0..MAX_PATH * 4] of Char;
  Size: DWORD;
begin
  Result := False;
  H := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, ProcessID);
  if H = 0 then
    H := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False,
      ProcessID);
  if H = 0 then
    Exit;
  try
    Size := Length(Buffer);
    if QueryFullProcessImageName(H, 0, Buffer, Size) then
      Result := NormalizePath(Buffer) = NormalizePath(ExpectedPath);
  finally
    CloseHandle(H);
  end;
end;

function NginxRodando: Boolean;
var
  Snapshot: THandle;
  Entry: TProcessEntry32;
  ExpectedPath: string;
begin
  Result := False;
  ExpectedPath := NginxExePath;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;
  try
    Entry.dwSize := SizeOf(Entry);
    if Process32First(Snapshot, Entry) then
    begin
      repeat
        if SameText(ExtractFileName(Entry.szExeFile), 'nginx.exe') and
          ProcessPathMatches(Entry.th32ProcessID, ExpectedPath) then
          Exit(True);
      until not Process32Next(Snapshot, Entry);
    end;
  finally
    CloseHandle(Snapshot);
  end;
end;

procedure IniciarNginx;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  ExePath: string;
  WorkDir: string;
begin
  ExePath := NginxExePath;
  WorkDir := NginxDir;

  if not FileExists(ExePath) then
    Exit;

  if NginxRodando then
    Exit;

  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;

  if not CreateProcess(PChar(ExePath), nil, nil, nil, False, CREATE_NO_WINDOW,
    nil, PChar(WorkDir), StartupInfo, ProcessInfo) then
    raise Exception.CreateFmt('Nao foi possivel iniciar o nginx: %s',
      [SysErrorMessage(GetLastError)]);

  CloseHandle(ProcessInfo.hThread);
  CloseHandle(ProcessInfo.hProcess);
end;

function ServiceExiste: Boolean;
var
  SCM: SC_HANDLE;
  Svc: SC_HANDLE;
begin
  Result := False;
  SCM := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SCM = 0 then
    Exit;
  try
    Svc := OpenService(SCM, NGINX_SERVICE_NAME, SERVICE_QUERY_STATUS);
    if Svc <> 0 then
    begin
      Result := True;
      CloseServiceHandle(Svc);
    end;
  finally
    CloseServiceHandle(SCM);
  end;
end;

procedure StartServiceSeExistir;
var
  SCM: SC_HANDLE;
  Svc: SC_HANDLE;
  Status: TServiceStatus;
  Args: PChar;
begin
  SCM := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SCM = 0 then
    Exit;
  try
    Svc := OpenService(SCM, NGINX_SERVICE_NAME, SERVICE_START or
      SERVICE_QUERY_STATUS);
    if Svc = 0 then
      Exit;
    try
      if QueryServiceStatus(Svc, Status) and (Status.dwCurrentState = SERVICE_RUNNING) then
        Exit;
      Args := nil;
      Winapi.WinSvc.StartService(Svc, 0, Args);
    finally
      CloseServiceHandle(Svc);
    end;
  finally
    CloseServiceHandle(SCM);
  end;
end;

procedure InstalarServicoComScElevado;
var
  Params: string;
  ExecInfo: TShellExecuteInfo;
begin
  Params := Format('/c sc create %s binPath= ""%s" %s" start= auto DisplayName= "%s" && sc start %s',
    [NGINX_SERVICE_NAME, ParamStr(0), NGINX_WATCH_PARAM, NGINX_SERVICE_DISPLAY,
    NGINX_SERVICE_NAME]);

  ZeroMemory(@ExecInfo, SizeOf(ExecInfo));
  ExecInfo.cbSize := SizeOf(ExecInfo);
  ExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ExecInfo.Wnd := Application.Handle;
  ExecInfo.lpVerb := 'runas';
  ExecInfo.lpFile := 'cmd.exe';
  ExecInfo.lpParameters := PChar(Params);
  ExecInfo.nShow := SW_HIDE;

  if ShellExecuteEx(@ExecInfo) then
  begin
    WaitForSingleObject(ExecInfo.hProcess, 30000);
    CloseHandle(ExecInfo.hProcess);
  end;
end;

procedure InstalarServicoNginx;
var
  SCM: SC_HANDLE;
  Svc: SC_HANDLE;
  BinPath: string;
  Args: PChar;
begin
  if ServiceExiste then
  begin
    StartServiceSeExistir;
    Exit;
  end;

  BinPath := Format('"%s" %s', [ParamStr(0), NGINX_WATCH_PARAM]);
  SCM := OpenSCManager(nil, nil, SC_MANAGER_CREATE_SERVICE);
  if SCM = 0 then
  begin
    InstalarServicoComScElevado;
    Exit;
  end;

  try
    Svc := CreateService(SCM, NGINX_SERVICE_NAME, NGINX_SERVICE_DISPLAY,
      SERVICE_START or SERVICE_QUERY_STATUS, SERVICE_WIN32_OWN_PROCESS,
      SERVICE_AUTO_START, SERVICE_ERROR_NORMAL, PChar(BinPath), nil, nil, nil,
      nil, nil);
    if Svc = 0 then
    begin
      if GetLastError = ERROR_SERVICE_EXISTS then
        StartServiceSeExistir
      else
        InstalarServicoComScElevado;
      Exit;
    end;

    try
      Args := nil;
      Winapi.WinSvc.StartService(Svc, 0, Args);
    finally
      CloseServiceHandle(Svc);
    end;
  finally
    CloseServiceHandle(SCM);
  end;
end;

procedure ValidarNginxInicializacao;
var
  ExePath: string;
begin
  ExePath := NginxExePath;
  if not FileExists(ExePath) then
    Exit;

  IniciarNginx;
  InstalarServicoNginx;
end;

procedure SetServiceState(State, Win32ExitCode, WaitHint: DWORD);
begin
  ServiceStatus.dwCurrentState := State;
  ServiceStatus.dwWin32ExitCode := Win32ExitCode;
  ServiceStatus.dwWaitHint := WaitHint;

  if State in [SERVICE_START_PENDING, SERVICE_STOP_PENDING] then
    ServiceStatus.dwControlsAccepted := 0
  else
    ServiceStatus.dwControlsAccepted := SERVICE_ACCEPT_STOP or
      SERVICE_ACCEPT_SHUTDOWN;

  if ServiceStatusHandle <> 0 then
    SetServiceStatus(ServiceStatusHandle, ServiceStatus);
end;

procedure ServiceControlHandler(Control: DWORD); stdcall;
begin
  case Control of
    SERVICE_CONTROL_STOP, SERVICE_CONTROL_SHUTDOWN:
      begin
        SetServiceState(SERVICE_STOP_PENDING, NO_ERROR, 3000);
        if StopEvent <> 0 then
          SetEvent(StopEvent);
      end;
  end;
end;

procedure ServiceMain(Argc: DWORD; Argv: PPChar); stdcall;
begin
  ServiceStatusHandle := RegisterServiceCtrlHandler(NGINX_SERVICE_NAME,
    @ServiceControlHandler);
  if ServiceStatusHandle = 0 then
    Exit;

  ZeroMemory(@ServiceStatus, SizeOf(ServiceStatus));
  ServiceStatus.dwServiceType := SERVICE_WIN32_OWN_PROCESS;
  SetServiceState(SERVICE_START_PENDING, NO_ERROR, 3000);

  StopEvent := CreateEvent(nil, True, False, nil);
  if StopEvent = 0 then
  begin
    SetServiceState(SERVICE_STOPPED, GetLastError, 0);
    Exit;
  end;

  SetServiceState(SERVICE_RUNNING, NO_ERROR, 0);
  try
    while WaitForSingleObject(StopEvent, NGINX_CHECK_INTERVAL_MS) = WAIT_TIMEOUT do
    begin
      try
        IniciarNginx;
      except
      end;
    end;
  finally
    CloseHandle(StopEvent);
    StopEvent := 0;
    SetServiceState(SERVICE_STOPPED, NO_ERROR, 0);
  end;
end;

procedure RunNginxWatcherService;
var
  ServiceTable: array[0..1] of TServiceTableEntry;
begin
  ServiceTable[0].lpServiceName := PChar(NGINX_SERVICE_NAME);
  ServiceTable[0].lpServiceProc := @ServiceMain;
  ServiceTable[1].lpServiceName := nil;
  ServiceTable[1].lpServiceProc := nil;

  if StartServiceCtrlDispatcher(ServiceTable[0]) then
    Exit;

  while True do
  begin
    try
      IniciarNginx;
    except
    end;
    Sleep(NGINX_CHECK_INTERVAL_MS);
  end;
end;

function IsNginxWatcherParam: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if SameText(ParamStr(I), NGINX_WATCH_PARAM) then
      Exit(True);
end;

end.
