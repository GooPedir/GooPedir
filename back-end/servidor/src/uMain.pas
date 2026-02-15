unit uMain;

interface

uses
  System.Zip, System.IOUtils,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, uSQL,
  Winapi.TlHelp32, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, conexao, Vcl.Menus,
  FMX.Printer, FireDAC.Stan.StorageBin, JSON,
  FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait,
  FireDAC.DApt, IniFiles, ACBrBase, ACBrDFe, ACBrNFe,
  uImportacaoProduto, DateUtils, Vcl.Controls, uRequisicao,
  Horse.SocketIO,
  uSite,
  GooPedirAPIController,
  REST.Client,
  IdFTP, ACBRutil,
  System.Generics.Collections,
  REST.Types,
  Data.Bind.Components,
  System.SyncObjs,
  Horse.XMLDoc, Xml.XMLDoc, uCodigoPedidoDia,
  Horse.SocketIO.ServerSocket,
  Data.Bind.ObjectScope, Horse.ExceptionHandler, Horse, Horse.ServerStatic,
  cors,
  uControllerSite,
  Web.HTTPApp, PedidoController,
  IdHTTP,
  IdSSLOpenSSL,
  Winapi.WinInet,
  GenericSocket,
  uAtualizacaoSite, uGlobais, uProcedure, ProdutoQueue, uControlerProduto,
  Tasks, TaskManager;

type
  TTaskProc = reference to procedure;

  TBalancaManager = class
  private
    FBalancas: TDictionary<string, Double>;
    FCritica: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AtualizarPeso(const BalancaId: string; const Peso: Double);
    function ObterPeso(const BalancaId: string): Double;
    function ExisteBalanca(const BalancaId: string): Boolean;
  end;

  TCacheItem = record
    Timestamp: TDateTime;
    Data: string;
  end;

  TSincronizaProdutosThread = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

  TAbrirServicos = class(TThread)
  protected
    procedure Execute; override;
    function IsGreaterByOneMinute(const ADateTime: TDateTime): Boolean;

  var
    conexao: Tconexao;
    Name: String;
  public
    constructor Create;
    destructor Destroy; override;

  var
    HorarioRestart: String;
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
    memEstoque: TFDMemTable;
    memEstoqueID: TIntegerField;
    memEstoqueTIPO: TIntegerField;
    memEstoqueNOME: TStringField;
    memEstoqueUN: TStringField;
    memEstoqueENTRADA: TFloatField;
    memEstoqueSEQUENCIAL: TIntegerField;
    memEstoqueQTD: TCurrencyField;
    memTesteImpressao: TFDMemTable;
    memTesteImpressaoIMPRESSORA: TIntegerField;
    memTesteImpressaoID: TIntegerField;
    dataSetPolling: TFDMemTable;
    dsPolling: TDataSource;
    dataSetMerchantStatus: TFDMemTable;
    dsMerchantStatus: TDataSource;
    memLog: TMemo;
    FDConnection1: TFDConnection;
    QueryFDB: TFDQuery;
    ACBrNFe1: TACBrNFe;
    PRODUTOS: TFDMemTable;
    PRODUTOScodigo: TIntegerField;
    PRODUTOSid: TIntegerField;
    PRODUTOSgrupo: TIntegerField;
    PRODUTOSdescricao: TStringField;
    PRODUTOSproduto: TStringField;
    PRODUTOSnome: TStringField;
    PRODUTOStotal: TFloatField;
    PRODUTOSquantidade: TFloatField;
    PRODUTOStipo: TStringField;
    PRODUTOSadicionais: TStringField;
    PRODUTOSunitario: TFloatField;
    PIX: TFDMemTable;
    PIXvalor: TFloatField;
    PIXbase64: TBCDField;
    memEstoqueMIN: TFloatField;
    FecharServioSite1: TMenuItem;
    pIdiFood: TMenuItem;
    N1: TMenuItem;
    HabilitarProduo1: TMenuItem;
    HabilitarHomologao1: TMenuItem;
    pTipoIfood: TMenuItem;
    EventNFC: TFDMemTable;
    EventNFCCODE: TIntegerField;
    EventNFCCHAVE: TStringField;
    EventNFCOBS: TStringField;
    EventNFCid: TIntegerField;
    memGrupo: TFDMemTable;
    memGrupovalue: TStringField;
    memGrupodescricao: TStringField;
    ReiniciarServioImpresso1: TMenuItem;
    RequisicaoToPedindo: iRequisicao;
    XXX: TMenuItem;
    iRequisicao1: iRequisicao;
    dataSetMerchants2: TFDMemTable;
    dataSetMerchants1: TFDMemTable;
    dsMerchants1: TDataSource;
    dsMerchants2: TDataSource;
    Timer1: TTimer;
    mHoraAbertura: TMenuItem;
    mAtualizacao: TFDMemTable;
    mAtualizacaoid: TIntegerField;
    mAtualizacaoarquivo: TStringField;
    mAtualizacaopercentual: TIntegerField;
    mAtualizacaostatus: TStringField;
    mAtualizacaotamanho: TStringField;
    mAtualizacaouuid: TStringField;
    mAtualizacaodata: TDateTimeField;
    memErrosNFCE: TFDMemTable;
    memErrosNFCEdata: TDateTimeField;
    memErrosNFCEpedido: TIntegerField;
    memErrosNFCEerros: TStringField;
    tBackupFTP: TTimer;
    memPaineis: TFDMemTable;
    memBanner: TFDMemTable;
    memTiposSite: TFDMemTable;
    memTipoMesa: TFDMemTable;
    Button1: TButton;
    procedure tMinimizaTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AposConectarBanco;
    function FazerBackupMySQL(conexao: Tconexao): Boolean;
    function GetMySQLDumpPath: string;
    function FileSizeByName(const FileName: string): Int64;
    procedure Fechar1Click(Sender: TObject);


    procedure tAtualizaProcessosTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FecharServioSite1Click(Sender: TObject);
    function IFoodRefreshTokenGet: string;
    procedure IFoodRefreshTokenSave(RefreshToken: string);
    procedure HabilitarProduo1Click(Sender: TObject);
    procedure HabilitarHomologao1Click(Sender: TObject);
    procedure pIdiFoodClick(Sender: TObject);
    procedure ReiniciarServioImpresso1Click(Sender: TObject);
    procedure IFoodLogRequest(ARequestId, AContent: string);
    procedure IFoodMerchantStatusError(AError: Exception);
    procedure IFoodPollingStart(StartPolling: TDateTime);
    procedure IFoodLogResponse(ARequestId, AContent: string;
      AStatusCode: Integer);

    procedure IFoodPollingError(Error: Exception);
    procedure VerificarOuCriarBanco;
    procedure ExecutarSQLScript(const SQLText: string);
    function SincronizarBackupFTP(const CaminhoArquivo, NomeUsuario: string;
      APIGoopedir: TGooPedirAPIController): Boolean;
    function FTP_DirectoryExists(FTP: TIdFTP; const Directory: string): Boolean;
    procedure tBackupFTPTimer(Sender: TObject);

    procedure ReProcessaImpressaoPedidoProduto(conexao: Tconexao);
    procedure Button1Click(Sender: TObject);
    function SocketProdutos(Message: String): String;

  private
    FHorSite: TDateTime;
    FDataBloqueio: TDate;
    FBase64Whatsapp: String;
    FNumeroWhatsapp: String;
    FStatusWhatsapp: Boolean;
    FLogoutWhatsapp: Boolean;
    FNomeExeSite: String;
    FStatusInstanciaCriada: Boolean;
    FNomeWhatsapp: String;
    FImagemWhatsapp: String;
    FSincNumeroWhatsapp: String;
    FSemDataBloqueio: Boolean;
    FDataConfianca: TDate;
    { Private declarations }
    procedure TemAtualizacao;
    procedure SemAtualizacao;
    procedure IniciarAtualizacao;
    procedure FimAtualizacao;
    procedure ExtornoPedidoNaoFinalizado;

    function ConverteValoriFood(Valor: String): Real;
    procedure SetHorSite(const Value: TDateTime);
    procedure SetDataBloqueio(const Value: TDate);

    procedure SetBase64Whatsapp(const Value: String);
    procedure SetNumeroWhatsapp(const Value: String);
    procedure SetStatusWhatsapp(const Value: Boolean);
    procedure SetLogoutWhatsapp(const Value: Boolean);
    procedure SetNomeExeSite(const Value: String);
    procedure SetNomeWhatsapp(const Value: String);
    procedure SetStatusInstanciaCriada(const Value: Boolean);
    procedure SetImagemWhatsapp(const Value: String);
    function NumeroWpp: String;
    procedure SetSincNumeroWhatsapp(const Value: String);
    procedure SetSemDataBloqueio(const Value: Boolean);
    procedure SetDataConfianca(const Value: TDate);

  public
    { Public declarations }
    Function VerificaExe(Nome: String): Boolean;
    procedure AbrirExe(Nome: String);
    procedure FecharExe(ExeFileName: String);
    function IMPRESSAO: String;
    function WHATSAPP: String;
    function SITE(Nome: string): String;
    function USANFCE: String;
    procedure LoadImpressora;
    procedure FichaTecnica;
    function PathExe: String;
    function ATUALIZADOR: String;

    function IntegracaoiFood: Boolean;
    procedure BuscaDadosiFood;
    function IDiFood: String;
    function TaxaiFood: Real;
    function StatusPedidoiFood: Integer;
    procedure AtualizaDadosiFood;

    function UserID: Integer;
    procedure buscarAtualizacao(user: Integer);
    procedure SincronizaProdutos;
    procedure BuscarModulo;
    function GetModulo: String;

    procedure AddLog(Text: String);
    procedure AddErro(Identificacao, Erro: String);
    procedure EnviaGlitchtip(DSN, Tipo, Identificacao, Mensagem: String);
    function GenerateUUID: string;

    function DadosProdutos: TJsonArray;

    property HorSite: TDateTime read FHorSite write SetHorSite;
    property DataBloqueio: TDate read FDataBloqueio write SetDataBloqueio;
    property SemDataBloqueio: Boolean read FSemDataBloqueio
      write SetSemDataBloqueio;
    property DataConfianca: TDate read FDataConfianca write SetDataConfianca;

    function RetornaCertificado: TJsonArray;
    procedure AtivaInativaProdutos;
    function ObterDiaDaSemana: string;
    procedure FazExclusaoClientes;

    procedure mModal(Valor: String);

    function ObjetoProdutoAdicional(Codigo: String): TJsonArray;

    procedure ImpressoraStatus;
    procedure ComandaStatus;
    procedure CozinhaStatus;
    procedure OutrosStatus;
    function ValidaTempoImpressaoStatus: Boolean;
    function ValidaTempoImpressaoStatusComanda: Boolean;
    function ValidaTempoImpressaoStatusCozinha: Boolean;
    function ValidaTempoImpressaoStatusOutros: Boolean;

    function GerarCodigoPedidoDia: Integer;
    procedure InicializarCodigo;

    procedure ReImpressao;
    procedure setUser;
    procedure ReiniciarAplicacao;

    // property
    property StatusWhatsapp: Boolean read FStatusWhatsapp
      write SetStatusWhatsapp;
    property NumeroWhatsapp: String read NumeroWpp write SetNumeroWhatsapp;
    property Base64Whatsapp: String read FBase64Whatsapp
      write SetBase64Whatsapp;
    property LogoutWhatsapp: Boolean read FLogoutWhatsapp
      write SetLogoutWhatsapp;
    property NomeWhatsapp: String read FNomeWhatsapp write SetNomeWhatsapp;
    property ImagemWhatsapp: String read FImagemWhatsapp
      write SetImagemWhatsapp;
    property StatusInstanciaCriada: Boolean read FStatusInstanciaCriada
      write SetStatusInstanciaCriada;

    property NomeExeSite: String read FNomeExeSite write SetNomeExeSite;

    function GetCachedData: string;

    procedure DadosApiWhatsapp;
    procedure DadosWhatsapp;
    procedure DadosQrCod;

    function FormatPhoneNumber(const RawNumber: string): string;

    procedure ImportaProdutosToPedindo;

    property SincNumeroWhatsapp: String read FSincNumeroWhatsapp
      write SetSincNumeroWhatsapp;

    function GetHorarioAbertura(Dia: String): String;
    function GetHorarioFechamento(Dia: String): String;
    function GetHorarioAtendimento(Dia: String): String;

    procedure SincronizaHorario;
    procedure SincronizaParametros;

    function GetInfoSystem: TJsonObject;

    procedure AtualizaSaldoEstoque;

    procedure DadosBloqueio;

    procedure MiddlewareCORS(Req: THorseRequest; Res: THorseResponse;
      Next: TProc);

    procedure AtivaInativaSite(user: Integer);
    procedure ResetUser;

    function CreateiFoodConnection(Name, MerchantID: String): String;
    function GetToken(Numero: Integer): String;
    procedure SaveToken(Numero: Integer; RefreshToken: string);

    function IFoodRefreshTokenGet1: string;
    function IFoodRefreshTokenGet2: string;

    procedure IFoodRefreshTokenSave1(RefreshToken: string);
    procedure IFoodRefreshTokenSave2(RefreshToken: string);


    function GetInstancia(Pedido: String): Integer;
    procedure IniciaIfood;
    procedure LogMiddleware(Req: THorseRequest; Res: THorseResponse;
      Next: TProc);
    function Metodo(Req: THorseRequest): String;
    procedure InitializeLogFile;
    function ImpressaoStatus: TJsonObject;
    procedure SincronizaCaixa(Codigo: Integer);
    function DoGetCaixaTresLancado(Codigo: Integer): TJsonArray;
    function DoGetCaixaTres(Codigo: Integer): TJsonArray;
    function DoGetCaixaTresSangria(Codigo: Integer): TJsonArray;
    function DoGetCaixaCincoProduto(Codigo: Integer): TJsonArray;
    function DoGetCaixaCincoCategoria(Codigo: Integer): TJsonArray;
    procedure EnvioCaixa;
    procedure AtualizaCacheSite;
    function GetTaxaEntrega: TJsonArray;
    function GetTipopagamento: TJsonArray;
    procedure AgendarReinicio;

  var
    BalancaManager: TBalancaManager;
    ServerSocket: iSocketServer;

    FechouWhatsapp: Boolean;
    FechouSite: Boolean;

    DataHoraImpressaoService: TDateTime;
    DataHoraImpressaoServiceComanda: TDateTime;
    DataHoraImpressaoServiceCozinha: TDateTime;
    DataHoraImpressaoServiceOutros: TDateTime;

    CodigoPedido: Integer;
    TempoRestartServer: Integer;
    APIGoopedir: TGooPedirAPIController;
    StatusSincProdutos: Boolean;

    JsonDadosBloqueio: TJsonObject;
    Faturas: TJsonArray;
    DadosWhatsappBoolean: Boolean;
    CarregaImagem: Boolean;
    FaturarEmAberto: Boolean;
    ThreadSincroniza: TSincronizaProdutosThread;
    UltimoHorarioPedidoTurnoTarde: TDateTime;
    JsonAtualizacao: TJsonObject;

    // Dados Publicos Padrão
    TaxaEntrega: TFDMemTable;
    TipoPagamento: TFDMemTable;
    NomeArquivoBackup: String;
    Queue: TProdutoQueue;
    CacheTiposJSON: string; // guarda o JSON cru em UTF-8
    CacheTiposArr: TJsonArray; // opcional se quiser parseado
    StatusMensagemWhatsapp: Integer;
    StatusErroWhatsapp: String;
    Modulos: TJsonObject;
    BackupExe: Boolean;

    Test: Integer;
    ClientSocket: iGenericSocket;
    JsonTipoMesa: TJsonArray;

  end;

var
  frmServidor: TfrmServidor;
  Atualizacao: TSQL;
  Servicos: TAbrirServicos;
  statusiFood: Boolean;
  user: Integer;

  Cache: TCacheItem;
  Port: Integer;
  LogFilePath: String;
  GerarLog: Boolean;
  MeusModulos: String;
  TaskRegistry: TDictionary<string, TTaskProc>;

implementation

{$R *.dfm}

uses Data.FireDACJSONReflect, DataSet.Serialize.Config,
  DataSet.Serialize.Consts, DataSet.Serialize.Export, DataSet.Serialize.Import,
  DataSet.Serialize.Language, DataSet.Serialize, uTablet,
  DataSet.Serialize.UpdatedStatus, DataSet.Serialize.Utils,
  Horse.BasicAuthentication, Horse.Commons, Horse.Constants,
  Horse.Core.Group.Contract, Horse.Core.Group, Horse.Core,
  Horse.Core.Route.Contract, Horse.Core.Route, Horse.Core.RouterTree,
  Horse.Etag, Horse.Exception, Horse.HTTP, Horse.Jhonson, Horse.JWT,
  Horse.OctetStream, Horse.Paginate, Horse.Proc, Horse.Provider.Abstract,
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
  util.backup, util, Web.WebConst, Winapi.ShellAPI, v2, NFCE, imprimir,
  REST.JSON, uToPedindo, uControllCaches, uDadosWhatsapp;

procedure TfrmServidor.AbrirExe(Nome: String);
begin
  if length(trim(Nome)) = 0 then
    exit;

  ShellExecute(handle, 'open', PChar(Nome), '', '', SW_SHOWNORMAL);

end;

procedure TfrmServidor.AddErro(Identificacao, Erro: String);
begin
  EnviaGlitchtip
    ('https://393ce11c328044b4a747820f31ce790a@nginx-glitchtip.l1p88w.easypanel.host/1',
    'Erro', Identificacao, Erro);
end;

procedure TfrmServidor.AddLog(Text: String);
begin
  EnviaGlitchtip
    ('https://393ce11c328044b4a747820f31ce790a@nginx-glitchtip.l1p88w.easypanel.host/1',
    'Log', 'AddLog', Text);
end;

procedure TfrmServidor.AgendarReinicio;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Cmd: string;
begin
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);

  Cmd := 'cmd.exe /C timeout /T 5 /NOBREAK > nul & start "" "ServicosGoopedir.exe"';

  CreateProcess(nil, PChar(Cmd), nil, nil, False, CREATE_NO_WINDOW, nil, nil,
    StartupInfo, ProcessInfo);

  CloseHandle(ProcessInfo.hProcess);
  CloseHandle(ProcessInfo.hThread);
end;

procedure TfrmServidor.AposConectarBanco;
var
  conexao: Tconexao;
  VersaoMysql: String;
  IniFile: TIniFile;
  HorarioRestart: String;
  ClientId: String;
  ClientSecret: String;
  PedidosManager: TPedidosManager;

  Qry: TFDQuery;
  nomeBKP: String;
  comando: String;
begin
  {
    Está no core
    try
    TDirectory.Delete(ExtractFilePath(ParamStr(0)) + 'cache\', True);
    except

    end;
    // ⚡ Tudo que depende que o banco esteja pronto:
    frmServidor.Configuracoes.Close;


    VersaoMysql := conexao.ValidaVersao;

    conexao.SQL.Add('select * from dados_whatsapp');
    frmServidor.Configuracoes.LoadFromJSON(conexao.ConsultaSQL);

    IniFile := TIniFile.Create('./goopedir.ini');
    IniFile.WriteString('site', 'clientId',    frmServidor.Configuracoes.FieldByName('client_id').AsString);
    IniFile.WriteString('site', 'clientSecurity',frmServidor.Configuracoes.FieldByName('client_security').AsString);
    IniFile.Free;
  }

  // Configurações adicionais de iFood
  conexao := Tconexao.Create('main'); // Se precisar reabrir
  IniFile := TIniFile.Create('./goopedir.ini');
  if IniFile.ReadString('IFOOD', 'CLIENTID', '') = '' then
  begin
    HabilitarProduo1Click(nil);
  end;

  ClientId := IniFile.ReadString('IFOOD', 'CLIENTID', '');
  ClientSecret := IniFile.ReadString('IFOOD', 'CLIENTSECRET', '');
  IniFile.Free;



  InicializarCodigo;
  IniciaIfood;
  FazerBackupMySQL(conexao);
  TSincronizaProdutosThread.Create;
  // EnvioCaixa;
  try
    RegisterAllTasks;

    // Executar uma task em paralelo
    TTaskManager.Run('sabores');
    TTaskManager.Run('clientes');
    // TTaskManager.Run('vendas');

    // Evita que o programa termine antes das tasks concluírem
    Readln;
  except

  end;
  conexao.Free;

end;

procedure TfrmServidor.AtivaInativaProdutos;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Data: TDate;
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  Data := IniFile.ReadDate('ATIVA', 'AtivaInativaProdutos',
    StrToDate('01/01/1999'));
  if Data = Date then
  begin
    IniFile.Free;
    exit;
  end;
  try
    conexao := Tconexao.Create('main');
    Dados := TFDMemTable.Create(nil);
    conexao.SQL.Add('select * from produto where dias = 1');
    Dados.LoadFromJSON(conexao.ConsultaSQL);

    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        conexao.SQL.Add
          ('update produto set ativo = :ativo, modificado_site = 0 where codigo = :codigo');
        conexao.Parametros('ativo', Dados.FieldByName(ObterDiaDaSemana)
          .AsString);
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsString);
        conexao.ExecuteSQL;
        Dados.Next;
      end;
    end;

    Dados.Free;
    conexao.Free;
  except
    on E: Exception do
    begin

    end;

  end;
  IniFile.WriteDate('ATIVA', 'AtivaInativaProdutos', Date);
  IniFile.Free;

