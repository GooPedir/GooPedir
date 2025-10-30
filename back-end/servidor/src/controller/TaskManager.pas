unit TaskManager;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Threading;

type
  TTaskProc = reference to procedure;

  TTaskManager = class
  private
    class var FRegistry: TDictionary<string, TTaskProc>;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure RegisterTask(const AName: string; AProc: TTaskProc);
    class procedure Run(const AName: string);
  end;

implementation

uses
  System.Classes, Vcl.Dialogs;

{ TTaskManager }

class constructor TTaskManager.Create;
begin
  FRegistry := TDictionary<string, TTaskProc>.Create;
end;

class destructor TTaskManager.Destroy;
begin
  FRegistry.Free;
end;

class procedure TTaskManager.RegisterTask(const AName: string;
  AProc: TTaskProc);
begin
  FRegistry.AddOrSetValue(AName.ToLower, AProc);
end;

class procedure TTaskManager.Run(const AName: string);
var
  TaskProc: TTaskProc;
begin
  if not FRegistry.TryGetValue(AName.ToLower, TaskProc) then
    raise Exception.CreateFmt('Task "%s" não encontrada.', [AName]);

  TTask.Run(
    procedure
    begin
      try
        TaskProc();
      except
        // Writeln('Erro ao executar task %s: %s', [AName, E.Message]);
      end;
    end);
end;

end.
