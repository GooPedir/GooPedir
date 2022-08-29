unit uClassFinalizarPedido;

interface

uses uBotConversa, FireDAC.Comp.Client, uPrincipal, System.SysUtils, Variants,
  uClassProduto;

type
  TFinalizarPedido = class
    function MontaMenu(Conversa: TBotConversa): String;
    function MontaMenuTipoPagamento(Conversa: TBotConversa): String;

    function GeraCodigoPorDiaPedido: Integer;

    function MensagemFinalizacao(Conversa: TBotConversa;
      CodigoPedido: Integer): String;

    function Tempo: Boolean;
    function TempoMensagem(Tipo: Integer): String;
  public

    function Finalizando(Conversa: TBotConversa): TBotConversa;

    function ProdutosResumo(Codigo: Integer; Conversa: TBotConversa): String;

  end;

implementation

{ TFinalizarPedido }

uses uClassPedido, uDM, uAlteracaoCancelamento, uRequisicao;

function TFinalizarPedido.Finalizando(Conversa: TBotConversa): TBotConversa;
var
  Mensagem: String;
  I: Integer;
  Tabela: TFDTable;
  TabelaImprimir: TFDTable;
begin
  case Conversa.Etapa of
    0:
      begin
        Tabela := dmPrincipal.CriaTabela('pedido');
        if Tabela.Locate
          ('codigo_cliente;codigo_cliente_endereco;data_pedido;status;pedido_impresso;origem',
          VarArrayOf([IntToStr(Conversa.CodigoClienteInterno),
          IntToStr(Conversa.CodigoEndereco), DateToStr(date), '-1', '1', '1']
          ), []) then
        begin

          if not(Tabela.FieldByName('valor_total_pedido').AsFloat >
            dm.DADOS_EMPRESA.FieldByName('pedido_minimo').AsFloat - 0.01) then
          begin
            Mensagem := '*--- PEDIDO MÍNIMO ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
            Mensagem := Mensagem + MONO_ESPACADA + 'Seu pedido no valor de ' +
              FormatFloat('R$ #0.00', Tabela.FieldByName('valor_total_pedido')
              .AsFloat) + ' não é superior ao pedido mínimo no valor de ' +
              FormatFloat('R$ #0.00',
              dm.DADOS_EMPRESA.FieldByName('pedido_minimo').AsFloat) + '!' +
              MONO_ESPACADA;
            dmPrincipal.Enviamensagem(Conversa, Mensagem);

            Conversa.Etapa := 2;
            Conversa.Situacao := MenuPedido;
            Conversa.Resposta := '';
            dmPrincipal.GravaConversa(Conversa);
            dmPrincipal.GestorInteracao(Conversa);
            exit;
          end;

        end;

        dmPrincipal.GeraLOG(Conversa, 'Valida as informações e monta o MENU');
        // Valida as informações e monta o MENU
        Mensagem := MontaMenu(Conversa);

        if Mensagem = '' then
        begin
          Conversa.Situacao := MenuPedido;
          Conversa.Etapa := 2;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end;
        Conversa.Etapa := 1;
        // Caso venha vazio, retornar ao menu de pedido
        Result := dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        sleep(2000);

        if Usar_Novo_Botao then
        begin
          dmPrincipal.EnviaBotao(Conversa, MontaMenuTipoPagamento(Conversa),
            'informe o código do tipo do pagamento ou escolha a opção abaixo!',
            ['MENU', 'CANCELAR', 'ALTERAR'], ['M', 'C', 'A']);
        end
        else
        begin
          Result := dmPrincipal.Enviamensagem(Conversa.Etapa,
            MontaMenuTipoPagamento(Conversa), Conversa);
        end;

      end;
    1:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Valida as informações e monta o MENU');
        Tabela := dmPrincipal.CriaTabela('pedido');

        if Tabela.Locate
          ('codigo_cliente;codigo_cliente_endereco;data_pedido;status;pedido_impresso;origem',
          VarArrayOf([IntToStr(Conversa.CodigoClienteInterno),
          IntToStr(Conversa.CodigoEndereco), DateToStr(date), '-1', '1', '1']
          ), []) then
        begin

        end
        else
        begin
          // Se não localizar enviar mesam mensagem ou verificar se foi finalizado!
        end;

        { Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*M* Para voltar ao *MENU* de pedidos' +
          MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*C* Para *CANCELAR* o pedido' + MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*A* Para  *ALTERAR/REMOVER*';
        }
        if Trim(UpperCase(Conversa.Resposta)) = 'M' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Volta para o MENU');
          Conversa.Situacao := MenuPedido;
          Conversa.Etapa := 2;
          Conversa.Resposta := '';
          Tabela.Free;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);

          exit;
        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'C' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Cancela o Pedido');
          Conversa.CodigoPedido := Tabela.FieldByName('codigo').AsInteger;
          Conversa.Situacao := Cancelamento;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          Tabela.Free;
          exit;
        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'A' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Altera o Pedido');
          Conversa.Situacao := AlteraRemove;
          Conversa.Etapa := 0;
          Conversa.Resposta := '';

          Tabela.Free;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);

          exit;
        end;

        // Validar aki o tipo de pagamento
        dmPrincipal.CriaQRY('AUX01').Close;
        dmPrincipal.CriaQRY('AUX01').SQL.Clear;
        dmPrincipal.CriaQRY('AUX01')
          .SQL.Add('SELECT * FROM tipo_pagamento where ativo = 1 and apenas_delivery = 1');
        dmPrincipal.CriaQRY('AUX01').Open;
        try
          if StrToInt(Conversa.Resposta) > dmPrincipal.CriaQRY('AUX01').RecordCount
          then
          begin
            Result := dmPrincipal.Enviamensagem(Conversa.Etapa,
              Conversa.Pergunta, Conversa);
            Tabela.Free;
            exit;
          end;
        except
          Result := dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          Tabela.Free;
          exit;
        end;

        I := 0;
        while not dmPrincipal.CriaQRY('AUX01').Eof do
        begin
          inc(I);
          if I = StrToInt(Conversa.Resposta) then
          begin
            Tabela.Edit;
            Tabela.FieldByName('codigo_pedido_dia').AsInteger :=
              GeraCodigoPorDiaPedido;
            Tabela.FieldByName('tipo_pagamento').AsInteger :=
              dmPrincipal.CriaQRY('AUX01').FieldByName('codigo').AsInteger;
            Tabela.FieldByName('status').AsInteger := 1;
            Tabela.FieldByName('pedido_impresso').AsInteger := 1;
            Tabela.FieldByName('hora_pedido').AsDateTime := time;
            Tabela.Post;
            // Enviar a confirmação pro cliente!
            Conversa.Situacao := Finalizado;
            Conversa.Etapa := 1;
            Result := dmPrincipal.Enviamensagem(Conversa.Etapa,
              MensagemFinalizacao(Conversa, Tabela.FieldByName('codigo')
              .AsInteger), Conversa);

            dmPrincipal.RequisicaoLocal.URL := '/v1/util/impressao/pedido/produtos/' +Tabela.FieldByName('codigo').asString;
            dmPrincipal.RequisicaoLocal.Metodo := mPost;
            try
              dmPrincipal.RequisicaoLocal.Execute;
            except

            end;

            dmPrincipal.ExecultaSQL
              ('update pedido set codigo_cliente = 0 where codigo_cliente = ' +
              IntToStr(Conversa.CodigoClienteInterno) + ' and status -1');
            dmPrincipal.GestorInteracao(Conversa);
            exit;
          end;

          dmPrincipal.CriaQRY('AUX01').Next;
        end;

        // Imprimir

        TabelaImprimir := dmPrincipal.CriaTabela('impressao_pedido');
        TabelaImprimir.Insert;
        TabelaImprimir.FieldByName('id').AsInteger :=
          dmPrincipal.GerarID('impressao_pedido', 'id');
        TabelaImprimir.FieldByName('data_solicitacao').AsDateTime := date;
        TabelaImprimir.FieldByName('hora_solicitacao').AsDateTime := time;
        TabelaImprimir.FieldByName('id_pedido').AsInteger :=
          Tabela.FieldByName('codigo').AsInteger;
        TabelaImprimir.FieldByName('status').AsInteger := 0;
        TabelaImprimir.Post;

        TabelaImprimir.Free;

        try
          Tabela.Free;
        except

        end;

        Result := dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
          Conversa);
        exit;

      end;
  end;
