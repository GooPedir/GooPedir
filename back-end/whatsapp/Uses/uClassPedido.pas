unit uClassPedido;

interface

uses uBotConversa, FireDAC.Comp.Client, uPrincipal, System.SysUtils, Variants,
  uClassProduto;

type
  TMenu = class
  private

    procedure AtualizaValorPedido(Valor: Real; CodigoPedido: Integer); overload;
    procedure AtualizaValorPedido(Valor: Real; CodigoPedido: Integer;
      Conversa: TBotConversa); overload;

  var
    PodeFinalizar: Boolean;
    qtdProdutos: Integer;

  public
    function VerificaPedidoAtual(Conversa: TBotConversa): Integer;

    function GravaItensPedido(Produto: TProduto; Quantidade: Integer;
      Observacao: String; Conversa: TBotConversa;
      ArrayComplementoDescricao, ArrayComplementosIten: Array of String;
      ArrayAdicionais: Array of Real;
      ArrayCategoriasTipoValor: array of Integer): String;

    function MenuPedido(Conversa: TBotConversa): TBotConversa;

    function MontaMenu(Conversa: TBotConversa): String;
    function MontaProdutos(Conversa: TBotConversa): String;

    function SQLMenuVemBuscar: String;
    function SQLMenuDelivery: String;

    function RetornaCodigoCategoriaSelecionada(Conversa: TBotConversa)
      : TBotConversa;

    function RetornaCodigoProdutoSelecionada(Conversa: TBotConversa)
      : TBotConversa;

  end;

implementation

{ TMenu }

uses uDM, uClassEndereco, uRequisicao;

procedure TMenu.AtualizaValorPedido(Valor: Real; CodigoPedido: Integer);
var
  Tabela: TFDTable;
begin
  Tabela := dmPrincipal.CriaTabela('pedido');

  if Tabela.Locate('codigo', IntToStr(CodigoPedido), []) then
  begin
    Tabela.Edit;
    Tabela.FieldByName('valor_pedido').AsFloat := Valor;
    Tabela.FieldByName('valor_total_pedido').AsFloat := Valor;
    Tabela.Post;
  end;
  Tabela.Free;
end;

procedure TMenu.AtualizaValorPedido(Valor: Real; CodigoPedido: Integer;
  Conversa: TBotConversa);
var
  Tabela: TFDTable;

  Endereco: TEndereco;
begin
  Tabela := dmPrincipal.CriaTabela('pedido');

  if Tabela.Locate('codigo', IntToStr(CodigoPedido), []) then
  begin
    Tabela.Edit;
    Tabela.FieldByName('valor_taxa_entrega').AsFloat :=
      Endereco.TaxaDeEntrega(Conversa);
    Tabela.FieldByName('valor_pedido').AsFloat :=
      Tabela.FieldByName('valor_pedido').AsFloat + Valor;
    Tabela.FieldByName('valor_total_pedido').AsFloat :=
      Tabela.FieldByName('valor_total_pedido').AsFloat + Valor;
    Tabela.FieldByName('valor_total_pedido').AsFloat :=
      Tabela.FieldByName('valor_total_pedido').AsFloat +
      Tabela.FieldByName('valor_taxa_entrega').AsFloat;
    Tabela.Post;
  end;
  Tabela.Free;
end;

function TMenu.GravaItensPedido(Produto: TProduto; Quantidade: Integer;
  Observacao: String; Conversa: TBotConversa; ArrayComplementoDescricao,
  ArrayComplementosIten: array of String; ArrayAdicionais: array of Real;
  ArrayCategoriasTipoValor: array of Integer): String;

var
  Tabela: TFDTable;
  TabelaSAP: TFDTable;
  CodigoPedidoAtual: Integer;

  ValorAdicional: Real;
  I: Integer;
  Valor: Real;
  Sabores: Integer;
begin
  CodigoPedidoAtual := VerificaPedidoAtual(Conversa);

  Tabela := dmPrincipal.CriaTabela('pedido_produtos', 'codigo');
  TabelaSAP := dmPrincipal.CriaTabela('pedido_produto_sap', 'codigo');

  // Inserir
  // if (Produto.Tipo <> Configuravel) then
  // begin
  // if Produto.Valor = 0 then
  // begin
  // Result := 'Lamentamos, o produto saiu do nosso cardápio!';
  // Tabela.Free;
  // TabelaSAP.Free;
  // exit;
  // end;
  // end
  // else if   (Produto.Tipo <> Pizza) then
  // begin
  // Result := 'Lamentamos, o produto saiu do nosso cardápio!';
  // Tabela.Free;
  // TabelaSAP.Free;
  // exit;
  // end;
  if (Produto.Tipo = Pizza) then
  begin
    Produto.Valor := 0;
    if (Length(ArrayComplementoDescricao) = 0) then
    begin
      Result := 'Lamentamos, o produto saiu do nosso cardápio!';
      Tabela.Free;
      TabelaSAP.Free;
      exit;
    end;

  end;

  Tabela.Insert;
  Tabela.FieldByName('codigo').AsInteger :=
    dmPrincipal.GerarID('pedido_produtos', 'codigo');
  Tabela.FieldByName('codigo_pedido').AsInteger := CodigoPedidoAtual;
  Tabela.FieldByName('codigo_produto').AsInteger := Produto.Codigo;
  Tabela.FieldByName('quantidade').AsInteger := Quantidade;
  Tabela.FieldByName('observacao').AsString := Observacao;
  Tabela.FieldByName('valor_unitario').AsFloat := Produto.Valor * Quantidade;
  Tabela.FieldByName('valor_adicional').AsFloat :=
    Tabela.FieldByName('valor_total').AsFloat + ValorAdicional * Quantidade;
  Tabela.FieldByName('valor_total').AsFloat :=
    Tabela.FieldByName('valor_adicional').AsFloat +
    Tabela.FieldByName('valor_unitario').AsFloat;
  Tabela.FieldByName('impresso').AsInteger := 0;
  Tabela.Post;

  dmPrincipal.RequisicaoLocal.URL := '/v1/util/impressao/aguarda/pedido/produtos/' +
    Tabela.FieldByName('codigo').asString;
  dmPrincipal.RequisicaoLocal.Metodo := mPost;
  try
    dmPrincipal.RequisicaoLocal.Execute;
  except

  end;

  // Adicionar aki o valor do pedido
  Result := '*--- INCLUIDO COM SUCESSO ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
  Result := Result + '*' + Trim(UpperCase(Produto.Nome)) + '*' +
    MENSAGEM_QUEBRA_LINHA;

  if (Produto.Tipo <> Simples) and
    (Length(ArrayComplementoDescricao) = Length(ArrayComplementosIten)) and
    (Length(ArrayComplementoDescricao) = Length(ArrayAdicionais)) and
    (Length(ArrayComplementoDescricao) > 0) then
  begin
    // Adicionar

    ValorAdicional := 0;
    Sabores := 0;
    if Produto.Tipo = Pizza then
    begin
      for I := 0 to Length(ArrayComplementoDescricao) - 1 do
      begin
        if ArrayCategoriasTipoValor[I] > 0 then
        begin
          Inc(Sabores);
        end;
      end;
    end;

    for I := 0 to Length(ArrayComplementoDescricao) - 1 do
    begin
      Valor := ArrayAdicionais[I];
      Result := Result + ' *- ' + ArrayComplementoDescricao[I] + ' ' +
        Trim(ArrayComplementosIten[I]) + '*' + MENSAGEM_QUEBRA_LINHA;

      case ArrayCategoriasTipoValor[I] of
        1:
          begin
            // Média
            Valor := (ArrayAdicionais[I] / Sabores);
            ValorAdicional := ValorAdicional + Valor;
          end;
        2:
          begin
            // Maxima

            if ArrayAdicionais[I] > ValorAdicional then
            begin
              ValorAdicional := ArrayAdicionais[I];
              Valor := ArrayAdicionais[I];
            end;
          end;
        3:
          begin
            // Soma
            ValorAdicional := ValorAdicional + ArrayAdicionais[I];
            Valor := ArrayAdicionais[I];
          end
      else
        begin
          ValorAdicional := ValorAdicional + ArrayAdicionais[I];
        end;

      end;
      // else
      // ValorAdicional := ValorAdicional + ArrayAdicionais[I];

      TabelaSAP.Insert;
      TabelaSAP.FieldByName('id').AsInteger :=
        dmPrincipal.GerarID('pedido_produto_sap', 'id');
      TabelaSAP.FieldByName('codigo_pedido_produto').AsInteger :=
        Tabela.FieldByName('codigo').AsInteger;
      TabelaSAP.FieldByName('nomeclatura').AsString :=
        ArrayComplementoDescricao[I];
      TabelaSAP.FieldByName('descricao').AsString := ArrayComplementosIten[I];
      TabelaSAP.FieldByName('valor').AsFloat := Valor;
      TabelaSAP.FieldByName('tipo_valor').AsInteger :=
        ArrayCategoriasTipoValor[I];
      TabelaSAP.Post;
    end;
    if Produto.Tipo = Pizza then
    begin
      Tabela.Edit;
      Tabela.FieldByName('valor_unitario').AsFloat := Round(ValorAdicional);
      Tabela.FieldByName('valor_adicional').AsFloat := 0;
      Tabela.FieldByName('valor_total').AsFloat :=
        Tabela.FieldByName('valor_unitario').AsFloat * Quantidade;
      Tabela.Post;
    end
    else
    begin

      Tabela.Edit;
      Tabela.FieldByName('valor_unitario').AsFloat := Produto.Valor +
        ValorAdicional;
      Tabela.FieldByName('valor_adicional').AsFloat := ValorAdicional *
        Quantidade;
      Tabela.FieldByName('valor_total').AsFloat :=
        Tabela.FieldByName('valor_unitario').AsFloat * Quantidade;
      Tabela.Post;
    end;
  end
  else
  begin
    TabelaSAP.Insert;
    TabelaSAP.FieldByName('id').AsInteger :=
      dmPrincipal.GerarID('pedido_produto_sap', 'id');
    TabelaSAP.FieldByName('codigo_pedido_produto').AsInteger :=
      Tabela.FieldByName('codigo').AsInteger;
    TabelaSAP.FieldByName('nomeclatura').AsString := '';
    TabelaSAP.FieldByName('descricao').AsString := '';
    TabelaSAP.FieldByName('valor').AsFloat := 0;
    TabelaSAP.Post;
  end;
  if Observacao <> '' then
  begin
    TabelaSAP.Insert;
    TabelaSAP.FieldByName('id').AsInteger :=
      dmPrincipal.GerarID('pedido_produto_sap', 'id');
    TabelaSAP.FieldByName('codigo_pedido_produto').AsInteger :=
      Tabela.FieldByName('codigo').AsInteger;
    TabelaSAP.FieldByName('nomeclatura').AsString := 'OBSERVAÇÃO';
    TabelaSAP.FieldByName('descricao').AsString := Observacao;
    TabelaSAP.FieldByName('valor').AsFloat := 0;
    TabelaSAP.Post;

  end;

  AtualizaValorPedido(Tabela.FieldByName('valor_total').AsFloat,
    CodigoPedidoAtual, Conversa);

  if Conversa.CategoriaDescricao = '' then
  begin
    Conversa.CategoriaDescricao := Produto.DescricaoCategoria;
  end;

  Result := Result + MENSAGEM_QUEBRA_LINHA;
  if not Usar_Novo_Botao then
  begin
    Result := Result + '*DIGITE*' + MENSAGEM_QUEBRA_LINHA;
    Result := Result + '*S* para adicionar outro(s) *' +
      Trim(UpperCase(Conversa.CategoriaDescricao)) + '*' +
      MENSAGEM_QUEBRA_LINHA_DUPLA;
    Result := Result + '*M* para voltar ao *MENU*' +
      MENSAGEM_QUEBRA_LINHA_DUPLA;
    Result := Result + '*F* para *FINALIZAR*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
  end;



  // if dm.CDT_TAB2.Locate(´TAB_COD;TAB_KEY´ , VarArrayOf([dbedit1.text,dbedit3.Text]),[]) then

  try
    Tabela.Free;
    TabelaSAP.Free;
  except

  end;

