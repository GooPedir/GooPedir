unit uGenericaFuncion;

interface

uses System.SysUtils;

function RemoveAcento(const pText: string): string;

implementation

function RemoveAcento(const pText: string): string;
const
  ComAcento = 'àâêôûãõáéíóúçüñıÀÂÊÔÛÃÕÁÉÍÓÚÇÜÑİ';
  SemAcento = 'aaeouaoaeioucunyAAEOUAOAEIOUCUNY';
var
  x: Cardinal;
  aText: String;
begin;
  aText := pText;
  for x := 1 to length(aText) do
    try
      if (pos(aText[x], ComAcento) <> 0) then
        aText[x] := SemAcento[pos(aText[x], ComAcento)];
    except
      on E: Exception do
        raise Exception.Create('Erro no processo.');
    end;

  Result := aText;
end;

end.
