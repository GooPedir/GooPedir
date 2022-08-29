unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, uSQL,
  Winapi.TlHelp32, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, conexao, Vcl.Menus,
  FMX.Printer;

type
  TAbrirServicos = class(TThread)
  protected
    procedure Execute; override;

  var
    conexao: Tconexao;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TfrmServidor = class(TForm)
    TrayIcon1: TTrayIcon;
    tMinimiza: TTimer;
    memoHistorico: TMemo;
    memoImagem: TMemo;
    Configuracoes: TFDMemTable;
    PopupMenu1: TPopupMenu;
    Fechar1: TMenuItem;
    memImpressora: TFDMemTable;
    memImpressoraID: TIntegerField;
    memImpressoraDRIVER: TStringField;
    procedure tMinimizaTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Fechar1Click(Sender: TObject);
  private
    { Private declarations }
    procedure TemAtualizacao;
    procedure SemAtualizacao;
    procedure IniciarAtualizacao;
    procedure FimAtualizacao;
    procedure Executaveis;

  public
    { Public declarations }
    Function VerificaExe(Nome: String): Boolean;
    procedure AbrirExe(Nome: String);
    procedure FecharExe(ExeFileName: String);
    function IMPRESSAO: String;
    function WHATSAPP: String;
    function SITE: String;
    procedure LoadImpressora;
  end;

var
  frmServidor: TfrmServidor;
  Atualizacao: TSQL;
  Servicos: TAbrirServicos;

implementation

{$R *.dfm}

uses Data.FireDACJSONReflect, DataSet.Serialize.Config,
  DataSet.Serialize.Consts, DataSet.Serialize.Export, DataSet.Serialize.Import,
  DataSet.Serialize.Language, DataSet.Serialize,
  DataSet.Serialize.UpdatedStatus, DataSet.Serialize.Utils,
  Horse.BasicAuthentication, Horse.Commons, Horse.Constants,
  Horse.Core.Group.Contract, Horse.Core.Group, Horse.Core,
  Horse.Core.Route.Contract, Horse.Core.Route, Horse.Core.RouterTree,
  Horse.Etag, Horse.Exception, Horse.HTTP, Horse.Jhonson, Horse.JWT,
  Horse.OctetStream, Horse.Paginate, Horse, Horse.Proc, Horse.Provider.Abstract,
  Horse.Provider.Apache, Horse.Provider.CGI, Horse.Provider.Console,
  Horse.Provider.Daemon, Horse.Provider.FPC.Apache, Horse.Provider.FPC.CGI,
  Horse.Provider.FPC.Daemon, Horse.Provider.FPC.FastCGI,
  Horse.Provider.FPC.HTTPApplication, Horse.Provider.ISAPI, Horse.Provider.Vcl,
  Horse.WebModule, JOSE.Builder, JOSE.Consumer, JOSE.Consumer.Validators,
  JOSE.Context, JOSE.Core.Base, JOSE.Core.Builder, JOSE.Core.JWA.Compression,
  JOSE.Core.JWA.Encryption, JOSE.Core.JWA.Factory, JOSE.Core.JWA,
  JOSE.Core.JWA.Signing, JOSE.Core.JWE, JOSE.Core.JWK, JOSE.Core.JWS,
  JOSE.Core.JWT, JOSE.Core.Parts, JOSE.Encoding.Base64, JOSE.Hashing.HMAC,
  JOSE.OpenSSL.Headers, JOSE.Signing.Base, JOSE.Signing.ECDSA, JOSE.Signing.RSA,
  JOSE.Types.Arrays, JOSE.Types.Bytes, JOSE.Types.JSON, JOSE.Types.Utils,
  RESTRequest4D, RESTRequest4D.Request.Client, RESTRequest4D.Request.Contract,
  RESTRequest4D.Response.Client, RESTRequest4D.Response.Contract,
  RESTRequest4D.Response.Indy, RESTRequest4D.Response.NetHTTP,
  RESTRequest4D.Utils, ThirdParty.Posix.Syslog, token.autorizacao, token, uDM,
  util.backup, util, Web.WebConst, Winapi.ShellAPI;

procedure TfrmServidor.AbrirExe(Nome: String);
begin

  ShellExecute(handle, 'open', PChar(Nome), '', '', SW_SHOWNORMAL);
end;

procedure TfrmServidor.Executaveis;
var
  Dados: TFDMemTable;
  conexao: Tconexao;
begin
  conexao := Tconexao.Create;
  Dados := TFDMemTable.Create(self);
  conexao.SQL.Add('select * from dados_whatsapp');
  Dados.LoadStructure(conexao.ConsultaSQL);

end;

procedure TfrmServidor.Fechar1Click(Sender: TObject);
begin


  // FecharExe();

  FecharExe(frmServidor.IMPRESSAO);
  FecharExe(frmServidor.WHATSAPP);
  FecharExe(frmServidor.SITE);
  FecharExe(Application.ExeName);
  FecharExe('GooPedir.exe');

  // Application.Terminate;
end;

procedure TfrmServidor.FecharExe(ExeFileName: String);
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  ExeFileName := ExtractFileName(ExeFileName);

  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile))
      = UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile)
      = UpperCase(ExeFileName))) then
      TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0),
        FProcessEntry32.th32ProcessID), 0);
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure TfrmServidor.FimAtualizacao;
begin
  //
end;