end;

function TMenu.MenuPedido(Conversa: TBotConversa): TBotConversa;
var
  Mensagem: String;
  subMensagem: String;
  botoes: array of string;
  botoesID: array of string;
  TipoSabor: String;
  Produto: TProduto;
  I: Integer;
  K: Integer;

  ArrayAux: Array of String;
  ArrayAuxI: Array of Integer;
  Aux: String;
  ID: Integer;
  NewID: Integer;

  SeparadoPorVirgula: TSeparadoPorVirgula;

  Tabela: TFDTable;
  AdicionouObrigatorio: Boolean;

  MensagemExtra: String;
begin

  case Conversa.Etapa of
    0:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Menu Inicial');
        Conversa.Etapa := 1;

        if Usar_Novo_Botao then
        begin
          dmPrincipal.EnviaBotao(Conversa, dmPrincipal.MenuInicial(Conversa),
            'escolha uma opção', ['DELIVERY', 'VEM BUSCAR'], ['D', 'V']);
        end
        else
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa,
            dmPrincipal.MenuInicial(Conversa), Conversa);
        end;

        exit;
      end;
    1:
      begin
        if Usar_Novo_Botao then
        begin
          Conversa.Resposta := Conversa.ValorBotao;
        end;
        if UpperCase(Trim(Conversa.Resposta)) = 'D' then
        begin
          if dm.DADOS_EMPRESA.FieldByName('tipo_entrega').AsInteger = 3 then
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
              Conversa);
            exit;
          end;
          dmPrincipal.GeraLOG(Conversa, 'Delivery');
          Conversa.Entrega := Delivery;
          Conversa.Situacao := EnderecoCliente;
          Conversa.Etapa := 0;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end
        else if UpperCase(Trim(Conversa.Resposta)) = 'V' then
        begin
          if dm.DADOS_EMPRESA.FieldByName('tipo_entrega').AsInteger = 2 then
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
              Conversa);
            exit;
          end;
          dmPrincipal.GeraLOG(Conversa, 'Vem Buscar');
          Conversa.CodigoEndereco := 0;
          Conversa.Entrega := VemBuscar;
          Conversa.CodigoEndereco := 0;
        end
        else if UpperCase(Trim(Conversa.Resposta)) = 'A' then
        begin
          if dm.DADOS_EMPRESA.FieldByName('atendimento').AsInteger <> 1 then
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
              Conversa);
            exit;
          end;
          dmPrincipal.GeraLOG(Conversa, 'Em Atendimento');
          Conversa.Situacao := AtendimentoHumano;
          Conversa.Etapa := 0;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.Enviamensagem(Conversa.Etapa,
            'Caso deseja retornar ao atendimente automatico basta digitar *VOLTAR*!',
            Conversa);
          exit;
        end
        else
        begin
          if Conversa.Pergunta = '' then
          begin
            Conversa.Etapa := 0;
            dmPrincipal.GravaConversa(Conversa);
            MenuPedido(Conversa);
            exit;
          end;
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;
        Conversa.Etapa := 11;
        dmPrincipal.GravaConversa(Conversa);
        MenuPedido(Conversa);
        exit;
      end;
    2:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Selecionando os Produtos');
        // Resetar os Array
        SetLength(Conversa.ArrayCategorias, 0);
        SetLength(Conversa.ArrayCategoriasItens, 0);
        SetLength(Conversa.ArrayCategoriasValores, 0);
        SetLength(Conversa.ArrayCategoriasTipoValor, 0);
        Conversa.Etapa := 3;

        if Usar_Novo_Botao then
        begin
          if PodeFinalizar then
          begin
            dmPrincipal.EnviaBotao(Conversa, MontaMenu(Conversa),
              'escolha apenas uma opção', ['FINALIZAR', 'CANCELAR', 'ALTERAR'],
              ['F', 'C', 'A']);
          end
          else
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, MontaMenu(Conversa),
              Conversa);
          end;

        end
        else
        begin
          Mensagem := MontaMenu(Conversa);

          if PodeFinalizar then
          begin
            Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;
            Mensagem := Mensagem + '*F* para *FINALIZAR*' +
              MENSAGEM_QUEBRA_LINHA;
            Mensagem := Mensagem + '*C* para *CANCELAR*' +
              MENSAGEM_QUEBRA_LINHA;
            Mensagem := Mensagem + '*A* para *ALTERAR/REMOVER*' +
              MENSAGEM_QUEBRA_LINHA;
            dmPrincipal.Enviamensagem(Conversa.Etapa, MontaMenu(Conversa),
              Conversa);
          end
          else
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, MontaMenu(Conversa),
              Conversa);
          end;

        end;

      end;
    3:
      begin
        if Usar_Novo_Botao then
        begin
          Conversa.Resposta := Conversa.ValorBotao;
        end;
        if Trim(UpperCase(Conversa.Resposta)) = 'F' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Finalizando');
          Conversa.Resposta := '';
          Conversa.Situacao := FinalizandoPedido;
          Conversa.Etapa := 0;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'A' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Alterando');
          Conversa.Situacao := AlteraRemove;
          Conversa.Etapa := 0;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'C' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Cancelando');
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
            dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
              Conversa);

            Tabela.Free;
            exit;
          end;

          Conversa.CodigoPedido := Tabela.FieldByName('codigo').AsInteger;
          Conversa.Situacao := Cancelamento;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          Tabela.Free;
          exit;
        end;

        if Conversa.Resposta <> '' then
          Conversa := RetornaCodigoCategoriaSelecionada(Conversa);

        if Conversa.ProdutoCategoriaSelecionada > 0 then
        begin

          Mensagem := MontaProdutos(Conversa);
          if qtdProdutos = 1 then
          begin
            Conversa.Resposta := '1';
            Conversa.Etapa := 4;
            MenuPedido(Conversa);
            exit;
          end;

          if Mensagem = '' then
          begin
            // Resetar os Array
            SetLength(Conversa.ArrayCategorias, 0);
            SetLength(Conversa.ArrayCategoriasItens, 0);
            SetLength(Conversa.ArrayCategoriasValores, 0);
            SetLength(Conversa.ArrayCategoriasTipoValor, 0);
            Conversa.Etapa := 3;
            Mensagem := '*Lamentamos!*' + MENSAGEM_QUEBRA_LINHA_DUPLA +
              '*Não há produtos na categoria selecionada HOJE*';
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
            Conversa.Resposta := 'M';
            dmPrincipal.GravaConversa(Conversa);
            MenuPedido(Conversa);
            exit;
          end;
          Conversa.Etapa := 4;
          dmPrincipal.GravaConversa(Conversa);
          if Usar_Novo_Botao then
          begin
            dmPrincipal.EnviaBotao(Conversa, Mensagem, '', ['MENU'], ['M']);
          end
          else
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
          end;
          exit;
        end
        else
        begin
          Conversa.Etapa := 2;
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);

          exit;
        end;

      end;
    4:
      begin
        if Usar_Novo_Botao then
          Conversa.Resposta := Conversa.ValorBotao;
        // Resetar os Array
        SetLength(Conversa.ArrayCategorias, 0);
        SetLength(Conversa.ArrayCategoriasItens, 0);
        SetLength(Conversa.ArrayCategoriasValores, 0);
        SetLength(Conversa.ArrayCategoriasTipoValor, 0);
        if Trim(UpperCase(Conversa.Resposta)) = 'M' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Menu');
          Conversa.Etapa := 2;
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;

        try
          StrToInt(Conversa.Resposta);
        except
          if Conversa.Pergunta = '' then
          begin
            Conversa.Etapa := 0;
            try
              Result := RetornaCodigoProdutoSelecionada(Conversa);
            except
              Conversa.Etapa := 2;
              dmPrincipal.GravaConversa(Conversa);
              MenuPedido(Conversa);
              exit;
            end;
            exit;

          end;
          Conversa.Etapa := 2;
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;

        Conversa := RetornaCodigoProdutoSelecionada(Conversa);

        if Conversa.ProdutoCategoriaSelecionada = 0 then
        begin
          Conversa.Etapa := 0;
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;

        if Conversa.ProdutoCodigoSelecionado = 0 then
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;

        Conversa.Etapa := 5;
        dmPrincipal.GravaConversa(Conversa);
        MenuPedido(Conversa);
        exit;
      end;
    5:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Validando Tipo do Produto');
        // Validar aki o tipo do produto
        // TTipoProduto = (Simples, AdicionarRemover, Configuravel, Pizza);
        Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
          Conversa);

        case Produto.Tipo of
          Simples:
            begin
              Mensagem :=
                'Informe a *QUANTIDADE* desejada ou digite *M* para retornar ao menu!';
              Conversa.Etapa := 6;
              dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
              exit;
            end;
          AdicionarRemover:
            begin
              // Não vai ser utilizado
              // Caso tenha algum com adicional, o sistema vai tratar e criar ele como configuravel!
              Mensagem :=
                'Informe a *QUANTIDADE* desejada ou digite *M* para retornar ao menu!';
              Conversa.Etapa := 6;
              dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
              exit;
            end;
          Configuravel:
            begin
              dmPrincipal.CriaQRY('CONFIGURAVEL').Close;
              dmPrincipal.CriaQRY('CONFIGURAVEL').SQL.Clear;
              dmPrincipal.CriaQRY('CONFIGURAVEL')
                .SQL.Add('SELECT * FROM pro_adi_personalizado where id_produto = '
                + IntToStr(Conversa.ProdutoCodigoSelecionado));
              dmPrincipal.CriaQRY('CONFIGURAVEL').Open;
              Conversa.MinimoCategoria := dmPrincipal.CriaQRY('CONFIGURAVEL')
                .FieldByName('qtd_minima').AsInteger;
              Conversa.MaximoCategoria := dmPrincipal.CriaQRY('CONFIGURAVEL')
                .FieldByName('qtd_maxima').AsInteger;
              Conversa.QuantidadeCategoria :=
                dmPrincipal.CriaQRY('CONFIGURAVEL').RecordCount + 1;
              Conversa.CategoriaAtual := 1;
              Conversa.Etapa := 9;
              Conversa.Resposta := '';
              dmPrincipal.GravaConversa(Conversa);
              MenuPedido(Conversa);
              exit;
            end;
          Pizza:
            begin
              Conversa.Resposta := '';
              Conversa.Etapa := 12;
              dmPrincipal.GravaConversa(Conversa);
              MenuPedido(Conversa);
              exit;
            end;

        end;
        Mensagem :=
          'Informe a *QUANTIDADE* desejada ou digite *M* para retornar ao menu!';
        Conversa.Etapa := 6;
        dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        exit;
      end;
    6:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Quantidade');
        Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
          Conversa);
        if Trim(UpperCase(Conversa.Resposta)) = 'M' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Menu');
          // Manda para o MENU
          Conversa.Etapa := 2;
          Conversa.Pergunta := '';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;
        try
          if StrToInt(Conversa.Resposta) < 0 then
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
              Conversa);
            exit;
          end;
        except
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;
        Conversa.Etapa := 7;
        Conversa.ProdutoQuantidade := StrToInt(Conversa.Resposta);
        if Usar_Novo_Botao then
        begin
          Mensagem :=
            'Descreva a observação para o item, ou clique no botão abaixo!';

          if not Produto.InformaObs then
          begin
            Conversa.Resposta := 'SEM OBSERVAÇÃO';
            dmPrincipal.GravaConversa(Conversa);
            MenuPedido(Conversa);
            exit;
          end;

          dmPrincipal.EnviaBotao(Conversa, Mensagem, '',
            ['SEM OBSERVAÇÃO'], ['P'])
        end
        else
        begin
          Mensagem :=
            'Descreva a observação para o item, digite *P* para prosseguir';
          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        end;

      end;
    7:
      begin
        if Usar_Novo_Botao then
          Conversa.Resposta := Conversa.ValorBotao;

        dmPrincipal.GeraLOG(Conversa, 'Descrição');
        // Valida Descrição
        if Trim(UpperCase(Conversa.Resposta)) = 'P' then
        begin
          Conversa.Resposta := '';
        end;

        Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
          Conversa);

        Mensagem := GravaItensPedido(Produto,
          StrToInt(FloatToStr(Conversa.ProdutoQuantidade)), Conversa.Resposta,
          Conversa, Conversa.ArrayCategorias, Conversa.ArrayCategoriasItens,
          Conversa.ArrayCategoriasValores, Conversa.ArrayCategoriasTipoValor);
        Conversa.Etapa := 8;
        SetLength(Conversa.ArrayCategorias, 0);
        SetLength(Conversa.ArrayCategoriasItens, 0);
        SetLength(Conversa.ArrayCategoriasValores, 0);
        SetLength(Conversa.ArrayCategoriasTipoValor, 0);

        if Mensagem = 'Lamentamos, o produto saiu do nosso cardápio!' then
        begin
          Conversa.Etapa := 8;
          Conversa.Resposta := 'S';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;
        if Usar_Novo_Botao then
        begin
          dmPrincipal.EnviaBotao(Conversa, Mensagem, 'adicionar outro(a) ' +
            Conversa.CategoriaDescricao, ['OUTRO', 'MENU', 'FINALIZAR'],
            ['S', 'M', 'F']);
        end
        else
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        end;

        exit;
      end;
    8:
      begin
        if Usar_Novo_Botao then
          Conversa.Resposta := Conversa.ValorBotao;
        if Trim(UpperCase(Conversa.Resposta)) = 'S' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Adicionando Outro Produto');
          Conversa.Etapa := 3;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'M' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Menu');
          Conversa.Etapa := 2;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;

        end
        else if Trim(UpperCase(Conversa.Resposta)) = 'F' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Finalizando');
          Conversa.Resposta := '';
          Conversa.Situacao := FinalizandoPedido;
          Conversa.Etapa := 0;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end
        else
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;

      end;
    9:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Produto Configuravel');
        // Categorias
        if Conversa.QuantidadeCategoria = 0 then
        begin
          Conversa.Resposta := '';
          Conversa.Etapa := 2;
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          // Ver o que vou fazer, acho que volta pro menu de selecionar o produto!
          exit;
        end;
        Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
          Conversa);

        if (Conversa.CategoriaAtual > Conversa.QuantidadeCategoria) or
          (Conversa.CategoriaAtual = Conversa.QuantidadeCategoria) and
          (Conversa.Resposta = '') then
        begin
          // Já selecionou todos os itens
          Conversa.Etapa := 6;
          Conversa.Resposta := '1';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;

        // Preciso de um index
        ID := Conversa.CategoriaAtual - 1;
        Mensagem := Mensagem + '*' + Produto.InfoAdicional.ArrayDescricao[ID] +
          '*' + MENSAGEM_QUEBRA_LINHA;

        if Produto.InfoAdicional.ArrayMinimo[ID] = 1 then
        begin
          if Produto.InfoAdicional.ArrayMaximo[ID] > 0 then
            Mensagem := Mensagem +
              'É obrigatorio selecionar pelomenos *1* item máximo ' + '*' +
              IntToStr(Produto.InfoAdicional.ArrayMaximo[ID]) + '*' +
              MENSAGEM_QUEBRA_LINHA_DUPLA
          else
            Mensagem := Mensagem + 'É obrigatorio selecionar pelomenos *1* item'
              + MENSAGEM_QUEBRA_LINHA_DUPLA;
        end
        else
        begin
          Mensagem := Mensagem + '*Informe os códigos separados por vírgula*' +
            MENSAGEM_QUEBRA_LINHA_DUPLA;
        end;




        // dmPrincipal.CriaQRY('CONFIGURAVEL').Close;
        // dmPrincipal.CriaQRY('CONFIGURAVEL').SQL.Clear;
        // dmPrincipal.CriaQRY('CONFIGURAVEL')
        // .SQL.Add('SELECT * FROM pro_adi_personalizado where id_produto = ' +
        // IntToStr(Conversa.ProdutoCodigoSelecionado));
        // dmPrincipal.CriaQRY('CONFIGURAVEL').Open;
        //
        // if Conversa.CategoriaAtual > 1 then
        // begin
        // for I := 2 to Conversa.CategoriaAtual do
        // dmPrincipal.CriaQRY('CONFIGURAVEL').Next;
        // end;

        // Mensagem := Mensagem + '*' + dmPrincipal.CriaQRY('CONFIGURAVEL')
        // .FieldByName('descricao').AsString + '*' + MENSAGEM_QUEBRA_LINHA;

        // if dmPrincipal.CriaQRY('CONFIGURAVEL').FieldByName('qtd_minima')
        // .AsInteger = 1 then
        // begin
        // // Obrigatorio
        // if dmPrincipal.CriaQRY('CONFIGURAVEL').FieldByName('qtd_maxima')
        // .AsInteger > 0 then
        // Mensagem := Mensagem +
        // 'É obrigatorio selecionar pelomenos *1* item máximo ' + '*' +
        // IntToStr(dmPrincipal.CriaQRY('CONFIGURAVEL')
        // .FieldByName('qtd_maxima').AsInteger) + '*' +
        // MENSAGEM_QUEBRA_LINHA_DUPLA
        // else
        // Mensagem := Mensagem + 'É obrigatorio selecionar pelomenos *1* item'
        // + MENSAGEM_QUEBRA_LINHA_DUPLA;
        // end
        // else
        // begin
        // Mensagem := Mensagem + '*Informe os códigos separados por vírgula*' +
        // MENSAGEM_QUEBRA_LINHA_DUPLA;
        // end;
        //
        // dmPrincipal.CriaQRY('CONFAUX').Close;
        // dmPrincipal.CriaQRY('CONFAUX').SQL.Clear;
        // dmPrincipal.CriaQRY('CONFAUX')
        // .SQL.Add('SELECT * FROM pro_adi_personalizado_sabores where id_pro_adi_personalizado = '
        // + dmPrincipal.CriaQRY('CONFIGURAVEL').FieldByName('id').AsString);
        // dmPrincipal.CriaQRY('CONFAUX').Open;
        //
        // if dmPrincipal.CriaQRY('CONFAUX').RecordCount = 0 then
        // begin
        // // Ver o que vou fazer, acho que volta pro menu de selecionar o produto!
        // exit;
        // end;

        if Length(Produto.InfoAdicional.ArrayDescricao) = 0 then
        begin

        end;
        NewID := 0;
        for I := 0 to Length(Produto.InfoAdicional.ArrayItemNome) - 1 do
        begin
          if Produto.InfoAdicional.ArrayItemIndex[I] = ID then
          begin
            Inc(NewID);
            Mensagem := Mensagem + '*' + FormatFloat('00', NewID) + ' - ' +
              Trim(Produto.InfoAdicional.ArrayItemNome[I]) + '*';

            if Produto.InfoAdicional.ArrayItemValor[I] > 0 then
              Mensagem := Mensagem + ' *R$ ' + FormatFloat('#0.00',
                Produto.InfoAdicional.ArrayItemValor[I]) + '*' +
                MENSAGEM_QUEBRA_LINHA
            else
              Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;

            if Trim(Produto.InfoAdicional.ArrayItemDescricao[I]) <> '' then
            begin
              Mensagem := Mensagem + MONO_ESPACADA +
                Trim(Produto.InfoAdicional.ArrayItemDescricao[I]) +
                MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
            end;
          end;

        end;

        Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;

        //
        // I := 0;
        // while not dmPrincipal.CriaQRY('CONFAUX').Eof do
        // begin
        // inc(I);
        // Mensagem := Mensagem + '*' + FormatFloat('00', I) + '* - ' +
        // dmPrincipal.CriaQRY('CONFAUX').FieldByName('nome').AsString;
        //
        // if dmPrincipal.CriaQRY('CONFAUX').FieldByName('valor').AsFloat > 0
        // then
        // Mensagem := Mensagem + ' R$ ' + FormatFloat('#0.00',
        // dmPrincipal.CriaQRY('CONFAUX').FieldByName('valor').AsFloat) +
        // MENSAGEM_QUEBRA_LINHA
        // else
        // Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;
        // dmPrincipal.CriaQRY('CONFAUX').Next;
        // end;
        //
        // Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;
        //
        // if dmPrincipal.CriaQRY('CONFIGURAVEL').FieldByName('qtd_minima')
        // .AsInteger = 0 then
        // begin
        // // Obrigatorio
        // Mensagem := Mensagem +
        // 'Caso não queira nenhuma das opções acima, digite *0* para prosseguir.'
        // + MENSAGEM_QUEBRA_LINHA;
        // end
        // else if dmPrincipal.CriaQRY('CONFIGURAVEL').FieldByName('qtd_minima')
        // .AsInteger = 1 then
        // begin
        // Mensagem := Mensagem + 'Informe o *código*!';
        // end
        // else
        // Mensagem := Mensagem + 'Informe os código referente ao *' +
        // Trim(dmPrincipal.CriaQRY('CONFIGURAVEL').FieldByName('descricao')
        // .AsString) + '* separados por *virgula*!';

        if Produto.InfoAdicional.ArrayMinimo[ID] = 0 then
        begin
          if Usar_Novo_Botao then
          begin
            SetLength(botoes, 2);
            SetLength(botoesID, 2);

            botoes[0] := 'PROXIMO';
            botoes[1] := 'MENU';
            botoesID[0] := 'P';
            botoesID[1] := 'M';
            subMensagem :=
              'Caso não queira nenhuma das opções acima, clique em PROXIMO, ou clique no MENU.';
          end
          else
          begin
            Mensagem := Mensagem +
              'Caso não queira nenhuma das opções acima, digite *0* para prosseguir, ou digite *M* para voltar ao MENU.'
              + MENSAGEM_QUEBRA_LINHA;
          end;

        end
        else if Produto.InfoAdicional.ArrayMaximo[ID] = 1 then
        begin
          if Usar_Novo_Botao then
          begin
            subMensagem := 'Informe o *código* ou clique no *MENU*';
            SetLength(botoes, 1);
            SetLength(botoesID, 1);
            botoes[0] := 'MENU';
            botoesID[0] := 'M';
          end
          else
          begin
            Mensagem := Mensagem +
              'Informe o *código* ou digite *M* para voltar ao MENU!';
          end;

        end
        else
        begin
          if Usar_Novo_Botao then
          begin
            subMensagem := 'Informe os código referente ao *' +
              Trim(Produto.InfoAdicional.ArrayDescricao[ID]) +
              '* separados por *virgula*, ou clique no *MENU*';
            SetLength(botoes, 1);
            SetLength(botoesID, 1);
            botoes[0] := 'MENU';
            botoesID[0] := 'M';
          end
          else
          begin
            Mensagem := Mensagem + 'Informe os código referente ao *' +
              Trim(Produto.InfoAdicional.ArrayDescricao[ID]) +
              '* separados por *virgula*, ou digite *MENU* para voltar ao MENU!';
          end;

        end;

        Conversa.Etapa := 10;

        if Usar_Novo_Botao then
          dmPrincipal.EnviaBotao(Conversa, Mensagem, subMensagem,
            botoes, botoesID)
        else
          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);

        exit;
      end;
    10:
      begin
        if Usar_Novo_Botao then
          Conversa.Resposta := Conversa.ValorBotao;

        if Trim(UpperCase(Conversa.Resposta)) = 'M' then
        begin
          // Volta ao Menu
          dmPrincipal.GeraLOG(Conversa, 'Adicionando Outro Produto');
          Conversa.Etapa := 3;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;
        if Trim(UpperCase(Conversa.Resposta)) = 'P' then
        begin
          Conversa.Resposta := '0';
        end;

        try
          Conversa.Resposta := StringReplace(Conversa.Resposta, ' ', '',
            [rfReplaceAll]);
          if Conversa.Resposta = '' then
          begin
            exit;
          end;
          dmPrincipal.GeraLOG(Conversa, 'Produto Configuravel');
          SetLength(ArrayAux, 0);
          if Conversa.Resposta <> '' then
          begin
            ID := Conversa.CategoriaAtual - 1;

            if Conversa.CategoriaAtual = 0 then
            begin
              Conversa.Etapa := 2;
              dmPrincipal.GravaConversa(Conversa);
              MenuPedido(Conversa);
              exit;
            end;

            for I := 1 to Length(Conversa.Resposta) do
            begin
              if Conversa.Resposta[I] = ',' then
              begin
                if Trim(Aux) <> '' then
                begin
                  SetLength(ArrayAux, Length(ArrayAux) + 1);
                  ArrayAux[Length(ArrayAux) - 1] := Aux;
                end;
                Aux := '';
              end
              else
              begin
                Aux := Aux + Conversa.Resposta[I];
              end;
            end;

            if Trim(Aux) <> '' then
            begin
              SetLength(ArrayAux, Length(ArrayAux) + 1);
              ArrayAux[Length(ArrayAux) - 1] := Aux;
            end;
            // Validar aki
            Produto := Produto.LocalizaProduto
              (Conversa.ProdutoCodigoSelecionado, Conversa);
            if Produto.InfoAdicional.ArrayMinimo[ID] = 1 then
            begin
              if Trim(Conversa.Resposta) = 'P' then
              begin
                dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
                  Conversa);
                exit;
              end;
            end;

            if Produto.InfoAdicional.ArrayMaximo[ID] > 0 then
            begin
              if Length(ArrayAux) > Produto.InfoAdicional.ArrayMaximo[ID] then
              begin
                dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
                  Conversa);
                exit;
              end;
            end;

            for I := 0 to Length(ArrayAux) - 1 do
            begin
              if ArrayAux[I] <> '0' then
              begin

                try
                  if StrToInt(ArrayAux[I]) > Produto.InfoAdicional.TotalPorID(ID)
                  then
                  begin
                    dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
                      Conversa);
                    exit;
                  end;

                  NewID := 0;

                  for K := 0 to Length
                    (Produto.InfoAdicional.ArrayItemNome) - 1 do
                  begin

                    if Produto.InfoAdicional.ArrayItemIndex[K] = ID then
                    begin
                      Inc(NewID);
                      try
                        if NewID = StrToInt(ArrayAux[I]) then
                        begin
                          SetLength(Conversa.ArrayCategorias,
                            Length(Conversa.ArrayCategorias) + 1);
                          SetLength(Conversa.ArrayCategoriasItens,
                            Length(Conversa.ArrayCategoriasItens) + 1);
                          SetLength(Conversa.ArrayCategoriasValores,
                            Length(Conversa.ArrayCategoriasValores) + 1);
                          SetLength(Conversa.ArrayCategoriasTipoValor,
                            Length(Conversa.ArrayCategoriasTipoValor) + 1);

                          Conversa.ArrayCategorias
                            [Length(Conversa.ArrayCategorias) - 1] :=
                            Produto.InfoAdicional.ArrayDescricao[ID];

                          Conversa.ArrayCategoriasItens
                            [Length(Conversa.ArrayCategorias) - 1] :=
                            Produto.InfoAdicional.ArrayItemNome[K];
                          Conversa.ArrayCategoriasValores
                            [Length(Conversa.ArrayCategorias) - 1] :=
                            Produto.InfoAdicional.ArrayItemValor[K];
                          Conversa.ArrayCategoriasTipoValor
                            [Length(Conversa.ArrayCategoriasTipoValor)
                            - 1] := 0;
                          AdicionouObrigatorio := True;
                        end;
                      except

                      end;

                    end;

                  end;

                except

                end;

              end
              else
              begin

                if Produto.InfoAdicional.ArrayMinimo[ID] = 0 then
                begin
                  Conversa.Resposta := '';
                  Conversa.CategoriaAtual := Conversa.CategoriaAtual + 1;
                  Conversa.Etapa := 9;
                  dmPrincipal.GravaConversa(Conversa);
                  MenuPedido(Conversa);
                  exit;
                end;

              end;
            end;
            // dmPrincipal.GravaConversa(Conversa);
            if Produto.InfoAdicional.ArrayMaximo[ID] > 0 then
            begin
              if not AdicionouObrigatorio then
              begin
                dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
                  Conversa);
                exit;
              end;

            end;
            Conversa.Resposta := '';
            Conversa.CategoriaAtual := Conversa.CategoriaAtual + 1;
            Conversa.Etapa := 9;
            dmPrincipal.GravaConversa(Conversa);
            MenuPedido(Conversa);
            exit;

          end
          else
          begin
            dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
              Conversa);
            exit;
          end;
        except
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;

        end;
      end;
    11:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Valida Pedido');
        // Valida se tem pedido
        Conversa.Etapa := 0;
        Conversa.Situacao := VerificaUltimoPedido;
        Conversa.Resposta := '';
        dmPrincipal.GravaConversa(Conversa);
        dmPrincipal.GestorInteracao(Conversa);
        exit;
      end;
    12:
      begin
        // Pizza
        dmPrincipal.GeraLOG(Conversa, 'Pizza');
        // Validar aki o tipo do produto
        // TTipoProduto = (Simples, AdicionarRemover, Configuravel, Pizza);
        Mensagem := '';
        Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
          Conversa);

        if Conversa.ProdutoCodigoSelecionado = 0 then
        begin
          Conversa.Situacao := Finalizado;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end;

        if Length(Produto.InfoPizza.ArrayBordaIndex) > 0 then
        begin
          Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
            Conversa);
          Mensagem := '*--- SELECIONE A BORDA ---*' +
            MENSAGEM_QUEBRA_LINHA_DUPLA;
          for I := 1 to Length(Produto.InfoPizza.ArrayBordaIndex) do
          begin
            Mensagem := Mensagem + '*' + IntToStr(I) + '* - ' +
              Produto.InfoPizza.RetornaBordaDescricao(I);
            if Produto.InfoPizza.RetornaBordaValor(I) > 0 then
              Mensagem := Mensagem + ' - R$ ' + FormatFloat('#0.00',
                Produto.InfoPizza.RetornaBordaValor(I));
            Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA;
          end;
        end;

        Conversa.Etapa := 13;
        Conversa.Resposta := '';
        if Mensagem <> '' then
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
          exit;
        end
        else
        begin
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;

      end;
    13:
      begin
        // Validar se a resposta é igual a VAZIO

        Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
          Conversa);

        if Trim(Conversa.Resposta) = '' then
        begin

          dmPrincipal.CriaQRY('SABORES').Close;
          dmPrincipal.CriaQRY('SABORES').SQL.Clear;
          dmPrincipal.CriaQRY('SABORES')
            .SQL.Add('SELECT * FROM produto_pizza where codigo_produto = ' +
            IntToStr(Conversa.ProdutoCodigoSelecionado));
          dmPrincipal.CriaQRY('SABORES').Open;

          if dmPrincipal.CriaQRY('SABORES').FieldByName('quantidade_sabores')
            .AsInteger > 1 then
          begin
            Mensagem := '*--- SELECIONE OS SABORES ---*' +
              MENSAGEM_QUEBRA_LINHA;
          end
          else
          begin
            Mensagem := '*--- SELECIONE O SABOR ---*' + MENSAGEM_QUEBRA_LINHA;
          end;

          case dm.DADOS_EMPRESA.FieldByName('TIPO_VALOR_PIZZA').AsInteger of
            3:
              begin
                if dmPrincipal.CriaQRY('SABORES')
                  .FieldByName('quantidade_sabores').AsInteger > 1 then
                begin
                  Mensagem := Mensagem + '*Selecione ' +
                    IntToStr(dmPrincipal.CriaQRY('SABORES')
                    .FieldByName('quantidade_sabores').AsInteger) +
                    ' sabores, separando cada sabor por vírgula!*' +
                    MENSAGEM_QUEBRA_LINHA;
                  Mensagem := Mensagem + MONO_ESPACADA +
                    'Informe os números referente aos sabores desejado, separando por vírgula!'
                    + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA_DUPLA;
                end
                else
                begin
                  Mensagem := Mensagem + '*Selecione ' +
                    IntToStr(dmPrincipal.CriaQRY('SABORES')
                    .FieldByName('quantidade_sabores').AsInteger) + ' sabor*!' +
                    MENSAGEM_QUEBRA_LINHA;
                  Mensagem := Mensagem + MONO_ESPACADA +
                    'Informe o número referente ao sabor desejado!' +
                    MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA_DUPLA;
                end;

              end
          else
            begin
              if dmPrincipal.CriaQRY('SABORES')
                .FieldByName('quantidade_sabores').AsInteger > 1 then
              begin
                MensagemExtra := '*Selecione até ' +
                  IntToStr(dmPrincipal.CriaQRY('SABORES')
                  .FieldByName('quantidade_sabores').AsInteger) + ' sabores*' +
                  MENSAGEM_QUEBRA_LINHA;
                MensagemExtra := MONO_ESPACADA +
                  'Informe os números referente aos sabores desejado, separando por vírgula!'
                  + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA_DUPLA;
              end
              else
              begin
                Mensagem := Mensagem + '*Selecione ' +
                  IntToStr(dmPrincipal.CriaQRY('SABORES')
                  .FieldByName('quantidade_sabores').AsInteger) + ' sabor*' +
                  MENSAGEM_QUEBRA_LINHA;
                Mensagem := Mensagem + MONO_ESPACADA +
                  'Informe os números referente aos sabores desejado, separando por vírgula!'
                  + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA_DUPLA;
              end;

            end;

          end;

          TipoSabor := '';

          // Seleciona os Sabores
          for I := 1 to Length(Produto.InfoPizza.ArraySaborIndex) - 1 do
          begin
            if TipoSabor = '' then
            begin
              TipoSabor := Produto.InfoPizza.RetornaSaborTipoSabor(I);
              Mensagem := Mensagem + MONO_ESPACADA + '--- ' + Trim(TipoSabor) +
                ' ---' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
            end
            else
            begin
              if TipoSabor <> Produto.InfoPizza.RetornaSaborTipoSabor(I) then
              begin
                TipoSabor := Produto.InfoPizza.RetornaSaborTipoSabor(I);
                Mensagem := Mensagem + MONO_ESPACADA + '--- ' + Trim(TipoSabor)
                  + ' ---' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
              end;
            end;

            case dm.DADOS_EMPRESA.FieldByName('TIPO_VALOR_PIZZA').AsInteger of
              3:
                begin
                  Mensagem := Mensagem + '*' + FormatFloat(FORMATA_CAMPO_MENU,
                    I) + ' - ' + Produto.InfoPizza.RetornaSaborNome(I) +
                    ' - R$ ' + FormatFloat('#0.00',
                    Produto.InfoPizza.RetornaSaborValor(I) *
                    dmPrincipal.CriaQRY('SABORES')
                    .FieldByName('quantidade_sabores').AsInteger) + '*' +
                    MENSAGEM_QUEBRA_LINHA;
                end
            else
              begin
                Mensagem := Mensagem + '*' + FormatFloat(FORMATA_CAMPO_MENU, I)
                  + ' - ' + Produto.InfoPizza.RetornaSaborNome(I) + ' - R$ ' +
                  FormatFloat('#0.00', Produto.InfoPizza.RetornaSaborValor(I)) +
                  '*' + MENSAGEM_QUEBRA_LINHA;
              end;
            end;

            if Produto.InfoPizza.RetornaSaborDescricao(I) <> '' then
            begin
              Mensagem := Mensagem + MONO_ESPACADA +
                Trim(Produto.InfoPizza.RetornaSaborDescricao(I)) + MONO_ESPACADA
                + MENSAGEM_QUEBRA_LINHA;
            end;

          end;

          Conversa.Etapa := 14;
          //
          // case dm.DADOS_EMPRESA.FieldByName('TIPO_VALOR_PIZZA').AsInteger of
          // 3:
          // begin
          // Mensagem := Mensagem + MONO_ESPACADA +
          // 'informar separado por vírgula!' + MONO_ESPACADA;
          // end
          // else
          // begin
          // Mensagem := Mensagem + MONO_ESPACADA +
          // 'Caso queira mais de um sabor, informar separado por vírgula!' +
          // MONO_ESPACADA;
          // end;
          // end;
          { Caso queira XX,XX }

          Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA + MensagemExtra +
            MENSAGEM_QUEBRA_LINHA;

          if Usar_Novo_Botao then
          begin
            subMensagem := 'Caso queira ' + MONO_ESPACADA +
              Trim(Produto.InfoPizza.RetornaSaborNome(1)) + ' e ' +
              Trim(Produto.InfoPizza.RetornaSaborNome(2)) + MONO_ESPACADA +
              ' digite *1,2* ou clique no MENU';
            dmPrincipal.EnviaBotao(Conversa, Mensagem, subMensagem,
              ['MENU'], ['M']);
          end
          else
          begin
            Mensagem := Mensagem + 'Caso queira ' + MONO_ESPACADA +
              Trim(Produto.InfoPizza.RetornaSaborNome(1)) + ' e ' +
              Trim(Produto.InfoPizza.RetornaSaborNome(2)) + MONO_ESPACADA +
              ' digite *1,2* ou digite no *M*';
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
          end;

          exit;
        end
        else
        begin
          // Seleciona a Borda
        end;

      end;
    14:
      begin
        // Caso de algum erro, conversa ela e reiniciada
        if UpperCase(Trim(Conversa.Resposta)) = 'M' then
        begin
          Conversa.Etapa := 2;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end;
        Conversa.Resposta := StringReplace(Conversa.Resposta, ' ', '',
          [rfReplaceAll]);
        if Conversa.ProdutoCodigoSelecionado = 0 then
        begin
          Conversa.Etapa := 0;
          Conversa.Situacao := Finalizado;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;
        end;

        Produto := Produto.LocalizaProduto(Conversa.ProdutoCodigoSelecionado,
          Conversa);

        SeparadoPorVirgula := Produto.SeparadoPorVirgula(Conversa.Resposta);

        if Length(SeparadoPorVirgula.Separados) = 0 then
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;

        // dmPrincipal.CriaQRY('SABORES').Close;
        // dmPrincipal.CriaQRY('SABORES').SQL.Clear;
        // dmPrincipal.CriaQRY('SABORES')
        // .SQL.Add('SELECT * FROM produto_pizza where codigo_produto = ' +
        // IntToStr(Conversa.ProdutoCodigoSelecionado));
        // dmPrincipal.CriaQRY('SABORES').Open;

        if Produto.InfoPizza.TotalSabores > 0 then
        begin
          if Length(SeparadoPorVirgula.Separados) > Produto.InfoPizza.MaximoSabores
          then
          begin
            Conversa.Etapa := 13;
            Conversa.Resposta := '';
            dmPrincipal.GravaConversa(Conversa);
            MenuPedido(Conversa);
            exit;
          end
          else
          begin
            case dm.DADOS_EMPRESA.FieldByName('TIPO_VALOR_PIZZA').AsInteger of
              3:
                begin
                  for I := 0 to Length(SeparadoPorVirgula.Separados) - 1 do
                  begin
                    if SeparadoPorVirgula.Separados[I] > Produto.InfoPizza.TotalSabores
                    then
                    begin
                      Mensagem := '*--- ATENÇÃO ---*' + MENSAGEM_QUEBRA_LINHA;
                      Mensagem := Mensagem +
                        'Você selecionou um sabor que não existe!';
                      dmPrincipal.Enviamensagem(Conversa.Etapa,
                        Conversa.Pergunta, Conversa);
                      exit;
                    end;
                  end;

                  if Length(SeparadoPorVirgula.Separados) <> Produto.InfoPizza.MaximoSabores
                  then
                  begin
                    Mensagem := '*--- ATENÇÃO ---*' + MENSAGEM_QUEBRA_LINHA;
                    Mensagem := Mensagem + 'Você deve selecionar ' +
                      IntToStr(Produto.InfoPizza.MaximoSabores) + ' sabor(es)!';
                    dmPrincipal.Enviamensagem(Conversa, Mensagem);
                    exit;
                  end;

                end;
            end;

          end;

        end
        else
        begin
          Conversa.Etapa := 2;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          exit;
        end;
        {
          if dmPrincipal.CriaQRY('SABORES').RecordCount > 0 then
          begin
          if Length(SeparadoPorVirgula.Separados) >
          dmPrincipal.CriaQRY('SABORES').FieldByName('quantidade_sabores').AsInteger
          then
          begin
          Conversa.Etapa := 13;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
          end
          else
          begin
          case dm.DADOS_EMPRESA.FieldByName('TIPO_VALOR_PIZZA').AsInteger of
          3:
          begin
          // dmPrincipal.CriaQRY('TOTSAB').Close;
          // dmPrincipal.CriaQRY('TOTSAB').SQL.Clear;
          // dmPrincipal.CriaQRY('TOTSAB')
          // .SQL.Add('SELECT count(*) as tot FROM sabores_completo where id_produto = '
          // + IntToStr(Produto.Codigo));
          // dmPrincipal.CriaQRY('TOTSAB').Open;
          //
          // for I := 0 to Length(SeparadoPorVirgula.Separados) - 1 do
          // begin
          // if SeparadoPorVirgula.Separados[I] >
          // dmPrincipal.CriaQRY('TOTSAB').FieldByName('tot').AsInteger
          // then
          // begin
          // Mensagem := '*--- ATENÇÃO ---*' + MENSAGEM_QUEBRA_LINHA;
          // Mensagem := Mensagem +
          // 'Você selecionou um sabor que não existe!';
          // dmPrincipal.Enviamensagem(Conversa.Etapa,
          // Conversa.Pergunta, Conversa);
          // exit;
          // end;
          //
          // end;

          // if Length(SeparadoPorVirgula.Separados) <>
          // dmPrincipal.CriaQRY('SABORES')
          // .FieldByName('quantidade_sabores').AsInteger then
          // begin
          // Mensagem := '*--- ATENÇÃO ---*' + MENSAGEM_QUEBRA_LINHA;
          // Mensagem := Mensagem + 'Você deve selecionar ' +
          // dmPrincipal.CriaQRY('SABORES')
          // .FieldByName('quantidade_sabores').AsString +
          // ' sabor(es)!';
          // dmPrincipal.Enviamensagem(Conversa, Mensagem);
          // if Length(SeparadoPorVirgula.Separados) <>
          // dmPrincipal.CriaQRY('SABORES')
          // .FieldByName('quantidade_sabores').AsInteger then
          // begin
          // dmPrincipal.Enviamensagem(Conversa.Etapa,
          // Conversa.Pergunta, Conversa);
          // exit;
          // end;
          // end;
          end;
          end;
          end;

          end
          else
          begin
          Conversa.Etapa := 2;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          exit;
          end; }

        SetLength(Conversa.ArrayCategorias,
          Length(SeparadoPorVirgula.Separados));
        SetLength(Conversa.ArrayCategoriasItens,
          Length(SeparadoPorVirgula.Separados));
        SetLength(Conversa.ArrayCategoriasValores,
          Length(SeparadoPorVirgula.Separados));
        SetLength(Conversa.ArrayCategoriasTipoValor,
          Length(SeparadoPorVirgula.Separados));

        for I := 0 to Length(SeparadoPorVirgula.Separados) - 1 do
        begin
          Conversa.ArrayCategorias[I] := Produto.InfoPizza.RetornaSaborTipoSabor
            (SeparadoPorVirgula.Separados[I]);
          Conversa.ArrayCategoriasItens[I] := Produto.InfoPizza.RetornaSaborNome
            (SeparadoPorVirgula.Separados[I]);
          Conversa.ArrayCategoriasValores[I] :=
            Produto.InfoPizza.RetornaSaborValor
            (SeparadoPorVirgula.Separados[I]);
          Conversa.ArrayCategoriasTipoValor[I] :=
            dm.DADOS_EMPRESA.FieldByName('TIPO_VALOR_PIZZA').AsInteger;
        end;

        if Length(Produto.InfoAdicional.ArrayDescricao) > 0 then
        begin
          Conversa.QuantidadeCategoria :=
            Length(Produto.InfoAdicional.ArrayDescricao) + 1;
          Conversa.CategoriaAtual := 1;
          Conversa.Etapa := 9;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
          exit;
        end
        else
        begin
          Conversa.Etapa := 6;
          Conversa.Resposta := '1';
          dmPrincipal.GravaConversa(Conversa);
          MenuPedido(Conversa);
        end;

        // dmPrincipal.CriaQRY('CONFIGURAVEL').Close;
        // dmPrincipal.CriaQRY('CONFIGURAVEL').SQL.Clear;
        // dmPrincipal.CriaQRY('CONFIGURAVEL')
        // .SQL.Add('SELECT * FROM pro_adi_personalizado where id_produto = ' +
        // IntToStr(Conversa.ProdutoCodigoSelecionado));
        // dmPrincipal.CriaQRY('CONFIGURAVEL').Open;
        // if dmPrincipal.CriaQRY('CONFIGURAVEL').RecordCount > 0 then
        // begin
        // Conversa.MinimoCategoria := dmPrincipal.CriaQRY('CONFIGURAVEL')
        // .FieldByName('qtd_minima').AsInteger;
        // Conversa.MaximoCategoria := dmPrincipal.CriaQRY('CONFIGURAVEL')
        // .FieldByName('qtd_maxima').AsInteger;
        // Conversa.QuantidadeCategoria := dmPrincipal.CriaQRY('CONFIGURAVEL')
        // .RecordCount;
        //
        // end
        // else
        // begin
        //
        // Conversa.Etapa := 6;
        // Conversa.Resposta := '1';
        // dmPrincipal.GravaConversa(Conversa);
        // MenuPedido(Conversa);
        // exit;
        // end;
      end;

  end;
