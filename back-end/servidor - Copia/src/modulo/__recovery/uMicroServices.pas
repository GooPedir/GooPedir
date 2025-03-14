unit uMicroServices;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, DateUtils, PedidoSite,
  System.Threading, uControllCaches, uLogThread, uMain;

procedure Registry;
procedure DoGetGerenciador(Req: THorseRequest; Res: THorseResponse; Next: TProc);


implementation

procedure Registry;
begin
  THorse.Get('/microservices/gerenciador', DoGetGerenciador);
end;

procedure DoGetGerenciador(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
JSonObject : TJSONObject;
begin
JSonObject := TJSONObject.Create;

if frmServidor.Configuracoes.FieldByName('a_impressora').AsInteger = 1 then
JSonObject.AddPair('service_impressao',true)
else
JSonObject.AddPair('service_impressao',false);

if frmServidor.Configuracoes.FieldByName('nfce').AsInteger = 1 then
JSonObject.AddPair('service_nfce',true)
else
JSonObject.AddPair('service_nfce',false);



JSonObject.AddPair('caminho_impressao',frmServidor.IMPRESSAO);
JSonObject.AddPair('caminho_nfce',frmServidor.USANFCE);
JSonObject.AddPair('caminho_site',frmServidor.SITE(NomeExeSite));




end;

end.
