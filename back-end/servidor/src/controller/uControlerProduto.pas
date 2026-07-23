unit uControlerProduto;

interface

uses Windows, JOSE.Types.JSON, Conexao, FireDAC.Comp.Client, DataSet.Serialize,
  System.SysUtils;

function ObjetoProduto(SQL,hash: String): TJsonArray;
function TempoDecorrido(Inicio: UInt64): String;
procedure ValidaPendenciaProduto(Codigo: Integer);
procedure AdicionaPendencia(Conexao: TConexao; Produto: Integer;
  Descricao, Observacao: String);
function IsIngredienteSem(const Texto: string): Boolean;

implementation

function IsIngredienteSem(const Texto: string): Boolean;
var
  PrimeiraPalavra: string;
  Espaco: Integer;
begin
  Espaco := Pos(' ', Texto); // posição do primeiro espaço
  if Espaco > 0 then
    PrimeiraPalavra := Copy(Texto, 1, Espaco - 1)
  else
    PrimeiraPalavra := Texto; // se não tiver espaço, pega o texto inteiro

  Result := SameText(UpperCase(PrimeiraPalavra), 'SEM');
  // compara ignorando maiúsculas/minúsculas
end;

procedure AdicionaPendencia(Conexao: TConexao; Produto: Integer;
  Descricao, Observacao: String);
begin
  Conexao.SQL.Add
    ('insert into produto_pendencia (id_produto,detalhe,observacao) values (:id,:detalhe,:observacao)');
  Conexao.Parametros('id', Produto);
  Conexao.Parametros('detalhe', Descricao);
  Conexao.Parametros('observacao', Observacao);
  Conexao.ExecuteSQL;
end;

function TempoDecorrido(Inicio: UInt64): String;
begin
  Result := IntToStr(GetTickCount64 - Inicio) + ' ms';
end;

procedure ValidaPendenciaProduto(Codigo: Integer);
var
  Conexao: TConexao;
  Dados: TFDMemTable;
  MarcarPendenciaExtra: Boolean;

