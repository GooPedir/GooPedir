unit uClassEndereco;

interface

uses FireDAC.Comp.Client, uPrincipal, System.SysUtils,
  REST.Response.Adapter, REST.Client, JSON, uBotConversa, Variants;

type

  TCidade = class
  public

    function CidadeFazParte(txCidade: String): Boolean;

  end;

  TDadosEndereco = class
  private
    txEndereco: String;
    txBairro: String;
    txCidade: String;
    txEstado: String;
    txIBGE: String;
    txCEP: String;
    boAchou: Boolean;
    FKM: Real;
    procedure SetKM(const Value: Real);

  public
    property Endereco: String read txEndereco write txEndereco;
    property Bairro: String read txBairro write txBairro;
    property Cidade: String read txCidade write txCidade;
    property Estado: String read txEstado write txEstado;
    property IBGE: String read txIBGE write txIBGE;
    property CEP: String read txCEP write txCEP;
    property Achou: Boolean read boAchou write boAchou;
    property KM: Real read FKM write SetKM;

  var
    ArrayRetornoJason: Array of String;
  end;

  TEndereco = class
  private
    function BuscaLocalizacao(vLat, vLng: string): TDadosEndereco;
    function BuscaCEP(CEP: String): TDadosEndereco;
    function ValidaEndereco(Bairro, Cidade, Estado: String): Boolean;
    function BairrosAtendidos(Cidade, Estado: String): String;
  public

    function Endereco(Conversa: TBotConversa): TBotConversa;

    function TaxaDeEntrega(Conversa: TBotConversa): Real;

    function BuscaDadosEndereco(Conversa: TBotConversa): TBotConversa;

  end;

implementation

{ TEndereco }

uses uClassEnderecoUtil, uDM, uClassAPIGooleLocalizacao, uClassFuncoes;

function TEndereco.BairrosAtendidos(Cidade, Estado: String): String;
begin

  dm.CriaQRY('VALIDAEND').Close;
  dm.CriaQRY('VALIDAEND').SQL.Clear;
  dm.CriaQRY('VALIDAEND').SQL.Add('SELECT * FROM taxa_entrega where cidade = ' +
    QuotedStr(Cidade) + ' and estado = ' + QuotedStr(Estado) +
    ' and ativo = 1 order by bairro');
  dm.CriaQRY('VALIDAEND').Open;
  Result := '';
  while not dm.CriaQRY('VALIDAEND').Eof do
  begin
    if Result = '' then
      Result := dm.CriaQRY('VALIDAEND').FieldByName('bairro').AsString
    else
      Result := Result + ', ' + dm.CriaQRY('VALIDAEND')
        .FieldByName('bairro').AsString;
    dm.CriaQRY('VALIDAEND').Next;
  end;

end;

function TEndereco.BuscaCEP(CEP: String): TDadosEndereco;
var
  Google: TGoogleAPI;
begin
  Google := TGoogleAPI.Create;
  Google.Tipo := tCEPSituacao;
  Google.CEP := CEP;
  Result := Google.Consulta;

end;

function TEndereco.BuscaDadosEndereco(Conversa: TBotConversa): TBotConversa;
var
  Tabela: TFDTable;
begin
  Result := Conversa;
  if Conversa.CodigoEndereco > 0 then
  begin
    Tabela := dm.CriaTabela('cliente_endereco', '');
    if Tabela.Locate('codigo', IntToStr(Conversa.CodigoEndereco), []) then
    begin
      if Result.DadosEnderecoCliente = nil then
        Result.DadosEnderecoCliente := TEnderecoLocalizacao.Create;

      Result.DadosEnderecoCliente.Rua := Tabela.FieldByName('rua').AsString;
      Result.DadosEnderecoCliente.Bairro :=
        Tabela.FieldByName('bairro').AsString;
      Result.DadosEnderecoCliente.Cidade :=
        Tabela.FieldByName('cidade').AsString;
      Result.DadosEnderecoCliente.Estado :=
        Tabela.FieldByName('estado').AsString;
      Result.DadosEnderecoCliente.KM := Tabela.FieldByName('km').AsFloat;
      Tabela.Free;
    end;
  end;
end;

function TEndereco.BuscaLocalizacao(vLat, vLng: string): TDadosEndereco;
var
  Google: TGoogleAPI;
begin
  Google := TGoogleAPI.Create;
  Google.Tipo := tLocalizacao;
  Google.Lat := StrToFloat(vLat);
  Google.Long := StrToFloat(vLng);
  Result := Google.Consulta;

end;

function TEndereco.Endereco(Conversa: TBotConversa): TBotConversa;
var
  Mensagem: String;
  subMensagem: String;
  EnderecoCliente: TEndereco;
  EnderecoLocalizacao: TDadosEndereco;
  I: Integer;
  A: Integer;
  ValidaCEP: TCEP;
