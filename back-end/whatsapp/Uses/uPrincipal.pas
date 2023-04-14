unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uTInject, uBotConversa, uBotGestor,
  uCEFWinControl, uCEFWindowParent, uTInject.Classes, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, Vcl.ComCtrls, System.Rtti,
  System.Bindings.Outputs, Vcl.Bind.Editors, Data.Bind.EngExt,
  Vcl.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope, Vcl.Grids,
  Vcl.DBGrids, Vcl.Menus, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList,
  Vcl.AppEvnts, Vcl.Buttons, Vcl.StdCtrls, uClassEnviaMensagem,
  uRequisicao, DataSet.Serialize;

type

  TEnviaWhatsapp = class(TThread)
  private
    Requisicao: iRequisicao;
  protected
    procedure Execute; override;
  public
    constructor Create();
  end;

  TdmPrincipal = class(TForm)
    iWhatsapp: TInject;
    pgPrincipal: TPageControl;
    TabWhatsapp: TTabSheet;
    TabLog: TTabSheet;
    CEFWindowParent1: TCEFWindowParent;
    memLOG: TFDMemTable;
    memLOGid: TStringField;
    memLOGNome: TStringField;
    memLOGetapa: TIntegerField;
    memLOGsituacao: TStringField;
    memLOGhora: TStringField;
    memLOGdescricao: TStringField;
    memLOGpergunta: TStringField;
    memLOGfinalizou_pedido: TIntegerField;
    dsLog: TDataSource;
    DBGrid1: TDBGrid;
    memLOGresposta: TStringField;
    pReset: TPopupMenu;
    ResetarConversa1: TMenuItem;
    tabTabelas: TTabSheet;
    dsTabelas: TDataSource;
    DBGrid2: TDBGrid;
    Tray: TTrayIcon;
    tMinimize: TTimer;
    ApplicationEvents1: TApplicationEvents;
    Test: TTabSheet;
    mMensagem: TMemo;
    edtMsg: TEdit;
    btnEnviar: TSpeedButton;
    CheckBox1: TCheckBox;
    imgSucesso: TImageList;
    imgSemConexao: TImageList;
    tNotificaPedido: TTimer;
    cRecebendoPedidos: TCheckBox;
    Log: TTabSheet;
    mLog: TMemo;
    cConfirmacao: TCheckBox;
    RequisicaoLocal: iRequisicao;
    procedure FormCreate(Sender: TObject);
    procedure iWhatsappGetQrCode(const Sender: TObject;
      const QrCode: TResultQRCodeClass);
    procedure iWhatsappGetUnReadMessages(const Chats: TChatList);
    procedure ResetarConversa1Click(Sender: TObject);
    procedure iWhatsappConnected(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tMinimizeTimer(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure AtualizadorAfterDownload(Sender: TObject;
      const Downloaded: Boolean);
    procedure AtualizadorAfterUpdate(Sender: TObject);
    procedure AtualizadorError(Sender: TObject; NumErro: Integer;
      MsgErro: string);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure edtMsgKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CheckBox1Click(Sender: TObject);
    procedure tNotificaPedidoTimer(Sender: TObject);
    procedure cRecebendoPedidosClick(Sender: TObject);
    procedure iWhatsappDisconnected(Sender: TObject);
    procedure iWhatsappDisconnectedBrute(Sender: TObject);
    procedure iWhatsappGetMyNumber(Sender: TObject);
  private
    FRecebendoPedido: Boolean;
    FHD: String;
    { Private declarations }

    function DescricaoSituacao(Situacao: TSituacaoConversa): String;

    procedure GeraArquivo(Conversa: TBotConversa);
    function ValidaNovosPedidos: Boolean;
    function ValidaMensagemNova(Conversa: TBotConversa): Boolean;

    procedure ValidaMensagensNaoRespondidas;

    // Atualizador
    procedure ConfiguraAtualizador;
    procedure GravaErro(E: Exception);

    procedure AdicionaMsgTest(Msg: String);
    procedure SetRecebendoPedido(const Value: Boolean);
    procedure SetHD(const Value: String);
  public
    procedure LimpaConversaBackup(Conversa: TBotConversa);
    { Public declarations }
    procedure GestorInteracao(Conversa: TBotConversa);
    function MenuInicial(Conversa: TBotConversa): String;

    procedure GravaConversa(Conversa: TBotConversa);
    procedure ConversaMensagem(Conversa: TBotConversa; Status: Integer);

    function CriaQRY(Nome: String): TFDQuery;
    function ExecultaSQL(SQL: String): Boolean;
    function CriaTabela(Tabela, PK: String): TFDTable; Overload;
    function CriaTabela(Tabela: String): TFDTable; Overload;

    function ParametrosDadosEmpresa: TFDMemTable;

    function GerarID(Tabela, Campo: String): Integer;

    function Enviamensagem(Etapa: Integer; Mensagem: String;
      Conversa: TBotConversa): TBotConversa; overload;

    procedure EnviaBotao(Conversa: TBotConversa; Mensagem, Descricao: String;
      Botao, ID: array of String);

    procedure Enviamensagem(Conversa: TBotConversa; Mensagem: String); overload;

    procedure GeraLOG(Conversa: TBotConversa; Descricao: String);

    procedure NotificaPedidoWindows(Pedido, Valor: String);

    property RecebendoPedido: Boolean read FRecebendoPedido
      write SetRecebendoPedido;

    procedure ADDLog(Mensagem: String);
    function SerialNum(): string;

    property HD: String read FHD write SetHD;

  var
    Mensagem: TEnviaMensagemThreed;
    AguardarEnvioMensagem: Boolean;
  end;

const
  MENSAGEM_QUEBRA_LINHA = '\n';
  MENSAGEM_QUEBRA_LINHA_DUPLA = '\n\n';
  FORMATA_CAMPO_MENU = '00';
  MONO_ESPACADA = '```';
  MEU_NUMERO = '554898153342@c.us';

var
  dmPrincipal: TdmPrincipal;
  IDMensagemTest: Integer;
  Site: TWppThreed;
  Gestor: TBotManager;

  // Novo Botão
  Usar_Novo_Botao: Boolean;

implementation

{$R *.dfm}

uses uConversa, uClassPedido, uClassEndereco, uDM, uClassFinalizarPedido,
  uAlteracaoCancelamento, uClassPedidoRecente,
  uClassCronometro, uClassThreeConversa, uBackup,
  udmProdutos;

procedure TdmPrincipal.ADDLog(Mensagem: String);
begin
  mLog.Lines.Add(DateToStr(now));
  mLog.Lines.Add(Mensagem);
  mLog.Lines.Add('');
end;

procedure TdmPrincipal.AdicionaMsgTest(Msg: String);
begin

  Msg := StringReplace(Msg, '\n', #13, [rfReplaceAll]);
  mMensagem.Lines.Text := Msg;
end;

procedure TdmPrincipal.ApplicationEvents1Exception(Sender: TObject;
  E: Exception);
begin
  GravaErro(E);
end;

procedure TdmPrincipal.AtualizadorAfterDownload(Sender: TObject;
  const Downloaded: Boolean);
var
  Mensagem: String;
begin
  Mensagem := '*Download concluido!*';
  iWhatsapp.Send(MEU_NUMERO, Mensagem);
end;

procedure TdmPrincipal.AtualizadorAfterUpdate(Sender: TObject);
var
  Mensagem: String;
begin
  Mensagem := '*Sistema Atualizado!*';
  iWhatsapp.Send(MEU_NUMERO, Mensagem);
end;

procedure TdmPrincipal.AtualizadorError(Sender: TObject; NumErro: Integer;
  MsgErro: string);
var
  Mensagem: String;
begin
  Mensagem := MsgErro;
  iWhatsapp.Send(MEU_NUMERO, Mensagem);
end;

procedure TdmPrincipal.CheckBox1Click(Sender: TObject);
begin
  Usar_Novo_Botao := CheckBox1.Checked;
end;

procedure TdmPrincipal.ConfiguraAtualizador;
begin

  // CriaQRY('FTP').Close;
  // CriaQRY('FTP').SQL.Clear;
  // CriaQRY('FTP').SQL.Add('select host,user,password,port from dados_whatsapp');
  // CriaQRY('FTP').Open;
  //
  // Atualizador.Config.FTP.User := CriaQRY('FTP').FieldByName('user').AsString;
  // Atualizador.Config.FTP.Password := CriaQRY('FTP')
  // .FieldByName('password').AsString;
  // Atualizador.Config.FTP.Server := CriaQRY('FTP').FieldByName('host').AsString;
  // Atualizador.Config.FTP.Port := CriaQRY('FTP').FieldByName('port').AsInteger;
  //
  // Atualizador.Config.FTP.Timeout := 10000;
  // Atualizador.Backup := True;
  // Atualizador.DirDownload := ExtractFilePath(Application.ExeName) + 'versao\';
  // Atualizador.DirBackupFile := ExtractFilePath(Application.ExeName) + 'backup\'
  // + FormatDateTime('dd_mm_yyyy', date) + '\';

end;

procedure TdmPrincipal.ConversaMensagem(Conversa: TBotConversa;
  Status: Integer);
var
  GeralConversautil: TGeralConversa;
begin
  GeralConversautil := TGeralConversa.Create;
  GeralConversautil.ConversaMensagem(Conversa, 0);
  GeralConversautil.Free;
end;

procedure TdmPrincipal.cRecebendoPedidosClick(Sender: TObject);
var
  QRYUpdate: TFDQuery;
  Valor: String;
begin

  if cRecebendoPedidos.Checked then
    Valor := 'F'
  else
    Valor := 'T';

  QRYUpdate := dm.CriaQRY('UPD');

  QRYUpdate.Close;
  QRYUpdate.SQL.Add
    ('update dados_componentes set valor = :valor where frm = ''frmPrincipal'' and campo = ''ckbRecebendoPedido'' and id_usuario = 0');
  QRYUpdate.ParamByName('valor').AsString := Valor;
  QRYUpdate.ExecSQL;
  QRYUpdate.Free

end;

function TdmPrincipal.CriaQRY(Nome: String): TFDQuery;
begin
  Result := dm.CriaQRY(Nome);
end;

function TdmPrincipal.CriaTabela(Tabela, PK: String): TFDTable;
begin
  Result := dm.CriaTabela(Tabela, PK);
end;

function TdmPrincipal.CriaTabela(Tabela: String): TFDTable;
begin
  Result := CriaTabela(Tabela, '');
end;

function TdmPrincipal.DescricaoSituacao(Situacao: TSituacaoConversa): String;
begin
  case Situacao of
    Aguardando:
      Result := 'Aguardando';
    NovoCliente:
      Result := 'Novo Cliente';
    NovoPedido:
      Result := 'Novo Pedido';
    MenuPedido:
      Result := 'Menu';
    AdicionandoProduto:
      Result := 'Adiciona Produto';
    AdicionandoPizza:
      Result := 'Adiciona Pizza';
    SelecionandoFormaPedido:
      Result := 'Forma de Pagamento';
    FinalizandoPedido:
      Result := 'Finalizando Pedido';
    CaschBack:
      Result := 'CashBack';
    Finalizado:
      Result := 'Finalizando Pedido';
    VerificaUltimoPedido:
      Result := 'Verificando Ultimo Peido';
    EnderecoCliente:
      Result := 'Endereço Cliente';
    AlteraRemove:
      Result := 'Alterar / Remover';
    Cancelamento:
      Result := 'Cancelamento';
  end;
end;

procedure TdmPrincipal.edtMsgKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  AMessage: TMessagesClass;

begin
  if Key = 13 then
  begin

    inc(IDMensagemTest);
    AMessage := TMessagesClass.Create('');
    AMessage.ID := '554800000000@c.us';

    AMessage.Sender.ID := '554800000000@c.us';
    AMessage.body := edtMsg.Text;
    AMessage.&type := 'chat';
    AMessage.t := IDMensagemTest;

    Gestor.ProcessarResposta(AMessage);
    try
      AMessage.Free;
    except

    end;

    edtMsg.Clear;
    edtMsg.SetFocus;

  end;
end;

function TdmPrincipal.Enviamensagem(Etapa: Integer; Mensagem: String;
  Conversa: TBotConversa): TBotConversa;
Var
  Responder: Boolean;
begin

  Result := Conversa;

  if Result.ID = '554800000000@c.us' then
  begin
    AdicionaMsgTest(Result.Pergunta);
  end;
  Responder := True;
  if SerialNum = '90FC9F1F' then
  begin
    if Result.ID <> '554898111156@c.us' then
    begin
      Responder := False;
    end;

    if  Result.Telefone = '4896185516' then
     Responder := True;


  end;
  if Responder then
  begin
    Result.Etapa := Etapa;
    Result.Pergunta := Mensagem;
    Result.Resposta := '';

    iWhatsapp.ReadMessages(Result.ID);
    iWhatsapp.Send(Result.ID, Mensagem);
    iWhatsapp.ReadMessages(Result.ID);
    // Conversa := Result;
    try
      ConversaMensagem(Conversa, 1);
    except

    end;
    try
      GravaConversa(Result);
    except

    end;
    try
      if dm.CriaTabela('conversa_backup_mensagem', 'id')
        .Locate('idmensagem', Conversa.IDMensagem, []) then
      begin
        dm.CriaTabela('conversa_backup_mensagem', 'id').Delete;
      end;
    except

    end;
  end;

end;

procedure TdmPrincipal.EnviaBotao(Conversa: TBotConversa;
  Mensagem, Descricao: String; Botao, ID: array of String);
var
  ArrayBotao: Array of String;
  ArrayBotaoID: Array of String;
  i: Integer;
begin
  //

  SetLength(ArrayBotao, length(Botao));
  SetLength(ArrayBotaoID, length(Botao));

  for i := 0 to length(Botao) - 1 do
  begin
    ArrayBotao[i] := Botao[i];
    try
      ArrayBotaoID[i] := ID[i];
    except
      ArrayBotaoID[i] := i.ToString;
    end;
  end;
  Conversa.IDMensagem := 0;

//  iWhatsapp.EnviaBotao(Conversa.ID, Mensagem, Descricao, ArrayBotao,    ArrayBotaoID);
  GravaConversa(Conversa);

end;

procedure TdmPrincipal.Enviamensagem(Conversa: TBotConversa; Mensagem: String);
begin

  if Conversa.ID = '554800000000@c.us' then
  begin
    AdicionaMsgTest(Conversa.Pergunta);
  end;
  Conversa.ID := '554898111156@c.us';

  iWhatsapp.ReadMessages(Conversa.ID);
  iWhatsapp.Send(Conversa.ID, Mensagem);
  iWhatsapp.ReadMessages(Conversa.ID);
  try
    if dm.CriaTabela('conversa_backup_mensagem', 'id')
      .Locate('idmensagem', Conversa.IDMensagem, []) then
    begin
      dm.CriaTabela('conversa_backup_mensagem', 'id').Delete;
    end;
  except

  end;
end;

function TdmPrincipal.ExecultaSQL(SQL: String): Boolean;
var
  QRYExecutar: TFDQuery;
begin
  QRYExecutar := CriaQRY('EXECUTAR');
  QRYExecutar.Close;
  QRYExecutar.SQL.Clear;
  QRYExecutar.SQL.Add(SQL);
  try
    QRYExecutar.ExecSQL;

    Result := True;
  except
    Result := False;
  end;

end;

procedure TdmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;
  WindowState := wsMinimized;

end;

procedure TdmPrincipal.FormCreate(Sender: TObject);
var
  QRYAux: TFDQuery;
begin
  SerialNum;
  sleep(1000);
  Site := TWppThreed.Create;
  Gestor := TBotManager.Create(self);
  Gestor.OnInteracao := GestorInteracao;
  if not iWhatsapp.Auth(False) then
  Begin
    iWhatsapp.FormQrCodeStart;
  End;

  memLOG.Open;

  QRYAux := CriaQRY('AUX01');
  QRYAux.Close;
  QRYAux.SQL.Clear;
  QRYAux.SQL.Add('SELECT * FROM conversa_backup where data = ' +
    QuotedStr(FormatDateTime('yyyy-mm-dd', date)));
  QRYAux.Open;

  while not QRYAux.Eof do
  begin
    if QRYAux.FieldByName('id_wpp').AsString <> '' then
    begin
      memLOG.Insert;
      memLOG.FieldByName('id').AsString := QRYAux.FieldByName('id_wpp')
        .AsString;
      memLOG.Post;
    end;

    QRYAux.Next;
  end;

  ValidaMensagensNaoRespondidas;
  ConfiguraAtualizador;

  IDMensagemTest := 0;
  mMensagem.Lines.Clear;
  dmProdutos := TdmProdutos.Create(self);

  Usar_Novo_Botao := False;
  CheckBox1.Checked := Usar_Novo_Botao;

end;

procedure TdmPrincipal.GeraArquivo(Conversa: TBotConversa);
var
  arq: TextFile;
  Geral: TGeralConversa;
begin
  try
    if not FileExists('C:\PapaLeguas\Conversa.txt') then
      exit;
    AssignFile(arq, 'C:\PapaLeguas\Conversa.txt');
    Append(arq);
    Writeln(arq, 'Nome: ' + Conversa.Nome);
    Writeln(arq, 'Celular: ' + Conversa.Telefone);
    Writeln(arq, 'Resposta: ' + Conversa.Resposta);
    Writeln(arq, 'Etapa: ' + IntToStr(Conversa.Etapa));
    Writeln(arq, 'Situacao: ' +
      IntToStr(Geral.idSituacaoAtual(Conversa.Situacao)));
    Writeln(arq, '');
    CloseFile(arq);
  except

  end;
end;

procedure TdmPrincipal.GeraLOG(Conversa: TBotConversa; Descricao: String);
begin
  if memLOG.Locate('id', Conversa.ID, []) then
  begin
    memLOG.Edit;
  end
  else
  begin
    memLOG.Insert;
    memLOG.FieldByName('id').AsString := Conversa.ID;
  end;
  memLOG.FieldByName('nome').AsString := Conversa.Nome;
  memLOG.FieldByName('etapa').AsInteger := Conversa.Etapa;
  memLOG.FieldByName('situacao').AsString :=
    DescricaoSituacao(Conversa.Situacao);
  memLOG.FieldByName('descricao').AsString := Descricao;
  memLOG.FieldByName('pergunta').AsString := Conversa.Pergunta;
  memLOG.FieldByName('resposta').AsString := Conversa.Resposta;
  memLOG.FieldByName('hora').AsString := FormatDateTime('hh:mm', time);
  memLOG.Post;

end;

function TdmPrincipal.GerarID(Tabela, Campo: String): Integer;
begin
  Result := dm.GerarID(Tabela, Campo);
end;

procedure TdmPrincipal.GestorInteracao(Conversa: TBotConversa);
var
  UsuarioValido: Boolean;

  GeralConversautil: TGeralConversa;
  MenuGeral: TMenu;
  EnderecoGeral: TEndereco;
  Finaliza: TFinalizarPedido;
  CancelamentoF: TCancelamento;
  AlteracaoRemover: TAlteracaoRemover;
  VerificaPedido: TPedidoRecente;
  Conversa2: TBotConversa;
  Erro: String;

  Resposta: String;
  Backup: TBackup;
begin


  if dm.DADOS_EMPRESA.FieldByName('tipo_wpp_auto_bot').AsInteger <> 1 then
  begin
    // Enviar apenas a mensagem do inicio

    if not(time > dm.DADOS_EMPRESA.FieldByName('horario_fechamento').AsDateTime)
    then
    begin
      dmPrincipal.Enviamensagem(0, dmPrincipal.MenuInicial(Conversa), Conversa);
    end;
    exit;
  end;

  if AguardarEnvioMensagem then
    exit;

  try
    if Backup = nil then
      Backup := TBackup.Create;

    if Backup.Backup(Conversa) then
    begin
      exit;
    end;
    Backup.Free;

    Resposta := trim(Conversa.Resposta);

    GeraArquivo(Conversa);

    RecebendoPedido := ValidaNovosPedidos;

    if not RecebendoPedido then
    begin
      exit;
    end;

    if GeralConversautil = nil then
      GeralConversautil := TGeralConversa.Create;
    Conversa := GeralConversautil.EtapaConversa(Conversa);
    GeralConversautil.ConversaMensagem(Conversa, 0);
    if Resposta <> '' then
      Conversa.Resposta := Resposta;

    if MenuGeral = nil then
      MenuGeral := TMenu.Create;
    if EnderecoGeral = nil then
      EnderecoGeral := TEndereco.Create;
    if Finaliza = nil then
      Finaliza := TFinalizarPedido.Create;
    if CancelamentoF = nil then
      CancelamentoF := TCancelamento.Create;
    if AlteracaoRemover = nil then
      AlteracaoRemover := TAlteracaoRemover.Create;
    if VerificaPedido = nil then
      VerificaPedido := TPedidoRecente.Create;

    // Grava em Qual Etapa o Cliente Esta

    // Valida Se o Cliente é cadastrado
    UsuarioValido := GeralConversautil.ClienteCadastrado(Conversa);
    if UsuarioValido then
    begin
      // Já é Cliente
      Conversa := GeralConversautil.DadosDoCliente(Conversa);
    end;

    case Conversa.Situacao of
      Aguardando:
        begin
          if UsuarioValido then
          begin
            // Já é Cliente
            Conversa2 := GeralConversautil.DadosDoCliente(Conversa);
            Conversa2.Etapa := 0;
            Conversa2.Situacao := MenuPedido;
            GeraLOG(Conversa2, 'Validando Usuario');
            GeralConversautil.GravaEtapaConversa(Conversa2);
            Conversa := Conversa2;
            GestorInteracao(Conversa);
            exit;
            // Mandar Para NovoPedido
          end
          else
          begin
            // Novo Cliente
            if Conversa.Situacao = Aguardando then
            begin
              Conversa.Situacao := NovoCliente;
              Conversa.Etapa := 0;
              GeraLOG(Conversa, 'Cadastro Cliente');
              GeralConversautil.GravaEtapaConversa(Conversa);

              GestorInteracao(Conversa);

              exit;
            end;
          end;
        end;

      NovoCliente:
        begin
          GeralConversautil.DadosNovoCliente(Conversa);
          exit;
        end;
      VerificaUltimoPedido:
        begin
          VerificaPedido.VerificaPedidoRecente(Conversa);
          exit;
        end;

      MenuPedido:
        begin
          MenuGeral.MenuPedido(Conversa);
          exit;
        end;

      NovoPedido:
        begin

        end;

      AdicionandoProduto:
        begin

        end;

      AdicionandoPizza:
        ;
      SelecionandoFormaPedido:
        ;
      FinalizandoPedido:
        begin
          Finaliza.Finalizando(Conversa);
          exit;
        end;
      AlteraRemove:
        begin
          AlteracaoRemover.AlterarRemover(Conversa);
          exit;
        end;
      Cancelamento:
        begin
          CancelamentoF.Cancelamento(Conversa);
          exit;
        end;

      CaschBack:
        ;
      Finalizado:
        begin
          dmPrincipal.GeraLOG(Conversa, 'Finalizado');
          LimpaConversaBackup(Conversa);
          if memLOG.Locate('id', Conversa.ID, []) then
            memLOG.Delete;
          Gestor.Conversas.Remove(Conversa);
          exit;
        end;

      EnderecoCliente:
        begin
          EnderecoGeral.Endereco(Conversa);
          exit;
        end;
      AtendimentoHumano:
        begin
          if UpperCase(Conversa.Resposta) = 'VOLTAR' then
          begin
            Conversa.Etapa := 0;
            Conversa.Resposta := '';
            Conversa.Situacao := MenuPedido;
            GravaConversa(Conversa);
            GestorInteracao(Conversa);;
            exit;
          end;
        end;
    end;

  except
    on E: Exception do
    begin
      if Conversa <> nil then
      begin
        if (pos('ACCESS', UpperCase(E.Message)) > 0) or
          (pos('IS NOT A VALID INTEGER', UpperCase(E.Message)) > 0) or
          (pos('INVALID POINTER OPERATIONEINVALIDPOINTER', UpperCase(E.Message))
          > 0) or (pos('OPERATION', UpperCase(E.Message)) > 0) then
        begin
          Enviamensagem(Conversa.Etapa, Conversa.Pergunta, Conversa);
          exit;
        end;
        Erro := Erro + '*Data/Hora:* ' + FormatDateTime('dd/mm/yyyy hh:mm', now)
          + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Cliente:* ' + Conversa.Nome + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Celular:* ' + Conversa.Telefone +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Etapa:* ' + IntToStr(Conversa.Etapa) +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Situação:* ' + DescricaoSituacao(Conversa.Situacao) +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Pergunta:* ' + Conversa.Pergunta +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Resposta:* ' + Conversa.Resposta +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Erro:* ' + E.Message + #13 + E.ClassName;
        iWhatsapp.Send(MEU_NUMERO, Erro);
        Erro := Conversa.Pergunta;
        if Conversa.Resposta = '' then
          Erro := '';
        iWhatsapp.Send(Conversa.ID, Erro);
        exit;
      end;
    end;
  end;

end;

procedure TdmPrincipal.GravaConversa(Conversa: TBotConversa);
var
  Tabela: TFDTable;
  TabelaSAP: TFDTable;
  Geral: TGeralConversa;
  i: Integer;
begin
  Gestor.ConversasMemoria.GravaConversa := Conversa;

  try
    Tabela := dmPrincipal.CriaTabela('conversa_backup');

    if Tabela.Locate('id_wpp', Conversa.ID, []) then
    begin
      Tabela.Edit;
    end
    else
    begin
      Tabela.Insert;
      Tabela.FieldByName('id').AsInteger :=
        dmPrincipal.GerarID('conversa_backup', 'id');
    end;

    dm.CriaQRY('DELETA').Close;
    dm.CriaQRY('DELETA').SQL.Clear;
    dm.CriaQRY('DELETA')
      .SQL.Add('delete from conversa_backup_sap where id_conversa = ' +
      Tabela.FieldByName('id').AsString);
    dm.CriaQRY('DELETA').ExecSQL;
    dm.CriaQRY('DELETA').Free;

    TabelaSAP := dmPrincipal.CriaTabela('conversa_backup_sap');

    Tabela.FieldByName('data').AsDateTime := date;
    Tabela.FieldByName('idmensagem').AsString :=
      FloatToStr(Conversa.IDMensagem);
    Tabela.FieldByName('aux').AsInteger := Conversa.AuxCliente;
    Tabela.FieldByName('codigo_endereco').AsInteger := Conversa.CodigoEndereco;
    Tabela.FieldByName('id_wpp').AsString := Conversa.ID;
    Tabela.FieldByName('pergunta').AsString := Conversa.Pergunta;
    Tabela.FieldByName('resposta').AsString := Conversa.Resposta;
    Tabela.FieldByName('etapa').AsInteger := Conversa.Etapa;
    Tabela.FieldByName('categoria').AsInteger :=
      Conversa.ProdutoCategoriaSelecionada;
    Tabela.FieldByName('produto').AsInteger :=
      Conversa.ProdutoCodigoSelecionado;
    Tabela.FieldByName('situacao').AsInteger :=
      Geral.idSituacaoAtual(Conversa.Situacao);

    if Conversa.Entrega = VemBuscar then
      Tabela.FieldByName('tipo_pedido').AsInteger := 0
    else
      Tabela.FieldByName('tipo_pedido').AsInteger := 1;

    Tabela.FieldByName('qtdcategoria').AsInteger :=
      Conversa.QuantidadeCategoria;
    Tabela.FieldByName('categoriaatual').AsInteger := Conversa.CategoriaAtual;
    Tabela.FieldByName('mincategoria').AsInteger := Conversa.MinimoCategoria;
    Tabela.FieldByName('maxcategoria').AsInteger := Conversa.MaximoCategoria;
    Tabela.FieldByName('produtocategoria').AsInteger :=
      Conversa.ProdutoCategoriaSelecionada;
    Tabela.FieldByName('produtoselecionado').AsInteger :=
      Conversa.ProdutoCodigoSelecionado;
    Tabela.FieldByName('sqlcategoria').AsString := Conversa.SQLCategoria;
    Tabela.FieldByName('qtdproduto').AsFloat := Conversa.ProdutoQuantidade;
    Tabela.FieldByName('codendereco').AsInteger := Conversa.CodigoEndereco;
    Tabela.FieldByName('numero').AsString := Conversa.Numero;
    Tabela.FieldByName('categoriadescricao').AsString :=
      Conversa.CategoriaDescricao;

    Tabela.FieldByName('complemento').AsString := Conversa.Complemento;
    if Conversa.DadosEnderecoCliente <> nil then
    begin
      Tabela.FieldByName('complemento').AsString :=
        Conversa.DadosEnderecoCliente.EnderecoCompleto;
      Tabela.FieldByName('numero').AsString :=
        Conversa.DadosEnderecoCliente.EnderecoComNumero;
      Tabela.FieldByName('rua').AsString := Conversa.DadosEnderecoCliente.Rua;
      Tabela.FieldByName('bairro').AsString :=
        Conversa.DadosEnderecoCliente.Bairro;
      Tabela.FieldByName('cidade').AsString :=
        Conversa.DadosEnderecoCliente.Cidade;
      Tabela.FieldByName('estado').AsString :=
        Conversa.DadosEnderecoCliente.Estado;
      Tabela.FieldByName('cep').AsString := Conversa.DadosEnderecoCliente.CEP;
      Tabela.FieldByName('km').AsFloat := Conversa.DadosEnderecoCliente.KM;
    end;

    Tabela.Post;

    for i := 0 to length(Conversa.ArrayCategorias) - 1 do
    begin
      TabelaSAP.Insert;
      TabelaSAP.FieldByName('id').AsInteger :=
        dmPrincipal.GerarID(TabelaSAP.TableName, 'id');
      TabelaSAP.FieldByName('id_conversa').AsInteger := Tabela.FieldByName('id')
        .AsInteger;
      TabelaSAP.FieldByName('descricao').AsString :=
        Conversa.ArrayCategorias[i];
      TabelaSAP.FieldByName('item').AsString :=
        Conversa.ArrayCategoriasItens[i];
      TabelaSAP.FieldByName('valor').AsFloat :=
        Conversa.ArrayCategoriasValores[i];
      TabelaSAP.FieldByName('tipo_valor').AsInteger :=
        Conversa.ArrayCategoriasTipoValor[i];
      TabelaSAP.Post;
    end;
    for i := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
    begin
      TabelaSAP.Insert;
      TabelaSAP.FieldByName('id').AsInteger :=
        dmPrincipal.GerarID(TabelaSAP.TableName, 'id');
      TabelaSAP.FieldByName('id_conversa').AsInteger := Tabela.FieldByName('id')
        .AsInteger;
      TabelaSAP.FieldByName('descricao').AsString :=
        Conversa.ArrayDadosEndereco[i];
      TabelaSAP.FieldByName('valor').AsFloat := -1;
      TabelaSAP.Post;
    end;

  except

  end;
  try
    Tabela.Free;
  except

  end;

end;

procedure TdmPrincipal.GravaErro(E: Exception);
var
  arq: TextFile;
  Local: String;
begin

  Local := ExtractFilePath(Application.ExeName) + '\ERRO_WPP.LOG';
  AssignFile(arq, Local);
  if FileExists(Local) then
  begin
    Append(arq);
  end
  else
  begin
    Rewrite(arq);
  end;
  //
  Writeln(arq, 'DATA/HORA: ' + FormatDateTime('dd/mm/yyyy hh:mm:ss', now));
  Writeln(arq, 'CLASSNAME: ' + E.ClassName);
  Writeln(arq, 'MENSAGEM: ' + E.Message);
  CloseFile(arq);
  // E.ClassName
end;

procedure TdmPrincipal.iWhatsappConnected(Sender: TObject);
var
  Cronometro: TCronometro;
  Envia: TEnviaWhatsapp;
begin
  TabLog.TabVisible := True;
  Tray.BalloonTitle := '#GooPedir';
  Tray.BalloonHint := 'Whatsapp Conectado';
  Tray.Animate := False;
  Tray.Icons := imgSucesso;
  Tray.Animate := True;
  Tray.ShowBalloonHint;

  Mensagem := TEnviaMensagemThreed.Create;
  Mensagem.Aguardar := True;
  Mensagem.Start;
  // tNotificaPedido.Enabled := True;
  // Cronometro := TCronometro.Create;
  // Cronometro.Start;
  Site.Start;

  Envia := TEnviaWhatsapp.Create;
  Envia.Start;
end;

procedure TdmPrincipal.iWhatsappDisconnected(Sender: TObject);
begin
  // if Assigned(Site) then
  // Site.free;
end;

procedure TdmPrincipal.iWhatsappDisconnectedBrute(Sender: TObject);
begin
  // if Assigned(Site) then
  // Site.free;
end;

procedure TdmPrincipal.iWhatsappGetMyNumber(Sender: TObject);
begin
  if Assigned(Site) then
    Site.AtualizaCelular(TInject(Sender).MyNumber);
end;

procedure TdmPrincipal.iWhatsappGetQrCode(const Sender: TObject;
  const QrCode: TResultQRCodeClass);
begin
  //
end;

procedure TdmPrincipal.iWhatsappGetUnReadMessages(const Chats: TChatList);
begin

  Gestor.AdministrarChatList(iWhatsapp, Chats);

end;

procedure TdmPrincipal.LimpaConversaBackup(Conversa: TBotConversa);
var
  Tabela: TFDTable;
begin
  Tabela := CriaTabela('conversa_backup');

  if Tabela.Locate('id_wpp', Conversa.ID, []) then
  begin
    CriaQRY('DELETE').Close;
    CriaQRY('DELETE').SQL.Clear;
    CriaQRY('DELETE')
      .SQL.Add('delete from conversa_backup_sap where id_conversa = ' +
      Tabela.FieldByName('id').AsString);
    try
      CriaQRY('DELETE').ExecSQL;
    except

    end;
    Tabela.Delete;
  end;
  Tabela.Free;

end;

function TdmPrincipal.MenuInicial(Conversa: TBotConversa): String;
Var
  txSaudacao: String;
begin

  if time > StrToDateTime('06:00') then
  begin
    txSaudacao := 'bom dia';
  end;
  if time > StrToDateTime('12:00') then
  begin
    txSaudacao := 'boa tarde';
  end;
  if time > StrToDateTime('18:00') then
  begin
    txSaudacao := 'boa noite';
  end;

  Result := dm.DADOS_EMPRESA.FieldByName('MENSAGEM_INICIAL').AsString;
  Result := StringReplace(Result, '[NOME_CLIENTE]', trim(Conversa.Nome),
    [rfReplaceAll]);
  Result := StringReplace(Result, '[SAUDACAO]', trim(txSaudacao),
    [rfReplaceAll]);
  Result := StringReplace(Result, '[NOME_EMPRESA]',
    trim(dm.DADOS_EMPRESA.FieldByName('NOME').AsString), [rfReplaceAll]);
  Result := StringReplace(Result, '[TECLA_DELIVERY]', 'D', [rfReplaceAll]);
  Result := StringReplace(Result, '[TECLA_VEMBUSCAR]', 'V', [rfReplaceAll]);
end;

procedure TdmPrincipal.NotificaPedidoWindows(Pedido, Valor: String);
begin
  Tray.BalloonTitle := Pedido;
  Tray.BalloonHint := Valor;
  Tray.ShowBalloonHint;
end;

function TdmPrincipal.ParametrosDadosEmpresa: TFDMemTable;
begin
  Result := dm.DADOS_EMPRESA;
end;

procedure TdmPrincipal.ResetarConversa1Click(Sender: TObject);

Var

  Mensagem: String;
begin
  if memLOG.RecordCount = 0 then
    exit;

  ExecultaSQL('delete from conversa_backup where id_wpp = ' +
    QuotedStr(memLOG.FieldByName('id').AsString));

  Mensagem := '*--- CONVERSA REINICIADA ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
  Mensagem := Mensagem + '*Favor reiniciar seu atendimento!*';
  iWhatsapp.Send(memLOG.FieldByName('id').AsString, Mensagem);

  Gestor.Conversas.Remove(Gestor.BuscarConversa(memLOG.FieldByName('id')
    .AsString));

  memLOG.Delete;

end;

function TdmPrincipal.SerialNum: string;
var
  DriveLetter: string;
  NotUsed: DWORD;
  VolumeFlags: DWORD;
  VolumeInfo: array [0 .. MAX_PATH] of AnsiChar;
  VolumeSerialNumber: DWORD;
begin
  if HD = '' then
  begin
    try
      DriveLetter := GetEnvironmentVariable('SystemDrive');
      GetVolumeInformation(PChar(DriveLetter + '\'), nil, SizeOf(VolumeInfo),
        @VolumeSerialNumber, NotUsed, VolumeFlags, nil, 0);
      Result := IntToHex(VolumeSerialNumber, 8);
    except
      Result := '????????';
    end;
    HD := Result;
  end
  else
  begin
    Result := HD;
  end;
end;

procedure TdmPrincipal.SetHD(const Value: String);
begin
  FHD := Value;
end;

procedure TdmPrincipal.SetRecebendoPedido(const Value: Boolean);
begin
  FRecebendoPedido := Value;
  cRecebendoPedidos.Checked := Value;
end;

procedure TdmPrincipal.tMinimizeTimer(Sender: TObject);
begin

  tMinimize.Enabled := False;
  // WindowState := wsMinimized;
  Tray.BalloonTitle := 'PapaLéguas Food';
  Tray.BalloonHint := 'Sistema Iniciado';
  Tray.ShowBalloonHint;

end;

procedure TdmPrincipal.tNotificaPedidoTimer(Sender: TObject);
var
  EnviarMsg: TEnviaMensagem;
begin
  {
    TThread.CreateAnonymousThread(
    procedure
    begin
    EnviarMsg := TEnviaMensagem.Create;
    EnviarMsg.Enviar;
    TThread.Synchronize(TThread.CurrentThread,
    procedure
    begin
    EnviarMsg.Free;
    ADDLog('Enviando Confirmação!');
    end);
    end).Start; }
end;

procedure TdmPrincipal.TrayClick(Sender: TObject);
begin
  WindowState := wsMaximized;
end;

function TdmPrincipal.ValidaMensagemNova(Conversa: TBotConversa): Boolean;
var
  Tabela: TFDTable;
begin
  Tabela := CriaTabela('conversa_backup', '');
  Result := Tabela.Locate('idmensagem', '', []);
  Tabela.Free;
end;

procedure TdmPrincipal.ValidaMensagensNaoRespondidas;
begin
  CriaQRY('AUX').Close;
  CriaQRY('AUX').SQL.Clear;
  CriaQRY('AUX').SQL.Add
    ('select * from conversa_backup_mensagem where status = 0');
  CriaQRY('AUX').Open;

  while not CriaQRY('AUX').Eof do
  begin
    if CriaTabela('conversa_backup').Locate('idmensagem',
      CriaQRY('AUX').FieldByName('idmensagem').AsString, []) then
    begin
      CriaTabela('conversa_backup').Edit;
      CriaTabela('conversa_backup').FieldByName('idmensagem').Value := 0;
      CriaTabela('conversa_backup').FieldByName('situacao').Value :=
        CriaQRY('AUX').FieldByName('situacao').Value;
      CriaTabela('conversa_backup').FieldByName('etapa').Value := CriaQRY('AUX')
        .FieldByName('etapa').Value;
      CriaTabela('conversa_backup').Post;
    end;
    CriaQRY('AUX').Next;
  end;

  CriaQRY('AUX').Close;
  CriaQRY('AUX').SQL.Clear;
  CriaQRY('AUX').SQL.Add('delete from conversa_backup_mensagem where id > 0');
  CriaQRY('AUX').ExecSQL;
end;

function TdmPrincipal.ValidaNovosPedidos: Boolean;
var
  QryTempo: TFDQuery;
  Campo: String;
begin
  try
    Campo := 'ckbRecebendoPedido';
    QryTempo := dmPrincipal.CriaQRY('TEMPO');
    QryTempo.Close;
    QryTempo.SQL.Clear;
    QryTempo.SQL.Add('SELECT valor FROM dados_componentes where frm = ' +
      QuotedStr('frmPrincipal') + ' and campo = ' + QuotedStr(Campo) +
      ' and id_usuario = 0');
    QryTempo.Open;

    Result := QryTempo.FieldByName('valor').AsString = 'T';
    QryTempo.Free;
  except
    Result := True;
  end;
end;

{ TEnviaWhatsapp }

constructor TEnviaWhatsapp.Create;
begin
  inherited Create(True);
  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := 'http://localhost:2121/';
  Requisicao.TempoExpiracao := 60 * 1000;
end;

procedure TEnviaWhatsapp.Execute;
Var
  Dados: TFDMemTable;
  Celular: String;
  CelularSemNove: String;
  Mensagem: String;
  Tipo: String;
begin
  inherited;

  while not Terminated do
  begin

//    if dm.DADOS_EMPRESA.FieldByName('tipo_wpp_confirmacao').AsInteger = 1 then
//    begin
//      Requisicao.URL := 'v1/util/whatsapp/status';
//      Requisicao.Metodo := mGet;
//      try
//        Requisicao.Execute;
//
//        Dados := TFDMemTable.Create(nil);
//        Dados.LoadFromJSON(Requisicao.Retorno);
//        if Dados.RecordCount > 0 then
//          while not Dados.Eof do
//          begin
//            Dados.Edit;
//            if dmPrincipal.SerialNum = '90FC9F1F' then
//            begin
//              Dados.FieldByName('celular').AsString := '4898111156';
//            end;
//
//            if Dados.FieldByName('wpp_status').IsNull then
//            begin
//              Dados.FieldByName('wpp_status').AsInteger := 0;
//            end;
//
//            Celular := Dados.FieldByName('celular').AsString;
//            CelularSemNove := Celular;
//
//            if length(Celular) = 10 then
//            begin
//              CelularSemNove := Celular;
//              Celular := copy(Celular, 0, 2) + '9' + copy(Celular, 3, 8);
//            end
//            else
//            begin
//              CelularSemNove := copy(Celular, 0, 2) + copy(Celular, 4, 8);
//            end;
//
//            // 48998111156
//
//            Mensagem := 'Olá *' + trim(Dados.FieldByName('nome').AsString) +
//              '*, recebemos o seu pedido código *#' +
//              FormatFloat('000', Dados.FieldByName('codigo_pedido_dia')
//              .AsInteger) + '* no valor de *R$ ' + FormatFloat('#0.00',
//              Dados.FieldByName('valor_total_pedido').AsFloat) + '*.' +
//              MENSAGEM_QUEBRA_LINHA_DUPLA;
//            Mensagem := Mensagem + 'Agradeçemos a preferência e bom apetite.';
//            if Dados.FieldByName('wpp_status').AsInteger <>
//              Dados.FieldByName('status').AsInteger then
//            begin
//              dmPrincipal.iWhatsapp.Send(Celular, Mensagem);
//              dmPrincipal.iWhatsapp.Send(CelularSemNove, Mensagem);
//            end;
//            Requisicao.URL := 'v1/util/whatsapp/status/' +
//              Dados.FieldByName('codigo').AsString;
//            Requisicao.Metodo := mPost;
//            try
//              Requisicao.Execute;
//            except
//
//            end;
//
//            Dados.Next;
//            sleep(500);
//          end;
//      except
//
//      end;
//      Dados.Free;
//    end;
//
//    if dm.DADOS_EMPRESA.FieldByName('tipo_wpp_status').AsInteger = 1 then
//    begin
//      Requisicao.URL := 'v1/util/whatsapp/status/alterado';
//      Requisicao.Metodo := mGet;
//      try
//        Requisicao.Execute;
//
//        Dados := TFDMemTable.Create(nil);
//        Dados.LoadFromJSON(Requisicao.Retorno);
//        if Dados.RecordCount > 0 then
//          while not Dados.Eof do
//          begin
//            Dados.Edit;
//            if dmPrincipal.SerialNum = '90FC9F1F' then
//            begin
//              Dados.FieldByName('celular').AsString := '4898111156';
//            end;
//
//            if Dados.FieldByName('wpp_status').IsNull then
//            begin
//              Dados.FieldByName('wpp_status').AsInteger := 0;
//            end;
//
//            Celular := Dados.FieldByName('celular').AsString;
//            CelularSemNove := Celular;
//
//            if length(Celular) = 10 then
//            begin
//              CelularSemNove := Celular;
//              Celular := copy(Celular, 0, 2) + '9' + copy(Celular, 3, 8);
//            end
//            else
//            begin
//              CelularSemNove := copy(Celular, 0, 2) + copy(Celular, 4, 8);
//            end;
//
//            // 48998111156
//            Celular := '48998111156';
//            CelularSemNove := '4898111156';
//
//            Mensagem := '*' + trim(Dados.FieldByName('nome').AsString) +
//              '* seu pedido Nº *#' + FormatFloat('000',
//              Dados.FieldByName('codigo_pedido_dia').AsInteger) +
//              '* no valor de *R$ ' + FormatFloat('#0.00',
//              Dados.FieldByName('valor_total_pedido').AsFloat) + '*';
//
//            if length(Dados.FieldByName('status_anterior').AsString) = 0 then
//            begin
//              Mensagem := Mensagem + ' teve uma alteração no status para *' +
//                trim(Dados.FieldByName('status_atual').AsString) + '*.';
//            end
//            else
//            begin
//              Mensagem := Mensagem + ' teve uma alteração no status de *' +
//                trim(Dados.FieldByName('status_anterior').AsString) + '* para *'
//                + trim(Dados.FieldByName('status_atual').AsString) + '*.';
//            end;
//
//            Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA_DUPLA +
//              'Agradeçemos a preferência e bom apetite.';
//
//            if Dados.FieldByName('status').AsInteger <> 6 then
//            begin
//              dmPrincipal.iWhatsapp.Send(Celular, Mensagem);
//              dmPrincipal.iWhatsapp.Send(CelularSemNove, Mensagem);
//            end;
//
//            Requisicao.URL := 'v1/util/whatsapp/status/' +
//              Dados.FieldByName('codigo').AsString;
//            Requisicao.Metodo := mPost;
//            try
//              Requisicao.Execute;
//            except
//
//            end;
//
//            Dados.Next;
//            sleep(500);
//          end;
//      except
//
//      end;
//      Dados.Free;
//    end;
//
//    if dm.DADOS_EMPRESA.FieldByName('tipo_wpp_confirmacao').AsInteger = 1 then
//    begin
//      Requisicao.URL := 'v1/util/whatsapp/status';
//      Requisicao.Metodo := mGet;
//      try
//        Requisicao.Execute;
//
//        Dados := TFDMemTable.Create(nil);
//        Dados.LoadFromJSON(Requisicao.Retorno);
//        if Dados.RecordCount > 0 then
//          while not Dados.Eof do
//          begin
//            Dados.Edit;
//
//            if Dados.FieldByName('wpp_status').IsNull then
//            begin
//              Dados.FieldByName('wpp_status').AsInteger := 0;
//            end;
//
//            Celular := Dados.FieldByName('celular').AsString;
//            CelularSemNove := Celular;
//
//            if length(Celular) = 10 then
//            begin
//              CelularSemNove := Celular;
//              Celular := copy(Celular, 0, 2) + '9' + copy(Celular, 3, 8);
//            end
//            else
//            begin
//              CelularSemNove := copy(Celular, 0, 2) + copy(Celular, 4, 8);
//            end;
//
//            // 48998111156
//            Celular := '48998111156';
//            CelularSemNove := '4898111156';
//
//            Mensagem := 'Olá *' + trim(Dados.FieldByName('nome').AsString) +
//              '*, recebemos o seu pedido Nº *#' +
//              FormatFloat('000', Dados.FieldByName('codigo_pedido_dia')
//              .AsInteger) + '* no valor de *R$ ' + FormatFloat('#0.00',
//              Dados.FieldByName('valor_total_pedido').AsFloat) + '*.' +
//              MENSAGEM_QUEBRA_LINHA_DUPLA;
//            Mensagem := Mensagem + 'Agradeçemos a preferência e bom apetite.';
//            if Dados.FieldByName('wpp_status').AsInteger <>
//              Dados.FieldByName('status').AsInteger then
//            begin
//              dmPrincipal.iWhatsapp.Send(Celular, Mensagem);
//              dmPrincipal.iWhatsapp.Send(CelularSemNove, Mensagem);
//            end;
//            Requisicao.URL := 'v1/util/whatsapp/status/' +
//              Dados.FieldByName('codigo').AsString;
//            Requisicao.Metodo := mPost;
//            try
//              Requisicao.Execute;
//            except
//
//            end;
//
//            Dados.Next;
//            sleep(500);
//          end;
//      except
//
//      end;
//      Dados.Free;
//    end;
//
//    if dm.DADOS_EMPRESA.FieldByName('tipo_wpp_pix').AsInteger = 1 then
//    begin
//
//      Requisicao.URL := 'v1/util/whatsapp/pix';
//      Requisicao.Metodo := mGet;
//      try
//        Requisicao.Execute;
//
//        Dados := TFDMemTable.Create(nil);
//        Dados.LoadFromJSON(Requisicao.Retorno);
//        if Dados.RecordCount > 0 then
//          while not Dados.Eof do
//          begin
//            Celular := Dados.FieldByName('celular').AsString;
//            CelularSemNove := Celular;
//
//            if length(Celular) = 10 then
//            begin
//              CelularSemNove := Celular;
//              Celular := copy(Celular, 0, 2) + '9' + copy(Celular, 3, 8);
//            end
//            else
//            begin
//              CelularSemNove := copy(Celular, 0, 2) + copy(Celular, 4, 8);
//            end;
//
//            Celular := '48998111156';
//            CelularSemNove := '4898111156';
//
//            Mensagem := 'Olá *' + trim(Dados.FieldByName('nome').AsString) +
//              '*, recebemos o seu pedido Nº *#' +
//              FormatFloat('000', Dados.FieldByName('codigo_pedido_dia')
//              .AsInteger) + '* no valor de *R$ ' + FormatFloat('#0.00',
//              Dados.FieldByName('valor_total_pedido').AsFloat) + '*.' +
//              MENSAGEM_QUEBRA_LINHA;
//
//            case Dados.FieldByName('tipo_chave_pix').AsInteger of
//              2:
//                begin
//                  Tipo := 'CPF';
//                end;
//              3:
//                begin
//                  Tipo := 'CNPJ';
//                end;
//              4:
//                begin
//                  Tipo := 'Celular';
//                end;
//              5:
//                begin
//                  Tipo := 'E-Mail';
//                end;
//              6:
//                begin
//                  Tipo := 'Aleatoria';
//                end
//            else
//              begin
//                Tipo := '';
//              end;
//
//            end;
//
//            if Tipo <> '' then
//            begin
//              Celular := '55' + Celular + '@c.us';
//
//              Mensagem := Mensagem +
//                'A forma de pagamento escolhida foi o *PIX*, para que possamos confirmar seu pedido nos envie o comprovante de pagamento no formato de *PDF*.'
//                + MENSAGEM_QUEBRA_LINHA_DUPLA;
//              Mensagem := Mensagem + 'Dados para o *PIX*' +
//                MENSAGEM_QUEBRA_LINHA;
//              Mensagem := Mensagem + 'Tipo: ' + Tipo + MENSAGEM_QUEBRA_LINHA;
//              Mensagem := Mensagem + 'Chave: ' + Dados.FieldByName('chave_pix')
//                .AsString + MENSAGEM_QUEBRA_LINHA;
//              Mensagem := Mensagem + Dados.FieldByName('chave_recebedor')
//                .AsString + MENSAGEM_QUEBRA_LINHA_DUPLA;
//              Mensagem := Mensagem + 'Agradeçemos a preferência e bom apetite.';
//              dmPrincipal.iWhatsapp.Send(Celular, Mensagem);
//              dmPrincipal.iWhatsapp.Send(CelularSemNove, Mensagem);
//            end;
//            Requisicao.URL := 'v1/util/whatsapp/pix/' +
//              Dados.FieldByName('codigo').AsString;
//            Requisicao.Metodo := mPost;
//            try
//              Requisicao.Execute;
//            except
//
//            end;
//            Dados.Next;
//            sleep(500);
//          end;
//      except
//
//      end;
//      Dados.Free;
//    end;

    sleep(60 * 1000);
  end;

end;

end.