end;

function TFinalizarPedido.GeraCodigoPorDiaPedido: Integer;
var
  QRY: TFDQuery;
  Data: TDate;
begin
  QRY := dmPrincipal.CriaQRY('AUX03');
  if time > StrToTime('04:59:59') then
  begin

    QRY.Close;
    QRY.SQL.Clear;
    QRY.SQL.Add
      ('SELECT max(codigo_pedido_dia) as maior FROM pedido where status > -1 and data_pedido ='
      + QuotedStr(FormatDateTime('yyyy-mm-dd', date)) + ' and hora_pedido > ' +
      QuotedStr('05:00:00'));
    QRY.Open;

    Result := QRY.FieldByName('maior').AsInteger + 1;

  end
  else
  begin

    QRY.Close;
    QRY.SQL.Clear;
    QRY.SQL.Add
      ('SELECT max(codigo_pedido_dia) as maior FROM pedido where status > -1 and data_pedido ='
      + QuotedStr(FormatDateTime('yyyy-mm-dd', date)) + ' and hora_pedido > ' +
      QuotedStr('00:00:00'));
    QRY.Open;

    if QRY.RecordCount > 0 then
      Result := QRY.FieldByName('maior').AsInteger + 1;

    if Result > 1 then
    begin
      QRY.Free;
      exit;
    end;
    QRY.Close;
    QRY.SQL.Clear;
    QRY.SQL.Add
      ('SELECT max(codigo_pedido_dia) as maior FROM pedido where status > 0 and data_pedido ='
      + QuotedStr(FormatDateTime('yyyy-mm-dd', date - 1)) +
      ' and hora_pedido > ' + QuotedStr('05:00:00'));
    QRY.Open;

    Result := QRY.FieldByName('maior').AsInteger + 1 + Result;

  end;

  if QRY.RecordCount = 0 then
    Result := 1;

  QRY.Free;