procedure TfrmServidor.FormCreate(Sender: TObject);
begin

  THorse.Use(Jhonson);
  THorse.Use(Etag);
  THorse.Use(OctetStream);
  // Declaração das URI da API
  token.Registry;
  util.Registry;

  // util.backup.Registry;

  // Inicialização do Console
  try
    THorse.Listen(2121,
      procedure(Horse: THorse)
      begin
        // Writeln('Server is runing on port ' + THorse.Port.ToString);
        // Writeln('');
      end);
  except
    Application.Terminate;
    exit;
  end;

  Atualizacao := TSQL.Create;
  // Atualizacao.LabelInfo := labelInfoAtualizacao;
  Atualizacao.MemoLog := memoHistorico;

  Atualizacao.SeTiverAtualizacao := TemAtualizacao;
  Atualizacao.seNaoTiverAtualizacao := SemAtualizacao;
  Atualizacao.IniciarAtualizacao := IniciarAtualizacao;
  Atualizacao.AposConcluirAtualizacao := FimAtualizacao;
  Atualizacao.VerificaAtualizacao;

  Servicos := TAbrirServicos.Create;
  Servicos.Start;

end;

function TfrmServidor.IMPRESSAO: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'ImpressaoGooPedir.exe';
end;

procedure TfrmServidor.IniciarAtualizacao;
begin
  //
end;

procedure TfrmServidor.LoadImpressora;
var
  I: integer;
  ID: integer;
begin
  memImpressora.Close;
  memImpressora.Open;
  ID := 1;
  memImpressora.Insert;
  memImpressora.FieldByName('ID').AsInteger := ID;
  memImpressora.FieldByName('DRIVER').AsString := 'Default';
  memImpressora.Post;
  for I := 0 to Printer.Count - 1 do
  begin

    if (UpperCase(Printer.Printers[I].Device) <> 'FAX') and
      (UpperCase(Printer.Printers[I].Device) <> 'MICROSOFT PRINT TO PDF') and
      (UpperCase(Printer.Printers[I].Device) <> 'MICROSOFT XPS DOCUMENT WRITER')
    then
    begin
      inc(ID);
      memImpressora.Insert;
      memImpressora.FieldByName('ID').AsInteger := ID;
      memImpressora.FieldByName('DRIVER').AsString :=
        Printer.Printers[I].Device;
      memImpressora.Post;
    end;
  end;

end;

procedure TfrmServidor.SemAtualizacao;
begin
  //
end;

function TfrmServidor.SITE: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'SiteGooPedir.exe';
end;

procedure TfrmServidor.TemAtualizacao;
begin
  Atualizacao.AtualizarBanco;
end;

procedure TfrmServidor.tMinimizaTimer(Sender: TObject);
begin
  tMinimiza.Enabled := False;
  self.Hide();
  self.WindowState := wsMinimized;
  // StatusForm := sOcuto;
end;

function TfrmServidor.VerificaExe(Nome: String): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Nome := ExtractFileName(Nome);
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(Nome)
      ) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(Nome))) then
    begin
      Result := True;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function TfrmServidor.WHATSAPP: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'WhatsappGoPedir.exe';
end;

{ TAbrirServicos }

constructor TAbrirServicos.Create;
begin
  inherited Create(True);
  conexao := Tconexao.Create;
end;

destructor TAbrirServicos.Destroy;
begin
  conexao.Free;
  inherited;
end;

procedure TAbrirServicos.Execute;
var

  ServicoImpressao: Boolean;
  ServicoWhatsapp: Boolean;
  DadosImpressao: TFDMemTable;

begin
  inherited;
  DadosImpressao := TFDMemTable.Create(nil);
  while not Terminated do
  begin
    conexao.SQL.Add('select * from dados_whatsapp');
    frmServidor.Configuracoes.LoadFromJSON(conexao.ConsultaSQL);
    conexao.SQL.Add
      ('SELECT * FROM impressao_pedido where data_solicitacao = current_date() and status = 0');
    DadosImpressao.LoadFromJSON(conexao.ConsultaSQL);

    if DadosImpressao.RecordCount >= 2 then
    begin
      frmServidor.FecharExe(frmServidor.IMPRESSAO);
    end;

    try
      ServicoImpressao := frmServidor.Configuracoes.FieldByName('a_impressora')
        .AsInteger = 1;
    except
      ServicoImpressao := False;
    end;
    try
      ServicoWhatsapp := frmServidor.Configuracoes.FieldByName('a_whatsapp')
        .AsInteger = 1;
    except
      ServicoWhatsapp := False;
    end;
    // ImpressaoGooPedir
    // ServidorGooPedir
    // WhatsappGoPedir
    // SiteGooPedir
    // GooPedir
    if (not frmServidor.VerificaExe(frmServidor.IMPRESSAO)) and ServicoImpressao
    then
      frmServidor.AbrirExe(frmServidor.IMPRESSAO);

    if (not frmServidor.VerificaExe(frmServidor.WHATSAPP)) and ServicoWhatsapp
    then
    begin
      if Time >= StrToTime(copy(frmServidor.Configuracoes.FieldByName('horario_abertura').AsString, 0, 8)) then
        frmServidor.AbrirExe(frmServidor.WHATSAPP);
    end;
    if  Time >= StrToTime(copy(frmServidor.Configuracoes.FieldByName('horario_fechamento').AsString, 0, 8)) then
    begin
      frmServidor.FecharExe(frmServidor.WHATSAPP);
    end;

    if (not frmServidor.VerificaExe(frmServidor.SITE)) then
      frmServidor.AbrirExe(frmServidor.SITE);

    Sleep(60 * 1000);
  end;

end;

end.
