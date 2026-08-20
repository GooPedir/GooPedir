unit uPedidoSite;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uRequisicao, Vcl.ExtCtrls, System.JSON,
  Vcl.StdCtrls, uImportacaoPedio, uExportacaoPedido, uGlobais;

type
  TfrmPedidoSite = class(TForm)
    ReqPedidos: iRequisicao;
    Button1: TButton;
    tMinimiza: TTimer;
    TrayIcon1: TTrayIcon;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure MedirTempoExecucao;
    procedure tMinimizaTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  frmPedidoSite: TfrmPedidoSite;
  pedido: Integer;
  userId: Integer;

implementation

{$R *.dfm}
{ TfrmPedidoSite }

procedure TfrmPedidoSite.Button1Click(Sender: TObject);
begin
  MedirTempoExecucao;
end;

procedure TfrmPedidoSite.FormCreate(Sender: TObject);

begin
{$IFDEF DEBUG}
  if (not Desenvolvimento) then
  begin
    ShowMessage('O sistema não pode ser executado em modo DEBUG.');
    Exit;
  end;
{$ENDIF}

  pedido := 0;
  userId := 43;
  try
    pedido := ParamStr(1).ToInteger();
    userId := ParamStr(2).ToInteger();
  except

  end;

  if ((pedido > 0) And (userId = 0)) then
  begin
    userId := -1;
  end;

end;

procedure TfrmPedidoSite.MedirTempoExecucao;
var
  TempoInicial, TempoFinal: DWORD;
  TempoDecorrido: Integer;
begin
  TempoInicial := GetTickCount; // Marca o tempo inicial

  getPedidos; // Executa a função que você quer medir

  TempoFinal := GetTickCount; // Marca o tempo final

  // Calcula o tempo decorrido em milissegundos
  TempoDecorrido := TempoFinal - TempoInicial;

  // Exibe o tempo decorrido em uma mensagem
  (Format('A função getPedidos demorou %d milissegundos para executar.',
    [TempoDecorrido]));
end;

procedure TfrmPedidoSite.Timer1Timer(Sender: TObject);
begin
Application.Terminate;
end;

procedure TfrmPedidoSite.tMinimizaTimer(Sender: TObject);
begin
  tMinimiza.Enabled := false;
  self.Hide();
  self.WindowState := wsMinimized;
  try
    if pedido = 0 then
      getPedidos
    else
    begin
      getPedido(pedido.ToString, userId.ToString);
    end;
  except
    on e: Exception do
    begin

    end;

  end;
  try
    EnviarPedidos;
  except
    on e: Exception do
    begin
    end;
  end;
  Application.Terminate;
end;

end.