begin
  Result := Conversa;
  EnderecoCliente := TEndereco.Create;

  // Se for vem buscar, vai direto pro MENU
  // if Conversa.Entrega = VemBuscar then
  // begin
  // Conversa.Situacao := MenuPedido;
  // Conversa.Etapa := 0;
  // dmPrincipal.GravaConversa(Conversa);
  // dmPrincipal.GestorInteracao(Conversa);
  // exit;
  // end;

  case Conversa.Etapa of
    0:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Validando endereços Ativos');
        // Validar se o cliente possui endereço ativo
        dmPrincipal.CriaQRY('ENDERECO').Close;
        dmPrincipal.CriaQRY('ENDERECO').SQL.Clear;
        dmPrincipal.CriaQRY('ENDERECO')
          .SQL.Add('SELECT * FROM cliente_endereco where codigo_cliente = ' +
          IntToStr(Conversa.CodigoClienteInterno) + ' and ativo = 1');
        dmPrincipal.CriaQRY('ENDERECO').Open;
        if dmPrincipal.CriaQRY('ENDERECO').RecordCount > 0 then
        begin
          // Localizou :3

          Conversa.DadosEnderecoCliente := TEnderecoLocalizacao.Create;
          Conversa.DadosEnderecoCliente.Cidade :=
            dmPrincipal.CriaQRY('ENDERECO').FieldByName('cidade').AsString;
          Conversa.DadosEnderecoCliente.Bairro :=
            dmPrincipal.CriaQRY('ENDERECO').FieldByName('bairro').AsString;
          Conversa.DadosEnderecoCliente.KM := dmPrincipal.CriaQRY('ENDERECO')
            .FieldByName('km').AsFloat;
          Mensagem := '*Endereço Localizado:*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
          Mensagem := Mensagem + '*Endereço:* ' + dmPrincipal.CriaQRY
            ('ENDERECO').FieldByName('rua').AsString + ', ' +
            dmPrincipal.CriaQRY('ENDERECO').FieldByName('numero').AsString +
            ' - ' + dmPrincipal.CriaQRY('ENDERECO').FieldByName('bairro')
            .AsString + MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*Complemento:* ' +
            dmPrincipal.CriaQRY('ENDERECO').FieldByName('complemento').AsString
            + MENSAGEM_QUEBRA_LINHA;

          if Conversa.DadosEnderecoCliente.KM > 0 then
            Mensagem := Mensagem + MONO_ESPACADA + FormatFloat('#0.00',
              Conversa.DadosEnderecoCliente.KM) + 'KM' + MONO_ESPACADA +
              MENSAGEM_QUEBRA_LINHA;

          Conversa.CodigoEndereco := dmPrincipal.CriaQRY('ENDERECO')
            .FieldByName('codigo').AsInteger;
          if TaxaDeEntrega(Conversa) > 0 then
          begin
            Mensagem := Mensagem + 'Taxa R$: ' + FormatFloat('#0.00',
              TaxaDeEntrega(Conversa)) + MENSAGEM_QUEBRA_LINHA_DUPLA;
          end;
          Mensagem := Mensagem + '*Deseja utilizar o endereço localizado?*';
          Conversa.Etapa := 1;
          Conversa.CodigoEndereco := dmPrincipal.CriaQRY('ENDERECO')
            .FieldByName('codigo').AsInteger;


          //
          // dmPrincipal.iWhatsapp.EnviaBotao(Conversa.ID,'*S* para sim ou *N* para não','Escolha a opção abaixo',['S','N']);

          if Usar_Novo_Botao then
          begin
            dmPrincipal.EnviaBotao(Conversa, Mensagem, 'escolha uma opção',
              ['SIM', 'NÃO'], ['S', 'N']);
          end
          else
          begin

            Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA +
              'Digite *S* para sim ou *N* para cadastrar um novo *endereço*!';
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
          end;

          exit;
        end
        else
        begin
          Conversa.Etapa := 2;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
      end;
    1:
      begin
        if Usar_Novo_Botao then
        begin
          Conversa.Resposta := Conversa.ValorBotao;
        end;
        if trim(UpperCase(Conversa.Resposta)) = 'S' then
        begin
          dmPrincipal.GeraLOG(Conversa, 'Escolheu usar endereço ativo');
          Conversa.Etapa := 11;
          Conversa.Situacao := MenuPedido;
          dmPrincipal.GravaConversa(Conversa);
          dmPrincipal.GestorInteracao(Conversa);
          exit;

        end
        else if trim(UpperCase(Conversa.Resposta)) = 'N' then
        begin
          dmPrincipal.GeraLOG(Conversa,
            'Escolheu usar cadastrar um endereço novo');
          dmPrincipal.CriaQRY('ENDERECO').Close;
          dmPrincipal.CriaQRY('ENDERECO').SQL.Clear;
          dmPrincipal.CriaQRY('ENDERECO')
            .SQL.Add('update cliente_endereco set ativo = 0 where codigo_cliente = '
            + IntToStr(Conversa.CodigoClienteInterno));
          dmPrincipal.CriaQRY('ENDERECO').ExecSQL;

          Conversa.Etapa := 0;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end
        else
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;
      end;
    2:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Aguardando a localização!');
        Mensagem := '*Envie sua localização fixa, ou envie seu CEP!*';
        Mensagem := '*Envie sua localização fixa!*';
        Conversa.Etapa := 3;
        dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        exit;
      end;
    3:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Aguardando a localização!');
        // Validar cep aki
        if ValidaCEP = nil then
          ValidaCEP := TCEP.Create;

        if (Conversa.Lat = 0) and (Conversa.Lng = 0) then
        begin
          if ValidaCEP.ValidaCEP(Conversa.Resposta) then
          begin
            EnderecoLocalizacao := BuscaCEP(Conversa.Resposta);
          end;
          if EnderecoLocalizacao = nil then
            EnderecoLocalizacao := TDadosEndereco.Create;

          if not EnderecoLocalizacao.Achou then
          begin
            Conversa.Etapa := 2;
            dmPrincipal.GravaConversa(Conversa);
            Endereco(Conversa);
            exit;
          end;

        end
        else
        begin
          EnderecoLocalizacao := EnderecoCliente.BuscaLocalizacao
            (FloatToStr(Conversa.Lat), FloatToStr(Conversa.Lng));
        end;

        if Conversa.DadosEnderecoCliente = nil then
          Conversa.DadosEnderecoCliente := TEnderecoLocalizacao.Create;

        Conversa.DadosEnderecoCliente.KM := EnderecoLocalizacao.KM;

        if not EnderecoLocalizacao.Achou then
        begin
          SetLength(Result.ArrayDadosEndereco,
            length(EnderecoLocalizacao.ArrayRetornoJason));
          for I := 0 to length(EnderecoLocalizacao.ArrayRetornoJason) - 1 do
            Result.ArrayDadosEndereco[I] :=
              EnderecoLocalizacao.ArrayRetornoJason[I];
          Result.Etapa := 4;
          dmPrincipal.GravaConversa(Result);
          Endereco(Result);
          exit;
        end
        else
        begin
          Conversa.DadosEnderecoCliente.Rua := EnderecoLocalizacao.txEndereco;
          Conversa.DadosEnderecoCliente.Bairro := EnderecoLocalizacao.txBairro;
          Conversa.DadosEnderecoCliente.Cidade := EnderecoLocalizacao.txCidade;
          Conversa.DadosEnderecoCliente.Estado := EnderecoLocalizacao.txEstado;
          Conversa.Resposta := '';
          Conversa.Etapa := 9;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
      end;
    4:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Verificando Taxa');
        // Aki vai validar os dados
        for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
        begin
          dmPrincipal.CriaQRY('VERIFICA_CITY').Close;
          dmPrincipal.CriaQRY('VERIFICA_CITY').SQL.Clear;
          dmPrincipal.CriaQRY('VERIFICA_CITY')
            .SQL.Add('SELECT * FROM cidades_estados where upper(cidade) like ' +
            QuotedStr('%' + Conversa.ArrayDadosEndereco[I] + '%') +
            ' and estado = ' + QuotedStr('SC') + ' limit 1');
          dmPrincipal.CriaQRY('VERIFICA_CITY').Open;

          if dmPrincipal.CriaQRY('VERIFICA_CITY').RecordCount > 0 then
          begin

            Conversa.DadosEnderecoCliente.Cidade :=
              Conversa.ArrayDadosEndereco[I];
            Conversa.DadosEnderecoCliente.Estado :=
              dmPrincipal.CriaQRY('VERIFICA_CITY')
              .FieldByName('estado').AsString;

            for A := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
            begin
              if I <> A then
              begin

                dmPrincipal.CriaQRY('VERIFICA_BAIRRO').Close;
                dmPrincipal.CriaQRY('VERIFICA_BAIRRO').SQL.Clear;
                dmPrincipal.CriaQRY('VERIFICA_BAIRRO')
                  .SQL.Add('SELECT * FROM bairros_cidade where (bairro) like ' +
                  QuotedStr('%' + Conversa.ArrayDadosEndereco[A] + '%') +
                  ' and upper(cidade) like ' +
                  QuotedStr('%' + Conversa.ArrayDadosEndereco[I] + '%') +
                  ' limit 1');
                dmPrincipal.CriaQRY('VERIFICA_BAIRRO').Open;
                if dmPrincipal.CriaQRY('VERIFICA_BAIRRO').RecordCount > 0 then
                begin
                  Conversa.DadosEnderecoCliente.Bairro :=
                    Conversa.ArrayDadosEndereco[A];
                end;

                dmPrincipal.CriaQRY('VERIFICA_BAIRRO').Close;
                dmPrincipal.CriaQRY('VERIFICA_BAIRRO').SQL.Clear;
                dmPrincipal.CriaQRY('VERIFICA_BAIRRO')
                  .SQL.Add('SELECT * FROM taxa_entrega where (bairro) like ' +
                  QuotedStr('%' + Conversa.ArrayDadosEndereco[A] + '%') +
                  ' and upper(cidade) like ' +
                  QuotedStr('%' + Conversa.ArrayDadosEndereco[I] + '%') +
                  ' limit 1');
                dmPrincipal.CriaQRY('VERIFICA_BAIRRO').Open;
                if dmPrincipal.CriaQRY('VERIFICA_BAIRRO').RecordCount > 0 then
                begin
                  Conversa.DadosEnderecoCliente.Bairro :=
                    Conversa.ArrayDadosEndereco[A];
                end;

              end;

            end;

          end;
        end;

        if (Conversa.DadosEnderecoCliente.Bairro <> '') and
          (Conversa.DadosEnderecoCliente.Cidade <> '') then
        begin
          Conversa.DadosEnderecoCliente.Rua := Conversa.ArrayDadosEndereco[0];
          Conversa.Resposta := '';
          Conversa.Etapa := 9;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end
        else if Conversa.DadosEnderecoCliente.Bairro = '' then
        begin
          Conversa.DadosEnderecoCliente.Rua := Conversa.ArrayDadosEndereco[0];
          Conversa.Resposta := '';
          Conversa.Etapa := 9;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;

        if Conversa.DadosEnderecoCliente.Rua = '' then
        begin
          Conversa.Etapa := 5;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
      end;
    5:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Escolhendo a sua Rua');
        Conversa.Etapa := 6;
        if Conversa.DadosEnderecoCliente.Rua = '' then
        begin
          Mensagem := '*Selecione a opção referente a sua rua!*' +
            MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem +
            'Caso a rua esteja com nome errado, basta selecionar ela e nos proximos passo altera-lá.'
            + MENSAGEM_QUEBRA_LINHA_DUPLA;
          if length(Conversa.ArrayDadosEndereco) = 0 then
          begin
            Mensagem := 'Dados incorretos ou incompletos para seu endereço!';
            Conversa.Etapa := 2;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
            dmPrincipal.GravaConversa(Conversa);
            Endereco(Conversa);
            exit;
          end;

          for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
            Mensagem := Mensagem + '*' + IntToStr(I) + '* - ' +
              Conversa.ArrayDadosEndereco[I] + MENSAGEM_QUEBRA_LINHA;
          Conversa.Resposta := '';
          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
          abort;
        end
        else
        begin
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
      end;
    6:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Escolhendo o Bairro');
        Mensagem := '*Selecione seu bairro!*';
        if (Conversa.DadosEnderecoCliente.Bairro <> '') and
          (Conversa.DadosEnderecoCliente.Rua <> '') then
        begin
          Conversa.Etapa := 7;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;

        if trim(Conversa.Resposta) = '' then
        begin
          // Deve-se
          // Validar aki se a cidade tem taxa cadastrada
          dm.CriaQRY('VALIDAEND').Close;
          dm.CriaQRY('VALIDAEND').SQL.Clear;
          dm.CriaQRY('VALIDAEND')
            .SQL.Add('SELECT * FROM taxa_entrega where cidade = ' +
            QuotedStr(Conversa.DadosEnderecoCliente.Cidade) + ' and estado = ' +
            QuotedStr(Conversa.DadosEnderecoCliente.Estado) +
            ' and ativo = 1 order by bairro');
          dm.CriaQRY('VALIDAEND').Open;
          Conversa.Etapa := 7;
          Conversa.Resposta := '';
          Mensagem := '*Selecione a opção referente ao seu bairro!*' +
            MENSAGEM_QUEBRA_LINHA_DUPLA;
          for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
            Mensagem := Mensagem + '*' + IntToStr(I + 1) + '* - ' +
              Conversa.ArrayDadosEndereco[I] + MENSAGEM_QUEBRA_LINHA;
          dm.CriaQRY('VALIDAEND').First;
          while not dm.CriaQRY('VALIDAEND').Eof do
          begin
            inc(I);
            Mensagem := Mensagem + '*' + IntToStr(I) + '* - ' +
              trim(dm.CriaQRY('VALIDAEND').FieldByName('bairro').AsString) +
              MENSAGEM_QUEBRA_LINHA;
            dm.CriaQRY('VALIDAEND').Next;
          end;

          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
          exit;
        end
        else
        begin
          try
            if strtoint(Conversa.Resposta) >
              length(Conversa.ArrayDadosEndereco) - 1 then
            begin
              strtoint('a')
            end;

            for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
            begin
              if strtoint(Conversa.Resposta) = I + 1 then
              begin
                Conversa.DadosEnderecoCliente.Rua :=
                  Conversa.ArrayDadosEndereco[I];
                Conversa.Etapa := 6;
                Conversa.Resposta := '';
                dmPrincipal.GravaConversa(Conversa);
                Endereco(Conversa);
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
    7:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Escolhendo a Cidade');
        Mensagem := '*Selecione sua cidade!*';
        if Conversa.DadosEnderecoCliente.Bairro = '' then
        begin

          if trim(Conversa.Resposta) = '' then
          begin

            Conversa.Etapa := 8;
            Mensagem := '*Selecione a opção referente a sua cidade!*' +
              MENSAGEM_QUEBRA_LINHA_DUPLA;
            for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
              Mensagem := Mensagem + '*' + IntToStr(I) + '* - ' +
                Conversa.ArrayDadosEndereco[I] + MENSAGEM_QUEBRA_LINHA;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
            exit;

          end
          else
          begin
            try

              dm.CriaQRY('VALIDAEND').Close;
              dm.CriaQRY('VALIDAEND').SQL.Clear;
              dm.CriaQRY('VALIDAEND')
                .SQL.Add('SELECT * FROM taxa_entrega where cidade = ' +
                QuotedStr(Conversa.DadosEnderecoCliente.Cidade) +
                ' and estado = ' +
                QuotedStr(Conversa.DadosEnderecoCliente.Estado) +
                ' and ativo = 1 order by bairro');
              dm.CriaQRY('VALIDAEND').Open;
              for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
              begin
                if strtoint(Conversa.Resposta) = I then
                begin
                  Conversa.DadosEnderecoCliente.Bairro :=
                    Conversa.ArrayDadosEndereco[I];
                  Conversa.Etapa := 8;
                  Conversa.Resposta := '';
                  dmPrincipal.GravaConversa(Conversa);
                  Endereco(Conversa);
                  exit;

                end;

              end;
              dm.CriaQRY('VALIDAEND').First;
              while not dm.CriaQRY('VALIDAEND').Eof do
              begin
                inc(I);
                if strtoint(Conversa.Resposta) = I then
                begin
                  Conversa.DadosEnderecoCliente.Bairro :=
                    trim(dm.CriaQRY('VALIDAEND').FieldByName('bairro')
                    .AsString);
                  Conversa.Etapa := 6;
                  Conversa.Resposta := '';
                  dmPrincipal.GravaConversa(Conversa);
                  Endereco(Conversa);
                  exit;
                end;

                dm.CriaQRY('VALIDAEND').Next;
              end;
              strtoint('a')
            except
              dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
                Conversa);
              exit;
            end;
          end;

        end
        else
        begin
          Conversa.Pergunta := '';
          Conversa.Etapa := 9;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
      end;

    8:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Escolhendo a Cidade');
        if Conversa.DadosEnderecoCliente.Cidade = '' then
        begin
          if trim(Conversa.Resposta) = '' then
          begin

            Conversa.Etapa := 8;
            Mensagem := '*Selecione a opção referente a sua cidade!*' +
              MENSAGEM_QUEBRA_LINHA_DUPLA;
            for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
              Mensagem := Mensagem + '*' + IntToStr(I) + '* - ' +
                Conversa.ArrayDadosEndereco[I] + MENSAGEM_QUEBRA_LINHA;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
            exit;

          end
          else
          begin
            try
              if strtoint(Conversa.Resposta) >
                length(Conversa.ArrayDadosEndereco) - 1 then
              begin
                strtoint('a')
              end;

              for I := 0 to length(Conversa.ArrayDadosEndereco) - 1 do
              begin
                if strtoint(Conversa.Resposta) = I then
                begin
                  Conversa.DadosEnderecoCliente.Cidade :=
                    Conversa.ArrayDadosEndereco[I];
                  Conversa.Etapa := 9;
                  Conversa.Resposta := '';
                  dmPrincipal.GravaConversa(Conversa);
                  Endereco(Conversa);
                  exit;

                end;

              end;
            except
              dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
                Conversa);
              exit;
            end;
          end;

        end
        else
        begin
          Conversa.Pergunta := '';
          Conversa.Etapa := 9;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;

      end;
    9:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Endereço Localizado');
        if Conversa.DadosEnderecoCliente.Rua = '' then
        begin
          Conversa.Etapa := 5;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
        if Conversa.DadosEnderecoCliente.Bairro = '' then
        begin
          Conversa.Etapa := 6;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
        if Conversa.DadosEnderecoCliente.Cidade = '' then
        begin
          Conversa.Etapa := 7;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
        if dm.DADOS_EMPRESA.FieldByName('taxa_por_km').AsInteger = 1 then
        begin
          if (Conversa.DadosEnderecoCliente.KM > dm.DADOS_EMPRESA.FieldByName
            ('KM_MAXIMO').AsFloat) and
            (dm.DADOS_EMPRESA.FieldByName('KM_MAXIMO').AsFloat > 0) then
          begin
            Mensagem := '*--- ARÉA NÃO ATENDIDA ---*' +
              MENSAGEM_QUEBRA_LINHA_DUPLA;
            Mensagem := Mensagem + MONO_ESPACADA +
              'Seu endereço utrapassou o raio de ' +
              FormatFloat('0', dm.DADOS_EMPRESA.FieldByName('KM_MAXIMO')
              .AsFloat) + 'KM.' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA_DUPLA;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);

            Conversa.Situacao := Finalizado;
            Conversa.Etapa := 0;
            dmPrincipal.GravaConversa(Conversa);
            dmPrincipal.GestorInteracao(Conversa);
            exit;
          end;
        end
        else
        begin
          // Validar aki se o endereço tem taxa de entrega
          // function ValidaEndereco(Bairro,Cidade,Estado:String):Boolean;

          if not ValidaEndereco(Conversa.DadosEnderecoCliente.Bairro,
            Conversa.DadosEnderecoCliente.Cidade,
            Conversa.DadosEnderecoCliente.Estado) then
          begin
          //Mostrar lista de bairros
          Conversa.Resposta := '';
          Conversa.Etapa := 12;
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
            Mensagem := '*--- BAIRRO NÃO ATENDIDO ---*' +
              MENSAGEM_QUEBRA_LINHA;
            Mensagem := Mensagem + MONO_ESPACADA+trim(Conversa.DadosEnderecoCliente.Bairro)+MONO_ESPACADA+MENSAGEM_QUEBRA_LINHA_DUPLA;
            Mensagem := Mensagem + MONO_ESPACADA +
              'Lamentamos mais no momento não atendemos o seu bairro!' +
              MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
            Mensagem := Mensagem + '*LISTA DE BAIRROS ATENDIDOS*' +
              MENSAGEM_QUEBRA_LINHA;
            Mensagem := Mensagem + MONO_ESPACADA +
              BairrosAtendidos(Conversa.DadosEnderecoCliente.Cidade,
              Conversa.DadosEnderecoCliente.Estado) + MONO_ESPACADA;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);

            Conversa.Situacao := Finalizado;
            Conversa.Etapa := 0;
            dmPrincipal.GravaConversa(Conversa);
            dmPrincipal.GestorInteracao(Conversa);
            exit;
          end;

        end;
        Conversa.CodigoEndereco := 0;
        Mensagem := '*Endereço localizado:*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
        Mensagem := Mensagem + '*Rua:* ' + Conversa.DadosEnderecoCliente.Rua +
          MENSAGEM_QUEBRA_LINHA;
        Mensagem := Mensagem + '*Bairro:* ' +
          Conversa.DadosEnderecoCliente.Bairro + MENSAGEM_QUEBRA_LINHA;
        Mensagem := Mensagem + '*Cidade:* ' +
          Conversa.DadosEnderecoCliente.Cidade + MENSAGEM_QUEBRA_LINHA_DUPLA;
        subMensagem :=
          'Caso a rua esteja incorreta, basta enviar o nome da *RUA* certo, ou caso esteja tudo certo, clique em PROXIMO';;
        Conversa.Etapa := 10;
        Conversa.DadosEnderecoCliente.Correto := True;

        if Usar_Novo_Botao then
        begin
          dmPrincipal.EnviaBotao(Conversa, Mensagem, subMensagem,
            ['PROXIMO'], ['P']);

        end
        else
        begin
          Mensagem := Mensagem + MENSAGEM_QUEBRA_LINHA +
            'Caso a rua esteja incorreta, basta enviar o nome da *RUA* certo, ou caso esteja tudo certo basta digitar *P*';
          dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        end;

        exit;
      end;
    10:
      begin
        if Usar_Novo_Botao then
        begin
          Conversa.Resposta := Conversa.ValorBotao;
        end;
        dmPrincipal.GeraLOG(Conversa, 'Validando Dados');
        if trim(Conversa.Resposta) <> '' then
        begin
          if trim(UpperCase(Conversa.Resposta)) = 'P' then
          begin
            Conversa.Etapa := 11;
            Conversa.Resposta := '';
            dmPrincipal.GravaConversa(Conversa);
            Endereco(Conversa);
            exit;
          end
          else
          begin
            Conversa.DadosEnderecoCliente.Rua := UpperCase(Conversa.Resposta);
            Conversa.Etapa := 8;
            Conversa.Resposta := '';
            dmPrincipal.GravaConversa(Conversa);
            Endereco(Conversa);
            exit;
          end;
        end
        else
        begin
          dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
            Conversa);
          exit;
        end;
      end;
    11:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Gravando Endereços');
        // Gravar aki os dados
        if not Conversa.EnviarMensagem then
        begin
          if dmPrincipal.ParametrosDadosEmpresa.FieldByName('seleciona_bairros')
            .AsInteger = 1 then
          begin
            Conversa.EnviarMensagem := True;
            Conversa.Etapa := 12;
            Conversa.Resposta := '';
            dmPrincipal.GravaConversa(Conversa);
            Endereco(Conversa);
            exit;
          end;
        end;
        if Conversa.DadosEnderecoCliente.EnderecoComNumero = '' then
        begin
          Conversa.Etapa := 13;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;

        if Conversa.DadosEnderecoCliente.EnderecoCompleto = '' then
        begin
          Conversa.Etapa := 14;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo').Insert;
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('codigo').AsInteger :=
          dmPrincipal.GerarID('cliente_endereco', 'codigo');
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('codigo_cliente').AsInteger :=
          Conversa.CodigoClienteInterno;
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('descricao').AsString := 'Principal';
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo').FieldByName('tipo')
          .AsString := '1';

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('ativo').AsString := '1';

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo').FieldByName('CEP')
          .AsString := '';

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo').FieldByName('rua')
          .AsString := Conversa.DadosEnderecoCliente.Rua;

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('bairro').AsString :=
          Conversa.DadosEnderecoCliente.Bairro;

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('cidade').AsString :=
          Conversa.DadosEnderecoCliente.Cidade;

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('estado').AsString :=
          Conversa.DadosEnderecoCliente.Estado;

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('estado').AsString :=
          Conversa.DadosEnderecoCliente.Estado;

        // Numero e Complemento Fazer dps
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('numero').AsString :=
          Conversa.DadosEnderecoCliente.EnderecoComNumero;

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('complemento').AsString :=
          Conversa.DadosEnderecoCliente.EnderecoCompleto;

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo').FieldByName('KM')
          .AsFloat := Conversa.DadosEnderecoCliente.KM;
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('latitude').AsFloat := Conversa.Lat;
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('longitude').AsFloat := Conversa.Lng;
        // Taxa de Entrega
        dmPrincipal.CriaTabela('cliente_endereco', 'codigo')
          .FieldByName('taxa_entrega').AsFloat := TaxaDeEntrega(Conversa);

        dmPrincipal.CriaTabela('cliente_endereco', 'codigo').Post;
        Conversa.CodigoEndereco := dmPrincipal.CriaTabela('cliente_endereco',
          'codigo').FieldByName('codigo').AsInteger;

        Conversa.Resposta := '';
        Conversa.Etapa := 0;
        dmPrincipal.GravaConversa(Conversa);
        Endereco(Conversa);
        exit;

      end;
    12:
      begin
        dmPrincipal.GeraLOG(Conversa, 'Escolhendo o Bairro');
        if trim(Conversa.Resposta) = '' then
        begin
          // Envia Lista de Bairros
          //
          dmPrincipal.CriaQRY('AUX').Close;
          dmPrincipal.CriaQRY('AUX').SQL.Clear;
          dmPrincipal.CriaQRY('AUX')
            .SQL.Add('SELECT * FROM taxa_entrega where upper(cidade) like ' +
            QuotedStr('%' + Conversa.DadosEnderecoCliente.Cidade + '%'));
          dmPrincipal.CriaQRY('AUX').Open;

          if dmPrincipal.CriaQRY('AUX').RecordCount = 0 then
          begin
            Mensagem := 'Lamentamos mais não atendemos a cidade de *' +
              Conversa.DadosEnderecoCliente.Cidade + '*!';
            Conversa.Etapa := 0;
            Conversa.Situacao := NovoCliente;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
            exit;
          end
          else
          begin
            I := 0;
            dmPrincipal.CriaQRY('AUX').First;
            Mensagem := '*Informe o código do seu bairro!*' +
              MENSAGEM_QUEBRA_LINHA_DUPLA;
            while not dmPrincipal.CriaQRY('AUX').Eof do
            begin
              inc(I);
              // Conversa.DadosEnderecoCliente.Bairro := dmPrincipal.CriaQRY('AUX').FieldByName('bairro').AsString;

              if Conversa.DadosEnderecoCliente.Bairro = dmPrincipal.CriaQRY
                ('AUX').FieldByName('bairro').AsString then
              begin
                Mensagem := Mensagem + '*' + FormatFloat('00', I) + '* - ```' +
                  dmPrincipal.CriaQRY('AUX').FieldByName('bairro').AsString +
                  '```' + ' *- SEU BAIRRO*' + MENSAGEM_QUEBRA_LINHA;
                Conversa.DadosEnderecoCliente.Bairro :=
                  dmPrincipal.CriaQRY('AUX').FieldByName('bairro').AsString;
                Conversa.Etapa := 11;
                Conversa.Resposta := '';
                dmPrincipal.GravaConversa(Conversa);
                Endereco(Conversa);
                exit;
              end
              else
              begin
                Mensagem := Mensagem + '*' + FormatFloat('00', I) + '* - ' +
                  dmPrincipal.CriaQRY('AUX').FieldByName('bairro').AsString +
                  MENSAGEM_QUEBRA_LINHA;
              end;

              dmPrincipal.CriaQRY('AUX').Next;
            end;
            dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
            exit;
          end;
        end
        else
        begin
          try
            strtoint(Conversa.Resposta);
          except
            dmPrincipal.Enviamensagem(Conversa.Etapa, Conversa.Pergunta,
              Conversa);
            exit;
          end;

          dmPrincipal.CriaQRY('AUX').Close;
          dmPrincipal.CriaQRY('AUX').SQL.Clear;
          dmPrincipal.CriaQRY('AUX')
            .SQL.Add('SELECT * FROM taxa_entrega where upper(cidade) like ' +
            QuotedStr('%' + Conversa.DadosEnderecoCliente.Cidade + '%'));
          dmPrincipal.CriaQRY('AUX').Open;

          dmPrincipal.CriaQRY('AUX').First;

          while not dmPrincipal.CriaQRY('AUX').Eof do
          begin
            inc(I);
            if I = strtoint(Conversa.Resposta) then
            begin
              Conversa.DadosEnderecoCliente.Bairro := dmPrincipal.CriaQRY('AUX')
                .FieldByName('bairro').AsString;
              Conversa.Etapa := 11;
              Conversa.Resposta := '';
              dmPrincipal.GravaConversa(Conversa);
              Endereco(Conversa);
              exit;
            end;
            dmPrincipal.CriaQRY('AUX').Next;
          end;

        end;

      end;
    13:
      begin
        // Numero
        Mensagem := '*Informe o número da casa/apartamento!*';
        Conversa.Etapa := 14;
        dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
      end;
    14:
      begin
        if Conversa.DadosEnderecoCliente.EnderecoComNumero = '' then
        begin
          if (length(Conversa.Resposta) = 0) or (length(Conversa.Resposta) > 250)
          then
          begin
            Conversa.Etapa := 13;
            Conversa.Resposta := '';
            dmPrincipal.GravaConversa(Conversa);
            Endereco(Conversa);
            exit;
          end;
          Conversa.DadosEnderecoCliente.EnderecoComNumero := Conversa.Resposta;
        end;

        Mensagem :=
          '*Descreva o complemento para melhor localizar seu endereço!*';
        Conversa.Etapa := 15;
        dmPrincipal.Enviamensagem(Conversa.Etapa, Mensagem, Conversa);
        exit;
        // Complemento
      end;
    15:
      begin
        if (length(Conversa.Resposta) = 0) or (length(Conversa.Resposta) > 250)
        then
        begin
          Conversa.Etapa := 14;
          Conversa.Resposta := '';
          dmPrincipal.GravaConversa(Conversa);
          Endereco(Conversa);
          exit;
        end;
        Conversa.DadosEnderecoCliente.EnderecoCompleto := Conversa.Resposta;

        Conversa.Etapa := 11;
        Conversa.Resposta := '';
        dmPrincipal.GravaConversa(Conversa);
        Endereco(Conversa);
      end;
  end;

