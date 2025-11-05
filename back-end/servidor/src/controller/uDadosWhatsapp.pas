unit uDadosWhatsapp;

interface

uses
  System.Classes, System.SysUtils;

type
  TDadosWhatsappAPI = class(TThread)
  private
    FProcedure: TProc;
    FInterval: Cardinal; // Intervalo em milissegundos
  protected
    procedure Execute; override;
  public
    constructor Create(AProcedure: TProc; AInterval: Cardinal); reintroduce;
  end;

implementation

{ TDadosWhatsappAPI }

constructor TDadosWhatsappAPI.Create(AProcedure: TProc; AInterval: Cardinal);
begin
  inherited Create(True); 
  FProcedure := AProcedure;
  FInterval := AInterval;
  FreeOnTerminate := True; // Libera automaticamente a memória ao encerrar
  Resume;
end;

procedure TDadosWhatsappAPI.Execute;
begin

  while not Terminated do
  begin

    if Assigned(FProcedure) then
      try
        FProcedure;
      except
        on E: Exception do
        begin
        end;
      end;
    Sleep(FInterval); // Aguarda o intervalo definido
    Terminate;
  end;
end;

end.
