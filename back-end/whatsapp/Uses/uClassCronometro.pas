unit uClassCronometro;

interface

uses System.Classes, FireDAC.Comp.Client, SysUtils;

type
  TCronometro = class(TThread)
  private
  var
    TimeOld: TDateTime;
    INICIO: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

  end;

implementation

uses uPrincipal;

{ TCronometro }

constructor TCronometro.Create;
begin
  inherited Create(True);
  TimeOld := Now;
  INICIO := StrToDateTime('00:00:00');
end;

destructor TCronometro.Destroy;
begin

  inherited;
end;

procedure TCronometro.Execute;
begin
  inherited;

  while not Finished do
  begin
    dmPrincipal.Caption := 'PapaLéguas Food - Whatsapp ' + FormatDateTime('HH:MM:SS',
      INICIO + Now - TimeOld);;
    Sleep(1000);
  end;

end;

end.
