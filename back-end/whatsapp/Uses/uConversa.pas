unit uConversa;

interface

uses uBotConversa, FireDAC.Comp.Client, uPrincipal, System.SysUtils;

type
  TGeralConversa = class
  public
    function EtapaConversa(Conversa: TBotConversa): TBotConversa;
    procedure GravaEtapaConversa(Conversa: TBotConversa);
    function idSituacaoAtual(Situacao: TSituacaoConversa): integer;
    function idTipoPedidoAual(TipoPedido: TTipoEntrega): integer;
    function TipoSitucacao(Codigo: integer): TSituacaoConversa;

    function ClienteCadastrado(Conversa: TBotConversa): Boolean;

    function DadosDoCliente(Conversa: TBotConversa): TBotConversa;

    function DadosNovoCliente(Conversa: TBotConversa): TBotConversa;

    procedure ConversaMensagem(Conversa: TBotConversa; Status: integer);

  private
    function ConsultaQRY(Nome: String): TFDQuery;
  end;

implementation

{ TGeralConversa }

uses uClassEndereco, uClassEnderecoUtil;

function TGeralConversa.ClienteCadastrado(Conversa: TBotConversa): Boolean;
begin
  // Verifica se o cliente já é cadastrado!

  ConsultaQRY('CLIENTE_CADASTRADO').Close;
  ConsultaQRY('CLIENTE_CADASTRADO').SQL.Clear;
  ConsultaQRY('CLIENTE_CADASTRADO')
    .SQL.Add('SELECT * FROM cliente where celular_wpp = ' +
    QuotedStr(Conversa.Telefone));
  ConsultaQRY('CLIENTE_CADASTRADO').Open;

  Result := ConsultaQRY('CLIENTE_CADASTRADO').RecordCount > 0;

end;

function TGeralConversa.ConsultaQRY(Nome: String): TFDQuery;
begin
  Result := dmPrincipal.CriaQRY(Nome);
end;

procedure TGeralConversa.ConversaMensagem(Conversa: TBotConversa;
  Status: integer);
begin

  if dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id')
    .Locate('idmensagem', FloatToStr(Conversa.IDMensagem), []) then
  begin
    dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id').Edit;
  end
  else
  begin
    dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id').Insert;
    dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id').FieldByName('id')
      .AsInteger := dmPrincipal.GerarID('conversa_backup_mensagem', 'id');
    dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id')
      .FieldByName('idmensagem').AsFloat := Conversa.IDMensagem;
  end;
  dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id').FieldByName('status')
    .AsInteger := Status;
  dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id').FieldByName('etapa')
    .AsInteger := Conversa.Etapa;
  dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id')
    .FieldByName('situacao').AsInteger := idSituacaoAtual(Conversa.Situacao);
  dmPrincipal.CriaTabela('conversa_backup_mensagem', 'id').Post;
end;

function TGeralConversa.DadosDoCliente(Conversa: TBotConversa): TBotConversa;
begin
  Result := Conversa;
  ConsultaQRY('CONSULTA_CLIE').Close;
  ConsultaQRY('CONSULTA_CLIE').SQL.Clear;
  ConsultaQRY('CONSULTA_CLIE')
    .SQL.Add('SELECT * FROM cliente where celular_wpp = ' +
    QuotedStr(Conversa.Telefone));
  ConsultaQRY('CONSULTA_CLIE').Open;
  Result.ClienteLocalizado := False;
  if ConsultaQRY('CONSULTA_CLIE').RecordCount > 0 then
  begin
    Result.CodigoClienteInterno := ConsultaQRY('CONSULTA_CLIE')
      .FieldByName('codigo').AsInteger;
    Result.Nome := ConsultaQRY('CONSULTA_CLIE').FieldByName('nome').AsString;
    Result.CPF := ConsultaQRY('CONSULTA_CLIE').FieldByName('cpf').AsString;
    Result.DataNascimento := ConsultaQRY('CONSULTA_CLIE')
      .FieldByName('data_nascimento').AsDateTime;
    Result.ClienteLocalizado := True;
    exit;
  end;

