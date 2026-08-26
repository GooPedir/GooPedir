unit uUpdaterConfig;

interface

uses System.SysUtils, System.IniFiles, uUpdaterArgs;

type
  TUpdaterConfig = class
  private
    FIni: TMemIniFile;
  public
    BaseUrl, Token, Company, CompanyName, CompanyDocument: string;
    Terminal, ProductCode, Channel: string;
    CurrentVersion, InstallDirectory, EntryPoint, ReleaseId: string;
    BackupExe, DbHost, DbUser, DbPassword, DbName: string;
    DbPort: Integer;
    Processes: TArray<string>;
    CloseTimeoutSeconds: Integer;
    ResultFile, ErrorFile: string;
    constructor Create(const FileName: string);
    destructor Destroy; override;
    procedure ApplyArguments(Arguments: TUpdaterArguments);
    procedure Validate;
    procedure ValidateDatabase;
  end;

implementation

uses System.IOUtils;

constructor TUpdaterConfig.Create(const FileName: string);
begin
  inherited Create;
  FIni := TMemIniFile.Create(FileName, TEncoding.UTF8);
  BaseUrl := FIni.ReadString('Server', 'BaseUrl', '').Trim.TrimRight(['/']);
  Token := FIni.ReadString('Server', 'Token', '').Trim;
  Company := FIni.ReadString('Client', 'Company', '').Trim;
  CompanyName := FIni.ReadString('Client', 'CompanyName', '').Trim;
  CompanyDocument := FIni.ReadString('Client', 'CompanyDocument', '').Trim;
  Terminal := FIni.ReadString('Client', 'Terminal',
    GetEnvironmentVariable('COMPUTERNAME')).Trim;
  ProductCode := FIni.ReadString('Client', 'Product', 'servidor').Trim;
  Channel := FIni.ReadString('Client', 'Channel', 'test').Trim.ToLower;
  CurrentVersion := FIni.ReadString('Client', 'CurrentVersion', '0.0.0').Trim;
  InstallDirectory := ExcludeTrailingPathDelimiter(FIni.ReadString('Install',
    'Directory', ExtractFilePath(ParamStr(0))));
  EntryPoint := FIni.ReadString('Install', 'EntryPoint',
    'ServidorGooPedir.exe').Trim;
  Processes := FIni.ReadString('Install', 'Processes', EntryPoint).Split([';'],
    TStringSplitOptions.ExcludeEmpty);
  CloseTimeoutSeconds := FIni.ReadInteger('Install', 'CloseTimeoutSeconds', 30);
  ResultFile := '';
  ErrorFile := '';
  ReleaseId := '';
  BackupExe := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Backup.exe');
  DbHost := FIni.ReadString('Database', 'Host',
    FIni.ReadString('Backup', 'Host', '')).Trim;
  DbPort := FIni.ReadInteger('Database', 'Port',
    FIni.ReadInteger('Backup', 'Port', 5432));
  DbUser := FIni.ReadString('Database', 'User',
    FIni.ReadString('Backup', 'User', '')).Trim;
  DbPassword := FIni.ReadString('Database', 'Password',
    FIni.ReadString('Backup', 'Password', ''));
  DbName := FIni.ReadString('Database', 'Database',
    FIni.ReadString('Backup', 'Database', '')).Trim;
end;

destructor TUpdaterConfig.Destroy;
begin
  FIni.Free;
  inherited;
end;

procedure TUpdaterConfig.ApplyArguments(Arguments: TUpdaterArguments);
var
  TextValue: string;
