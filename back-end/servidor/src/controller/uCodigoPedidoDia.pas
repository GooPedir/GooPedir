unit uCodigoPedidoDia;

interface

function ProximoCodigoPedidoDia: Integer;
procedure InicializarCodigoPedidoDia(const ValorInicial: Integer);

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  System.DateUtils;

var
  FCodigoPedido: Integer = 0;
  FCritical: TCriticalSection;
  FReferenciaDia: TDateTime;

function DiaLogicoAtual: TDateTime;
var
  Agora: TDateTime;
begin
  Agora := Now;

  // Se ainda não chegou 05:00, pertence ao "dia anterior"
  if HourOf(Agora) < 5 then
    Result := StartOfTheDay(Agora - 1)
  else
    Result := StartOfTheDay(Agora);
end;

procedure InicializarCodigoPedidoDia(const ValorInicial: Integer);
begin
  FCritical.Enter;
  try
    FCodigoPedido := ValorInicial;
    FReferenciaDia := DiaLogicoAtual;
  finally
    FCritical.Leave;
  end;
end;

function ProximoCodigoPedidoDia: Integer;
var
  DiaAtual: TDateTime;
begin
  FCritical.Enter;
  try
    DiaAtual := DiaLogicoAtual;

    // Se mudou o dia lógico (passou das 05:00)
    if DiaAtual <> FReferenciaDia then
    begin
      FCodigoPedido := 0;
      FReferenciaDia := DiaAtual;
    end;

    Inc(FCodigoPedido);
    Result := FCodigoPedido;
  finally
    FCritical.Leave;
  end;
end;

initialization
  FCritical := TCriticalSection.Create;
  FReferenciaDia := DiaLogicoAtual;

finalization
  FCritical.Free;

end.
