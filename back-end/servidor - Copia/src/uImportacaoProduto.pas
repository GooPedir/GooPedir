unit uImportacaoProduto;

interface

uses conexao, FireDAC.Comp.Client, DataSet.Serialize, System.SysUtils;

type
  TItemAdicional = class
  public
    id: Integer;
    nome: string;
    descricao: string;
    status: Integer;
    valor: Double;
  end;

  TAdicional = class
  public
    id: Integer;
    nome: string;
    min: Integer;
    max: Integer;
    itens: TArray<TItemAdicional>;
  end;

  TProduto = class
  public
    id: Integer;
    name: string;
    descricao: string;
    valor: Double;
    status: Integer;
    posicao: Integer;
    adicional_delivery: Double;
    estoque: Integer;
    vendido: Integer;
    promo: Double;
    foto: string;
    pessoas: Integer;
    fidelidade: Double;
    adicionais: TArray<TAdicional>;
  end;

  TCategoria = class
  public
    id: Integer;
    name: string;
    ordem: Integer;
    produtos: TArray<TProduto>;
  end;

procedure ImportaProdutos;

implementation

uses
  System.JSON, uRequisicao;

procedure ImportaProdutos;
var
  LJSONArray: TJSONArray;
  LCategoria: TCategoria;
  LProduto: TProduto;
  LAdicional: TAdicional;
  LItem: TItemAdicional;
  I, J, K, L: Integer;
  Requisicao: iRequisicao;

  conexao: TConexao;
  Codigo: Integer;
  Grupo: Integer;
  CodigoAdicional: Integer;
  CodigoItemAdicional: Integer;

