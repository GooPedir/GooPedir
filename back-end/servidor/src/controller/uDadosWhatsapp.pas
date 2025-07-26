unit uDadosWhatsapp;

interface

uses
  System.Classes, System.SysUtils, uLogThread;

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
 inherited Create(True); // Cria a Thread1 suspensa
  FProcedure := AProcedure;
  FInterval := AInterval;
  FreeOnTerminate := True; // Libera automaticamente a memória ao encerrar
  Resume; // Inicia a Thread1
end;

procedure TDadosWhatsappAPI.Execute;
begin

  while not Terminated do
  begin
      LogThread('TDadosWhatsappAPI','Iniciando');
    if Assigned(FProcedure) then
      try
        FProcedure;
      except
        on E: Exception do
        begin

            LogThread('TDadosWhatsappAPI','Erro: '+E.message);
        end;
      end;
    Sleep(FInterval); // Aguarda o intervalo definido
    Terminate;
  end;
end;

end.
