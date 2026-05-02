unit uGenericaFuncion;

interface

uses System.SysUtils, Conexao;

function RemoveAcento(const pText: string): string;
function GetParametro(nome: String): string;
procedure PostParametro(nome: String; valor :Variant);

implementation

function RemoveAcento(const pText: string): string;
const
  ComAcento = '‡‚ÍÙ˚„ı·ÈÌÛ˙Á¸Ò˝¿¬ ‘€√’¡…Õ”⁄«‹—›';
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

function GetParametro(nome: String): string;
var
  Conexao: Tconexao;
begin
  Conexao := Tconexao.Create('GetParametro');
  Conexao.SQL.Add('select * from configuracoes where chave = :chave');
  Conexao.Parametros('chave', nome);
  try
    Result := Conexao.FieldByName('valor');
  except

  end;

  Conexao.Free;

end;

procedure PostParametro(nome: String; valor :Variant);
begin

end;

end.