end;

function TMenu.MontaMenu(Conversa: TBotConversa): String;
var
  ID: Integer;
  Tabela: TFDTable;
begin
  dmPrincipal.CriaQRY('MENU').Close;
  dmPrincipal.CriaQRY('MENU').SQL.Clear;

  case Conversa.Entrega of
    VemBuscar:
      dmPrincipal.CriaQRY('MENU').SQL.Add(SQLMenuVemBuscar);
    Delivery:
      dmPrincipal.CriaQRY('MENU').SQL.Add(SQLMenuDelivery);
  end;

  dmPrincipal.CriaQRY('MENU').Open;

  Result := '*' + dm.DADOS_EMPRESA.FieldByName('NOME').AsString + '*' +
    MENSAGEM_QUEBRA_LINHA;
  Result := Result + '*--- FAÇA JÁ O SEU PEDIDO ---*' +
    MENSAGEM_QUEBRA_LINHA_DUPLA;

  ID := 0;

  while not dmPrincipal.CriaQRY('MENU').Eof do
  begin

    if dmPrincipal.CriaQRY('MENU').FieldByName('total').AsInteger > 0 then
    begin

      Inc(ID);
      Result := Result + '*' + FormatFloat(FORMATA_CAMPO_MENU, ID) + ' - ' +
        Trim(dmPrincipal.CriaQRY('MENU').FieldByName('descricao').AsString) +
        '*' + MENSAGEM_QUEBRA_LINHA;

    end;
    dmPrincipal.CriaQRY('MENU').Next;
  end;
  PodeFinalizar := False;
  Conversa.CodigoPedido := VerificaPedidoAtual(Conversa);
  Tabela := dmPrincipal.CriaTabela('pedido');
  if Tabela.Locate('codigo', IntToStr(Conversa.CodigoPedido), []) then
  begin

    if Tabela.FieldByName('valor_total_pedido').AsFloat >
      dm.DADOS_EMPRESA.FieldByName('pedido_minimo').AsFloat then
    begin
      PodeFinalizar := True;
      if not Usar_Novo_Botao then
      begin

        Result := Result + MENSAGEM_QUEBRA_LINHA;
        Result := Result + '*F* para *FINALIZAR*' + MENSAGEM_QUEBRA_LINHA;
        Result := Result + '*C* para *CANCELAR*' + MENSAGEM_QUEBRA_LINHA;
        Result := Result + '*A* para *ALTERAR/REMOVER*' + MENSAGEM_QUEBRA_LINHA;

      end;

    end;
  end;

  Tabela.Free;
  // Verificar aki se o cliente tem pedido iniciado

  // if VerificaPedidoAtual then

