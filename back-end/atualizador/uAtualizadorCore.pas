unit uAtualizadorCore;

interface

type
  TAtualizadorApp = class
  private
    function ExecutarConsulta: Integer;
    function PrepararAtualizacao: Integer;
  public
    function Executar: Integer;
  end;

const
  ATU_SEM_ATUALIZACAO = 0;
  ATU_DISPONIVEL = 1;
  ATU_OBRIGATORIA = 2;
  ATU_APLICADA = 3;
  ATU_ERRO_PARAMETROS = 10;
  ATU_ERRO_AUTENTICACAO = 11;
  ATU_ERRO_SERVIDOR = 12;
  ATU_ERRO_DOWNLOAD = 13;
  ATU_ERRO_PROCESSO_ABERTO = 14;
  ATU_ERRO_ROLLBACK = 15;
  ATU_ERRO_CRITICO = 16;
  ATU_ERRO_BACKUP = 17;

implementation

uses System.SysUtils, System.IOUtils, System.JSON, System.DateUtils,
  Winapi.Windows, Winapi.ShellAPI, uUpdaterArgs,
  uUpdaterConfig, uUpdaterHttp, uUpdaterModels, uUpdaterFiles, uUpdaterResult,
  uUpdaterState, uUpdaterPackage, uUpdaterDatabase,
  uUpdaterConsole;

type
  EUpdaterRollbackError = class(Exception);
  EUpdaterBackupError = class(Exception);

var
  Arguments: TUpdaterArguments;
  Config: TUpdaterConfig;
  LogFile: string;
  WorkRoot, OperationId: string;

procedure SetState(const State: string; const LastError: string = '');
begin
  ConsoleSetState(State);
  if LastError <> '' then ConsoleDetail(LastError);
  WriteUpdateState(WorkRoot, OperationId, Config.ProductCode, Config.Channel,
    Config.CurrentVersion, State, LastError);
end;

procedure Log(const Text: string);
begin
  if LogFile <> '' then
    TFile.AppendAllText(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) +
      ' ' + Text + sLineBreak, TEncoding.UTF8);
  ConsoleDetail(Text);
end;

procedure PrepareUtf8Log(const RootDirectory: string);
var
  MarkerFile, ExistingLog, LegacyLog: string;
begin
  MarkerFile := TPath.Combine(RootDirectory, '.utf8-log-v1');
  if TFile.Exists(MarkerFile) then Exit;

  ExistingLog := TPath.Combine(RootDirectory, 'updater.log');
  if TFile.Exists(ExistingLog) then
  begin
    LegacyLog := TPath.Combine(RootDirectory, 'updater-legacy-' +
      FormatDateTime('yyyymmdd-hhnnss', Now) + '.log');
    TFile.Move(ExistingLog, LegacyLog);
  end;
  TFile.WriteAllText(MarkerFile, 'UTF-8', TEncoding.UTF8);
end;

procedure DownloadProgress(AContentLength, AReadCount: Int64);
begin
  ConsoleDownloadProgress(AContentLength, AReadCount);
end;

function BuildCheckResult(const Info: TUpdateInfo;
  Downloaded: Boolean): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('operationId', OperationId);
  Result.AddPair('available', TJSONBool.Create(Info.Available));
  Result.AddPair('downloaded', TJSONBool.Create(Downloaded));
  { mandatory mantem compatibilidade com clientes antigos e significa bloqueio imediato. }
  Result.AddPair('mandatory', TJSONBool.Create(Info.MandatoryNow));
  Result.AddPair('mandatoryScheduled', TJSONBool.Create(Info.Mandatory));
  Result.AddPair('mandatoryNow', TJSONBool.Create(Info.MandatoryNow));
  if Info.HasMandatoryAt then
    Result.AddPair('mandatoryAt', DateToISO8601(Info.MandatoryAt, True));
  if Info.HasServerTime then
    Result.AddPair('serverTime', DateToISO8601(Info.ServerTime, True));
  Result.AddPair('releaseId', Info.ReleaseId);
  Result.AddPair('version', Info.Version);
  Result.AddPair('notes', Info.Notes);
  Result.AddPair('sha256', Info.Sha256);
  Result.AddPair('sizeBytes', TJSONNumber.Create(Info.SizeBytes));
end;

function SafePathSegment(const Value: string): string;
var
  CharacterValue: Char;
