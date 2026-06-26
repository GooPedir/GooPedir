unit uMicroServices;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, DateUtils, PedidoSite,
  System.Threading, uControllCaches, uMain;

procedure Registry;
procedure DoGetGerenciador(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

implementation

procedure Registry;
begin
  THorse.Get('/microservices/gerenciador', DoGetGerenciador);
end;

procedure DoGetGerenciador(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  JSonObject: TJSONObject;
begin
  JSonObject := TJSONObject.Create;

  JSonObject.AddPair('service_impressao', true);

  JSonObject.AddPair('service_nfce', true);

end;

end.
