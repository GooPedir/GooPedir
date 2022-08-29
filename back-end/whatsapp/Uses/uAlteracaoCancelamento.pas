unit uAlteracaoCancelamento;

interface

uses uBotConversa, FireDAC.Comp.Client, uPrincipal, System.SysUtils, Variants,
  uClassProduto;

type

  TCancelamento = class
  public
    function Cancelamento(Conversa: TBotConversa): TBotConversa;
  end;

  TAlteracaoRemover = class
  private
    function RetornaProdutos(Conversa: TBotConversa): String;
    function ValidaProduto(Conversa: TBotConversa): TProduto;

    procedure AtualizaValorPedido(Valor: Real; CodigoPedido: Integer;
      Conversa: TBotConversa);
  public
    function AlterarRemover(Conversa: TBotConversa): TBotConversa;
    function RemoveProduto(CodigoProduto: Integer): boolean;
  end;

implementation

{ TAlteracaoRemover }

uses uClassPedido;

function TAlteracaoRemover.AlterarRemover(Conversa: TBotConversa): TBotConversa;
var
  Mensagem: String;
  Produto: TProduto;

  Tabela: TFDTable;
  Menu: TMenu;

begin
  case Conversa.Etapa of
    0:
      begin
        dmPrincipal.GeraLOG(Conversa,
          'Alteração / Remover selecionar o produto');
        Conversa.CodigoPedido := Menu.VerificaPedidoAtual(Conversa);
        Mensagem := RetornaProdutos(Conversa);

        if Mensagem = '' then
        begin
          // Retornar ao menu
          Conversa.Etapa := 2;
          Conversa.Situacao := MenuPedido;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end;

        Mensagem := '*--- SELECIONE O PRODUTO ---*' +
          MENSAGEM_QUEBRA_LINHA_DUPLA + Mensagem;

        Conversa.Etapa := 1;
        if Usar_Novo_Botao then
        begin
          dmPrincipal.EnviaBotao(Conversa, Mensagem, '', ['MENU'], ['M']);
        end
        else
        begin
          Mensagem := Mensagem + '*M* para voltar ao *MENU*';
          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        end;
      end;
    1:
      begin
        dmPrincipal.GeraLOG(Conversa,
          'Seleciou o produto, aguardando ação Remover, Alterar ou Voltar');
        if trim(UpperCase(Conversa.Resposta)) = 'M' then
        begin
          Conversa.Etapa := 2;
          Conversa.Situacao := MenuPedido;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end;
        Produto := ValidaProduto(Conversa);

        if Produto.Ativo then
        begin
          // localizou o Produto
          Conversa.ProdutoCodigoSelecionado := Produto.Codigo;
          Mensagem := '*--- O DESEJA FAZER O QUE COM O ' + Produto.Nome + '?*';

          Conversa.Etapa := 3;

          if Usar_Novo_Botao then
          begin

            dmPrincipal.EnviaBotao(Conversa, Mensagem, '',
              ['REMOVER', 'ALTERAR', 'VOLTAR'], ['1', '2', '3']);
          end
          else
          begin