end;

function TFinalizarPedido.MensagemFinalizacao(Conversa: TBotConversa;
  CodigoPedido: Integer): String;
var
  Mensagem: String;
  Tabela: TFDTable;
  TabelaProdutos: TFDTable;

  TabelaImpressao: TFDTable;
begin
  Tabela := dmPrincipal.CriaTabela('pedido');
  TabelaImpressao := dmPrincipal.CriaTabela('impressao_pedido');

  if Assigned(TabelaImpressao) then
  begin
    TabelaImpressao.Insert;
    TabelaImpressao.FieldByName('id').AsInteger :=
      dmPrincipal.GerarID('impressao_pedido', 'id');
    TabelaImpressao.FieldByName('data_solicitacao').AsDateTime := date;
    TabelaImpressao.FieldByName('hora_solicitacao').AsDateTime := time;
    TabelaImpressao.FieldByName('status').AsInteger := 0;
    TabelaImpressao.FieldByName('vias').AsInteger := 0;
    TabelaImpressao.FieldByName('id_pedido').AsInteger := CodigoPedido;
    TabelaImpressao.Post;

    TabelaImpressao.Free;
  end;

  dmPrincipal.CriaQRY('UPDPED').Close;
  dmPrincipal.CriaQRY('UPDPED').SQL.Clear;
  dmPrincipal.CriaQRY('UPDPED')
    .SQL.Add('update pedido_produtos set codigo_pedido = 0 where codigo_pedido = '
    + IntToStr(CodigoPedido) + ' and quantidade = 0');
  dmPrincipal.CriaQRY('UPDPED').ExecSQL;

  Tabela.Locate('codigo', IntToStr(CodigoPedido), []);
  Tabela.Edit;
  Tabela.FieldByName('valor_total_pedido').AsFloat :=
    Tabela.FieldByName('valor_pedido').AsFloat +
    Tabela.FieldByName('valor_taxa_entrega').AsFloat;
  Tabela.Post;

  dmPrincipal.NotificaPedidoWindows('Pedido ' + FormatFloat('000000',
    Tabela.FieldByName('codigo_pedido_dia').AsInteger),
    'R$: ' + FormatFloat('#.00', Tabela.FieldByName('valor_total_pedido')
    .AsFloat));

  Mensagem := '*--- PEDIDO CONCLUIDO COM SUCESSO ---*' +
    MENSAGEM_QUEBRA_LINHA_DUPLA;

  Mensagem := Mensagem + '*PEDIDO*' + MENSAGEM_QUEBRA_LINHA;
  Mensagem := Mensagem + FormatFloat('000000',
    Tabela.FieldByName('codigo_pedido_dia').AsFloat) + MENSAGEM_QUEBRA_LINHA;
  Mensagem := Mensagem + '*DATA/HORA*' + MENSAGEM_QUEBRA_LINHA;
  Mensagem := Mensagem + Tabela.FieldByName('data_pedido').AsString + ' ' +
    Tabela.FieldByName('hora_pedido').AsString + MENSAGEM_QUEBRA_LINHA_DUPLA;

  Mensagem := Mensagem + TempoMensagem
    (Tabela.FieldByName('codigo_cliente_endereco').AsInteger);

  Mensagem := Mensagem +
    '```Mensagem automática, não é necessário responder, desde já agradeçemos a sua preferência.```';
  Result := Mensagem;
  Tabela.Free;
