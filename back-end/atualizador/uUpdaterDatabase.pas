unit uUpdaterDatabase;

interface

uses uUpdaterConfig;

procedure ExecuteSqlPackage(const Config: TUpdaterConfig;
  const SqlFileName: string);

implementation

uses System.SysUtils, System.IOUtils, FireDAC.Comp.Client,
  FireDAC.Comp.Script, FireDAC.Comp.ScriptCommands,
  FireDAC.Stan.Def, FireDAC.Stan.Intf,
  FireDAC.Phys, FireDAC.Phys.PG, FireDAC.Phys.PGDef;

procedure ExecuteSqlPackage(const Config: TUpdaterConfig;
  const SqlFileName: string);
var
  Connection: TFDConnection;
  Script: TFDScript;
  SqlText: string;
begin
  if not TFile.Exists(SqlFileName) then
    raise Exception.Create('Arquivo SQL nao encontrado: ' + SqlFileName);

  SqlText := TFile.ReadAllText(SqlFileName, TEncoding.UTF8).Trim;
  if SqlText = '' then
    raise Exception.Create('O pacote SQL esta vazio');

  Connection := TFDConnection.Create(nil);
  Script := TFDScript.Create(nil);
  try
    Connection.LoginPrompt := False;
    Connection.Params.Clear;
    Connection.Params.Values['DriverID'] := 'PG';
    Connection.Params.Values['Server'] := Config.DbHost;
    Connection.Params.Values['Port'] := Config.DbPort.ToString;
    Connection.Params.Values['Database'] := Config.DbName;
    Connection.Params.Values['User_Name'] := Config.DbUser;
    Connection.Params.Values['Password'] := Config.DbPassword;
    Connection.Connected := True;

    Script.Connection := Connection;
    Script.SQLScripts.Add.SQL.Text := SqlText;
    Connection.StartTransaction;
    try
      Script.ValidateAll;
      Script.ExecuteAll;
      Connection.Commit;
    except
      if Connection.InTransaction then
        Connection.Rollback;
      raise;
    end;
  finally
    Script.Free;
    Connection.Free;
  end;
end;

end.
