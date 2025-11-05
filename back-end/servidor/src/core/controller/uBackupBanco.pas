unit uBackupBanco;

interface

uses
  conexao, Winapi.Windows,DataSet.Serialize, FireDAC.Comp.Client, Vcl.Dialogs, System.SysUtils,
  IdHTTP, IdSSLOpenSSL, FireDAC.Stan.Error,
  System.IniFiles;

type
  TBackupBanco = class
  var
  NomeArquivoBackup : String;
  function GetMySQLDumpPath: string;
  function FileSizeByName(const FileName: string): Int64;
  public
    procedure Iniciar;
  end;

implementation



{ TBackupBanco }

function TBackupBanco.FileSizeByName(const FileName: string): Int64;
var
  sr: TSearchRec;
begin
  if FindFirst(FileName, faAnyFile, sr) = 0 then
    Result := sr.Size
  else
    Result := 0;
  FindClose(sr);
end;

function TBackupBanco.GetMySQLDumpPath: string;
const
  // Possíveis locais do mysqldump.exe
  PossiblePaths: array [0 .. 3] of string =
    ('C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe',
    'C:\Program Files\MySQL\MySQL Server 5.7\bin\mysqldump.exe',
    'C:\Program Files (x86)\MySQL\MySQL Server 8.0\bin\mysqldump.exe',
    'C:\Program Files (x86)\MySQL\MySQL Server 5.7\bin\mysqldump.exe');
var
  i: Integer;
begin
  Result := '';
  for i := Low(PossiblePaths) to High(PossiblePaths) do
  begin
    if FileExists(PossiblePaths[i]) then
    begin
      Result := PossiblePaths[i];
      exit;
    end;
  end;

  // Como fallback, tenta buscar no PATH do sistema
  Result := 'mysqldump.exe'; // O sistema tentará achar se estiver no PATH
end;
procedure TBackupBanco.Iniciar;
var
  MySQLDumpPath, PastaBackup, CmdLine: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  ExitCode: DWORD;
  conexao : TConexao;
begin

  conexao := TConexao.Create('bkpBanco');
  PastaBackup := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) +
    'backup\bd');
  ForceDirectories(PastaBackup);
  NomeArquivoBackup := Format('%s%s_%s.sql', [PastaBackup, conexao.NomeBanco,
    FormatDateTime('yyyymmdd', now) // evita colisão/overwrite
    ]);

  if FileExists(NomeArquivoBackup) then
  begin
//    tBackupFTP.Enabled := True;
    exit;
  end;

  MySQLDumpPath := GetMySQLDumpPath;
  // ex.: C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe
  if (MySQLDumpPath = '') or (not FileExists(MySQLDumpPath)) then
  begin
    ShowMessage('mysqldump.exe não encontrado.');
    exit;
  end;

  // IMPORTANTE:
  // - sem redirecionamento ">"
  // - grava direto com --result-file
  // - flags para bases grandes e InnoDB
  // - GTID OFF evita barulho quando não precisa de replicação
  // - hex-blob garante binários seguros
  CmdLine := '"' + MySQLDumpPath + '"' + ' -h' + conexao.Servidor + ' -P' +
    (conexao.Porta) + ' -u' + conexao.Usuario + ' -p' + conexao.Senha +
  // se a senha tiver caracteres especiais, considere usar --defaults-file (ver nota abaixo)
    ' --databases ' + conexao.NomeBanco +
    ' --single-transaction --quick --hex-blob' +
    ' --routines --events --triggers' + ' --set-gtid-purged=OFF' +
    ' --default-character-set=utf8mb4' + ' --max-allowed-packet=512M' +
    ' --result-file="' + NomeArquivoBackup + '"';

  ZeroMemory(@SI, SizeOf(SI));
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE;

  ZeroMemory(@PI, SizeOf(PI));

  if not CreateProcess(nil, PChar(CmdLine), nil, nil, false, CREATE_NO_WINDOW,
    nil, nil, SI, PI) then
    exit;

  try
    WaitForSingleObject(PI.hProcess, INFINITE);
    if GetExitCodeProcess(PI.hProcess, ExitCode) then
    begin
      // mysqldump retorna 0 em sucesso
      if (ExitCode = 0) and FileExists(NomeArquivoBackup) and
        (FileSizeByName(NomeArquivoBackup) > 0) then
      begin
//        Result := True;
        // tBackupFTP.Enabled := True;
      end
      else
      begin
        // dica: logue ExitCode e gere um .log com stderr (ver seção “Logs”, abaixo)
        // ShowMessage(Format('mysqldump falhou. ExitCode=%d', [ExitCode]));
      end;
    end;
  finally
    CloseHandle(PI.hThread);
    CloseHandle(PI.hProcess);
  end;
end;

end.
