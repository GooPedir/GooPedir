unit uLoginWindows;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Effects, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit;

type
  TfrmLoginWindows = class(TForm)
    layPrincipal: TLayout;
    Rectangle1: TRectangle;
    ShadowEffect1: TShadowEffect;
    Rectangle2: TRectangle;
    Label3: TLabel;
    ShadowEffect4: TShadowEffect;
    Layout1: TLayout;
    edtUsuario: TEdit;
    ShadowEffect2: TShadowEffect;
    Label2: TLabel;
    edtSenha: TEdit;
    ShadowEffect3: TShadowEffect;
    Label1: TLabel;
    recSair: TRectangle;
    Label4: TLabel;
    recLogin: TRectangle;
    Label5: TLabel;
    procedure recSairMouseEnter(Sender: TObject);
    procedure recSairMouseLeave(Sender: TObject);
    procedure recSairClick(Sender: TObject);
    procedure recLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edtUsuarioKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure edtSenhaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  Var
    Logado: Boolean;
    URL: String;
  end;

var
  frmLoginWindows: TfrmLoginWindows;

implementation

{$R *.fmx}

uses UnitLogin, uDM, uRequisicao, Funcoes;

procedure TfrmLoginWindows.edtSenhaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    recLoginClick(recLogin);

  end;
end;

procedure TfrmLoginWindows.edtUsuarioKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    edtSenha.SetFocus;

  end;
end;

procedure TfrmLoginWindows.FormCreate(Sender: TObject);
begin

  FrmLogin := TFrmLogin.Create(Application);

  if length(FrmLogin.GetHost) = 0 then
  begin

    FrmLogin.TabControl.TabIndex := 1;

    FrmLogin.Label1.Visible := False;
    FrmLogin.edtUsuario.Visible := False;
    FrmLogin.edtSenha.Visible := False;
    FrmLogin.Label6.Visible := False;
    FrmLogin.WIN := True;
    FrmLogin.ShowModal;

  end;
  URL := 'http://' + FrmLogin.GetHost + ':2121/';

end;

procedure TfrmLoginWindows.FormShow(Sender: TObject);
begin
  edtUsuario.SetFocus;
end;

procedure TfrmLoginWindows.recLoginClick(Sender: TObject);
begin

  // BaseURL := DM.GetHost;
  if not DM.GetSimples2('/v1/usuario/' + edtUsuario.Text + '/' + edtSenha.Text,
    DM.Usuario) then
  begin
    ShowMessageToast(self, 'Sem conexão com servidor!', 1);
    exit;
  end;

  if DM.Usuario.RecordCount = 0 then
  begin
    ShowMessageToast(self, 'Usuário/Senha Invalido!', 1);
    exit;
  end;
  FrmLogin.Senha := edtSenha.Text;
  FrmLogin.Usuario := edtUsuario.Text;
  Logado := True;
  Close;
end;

procedure TfrmLoginWindows.recSairClick(Sender: TObject);
begin
  Logado := False;
  Close;
end;

procedure TfrmLoginWindows.recSairMouseEnter(Sender: TObject);
begin
  (Sender as TRectangle).Opacity := 1;
end;

procedure TfrmLoginWindows.recSairMouseLeave(Sender: TObject);
begin
  (Sender as TRectangle).Opacity := 0.8;
end;

end.
