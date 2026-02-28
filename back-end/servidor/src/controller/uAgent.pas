unit uAgent;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.DateUtils;

type
  TAgentSession = class
  public
    Codigo: string;
    Nome: string;
    Status: Integer;
    UltimaAtividade: TDateTime;
  end;

  TAgentManager = class
  private
  class var
    FInstance: TAgentManager;
    FAgents: TObjectDictionary<string, TAgentSession>;
    constructor CreatePrivate;
  public
    class function Instance: TAgentManager;

    procedure AddOrUpdate(const ACodigo: string);
    function Get(const ACodigo: string): TAgentSession;
    procedure SetStatus(const ACodigo: string; AStatus: Integer);
    procedure Remove(const ACodigo: string);
    procedure ClearExpired(AMinutos: Integer);
  end;

implementation

{ TAgentManager }

procedure TAgentManager.AddOrUpdate(const ACodigo: string);
var
  Agent: TAgentSession;
begin
  if not FAgents.TryGetValue(ACodigo, Agent) then
  begin
    Agent := TAgentSession.Create;
    Agent.Codigo := ACodigo;
    FAgents.Add(ACodigo, Agent);
  end;

  Agent.UltimaAtividade := Now;
end;


procedure TAgentManager.ClearExpired(AMinutos: Integer);
var
  Key: string;
  Agent: TAgentSession;
  ListaRemover: TList<string>;
begin
  ListaRemover := TList<string>.Create;
  try
    for Key in FAgents.Keys do
    begin
      Agent := FAgents.Items[Key];
      if MinutesBetween(Now, Agent.UltimaAtividade) > AMinutos then
        ListaRemover.Add(Key);
    end;

    for Key in ListaRemover do
      FAgents.Remove(Key);
  finally
    ListaRemover.Free;
  end;
end;

constructor TAgentManager.CreatePrivate;
begin
 FAgents := TObjectDictionary<string, TAgentSession>.Create([doOwnsValues]);
end;

function TAgentManager.Get(const ACodigo: string): TAgentSession;
begin
  if FAgents.TryGetValue(ACodigo, Result) then
    Result.UltimaAtividade := Now
  else
    Result := nil;
end;

class function TAgentManager.Instance: TAgentManager;
begin
   if not Assigned(FInstance) then
    FInstance := TAgentManager.CreatePrivate;

  Result := FInstance;
end;

procedure TAgentManager.Remove(const ACodigo: string);
begin
 FAgents.Remove(ACodigo);
end;

procedure TAgentManager.SetStatus(const ACodigo: string; AStatus: Integer);
var
  Agent: TAgentSession;
begin
  if FAgents.TryGetValue(ACodigo, Agent) then
  begin
    Agent.Status := AStatus;
    Agent.UltimaAtividade := Now;
  end;
end;

end.
