unit uBotGestor;


interface

uses
  System.Classes, Vcl.ExtCtrls, System.Generics.Collections,
  uBotConversa,
  uTInject,
  uTInject.Classes, FireDAC.Comp.Client, DateUtils, uDM, uGravaConversaMemoria;

type
  TBotManager = class(TComponent)
  private
    FSenhaADM: String;
    FSimutaneios: Integer;
    FTempoInatividade: Integer;
    FConversas: TObjectList<TBotConversa>;
    FIDJaRecebidos: Array of Extended;

    FOnInteracao: TNotifyConversa;
    FConversasMemoria: TGravaConversaMemoria;

    function MotoBoy(Telefone: String): TTipoUsuario;

    function RemoveAcento(aText: string): string;
    procedure SetConversasMemoria(const Value: TGravaConversaMemoria);
    procedure AdicionaID(Valor: Extended);
    function LocalizaID(Valor: Extended): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SoLetra(fField: String): String;

    procedure AdministrarChatList(AInject: TInject; AChats: TChatList);
    procedure ProcessarResposta(AMessagem: TMessagesClass);

    function BuscarConversa(AID: String): TBotConversa;
    function NovaConversa(AMessage: TMessagesClass): TBotConversa;
    function BuscarConversaEmEspera: TBotConversa;
    function AtenderProximoEmEspera: TBotConversa;

    property SenhaADM: String read FSenhaADM write FSenhaADM;
    property Simutaneios: Integer read FSimutaneios write FSimutaneios
      default 1;
    property Conversas: TObjectList<TBotConversa> read FConversas;
    property TempoInatividade: Integer read FTempoInatividade
      write FTempoInatividade;

    // Procedures notificadoras
    procedure ProcessarInteracao(Conversa: TBotConversa);
    procedure ConversaSituacaoAlterada(Conversa: TBotConversa);

    // Notify
    property OnInteracao: TNotifyConversa read FOnInteracao write FOnInteracao;

    function SituacaoCodigo(Codigo: Integer): TSituacaoConversa;
    function TipoEntregaCodigo(Codigo: Integer): TTipoEntrega;

    // Tratamento
    function ValidaMensagem(IdMensagem: Real): Boolean;

    property ConversasMemoria: TGravaConversaMemoria read FConversasMemoria
      write SetConversasMemoria;
  end;

implementation

uses
  System.StrUtils, System.SysUtils, uPrincipal, uConversa;

{ TBotManager }

constructor TBotManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConversas := TObjectList<TBotConversa>.Create;
  FConversasMemoria := TGravaConversaMemoria.Create;

end;

destructor TBotManager.Destroy;
begin
  FreeAndNil(FConversas);

  inherited Destroy;
end;

function TBotManager.LocalizaID(Valor: Extended): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to length(FIDJaRecebidos) - 1 do
  begin
    if FIDJaRecebidos[I] = Valor then
    begin
      Result := True;
      exit;
    end;

  end;
end;

function TBotManager.MotoBoy(Telefone: String): TTipoUsuario;
var
  Campo: String;
  CodigoMotoBoy: Integer;
begin
  Telefone := StringReplace(Telefone, '55', '', [rfReplaceAll]);
  if length(Telefone) > 11 then
    Campo := 'celular'
  else
    Campo := 'celular_wpp';

  // dmModulo.qryAux.Close;
  // dmModulo.qryAux.SQL.Clear;
  // dmModulo.qryAux.SQL.Add('select * from motoboy where ' + Campo + ' = ' +
  // QuotedStr(Telefone) + ' and ativo = 1');
  // dmModulo.qryAux.Open;
  // CodigoMotoBoy := dmModulo.qryAux.FieldByName('codigo').AsInteger;
  //
  // dmModulo.qryAux.Close;
  // dmModulo.qryAux.SQL.Clear;
  // dmModulo.qryAux.SQL.Add('select * from pedido_motoboy where codigo_motoboy = '
  // + IntToStr(CodigoMotoBoy) + ' and status not in (0,6)');
  // dmModulo.qryAux.Open;
  // dmModulo.qryAux.SQL.Text;
  // if dmModulo.qryAux.RecordCount > 0 then
  // Result := tpMotoboy
  // else
  // Result := tpCliente;
  // if dmModulo.qryAux.RecordCount > 0 then
  // Result := tpMotoboy;
end;

procedure TBotManager.AdicionaID(Valor: Extended);
begin
  // length()
  SetLength(FIDJaRecebidos, length(FIDJaRecebidos) + 1);
  FIDJaRecebidos[length(FIDJaRecebidos) - 1] := Valor;
end;

procedure TBotManager.AdministrarChatList(AInject: TInject; AChats: TChatList);
var
  AChat: TChatClass;
  AMessage: TMessagesClass;
