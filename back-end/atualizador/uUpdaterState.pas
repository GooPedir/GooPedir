unit uUpdaterState;

interface

uses System.SysUtils, Winapi.Windows;

type
  EUpdaterAlreadyRunning = class(Exception);

  TUpdaterLock = class
  private
    FHandle: THandle;
  public
    constructor Create;
    destructor Destroy; override;
  end;

procedure WriteUpdateState(const WorkRoot, OperationId, ProductCode, Channel,
  CurrentVersion, State, LastError: string);

implementation

uses System.IOUtils, System.JSON, System.DateUtils, uUpdaterResult;

constructor TUpdaterLock.Create;
begin
  inherited Create;
  FHandle := CreateMutex(nil, False, 'Local\GooPedir.Servidor.Atualizador');
  if FHandle = 0 then RaiseLastOSError;
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    CloseHandle(FHandle);
    FHandle := 0;
    raise EUpdaterAlreadyRunning.Create('Ja existe uma instancia do Atualizador em execucao');
  end;
end;

destructor TUpdaterLock.Destroy;
begin
  if FHandle <> 0 then CloseHandle(FHandle);
  inherited;
end;

procedure WriteUpdateState(const WorkRoot, OperationId, ProductCode, Channel,
  CurrentVersion, State, LastError: string);
var
  Json: TJSONObject;
begin
  Json := TJSONObject.Create;
  try
    Json.AddPair('operationId', OperationId);
    Json.AddPair('product', ProductCode);
    Json.AddPair('channel', Channel);
    Json.AddPair('currentVersion', CurrentVersion);
    Json.AddPair('state', State);
    Json.AddPair('updatedAt', DateToISO8601(TTimeZone.Local.ToUniversalTime(Now), True));
    Json.AddPair('lastError', LastError);
    WriteResult(TPath.Combine(WorkRoot, 'update-state.json'), Json);
  finally
    Json.Free;
  end;
end;

end.