end;

function TMenu.MontaProdutos(Conversa: TBotConversa): String;
var
  ID: Integer;

  Produtos: TProduto;

begin
  qtdProdutos := 0;
  dmPrincipal.CriaQRY('AUX').Close;
  dmPrincipal.CriaQRY('AUX').SQL.Clear;
  Conversa.SQLCategoria :=
    'SELECT codigo,nome_produto,valor_venda,controle_estoque,ativo,observacao,adicional_personalizado FROM produto where codigo_grupo = '
    + IntToStr(Conversa.ProdutoCategoriaSelecionada) +
    ' order by ativo desc,codigo_interno';
  dmPrincipal.CriaQRY('AUX').SQL.Add(Conversa.SQLCategoria);
  dmPrincipal.CriaQRY('AUX').Open;
  qtdProdutos := dmPrincipal.CriaQRY('AUX').RecordCount;
  if qtdProdutos = 0 then
  begin
    Result := '';
    exit;
  end;

  Result := '*Digite o código correspondente a(o) ' +
    Trim(Conversa.CategoriaDescricao) + '*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
  ID := 0;

  while not dmPrincipal.CriaQRY('AUX').Eof do
  begin

    Produtos := Produtos.LocalizaProduto(dmPrincipal.CriaQRY('AUX')
      .FieldByName('codigo').AsInteger, Conversa);

    if Produtos.Ativo then
    begin

      Inc(ID);
      Result := Result + '*' + FormatFloat(FORMATA_CAMPO_MENU, ID) + ' - ' +
        Trim(Produtos.Nome) + '*';

      if (Produtos.Tipo <> Pizza) and (Produtos.Valor > 0) then
        Result := Result + ' *R$ ' + FormatFloat('#0.00', Produtos.Valor) + '*';

      Result := Result + MENSAGEM_QUEBRA_LINHA;
      if Produtos.Descricao = ' ' then
        Result := Result + MENSAGEM_QUEBRA_LINHA
      else
      begin
        if Trim(Produtos.Descricao) <> '' then
        begin
          Result := Result + MONO_ESPACADA + Trim(Produtos.Descricao) +
            MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
        end;
      end;
    end
    else
    begin
      if Produtos.ValorComBaseAdicional then
      begin
        case Produtos.Tipo of
          Configuravel:
            begin
              Inc(ID);
              Result := Result + '*' + FormatFloat(FORMATA_CAMPO_MENU, ID) +
                ' - ' + Produtos.Nome + '*';
              if Produtos.Valor > 0 then
                Result := Result + ' R$ ' + FormatFloat('#0.00', Produtos.Valor)
                  + MENSAGEM_QUEBRA_LINHA
              else
                Result := Result + MENSAGEM_QUEBRA_LINHA;
            end;

        end;
      end;

    end;

    dmPrincipal.CriaQRY('AUX').Next;
  end;

  if ID = 0 then
  begin
    Result := '';
    exit;
  end;
  if not Usar_Novo_Botao then
  begin
    Result := Result + MENSAGEM_QUEBRA_LINHA +
      'Digite *M* para retornar ao menu inícial';
  end;