begin
  Result := '';
  for CharacterValue in Value do
    if CharInSet(CharacterValue, ['a'..'z', 'A'..'Z', '0'..'9', '-', '_']) then
      Result := Result + CharacterValue;
  if (Result = '') or not SameText(Result, Value) then
    raise EUpdaterServerError.Create('releaseId invalido para armazenamento local', 0);
end;

function PackageIsValid(const FileName: string; const Info: TUpdateInfo): Boolean;
begin
  Result := TFile.Exists(FileName) and (Info.Sha256 <> '');
  if Result and (Info.SizeBytes > 0) then
    Result := TFile.GetSize(FileName) = Info.SizeBytes;
  if Result then Result := SameText(FileSha256(FileName), Info.Sha256);
end;

function Quoted(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '\"', [rfReplaceAll]) + '"';
end;

procedure ExecuteBackup(const Config: TUpdaterConfig);
var
  Info: TShellExecuteInfo;
  ExitCode: Cardinal;
  Parameters: string;
begin
  try
    if Config.BackupExe.Trim = '' then
      raise EUpdaterBackupError.Create('BackupExe nao informado');
    if not TFile.Exists(Config.BackupExe) then
      raise EUpdaterBackupError.Create('BackupExe nao encontrado: ' +
        Config.BackupExe);

    Config.ValidateDatabase;
    Parameters := '/backup' +
      ' /dbhost=' + Quoted(Config.DbHost) +
      ' /dbporta=' + IntToStr(Config.DbPort) +
      ' /dbusuario=' + Quoted(Config.DbUser) +
      ' /dbsenha=' + Quoted(Config.DbPassword) +
      ' /dbbanco=' + Quoted(Config.DbName);

    ZeroMemory(@Info, SizeOf(Info));
    Info.cbSize := SizeOf(Info);
    Info.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
    Info.lpVerb := 'open';
    Info.lpFile := PChar(Config.BackupExe);
    Info.lpParameters := PChar(Parameters);
    Info.lpDirectory := PChar(ExtractFilePath(Config.BackupExe));
    Info.nShow := SW_HIDE;
    if not ShellExecuteEx(@Info) then
      RaiseLastOSError;
    try
      if WaitForSingleObject(Info.hProcess, INFINITE) <> WAIT_OBJECT_0 then
        RaiseLastOSError;
      if not GetExitCodeProcess(Info.hProcess, ExitCode) then
        RaiseLastOSError;
      if ExitCode <> 0 then
        raise EUpdaterBackupError.CreateFmt('Backup falhou. ExitCode=%d',
          [ExitCode]);
    finally
      CloseHandle(Info.hProcess);
    end;
  except
    on E: EUpdaterBackupError do
      raise;
    on E: Exception do
      raise EUpdaterBackupError.Create('Falha ao executar backup: ' + E.Message);
  end;
end;

function ManagedPath(const RootDirectory, RelativePath: string): string;
var
  Root: string;
begin
  if (RelativePath = '') or TPath.IsPathRooted(RelativePath) then
    raise EUpdaterPackageError.Create('Caminho relativo invalido: ' + RelativePath);
  Root := IncludeTrailingPathDelimiter(TPath.GetFullPath(RootDirectory));
  Result := TPath.GetFullPath(TPath.Combine(RootDirectory,
    RelativePath.Replace('/', PathDelim)));
  if not Result.StartsWith(Root, True) then
    raise EUpdaterPackageError.Create('Caminho inseguro: ' + RelativePath);
end;

procedure CreateFileSnapshot(const Manifest: TPackageManifest;
  const InstallDirectory, SnapshotDirectory, JournalFile: string);
var
  Item: TManifestFile;
  DestinationFile, SnapshotFile: string;
  Journal: TJSONObject;
  Files: TJSONArray;
  FileEntry: TJSONObject;
begin
  TDirectory.CreateDirectory(SnapshotDirectory);
  Journal := TJSONObject.Create;
  try
    Files := TJSONArray.Create;
    Journal.AddPair('files', Files);
    for Item in Manifest.Files do
    begin
      DestinationFile := ManagedPath(InstallDirectory, Item.Destination);
      FileEntry := TJSONObject.Create;
      FileEntry.AddPair('destination', Item.Destination);
      FileEntry.AddPair('existed', TJSONBool.Create(TFile.Exists(DestinationFile)));
      Files.AddElement(FileEntry);
      if TFile.Exists(DestinationFile) then
      begin
        SnapshotFile := ManagedPath(SnapshotDirectory, Item.Destination);
        TDirectory.CreateDirectory(ExtractFileDir(SnapshotFile));
        TFile.Copy(DestinationFile, SnapshotFile, True);
      end;
    end;
    WriteResult(JournalFile, Journal);
  finally
    Journal.Free;
  end;
