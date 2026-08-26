unit uUpdaterArgs;

interface

uses System.SysUtils, System.Generics.Collections;

type
  TUpdaterMode = (umNone, umCheck, umUpdate);

  TUpdaterArguments = class
  private
    FMode: TUpdaterMode;
    FValues: TDictionary<string, string>;
    function NormalizeName(const Name: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function HasValue(const Name: string): Boolean;
    function Value(const Name: string; const Default: string = ''): string;
    property Mode: TUpdaterMode read FMode;
  end;

implementation

function RemoveOuterQuotes(const Value: string): string;
begin
  Result := Value;
  if (Length(Result) >= 2) and (Result[1] = '"') and
    (Result[Length(Result)] = '"') then
    Result := Result.Substring(1, Result.Length - 2);
end;

constructor TUpdaterArguments.Create;
var
  I, Separator: Integer;
  Argument, Name, ArgumentValue: string;
begin
  inherited Create;
  FValues := TDictionary<string, string>.Create;
  FMode := umNone;
  for I := 1 to ParamCount do
  begin
    Argument := ParamStr(I).Trim;
    if (Argument = '') or not CharInSet(Argument[1], ['/', '-']) then Continue;
    Argument := Argument.Substring(1);
    if SameText(Argument, 'consultar') then
    begin
      if FMode <> umNone then
        raise EArgumentException.Create('Informe somente um modo de execucao');
      FMode := umCheck;
      Continue;
    end;
    if SameText(Argument, 'atualizar') then
    begin
      if FMode <> umNone then
        raise EArgumentException.Create('Informe somente um modo de execucao');
      FMode := umUpdate;
      Continue;
    end;
    Separator := Argument.IndexOf('=');
    if Separator < 1 then
      raise EArgumentException.Create('Parametro invalido: ' + ParamStr(I));
    Name := NormalizeName(Argument.Substring(0, Separator));
    ArgumentValue := RemoveOuterQuotes(Argument.Substring(Separator + 1));
    FValues.AddOrSetValue(Name, ArgumentValue);
  end;
  if FMode = umNone then
    raise EArgumentException.Create('Informe /consultar ou /atualizar');
end;

destructor TUpdaterArguments.Destroy;
begin
  FValues.Free;
  inherited;
end;

function TUpdaterArguments.NormalizeName(const Name: string): string;
begin
  Result := Name.Trim.ToLower;
  if Result = 'cliente' then Result := 'empresa';
  if Result = 'terminal' then Result := 'estacao';
  if Result = 'origem' then Result := 'canal';
end;

function TUpdaterArguments.HasValue(const Name: string): Boolean;
begin
  Result := FValues.ContainsKey(NormalizeName(Name));
end;

function TUpdaterArguments.Value(const Name, Default: string): string;
begin
  if not FValues.TryGetValue(NormalizeName(Name), Result) then Result := Default;
end;

end.
