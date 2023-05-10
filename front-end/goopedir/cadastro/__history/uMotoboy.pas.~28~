unit uMotoboy;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uCadastroPadrao, FMX.Effects, FMX.Layouts, FMX.TabControl,
  FMX.Controls.Presentation, FMX.Objects, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, uMemTable, FMX.Edit, uEdit, System.Rtti, FMX.Grid.Style,
  FMX.ScrollBox, FMX.Grid, Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Bind.Grid,
  System.Bindings.Outputs, FMX.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.DBScope;

type
  TfrmMotoboy = class(TfrmCadastroBase)
    DADOS: iMemTable;
    DADOScodigo: TIntegerField;
    DADOSnome: TStringField;
    DADOSativo: TIntegerField;
    Layout1: TLayout;
    edtBairro: iEdit;
    Label3: TLabel;
    StringGrid4: TStringGrid;
    BDSDADOS: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBDSDADOS: TLinkGridToDataSource;
    DADOSacesso_site: TStringField;
    procedure rAlterarClick(Sender: TObject);
    procedure rSalvarClick(Sender: TObject);
    procedure rAdicionarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rAtivarDesativarClick(Sender: TObject);
  private
    { Private declarations }
    procedure GetDados;
  public
    { Public declarations }
  end;

var
  frmMotoboy: TfrmMotoboy;

implementation

{$R *.fmx}

uses uDM, util, uMain, System.JSON, uRequisicao;

{ TfrmMotoboy }

procedure TfrmMotoboy.FormCreate(Sender: TObject);
begin
  inherited;
  GetDados;
  tabPrincipal.TabIndex := 0;
  tabPrincipal.TabPosition := TTabPosition.None;
end;

procedure TfrmMotoboy.GetDados;
begin
  dm.GetSimples('/v1/consulta/todos/motoboy', DADOS);
end;

procedure TfrmMotoboy.rAdicionarClick(Sender: TObject);
begin
  inherited;
  if not DADOS.Active then
    DADOS.Open;

  DADOS.insert;
  DADOS.FieldByName('codigo').AsInteger := 0;
  DADOS.FieldByName('ativo').AsInteger := 1;
  tabPrincipal.TabIndex := 1;

end;

procedure TfrmMotoboy.rAlterarClick(Sender: TObject);
begin
  inherited;
  if DADOS.RecordCount = 0 then
    exit;
  DADOS.Edit;
  tabPrincipal.TabIndex := 1;
end;

procedure TfrmMotoboy.rAtivarDesativarClick(Sender: TObject);
var
  Body: String;
  DadosBody: TJSONObject;
begin
  inherited;
  if Length(DADOS.FieldByName('acesso_site').AsString) > 0 then
  begin

  end;
  DADOS.Edit;
  DADOS.FieldByName('acesso_site').AsString := FormatFloat('S000', dm.UserId) +
    FormatFloat('-000', dm.UserId + DADOS.FieldByName('codigo').AsInteger);
  DADOS.Post;
  DadosBody := TJSONObject.Create;
  DadosBody.AddPair('id', 0);
  DadosBody.AddPair('user_id', dm.UserId.ToString);
  DadosBody.AddPair('deliveryman_name',
    UpperCase(DADOS.FieldByName('nome').AsString));
  DadosBody.AddPair('deliveryman_phone_number', DADOS.FieldByName('codigo')
    .AsString);
  DadosBody.AddPair('senha', DADOS.FieldByName('acesso_site').AsString);
  DadosBody.AddPair('id_local', DADOS.FieldByName('codigo').AsString);
  dm.Requisicao.URL := 'insert/ws_motoboys/' + dm.UserId.ToString + '/a';
  dm.Requisicao.Metodo := mPost;
  // ShowMessage(DadosBody.ToString);
  dm.Requisicao.Body(DadosBody.ToString);
  dm.Requisicao.Execute;

end;

procedure TfrmMotoboy.rSalvarClick(Sender: TObject);
begin
  inherited;
  DADOS.FieldByName('nome').AsString := edtBairro.Text;
  DADOS.Post;
  dm.PostSimplesUnico('/v1/insert/generico/motoboy/codigo', DADOS);
  GetDados;
  tabPrincipal.TabIndex := 0;
  ShowMessageToast(self, 'Registro Salvo Com Sucesso', 2);
end;

initialization

RegisterClass(TfrmMotoboy);

end.