end;

procedure TGeralConversa.GravaEtapaConversa(Conversa: TBotConversa);
begin
  dmPrincipal.GravaConversa(Conversa);
end;

function TGeralConversa.idSituacaoAtual(Situacao: TSituacaoConversa): integer;
begin
  case Situacao of
    Aguardando:
      Result := 1;
    NovoCliente:
      Result := 2;
    NovoPedido:
      Result := 3;
    MenuPedido:
      Result := 4;
    AdicionandoProduto:
      Result := 5;
    AdicionandoPizza:
      Result := 6;
    SelecionandoFormaPedido:
      Result := 7;
    FinalizandoPedido:
      Result := 8;
    CaschBack:
      Result := 9;
    Finalizado:
      Result := 10;
    VerificaUltimoPedido:
      Result := 11;
    EnderecoCliente:
      Result := 12;
    AlteraRemove:
      Result := 13;
    Cancelamento:
      Result := 14;
    AtendimentoHumano:
      Result := 15;
  end;
end;

function TGeralConversa.idTipoPedidoAual(TipoPedido: TTipoEntrega): integer;
begin
  case TipoPedido of
    VemBuscar:
      Result := 1;
    Delivery:
      Result := 2;
  end;
end;

function TGeralConversa.TipoSitucacao(Codigo: integer): TSituacaoConversa;
begin
  case Codigo of
    1:
      Result := Aguardando;
    2:
      Result := NovoCliente;
    3:
      Result := NovoPedido;
    4:
      Result := MenuPedido;
    5:
      Result := AdicionandoProduto;
    6:
      Result := AdicionandoPizza;
    7:
      Result := SelecionandoFormaPedido;
    8:
      Result := FinalizandoPedido;
    9:
      Result := CaschBack;
    10:
      Result := Finalizado;
    11:
      Result := VerificaUltimoPedido;
    12:
      Result := EnderecoCliente;
    13:
      Result := AlteraRemove;
    14:
      Result := Cancelamento;
    15:
      Result := AtendimentoHumano;
  end;
end;

function TGeralConversa.DadosNovoCliente(Conversa: TBotConversa): TBotConversa;
var
  I: integer;
  auxNome: String;
  NomeArray: Array of String;

  txMensagem: String;
  SQL: String;