end;

function TEndereco.TaxaDeEntrega(Conversa: TBotConversa): Real;
var
  QryAux: TFDQuery;
  SQL: String;
  KM : Real;
begin
  if Conversa.CodigoEndereco = 0 then
  begin
    Result := 0;
    exit;
  end;
  try
    QryAux := dmPrincipal.CriaQRY('AUX');

    QryAux.Close;
    QryAux.SQL.Clear;
    QryAux.SQL.Add('SELECT * FROM taxa_entrega where bairro = ' +
      QuotedStr(Conversa.DadosEnderecoCliente.Bairro) + ' and cidade = ' +
      QuotedStr(Conversa.DadosEnderecoCliente.Cidade));
    QryAux.Open;

    if QryAux.RecordCount > 0 then
    begin
      Result := QryAux.FieldByName('valor_taxa').AsFloat;
      QryAux.Free;
      exit;
    end;
    if dm.DADOS_EMPRESA.FieldByName('TAXA_POR_KM').AsInteger = 1 then
    begin
      SQL := 'SELECT * FROM taxa_por_km where km < ' +
        FloatToStr(Conversa.DadosEnderecoCliente.KM) + ' or km = ' +
        FloatToStr(Conversa.DadosEnderecoCliente.KM) + ' order by km desc';
      SQL := StringReplace(SQL, ',', '.', [rfReplaceAll]);
      QryAux.Close;
      QryAux.SQL.Clear;
      QryAux.SQL.Add(SQL);

      QryAux.Open;

      Result := QryAux.FieldByName('valor_fixo').AsFloat;
      KM := Conversa.DadosEnderecoCliente.KM;
      if KM < 1 then
      KM := 1;
      if Result = 0 then
        Result := Round(QryAux.FieldByName('valor_por_km').AsFloat *
          KM);
      QryAux.Free;
      exit;
    end;
  except
    Result := 0;
  end;
  Result := dm.DADOS_EMPRESA.FieldByName('taxa_entrega').AsFloat;
  exit;
