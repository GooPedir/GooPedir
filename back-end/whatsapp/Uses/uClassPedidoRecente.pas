unit uClassPedidoRecente;

interface

uses uBotConversa, FireDAC.Comp.Client, uPrincipal, System.SysUtils, Variants,
  uClassProduto, DateUtils;

type

  TPedidoRecente = class
  private
    function PedidoRecente5m(Conversa: TBotConversa): boolean;

    function DadosUltimoPedido(Conversa: TBotConversa): String;

    procedure ClonaUltimoPedido(Conversa: TBotConversa);
  public
    function VerificaPedidoRecente(Conversa: TBotConversa): TBotConversa;
  end;

implementation

{ TPedidoRecente }

uses uClassPedido, uClassFinalizarPedido;

procedure TPedidoRecente.ClonaUltimoPedido(Conversa: TBotConversa);
var
  QRY: TFDQuery;
  QRYItens: TFDQuery;
  QRYItensDetalhes: TFDQuery;

  Produto: TProduto;

  Menu: TMenu;

  ArrayProdutoDescricao: Array of String;
  ArrayProdutoDescricaoItem: Array of String;
  ArrayProdutoValor: Array of Real;
  ArrayProdutoTipoValor: array of Integer;
  I: Integer;
begin
  QRY := dmPrincipal.CriaQRY('AUX09');
  QRYItens := dmPrincipal.CriaQRY('AUX10');
  QRYItensDetalhes := dmPrincipal.CriaQRY('AUX11');

  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add('SELECT * FROM pedido where codigo_cliente = ' +
    '(select codigo from cliente where celular_wpp = ' +
    QuotedStr(Conversa.Telefone) + ')' +
    ' and status = 1 and codigo_cliente_endereco = ' +
    IntToStr(Conversa.CodigoEndereco) + ' order by codigo desc limit 1');
  QRY.Open;

  QRYItens.Close;
  QRYItens.SQL.Clear;
  QRYItens.SQL.Add('SELECT * FROM pedido_produtos where codigo_pedido = ' +
    QRY.FieldByName('codigo').AsString);
  QRYItens.Open;

  while not QRYItens.Eof do
  begin
    Produto := Produto.LocalizaProduto(QRYItens.FieldByName('codigo_produto')
      .AsInteger, Conversa);

    QRYItensDetalhes.Close;
    QRYItensDetalhes.SQL.Clear;
    QRYItensDetalhes.SQL.Add
      ('SELECT * FROM pedido_produto_sap where codigo_pedido_produto = ' +
      QRYItens.FieldByName('codigo').AsString);
    QRYItensDetalhes.Open;
    SetLength(ArrayProdutoDescricao, QRYItensDetalhes.RecordCount);
    SetLength(ArrayProdutoDescricaoItem, QRYItensDetalhes.RecordCount);
    SetLength(ArrayProdutoValor, QRYItensDetalhes.RecordCount);
    SetLength(ArrayProdutoTipoValor, QRYItensDetalhes.RecordCount);
    I := 0;
    while not QRYItensDetalhes.Eof do
    begin
      ArrayProdutoDescricao[I] := QRYItensDetalhes.FieldByName
        ('nomeclatura').AsString;
      ArrayProdutoDescricaoItem[I] := QRYItensDetalhes.FieldByName
        ('descricao').AsString;
      ArrayProdutoValor[I] := QRYItensDetalhes.FieldByName('valor').AsFloat;
      ArrayProdutoTipoValor[I] := QRYItensDetalhes.FieldByName('tipo_valor')
        .AsInteger;
      inc(I);
      QRYItensDetalhes.Next;
    end;

    Menu.GravaItensPedido(Produto, QRYItens.FieldByName('quantidade').AsInteger,
      '', Conversa, ArrayProdutoDescricao, ArrayProdutoDescricaoItem,
      ArrayProdutoValor, ArrayProdutoTipoValor);

    QRYItens.Next;
  end;
  QRY.Free;
  QRYItens.Free;
  QRYItensDetalhes.Free;

end;

function TPedidoRecente.DadosUltimoPedido(Conversa: TBotConversa): String;
var
  QRY: TFDQuery;
  QryItensDetail: TFDQuery;
  mensagem: String;
  Produto: TProduto;
  Cancelado: String;
  TabelaPedido: TFDTable;

  Finaliza: TFinalizarPedido;

  pedido: String;

begin
  QRY := dmPrincipal.CriaQRY('AUX06');
  QryItensDetail := dmPrincipal.CriaQRY('AUX07');
  TabelaPedido := dmPrincipal.CriaTabela('pedido');

  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add('SELECT * FROM pedido where codigo_cliente = ' +
    '(select codigo from cliente where celular_wpp = ' +
    QuotedStr(Conversa.Telefone) + ' limit 1)' +
    ' and status = 1 and codigo_cliente_endereco = ' +
    IntToStr(Conversa.CodigoEndereco) + ' order by codigo desc limit 1');
  QRY.Open;

  if QRY.RecordCount = 0 then
  begin
    QRY.Free;
    Result := '';
    Exit;
  end;
  QRY.Free;
  Result := '';
  Exit;

  Conversa.AuxCliente := QRY.FieldByName('codigo').AsInteger;

  mensagem := '*--- ULTIMO PEDIDO ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;

  TabelaPedido.Locate('codigo', Conversa.AuxCliente, []);
  pedido := Finaliza.ProdutosResumo(Conversa.AuxCliente, Conversa);
  mensagem := mensagem + pedido;

  mensagem := mensagem + '*Deseja refazer o pedido a cima?*' +
    MENSAGEM_QUEBRA_LINHA;
  mensagem := mensagem + '*S* para *SIM*' + MENSAGEM_QUEBRA_LINHA;
  mensagem := mensagem + '*N* para *NÃO*' + MENSAGEM_QUEBRA_LINHA;
  if pedido = '' then
    mensagem := '';

  Result := mensagem;
  try
    if TabelaPedido <> nil then

      TabelaPedido.Free;
  except

  end;
  try
    if QRY <> nil then
      QRY.Free;
  except

  end;
  try
    if QryItensDetail <> nil then
      QryItensDetail.Free;
  except

  end;