//             MENSAGEM_QUEBRA_LINHA_DUPLA;
             Mensagem := MENSAGEM_QUEBRA_LINHA_DUPLA+Mensagem + '*1 REMOVER*' + MENSAGEM_QUEBRA_LINHA;
             Mensagem := Mensagem + '*2 ALTERAR*' + MENSAGEM_QUEBRA_LINHA;
             Mensagem := Mensagem + '*3 VOLTAR*' + MENSAGEM_QUEBRA_LINHA;
             dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
          end;
          exit;
        end
        else
        begin
          dmPrincipal.GeraLOG(Conversa, 'Removeu o Produto');

          if RemoveProduto(Conversa.AuxCliente) then
          begin
            Mensagem := '*~--- PRODUTO ' + Produto.Nome + ' REMOVIDO ---~*';

            Conversa.Etapa := 0;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);

            sleep(2000);
            AlterarRemover(Conversa);
          end
          else
          begin
            Tabela.Free;
            Conversa.Resposta := '';
            Conversa.Etapa := 0;
            AlterarRemover(Conversa);
            exit;
          end;

          Conversa.Etapa := 0;
          AlterarRemover(Conversa);
        end;

      end;
    3:
      begin
        try
          if Usar_Novo_Botao then
          begin
            Conversa.Resposta := Conversa.ValorBotao;
          end;
          case StrToInt(Conversa.Resposta) of
            1:
              begin
                // Remover
                dmPrincipal.GeraLOG(Conversa, 'Removeu o Produto');
                Produto := Produto.LocalizaProduto
                  (Conversa.ProdutoCodigoSelecionado, Conversa);

                if RemoveProduto(Conversa.AuxCliente) then
                begin
                  Mensagem := '*~--- PRODUTO ' + Produto.Nome +
                    ' REMOVIDO ---~*';

                  Conversa.Etapa := 0;
                  dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);

                  sleep(2000);
                  AlterarRemover(Conversa);
                end
                else
                begin
                  Tabela.Free;
                  Conversa.Resposta := '';
                  Conversa.Etapa := 0;
                  AlterarRemover(Conversa);
                  exit;
                end;

              end;
            2:
              begin
                dmPrincipal.GeraLOG(Conversa, 'Alterou o Produto');
                Tabela := dmPrincipal.CriaTabela('pedido_produtos');
                if Tabela.Locate('codigo', IntToStr(Conversa.AuxCliente), [])
                then
                begin
                  AtualizaValorPedido(Tabela.FieldByName('valor_total').AsFloat,
                    Tabela.FieldByName('codigo_pedido').AsInteger, Conversa);
                  Tabela.Edit;
                  Tabela.FieldByName('quantidade').AsInteger := 0;
                  Tabela.Post;
                end
                else
                begin
                  Tabela.Free;
                  Conversa.Resposta := '';
                  Conversa.Etapa := 0;
                  AlterarRemover(Conversa);
                  exit;
                end;

                // Alterar
                Conversa.Etapa := 5;
                Conversa.Situacao := MenuPedido;
                Tabela.Free;
                dmPrincipal.GravaConversa(Conversa);
                dmPrincipal.GestorInteracao(Conversa);
                exit;
              end;
            3:
              begin
                dmPrincipal.GeraLOG(Conversa, 'Voltou');
                // Voltar
                Conversa.Resposta := '';
                Conversa.Etapa := 0;
                AlterarRemover(Conversa);
                exit;
              end
          else
            begin
              dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
                Conversa);
              exit;
            end;
          end;
        except
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;

      end;

  end;
end;

procedure TAlteracaoRemover.AtualizaValorPedido(Valor: Real;
  CodigoPedido: Integer; Conversa: TBotConversa);

begin

  if dmPrincipal.CriaTabela('pedido').Locate('codigo',
    IntToStr(CodigoPedido), []) then
  begin
    dmPrincipal.CriaTabela('pedido').Edit;
    dmPrincipal.CriaTabela('pedido').FieldByName('valor_pedido').AsFloat :=
      dmPrincipal.CriaTabela('pedido').FieldByName('valor_pedido')
      .AsFloat - Valor;

    dmPrincipal.CriaTabela('pedido').FieldByName('valor_total_pedido').AsFloat
      := dmPrincipal.CriaTabela('pedido').FieldByName('valor_total_pedido')
      .AsFloat - Valor;

    dmPrincipal.CriaTabela('pedido').FieldByName('valor_total_pedido').AsFloat
      := dmPrincipal.CriaTabela('pedido').FieldByName('valor_total_pedido')
      .AsFloat - dmPrincipal.CriaTabela('pedido')
      .FieldByName('valor_taxa_entrega').AsFloat;
    dmPrincipal.CriaTabela('pedido').Post;
  end;

end;

function TAlteracaoRemover.RemoveProduto(CodigoProduto: Integer): boolean;
var
  Tabela: TFDTable;
begin
  Tabela := dmPrincipal.CriaTabela('pedido_produtos');
  Result := False;
  if Tabela.Locate('codigo', IntToStr(CodigoProduto), []) then
  begin
    if Tabela.FieldByName('quantidade').AsInteger > 0 then
    begin
      AtualizaValorPedido(Tabela.FieldByName('valor_total').AsFloat,
        Tabela.FieldByName('codigo_pedido').AsInteger, nil);
      Tabela.Edit;

      Tabela.Edit;
      Tabela.FieldByName('quantidade').AsInteger := 0;
      Tabela.FieldByName('valor_unitario').AsInteger := 0;
      Tabela.FieldByName('valor_unitario').AsInteger := 0;
      Tabela.FieldByName('valor_adicional').AsInteger := 0;
      Tabela.Post;
      Result := True;
    end;
  end;
  Tabela.Free;
end;

function TAlteracaoRemover.RetornaProdutos(Conversa: TBotConversa): String;
Var
  Qry: TFDQuery;
  Qry2: TFDQuery;
  I: Integer;
  Produto: TProduto;
