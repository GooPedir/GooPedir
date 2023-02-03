unit uMain;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, Vcl.AppEvnts, ppReport, Data.DB, Vcl.Grids,
  Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;
type
  TStatusApp = (sVisivel, sOcuto);
  TfrmMain = class(TForm)
    ImageList1: TImageList;
    TrayIcon1: TTrayIcon;
    tMinimiza: TTimer;
    dsImpressao: TDataSource;
    DBGrid1: TDBGrid;
    Memo1: TMemo;
    memImpressao: TFDMemTable;
    memImpressaoIMPRESSORA: TIntegerField;
    memImpressaoID: TIntegerField;
    procedure FormCreate(Sender: TObject);
    procedure tMinimizaTimer(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure LogErro(Mesagem:String);
  end;
var
  frmMain: TfrmMain;
  StatusForm: TStatusApp;
  Codigo : Integer;
implementation
{$R *.dfm}
uses uModuloImpressao;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Thread: TImpressaoPedidos;
begin
  Thread := TImpressaoPedidos.Create;
  Thread.Start;
  Codigo := 0;
end;
procedure TfrmMain.LogErro(Mesagem: String);
begin
//
Memo1.Lines.Add(FormatDateTime('dd/mm/yyyy hh:mm',now));
Memo1.Lines.Add(Mesagem);
Memo1.Lines.Add('');
end;
procedure TfrmMain.tMinimizaTimer(Sender: TObject);
begin
  tMinimiza.Enabled := False;
  Self.Hide();
  Self.WindowState := wsMinimized;
  StatusForm := sOcuto;
end;
procedure TfrmMain.TrayIcon1Click(Sender: TObject);
begin
  case StatusForm of
    sVisivel:
      begin
        StatusForm := sOcuto;
        Self.WindowState := wsMinimized;
        Self.Hide();
      end
  else
    begin
      StatusForm := sVisivel;
      Self.WindowState := wsMaximized;
      Self.Show();
    end;
  end;
end;
end.
