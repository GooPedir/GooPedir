unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, uSQL,
  Winapi.TlHelp32, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, conexao, Vcl.Menus,
  FMX.Printer, ADRIFood.Model.Interfaces, ADRIFood.Model.Types,
  ADRIFood.Component.Events, ADRIFood.Component, FireDAC.Stan.StorageBin, JSON,
  FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait,
  FireDAC.DApt, IniFiles, ACBrBase, ACBrDFe, ACBrNFe, ACBrUtil,
  uImportacaoProduto, DateUtils, uProcessamentoiFood, Vcl.Controls, uRequisicao,
  uSite,
  GooPedirAPIController,
  REST.Client,
  REST.Types,
  Data.Bind.Components,
  Horse.XMLDoc, Xml.XMLDoc,
  System.IOUtils,
  Data.Bind.ObjectScope, Horse.ExceptionHandler, Horse, Horse.ServerStatic,
  cors,
  Web.HTTPApp, PedidoController, uLogThread;

type
  TCacheItem = record
    Timestamp: TDateTime;
    Data: string;
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
    IFood: TADRIFood;
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
    Button1: TButton;
    Timer1: TTimer;
    mHoraAbertura: TMenuItem;
    procedure tMinimizaTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Fechar1Click(Sender: TObject);
    procedure IFoodMerchantStatus
      (Status: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelMerchantStatus>);
    procedure IFoodOrderCancellationFailed(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderCancellationRequested
      (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderCancelled(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderChangePreparationTime
      (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderCollected(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderConcluded(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderConfirmed(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderConsumerCancellationAccepted
      (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderConsumerCancellationDenied
      (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderConsumerCancellationRequested
      (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderDelayNotification(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderDelivered(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderDispatched(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderGoingToOrigin(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderIntegrated(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderPickupAreaAssigned(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderPlaced(Order: IADRIFoodModelOrder;
      OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderPreparationStarted(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderReadyToDeliver(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderReadyToPickup(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderRecommendedPreparation
      (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderRequestDriver(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderRequestDriverAvailability
      (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderRequestDriverFailed(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderRequestDriverSuccess(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderBoxAssigned(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderAssignDriver(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodOrderArrivedAtOrigin(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
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
    procedure IFoodPollingEnd(EndPooling: TDateTime;
      OrdersHead: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelOrderHead>);
    procedure IFoodPollingError(Error: Exception);
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

    function ConverteValoriFood(Valor: String): Real;
    procedure SetHorSite(const Value: TDateTime);
    procedure SetDataBloqueio(const Value: TDate);
    procedure DescricaoIfood;
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

    function IntegracaoiFood: Boolean;
    procedure BuscaDadosiFood;
    function IDiFood: String;
    function TaxaiFood: Real;
    function StatusPedidoiFood: Integer;
    procedure AtualizaDadosiFood;
    procedure AtualizaStatus(OrderHead: IADRIFoodModelOrderHead);

    function UserID: Integer;
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
    function ObjetoProduto(SQL: String): TJsonArray;
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
    procedure BuscarWhatsappHeroku;
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

    procedure AtivaInativaSite(User: Integer);
    procedure ResetUser;

    function CreateiFoodConnection(Name, MerchantID: String): String;

    function GetToken(Numero: Integer): String;
    procedure SaveToken(Numero: Integer; RefreshToken: string);

    function IFoodRefreshTokenGet1: string;
    function IFoodRefreshTokenGet2: string;

    procedure IFoodRefreshTokenSave1(RefreshToken: string);
    procedure IFoodRefreshTokenSave2(RefreshToken: string);

    procedure IFoodOrderPlaced1(Order: IADRIFoodModelOrder;
      OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderPlaced2(Order: IADRIFoodModelOrder;
      OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);

    procedure IniciaIfood;
    function GetADRIFoodByTag(TagValue: Integer): TADRIFood;
    function GetInstancia(Pedido: String): Integer;

    procedure LogMiddleware(Req: THorseRequest; Res: THorseResponse;
      Next: TProc);
    function Metodo(Req: THorseRequest): String;
    procedure InitializeLogFile;

  var
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

  end;

var
  frmServidor: TfrmServidor;
  Atualizacao: TSQL;
  Servicos: TAbrirServicos;
  statusiFood: Boolean;
  User: Integer;
  ProcessamentoiFood: TProcessamentoiFood;

  ProcessamentoiFood1: TProcessamentoiFood;
  ProcessamentoiFood2: TProcessamentoiFood;

  Cache: TCacheItem;
  Port: Integer;
  LogFilePath: String;
  GerarLog: Boolean;

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

procedure TfrmServidor.AtivaInativaProdutos;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
begin

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

end;

procedure TfrmServidor.AtivaInativaSite(User: Integer);
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
    exit;
  end;
  IniFile.WriteDate('ATIVA', 'ATIVA', Date);
  IniFile.Free;
  try
    conexao := Tconexao.Create('AtivaInativaSite');

    JsonObject := TJsonObject.Create;
    JsonObject.AddPair('user', User);

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
      ('select 0 as zero, (id_site) as codigo from produto where id_site > 0 and ativo = 1');
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
      ('select id_pro_adi_personalizado, nome, (id_site) as codigo from pro_adi_personalizado_sabores where id_site > 0');
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    Valor := '0';
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        conexao.SQL.Add
          ('delete from pro_adi_personalizado_sabores where nome = :nome and id_pro_adi_personalizado = :id_pro_adi_personalizado and id_site <> :id_site');
        conexao.Parametros('nome', Dados.FieldByName('nome').AsString);
        conexao.Parametros('id_pro_adi_personalizado',
          Dados.FieldByName('id_pro_adi_personalizado').AsString);
        conexao.Parametros('id_site', Dados.FieldByName('id_site').AsString);
        conexao.ExecuteSQL;

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
      ('select 0 as zero, (id_site) as codigo from pro_adi_personalizado_sabores where id_site > 0 and ativo = 1');
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
      ('select 0 as zero, (id_site) as codigo from pro_adi_personalizado_sabores where id_site > 0 and ativo = 0');
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

    // showmessage1(JsonObject.ToString);

    Req := iRequisicao.Create(nil);
    Req.BaseURL := 'https://ws.goopedir.com/v1/itens.php';
    Req.BODY(JsonObject);

    Req.Metodo := mPost;
    Req.Execute;
    Req.Free;

    conexao.Free;
  except
    on E: Exception do
    begin
      // showmessage1(E.Message);

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

procedure TfrmServidor.AtualizaStatus(OrderHead: IADRIFoodModelOrderHead);
var
  conexao: Tconexao;
  SQL: String;
  statuscod: String;
  Status: String;
  IFood: String;
  Codigo, CodigoIntermo: Integer;
  imprimir: Integer;
begin

  statuscod := OrderHead.code;
  Status := OrderHead.fullCode;
  IFood := OrderHead.orderId;

  if OrderHead.code = 'CAN' then
  begin
    SQL := 'update pedido set status = 0, desc_desconto_ifood = motivo_cancelamento, status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
  end
  else
  begin
    if OrderHead.code = 'CAR' then
    begin
      SQL := 'update pedido set desc_desconto_ifood = "CANCELADO PELO GESTO", motivo_cancelamento = "CANCELADO PELO GESTO", status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
    end;

    SQL := 'update pedido set status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
  end;
  conexao := Tconexao.Create('main');
  conexao.SQL.Add(SQL);
  conexao.Parametros('id_ifood', IFood);
  conexao.Parametros('status_ifood', statuscod);
  conexao.Parametros('status_ifood_descricao', Status);
  conexao.ExecuteSQL;

  if OrderHead.code = 'CFM' then
  begin
    conexao.SQL.Add
      ('SELECT codigo, 0 as zero FROM pedido where id_ifood = :codigo');
    conexao.Parametros('codigo', IFood);
    CodigoIntermo := conexao.FieldByName('codigo');

    if CodigoIntermo > 0 then
    begin

      conexao.SQL.Add
        ('select * from impressao_pedido where id_pedido = :pedido');
      conexao.Parametros('pedido', CodigoIntermo);
      try
        imprimir := conexao.FieldByName('id');
      except
        imprimir := 0;
      end;
      // Imprimir

      if imprimir = 0 then
      begin
        Codigo := conexao.GerarID('impressao_pedido', 'id');
        conexao.SQL.Add
          ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
        conexao.Parametros('id', Codigo);
        conexao.Parametros('pedido', CodigoIntermo);
        conexao.ExecuteSQL;
      end;

      conexao.SQL.Add('UPDATE impressao_pedido_produto');
      conexao.SQL.Add('SET status = 0');
      conexao.SQL.Add('WHERE data_impressao IS NULL');
      conexao.SQL.Add
        ('AND id_pedido IN (SELECT codigo FROM pedido_produtos WHERE pedido_produtos.codigo_pedido = :pedido)');
      conexao.Parametros('pedido', CodigoIntermo);
      conexao.ExecuteSQL;
    end;
  end;

  conexao.Free;

end;

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
  // // //showmessage1(memCategoriaExtra.ToJSONArray().ToString);
  //
  // dataSetCategoy.Next;
  // end;
  //
  // end;
  //
  // conexao.Free;

end;

procedure TfrmServidor.BuscarModulo;
var
  Requisicao: iRequisicao;
  Memo: TMemo;
begin

  Memo := TMemo.Create(nil);

  Requisicao := iRequisicao.Create(self);
  Requisicao.BaseURL := 'https://ws.goopedir.com/modulos/index.php?user=' +
    UserID.ToString;
  try
    Requisicao.Execute;
    Memo.Text := Requisicao.Retorno;

  except
    on E: Exception do
    begin
      Memo.Text := '{}';

    end;
  end;

  Memo.Lines.SaveToFile('module.conf');
  Memo.Free;
  Requisicao.Free;

end;

procedure TfrmServidor.BuscarWhatsappHeroku;
var
  Req: iRequisicao;
  JSONObj: TJsonObject;
  InstanceData: TJsonObject;
  User: TJsonObject;
  ErrorValue: Boolean;
  IDValue: string;
begin

  if UserID > 0 then
  begin
    Req := iRequisicao.Create(nil);
    Req.BaseURL := 'whatsapp-api.goopedir.com/instance/';
    Req.URL := 'info?key=' + UserID.ToString;
    Req.Execute;

    JSONObj := TJsonObject.ParseJSONValue(Req.Retorno) as TJsonObject;
    try
      if Assigned(JSONObj) then
      begin
        // Extrai o valor do campo 'error'
        ErrorValue := JSONObj.GetValue<Boolean>('error');
        if not ErrorValue then
        begin
          StatusWhatsapp := true;
          // Extrai o campo 'instance_data'
          InstanceData := JSONObj.GetValue<TJsonObject>('instance_data');
          if Assigned(InstanceData) then
          begin
            // Extrai o campo 'user'
            User := InstanceData.GetValue<TJsonObject>('user');
            if Assigned(User) then
            begin
              // Extrai o valor do campo 'id'
              try
                IDValue := User.GetValue<string>('id');
                NumeroWhatsapp := FormatPhoneNumber(IDValue);
              except
                StatusWhatsapp := false;
                JSONObj.Free;
                Req.URL := 'qrbase64?key=' + UserID.ToString;
                Req.Execute;
                JSONObj := TJsonObject.ParseJSONValue(Req.Retorno)
                  as TJsonObject;
                Base64Whatsapp :=
                  StringReplace(JSONObj.GetValue<String>('qrcode'),
                  'data:image/png;base64,', '', [rfReplaceAll]);
              end;

            end;

          end;
        end
        else
        begin
          Req.URL := 'init?key=' + UserID.ToString + '&token=goopedir-whatsapp';
          Req.Execute;
          Req.Free;
          BuscarWhatsappHeroku;
          exit;
        end;
      end;
    finally
      JSONObj.Free;
    end;

  end;
  Req.Free;

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
var
  NewIfood: TADRIFood;
  Processamento: TProcessamentoiFood;
begin

  NewIfood := TADRIFood.Create(self);
  NewIfood.Name := 'IFOOD' + Name;
  NewIfood.Tag := StrToInt(Name);

  NewIfood.SoftwareHouse.Id := '09071157997';
  NewIfood.OnLogRequest := IFoodLogRequest;
  NewIfood.OnLogResponse := IFoodLogResponse;
  NewIfood.OnMerchantStatus := IFoodMerchantStatus;
  NewIfood.OnMerchantStatusError := IFoodMerchantStatusError;
  NewIfood.OnOrderArrivedAtOrigin := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderAssignDriver := IFoodOrderAssignDriver;
  NewIfood.OnOrderBoxAssigned := IFoodOrderBoxAssigned;
  NewIfood.OnOrderCancellationFailed := IFoodOrderCancellationFailed;
  NewIfood.OnOrderCancellationRequested := IFoodOrderCancellationRequested;
  NewIfood.OnOrderCancelled := IFoodOrderCancelled;
  NewIfood.OnOrderChangePreparationTime := IFoodOrderChangePreparationTime;
  NewIfood.OnOrderCollected := IFoodOrderCollected;
  NewIfood.OnOrderConcluded := IFoodOrderConcluded;
  NewIfood.OnOrderConfirmed := IFoodOrderConfirmed;
  NewIfood.OnOrderConsumerCancellationRequested :=
    IFoodOrderConsumerCancellationRequested;
  NewIfood.OnOrderConsumerCancellationAccepted :=
    IFoodOrderConsumerCancellationAccepted;
  NewIfood.OnOrderConsumerCancellationDenied :=
    IFoodOrderConsumerCancellationDenied;
  NewIfood.OnOrderDelayNotification := IFoodOrderDelayNotification;
  NewIfood.OnOrderDelivered := IFoodOrderDelivered;
  NewIfood.OnOrderDispatched := IFoodOrderDispatched;
  NewIfood.OnOrderGoingToOrigin := IFoodOrderGoingToOrigin;
  NewIfood.OnOrderIntegrated := IFoodOrderIntegrated;
  NewIfood.OnOrderPickupAreaAssigned := IFoodOrderPickupAreaAssigned;

  NewIfood.OnOrderPreparationStarted := IFoodOrderPreparationStarted;
  NewIfood.OnOrderReadyToDeliver := IFoodOrderReadyToDeliver;
  NewIfood.OnOrderReadyToPickup := IFoodOrderReadyToPickup;
  NewIfood.OnOrderRecommendedPreparation := IFoodOrderRecommendedPreparation;
  NewIfood.OnOrderRequestDriver := IFoodOrderRequestDriver;
  NewIfood.OnOrderRequestDriverAvailability :=
    IFoodOrderRequestDriverAvailability;
  NewIfood.OnOrderRequestDriverFailed := IFoodOrderRequestDriverFailed;
  NewIfood.OnOrderRequestDriverSuccess := IFoodOrderRequestDriverSuccess;
  NewIfood.OnPollingEnd := IFoodPollingEnd;
  NewIfood.OnPollingError := IFoodPollingError;
  NewIfood.OnPollingStart := IFoodPollingStart;
  if StrToInt(Name) = 1 then
  begin
    NewIfood.OnRefreshTokenSave := IFoodRefreshTokenSave1;
    NewIfood.OnRefreshTokenGet := IFoodRefreshTokenGet1;
    NewIfood.OnOrderPlaced := IFoodOrderPlaced1;

  end;
  if StrToInt(Name) = 2 then
  begin
    NewIfood.OnRefreshTokenSave := IFoodRefreshTokenSave2;
    NewIfood.OnRefreshTokenGet := IFoodRefreshTokenGet2;
    NewIfood.OnOrderPlaced := IFoodOrderPlaced2;

  end;

  NewIfood.Credentials.ClientId := IFood.Credentials.ClientId;
  NewIfood.Credentials.ClientSecret := IFood.Credentials.ClientSecret;
  if (IFood.Credentials.ClientId = '1a5799db-d82c-4a5d-a003-36247fe18176') then
  begin
    NewIfood.Credentials.AuthorizationType := ctCentralized;
  end
  else
  begin
    NewIfood.Credentials.AuthorizationType := ctDistributed;
  end;

  if (MerchantID <> '') then
  begin
    try
      NewIfood.MerchantStatus.AutoStatus := true;
      NewIfood.Polling.AutoPolling := true;
      NewIfood.MerchantID(IDiFood);

      if StrToInt(Name) = 1 then
      begin
        ProcessamentoiFood1 := TProcessamentoiFood.Create;
        ProcessamentoiFood1.IFood := NewIfood;
        ProcessamentoiFood1.statusiFood := frmServidor.Configuracoes.FieldByName
          ('aceitar_pedidos_ifood').AsInteger;
        ProcessamentoiFood1.Start;
        NewIfood.MerchantStatus.DataSource := dsMerchants1;

      end;
      if StrToInt(Name) = 2 then
      begin
        ProcessamentoiFood2 := TProcessamentoiFood.Create;
        ProcessamentoiFood2.IFood := NewIfood;
        ProcessamentoiFood2.statusiFood := frmServidor.Configuracoes.FieldByName
          ('aceitar_pedidos_ifood').AsInteger;
        ProcessamentoiFood2.Start;
        NewIfood.MerchantStatus.DataSource := dsMerchants2;
      end;

    except
      on E: Exception do
      begin
        // showmessage1(E.Message);

      end;

    end;

  end;

end;

procedure TfrmServidor.DadosApiWhatsapp;
var
  Req: iRequisicao;
  JsonObject: TJsonObject;
  ErrorValue: Boolean;
  User: TJsonObject;
begin

  if UserID > 0 then
  begin
    Req := iRequisicao.Create(nil);
    Req.BaseURL := 'https://ws.goopedir.com/whatsapp/status.php?instance=' +
      UserID.ToString;
    Req.TempoExpiracao := 15 * 1000;
    try
      Req.Execute;
      ErrorValue := false;

      JsonObject := TJsonObject.ParseJSONValue(Req.Retorno) as TJsonObject;
      if Assigned(JsonObject) then
      begin
        try
          ErrorValue := JsonObject.GetValue<Boolean>('error');
        except

        end;
        if not ErrorValue then
        begin
          User := JsonObject.GetValue<TJsonObject>('instance');

          if User.GetValue<String>('state') = 'open' then
          begin
            // Pegar dados
            DadosWhatsapp;
          end
          else
          begin
            // Buscar QRCod
            DadosQrCod;

          end;

          User.Free;

          StatusInstanciaCriada := true;
        end;

      end;
    except
      on E: Exception do
      begin
        // //showmessage1(e.Message);

      end;

    end;
    Req.Free;
    // if Assigned(JsonObject) then
    // JsonObject.Free;
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
    Requisicao.URL := 'https://ws.goopedir.com/v1/faturasn/' +
      frmServidor.UserID.ToString + '/a';
    // Requisicao.URL := 'https://ws.goopedir.com/v1/faturasn/44/a';
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
      JsonDadosBloqueio.AddPair('confianca', false);
    end
    else
    begin
      JsonDadosBloqueio.AddPair('confianca', true);
    end;

  except
    on E: Exception do
    begin
      // Res.Send(E.Message);

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
  Req.BaseURL := 'https://ws.goopedir.com/whatsapp/qrcod.php?instance=' +
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
        StatusWhatsapp := false;
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
  Req.BaseURL := 'https://ws.goopedir.com/whatsapp/instancia.php?instanceName='
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
      // //showmessage1(e.Message);

    end;

  end;
  Req.Free;

end;

procedure TfrmServidor.DescricaoIfood;
begin

  if (IFood.Credentials.ClientId = 'b683664a-f536-4cbf-a162-a2f98ac757e3') then
  begin
    pTipoIfood.Caption := 'Produção';
  end
  else
  begin
    pTipoIfood.Caption := 'Homologação';
  end;

  if (IFood.Credentials.ClientId = '156b1271-4e6b-49c7-98cd-92a49cd1dec7') then
    pTipoIfood.Caption := 'Homologação - Eneway';

end;

procedure TfrmServidor.EnviaGlitchtip(DSN, Tipo, Identificacao,
  Mensagem: String);
var
  JsonObjec: TJsonObject;
  Chave, API, JSONBody: string;
  URL: String;
  iGlitchtip: iRequisicao;

  RESTClient1: TRESTClient;
  RESTRequest1: TRESTRequest;
  RESTResponse1: TRESTResponse;
begin
  if not GerarLog then
    exit;

  JsonObjec := TJsonObject.Create;
  // Extrai a chave e a URL da DSN
  Chave := Copy(DSN, Pos('//', DSN) + 2, Pos('@', DSN) - Pos('//', DSN) - 2);
  URL := Copy(DSN, Pos('@', DSN) + 1, length(DSN));
  URL := StringReplace(URL, '/api/', '/api/' + Chave + '/store/', []);
  API := Copy(URL, Pos('/', URL) + 1, length(URL));
  URL := StringReplace(URL, '/' + API, '', []);

  JSONBody := JSONBody + '{';
  JSONBody := JSONBody + '  "event_id": "' + GenerateUUID + '",';
  JSONBody := JSONBody + '  "timestamp": "' +
    FormatDateTime('yyyy-mm-dd"T"hh":"nn":"ss"Z"', now) + '",';
  JSONBody := JSONBody + '  "level": "' + Tipo + '",';
  JSONBody := JSONBody + '  "platform": "delphi",';
  JSONBody := JSONBody + '  "message": "' + Identificacao + '",';
  JSONBody := JSONBody + '  "exception": {';
  JSONBody := JSONBody + '    "values": [';
  JSONBody := JSONBody + '      {';
  JSONBody := JSONBody + '        "type": "' + UpperCase(Tipo) + '",';
  JSONBody := JSONBody + '        "value": "' + Mensagem + '"';
  JSONBody := JSONBody + '      }';
  JSONBody := JSONBody + '    ]';
  JSONBody := JSONBody + '  },';
  JSONBody := JSONBody + '  "tags": {';
  JSONBody := JSONBody + '    "environment": "' + UserID.ToString + '",';
  JSONBody := JSONBody + '    "user": "' + UserID.ToString + '"';
  JSONBody := JSONBody + '  }';
  JSONBody := JSONBody + '}';
  JsonObjec.AddPair('url', 'https://' + URL + '/api/' + API + '/store/');
  JsonObjec.AddPair('autorizacao', Chave);
  JsonObjec.AddPair('body', TJsonObject.ParseJSONValue(JSONBody)
    as TJsonObject);

  // iGlitchtip := iRequisicao.Create(nil);
  // iGlitchtip.URL := 'https://ws.goopedir.com/glitchtip/index.php';
  // iGlitchtip.BODY(JsonObjec);
  //
  // try
  // iGlitchtip.Metodo := mPost;
  //
  // iGlitchtip.Execute;
  //
  // except
  // on E: Exception do
  // begin
  // ShowMessage(E.Message);
  // end;
  //
  // end;
  // iGlitchtip.Free;

  // Criando o TRESTClient

  RESTClient1 := TRESTClient.Create(nil);
  try
    RESTClient1.BaseURL := 'https://ws.goopedir.com/glitchtip/index.php';
    RESTClient1.SynchronizedEvents := false;

    // Criando o TRESTResponse
    RESTResponse1 := TRESTResponse.Create(nil);

    // Criando o TRESTRequest
    RESTRequest1 := TRESTRequest.Create(nil);
    try
      RESTRequest1.Client := RESTClient1;
      RESTRequest1.Response := RESTResponse1;
      RESTRequest1.SynchronizedEvents := false;
      RESTRequest1.Method := rmPOST;

      // Configurando os parâmetros da requisição
      // with RESTRequest1.Params.AddItem do
      // begin
      // Kind := pkREQUESTBODY;
      // Name := 'body67FAC2D51FE84D139EE71109F4F5AC14';
      // Value := JsonObjec.ToString;
      // ContentType := ctAPPLICATION_JSON;
      // end;

      RESTRequest1.AddBody(JsonObjec);

      // Executando a requisição
      try
        RESTRequest1.Execute;
        // ShowMessage(RESTResponse1.Content);
      except
        on E: Exception do
        begin
          // ShowMessage(E.Message);
        end;

      end;

      // Processando a resposta
      if RESTResponse1.StatusCode = 200 then
      begin
        // Sucesso
        // WriteLn('Requisição bem-sucedida: ' + RESTResponse1.Content);
      end
      else
      begin
        // Erro
        // WriteLn('Erro na requisição: ' + RESTResponse1.StatusText);
      end;

    finally
      RESTRequest1.Free;
    end;

  finally
    RESTClient1.Free;
    RESTResponse1.Free;
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
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
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
  I: Integer;
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
          for I := 0 to 9 do
          begin
            Ingrediente := StringReplace(Ingrediente, I.ToString, '',
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
  ClientId: String;
  ClientSecret: String;
  PedidosManager: TPedidosManager;

begin

  Caption := FormatDateTime('hh:nn', now);
  mHoraAbertura.Caption := Caption;
  THorse.Use(LogMiddleware);
  THorse.Use(ConfigurarCORS);
  THorse.Use(ExceptionMiddleware);
  THorse.Use(Jhonson);
  // THorse.Use(Etag);
  THorse.Use(OctetStream);
  THorse.Use(MiddlewareCORS);
  PIX.Open;
  CodigoPedido := 0;

  IniFile := TIniFile.Create('./goopedir.ini');
  Port := IniFile.ReadInteger('server', 'port', 2121);
  HorarioRestart := IniFile.ReadString('server', 'restart', '03:00');
  IniFile.WriteInteger('server', 'port', Port);
  IniFile.WriteString('server', 'baseurl', 'http://localhost:' +
    Port.ToString + '/');
  IniFile.WriteString('server', 'restart', '03:00');
  NomeExeSite := IniFile.ReadString('server', 'name', '');

  conexao := Tconexao.Create('main');
  VersaoMysql := conexao.ValidaVersao;
  conexao.SQL.Add('select * from dados_whatsapp');
  frmServidor.Configuracoes.LoadFromJSON(conexao.ConsultaSQL);
  conexao.Free;

  token.Registry;
  util.Registry;
  v2.Registry;
  NFCE.Registry;
  imprimir.Registry;

  try
    THorse.Listen(Port);
  except
    Application.Terminate;
    exit;
  end;

  {
    // PedidosManager := TPedidosManager.Create('1');


    //  if IniFile.ReadString('IFOOD', 'CLIENTID', '') = '' then
    //  begin
    //    HabilitarProduo1Click(nil);
    //  end;

    //  ClientId := IniFile.ReadString('IFOOD', 'CLIENTID', '');
    //  ClientSecret := IniFile.ReadString('IFOOD', 'CLIENTSECRET', '');
    //  IFood.Credentials.ClientId := ClientId;
    //  IFood.Credentials.ClientSecret := ClientSecret;
    //  if (ClientId = '1a5799db-d82c-4a5d-a003-36247fe18176') then
    //  begin
    //    IFood.Credentials.AuthorizationType := ctCentralized;
    //  end
    //  else
    //  begin
    //    IFood.Credentials.AuthorizationType := ctDistributed;
    //  end;
    //
    //  DescricaoIfood;
    Atualizacao := TSQL.Create;
    Atualizacao.MemoLog := memoHistorico;

    Atualizacao.SeTiverAtualizacao := TemAtualizacao;
    Atualizacao.seNaoTiverAtualizacao := SemAtualizacao;
    Atualizacao.IniciarAtualizacao := IniciarAtualizacao;
    Atualizacao.AposConcluirAtualizacao := FimAtualizacao;
    Atualizacao.AtualizaEstoque := AtualizaSaldoEstoque;

    Atualizacao.VerificaAtualizacao;

    Servicos := TAbrirServicos.Create;
    Servicos.HorarioRestart := HorarioRestart;
    Servicos.Start;
    frmServidor.LoadImpressora;

    IniFile.WriteString('site', 'clientId',
    frmServidor.Configuracoes.FieldByName('client_id').AsString);
    IniFile.WriteString('site', 'clientSecurity',
    frmServidor.Configuracoes.FieldByName('client_security').AsString);
    IniFile.Free;

    //  APIGoopedir := TGooPedirAPIController.Create
    //    ('https://site-api-v2.goopedir.com/',
    //    frmServidor.Configuracoes.FieldByName('client_id').AsString,
    //    frmServidor.Configuracoes.FieldByName('client_security').AsString,
    //    GetHorarioAbertura, GetHorarioFechamento, GetHorarioAtendimento);
    exit;

    // showmessage1(AtualizacaoCustoIngrediente(72).ToString);
    // BuscaCacheGeral;

    // ImportaProdutos;


    // THorse.Use(ServerStatic('public'));

    // Declaração das URI da API


    // Inicialização do Console




    // APIGoopedir.FunctionHorarioAbertura := GetHorarioAbertura;
    // APIGoopedir.FuncationHorarioFechamento := GetHorarioFechamento;
    // APIGoopedir.FunctionHorario := GetHorarioAtendimento;
    // FimAtualizacao;
  }

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
begin

  if CodigoPedido > 0 then
  begin
    inc(CodigoPedido);
    Result := CodigoPedido;
    exit;
  end;

  conexao := Tconexao.Create('main');
  conexao.SQL.Add
    ('select COALESCE(max(codigo_pedido_dia),0) as codigo, 0 as zero from pedido where data_pedido = curdate() and hora_pedido > "04:59:59"');
  CodigoPedido := conexao.FieldByName('codigo');
  conexao.Free;
  CodigoPedido := CodigoPedido + 1;
  Result := CodigoPedido;

end;

function TfrmServidor.GetADRIFoodByTag(TagValue: Integer): TADRIFood;
var
  I: Integer;
begin
  Result := nil; // Inicializa o resultado como nil
  for I := 0 to self.ComponentCount - 1 do
  begin
    if (self.Components[I] is TADRIFood) and
      (TADRIFood(self.Components[I]).Tag = TagValue) then
    begin
      Result := TADRIFood(self.Components[I]);
      Break; // Encontrou o componente, então sai do loop
    end;
  end;
end;

function TfrmServidor.GetCachedData: string;
var
  Requisicao: iRequisicao;
  JsonResponse: TJsonObject;
  ResultJson: TJsonObject;
  conexao: Tconexao;
begin

  if (Cache.Data <> '') and (MinutesBetween(now, Cache.Timestamp) <= 1) then
  begin
    Result := Cache.Data;
    exit;
  end;

  try
    Requisicao := iRequisicao.Create(nil);
    Requisicao.BaseURL := 'https://ws.goopedir.com/v1/horario.php?codigo=' +
      frmServidor.UserID.ToString;
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
      Cache.Timestamp := now;
      Cache.Data := ResultJson.ToString;

      conexao := Tconexao.Create('main');
      conexao.SQL.Add('update dados_whatsapp set cor_fundo = ' +
        QuotedStr(JsonResponse.GetValue('cor_topo').Value) + ', cor_fonte = ' +
        QuotedStr(JsonResponse.GetValue('cor_titulo_produtos').Value));
      conexao.ExecuteSQL;
      conexao.Free;
    end;

  except
    Cache.Data := '{}';
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
var
  ConfigFile: TStringList;
begin

  ConfigFile := TStringList.Create;
  try
    ConfigFile.LoadFromFile(ExtractFileDir(Application.ExeName) +
      '/module.conf');
    Result := ConfigFile.Text;
  finally
    ConfigFile.Free;
  end;

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

  IFood.Credentials.ClientId := 'ae66e3db-e145-4f3f-a810-6ff9ac5d4c5e';
  IFood.Credentials.ClientSecret :=
    'skywowzclkem9fcpvodbeof8rzghwerjiegvv1gnjxc5zmpgdnii4rld9sjriutxd6o1e9ds4yuh2181qlfspj5f1zv64ljk5uc';
  DescricaoIfood;
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

  IFood.Credentials.ClientId := 'b683664a-f536-4cbf-a162-a2f98ac757e3';
  IFood.Credentials.ClientSecret :=
    '1dg6shdja6v67rzy36djzw809zwqgfax3sidx6coemw9c9kzro5wxh2zvi5k65d3bt8cycn06ms43mfm7knayh7vxzxlbrl51ia';
  DescricaoIfood;
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
  Result := '13ba1b92-4e7f-4bb1-bb59-e234e4c6cedb';
  // '155cc414-36d0-4ec2-9d06-f85fad9e782a';
end;

procedure TfrmServidor.IFoodLogRequest(ARequestId, AContent: string);
// var
// log : String;
// log2 : String;
// begin
// log :=  ARequestId;
// log2 :=  AContent;
// end;
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
        Requisicao.BaseURL := 'https://ws.goopedir.com/logger.php';
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

procedure TfrmServidor.IFoodMerchantStatus
  (Status: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelMerchantStatus>);
begin
  statusiFood := dataSetMerchantStatus.FieldByName('available').AsBoolean;

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
        Requisicao.BaseURL := 'https://ws.goopedir.com/logger.php';
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

procedure TfrmServidor.IFoodOrderArrivedAtOrigin
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderAssignDriver
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderBoxAssigned(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderCancellationFailed
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderCancellationRequested
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderCancelled(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderChangePreparationTime
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderCollected(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderConcluded(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderConfirmed(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderConsumerCancellationAccepted
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderConsumerCancellationDenied
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderConsumerCancellationRequested
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderDelayNotification
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderDelivered(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderDispatched(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderGoingToOrigin
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderIntegrated(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderPickupAreaAssigned
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderPlaced(Order: IADRIFoodModelOrder;
  OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  ProcessamentoiFood.orderId(Order, OrderHead);

end;

procedure TfrmServidor.IFoodOrderPlaced1(Order: IADRIFoodModelOrder;
  OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  ProcessamentoiFood1.orderId(Order, OrderHead);

end;

procedure TfrmServidor.IFoodOrderPlaced2(Order: IADRIFoodModelOrder;
  OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  ProcessamentoiFood2.orderId(Order, OrderHead);

end;

procedure TfrmServidor.IFoodOrderPreparationStarted
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderReadyToDeliver
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderReadyToPickup
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderRecommendedPreparation
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderRequestDriver
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderRequestDriverAvailability
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderRequestDriverFailed
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodOrderRequestDriverSuccess
  (OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin

  bAcknowledgment := true;
  AtualizaStatus(OrderHead);

end;

procedure TfrmServidor.IFoodPollingEnd(EndPooling: TDateTime;
  OrdersHead: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelOrderHead>);
var
  test: String;
begin
  test := test;
end;

procedure TfrmServidor.IFoodPollingError(Error: Exception);
var
  test: String;
begin
  test := test;
end;

procedure TfrmServidor.IFoodPollingStart(StartPolling: TDateTime);
var
  test: String;
begin
  test := test;
end;

function TfrmServidor.IFoodRefreshTokenGet: string;
var
  IniFile: TIniFile;
  conexao: Tconexao;
  ComponenteChamador: TADRIFood;
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
  I, J, K: Integer;
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

  for I := 0 to JSONArray.Count - 1 do
  begin
    JSONItem := JSONArray.Items[I] as TJsonObject;
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
        Result := false;
    end;
  except

  end;

end;

procedure TfrmServidor.LoadImpressora;
var
  I: Integer;
  Id: Integer;
begin
  memImpressora.Close;
  memImpressora.Open;
  Id := 1;
  memImpressora.Insert;
  memImpressora.FieldByName('ID').AsInteger := Id;
  memImpressora.FieldByName('DRIVER').AsString := 'Default';
  memImpressora.Post;
  for I := 0 to Printer.Count - 1 do
  begin

    if (UpperCase(Printer.Printers[I].Device) <> 'FAX') and
      (UpperCase(Printer.Printers[I].Device) <> 'MICROSOFT PRINT TO PDF') and
      (UpperCase(Printer.Printers[I].Device) <> 'MICROSOFT XPS DOCUMENT WRITER')
    then
    begin
      inc(Id);
      memImpressora.Insert;
      memImpressora.FieldByName('ID').AsInteger := Id;
      memImpressora.FieldByName('DRIVER').AsString :=
        Printer.Printers[I].Device;
      memImpressora.Post;
    end;
  end;

end;

procedure TfrmServidor.LogMiddleware(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LogLine, BodyContent: string;
  LogFile: TStreamWriter;
begin
  if SameText(Metodo(Req), 'POST') then
  begin
    BodyContent := Req.BODY;
    // LogLine := LogLine + Format(' | Body: %s', [BodyContent]);
  end;
  EnviaGlitchtip
    ('https://9327eaf954a340cb94c64a8bf4afb696@nginx-glitchtip.l1p88w.easypanel.host/5',
    Req.RawWebRequest.RawPathInfo, Metodo(Req), BodyContent);
  // Req.RawWebRequest.RawPathInfo
  // try
  // // Monta a linha de log
  //
  // LogLine := Format('%s | %s | %s', [DateTimeToStr(now), Metodo(Req),
  // Req.RawWebRequest.PathInfo]);
  //
  // // Se for um método POST, adiciona o corpo da requisição

  //
  // // Abre o arquivo de log e escreve a linha
  // LogFile := TStreamWriter.Create(LogFilePath, true, TEncoding.UTF8);
  // try
  // LogFile.WriteLine(LogLine);
  // finally
  // LogFile.Free;
  // end;
  // except
  // on E: Exception do
  //
  // end;

  // Chama o próximo middleware ou a rota
  Next;
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
  // //showmessage1(Valor);
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

function TfrmServidor.ObjetoProduto(SQL: String): TJsonArray;
var
  conexao: Tconexao;
  Data: TJsonArray;
  DataS: String;

  JSONArray: TJsonArray;
  JsonObjeto: TJsonObject;
  JSonArrayAdicional: TJsonArray;
  JsonObjetoCategoriaAdicional: TJsonObject;

  JSonArrayAdicionalItens: TJsonArray;
  JSonObjetoAdicionalItens: TJsonObject;

  JSonObjectoPizza: TJsonObject;
  JSonArraySabores: TJsonArray;
  JSonObjectoSabores: TJsonObject;

  DadosProduto: TFDQuery;
  DadosCategoria: TFDMemTable;
  DadosAdicionais: TFDMemTable;
  DadosAdicionaisItens: TFDMemTable;
  DadosPizza: TFDMemTable;
  Min: Real;
  Max: Real;
  Estoque: Real;
begin
  conexao := Tconexao.Create('main');
  try
    DadosProduto := conexao.CriaQRY;
    DadosCategoria := TFDMemTable.Create(nil);
    DadosAdicionais := TFDMemTable.Create(nil);
    DadosAdicionaisItens := TFDMemTable.Create(nil);
    DadosPizza := TFDMemTable.Create(nil);

    conexao.SQL.Add(SQL);
    DadosProduto.SQL.Text := SQL;
    DadosProduto.Open;

    JSONArray := TJsonArray.Create;
    if DadosProduto.RecordCount > 0 then
    begin

      while not DadosProduto.Eof do
      begin
        Min := 9999999;
        Max := 0;

        JsonObjeto := TJsonObject.Create;

        JsonObjeto.AddPair('id', DadosProduto.FieldByName('codigo').AsInteger);
        JsonObjeto.AddPair('position', DadosProduto.FieldByName('position')
          .AsInteger);
        JsonObjeto.AddPair('new', DadosProduto.FieldByName('novidade')
          .AsInteger);
        JsonObjeto.AddPair('name', DadosProduto.FieldByName('nome_produto')
          .AsWideString);
        JsonObjeto.AddPair('description', DadosProduto.FieldByName('descricao')
          .AsString);
        JsonObjeto.AddPair('value',
          DadosProduto.FieldByName('valor_venda').AsFloat);
        try
          JsonObjeto.AddPair('tax_delivery',
            DadosProduto.FieldByName('valor_embalagem_delivery').AsFloat);
        except
          JsonObjeto.AddPair('tax_delivery', 0);
        end;
        try
          JsonObjeto.AddPair('stock_min',
            DadosProduto.FieldByName('estoque_min').AsFloat);
        except
          JsonObjeto.AddPair('stock_min', 0);
        end;
        try
          JsonObjeto.AddPair('tax_vb',
            DadosProduto.FieldByName('valor_embalagem_delivery').AsFloat);
        except
          JsonObjeto.AddPair('tax_delivery', 0);
        end;
        JsonObjeto.AddPair('status', DadosProduto.FieldByName('ativo')
          .AsInteger);
        JsonObjeto.AddPair('stock', DadosProduto.FieldByName('controle_estoque')
          .AsInteger);
        JsonObjeto.AddPair('img', DadosProduto.FieldByName('caminho_imagem')
          .AsString);
        JsonObjeto.AddPair('category', DadosProduto.FieldByName('codigo_grupo')
          .AsInteger);

        JsonObjeto.AddPair('ifood_id', DadosProduto.FieldByName('id_ifood')
          .AsString);
        JsonObjeto.AddPair('ifood_value',
          DadosProduto.FieldByName('valor_ifood').AsString);
        JsonObjeto.AddPair('ifood_img', DadosProduto.FieldByName('foto_ifood')
          .AsString);
        JsonObjeto.AddPair('ncm', DadosProduto.FieldByName('ncm').AsInteger);
        JsonObjeto.AddPair('cest', DadosProduto.FieldByName('cest').AsInteger);
        JsonObjeto.AddPair('cfop', DadosProduto.FieldByName('cfop').AsInteger);
        JsonObjeto.AddPair('cstipi', DadosProduto.FieldByName('cstipi')
          .AsInteger);
        JsonObjeto.AddPair('csticms', DadosProduto.FieldByName('csticms')
          .AsInteger);
        JsonObjeto.AddPair('cstpis', DadosProduto.FieldByName('cstpis')
          .AsInteger);
        JsonObjeto.AddPair('cstcofins', DadosProduto.FieldByName('cstcofins')
          .AsInteger);
        JsonObjeto.AddPair('csosn', DadosProduto.FieldByName('csosn')
          .AsInteger);
        JsonObjeto.AddPair('icms', DadosProduto.FieldByName('icms').AsFloat);
        JsonObjeto.AddPair('ipi', DadosProduto.FieldByName('ipi').AsFloat);
        JsonObjeto.AddPair('pis', DadosProduto.FieldByName('pis').AsFloat);
        JsonObjeto.AddPair('cofins', DadosProduto.FieldByName('cofins')
          .AsString);
        JsonObjeto.AddPair('frete', DadosProduto.FieldByName('frete').AsFloat);
        JsonObjeto.AddPair('un', DadosProduto.FieldByName('un').AsString);
        JsonObjeto.AddPair('fidelidade', DadosProduto.FieldByName('fidelidade')
          .AsString);
        JsonObjeto.AddPair('dias', DadosProduto.FieldByName('dias').AsString);
        JsonObjeto.AddPair('segunda', DadosProduto.FieldByName('segunda')
          .AsString);
        JsonObjeto.AddPair('terca', DadosProduto.FieldByName('terca').AsString);
        JsonObjeto.AddPair('quarta', DadosProduto.FieldByName('quarta')
          .AsString);
        JsonObjeto.AddPair('quinta', DadosProduto.FieldByName('quinta')
          .AsString);
        JsonObjeto.AddPair('sexta', DadosProduto.FieldByName('sexta').AsString);
        JsonObjeto.AddPair('sabado', DadosProduto.FieldByName('sabado')
          .AsString);
        JsonObjeto.AddPair('domingo', DadosProduto.FieldByName('domingo')
          .AsString);

        JsonObjeto.AddPair('people', DadosProduto.FieldByName('pessoas')
          .AsString);
        JsonObjeto.AddPair('value_discont',
          DadosProduto.FieldByName('valor_desconto').AsString);
        JsonObjeto.AddPair('value_percent',
          DadosProduto.FieldByName('percentual_desconto').AsString);
        JsonObjeto.AddPair('quanty', DadosProduto.FieldByName('saldo_atual')
          .AsString);
        JsonObjeto.AddPair('externalCode', DadosProduto.FieldByName('id_site')
          .AsInteger);
        JsonObjeto.AddPair('usaStock',
          DadosProduto.FieldByName('controle_estoque').AsInteger);
        JsonObjeto.AddPair('stock_current',
          DadosProduto.FieldByName('saldo_atual').AsInteger);

        {

          conexao.SQL.Add
          ('SELECT * FROM pro_adi_personalizado where id_produto = :id_produto');
          conexao.Parametros('id_produto', DadosProduto.FieldByName('codigo')
          .AsInteger);

          DadosAdicionais.Close;
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
          ('select * from pro_adi_personalizado_sabores where id_pro_adi_personalizado = :id');
          conexao.Parametros('id', DadosAdicionais.FieldByName('id')
          .AsInteger);
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
          JsonObjeto.AddPair('additional', JSonArrayAdicional);
          end
          else
          begin
          JSonArrayAdicional := TJsonArray.Create;
          JsonObjeto.AddPair('additional', JSonArrayAdicional);
          end;
        }
        { conexao.SQL.Add('select  ');
          conexao.SQL.Add('sabores_completo.id as sabor_id,  ');
          conexao.SQL.Add('sabores_completo.nome as sabor_nome,');
          conexao.SQL.Add('sabores_completo.descricao as sabor_descricao,');
          conexao.SQL.Add('sabores_completo.vl_venda as sabor_venda,');
          conexao.SQL.Add('sabores_completo.ativo as sabor_status,');
          conexao.SQL.Add('produto_pizza.quantidade_sabores as qtd_sabor, ');
          conexao.SQL.Add('tipo_sabor.id as tipo_id,');
          conexao.SQL.Add('tipo_sabor.nome as tipo_nome, tipo_sabor.descricao as tipo_descricao, tipo_sabor.ativo as tipo_status, ');
          conexao.SQL.Add('(select tipo_preco_pizza from dados_whatsapp limit 1) as tipo_valor from sabores_completo');
          conexao.SQL.Add('join produto_pizza on produto_pizza.codigo_produto = sabores_completo.id_produto');
          conexao.SQL.Add('join tipo_sabor on tipo_sabor.id  = sabores_completo.id_tipo_sabor');
          conexao.SQL.Add('where sabores_completo.id_produto = :id');
          conexao.SQL.Add('order by sabores_completo.id_produto, sabores_completo.id_tipo_sabor, sabores_completo.nome'); }
        conexao.SQL.Clear;
        conexao.SQL.Add('SELECT  ');
        conexao.SQL.Add('    sc.id AS sabor_id,  ');
        conexao.SQL.Add('    sc.nome AS sabor_nome, ');
        conexao.SQL.Add('    sc.descricao AS sabor_descricao, ');
        conexao.SQL.Add('    sc.vl_venda AS sabor_venda, ');
        conexao.SQL.Add('    sc.ativo AS sabor_status, ');
        conexao.SQL.Add('    pp.quantidade_sabores AS qtd_sabor, ');
        conexao.SQL.Add('    ts.id AS tipo_id, ');
        conexao.SQL.Add('    ts.nome AS tipo_nome, ');
        conexao.SQL.Add('    ts.descricao AS tipo_descricao, ');
        conexao.SQL.Add('    ts.ativo AS tipo_status, ');
        conexao.SQL.Add
          ('    (SELECT tipo_preco_pizza FROM dados_whatsapp LIMIT 1) AS tipo_valor ');
        conexao.SQL.Add('FROM sabores_completo sc ');
        conexao.SQL.Add
          ('JOIN produto_pizza pp ON pp.codigo_produto = sc.id_produto ');
        conexao.SQL.Add('JOIN tipo_sabor ts ON ts.id = sc.id_tipo_sabor ');
        conexao.SQL.Add('WHERE sc.id_produto = :id ');
        conexao.SQL.Add('ORDER BY sc.id_produto, sc.id_tipo_sabor, sc.nome');
        conexao.Parametros('id', DadosProduto.FieldByName('codigo').AsInteger);

        DadosPizza.Close;
        DadosPizza.LoadFromJSON(conexao.ConsultaSQL);
        JSonObjectoPizza := TJsonObject.Create;
        if DadosPizza.RecordCount > 0 then
        begin
          Min := 9999999;
          Max := 0;
          JSonObjectoPizza.AddPair('amountOfFlavors',
            DadosPizza.FieldByName('qtd_sabor').AsInteger);
          JSonObjectoPizza.AddPair('typeOfValue',
            DadosPizza.FieldByName('tipo_valor').AsInteger);
          case DadosPizza.FieldByName('tipo_valor').AsInteger of
            0:
              begin
                JSonObjectoPizza.AddPair('typeOfValueDescription',
                  'Average values / Média');
              end;
            1:
              begin
                JSonObjectoPizza.AddPair('typeOfValueDescription',
                  'Highest Value / Valor mais alto');
              end;
            2:
              begin
                JSonObjectoPizza.AddPair('typeOfValueDescription',
                  'Sum Of Values / Soma dos Valores');
              end
          else
            begin
              JSonObjectoPizza.AddPair('typeOfValueDescription', 'None');
            end;
          end;

          JSonArraySabores := TJsonArray.Create;
          while not DadosPizza.Eof do
          begin
            if Min > DadosPizza.FieldByName('sabor_venda').AsFloat then
              Min := DadosPizza.FieldByName('sabor_venda').AsFloat;

            if DadosPizza.FieldByName('sabor_venda').AsFloat > Max then
              Max := DadosPizza.FieldByName('sabor_venda').AsFloat;

            JSonObjectoSabores := TJsonObject.Create;
            JSonObjectoSabores.AddPair('typeId',
              DadosPizza.FieldByName('tipo_id').AsInteger);
            JSonObjectoSabores.AddPair('typeName',
              DadosPizza.FieldByName('tipo_nome').AsString);
            JSonObjectoSabores.AddPair('typeDescription',
              DadosPizza.FieldByName('tipo_descricao').AsString);
            JSonObjectoSabores.AddPair('typeStatus',
              DadosPizza.FieldByName('tipo_status').AsString);
            JSonObjectoSabores.AddPair('flavorId',
              DadosPizza.FieldByName('sabor_id').AsInteger);
            JSonObjectoSabores.AddPair('flavorName',
              DadosPizza.FieldByName('sabor_nome').AsString);
            JSonObjectoSabores.AddPair('flavorDescription',
              DadosPizza.FieldByName('sabor_descricao').AsString);
            JSonObjectoSabores.AddPair('flavorValue',
              DadosPizza.FieldByName('sabor_venda').AsFloat);
            JSonObjectoSabores.AddPair('flavorId',
              DadosPizza.FieldByName('sabor_id').AsInteger);
            JSonObjectoSabores.AddPair('flavorStatus',
              DadosPizza.FieldByName('sabor_status').AsInteger);
            JSonArraySabores.AddElement(JSonObjectoSabores);
            DadosPizza.Next;
          end;
          JSonObjectoPizza.AddPair('min', Min);
          JSonObjectoPizza.AddPair('max', Max);
          JSonObjectoPizza.AddPair('flavor', JSonArraySabores);

        end;

        JsonObjeto.AddPair('min', Min);
        JsonObjeto.AddPair('max', Max);
        JsonObjeto.AddPair('pizza', JSonObjectoPizza);
        JSONArray.AddElement(JsonObjeto);
        DadosProduto.Next;
      end;
    end;
  except
    on E: Exception do
    begin
    end;

  end;
  Result := JSONArray;
  conexao.Free;
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
        ('select * from pro_adi_personalizado_sabores where id_pro_adi_personalizado = :id');
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
  I: Integer;
begin
  for I := 1 to 1000 do
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
          CodigoAux := conexao.GerarID('impressao_pedido_produto', 'id');
          conexao.SQL.Add
            ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:pedido,:status,0,:usuario)');
          conexao.Parametros('pedido', Dados.FieldByName('codigo').AsString);
          conexao.Parametros('id', CodigoAux);
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
  ZeroMemory(@StartupInfo, sizeof(StartupInfo));
  StartupInfo.cb := sizeof(StartupInfo);
  ZeroMemory(@ProcessInfo, sizeof(ProcessInfo));

  // Cria um novo processo para reiniciar o executável
  if CreateProcess(PChar(Application.ExeName), // Caminho do executável
    nil, // Parâmetros de linha de comando
    nil, // Atributos de segurança do processo
    nil, // Atributos de segurança da thread
    false, // Herança de handles
    0, // Flags de criação
    nil, // Ambiente
    nil, // Diretório atual
    StartupInfo, ProcessInfo) then
  begin
    // Fecha os handles do processo e da thread
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

procedure TfrmServidor.ResetUser;
begin
  User := 0;
end;

function TfrmServidor.RetornaCertificado: TJsonArray;
var
  Objeto: TJsonObject;
  I: Integer;
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

    for I := 0 to ACBrNFe1.SSL.ListaCertificados.Count - 1 do
    begin
      with ACBrNFe1.SSL.ListaCertificados[I] do
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
      // //showmessage1(e.Message)
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

      IniciaIfood;

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

        // ShowMessage('1-' + E.Message);

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
  User := 0;
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
  StatusSincProdutos := false;

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

procedure TfrmServidor.TemAtualizacao;
begin
  // Atualizacao.AtualizarBanco;
end;

procedure TfrmServidor.Timer1Timer(Sender: TObject);
var
  Comando: String;
begin
  TrayIcon1.Visible := false;
  // Finaliza o servidor Horse
  THorse.StopListen;

  // Monta o comando CMD
  Comando := Format('timeout /t %d /nobreak && start "" "%s"',
    [1, Application.ExeName]);

  // Executa o comando no CMD
  ShellExecute(0, 'open', 'cmd.exe', PChar('/c ' + Comando), nil, SW_HIDE);
  FecharExe(Application.ExeName);

end;

procedure TfrmServidor.tMinimizaTimer(Sender: TObject);
begin

  tMinimiza.Enabled := false;
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
begin



  // user := 58;

  if User = 0 then
  begin
    try
      Requisicao := iRequisicao.Create(nil);
      Requisicao.BaseURL := 'https://goopedir.com/ws/v1/';
      Requisicao.URL := 'token2/a';
      BODY := '{' + #13 + '"client_id":"' +
        frmServidor.Configuracoes.FieldByName('client_id').AsString + '",' + #13
        + '"client_security":"' + frmServidor.Configuracoes.FieldByName
        ('client_security').AsString + '"' + #13 + '}';

      Requisicao.BODY(BODY);

      Requisicao.Metodo := mPost;

      Requisicao.TempoExpiracao := 60 * 1000;
      Requisicao.Execute;
      JSonDadosSite := TJsonObject.ParseJSONValue(Requisicao.Retorno)
        as TJsonObject;

      // Data := TransformaData(JSonDadosSite.Get('empresa_data_renovacao').JsonValue.ToString);
      // "2023-01-01"

      Result := StrToInt(StringReplace(JSonDadosSite.Get('user')
        .JsonValue.ToString, '"', '', [rfReplaceAll]));
      User := Result;
      AtivaInativaSite(User);
      BuscarModulo;
      DadosApiWhatsapp;
      if not DadosWhatsappBoolean then
      begin
        DadosThread1 := TDadosWhatsappAPI.Create(DadosApiWhatsapp, 15000 * 4);
        DadosThread1.FreeOnTerminate := true;
        // Libera a memória automaticamente quando terminar
        DadosWhatsappBoolean := true;
      end;
      SemDataBloqueio := false;
      try
        self.DataBloqueio :=
          StrToDate(Copy(JSonDadosSite.Get('empresa_data_renovacao')
          .JsonValue.ToString, 10, 2) + '/' +
          Copy(JSonDadosSite.Get('empresa_data_renovacao').JsonValue.ToString,
          7, 2) + '/' + Copy(JSonDadosSite.Get('empresa_data_renovacao')
          .JsonValue.ToString, 2, 4));
      except
        SemDataBloqueio := true;
      end;

      DataConfianca :=
        StrToDate(Copy(JSonDadosSite.Get('confianca').JsonValue.ToString, 10, 2)
        + '/' + Copy(JSonDadosSite.Get('confianca').JsonValue.ToString, 7, 2) +
        '/' + Copy(JSonDadosSite.Get('confianca').JsonValue.ToString, 2, 4));
      frmServidor.SincronizaHorario;
      SincronizaProdutos;

      conexao := Tconexao.Create('USER');
      conexao.SQL.Add('update produto set userid = :user where userid is null');
      conexao.Parametros('user', User);
      conexao.ExecuteSQL;
      conexao.Free;

    except
      on E: Exception do
      begin
        frmServidor.AddErro('UserID', E.Message);

      end;

    end;
  end;

  Result := User;

  frmServidor.TrayIcon1.Hint := Port.ToString + 'p - ' + User.ToString + 'u';

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
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := false;
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
    inc(contador);

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
      ServicoImpressao := false;
    end;
    try
      ServicoWhatsapp := frmServidor.Configuracoes.FieldByName('a_whatsapp')
        .AsInteger = 1;
    except
      ServicoWhatsapp := false;
    end;
    try
      ServicoNFCe := frmServidor.Configuracoes.FieldByName('nfce')
        .AsInteger = 1;
    except
      ServicoNFCe := false;
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
  Result := false;
end;

end.
