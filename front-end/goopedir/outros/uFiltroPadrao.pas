unit uFiltroPadrao;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, uButton,
  FMX.DateTimeCtrls, FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.Effects,
  uMemTable;

type
  TCallback = procedure of object;

  TfrmFiltroPadrao = class(TForm)
    Layout1: TLayout;
    Layout2: TLayout;
    Label1: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    btnNao: iButton;
    btnSim: iButton;
    VertScrollBox1: TVertScrollBox;
    Layout3: TLayout;
    Label2: TLabel;
    edtDataInicial: TDateEdit;
    Layout4: TLayout;
    Label3: TLabel;
    Layout5: TLayout;
    Label4: TLabel;
    edtDataFinal: TDateEdit;
    sMax: TSpinBox;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    ShadowEffect1: TShadowEffect;
    Rectangle3: TRectangle;
    procedure btnSimClick(Sender: TObject);
    procedure btnNaoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FMaxRegistros: Integer;
    FDataFinal: TDate;
    FDataInicial: TDate;
    FDadosFiltros: iMemTable;
    procedure SetDataFinal(const Value: TDate);
    procedure SetDataInicial(const Value: TDate);
    procedure SetMaxRegistros(const Value: Integer);
    procedure SetDadosFiltros(const Value: iMemTable);
    { Private declarations }
  public
    { Public declarations }
    procedure Filtros;
    procedure Abrir;

  var
    Sim: TCallback;
    Executar: TCallback;
    property DataInicial: TDate read FDataInicial write SetDataInicial;
    property DataFinal: TDate read FDataFinal write SetDataFinal;
    property MaxRegistros: Integer read FMaxRegistros write SetMaxRegistros;
    property DadosFiltros: iMemTable read FDadosFiltros write SetDadosFiltros;
  end;

var
  frmFiltroPadrao: TfrmFiltroPadrao;

implementation

uses
  System.DateUtils{, FMX.Toast, uSQL};

{$R *.fmx}

procedure TfrmFiltroPadrao.Abrir;
begin
  Show;
  try
    edtDataInicial.Date := DataInicial;
  except

  end;
  try
    edtDataFinal.Date := DataFinal;
  except

  end;
  try
    sMax.Text := MaxRegistros.ToString;
  except

  end;

end;

procedure TfrmFiltroPadrao.btnNaoClick(Sender: TObject);
begin
  Hide;
end;

procedure TfrmFiltroPadrao.btnSimClick(Sender: TObject);
begin

  if edtDataInicial.Date > edtDataFinal.Date then
  begin
//    ShowMessageToast('Data inicial não pode ser maior que a data final!', 1);
    exit;
  end;

  DataInicial := edtDataInicial.Date;
  DataFinal := edtDataFinal.Date;
  MaxRegistros := sMax.Text.ToInteger;
  Filtros;
  Hide;
  if Assigned(Sim) then
    Sim;
  if Assigned(Executar) then
    Executar;

end;

procedure TfrmFiltroPadrao.Filtros;
begin
  if not Assigned(DadosFiltros) then
    exit;

  DadosFiltros.close;

  DadosFiltros.Open;

  DadosFiltros.Insert;
  DadosFiltros.FieldByName('FILTRO').AsString := 'DATA_INI';
  DadosFiltros.FieldByName('VALOR').AsDateTime := frmFiltroPadrao.DataInicial;
  DadosFiltros.Post;

  DadosFiltros.Insert;
  DadosFiltros.FieldByName('FILTRO').AsString := 'DATA_FIM';
  DadosFiltros.FieldByName('VALOR').AsDateTime := frmFiltroPadrao.DataFinal;
  DadosFiltros.Post;

  DadosFiltros.Insert;
  DadosFiltros.FieldByName('FILTRO').AsString := 'MAX';
  DadosFiltros.FieldByName('VALOR').AsInteger := frmFiltroPadrao.MaxRegistros;
  DadosFiltros.Post;
end;

procedure TfrmFiltroPadrao.FormCreate(Sender: TObject);
begin
  DataInicial := StrToDate('01/' + FormatDateTime('mm/yyyy', now));
  // DataInicial := now-15;
  DataFinal := StrToDate(FormatFloat('00', DaysInMonth(now)) +
    FormatDateTime('/mm/yyyy', now));
  MaxRegistros := 30;
end;

procedure TfrmFiltroPadrao.SetDadosFiltros(const Value: iMemTable);
begin
  FDadosFiltros := Value;
end;

procedure TfrmFiltroPadrao.SetDataFinal(const Value: TDate);
begin
  FDataFinal := Value;
end;

procedure TfrmFiltroPadrao.SetDataInicial(const Value: TDate);
begin
  FDataInicial := Value;
end;

procedure TfrmFiltroPadrao.SetMaxRegistros(const Value: Integer);
begin
  FMaxRegistros := Value;
end;

end.
