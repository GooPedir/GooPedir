unit uUpdaterConsole;

interface

procedure ConsoleInitialize(const LogFile: string);
procedure ConsoleSetVersion(const Version: string);
procedure ConsoleSetState(const State: string);
procedure ConsoleDownloadProgress(TotalBytes, ReadBytes: Int64);
procedure ConsoleDetail(const Text: string);
procedure ConsoleFinish(Success: Boolean; const Text: string);

implementation

uses System.SysUtils, System.Math, System.StrUtils, Winapi.Windows;

const
  INNER_WIDTH = 62;
  BAR_WIDTH = 34;

var
  OutputHandle: THandle;
  CurrentState: string;
  CurrentVersion: string;
  CurrentDetail: string;
  CurrentLogFile: string;
  DownloadTotal: Int64;
  DownloadRead: Int64;
  DownloadStartedAt: UInt64;
  Initialized: Boolean;

function Fit(const Text: string): string;
var
  Value: string;
begin
  Value := Text.Replace(#13, ' ').Replace(#10, ' ');
  if Length(Value) > INNER_WIDTH then
    Value := Copy(Value, 1, INNER_WIDTH - 3) + '...';
  Result := Value + StringOfChar(' ', INNER_WIDTH - Length(Value));
end;

function UC(Code: Word): string;
begin
  Result := WideChar(Code);
end;

procedure WriteWide(const Text: string);
var
  Written: Cardinal;
begin
  WriteConsoleW(OutputHandle, PWideChar(Text), Length(Text), Written, nil);
end;

function HumanBytes(Value: Int64): string;
const
  UNITS: array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
var
  Number: Double;
  Index: Integer;
begin
  Number := Value;
  Index := 0;
  while (Number >= 1024) and (Index < High(UNITS)) do
  begin
    Number := Number / 1024;
    Inc(Index);
  end;
  if Index = 0 then Result := Format('%.0f %s', [Number, UNITS[Index]])
  else Result := Format('%.1f %s', [Number, UNITS[Index]]);
end;

function StateOrder(const State: string): Integer;
begin
  if MatchText(State, ['checking']) then Exit(0);
  if MatchText(State, ['downloading', 'ready']) then Exit(1);
  if MatchText(State, ['waiting_processes']) then Exit(2);
  if MatchText(State, ['preparing', 'installing', 'prepared', 'validating']) then Exit(3);
  if MatchText(State, ['completed']) then Exit(5);
  Result := 0;
end;

function StepSymbol(Index: Integer): string;
var
  Order: Integer;
begin
  Order := StateOrder(CurrentState);
  if SameText(CurrentState, 'failed') then
  begin
    if Index = 0 then Exit(UC($00D7));
    Exit(UC($25CB));
  end;
  if Index < Order then Result := UC($2713)
  else if Index = Order then Result := UC($25CF)
  else Result := UC($25CB);
end;

function StateText: string;
begin
  if SameText(CurrentState, 'checking') then Exit('Verificando versao...');
  if SameText(CurrentState, 'downloading') then Exit('Baixando atualizacao...');
  if SameText(CurrentState, 'ready') then Exit('Download concluido');
  if SameText(CurrentState, 'waiting_processes') then Exit('Aguardando o fechamento do servidor...');
  if SameText(CurrentState, 'preparing') then Exit('Preparando atualizacao...');
  if SameText(CurrentState, 'preparing') then Exit('Preparando atualizacao...');
  if SameText(CurrentState, 'installing') then Exit('Instalando atualizacao...');
  if SameText(CurrentState, 'validating') then Exit('Validando instalacao...');
  if SameText(CurrentState, 'completed') then Exit('Atualizacao concluida');
  if SameText(CurrentState, 'failed') then Exit('A atualizacao falhou');
  Result := 'Inicializando...';
end;

procedure Draw;
var
  Position: TCoord;
  ConsoleInfo: TConsoleScreenBufferInfo;
  I, Percent, Filled: Integer;
  Bar, Transfer, Target: string;
  ElapsedSeconds, Speed: Double;
begin
  if not Initialized then Exit;
  Position.X := 0;
  Position.Y := 0;
  SetConsoleCursorPosition(OutputHandle, Position);

  WriteWide(UC($250C) + DupeString(UC($2500), INNER_WIDTH) + UC($2510) + sLineBreak);
  WriteWide(UC($2502) + Fit('  Atualizador GooPedir') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('  ' + StateText) + UC($2502) + sLineBreak);
  if CurrentVersion <> '' then Target := '  Versao de destino: ' + CurrentVersion
  else Target := '  Consultando o servidor';
  WriteWide(UC($2502) + Fit(Target) + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('') + UC($2502) + sLineBreak);

  Percent := 0;
  if DownloadTotal > 0 then
    Percent := EnsureRange(Round(DownloadRead * 100 / DownloadTotal), 0, 100)
  else if StateOrder(CurrentState) > 1 then Percent := 100;
  Filled := Round(Percent * BAR_WIDTH / 100);
  Bar := DupeString(UC($2588), Filled) + DupeString(UC($2591), BAR_WIDTH - Filled);
  WriteWide(UC($2502) + Fit('  ' + Bar + Format('  %3d%%', [Percent])) + UC($2502) + sLineBreak);

  Transfer := '';
  if DownloadRead > 0 then
  begin
    ElapsedSeconds := Max(0.001, (GetTickCount64 - DownloadStartedAt) / 1000);
    Speed := DownloadRead / ElapsedSeconds;
    Transfer := '  ' + HumanBytes(DownloadRead);
    if DownloadTotal > 0 then Transfer := Transfer + ' de ' + HumanBytes(DownloadTotal);
    Transfer := Transfer + ' | ' + HumanBytes(Round(Speed)) + '/s';
  end;
  WriteWide(UC($2502) + Fit(Transfer) + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('') + UC($2502) + sLineBreak);

  WriteWide(UC($2502) + Fit('  ' + StepSymbol(0) + ' Verificando versao') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('  ' + StepSymbol(1) + ' Baixando pacote') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('  ' + StepSymbol(2) + ' Fechando processos') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('  ' + StepSymbol(3) + ' Instalando atualizacao') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('  ' + StepSymbol(4) + ' Reiniciando o sistema') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('') + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('  Detalhes: ' + CurrentDetail) + UC($2502) + sLineBreak);
  WriteWide(UC($2502) + Fit('  Log: ' + CurrentLogFile) + UC($2502) + sLineBreak);
  WriteWide(UC($2514) + DupeString(UC($2500), INNER_WIDTH) + UC($2518) + sLineBreak);

  if GetConsoleScreenBufferInfo(OutputHandle, ConsoleInfo) then
    for I := ConsoleInfo.dwCursorPosition.Y to 18 do
      WriteWide(StringOfChar(' ', INNER_WIDTH + 2) + sLineBreak);
end;

procedure ConsoleInitialize(const LogFile: string);
var
  CursorInfo: TConsoleCursorInfo;
  InputHandle: THandle;
  InputMode: Cardinal;
begin
  OutputHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  Initialized := OutputHandle <> INVALID_HANDLE_VALUE;
  if not Initialized then Exit;
  SetConsoleTitle('Atualizador GooPedir');
  SetConsoleOutputCP(CP_UTF8);
  { Quick Edit congela todo o processo quando o usuario clica no console e
    somente libera depois de Enter/Esc. O atualizador nunca deve pausar por
    selecao acidental de texto. }
  InputHandle := GetStdHandle(STD_INPUT_HANDLE);
  if (InputHandle <> INVALID_HANDLE_VALUE) and
     GetConsoleMode(InputHandle, InputMode) then
  begin
    InputMode := InputMode or ENABLE_EXTENDED_FLAGS;
    InputMode := InputMode and not ENABLE_QUICK_EDIT_MODE;
    SetConsoleMode(InputHandle, InputMode);
  end;
  CursorInfo.dwSize := 25;
  CursorInfo.bVisible := False;
  SetConsoleCursorInfo(OutputHandle, CursorInfo);
  CurrentLogFile := LogFile;
  CurrentState := 'initializing';
  CurrentDetail := 'Preparando componentes';
  DownloadStartedAt := GetTickCount64;
  Draw;
end;

procedure ConsoleSetVersion(const Version: string);
begin
  CurrentVersion := Version;
  Draw;
end;

procedure ConsoleSetState(const State: string);
begin
  CurrentState := State;
  if SameText(State, 'downloading') then
  begin
    DownloadRead := 0;
    DownloadTotal := 0;
    DownloadStartedAt := GetTickCount64;
  end;
  Draw;
end;

procedure ConsoleDownloadProgress(TotalBytes, ReadBytes: Int64);
begin
  DownloadTotal := TotalBytes;
  DownloadRead := ReadBytes;
  Draw;
end;

procedure ConsoleDetail(const Text: string);
begin
  CurrentDetail := Text;
  Draw;
end;

procedure ConsoleFinish(Success: Boolean; const Text: string);
begin
  if Success then CurrentState := 'completed' else CurrentState := 'failed';
  CurrentDetail := Text;
  Draw;
end;

end.