end;

procedure TfrmServidor.AtivaInativaSite(user: Integer);
var
  JsonObject: TJsonObject;
  JsonProduto: TJsonObject;
  JsonAdicionais: TJsonObject;
  JsonSabores: TJsonObject;
  conexao: Tconexao;
  Valor: String;
  Req: iRequisicao;
  Dados: TFDMemTable;
  IniFile: TIniFile;
  Data: TDate;

begin

  IniFile := TIniFile.Create('./goopedir.ini');
  Data := IniFile.ReadDate('ATIVA', 'ATIVA', StrToDate('01/01/1999'));
  if Data = Date then
  begin
    IniFile.Free;
    exit;
  end;

  SincronizaTaxaEntrega(user); // Sincroniza as taxas
  SincronizaFormaPagamento(user); // Sincroniza as forma de pagamento
  SincronizaMotoboy(user); // sincroniza os motoboys

  try
    conexao := Tconexao.Create('AtivaInativaSite');

    JsonObject := TJsonObject.Create;
    JsonObject.AddPair('user', user);

    JsonProduto := TJsonObject.Create;

    conexao.SQL.Add
      ('select 0 as zero, id_site as codigo from produto where id_site > 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;

    conexao.SQL.Add('update produto set modificado_site = 0 where id_site in ('
      + Valor + ')');
    conexao.ExecuteSQL;

    JsonProduto.AddPair('all', Valor);

    conexao.SQL.Add
      ('select 0 as zero, (id_site) as codigo from produto where id_site > 0 and ativo = 1 and deletado = 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonProduto.AddPair('active', Valor);

    conexao.SQL.Add
      ('select 0 as zero, (id_site) as codigo from produto where id_site > 0 and ativo = 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonProduto.AddPair('disabled', Valor);

    JsonAdicionais := TJsonObject.Create;
    conexao.SQL.Add
      ('select 0 as zero, (pro_adi_personalizado_sabores.id_site) as codigo from pro_adi_personalizado_sabores');
    conexao.SQL.Add
      ('join pro_adi_personalizado on pro_adi_personalizado.id = pro_adi_personalizado_sabores.id_pro_adi_personalizado');
    conexao.SQL.Add('where pro_adi_personalizado_sabores.id_site > 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        { conexao.SQL.Add('delete from pro_adi_personalizado_sabores where nome = :nome and id_pro_adi_personalizado = :id_pro_adi_personalizado and id_site <> :id_site');
          conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
          conexao.Parametros('id_pro_adi_personalizado',
          Dados.FieldByName('id_pro_adi_personalizado').AsString);
          conexao.Parametros('id_site', Dados.FieldByName('codigo').AsString);
          conexao.ExecuteSQL; }

        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonAdicionais.AddPair('all', Valor);
    conexao.SQL.Add
      ('update pro_adi_personalizado_sabores set modificado_site = 0 where id_site in ('
      + Valor + ')');
    conexao.ExecuteSQL;

    conexao.SQL.Add
      ('select 0 as zero, (pro_adi_personalizado_sabores.id_site) as codigo from pro_adi_personalizado_sabores');
    conexao.SQL.Add
      ('join pro_adi_personalizado on pro_adi_personalizado.id = pro_adi_personalizado_sabores.id_pro_adi_personalizado');
    conexao.SQL.Add
      ('where pro_adi_personalizado_sabores.id_site > 0 and pro_adi_personalizado_sabores.ativo = 1');

    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonAdicionais.AddPair('active', Valor);

    conexao.SQL.Add
      ('select 0 as zero, (pro_adi_personalizado_sabores.id_site) as codigo from pro_adi_personalizado_sabores');
    conexao.SQL.Add
      ('join pro_adi_personalizado on pro_adi_personalizado.id = pro_adi_personalizado_sabores.id_pro_adi_personalizado');
    conexao.SQL.Add
      ('where pro_adi_personalizado_sabores.id_site > 0 and pro_adi_personalizado_sabores.ativo = 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonAdicionais.AddPair('disabled', Valor);

    JsonSabores := TJsonObject.Create;
    conexao.SQL.Add
      ('select 0 as zero, (id_site) as codigo from sabores_completo where id_site > 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonSabores.AddPair('all', Valor);
    conexao.SQL.Add
      ('update sabores_completo set modificado_site = 0 where id_site in (' +
      Valor + ')');
    conexao.ExecuteSQL;

    conexao.SQL.Add
      ('select 0 as zero, (id_site) as codigo from sabores_completo where id_site > 0 and ativo = 1');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonSabores.AddPair('active', Valor);

    conexao.SQL.Add
      ('select 0 as zero, (id_site) as codigo from sabores_completo where id_site > 0 and ativo = 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        Valor := Valor + ',' + Dados.FieldByName('codigo').AsString;
        Dados.Next;
      end;
    end;
    Dados.Free;
    JsonSabores.AddPair('disabled', Valor);

    JsonObject.AddPair('product', JsonProduto);
    JsonObject.AddPair('adicional', JsonAdicionais);
    JsonObject.AddPair('sabores', JsonSabores);

    IniFile.WriteString('ATIVA', 'JSON', JsonObject.ToString);

    Req := iRequisicao.Create(nil);
    Req.BaseURL := API_BASE_URL;
    Req.URL := 'api/empresa/atualiza/cardapio';
    Req.BODY(JsonObject);

    Req.Metodo := mPost;
    Req.Execute;
    Req.Free;

    AtualizaCacheSite;
    conexao.Free;
  except
    on E: Exception do
    begin
      // //showmessage(E.Message);
    end;
  end;
  IniFile.WriteDate('ATIVA', 'ATIVA', Date);
  IniFile.Free;
end;

procedure TfrmServidor.AtualizaCacheSite;
var
  Requisicao: iRequisicao;
  token: String;
begin
  Requisicao := iRequisicao.Create(nil);
  token := GerarTokenJWT(UserID);
  Requisicao.AddHEader('token', token);
  Requisicao.BaseURL := API_BASE_URL;
  Requisicao.URL := '/api/empresa/atualizacao/produto/' + UserID.ToString;
  Requisicao.Metodo := mPost;
  try
    Requisicao.Execute;

  except
    on E: Exception do
    begin

    end;
  end;

end;

procedure TfrmServidor.AtualizaDadosiFood;
var
  conexao: Tconexao;
begin

  if IntegracaoiFood then
  begin

    conexao := Tconexao.Create('main');
    conexao.SQL.Add
      ('update produto set valor_ifood = (valor_venda + ((valor_venda*' +
      FloatToStr(TaxaiFood) +
      ')/100)), atualizado = 0 where valor_venda <> (valor_venda + ((valor_venda*'
      + FloatToStr(TaxaiFood) + ')/100))');
    conexao.ExecuteSQL;
    conexao.Free;
  end;

end;

function TfrmServidor.ATUALIZADOR: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'atualizador.exe';
end;

procedure TfrmServidor.AtualizaSaldoEstoque;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Estoque: Real;
begin

  conexao := Tconexao.Create('EstoqueAtualiza');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT 0 as zero, codigo FROM produto where controle_estoque = 1');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin

    while not Dados.Eof do
    begin
      try
        conexao.SQL.Clear;
        conexao.SQL.Add
          ('select sum(quantidade) as qtd, 0 as zero from produto_estoque where codigo_produto = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        Estoque := conexao.FieldByName('qtd');
      except
        Estoque := 0;
      end;

      conexao.SQL.Clear;
      conexao.SQL.Add
        ('update produto set saldo_atual = :estoque where codigo = :codigo');
      conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
      conexao.Parametros('estoque', Estoque);
      conexao.ExecuteSQL;

      Dados.Next;
    end;
  end;

  Dados.Free;
  conexao.Free;

end;
//
// procedure TfrmServidor.AtualizaStatus(OrderHead: IADRIFoodModelOrderHead);
// var
// conexao: Tconexao;
// SQL: String;
// statuscod: String;
// Status: String;
// IFood: String;
// Codigo, CodigoIntermo: Integer;
// imprimir: Integer;
// begin
//
// statuscod := OrderHead.code;
// Status := OrderHead.fullCode;
// IFood := OrderHead.orderId;
//
// if OrderHead.code = 'CAN' then
// begin
// SQL := 'update pedido set status = 0, desc_desconto_ifood = motivo_cancelamento, status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
// end
// else
// begin
// if OrderHead.code = 'CAR' then
// begin
// SQL := 'update pedido set desc_desconto_ifood = "CANCELADO PELO GESTO", motivo_cancelamento = "CANCELADO PELO GESTO", status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
// end;
//
// SQL := 'update pedido set status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
// end;
// conexao := Tconexao.Create('main');
// conexao.SQL.Add(SQL);
// conexao.Parametros('id_ifood', IFood);
// conexao.Parametros('status_ifood', statuscod);
// conexao.Parametros('status_ifood_descricao', Status);
// conexao.ExecuteSQL;
//
// if OrderHead.code = 'CFM' then
// begin
// conexao.SQL.Add
// ('SELECT codigo, 0 as zero FROM pedido where id_ifood = :codigo');
// conexao.Parametros('codigo', IFood);
// CodigoIntermo := conexao.FieldByName('codigo');
//
// if CodigoIntermo > 0 then
// begin
//
// conexao.SQL.Add
// ('select * from impressao_pedido where id_pedido = :pedido');
// conexao.Parametros('pedido', CodigoIntermo);
// try
// imprimir := conexao.FieldByName('id');
// except
// imprimir := 0;
// end;
// // Imprimir
//
// if imprimir = 0 then
// begin
// Codigo := conexao.GerarID('impressao_pedido', 'id');
// conexao.SQL.Add
// ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
// conexao.Parametros('id', Codigo);
// conexao.Parametros('pedido', CodigoIntermo);
// conexao.ExecuteSQL;
// end;
//
// conexao.SQL.Add('UPDATE impressao_pedido_produto');
// conexao.SQL.Add('SET status = 0');
// conexao.SQL.Add('WHERE data_impressao IS NULL');
// conexao.SQL.Add
// ('AND id_pedido IN (SELECT codigo FROM pedido_produtos WHERE pedido_produtos.codigo_pedido = :pedido)');
// conexao.Parametros('pedido', CodigoIntermo);
// conexao.ExecuteSQL;
// end;
// end;
//
// conexao.Free;
//
// end;

procedure TfrmServidor.BuscaDadosiFood;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Codigo: Integer;
  Categoria: Integer;
  CodigoProduto: Integer;
  dataSetCategoy: TFDMemTable;
  memItens: TFDMemTable;
begin
  // dataSetCategoy := TFDMemTable.Create(nil);
  // conexao := Tconexao.Create('main');
  // IFood.Category.List(dataSetCategoy);
  // Dados := TFDMemTable.Create(self);
  //
  // if dataSetCategoy.RecordCount > 0 then
  // begin
  // dataSetCategoy.First;
  // while not dataSetCategoy.Eof do
  // begin
  // Dados.Close;
  // conexao.SQL.Add('select * from tipo_produto where upper(descricao) like '
  // + QuotedStr('%' + UpperCase(RemoveAcento(dataSetCategoy.FieldByName
  // ('name').AsString)) + '%') + ' or id_ifood = :ifood');
  // conexao.Parametros('ifood', dataSetCategoy.FieldByName('id').AsString);
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  // if Dados.RecordCount = 0 then
  // begin
  // Codigo := conexao.GerarID('tipo_produto', 'codigo');
  // conexao.SQL.Add
  // ('insert into tipo_produto (codigo,descricao,modificado_site,id_ifood) values (:codigo,:descricao,1,:id_ifood)');
  // conexao.Parametros('codigo', Codigo);
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(dataSetCategoy.FieldByName('name').AsString)));
  // conexao.Parametros('id_ifood', dataSetCategoy.FieldByName('id')
  // .AsString);
  // conexao.ExecuteSQL;
  // end
  // else
  // begin
  // Codigo := Dados.FieldByName('codigo').AsInteger;
  // end;
  // Categoria := Codigo;
  //
  // IFood.ProductItem.List(dataSetCategoy.FieldByName('id').AsString,
  // memItens, memItensPreco, memCategoriaExtra,
  // dataSetProductsItemsOptions);
  //
  // memItens.First;
  //
  // while not memItens.Eof do
  // begin
  // Dados.Close;
  // conexao.SQL.Add('select * from produto where id_ifood = ' +
  // QuotedStr(memItens.FieldByName('id').AsString));
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  // if Dados.RecordCount = 0 then
  // begin
  // try
  // conexao.SQL.Add
  // ('select * from produto where codigo_interno = :external or id_ifood = :ifood');
  // conexao.Parametros('external', FormatFloat('000000',
  // memItens.FieldByName('externalCode').AsInteger));
  // conexao.Parametros('ifood', memItens.FieldByName('id').AsString);
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  // except
  //
  // end;
  // end;
  // // Qual margem do ifood ?
  // // Tirar a margem do ifood
  // // *
  // if Dados.RecordCount = 0 then
  // begin
  // Codigo := conexao.GerarID('produto', 'codigo');
  // conexao.SQL.Clear;
  // conexao.SQL.Add
  // ('insert into produto (codigo,codigo_interno,data_cadastro,nome_produto,descricao,codigo_grupo,valor_venda,valor_ifood,ativo,observacao,modificado_site,id_ifood)');
  // conexao.SQL.Add
  // ('values (:codigo,:codigo_interno,current_date,:nome_produto,:descricao,:codigo_grupo,:valor_venda,:valor_ifood,0,1,1,:id_ifood)');
  // conexao.Parametros('codigo', Codigo);
  // conexao.Parametros('codigo_interno', FormatFloat('000000', Codigo));
  // conexao.Parametros('nome_produto',
  // UpperCase(RemoveAcento(memItens.FieldByName('name').AsString)));
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(memItens.FieldByName('description')
  // .AsString)));
  // conexao.Parametros('codigo_grupo', Categoria);
  // // MargemiFood
  // conexao.Parametros('valor_venda',
  // memItens.FieldByName('value').AsFloat);
  // conexao.Parametros('valor_ifood',
  // memItens.FieldByName('value').AsFloat);
  // conexao.Parametros('id_ifood', memItens.FieldByName('id').AsString);
  // conexao.ExecuteSQL;
  // end;
  //
  // conexao.SQL.Add
  // ('update produto set position = :position, nome_produto = :nome_produto, descricao = :descricao,');
  // conexao.SQL.Add
  // ('valor_venda = :valor_venda, valor_ifood = :valor_ifood, codigo_grupo = :codigo_grupo, ativo = :ativo, foto_ifood = :foto_ifood, pessoas = :pessoas where id_ifood = :id_ifood');
  // conexao.Parametros('nome_produto',
  // UpperCase(RemoveAcento(memItens.FieldByName('Name').AsString)));
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(memItens.FieldByName('Description')
  // .AsString)));
  // conexao.Parametros('codigo_grupo', Categoria);
  //
  // conexao.Parametros('valor_venda', memItens.FieldByName('value').AsFloat
  // - ((memItens.FieldByName('value').AsFloat * TaxaiFood) / 100));
  // conexao.Parametros('valor_ifood', memItens.FieldByName('value')
  // .AsFloat);
  // conexao.Parametros('id_ifood', memItens.FieldByName('id').AsString);
  // conexao.Parametros('pessoas', memItens.FieldByName('serving').AsString);
  // conexao.Parametros('position', memItens.FieldByName('sequence')
  // .AsString);
  //
  // //
  // if memItens.FieldByName('available').AsBoolean then
  // conexao.Parametros('ativo', '1')
  // else
  // conexao.Parametros('ativo', '0');
  // conexao.Parametros('foto_ifood',
  // ((memItens.FieldByName('imagepath').AsString)));
  // /// foto_ifood
  // /// available
  //
  // conexao.ExecuteSQL;
  //
  // memItens.Next;
  // end;
  //
  // memCategoriaExtra.First;
  // while not memCategoriaExtra.Eof do
  // begin
  //
  // conexao.SQL.Add('select * from produto where id_ifood = ' +
  // QuotedStr(memCategoriaExtra.FieldByName('productitemid').AsString));
  // try
  // CodigoProduto := conexao.FieldByName('codigo');
  // except
  //
  // end;
  // if Codigo > 0 then
  // begin
  // conexao.SQL.Add
  // ('select * from pro_adi_personalizado where id_ifood = ' +
  // QuotedStr(memCategoriaExtra.FieldByName('optiongroupid').AsString));
  // try
  // Codigo := conexao.FieldByName('id');
  // except
  // Codigo := 0;
  // end;
  // if Codigo = 0 then
  // begin
  // Codigo := conexao.GerarID('pro_adi_personalizado', 'id');
  // conexao.SQL.Add
  // ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,id_ifood)');
  // conexao.SQL.Add
  // ('values (:id,:id_produto,:descricao,1,:qtd_minima,:qtd_maxima,:id_ifood)');
  // conexao.Parametros('id', Codigo);
  // conexao.Parametros('id_produto', CodigoProduto);
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(memCategoriaExtra.FieldByName
  // ('optiongroupname').AsString)));
  // conexao.Parametros('qtd_minima',
  // memCategoriaExtra.FieldByName('min').AsInteger);
  // conexao.Parametros('qtd_maxima',
  // memCategoriaExtra.FieldByName('max').AsInteger);
  // conexao.Parametros('id_ifood',
  // memCategoriaExtra.FieldByName('optiongroupid').AsString);
  // conexao.ExecuteSQL;
  // end;
  //
  // conexao.SQL.Add
  // ('update pro_adi_personalizado set descricao = :descricao, qtd_minima = :qtd_minima, qtd_maxima = :qtd_maxima where id_ifood = :id_ifood');
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(memCategoriaExtra.FieldByName
  // ('optiongroupname').AsString)));
  // conexao.Parametros('qtd_minima', memCategoriaExtra.FieldByName('min')
  // .AsInteger);
  // conexao.Parametros('qtd_maxima', memCategoriaExtra.FieldByName('max')
  // .AsInteger);
  // conexao.Parametros('id_ifood',
  // memCategoriaExtra.FieldByName('optiongroupid').AsString);
  // conexao.ExecuteSQL;
  // end;
  //
  // memCategoriaExtra.Next;
  // end;
  // dataSetProductsItemsOptions.First;
  // while not dataSetProductsItemsOptions.Eof do
  // begin
  // conexao.SQL.Add('select * from pro_adi_personalizado where id_ifood = '
  // + QuotedStr(memCategoriaExtra.FieldByName('optiongroupid').AsString));
  // try
  // CodigoProduto := conexao.FieldByName('id');
  // except
  // CodigoProduto := 0;
  // end;
  //
  // if CodigoProduto > 0 then
  // begin
  // conexao.SQL.Add
  // ('select * from pro_adi_personalizado_sabores where id_ifood = ' +
  // QuotedStr(dataSetProductsItemsOptions.FieldByName('productId')
  // .AsString));
  // try
  // Codigo := conexao.FieldByName('id');
  // except
  // Codigo := 0;
  // end;
  // if Codigo = 0 then
  // begin
  // Codigo := conexao.GerarID('pro_adi_personalizado_sabores', 'id');
  // conexao.SQL.Add
  // ('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo,id_ifood)');
  // conexao.SQL.Add
  // ('values (:id,:id_pro_adi_personalizado,:nome,:descricao,:valor,:ativo,:id_ifood)');
  // conexao.Parametros('id', Codigo);
  // conexao.Parametros('id_pro_adi_personalizado', CodigoProduto);
  // conexao.Parametros('nome',
  // UpperCase(RemoveAcento(dataSetProductsItemsOptions.FieldByName
  // ('productname').AsString)));
  //
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(dataSetProductsItemsOptions.FieldByName
  // ('productDescription').AsString)));
  // conexao.Parametros('valor', dataSetProductsItemsOptions.FieldByName
  // ('value').AsFloat);
  // if dataSetProductsItemsOptions.FieldByName('available').AsBoolean
  // then
  // conexao.Parametros('ativo', '1')
  // else
  // conexao.Parametros('ativo', '0');
  // conexao.Parametros('id_ifood',
  // dataSetProductsItemsOptions.FieldByName('productId').AsString);
  // conexao.ExecuteSQL;
  // end;
  //
  // conexao.SQL.Add
  // ('update pro_adi_personalizado_sabores set nome = :nome, descricao = :descricao, valor = :valor, ativo = :ativo where id_ifood = :id_ifood');
  // conexao.Parametros('nome',
  // UpperCase(RemoveAcento(dataSetProductsItemsOptions.FieldByName
  // ('productname').AsString)));
  //
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(dataSetProductsItemsOptions.FieldByName
  // ('productdescription').AsString)));
  // conexao.Parametros('valor', dataSetProductsItemsOptions.FieldByName
  // ('value').AsFloat);
  // if dataSetProductsItemsOptions.FieldByName('available').AsBoolean then
  // conexao.Parametros('ativo', '1')
  // else
  // conexao.Parametros('ativo', '0');
  // conexao.Parametros('id_ifood', dataSetProductsItemsOptions.FieldByName
  // ('productId').AsString);
  // conexao.ExecuteSQL;
  //
  // end;
  //
  // dataSetProductsItemsOptions.Next;
  // end;
  //
  // // ////////showmessage1(memCategoriaExtra.ToJSONArray().ToString);
  //
  // dataSetCategoy.Next;
  // end;
  //
  // end;
  //
  // conexao.Free;

end;

procedure TfrmServidor.buscarAtualizacao(user: Integer);
var
  iReq: iRequisicao;
begin
  iReq := iRequisicao.Create(nil);
  iReq.BaseURL := API_BASE_URL;
  iReq.URL := 'api/atualizacoes/busca/atualizacao/' + user.ToString;
  try
    iReq.Execute;

    if iReq.Status <> 404 then
    begin
      // Abrir exe
      AbrirExe(ATUALIZADOR);
    end;

  except

  end;
end;

procedure TfrmServidor.BuscarModulo;
var
  Requisicao: iRequisicao;
  memo: TMemo;
begin
  memo := TMemo.Create(self);
  memo.Parent := self;
  Requisicao := iRequisicao.Create(self);
  Requisicao.BaseURL := API_BASE_URL;

  Requisicao.URL := 'api/modulos?user=' + UserID.ToString;
  try
    Requisicao.Execute;
    memo.Lines.Text := Requisicao.Retorno;
    memo.Lines.SaveToFile('conf.js');
    Modulos := TJsonObject.ParseJSONValue(Requisicao.Retorno) as TJsonObject;
  except
    on E: Exception do
    begin
      // Modulos := TJsonObject.Create;

    end;
  end;
  memo.Free;
  Requisicao.Free;

end;

procedure TfrmServidor.Button1Click(Sender: TObject);
begin
  ClientSocket.SocketClient.RegisterCallback('/produtos', SocketProdutos)
    .Connect('localhost', 8050, '@brst');
end;

procedure TfrmServidor.ComandaStatus;
begin
  DataHoraImpressaoServiceComanda := now;
  ImpressoraStatus;
end;

function TfrmServidor.ConverteValoriFood(Valor: String): Real;
begin
  Result := StrToFloat(StringReplace(Valor, ',', '.', [rfReplaceAll]));
end;

procedure TfrmServidor.CozinhaStatus;
begin

  DataHoraImpressaoServiceCozinha := now;
  ImpressoraStatus;

end;

function TfrmServidor.CreateiFoodConnection(Name, MerchantID: String): String;

begin


end;

procedure TfrmServidor.DadosApiWhatsapp;
var
  Req: iRequisicao;
  JsonObject: TJsonObject;
  ErrorValue: Boolean;
  user: TJsonObject;
begin
  ContadorDePedidos;
  if UserID > 0 then
  begin
    Req := iRequisicao.Create(nil);
    Req.BaseURL := API_BASE_URL;
    Req.URL := 'api/whatsapp/instancia?user_id=' + UserID.ToString;
    try
      Req.Execute;
      JsonObject := TJsonObject.ParseJSONValue(Req.Retorno) as TJsonObject;
      if Assigned(JsonObject) then
      begin
        if JsonObject.GetValue<String>('status') = 'connecting' then
        begin
          Base64Whatsapp := StringReplace(JsonObject.GetValue<String>('qrcod'),
            'data:image/png;base64,', '', [rfReplaceAll]);
          NomeWhatsapp := '';
          ImagemWhatsapp := '';
          NumeroWhatsapp := '';
          StatusWhatsapp := False;
        end;

        if JsonObject.GetValue<String>('status') = 'connected' then
        begin
          NomeWhatsapp := JsonObject.GetValue<String>('nome');
          ImagemWhatsapp := JsonObject.GetValue<String>('foto');
          // NumeroWhatsapp := FormatPhoneNumber(JsonObject.GetValue<String>('ownerJid'));
          NumeroWhatsapp := '';
          StatusWhatsapp := true;
        end;

        if JsonObject.GetValue<String>('status') = 'connecting' then
        begin

        end;

      end;

    except

    end;

    // Req := iRequisicao.Create(nil);
    // Req.BaseURL := 'https://old.goopedir.com/whatsapp/status.php?instance=' +
    // UserID.ToString;
    // Req.TempoExpiracao := 15 * 1000;
    // try
    // Req.Execute;
    // ErrorValue := false;
    // JsonObject := TJsonObject.ParseJSONValue(Req.Retorno) as TJsonObject;
    // if Assigned(JsonObject) then
    // begin
    // try
    // ErrorValue := JsonObject.GetValue<Boolean>('error');
    // except
    //
    // end;
    // if not ErrorValue then
    // begin
    // user := JsonObject.GetValue<TJsonObject>('instance');
    //
    // if user.GetValue<String>('state') = 'open' then
    // begin
    // // Pegar dados
    // DadosWhatsapp;
    // StatusMensagemWhatsapp := 1;
    // end
    // else
    // begin
    // // Buscar QRCod
    // DadosQrCod;
    // StatusMensagemWhatsapp := 2;
    // end;
    // user.Free;
    // StatusInstanciaCriada := true;
    // end;
    // end;
    // except
    // on E: Exception do
    // begin
    // StatusErroWhatsapp := E.Message;
    // StatusMensagemWhatsapp := 3;
    // end;
    // end;
    Req.Free;
  end;

end;

procedure TfrmServidor.DadosBloqueio;
var
  Difference: Integer;
  Requisicao: iRequisicao;
begin

  try
    // frmServidor.setUser;
    Requisicao := iRequisicao.Create(nil);
    Requisicao.URL := 'https://old.goopedir.com/v1/faturasn/' +
      frmServidor.UserID.ToString + '/a';
    Requisicao.TempoExpiracao := 60 * 1000;
    Requisicao.Execute;

    if SemDataBloqueio then
    begin
      frmServidor.DataBloqueio := IncDay(Date, -10);
    end;

    if frmServidor.DataBloqueio = Date then
      Difference := 1
    else
      Difference := DaysBetween(Date, frmServidor.DataBloqueio);

    if Date > frmServidor.DataBloqueio then
      Difference := 0;

    if Assigned(JsonDadosBloqueio) then
      JsonDadosBloqueio.Free;

    if Requisicao.Retorno = 'null' then
    begin
      Faturas := TJsonArray.Create;
    end
    else
    begin
      Faturas := TJsonArray.ParseJSONValue(Requisicao.Retorno) as TJsonArray;
    end;

    JsonDadosBloqueio := TJsonObject.Create;
    JsonDadosBloqueio.AddPair('vencimento',
      DateToStr(frmServidor.DataBloqueio));
    JsonDadosBloqueio.AddPair('dias', Difference);
    JsonDadosBloqueio.AddPair('user', frmServidor.UserID);
    JsonDadosBloqueio.AddPair('faturas', Faturas);
    if (FormatDateTime('yyyy', DataConfianca) = FormatDateTime('yyyy', now)) and
      (FormatDateTime('mm', DataConfianca) = FormatDateTime('mm', now)) then
    begin
      JsonDadosBloqueio.AddPair('confianca', False);
    end
    else
    begin
      JsonDadosBloqueio.AddPair('confianca', true);
    end;

  except
    on E: Exception do
    begin
      // Res.Send(E.Message);
      JsonDadosBloqueio := TJsonObject.Create;

    end;

  end;

end;

function TfrmServidor.DadosProdutos: TJsonArray;
var
  Categoria: TFDMemTable;
  JsonObjeto: TJsonObject;
  PRODUTOS: TFDMemTable;
begin
  // Categoria := TFDMemTable.Create(nil);
  // IFood.Category.List(Categoria);
  // Result := TJsonArray.Create;
  //
  // Categoria.First;
  // while not Categoria.Eof do
  // begin
  // PRODUTOS := TFDMemTable.Create(nil);
  // JsonObjeto := TJsonObject.Create;
  // JsonObjeto.AddPair('id', Categoria.FieldByName('id').AsString);
  // JsonObjeto.AddPair('name', Categoria.FieldByName('name').AsString);
  // IFood.Item.List(Categoria.FieldByName('id').AsString, PRODUTOS);
  // JsonObjeto.AddPair('produtos', PRODUTOS.ToJSONArray());
  // Result.Add(JsonObjeto);
  // Categoria.Next;
  // end;

end;

procedure TfrmServidor.DadosQrCod;
var
  Req: iRequisicao;
  JsonObject: TJsonObject;
begin

  Req := iRequisicao.Create(nil);
  Req.BaseURL := 'https://old.goopedir.com/whatsapp/qrcod.php?instance=' +
    UserID.ToString;
  Req.TempoExpiracao := 20 * 1000;
  try
    Req.Execute;

    JsonObject := TJsonObject.ParseJSONValue(Req.Retorno) as TJsonObject;
    if Assigned(JsonObject) then
    begin
      try
        Base64Whatsapp := StringReplace(JsonObject.GetValue<String>('base64'),
          'data:image/png;base64,', '', [rfReplaceAll]);
        NomeWhatsapp := '';
        ImagemWhatsapp := '';
        NumeroWhatsapp := '';
        StatusWhatsapp := False;
      except

      end;
      // Base64Whatsapp := JsonObject.GetValue<String>('base64');
      // StatusWhatsapp := true;
    end;

  except

  end;
  Req.Free;

end;

procedure TfrmServidor.DadosWhatsapp;
var
  Req: iRequisicao;
  JsonObject: TJsonObject;
begin

  Req := iRequisicao.Create(nil);
  Req.BaseURL := 'https://old.goopedir.com/whatsapp/instancia.php?instanceName='
    + UserID.ToString;
  Req.TempoExpiracao := 15 * 1000;
  try
    Req.Execute;

    JsonObject := TJsonObject.ParseJSONValue(Req.Retorno) as TJsonObject;
    if Assigned(JsonObject) then
    begin
      NomeWhatsapp := JsonObject.GetValue<String>('profileName');
      ImagemWhatsapp := JsonObject.GetValue<String>('profilePicUrl');
      NumeroWhatsapp := FormatPhoneNumber
        (JsonObject.GetValue<String>('ownerJid'));
      StatusWhatsapp := true;
    end;

  except
    on E: Exception do
    begin
      // ////////showmessage1(e.Message);

    end;

  end;
  Req.Free;

end;

function TfrmServidor.DoGetCaixaCincoCategoria(Codigo: Integer): TJsonArray;
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('imprimir');
  conexao.SQL.Add('SELECT');
  conexao.SQL.Add('    p.id_caixa AS id,');
  conexao.SQL.Add('    UPPER(tp.descricao) AS produto,');
  conexao.SQL.Add('    sum(pp.quantidade) AS quantidade,');
  conexao.SQL.Add
    ('    COALESCE(SUM(pp.valor_total - pp.valor_adicional), 0) AS total,');
  conexao.SQL.Add
    ('    COALESCE(SUM(pp.valor_adicional), 0) AS total_adicional,');
  conexao.SQL.Add
    ('    COALESCE(SUM(pp.valor_total - pp.valor_adicional), 0) + COALESCE(SUM(pp.valor_adicional), 0) AS total_geral');
  conexao.SQL.Add('FROM pedido AS p');
  conexao.SQL.Add('JOIN pedido_produtos AS pp ON pp.codigo_pedido = p.codigo');
  conexao.SQL.Add('JOIN produto AS prod ON prod.codigo = pp.codigo_produto');
  conexao.SQL.Add('JOIN tipo_produto AS tp ON tp.codigo = prod.codigo_grupo');
  conexao.SQL.Add('WHERE p.id_caixa = :id');
  conexao.SQL.Add('GROUP BY UPPER(tp.descricao)');
  conexao.SQL.Add('ORDER BY sum(pp.quantidade) DESC;');
  conexao.Parametros('id', Codigo);
  Result := TJsonArray.Create;
  Result := conexao.ConsultaSQL;
  conexao.Free;
end;

function TfrmServidor.DoGetCaixaCincoProduto(Codigo: Integer): TJsonArray;
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('imprimir');
  conexao.SQL.Add('SELECT');
  conexao.SQL.Add('    p.id_caixa AS id,');
  conexao.SQL.Add('    UPPER(prod.nome_produto) AS produto,');
  conexao.SQL.Add('    sum(pp.quantidade) AS quantidade,');
  conexao.SQL.Add
    ('    COALESCE(SUM(pp.valor_total - pp.valor_adicional), 0) AS total,');
  conexao.SQL.Add
    ('    COALESCE(SUM(pp.valor_adicional), 0) AS total_adicional,');
  conexao.SQL.Add
    ('    COALESCE(SUM(pp.valor_total - pp.valor_adicional), 0) + COALESCE(SUM(pp.valor_adicional), 0) AS total_geral');
  conexao.SQL.Add('FROM pedido AS p');
  conexao.SQL.Add('JOIN pedido_produtos AS pp ON pp.codigo_pedido = p.codigo');
  conexao.SQL.Add('JOIN produto AS prod ON prod.codigo = pp.codigo_produto');
  conexao.SQL.Add('WHERE p.id_caixa = :id');
  conexao.SQL.Add('GROUP BY UPPER(prod.nome_produto)');
  conexao.SQL.Add('ORDER BY sum(pp.quantidade) DESC;');

  conexao.Parametros('id', Codigo);
  Result := TJsonArray.Create;
  Result := conexao.ConsultaSQL;
  conexao.Free;
end;

function TfrmServidor.DoGetCaixaTres(Codigo: Integer): TJsonArray;
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('imprimir');
  conexao.SQL.Add('SELECT');
  conexao.SQL.Add('    MAX(c.id) as id,');
  conexao.SQL.Add('    MAX( DATE_FORMAT(c.data_abertura, ' +
    QuotedStr('%d/%m/%Y') + ')) as data_abertura,');
  conexao.SQL.Add('    MAX(TIME_FORMAT(c.hora_abertura, ' + QuotedStr('%H:%i') +
    ')) as hora_abertura,');
  conexao.SQL.Add('    MAX( DATE_FORMAT(c.data_fechamento, ' +
    QuotedStr('%d/%m/%Y') + ')) as data_fechamento,');
  conexao.SQL.Add('    MAX(TIME_FORMAT(c.hora_fechamento, ' + QuotedStr('%H:%i')
    + ')) as hora_fechamento,');
  conexao.SQL.Add('    MAX(c.valor_abertura) as valor_abertura,');
  conexao.SQL.Add('    MAX(c.valor_fechamento) as valor_fechamento,');
  conexao.SQL.Add('    tp.descricao,');
  conexao.SQL.Add('    SUM(cm.valor) AS valor,');
  conexao.SQL.Add
    ('    (select nome from usuario where codigo = id_usuario) as usuario,');
  conexao.SQL.Add('    COALESCE(SUM(cm.valor), 0) as valor_tipo_pagamento,');
  conexao.SQL.Add
    ('    COALESCE((SELECT SUM(pl.valor_total_pedido) FROM pedido AS pl WHERE pl.id_caixa = c.id AND pl.codigo_cliente_endereco = 0 AND pl.id_ficha > 0), 0) as valor_mesa,');
  conexao.SQL.Add
    ('    COALESCE((SELECT SUM(pl.valor_total_pedido) FROM pedido AS pl WHERE pl.id_caixa = c.id AND pl.codigo_cliente_endereco = 0 AND (pl.id_ficha IS NULL or pl.id_ficha = 0)), 0) as valor_vem_buscar,');
  conexao.SQL.Add
    ('    COALESCE((SELECT SUM(pl.valor_pedido) FROM pedido AS pl WHERE pl.id_caixa = c.id AND pl.codigo_cliente_endereco > 0), 0) as valor_delivery,');
  conexao.SQL.Add
    ('    COALESCE((SELECT SUM(pl.valor_taxa_entrega) FROM pedido AS pl WHERE pl.id_caixa = c.id AND pl.codigo_cliente_endereco > 0), 0) as taxa_entrega,');
  conexao.SQL.Add
    ('    COALESCE((c.valor_fechamento - (SELECT SUM(pl.valor_total_pedido) FROM pedido AS pl WHERE pl.id_caixa = c.id)), 0) as valor_diferenca,');
  conexao.SQL.Add
    ('    COALESCE((SELECT SUM(valor) FROM caixa_movimento WHERE tipo = 2 AND id_caixa = :id), 0) as sangria,');
  conexao.SQL.Add
    ('    COALESCE((SELECT SUM(servico) FROM pedido WHERE id_caixa = :id), 0) as servico');
  conexao.SQL.Add('FROM ');
  conexao.SQL.Add('    caixa AS c');
  conexao.SQL.Add('JOIN');
  conexao.SQL.Add('    caixa_movimento AS cm ON cm.id_caixa = c.id');
  conexao.SQL.Add('JOIN');
  conexao.SQL.Add('    pedido AS p ON p.codigo = cm.id_pedido');
  conexao.SQL.Add('JOIN');
  conexao.SQL.Add
    ('    tipo_pagamento AS tp ON tp.codigo = cm.id_tipo_pagamento');
  conexao.SQL.Add('WHERE');
  conexao.SQL.Add('    c.id = :id AND cm.tipo = 1');
  conexao.SQL.Add('GROUP BY');
  conexao.SQL.Add('    c.id, tp.codigo, tp.descricao;');
  conexao.Parametros('id', Codigo);
  Result := TJsonArray.Create;
  Result := conexao.ConsultaSQL;
  conexao.Free;

end;

function TfrmServidor.DoGetCaixaTresLancado(Codigo: Integer): TJsonArray;
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('imprimir');
  conexao.SQL.Add('SELECT');
  conexao.SQL.Add('    MIN(caixa_movimento.id) AS id,');
  conexao.SQL.Add('    IFNULL(upper(tipo_pagamento.descricao), ' +
    QuotedStr('SANGRIA') + ') AS descricao,');
  conexao.SQL.Add('    SUM(caixa_movimento.valor) AS valor');
  conexao.SQL.Add('FROM');
  conexao.SQL.Add('    caixa');
  conexao.SQL.Add('JOIN');
  conexao.SQL.Add('    caixa_movimento ON caixa_movimento.id_caixa = caixa.id');
  conexao.SQL.Add('LEFT JOIN');
  conexao.SQL.Add
    ('    tipo_pagamento ON tipo_pagamento.codigo = caixa_movimento.id_tipo_pagamento  and tipo_pagamento.codigo > 0');
  conexao.SQL.Add('WHERE');
  conexao.SQL.Add
    ('    caixa.id = :id AND caixa_movimento.tipo IN (262626, 2) AND caixa_movimento.valor > 0');
  conexao.SQL.Add('GROUP BY');
  conexao.SQL.Add('    descricao;');
  conexao.Parametros('id', Codigo);
  Result := TJsonArray.Create;
  Result := conexao.ConsultaSQL;
  conexao.Free;

end;

function TfrmServidor.DoGetCaixaTresSangria(Codigo: Integer): TJsonArray;
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('imprimir');
  conexao.SQL.Add
    ('select  CONVERT(TRIM(BOTH '' '' FROM REPLACE(SUBSTRING(descricao, LOCATE(''-'', descricao) + 1), ''-'', '''')) USING utf8)  AS descricao, valor from caixa_movimento where tipo = 2 and id_caixa = :id');
  conexao.Parametros('id', Codigo);
  Result := TJsonArray.Create;
  Result := conexao.ConsultaSQL;
  conexao.Free;

end;

procedure TfrmServidor.EnviaGlitchtip(DSN, Tipo, Identificacao,
  Mensagem: String);
var
  JsonObjec, JSONBody, ExceptionObj, ExceptionVal, Tags: TJsonObject;
  ExceptionArr: TJsonArray;
  Chave, API, URL: string;
  iGlitchtip: iRequisicao;
begin
  iGlitchtip := iRequisicao.Create(nil);

  // Extrai a chave e a URL da DSN
  Chave := Copy(DSN, pos('//', DSN) + 2, pos('@', DSN) - pos('//', DSN) - 2);
  URL := Copy(DSN, pos('@', DSN) + 1, length(DSN));
  URL := StringReplace(URL, '/api/', '/api/' + Chave + '/store/', []);
  API := Copy(URL, pos('/', URL) + 1, length(URL));
  URL := StringReplace(URL, '/' + API, '', []);

  // Monta JSON
  JSONBody := TJsonObject.Create;
  JSONBody.AddPair('event_id', GenerateUUID);
  JSONBody.AddPair('timestamp',
    FormatDateTime('yyyy-mm-dd"T"hh":"nn":"ss"Z"', now));
  JSONBody.AddPair('level', Tipo);
  JSONBody.AddPair('platform', 'delphi');
  JSONBody.AddPair('message', Identificacao);

  // exception
  ExceptionObj := TJsonObject.Create;
  ExceptionVal := TJsonObject.Create;
  ExceptionVal.AddPair('type', UpperCase(Tipo));
  ExceptionVal.AddPair('value', Mensagem);

  ExceptionArr := TJsonArray.Create;
  ExceptionArr.AddElement(ExceptionVal);
  ExceptionObj.AddPair('values', ExceptionArr);
  JSONBody.AddPair('exception', ExceptionObj);

  // tags
  Tags := TJsonObject.Create;
  if (GetEnvironmentVariable('COMPUTERNAME') = 'ALLAN-PC') then
  begin
    Tags.AddPair('environment', 'desenvolvimento');
  end
  else
  begin
    Tags.AddPair('environment', 'produção');
  end;

  Tags.AddPair('user', GetEnvironmentVariable('COMPUTERNAME'));
  JSONBody.AddPair('tags', Tags);

  // wrapper para envio
  JsonObjec := TJsonObject.Create;
  JsonObjec.AddPair('url', 'https://' + URL + '/api/' + API + '/store/');
  JsonObjec.AddPair('autorizacao', Chave);
  JsonObjec.AddPair('body', JSONBody);

  iGlitchtip.URL := 'https://old.goopedir.com/glitchtip/index.php';
  iGlitchtip.BODY(JsonObjec);

  try
    iGlitchtip.Metodo := mPost;
    iGlitchtip.Execute;
  except
    on E: Exception do
    begin
      // tratamento
    end;
  end;

  iGlitchtip.Free;
end;

procedure TfrmServidor.EnvioCaixa;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin
  conexao := Tconexao.Create('EnvioCaixa');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT 0 as zero, id FROM caixa where id_site = 0 and data_fechamento is not null');
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      SincronizaCaixa(Dados.FieldByName('id').AsInteger);
      Dados.Next;
    end;

  end;
  Dados.Free;
  conexao.Free;
end;

procedure TfrmServidor.ExecutarSQLScript(const SQLText: string);
var
  Lista: TStringList;
  Qry: TFDQuery;
  i, Tentativas: Integer;
  ComandoAtual: string;
  Pendentes, Erros: TStringList;
  ExecucaoRestante: Boolean;
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('ExecutarSQLScript');
  Lista := TStringList.Create;
  Pendentes := TStringList.Create;
  Erros := TStringList.Create;
  Qry := conexao.CriaQRY;
  try
    Lista.Text := SQLText;
    ComandoAtual := '';

    // Primeira rodada: executa tudo possível
    for i := 0 to Lista.Count - 1 do
    begin
      if (trim(Lista[i]) = '') or (trim(Lista[i]).StartsWith('--')) or
        (trim(Lista[i]).StartsWith('/*!')) or
        (trim(Lista[i]).StartsWith('LOCK TABLES')) or
        (trim(Lista[i]).StartsWith('UNLOCK TABLES')) or
        (trim(Lista[i]).StartsWith('ALTER TABLE')) then
        Continue;

      ComandoAtual := ComandoAtual + sLineBreak + Lista[i];

      if pos(';', Lista[i]) > 0 then
      begin
        try
          Qry.SQL.Clear;
          Qry.SQL.Text := ComandoAtual;
          Qry.ExecSQL;
        except
          on E: Exception do
          begin
            if pos('Failed to open the referenced table', E.Message) > 0 then
            begin
              // Se for erro de foreign key, adia
              Pendentes.Add(ComandoAtual);
            end
            else
              raise Exception.Create('Erro executando SQL: ' + E.Message +
                sLineBreak + 'Comando: ' + ComandoAtual);
          end;
        end;
        ComandoAtual := '';
      end;
    end;

    // Agora tenta executar os pendentes
    Tentativas := 0;
    repeat
      ExecucaoRestante := False;
      Inc(Tentativas);

      for i := Pendentes.Count - 1 downto 0 do
      begin
        try
          Qry.SQL.Clear;
          Qry.SQL.Text := Pendentes[i];
          Qry.ExecSQL;
          Pendentes.Delete(i); // Deu certo, remove da lista
        except
          on E: Exception do
          begin
            if (Tentativas >= 3) then
            begin
              // Se já tentou 3x e não deu, grava no erro
              Erros.Add(Pendentes[i]);
              Pendentes.Delete(i);
            end
            else
              ExecucaoRestante := true; // Ainda tem pendente, mais uma rodada
          end;
        end;
      end;

    until (not ExecucaoRestante) or (Tentativas >= 3);

    // Se sobrou algum erro grave, salva o log
    if Erros.Count > 0 then
    begin
      Erros.SaveToFile(ExtractFilePath(ParamStr(0)) + 'log_erros_sql.txt');
      // //showmessage
      // ('Alguns comandos SQL não puderam ser executados. Veja o arquivo log_erros_sql.txt');
    end;

  finally
    Qry.Free;
    Lista.Free;
    Pendentes.Free;
    Erros.Free;
  end;
end;

procedure TfrmServidor.ExtornoPedidoNaoFinalizado;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  PRODUTOS: TFDMemTable;
begin
  try
    conexao := Tconexao.Create('ExtornoPedidoNaoFinalizado');
    // conexao.SQL.Add('SELECT 0 as zero, codigo FROM pedido where status = -1 and id_ficha = 0 and data_pedido <= curdate() and hora_pedido < DATE_SUB(current_time(), INTERVAL 15 MINUTE) and valor_pedido > 0');
    conexao.SQL.Add
      ('SELECT 0 as zero, codigo FROM pedido where status = -1 and (id_ficha = 0 or id_ficha is null) and data_pedido <= curdate() and hora_pedido < DATE_SUB(current_time(), INTERVAL 5 MINUTE)');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);

    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        PRODUTOS := TFDMemTable.Create(nil);
        conexao.SQL.Add
          ('select codigo, 0 as zero from pedido_produtos where codigo_pedido = :pedido');
        conexao.Parametros('pedido', Dados.FieldByName('codigo').AsInteger);
        PRODUTOS.LoadFromJSON(conexao.ConsultaSQL);

        if PRODUTOS.RecordCount > 0 then
        begin
          while not PRODUTOS.Eof do
          begin
            ApagarProduto(PRODUTOS.FieldByName('codigo').AsInteger,
              'Pedido não concluido no tempo, produto estornado para correção do estoque! (Automático)',
              -1);
            PRODUTOS.Next;
          end;

        end;

        PRODUTOS.Free;

        conexao.SQL.Add('delete from pedido where codigo = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        conexao.ExecuteSQL;

        Dados.Next;
      end;
    end;

    Dados.Free;
    conexao.Free;
  except

  end;

end;

function TfrmServidor.FazerBackupMySQL(conexao: Tconexao): Boolean;
var
  MySQLDumpPath, PastaBackup, CmdLine: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  ExitCode: DWORD;
begin
  Result := False;

  PastaBackup := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) +
    'backup\bd');
  ForceDirectories(PastaBackup);
  NomeArquivoBackup := Format('%s%s_%s.sql', [PastaBackup, conexao.NomeBanco,
    FormatDateTime('yyyymmdd', now) // evita colisão/overwrite
    ]);

  if FileExists(NomeArquivoBackup) then
  begin
    tBackupFTP.Enabled := true;
    exit;
  end;

  MySQLDumpPath := GetMySQLDumpPath;
  // ex.: C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe
  if (MySQLDumpPath = '') or (not FileExists(MySQLDumpPath)) then
  begin
    // //showmessage('mysqldump.exe não encontrado.');
    exit;
  end;

  // IMPORTANTE:
  // - sem redirecionamento ">"
  // - grava direto com --result-file
  // - flags para bases grandes e InnoDB
  // - GTID OFF evita barulho quando não precisa de replicação
  // - hex-blob garante binários seguros
  CmdLine := '"' + MySQLDumpPath + '"' + ' -h' + conexao.Servidor + ' -P' +
    (conexao.Porta) + ' -u' + conexao.Usuario + ' -p' + conexao.Senha +
  // se a senha tiver caracteres especiais, considere usar --defaults-file (ver nota abaixo)
    ' --databases ' + conexao.NomeBanco +
    ' --single-transaction --quick --hex-blob' +
    ' --routines --events --triggers' + ' --set-gtid-purged=OFF' +
    ' --default-character-set=utf8mb4' + ' --max-allowed-packet=512M' +
    ' --result-file="' + NomeArquivoBackup + '"';

  ZeroMemory(@SI, SizeOf(SI));
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE;

  ZeroMemory(@PI, SizeOf(PI));

  if not CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_NO_WINDOW,
    nil, nil, SI, PI) then
    exit;

  try
    WaitForSingleObject(PI.hProcess, INFINITE);
    if GetExitCodeProcess(PI.hProcess, ExitCode) then
    begin
      // mysqldump retorna 0 em sucesso
      if (ExitCode = 0) and FileExists(NomeArquivoBackup) and
        (FileSizeByName(NomeArquivoBackup) > 0) then
      begin
        Result := true;
        tBackupFTP.Enabled := true;
      end
      else
      begin
        // dica: logue ExitCode e gere um .log com stderr (ver seção “Logs”, abaixo)
        // ////showmessage(Format('mysqldump falhou. ExitCode=%d', [ExitCode]));
      end;
    end;
  finally
    CloseHandle(PI.hThread);
    CloseHandle(PI.hProcess);
  end;
end;

procedure TfrmServidor.FazExclusaoClientes;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  DadosCliente: TFDMemTable;
  Codigo: Integer;
begin

  conexao := Tconexao.Create('main');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add
    ('SELECT celular, 0 as zero FROM cliente GROUP BY celular HAVING COUNT(celular) > 1;');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin

    while not Dados.Eof do
    begin
      DadosCliente := TFDMemTable.Create(nil);
      conexao.SQL.Add('select ');
      conexao.SQL.Add('codigo,nome,celular,cpf,');
      conexao.SQL.Add
        ('(select count(*) from pedido where pedido.codigo_cliente = cliente.codigo) as pedidos,');
      conexao.SQL.Add
        ('(select count(*) from cliente_endereco where cliente_endereco.codigo_cliente = cliente.codigo) as endereco,');
      conexao.SQL.Add
        ('(select count(*) from caixa_receber where id_cliente = cliente.codigo) as pagar');
      conexao.SQL.Add('from cliente where celular = ' +
        QuotedStr(Dados.FieldByName('celular').AsString));
      conexao.SQL.Add('order by cpf desc,nome desc, celular desc');
      DadosCliente.LoadFromJSON(conexao.ConsultaSQL);
      if DadosCliente.RecordCount > 0 then
      begin
        Codigo := DadosCliente.FieldByName('codigo').AsInteger;
        DadosCliente.Next;
        while not DadosCliente.Eof do
        begin
          conexao.SQL.Add
            ('update pedido set codigo_cliente = :cliente where codigo_cliente = :old');
          conexao.Parametros('cliente', Codigo);
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          conexao.SQL.Add
            ('update cliente_endereco set codigo_cliente = :cliente where codigo_cliente = :old');
          conexao.Parametros('cliente', Codigo);
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          conexao.SQL.Add
            ('update caixa_receber set id_cliente = :cliente where id_caixa = :old');
          conexao.Parametros('cliente', Codigo);
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          conexao.SQL.Add('delete from cliente where codigo = :old');
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          DadosCliente.Next;
        end;
        DadosCliente.Free;
      end;

      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;

end;

procedure TfrmServidor.Fechar1Click(Sender: TObject);
begin
  FecharExe(ExtractFileDir(Application.ExeName) + '\ServicosGoopedir.exe');
  FecharExe('ServicosGoopedir.exe');
  FecharExe(frmServidor.IMPRESSAO);
  FecharExe(frmServidor.WHATSAPP);
  FecharExe(frmServidor.SITE(NomeExeSite));
  FecharExe(frmServidor.USANFCE);
  FecharExe(Application.ExeName);
  FecharExe('GooPedir.exe');
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
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
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

procedure TfrmServidor.FecharServioSite1Click(Sender: TObject);
begin
  FecharExe(frmServidor.SITE(NomeExeSite));
end;

procedure TfrmServidor.FichaTecnica;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  DadosProduto: TFDMemTable;
  Ingrediente: String;
  CodigoIngrediente: Integer;
  Codigo: Integer;
  i: Integer;
begin

  conexao := Tconexao.Create('main');
  try
    if frmServidor.Configuracoes.FieldByName('ficha_tecnica').AsInteger = 1 then
    begin

      Dados := TFDMemTable.Create(nil);
      DadosProduto := TFDMemTable.Create(nil);
      conexao.SQL.Add
        ('SELECT group_concat(pro_adi_personalizado.id_produto) as produtos, group_concat(pro_adi_personalizado_sabores.id) as ids, upper(pro_adi_personalizado_sabores.nome) as nome  FROM pro_adi_personalizado');
      conexao.SQL.Add
        ('join pro_adi_personalizado_sabores on pro_adi_personalizado_sabores.id_pro_adi_personalizado = pro_adi_personalizado.id');
      conexao.SQL.Add('where pro_adi_personalizado_sabores.valor = 0');
      conexao.SQL.Add('group by upper(pro_adi_personalizado_sabores.nome)');
      Dados.LoadFromJSON(conexao.ConsultaSQL);
      if Dados.RecordCount > 0 then
      begin

        while not Dados.Eof do
        begin
          DadosProduto.Close;
          conexao.SQL.Add('select * from produto where codigo in (' +
            Dados.FieldByName('produtos').AsString + ')');
          DadosProduto.LoadFromJSON(conexao.ConsultaSQL);

          Ingrediente := RemoveAcento(Dados.FieldByName('nome').AsString);
          Ingrediente := StringReplace(Ingrediente, 'SEM ', '', [rfReplaceAll]);
          for i := 0 to 9 do
          begin
            Ingrediente := StringReplace(Ingrediente, i.ToString, '',
              [rfReplaceAll]);
          end;
          Ingrediente := trim(Ingrediente);

          conexao.SQL.Add('select * from ingredientes where descricao = ' +
            QuotedStr(Ingrediente));
          try
            CodigoIngrediente := conexao.FieldByName('id');
          except
            CodigoIngrediente := 0
          end;
          if CodigoIngrediente = 0 then
          begin
            CodigoIngrediente := conexao.GerarID('ingredientes', 'id');
            conexao.SQL.Add
              ('insert into ingredientes (id,descricao,unidade) values (:id,:descricao,:unidade)');
            conexao.Parametros('id', CodigoIngrediente);
            conexao.Parametros('descricao', Ingrediente);
            conexao.Parametros('unidade', 'UN');

            conexao.ExecuteSQL;
          end;
          while not DadosProduto.Eof do
          begin
            conexao.SQL.Add
              ('select * from produto_ingredientes where id_produto = :id_produto and id_ingredientes = :id_ingredientes');
            conexao.Parametros('id_ingredientes', CodigoIngrediente);
            conexao.Parametros('id_produto', DadosProduto.FieldByName('codigo')
              .AsInteger);

            try
              Codigo := conexao.FieldByName('id');

            except
              Codigo := 0;

            end;

            if Codigo = 0 then
            begin
              Codigo := conexao.GerarID('produto_ingredientes', 'id');
              conexao.SQL.Add
                ('insert into produto_ingredientes (id,id_produto,id_ingredientes,quantidade) values (:id,:id_produto,:id_ingredientes,:quantidade)');
              conexao.Parametros('id', Codigo);
              conexao.Parametros('id_produto',
                DadosProduto.FieldByName('codigo').AsInteger);
              conexao.Parametros('id_ingredientes', CodigoIngrediente);
              conexao.Parametros('quantidade', 1);
              conexao.ExecuteSQL;
            end;

            DadosProduto.Next;
          end;

          conexao.SQL.Add
            ('update pro_adi_personalizado_sabores set id_ingredientes = :id_ingredientes where id in('
            + Dados.FieldByName('ids').AsString + ')');

          conexao.Parametros('id_ingredientes', CodigoIngrediente);
          conexao.ExecuteSQL;

          Dados.Next;
        end;
      end;
      Dados.Free;
    end;
  except

  end;
  conexao.Free;

end;

function TfrmServidor.FileSizeByName(const FileName: string): Int64;
var
  sr: TSearchRec;
begin
  if FindFirst(FileName, faAnyFile, sr) = 0 then
    Result := sr.Size
  else
    Result := 0;
  FindClose(sr);
end;

procedure TfrmServidor.FimAtualizacao;
begin
  // FichaTecnica;



  // GerarCupom;
  // EnviarCupom;

  SemAtualizacao;
end;

function TfrmServidor.FormatPhoneNumber(const RawNumber: string): string;
var
  CountryCode, AreaCode, NumberPart: string;
begin
  // Remove o sufixo ':27@s.whatsapp.net'
  Result := RawNumber.Split([':'])[0];

  // Remove o código do país, assumindo que o código do país é sempre '55'
  CountryCode := Copy(Result, 1, 2);
  Result := Copy(Result, 3, length(Result) - 2);

  // Extraí o código de área e o número
  AreaCode := Copy(Result, 1, 2);
  NumberPart := Copy(Result, 3, length(Result) - 2);

  // Formata o número
  Result := Format('+%s (%s) %s-%s', [CountryCode, AreaCode, Copy(NumberPart, 1,
    4), Copy(NumberPart, 5, 4)]);
end;

procedure TfrmServidor.FormCreate(Sender: TObject);
var
  conexao: Tconexao;
  VersaoMysql: String;
  IniFile: TIniFile;
  HorarioRestart: String;
  PedidosManager: TPedidosManager;
  Qry: TFDQuery;
  memo: TMemo;
  Nome: String;

begin
  ClientSocket := TGenericSocket.New;
  conexao := Tconexao.Create('main');
  // Migrado Para o Core
  try
    conexao.SQL.Add('select * from dados_whatsapp');
    frmServidor.Configuracoes.Close;
    try
      frmServidor.Configuracoes.LoadFromJSON(conexao.ConsultaSQL);
    except

    end;

    if frmServidor.Configuracoes.RecordCount = 0 then
    begin
      // Banco não existe, criar
      VerificarOuCriarBanco;

      // Depois que criar o banco, precisa recarregar tudo
      AposConectarBanco;
    end
    else
    begin
      // Se banco já existe, também configura
      AposConectarBanco;
    end;

  except
    on E: Exception do
    begin

      // //showmessage('Erro ao conectar/criar banco: ' + E.Message);
      Application.Terminate;
      exit;
    end;
  end;

  Test := Random(500);
  Nome := ExtractFileName(Application.ExeName);
  memo := TMemo.Create(nil);
  memo.Parent := self;

  try
    memo.Lines.LoadFromFile('conf.js');
    Modulos := TJsonObject.ParseJSONValue(memo.Lines.Text) as TJsonObject;
  except

  end;
  PIX.Open;
  CodigoPedido := 0;
  StatusMensagemWhatsapp := 0;
  IniFile := TIniFile.Create('./goopedir.ini');
  Port := IniFile.ReadInteger('server', 'port', 2121);
  HorarioRestart := IniFile.ReadString('server', 'restart', '03:00');
  IniFile.WriteInteger('server', 'port', Port);
  IniFile.WriteString('server', 'baseurl', 'http://localhost:' +
    Port.ToString + '/');
  IniFile.WriteString('server', 'restart', '03:00');
  NomeExeSite := IniFile.ReadString('server', 'name', '');

  memo.Free;
  Queue := TProdutoQueue.Create;
  BalancaManager := TBalancaManager.Create;
  memErrosNFCE.Open;
  mAtualizacao.Open;
  Caption := FormatDateTime('hh:nn', now);
  mHoraAbertura.Caption := Caption;

  conexao.SQL.Add('select * from dados_whatsapp');
  frmServidor.Configuracoes.LoadFromJSON(conexao.ConsultaSQL);

  if IniFile.ReadString('IFOOD', 'CLIENTID', '') = '' then
  begin
    HabilitarProduo1Click(nil);
  end;

  if frmServidor.Configuracoes.FieldByName('client_id').AsString <> '' then
  begin

    APIGoopedir := TGooPedirAPIController.Create(API_BASE_URL,
      frmServidor.Configuracoes.FieldByName('client_id').AsString,
      frmServidor.Configuracoes.FieldByName('client_security').AsString,
      GetHorarioAbertura, GetHorarioFechamento, GetHorarioAtendimento,
      frmServidor.Configuracoes.FieldByName('user_id').AsString);
    APIGoopedir.EnviaParametroUnico('nome_banco', conexao.NomeBanco, 'string');
  end;
  conexao.Free;
  // Rotas
  v2.Registry;
  token.Registry;
  util.Registry;
  NFCE.Registry;
  imprimir.Registry;
  LoadImpressora;
  uTablet.Registry;

  // Middlewares
  THorse.Use(LogMiddleware);
  THorse.Use(ConfigurarCORS);
  THorse.Use(ExceptionMiddleware);
  THorse.Use(Jhonson);
  THorse.Use(OctetStream);
  THorse.Use(MiddlewareCORS);
  THorse.Use(SocketIO);

  AtualizaCacheSite;
  IniFile.Free;

  conexao := Tconexao.Create('main');
  conexao.SQL.Add('SET GLOBAL max_connections = 1000;');
  conexao.ExecuteSQL;

  conexao.SQL.Add('select * from mesa_tipo where ativo = 1');
  memTipoMesa.LoadFromJSON(conexao.ConsultaSQL());

  VersaoMysql := conexao.ValidaVersao;
  GerarLog := true;

  // AposConectarBanco;
  // Agora pode iniciar Horse
  try
    THorse.Listen(Port);
  except
    Application.Terminate;
    exit;
  end;

  // SincronizarBackupFTP('C:\goopedir\backup\bd\viapian_forquilhinha19072025.sql','1');
end;

function TfrmServidor.FTP_DirectoryExists(FTP: TIdFTP;
  const Directory: string): Boolean;
begin
  Result := true;
  try
    FTP.List(nil, Directory, False);
  except
    on E: Exception do
      Result := False;
  end;
end;

function TfrmServidor.GenerateUUID: string;
var
  GUID: TGUID;
begin
  // Gera um novo GUID
  if CreateGUID(GUID) = 0 then
    // Converte o GUID para string no formato padrão
    Result := GUIDToString(GUID)
  else
    Result := ''; // Retorna uma string vazia em caso de erro
end;

function TfrmServidor.GerarCodigoPedidoDia: Integer;
var
  conexao: Tconexao;
  horaInicio: string;
begin
  // if CodigoPedido > 0 then
  // begin
  // Inc(CodigoPedido);
  // Result := CodigoPedido;
  // exit;
  // end;
  //
  // // Define o horário de corte baseado na hora atual
  // if HourOf(now) >= 15 then
  // horaInicio := '14:59:59' // para incluir pedidos a partir das 15h
  // else
  // horaInicio := '04:59:59'; // para incluir pedidos a partir das 5h
  //
  // conexao := Tconexao.Create('main');
  // try
  // conexao.SQL.Add
  // ('select 0 as zero, COALESCE(max(codigo_pedido_dia),0) as codigo from pedido where data_pedido = curdate() and hora_pedido > :hora');
  // conexao.Parametros('hora', horaInicio);
  // CodigoPedido := conexao.FieldByName('codigo');
  // finally
  // conexao.Free;
  // end;
  //
  // CodigoPedido := CodigoPedido + 1;
  // Result := CodigoPedido;
  Result := ProximoCodigoPedidoDia;
end;


// function TfrmServidor.GerarCodigoPedidoDia: Integer;
// var
// conexao: Tconexao;
// begin
//
// if CodigoPedido > 0 then
// begin
// Inc(CodigoPedido);
// Result := CodigoPedido;
// exit;
// end;
//
// conexao := Tconexao.Create('main');
// conexao.SQL.Add
// ('select COALESCE(max(codigo_pedido_dia),0) as codigo, 0 as zero from pedido where data_pedido = curdate() and hora_pedido > "04:59:59"');
// CodigoPedido := conexao.FieldByName('codigo');
// conexao.Free;
// CodigoPedido := CodigoPedido + 1;
// Result := CodigoPedido;
//
// end;



function TfrmServidor.GetCachedData: string;
var
  Requisicao: iRequisicao;
  JsonResponse: TJsonObject;
  ResultJson: TJsonObject;
  conexao: Tconexao;
  LogoURL, HeaderURL: string;

begin

  if (Cache.Data <> '') and (MinutesBetween(now, Cache.Timestamp) <= 1) then
  begin
    Result := Cache.Data;
    exit;
  end;

  try
    Requisicao := iRequisicao.Create(nil);
    Requisicao.BaseURL := 'https://old.goopedir.com/v1/horario.php?codigo=' +
      frmServidor.UserID.ToString;
    Requisicao.TempoExpiracao := 1000;
    Requisicao.Execute;
    Cache.Data := Requisicao.Retorno;
    Cache.Data := StringReplace(Cache.Data, '[', '', [rfReplaceAll]);
    Cache.Data := StringReplace(Cache.Data, ']', '', [rfReplaceAll]);
    Cache.Timestamp := now;

    JsonResponse := TJsonObject.ParseJSONValue(Cache.Data) as TJsonObject;

    if Assigned(JsonResponse) then
    begin
      // Cria um novo JSON apenas com os campos desejados
      ResultJson := TJsonObject.Create;
      ResultJson.AddPair('difference',
        JsonResponse.GetValue('difference').Value);
      ResultJson.AddPair('status_loja',
        JsonResponse.GetValue('status_loja').Value);
      ResultJson.AddPair('hora_servidor',
        JsonResponse.GetValue('hora_servidor').Value);
      ResultJson.AddPair('hora_inicio',
        JsonResponse.GetValue('hora_inicio').Value);
      ResultJson.AddPair('hora_fim', JsonResponse.GetValue('hora_fim').Value);
      ResultJson.AddPair('verificacao',
        JsonResponse.GetValue('verificacao').Value);
      ResultJson.AddPair('motivo', JsonResponse.GetValue('motivo').Value);
      ResultJson.AddPair('aberto', JsonResponse.GetValue('aberto').Value);
      ResultJson.AddPair('background', JsonResponse.GetValue('cor_topo').Value);
      ResultJson.AddPair('titulo',
        JsonResponse.GetValue('cor_titulo_produtos').Value);
      // Atualiza o cache
      if not CarregaImagem then
      begin
        conexao := Tconexao.Create('main');

        conexao.SQL.Add
          ('update dados_whatsapp set cor_fundo = :cor_fundo, cor_fonte = :cor_fonte, logo = :img_logo, banner = :img_header');
        conexao.Parametros('cor_fundo',
          JsonResponse.GetValue('cor_topo').Value);
        conexao.Parametros('cor_fonte',
          JsonResponse.GetValue('cor_titulo_produtos').ToString);
        // conexao.Parametros('img_logo', JsonResponse.GetValue('img_logo').ToString);
        // conexao.Parametros('img_header', JsonResponse.GetValue('img_header').ToString);
        if JsonResponse.GetValue('img_logo') <> nil then
        begin
          LogoURL := JsonResponse.GetValue('img_logo').Value;
          LogoURL := StringReplace(LogoURL, '\/', '/', [rfReplaceAll]);
          conexao.Parametros('img_logo', LogoURL);
        end
        else
          conexao.Parametros('img_logo', '');

        // Banner/Header - com tratamento das barras invertidas
        if JsonResponse.GetValue('img_header') <> nil then
        begin
          HeaderURL := JsonResponse.GetValue('img_header').Value;
          HeaderURL := StringReplace(HeaderURL, '\/', '/', [rfReplaceAll]);
          conexao.Parametros('img_header', HeaderURL);
        end
        else
          conexao.Parametros('img_header', '');
        conexao.ExecuteSQL;
        conexao.Free;
        CarregaImagem := true;
      end;

      Cache.Timestamp := now;
      Cache.Data := ResultJson.ToString;

    end;

  except
    on E: Exception do
    begin
      Cache.Data := '{}';

    end;
  end;
  Requisicao.Free;
  Result := Cache.Data;

end;

function TfrmServidor.GetHorarioAbertura(Dia: String): String;
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('main');
  conexao.SQL.Add('select * from horario where dia_da_sema = ' +
    QuotedStr(Copy(Dia, 0, 3)));

  Result := Copy(conexao.FieldByName('abertura'), 0, 5);

  if Result = '' then
    Result := '00:00:00';

  conexao.Free;

end;

function TfrmServidor.GetHorarioAtendimento(Dia: String): String;
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('main');
  conexao.SQL.Add('select * from horario where dia_da_sema = ' +
    QuotedStr(Copy(Dia, 0, 3)));

  Result := conexao.FieldByName('status');

  if Result = '' then
    Result := '0';
  if Result = '1' then
    Result := 'true'
  else
    Result := 'false';

  conexao.Free;

end;

function TfrmServidor.GetHorarioFechamento(Dia: String): String;
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('main');
  conexao.SQL.Add('select * from horario where dia_da_sema = ' +
    QuotedStr(Copy(Dia, 0, 3)));

  Result := Copy(conexao.FieldByName('fechamento'), 0, 5);

  if Result = '' then
    Result := '00:00:00';
  conexao.Free;

end;

function TfrmServidor.GetInfoSystem: TJsonObject;
var
  conexao: Tconexao;
  MaxConnection: String;
  Connection: String;
begin

  Result := TJsonObject.Create;

  conexao := Tconexao.Create('GetInfoSystem');
  conexao.SQL.Add('SHOW VARIABLES LIKE ' + QuotedStr('max_connections'));
  try
    MaxConnection := conexao.FieldByName('value');
  except
    MaxConnection := '0';
  end;
  conexao.SQL.Add('SELECT 0 as zero, COUNT(*) AS conexoes');
  conexao.SQL.Add('FROM information_schema.PROCESSLIST');
  conexao.SQL.Add('where db = ' + QuotedStr(conexao.NomeBanco));

  try
    Connection := conexao.FieldByName('conexoes');;
  except
    Connection := '0';
  end;

  Result.AddPair('max_connection', MaxConnection.ToInteger());
  Result.AddPair('connection', Connection.ToInteger());
  Result.AddPair('db', conexao.NomeBanco);
  Result.AddPair('path', Application.ExeName);

  conexao.Free;

end;

function TfrmServidor.GetInstancia(Pedido: String): Integer;
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('GetInstancia');
  try
    conexao.SQL.Add
      ('select 0 as zero, ifood from pedido where id_ifood = :ifood');
    conexao.Parametros('ifood', Pedido);
    Result := conexao.FieldByName('ifood');
  except
    Result := 0;
  end;
  conexao.Free;

end;

function TfrmServidor.GetModulo: String;
begin

  Result := Modulos.ToString;

end;

function TfrmServidor.GetMySQLDumpPath: string;
const
  // Possíveis locais do mysqldump.exe
  PossiblePaths: array [0 .. 3] of string =
    ('C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe',
    'C:\Program Files\MySQL\MySQL Server 5.7\bin\mysqldump.exe',
    'C:\Program Files (x86)\MySQL\MySQL Server 8.0\bin\mysqldump.exe',
    'C:\Program Files (x86)\MySQL\MySQL Server 5.7\bin\mysqldump.exe');
var
  i: Integer;
begin
  Result := '';
  for i := Low(PossiblePaths) to High(PossiblePaths) do
  begin
    if FileExists(PossiblePaths[i]) then
    begin
      Result := PossiblePaths[i];
      exit;
    end;
  end;

  // Como fallback, tenta buscar no PATH do sistema
  Result := 'mysqldump.exe'; // O sistema tentará achar se estiver no PATH
end;

function TfrmServidor.GetTaxaEntrega: TJsonArray;
var
  conexao: Tconexao;
begin
  if not Assigned(TaxaEntrega) then
    TaxaEntrega := TFDMemTable.Create(nil);

  if not TaxaEntrega.Active then
  begin
    conexao := Tconexao.Create('TaxaEntrega');
    conexao.SQL.Add('SELECT * FROM taxa_entrega where ativo = 1');
    TaxaEntrega.LoadFromJSON(conexao.ConsultaSQL);
    conexao.Free;
  end;

  Result := TaxaEntrega.ToJSONArray();
end;

function TfrmServidor.GetTipopagamento: TJsonArray;
var
  conexao: Tconexao;
begin
  if not Assigned(TipoPagamento) then
    TipoPagamento := TFDMemTable.Create(nil);

  if not TipoPagamento.Active then
  begin
    conexao := Tconexao.Create('TipoPagamento');
    conexao.SQL.Add('SELECT * FROM tipo_pagamento where ativo = 1');
    TipoPagamento.LoadFromJSON(conexao.ConsultaSQL);
    conexao.Free;
  end;

  Result := TipoPagamento.ToJSONArray();

end;

function TfrmServidor.GetToken(Numero: Integer): String;
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('IFoodRefreshTokenGet');
  conexao.SQL.Add('select * from ifood_connect where id = :id');
  conexao.Parametros('id', Numero);
  try
    Result := conexao.FieldByName('token');
  except
    Result := '';
  end;
  conexao.Free;

end;

procedure TfrmServidor.HabilitarHomologao1Click(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  IniFile.WriteString('IFOOD', 'CLIENTID',
    'ae66e3db-e145-4f3f-a810-6ff9ac5d4c5e');
  IniFile.WriteString('IFOOD', 'CLIENTSECRET',
    'skywowzclkem9fcpvodbeof8rzghwerjiegvv1gnjxc5zmpgdnii4rld9sjriutxd6o1e9ds4yuh2181qlfspj5f1zv64ljk5uc');
  IniFile.Free;


end;

procedure TfrmServidor.HabilitarProduo1Click(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  IniFile.WriteString('IFOOD', 'CLIENTID',
    'b683664a-f536-4cbf-a162-a2f98ac757e3');
  IniFile.WriteString('IFOOD', 'CLIENTSECRET',
    '1dg6shdja6v67rzy36djzw809zwqgfax3sidx6coemw9c9kzro5wxh2zvi5k65d3bt8cycn06ms43mfm7knayh7vxzxlbrl51ia');
  IniFile.Free;

end;

function TfrmServidor.IDiFood: String;
var
  conexao: Tconexao;
begin

  conexao := Tconexao.Create('main');
  conexao.SQL.Add('select merchant as M, 0 as zero from dados_whatsapp');
  Result := '';
  try
    Result := conexao.FieldByName('M');
  except

  end;
  pIdiFood.Caption := Result;
  Result := Result;
  conexao.Free;
  // Result := '13ba1b92-4e7f-4bb1-bb59-e234e4c6cedb';
  // '155cc414-36d0-4ec2-9d06-f85fad9e782a';
end;

procedure TfrmServidor.IFoodLogRequest(ARequestId, AContent: string);

var
  arq: TextFile;
  Requisicao: iRequisicao;
  JSON: TJsonObject;
begin
  if AContent = '' then
    exit;

  try
    JSON := TJsonObject.Create;
    try
      // Configura o JSON com os valores
      JSON.AddPair('computer_name', 'ifood');
      JSON.AddPair('error_message', AContent);
      JSON.AddPair('banco', 'IFOOD' + ARequestId);

      // Cria e configura a requisição
      Requisicao := iRequisicao.Create(nil);
      try
        Requisicao.BaseURL := 'https://old.goopedir.com/logger.php';
        Requisicao.BODY(JSON);
        Requisicao.Metodo := mPost;
        Requisicao.Execute;
      finally
        Requisicao.Free;
      end;
    finally
      JSON.Free;
    end;
  except
    on E: Exception do
    begin

    end;
  end;

end;

procedure TfrmServidor.IFoodLogResponse(ARequestId, AContent: string;
  AStatusCode: Integer);
begin
  //
end;



procedure TfrmServidor.IFoodMerchantStatusError(AError: Exception);
var
  arq: TextFile;
  Requisicao: iRequisicao;
  JSON: TJsonObject;
  a: String;
begin
  if AError.Message = '' then
    exit;

  try
    JSON := TJsonObject.Create;
    try
      // Configura o JSON com os valores
      JSON.AddPair('computer_name', 'ifood');
      JSON.AddPair('error_message', AError.Message);
      JSON.AddPair('banco', 'IFOOD');

      // Cria e configura a requisição
      Requisicao := iRequisicao.Create(nil);
      try
        Requisicao.BaseURL := 'https://old.goopedir.com/logger.php';
        a := JSON.ToString;
        Requisicao.BODY(JSON);
        Requisicao.Metodo := mPost;
        Requisicao.Execute;
      finally
        Requisicao.Free;
      end;
    finally
      JSON.Free;
    end;
  except
    on E: Exception do
    begin

    end;
  end;

end;

procedure TfrmServidor.IFoodPollingError(Error: Exception);
var
  Test: String;
begin
  Test := Test;
end;

procedure TfrmServidor.IFoodPollingStart(StartPolling: TDateTime);
var
  Test: String;
begin
  Test := Test;
end;

function TfrmServidor.IFoodRefreshTokenGet: string;
var
  IniFile: TIniFile;
  conexao: Tconexao;
begin
  // ComponenteChamador := Sender as TADRIFood;

  conexao := Tconexao.Create('IFoodRefreshTokenGet');
  conexao.SQL.Add('select 0 as zero, token_ifood from dados_whatsapp');
  try
    Result := conexao.FieldByName('token_ifood');
    pIdiFood.Caption := Result;
  finally
    conexao.Free;
  end;

end;

function TfrmServidor.IFoodRefreshTokenGet1: string;
begin
  Result := GetToken(1);
end;

function TfrmServidor.IFoodRefreshTokenGet2: string;
begin
  Result := GetToken(2);
end;

procedure TfrmServidor.IFoodRefreshTokenSave(RefreshToken: string);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('IFoodRefreshTokenSave');
  conexao.SQL.Add('update dados_whatsapp set token_ifood = :token');
  conexao.Parametros('token', RefreshToken);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure TfrmServidor.IFoodRefreshTokenSave1(RefreshToken: string);
begin
  SaveToken(1, RefreshToken);
end;

procedure TfrmServidor.IFoodRefreshTokenSave2(RefreshToken: string);
begin
  SaveToken(2, RefreshToken);
end;

procedure TfrmServidor.ImportaProdutosToPedindo;
var
  JSONArray: TJsonArray;
  i, J, K: Integer;
  JSONItem: TJsonObject;
  Produto: TProdutoToPedindo;
  conexao: Tconexao;

  CategoriaComplementoNaoPausado: TJsonArray;
  ObjectComplemento: TJsonObject;
  CodigoCategoria: Integer;

  ComplementoNaoPausado: TJsonArray;
  ObjectComplementoItens: TJsonObject;
  CodigoItem: Integer;

  Query: TFDQuery;
begin
  RequisicaoToPedindo.Execute;
  conexao := Tconexao.Create('main');
  Query := conexao.CriaQRY;

  JSONArray := TJsonArray.ParseJSONValue(RequisicaoToPedindo.Retorno)
    as TJsonArray;

  for i := 0 to JSONArray.Count - 1 do
  begin
    JSONItem := JSONArray.Items[i] as TJsonObject;
    Produto := TJson.JsonToObject<TProdutoToPedindo>(JSONItem);

    conexao.SQL.Add('select * from tipo_produto where id_ifood = :id');
    conexao.Parametros('id', Produto.CategoriaItem.Id);
    Produto.CategoriaItem.Codigo := conexao.FieldByName('codigo');

    if Produto.CategoriaItem.Codigo = 0 then
    begin
      Produto.CategoriaItem.Codigo := conexao.GerarID('tipo_produto', 'codigo');
      conexao.SQL.Add
        ('insert into tipo_produto (codigo,descricao, visivel_vem_buscar, visivel_delivery, ordem,id_ifood,descricao_cat) values (:codigo,:descricao, 1, 1, :ordem, :id_ifood,:descricao_cat)');
      conexao.Parametros('codigo', Produto.CategoriaItem.Codigo);
      conexao.Parametros('descricao', Produto.CategoriaItem.Nome);
      conexao.Parametros('id_ifood', Produto.CategoriaItem.Id);
      conexao.Parametros('ordem', Produto.CategoriaItem.Ordem);
      conexao.Parametros('descricao_cat', Produto.CategoriaItem.Descricao);
      conexao.ExecuteSQL;
    end;

    Query.SQL.Text :=
      'update tipo_produto set descricao = :descricao where codigo = :codigo';
    Query.ParamByName('descricao').AsString := Produto.CategoriaItem.Nome;
    Query.ParamByName('codigo').AsInteger := Produto.CategoriaItem.Codigo;
    Query.ExecSQL;

    conexao.SQL.Add('select * from produto where codigo_interno = :id');
    conexao.Parametros('id', Produto.Id);
    Produto.Codigo := conexao.FieldByName('codigo');

    if Produto.Codigo = 0 then
    begin
      Produto.Codigo := conexao.GerarID('produto', 'codigo');
      conexao.SQL.Add('insert into produto');
      conexao.SQL.Add
        ('(codigo,codigo_interno,data_cadastro,nome_produto,descricao,codigo_grupo,valor_venda,');
      conexao.SQL.Add
        ('ativo,controle_estoque,foto_ifood,position,valor_desconto,percentual_desconto,un,fidelidade,segunda,terca,quarta,quinta,sexta,sabado,domingo,novidade,vembuscar,delivery) values');
      conexao.SQL.Add
        (' (:codigo,:codigo_interno,current_date(),:nome_produto,:descricao,:codigo_grupo,:valor_venda,');
      conexao.SQL.Add
        (':ativo,0,:foto_ifood,:position,:valor_desconto,:percentual_desconto,:un,:fidelidade,:segunda,:terca,:quarta,:quinta,:sexta,:sabado,:domingo,0,:vembuscar,:delivery)');
      conexao.Parametros('codigo', Produto.Codigo);
      conexao.Parametros('codigo_interno', Produto.Id);

      // Produto.ValorProduto := StrToFloat(StringReplace(Produto.Preco,'.',',',[]);

      conexao.Parametros('nome_produto', Produto.Nome);
      conexao.Parametros('descricao', Produto.Descricao);
      conexao.Parametros('codigo_grupo', Produto.CategoriaItem.Codigo);
      conexao.Parametros('valor_venda', Produto.Preco);
      conexao.Parametros('ativo', Produto.Status);
      conexao.Parametros('foto_ifood', Produto.Image);
      conexao.Parametros('position', Produto.Ordem);
      conexao.Parametros('valor_desconto', Produto.PrecoComDescontoPromocional);
      conexao.Parametros('percentual_desconto', Produto.PorcentagemPromocional);
      conexao.Parametros('un', 'UN');
      conexao.Parametros('fidelidade', (Produto.Preco) * Produto.ValorPontos);

      conexao.Parametros('segunda', Produto.Disponibilidade.Seg);
      conexao.Parametros('terca', Produto.Disponibilidade.Ter);
      conexao.Parametros('quarta', Produto.Disponibilidade.Qua);
      conexao.Parametros('quinta', Produto.Disponibilidade.Qui);
      conexao.Parametros('sexta', Produto.Disponibilidade.Sex);
      conexao.Parametros('sabado', Produto.Disponibilidade.Sab);
      conexao.Parametros('domingo', Produto.Disponibilidade.Dom);
      conexao.Parametros('vembuscar', 1);
      conexao.Parametros('delivery', 1);
      conexao.ExecuteSQL

    end;

    Query.SQL.Text :=
      'update produto set nome_produto = :nome_produto, descricao = :descricao where codigo = :codigo';
    Query.ParamByName('nome_produto').AsString := Produto.Nome;
    Query.ParamByName('descricao').AsString := Produto.Descricao;
    Query.ParamByName('codigo').AsInteger := Produto.Codigo;
    Query.ExecSQL;

    try

      if JSONItem.TryGetValue<TJsonArray>
        ('categorias_complementos_nao_pausados', CategoriaComplementoNaoPausado)
      then
      begin

        for J := 0 to CategoriaComplementoNaoPausado.Count - 1 do
        begin
          ObjectComplemento := CategoriaComplementoNaoPausado.Items[J]
            as TJsonObject;

          if ObjectComplemento.GetValue<string>('tipo_calculo') = '0' then
          begin

            conexao.SQL.Add
              ('select * from pro_adi_personalizado where id_ifood = :id');
            conexao.Parametros('id', ObjectComplemento.GetValue<string>('id'));
            CodigoCategoria := conexao.FieldByName('id');
            if CodigoCategoria = 0 then
            begin
              CodigoCategoria := conexao.GerarID('pro_adi_personalizado', 'id');
            end;
            conexao.SQL.Add
              ('INSERT INTO pro_adi_personalizado (id, id_produto, descricao, ativo, qtd_minima, qtd_maxima, id_ifood)');
            conexao.SQL.Add
              ('VALUES (:id, :id_produto, :descricao, :ativo, :qtd_minima, :qtd_maxima, :id_ifood)');
            conexao.SQL.Add('ON DUPLICATE KEY UPDATE');
            conexao.SQL.Add('    id_produto = VALUES(id_produto),');
            conexao.SQL.Add('    descricao = VALUES(descricao),');
            conexao.SQL.Add('    ativo = VALUES(ativo),');
            conexao.SQL.Add('    qtd_minima = VALUES(qtd_minima),');
            conexao.SQL.Add('    qtd_maxima = VALUES(qtd_maxima),');
            conexao.SQL.Add('    id_ifood = VALUES(id_ifood);');
            conexao.Parametros('id', CodigoCategoria);
            conexao.Parametros('id_produto', Produto.Codigo);
            conexao.Parametros('descricao',
              ObjectComplemento.GetValue<string>('nome'));
            conexao.Parametros('ativo',
              ObjectComplemento.GetValue<string>('status'));
            conexao.Parametros('qtd_minima',
              ObjectComplemento.GetValue<string>('qtd_minima'));
            conexao.Parametros('qtd_maxima',
              ObjectComplemento.GetValue<string>('qtd_maxima'));
            conexao.Parametros('id_ifood',
              ObjectComplemento.GetValue<string>('id'));
            conexao.ExecuteSQL;

            if ObjectComplemento.TryGetValue<TJsonArray>
              ('complementos_nao_pausados', ComplementoNaoPausado) then
            begin

              for K := 0 to ComplementoNaoPausado.Count - 1 do
              begin
                ObjectComplementoItens := ComplementoNaoPausado.Items[K]
                  as TJsonObject;
                conexao.SQL.Add
                  ('select * from pro_adi_personalizado_sabores where id_ifood = :id');
                conexao.Parametros('id',
                  ObjectComplementoItens.GetValue<string>('id'));
                CodigoItem := conexao.FieldByName('id');

                if CodigoItem = 0 then
                begin
                  CodigoItem :=
                    conexao.GerarID('pro_adi_personalizado_sabores', 'id');
                end;
                conexao.SQL.Add('INSERT INTO pro_adi_personalizado_sabores');
                conexao.SQL.Add
                  ('(id, id_pro_adi_personalizado, nome, descricao, valor, ativo, id_ifood)');
                conexao.SQL.Add
                  ('VALUES (:id, :id_pro_adi_personalizado, :nome, :descricao, :valor, :ativo, :id_ifood)');
                conexao.SQL.Add('ON DUPLICATE KEY UPDATE');
                conexao.SQL.Add
                  ('id_pro_adi_personalizado = VALUES(id_pro_adi_personalizado),');
                conexao.SQL.Add('nome = VALUES(nome),');
                conexao.SQL.Add('descricao = VALUES(descricao),');
                conexao.SQL.Add('valor = VALUES(valor),');
                conexao.SQL.Add('ativo = VALUES(ativo),');
                conexao.SQL.Add('id_ifood = VALUES(id_ifood);');
                conexao.Parametros('id', CodigoItem);
                conexao.Parametros('id_pro_adi_personalizado', CodigoCategoria);
                conexao.Parametros('nome',
                  ObjectComplementoItens.GetValue<string>('nome'));
                conexao.Parametros('descricao',
                  ObjectComplementoItens.GetValue<string>('descricao'));
                conexao.Parametros('valor',
                  ObjectComplementoItens.GetValue<Real>('preco'));
                conexao.Parametros('ativo',
                  ObjectComplementoItens.GetValue<string>('status'));
                conexao.Parametros('id_ifood',
                  ObjectComplementoItens.GetValue<string>('id'));
                conexao.ExecuteSQL;
              end;

            end;
          end
          else
          begin
            CodigoCategoria := conexao.GerarID('produto_pizza', 'codigo');
            conexao.SQL.Add
              ('insert into produto_pizza (codigo,codigo_produto,quantidade_sabores,borda,ativo) values (:codigo,:codigo_produto,:quantidade_sabores,0,1)');
            conexao.Parametros('quantidade_sabores',
              ObjectComplemento.GetValue<string>('qtd_maxima'));
            conexao.Parametros('codigo_produto', Produto.Codigo);
            conexao.Parametros('codigo', CodigoCategoria);
            conexao.ExecuteSQL;

            if ObjectComplemento.TryGetValue<TJsonArray>
              ('complementos_nao_pausados', ComplementoNaoPausado) then
            begin

              for K := 0 to ComplementoNaoPausado.Count - 1 do
              begin
                ObjectComplementoItens := ComplementoNaoPausado.Items[K]
                  as TJsonObject;
                conexao.SQL.Add
                  ('select * from sabores_completo where id_produto = :produto and id_ifood = :ifood');
                conexao.Parametros('produto', Produto.Codigo);
                conexao.Parametros('ifood',
                  ObjectComplementoItens.GetValue<string>('id'));
                CodigoItem := conexao.FieldByName('id');

                if CodigoItem = 0 then
                begin
                  CodigoItem := conexao.GerarID('sabores_completo', 'id');
                end;

                conexao.SQL.Add
                  ('INSERT INTO sabores_completo (id, id_produto, id_tipo_sabor, dt_cadastro, nome, descricao, vl_venda, ativo, id_ifood)');
                conexao.SQL.Add
                  ('VALUES (:id, :id_produto, 1, current_date, :nome, :descricao, :vl_venda, :ativo, :id_ifood)');
                conexao.SQL.Add('ON DUPLICATE KEY UPDATE');
                conexao.SQL.Add('    id_produto = VALUES(id_produto),');
                conexao.SQL.Add('    nome = VALUES(nome),');
                conexao.SQL.Add('    descricao = VALUES(descricao),');
                conexao.SQL.Add('    vl_venda = VALUES(vl_venda),');
                conexao.SQL.Add('    ativo = VALUES(ativo),');
                conexao.SQL.Add('    id_ifood = VALUES(id_ifood);');
                conexao.Parametros('id', CodigoItem);
                conexao.Parametros('id_produto', Produto.Codigo);
                conexao.Parametros('nome',
                  ObjectComplementoItens.GetValue<string>('nome'));
                conexao.Parametros('descricao',
                  ObjectComplementoItens.GetValue<string>('descricao'));
                conexao.Parametros('vl_venda',
                  ObjectComplementoItens.GetValue<Real>('preco'));
                conexao.Parametros('ativo',
                  ObjectComplementoItens.GetValue<string>('status'));
                conexao.Parametros('id_ifood',
                  ObjectComplementoItens.GetValue<string>('id'));
                conexao.ExecuteSQL;

                // conexao.SQL.Add
                // ('select * from pro_adi_personalizado_sabores where id_ifood = :id');
                // conexao.Parametros('id',
                // ObjectComplementoItens.GetValue<string>('id'));
                // CodigoItem := conexao.FieldByName('id');
                //
                // if CodigoItem = 0 then
                // begin
                // CodigoItem :=
                // conexao.GerarID('pro_adi_personalizado_sabores', 'id');
                // end;
                // conexao.SQL.Add('INSERT INTO pro_adi_personalizado_sabores');
                // conexao.SQL.Add('(id, id_pro_adi_personalizado, nome, descricao, valor, ativo, id_ifood)');
                // conexao.SQL.Add('VALUES (:id, :id_pro_adi_personalizado, :nome, :descricao, :valor, :ativo, :id_ifood)');
                // conexao.SQL.Add('ON DUPLICATE KEY UPDATE');
                // conexao.SQL.Add('id_pro_adi_personalizado = VALUES(id_pro_adi_personalizado),');
                // conexao.SQL.Add('nome = VALUES(nome),');
                // conexao.SQL.Add('descricao = VALUES(descricao),');
                // conexao.SQL.Add('valor = VALUES(valor),');
                // conexao.SQL.Add('ativo = VALUES(ativo),');
                // conexao.SQL.Add('id_ifood = VALUES(id_ifood);');
                // conexao.Parametros('id', CodigoItem);
                // conexao.Parametros('id_pro_adi_personalizado', CodigoCategoria);
                // conexao.Parametros('nome',ObjectComplementoItens.GetValue<string>('nome'));
                // conexao.Parametros('descricao',ObjectComplementoItens.GetValue<string>('descricao'));
                // conexao.Parametros('valor',ObjectComplementoItens.GetValue<Real>('preco'));
                // conexao.Parametros('ativo',ObjectComplementoItens.GetValue<string>('status'));
                // conexao.Parametros('id_ifood',ObjectComplementoItens.GetValue<string>('id'));
                // conexao.ExecuteSQL;
              end;

            end;

          end;

        end;

      end;
    finally
      CategoriaComplementoNaoPausado.Free;
    end;

    // for J := 0 to Produto.CategoriasComplementosNaoPausados.Count - 1 do
    // begin
    //
    // if Produto.CategoriasComplementosNaoPausados[J].Codigo = 0 then
    // begin
    //
    // Produto.CategoriasComplementosNaoPausados[J].Codigo :=
    // conexao.GerarID('pro_adi_personalizado', 'id');
    // conexao.SQL.Add
    // ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,id_ifood) values (:id,:id_produto,:descricao,:ativo,:qtd_minima,:qtd_maxima,:id_ifood)');
    // conexao.Parametros('id', Produto.CategoriasComplementosNaoPausados
    // [J].Codigo);
    // conexao.Parametros('id_produto', Produto.Codigo);
    // conexao.Parametros('descricao',
    // Produto.CategoriasComplementosNaoPausados[J].Nome);
    // conexao.Parametros('ativo', 1);
    // conexao.Parametros('qtd_minima',
    // Produto.CategoriasComplementosNaoPausados[J].QtdMinima);
    // conexao.Parametros('qtd_maxima',
    // Produto.CategoriasComplementosNaoPausados[J].QtdMaxima);
    // conexao.Parametros('id_ifood',
    // Produto.CategoriasComplementosNaoPausados[J].ID);
    // conexao.ExecuteSQL;
    // end;
    // end;

    try
      for J := 0 to Produto.ComplementosNaoPausados.Count - 1 do
      begin

        conexao.SQL.Add
          ('select * from pro_adi_personalizado_sabores where id_ifood = :id');
        conexao.Parametros('id', Produto.ComplementosNaoPausados[J].Id);
        Produto.ComplementosNaoPausados[J].Codigo := conexao.FieldByName('id');

        if Produto.ComplementosNaoPausados[J].Codigo = 0 then
        begin
          Produto.ComplementosNaoPausados[J].Codigo :=
            conexao.GerarID('pro_adi_personalizado_sabores', 'id');
          conexao.SQL.Add
            ('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo,id_ifood) values (:id,:id_pro_adi_personalizado,:nome,:descricao,:valor,:ativo,:id_ifood)');
          conexao.Parametros('id', Produto.ComplementosNaoPausados[J].Codigo);
          conexao.Parametros('id_pro_adi_personalizado',
            Produto.ComplementosNaoPausados[J].Categoria);
          conexao.Parametros('nome', Produto.ComplementosNaoPausados[J].Nome);
          conexao.Parametros('descricao', Produto.ComplementosNaoPausados[J]
            .Descricao);
          conexao.Parametros('valor', Produto.ComplementosNaoPausados[J].Preco);
          conexao.Parametros('ativo', Produto.ComplementosNaoPausados
            [J].Status);
          conexao.Parametros('id_ifood', Produto.ComplementosNaoPausados[J].Id);
          conexao.ExecuteSQL;

        end;

      end;
    except

    end;

    try

    finally
      Produto.Free;
    end;
  end;

end;

function TfrmServidor.IMPRESSAO: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'ImpressaoGooPedir.exe';
end;

function TfrmServidor.ImpressaoStatus: TJsonObject;
begin

  Result := TJsonObject.Create;
  Result.AddPair('comanda', frmServidor.ValidaTempoImpressaoStatusComanda);
  Result.AddPair('cozinha', frmServidor.ValidaTempoImpressaoStatusCozinha);
  Result.AddPair('outros', frmServidor.ValidaTempoImpressaoStatusCozinha);
  Result.AddPair('status', frmServidor.ValidaTempoImpressaoStatus);
end;

procedure TfrmServidor.ImpressoraStatus;
begin
  DataHoraImpressaoService := now;
end;

procedure TfrmServidor.IniciaIfood;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin

  conexao := Tconexao.Create('IniciaIfood');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('select * from ifood_connect');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin

    while not Dados.Eof do
    begin
      if Dados.FieldByName('merchantid').AsString <> '' then
      begin
        CreateiFoodConnection(Dados.FieldByName('id').AsString,
          Dados.FieldByName('merchantid').AsString);
      end;
      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;

end;

procedure TfrmServidor.InicializarCodigo;
var
  conexao: Tconexao;
  horaInicio: string;
  Codigo: Integer;
begin
  if HourOf(now) >= 15 then
    horaInicio := '14:59:59'
  else
    horaInicio := '04:59:59';

  conexao := Tconexao.Create('main');
  try
    conexao.SQL.Add
      ('select 0 as zero, COALESCE(max(codigo_pedido_dia),0) as codigo ' +
      'from pedido where data_pedido = curdate() and hora_pedido > :hora');
    conexao.Parametros('hora', horaInicio);
    Codigo := conexao.FieldByName('codigo');
  finally
    conexao.Free;
  end;

  InicializarCodigoPedidoDia(Codigo);
end;

procedure TfrmServidor.IniciarAtualizacao;
begin
  //
end;

procedure TfrmServidor.InitializeLogFile;
var
  FileName: string;
begin
  // Gera o nome do arquivo de log com base na data/hora da execução
  FileName := 'log/' + FormatDateTime('yyyy-mm-dd_hh-nn-ss', now) + '_log.txt';
  LogFilePath := TPath.Combine(ApplicationPath, FileName);

  // Cria o arquivo vazio para começar o log
  TFile.WriteAllText(LogFilePath, '', TEncoding.UTF8);

end;

function TfrmServidor.IntegracaoiFood: Boolean;
begin

  try
    Result := frmServidor.Configuracoes.FieldByName('ifood_integracao')
      .AsInteger = 1;

    if Result then
    begin
      if IDiFood = '' then
        Result := False;
    end;
  except

  end;

end;

procedure TfrmServidor.LoadImpressora;
var
  i: Integer;
  Id: Integer;
begin
  memImpressora.Close;
  memImpressora.Open;
  Id := 1;
  memImpressora.Insert;
  memImpressora.FieldByName('ID').AsInteger := Id;
  memImpressora.FieldByName('DRIVER').AsString := 'Default';
  memImpressora.post;
  for i := 0 to Printer.Count - 1 do
  begin

    if (UpperCase(Printer.Printers[i].Device) <> 'FAX') and
      (UpperCase(Printer.Printers[i].Device) <> 'MICROSOFT PRINT TO PDF') and
      (UpperCase(Printer.Printers[i].Device) <> 'MICROSOFT XPS DOCUMENT WRITER')
    then
    begin
      Inc(Id);
      memImpressora.Insert;
      memImpressora.FieldByName('ID').AsInteger := Id;
      memImpressora.FieldByName('DRIVER').AsString :=
        Printer.Printers[i].Device;
      memImpressora.post;
    end;
  end;

end;

// procedure TfrmServidor.LogMiddleware(Req: THorseRequest; Res: THorseResponse;
// Next: TProc);
// var
// LogLine, BodyContent: string;
// LogFile: TStreamWriter;
// begin
// exit;
// if SameText(Metodo(Req), 'POST') then
// begin
// BodyContent := Req.BODY;
// // LogLine := LogLine + Format(' | Body: %s', [BodyContent]);
// end;
// EnviaGlitchtip
// ('https://9327eaf954a340cb94c64a8bf4afb696@nginx-glitchtip.l1p88w.easypanel.host/5',
// Req.RawWebRequest.RawPathInfo, Metodo(Req), BodyContent);
// // Req.RawWebRequest.RawPathInfo
// // try
// // // Monta a linha de log
// //
// // LogLine := Format('%s | %s | %s', [DateTimeToStr(now), Metodo(Req),
// // Req.RawWebRequest.PathInfo]);
// //
// // // Se for um método POST, adiciona o corpo da requisição
//
// //
// // // Abre o arquivo de log e escreve a linha
// // LogFile := TStreamWriter.Create(LogFilePath, true, TEncoding.UTF8);
// // try
// // LogFile.WriteLine(LogLine);
// // finally
// // LogFile.Free;
// // end;
// // except
// // on E: Exception do
// //
// // end;
//
// // Chama o próximo middleware ou a rota
// Next;
// end;

procedure TfrmServidor.LogMiddleware(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LogDir, LogFilePath, LogLine, BodyContent, MetodoHTTP: string;
  LogFile: TStreamWriter;
begin
  // continua o fluxo normal da requisição
  Next;
  exit;

  EnviaGlitchtip
    ('https://9327eaf954a340cb94c64a8bf4afb696@nginx-glitchtip.l1p88w.easypanel.host/5',
    Req.RawWebRequest.RawPathInfo, Metodo(Req), BodyContent);

  try
    MetodoHTTP := Req.RawWebRequest.Method;

    // Define pasta base dos logs
    LogDir := ExtractFilePath(ParamStr(0)) + 'logs\rotas\';
    if not DirectoryExists(LogDir) then
      ForceDirectories(LogDir);

    // Cria um arquivo novo por dia: ex: rotas_2025-11-03.log
    LogFilePath := LogDir + 'rotas_' + FormatDateTime('yyyy-mm-dd', now) + '-' +
      Test.ToString + '.log';

    // Captura o body apenas se for POST
    if SameText(MetodoHTTP, 'POST') then
      BodyContent := Req.BODY
    else
      BodyContent := '';

    // Monta a linha de log
    LogLine := Format('[%s] %s %s | IP: %s | Body: %s',
      [FormatDateTime('hh:nn:ss.zzz', now), MetodoHTTP,
      Req.RawWebRequest.RawPathInfo, Req.RawWebRequest.RemoteAddr,
      BodyContent]);

    // Abre o arquivo e escreve
    LogFile := TStreamWriter.Create(LogFilePath, true, TEncoding.UTF8);
    try
      LogFile.WriteLine(LogLine);
    finally
      LogFile.Free;
    end;
  except
    on E: Exception do
      // opcional: tratamento de falha no log
      Writeln('Erro ao registrar log: ' + E.Message);
  end;
end;

function TfrmServidor.Metodo(Req: THorseRequest): String;
begin
  case Req.MethodType of
    mtAny:
      begin
        Result := 'ANY';
      end;
    mtGet:
      begin
        Result := 'GET';
      end;
    mtPut:
      begin
        Result := 'PUT';
      end;
    mtPost:
      begin
        Result := 'POST';
      end;
    mtHead:
      begin
        Result := 'HEAD';
      end;
    mtDelete:
      begin
        Result := 'DELET';
      end;
    mtPatch:
      begin
        Result := 'PATCH';
      end;

  end;
end;

procedure TfrmServidor.MiddlewareCORS(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Origin', '*');
  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Methods',
    'GET, POST, PUT, DELETE, OPTIONS');
  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Headers',
    'Content-Type, Authorization');
  if Req.RawWebRequest.Method = 'OPTIONS' then
    Res.Status(204).Send('')
  else
    Next;
end;

procedure TfrmServidor.mModal(Valor: String);
begin
  // ////////showmessage1(Valor);
end;

function TfrmServidor.NumeroWpp: String;
begin
  if Assigned(APIGoopedir) then
  begin

    if SincNumeroWhatsapp <> FNumeroWhatsapp then
    begin
      APIGoopedir.EnviaParametroUnico('telefone_wpp', FNumeroWhatsapp,
        'string');
      SincNumeroWhatsapp := FNumeroWhatsapp;
    end;

  end;
  Result := FNumeroWhatsapp;
end;

function TfrmServidor.ObjetoProdutoAdicional(Codigo: String): TJsonArray;
var
  conexao: Tconexao;
  DadosAdicionais: TFDMemTable;
  JSonArrayAdicional: TJsonArray;
  JsonObjetoCategoriaAdicional: TJsonObject;
  DadosAdicionaisItens: TFDMemTable;
  JSonArrayAdicionalItens: TJsonArray;
  JSonObjetoAdicionalItens: TJsonObject;
  Min: Real;
  Max: Real;
begin
  conexao := Tconexao.Create('ObjetoProdutoAdicional');
  DadosAdicionais := TFDMemTable.Create(nil);
  DadosAdicionaisItens := TFDMemTable.Create(nil);

  conexao.SQL.Add
    ('SELECT * FROM pro_adi_personalizado where id_produto = :id_produto');
  conexao.Parametros('id_produto', Codigo);

  DadosAdicionais.LoadFromJSON(conexao.ConsultaSQL);

  if DadosAdicionais.RecordCount > 0 then
  begin
    JSonArrayAdicional := TJsonArray.Create;
    while not DadosAdicionais.Eof do
    begin
      JsonObjetoCategoriaAdicional := TJsonObject.Create;
      JsonObjetoCategoriaAdicional.AddPair('categoryId',
        DadosAdicionais.FieldByName('id').AsInteger);
      JsonObjetoCategoriaAdicional.AddPair('categoryName',
        DadosAdicionais.FieldByName('descricao').AsString);
      JsonObjetoCategoriaAdicional.AddPair('categoryStatus',
        DadosAdicionais.FieldByName('ativo').AsInteger);
      JsonObjetoCategoriaAdicional.AddPair('categoryMin',
        DadosAdicionais.FieldByName('qtd_minima').AsInteger);
      JsonObjetoCategoriaAdicional.AddPair('categoryMax',
        DadosAdicionais.FieldByName('qtd_maxima').AsInteger);

      DadosAdicionaisItens.Close;
      conexao.SQL.Add
        ('select * from pro_adi_personalizado_sabores where id_pro_adi_personalizado = :id and deletado = 0');
      conexao.Parametros('id', DadosAdicionais.FieldByName('id').AsInteger);
      DadosAdicionaisItens.LoadFromJSON(conexao.ConsultaSQL);
      JSonArrayAdicionalItens := TJsonArray.Create;

      while not DadosAdicionaisItens.Eof do
      begin
        JSonObjetoAdicionalItens := TJsonObject.Create;
        JSonObjetoAdicionalItens.AddPair('itensId',
          DadosAdicionaisItens.FieldByName('id').AsInteger);
        JSonObjetoAdicionalItens.AddPair('itensName',
          DadosAdicionaisItens.FieldByName('nome').AsString);
        JSonObjetoAdicionalItens.AddPair('itensDescription',
          DadosAdicionaisItens.FieldByName('descricao').AsString);
        JSonObjetoAdicionalItens.AddPair('itensValue',
          DadosAdicionaisItens.FieldByName('valor').AsFloat);
        JSonObjetoAdicionalItens.AddPair('itensProdStock',
          DadosAdicionaisItens.FieldByName('id_prod_estoque').AsInteger);
        JSonObjetoAdicionalItens.AddPair('itensStatus',
          DadosAdicionaisItens.FieldByName('ativo').AsInteger);
        JSonObjetoAdicionalItens.AddPair('itensInsumo',
          DadosAdicionaisItens.FieldByName('id_ingredientes').AsInteger);
        JSonObjetoAdicionalItens.AddPair('itensAlerta',
          DadosAdicionaisItens.FieldByName('alerta').AsInteger);
        try
          JSonObjetoAdicionalItens.AddPair('url',
            DadosAdicionaisItens.FieldByName('url').AsString);
        except
          JSonObjetoAdicionalItens.AddPair('url', '');
        end;

        JSonArrayAdicionalItens.AddElement(JSonObjetoAdicionalItens);

        if DadosAdicionaisItens.FieldByName('valor').AsFloat > 0 then
        begin
          if Min > DadosAdicionaisItens.FieldByName('valor').AsFloat then
            Min := DadosAdicionaisItens.FieldByName('valor').AsFloat;

          if DadosAdicionaisItens.FieldByName('valor').AsFloat > Max then
            Max := DadosAdicionaisItens.FieldByName('valor').AsFloat;
        end;

        DadosAdicionaisItens.Next;
      end;
      JsonObjetoCategoriaAdicional.AddPair('categoryItens',
        JSonArrayAdicionalItens);

      JSonArrayAdicional.Add(JsonObjetoCategoriaAdicional);
      DadosAdicionais.Next;
    end;
  end
  else
  begin
    JSonArrayAdicional := TJsonArray.Create;
  end;
  Result := JSonArrayAdicional;
  conexao.Free;
end;

function TfrmServidor.ObterDiaDaSemana: string;
const
  NomesDiasSemana: array [1 .. 7] of string = ('domingo', 'segunda', 'terca',
    'quarta', 'quinta', 'sexta', 'sabado');
var
  DiaDaSemana: Integer;
begin
  // Obter o índice do dia da semana (1 para domingo, 2 para segunda, etc.)
  DiaDaSemana := DayOfWeek(now);

  // Mapear o índice para o nome do dia da semana
  Result := NomesDiasSemana[DiaDaSemana];
end;

procedure TfrmServidor.OutrosStatus;
begin
  DataHoraImpressaoServiceOutros := now;
  ImpressoraStatus;
end;

function TfrmServidor.USANFCE: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'NFCe.exe';
end;

function TfrmServidor.PathExe: String;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

procedure TfrmServidor.pIdiFoodClick(Sender: TObject);
var
  conexao: Tconexao;
  i: Integer;
begin
  for i := 1 to 1000 do
  begin
    conexao := Tconexao.Create('main');
    conexao.SQL.Add('select * from motoboy');
    conexao.ConsultaSQL;
  end;
end;

procedure TfrmServidor.ReImpressao;
var
  Dados: TFDMemTable;
  DadosProdutos: TFDMemTable;
  CodigoAux: Integer;
  conexao: Tconexao;

begin

  try
    Dados := TFDMemTable.Create(nil);
    conexao := Tconexao.Create('main');
    conexao.SQL.Add('select pedido_produtos.* from pedido');
    conexao.SQL.Add
      ('join pedido_produtos on pedido_produtos.codigo_pedido = pedido.codigo');
    conexao.SQL.Add
      ('where pedido.data_pedido >= "2024-05-22" and impresso = 0 and pedido.status <> 0');
    conexao.SQL.Add
      ('AND TIMESTAMPDIFF(MINUTE, pedido_produtos.hora, NOW()) > 5;');

    Dados.LoadFromJSON(conexao.ConsultaSQL);
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        conexao.SQL.Add
          ('SELECT * FROM impressao_pedido_produto where id_pedido = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsString);

        CodigoAux := conexao.FieldByName('id');

        if CodigoAux = 0 then
        begin
          conexao.SQL.Add
            ('insert into impressao_pedido_produto (data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (current_date(),current_time(),:pedido,:status,0,:usuario)');
          conexao.Parametros('pedido', Dados.FieldByName('codigo').AsString);
          conexao.Parametros('status', 0);
          conexao.Parametros('usuario', -3);
          conexao.ExecuteSQL;
        end;

        conexao.SQL.Add
          ('update pedido_produtos set impresso = 1 where  codigo = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsString);
        conexao.ExecuteSQL;

        Dados.Next;
      end;
    end;

  except

  end;
  Dados.Free;
  conexao.Free;
end;

procedure TfrmServidor.ReiniciarAplicacao;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  // Configura a estrutura StartupInfo
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));

  // Cria um novo processo para reiniciar o executável
  if CreateProcess(PChar(Application.ExeName), // Caminho do executável
    nil, // Parâmetros de linha de comando
    nil, // Atributos de segurança do processo
    nil, False, // Herança de handles
    0, // Flags de criação
    nil, // Ambiente
    nil, // Diretório atual
    StartupInfo, ProcessInfo) then
  begin

    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end
  else
  begin
    // Se não foi possível criar o processo, exibe uma mensagem de erro
    RaiseLastOSError;
  end;
end;

procedure TfrmServidor.ReiniciarServioImpresso1Click(Sender: TObject);
begin
  FecharExe(frmServidor.IMPRESSAO);
  AbrirExe(frmServidor.IMPRESSAO);
end;

procedure TfrmServidor.ReProcessaImpressaoPedidoProduto(conexao: Tconexao);
var
  Dados: TFDMemTable;
  Codigo: Integer;
begin
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('SELECT ');
  conexao.SQL.Add('p.codigo as codigo_imprimir_pedido,');
  conexao.SQL.Add('ip.id as codigo_impressao_pedido,');
  conexao.SQL.Add('ip.hora_impressao as hora_impressao_pedido,');
  conexao.SQL.Add('       CASE ');
  conexao.SQL.Add('           WHEN p.origem = 3 THEN true');
  conexao.SQL.Add('           ELSE false');
  conexao.SQL.Add('       END AS mesa,');
  conexao.SQL.Add('p.codigo_pedido_dia,');
  conexao.SQL.Add('pp.codigo as codigo_imprimir_produto, pp.tempo_liberacao,');
  conexao.SQL.Add('ipp.id as codigo_impressao_pedido_produto,');
  conexao.SQL.Add('ipp.hora_impressao as hora_impressao_pedido_produto,');
  conexao.SQL.Add('TIMESTAMPDIFF(MINUTE, pp.hora, NOW()) AS tempo,');
  conexao.SQL.Add('TIMESTAMPDIFF(SECOND, pp.hora, NOW()) AS segundos');
  conexao.SQL.Add('FROM pedido_produtos as pp');
  conexao.SQL.Add('join pedido as p on p.codigo = pp.codigo_pedido');
  conexao.SQL.Add
    ('left join impressao_pedido as ip on ip.id_pedido = p.codigo');
  conexao.SQL.Add
    ('left join impressao_pedido_produto as ipp on ipp.id_pedido = pp.codigo');
  conexao.SQL.Add
    ('where pp.impresso <> 1 and pp.codigo_pedido > 0 and DATE(pp.hora) = curdate()');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount = 0 then
  begin
    Dados.Free;
    exit;
  end;

  while not Dados.Eof do
  begin
    if (Dados.FieldByName('mesa').AsInteger = 1) and
      (Dados.FieldByName('tempo').AsInteger >=
      Dados.FieldByName('tempo_liberacao').AsInteger) then
    begin

      if (Dados.FieldByName('codigo_impressao_pedido_produto').AsInteger = 0)
      then
      begin
        // Se for maior que 5m e não estiver na fila, deve lançar ele na fila
        conexao.SQL.Add
          ('insert into impressao_pedido_produto (id_pedido,status,data_solicitacao,hora_solicitacao,usuario) values (:codigo,1,curdate(),curtime(),-2)');
        conexao.Parametros('codigo',
          Dados.FieldByName('codigo_imprimir_produto').AsInteger);
        conexao.ExecuteSQL;

      end
      else
      begin
        conexao.SQL.Add
          ('update impressao_pedido_produto set status = 0 where id = :id');
        conexao.Parametros('id',
          Dados.FieldByName('codigo_impressao_pedido_produto').AsInteger);
        conexao.ExecuteSQL;
      end;

    end
    else
    begin
      if (Dados.FieldByName('tempo').AsInteger >= 2) then
      begin
        // Validação do pedido
        if (Dados.FieldByName('codigo_pedido_dia').AsInteger > 0) then
        begin
          if (Dados.FieldByName('codigo_impressao_pedido').AsInteger = 0) then
          begin
            // Inserir registro
            if Dados.FieldByName('segundos').AsInteger > 60 then
            begin

              conexao.SQL.Add
                ('select * from impressao_pedido where id_pedido = :pedido');
              conexao.Parametros('pedido',
                Dados.FieldByName('codigo_imprimir_pedido').AsInteger);
              try
                Codigo := conexao.FieldByName('id');
              except
                Codigo := 0;
              end;

              if Codigo = 0 then
              begin
                Codigo := conexao.GerarID('impressao_pedido', 'id');
                conexao.SQL.Add
                  ('insert into impressao_pedido (id,data_solicitacao, hora_solicitacao,id_pedido,status,vias)');
                conexao.SQL.Add
                  ('values  (:id,current_date, current_time,:pedido,:status,-1)');
                conexao.Parametros('id', Codigo);
                conexao.Parametros('pedido',
                  Dados.FieldByName('codigo_imprimir_pedido').AsInteger);
                conexao.Parametros('status', 0);
                conexao.ExecuteSQL;
              end;
            end;
          end
          else
          begin
            // Liberar
            if (Dados.FieldByName('hora_impressao_pedido').AsString = '') then
            begin
              conexao.SQL.Add
                ('update impressao_pedido set status = 0 where id = :id');
              conexao.Parametros('id',
                Dados.FieldByName('codigo_impressao_pedido').AsInteger);
              conexao.ExecuteSQL;
            end;
          end;
        end;
        // Validação Produto
        if (Dados.FieldByName('codigo_impressao_pedido_produto').AsInteger = 0)
        then
        begin
          conexao.SQL.Add
            ('insert into impressao_pedido_produto (id_pedido,status,data_solicitacao,hora_solicitacao,usuario) values (:codigo,1,curdate(),curtime(),-2)');
          conexao.Parametros('codigo',
            Dados.FieldByName('codigo_imprimir_produto').AsInteger);
          conexao.ExecuteSQL;
        end
        else
        begin
          if (Dados.FieldByName('hora_impressao_pedido_produto').AsString = '')
          then
          begin
            conexao.SQL.Add
              ('update impressao_pedido_produto set status = 0 where id = :id');
            conexao.Parametros('id',
              Dados.FieldByName('codigo_impressao_pedido_produto').AsInteger);
            conexao.ExecuteSQL;
          end;
        end;

      end;




      // if Codigo = 0 then
      // begin
      //

      // end;
      // end;
      // if (Dados.FieldByName('codigo_impressao_pedido').AsInteger > 0) and
      // (Dados.FieldByName('hora_impressao_pedido_produto').AsString = '') then
      // begin
      //
      // end;

    end;

    Dados.Next;
  end;

  Dados.Free;
end;

procedure TfrmServidor.ResetUser;
begin
  user := 0;
  APIGoopedir.BuscarToken;
end;

function TfrmServidor.RetornaCertificado: TJsonArray;
var
  Objeto: TJsonObject;
  i: Integer;
begin
  try
    ACBrNFe1.SSL.LerCertificadosStore;

    Result := TJsonArray.Create;
    Objeto := TJsonObject.Create;
    Objeto.AddPair('value', '');
    Objeto.AddPair('descricao', 'Sem Certificado');
    Objeto.AddPair('numero_serie', '');
    Objeto.AddPair('razao_social', '');
    Objeto.AddPair('vencimento', FormatDateBr(now));
    Objeto.AddPair('certificadora', 'SEM CERTIFICADO');
    Objeto.AddPair('cnpj', '');
    Result.AddElement(Objeto);

    for i := 0 to ACBrNFe1.SSL.ListaCertificados.Count - 1 do
    begin
      with ACBrNFe1.SSL.ListaCertificados[i] do
      begin
        if (CNPJ <> '') then
        begin
          Objeto := TJsonObject.Create;
          Objeto.AddPair('value', NumeroSerie);
          Objeto.AddPair('descricao', '(' + NumeroSerie + ') ' + RazaoSocial +
            ' - CNPJ ' + CNPJ);
          Objeto.AddPair('numero_serie', NumeroSerie);
          Objeto.AddPair('razao_social', RazaoSocial);
          Objeto.AddPair('vencimento', FormatDateBr(DataVenc));
          Objeto.AddPair('certificadora', Certificadora);
          Objeto.AddPair('cnpj', CNPJ);
          Result.AddElement(Objeto);
        end;

      end;

    end;
  except
    on E: Exception do
    begin
      // ////////showmessage1(e.Message)
    end;
  end;

end;

procedure TfrmServidor.SaveToken(Numero: Integer; RefreshToken: string);
var
  conexao: Tconexao;
begin
  conexao := Tconexao.Create('SaveToken');
  conexao.SQL.Add('update ifood_connect set token = :token where id = :id');
  conexao.Parametros('id', Numero);
  conexao.Parametros('token', RefreshToken);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure TfrmServidor.SemAtualizacao;
begin
  if IntegracaoiFood then
  begin
    try

      // if not BackupExe then
      // IniciaIfood;

      // IFood.MerchantID(IDiFood);
      // // BuscaDadosiFood;
      // // IFood.MerchantStatus.AutoStatus := true;
      // // IFood.Polling.AutoPolling := true;
      // // BuscaDadosiFood;
      //
      // if not Assigned(ProcessamentoiFood) then
      // begin
      // ProcessamentoiFood := TProcessamentoiFood.Create;
      // ProcessamentoiFood.IFood := IFood;
      // ProcessamentoiFood.statusiFood := frmServidor.Configuracoes.FieldByName
      // ('aceitar_pedidos_ifood').AsInteger;
      // ProcessamentoiFood.Start;
      // end;

      // ProcessamentoiFood.TestImport;
    except
      on E: Exception do
      begin

      end;

    end;

  end;

  AtivaInativaProdutos;
  FazExclusaoClientes;

  try
    THorse.Listen(Port,
      procedure(Horse: THorse)
      begin

      end);
  except
    Application.Terminate;
    exit;
  end;
end;

procedure TfrmServidor.SetBase64Whatsapp(const Value: String);
begin
  FBase64Whatsapp := Value;
end;

procedure TfrmServidor.SetDataBloqueio(const Value: TDate);
begin
  FDataBloqueio := Value;
end;

procedure TfrmServidor.SetDataConfianca(const Value: TDate);
begin
  FDataConfianca := Value;
end;

procedure TfrmServidor.SetHorSite(const Value: TDateTime);
begin
  FHorSite := Value;
end;

procedure TfrmServidor.SetImagemWhatsapp(const Value: String);
begin
  FImagemWhatsapp := Value;
end;

procedure TfrmServidor.SetLogoutWhatsapp(const Value: Boolean);
begin
  FLogoutWhatsapp := Value;
end;

procedure TfrmServidor.SetNomeExeSite(const Value: String);
begin
  FNomeExeSite := Value;
end;

procedure TfrmServidor.SetNomeWhatsapp(const Value: String);
begin
  FNomeWhatsapp := (((Value)));
end;

procedure TfrmServidor.SetNumeroWhatsapp(const Value: String);
var
  conexao: Tconexao;
begin
  FNumeroWhatsapp := Value;
end;

procedure TfrmServidor.SetSemDataBloqueio(const Value: Boolean);
begin
  FSemDataBloqueio := Value;
end;

procedure TfrmServidor.SetSincNumeroWhatsapp(const Value: String);
begin
  FSincNumeroWhatsapp := Value;
end;

procedure TfrmServidor.SetStatusInstanciaCriada(const Value: Boolean);
begin
  FStatusInstanciaCriada := Value;
end;

procedure TfrmServidor.SetStatusWhatsapp(const Value: Boolean);
begin
  FStatusWhatsapp := Value;
end;

procedure TfrmServidor.setUser;
begin
  user := 0;
end;

procedure TfrmServidor.SincronizaCaixa(Codigo: Integer);
var
  Req: iRequisicao;
  conexao: Tconexao;
  JSON: TJsonObject;
  LJsonObject: TJsonObject;
  LCaixaId: Integer;
  LLink: string;
  Test: String;
begin

  try
    conexao := Tconexao.Create('SincronizaCaixa');
    Req := iRequisicao.Create(nil);
    Req.BaseURL := API_BASE_URL;
    Req.URL := 'api/interno/caixa/sinc';
    Req.Metodo := mPost;

    JSON := TJsonObject.Create;
    JSON.AddPair('user', UserID);
    JSON.AddPair('computado', DoGetCaixaTres(Codigo));
    JSON.AddPair('informado', DoGetCaixaTresLancado(Codigo));
    JSON.AddPair('sangria', DoGetCaixaTresSangria(Codigo));
    JSON.AddPair('produto', DoGetCaixaCincoProduto(Codigo));
    JSON.AddPair('categoria', DoGetCaixaCincoCategoria(Codigo));

    // Pedidos Cancelados

    // Produtos Excluidos
    Test := JSON.ToString;

    Req.BODY(JSON);
    Req.Execute;

    conexao.SQL.Add
      ('update caixa set id_site = :site, link = :link where id = :id');
    conexao.Parametros('id', Codigo);

    LJsonObject := TJsonObject.ParseJSONValue(Req.Retorno) as TJsonObject;
    try
      if Assigned(LJsonObject) then
      begin
        // Extrair o valor de caixa_id
        if LJsonObject.TryGetValue<Integer>('caixa_id', LCaixaId) then
        begin
          conexao.Parametros('site', LCaixaId);
        end
        else
        begin
          conexao.Parametros('site', -99);
        end;

        // Extrair o valor de link
        if LJsonObject.TryGetValue<string>('link', LLink) then
        begin
          conexao.Parametros('link', LLink);
        end
        else
        begin
          conexao.Parametros('link', 'dado incompleto');
        end;

      end;
    finally
      LJsonObject.Free;
    end;

  except
    conexao.Parametros('site', -1);
    conexao.Parametros('link', '');
  end;
  conexao.ExecuteSQL;
  Req.Free;
  conexao.Free;
end;

procedure TfrmServidor.SincronizaHorario;
begin
  if Assigned(APIGoopedir) then
    APIGoopedir.EnviaFuncionamento;
end;

procedure TfrmServidor.SincronizaParametros;
var
  conexao: Tconexao;
  Values: String;
begin
  if not Assigned(APIGoopedir) then
    exit;

  conexao := Tconexao.Create('main');
  conexao.SQL.Add('SELECT * FROM dados_whatsapp');
  Values := conexao.ConsultaSQL.ToString;

  APIGoopedir.SincronizaParametros(Values);
  conexao.Free;
end;

procedure TfrmServidor.SincronizaProdutos;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin
  if StatusSincProdutos then
    exit;
  StatusSincProdutos := true;
  conexao := Tconexao.Create('main');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT 0 as zero, codigo FROM produto where modificado_site = 0 and id_site > 0');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  // Produtos Novos
  conexao.SQL.Add
    ('SELECT 0 as zero, codigo FROM produto where id_site is null');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      EnviaProduto(Dados.FieldByName('codigo').AsInteger, '');
      Dados.Next;
    end;
  end;
  conexao.Free;
  Dados.Free;

  StatusSincProdutos := False;

end;

function TfrmServidor.SincronizarBackupFTP(const CaminhoArquivo,
  NomeUsuario: string; APIGoopedir: TGooPedirAPIController): Boolean;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      FTP: TIdFTP;
      SSL: TIdSSLIOHandlerSocketOpenSSL;
      AnoMes, PastaRemota, NomeArquivoOriginal, NomeZip, NomeSemExtensao,
        NomeArquivoLimpo: string;
      Zip: TZipFile;
    begin
      FTP := TIdFTP.Create(nil);
      SSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
      try
        try
          FTP.Host := 'ftp.goopedir.com';
          FTP.Username := 'u567036950.backup';
          FTP.Password := 'backup@Goopedir2025';
          FTP.Passive := true;
          FTP.ConnectTimeout := 15000;
          FTP.Connect;

          AnoMes := FormatDateTime('yyyy_mm', now);
          PastaRemota := NomeUsuario + '/' + AnoMes;

          // Cria diretórios
          try
            FTP.MakeDir(NomeUsuario);
          except
          end;
          try
            FTP.MakeDir(PastaRemota);
          except
          end;
          FTP.ChangeDir(PastaRemota);

          NomeArquivoOriginal := ExtractFileName(CaminhoArquivo);
          NomeSemExtensao := ChangeFileExt(NomeArquivoOriginal, '');

          // Remove data do nome
          NomeSemExtensao := ChangeFileExt(NomeArquivoOriginal, '');
          while (length(NomeSemExtensao) > 0) and
            (NomeSemExtensao[length(NomeSemExtensao)] in ['0' .. '9']) do
            Delete(NomeSemExtensao, length(NomeSemExtensao), 1);
          Delete(NomeSemExtensao, length(NomeSemExtensao), 1);
          NomeZip := TPath.ChangeExtension(NomeSemExtensao, '.zip');

          // Caminho local do ZIP
          NomeArquivoLimpo := TPath.Combine(TPath.GetTempPath, NomeZip);

          // Cria o ZIP
          if FileExists(NomeArquivoLimpo) then
            DeleteFile(NomeArquivoLimpo);

          Zip := TZipFile.Create;
          try
            Zip.Open(NomeArquivoLimpo, zmWrite);
            Zip.Add(CaminhoArquivo, NomeArquivoOriginal);
            // mantém nome original dentro do zip
            Zip.Close;
          finally
            Zip.Free;
          end;
          APIGoopedir.EnviaParametroUnico('nome_arquivo',
            PastaRemota + '/' + NomeZip, 'string');
          APIGoopedir.EnviaParametroUnico('nome_zip', NomeZip, 'string');
          // Envia o .zip em vez do .sql
          FTP.Put(NomeArquivoLimpo, NomeZip, False);
          TThread.Synchronize(nil,
            procedure
            begin

            end);

        except
          on E: Exception do
            TThread.Synchronize(nil,
              procedure
              begin

              end);
        end;
      finally
        if FTP.Connected then
          FTP.Disconnect;
        FTP.Free;
        SSL.Free;
      end;
    end).Start;
end;

function TfrmServidor.SITE(Nome: string): String;
var
  NomeEXE: String;
begin
  if Nome <> '' then
    NomeEXE := Nome + '.exe'
  else
    NomeEXE := 'SiteGooPedir.exe';

  if not FechouSite then
    Result := ExtractFileDir(Application.ExeName) + '\' + NomeEXE;
end;

function TfrmServidor.SocketProdutos(Message: String): String;
begin
  memLog.Lines.Add('Recebi ' + Message + ' e Respondi.');
  Result := 'Respondido!';
end;

function TfrmServidor.StatusPedidoiFood: Integer;
begin
  try
    Result := frmServidor.Configuracoes.FieldByName('aceitar_pedidos_ifood')
      .AsInteger;
  except
    Result := 0;
  end;
end;

procedure TfrmServidor.tAtualizaProcessosTimer(Sender: TObject);
var
  myThread1: TThread;
begin
  // myThread1 := TThread.CreateAnonymousThread(
  // procedure
  // begin

  // AtivaInativaProdutos;
  // FazExclusaoClientes;

  // end);
  //
  /// / Configura a Thread1 para se liberar automaticamente após a execução
  // myThread1.FreeOnTerminate := true;
  //
  // myThread1.Start();
end;

function TfrmServidor.TaxaiFood: Real;
begin
  try
    Result := frmServidor.Configuracoes.FieldByName('ifood_percentual').AsFloat;
  except
    Result := 0;
  end;
end;

procedure TfrmServidor.tBackupFTPTimer(Sender: TObject);
begin
  if (NomeArquivoBackup = '') then
    exit;

  if UserID < 1 then
    exit;
  tBackupFTP.Enabled := False;
  SincronizarBackupFTP(NomeArquivoBackup, UserID.ToString, APIGoopedir);
end;

procedure TfrmServidor.TemAtualizacao;
begin
  // Atualizacao.AtualizarBanco;
end;

procedure TfrmServidor.Timer1Timer(Sender: TObject);
var
  comando: String;
begin
  TrayIcon1.Visible := False;
  // Finaliza o servidor Horse
  THorse.StopListen;

  // Monta o comando CMD
  comando := Format('timeout /t %d /nobreak && start "" "%s"',
    [1, Application.ExeName]);

  // Executa o comando no CMD
  ShellExecute(0, 'open', 'cmd.exe', PChar('/c ' + comando), nil, SW_HIDE);
  FecharExe(Application.ExeName);

end;

procedure TfrmServidor.tMinimizaTimer(Sender: TObject);
begin

  tMinimiza.Enabled := False;
  self.Hide();
  self.WindowState := wsMinimized;
  // StatusForm := sOcuto;
  //
  // THorse.StopListen;
  // Sleep(1000);
  //
  // // Reinicia a aplicação
  // // ReiniciarAplicacao;
  //
  // // Finaliza a aplicação atual
  // try
  // Application.Terminate;
  // except
  //
  // end;
end;

function TfrmServidor.UserID: Integer;
var
  Requisicao: iRequisicao;
  BODY: String;
  JSonDadosSite: TJsonObject;
  Data: TDate;
  FormatSettings: TFormatSettings;
  DadosThread1: TDadosWhatsappAPI;
  conexao: Tconexao;
  Test: String;
  ArquivoExcluir: String;
  StatusWhatsapp: Boolean;
begin
  if not Assigned(APIGoopedir) then
    exit;

  if frmServidor.Configuracoes.FieldByName('client_id').AsString = '' then
  begin
    user := 0;
    Result := 0;
    Modulos := TJsonObject.Create;
    frmServidor.TrayIcon1.Hint := Port.ToString + 'p - Não Licenciado';
    exit;
  end;
  if user = -1 then
  begin
    // Fazer opção para recuperar o cache e não sincronizar produtos
    Result := user;
    exit;
  end;

  if user = 0 then
  begin
    try
      user := APIGoopedir.UserID;
      Result := APIGoopedir.UserID;

      BuscarModulo;

      try
        StatusWhatsapp := Modulos.GetValue<TJsonObject>('whatsapp')
          .GetValue<Boolean>('status');
      except
        StatusWhatsapp := False;
        StatusMensagemWhatsapp := -1;
      end;

      if StatusWhatsapp then
      begin
        DadosApiWhatsapp;
        if not DadosWhatsappBoolean then
        begin
          DadosThread1 := TDadosWhatsappAPI.Create(DadosApiWhatsapp, 15000 * 4);
          DadosThread1.FreeOnTerminate := true;
          // Libera a memória automaticamente quando terminar
          DadosWhatsappBoolean := true;
        end;
      end
      else
      begin
        StatusMensagemWhatsapp := -1;
      end;

      SemDataBloqueio := False;
      if UserID = -1 then
      begin
        self.DataBloqueio := IncDay(Data, 1);

        exit;
      end;
      try
        Test := '9';
        self.DataBloqueio := APIGoopedir.GetBloqueio;
      except
        // self.DataBloqueio := IncDay(Data, 1);
        SemDataBloqueio := true;
      end;

    except
      on E: Exception do
      begin
        frmServidor.AddErro('UserID', E.Message);

      end;

    end;
  end;

  Result := user;

  frmServidor.TrayIcon1.Hint := Port.ToString + 'p - ' + user.ToString + 'u';

end;

function TfrmServidor.ValidaTempoImpressaoStatus: Boolean;
var
  Diff: Int64;
begin
  // Verifica se Data1 é maior que Data2
  if now > DataHoraImpressaoService then
  begin
    // Calcula a diferença em minutos
    Diff := Round((now - DataHoraImpressaoService) * 24 * 60);
    // 24 horas * 60 minutos

    // Verifica se a diferença é maior que 3 minutos
    Result := Diff <= 1;
  end
  else
  begin
    // Se Data1 não for maior que Data2, retorna False
    Result := true;
  end;
end;

function TfrmServidor.ValidaTempoImpressaoStatusComanda: Boolean;
var
  Diff: Int64;
begin
  // Verifica se Data1 é maior que Data2
  if now > DataHoraImpressaoServiceComanda then
  begin
    // Calcula a diferença em minutos
    Diff := Round((now - DataHoraImpressaoServiceComanda) * 24 * 60);
    // 24 horas * 60 minutos

    // Verifica se a diferença é maior que 3 minutos
    Result := Diff <= 1;
  end
  else
  begin
    // Se Data1 não for maior que Data2, retorna False
    Result := true;
  end;
end;

function TfrmServidor.ValidaTempoImpressaoStatusCozinha: Boolean;
var
  Diff: Int64;
begin
  // Verifica se Data1 é maior que Data2
  if now > DataHoraImpressaoServiceCozinha then
  begin
    // Calcula a diferença em minutos
    Diff := Round((now - DataHoraImpressaoServiceCozinha) * 24 * 60);
    // 24 horas * 60 minutos

    // Verifica se a diferença é maior que 3 minutos
    Result := Diff <= 1;
  end
  else
  begin
    // Se Data1 não for maior que Data2, retorna False
    Result := true;
  end;
end;

function TfrmServidor.ValidaTempoImpressaoStatusOutros: Boolean;
var
  Diff: Int64;
begin
  // Verifica se Data1 é maior que Data2
  if now > DataHoraImpressaoServiceOutros then
  begin
    // Calcula a diferença em minutos
    Diff := Round((now - DataHoraImpressaoServiceOutros) * 24 * 60);
    // 24 horas * 60 minutos

    // Verifica se a diferença é maior que 3 minutos
    Result := Diff <= 1;
  end
  else
  begin
    // Se Data1 não for maior que Data2, retorna False
    Result := true;
  end;
end;

function TfrmServidor.VerificaExe(Nome: String): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Nome := ExtractFileName(Nome);
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(Nome)
      ) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(Nome))) then
    begin
      Result := true;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure TfrmServidor.VerificarOuCriarBanco;
var
  Qry: TFDQuery;
  HTTP: TIdHTTP;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  SQLScript, DatabaseName: string;
  Stream: TStringStream;
  conexao: Tconexao;
  iReq: iRequisicao;
begin
  conexao := Tconexao.Create('VerificarOuCriarBanco');
  try
    if frmServidor.Configuracoes.RecordCount = 0 then
    begin
      Qry := conexao.CriaQRY;
      try
        Qry.SQL.Text := 'SELECT * FROM version';
        Qry.Open;
      finally
        Qry.Free;
      end;
    end;
  except
    on E: EFDDBEngineException do
    begin
      // Captura erro de banco inexistente
      if pos('Unknown database', E.Message) > 0 then
      begin
        // Extrai nome do banco entre as aspas
        DatabaseName := Copy(E.Message, pos('''', E.Message) + 1, MaxInt);
        DatabaseName := Copy(DatabaseName, 1, pos('''', DatabaseName) - 1);

        iReq := iRequisicao.Create(nil);
        iReq.URL := 'https://goopedir.com/new.sql';
        iReq.TempoExpiracao := 15000;
        try
          iReq.Execute;
        finally
          SQLScript := iReq.Retorno;
        end;

        conexao.DisconectBanco;
        conexao.CriaQRY.ExecSQL('CREATE DATABASE `' + DatabaseName +
          '` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
        conexao.ConectaBanco(DatabaseName);
        conexao.Free;
        ExecutarSQLScript(SQLScript);

        // //showmessage('Banco de dados criado com sucesso.');
      end
      else
      begin
        raise; // Se for outro erro, apenas repassa
      end;
    end;
  end;
end;

function TfrmServidor.WHATSAPP: String;
begin
  if not FechouWhatsapp then
    Result := ExtractFileDir(Application.ExeName) + '\' + 'WhatsappGoPedir.exe';
end;

{ TAbrirServicos }

constructor TAbrirServicos.Create;
var
  IniFile: TIniFile;
begin

  inherited Create(true);
  conexao := Tconexao.Create('main');
  IniFile := TIniFile.Create('./goopedir.ini');
  Name := IniFile.ReadString('server', 'name', 'GooPedir');
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
  ServicoNFCe: Boolean;
  DadosImpressao: TFDMemTable;

  HoraAbertura: TTime;
  HoraFechamento: TTime;
  HoraAtual: TTime;

  Abertura: Integer;
  Fechamento: Integer;
  Atual: Integer;
  contador: Integer;

begin
  inherited;
  // DadosImpressao := TFDMemTable.Create(nil);
  contador := 0;

  while not Terminated do
  begin
    Inc(contador);

    // conexao.SQL.Add('select * from dados_whatsapp');
    // frmServidor.Configuracoes.LoadFromJSON(conexao.ConsultaSQL);
    // conexao.SQL.Add
    // ('SELECT * FROM impressao_pedido where data_solicitacao = current_date() and status = 0 and id_pedido > 0');
    // DadosImpressao.LoadFromJSON(conexao.ConsultaSQL);

    HoraAbertura :=
      StrToTime(Copy(frmServidor.Configuracoes.FieldByName('horario_abertura')
      .AsString, 0, 8));
    HoraFechamento :=
      StrToTime(Copy(frmServidor.Configuracoes.FieldByName('horario_fechamento')
      .AsString, 0, 8));

    // if DadosImpressao.RecordCount >= 5 then
    // begin
    // frmServidor.FecharExe(frmServidor.IMPRESSAO);
    // end;

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
    try
      ServicoNFCe := frmServidor.Configuracoes.FieldByName('nfce')
        .AsInteger = 1;
    except
      ServicoNFCe := False;
    end;
    if IsGreaterByOneMinute(now) then
    begin
      frmServidor.FecharExe(frmServidor.SITE(frmServidor.NomeExeSite));
    end;

    if (not frmServidor.VerificaExe(frmServidor.USANFCE)) and ServicoNFCe then
      frmServidor.AbrirExe(frmServidor.USANFCE);

    if (not frmServidor.VerificaExe(frmServidor.IMPRESSAO)) and ServicoImpressao
    then
      frmServidor.AbrirExe(frmServidor.IMPRESSAO);

    HoraAtual := now;
    HoraAbertura := IncMinute(HoraAbertura, -5);
    HoraFechamento := IncMinute(HoraFechamento, 15);

    Abertura := StrToInt(FormatDateTime('hhnn', HoraAbertura));
    Fechamento := StrToInt(FormatDateTime('hhnn', HoraFechamento));
    Atual := StrToInt(FormatDateTime('hhnn', HoraAtual));

    if (Atual >= Abertura) and (Fechamento >= Atual) then
    begin
      // Execute a função para abrir o caixa
      frmServidor.AbrirExe(frmServidor.WHATSAPP);
    end
    else
    begin
      // Fora do horário de abertura, não faz nada ou execute alguma outra ação, se necessário
      frmServidor.FecharExe(frmServidor.WHATSAPP);
    end;

    if (not frmServidor.VerificaExe(frmServidor.SITE(frmServidor.NomeExeSite)))
    then
    begin
      frmServidor.AbrirExe(frmServidor.SITE(frmServidor.NomeExeSite));
      frmServidor.XXX.Caption := frmServidor.SITE(frmServidor.NomeExeSite);
    end
    else
    begin
      frmServidor.XXX.Caption := 'OK';
    end;

    if HorarioRestart = FormatDateTime('hh:nn', now) then
    begin
      frmServidor.FecharExe(frmServidor.SITE(frmServidor.NomeExeSite));
      frmServidor.FecharExe(frmServidor.IMPRESSAO);
      frmServidor.FecharExe(frmServidor.WHATSAPP);
      frmServidor.FecharExe(frmServidor.SITE(frmServidor.NomeExeSite));
      frmServidor.FecharExe(frmServidor.USANFCE);
      frmServidor.FecharExe(Application.ExeName);
      frmServidor.FecharExe('GooPedir.exe');
    end;

    if contador = 1 then
    begin
      frmServidor.ReImpressao;
    end;
    if contador = 12 then
      contador := 1;

    Sleep(30 * 1000);
  end;

end;

function TAbrirServicos.IsGreaterByOneMinute(const ADateTime
  : TDateTime): Boolean;
var
  DifferenceInMinutes: Int64;
begin
  DifferenceInMinutes := MinutesBetween(frmServidor.HorSite, now);
  // Result := DifferenceInMinutes > 3;
  Result := False;
end;

{ TSincronizaProdutosThread }

constructor TSincronizaProdutosThread.Create;
begin
  inherited Create(False); // inicia automaticamente
  FreeOnTerminate := true;
end;

procedure TSincronizaProdutosThread.Execute;
var
  conexao: Tconexao;
  Memory: TFDMemTable;
begin
  inherited;

  while not Terminated do
  begin
    try
      conexao := Tconexao.Create('TSincronizaProdutosThread');
      Memory := TFDMemTable.Create(nil);
      conexao.SQL.Add
        ('SELECT 0 as zero, codigo FROM produto where modificado_site = 0 and id_site > 0');
      Memory.LoadFromJSON(conexao.ConsultaSQL);
      if Memory.RecordCount > 0 then
      begin
        while not Memory.Eof do
        begin
          conexao.SQL.Add
            ('update produto set modificado_site = 2 where codigo = :codigo');
          conexao.Parametros('codigo', Memory.FieldByName('codigo').AsInteger);
          conexao.ExecuteSQL;
          EnviaProduto(Memory.FieldByName('codigo').AsInteger, '');
          Memory.Next;
        end;
      end;

      conexao.Free;
      Memory.Free;

    except
      on E: Exception do
      begin
        if Assigned(conexao) then
          conexao.Free;
        if Assigned(Memory) then
          Memory.Free;
        // Se quiser logar erros, use TThread.Queue ou log local
      end;
    end;
    frmServidor.ExtornoPedidoNaoFinalizado;
    frmServidor.AtivaInativaProdutos;
    frmServidor.EnvioCaixa;
    Sleep(30000); // pausa de 30 segundos
  end;

end;

{ TBalancaManager }

constructor TBalancaManager.Create;
begin
  FBalancas := TDictionary<string, Double>.Create;
  FCritica := TCriticalSection.Create;
end;

destructor TBalancaManager.Destroy;
begin
  FBalancas.Free;
  FCritica.Free;
  inherited;
end;

procedure TBalancaManager.AtualizarPeso(const BalancaId: string;
const Peso: Double);
begin
  FCritica.Acquire;
  try
    FBalancas.AddOrSetValue(BalancaId, Peso);
  finally
    FCritica.Release;
  end;
end;

function TBalancaManager.ObterPeso(const BalancaId: string): Double;
begin
  FCritica.Acquire;
  try
    if not FBalancas.TryGetValue(BalancaId, Result) then
      Result := 0.0;
  finally
    FCritica.Release;
  end;
end;

function TBalancaManager.ExisteBalanca(const BalancaId: string): Boolean;
begin
  FCritica.Acquire;
  try
    Result := FBalancas.ContainsKey(BalancaId);
  finally
    FCritica.Release;
  end;
end;

end.
