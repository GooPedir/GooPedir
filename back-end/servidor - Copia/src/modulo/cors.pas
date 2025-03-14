unit cors;

interface

uses
  Horse, Horse.Commons;

procedure ConfigurarCORS(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

procedure ConfigurarCORS(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  // Define cabeçalhos CORS
  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Origin', '*');
  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Credentials', 'true');
  // Verifica se a requisição é um preflight CORS (OPTIONS)
  if Req.RawWebRequest.Method = 'OPTIONS' then
  begin
    Res.Status(THTTPStatus.NoContent).Send('');  // Retorna 204 No Content
    raise EHorseCallbackInterrupted.Create;       // Interrompe o processamento
  end;
  // Continua para o próximo middleware ou rota se não for OPTIONS
  Next;
end;

end.
