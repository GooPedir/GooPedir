unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IniFiles, Vcl.ExtCtrls, uRequisicao,
  Vcl.StdCtrls, DataSet.Serialize, FireDAC.Comp.Client, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  System.ImageList, Vcl.ImgList;

type

  TfrmMain = class(TForm)
    tBuscaImpressao: TTimer;
    mLog: TMemo;
    mImpressora: TFDMemTable;
    memImpressora: TFDMemTable;
    memImpressoraID: TIntegerField;
    memImpressoraDRIVER: TStringField;
    memImpressao: TFDMemTable;
    memImpressaoIMPRESSORA: TIntegerField;
    memImpressaoID: TIntegerField;
    TrayIcon1: TTrayIcon;
    ImageList1: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure tBuscaImpressaoTimer(Sender: TObject);
  private
    FUrlServidor: String;
    procedure SetUrlServidor(const Value: String);
    { Private declarations }
  public
    { Public declarations }
    property UrlServidor: String read FUrlServidor write SetUrlServidor;

    function Consulta(URL: String): String;
    procedure AddLog(Descricao: String);

    // Obrigatorio
    function StatusVisible: Boolean;
    function urlServer: String;
    procedure BuscaDadosParametros(Memory: TFDMemTable);
    procedure GravaLog(Dados: String);
    function ValidarTempo: Boolean;
    procedure setPrioridadeCozinha;
    procedure setPrioridadeComanda;
    procedure setPrioridadeOutros;
    procedure setPrioridadeNull;
    function PrioridadeCozinha: Boolean;
    function PrioridadeComanda: Boolean;
    function PrioridadeOutros: Boolean;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uModuloImpressao;

{$R *.dfm}

procedure TfrmMain.AddLog(Descricao: String);
begin
  if mLog.Lines.Count > 50 then
    mLog.Lines.Clear;

  mLog.Lines.Add(FormatDateTime('hh:nn', now) + ' - ' + Descricao);

end;

procedure TfrmMain.BuscaDadosParametros(Memory: TFDMemTable);
var
  Req: iRequisicao;
begin
  Memory.Close;
  Req := iRequisicao.Create(nil);
  Req.BaseURL := frmMain.urlServer;
  Req.URL := 'v1/consulta/generica/dados_whatsapp/*/*/*';
  Req.TempoExpiracao := 60 * 1000;
  try
    Req.MemTable2 := Memory;
    Req.Execute;
  except

  end;
  Req.Free;

end;

function TfrmMain.Consulta(URL: String): String;
var
  Req: iRequisicao;
begin
  Req := iRequisicao.Create(nil);
  Req.BaseURL := UrlServidor;
  Req.URL := URL;
  Req.TempoExpiracao := 5 * 1000;
  try
    Req.Execute;
    Result := Req.Retorno;
    // //showmessage(Result)
  except
    on E: Exception do
    begin
      Result := '[]';
      TrayIcon1.IconIndex := 2;
      // //showmessage(e.Message)
    end;
  end;

  Req.Free;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  UrlServidor := IniFile.ReadString('server', 'baseurl',
    'http://localhost:2121/');
  mLog.Lines.Clear;

end;

procedure TfrmMain.GravaLog(Dados: String);
begin
  //
end;

function TfrmMain.PrioridadeComanda: Boolean;
begin

end;

function TfrmMain.PrioridadeCozinha: Boolean;
begin

end;

function TfrmMain.PrioridadeOutros: Boolean;
begin

end;

procedure TfrmMain.setPrioridadeComanda;
begin

end;

procedure TfrmMain.setPrioridadeCozinha;
begin

end;

procedure TfrmMain.setPrioridadeNull;
begin

end;

procedure TfrmMain.setPrioridadeOutros;
begin

end;

procedure TfrmMain.SetUrlServidor(const Value: String);
begin
  FUrlServidor := Value;
end;

function TfrmMain.StatusVisible: Boolean;
begin

end;

procedure TfrmMain.tBuscaImpressaoTimer(Sender: TObject);
begin
  // Desabilita o timer para evitar execuções sobrepostas
  tBuscaImpressao.Enabled := False;

  // Cria e executa uma thread anônima
  TThread.CreateAnonymousThread(
    procedure
    var
      mPedidos: TFDMemTable;
    begin
      mPedidos := TFDMemTable.Create(nil);
      try
        // Carrega os dados da consulta
        mPedidos.LoadFromJSON(Consulta('/impressao/pedidos'));

        // Verifica se há pedidos
        if mPedidos.RecordCount > 0 then
        begin
          // Atualiza a interface do usuário (usando TThread.Synchronize)
          TThread.Synchronize(nil,
            procedure
            begin
              TrayIcon1.IconIndex := 3;
            end);

          // Verifica se os dados do cabeçalho estão vazios
          if dmImpressaoV2.DADOS_CABECALHO.RecordCount = 0 then
          begin
            TThread.Synchronize(nil,
              procedure
              begin
                dmImpressaoV2.DadosEmpresa;
              end);
          end;

          // Processa cada pedido
          while not mPedidos.Eof do
          begin
            TThread.Synchronize(nil,
              procedure
              begin
                AddLog('Código: ' + mPedidos.FieldByName('id_pedido').AsString);
              end);

            // Imprime o pedido
            dmImpressaoV2.ImprimirComanda(dmImpressaoV2.COMANDA80MM,
              mPedidos.FieldByName('id_pedido').AsInteger, 0);

            mPedidos.Next;
          end;
        end
        else
        begin
          // Atualiza a interface do usuário se não houver pedidos
          TThread.Synchronize(nil,
            procedure
            begin
              TrayIcon1.IconIndex := 1;
            end);
        end;
      finally
        mPedidos.Free; // Libera a memória da tabela
        tBuscaImpressao.Enabled := True;
      end;
    end

    ).Start; // Inicia a thread
end;

function TfrmMain.urlServer: String;
begin
  Result := UrlServidor;
end;

function TfrmMain.ValidarTempo: Boolean;
begin

end;

end.
