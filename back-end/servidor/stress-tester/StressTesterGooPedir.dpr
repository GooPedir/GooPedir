program StressTesterGooPedir;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  uStressTesterMain in 'uStressTesterMain.pas',
  Horse in '..\src\other\Horse.pas',
  Horse.Commons in '..\src\other\Horse.Commons.pas',
  Horse.Constants in '..\src\other\Horse.Constants.pas',
  Horse.Core in '..\src\other\Horse.Core.pas',
  Horse.Core.Group in '..\src\other\Horse.Core.Group.pas',
  Horse.Core.Group.Contract in '..\src\other\Horse.Core.Group.Contract.pas',
  Horse.Core.Route in '..\src\other\Horse.Core.Route.pas',
  Horse.Core.Route.Contract in '..\src\other\Horse.Core.Route.Contract.pas',
  Horse.Core.RouterTree in '..\src\other\Horse.Core.RouterTree.pas',
  Horse.Exception in '..\src\other\Horse.Exception.pas',
  Horse.HTTP in '..\src\other\Horse.HTTP.pas',
  Horse.Proc in '..\src\other\Horse.Proc.pas',
  Horse.Provider.Abstract in '..\src\other\Horse.Provider.Abstract.pas',
  Horse.Provider.Console in '..\src\other\Horse.Provider.Console.pas',
  Horse.Provider.Daemon in '..\src\other\Horse.Provider.Daemon.pas',
  Horse.Provider.ISAPI in '..\src\other\Horse.Provider.ISAPI.pas',
  Horse.Provider.Apache in '..\src\other\Horse.Provider.Apache.pas',
  Horse.Provider.CGI in '..\src\other\Horse.Provider.CGI.pas',
  Horse.Provider.VCL in '..\src\other\Horse.Provider.VCL.pas',
  Horse.WebModule in '..\src\other\Horse.WebModule.pas' {HorseWebModule: TWebModule};

begin
  try
    RunStressTester;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Readln;
    end;
  end;
end.
