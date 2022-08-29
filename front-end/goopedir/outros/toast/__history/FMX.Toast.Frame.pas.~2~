unit FMX.Toast.Frame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Objects, FMX.Effects,
  FMX.Layouts;

type
  TFrameToast = class(TFrame)
    retContent: TRectangle;
    retLine: TRectangle;
    imgIcon: TPath;
    lytText: TLayout;
    txtTitle: TText;
    txtMessage: TText;
    lytClose: TLayout;
    imgClose: TPath;
    sdwContent: TShadowEffect;
    lytIcon: TLayout;
    procedure retContentClick(Sender: TObject);
  private
    FOnClose: TProc;
  public
    property OnClose: TProc read FOnClose write FOnClose;
  end;

implementation

{$R *.fmx}

procedure TFrameToast.retContentClick(Sender: TObject);
begin
  Self.Visible := False;
  if Assigned(FOnClose) then
    FOnClose;
end;

end.
