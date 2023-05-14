unit uLoginNovo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Ani,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  System.IOUtils;

type
  TFrmLoginNovo = class(TForm)
    layoutCircle: TLayout;
    circle: TCircle;
    AnimationCircle: TFloatAnimation;
    layoutLogin: TLayout;
    layoutLoginTexto: TLayout;
    layoutLoginCampos: TLayout;
    layoutNovo: TLayout;
    btnCriarConta: TRoundRect;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    layoutConta: TLayout;
    layoutContaCampos: TLayout;
    layoutContaTexto: TLayout;
    Layout6: TLayout;
    recLoginClick: TRoundRect;
    Label9: TLabel;
    Label10: TLabel;
    rUsuario: TRoundRect;
    rSenha: TRoundRect;
    Layout4: TLayout;
    Label7: TLabel;
    imgLogin: TImage;
    edtUsuario: TEdit;
    StyleBook1: TStyleBook;
    edtSenha: TEdit;
    Label4: TLabel;
    lStatus: TLabel;
    tFoco: TTimer;
    procedure AnimationCircleFinish(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCriarContaClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure recLoginClickClick(Sender: TObject);
    procedure edtUsuarioKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure edtSenhaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure tFocoTimer(Sender: TObject);
    procedure edtUsuarioEnter(Sender: TObject);
    procedure edtUsuarioExit(Sender: TObject);
    procedure edtSenhaExit(Sender: TObject);
    procedure edtSenhaEnter(Sender: TObject);
  private
    procedure PosicionaObjetos;
    procedure Animar;
    function Servidor: String;
    { Private declarations }
  public
    { Public declarations }
  Var
    Logado: Boolean;
    URL: String;
  end;

var
  FrmLoginNovo: TFrmLoginNovo;

implementation

{$R *.fmx}

uses uDM, UnitLogin, uRequisicao, util, FMXTee.Canvas;

procedure TFrmLoginNovo.Animar;
begin
  TAnimator.AnimateFloat(layoutLogin, 'Opacity', 0, 0.5);
  TAnimator.AnimateFloat(layoutConta, 'Opacity', 0, 0.5);
  AnimationCircle.Start;
end;

procedure TFrmLoginNovo.AnimationCircleFinish(Sender: TObject);
begin
  layoutLogin.Visible := false;
  layoutConta.Visible := false;

  if AnimationCircle.Inverse then
  begin
    layoutLogin.Visible := true;
    TAnimator.AnimateFloat(layoutLogin, 'Opacity', 1, 0.5);
  end
  else
  begin
    layoutConta.Visible := true;
    TAnimator.AnimateFloat(layoutConta, 'Opacity', 1, 0.5);
  end;

  AnimationCircle.Inverse := NOT AnimationCircle.Inverse;
end;

procedure TFrmLoginNovo.btnCriarContaClick(Sender: TObject);
begin
  Animar;
end;

procedure TFrmLoginNovo.edtSenhaEnter(Sender: TObject);
begin
rSenha.Fill.Color := recLoginClick.Fill.Color;
rSenha.Stroke.Color := recLoginClick.Fill.Color;
end;

procedure TFrmLoginNovo.edtSenhaExit(Sender: TObject);
begin
rSenha.Fill.Color := RGB(234,234,234);
rSenha.Stroke.Color := RGB(234,234,234);
end;

procedure TFrmLoginNovo.edtSenhaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    recLoginClickClick(recLoginClick);

  end;
end;

procedure TFrmLoginNovo.edtUsuarioEnter(Sender: TObject);
begin
rUsuario.Fill.Color := recLoginClick.Fill.Color;
rUsuario.Stroke.Color := recLoginClick.Fill.Color;
end;

procedure TFrmLoginNovo.edtUsuarioExit(Sender: TObject);
begin
rUsuario.Fill.Color := RGB(234,234,234);
rUsuario.Stroke.Color := RGB(234,234,234);
end;

procedure TFrmLoginNovo.edtUsuarioKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    edtSenha.SetFocus;

  end;
end;

procedure TFrmLoginNovo.FormCreate(Sender: TObject);
begin
  FrmLogin := TFrmLogin.Create(Application);

  if length(FrmLogin.GetHost) = 0 then
  begin

    FrmLogin.TabControl.TabIndex := 1;

    FrmLogin.Label1.Visible := false;
    FrmLogin.edtUsuario.Visible := false;
    FrmLogin.edtSenha.Visible := false;
    FrmLogin.Label6.Visible := false;
    FrmLogin.WIN := true;
    FrmLogin.ShowModal;

  end;
  URL := 'http://' + FrmLogin.GetHost + ':2121/';
  DM.CONEXAO.BaseURL := URL;
  edtUsuario.SetFocus;
end;

procedure TFrmLoginNovo.FormResize(Sender: TObject);
begin
  PosicionaObjetos;
end;

procedure TFrmLoginNovo.FormShow(Sender: TObject);
begin
  AnimationCircle.Inverse := false;
  Animar;
end;

procedure TFrmLoginNovo.PosicionaObjetos;
begin
  // Paisagem...
  if layoutCircle.Width >= layoutCircle.Height then
  begin
    circle.Width := layoutCircle.Width * 1.5;
    circle.Height := circle.Width;
    circle.Margins.Bottom := circle.Width * 0.30;

    AnimationCircle.PropertyName := 'Margins.Right';
    AnimationCircle.StartValue := circle.Width;
    AnimationCircle.StopValue := -circle.Width;

    if NOT AnimationCircle.Inverse then
      circle.Margins.Right := AnimationCircle.StartValue
    else
      circle.Margins.Right := AnimationCircle.StopValue;

    layoutLoginTexto.Align := TAlignLayout.Left;
    layoutLoginTexto.Width := layoutCircle.Width / 2;

    layoutLoginCampos.Width := layoutCircle.Width / 2;
    layoutLoginCampos.Align := TAlignLayout.Right;

    layoutContaTexto.Align := TAlignLayout.Right;
    layoutContaTexto.Width := layoutCircle.Width / 2;

    layoutContaCampos.Width := layoutCircle.Width / 2;
    layoutContaCampos.Align := TAlignLayout.Left;

    imgLogin.Height := layoutCircle.Height * 0.40;
    // imgConta.Height := layoutCircle.Height * 0.40;

    imgLogin.Visible := true;
    // imgConta.Visible := true;
  end
  else
  // Retrato...
  begin
    circle.Height := layoutCircle.Height * 1.5;
    circle.Width := circle.Height;
    circle.Margins.Right := 0;

    AnimationCircle.PropertyName := 'Margins.Bottom';
    AnimationCircle.StartValue := circle.Width * 1.20;
    AnimationCircle.StopValue := -circle.Width * 1.20;

    if NOT AnimationCircle.Inverse then
      circle.Margins.Bottom := circle.Width * 1.20
    else
      circle.Margins.Bottom := -circle.Width * 1.20;

    layoutLoginTexto.Align := TAlignLayout.Top;
    layoutLoginTexto.Height := 200;

    layoutLoginCampos.Align := TAlignLayout.Client;

    layoutContaTexto.Align := TAlignLayout.Bottom;
    layoutContaTexto.Height := 200;

    layoutContaCampos.Align := TAlignLayout.Client;

    imgLogin.Visible := false;
    // imgConta.Visible := false;
  end;

end;

procedure TFrmLoginNovo.recLoginClickClick(Sender: TObject);
begin
  // Valida se é o servidor
  if UpperCase(DM.GetHost) = 'HTTP://LOCALHOST:2121/' then
  begin

    if FileExists(Servidor) then
    begin
//      ShowMessage(Servidor);
    end;
  end;

  lStatus.Text := '';
  DM.CONEXAO.BaseURL := DM.GetHost;
  DM.CONEXAO.URL := '/v1/usuario/' + edtUsuario.Text + '/' + edtSenha.Text;
  DM.CONEXAO.Metodo := mGet;
  DM.CONEXAO.MemTable2 := DM.Usuario;
  DM.CONEXAO.TempoExpiracao := (5*1000) * 30;
  try
    DM.CONEXAO.Execute;
  except
    lStatus.Text := 'Sem conexão com o servidor!';

    exit;
  end;

  if DM.Usuario.RecordCount = 0 then
  begin
    lStatus.Text := 'Usuário/Senha Invalido!';

    exit;
  end;
  FrmLogin.Senha := edtSenha.Text;
  FrmLogin.Usuario := edtUsuario.Text;
  Logado := true;
  Close;
end;

function TFrmLoginNovo.Servidor: String;
begin
  Result := ExtractFileDir(ParamStr(0)) + '\ServidorGooPedir.exe';
end;

procedure TFrmLoginNovo.tFocoTimer(Sender: TObject);
begin
tFoco.Enabled := False;
edtUsuario.SetFocus;
end;

end.