begin
  Conexao := TConexao.Create('ValidaPendenciaProduto');
  Conexao.SQL.Add('delete from produto_pendencia where id_produto = :id');
  Conexao.Parametros('id', Codigo);
  Conexao.ExecuteSQL;
  Dados := TFDMemTable.Create(nil);
  Conexao.SQL.Add
    ('select p.codigo as produtoID, p.nome_produto as produto, p.descricao as produtoDescricao, p.foto_ifood as produtoUrl, p.alerta as produtoAlerta, p.valor_venda as produtoValor, p.un,p.ncm,p.cest,p.cfop,p.cstipi,p.csticms,p.cstpis,p.cstcofins,p.csosn,p.ibs_cbs_cst,p.ibs_cbs_class_trib,p.ibs_uf_aliq,p.ibs_mun_aliq,p.cbs_aliq,');
  Conexao.SQL.Add
    ('(select count(*) from produto_combo_config where produto_combo_id = p.codigo and status = "ATIVO") as combo, pap.id as extraId, pap.descricao as extra, pap.qtd_minima as extraMin, pap.qtd_maxima as extraMax, ');
  Conexao.SQL.Add
    ('paps.id as itenExtraId, paps.nome as extraIten, paps.alerta as itemExtraAlerta, paps.valor as itemExtraValor, paps.id_prod_estoque as extraItemProdutoBaixa,');
  Conexao.SQL.Add
    ('prodExtra.codigo as produtoCodigoItemExtra, prodExtra.valor_venda as produtoValorItemExtra, prodExtra.nome_produto produtoNomeItemExtra,');
  Conexao.SQL.Add('(select nfce from dados_whatsapp limit 1 ) as nfc');
  Conexao.SQL.Add('from produto as p');
  Conexao.SQL.Add
    ('left join pro_adi_personalizado as pap on pap.id_produto = p.codigo and pap.deletado = 0');
  Conexao.SQL.Add
    ('left join pro_adi_personalizado_sabores as paps on paps.id_pro_adi_personalizado = pap.id and paps.deletado = 0');
  Conexao.SQL.Add
    ('left join produto as prodExtra on prodExtra.codigo = (select codigo from produto where deletado <> 1 and upper(nome_produto) like concat("%",upper(paps.nome)) limit 1)');
  Conexao.SQL.Add('where p.codigo = :codigo');
  Conexao.Parametros('codigo', Codigo);
  Dados.LoadFromJSON(Conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    // Validação do Produto
    if Dados.FieldByName('produto').AsString = '' then
    begin
      AdicionaPendencia(Conexao, Codigo, 'Produto sem nome', '');
    end;
    if Dados.FieldByName('produtoDescricao').AsString = '' then
    begin
      AdicionaPendencia(Conexao, Codigo, 'Produto sem descrição',
        'Um produto com descrição evita transtorno com clientes');
    end;
    if Dados.FieldByName('produtoValor').AsFloat = 0 then
    begin
      AdicionaPendencia(Conexao, Codigo, 'Produto sem valor', '');
    end;

    if Dados.FieldByName('produtoUrl').AsString = '' then
    begin
      AdicionaPendencia(Conexao, Codigo, 'Produto sem foto',
        'Um produto com foto chama muito mais atenção');
    end;
    if Dados.FieldByName('produtoUrl').AsString = 'https://fotos.goopedir.com//fotos/MA=='
    then
    begin
      AdicionaPendencia(Conexao, Codigo, 'Produto sem foto',
        'Um produto com foto chama muito mais atenção!');
    end;
    if (Dados.FieldByName('nfc').AsString = '1') then
    begin
      if Dados.FieldByName('un').AsString = '' then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem UNIDADE',
          'Unidade deve ser informado');
      end;
      if Dados.FieldByName('ncm').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem NCM',
          'NCM deve ser informado');
      end;
      if Dados.FieldByName('cest').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CEST',
          'CEST deve ser informado');
      end;

      if Dados.FieldByName('cfop').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CFOP',
          'CFOP deve ser informado');
      end;

      if Dados.FieldByName('cstipi').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CST IPI',
          'CST IPI deve ser informado');
      end;

      if Dados.FieldByName('csticms').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CST ICMS',
          'CST ICMS deve ser informado');
      end;

      if Dados.FieldByName('cstpis').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CST PIS',
          'CST PIS deve ser informado');
      end;

      if Dados.FieldByName('cstcofins').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CST COFINS',
          'CST COFINS deve ser informado');
      end;

      if Dados.FieldByName('csosn').AsFloat = 0 then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CSOSN',
          'CSOSN deve ser informado');
      end;

      if Trim(Dados.FieldByName('ibs_cbs_cst').AsString) = '' then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem CST IBS/CBS',
          'CST IBS/CBS deve ser informado');
      end;

      if Trim(Dados.FieldByName('ibs_cbs_class_trib').AsString) = '' then
      begin
        AdicionaPendencia(Conexao, Codigo, 'Produto sem Class. Trib. IBS/CBS',
          'Classificacao tributaria IBS/CBS deve ser informada');
      end;
    end;
    // Validação dos Adicionais
    while not Dados.Eof do
    begin
      MarcarPendenciaExtra := false;
      if Dados.FieldByName('itemExtraAlerta').AsString = '' then
      begin
        Dados.Edit;
        Dados.FieldByName('itemExtraAlerta').AsFloat := 2;
      end;
      if Dados.FieldByName('itemExtraAlerta').AsFloat <> 2 then
      begin
        if Dados.FieldByName('extraMax').AsFloat = 0 then
        begin
          AdicionaPendencia(Conexao, Codigo, 'Extra',
            'Não possue quantidade máxima para ser selecionada');
        end;

        if Dados.FieldByName('extra').AsString = 'Ingredientes' then
        begin
          if (Not IsIngredienteSem(Dados.FieldByName('extraIten').AsString))
          then
          begin
            AdicionaPendencia(Conexao, Codigo,
              'Extra ' + Dados.FieldByName('extraIten').AsString + '',
              'Não se encaixa na categoria de ' +
              UpperCase(Dados.FieldByName('extra').AsString));
            MarcarPendenciaExtra := True;
          end;
        end;
        if (Not IsIngredienteSem(Dados.FieldByName('extraIten').AsString)) then
          if Dados.FieldByName('itemExtraValor').AsFloat = 0 then
          begin
            AdicionaPendencia(Conexao, Codigo,
              'Extra ' + Dados.FieldByName('extraIten').AsString + '',
              'Está com valor ZERADO');
            MarcarPendenciaExtra := True;
          end;
        Dados.Edit;
        if (Dados.FieldByName('produtoCodigoItemExtra').AsString = '') then
        begin
          Dados.FieldByName('produtoCodigoItemExtra').AsInteger := 0;
        end;

        if Dados.FieldByName('extraItemProdutoBaixa').AsInteger <>
          Dados.FieldByName('produtoCodigoItemExtra').AsInteger then
        begin
          if Dados.FieldByName('produtoValorItemExtra').AsString = '' then
          begin
            Dados.Edit;
            Dados.FieldByName('produtoValorItemExtra').AsFloat :=
              Dados.FieldByName('itemExtraValor').AsFloat;
          end;
          if Dados.FieldByName('itemExtraValor').AsFloat <>
            Dados.FieldByName('produtoValorItemExtra').AsFloat then
          begin
            if Dados.FieldByName('itemExtraValor').AsInteger = 0 then
            begin
              AdicionaPendencia(Conexao, Codigo,
                'O extra ' + Dados.FieldByName('extraIten').AsString,
                'Ele está com o valor ZERADO');
            end
            else
            begin
              AdicionaPendencia(Conexao, Codigo,
                'O extra ' + Dados.FieldByName('extraIten').AsString,
                'Ele está com o valor diferente do produto');
            end;
            MarcarPendenciaExtra := True;
          end;

        end;
      end;
      if MarcarPendenciaExtra then
      begin
        Conexao.SQL.Add
          ('update pro_adi_personalizado_sabores set alerta = 1 where id = :id');
        Conexao.Parametros('id', Dados.FieldByName('itenExtraId').AsInteger);
        Conexao.ExecuteSQL;
      end;

      Dados.Next;
    end;
  end;

  Dados.Free;
  Conexao.Free;

