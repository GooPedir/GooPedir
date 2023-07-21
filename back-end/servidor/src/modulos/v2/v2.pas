unit v2;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions;

procedure Registry;

implementation

uses FireDAC.Stan.Option, token, conexao, JOSE.Types.JSON, System.Classes,
  Data.DB, IdWinsock2, Vcl.Dialogs, Vcl.ExtCtrls, Horse.Upload, System.Types,
  Winapi.Windows, uMain, System.StrUtils, Vcl.StdCtrls, util, uSite;

procedure DoGetCaetegory(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create;

  conexao.SQL.Add('SELECT produto.codigo as id,');
  conexao.SQL.Add('produto.nome_produto as name,');
  conexao.SQL.Add('produto.descricao as description,');
  conexao.SQL.Add('produto.ativo as status,');
  conexao.SQL.Add('produto_pizza.quantidade_sabores as sabores');
  conexao.SQL.Add('FROM produto');
  conexao.SQL.Add
    ('join produto_pizza on produto_pizza.codigo_produto = produto.codigo');
  conexao.SQL.Add('where produto.codigo_grupo = :grupo');
  conexao.Parametros('grupo', Req.Params['category']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

end;

procedure DoPostCategory(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  DadosTipo: TFDMemTable;

  JSONString: string;
  JSONValue: TJSONValue;
  JSONObject: TJSONObject;
  ProductArray: TJSONArray;
  ProductItem: TJSONObject;
  I: Integer;
  CodigoGrupo: Integer;
  CodigoAux: Integer;
  Aux: Integer;

begin
  conexao := TConexao.Create;
  DadosTipo := TFDMemTable.Create(nil);

  // Fazer o parsing do JSON
  JSONValue := TJSONObject.ParseJSONValue(Req.Body);

  // Verificar se o JSON foi parseado com sucesso
  if Assigned(JSONValue) and (JSONValue is TJSONObject) then
  begin
    // Converter o JSONValue para um TJSONObject
    JSONObject := JSONValue as TJSONObject;
    conexao.SQL.Add('select * from tipo_produto where codigo = :codigo');
    conexao.Parametros('codigo', JSONObject.Values['id'].Value);
    DadosTipo.LoadFromJSON(conexao.ConsultaSQL);

    if DadosTipo.RecordCount = 0 then
    begin
      CodigoGrupo := conexao.GerarID('tipo_produto', 'codigo');
      conexao.SQL.Add
        ('insert into tipo_produto (codigo,descricao,impressora,pizza,visivel_delivery,visivel_vem_buscar)');
      conexao.SQL.Add('values (:codigo,:descricao,:impressora,:pizza,1,1)');
      conexao.Parametros('codigo', CodigoGrupo);
      conexao.Parametros('descricao', JSONObject.Values['name'].Value);
      conexao.Parametros('impressora', JSONObject.Values['printer'].Value);
      if (JSONObject.Values['type'].Value = '1') then
        conexao.Parametros('pizza', 0)
      else
        conexao.Parametros('pizza', 1);
      conexao.ExecuteSQL;
    end
    else
    begin
      conexao.SQL.Add
        ('update tipo_produto set descricao = :descricao, impressora = :impressora where codigo = :codigo');
      conexao.Parametros('codigo', DadosTipo.FieldByName('codigo').AsInteger);
      conexao.Parametros('descricao', JSONObject.Values['name'].Value);
      conexao.Parametros('impressora', JSONObject.Values['printer'].Value);
      conexao.ExecuteSQL;
    end;

    // Enviar categoria
    // EnviaCategoria(StrToInt(JSONObject.Values['category'].Value)

    // Ler o array "product"
    ProductArray := JSONObject.Values['product'] as TJSONArray;

    // Iterar sobre os itens do array "product"
    for I := 0 to ProductArray.Count - 1 do
    begin
      //
      ProductItem := ProductArray.Items[I] as TJSONObject;

      if (ProductItem.Values['id'].Value = '0') then
      begin
        CodigoAux := conexao.GerarID('produto', 'codigo');
        conexao.SQL.Add
          ('insert into produto (codigo,codigo_interno,data_cadastro,nome_produto,descricao,codigo_grupo,valor_venda,ativo,position)');
        conexao.SQL.Add
          ('values (:codigo,:codigo_interno,current_date,:nome_produto,:descricao,:codigo_grupo,0,;ativo,:position)');
        conexao.Parametros('codigo', CodigoAux);
        conexao.Parametros('codigo_interno', CodigoAux);
        conexao.Parametros('codigo_grupo', CodigoGrupo);
        conexao.Parametros('nome_produto', ProductItem.Values['name'].Value);
        conexao.Parametros('descricao',
          ProductItem.Values['description'].Value);
        conexao.Parametros('ativo', ProductItem.Values['status'].Value);
        conexao.Parametros('position', I + 1);
        conexao.ExecuteSQL;

        if (JSONObject.Values['type'].Value = '2') then
        begin
          Aux := conexao.GerarID('produto_pizza', 'codigo');
          conexao.SQL.Add
            ('insert into produto_pizza (codigo,codigo_produto,quantidade_sabores,borda,ativo)');
          conexao.SQL.Add
            ('values (:codigo,:codigo_produto,:quantidade_sabores,0,1)');
          conexao.Parametros('codigo', Aux);
          conexao.Parametros('codigo_produto', CodigoAux);
          conexao.Parametros('quantidade_sabores',
            ProductItem.Values['qtd'].Value);
          conexao.ExecuteSQL;
        end;
      end
      else
      begin
        conexao.SQL.Add
          ('update produto set nome_produto = :nome, descricao = :descricao, ativo = :ativo, position = :position where codigo = :codigo');
        conexao.Parametros('nome', ProductItem.Values['name'].Value);
        conexao.Parametros('descricao',
          ProductItem.Values['description'].Value);
        conexao.Parametros('ativo', ProductItem.Values['status'].Value);
        conexao.Parametros('position', I + 1);
        conexao.Parametros('codigo', ProductItem.Values['id'].Value);
        conexao.ExecuteSQL;

        conexao.SQL.Add
          ('update produto_pizza set quantidade_sabores = :qtd where codigo_produto = :codigo');
        conexao.Parametros('codigo', ProductItem.Values['id'].Value);
        conexao.Parametros('qtd', ProductItem.Values['qtd'].Value);
        conexao.ExecuteSQL;
      end;
    end;
    DadosTipo.Free;
  end;

  JSONValue.Free; // Liberar a memória alocada pelo JSONValue
  conexao.Free;
end;

procedure DoPostProduct(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  JSONValue: TJSONValue;
  JSONObject: TJSONObject;
  DadosProduto: TFDMemTable;

  ExtraArray: TJSONArray;
  ExtraItem: TJSONObject;

  ExtraItensArray: TJSONArray;
  ExtraItensItem: TJSONObject;

  Site: Integer;
  Position: Integer;
  Codigo: Integer;
  CategoriaSite: Integer;
  I: Integer;
  CodigoExtra: Integer;
  CodigoAux: Integer;
  K: Integer;

begin
  conexao := TConexao.Create;
  DadosProduto := TFDMemTable.Create(nil);
  // Fazer o parsing do JSON
  JSONValue := TJSONObject.ParseJSONValue(Req.Body);

  // Verificar se o JSON foi parseado com sucesso
  if Assigned(JSONValue) and (JSONValue is TJSONObject) then
  begin
    JSONObject := JSONValue as TJSONObject;
    conexao.SQL.Add('select * from produto where codigo = :codigo');
    conexao.Parametros('codigo', JSONObject.Values['id'].Value);
    DadosProduto.LoadFromJSON(conexao.ConsultaSQL);

    if DadosProduto.RecordCount = 0 then
    begin
      // Envia

      conexao.SQL.Add
        ('select max(position)+1 as max, 0 as zero from produto where codigo_grupo = :codigo_grupo');
      conexao.Parametros('codigo_grupo', JSONObject.Values['category'].Value);
      try
        Position := conexao.FieldByName('max');
      except
        Position := 1;
      end;
      Codigo := conexao.GerarID('produto', 'codigo');

      conexao.SQL.Add
        ('insert into produto (codigo,codigo_interno,data_cadastro,nome_produto,descricao,codigo_grupo,valor_venda,controle_estoque,caminho_imagem,usa_tabela_preco,position, pessoas, valor_desconto, percentual_desconto, saldo_atual, ativo)');
      conexao.SQL.Add
        ('values (:codigo,:codigo_interno,current_date,:nome_produto,:descricao,:codigo_grupo,:valor_venda,:controle_estoque,:caminho_imagem,:usa_tabela_preco,:position, :pessoas, :valor_desconto, :percentual_desconto, :saldo_atual,1)');
      conexao.Parametros('codigo', Codigo);
      conexao.Parametros('codigo_interno', Codigo);
      conexao.Parametros('nome_produto', JSONObject.Values['name'].Value);
      conexao.Parametros('descricao', JSONObject.Values['description'].Value);
      conexao.Parametros('codigo_grupo', JSONObject.Values['category'].Value);
      conexao.Parametros('valor_venda', JSONObject.Values['value'].Value);
      conexao.Parametros('controle_estoque', JSONObject.Values['stock'].Value);
      conexao.Parametros('caminho_imagem', '');
      conexao.Parametros('usa_tabela_preco', 0);
      conexao.Parametros('position', Position);
      conexao.Parametros('pessoas', JSONObject.Values['people'].Value);
      conexao.Parametros('valor_desconto',
        JSONObject.Values['value_discont'].Value);
      conexao.Parametros('percentual_desconto',
        JSONObject.Values['value_percent'].Value);
      conexao.Parametros('saldo_atual', JSONObject.Values['quanty'].Value);

      conexao.ExecuteSQL;
    end
    else
    begin
      // Update
      try
        Site := DadosProduto.FieldByName('id_site').AsInteger;
      except

      end;

      Codigo := DadosProduto.FieldByName('codigo').AsInteger;

      // update produto set nome_produto = :nome_produto, descricao = :descricao, codigo_grupo = :codigo_grupo, valor_venda = :valor_venda
      conexao.SQL.Add
        ('update produto set nome_produto = :nome_produto, descricao = :descricao, codigo_grupo = :codigo_grupo, valor_venda = :valor_venda,');
      conexao.SQL.Add
        ('controle_estoque = :controle_estoque, pessoas = :pessoas, valor_desconto = :valor_desconto,');
      conexao.SQL.Add
        ('percentual_desconto = :percentual_desconto, saldo_atual = :saldo_atual');
      conexao.SQL.Add('where codigo = :codigo');
      conexao.Parametros('nome_produto', JSONObject.Values['name'].Value);
      conexao.Parametros('descricao', JSONObject.Values['description'].Value);
      conexao.Parametros('codigo_grupo', JSONObject.Values['category'].Value);
      conexao.Parametros('valor_venda', JSONObject.Values['value'].Value);
      conexao.Parametros('controle_estoque', JSONObject.Values['stock'].Value);
      conexao.Parametros('pessoas', JSONObject.Values['people'].Value);
      conexao.Parametros('valor_desconto',
        JSONObject.Values['value_discont'].Value);
      conexao.Parametros('percentual_desconto',
        JSONObject.Values['value_percent'].Value);
      conexao.Parametros('saldo_atual', JSONObject.Values['quanty'].Value);
      conexao.Parametros('codigo', JSONObject.Values['id'].Value);
      conexao.ExecuteSQL;
    end;

    ExtraArray := JSONObject.Values['extra'] as TJSONArray;

    for I := 0 to ExtraArray.Count - 1 do
    begin
      ExtraItem := ExtraArray.Items[I] as TJSONObject;
      if (ExtraItem.Values['id'].Value = '0') then
      begin
        //
        // CodigoExtra : Integer;
        // CodigoAux : Integer;
        CodigoExtra := conexao.GerarID('pro_adi_personalizado', 'id');
        conexao.SQL.Add
          ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima)');
        conexao.SQL.Add
          ('values(:id,:id_produto,:descricao,:ativo,:qtd_minima,:qtd_maxima)');
      end
      else
      begin
        CodigoExtra := StrToInt(ExtraItem.Values['id'].Value);
        conexao.SQL.Add
          ('update pro_adi_personalizado set id_produto = :id_produto, descricao = :descricao, ativo = :ativo, qtd_minima = :qtd_minima, qtd_maxima = :qtd_maxima where id = :id');
      end;
      conexao.Parametros('id', CodigoExtra);
      conexao.Parametros('id_produto', Codigo);
      conexao.Parametros('descricao', ExtraItem.Values['name'].Value);
      conexao.Parametros('ativo', ExtraItem.Values['status'].Value);
      conexao.Parametros('qtd_minima', ExtraItem.Values['min'].Value);
      conexao.Parametros('qtd_maxima', ExtraItem.Values['max'].Value);
      conexao.ExecuteSQL;

      ExtraItensArray := ExtraItem.Values['extra'] as TJSONArray;
      for K := 0 to ExtraItensArray.Count - 1 do
      begin
        ExtraItensItem := ExtraItensArray.Items[K] as TJSONObject;
        if ExtraItensItem.Values['id'].Value = '0' then
        begin
          CodigoAux := conexao.GerarID('pro_adi_personalizado_sabores', 'id');
          conexao.SQL.Add
            ('insert into pro_adi_personalizado_sabores (id, id_pro_adi_personalizado,nome,descricao,valor,ativo)');
          conexao.SQL.Add
            ('values (:id, :id_pro_adi_personalizado,:nome,:descricao,:valor,:ativo)');

        end
        else
        begin
          CodigoAux := StrToInt(ExtraItensItem.Values['id'].Value);
          conexao.SQL.Add
            ('update pro_adi_personalizado_sabores set id_pro_adi_personalizado = :id_pro_adi_personalizado, nome = :nome, descricao = :descricao, valor = :valor, ativo = :ativo');
          conexao.SQL.Add('where id = :id');
        end;
        conexao.Parametros('id', CodigoAux);
        conexao.Parametros('id_pro_adi_personalizado', CodigoExtra);
        conexao.Parametros('nome', ExtraItensItem.Values['name'].Value);
        conexao.Parametros('descricao',
          ExtraItensItem.Values['description'].Value);
        conexao.Parametros('valor', ExtraItensItem.Values['value'].Value);
        conexao.Parametros('ativo', ExtraItensItem.Values['status'].Value);
        conexao.ExecuteSQL;

      end;


      // ExtraItensItem: TJSONObject;

      // conexao.SQL.Add('select * pro_adi_personalizado where id_produto = :produto and id = :id');
      // conexao.Parametros('produto',Codigo);
      // conexao.

      // ProductItem := ProductArray.Items[I] as TJSONObject;

    end;

    Site := EnviaProduto(Codigo);

    if (JSONObject.Values['base64'].Value <> '') then
      EnviaFotoProduto(Site, JSONObject.Values['base64'].Value);

    // Enviar pro site
    // Site

  end;

end;

procedure Registry;
begin
  THorse.Post('/v2/category', DoPostCategory);
  THorse.get('/v2/product/of/category/:category', DoGetCaetegory);
  THorse.Post('/v2/product', DoPostProduct);

end;

end.
