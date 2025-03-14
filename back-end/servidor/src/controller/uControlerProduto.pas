unit uControlerProduto;

interface

uses JOSE.Types.JSON, Conexao, FireDAC.Comp.Client, DataSet.Serialize, System.SysUtils;

function ObjetoProduto(SQL: String): TJsonArray;

implementation

function ObjetoProduto(SQL: String): TJsonArray;
var
  conexao: Tconexao;
  Data: TJsonArray;
  DataS: String;

  JSONArray: TJsonArray;
  JsonObjeto: TJsonObject;
  JSonArrayAdicional: TJsonArray;
  JsonObjetoCategoriaAdicional: TJsonObject;

  JSonArrayAdicionalItens: TJsonArray;
  JSonObjetoAdicionalItens: TJsonObject;

  JSonObjectoPizza: TJsonObject;
  JSonArraySabores: TJsonArray;
  JSonObjectoSabores: TJsonObject;

  DadosProduto: TFDQuery;
  DadosCategoria: TFDMemTable;
  DadosAdicionais: TFDMemTable;
  DadosAdicionaisItens: TFDMemTable;
  DadosPizza: TFDMemTable;
  Min: Real;
  Max: Real;
  Estoque: Real;
begin
 conexao := Tconexao.Create('main');
  try
    DadosProduto := conexao.CriaQRY;
    DadosCategoria := TFDMemTable.Create(nil);
    DadosAdicionais := TFDMemTable.Create(nil);
    DadosAdicionaisItens := TFDMemTable.Create(nil);
    DadosPizza := TFDMemTable.Create(nil);

    conexao.SQL.Add(SQL);
    DadosProduto.SQL.Text := SQL;
    DadosProduto.Open;

    JSONArray := TJsonArray.Create;
    if DadosProduto.RecordCount > 0 then
    begin

      while not DadosProduto.Eof do
      begin
        Min := 9999999;
        Max := 0;

        JsonObjeto := TJsonObject.Create;

        JsonObjeto.AddPair('id', DadosProduto.FieldByName('codigo').AsInteger);
        JsonObjeto.AddPair('position', DadosProduto.FieldByName('position')
          .AsInteger);
        JsonObjeto.AddPair('new', DadosProduto.FieldByName('novidade')
          .AsInteger);
        JsonObjeto.AddPair('name', DadosProduto.FieldByName('nome_produto')
          .AsWideString);
        JsonObjeto.AddPair('description', DadosProduto.FieldByName('descricao')
          .AsString);
        JsonObjeto.AddPair('value',
          DadosProduto.FieldByName('valor_venda').AsFloat);
        try
          JsonObjeto.AddPair('tax_delivery',
            DadosProduto.FieldByName('valor_embalagem_delivery').AsFloat);
        except
          JsonObjeto.AddPair('tax_delivery', 0);
        end;
        try
          JsonObjeto.AddPair('stock_min',
            DadosProduto.FieldByName('estoque_min').AsFloat);
        except
          JsonObjeto.AddPair('stock_min', 0);
        end;
        try
          JsonObjeto.AddPair('tax_vb',
            DadosProduto.FieldByName('valor_embalagem_delivery').AsFloat);
        except
          JsonObjeto.AddPair('tax_delivery', 0);
        end;
        JsonObjeto.AddPair('status', DadosProduto.FieldByName('ativo')
          .AsInteger);
        JsonObjeto.AddPair('stock', DadosProduto.FieldByName('controle_estoque')
          .AsInteger);
        JsonObjeto.AddPair('img', DadosProduto.FieldByName('caminho_imagem')
          .AsString);
        JsonObjeto.AddPair('category', DadosProduto.FieldByName('codigo_grupo')
          .AsInteger);

        JsonObjeto.AddPair('ifood_id', DadosProduto.FieldByName('id_ifood')
          .AsString);
        JsonObjeto.AddPair('ifood_value',
          DadosProduto.FieldByName('valor_ifood').AsString);
        JsonObjeto.AddPair('ifood_img', DadosProduto.FieldByName('foto_ifood')
          .AsString);
        JsonObjeto.AddPair('ncm', DadosProduto.FieldByName('ncm').AsInteger);
        JsonObjeto.AddPair('cest', DadosProduto.FieldByName('cest').AsInteger);
        JsonObjeto.AddPair('cfop', DadosProduto.FieldByName('cfop').AsInteger);
        JsonObjeto.AddPair('cstipi', DadosProduto.FieldByName('cstipi')
          .AsInteger);
        JsonObjeto.AddPair('csticms', DadosProduto.FieldByName('csticms')
          .AsInteger);
        JsonObjeto.AddPair('cstpis', DadosProduto.FieldByName('cstpis')
          .AsInteger);
        JsonObjeto.AddPair('cstcofins', DadosProduto.FieldByName('cstcofins')
          .AsInteger);
        JsonObjeto.AddPair('csosn', DadosProduto.FieldByName('csosn')
          .AsInteger);
        JsonObjeto.AddPair('icms', DadosProduto.FieldByName('icms').AsFloat);
        JsonObjeto.AddPair('ipi', DadosProduto.FieldByName('ipi').AsFloat);
        JsonObjeto.AddPair('pis', DadosProduto.FieldByName('pis').AsFloat);
        JsonObjeto.AddPair('cofins', DadosProduto.FieldByName('cofins')
          .AsString);
        JsonObjeto.AddPair('frete', DadosProduto.FieldByName('frete').AsFloat);
        JsonObjeto.AddPair('un', DadosProduto.FieldByName('un').AsString);
        JsonObjeto.AddPair('fidelidade', DadosProduto.FieldByName('fidelidade')
          .AsString);
        JsonObjeto.AddPair('dias', DadosProduto.FieldByName('dias').AsString);
        JsonObjeto.AddPair('segunda', DadosProduto.FieldByName('segunda')
          .AsString);
        JsonObjeto.AddPair('terca', DadosProduto.FieldByName('terca').AsString);
        JsonObjeto.AddPair('quarta', DadosProduto.FieldByName('quarta')
          .AsString);
        JsonObjeto.AddPair('quinta', DadosProduto.FieldByName('quinta')
          .AsString);
        JsonObjeto.AddPair('sexta', DadosProduto.FieldByName('sexta').AsString);
        JsonObjeto.AddPair('sabado', DadosProduto.FieldByName('sabado')
          .AsString);
        JsonObjeto.AddPair('domingo', DadosProduto.FieldByName('domingo')
          .AsString);

        JsonObjeto.AddPair('people', DadosProduto.FieldByName('pessoas')
          .AsString);
        JsonObjeto.AddPair('value_discont',
          DadosProduto.FieldByName('valor_desconto').AsString);
        JsonObjeto.AddPair('value_percent',
          DadosProduto.FieldByName('percentual_desconto').AsString);
        JsonObjeto.AddPair('quanty', DadosProduto.FieldByName('saldo_atual')
          .AsString);
        JsonObjeto.AddPair('externalCode', DadosProduto.FieldByName('id_site')
          .AsInteger);
        JsonObjeto.AddPair('usaStock',
          DadosProduto.FieldByName('controle_estoque').AsInteger);
        JsonObjeto.AddPair('stock_current',
          DadosProduto.FieldByName('saldo_atual').AsInteger);

        {

          conexao.SQL.Add
          ('SELECT * FROM pro_adi_personalizado where id_produto = :id_produto');
          conexao.Parametros('id_produto', DadosProduto.FieldByName('codigo')
          .AsInteger);

          DadosAdicionais.Close;
          DadosAdicionais.LoadFromJSON(conexao.ConsultaSQL);

          if DadosAdicionais.RecordCount > 0 then
          begin
          JSonArrayAdicional := TJsonArray.Create;
          while not DadosAdicionais.Eof do
          begin
          JsonObjetoCategoriaAdicional := TJsonObject.Create;
          JsonObjetoCategoriaAdicional.AddPair('categoryId',
          DadosAdicionais.FieldByName('id').AsInteger);
          JsonObjetoCategoriaAdicional.AddPair('categoryName',
          DadosAdicionais.FieldByName('descricao').AsString);
          JsonObjetoCategoriaAdicional.AddPair('categoryStatus',
          DadosAdicionais.FieldByName('ativo').AsInteger);
          JsonObjetoCategoriaAdicional.AddPair('categoryMin',
          DadosAdicionais.FieldByName('qtd_minima').AsInteger);
          JsonObjetoCategoriaAdicional.AddPair('categoryMax',
          DadosAdicionais.FieldByName('qtd_maxima').AsInteger);

          DadosAdicionaisItens.Close;
          conexao.SQL.Add
          ('select * from pro_adi_personalizado_sabores where id_pro_adi_personalizado = :id');
          conexao.Parametros('id', DadosAdicionais.FieldByName('id')
          .AsInteger);
          DadosAdicionaisItens.LoadFromJSON(conexao.ConsultaSQL);
          JSonArrayAdicionalItens := TJsonArray.Create;

          while not DadosAdicionaisItens.Eof do
          begin
          JSonObjetoAdicionalItens := TJsonObject.Create;
          JSonObjetoAdicionalItens.AddPair('itensId',
          DadosAdicionaisItens.FieldByName('id').AsInteger);
          JSonObjetoAdicionalItens.AddPair('itensName',
          DadosAdicionaisItens.FieldByName('nome').AsString);
          JSonObjetoAdicionalItens.AddPair('itensDescription',
          DadosAdicionaisItens.FieldByName('descricao').AsString);
          JSonObjetoAdicionalItens.AddPair('itensValue',
          DadosAdicionaisItens.FieldByName('valor').AsFloat);
          JSonObjetoAdicionalItens.AddPair('itensProdStock',
          DadosAdicionaisItens.FieldByName('id_prod_estoque').AsInteger);
          JSonObjetoAdicionalItens.AddPair('itensStatus',
          DadosAdicionaisItens.FieldByName('ativo').AsInteger);
          JSonObjetoAdicionalItens.AddPair('itensInsumo',
          DadosAdicionaisItens.FieldByName('id_ingredientes').AsInteger);

          JSonArrayAdicionalItens.AddElement(JSonObjetoAdicionalItens);

          if DadosAdicionaisItens.FieldByName('valor').AsFloat > 0 then
          begin
          if Min > DadosAdicionaisItens.FieldByName('valor').AsFloat then
          Min := DadosAdicionaisItens.FieldByName('valor').AsFloat;

          if DadosAdicionaisItens.FieldByName('valor').AsFloat > Max then
          Max := DadosAdicionaisItens.FieldByName('valor').AsFloat;
          end;

          DadosAdicionaisItens.Next;
          end;
          JsonObjetoCategoriaAdicional.AddPair('categoryItens',
          JSonArrayAdicionalItens);

          JSonArrayAdicional.Add(JsonObjetoCategoriaAdicional);
          DadosAdicionais.Next;
          end;
          JsonObjeto.AddPair('additional', JSonArrayAdicional);
          end
          else
          begin
          JSonArrayAdicional := TJsonArray.Create;
          JsonObjeto.AddPair('additional', JSonArrayAdicional);
          end;
        }
        { conexao.SQL.Add('select  ');
          conexao.SQL.Add('sabores_completo.id as sabor_id,  ');
          conexao.SQL.Add('sabores_completo.nome as sabor_nome,');
          conexao.SQL.Add('sabores_completo.descricao as sabor_descricao,');
          conexao.SQL.Add('sabores_completo.vl_venda as sabor_venda,');
          conexao.SQL.Add('sabores_completo.ativo as sabor_status,');
          conexao.SQL.Add('produto_pizza.quantidade_sabores as qtd_sabor, ');
          conexao.SQL.Add('tipo_sabor.id as tipo_id,');
          conexao.SQL.Add('tipo_sabor.nome as tipo_nome, tipo_sabor.descricao as tipo_descricao, tipo_sabor.ativo as tipo_status, ');
          conexao.SQL.Add('(select tipo_preco_pizza from dados_whatsapp limit 1) as tipo_valor from sabores_completo');
          conexao.SQL.Add('join produto_pizza on produto_pizza.codigo_produto = sabores_completo.id_produto');
          conexao.SQL.Add('join tipo_sabor on tipo_sabor.id  = sabores_completo.id_tipo_sabor');
          conexao.SQL.Add('where sabores_completo.id_produto = :id');
          conexao.SQL.Add('order by sabores_completo.id_produto, sabores_completo.id_tipo_sabor, sabores_completo.nome'); }
        conexao.SQL.Clear;
        conexao.SQL.Add('SELECT  ');
        conexao.SQL.Add('    sc.id AS sabor_id,  ');
        conexao.SQL.Add('    sc.nome AS sabor_nome, ');
        conexao.SQL.Add('    sc.descricao AS sabor_descricao, ');
        conexao.SQL.Add('    sc.vl_venda AS sabor_venda, ');
        conexao.SQL.Add('    sc.ativo AS sabor_status, ');
        conexao.SQL.Add('    pp.quantidade_sabores AS qtd_sabor, ');
        conexao.SQL.Add('    ts.id AS tipo_id, ');
        conexao.SQL.Add('    ts.nome AS tipo_nome, ');
        conexao.SQL.Add('    ts.descricao AS tipo_descricao, ');
        conexao.SQL.Add('    ts.ativo AS tipo_status, ');
        conexao.SQL.Add
          ('    (SELECT tipo_preco_pizza FROM dados_whatsapp LIMIT 1) AS tipo_valor ');
        conexao.SQL.Add('FROM sabores_completo sc ');
        conexao.SQL.Add
          ('JOIN produto_pizza pp ON pp.codigo_produto = sc.id_produto ');
        conexao.SQL.Add('JOIN tipo_sabor ts ON ts.id = sc.id_tipo_sabor ');
        conexao.SQL.Add('WHERE sc.id_produto = :id ');
        conexao.SQL.Add('ORDER BY sc.id_produto, sc.id_tipo_sabor, sc.nome');
        conexao.Parametros('id', DadosProduto.FieldByName('codigo').AsInteger);

        DadosPizza.Close;
        DadosPizza.LoadFromJSON(conexao.ConsultaSQL);
        JSonObjectoPizza := TJsonObject.Create;
        if DadosPizza.RecordCount > 0 then
        begin
          Min := 9999999;
          Max := 0;
          JSonObjectoPizza.AddPair('amountOfFlavors',
            DadosPizza.FieldByName('qtd_sabor').AsInteger);
          JSonObjectoPizza.AddPair('typeOfValue',
            DadosPizza.FieldByName('tipo_valor').AsInteger);
          case DadosPizza.FieldByName('tipo_valor').AsInteger of
            0:
              begin
                JSonObjectoPizza.AddPair('typeOfValueDescription',
                  'Average values / Média');
              end;
            1:
              begin
                JSonObjectoPizza.AddPair('typeOfValueDescription',
                  'Highest Value / Valor mais alto');
              end;
            2:
              begin
                JSonObjectoPizza.AddPair('typeOfValueDescription',
                  'Sum Of Values / Soma dos Valores');
              end
          else
            begin
              JSonObjectoPizza.AddPair('typeOfValueDescription', 'None');
            end;
          end;

          JSonArraySabores := TJsonArray.Create;
          while not DadosPizza.Eof do
          begin
            if Min > DadosPizza.FieldByName('sabor_venda').AsFloat then
              Min := DadosPizza.FieldByName('sabor_venda').AsFloat;

            if DadosPizza.FieldByName('sabor_venda').AsFloat > Max then
              Max := DadosPizza.FieldByName('sabor_venda').AsFloat;

            JSonObjectoSabores := TJsonObject.Create;
            JSonObjectoSabores.AddPair('typeId',
              DadosPizza.FieldByName('tipo_id').AsInteger);
            JSonObjectoSabores.AddPair('typeName',
              DadosPizza.FieldByName('tipo_nome').AsString);
            JSonObjectoSabores.AddPair('typeDescription',
              DadosPizza.FieldByName('tipo_descricao').AsString);
            JSonObjectoSabores.AddPair('typeStatus',
              DadosPizza.FieldByName('tipo_status').AsString);
            JSonObjectoSabores.AddPair('flavorId',
              DadosPizza.FieldByName('sabor_id').AsInteger);
            JSonObjectoSabores.AddPair('flavorName',
              DadosPizza.FieldByName('sabor_nome').AsString);
            JSonObjectoSabores.AddPair('flavorDescription',
              DadosPizza.FieldByName('sabor_descricao').AsString);
            JSonObjectoSabores.AddPair('flavorValue',
              DadosPizza.FieldByName('sabor_venda').AsFloat);
            JSonObjectoSabores.AddPair('flavorId',
              DadosPizza.FieldByName('sabor_id').AsInteger);
            JSonObjectoSabores.AddPair('flavorStatus',
              DadosPizza.FieldByName('sabor_status').AsInteger);
            JSonArraySabores.AddElement(JSonObjectoSabores);
            DadosPizza.Next;
          end;
          JSonObjectoPizza.AddPair('min', Min);
          JSonObjectoPizza.AddPair('max', Max);
          JSonObjectoPizza.AddPair('flavor', JSonArraySabores);

        end;

        JsonObjeto.AddPair('min', Min);
        JsonObjeto.AddPair('max', Max);
        JsonObjeto.AddPair('pizza', JSonObjectoPizza);
        JSONArray.AddElement(JsonObjeto);
        DadosProduto.Next;
      end;
    end;
  except
    on E: Exception do
    begin
    end;

  end;
  Result := JSONArray;
  conexao.Free;
end;

end.