begin

  Result := Conversa;
  case Conversa.Etapa of
    0:
      begin
        // Validar aki o nome
        dmPrincipal.GeraLOG(Conversa, 'Validando Nome');
        if length(trim(Conversa.Nome)) > 0 then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Validando Nome 1');

          for I := 1 to length(Conversa.Nome) do
          begin
            dmPrincipal.GeraLOG(Conversa, 'Validando Nome FOR');
            if Conversa.Nome[I] = ' ' then
            begin
              SetLength(NomeArray, length(NomeArray) + 1);
              NomeArray[length(NomeArray) - 1] := auxNome;
              auxNome := '';
            end
            else
              auxNome := auxNome + Conversa.Nome[I];
          end;

          SetLength(NomeArray, length(NomeArray) + 1);
          NomeArray[length(NomeArray) - 1] := auxNome;
          dmPrincipal.GeraLOG(Conversa, 'Validando Nome SLA');
          for I := 0 to length(NomeArray) - 1 do
          begin
            dmPrincipal.GeraLOG(Conversa, 'Validando Nome ARRAY');
            ConsultaQRY('VALIDA_NOME').Close;
            ConsultaQRY('VALIDA_NOME').SQL.Clear;
            ConsultaQRY('VALIDA_NOME')
              .SQL.Add('SELECT * FROM nomes_validos where nome = ' +
              QuotedStr(NomeArray[I]));
            ConsultaQRY('VALIDA_NOME').Open;
            if ConsultaQRY('VALIDA_NOME').RecordCount > 0 then
            begin
              dmPrincipal.GeraLOG(Conversa, 'Validando Nome VALIDA');
              if Conversa.NomeValido = '' then
                Conversa.NomeValido := NomeArray[I]
              else
                Conversa.NomeValido := Conversa.NomeValido + ' ' + NomeArray[I];

              dmPrincipal.GeraLOG(Conversa, 'Validando Nome NOME VALIDO');
              // NomeValido
              // Criar uma variavel pra adicionar o nome valido
            end
            else
            begin
              dmPrincipal.GeraLOG(Conversa,
                'Validando Nome VEIO EM OUTRO LUGA');
              if I = 1 then
              begin
                dmPrincipal.GeraLOG(Conversa, 'Validando Nome PQP');
                Conversa.Etapa := 1;
                DadosNovoCliente(Conversa);
                exit;
              end;

            end;
            // Validar aki se o nome esta cadastrado
          end;

          if trim(Conversa.NomeValido) = '' then
          begin
            dmPrincipal.GeraLOG(Conversa, 'Validando Nome CU');
            // ETAPA
            Conversa.Etapa := 1;
            Result := DadosNovoCliente(Conversa);
            exit;
          end
          else
          begin
            dmPrincipal.GeraLOG(Conversa, 'Validando Nome TST');
            Result.Resposta := Conversa.Nome;
            Result.Etapa := 3;
            DadosNovoCliente(Result);
            exit;
          end;
        end
        else
        begin
          Conversa.Etapa := 1;
          DadosNovoCliente(Conversa);
          exit;
        end;
      end;
    1:
      begin
        Result.Etapa := 2;
        dmPrincipal.GeraLOG(Conversa, 'Aguardando o Nome');
        txMensagem := '*Para que possamos iniciar informe seu nome completo.*';
        dmPrincipal.Enviamensagem(Result.Etapa, txMensagem, Result);
      end;
    2:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Aguardando o Nome');
        Conversa.Resposta := UpperCase(Conversa.Resposta);
        if length(trim(Conversa.Resposta)) > 2 then
        begin

          for I := 1 to length(Conversa.Resposta) do
          begin
            if Conversa.Resposta[I] = ' ' then
            begin
              SetLength(NomeArray, length(NomeArray) + 1);
              NomeArray[length(NomeArray) - 1] := auxNome;
              auxNome := '';
            end
            else
              auxNome := auxNome + Conversa.Resposta[I];
          end;
          SetLength(NomeArray, length(NomeArray) + 1);
          NomeArray[length(NomeArray) - 1] := auxNome;
          try
            for I := 0 to 3 do
            begin

              if NomeArray[I] <> '' then
              begin
                try
                  SQL := 'insert into nomes_validos (nome) values (' +
                    QuotedStr(UpperCase(NomeArray[I])) + ')';

                  ConsultaQRY('INSERT').Close;
                  ConsultaQRY('INSERT').SQL.Clear;
                  ConsultaQRY('INSERT').SQL.Add(SQL);
                  ConsultaQRY('INSERT').ExecSQL;
                except

                end;

              end;
            end;
          except

          end;
          // Tirar acento
          Result.Nome := Conversa.Resposta;
          Result.Etapa := 3;
          DadosNovoCliente(Result);
          exit;
        end
        else
        begin
          // Nome Invalido, menos de 3 caracteres
          dmPrincipal.Enviamensagem(Result.Etapa, Result.Pergunta, Result);
          exit;
        end;
      end;
    3:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Aguardando a Data de Nascimento');
        txMensagem := '*Informe a sua data de nascimento*' +
          MENSAGEM_QUEBRA_LINHA;
        txMensagem := txMensagem + 'Exemplo: ' + DateToStr(date);
        Conversa.Etapa := 4;
        Conversa.Resposta := '01/01/0001';
        DadosNovoCliente(Conversa);
        // dmPrincipal.Enviamensagem(Conversa.Etapa, txMensagem, Result);
        exit;
      end;
    4:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Gravando o Cliente');
        try
          Result.DataNascimento := StrToDate(Conversa.Resposta);
          // Gravar Usuario AKI
          dmPrincipal.CriaTabela('cliente', 'codigo').Insert;
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('codigo')
            .AsInteger := dmPrincipal.GerarID('cliente', 'codigo');
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('nome')
            .AsString := Result.Nome;
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('cpf')
            .AsString := Result.CPF;
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('celular')
            .AsString := Result.Telefone;
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('celular_wpp')
            .AsString := Result.Telefone;
          dmPrincipal.CriaTabela('cliente', 'codigo')
            .FieldByName('data_nascimento').AsDateTime := Result.DataNascimento;
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('origem')
            .AsInteger := 1;
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('ativo')
            .AsInteger := 1;
          dmPrincipal.CriaTabela('cliente', 'codigo').FieldByName('bloqueado')
            .AsInteger := 0;
          dmPrincipal.CriaTabela('cliente', 'codigo').Post;
          Result.Situacao := MenuPedido;
          Result.Etapa := 0;
          dmPrincipal.GravaConversa(Result);
          dmPrincipal.GestorInteracao(Result);
          exit;
        except
          dmPrincipal.Enviamensagem(Result.Etapa, Result.Pergunta, Result);
          exit;
        end;

      end;
  end;
