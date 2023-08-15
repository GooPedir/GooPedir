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
          ('values (:codigo,:codigo_interno,current_date,:nome_produto,:descricao,:codigo_grupo,0,1,:position)');
        conexao.Parametros('codigo', CodigoAux);
        conexao.Parametros('codigo_interno', CodigoAux);
        conexao.Parametros('codigo_grupo', CodigoGrupo);
        conexao.Parametros('nome_produto', ProductItem.Values['name'].Value);
        conexao.Parametros('descricao',
          ProductItem.Values['description'].Value);
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

procedure DoGetUserID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send(frmServidor.UserID.ToString);
end;

procedure DoPostNovoValorFlavor(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
begin
  conexao := TConexao.Create;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select distinct id_produto, 0 as zero from sabores_completo where nome = :nome');
  conexao.Parametros('nome', Req.Params['name']);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  conexao.SQL.Add
    ('update sabores_completo set vl_venda = :vl_venda, modificado_site = 0 where nome = :nome and id_produto = :product');
  conexao.Parametros('vl_venda', Req.Params['value']);
  conexao.Parametros('nome', Req.Params['name']);
  conexao.Parametros('product', Req.Params['product']);
  conexao.ExecuteSQL;

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      EnviaProduto(Dados.FieldByName('id_produto').AsInteger);
      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;
end;

procedure DoPostStatusFlavor(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
begin
  conexao := TConexao.Create;
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select distinct id_produto, 0 as zero from sabores_completo where nome = :nome');
  conexao.Parametros('nome', Req.Params['name']);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  conexao.SQL.Add
    ('update sabores_completo set ativo = :ativo, modificado_site = 0 where nome = :nome');
  conexao.Parametros('ativo', Req.Params['status']);
  conexao.Parametros('nome', Req.Params['name']);
  conexao.ExecuteSQL;

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      EnviaProduto(Dados.FieldByName('id_produto').AsInteger);
      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;

end;

procedure DoGetFlavor(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  ArrayJson: TJSONArray;
  ObjetoJson: TJSONObject;
  ArrayProdutos: TJSONArray;
  ObjetoProduto: TJSONObject;
  Dados: TFDMemTable;
  DadosProduto: TFDMemTable;
  DadosAux: TFDMemTable;
  DadosSabores: TFDMemTable;
  valor: Real;
  Codigo: Integer;
begin

  conexao := TConexao.Create;
  try
    DadosProduto := TFDMemTable.Create(nil);
    Dados := TFDMemTable.Create(nil);
    DadosAux := TFDMemTable.Create(nil);
    ArrayJson := TJSONArray.Create;
    DadosSabores := TFDMemTable.Create(nil);

    // conexao.SQL.Add('select * from produto where produto.codigo_grupo = :grupo order by codigo');
    conexao.SQL.Add('select * from produto');
    conexao.SQL.Add
      ('join tipo_produto on tipo_produto.codigo = produto.codigo_grupo and tipo_produto.pizza = 1');
    conexao.SQL.Add
      ('where produto.codigo_grupo = :grupo order by produto.codigo');

    conexao.Parametros('grupo', Req.Params['category']);
    DadosProduto.LoadFromJSON(conexao.ConsultaSQL);

    conexao.SQL.Add
      ('SELECT distinct sabores_completo.nome, ativo, descricao, id_tipo_sabor FROM sabores_completo');
    Dados.LoadFromJSON(conexao.ConsultaSQL);

    while not Dados.Eof do
    begin

      ObjetoJson := TJSONObject.Create;
      ObjetoJson.AddPair('flavor', Dados.FieldByName('nome').AsString);
      ObjetoJson.AddPair('description', Dados.FieldByName('descricao')
        .AsString);
      ObjetoJson.AddPair('status', Dados.FieldByName('ativo').AsInteger);
      ObjetoJson.AddPair('type', Dados.FieldByName('id_tipo_sabor').AsInteger);
      ArrayProdutos := TJSONArray.Create;
      DadosProduto.First;
      while not DadosProduto.Eof do
      begin

        DadosSabores.Close;
        conexao.SQL.Add
          ('select * from sabores_completo where id_produto = :produto and nome = :sabor');
        conexao.Parametros('produto', DadosProduto.FieldByName('codigo')
          .AsInteger);
        conexao.Parametros('sabor', Dados.FieldByName('nome').AsString);
        DadosSabores.LoadFromJSON(conexao.ConsultaSQL);

        if DadosSabores.RecordCount = 0 then
        begin
          valor := 0;

          Codigo := conexao.GerarID('sabores_completo', 'id');
          conexao.SQL.Add
            ('insert into sabores_completo (id,id_produto,id_tipo_sabor,dt_cadastro,nome,descricao,vl_venda,ativo,modificado_site)');
          conexao.SQL.Add
            ('values (:id,:id_produto,:id_tipo_sabor,current_date,:nome,:descricao,:vl_venda,1,0)');
          conexao.Parametros('id', Codigo);
          conexao.Parametros('id_produto', DadosProduto.FieldByName('codigo')
            .AsInteger);
          conexao.Parametros('id_tipo_sabor', 1);
          conexao.Parametros('nome',
            UpperCase(Dados.FieldByName('nome').AsString));
          conexao.Parametros('descricao',
            UpperCase(Dados.FieldByName('descricao').AsString));
          conexao.Parametros('vl_venda', 0);
          conexao.ExecuteSQL;
        end
        else
        begin
          valor := DadosSabores.FieldByName('vl_venda').AsFloat;
        end;

        ObjetoProduto := TJSONObject.Create;

        ObjetoProduto.AddPair('id', DadosProduto.FieldByName('codigo')
          .AsInteger);
        ObjetoProduto.AddPair('name', DadosProduto.FieldByName('nome_produto')
          .AsString);
        ObjetoProduto.AddPair('value', valor);

        ArrayProdutos.Add(ObjetoProduto);

        DadosProduto.Next;
      end;
      ObjetoJson.AddPair('product', ArrayProdutos);
      ArrayJson.Add(ObjetoJson);
      Dados.Next;
    end;
    Res.Send<TJSONArray>(ArrayJson);
    // ArrayJson.Free;

    Dados.Free;
    DadosAux.Free;
    DadosProduto.Free;
  except
    ArrayJson := TJSONArray.Create;
    Res.Send<TJSONArray>(ArrayJson);
  end;
  conexao.Free;

end;

procedure DoPostFlavor(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LJSONValue, LSizeValue: TJSONValue;
  LJSONObject: TJSONObject;
  LJSONArray: TJSONArray;
  LSizeObject: TJSONObject;
  I: Integer;
  conexao: TConexao;
  Codigo: Integer;
  SaborAntigo: String;
begin
  conexao := TConexao.Create;

  LJSONValue := TJSONObject.ParseJSONValue(Req.Body);

  if LJSONValue is TJSONObject then
  begin
    LJSONObject := LJSONValue as TJSONObject;

    // ShowMessage('ID: ' + LJSONObject.GetValue('id').Value);
    // ShowMessage('Name: ' + LJSONObject.GetValue('name').Value);
    // ShowMessage('Description: ' + LJSONObject.GetValue('description').Value);
    // ShowMessage('Base64: ' + LJSONObject.GetValue('base64').Value);
    // flavorOld

    LSizeValue := LJSONObject.GetValue('size');

    if LSizeValue is TJSONArray then
    begin
      LJSONArray := LSizeValue as TJSONArray;
      for I := 0 to LJSONArray.Count - 1 do
      begin
        // SaborAntigo := UpperCase(LJSONObject.GetValue('flavorOld').Value);

        LSizeObject := LJSONArray.Items[I] as TJSONObject;
        conexao.SQL.Add
          ('select * from sabores_completo where id_produto = :produto and (nome = :sabor or nome = :old)');
        conexao.Parametros('produto', LSizeObject.GetValue('id').Value);
        conexao.Parametros('sabor',
          UpperCase(LJSONObject.GetValue('name').Value));
        conexao.Parametros('old',
          UpperCase(LJSONObject.GetValue('flavorOld').Value));

        try
          Codigo := conexao.FieldByName('id');
        except
          Codigo := 0;
        end;

        if Codigo = 0 then
        begin
          Codigo := conexao.GerarID('sabores_completo', 'id');
          conexao.SQL.Add
            ('insert into sabores_completo (id,id_produto,id_tipo_sabor,dt_cadastro,nome,descricao,vl_venda,ativo,modificado_site)');
          conexao.SQL.Add
            ('values (:id,:id_produto,:id_tipo_sabor,current_date,:nome,:descricao,:vl_venda,1,0)');
          conexao.Parametros('id', Codigo);
          conexao.Parametros('id_produto', LSizeObject.GetValue('id').Value);
          conexao.Parametros('id_tipo_sabor',
            LJSONObject.GetValue('type').Value);
          conexao.Parametros('nome',
            UpperCase(LJSONObject.GetValue('name').Value));
          conexao.Parametros('descricao',
            UpperCase(LJSONObject.GetValue('description').Value));
          conexao.Parametros('vl_venda', LSizeObject.GetValue('value').Value);
          conexao.ExecuteSQL;
        end;

        conexao.SQL.Add
          ('update sabores_completo set nome = :nome, descricao = :descricao, vl_venda = :vl_venda, modificado_site = 0 where id = :id');
        conexao.Parametros('id', Codigo);
        conexao.Parametros('nome',
          UpperCase(LJSONObject.GetValue('name').Value));
        conexao.Parametros('descricao',
          UpperCase(LJSONObject.GetValue('description').Value));
        conexao.Parametros('vl_venda', LSizeObject.GetValue('value').Value);
        conexao.ExecuteSQL;
        // EnviaProduto(StrToInt(LSizeObject.GetValue('id').Value));
        // insert into sabores_completo (id,id_produto,id_tipo_sabor,dt_cadastro,nome,descricao,vl_venda,ativo,modificado_site)
      end;
    end;
  end;

  LJSONValue.Free;
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

  try

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
        conexao.Parametros('controle_estoque',
          JSONObject.Values['stock'].Value);
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
        conexao.Parametros('controle_estoque',
          JSONObject.Values['stock'].Value);
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

      if (JSONObject.Values['base64'].Value <> '') and
        (JSONObject.Values['id'].Value = '0') then
        EnviaFotoProduto(Site, JSONObject.Values['base64'].Value);

      // Enviar pro site
      // Site

    end;

  except
    on E: Exception do
    begin
      frmServidor.AddLog(E.Message);
    end;
  end;
  conexao.Free;
  DadosProduto.Free;
  JSONValue.Free;
end;

procedure DoGetPedidosMotoboy(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;

begin
  conexao := TConexao.Create;
  conexao.SQL.Add
    ('select pedido.data_pedido, group_concat(pedido.codigo_pedido_dia) as pedidos, sum(pedido.valor_taxa_entrega) as taxa, sum(pedido.valor_total_pedido) as total from pedido');
  conexao.SQL.Add
    ('join pedido_motoboy on pedido_motoboy.codigo_pedido = pedido.codigo');
  conexao.SQL.Add
    ('where pedido.data_pedido >= current_date()-7 and pedido_motoboy.codigo_motoboy = :codigo ');
  conexao.SQL.Add('group by pedido.data_pedido');
  conexao.SQL.Add('order by pedido.data_pedido desc');

  conexao.Parametros('codigo', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure PostGetPedidosMotoboy(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Body: String;
  JSONArr: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  conexao: TConexao;
  Dados: TFDMemTable;
  ID: Integer;
  Requisicao: iRequisicao;

begin
  conexao := TConexao.Create;
  Dados := TFDMemTable.Create(nil);
  Body := Req.Body;
  JSONArr := TJSONObject.ParseJSONValue(Body) as TJSONArray;
  try
    for I := 0 to JSONArr.Count - 1 do
    begin
      JSONObj := JSONArr.Items[I] as TJSONObject;
      Dados.Close;
      conexao.SQL.Add
        ('select * from pedido where pedido.codigo_pedido_dia = :codigo and pedido.codigo_cliente_endereco > 0 order by data_pedido desc limit 1');
      conexao.Parametros('codigo', JSONObj.GetValue<string>('codigo'));
      Dados.LoadFromJSON(conexao.ConsultaSQL);
      if Dados.RecordCount > 0 then
      begin

        // Codigo := StrToIntDef(JSONObj.GetValue<string>('codigo'), 0);
        // Tipo := JSONObj.GetValue<Integer>('tipo');
        // Motoboy := JSONObj.GetValue<Integer>('motoboy');
        if JSONObj.GetValue<Integer>('tipo') = 1 then
        begin
          // Saiu para entrega
          conexao.SQL.Add
            ('update pedido set status = :status where codigo = :codigo');
          conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
          conexao.Parametros('status', 5);
          conexao.ExecuteSQL;

          ID := conexao.GerarID('pedido_status', 'id');
          conexao.SQL.Add
            ('insert into pedido_status (id,id_pedido,id_status,horario) values (:id,:pedido,:status,timestamp)');
          conexao.Parametros('pedido', Dados.FieldByName('codigo').AsInteger);
          conexao.Parametros('status', 5);
          conexao.Parametros('id', ID);
          conexao.ExecuteSQL;

        end;

        conexao.SQL.Add
          ('delete from pedido_motoboy where codigo_pedido = :pedido');
        conexao.Parametros('pedido', Dados.FieldByName('codigo').AsInteger);
        conexao.ExecuteSQL;

        ID := conexao.GerarID('pedido_motoboy', 'codigo');

        conexao.SQL.Add
          ('insert into pedido_motoboy (codigo,codigo_motoboy,codigo_pedido,hora_pego_motoboy,status) values (:codigo,:motoboy,:pedido,current_time,1)');
        conexao.Parametros('codigo', ID);
        conexao.Parametros('motoboy', JSONObj.GetValue<Integer>('motoboy'));
        conexao.Parametros('pedido', Dados.FieldByName('codigo').AsInteger);
        conexao.ExecuteSQL;

        if Dados.FieldByName('id_pedido_site').AsInteger > 0 then
        begin
          try
            Requisicao := iRequisicao.Create(nil);
            Requisicao.BaseURL :=
              'https://ws.goopedir.com/v1/atualiza_status_pedido.php?codigo=' +
              Dados.FieldByName('id_pedido_site').AsString + '&status=' +
              'Saiu Para Entrega';
            Requisicao.Execute;
          except

          end;
          Requisicao.Free;
        end;

      end;

      // Agora você tem os valores. Faça o que você precisa com eles.
      // Por exemplo, apenas imprimindo:
      // Writeln(Format('Codigo: %d, Tipo: %d, Motoboy: %d', [Codigo, Tipo, Motoboy]));
    end;
  finally
    JSONArr.Free;
  end;
  conexao.Free;
end;


procedure DoGetProdutosiFood(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJsonArray>(frmServidor.DadosProdutos);
end;

procedure Registry;
begin
  THorse.Post('/v2/category', DoPostCategory);
  THorse.get('/v2/product/of/category/:category', DoGetCaetegory);
  THorse.Post('/v2/product', DoPostProduct);
  THorse.Post('/v2/flavor', DoPostFlavor);
  THorse.get('/v2/flavor/:category', DoGetFlavor);
  THorse.Post('/v2/flavor/:name/:status', DoPostStatusFlavor);
  THorse.Post('/v2/flavor/:product/:name/:value', DoPostNovoValorFlavor);
  THorse.get('/v2/user/id', DoGetUserID);

  THorse.get('/v2/pedidos/motoboy/:codigo', DoGetPedidosMotoboy);
  THorse.Post('/v2/pedidos/motoboy', PostGetPedidosMotoboy);


  THorse.get('/v2/produtos/ifood', DoGetProdutosiFood);

end;

end.
