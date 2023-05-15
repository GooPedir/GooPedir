unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl, FMX.Layouts,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uMemTable, uRequisicao,
  FMX.Objects;

type
  TConexaoServidor = class(TThread)
  private
    FStatus: Boolean;
    FStatusAnterior: Boolean;
    procedure SetStatus(const Value: Boolean);
    procedure SetStatusAnterior(const Value: Boolean);

  protected
    procedure Execute; override;
    property Status: Boolean read FStatus write SetStatus;
    property StatusAnterior: Boolean read FStatusAnterior
      write SetStatusAnterior;

  var
    Conexao: iRequisicao;
  public
    constructor Create;
    destructor Destroy; override;

  var
    Iniciado: Boolean;
  end;

  TfrmMain = class(TForm)
    Layout1: TLayout;
    tabMain: TTabControl;
    FORM: iMemTable;
    FORMCLASSNAME: TStringField;
    FORMINDEX: TIntegerField;
    FORMTABINDEX: TIntegerField;
    StyleBook1: TStyleBook;
    rSemConexao: TRectangle;
    Label1: TLabel;
    layPedido: TLayout;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure FinalizouCarregamento;
  public
    { Public declarations }

    function GetParametros(NomeParametro: String): Variant;

    procedure AbrirForm(Nome: String);
    procedure AbrirFormVisivel(Nome: String; Visible: Boolean);
    function FormsName(Nome: String): String;

    procedure OpenClose;

  var
    Usuario: String;
    Senha: String;
    URL: String;

  end;

var
  frmMain: TfrmMain;
  fActiveForm: array of TForm;

implementation

{$R *.fmx}

uses uPedido, uProduto, uCategoria, uTaxaEntrega, uDM, uMotoboy,
  uDashBoard, UnitAddItem, UnitResumo;

procedure TfrmMain.AbrirForm(Nome: String);
begin
  AbrirFormVisivel(Nome, True);
end;

procedure TfrmMain.AbrirFormVisivel(Nome: String; Visible: Boolean);
var
  Index: Integer;
  aForm: TComponentClass;

  NomeTab: String;
  NomeLayout: String;
  Layout: TComponent;

  NewTab: TTabItem;
begin

  NomeTab := 'Tab' + Nome;
  NomeLayout := 'Layout' + NomeTab;

  if FORM.Locate('CLASSNAME', Nome, []) then
  begin
    if Nome <> 'TfrmCaixa' then
      tabMain.TabIndex := FORM.FieldByName('TABINDEX').AsInteger;
    Index := FORM.FieldByName('INDEX').AsInteger;

    try
      NewTab := tabMain.FindComponent(NomeTab) as TTabItem;

      if NewTab.Visible then
      begin
        if Nome <> 'TfrmCaixa' then
          tabMain.TabIndex := 0;
        NewTab.Visible := False;
        exit;

      end
      else
      begin

        NewTab.Visible := True;
        if not Visible then
        begin
          if Nome <> 'TfrmCaixa' then
            tabMain.TabIndex := NewTab.Index;
        end;
      end;
    except

    end;

  end
  else
  begin
    SetLength(fActiveForm, length(fActiveForm) + 1);
    Index := length(fActiveForm) - 1;

    aForm := TComponentClass(FindClass(Nome));

    Application.CreateForm(aForm, fActiveForm[Index]);

    try
      TLabel(fActiveForm[Index].FindComponent('lNomeForm')).text :=
        FormsName(Nome);
    except

    end;

    NewTab := TTabItem.Create(tabMain);
    NewTab.Name := NomeTab;
    NewTab.Visible := Visible;

    NewTab.text := FormsName(Nome);
    NewTab.Parent := tabMain;

    Layout := TLayout.Create(Self);

    (Layout as TLayout).Name := NomeLayout;
    (Layout as TLayout).Align := tabMain.Align;
    (Layout as TLayout).Parent := NewTab;

    (Layout as TLayout).AddObject
      (TLayout(fActiveForm[Index].FindComponent('layClient')));

    FORM.Insert;
    FORM.FieldByName('CLASSNAME').AsString := Nome;
    FORM.FieldByName('INDEX').AsInteger := Index;
    FORM.FieldByName('TABINDEX').AsInteger := tabMain.TabCount - 1;
    FORM.Post;
    if Nome <> 'TfrmCaixa' then
      tabMain.TabIndex := tabMain.TabCount - 1;

  end;
  if Assigned(fActiveForm[Index].OnActivate) then
    fActiveForm[Index].OnActivate(nil);
end;

