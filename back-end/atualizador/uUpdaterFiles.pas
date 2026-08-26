unit uUpdaterFiles;

interface

uses System.SysUtils;

procedure EnsureEmptyDirectory(const Directory: string);
procedure CopyDirectory(const Source, Target: string; const Excluded: TArray<string>);
function FileSha256(const FileName: string): string;
procedure ExtractZipSafe(const ZipFile, TargetDirectory: string);
function IsZipFile(const FileName: string): Boolean;
function IsProcessRunning(const ExeName: string): Boolean;
procedure RequestProcessesClose(const Processes: TArray<string>;
  const InstallDirectory: string);
function WaitProcessesClosed(const Processes: TArray<string>;
  TimeoutSeconds: Integer; const InstallDirectory: string = ''): Boolean;
function RunningProcesses(const Processes: TArray<string>;
  const InstallDirectory: string = ''): string;

implementation

uses System.IOUtils, System.Hash, System.Zip, System.Classes, System.DateUtils,
  Winapi.Windows, Winapi.TlHelp32;

const
  WM_CLOSE_MESSAGE = $0010;
  PROCESS_QUERY_LIMITED_INFO = $1000;

function QueryFullProcessImageNameW(hProcess: THandle; dwFlags: DWORD;
  lpExeName: PWideChar; var lpdwSize: DWORD): BOOL; stdcall;
  external kernel32 name 'QueryFullProcessImageNameW';

function IsZipFile(const FileName: string): Boolean;
var
  Stream: TFileStream;
  Signature: array[0..3] of Byte;
begin
  Result := False;
  if not TFile.Exists(FileName) or (TFile.GetSize(FileName) < 4) then Exit;
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Read(Signature, SizeOf(Signature)) <> SizeOf(Signature) then Exit;
    Result := (Signature[0] = $50) and (Signature[1] = $4B) and
      (((Signature[2] = $03) and (Signature[3] = $04)) or
       ((Signature[2] = $05) and (Signature[3] = $06)) or
       ((Signature[2] = $07) and (Signature[3] = $08)));
  finally
    Stream.Free;
  end;
end;

procedure EnsureEmptyDirectory(const Directory: string);
begin
  if TDirectory.Exists(Directory) then TDirectory.Delete(Directory, True);
  TDirectory.CreateDirectory(Directory);
end;

function IsExcluded(const Path: string; const Excluded: TArray<string>): Boolean;
var Item: string;
begin
  Result := False;
  for Item in Excluded do
    if SameText(TPath.GetFileName(Path), Item) then Exit(True);
end;

procedure CopyDirectory(const Source, Target: string; const Excluded: TArray<string>);
var FileName, Directory: string;
begin
  TDirectory.CreateDirectory(Target);
  for FileName in TDirectory.GetFiles(Source) do
    if not IsExcluded(FileName, Excluded) then
      TFile.Copy(FileName, TPath.Combine(Target, TPath.GetFileName(FileName)), True);
  for Directory in TDirectory.GetDirectories(Source) do
    if not IsExcluded(Directory, Excluded) then
      CopyDirectory(Directory, TPath.Combine(Target, TPath.GetFileName(Directory)), Excluded);
end;

function FileSha256(const FileName: string): string;
var Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := THashSHA2.GetHashString(Stream, THashSHA2.TSHA2Version.SHA256).ToLower;
  finally
    Stream.Free;
  end;
end;

procedure ExtractZipSafe(const ZipFile, TargetDirectory: string);
var
  Zip: TZipFile;
  I: Integer;
  Name, Destination, Root: string;
begin
  Root := IncludeTrailingPathDelimiter(TPath.GetFullPath(TargetDirectory));
  Zip := TZipFile.Create;
  try
    Zip.Open(ZipFile, zmRead);
    for I := 0 to Zip.FileCount - 1 do
    begin
      Name := Zip.FileNames[I].Replace('/', PathDelim);
      Destination := TPath.GetFullPath(TPath.Combine(TargetDirectory, Name));
      if not Destination.StartsWith(Root, True) then
        raise Exception.Create('Pacote contem caminho inseguro: ' + Name);
    end;
    Zip.ExtractAll(TargetDirectory);
  finally
    Zip.Free;
  end;