end;

procedure ApplyManifestFiles(const Manifest: TPackageManifest;
  const StagingDirectory, InstallDirectory, OperationId: string);
var
  Item: TManifestFile;
  SourceFile, DestinationFile, TemporaryFile: string;
begin
  for Item in Manifest.Files do
  begin
    SourceFile := ManagedPath(StagingDirectory, Item.Source);
    DestinationFile := ManagedPath(InstallDirectory, Item.Destination);
    TDirectory.CreateDirectory(ExtractFileDir(DestinationFile));
    TemporaryFile := DestinationFile + '.updater-' + OperationId + '.tmp';
    if TFile.Exists(TemporaryFile) then TFile.Delete(TemporaryFile);
    TFile.Copy(SourceFile, TemporaryFile, True);
    if not SameText(FileSha256(TemporaryFile), Item.Sha256) then
      raise EUpdaterPackageError.Create('Falha ao validar copia temporaria: ' +
        Item.Destination);
    if TFile.Exists(DestinationFile) then TFile.Delete(DestinationFile);
    TFile.Move(TemporaryFile, DestinationFile);
  end;
end;

procedure ValidateInstalledFiles(const Manifest: TPackageManifest;
  const InstallDirectory: string);
var
  Item: TManifestFile;
  DestinationFile: string;
begin
  for Item in Manifest.Files do
  begin
    DestinationFile := ManagedPath(InstallDirectory, Item.Destination);
    if not TFile.Exists(DestinationFile) then
      raise EUpdaterPackageError.Create('Arquivo instalado nao encontrado: ' +
        Item.Destination);
    if not SameText(FileSha256(DestinationFile), Item.Sha256) then
      raise EUpdaterPackageError.Create('SHA-256 instalado divergente: ' +
        Item.Destination);
  end;
end;

procedure RestoreFileSnapshot(const Manifest: TPackageManifest;
  const InstallDirectory, SnapshotDirectory: string);
var
  Item: TManifestFile;
  DestinationFile, SnapshotFile: string;
begin
  for Item in Manifest.Files do
  begin
    DestinationFile := ManagedPath(InstallDirectory, Item.Destination);
    SnapshotFile := ManagedPath(SnapshotDirectory, Item.Destination);
    if TFile.Exists(SnapshotFile) then
    begin
      TDirectory.CreateDirectory(ExtractFileDir(DestinationFile));
      TFile.Copy(SnapshotFile, DestinationFile, True);
    end
    else if TFile.Exists(DestinationFile) then
      TFile.Delete(DestinationFile);
  end;
end;

function TAtualizadorApp.ExecutarConsulta: Integer;
var
  Http: TUpdaterHttp;
  Info: TUpdateInfo;
  CacheDirectory, DownloadFile, TemporaryFile: string;
  Json: TJSONObject;