procedure TfrmMain.FinalizouCarregamento;
begin
  // AbrirForm('TfrmPedido');
  AbrirForm('TfrmMesas');
  AbrirForm('TfrmProduto');
  if dm.ControleEstoque = 1 then
  begin
    AbrirForm('TfrmEstoque');
  end;
  AbrirFormVisivel('TfrmCaixa', False);
  tabMain.TabIndex := 0;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin

  dm.LogUsuario;

  dm.UserId;
  tabMain.TabIndex := 0;
  // TThread.CreateAnonymousThread(
  // procedure
  // begin
  // frmMain.Caption := frmMain.Caption + dm.GetNomeEmpresa;
  // DM.IniciaVerificacao;

  // Thread.Sleep(5000);
  // TThread.Synchronize(TThread.CurrentThread,
  // procedure
  // begin
  // Memo1.Lines.Add('Teste anonymous Thread');
  // end);
  // end).Start;

  if NOT Assigned(FrmAddItem) then
  begin
    Application.CreateForm(TFrmAddItem, FrmAddItem);
    FrmAddItem.ExecutarQuandoCarregaProdutos := FinalizouCarregamento;
    FrmAddItem.Load;
  end;

  AbrirForm('TfrmDashBoard');

  FrmResumo := TFrmResumo.Create(Self);

  layPedido.AddObject(TLayout(FrmResumo.FindComponent('layClient')));

end;

function TfrmMain.FormsName(Nome: String): String;
begin

  if Nome = 'TfrmEstoque' then
  begin
    Result := 'Estoque';
    exit;
  end;

  if Nome = 'TfrmCupom' then
  begin
    Result := 'Cupom de Desconto Site';
    exit;
  end;

  if Nome = 'TfrmCliente' then
  begin
    Result := 'Cliente';
    exit;
  end;

  if Nome = 'TfrmTipoPagamento' then
  begin
    Result := 'Pagamento';
    exit;
  end;

  if Nome = 'TfrmRelatorioVendas' then
  begin
    Result := 'Relatórios';
    exit;
  end;

  if Nome = 'TfrmImpressora' then
  begin
    Result := 'Impressoras';
    exit;
  end;

  if Nome = 'TfrmParametros' then
  begin
    Result := 'Parâmetros';
    exit;
  end;

  if Nome = 'TfrmCadastroMesas' then
  begin
    Result := 'Cadastro Salão';
    exit;
  end;
  if Nome = 'TfrmDashBoard' then
  begin
    Result := 'Inicio';
    exit;
  end;

  if Nome = 'TfrmMesas' then
  begin
    Result := 'Salão';
    exit;
  end;

  if Nome = 'TfrmMotoboy' then
  begin
    Result := 'Motoboy';
    exit;
  end;

  if Nome = 'TfrmTaxaEntrega' then
  begin
    Result := 'Taxa de Entrega';
    exit;
  end;

  if Nome = 'TfrmCategoria' then
  begin
    Result := 'Categorias';
    exit;
  end;

  if Nome = 'TfrmPedido' then
  begin
    Result := 'Pedidos';
    exit;
  end;

  if Nome = 'TfrmProduto' then
  begin
    Result := 'Produtos';
    exit;
  end;

  if Nome = 'TfrmCaixa' then
  begin
    Result := 'Caixa';
    exit;
  end;

  if Nome = 'TfrmIngredientesProduto' then
  begin
    Result := 'Ingredientes';
    exit;
  end;

end;

function TfrmMain.GetParametros(NomeParametro: String): Variant;
begin

  if dm.PARAMETRO.RecordCount = 0 then
  begin
    dm.GetSimples2('/v1/consulta/todos/dados_whatsapp', dm.PARAMETRO);
  end;

  try
    Result := dm.PARAMETRO.FieldByName(NomeParametro).AsVariant;
  except

  end;

end;

procedure TfrmMain.OpenClose;
begin
  if layPedido.Visible then
  begin
    layPedido.Visible := False;
    Layout1.Visible := True;
  end
  else
  begin
    FrmResumo.LoadMain;
    layPedido.Visible := True;
    Layout1.Visible := False;
  end;

end;

{ TConexaoServidor }

constructor TConexaoServidor.Create;
begin
end;

destructor TConexaoServidor.Destroy;
begin

  inherited;
end;

procedure TConexaoServidor.Execute;
begin
  inherited;

  while not Terminated do
  begin
    Status := dm.GetSimples('v1/versao/app', nil);

    if Status then
      Sleep(1500)
    else
      Sleep(5000);

  end;
end;

procedure TConexaoServidor.SetStatus(const Value: Boolean);
begin
  FStatus := Value;

  // if StatusAnterior <> Status then
  // begin
  // StatusAnterior := Value;
  // if not Value then
  // begin
  // try
  // TLoading.Show(frmMain, 'Sem Conexão Com o Servidor, Aguarde...')
  // except
  //
  // end;
  // end
  // else
  // begin
  // try
  // TLoading.Hide;
  // except
  //
  // end;
  // end;
  // end;
  //
  // exit;
  // if StatusAnterior <> Value then
  // begin
  //
  // StatusAnterior := Value;
  // if not Value then
  // begin
  // try
  // TLoading.Show(frmMain, 'Sem Conexão Com o Servidor, Aguarde...')
  // except
  // end;
  // end
  // else
  // begin
  //
  // try
  // TLoading.Hide;
  // except
  // end;
  // ShowMessageToast('Conexão com o servidor restabelecida', 2);
  // end;
  //
  // end;
end;

procedure TConexaoServidor.SetStatusAnterior(const Value: Boolean);
begin
  FStatusAnterior := Value;
end;

end.