end;

function TMenu.RetornaCodigoCategoriaSelecionada(Conversa: TBotConversa)
  : TBotConversa;
Var
  ID: Integer;
begin
  Result := Conversa;
  dmPrincipal.CriaQRY('AUX').Close;
  dmPrincipal.CriaQRY('AUX').SQL.Clear;
  case Conversa.Entrega of
    VemBuscar:
      dmPrincipal.CriaQRY('AUX').SQL.Add(SQLMenuVemBuscar);
    Delivery:
      dmPrincipal.CriaQRY('AUX').SQL.Add(SQLMenuDelivery);
  end;
  dmPrincipal.CriaQRY('AUX').Open;
  ID := 0;
  try
    while not dmPrincipal.CriaQRY('AUX').Eof do
    begin
      if dmPrincipal.CriaQRY('AUX').FieldByName('total').AsInteger > 0 then
      begin
        Inc(ID);
        if ID = StrToInt(Conversa.Resposta) then
        begin
          Result.ProdutoCategoriaSelecionada := dmPrincipal.CriaQRY('AUX')
            .FieldByName('codigo').AsInteger;
          Result.CategoriaDescricao := dmPrincipal.CriaQRY('AUX')
            .FieldByName('descricao').AsString;
          exit;
        end;
      end;
      dmPrincipal.CriaQRY('AUX').Next;
    end;
  except
    Result.ProdutoCategoriaSelecionada := 0;
    Result.CategoriaDescricao := '';
    exit;
  end;
  Result.ProdutoCategoriaSelecionada := 0;
  Result.CategoriaDescricao := '';
  exit;