begin
  Http := TUpdaterHttp.Create(Config.Token);
  try
    Log('Consultando atualizacao...');
    SetState('checking');
    Http.CheckHealth(Config.BaseUrl);
    Info := Http.Check(Config.BaseUrl, Config.ProductCode, Config.Channel,
      Config.CurrentVersion, Config.Company, Config.CompanyName,
      Config.CompanyDocument, Config.Terminal);
    ConsoleSetVersion(Info.Version);
    if not Info.Available then
    begin
      Json := BuildCheckResult(Info, False);
      try WriteResult(Config.ResultFile, Json); finally Json.Free; end;
      Log('Nenhuma atualizacao disponivel.');
      SetState('completed');
      Exit(ATU_SEM_ATUALIZACAO);
    end;

    CacheDirectory := TPath.Combine(TPath.Combine(TPath.Combine(TPath.Combine(
      Config.InstallDirectory, '.updater'), 'cache'), Config.Channel),
      SafePathSegment(Info.ReleaseId));
    TDirectory.CreateDirectory(CacheDirectory);
    DownloadFile := TPath.Combine(CacheDirectory, 'package.zip');
    TemporaryFile := DownloadFile + '.download';
    if PackageIsValid(DownloadFile, Info) then
      Log('Pacote validado ja esta disponivel no cache.')
    else
    begin
      if TFile.Exists(TemporaryFile) then TFile.Delete(TemporaryFile);
      try
        Log('Baixando versao ' + Info.Version + '...');
        SetState('downloading');
        Http.OnDownloadProgress := DownloadProgress;
        Http.Download(Info.DownloadUrl, TemporaryFile);
        Http.OnDownloadProgress := nil;
        if (Info.SizeBytes > 0) and
          (TFile.GetSize(TemporaryFile) <> Info.SizeBytes) then
          raise EUpdaterDownloadError.Create('Tamanho do pacote divergente', 0);
        if (Info.Sha256 = '') or
          not SameText(FileSha256(TemporaryFile), Info.Sha256) then
          raise EUpdaterDownloadError.Create('SHA-256 do pacote divergente', 0);
        if TFile.Exists(DownloadFile) then TFile.Delete(DownloadFile);
        TFile.Move(TemporaryFile, DownloadFile);
      except
        if TFile.Exists(TemporaryFile) then TFile.Delete(TemporaryFile);
        raise;
      end;
    end;

    Json := BuildCheckResult(Info, True);
    try
      Json.AddPair('packageFile', DownloadFile);
      WriteResult(TPath.Combine(CacheDirectory, 'cache-info.json'), Json);
      WriteResult(Config.ResultFile, Json);
    finally Json.Free; end;
    Log('Versao ' + Info.Version + ' baixada e validada.');
    SetState('ready');
    if Info.MandatoryNow then Result := ATU_OBRIGATORIA
    else Result := ATU_DISPONIVEL;
  finally
    Http.Free;
  end;
end;

function TAtualizadorApp.PrepararAtualizacao: Integer;
var
  CacheDirectory, CacheInfoFile, ExpectedPackageFile: string;
  StagingDirectory, ManifestFile: string;
  Cache: TPackageCacheInfo;
  Manifest: TPackageManifest;
  Json: TJSONObject;
  OperationDirectory: string;
  Http: TUpdaterHttp;
  InstalledVersionFile: string;
  SnapshotDirectory, JournalFile, Running: string;
  InstallationStarted: Boolean;
  HadInstalledVersion: Boolean;
  PreviousInstalledVersion: string;
