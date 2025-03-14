unit uInserirUpdate;

interface

uses JOSE.Core.Builder, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, SysUtils, IOUtils,
  System.Variants, conexao, uCacheControl, uControllCaches;

function InserirUpdate(tabela, User: String;
  ArrayCampos, ArrayValores: Array of String): Integer;

implementation

function InserirUpdate(tabela, User: String;
  ArrayCampos, ArrayValores: Array of String): Integer;

var
  Inserir: Boolean;

  Campos: String;
  Parametros: String;
  I: Integer;

  SQL: String;

  Montado: String;
  Requisicao: iRequisicao;
  Valor: String;

begin

  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := 'https://ws.goopedir.com/v1/';

  Requisicao.URL := 'insert/' + tabela + '/' + User + '/a';
  Montado := '';

  for I := 0 to length(ArrayCampos) - 1 do
  begin
    Valor := ArrayValores[I];

    try
      strtofloat(Valor);
      Valor := StringReplace(Valor, ',', '.', [rfReplaceAll]);
    except

    end;

    if I = 0 then
    begin
      Montado := '"' + ArrayCampos[I] + '":"' + Valor + '"';
    end
    else
    begin
      Montado := Montado + ',"' + ArrayCampos[I] + '":"' + Valor + '"';
    end;
  end;
  Montado := '{' + Montado + '}';
  Montado := StringReplace(Montado, '#$A', '', [rfReplaceAll]);
  Montado := StringReplace(Montado, #$A, '', [rfReplaceAll]);
  Montado := StringReplace(Montado, #$D, '', [rfReplaceAll]);

  Requisicao.Body(Montado);

  Requisicao.Metodo := mPost;
  try
    Requisicao.TempoExpiracao := 15 * 1000;
    Requisicao.Execute;

    Result := StrToInt(Requisicao.retorno);

  except
    Result := 0;

  end;
  Requisicao.Free;
end;

end.
