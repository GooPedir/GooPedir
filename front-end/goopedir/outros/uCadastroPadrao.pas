unit uCadastroPadrao;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.TabControl, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Effects;

type
  TfrmCadastroBase = class(TForm)
    layClient: TLayout;
    Rectangle1: TRectangle;
    tabPrincipal: TTabControl;
    tabConsulta: TTabItem;
    TabDados: TTabItem;
    Image1: TImage;
    lNomeForm: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    rAdicionar: TRectangle;
    Label1: TLabel;
    ShadowEffect1: TShadowEffect;
    rAlterar: TRectangle;
    Label2: TLabel;
    ShadowEffect2: TShadowEffect;
    rAtivarDesativar: TRectangle;
    lTipoAtivo: TLabel;
    ShadowEffect3: TShadowEffect;
    rSalvar: TRectangle;
    Layout21: TLayout;
    Image3: TImage;
    Label7: TLabel;
    procedure rAdicionarMouseEnter(Sender: TObject);
    procedure rAdicionarMouseLeave(Sender: TObject);
    procedure Image1Click(Sender: TObject);
  private
    { Private declarations }
    procedure SimVoltar;
  public
    { Public declarations }
  end;

var
  frmCadastroBase: TfrmCadastroBase;

implementation

{$R *.fmx}

uses uSimNao, uMain;

procedure TfrmCadastroBase.Image1Click(Sender: TObject);
begin
  case tabPrincipal.TabIndex of
    0:
      begin
        frmMain.AbrirForm('T'+Self.Name);
      end
  else
    begin
       frmSimNao.titulo := 'Confirmação';
        frmSimNao.Descricao := 'Deseja voltar?';
        frmSimNao.Sim := SimVoltar;
        frmSimNao.Show;
        exit;
    end;
  end;
end;

procedure TfrmCadastroBase.rAdicionarMouseEnter(Sender: TObject);
begin
  (Sender as TRectangle).Opacity := 1;
end;

procedure TfrmCadastroBase.rAdicionarMouseLeave(Sender: TObject);
begin
  (Sender as TRectangle).Opacity := 0.5;
end;

procedure TfrmCadastroBase.SimVoltar;
begin
tabPrincipal.TabIndex := tabPrincipal.TabIndex -1;
end;

end.