end;

function TMenu.RetornaCodigoProdutoSelecionada(Conversa: TBotConversa)
  : TBotConversa;
var
  ID: Integer;
  Produtos: TProduto;
begin
  Result := Conversa;
  dmPrincipal.CriaQRY('AUX').Close;
  dmPrincipal.CriaQRY('AUX').SQL.Clear;
  Conversa.SQLCategoria :=
    'SELECT codigo,nome_produto,valor_venda,controle_estoque,ativo,observacao,adicional_personalizado FROM produto where codigo_grupo = '
    + IntToStr(Conversa.ProdutoCategoriaSelecionada) +
    ' order by ativo desc,codigo_interno';
  dmPrincipal.CriaQRY('AUX').SQL.Add(Conversa.SQLCategoria);
  dmPrincipal.CriaQRY('AUX').Open;

  if dmPrincipal.CriaQRY('AUX').RecordCount = 0 then
  begin
    Conversa.ProdutoCategoriaSelecionada := 0;
    Result := Conversa;
    exit;
  end;

  ID := 0;
  Result.ProdutoCodigoSelecionado := 0;
  while not dmPrincipal.CriaQRY('AUX').Eof do
  begin

    Produtos := Produtos.LocalizaProduto(dmPrincipal.CriaQRY('AUX')
      .FieldByName('codigo').AsInteger, Conversa);

    if Produtos.Ativo then
    begin

      Inc(ID);
      if ID = StrToInt(Conversa.Resposta) then
      begin
        Result.ProdutoCodigoSelecionado := dmPrincipal.CriaQRY('AUX')
          .FieldByName('codigo').AsInteger;
        exit;
      end;

    end
    else
    begin
      case Produtos.Tipo of

        Configuravel:
          begin
            Inc(ID);
            if ID = StrToInt(Conversa.Resposta) then
            begin
              Result.ProdutoCodigoSelecionado := dmPrincipal.CriaQRY('AUX')
                .FieldByName('codigo').AsInteger;
              exit;
            end;
          end;

      end;

    end;

    dmPrincipal.CriaQRY('AUX').Next;
  end;
