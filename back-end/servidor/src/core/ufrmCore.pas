unit ufrmCore;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, DataSet.Serialize;

type
  TfrmCore = class(TForm)
    tMinimiza: TTimer;
    dataSetMerchants2: TFDMemTable;
    dataSetMerchants1: TFDMemTable;
    dsMerchants1: TDataSource;
    dsMerchants2: TDataSource;
    Configuracoes: TFDMemTable;
    procedure tMinimizaTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCore: TfrmCore;

implementation

uses
  conexao, uAtualizador, System.IOUtils;

{$R *.dfm}
{
  Mapa dos Tipos
  1 - Backup Banco de Dados
  2 - iFood
  3 -
  4 -

}

procedure TfrmCore.FormCreate(Sender: TObject);
var
  tipo: String;
  conexao : Tconexao;
  Banco : TAtualizacao;
begin
  try
    Banco := TAtualizacao.Create;
    try
      Banco.Iniciar;
    finally
      Banco.Free;
    end;

    conexao := Tconexao.Create('main');
    try
      conexao.SQL.Add('select * from dados_whatsapp');
      Configuracoes.LoadFromJSON(conexao.ConsultaSQL);
    finally
      conexao.Free;
    end;
  except
    on E: Exception do
    begin
      TFile.AppendAllText(TPath.Combine(ExtractFilePath(ParamStr(0)),
        'atualizador-core.log'), FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) +
        ' Falha ao iniciar atualizador: ' + E.Message + sLineBreak,
        TEncoding.UTF8);
      raise;
    end;
  end;

  if ParamCount > 0 then
  begin
    tipo := ParamStr(1);
  end;
end;

procedure TfrmCore.tMinimizaTimer(Sender: TObject);
begin
  tMinimiza.Enabled := false;
  self.Hide();
  self.WindowState := wsMinimized;
end;

end.
