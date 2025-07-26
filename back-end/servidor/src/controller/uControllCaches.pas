unit uControllCaches;

interface

uses
  JOSE.Types.JSON, uCacheControl, IOUtils, uControlerProduto;

function GetProdutoAdiciona(chave: String): TJsonArray;
function GetProdutoSabores(chave: String): TJsonArray;
function GetCategoria(chave: String): TJsonArray;
function GetAllCategoria(chave: String): TJsonArray;
function GetFichaProduto(chave: String): TJsonArray;
function GetProdutoCategoria(chave: String): TJsonArray;
function GetParametros: TJsonArray;

procedure LimpaCacheGeral;
procedure BuscaCacheGeral;
procedure GetAllProduto(Codigo: Integer);
procedure AtualizaParametro;
function GetProdutoVenda(Body, Codigo: String): TJSONObject;

implementation

uses
  conexao, System.SysUtils, System.Classes, Vcl.Dialogs;

function GetProdutoVenda(Body, Codigo: String): TJSONObject;
var
  conexao: TConexao;
  JSONObject: TJSONObject;

  QUANTIDADE: Real;
  JsonBody: TJSONObject;
  Data: String;
  Custo: Real;
  Venda: Real;
  CMV: Real;
  ReceitaTotal: Real;
  CMVPercentual: Real;

  URL: String;
begin
  URL := Codigo;
  try
    JsonBody := TJSONObject.ParseJSONValue(Body) as TJSONObject;
    if Assigned(JsonBody) then
    begin
      URL := Codigo + JsonBody.GetValue<String>('inicial') +
        JsonBody.GetValue<String>('final');
    end;
  except

  end;

  Result := BuscaCacheObject('GetProdutoVenda', URL);

  if Result.Count = 0 then
  begin

    conexao := TConexao.Create('CMV');
    JSONObject := TJSONObject.Create;
    conexao.SQL.Add
      ('select sum(pp.quantidade) as total, 0 as zero from pedido as p');
    conexao.SQL.Add
      ('join pedido_produtos as pp on pp.codigo_pedido = p.codigo');
    conexao.SQL.Add('where p.status > 0 and pp.codigo_produto = :codigo');
    conexao.Parametros('codigo', Codigo);
    try

      JsonBody := TJSONObject.ParseJSONValue(Body) as TJSONObject;
      if Assigned(JsonBody) then
      begin
        Data := JsonBody.GetValue<String>('inicial');
        conexao.SQL.Add('and p.data_pedido between :ini and :fim');
        conexao.Parametros('ini', JsonBody.GetValue<String>('inicial'));
        conexao.Parametros('fim', JsonBody.GetValue<String>('final'));

      end;
    except

    end;

    try
      QUANTIDADE := conexao.FieldByName('total');
    except
      QUANTIDADE := 1;
    end;

    JSONObject.AddPair('quantidade', QUANTIDADE);
    if QUANTIDADE = 0 then
    begin
      QUANTIDADE := 1;
    end;

    conexao.SQL.Add
      ('select custo_indiretos  as custo, 0 as zero from cmv where codigo_produto = :codigo order by id desc limit 1 ');
    conexao.Parametros('codigo', Codigo);
    try
      Custo := conexao.FieldByName('custo');
    except
      Custo := 0;
    end;

    conexao.SQL.Add
      ('  select valor_venda as venda, 0 as zero from produto where codigo = :codigo');
    conexao.Parametros('codigo', Codigo);
    try
      Venda := conexao.FieldByName('venda');
    except
      Venda := 0;
    end;

    CMV := Custo * QUANTIDADE;
    ReceitaTotal := Venda * QUANTIDADE;
    CMVPercentual := (CMV / ReceitaTotal) * 100;
    JSONObject.AddPair('cmv', CMVPercentual);

    Result := JSONObject;
    GravaCache('GetProdutoVenda', URL, Result.ToString);
    // Res.Send<TJSONObject>(JSONObject);
    conexao.Free;
  end;

end;

function GetParametros: TJsonArray;
var
  conexao: TConexao;
begin

  Result := BuscaCache('DoGetParametros', 'cache');
  if Result.Count = 0 then
  begin
    conexao := TConexao.Create('Util');
    conexao.SQL.Add('select * from dados_whatsapp');
    Result := conexao.ConsultaSQL;
    GravaCache('DoGetParametros', 'cache', Result.ToString);
    conexao.Free;
  end;

end;

function GetProdutoAdiciona(chave: String): TJsonArray;
var
  conexao: TConexao;
