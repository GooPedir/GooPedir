unit Controller;

interface

uses uDM, DateUtils;

type

  TController = class
  private
    FDM: Array of Tdm;
    FInicial: integer;
    FMax: integer;
    FMin: integer;
    procedure SetInicial(const Value: integer);
    procedure SetMax(const Value: integer);
    procedure SetMin(const Value: integer);
    procedure Limpa;
    function CriaDM: Tdm;
  public
    constructor Create;
    property Max: integer read FMax write SetMax;
    property Min: integer read FMin write SetMin;
    property Inicial: integer read FInicial write SetInicial;
    function DataModule: Tdm;
  end;

implementation

uses
  System.SysUtils;

{ TController }

constructor TController.Create;
begin
  SetLength(FDM, 0);
end;

function TController.CriaDM: Tdm;
begin
  Result := Tdm.Create(nil);
  Result.Hora := Time;
end;

function TController.DataModule: Tdm;
var
  I: integer;
  Achou: Boolean;
begin
  Achou := False;
  while not Achou do
  begin
    for I := 0 to length(FDM) - 1 do
    begin
      if not FDM[I].EmUso then
      begin
        Result := FDM[I];
        if Result = nil then
          Result := CriaDM;
        FDM[I].EmUso := True;
        FDM[I].Hora := Time;
        Achou := True;
        break;
      end;
    end;
    if Achou then
    begin
      Limpa;
      exit;
    end;
    if length(FDM) < FMax then
    begin
      SetLength(FDM, length(FDM) + 1);
      FDM[length(FDM) - 1] := Tdm.Create(nil);
    end;
    sleep(1000);
  end;

end;

procedure TController.Limpa;
var
  I: integer;
  Hora: TTime;
begin
  if FMin = 0 then
    exit;
  Hora := Time + 1;

  for I := length(FDM) - 1 downto FMin do
  begin
    if FDM[I] <> nil then
    begin
      if not FDM[I].EmUso then
      begin
        if Hora > IncMinute(FDM[I].Hora, 1) then
        begin
          FreeAndNil(FDM[I]);
        end;
      end;
    end;

  end;

end;

procedure TController.SetInicial(const Value: integer);
var
  I: integer;
begin
  FInicial := Value;
  SetLength(FDM, Value);

  for I := 0 to Value - 1 do
  begin
    FDM[I] := CriaDM;
  end;
end;

procedure TController.SetMax(const Value: integer);
begin
  FMax := Value;
end;

procedure TController.SetMin(const Value: integer);
begin
  FMin := Value;
end;

end.