end;

function IsProcessRunning(const ExeName: string): Boolean;
var Snapshot: THandle; Entry: TProcessEntry32;
begin
  Result := False;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then Exit;
  try
    Entry.dwSize := SizeOf(Entry);
    if Process32First(Snapshot, Entry) then
      repeat
        if SameText(Entry.szExeFile, ExeName) then Exit(True);
      until not Process32Next(Snapshot, Entry);
  finally
    CloseHandle(Snapshot);
  end;
end;

function CloseWindowForProcess(WindowHandle: HWND; ProcessId: LPARAM): BOOL; stdcall;
var
  WindowProcessId: Cardinal;
begin
  GetWindowThreadProcessId(WindowHandle, @WindowProcessId);
  if WindowProcessId = Cardinal(ProcessId) then
    PostMessage(WindowHandle, WM_CLOSE_MESSAGE, 0, 0);
  Result := True;
end;

function ProcessIsInDirectory(ProcessId: Cardinal;
  const InstallDirectory: string): Boolean;
var
  ProcessHandle: THandle;
  Buffer: array[0..32767] of Char;
  BufferLength: Cardinal;
  ProcessFile, ExpectedDirectory: string;
begin
  Result := False;
  ProcessHandle := OpenProcess(PROCESS_QUERY_LIMITED_INFO, False,
    ProcessId);
  if ProcessHandle = 0 then Exit;
  try
    BufferLength := Length(Buffer);
    if not QueryFullProcessImageNameW(ProcessHandle, 0, Buffer, BufferLength) then
      Exit;
    SetString(ProcessFile, Buffer, BufferLength);
    ExpectedDirectory := ExcludeTrailingPathDelimiter(
      TPath.GetFullPath(InstallDirectory));
    Result := SameText(ExcludeTrailingPathDelimiter(
      TPath.GetFullPath(ExtractFileDir(ProcessFile))), ExpectedDirectory);
  finally
    CloseHandle(ProcessHandle);
  end;
end;

procedure RequestProcessesClose(const Processes: TArray<string>;
  const InstallDirectory: string);
var
  Snapshot: THandle;
  Entry: TProcessEntry32;
  Item: string;
begin
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then Exit;
  try
    Entry.dwSize := SizeOf(Entry);
    if Process32First(Snapshot, Entry) then
      repeat
        for Item in Processes do
          if (Item.Trim <> '') and SameText(Entry.szExeFile, Item.Trim) and
             (Entry.th32ProcessID <> GetCurrentProcessId) and
             ProcessIsInDirectory(Entry.th32ProcessID, InstallDirectory) then
          begin
            EnumWindows(@CloseWindowForProcess, LPARAM(Entry.th32ProcessID));
            Break;
          end;
      until not Process32Next(Snapshot, Entry);
  finally
    CloseHandle(Snapshot);
  end;
end;

function WaitProcessesClosed(const Processes: TArray<string>;
  TimeoutSeconds: Integer; const InstallDirectory: string): Boolean;
var Deadline: TDateTime;
begin
  Deadline := Now + TimeoutSeconds / SecsPerDay;
  repeat
    if RunningProcesses(Processes, InstallDirectory) = '' then Exit(True);
    Sleep(500);
  until Now >= Deadline;
  Result := False;
end;

function RunningProcesses(const Processes: TArray<string>;
  const InstallDirectory: string): string;
var
  Snapshot: THandle;
  Entry: TProcessEntry32;
  Item: string;
begin
  Result := '';
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then Exit;
  try
    Entry.dwSize := SizeOf(Entry);
    if Process32First(Snapshot, Entry) then
      repeat
        for Item in Processes do
          if (Item.Trim <> '') and SameText(Entry.szExeFile, Item.Trim) and
             (Entry.th32ProcessID <> GetCurrentProcessId) and
             ((InstallDirectory = '') or ProcessIsInDirectory(
               Entry.th32ProcessID, InstallDirectory)) then
          begin
            if Result <> '' then Result := Result + ', ';
            Result := Result + Item.Trim;
            Break;
          end;
      until not Process32Next(Snapshot, Entry);
  finally
    CloseHandle(Snapshot);
  end;
end;

end.
