unit uCproduto;

interface

procedure Registry;

implementation

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, JSON, token.autorizacao,
  DataSet.Serialize, FireDAC.Comp.Client, util, uDM;


procedure GetProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONArray>(GetGenerico('FICHAPROD', '', ''));
end;

procedure Registry;
begin

THorse.get('/produtos', GetProduto);

end;

end.