end;

function TFinalizarPedido.MontaMenu(Conversa: TBotConversa): String;
var
  QryItens: TFDQuery;
  QryItensDetail: TFDQuery;
  TabelaPedido: TFDTable;

  Mensagem: String;

  Produto: TProduto;
  Cancelado: String;

  Menu: TMenu;
  Produtos: String;
begin
  Produtos := ProdutosResumo(Menu.VerificaPedidoAtual(Conversa), Conversa);
  if Produtos = '' then
  begin
    Result := '';
    exit;
  end;

  Mensagem := '*--- RESUMO DO PEDIDO ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
  Mensagem := Mensagem + '*QTD - DESCRICAO*' + MENSAGEM_QUEBRA_LINHA;
  Mensagem := Mensagem + Produtos;

  Result := Mensagem;

end;

function TFinalizarPedido.MontaMenuTipoPagamento
  (Conversa: TBotConversa): String;
var
  Mensagem: String;

  QRYPagamento: TFDQuery;
  ID: Integer;
begin
  QRYPagamento := dmPrincipal.CriaQRY('AUX03');

  Mensagem := '*--- FINALIZAÇÃO DO PEDIDO ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;

  Mensagem := Mensagem + '*PAGAMENTO*' + MENSAGEM_QUEBRA_LINHA_DUPLA;

  QRYPagamento.Close;
  QRYPagamento.SQL.Clear;
  QRYPagamento.SQL.Add
    ('SELECT * FROM tipo_pagamento where ativo = 1 and apenas_delivery = 1');
  QRYPagamento.Open;
  ID := 0;
  while not QRYPagamento.Eof do
  begin
    inc(ID);
    Mensagem := Mensagem + '*' + IntToStr(ID) + '* - ' +
      QRYPagamento.FieldByName('descricao').AsString + MENSAGEM_QUEBRA_LINHA;

    QRYPagamento.Next;
  end;
  QRYPagamento.Free;
  if not Usar_Novo_Botao then
  begin
    Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;
    Mensagem := Mensagem + '*M* - Para voltar ao *MENU*' +
      MENSAGEM_QUEBRA_LINHA;
    Mensagem := Mensagem + '*C* - Para *CANCELAR*' + MENSAGEM_QUEBRA_LINHA;
    Mensagem := Mensagem + '*A* - Para *ALTERAR/REMOVER*';
  end;

  Result := Mensagem;

end;

function TFinalizarPedido.ProdutosResumo(Codigo: Integer;
  Conversa: TBotConversa): String;
var
  QryItens: TFDQuery;
  QryItensDetail: TFDQuery;
  TabelaPedido: TFDTable;

  Produto: TProduto;
  Cancelado: String;
  Total: Real;
  Alteracao: TAlteracaoRemover;
  Recalcular: Boolean;

  ValorProduto: Real;
  ValorTotal: Real;

  ValorAux: Real;
  IDAux: Integer;