begin
  if Config.ReleaseId = '' then
    raise EArgumentException.Create('releaseid nao informado para /atualizar');

  SetState('preparing');
  CacheDirectory := TPath.Combine(TPath.Combine(TPath.Combine(
    WorkRoot, 'cache'), Config.Channel), SafePathSegment(Config.ReleaseId));
  CacheInfoFile := TPath.Combine(CacheDirectory, 'cache-info.json');
  Cache := LoadPackageCacheInfo(CacheInfoFile);
  ConsoleSetVersion(Cache.Version);
  ExpectedPackageFile := TPath.GetFullPath(TPath.Combine(CacheDirectory,
    'package.zip'));
  if not SameText(TPath.GetFullPath(Cache.PackageFile), ExpectedPackageFile) then
    raise EUpdaterPackageError.Create('Caminho do pacote no cache e invalido');
  ValidateCachedPackage(Cache, Config.ReleaseId);

  OperationDirectory := TPath.Combine(TPath.Combine(WorkRoot, 'operations'),
    OperationId);
  TDirectory.CreateDirectory(OperationDirectory);

  SetState('backing_up');
  Log('Executando backup antes da atualizacao...');
  ExecuteBackup(Config);
  Log('Backup concluido.');

  SetState('waiting_processes');
  Log('Aguardando fechamento do servidor e integracoes...');
  Running := RunningProcesses(Config.Processes, Config.InstallDirectory);
  if Running <> '' then Log('Processos ainda abertos: ' + Running);
  RequestProcessesClose(Config.Processes, Config.InstallDirectory);
  if not WaitProcessesClosed(Config.Processes, Config.CloseTimeoutSeconds,
    Config.InstallDirectory) then
    raise Exception.Create('Processos continuam em execucao: ' +
      RunningProcesses(Config.Processes, Config.InstallDirectory));

  { Atualizações compostas apenas por SQL são entregues como texto puro.
    O nome package.zip pertence ao cache e não define o tipo do conteúdo. }
  if not IsZipFile(Cache.PackageFile) then
  begin
    Config.ValidateDatabase;
    SetState('installing');
    Log('Executando atualizacao SQL...');
    ExecuteSqlPackage(Config, Cache.PackageFile);

    InstalledVersionFile := TPath.Combine(Config.InstallDirectory,
      'installed.version');
    TFile.WriteAllText(InstalledVersionFile, Cache.Version, TEncoding.UTF8);
    SetState('completed');
    Log('Atualizacao SQL concluida com sucesso.');

    Http := TUpdaterHttp.Create(Config.Token);
    try
      try
        Http.SendEvent(Config.BaseUrl, Config.Company, Config.Terminal,
          Config.ProductCode, Config.CurrentVersion, Cache.Version, 'success',
          'Atualizacao SQL aplicada');
      except
        on E: Exception do Log('Aviso ao enviar evento: ' + E.Message);
      end;
    finally
      Http.Free;
    end;

    Sleep(1500);
    if not IsProcessRunning(Config.EntryPoint) then
      ShellExecute(0, 'open',
        PChar(TPath.Combine(Config.InstallDirectory, Config.EntryPoint)), nil,
        PChar(Config.InstallDirectory), SW_SHOWNORMAL);
    Exit(ATU_APLICADA);
  end;

  StagingDirectory := TPath.Combine(OperationDirectory, 'staging');
  EnsureEmptyDirectory(StagingDirectory);
  ExtractZipSafe(Cache.PackageFile, StagingDirectory);
  ManifestFile := TPath.Combine(StagingDirectory, 'manifest.json');
  if TFile.Exists(ManifestFile) then
  begin
    Manifest := LoadPackageManifest(ManifestFile);
    ValidateManifest(Manifest, Config.ReleaseId, Config.ProductCode,
      Config.Channel);
  end
  else
  begin
    { Compatibilidade com releases antigas compostas somente pelo executavel.
      O pacote externo ja foi validado pelo SHA-256 fornecido pelo servidor. }
    InstalledVersionFile := TPath.Combine(StagingDirectory, Config.EntryPoint);
    if not TFile.Exists(InstalledVersionFile) then
      raise EUpdaterPackageError.Create(
        'manifest.json ausente e o pacote nao contem ' + Config.EntryPoint);
    Manifest := Default(TPackageManifest);
    Manifest.ReleaseId := Config.ReleaseId;
    Manifest.ProductCode := Config.ProductCode;
    Manifest.Channel := Config.Channel;
    Manifest.Version := Cache.Version;
    Manifest.EntryPoint := Config.EntryPoint;
    SetLength(Manifest.Files, 1);
    Manifest.Files[0].Source := Config.EntryPoint;
    Manifest.Files[0].Destination := Config.EntryPoint;
    Manifest.Files[0].Sha256 := FileSha256(InstalledVersionFile);
    Log('Pacote legado sem manifest.json; atualizando somente ' +
      Config.EntryPoint + '.');
  end;
  ValidateManifestFiles(Manifest, StagingDirectory);
  if not SameText(Manifest.Version, Cache.Version) then
    raise EUpdaterPackageError.Create('Versao do manifesto nao corresponde ao cache');

  SnapshotDirectory := TPath.Combine(OperationDirectory, 'snapshot');
  JournalFile := TPath.Combine(OperationDirectory, 'journal.json');
  InstalledVersionFile := TPath.Combine(Config.InstallDirectory,
    'installed.version');
  HadInstalledVersion := TFile.Exists(InstalledVersionFile);
  if HadInstalledVersion then
    PreviousInstalledVersion := TFile.ReadAllText(InstalledVersionFile,
      TEncoding.UTF8)
  else
    PreviousInstalledVersion := '';
  Log('Criando snapshot dos arquivos instalados...');
  CreateFileSnapshot(Manifest, Config.InstallDirectory, SnapshotDirectory,
    JournalFile);

  InstallationStarted := False;
  try
    InstallationStarted := True;
    SetState('installing');
    Log('Aplicando arquivos da versao ' + Manifest.Version + '...');
    ApplyManifestFiles(Manifest, StagingDirectory, Config.InstallDirectory,
      OperationId);

    SetState('validating');
    Log('Validando arquivos instalados...');
    ValidateInstalledFiles(Manifest, Config.InstallDirectory);
    TFile.WriteAllText(InstalledVersionFile, Manifest.Version, TEncoding.UTF8);

    Json := TJSONObject.Create;
    try
      Json.AddPair('success', TJSONBool.Create(True));
      Json.AddPair('applied', TJSONBool.Create(True));
      Json.AddPair('operationId', OperationId);
      Json.AddPair('releaseId', Manifest.ReleaseId);
      Json.AddPair('version', Manifest.Version);
      WriteResult(Config.ResultFile, Json);
    finally
      Json.Free;
    end;
    SetState('completed');
    Log('Atualizacao concluida com sucesso.');

    Http := TUpdaterHttp.Create(Config.Token);
    try
      try
        Http.SendEvent(Config.BaseUrl, Config.Company, Config.Terminal,
          Config.ProductCode, Config.CurrentVersion, Manifest.Version,
          'success', 'Atualizacao aplicada');
      except
        on E: Exception do Log('Aviso ao enviar evento: ' + E.Message);
      end;
    finally
      Http.Free;
    end;

    Sleep(1500);
    if not IsProcessRunning(Config.EntryPoint) then
      ShellExecute(0, 'open',
        PChar(TPath.Combine(Config.InstallDirectory, Config.EntryPoint)), nil,
        PChar(Config.InstallDirectory), SW_SHOWNORMAL);
    Result := ATU_APLICADA;
  except
    on E: Exception do
    begin
      if InstallationStarted then
      begin
        SetState('rolling_back', E.Message);
        Log('Falha na instalacao; restaurando snapshot: ' + E.Message);
        try
          RestoreFileSnapshot(Manifest, Config.InstallDirectory,
            SnapshotDirectory);
          if HadInstalledVersion then
            TFile.WriteAllText(InstalledVersionFile, PreviousInstalledVersion,
              TEncoding.UTF8)
          else if TFile.Exists(InstalledVersionFile) then
            TFile.Delete(InstalledVersionFile);
          Log('Rollback dos arquivos concluido.');
        except
          on ERollback: Exception do
            raise EUpdaterRollbackError.Create('Falha original: ' + E.Message +
              '. Falha no rollback: ' + ERollback.Message);
        end;
      end;
      raise;
    end;
  end;
