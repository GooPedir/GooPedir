unit uSite;

interface

uses util, conexao, FireDAC.Comp.Client, DataSet.Serialize, System.SysUtils;

function EnviaCategoria(codigo: Integer): Integer;
function EnviaProduto(codigo: Integer): Integer;

procedure EnviaFotoProduto(codigo: Integer; Base64: String);

implementation

uses uMain, System.Classes, uRequisicao;

function EnviaCategoria(codigo: Integer): Integer;
var
  conexao: TConexao;
  Dados: TFDMemTable;
begin
  conexao := TConexao.Create;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from tipo_produto where codigo = :codigo');
  conexao.Parametros('codigo', codigo);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  Dados.Edit;

  if Dados.FieldByName('id_site').IsNull then
    Dados.FieldByName('id_site').AsInteger := 0;

  Result := InserirUpdate('ws_cat', frmServidor.UserID.ToString,
    ['id', 'user_id', 'dias_semana', 'nome_cat', 'desc_cat', 'icon_cat',
    'ordem'], [Dados.FieldByName('id_site').AsString,
    frmServidor.UserID.ToString,
    'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado',
    Dados.FieldByName('descricao').AsString, '', '', Dados.FieldByName('ordem')
    .AsString]);
  if Result > 0 then
  begin
    conexao.SQL.Add
      ('update tipo_produto set modificado_site = 1, id_site = :site where codigo = :codigo');
    conexao.Parametros('site', Result);
    conexao.Parametros('codigo', codigo);
    conexao.ExecuteSQL;
  end;
  Dados.Free;
  conexao.Free;
end;

function EnviaProduto(codigo: Integer): Integer;
var
  conexao: TConexao;
  Dados: TFDMemTable;
  DadosExtra: TFDMemTable;
  DadosExtraItem: TFDMemTable;
  CodigoExtra: Integer;
begin
  conexao := TConexao.Create;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from produto where codigo = :codigo');
  conexao.Parametros('codigo', codigo);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  Dados.Edit;
  if Dados.FieldByName('id_site').IsNull then
    Dados.FieldByName('id_site').AsInteger := 0;

  Result := InserirUpdate('ws_itens', frmServidor.UserID.ToString,
    ['id', 'user_id', 'img_item', 'config_total_s', 'dia_semana',
    'number_adicional', 'number_adicional_pago', 'posicao', 'id_cat',
    'nome_item', 'descricao_item', 'preco_item', 'disponivel', 'valor_delivery',
    'estoque', 'img_ifood', 'pessoas', 'promo_valor', 'promo_percentual',
    'disponivel'], [Dados.FieldByName('id_site').AsString,
    frmServidor.UserID.ToString, 'false', '0',
    'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado', '0', '0',
    codigo.ToString, EnviaCategoria(Dados.FieldByName('codigo_grupo').AsInteger)
    .ToString, Dados.FieldByName('nome_produto').AsString,
    Dados.FieldByName('descricao').AsString, Dados.FieldByName('valor_venda')
    .AsString, '1', '0', Dados.FieldByName('saldo_atual').AsString, '',
    Dados.FieldByName('pessoas').AsString, Dados.FieldByName('valor_desconto')
    .AsString, Dados.FieldByName('percentual_desconto').AsString,
    Dados.FieldByName('ativo').AsString]);

  if Result > 0 then
  begin
    conexao.SQL.Add
      ('update produto set modificado_site = 1, id_site = :site where codigo = :codigo');
    conexao.Parametros('site', Result);
    conexao.Parametros('codigo', codigo);
    conexao.ExecuteSQL;

    //
    DadosExtra := TFDMemTable.Create(nil);
    DadosExtraItem := TFDMemTable.Create(nil);
    conexao.SQL.Add
      ('select * from pro_adi_personalizado where id_produto = :produto');
    conexao.Parametros('produto', codigo);
    DadosExtra.LoadFromJSON(conexao.ConsultaSQL);

    if DadosExtra.RecordCount > 0 then
    begin
      while not DadosExtra.Eof do
      begin
        DadosExtra.Edit;
        if DadosExtra.FieldByName('id_site').IsNull then
          DadosExtra.FieldByName('id_site').AsInteger := 0;

        CodigoExtra := InserirUpdate('ws_adicionais_cat',
          frmServidor.UserID.ToString, ['id', 'user_id', 'pay', 'img_cat',
          'id_itens', 'id_cat', 'name_adicionais_cat', 'minimo', 'amount'],
          [DadosExtra.FieldByName('id_site').AsString,
          frmServidor.UserID.ToString, '1', '', Result.ToString,
          Dados.FieldByName('codigo_grupo').AsString,
          DadosExtra.FieldByName('descricao').AsString,
          DadosExtra.FieldByName('qtd_minima').AsString,
          DadosExtra.FieldByName('qtd_maxima').AsString]);

        conexao.SQL.Add
          ('update pro_adi_personalizado set modificado_site = 1, id_site = :site where id = :codigo');
        conexao.Parametros('site', codigo);
        conexao.Parametros('codigo', DadosExtra.FieldByName('id').AsString);
        conexao.ExecuteSQL;

        DadosExtraItem.Close;
        conexao.SQL.Add
          ('SELECT * FROM pro_adi_personalizado_sabores where id_pro_adi_personalizado = :codigo');
        conexao.Parametros('codigo', DadosExtra.FieldByName('id').AsString);
        DadosExtraItem.LoadFromJSON(conexao.ConsultaSQL);

        if DadosExtraItem.RecordCount > 0 then
        begin
          while not DadosExtraItem.Eof do
          begin
            codigo := InserirUpdate('ws_adicionais_itens',
              frmServidor.UserID.ToString, ['id_adicionais', 'user_id',
              'categorias_adicional', 'id_adicionais_cat', 'medida_adicional',
              'nome_adicional', 'valor_adicional', 'status_adicional',
              'descricao'], [DadosExtraItem.FieldByName('id_site').AsString,
              frmServidor.UserID.ToString, Dados.FieldByName('codigo_grupo')
              .AsString, CodigoExtra.ToString, 'UN',
              DadosExtraItem.FieldByName('nome').AsString,
              DadosExtraItem.FieldByName('valor').AsString,
              DadosExtraItem.FieldByName('ativo').AsString,
              DadosExtraItem.FieldByName('descricao').AsString]);

            conexao.SQL.Add
              ('update pro_adi_personalizado_sabores set modificado_site = 1, id_site = :site where id = :codigo');
            conexao.Parametros('site', codigo);
            conexao.Parametros('codigo', DadosExtraItem.FieldByName('id')
              .AsString);
            conexao.ExecuteSQL;

            DadosExtraItem.Next;
          end;
        end;

        DadosExtra.Next;
      end;

    end;

  end;
  conexao.Free;
  Dados.Free;
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
  Requisicao.Execute;
  conexao := TConexao.Create;
  conexao.SQL.Add('update produto set caminho_imagem = concat(' +
    QuotedStr('https://fotos.goopedir.com/fotos/') +
    ',TO_BASE64(:img)) where id_site = :codigo');
  conexao.Parametros('img', codigo);
  conexao.Parametros('codigo', codigo);
  conexao.ExecuteSQL;
  conexao.Free;

  Requisicao.Free;

end;

end.
