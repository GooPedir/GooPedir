unit uSite;

interface

uses util, conexao, FireDAC.Comp.Client, DataSet.Serialize, System.SysUtils,
  uLogThread;

function EnviaCategoria(codigo: Integer): Integer;
function EnviaProduto(codigo: Integer; Base64Imagem: String): Integer;
procedure EnviaSabores(codigoGrupo: Integer);

procedure EnviaFotoProduto(codigo: Integer; Base64: String);

procedure EnviaTempoDelivery(Tempo: Integer);
procedure EnviaTempoVemBuscar(Tempo: Integer);

implementation

uses uMain, System.Classes, uRequisicao, uControllCaches;

procedure EnviaTempoDelivery(Tempo: Integer);
begin
  InserirUpdate('ws_empresa', frmServidor.UserID.ToString,
    ['user_id', 'msg_tempo_delivery'], [frmServidor.UserID.ToString,
    'Aproximado ' + IntToStr(Tempo) + ' minutos.']);
end;

procedure EnviaTempoVemBuscar(Tempo: Integer);
begin
  InserirUpdate('ws_empresa', frmServidor.UserID.ToString,
    ['user_id', 'msg_tempo_buscar'], [frmServidor.UserID.ToString,
    'Aproximado ' + IntToStr(Tempo) + ' minutos.']);
end;

function EnviaCategoria(codigo: Integer): Integer;
var
  conexao: TConexao;
  Query: TFDQuery;
begin
  conexao := TConexao.Create('uSite');
  Query := conexao.CriaQRY;
  try
    Query.SQL.Text := 'select * from tipo_produto where codigo = :codigo';
    Query.ParamByName('codigo').AsInteger := codigo;
    Query.Open;

    Result := InserirUpdate('ws_cat', frmServidor.UserID.ToString,
      ['id', 'user_id', 'dias_semana', 'nome_cat', 'desc_cat', 'icon_cat',
      'ordem', 'descricao', 'borda_topo_direito', 'borda_topo_esquerdo',
      'borda_inferior_direito', 'borda_inferior_esquerdo', 'espacamento',
      'fonte_nome', 'fonte_descricao', 'cor_fundo', 'cor_nome',
      'cor_descricao'], [Query.FieldByName('id_site').AsString,
      frmServidor.UserID.ToString,
      'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado',
      Query.FieldByName('descricao').AsWideString, '', '',
      Query.FieldByName('ordem').AsString, Query.FieldByName('descricao_cat')
      .AsWideString, Query.FieldByName('borda_topo_direito').AsWideString,
      Query.FieldByName('borda_topo_esquerdo').AsWideString,
      Query.FieldByName('borda_inferior_direito').AsWideString,
      Query.FieldByName('borda_inferior_esquerdo').AsWideString,
      Query.FieldByName('espacamento').AsWideString,
      Query.FieldByName('fonte_nome').AsWideString,
      Query.FieldByName('fonte_descricao').AsWideString,
      Query.FieldByName('cor_fundo').AsWideString, Query.FieldByName('cor_nome')
      .AsWideString, Query.FieldByName('cor_descricao').AsWideString]);

    if Result > 0 then
    begin
      Query.SQL.Text :=
        'update tipo_produto set modificado_site = 1, id_site = :site where codigo = :codigo';
      Query.ParamByName('site').AsInteger := Result;
      Query.ParamByName('codigo').AsInteger := codigo;
      Query.ExecSQL;
    end;

  finally
    Query.Free;
    conexao.Free;
  end;
end;

