unit rota;

interface

uses Math, Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  uCacheControl, FireDAC.Comp.Client, Dataset.Serialize, JSON,
  token.autorizacao, Web.HTTPApp, System.Diagnostics,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, DateUtils, PedidoSite,
  System.Threading, uControllCaches, System.Generics.Collections,
  uNewConsultas, uControllerSite, GooPedirAPIController, uAtualizacaoSite,
  System.IOUtils, uGlobais, conexao, Xml.XMLDoc, Xml.XMLIntf,
  uControlerProdutoNotaFiscal;

procedure Registry;

implementation

uses uMain;

procedure DoGetHeart(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('OK');
end;

procedure DoGetRotaPendente(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send<TJSONObject>(frmServidor.APIGoopedir.GetRotas);
end;

procedure DoGetMotboy(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONObject>(frmServidor.APIGoopedir.GetMotoboy);
end;

procedure DoPostRotaNova(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONObject>(frmServidor.APIGoopedir.PostRotas(Req.Body));
end;

procedure DoPutInicia(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONObject>(frmServidor.APIGoopedir.PutInicia(Req.Params['id']));
end;

procedure DoPutFinalizar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONObject>(frmServidor.APIGoopedir.PutFinalizar(Req.Params['id']));
end;

procedure DoPostMokup(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send(frmServidor.APIGoopedir.PostApi('api/empresa/pedidos/mockup','{ "quantidade": 5 }'));
end;

procedure DoPostAtivaPausa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send(frmServidor.APIGoopedir.PostApi('api/empresa/gerar_rotas',
    '{ "valor": ' + Req.Params['status'] + ' }'));
end;

procedure DoGetMotoboy(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('DoGetMotoboy');

  conexao.SQL.Add('update motoboy set acesso_site = SHA2(concat(' +
    frmServidor.UserID.ToString +
    ',"-",id_site), 256) where acesso_site is null');

  conexao.ExecuteSQL;
  conexao.SQL.Add('select * from motoboy');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;


procedure DoPostBuscarNovoEndereco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
 Res.Send(frmServidor.APIGoopedir.PostApi('api/localizacao/endereco',req.Body));
end;

procedure DoPostEnviarLocalizacao(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send(frmServidor.APIGoopedir.PostApi('api/whatsapp/pedido/'+Req.Params['id']+'/solicitar-localizacao-fixa',''));
end;

procedure DoPostAtualizarLocalizacao(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send(frmServidor.APIGoopedir.PostApi('api/localizacao/endereco',req.Body));
end;



procedure Registry;
begin
  THorse.Get('/rota/pendente', DoGetRotaPendente);
  THorse.Get('/rota/motoboy', DoGetMotboy);
  THorse.Post('/rota/nova', DoPostRotaNova);
  THorse.Put('/rota/iniciar/:id', DoPutInicia);
  THorse.Put('/rota/finalizar/:id', DoPutFinalizar);
  THorse.Post('/rota/mokup', DoPostMokup);
  THorse.Post('/rota/ativa/pausa/:status', DoPostAtivaPausa);
  THorse.Post('/rota/nova/localizacao', DoPostBuscarNovoEndereco);
  THorse.Post('/rota/pedir/localizacao/:id', DoPostEnviarLocalizacao);
  THorse.Post('/rota/confirmar/localizacao', DoPostAtualizarLocalizacao);
  THorse.Get('/motoboy', DoGetMotoboy);

end;

end.
