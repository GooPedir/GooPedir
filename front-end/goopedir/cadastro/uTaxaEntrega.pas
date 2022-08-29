unit uTaxaEntrega;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uCadastroPadrao, FMX.Effects, FMX.Layouts, FMX.TabControl,
  FMX.Controls.Presentation, FMX.Objects, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, uMemTable, System.Rtti, FMX.Grid.Style,
  Data.Bind.Components, Data.Bind.DBScope, FMX.ScrollBox, FMX.Grid,
  Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Bind.Grid, System.Bindings.Outputs,
  FMX.Bind.Editors, Data.Bind.Grid, FMX.Edit, uEdit;

type
  TfrmTaxaEntrega = class(TfrmCadastroBase)
    DADOS: iMemTable;
    DADOScodigo: TIntegerField;
    DADOScidade: TStringField;
    DADOSbairro: TStringField;
    DADOSvalor_taxa: TFloatField;
    DADOSativo: TIntegerField;
    DADOSestado: TStringField;
    DADOSmodificado_site: TIntegerField;
    DADOSid_site: TIntegerField;
    StringGrid4: TStringGrid;
    BDSDADOS: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBDSDADOS: TLinkGridToDataSource;
    Layout1: TLayout;
    edtBairro: iEdit;
    Label3: TLabel;
    Layout2: TLayout;
    iEdit1: iEdit;
    Label4: TLabel;
    Layout3: TLayout;
    iEdit2: iEdit;
    Label5: TLabel;
    Layout4: TLayout;
    iEdit3: iEdit;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure rAdicionarClick(Sender: TObject);
    procedure rAlterarClick(Sender: TObject);
    procedure rSalvarClick(Sender: TObject);
    procedure edtBairroExit(Sender: TObject);
    procedure iEdit3Exit(Sender: TObject);
  private
    { Private declarations }
    procedure GetDados;
  public
    { Public declarations }
  end;

var
  frmTaxaEntrega: TfrmTaxaEntrega;

implementation

{$R *.fmx}

uses uDM, uMain, util, uFuncoes;

procedure TfrmTaxaEntrega.edtBairroExit(Sender: TObject);
begin
  inherited;
  (Sender as iEdit).Text := RemoveAcento((Sender as iEdit).Text);
end;

procedure TfrmTaxaEntrega.FormCreate(Sender: TObject);
begin
  inherited;
  GetDados;
  tabPrincipal.TabIndex := 0;
  tabPrincipal.TabPosition := TTabPosition.None;

end;

procedure TfrmTaxaEntrega.GetDados;
begin
  dm.GetSimples('/v1/consulta/todos/taxa_entrega', DADOS);
end;

procedure TfrmTaxaEntrega.iEdit3Exit(Sender: TObject);
begin
  inherited;
  try
    StrToFloat((Sender as iEdit).Text);
  except
    ShowMessageToast(self, 'Valor Informado Invalido!', 1);
    (Sender as iEdit).SetFocus;
  end;
end;

procedure TfrmTaxaEntrega.rAdicionarClick(Sender: TObject);
begin
  inherited;
  DADOS.Insert;
  tabPrincipal.TabIndex := 1;
  DADOS.FieldByName('cidade').AsString := frmMain.GetParametros('cidade');
  DADOS.FieldByName('estado').AsString := frmMain.GetParametros('estado');
  DADOS.FieldByName('valor_taxa').AsFloat := 0;
  DADOS.FieldByName('codigo').AsInteger := 0;
  DADOS.FieldByName('ativo').AsInteger := 1;
  DADOS.FieldByName('modificado_site').AsInteger := 1;
  DADOS.FieldByName('id_site').AsInteger := 1;
  DADOS.AtualizaCampos;
  edtBairro.SetFocus;
end;

procedure TfrmTaxaEntrega.rAlterarClick(Sender: TObject);
begin
  inherited;
  DADOS.Edit;
  tabPrincipal.TabIndex := 1;
end;

procedure TfrmTaxaEntrega.rSalvarClick(Sender: TObject);
begin
  inherited;
  edtBairro.SetFocus;
  DADOS.Post;
  dm.PostSimplesUnico('/v1/insert/generico/taxa_entrega/codigo', DADOS);
  GetDados;
  tabPrincipal.TabIndex := 0;
  ShowMessageToast(self, 'Registro Salvo Com Sucesso', 2);
end;

initialization

RegisterClass(TfrmTaxaEntrega);

end.
