unit uCodigoPedidoDia;

interface

function ProximoCodigoPedidoDia: Integer;
procedure InicializarCodigoPedidoDia(const ValorInicial: Integer);

implementation

uses
  System.SyncObjs;

var
  FCodigoPedido: Integer = 0;
  FCritical: TCriticalSection;

procedure InicializarCodigoPedidoDia(const ValorInicial: Integer);
begin
  FCritical.Enter;
  try
    FCodigoPedido := ValorInicial;
  finally
    FCritical.Leave;
  end;
end;

function ProximoCodigoPedidoDia: Integer;
begin
  FCritical.Enter;
  try
    Inc(FCodigoPedido);
    Result := FCodigoPedido;
  finally
    FCritical.Leave;
  end;
end;

initialization

FCritical := TCriticalSection.Create;

finalization

FCritical.Free;

end.
