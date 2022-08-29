unit util;

interface

uses uMemTable, System.UITypes,
  System.Classes, FMX.Toast, Data.DB, FMX.Grid, FMX.Types, System.JSON;

procedure ShowMessageToast(Form: TFmxObject; Mensage: String; Tipo: integer);
function ArquivoParaJSON(pDirArquivo: string): String;
function FormataNome(sNome: String): string;

implementation

uses uMain, System.SysUtils;

procedure ShowMessageToast(Form: TFmxObject; Mensage: String; Tipo: integer);
begin
  Form := frmMain;
  case Tipo of
    1:
      begin
        TToast.New(Form).Error(Mensage);
      end;

    2:
      begin
        TToast.New(Form).Info(Mensage);
      end;
    3:
      begin
        TToast.New(Form).Success(Mensage);
      end;
    4:
      begin
        TToast.New(Form).Warning(Mensage);
      end
  else
    begin
      TToast.New(Form).Info(Mensage);
    end;
  end;
end;

function ArquivoParaJSON(pDirArquivo: string): String;
var
  sBytesArquivo, sNomeArquivo: string;
  oSSArquivoStream: TStringStream;
  iTamanhoArquivo, iCont: integer;
begin
  try
    // Result := TJSONArray.Create; // Instanciando o objeto JSON que conterá o arquivo serializado

    oSSArquivoStream := TStringStream.Create;
    // Instanciando o objeto stream que carregará o arquivo para memoria
    oSSArquivoStream.LoadFromFile(pDirArquivo);
    // Carregando o arquivo para memoria
    iTamanhoArquivo := oSSArquivoStream.Size; // pegando o tamanho do arquivo

    sBytesArquivo := '';

    // Fazendo um lanço no arquivo que está na memoria para pegar os bytes do mesmo
    for iCont := 0 to iTamanhoArquivo - 1 do
    begin
      // A medida que está fazendo o laço para pegar os bytes, os mesmos são jogados para
      // uma variável do tipo string separado por ","
      sBytesArquivo := sBytesArquivo +
        IntToStr(oSSArquivoStream.Bytes[iCont]) + ', ';
    end;

    // Como é colocado uma vírgula após o byte, fica sempre sobrando uma vígugula, que é deletada
    Delete(sBytesArquivo, Length(sBytesArquivo) - 1, 2);

    // Adiciona a string que contém os bytes para o array JSON
    // Result.Add(sBytesArquivo);

    // Adiciona para o array JSON o tamanho do arquivo
    // Result.AddElement(TJSONNumber.Create(iTamanhoArquivo));

    // Extrai o nome do arquivo
    sNomeArquivo := ExtractFileName(pDirArquivo);

    // Adiciona na terceira posição do array JSON o nome do arquivo
    // Result.AddElement(TJSONString.Create(sNomeArquivo));

    Result := '{"byte":"' + sBytesArquivo + '","size":' + iTamanhoArquivo
      .ToString + ',"arquivo":"' + sNomeArquivo + '"}'
  finally
    oSSArquivoStream.Free;
  end;
end;

function FormataNome(sNome: String): string;
const
  excecao: array[0..5] of string = (' da ', ' de ', ' do ', ' das ', ' dos ', ' e ');
var
  tamanho, j: integer;
  i: byte;
begin
  Result := AnsiLowerCase(sNome);
  tamanho := Length(Result);

  for j := 1 to tamanho do
    // Se é a primeira letra ou se o caracter anterior é um espaço
    if (j = 1) or ((j>1) and (Result[j-1]=Chr(32))) then
      Result[j] := AnsiUpperCase(Result[j])[1];
  for i := 0 to Length(excecao)-1 do
    result:= StringReplace(result,excecao[i],excecao[i],[rfReplaceAll, rfIgnoreCase]);
end;

end.
