unit uClassThreeConversa;

interface

uses System.Classes, FireDAC.Comp.Client, SysUtils, uConversa, uClassPedido,
  uClassEndereco, uDM, uClassFinalizarPedido,
  uAlteracaoCancelamento, uClassPedidoRecente, uClassProduto,
  uClassEnviaMensagem, uClassCronometro, uBotConversa;

type
  TConversaThread = class(TThread)
  private
    FConversa: TBotConversa;
  procedure GestorInteracao(Conversa: TBotConversa);
    procedure SetConversa(const Value: TBotConversa);
  protected
    procedure Execute; override;
  public
  property Conversa : TBotConversa read FConversa write SetConversa;
    constructor Create;
    destructor Destroy; override;


  end;

implementation

{ TCronometro }

uses uPrincipal;

constructor TConversaThread.Create;
begin
  inherited Create(True);
end;

destructor TConversaThread.Destroy;
begin

  inherited;
end;

procedure TConversaThread.Execute;

begin
  inherited;
  while not Terminated do
  begin
    GestorInteracao(Conversa);
    Free;
  end;

end;

procedure TConversaThread.GestorInteracao(Conversa: TBotConversa);
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
begin
  try

//    GeraArquivo(Conversa);
    GeralConversautil := TGeralConversa.Create;
    Conversa := GeralConversautil.EtapaConversa(Conversa);
//    GeraArquivo(Conversa);
    MenuGeral := TMenu.Create;
    EnderecoGeral := TEndereco.Create;
    Finaliza := TFinalizarPedido.Create;
    CancelamentoF := TCancelamento.Create;
    AlteracaoRemover := TAlteracaoRemover.Create;
    VerificaPedido := TPedidoRecente.Create;

    // Grava em Qual Etapa o Cliente Esta
    GeralConversautil.GravaEtapaConversa(Conversa);

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
            dmPrincipal.GeraLOG(Conversa2, 'Validando Usuario');
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
              dmPrincipal.GeraLOG(Conversa, 'Cadastro Cliente');
              GeralConversautil.GravaEtapaConversa(Conversa);
              GestorInteracao(Conversa);

              exit;
            end;
          end;
        end;

      NovoCliente:
        begin
          Conversa2 := GeralConversautil.DadosNovoCliente(Conversa);
          GeralConversautil.GravaEtapaConversa(Conversa2);
        end;
      VerificaUltimoPedido:
        begin
          Conversa2 := VerificaPedido.VerificaPedidoRecente(Conversa);
          GeralConversautil.GravaEtapaConversa(Conversa2);
          Conversa := Conversa2;
          exit;
        end;

      MenuPedido:
        begin
          // MENU
          Conversa2 := MenuGeral.MenuPedido(Conversa);
          GeralConversautil.GravaEtapaConversa(Conversa2);

        end;

      NovoPedido:
        begin

        end;

      AdicionandoProduto:
        ;
      AdicionandoPizza:
        ;
      SelecionandoFormaPedido:
        ;
      FinalizandoPedido:
        begin
          Conversa2 := Finaliza.Finalizando(Conversa);
          GeralConversautil.GravaEtapaConversa(Conversa2);
        end;
      AlteraRemove:
        begin
          Conversa2 := AlteracaoRemover.AlterarRemover(Conversa);
          GeralConversautil.GravaEtapaConversa(Conversa2);
        end;
      Cancelamento:
        begin
          Conversa2 := CancelamentoF.Cancelamento(Conversa);

        end;

      CaschBack:
        ;
      Finalizado:
        begin
          dmPrincipal.GeraLOG(Conversa, 'Finalizado');
          dmPrincipal.LimpaConversaBackup(Conversa);
          if dmPrincipal.memLOG.Locate('id', Conversa.ID, []) then
           dmPrincipal. memLOG.Delete;

          Gestor.Conversas.Remove(Conversa);
          exit;
        end;

      EnderecoCliente:
        begin
          Conversa2 := EnderecoGeral.Endereco(Conversa);
          GeralConversautil.GravaEtapaConversa(Conversa2);
        end;
      AtendimentoHumano:
        begin
          if UpperCase(Conversa.Resposta) = 'VOLTAR' then
          begin
            Conversa.Etapa := 0;
            Conversa.Resposta := '';
            Conversa.Situacao := MenuPedido;
            dmPrincipal.GravaConversa(Conversa);
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
        //
        if (pos('ACCESS', UpperCase(E.Message)) > 0) or
          (pos('IS NOT A VALID INTEGER', UpperCase(E.Message)) > 0) or
          (pos('INVALID POINTER OPERATIONEINVALIDPOINTER', UpperCase(E.Message)
          ) > 0) then
        begin
          // Remover a conversa
          Conversa.Situacao := Finalizado;
          // Enviamensagem(0, '*ACONTECEU UM ERRO INESPERADO*' +
          // MENSAGEM_QUEBRA_LINHA_DUPLA +
          // '*Mande outra mensagem para reiniciar seu pedido, ou basta ignorar essa mensagem.*',
          // Conversa);
          dmPrincipal.GravaConversa(Conversa);

          GestorInteracao(Conversa);
          exit;
        end;
        // Access violation at address
        // se der access deve remover a conversa :3
        // GravaErroConversa(E, Conversa);
        // Erro := '*Nome:* ' + ConfDelivery.Nome + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Data/Hora:* ' + FormatDateTime('dd/mm/yyyy hh:mm', now)
          + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Cliente:* ' + Conversa.Nome + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Celular:* ' + Conversa.Telefone +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Etapa:* ' + IntToStr(Conversa.Etapa) +
          MENSAGEM_QUEBRA_LINHA;
        // Erro := Erro + '*Situação:* ' + SituacaoConversa(Conversa.Situacao) +
        // MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Pergunta:* ' + Conversa.Pergunta +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Resposta:* ' + Conversa.Resposta +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Erro:* ' + E.Message + #13 + E.ClassName;
        dmPrincipal.iWhatsapp.Send('554898111156@c.us', Erro);
        Erro := Conversa.Pergunta;
        if Conversa.Resposta = '' then
          Erro := '';
        dmPrincipal.iWhatsapp.Send(Conversa.ID, Erro);
        exit;
      end;
    end;
  end;
end;

procedure TConversaThread.SetConversa(const Value: TBotConversa);
begin
  FConversa := Value;
end;

end.
