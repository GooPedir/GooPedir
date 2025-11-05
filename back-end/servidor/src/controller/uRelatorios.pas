unit uRelatorios;

interface


uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, DateUtils, PedidoSite,
  System.Threading, uControllCaches, System.Generics.Collections,
  uNewConsultas, uControllerSite, GooPedirAPIController, uAtualizacaoSite,
  System.IOUtils, uGlobais, conexao;

function getDadosPedidos(Data : TDate): TJsonArray;

implementation

function getDadosPedidos(Data : TDate): TJsonArray;
var
conexao : TConexao;
begin
conexao := TConexao.Create('getDadosPedidos');

end;

end.
