unit util.backup;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect;

procedure Registry;

implementation

procedure DoBackupStart(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
//Faz o backup

end;

procedure Registry;
begin
  //
  THorse.Get('/v1/backup/start', DoBackupStart);
end;

end.
