unit uImageLocal;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.NetEncoding,
  System.JSON;

  function SalvarImagemBase64TabletJSON(const Base64Original: string): TJSONObject;

implementation

function SalvarImagemBase64TabletJSON(const Base64Original: string): TJSONObject;
var
  Base64   : string;
  Bytes    : TBytes;
  FileName : string;
  FilePath : string;
  Pasta    : string;
begin
  Base64 := Base64Original;

  // Remove prefixo data:image/...;base64,
  if Base64.Contains(',') then
    Base64 := Base64.Substring(Base64.IndexOf(',') + 1);

  Bytes := TNetEncoding.Base64.DecodeStringToBytes(Base64);

  Pasta := 'C:\goopedir\tablet\imagens\';
  ForceDirectories(Pasta);

  FileName := TGUID.NewGuid.ToString
                .Replace('{', '')
                .Replace('}', '') + '.png';

  FilePath := Pasta + FileName;

  TFile.WriteAllBytes(FilePath, Bytes);

  Result := TJSONObject.Create;
  Result.AddPair('arquivo', FileName);
  Result.AddPair('url', '/tablet/imagens/' + FileName);
end;


end.
