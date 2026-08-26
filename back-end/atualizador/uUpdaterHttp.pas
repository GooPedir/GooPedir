unit uUpdaterHttp;

interface

uses System.SysUtils, System.Classes, System.Net.HttpClient,
  System.Net.URLClient, System.JSON, uUpdaterModels;

type
  TDownloadProgressEvent = procedure(AContentLength, AReadCount: Int64);

  EUpdaterHttpError = class(Exception)
  private
    FStatusCode: Integer;
  public
    constructor Create(const MessageText: string; StatusCode: Integer);
    property StatusCode: Integer read FStatusCode;
  end;

  EUpdaterAuthenticationError = class(EUpdaterHttpError);
  EUpdaterServerError = class(EUpdaterHttpError);
  EUpdaterHealthError = class(EUpdaterServerError);
  EUpdaterDownloadError = class(EUpdaterHttpError);

  TUpdaterHttp = class
  private
    FClient: THTTPClient;
    FToken: string;
    FOnDownloadProgress: TDownloadProgressEvent;
    procedure ReceiveData(const Sender: TObject; AContentLength,
      AReadCount: Int64; var AAbort: Boolean);
  public
    constructor Create(const Token: string);
    destructor Destroy; override;
    procedure CheckHealth(const BaseUrl: string);
    function Check(const BaseUrl, ProductCode, Channel, Version, Company,
      CompanyName, CompanyDocument, Terminal: string): TUpdateInfo;
    procedure Download(const Url, TargetFile: string);
    procedure SendEvent(const BaseUrl, Company, Terminal, ProductCode,
      PreviousVersion, TargetVersion, Status, MessageText: string);
    property OnDownloadProgress: TDownloadProgressEvent
      read FOnDownloadProgress write FOnDownloadProgress;
  end;

implementation

uses System.NetEncoding, System.DateUtils;

const
  CHECK_CONNECTION_TIMEOUT = 3000;
  CHECK_RESPONSE_TIMEOUT = 5000;
  DOWNLOAD_CONNECTION_TIMEOUT = 15000;
  DOWNLOAD_RESPONSE_TIMEOUT = 300000;

constructor EUpdaterHttpError.Create(const MessageText: string;
  StatusCode: Integer);
begin
  inherited Create(MessageText);
  FStatusCode := StatusCode;
end;

procedure ValidateResponse(const Response: IHTTPResponse;
  const OperationText: string; Download: Boolean = False);
begin
  if (Response.StatusCode >= 200) and (Response.StatusCode < 300) then Exit;
  if (Response.StatusCode = 401) or (Response.StatusCode = 403) then
    raise EUpdaterAuthenticationError.Create(
      Format('%s: acesso negado (HTTP %d)', [OperationText, Response.StatusCode]),
      Response.StatusCode);
  if Download then
    raise EUpdaterDownloadError.Create(
      Format('%s: HTTP %d', [OperationText, Response.StatusCode]),
      Response.StatusCode);
  raise EUpdaterServerError.Create(
    Format('%s: HTTP %d', [OperationText, Response.StatusCode]),
    Response.StatusCode);
end;

function TryReadISODate(Json: TJSONObject; const Name: string;
  out Value: TDateTime): Boolean;
var
  TextValue: string;
begin
  Result := Json.TryGetValue<string>(Name, TextValue) and (TextValue <> '');
  if Result then
    try
      Value := ISO8601ToDate(TextValue, True);
    except
      raise EUpdaterServerError.Create('Data invalida no campo ' + Name, 0);
    end;
end;

constructor TUpdaterHttp.Create(const Token: string);
begin
  inherited Create;
  FToken := Token;
  FClient := THTTPClient.Create;
  FClient.ConnectionTimeout := CHECK_CONNECTION_TIMEOUT;
  FClient.ResponseTimeout := CHECK_RESPONSE_TIMEOUT;
  FClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
  FClient.OnReceiveData := ReceiveData;
end;

procedure TUpdaterHttp.ReceiveData(const Sender: TObject; AContentLength,
  AReadCount: Int64; var AAbort: Boolean);
begin
  if Assigned(FOnDownloadProgress) then
    FOnDownloadProgress(AContentLength, AReadCount);
end;

destructor TUpdaterHttp.Destroy;
begin
  FClient.Free;
  inherited;
end;

function Enc(const S: string): string;
begin
  Result := TNetEncoding.URL.Encode(S);
end;

function IsAbsoluteHttpUrl(const Url: string): Boolean;
begin
  Result := SameText(Copy(Url, 1, 7), 'http://') or
    SameText(Copy(Url, 1, 8), 'https://');
end;

function ResolveDownloadUrl(const BaseUrl, DownloadUrl: string): string;
var
  CleanBaseUrl, CleanDownloadUrl: string;
begin
  CleanDownloadUrl := DownloadUrl.Trim;
  if (CleanDownloadUrl = '') or IsAbsoluteHttpUrl(CleanDownloadUrl) then
    Exit(CleanDownloadUrl);

  CleanBaseUrl := BaseUrl.Trim.TrimRight(['/']);
  if Copy(CleanDownloadUrl, 1, 1) = '/' then
    Result := CleanBaseUrl + CleanDownloadUrl
  else
    Result := CleanBaseUrl + '/' + CleanDownloadUrl;
end;

procedure TUpdaterHttp.CheckHealth(const BaseUrl: string);
var
  Response: IHTTPResponse;
  StatusCode: Integer;