end;

function TPedidoRecente.PedidoRecente5m(Conversa: TBotConversa): boolean;
var
  QRY: TFDQuery;
begin
  QRY := dmPrincipal.CriaQRY('AUX03');

  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add('SELECT * FROM pedido where data_pedido = ' +
    QuotedStr(FormatDateTime('yyyy-mm-dd', now)) + ' and hora_pedido < ' +
    QuotedStr(FormatDateTime('hh:mm:ss', IncMinute(time, -5))) +
    ' and status = 1 and codigo_cliente = ' +
    IntToStr(Conversa.CodigoClienteInterno) + ' and codigo_cliente_endereco = '
    + IntToStr(Conversa.CodigoEndereco));

  QRY.Open;
  Result := QRY.RecordCount > 0;

  QRY.Free;
end;

function TPedidoRecente.VerificaPedidoRecente(Conversa: TBotConversa)
  : TBotConversa;
var
  mensagem: String;
  QRY: TFDQuery;
begin
  case Conversa.Etapa of
    0:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Verificando Pedidos');
        if PedidoRecente5m(Conversa) then
        begin
          mensagem := '*--- VOCÊ JÁ POSSUE UM PEDIDO HOJE ---*' +
            MENSAGEM_QUEBRA_LINHA_DUPLA;
          mensagem := mensagem + '*Deseja fazer um pedido novo?*';

          Conversa.Etapa := 1;

          if Usar_Novo_Botao then
          begin
            dmPrincipal.EnviaBotao(Conversa, mensagem, '', ['SIM', 'NÃO'],
              ['S', 'N']);
          end
          else
          begin
            mensagem := MENSAGEM_QUEBRA_LINHA + mensagem + '*S* para *SIM*' +
              MENSAGEM_QUEBRA_LINHA;
            mensagem := mensagem + '*N* para *NÃO*' + MENSAGEM_QUEBRA_LINHA;
            dmPrincipal.Enviamensagem(Conversa.Etapa, mensagem, Conversa);
          end;
        end
        else
        begin
          // Não possui pedido novo
          Conversa.Resposta := '';
          Conversa.Etapa := 2;
          VerificaPedidoRecente(Conversa);
          Exit;
        end;
      end;
    1:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Verificando Pedidos');
        if Trim(UpperCase(Conversa.Resposta)) = 'S' then
        begin
          Conversa.Resposta := '';
          Conversa.Etapa := 2;
          VerificaPedidoRecente(Conversa);
          Exit;
        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'N' then
        begin
          dmPrincipal.ExecultaSQL
            ('update pedido set codigo_cliente = 0 where codigo_cliente = ' +
            IntToStr(Conversa.CodigoClienteInterno) + ' and status -1');
          Conversa.Etapa := 0;
          Conversa.Situacao := Finalizado;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          Exit;

        end
        else
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          Exit;
        end;
      end;
    2:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Verificando Pedidos');
        // Verificar ultimo pedido

        mensagem := DadosUltimoPedido(Conversa);
        if mensagem = '' then
        begin
          dmPrincipal.ExecultaSQL
            ('update pedido set codigo_cliente = 0 where codigo_cliente = ' +
            IntToStr(Conversa.CodigoClienteInterno) + ' and status -1');
          Conversa.Resposta := 'N';
          Conversa.Etapa := 3;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          Exit;

        end;

        Conversa.Etapa := 3;
        dmPrincipal.Enviamensagem(Conversa.Etapa, mensagem, Conversa);
        // SELECT * FROM pedido where codigo_cliente = 1 order by codigo desc limit 1
      end;
    3:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Verificando Pedidos');
        if Trim(UpperCase(Conversa.Resposta)) = 'S' then
        begin
          // REFAZER AKI
          dmPrincipal.GeraLOG(Conversa, 'Clonando Ultimo Pedido');
          ClonaUltimoPedido(Conversa);

          Conversa.Etapa := 2;
          Conversa.Situacao := MenuPedido;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          Exit;

        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'N' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Excluindo Pedido em Aberto');
          // SELECT * FROM pedido where codigo_cliente = X and data_pedido = X and status = -1
          QRY := dmPrincipal.CriaQRY('AUXUP');
          QRY.Close;
          QRY.SQL.Clear;
          QRY.SQL.Add
            ('update pedido set codigo_cliente = 0  where codigo_cliente = ' +
            IntToStr(Conversa.CodigoClienteInterno) + ' and data_pedido = ' +
            QuotedStr(FormatDateTime('yyyy-mm-dd', date)) + ' and status = -1');
          QRY.ExecSQL;

          Conversa.Etapa := 2;
          Conversa.Situacao := MenuPedido;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          Exit;
        end
        else
        begin
          if Conversa.Pergunta = '' then
          begin
            Conversa.Etapa := 0;
            dmPrincipal.GravaConversa(Conversa);
            dmPrincipal.GestorInteracao(Conversa);
            Exit;
          end;

          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          Exit;
        end;
      end;
  end;
end;

end.
