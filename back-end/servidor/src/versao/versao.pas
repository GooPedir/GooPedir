unit versao;

interface

procedure Registry;

implementation

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, JSON, token.autorizacao,
  DataSet.Serialize, FireDAC.Comp.Client, util, uDM;


procedure PostVersao(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
 InsertGenerico(Req.Body, 'versao', 'id');
end;

procedure Registry;
begin
  // Cadastra Versão
  THorse.Post('/versao', Authorization(), PostVersao);
end;

end.