begin
  conexao := TConexao.Create('uImportacaoProduto');

  Requisicao := iRequisicao.Create(nil);
  Requisicao.URL := 'https://api.goopedir.com.br/api/importacao/produtos/38';
  Requisicao.TempoExpiracao := 60 * 1000;
  Requisicao.Execute;

  LJSONArray := TJSONObject.ParseJSONValue(Requisicao.Retorno) as TJSONArray;

  for I := 0 to LJSONArray.Count - 1 do
  begin
    LCategoria := TCategoria.Create;
    try
      // Mapeando a Categoria
      LCategoria.id := LJSONArray.Items[I].GetValue<Integer>('id');
      LCategoria.name := LJSONArray.Items[I].GetValue<string>('name');
      LCategoria.ordem := LJSONArray.Items[I].GetValue<Integer>('ordem');

      conexao.SQL.Add('select * from tipo_produto where id_site = :site');
      conexao.Parametros('site', LCategoria.id);
      try
        Grupo := conexao.FieldByName('codigo');
      except
        Grupo := 0;
      end;

      if Grupo = 0 then
      begin
        // inserir
        Grupo := conexao.GerarID('tipo_produto', 'codigo');
        conexao.SQL.Add
          ('insert into tipo_produto (codigo,descricao,pizza,id_site,ordem,modificado_site) values (:codigo,:descricao,0,:id_site,:ordem,1)');
        conexao.Parametros('codigo', Grupo);
      end
      else
      begin
        conexao.SQL.Add
          ('update tipo_produto set descricao = :descricao, ordem = :ordem where id_site = :id_site');
      end;

      conexao.Parametros('descricao', LCategoria.name);
      conexao.Parametros('id_site', LCategoria.id);
      conexao.Parametros('ordem', Codigo);
      conexao.ExecuteSQL;

      // Para os produtos
      for J := 0 to LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
        .Count - 1 do
      begin
        LProduto := TProduto.Create;
        try
          LProduto.id := LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<Integer>('id');
          LProduto.name := LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('name');

          conexao.SQL.Add('select * from produto where id_site = :site');
          conexao.Parametros('site', LProduto.id);
          try
            Codigo := conexao.FieldByName('codigo');
          except
            Codigo := 0;
          end;

          if Codigo = 0 then
          begin
            Codigo := conexao.GerarID('produto', 'codigo');
            conexao.SQL.Add
              ('insert into produto (codigo,codigo_interno,data_cadastro,nome_produto,descricao,codigo_grupo,valor_venda,ativo,caminho_imagem,id_site,valor_embalagem_delivery,modificado_site,position,pessoas,valor_desconto,fidelidade)');
            conexao.SQL.Add
              ('values (:codigo,:codigo_interno,current_date,:nome_produto,:descricao,:codigo_grupo,:valor_venda,:ativo,:caminho_imagem,:id_site,:valor_embalagem_delivery,1,:position,:pessoas,:valor_desconto,:fidelidade)');
            conexao.Parametros('codigo', Codigo);
            conexao.Parametros('codigo_interno', FormatFloat('000000', Codigo));
            conexao.Parametros('codigo_grupo', Grupo);
          end
          else
          begin
            conexao.SQL.Add
              ('update produto set nome_produto = :nome_produto, descricao = :descricao, valor_venda = :valor_venda, ativo = :ativo, caminho_imagem = :caminho_imagem,');
            conexao.SQL.Add
              ('valor_embalagem_delivery = :valor_embalagem_delivery, position = :position, pessoas = :pessoas, valor_desconto = :valor_desconto, fidelidade = :fidelidade');
            conexao.SQL.Add('where id_site = :id_site');
          end;

          conexao.Parametros('nome_produto',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('name'));
          conexao.Parametros('descricao',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('descricao'));
          conexao.Parametros('valor_venda',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('valor'));
          conexao.Parametros('ativo', LJSONArray.Items[I].GetValue<TJSONArray>
            ('produtos').Items[J].GetValue<string>('status'));
          conexao.Parametros('caminho_imagem',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('foto'));
          conexao.Parametros('id_site', LJSONArray.Items[I].GetValue<TJSONArray>
            ('produtos').Items[J].GetValue<string>('id'));
          conexao.Parametros('valor_embalagem_delivery',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('adicional_delivery'));
          conexao.Parametros('position',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('posicao'));
          conexao.Parametros('pessoas', LJSONArray.Items[I].GetValue<TJSONArray>
            ('produtos').Items[J].GetValue<string>('pessoas'));
          conexao.Parametros('valor_desconto',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('promo'));
          conexao.Parametros('fidelidade',
            LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<string>('fidelidade'));
          // ... faça isso para todos os outros campos do produto
          conexao.ExecuteSQL;
          // Para os adicionais
          for K := 0 to LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
            .Items[J].GetValue<TJSONArray>('adicionais').Count - 1 do
          begin
            LAdicional := TAdicional.Create;

            // insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,id_site,modificado_site) values (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,id_site,modificado_site)
            try
              LAdicional.id := LJSONArray.Items[I].GetValue<TJSONArray>
                ('produtos').Items[J].GetValue<TJSONArray>('adicionais')
                .Items[K].GetValue<Integer>('id');
              LAdicional.nome := LJSONArray.Items[I].GetValue<TJSONArray>
                ('produtos').Items[J].GetValue<TJSONArray>('adicionais')
                .Items[K].GetValue<string>('nome');
              // ... faça isso para todos os campos de LAdicional

              conexao.SQL.Add
                ('select * from pro_adi_personalizado where id_site = :site');
              conexao.Parametros('site', LAdicional.id);
              try
                CodigoAdicional := conexao.FieldByName('id');
              except
                CodigoAdicional := 0;
              end;

              if CodigoAdicional = 0 then
              begin
                CodigoAdicional :=
                  conexao.GerarID('pro_adi_personalizado', 'id');
                conexao.SQL.Add
                  ('insert into pro_adi_personalizado (id,id_produto,descricao,ativo,qtd_minima,qtd_maxima,id_site,modificado_site)');
                conexao.SQL.Add
                  ('values (:id,:id_produto,:descricao,:ativo,:qtd_minima,:qtd_maxima,:id_site,1)');
                conexao.Parametros('id_produto', Codigo);
                conexao.Parametros('id', CodigoAdicional);
                conexao.Parametros('ativo', 1);
              end
              else
              begin
                conexao.SQL.Add
                  ('update pro_adi_personalizado set descricao = :descricao,  qtd_minima = :qtd_minima, qtd_maxima = :qtd_maxima where id_site = :id_site');
              end;

              conexao.Parametros('descricao',
                LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                .Items[J].GetValue<TJSONArray>('adicionais')
                .Items[K].GetValue<string>('nome'));

              conexao.Parametros('qtd_minima',
                LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                .Items[J].GetValue<TJSONArray>('adicionais')
                .Items[K].GetValue<string>('min'));
              conexao.Parametros('qtd_maxima',
                LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                .Items[J].GetValue<TJSONArray>('adicionais')
                .Items[K].GetValue<string>('max'));
              conexao.Parametros('id_site', LAdicional.id);
              conexao.ExecuteSQL;

              // Para os itens do adicional
              for L := 0 to LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                .Items[J].GetValue<TJSONArray>('adicionais')
                .Items[K].GetValue<TJSONArray>('itens').Count - 1 do
              begin
                LItem := TItemAdicional.Create;

                conexao.SQL.Add
                  ('select * from pro_adi_personalizado_sabores where id_site = :site');
                conexao.Parametros('site', LAdicional.id);
                try
                  CodigoItemAdicional := conexao.FieldByName('id');
                except
                  CodigoItemAdicional := 0;
                end;

                if CodigoItemAdicional = 0 then
                begin
                  CodigoItemAdicional :=
                    conexao.GerarID('pro_adi_personalizado_sabores', 'id');
                  conexao.SQL.Add
                    ('insert into pro_adi_personalizado_sabores (id,id_pro_adi_personalizado,nome,descricao,valor,ativo,id_site,modificado_site)');
                  conexao.SQL.Add
                    ('values (:id,:id_pro_adi_personalizado,:nome,:descricao,:valor,:ativo,:id_site,1)');

                  conexao.Parametros('id', CodigoItemAdicional);
                  conexao.Parametros('id_pro_adi_personalizado',
                    CodigoAdicional);

                end
                else
                begin
                  conexao.SQL.Add
                    ('update pro_adi_personalizado_sabores set nome = :nome, descricao = :descricao, valor = :valor, ativo = :ativo where id_site = :id_site');
                end;

                conexao.Parametros('nome',
                  LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                  .Items[J].GetValue<TJSONArray>('adicionais')
                  .Items[K].GetValue<TJSONArray>('itens')
                  .Items[L].GetValue<String>('nome'));
                conexao.Parametros('descricao',
                  LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                  .Items[J].GetValue<TJSONArray>('adicionais')
                  .Items[K].GetValue<TJSONArray>('itens')
                  .Items[L].GetValue<String>('descricao'));
                conexao.Parametros('valor',
                  LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                  .Items[J].GetValue<TJSONArray>('adicionais')
                  .Items[K].GetValue<TJSONArray>('itens')
                  .Items[L].GetValue<String>('valor'));
                conexao.Parametros('ativo',
                  LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                  .Items[J].GetValue<TJSONArray>('adicionais')
                  .Items[K].GetValue<TJSONArray>('itens')
                  .Items[L].GetValue<String>('status'));
                conexao.Parametros('id_site',
                  LJSONArray.Items[I].GetValue<TJSONArray>('produtos')
                  .Items[J].GetValue<TJSONArray>('adicionais')
                  .Items[K].GetValue<TJSONArray>('itens')
                  .Items[L].GetValue<String>('id'));
                conexao.ExecuteSQL;

              end;
            finally
              LAdicional.Free;
            end;
          end;
        finally
          LProduto.Free;
        end;
      end;
    finally
      LCategoria.Free;
    end;

  end;
  Requisicao.Free;
  conexao.Free;

end;

end.