begin
  // Loop em todos os chats
  for AChat in AChats.Result do
  begin
    // N„o considerar chats de grupos
    if not AChat.isGroup then
    begin
      // Define que a mensagem ja foi lida,
      // para evitar recarrega-la novamente.
      // AInject.ReadMessages(AChat.id);

      // Pode haver mais de uma mensagem, pego a ultima
      AMessage := AChat.messages[High(AChat.messages)];

      AMessage.ID := AMessage.ID;

      // N„o considerar mensagens enviadas por mim
      if not AMessage.sender.isMe then
      begin
        // Carregar Conversa e passar a mensagem
        ProcessarResposta(AMessage);
      end;
    end;
  end;
end;

procedure TBotManager.ProcessarResposta(AMessagem: TMessagesClass);
var
  AConversa: TBotConversa;
  Sair: Boolean;
  MyID: Boolean;
  GeralConversautil: TGeralConversa;
begin
  AConversa := BuscarConversa(AMessagem.sender.ID);
  if not Assigned(AConversa) then
  begin
    AConversa := NovaConversa(AMessagem);
  end;

  if (AMessagem.&type = 'chat') or (AMessagem.&type = 'button_response') then
    Sair := True;

  if not Sair then
    Sair := AMessagem.&type = 'location';

  try
    GeralConversautil := TGeralConversa.Create;
    AConversa := GeralConversautil.EtapaConversa(AConversa);
    AConversa := GeralConversautil.DadosDoCliente(AConversa);
    GeralConversautil.free;
  except
    GeralConversautil.free;
  end;

  // Tratando a situaÁ„o em que vem a mesma mensagem.
  MyID := LocalizaID(AMessagem.t);
  if (not MyID) and (Sair) then
  begin
    AdicionaID(AMessagem.t);
    AConversa.IdMensagem := AMessagem.t;

    AConversa.Resposta := AMessagem.body;

    // Houve interacao, reinicia o timer de inatividade da conversa;
    AConversa.ReiniciarTimer;
    // Tratando a situacao em que vem a localizacao.
    if (AMessagem.lat <> 0) and (AMessagem.lng <> 0) then
    begin
      AConversa.lat := AMessagem.lat;
      AConversa.lng := AMessagem.lng;
      AConversa.Resposta := '';
    end;

//    AConversa.ValorBotao := trim(AMessagem.selectedButtonId);

    if AConversa.ValorBotao = '' then
    begin
      AConversa.ValorBotao := AMessagem.body;
    end;

    // try
    // dmPrincipal.GravaConversa(AConversa);
    // except
    //
    // end;
    // Notifica mensagem recebida
    ProcessarInteracao(AConversa);
  end;
  // GeralConversautil.free;
end;

function TBotManager.RemoveAcento(aText: string): string;
const
  ComAcento = '‡‚ÍÙ˚„ı·ÈÌÛ˙Á¸Ò˝¿¬ ‘€√’¡…Õ”⁄«‹—›';
  SemAcento = 'aaeouaoaeioucunyAAEOUAOAEIOUCUNY';
var
  x: Cardinal;
begin;
  for x := 1 to length(aText) do
    try
      if (Pos(aText[x], ComAcento) <> 0) then
        aText[x] := SemAcento[Pos(aText[x], ComAcento)];
    except
      on E: Exception do
        raise Exception.Create('Erro no processo.');
    end;

  Result := aText;
end;

procedure TBotManager.SetConversasMemoria(const Value: TGravaConversaMemoria);
begin
  FConversasMemoria := Value;
end;

function TBotManager.SituacaoCodigo(Codigo: Integer): TSituacaoConversa;
begin
  {
    case Codigo of
    1:
    Result := saIndefinido;
    2:
    Result := saNova;
    3:
    Result := saEmAtendimento;
    4:
    Result := saEmEspera;
    5:
    Result := saInativa;
    6:
    Result := saCadastroCliente;
    7:
    Result := saFazendoPedido;
    8:
    Result := saFinalizandoPedido;
    9:
    Result := saAtendente;
    10:
    Result := saCashback;
    11:
    Result := saFinalizada;
    12:
    Result := saFinalizaPedido;
    end; }

end;

function TBotManager.SoLetra(fField: String): String;
var
  I: Byte;
begin
  fField := RemoveAcento(fField);

  fField := UpperCase(fField);
  Result := '';
  for I := 1 To length(fField) do
    if fField[I] = ' ' then
    begin
      Result := Result + fField[I];
    end
    else if fField[I] In ['A' .. 'Z'] Then
      Result := Result + fField[I];
end;