function EnviaProduto(codigo: Integer; Base64Imagem: String): Integer;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      conexao: TConexao;
      Dados: TFDQuery;
      DadosExtra: TFDQuery;
      DadosExtraItem: TFDQuery;
      CodigoExtra: Integer;
      Result: Integer;
      Query: TFDQuery;
    begin
      LogThread('EnviaProduto', 'Iniciando');
      GetAllProduto(codigo);
      if frmServidor.UserID = 0 then
      begin
        conexao := TConexao.Create('EnviaProduto');
        conexao.SQL.Add('update produto set new = 0 where codigo = :codigo');
        conexao.Parametros('codigo', codigo);
        conexao.ExecuteSQL;

        exit;
      end;

      try
        conexao := TConexao.Create('uSite');
        Dados := conexao.CriaQRY;
        Dados.SQL.Text := ('select * from produto where codigo = :codigo');
        Dados.ParamByName('codigo').AsInteger := codigo;
        frmServidor.AddLog('Enviando');

        Dados.Open;
        // Dados.Edit;
        // if Dados.FieldByName('id_site').IsNull then
        // Dados.FieldByName('id_site').AsInteger := 0;

        // Result := InserirUpdate('ws_itens', frmServidor.UserID.ToString,
        // ['id', 'user_id', 'img_item', 'config_total_s', 'dia_semana',
        // 'number_adicional', 'number_adicional_pago', 'posicao', 'id_cat',
        // 'nome_item', 'descricao_item', 'preco_item', 'disponivel',
        // 'valor_delivery', 'estoque', 'img_ifood', 'pessoas', 'promo_valor',
        // 'promo_percentual', 'disponivel', 'fidelidade_valor','novidade','vembuscar','delivery'],
        // [Dados.FieldByName('id_site').AsString, frmServidor.UserID.ToString,
        // 'false', '0', 'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado',
        // '0', '0', codigo.ToString,
        // EnviaCategoria(Dados.FieldByName('codigo_grupo').AsInteger)
        // .ToString, Dados.FieldByName('nome_produto').AsString,
        // Dados.FieldByName('descricao').AsString,
        // Dados.FieldByName('valor_venda').AsString, '1', Dados.FieldByName('valor_embalagem_delivery').AsString,
        // Dados.FieldByName('saldo_atual').AsString, '',
        // Dados.FieldByName('pessoas').AsString, Dados.FieldByName('valor_venda').AsString, Dados.FieldByName('percentual_desconto').AsString,
        // Dados.FieldByName('ativo').AsString, Dados.FieldByName('fidelidade')
        // .AsString,Dados.FieldByName('novidade').AsString,Dados.FieldByName('vembuscar').AsString,Dados.FieldByName('delivery').AsString]);

        if Dados.FieldByName('valor_desconto').AsFloat > 0 then
        begin
          Result := InserirUpdate('ws_itens', frmServidor.UserID.ToString,
            ['id', 'user_id', 'img_item', 'config_total_s', 'dia_semana',
            'number_adicional', 'number_adicional_pago', 'posicao', 'id_cat',
            'nome_item', 'descricao_item', 'preco_item', 'disponivel',
            'valor_delivery', 'estoque', 'img_ifood', 'pessoas', 'promo_valor',
            'promo_percentual', 'disponivel', 'fidelidade_valor', 'novidade'],
            [Dados.FieldByName('id_site').AsString, frmServidor.UserID.ToString,
            'false', '0', 'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado',
            '0', '0', codigo.ToString,
            EnviaCategoria(Dados.FieldByName('codigo_grupo').AsInteger)
            .ToString, Dados.FieldByName('nome_produto').AsWideString,
            Dados.FieldByName('descricao').AsWideString,
            Dados.FieldByName('valor_desconto').AsString, '1',
            Dados.FieldByName('valor_embalagem_delivery').AsString, '9999', '',
            Dados.FieldByName('pessoas').AsString,
            Dados.FieldByName('valor_venda').AsString,
            Dados.FieldByName('percentual_desconto').AsString,
            Dados.FieldByName('ativo').AsString, Dados.FieldByName('fidelidade')
            .AsString, Dados.FieldByName('novidade').AsString]);
        end
        else
        begin
          Result := InserirUpdate('ws_itens', frmServidor.UserID.ToString,
            ['id', 'user_id', 'config_total_s', 'dia_semana',
            'number_adicional', 'number_adicional_pago', 'posicao', 'id_cat',
            'nome_item', 'descricao_item', 'preco_item', 'disponivel',
            'valor_delivery', 'estoque', 'pessoas', 'promo_valor',
            'promo_percentual', 'disponivel', 'fidelidade_valor', 'novidade'],
            [Dados.FieldByName('id_site').AsString, frmServidor.UserID.ToString,
            '0', 'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado', '0', '0',
            codigo.ToString, EnviaCategoria(Dados.FieldByName('codigo_grupo')
            .AsInteger).ToString, Dados.FieldByName('nome_produto')
            .AsWideString, Dados.FieldByName('descricao').AsWideString,
            Dados.FieldByName('valor_venda').AsString, '1',
            Dados.FieldByName('valor_embalagem_delivery').AsString, '99999',
            Dados.FieldByName('pessoas').AsString, '0', '0',
            Dados.FieldByName('ativo').AsString, Dados.FieldByName('fidelidade')
            .AsString, Dados.FieldByName('novidade').AsString]);
        end;
        frmServidor.AddLog('Codigo: ' + Result.ToString);

        if Result > 0 then
        begin
          Query := conexao.CriaQRY;
          try
            Query.SQL.Text :=
              'update produto set modificado_site = 1, id_site = :site, new = 0 where codigo = :codigo';
            Query.ParamByName('site').AsInteger := Result;
            Query.ParamByName('codigo').AsInteger := codigo;
            Query.ExecSQL;
            frmServidor.AddLog('Update');

            if Base64Imagem <> '' then
            begin
              EnviaFotoProduto(Result, Base64Imagem);
            end;

            DadosExtra := conexao.CriaQRY;
            DadosExtraItem := conexao.CriaQRY;
            try
              // Seleciona adicionais personalizados do produto
              DadosExtra.SQL.Text :=
                'select * from pro_adi_personalizado where id_produto = :produto';
              DadosExtra.ParamByName('produto').AsInteger := codigo;
              DadosExtra.Open;

              if DadosExtra.RecordCount > 0 then
              begin
                while not DadosExtra.Eof do
                begin
                  if DadosExtra.FieldByName('id_site').IsNull then
                  begin
                    DadosExtra.Edit;
                    DadosExtra.FieldByName('id_site').AsInteger := 0;
                  end;

                  CodigoExtra := InserirUpdate('ws_adicionais_cat',
                    frmServidor.UserID.ToString, ['id', 'user_id', 'pay',
                    'img_cat', 'id_itens', 'id_cat', 'name_adicionais_cat',
                    'minimo', 'amount'],
                    [DadosExtra.FieldByName('id_site').AsWideString,
                    frmServidor.UserID.ToString, '1', '', Result.ToString,
                    DadosExtra.FieldByName('id_site').AsWideString,
                    DadosExtra.FieldByName('descricao').AsWideString,
                    DadosExtra.FieldByName('qtd_minima').AsWideString,
                    DadosExtra.FieldByName('qtd_maxima').AsWideString]);

                  Query.SQL.Text :=
                    'update pro_adi_personalizado set modificado_site = 1, id_site = :site where id = :codigo';
                  Query.ParamByName('site').AsInteger := CodigoExtra;
                  Query.ParamByName('codigo').AsInteger :=
                    DadosExtra.FieldByName('id').AsInteger;
                  Query.ExecSQL;

                  // Seleciona os itens adicionais personalizados
                  // DadosExtraItem.SQL.Text :=
                  // 'SELECT * FROM pro_adi_personalizado_sabores where id_pro_adi_personalizado = :codigo';
                  DadosExtraItem.SQL.Text :=
                    'SELECT pads.*, pad.id_site as codigo_grupo FROM pro_adi_personalizado_sabores as pads join pro_adi_personalizado as pad on pad.id = pads.id_pro_adi_personalizado where id_pro_adi_personalizado = :codigo';

                  DadosExtraItem.ParamByName('codigo').AsInteger :=
                    DadosExtra.FieldByName('id').AsInteger;
                  DadosExtraItem.Open;

                  if DadosExtraItem.RecordCount > 0 then
                  begin
                    while not DadosExtraItem.Eof do
                    begin
                      codigo := InserirUpdate('ws_adicionais_itens',
                        frmServidor.UserID.ToString, ['id_adicionais',
                        'user_id', 'categorias_adicional', 'id_adicionais_cat',
                        'medida_adicional', 'nome_adicional', 'valor_adicional',
                        'status_adicional', 'descricao'],
                        [DadosExtraItem.FieldByName('id_site').AsWideString,
                        frmServidor.UserID.ToString,
                        DadosExtra.FieldByName('id_site').AsWideString,
                        CodigoExtra.ToString, 'UN',
                        DadosExtraItem.FieldByName('nome').AsWideString,
                        DadosExtraItem.FieldByName('valor').AsWideString,
                        DadosExtraItem.FieldByName('ativo').AsWideString,
                        DadosExtraItem.FieldByName('descricao').AsWideString]);

                      Query.SQL.Text :=
                        'update pro_adi_personalizado_sabores set modificado_site = 1, id_site = :site where id = :codigo';
                      Query.ParamByName('site').AsInteger := codigo;
                      Query.ParamByName('codigo').AsInteger :=
                        DadosExtraItem.FieldByName('id').AsInteger;
                      Query.ExecSQL;

                      DadosExtraItem.Next;
                    end;
                  end;

                  DadosExtra.Next;
                end;
              end;
            finally
              DadosExtra.Free;
              DadosExtraItem.Free;
            end;
          finally
            Query.Free;
          end;
        end;

        EnviaSabores(Dados.FieldByName('codigo_grupo').AsInteger);
        conexao.Free;
        Dados.Free;

      except
        on e: exception do
        begin
          frmServidor.AddLog('CUCA ' + e.Message);
          LogThread('EnviaProduto', 'Erro: ' + e.Message);
        end;

      end;
      LogThread('EnviaProduto', 'Finaliza');
      // LimparCacheProduto;

    end).Start;