end;

function TGeralConversa.EtapaConversa(Conversa: TBotConversa): TBotConversa;
var
  Tabela: TFDTable;
  ID: integer;
  Endereco: TEndereco;
  ConversaB: TBotConversa;
begin

  ConversaB := Gestor.ConversasMemoria.LocalizaConversa(Conversa);

  if Assigned(ConversaB) then
  begin
    Conversa := ConversaB;
    exit;
  end;

  if Conversa = nil then
  begin
    exit;
  end;
  Result := Conversa;
  Tabela := dmPrincipal.CriaTabela('conversa_backup');

  if Tabela.Locate('id_wpp', Conversa.ID, []) then
  begin
    if Tabela.FieldByName('data').AsDateTime = date then
    begin
      Result.AuxCliente := Tabela.FieldByName('aux').AsInteger;
      Result.IDMensagem := Tabela.FieldByName('idmensagem').AsFloat;
      Result.Resposta := Tabela.FieldByName('resposta').AsString;
      Result.Pergunta := Tabela.FieldByName('pergunta').AsString;
      Result.ProdutoCategoriaSelecionada := Tabela.FieldByName('categoria')
        .AsInteger;
      Result.ProdutoCodigoSelecionado := Tabela.FieldByName('produto')
        .AsInteger;
      Result.Etapa := Tabela.FieldByName('etapa').AsInteger;
      Result.Situacao := TipoSitucacao(Tabela.FieldByName('situacao')
        .AsInteger);
      Result.CodigoEndereco := Tabela.FieldByName('codigo_endereco').AsInteger;

      Result.QuantidadeCategoria := Tabela.FieldByName('qtdcategoria')
        .AsInteger;
      Result.CategoriaAtual := Tabela.FieldByName('categoriaatual').AsInteger;
      Result.MinimoCategoria := Tabela.FieldByName('mincategoria').AsInteger;
      Result.MaximoCategoria := Tabela.FieldByName('maxcategoria').AsInteger;
      Result.ProdutoCategoriaSelecionada :=
        Tabela.FieldByName('produtocategoria').AsInteger;
      Result.ProdutoCodigoSelecionado :=
        Tabela.FieldByName('produtoselecionado').AsInteger;
      Result.SQLCategoria := Tabela.FieldByName('sqlcategoria').AsString;
      Result.ProdutoQuantidade := Tabela.FieldByName('qtdproduto').AsFloat;
      Result.CodigoEndereco := Tabela.FieldByName('codendereco').AsInteger;
      Result.Numero := Tabela.FieldByName('numero').AsString;
      Result.Complemento := Tabela.FieldByName('complemento').AsString;
      Result.CategoriaDescricao :=
        Tabela.FieldByName('categoriadescricao').AsString;

      if Result.CodigoEndereco > 0 then
      begin
        Result.Entrega := Delivery;
      end
      else
      begin
        Result.Entrega := VemBuscar;
      end;

      SetLength(Result.ArrayCategorias, 0);
      SetLength(Result.ArrayCategoriasItens, 0);
      SetLength(Result.ArrayCategoriasValores, 0);

      dmPrincipal.CriaQRY('DADOARRAY').Close;
      dmPrincipal.CriaQRY('DADOARRAY').SQL.Clear;
      dmPrincipal.CriaQRY('DADOARRAY')
        .SQL.Add('select * from conversa_backup_sap where id_conversa = ' +
        Tabela.FieldByName('id').AsString + ' and valor > -1');
      dmPrincipal.CriaQRY('DADOARRAY').Open;

      SetLength(Result.ArrayCategorias, dmPrincipal.CriaQRY('DADOARRAY')
        .RecordCount);
      SetLength(Result.ArrayCategoriasItens, dmPrincipal.CriaQRY('DADOARRAY')
        .RecordCount);
      SetLength(Result.ArrayCategoriasValores, dmPrincipal.CriaQRY('DADOARRAY')
        .RecordCount);
      SetLength(Result.ArrayCategoriasTipoValor,
        dmPrincipal.CriaQRY('DADOARRAY').RecordCount);
      ID := 0;
      while not dmPrincipal.CriaQRY('DADOARRAY').Eof do
      begin
        Result.ArrayCategorias[ID] := dmPrincipal.CriaQRY('DADOARRAY')
          .FieldByName('descricao').AsString;
        Result.ArrayCategoriasItens[ID] := dmPrincipal.CriaQRY('DADOARRAY')
          .FieldByName('item').AsString;
        Result.ArrayCategoriasValores[ID] := dmPrincipal.CriaQRY('DADOARRAY')
          .FieldByName('valor').AsFloat;
        Result.ArrayCategoriasTipoValor[ID] := dmPrincipal.CriaQRY('DADOARRAY')
          .FieldByName('tipo_valor').AsInteger;
        inc(ID);
        dmPrincipal.CriaQRY('DADOARRAY').Next;
      end;

      dmPrincipal.CriaQRY('DADOARRAY').Close;
      dmPrincipal.CriaQRY('DADOARRAY').SQL.Clear;
      dmPrincipal.CriaQRY('DADOARRAY')
        .SQL.Add('select * from conversa_backup_sap where id_conversa = ' +
        Tabela.FieldByName('id').AsString + ' and valor = -1');
      dmPrincipal.CriaQRY('DADOARRAY').Open;

      SetLength(Result.ArrayDadosEndereco, dmPrincipal.CriaQRY('DADOARRAY')
        .RecordCount);

      ID := 0;
      while not dmPrincipal.CriaQRY('DADOARRAY').Eof do
      begin
        Result.ArrayDadosEndereco[ID] := dmPrincipal.CriaQRY('DADOARRAY')
          .FieldByName('descricao').AsString;
        inc(ID);
        dmPrincipal.CriaQRY('DADOARRAY').Next;
      end;

      Result.DadosEnderecoCliente := TEnderecoLocalizacao.Create;

      Result.DadosEnderecoCliente.Rua := Tabela.FieldByName('rua').AsString;
      Result.DadosEnderecoCliente.Bairro :=
        Tabela.FieldByName('bairro').AsString;
      Result.DadosEnderecoCliente.Cidade :=
        Tabela.FieldByName('cidade').AsString;
      Result.DadosEnderecoCliente.Estado :=
        Tabela.FieldByName('estado').AsString;
      Result.DadosEnderecoCliente.KM := Tabela.FieldByName('km').AsFloat;
      Result.DadosEnderecoCliente.CEP := Tabela.FieldByName('cep').AsString;
      Result.DadosEnderecoCliente.EnderecoComNumero := Result.Numero;
      Result.DadosEnderecoCliente.EnderecoCompleto := Result.Complemento;

      if (Result.CodigoEndereco > 0) then
      begin
        Result := Endereco.BuscaDadosEndereco(Result);
        if Result.DadosEnderecoCliente <> nil then
        begin
          Result.DadosEnderecoCliente.EnderecoComNumero := Result.Numero;
          Result.DadosEnderecoCliente.EnderecoCompleto := Result.Complemento;
        end;
      end;

    end
    else
    begin
      Result := Conversa;
    end;

  end;
  Tabela.free;
end;

end.