begin

  Total := 0;
  ValorTotal := 0;
  QryItens := dmPrincipal.CriaQRY('AUX01');
  QryItensDetail := dmPrincipal.CriaQRY('AUX02');

  TabelaPedido := dmPrincipal.CriaTabela('pedido');

  if TabelaPedido.Locate('codigo', IntToStr(Codigo), []) then
  begin
    dm.CriaQRY('LOCALCLI').Close;
    dm.CriaQRY('LOCALCLI').SQL.Clear;
    dm.CriaQRY('LOCALCLI').SQL.Add('select * from cliente where codigo = ' +
      TabelaPedido.FieldByName('codigo_cliente').AsString);
    dm.CriaQRY('LOCALCLI').Open;
    Recalcular := TabelaPedido.FieldByName('status').AsInteger > 0;
    if TabelaPedido.FieldByName('origem').AsInteger = 2 then
      Recalcular := False;
  end
  else
  begin
    TabelaPedido.Free;
    QryItens.Free;
    QryItensDetail.Free;
    Result := '';
    exit;
  end;

  QryItens.Close;
  QryItens.SQL.Clear;
  QryItens.SQL.Add('select * from pedido_produtos where codigo_pedido = ' +
    IntToStr(Codigo));
  QryItens.Open;

  while not QryItens.Eof do
  begin
    ValorProduto := 0;
    Produto := Produto.LocalizaProduto(QryItens.FieldByName('codigo_produto')
      .AsInteger, Conversa);

    Cancelado := '';
    if QryItens.FieldByName('quantidade').AsInteger = 0 then
    begin
      Cancelado := '~';
    end;
    ValorProduto := 0;
    if Produto.Tipo <> Pizza then
      ValorProduto := Produto.Valor * QryItens.FieldByName('quantidade')
        .AsInteger;

    if QryItens.FieldByName('valor_total').AsInteger = 0 then
    begin
      Cancelado := '~';
    end;
    if not Produto.Ativo then
    begin
      if not Recalcular then
      begin
        Alteracao := TAlteracaoRemover.Create;
        Alteracao.RemoveProduto(QryItens.FieldByName('codigo').AsInteger);
        Alteracao.Free;
        Cancelado := '~';
      end;

    end;

    Result := Result + '*' + Cancelado + FormatFloat('000 - ',
      QryItens.FieldByName('quantidade').AsInteger) + Trim(Produto.Nome) +
      Cancelado + '*' + MENSAGEM_QUEBRA_LINHA;

    QryItensDetail.Close;
    QryItensDetail.SQL.Clear;
    QryItensDetail.SQL.Add
      ('SELECT * FROM pedido_produto_sap where codigo_pedido_produto = ' +
      QryItens.FieldByName('codigo').AsString);
    QryItensDetail.Open;

    ValorAux := 0;
    IDAux := 0;

    while not QryItensDetail.Eof do
    begin

      if QryItensDetail.FieldByName('nomeclatura').AsString <> '' then
      begin
        Result := Result + '         *_' + Cancelado + '- ' +
          QryItensDetail.FieldByName('nomeclatura').AsString + ' ' +
          Trim(QryItensDetail.FieldByName('descricao').AsString) +
          Cancelado + '_*';
        if QryItensDetail.FieldByName('valor').AsFloat > 0 then
          Result := Result + ' *_' + Cancelado + 'R$: ' +
            FormatFloat('#0.00', QryItensDetail.FieldByName('valor').AsFloat) +
            Cancelado + '_*';

        case QryItensDetail.FieldByName('tipo_valor').AsInteger of
          0:
            begin
              ValorProduto := ValorProduto + QryItensDetail.FieldByName
                ('valor').AsFloat;
            end;
          1:
            begin
              // Media
              ValorAux := ValorAux + QryItensDetail.FieldByName
                ('valor').AsFloat;
              inc(IDAux);
            end;
          2:
            begin
              // Maior
              if QryItensDetail.FieldByName('valor').AsFloat > ValorAux then
                ValorAux := QryItensDetail.FieldByName('valor').AsFloat;
            end;
          3:
            begin
              // Soma
              ValorProduto := ValorProduto + QryItensDetail.FieldByName
                ('valor').AsFloat;
            end
        else
          begin
            ValorProduto := ValorProduto + QryItensDetail.FieldByName
              ('valor').AsFloat;
          end;

        end;

        Result := Result + MENSAGEM_QUEBRA_LINHA;
      end;

      QryItensDetail.Next;
    end;
    if ValorAux > 0 then
    begin
      ValorAux := ValorAux / IDAux;

      if ValorAux > 0 then
      begin
        ValorProduto := Round(ValorProduto + ValorAux);
      end;

    end;

    if Cancelado <> '' then
    begin
      Result := Result + '*~REMOVIDO / CANCELADO / SEM ESTOQUE~*' +
        MENSAGEM_QUEBRA_LINHA_DUPLA;
    end
    else
    begin
      Total := Total + QryItens.FieldByName('valor_total').AsFloat;
      if Recalcular then
        Result := Result + '*' + Cancelado + 'R$: ' +
          FormatFloat('#0.00', ValorProduto) + Cancelado + '*' +
          MENSAGEM_QUEBRA_LINHA_DUPLA
      else
        Result := Result + '*' + Cancelado + 'R$: ' +
          FormatFloat('#0.00', QryItens.FieldByName('valor_total').AsFloat) +
          Cancelado + '*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
      ValorTotal := ValorTotal + ValorProduto;
    end;

    QryItens.Next;
  end;

  QryItens.Close;
  QryItens.SQL.Clear;
  QryItens.SQL.Add('select * from pedido_produtos where codigo_pedido = ' +
    IntToStr(Codigo));
  QryItens.Open;
  if Recalcular then
  begin

    Result := Result + '*-- TAXA --*' + MENSAGEM_QUEBRA_LINHA;
    Result := Result + '    *R$ ' + FormatFloat('#0.00',
      TabelaPedido.FieldByName('valor_taxa_entrega').AsFloat) + '*' +
      MENSAGEM_QUEBRA_LINHA;
    Result := Result + '*-- PEDIDO --*' + MENSAGEM_QUEBRA_LINHA;
    Result := Result + '    *R$ ' + FormatFloat('#0.00', ValorTotal) + '*' +
      MENSAGEM_QUEBRA_LINHA;
    Result := Result + '*-- TOTAL --*' + MENSAGEM_QUEBRA_LINHA;
    Result := Result + '    *R$ ' + FormatFloat('#0.00',
      ValorTotal + TabelaPedido.FieldByName('valor_taxa_entrega').AsFloat) + '*'
      + MENSAGEM_QUEBRA_LINHA;
    if ValorTotal = 0 then
      Result := '';

  end
  else
  begin
    Result := Result + '*-- TAXA --*' + MENSAGEM_QUEBRA_LINHA;
    Result := Result + '    *R$ ' + FormatFloat('#0.00',
      TabelaPedido.FieldByName('valor_taxa_entrega').AsFloat) + '*' +
      MENSAGEM_QUEBRA_LINHA;
    Result := Result + '*-- PEDIDO --*' + MENSAGEM_QUEBRA_LINHA;
    Result := Result + '    *R$ ' + FormatFloat('#0.00', Total) + '*' +
      MENSAGEM_QUEBRA_LINHA;
    Result := Result + '*-- TOTAL --*' + MENSAGEM_QUEBRA_LINHA;
    Result := Result + '    *R$ ' + FormatFloat('#0.00',
      Total + TabelaPedido.FieldByName('valor_taxa_entrega').AsFloat) + '*' +
      MENSAGEM_QUEBRA_LINHA;

    if Total = 0 then
      Result := '';
  end;

  TabelaPedido.Free;
  QryItens.Free;
  QryItensDetail.Free;