end;

function ObjetoProduto(SQL,hash: String): TJsonArray;
var
  Conexao: TConexao;
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
  Observacao: TJsonArray;
  ObjetoObs: TJsonObject;

  ObjCombo: TJsonObject;
  Combos: TJsonArray;
  DadosCombo: TFDMemTable;

begin

  Conexao := TConexao.Create('main');
  try
    DadosProduto := Conexao.CriaQRY;
    DadosCategoria := TFDMemTable.Create(nil);
    DadosAdicionais := TFDMemTable.Create(nil);
    DadosAdicionaisItens := TFDMemTable.Create(nil);
    DadosPizza := TFDMemTable.Create(nil);

    Conexao.SQL.Add(SQL);
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
        JsonObjeto.AddPair('hash',hash);
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
          JsonObjeto.AddPair('vembuscar',
            DadosProduto.FieldByName('vembuscar').AsFloat);
        except
          JsonObjeto.AddPair('vembuscar', 0);
        end;
        try
          JsonObjeto.AddPair('delivery',
            DadosProduto.FieldByName('delivery').AsFloat);
        except
          JsonObjeto.AddPair('delivery', 0);
        end;

        try
          JsonObjeto.AddPair('referencia',
            DadosProduto.FieldByName('referencia').AsFloat);
        except
          JsonObjeto.AddPair('referencia', '');
        end;
        try
          JsonObjeto.AddPair('tiposite', DadosProduto.FieldByName('tiposite')
            .AsString);
        except
          JsonObjeto.AddPair('tiposite', '');
        end;

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
        JsonObjeto.AddPair('ibs_cbs_cst', DadosProduto.FieldByName('ibs_cbs_cst')
          .AsString);
        JsonObjeto.AddPair('ibs_cbs_class_trib',
          DadosProduto.FieldByName('ibs_cbs_class_trib').AsString);
        JsonObjeto.AddPair('ibs_uf_aliq', DadosProduto.FieldByName('ibs_uf_aliq')
          .AsFloat);
        JsonObjeto.AddPair('ibs_mun_aliq', DadosProduto.FieldByName('ibs_mun_aliq')
          .AsFloat);
        JsonObjeto.AddPair('cbs_aliq', DadosProduto.FieldByName('cbs_aliq')
          .AsFloat);
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
          DadosProduto.FieldByName('valor_desconto').AsFloat);
        JsonObjeto.AddPair('value_percent',
          DadosProduto.FieldByName('percentual_desconto').AsFloat);
        if DadosProduto.FieldByName('saldo_atual').AsString = '' then
          JsonObjeto.AddPair('quanty', 0)
        else
          JsonObjeto.AddPair('quanty', DadosProduto.FieldByName('saldo_atual')
            .AsString);
        JsonObjeto.AddPair('externalCode', DadosProduto.FieldByName('id_site')
          .AsInteger);
        JsonObjeto.AddPair('usaStock',
          DadosProduto.FieldByName('controle_estoque').AsInteger);
        JsonObjeto.AddPair('stock_current',
          DadosProduto.FieldByName('saldo_atual').AsInteger);

        try
          JsonObjeto.AddPair('referencia',
            DadosProduto.FieldByName('referencia').AsString);
        except
          JsonObjeto.AddPair('referencia', '');
        end;
        Conexao.SQL.Clear;
        Conexao.SQL.Add
          ('select * from produto_pendencia where id_produto = :id');
        Conexao.Parametros('id', DadosProduto.FieldByName('codigo').AsInteger);
        JsonObjeto.AddPair('alerta', Conexao.ConsultaSQL);
        Conexao.SQL.Clear;
        Conexao.SQL.Add
          ('SELECT * FROM pro_adi_personalizado where id_produto = :id_produto');
        Conexao.Parametros('id_produto', DadosProduto.FieldByName('codigo')
          .AsInteger);

        DadosAdicionais.Close;
        DadosAdicionais.LoadFromJSON(Conexao.ConsultaSQL);

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
            Conexao.SQL.Add
              ('select * from pro_adi_personalizado_sabores where id_pro_adi_personalizado = :id');
            Conexao.Parametros('id', DadosAdicionais.FieldByName('id')
              .AsInteger);
            DadosAdicionaisItens.LoadFromJSON(Conexao.ConsultaSQL);
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
              JSonObjetoAdicionalItens.AddPair('alerta',
                DadosAdicionaisItens.FieldByName('alerta').AsInteger);
              try
                JSonObjetoAdicionalItens.AddPair('url',
                  DadosAdicionaisItens.FieldByName('url').AsString);
              except
                JSonObjetoAdicionalItens.AddPair('url', '');
              end;

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

        // ObjCombo: TJsonObject;

        DadosCombo := TFDMemTable.Create(nil);
        Combos := TJsonArray.Create;
        Conexao.SQL.Add
          ('select pci.produto_id as id, p.nome_produto as nome, p.foto_ifood as url, pci.ratio, pci.base_value as base_value from produto_combo_config as pc');
        Conexao.SQL.Add
          ('join produto_combo_item as pci on pci.combo_config_id = pc.id');
        Conexao.SQL.Add('join produto as p on p.codigo = pci.produto_id');
        Conexao.SQL.Add('where pc.produto_combo_id = :id and status = "ATIVO"');
        Conexao.Parametros('id', DadosProduto.FieldByName('codigo').AsInteger);
        DadosCombo.LoadFromJSON(Conexao.ConsultaSQL);
        if DadosCombo.RecordCount > 0 then
        begin
          while not DadosCombo.Eof do
          begin
            ObjCombo := TJsonObject.Create;
            ObjCombo.AddPair('id', DadosCombo.FieldByName('id').AsInteger);
            ObjCombo.AddPair('name', DadosCombo.FieldByName('nome').AsString);
            ObjCombo.AddPair('url', DadosCombo.FieldByName('url').AsString);
            ObjCombo.AddPair('ratio', DadosCombo.FieldByName('ratio').AsFloat);
            ObjCombo.AddPair('base_value',
              DadosCombo.FieldByName('base_value').AsFloat);
            Combos.Add(ObjCombo);
            DadosCombo.Next;
          end;
        end;
        JsonObjeto.AddPair('combo_products', Combos);
        DadosCombo.Free;

        JSONArray.AddElement(JsonObjeto);
        DadosProduto.Next;
      end;
    end;
  except
    on E: Exception do
    begin
      DataS := E.Message
    end;

  end;
  Result := JSONArray;
  Conexao.Free;
end;

end.
