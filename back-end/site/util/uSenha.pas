unit uSenha;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmSenha = class(TForm)
    Label1: TLabel;
    edtSenha: TEdit;
    btnConfirmar: TButton;
    procedure btnConfirmarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Correta: Boolean;
  end;

var
  frmSenha: TfrmSenha;

implementation

{$R *.dfm}

procedure TfrmSenha.btnConfirmarClick(Sender: TObject);
begin
  Correta := edtSenha.Text = DateToStr(Date);
  if not Correta then
  begin
    ////showmessage('Senha Incorreta!');
    exit;
  end;
  Close;
end;

end.
