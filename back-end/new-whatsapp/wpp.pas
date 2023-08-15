unit wpp;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, JSON,
  Data.DB, DataSet.Serialize, EncdDecd, Horse.BasicAuthentication,
  System.Classes, Horse.Commons, System.NetEncoding, DateUtils;

procedure Registry;

implementation

uses uMain;


procedure DoGetTest(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
 JSonObject : TJSONObject;
begin
  JSonObject := TJSONObject.Create;
  JSonObject.AddPair('status',frmMain.Status);
  JSonObject.AddPair('celular',frmMain.Numero);
  JSonObject.AddPair('base64',frmMain.Base64);

 res.Send<TJSONObject>(JSonObject);
end;

procedure DoPostDesconectar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  frmMain.Close;
end;

procedure DoPostVisualizar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  frmMain.ExibirWhatsapp;
end;



procedure Registry;
begin
  THorse.get('/whatsapp/goopedir/data', DoGetTest);
  THorse.post('/whatsapp/goopedir/desconectar', DoPostDesconectar);
  THorse.post('/whatsapp/goopedir/visualizar', DoPostVisualizar);
end;

end.