end;

function TFinalizarPedido.Tempo: Boolean;
var
  QryTempo: TFDQuery;
begin
  QryTempo := dmPrincipal.CriaQRY('TEMPO');
  QryTempo.Close;
  QryTempo.SQL.Clear;
  QryTempo.SQL.Add('SELECT valor FROM dados_componentes where frm = ' +
    QuotedStr('frmPrincipal') + ' and campo = ' +
    QuotedStr('cAtivarTempoEstimado') + ' and id_usuario = 0');
  QryTempo.Open;

  try
    Result := QryTempo.FieldByName('valor').AsString = 'T';
  except
    Result := False;
  end;
  QryTempo.Free;
end;

function TFinalizarPedido.TempoMensagem(Tipo: Integer): String;
var
  QryTempo: TFDQuery;
  campo: String;
begin
  case Tipo of
    0:
      begin
        campo := 'temp_vembuscar';
      end
  else
    begin
      campo := 'temp_delivery';
    end;
  end;

  QryTempo := dmPrincipal.CriaQRY('TEMPO');
  QryTempo.Close;
  QryTempo.SQL.Clear;
  QryTempo.SQL.Add('select ' + campo + ' as valor from dados_whatsapp');
  QryTempo.Open;

  try
    case Tipo of
      0:
        begin
          Result := MONO_ESPACADA + 'O TEMPO ESTIMADO PARA RETIRADA É DE ' +
            QryTempo.FieldByName('valor').AsString + 'M.' + MONO_ESPACADA +
            MENSAGEM_QUEBRA_LINHA;
        end
    else
      begin
        Result := MONO_ESPACADA + 'O TEMPO ESTIMADO PARA DELIVERY É DE ' +
          QryTempo.FieldByName('valor').AsString + 'M.' + MONO_ESPACADA +
          MENSAGEM_QUEBRA_LINHA;
      end;
    end;

  except
    Result := '';
  end;

  QryTempo.Free;
end;

end.
