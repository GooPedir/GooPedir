program Atualizador;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  uAtualizadorCore in 'uAtualizadorCore.pas',
  uUpdaterArgs in 'uUpdaterArgs.pas',
  uUpdaterResult in 'uUpdaterResult.pas',
  uUpdaterState in 'uUpdaterState.pas',
  uUpdaterPackage in 'uUpdaterPackage.pas',
  uUpdaterDatabase in 'uUpdaterDatabase.pas',
  uUpdaterConsole in 'uUpdaterConsole.pas',
  uUpdaterConfig in 'uUpdaterConfig.pas',
  uUpdaterHttp in 'uUpdaterHttp.pas',
  uUpdaterFiles in 'uUpdaterFiles.pas',
  uUpdaterModels in 'uUpdaterModels.pas';

begin
  try
    with TAtualizadorApp.Create do
    try
      ExitCode := Executar;
    finally
      Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := ATU_ERRO_CRITICO;
    end;
  end;
end.