begin

  Result := BuscaCache('DoGetProdutoAdiciona', chave);
  if Result.Count = 0 then
  begin
    conexao := TConexao.Create('Util');
    conexao.SQL.Add('select paps.id as codigo, pap.descricao as categoria, paps.nome, paps.valor, p.observacao, qtd_minima as min, qtd_maxima as max from produto as p');
    conexao.SQL.Add('inner join pro_adi_personalizado as pap on pap.id_produto = p.codigo');
//    conexao.SQL.Add('inner join pro_adi_personalizado as pap on pap.id_produto = p.codigo or pap.categoria = p.codigo_grupo');
    conexao.SQL.Add('inner join pro_adi_personalizado_sabores as paps on paps.id_pro_adi_personalizado = pap.id and paps.ativo = 1');
    conexao.SQL.Add('where p.codigo = :codigo order by pap.categoria desc, paps.id_pro_adi_personalizado');
    conexao.Parametros('codigo', chave);
    Result := conexao.ConsultaSQL;
    GravaCache('DoGetProdutoAdiciona', chave, Result.ToString);
    conexao.Free;
  end;

end;

function GetProdutoSabores(chave: String): TJsonArray;
var
  conexao: TConexao;
begin

  Result := BuscaCache('DoGetProdutoSabores', chave);
  if Result.Count = 0 then
  begin
    conexao := TConexao.Create('Util');
    conexao.SQL.Add
      ('SELECT pp.quantidade_sabores, sc.nome, sc.vl_venda, sc.id, (SELECT tipo_preco_pizza FROM dados_whatsapp limit 1) as tipo_preco, (select nome from tipo_sabor where id = id_tipo_sabor) as tipo FROM produto_pizza as pp');
    conexao.SQL.Add
      ('join sabores_completo as sc on sc.id_produto = pp.codigo_produto');
    conexao.SQL.Add('where sc.id_produto = :codigo');
    conexao.SQL.Add('order by sc.id_tipo_sabor, sc.nome');
    conexao.Parametros('codigo', chave);
    Result := conexao.ConsultaSQL;
    GravaCache('DoGetProdutoSabores', chave, Result.ToString);
    conexao.Free;
  end;

end;

function GetCategoria(chave: String): TJsonArray;
var
  conexao: TConexao;
begin

  Result := BuscaCache('GetCategoria', chave);

  if Result.Count = 0 then
  begin
    conexao := TConexao.Create('Util');
    conexao.SQL.Add('SELECT  tp.* FROM tipo_produto as tp');
    conexao.SQL.Add('ORDER BY tp.ordem;');
    Result := conexao.ConsultaSQL;
    GravaCache('GetCategoria', chave, Result.ToString);
    conexao.Free;
  end;

end;

function GetAllCategoria(chave: String): TJsonArray;
var
  conexao: TConexao;
begin
  Result := BuscaCache('DoGetAllCategoria', chave);
  if Result.Count = 0 then
  begin
    conexao := TConexao.Create('Util');
    conexao.SQL.Add('SELECT DISTINCT tp.* FROM tipo_produto as tp');
    conexao.SQL.Add
      ('HAVING (SELECT COUNT(*) FROM produto WHERE produto.codigo_grupo = tp.codigo and produto.ativo = 1) > 0');
    conexao.SQL.Add('ORDER BY tp.ordem;');
    Result := conexao.ConsultaSQL;
    GravaCache('DoGetAllCategoria', chave, Result.ToString);
    conexao.Free;
  end;
end;

function GetFichaProduto(chave: String): TJsonArray;
var
  conexao: TConexao;
begin
  Result := BuscaCache('GetFichaProduto', chave);

  if Result.Count = 0 then
  begin
    conexao := TConexao.Create('Util');
    conexao.SQL.Add
      ('select produto_ingredientes.*, ingredientes.descricao, ingredientes.unidade, ingredientes.custo from produto_ingredientes');
    conexao.SQL.Add
      ('join ingredientes on ingredientes.id = produto_ingredientes.id_ingredientes');
    conexao.SQL.Add('where produto_ingredientes.id_produto = :produto');
    conexao.Parametros('produto', chave);
    Result := conexao.ConsultaSQL;
    GravaCache('GetFichaProduto', chave, Result.ToString);
    conexao.Free;
  end;
end;

function GetProdutoCategoria(chave: String): TJsonArray;
var
  conexao: TConexao;
  SQL: String;