begin
  StatusCode := 0;
  FClient.ConnectionTimeout := CHECK_CONNECTION_TIMEOUT;
  FClient.ResponseTimeout := CHECK_RESPONSE_TIMEOUT;
  try
    Response := FClient.Get(BaseUrl + '/health');
    StatusCode := Response.StatusCode;
    if (StatusCode < 200) or (StatusCode >= 300) then
      raise EUpdaterHealthError.Create(
        'Servidor de atualizacao indisponivel.', StatusCode);
  except
    on E: EUpdaterHealthError do
      raise;
    on E: Exception do
      raise EUpdaterHealthError.Create(
        'Servidor de atualizacao indisponivel.', StatusCode);
  end;
end;

function TUpdaterHttp.Check(const BaseUrl, ProductCode, Channel, Version,
  Company, CompanyName, CompanyDocument, Terminal: string): TUpdateInfo;
var
  Response: IHTTPResponse;
  Json: TJSONObject;
  Body: TStringStream;
  ClientJson, TerminalJson: TJSONObject;
begin
  Result := Default(TUpdateInfo);
  FClient.ConnectionTimeout := CHECK_CONNECTION_TIMEOUT;
  FClient.ResponseTimeout := CHECK_RESPONSE_TIMEOUT;
  Json := TJSONObject.Create;
  ClientJson := TJSONObject.Create;
  TerminalJson := TJSONObject.Create;
  ClientJson.AddPair('id', Company);
  ClientJson.AddPair('name', CompanyName);
  ClientJson.AddPair('document', CompanyDocument);
  TerminalJson.AddPair('id', Terminal);
  TerminalJson.AddPair('name', GetEnvironmentVariable('COMPUTERNAME'));
  TerminalJson.AddPair('computerName', GetEnvironmentVariable('COMPUTERNAME'));
  Json.AddPair('client', ClientJson);
  Json.AddPair('terminal', TerminalJson);
  Json.AddPair('product', ProductCode);
  Json.AddPair('channel', Channel);
  Json.AddPair('currentVersion', Version);
  Body := TStringStream.Create(Json.ToJSON, TEncoding.UTF8);
  try
    Response := FClient.Post(BaseUrl + '/api/v1/updates/check', Body, nil,
      [TNameValuePair.Create('Content-Type', 'application/json')]);
  finally
    Body.Free;
    Json.Free;
  end;
  ValidateResponse(Response, 'Falha ao consultar atualizacao');
  Json := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8)) as TJSONObject;
  try
    if not Assigned(Json) then raise Exception.Create('Resposta JSON invalida');
    Json.TryGetValue<Boolean>('available', Result.Available);
    Json.TryGetValue<string>('version', Result.Version);
    Json.TryGetValue<string>('releaseId', Result.ReleaseId);
    Json.TryGetValue<Boolean>('mandatory', Result.Mandatory);
    Json.TryGetValue<Boolean>('mandatoryNow', Result.MandatoryNow);
    Result.HasMandatoryAt := TryReadISODate(Json, 'mandatoryAt', Result.MandatoryAt);
    Result.HasServerTime := TryReadISODate(Json, 'serverTime', Result.ServerTime);
    if Result.Mandatory and Result.HasMandatoryAt and Result.HasServerTime then
      Result.MandatoryNow := Result.ServerTime >= Result.MandatoryAt;
    Json.TryGetValue<string>('downloadUrl', Result.DownloadUrl);
    Result.DownloadUrl := ResolveDownloadUrl(BaseUrl, Result.DownloadUrl);
    Json.TryGetValue<string>('sha256', Result.Sha256);
    Json.TryGetValue<Int64>('sizeBytes', Result.SizeBytes);
    Json.TryGetValue<string>('notes', Result.Notes);
    if Result.Available and (Result.ReleaseId = '') then
      raise EUpdaterServerError.Create('releaseId nao informado pelo servidor', 0);
    if Result.Available and (Result.Version = '') then
      raise EUpdaterServerError.Create('version nao informada pelo servidor', 0);
    if Result.Available and (Result.DownloadUrl = '') then
      raise EUpdaterServerError.Create('downloadUrl nao informada pelo servidor', 0);
  finally
    Json.Free;
  end;
end;

procedure TUpdaterHttp.Download(const Url, TargetFile: string);
var
  Stream: TFileStream;
  Response: IHTTPResponse;
begin
  FClient.ConnectionTimeout := DOWNLOAD_CONNECTION_TIMEOUT;
  FClient.ResponseTimeout := DOWNLOAD_RESPONSE_TIMEOUT;
  Stream := TFileStream.Create(TargetFile, fmCreate);
  try
    Response := FClient.Get(Url, Stream);
    ValidateResponse(Response, 'Falha no download', True);
  finally
    Stream.Free;
  end;
end;

procedure TUpdaterHttp.SendEvent(const BaseUrl, Company, Terminal, ProductCode,
  PreviousVersion, TargetVersion, Status, MessageText: string);
var
  Json: TJSONObject;
  Body: TStringStream;
  Response: IHTTPResponse;
begin
  FClient.ConnectionTimeout := CHECK_CONNECTION_TIMEOUT;
  FClient.ResponseTimeout := CHECK_RESPONSE_TIMEOUT;
  Json := TJSONObject.Create;
  try
    Json.AddPair('terminalId', Terminal);
    Json.AddPair('previousVersion', PreviousVersion);
    Json.AddPair('targetVersion', TargetVersion);
    Json.AddPair('status', Status);
    Json.AddPair('message', MessageText);
    Body := TStringStream.Create(Json.ToJSON, TEncoding.UTF8);
    try
      Response := FClient.Post(BaseUrl + '/api/v1/updates/events', Body, nil,
        [TNameValuePair.Create('Content-Type', 'application/json')]);
      if Response.StatusCode <> 202 then
        Writeln('Aviso: evento nao enviado. HTTP ' + Response.StatusCode.ToString);
    finally
      Body.Free;
    end;
  finally
    Json.Free;
  end;
end;

end.
