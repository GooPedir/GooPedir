unit uWhatsTravado;

interface

uses System.Classes, SysUtils, FireDAC.Comp.Client,IniFiles;

type

  TWhatsTravado = class(TThread)
  private
    FTempo: Integer;
     ArquivoINI: TIniFile;
    FCaminho: String;
    procedure SetTempo(const Value: Integer);
    procedure SetCaminho(const Value: String);
  protected
    procedure Execute; override;

  public
    constructor Create;
    destructor Destroy; override;

    property Tempo: Integer read FTempo write SetTempo;
    property Caminho : String read FCaminho write SetCaminho;
  end;

implementation

{ TWhatsTravado }

uses uDM;

constructor TWhatsTravado.Create;
begin
  inherited Create(True);


end;

destructor TWhatsTravado.Destroy;
begin

  inherited;
end;

procedure TWhatsTravado.Execute;
begin
  inherited;

  while not Terminated do
  begin

    Sleep(FTempo);
  end;

end;

procedure TWhatsTravado.SetCaminho(const Value: String);
begin
  FCaminho := Value;
end;

procedure TWhatsTravado.SetTempo(const Value: Integer);
begin
  FTempo := Value * 1000;
end;

end.