begin
  Result := BuscaCache('GetProdutoCategoria', chave);

  if Result.Count = 0 then
  begin
    if chave = '0' then
    begin
      SQL := 'select produto.* from produto ';
      SQL := SQL +
        ' join tipo_produto on tipo_produto.codigo = produto.codigo_grupo ';
      // SQL := SQL + ' where produto.ativo = 1 ';
      SQL := SQL + ' order by codigo_grupo';
    end
    else
    begin
      SQL := 'select produto.* from produto ';
      SQL := SQL +
        ' join tipo_produto on tipo_produto.codigo = produto.codigo_grupo ';
      SQL := SQL + ' where codigo_grupo = ' + chave;
      SQL := SQL + ' order by position';
    end;
    Result := ObjetoProduto(SQL);
    GravaCache('GetProdutoCategoria', chave, Result.ToString);
  end;
end;

procedure LimpaCacheGeral;
var
  CaminhoExecutavel: String;
  PastaCache: String;
  Arquivo: TSearchRec;
begin
  // Obtém o caminho do executável
  CaminhoExecutavel := ExtractFilePath(ParamStr(0));

  // Define o caminho da pasta cache
  PastaCache := CaminhoExecutavel + 'cache';

  // Verifica se a pasta existe
  if DirectoryExists(PastaCache) then
  begin
    // Deleta todos os arquivos dentro da pasta cache
    if FindFirst(PastaCache + '\*.*', faAnyFile, Arquivo) = 0 then
      try
        repeat
          // Verifica se o arquivo não é diretório "." ou ".."
          if (Arquivo.Name <> '.') and (Arquivo.Name <> '..') then
          begin
            // Se for um arquivo, apaga
            if (Arquivo.Attr and faDirectory) = 0 then
            begin
              DeleteFile(PastaCache + '\' + Arquivo.Name);
            end
            // Se for uma pasta, usa TDirectory para apagá-la recursivamente
            else
            begin
              TDirectory.Delete(PastaCache + '\' + Arquivo.Name, True);
            end;
          end;
        until FindNext(Arquivo) <> 0;
      finally
        FindClose(Arquivo);
      end;
  end;
end;

procedure BuscaCacheGeral;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Categorias: TJsonArray;
      I: Integer;
      Categoria: TJSONObject;
      Codigo: TJSONValue;

      Produtos: TJsonArray;
      K: Integer;
      Produto: TJSONObject;
      CodigoProduto: TJSONValue;
    begin
      // LogThread('BuscaCacheGeral','Inicia');
      try
        LimpaCacheGeral;
        Categorias := GetCategoria('all');
        GetAllCategoria('all');

        // Verifica se o array de categorias é válido
        if Assigned(Categorias) then
        begin
          for I := 0 to Categorias.Count - 1 do
          begin
            // Converte cada item do array para um objeto JSON
            Categoria := Categorias.Items[I] as TJSONObject;

            // Pega o valor do campo 'codigo'
            Codigo := Categoria.GetValue('codigo');
            if Assigned(Codigo) then
            begin
              // Mostra o valor do campo 'codigo'
              Produtos := GetProdutoCategoria(Codigo.Value);

              if Assigned(Produtos) then
              begin
                for K := 0 to Produtos.Count - 1 do
                begin
                  Produto := Produtos.Items[K] as TJSONObject;
                  if Assigned(Produto) then
                  begin
                    CodigoProduto := Produto.GetValue('id');
                    GetAllProduto(StrToInt(CodigoProduto.Value));
                  end;
                end;
              end;
            end;
          end;
        end;
      except
        on E: Exception do
        begin

          // LogThread('BuscaCacheGeral','Erro: '+e.Message);
        end;
      end;
      // LogThread('BuscaCacheGeral','Finaliza');
    end).Start;
end;

procedure GetAllProduto(Codigo: Integer);
var
  conexao: TConexao;
  CodigoGrupo: Integer;
begin
  conexao := TConexao.Create('GetAllProduto');
  conexao.SQL.Add('select * from produto where codigo = :codigo');
  conexao.Parametros('codigo', Codigo);
  CodigoGrupo := conexao.FieldByName('codigo_grupo');

  LimpaCache('DoGetProdutoAdiciona', Codigo.ToString);
  LimpaCache('DoGetProdutoSabores', Codigo.ToString);
  LimpaCache('GetFichaProduto', Codigo.ToString);
  LimpaCache('GetProdutoCategoria', CodigoGrupo.ToString);
  // //showmessage1(CodigoGrupo.ToString);

  GetProdutoCategoria(CodigoGrupo.ToString);
  GetProdutoAdiciona(Codigo.ToString);
  GetProdutoSabores(Codigo.ToString);
  GetFichaProduto(Codigo.ToString);
  conexao.Free;
end;

procedure AtualizaParametro;
begin
  LimpaCache('DoGetParametros', 'cache');
  GetParametros;

end;

end.