end;

function TEndereco.ValidaEndereco(Bairro, Cidade, Estado: String): Boolean;
begin

  dm.CriaQRY('VALIDAEND').Close;
  dm.CriaQRY('VALIDAEND').SQL.Clear;
  dm.CriaQRY('VALIDAEND').SQL.Add('SELECT * FROM taxa_entrega where cidade = ' +
    QuotedStr(Cidade) + ' and bairro = ' + QuotedStr(Bairro) + ' and estado = '
    + QuotedStr(Estado) + ' and ativo = 1');
  dm.CriaQRY('VALIDAEND').Open;

  Result := dm.CriaQRY('VALIDAEND').RecordCount > 0;

  if not Result then
  begin

    if not dm.CriaTabela('bairros_sem_atendimento', 'id')
      .Locate('cidade;bairro;estado', VarArrayOf([Cidade, Bairro, Estado]), [])
    then
    begin
      dm.CriaTabela('bairros_sem_atendimento', 'id').Insert;
      dm.CriaTabela('bairros_sem_atendimento', 'id').FieldByName('id').AsInteger
        := dm.GerarID('bairros_sem_atendimento', 'id');
      dm.CriaTabela('bairros_sem_atendimento', 'id').FieldByName('cidade')
        .AsString := Cidade;
      dm.CriaTabela('bairros_sem_atendimento', 'id').FieldByName('estado')
        .AsString := Estado;
      dm.CriaTabela('bairros_sem_atendimento', 'id').FieldByName('bairro')
        .AsString := Bairro;
      dm.CriaTabela('bairros_sem_atendimento', 'id').Post;
    end;

  end;

end;

function TCidade.CidadeFazParte(txCidade: String): Boolean;
var
  I: Integer;
begin
  // Cidade := '';
  // txCidade := UpperCase(RemoveAcento(txCidade));
  // So se tiver com o paremetro ativo
  Result := True;
end;

{ TDadosEndereco }

procedure TDadosEndereco.SetKM(const Value: Real);
begin
  FKM := Value;
end;

end.