begin
  if Arguments.HasValue('baseurl') then BaseUrl := Arguments.Value('baseurl').Trim.TrimRight(['/']);
  if Arguments.HasValue('token') then Token := Arguments.Value('token').Trim;
  if Arguments.HasValue('empresa') then Company := Arguments.Value('empresa').Trim;
  if Arguments.HasValue('empresanome') then
    CompanyName := Arguments.Value('empresanome').Trim;
  if Arguments.HasValue('empresadocumento') then
    CompanyDocument := Arguments.Value('empresadocumento').Trim;
  if Arguments.HasValue('estacao') then Terminal := Arguments.Value('estacao').Trim;
  if Arguments.HasValue('produto') then ProductCode := Arguments.Value('produto').Trim;
  if Arguments.HasValue('canal') then Channel := Arguments.Value('canal').Trim.ToLower;
  if Arguments.HasValue('versao') then CurrentVersion := Arguments.Value('versao').Trim;
  if Arguments.HasValue('releaseid') then ReleaseId := Arguments.Value('releaseid').Trim;
  if Arguments.HasValue('backupexe') then BackupExe := Arguments.Value('backupexe').Trim;
  if Arguments.HasValue('dbhost') then DbHost := Arguments.Value('dbhost').Trim;
  if Arguments.HasValue('dbusuario') then DbUser := Arguments.Value('dbusuario').Trim;
  if Arguments.HasValue('dbsenha') then DbPassword := Arguments.Value('dbsenha');
  if Arguments.HasValue('dbbanco') then DbName := Arguments.Value('dbbanco').Trim;
  if Arguments.HasValue('dbporta') then
  begin
    TextValue := Arguments.Value('dbporta');
    if not TryStrToInt(TextValue, DbPort) then
      raise EArgumentException.Create('dbporta invalida: ' + TextValue);
  end;
  if Arguments.HasValue('installdirectory') then
    InstallDirectory := ExcludeTrailingPathDelimiter(Arguments.Value('installdirectory').Trim);
  if Arguments.HasValue('entrypoint') then EntryPoint := Arguments.Value('entrypoint').Trim;
  if Arguments.HasValue('processos') then
    Processes := Arguments.Value('processos').Split([';'], TStringSplitOptions.ExcludeEmpty);
  if Arguments.HasValue('closetimeoutseconds') then
  begin
    TextValue := Arguments.Value('closetimeoutseconds');
    if not TryStrToInt(TextValue, CloseTimeoutSeconds) then
      raise EArgumentException.Create('closetimeoutseconds invalido: ' + TextValue);
  end;
  ResultFile := Arguments.Value('resultfile').Trim;
  ErrorFile := Arguments.Value('errorfile').Trim;
end;

procedure TUpdaterConfig.ValidateDatabase;
begin
  if DbHost = '' then raise EArgumentException.Create('Host do banco nao informado');
  if (DbPort < 1) or (DbPort > 65535) then
    raise EArgumentException.Create('Porta do banco invalida');
  if DbUser = '' then raise EArgumentException.Create('Usuario do banco nao informado');
  if DbPassword = '' then raise EArgumentException.Create('Senha do banco nao informada');
  if DbName = '' then raise EArgumentException.Create('Banco nao informado');
end;

procedure TUpdaterConfig.Validate;
begin
  if BaseUrl = '' then raise EArgumentException.Create('BaseUrl nao informada');
  if Token = '' then raise EArgumentException.Create('Token nao informado');
  if (Company = '') or SameText(Company, 'UUID-ESTAVEL-DO-CLIENTE') then
    raise EArgumentException.Create('Cliente/empresa nao informado');
  if CompanyName = '' then
    raise EArgumentException.Create('Nome do cliente/empresa nao informado');
  if CompanyDocument = '' then
    raise EArgumentException.Create('Documento do cliente/empresa nao informado');
  if (Terminal = '') or SameText(Terminal, 'UUID-ESTAVEL-DO-TERMINAL') then
    raise EArgumentException.Create('Terminal/estacao nao informado');
  if ProductCode = '' then raise EArgumentException.Create('Produto nao informado');
  if not SameText(Channel, 'production') and not SameText(Channel, 'beta') and
    not SameText(Channel, 'test') then
    raise EArgumentException.Create('Origem/canal invalido: ' + Channel);
  if CurrentVersion = '' then raise EArgumentException.Create('Versao atual nao informada');
  if CloseTimeoutSeconds < 1 then
    raise EArgumentException.Create('closetimeoutseconds deve ser maior que zero');
end;

end.