end;

function TMenu.SQLMenuDelivery: String;
begin
  Result := 'SELECT tp.codigo, upper(tp.descricao) as descricao, (select sum(codigo) from produto where codigo_grupo = tp.codigo) as total FROM tipo_produto as tp where tp.visivel_delivery = 1 order by tp.ordem';
end;

function TMenu.SQLMenuVemBuscar: String;
begin
  Result := 'SELECT tp.codigo, upper(tp.descricao) as descricao, (select sum(codigo) from produto where codigo_grupo = tp.codigo) as total FROM tipo_produto as tp where tp.visivel_vem_buscar = 1 order by tp.ordem';
end;

function TMenu.VerificaPedidoAtual(Conversa: TBotConversa): Integer;
var
  Tabela: TFDTable;
begin
  Tabela := dmPrincipal.CriaTabela('pedido');

  if Tabela.Locate
    ('codigo_cliente;codigo_cliente_endereco;data_pedido;status;pedido_impresso;origem',
    VarArrayOf([IntToStr(Conversa.CodigoClienteInterno),
    IntToStr(Conversa.CodigoEndereco), DateToStr(date), '-1', '1', '1']), [])
  then
  begin

  end
  else
  begin
    Tabela.Insert;
    Tabela.FieldByName('codigo').AsInteger := dmPrincipal.GerarID('pedido',
      'codigo');
    Tabela.FieldByName('codigo_pedido_dia').AsInteger := 0;
    Tabela.FieldByName('codigo_cliente').AsInteger :=
      Conversa.CodigoClienteInterno;
    Tabela.FieldByName('codigo_cliente_endereco').AsInteger :=
      Conversa.CodigoEndereco;
    Tabela.FieldByName('data_pedido').AsDateTime := date;
    Tabela.FieldByName('hora_pedido').AsDateTime := Time;
    Tabela.FieldByName('status').AsInteger := -1;
    Tabela.FieldByName('valor_pedido').AsInteger := 0;
    Tabela.FieldByName('valor_taxa_entrega').AsInteger := 0;
    Tabela.FieldByName('valor_total_pedido').AsInteger := 0;
    Tabela.FieldByName('pedido_impresso').AsInteger := 1;
    Tabela.FieldByName('origem').AsInteger := 1;
    Tabela.Post;
  end;
  Result := Tabela.FieldByName('codigo').AsInteger;
  Tabela.Free;
end;

end.
