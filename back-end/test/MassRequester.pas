unit MassRequester;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.SyncObjs,
  System.Net.HttpClient, System.Net.URLClient, System.Diagnostics, System.Types,
  System.Generics.Defaults, System.Net.HttpClientComponent, Math;

type
  TRequestResult = record
    URL: string;
    StatusCode: Integer;
    BodySnippet: string;
    ErrorMsg: string;
    DurationMs: Int64;
  end;

  TOnRequestResult = reference to procedure(const AResult: TRequestResult);
  TOnAllFinished = reference to procedure;

  TMassRequester = class
  private
    FQueue: TQueue<string>;
    FQueueLock: TCriticalSection;
    FWorkers: TObjectList<TThread>;
    FWorkerCount: Integer;
    FClientTimeoutMs: Integer;
    FOnResult: TOnRequestResult;
    FOnAllFinished: TOnAllFinished;
    FActiveWorkers: Integer;
    FActiveLock: TCriticalSection;
    FStopped: Boolean;
    procedure WorkerDone;
    function DequeueURL(var AUrl: string): Boolean;
  public
    constructor Create(const AUrls: TArray<string>; AWorkerCount: Integer = 10; ATimeoutMs: Integer = 10000);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    property OnResult: TOnRequestResult read FOnResult write FOnResult;
    property OnAllFinished: TOnAllFinished read FOnAllFinished write FOnAllFinished;
    property WorkerCount: Integer read FWorkerCount write FWorkerCount;
    property ClientTimeoutMs: Integer read FClientTimeoutMs write FClientTimeoutMs;
  end;

implementation

uses
  System.NetConsts;

type
  TRequestWorker = class(TThread)
  private
    FOwner: TMassRequester;
    FClient: TNetHTTPClient;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TMassRequester); reintroduce;
    destructor Destroy; override;
  end;

{ TMassRequester }

constructor TMassRequester.Create(const AUrls: TArray<string>; AWorkerCount: Integer = 10; ATimeoutMs: Integer = 10000);
var
  i: Integer;
begin
  inherited Create;
  FQueue := TQueue<string>.Create;
  FQueueLock := TCriticalSection.Create;
  FActiveLock := TCriticalSection.Create;
  FWorkers := TObjectList<TThread>.Create(True); // owns threads
  FWorkerCount := Max(1, AWorkerCount);
  FClientTimeoutMs := ATimeoutMs;
  FStopped := False;
  for i := 0 to Length(AUrls)-1 do
    FQueue.Enqueue(AUrls[i]);
end;

destructor TMassRequester.Destroy;
begin
  Stop;
  FWorkers.Free;
  FQueue.Free;
  FQueueLock.Free;
  FActiveLock.Free;
  inherited;
end;

procedure TMassRequester.Stop;
begin
  FStopped := True;
  // wait threads to terminate
  while True do
  begin
    FActiveLock.Acquire;
    try
      if FActiveWorkers = 0 then Break;
    finally
      FActiveLock.Release;
    end;
    Sleep(50);
  end;
end;

procedure TMassRequester.Start;
var
  i: Integer;
  w: TRequestWorker;
begin
  FStopped := False;
  for i := 1 to FWorkerCount do
  begin
    w := TRequestWorker.Create(Self);
    FWorkers.Add(w);
  end;
end;

function TMassRequester.DequeueURL(var AUrl: string): Boolean;
begin
  Result := False;
  FQueueLock.Acquire;
  try
    if (FQueue.Count > 0) then
    begin
      AUrl := FQueue.Dequeue;
      Result := True;
    end;
  finally
    FQueueLock.Release;
  end;
end;

procedure TMassRequester.WorkerDone;
begin
  FActiveLock.Acquire;
  try
    Dec(FActiveWorkers);
    if (FActiveWorkers = 0) and (FQueue.Count = 0) then
    begin
      if Assigned(FOnAllFinished) then
      begin
        TThread.Queue(nil,
          procedure
          begin
            try
              FOnAllFinished();
            except
            end;
          end);
      end;
    end;
  finally
    FActiveLock.Release;
  end;
end;

{ TRequestWorker }

constructor TRequestWorker.Create(AOwner: TMassRequester);
begin
  FOwner := AOwner;
  FClient := TNetHTTPClient.Create(nil);
  FClient.ConnectionTimeout := FOwner.ClientTimeoutMs;
  FClient.ResponseTimeout := FOwner.ClientTimeoutMs;
  inherited Create(False);
  FreeOnTerminate := False;
end;

destructor TRequestWorker.Destroy;
begin
  FClient.Free;
  inherited;
end;

procedure TRequestWorker.Execute;
var
  url: string;
  resp: IHTTPResponse;
  res: TRequestResult;
  sw: TStopwatch;
begin
  inherited;
  FOwner.FActiveLock.Acquire;
  try
    Inc(FOwner.FActiveWorkers);
  finally
    FOwner.FActiveLock.Release;
  end;

  try
    while not Terminated and not FOwner.FStopped do
    begin
      if not FOwner.DequeueURL(url) then
        Break;

      res.URL := url;
      res.StatusCode := 0;
      res.BodySnippet := '';
      res.ErrorMsg := '';
      res.DurationMs := 0;

      try
        sw := TStopwatch.StartNew;
        try
          resp := FClient.Get(url);
          sw.Stop;
          res.DurationMs := sw.ElapsedMilliseconds;
          if Assigned(resp) then
          begin
            res.StatusCode := resp.StatusCode;
            if resp.ContentLength > 0 then
            begin
              if resp.ContentLength > 1024 then
                res.BodySnippet := resp.ContentAsString.Substring(0, 1024)
              else
                res.BodySnippet := resp.ContentAsString;
            end;
          end;
        except
          on E: Exception do
          begin
            sw.Stop;
            res.DurationMs := sw.ElapsedMilliseconds;
            res.ErrorMsg := E.ClassName + ': ' + E.Message;
          end;
        end;
      finally
        if Assigned(FOwner.FOnResult) then
        begin
          TThread.Queue(nil,
            procedure
            begin
              try
                FOwner.FOnResult(res);
              except
              end;
            end);
        end;
      end;
    end;
  finally
    FOwner.WorkerDone;
  end;
end;

end.