end;

procedure EnviaFotoProduto(codigo: Integer; Base64: String);
var
  Requisicao: iRequisicao;
  conexao: TConexao;
begin

  Requisicao := iRequisicao.Create(nil);
  Requisicao.BaseURL := 'https://fotos.goopedir.com/';
  Requisicao.AddHEader('nome', codigo.ToString);
  Requisicao.AddHEader('Content-Type', 'application/json');
  Requisicao.Metodo := mPost;
  Requisicao.BODY(Base64);
  Requisicao.TempoExpiracao := 15 * 1000;
  try
    Requisicao.Execute;
  except

  end;

  conexao := TConexao.Create('uSite');
  conexao.SQL.Add('update produto set caminho_imagem = concat(' +
    QuotedStr('https://fotos.goopedir.com/fotos/') +
    ',TO_BASE64(:img)) where id_site = :codigo');
  conexao.Parametros('img', codigo);
  conexao.Parametros('codigo', codigo);
  conexao.ExecuteSQL;
  conexao.Free;

  Requisicao.Free;

end;

procedure EnviaSabores(codigoGrupo: Integer);
var
  conexao: TConexao;
  Query: TFDQuery;
  codigo: Integer;
  SQL: String;
begin
  conexao := TConexao.Create('uSite');
  Query := conexao.CriaQRY;

  try
    Query.SQL.Text :=
      'SELECT cs.id, cs.id_site, cs.nome, cs.descricao, cs.vl_venda as valor, cs.ativo, ts.nome as tipo, '
      + 'p.id_site as id_itens, pp.quantidade_sabores as qtd_sabor, ' +
      '(SELECT tipo_preco_pizza FROM dados_whatsapp limit 1) as tipo_valor ' +
      'FROM sabores_completo as cs ' +
      'join tipo_sabor as ts on ts.id = cs.id_tipo_sabor ' +
      'join produto as p on p.codigo = cs.id_produto ' +
      'join produto_pizza as pp on pp.codigo_produto = p.codigo ' +
      'where p.codigo_grupo = :codigo';
    Query.ParamByName('codigo').AsInteger := codigoGrupo;
    Query.Open;

    if Query.RecordCount > 0 then
    begin
      while not Query.Eof do
      begin
        codigo := InserirUpdate('ws_sabores', frmServidor.UserID.ToString,
          ['id', 'user_id', 'id_itens', 'qtd_sabor', 'ativo', 'tipo_valor',
          'valor', 'tipo', 'sabor', 'descricao'],
          [Query.FieldByName('id_site').AsWideString,
          frmServidor.UserID.ToString, Query.FieldByName('id_itens')
          .AsWideString, Query.FieldByName('qtd_sabor').AsWideString,
          Query.FieldByName('ativo').AsWideString,
          Query.FieldByName('tipo_valor').AsWideString,
          Query.FieldByName('valor').AsWideString, Query.FieldByName('tipo')
          .AsWideString, Trim(Query.FieldByName('nome').AsWideString),
          Trim(Query.FieldByName('descricao').AsWideString)]);

        if codigo > 0 then
        begin
          SQL := 'update sabores_completo set modificado_site = 1 where id = ' +
            Query.FieldByName('id').AsWideString;
          conexao.ExecuteSQL(SQL);

          SQL := 'update sabores_completo set id_site = ' + codigo.ToString +
            ' where id = ' + Query.FieldByName('id').AsWideString;
          conexao.ExecuteSQL(SQL);
        end;

        Query.Next;
      end;
    end;

  finally
    Query.Free;
    conexao.Free;
  end;
end;

end.
