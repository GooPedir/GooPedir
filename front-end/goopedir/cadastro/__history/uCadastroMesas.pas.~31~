unit uCadastroMesas;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uCadastroPadrao, FMX.Effects, FMX.Layouts, FMX.TabControl,
  FMX.Controls.Presentation, FMX.Objects, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.Bind.Components, Data.Bind.DBScope,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uMemTable, System.Rtti,
  FMX.Grid.Style, Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Bind.Grid,
  System.Bindings.Outputs, FMX.Bind.Editors, Data.Bind.Grid, FMX.ScrollBox,
  FMX.Grid, FMX.Edit, uEdit;

type

  TfrmCadastroMesas = class(TfrmCadastroBase)
    DADOS: iMemTable;
    BDSDADOS: TBindSourceDB;
    DADOSid_mesa: TIntegerField;
    DADOSnr_mesa: TIntegerField;
    DADOStot_mesa: TFloatField;
    DADOSfk_tipo_mesa: TIntegerField;
    DADOSdescricao: TStringField;
    StringGrid4: TStringGrid;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBDSDADOS: TLinkGridToDataSource;
    Layout3: TLayout;
    edtTipo: iEdit;
    Label5: TLabel;
    Layout1: TLayout;
    EdtMin: iEdit;
    Label3: TLabel;
    Layout2: TLayout;
    EdtMax: iEdit;
    Label4: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure rAlterarClick(Sender: TObject);
    procedure rAtivarDesativarClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rSalvarClick(Sender: TObject);
    procedure edtTipoExit(Sender: TObject);
    procedure rAdicionarClick(Sender: TObject);
  private
    { Private declarations }
    procedure GetDados;
    procedure SenhaCorreta;
    procedure Deletado;
    function MesaUltima(Descricao: String): Integer;
  public
    { Public declarations }
  end;

var
  frmCadastroMesas: TfrmCadastroMesas;

implementation

{$R *.fmx}

uses uDM, uSimNao, uSenha, util, uMain;

{ TfrmCadastroMesas }

procedure TfrmCadastroMesas.Deletado;
begin
  ShowMessageToast(self, 'Ficha Deletada!', 3);
  if Assigned(frmSenha) then
    frmSenha.Free;

  dm.PostSimplesUnico('/v1/mesa/deleta/' + DADOS.FieldByName('id_mesa')
    .AsString, nil);
  GetDados;

end;

procedure TfrmCadastroMesas.edtTipoExit(Sender: TObject);
begin
  inherited;
  EdtMin.Text := MesaUltima(edtTipo.Text).ToString;
end;

procedure TfrmCadastroMesas.FormActivate(Sender: TObject);
begin
  inherited;
  GetDados;
end;

procedure TfrmCadastroMesas.FormCreate(Sender: TObject);
begin
  inherited;
  tabPrincipal.TabPosition :=  TTabPosition.None;
  GetDados;
end;

procedure TfrmCadastroMesas.GetDados;
begin
  try
    dm.GetSimples('/v1/mesas/all/', DADOS);
  except

  end;
end;

procedure TfrmCadastroMesas.Image1Click(Sender: TObject);
begin
  inherited;
  if tabPrincipal.TabIndex = 1 then
  begin
     tabPrincipal.TabIndex := 0;
     GetDados;
  end else
  frmMain.AbrirForm('T' + self.Name);
end;

function TfrmCadastroMesas.MesaUltima(Descricao: String): Integer;
var
  ValorMinimo: Integer;
begin
  GetDados;
  DADOS.First;
  ValorMinimo := 0;
  while not DADOS.Eof do
  begin
    if UpperCase(DADOS.FieldByName('descricao').AsString) = edtTipo.Text then
    begin
      if DADOS.FieldByName('nr_mesa').AsInteger > ValorMinimo then
        ValorMinimo := DADOS.FieldByName('nr_mesa').AsInteger;
    end;
    DADOS.Next;
  end;
  Result := ValorMinimo;
end;

procedure TfrmCadastroMesas.rAdicionarClick(Sender: TObject);
begin
  inherited;
  tabPrincipal.TabIndex := 1;
end;

procedure TfrmCadastroMesas.rAlterarClick(Sender: TObject);
begin
  inherited;
  if not Assigned(frmSenha) then
    frmSenha := TfrmSenha.Create(self);
  frmSenha.Tipo := Validar;
  frmSenha.Sim := SenhaCorreta;
  frmSenha.Show;
end;

procedure TfrmCadastroMesas.rAtivarDesativarClick(Sender: TObject);
begin
  inherited;
  if not Assigned(frmSenha) then
    frmSenha := TfrmSenha.Create(self);
  frmSenha.Tipo := Validar;
  frmSenha.Sim := Deletado;
  frmSenha.Show;
end;

procedure TfrmCadastroMesas.rSalvarClick(Sender: TObject);
var
  Minimo: Integer;
  Maximo: Integer;
  ValorMinimo: Integer;
begin
  inherited;

  ValorMinimo := MesaUltima(edtTipo.Text);

  if length(edtTipo.Text) = 0 then
  begin
    ShowMessageToast(self, 'Tipo deve ser informado!', 1);
    exit;
  end;
  try
    Minimo := EdtMin.Text.ToInteger;
  except
    ShowMessageToast(self, 'Valor minimo informado invalido!', 1);
    exit;
  end;

  if not(Minimo > ValorMinimo) then
  begin
    EdtMin.Text := (ValorMinimo + 1).ToString;
  end;

  try
    Maximo := EdtMax.Text.ToInteger;
  except
    ShowMessageToast(self, 'Valor máximo informado invalido!', 1);
    exit;
  end;

  dm.PostSimples('/v1/util/grava/mesa/' + edtTipo.Text + '/' + EdtMin.Text + '/'
    + EdtMax.Text, nil);
  GetDados;
  tabPrincipal.TabIndex := 0;
  EdtMin.Text := '';
  edtTipo.Text := '';
  EdtMax.Text := '';
end;

procedure TfrmCadastroMesas.SenhaCorreta;
begin
  ShowMessageToast(self, 'Ficha liberada!', 3);
  if Assigned(frmSenha) then
    frmSenha.Free;

  dm.PostSimplesUnico('/v1/mesa/zera/' + DADOS.FieldByName('id_mesa')
    .AsString, nil);
  GetDados;

end;

initialization

RegisterClass(TfrmCadastroMesas);

end.