begin
  Qry := dmPrincipal.CriaQRY('RP');
  Qry2 := dmPrincipal.CriaQRY('RP2');
  Qry.Close;
  Qry.SQL.Clear;
  Qry.SQL.Add('SELECT * FROM pedido_produtos where codigo_pedido = ' +
    IntToStr(Conversa.CodigoPedido) +
    ' and quantidade > 0 and valor_total > 0');
  Qry.Open;
  I := 0;
  Result := '';
  while not Qry.Eof do
  begin

    if (Qry.FieldByName('quantidade').AsInteger > 0) and
      (Qry.FieldByName('valor_total').AsInteger > 0) then
    begin
      Produto := Produto.LocalizaProduto(Qry.FieldByName('codigo_produto')
        .AsInteger, Conversa);
      inc(I);
      Result := Result + '*' + FormatFloat('00', I) + ' - ' + trim(Produto.Nome)
        + '*' + MENSAGEM_QUEBRA_LINHA;

      Qry2.Close;
      Qry2.SQL.Clear;
      Qry2.SQL.Add
        ('SELECT * FROM pedido_produto_sap where codigo_pedido_produto = ' +
        Qry.FieldByName('codigo').AsString);
      Qry2.Open;

      while not Qry2.Eof do
      begin

        if Qry2.FieldByName('nomeclatura').AsString <> '' then
        begin
          Result := Result + '     _- ' + Qry2.FieldByName('nomeclatura')
            .AsString + ' ' + Qry2.FieldByName('descricao').AsString + '_' +
            MENSAGEM_QUEBRA_LINHA;
        end;
        Qry2.Next;
      end;
      if Qry.FieldByName('quantidade').AsInteger > 1 then
        Result := Result + '     *- ' + IntToStr(Qry.FieldByName('quantidade')
          .AsInteger) + 'Un*' + MENSAGEM_QUEBRA_LINHA;
      Result := Result + '       *R$ ' + FormatFloat('#0.00',
        Qry.FieldByName('valor_total').AsFloat) + '*' +
        MENSAGEM_QUEBRA_LINHA_DUPLA

    end;
    Qry.Next;
  end;
  Qry.Free;
  Qry2.Free;
end;

function TAlteracaoRemover.ValidaProduto(Conversa: TBotConversa): TProduto;
var
  Qry: TFDQuery;
  I: Integer;
  Menu: TMenu;
begin
  Result := TProduto.Create;
  try
    StrToInt(Conversa.Resposta);
  except
    Result.Ativo := False;
    exit;
  end;
  Menu := TMenu.Create;
  Conversa.CodigoPedido := Menu.VerificaPedidoAtual(Conversa);

  Qry := dmPrincipal.CriaQRY('RP');

  Qry.Close;
  Qry.SQL.Clear;
  Qry.SQL.Add('SELECT * FROM pedido_produtos where codigo_pedido = ' +
    IntToStr(Conversa.CodigoPedido) +
    ' and quantidade > 0 and valor_total > 0');
  Qry.Open;

  if StrToInt(Conversa.Resposta) > Qry.RecordCount then
  begin
    Result.Ativo := False;
    Qry.Free;
    exit;
  end;

  I := 0;
  while not Qry.Eof do
  begin
    inc(I);
    if I = StrToInt(Conversa.Resposta) then
    begin
      Result.Free;
      Result := Result.LocalizaProduto(Qry.FieldByName('codigo_produto')
        .AsInteger, Conversa);
      Conversa.AuxCliente := Qry.FieldByName('codigo').AsInteger;
      Qry.Free;
      exit;

    end;

    Qry.Next;
  end;
  Qry.Free;
end;

{ TCancelamento }

function TCancelamento.Cancelamento(Conversa: TBotConversa): TBotConversa;
var
  Tabela: TFDTable;
  Mensagem: String;
begin
  dmPrincipal.GeraLOG(Conversa, 'Cancelamento do Pedido');
  Tabela := dmPrincipal.CriaTabela('pedido');

  if Tabela.Locate('codigo', IntToStr(Conversa.CodigoPedido), []) then
  begin
    Tabela.Edit;
    Tabela.FieldByName('status').AsInteger := -9;
    Tabela.Post;
  end;
  Tabela.Free;
  Mensagem := '*~--- CANCELAMENTO ---~*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
  Mensagem := Mensagem + '*_Seu pedido foi cancelado com sucesso!_*';
  Conversa.Situacao := Finalizado;

  dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
  dmPrincipal.GravaConversa(Conversa);
  dmPrincipal.GestorInteracao(Conversa);

end;

end.
