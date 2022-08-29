unit uGravaConversaMemoria;

interface

uses uBotConversa;

Type

  TGravaConversaMemoria = class
  private
    Conversas: Array of TBotConversa;

    procedure SetGravaConversa(const Value: TBotConversa);
  public
    constructor Create;

    property GravaConversa: TBotConversa write SetGravaConversa;

    function LocalizaConversa(Conversa:TBotConversa):TBotConversa;

  end;

implementation

{ TGravaConversaMemoria }

constructor TGravaConversaMemoria.Create;
begin
  SetLength(Conversas, 0);
end;

function TGravaConversaMemoria.LocalizaConversa(
  Conversa: TBotConversa): TBotConversa;
  var
   I: Integer;
begin
   for I := 0 to length(Conversas) - 1 do
  begin
    Result := Conversas[I];
    break;
  end;
  Result := nil;
end;

procedure TGravaConversaMemoria.SetGravaConversa(const Value: TBotConversa);
var
  I: Integer;
  Achou: Boolean;
begin
  Achou := False;
  for I := 0 to length(Conversas) - 1 do
  begin
    Achou := True;
    break;
  end;

  if not Achou then
  begin
    I := Length(Conversas);
    SetLength(Conversas,I+1);
  end;

  Conversas[I] :=Value;
end;

end.
