unit Produto;

interface

procedure Registry;

var
  Count: Integer;

implementation

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, JSON, token.autorizacao,
  DataSet.Serialize, FireDAC.Comp.Client, util, uDM, Horse.OctetStream,
  System.Classes;

procedure GetProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  // LStream: TFileStream;
  StringN: String;
  I: Integer;
  StN: String;
begin

  // StringN :=
  // 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
  // for I := 0 to 100000 do
  // begin
  // StN := StN + StringN;
  // end;
  // Res.Send(StN);
  // LStream := TFileStream.Create('D:\Projetos\Demos\servidor-backend\txt.txt', fmOpenRead);
  // Res.Send<TStream>(LStream);
  // inc(Count);
  Res.Send<TJSONArray>(GetGenerico('FICHAPROD', '', ''));
  // Write(IntToStr(Count));
end;

procedure GetDescarte(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONArray>(GetGenerico('MENSAGEM', '', ''));
end;

procedure Registry;
begin
  THorse.Use(OctetStream);

  THorse.get('/produtos', GetProduto);

  THorse.get('/descarte', GetDescarte);

end;

end.