end;

function TAtualizadorApp.Executar: Integer;
var
  Lock: TUpdaterLock;
  Id: TGUID;
begin
  Arguments := nil;
  Config := nil;
  LogFile := '';
  WorkRoot := '';
  OperationId := '';
  Lock := nil;
  try
    try
      Arguments := TUpdaterArguments.Create;
      Config := TUpdaterConfig.Create(TPath.Combine(ExtractFilePath(ParamStr(0)),
        'updater.ini'));
      Config.ApplyArguments(Arguments);
      ClearOutputFiles(Config.ResultFile, Config.ErrorFile);
      Config.Validate;
      WorkRoot := TPath.Combine(Config.InstallDirectory, '.updater');
      TDirectory.CreateDirectory(WorkRoot);
      PrepareUtf8Log(WorkRoot);
      LogFile := TPath.Combine(WorkRoot, 'updater.log');
      ConsoleInitialize(LogFile);
      Lock := TUpdaterLock.Create;
      if CreateGUID(Id) <> 0 then RaiseLastOSError;
      OperationId := GUIDToString(Id).Trim(['{', '}']).ToLower;
      if Arguments.Mode = umCheck then
        Result := ExecutarConsulta
      else
        Result := PrepararAtualizacao;
    except
      on E: EArgumentException do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        Log(E.Message);
        Result := ATU_ERRO_PARAMETROS;
      end;
      on E: EUpdaterAuthenticationError do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_AUTENTICACAO;
      end;
      on E: EUpdaterDownloadError do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_DOWNLOAD;
      end;
      on E: EUpdaterPackageError do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_DOWNLOAD;
      end;
      on E: EUpdaterRollbackError do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_ROLLBACK;
      end;
      on E: EUpdaterBackupError do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_BACKUP;
      end;
      on E: EUpdaterHealthError do
      begin
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_SERVIDOR;
      end;
      on E: EUpdaterServerError do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_SERVIDOR;
      end;
      on E: Exception do
      begin
        if Assigned(Config) then WriteError(Config.ErrorFile, E.Message);
        if (WorkRoot <> '') and (OperationId <> '') then
          try SetState('failed', E.Message); except end;
        Log(E.Message);
        Result := ATU_ERRO_SERVIDOR;
      end;
    end;
//    if (Result >= ATU_ERRO_PARAMETROS) and not RetornarImediatamente then
//      Sleep(5000);
  finally
    Lock.Free;
    Config.Free;
    Arguments.Free;
  end;
end;

end.