function TBotManager.TipoEntregaCodigo(Codigo: Integer): TTipoEntrega;
begin
  case Codigo of
    1:
      Result := VemBuscar;
    2:
      Result := Delivery;
  end;
end;

function TBotManager.ValidaMensagem(IdMensagem: Real): Boolean;
begin
  try
    dmPrincipal.CriaQRY('CON').Close;
    dmPrincipal.CriaQRY('CON').Sql.Clear;
    dmPrincipal.CriaQRY('CON')
      .Sql.Add('select * from conversa_backup where idmensagem = :idmensagem');
    dmPrincipal.CriaQRY('CON').ParamByName('idmensagem').Value := IdMensagem;
    dmPrincipal.CriaQRY('CON').Open;

    Result := dmPrincipal.CriaQRY('CON').RecordCount > 0;
  except

  end;
end;

function TBotManager.BuscarConversa(AID: String): TBotConversa;
var
  AConversa: TBotConversa;
  GeralConversautil: TGeralConversa;
begin

  Result := nil;
  for AConversa in FConversas do
  begin
    if AConversa.ID = AID then
    begin
      Result := AConversa;
      try
        GeralConversautil := TGeralConversa.Create;

        Result := GeralConversautil.EtapaConversa(Result);
        Result := GeralConversautil.DadosDoCliente(Result);
        GeralConversautil.free;
      except

      end;
      Break;
    end;
  end;

end;

function TBotManager.NovaConversa(AMessage: TMessagesClass): TBotConversa;
var
  ADisponivel: Boolean;
  CodigoCliente: Integer;
  PedidoRecente: Boolean;

  GeralConversautil: TGeralConversa;
begin
  // inc(ConfDelivery.TotalAtendimentoAtual);
  ADisponivel := (Conversas.Count < Simutaneios);
  //
  Result := TBotConversa.Create(Self);
  with Result do
  begin
    TipoUsuario := cliente;
    // TipoUsuario := tpAdm;
    TempoInatividade := Self.TempoInatividade;
    ID := AMessage.sender.ID;
    Telefone := Copy(AMessage.sender.ID, 1, Pos('@', AMessage.sender.ID) - 1);
    TipoUsuario := MotoBoy(Telefone);
    // Telefone := StringReplace(Telefone, '55', '', [rfReplaceAll]);
    Telefone := Copy(Telefone, 3, 10);

    // Capturar nome publico, ou formatado (numero/nome).
    Nome := IfThen(AMessage.sender.PushName <> EmptyStr,
      AMessage.sender.PushName, AMessage.sender.FormattedName);

    if AMessage.sender.PushName = '' then
      Nome := AMessage.sender.verifiedName;

    Nome := SoLetra(Nome);
    //
    OnSituacaoAlterada := ConversaSituacaoAlterada;
    OnRespostaRecebida := ProcessarInteracao;
  end;
  if PedidoRecente then
  begin
    exit;
  end;

  FConversas.Add(Result);

  // se existir um cadastro de cliente pegar as latitudes


  // Verifica se tem pedido aberto

end;

function TBotManager.BuscarConversaEmEspera: TBotConversa;
var
  AConversa: TBotConversa;
begin
  Result := nil;
  for AConversa in FConversas do
  begin
    if AConversa.Situacao = Aguardando then
    begin
      Result := AConversa;
      Break;
    end;
  end;
end;

function TBotManager.AtenderProximoEmEspera: TBotConversa;
var
  AConversa: TBotConversa;
begin
  Result := BuscarConversaEmEspera;

  if Assigned(Result) then
  begin
    Result.Situacao := NovoCLiente;
    Result.ReiniciarTimer;
    ProcessarInteracao(Result);
  end;
end;

procedure TBotManager.ProcessarInteracao(Conversa: TBotConversa);
begin
  // if Assigned(OnInteracao) then
  OnInteracao(Conversa);
end;

procedure TBotManager.ConversaSituacaoAlterada(Conversa: TBotConversa);
begin
  // Se ficou inativo
  if Conversa.Situacao in [Finalizado] then
  begin
    // Encaminha
    // OnInteracao(Conversa);
    //
    // // frmPrincipal.InativaDados(Conversa.Telefone);
    // // Destroy
    // frmPrincipal.Inject1.ReadMessages(Conversa.id);
    //
    // if dmModulo.tabela_conversa_backup.Locate('id_wpp', Conversa.id, []) then
    // begin
    // dmModulo.tabela_conversa_backup.delete;
    // end;
    //
    // ConfDelivery.TotalAtendimentoAtual :=
    // ConfDelivery.TotalAtendimentoAtual - 1;
    // Conversas.Remove(Conversa);
    // // Atende proximo da fila
    // AtenderProximoEmEspera;
  end;
end;

end.

