unit uFazPedido;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Edit,
  uEdit, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, uMemTable;

type
  TfrmFazPedido = class(TForm)
    Rectangle1: TRectangle;
    lNomeForm: TLabel;
    Layout5: TLayout;
    Layout2: TLayout;
    edtTaxa: iEdit;
    Label4: TLabel;
    Layout1: TLayout;
    edtDesconto: iEdit;
    Label1: TLabel;
    Layout3: TLayout;
    edtAcrescimo: iEdit;
    Label2: TLabel;
    Layout4: TLayout;
    edtTotal: iEdit;
    Label3: TLabel;
    Layout6: TLayout;
    iEdit1: iEdit;
    Label5: TLabel;
    Layout7: TLayout;
    edtCodigo: iEdit;
    Label6: TLabel;
    CLIENTE: iMemTable;
    CLIENTEcodigo: TIntegerField;
    CLIENTEendereco: TIntegerField;
    CLIENTEnome: TStringField;
    CLIENTErua: TStringField;
    CLIENTEbairro: TStringField;
    CLIENTEcidade: TStringField;
    CLIENTEestado: TStringField;
    CLIENTEcomplemento: TStringField;
    CLIENTEvalor_taxa: TFloatField;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmFazPedido: TfrmFazPedido;

implementation

{$R *.fmx}

end.
