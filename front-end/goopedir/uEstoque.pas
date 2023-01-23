unit uEstoque;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uFrmClonePadrao, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FMX.TabControl, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uMemTable,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, System.Rtti,
  FMX.Grid.Style, Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Bind.Grid,
  System.Bindings.Outputs, FMX.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.DBScope, FMX.ScrollBox, FMX.Grid;

type
  TfrmEstoque = class(TfrmPadrao)
    tabPrincipal: TTabItem;
    TabEntradaEstoque: TTabItem;
    DADOS: TFDMemTable;
    Layout1: TLayout;
    Grid1: TGrid;
    DADOSID: TIntegerField;
    DADOSTIPO: TIntegerField;
    DADOSNOME: TStringField;
    DADOSUN: TStringField;
    DADOSQTD: TFloatField;
    DADOSENTRADA: TFloatField;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBindSourceDB1: TLinkGridToDataSource;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmEstoque: TfrmEstoque;

implementation

{$R *.fmx}

uses Funcoes;

procedure TfrmEstoque.FormCreate(Sender: TObject);
begin
  inherited;
  GetSimples2('v1/util/estoque/geral', DADOS);
end;

initialization

RegisterClass(TfrmEstoque);

end.
