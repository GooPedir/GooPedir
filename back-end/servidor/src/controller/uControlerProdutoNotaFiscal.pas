unit uControlerProdutoNotaFiscal;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  Horse, Conexao, System.DateUtils, dialogs;

type
  TNotaEmpresa = record
    CNPJ: string;
    Nome: string;
  end;

  // TNota = record
  // ValorTotal: Double;
  // DataExpedicao: TDate;
  // end;

  // TNotaProduto = record
  // Codigo: string;
  // Nome: string;
  // NCM: string;
  // Unidade: string;
  // Quantidade: Double;
  // ValorUnitario: Double;
  // cEAN: String;
  // CEST: String;
  // CFOP: String;
  // uCom: String;

  TNota = record
    Serie: string;
    Numero: string;
    Chave: string;
    Modelo: string;
    Tipo: string;
    DataEmissao: TDateTime;
    DataEntrada: TDateTime;
    vNF: Double;
    vFrete: Double;
    vDesc: Double;
    vOutro: Double;
    XML: string;
    Status: string;
  end;

  TNotaProduto = record
    Codigo: string;
    Nome: string;
    NCM: string;
    CFOP: string;
    qCom: Double;
    uCom: string;
    vUnCom: Double;
    vProd: Double;
    vDesc: Double;
    vFrete: Double;
    vOutro: Double;
    vTotal: Double;
    uTrib: string;
  end;

procedure DoPostDadosNotaFiscalFornecedor(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

procedure DoPostDadosNotaFiscalFornecedorItemFator(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

procedure DoPostValidarNotaFiscalDespesa(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

implementation

// procedure DoPostDadosNotaFiscalFornecedor(Req: THorseRequest;
// Res: THorseResponse; Next: TProc);
// var
// Conexao: TConexao;
// JSONBody: TJSONObject;
// EmpresaObj, NotaObj: TJSONObject;
// ProdutosArray: TJSONArray;
// Empresa: TNotaEmpresa;
// Nota: TNota;
// Produtos: TList<TNotaProduto>;
// ProdutoItem: TNotaProduto;
// I: Integer;
// CodigoFornecedor: String;
// CodigoProduto: String;
// begin
// Conexao := TConexao.Create('DoPostDadosNotaFiscalFornecedor');
// try
//
// JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
//
// // --- Empresa ---
// EmpresaObj := JSONBody.GetValue<TJSONObject>('empresa');
// Empresa.CNPJ := EmpresaObj.GetValue<string>('cnpj');
// Empresa.Nome := EmpresaObj.GetValue<string>('nome');
//
// // --- Nota ---
// NotaObj := JSONBody.GetValue<TJSONObject>('nota');
// Nota.ValorTotal := NotaObj.GetValue<Double>('valorTotal');
// Nota.DataExpedicao :=
// ISO8601ToDate(NotaObj.GetValue<string>('dataExpedicao'));
//
// // --- Produtos ---
// Produtos := TList<TNotaProduto>.Create;
// try
// ProdutosArray := JSONBody.GetValue<TJSONArray>('produtos');
// for I := 0 to ProdutosArray.Count - 1 do
// begin
// with TJSONObject(ProdutosArray.Items[I]) do
// begin
// ProdutoItem.Codigo := GetValue<string>('codigo');
// ProdutoItem.Nome := GetValue<string>('nome');
// ProdutoItem.NCM := GetValue<string>('ncm');
// ProdutoItem.cEAN := GetValue<string>('cEAN');
// ProdutoItem.CEST := GetValue<string>('CEST');
// ProdutoItem.CFOP := GetValue<string>('CFOP');
// ProdutoItem.uCom := GetValue<string>('uCom');
// ProdutoItem.Unidade := GetValue<string>('unidade');
// ProdutoItem.Quantidade := GetValue<Double>('quantidade');
// ProdutoItem.ValorUnitario := GetValue<Double>('valorUnitario');
//
// end;
// Produtos.Add(ProdutoItem);
// end;
//
// Conexao.SQL.Add('select * from fornecedor where cnpj = :cnpj');
// Conexao.Parametros('cnpj', Empresa.CNPJ);
// try
// CodigoFornecedor := Conexao.FieldByName('id');
// except
//
// end;
//
// if CodigoFornecedor = '0' then
// begin
// Conexao.SQL.Add
// ('insert into fornecedor (id,cnpj,nome) value (UUID(),:cnpj,:nome)');
// Conexao.Parametros('cnpj', Empresa.CNPJ);
// Conexao.Parametros('nome', Empresa.Nome);
// Conexao.ExecuteSQL;
// Conexao.SQL.Add('select * from fornecedor where cnpj = :cnpj');
// Conexao.Parametros('cnpj', Empresa.CNPJ);
// try
// CodigoFornecedor := Conexao.FieldByName('id');
// except
//
// end;
// end;
//
// for I := 0 to Produtos.Count - 1 do
// begin
// CodigoProduto := '';
// Conexao.SQL.Add
// ('select * from fornecedor_item  where fornecedor_id = :fornecedor and cprod = :cprod');
// Conexao.Parametros('fornecedor', CodigoFornecedor);
// Conexao.Parametros('cprod', Produtos[I].Codigo);
// try
// CodigoProduto := Conexao.FieldByName('id');
// except
//
// end;
// if CodigoProduto = '0' then
// begin
// Conexao.SQL.Add
// ('insert into fornecedor_item (id,fornecedor_id,cprod,cEAN,xProd,NCM,CEST,CFOP,uCom)');
// Conexao.SQL.Add
// ('values (UUID(),:fornecedor_id,:cprod,:cEAN,:xProd,:NCM,:CEST,:CFOP,:uCom)');
// Conexao.Parametros('fornecedor_id', CodigoFornecedor);
// Conexao.Parametros('cprod', Produtos[I].Codigo);
// Conexao.Parametros('cEAN', Produtos[I].cEAN);
// Conexao.Parametros('xProd', Produtos[I].Nome);
// Conexao.Parametros('NCM', Produtos[I].NCM);
// Conexao.Parametros('CEST', Produtos[I].CEST);
// Conexao.Parametros('CFOP', Produtos[I].CFOP);
// Conexao.Parametros('uCom', Produtos[I].uCom);
// Conexao.ExecuteSQL;
// end;
//
// end;
//
// // Aqui você pode integrar com o banco
// // Exemplo:
// // Conexao.InserirEmpresa(Empresa);
// // Conexao.InserirNota(Nota, Empresa.CNPJ);
// // for ProdutoItem in Produtos do
// // Conexao.InserirProduto(ProdutoItem, NotaID);
// Conexao.SQL.Add('select fi.*, ');
// Conexao.SQL.Add('CASE');
// Conexao.SQL.Add
// ('    WHEN fi.tabela_vinculo = "produto" THEN upper(p.nome_produto)');
// Conexao.SQL.Add('    ELSE upper(i.descricao)');
// Conexao.SQL.Add('  END AS insumo_nome,');
// Conexao.SQL.Add('CASE');
// Conexao.SQL.Add
// ('    WHEN fi.tabela_vinculo = "produto" THEN upper(p.un)');
// Conexao.SQL.Add('    ELSE upper(i.unidade)');
// Conexao.SQL.Add('  END AS insumo_unidade  ');
// Conexao.SQL.Add('from fornecedor_item as fi');
// Conexao.SQL.Add('left join produto as p on p.codigo = fi.codigo_vinculo');
// Conexao.SQL.Add
// ('left join ingredientes as i on i.id = fi.codigo_vinculo');
//
// Conexao.SQL.Add('where fornecedor_id = :fornecedor');
// Conexao.Parametros('fornecedor', CodigoFornecedor);
//
// Res.Send<TJSONArray>(Conexao.ConsultaSQL);
// finally
// Produtos.Free;
// end;
// finally
// Conexao.Free;
// end;
// end;

procedure DoPostDadosNotaFiscalFornecedor(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSONBody: TJSONObject;
  EmpresaObj, NotaObj: TJSONObject;
  ProdutosArray: TJSONArray;
  Empresa: TNotaEmpresa;
  Nota: TNota;
  Produtos: TList<TNotaProduto>;
  ProdutoItem: TNotaProduto;
  I: Integer;
  CodigoFornecedor, CodigoProduto, CodigoNota, CodigoFornecedorItem: String;
  Fmt: TFormatSettings;
begin
  Fmt := TFormatSettings.Create;
  Fmt.DecimalSeparator := '.';
  Conexao := TConexao.Create('DoPostDadosNotaFiscalFornecedor');
  try
    JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

    // --- EMPRESA ---
    EmpresaObj := JSONBody.GetValue<TJSONObject>('empresa');
    Empresa.CNPJ := EmpresaObj.GetValue<string>('cnpj');
    Empresa.Nome := EmpresaObj.GetValue<string>('nome');

    // --- NOTA ---
    NotaObj := JSONBody.GetValue<TJSONObject>('nota');
    Nota.Serie := NotaObj.GetValue<string>('serie');
    Nota.Numero := NotaObj.GetValue<string>('numero');
    Nota.Chave := NotaObj.GetValue<string>('chave');
    Nota.Modelo := NotaObj.GetValue<string>('modelo');
    Nota.Tipo := NotaObj.GetValue<string>('tipo');
    Nota.DataEmissao := ISO8601ToDate(NotaObj.GetValue<string>('data_emissao'));
    Nota.DataEntrada := ISO8601ToDate(NotaObj.GetValue<string>('data_entrada'));
    Nota.vNF := NotaObj.GetValue<Double>('vNF');
    Nota.vFrete := NotaObj.GetValue<Double>('vFrete');
    Nota.vDesc := NotaObj.GetValue<Double>('vDesc');
    Nota.vOutro := NotaObj.GetValue<Double>('vOutro');
    Nota.XML := NotaObj.GetValue<string>('xml_original');
    Nota.Status := NotaObj.GetValue<string>('status_importacao');

    // --- PRODUTOS ---
    Produtos := TList<TNotaProduto>.Create;
    try
      ProdutosArray := JSONBody.GetValue<TJSONArray>('produtos');
      for I := 0 to ProdutosArray.Count - 1 do
      begin
        with TJSONObject(ProdutosArray.Items[I]) do
        begin
          ProdutoItem.Codigo := GetValue<string>('cProd');
          ProdutoItem.Nome := GetValue<string>('xProd');
          ProdutoItem.NCM := GetValue<string>('NCM');
          ProdutoItem.CFOP := GetValue<string>('CFOP');
          ProdutoItem.qCom := GetValue<Double>('qCom');
          ProdutoItem.uCom := GetValue<string>('uCom');
          ProdutoItem.vUnCom := GetValue<Double>('vUnCom');
          ProdutoItem.vProd := GetValue<Double>('vProd');
          ProdutoItem.vDesc := GetValue<Double>('vDesc');
          ProdutoItem.vFrete := GetValue<Double>('vFrete');
          ProdutoItem.vOutro := GetValue<Double>('vOutro');
          ProdutoItem.vTotal := GetValue<Double>('vTotal');
          ProdutoItem.uTrib := GetValue<string>('uTrib');
        end;
        Produtos.Add(ProdutoItem);
      end;

      // --- FORNECEDOR ---
      Conexao.SQL.Add
        ('select id, 0 as zero from fornecedor where cnpj = :cnpj');
      Conexao.Parametros('cnpj', Empresa.CNPJ);
      CodigoFornecedor := Conexao.FieldByName('id');

      if (CodigoFornecedor = '') or (CodigoFornecedor = '0') then
      begin
        Conexao.SQL.Add
          ('insert into fornecedor (id, cnpj, nome, criado_em) values (UUID(), :cnpj, :nome, NOW())');
        Conexao.Parametros('cnpj', Empresa.CNPJ);
        Conexao.Parametros('nome', Empresa.Nome);
        Conexao.ExecuteSQL;

        Conexao.SQL.Add
          ('select id, 0 as zero from fornecedor where cnpj = :cnpj');
        Conexao.Parametros('cnpj', Empresa.CNPJ);
        CodigoFornecedor := Conexao.FieldByName('id');
      end;

      // --- NOTA FISCAL ---
      Conexao.SQL.Add
        ('select id, 0 as zero from nota_fiscal where chave = :chave');
      Conexao.Parametros('chave', Nota.Chave);
      CodigoNota := Conexao.FieldByName('id');

      if (CodigoNota = '') or (CodigoNota = '0') then
      begin
        Conexao.SQL.Add
          ('insert into nota_fiscal (id, fornecedor_id, serie, numero, chave, modelo, tipo, data_emissao, data_entrada, vNF, vFrete, vDesc, vOutro, xml_original, status_importacao, criado_em)');
        Conexao.SQL.Add
          ('values (UUID(), :fornecedor_id, :serie, :numero, :chave, :modelo, :tipo, :data_emissao, :data_entrada, :vNF, :vFrete, :vDesc, :vOutro, :xml_original, :status_importacao, NOW())');
        Conexao.Parametros('fornecedor_id', CodigoFornecedor);
        Conexao.Parametros('serie', Nota.Serie);
        Conexao.Parametros('numero', Nota.Numero);
        Conexao.Parametros('chave', Nota.Chave);
        Conexao.Parametros('modelo', Nota.Modelo);
        Conexao.Parametros('tipo', Nota.Tipo);
        Conexao.Parametros('data_emissao', FormatDateTime('yyyy-mm-dd hh:nn:ss',
          Nota.DataEmissao));
        Conexao.Parametros('data_entrada', FormatDateTime('yyyy-mm-dd hh:nn:ss',
          Nota.DataEntrada));
        Conexao.Parametros('vNF', Nota.vNF);
        Conexao.Parametros('vFrete', Nota.vFrete);
        Conexao.Parametros('vDesc', Nota.vDesc);
        Conexao.Parametros('vOutro', Nota.vOutro);
        Conexao.Parametros('xml_original', Nota.XML);
        Conexao.Parametros('status_importacao', Nota.Status);
        Conexao.ExecuteSQL;

        Conexao.SQL.Add('select id from nota_fiscal where chave = :chave');
        Conexao.Parametros('chave', Nota.Chave);
        CodigoNota := Conexao.FieldByName('id');
      end;

      // --- ITENS DA NOTA ---
      for I := 0 to Produtos.Count - 1 do
      begin
        // Verifica se já existe o item do fornecedor
        Conexao.SQL.Add
          ('select id, 0 as zero from fornecedor_item where fornecedor_id = :fornecedor and cprod = :cprod');
        Conexao.Parametros('fornecedor', CodigoFornecedor);
        Conexao.Parametros('cprod', Produtos[I].Codigo);
        CodigoFornecedorItem := Conexao.FieldByName('id');

        if (CodigoFornecedorItem = '') or (CodigoFornecedorItem = '0') then
        begin
          Conexao.SQL.Add
            ('insert into fornecedor_item (id, fornecedor_id, cprod, xProd, NCM, CFOP, uCom, criado_em)');
          Conexao.SQL.Add
            ('values (UUID(), :fornecedor_id, :cprod, :xProd, :NCM, :CFOP, :uCom, NOW())');
          Conexao.Parametros('fornecedor_id', CodigoFornecedor);
          Conexao.Parametros('cprod', Produtos[I].Codigo);
          Conexao.Parametros('xProd', Produtos[I].Nome);
          Conexao.Parametros('NCM', Produtos[I].NCM);
          Conexao.Parametros('CFOP', Produtos[I].CFOP);
          Conexao.Parametros('uCom', Produtos[I].uCom);
          Conexao.ExecuteSQL;

          Conexao.SQL.Add
            ('select id, 0 as zero from fornecedor_item where fornecedor_id = :fornecedor and cprod = :cprod');
          Conexao.Parametros('fornecedor', CodigoFornecedor);
          Conexao.Parametros('cprod', Produtos[I].Codigo);
          CodigoFornecedorItem := Conexao.FieldByName('id');
        end;

        // Insere item da nota
        Conexao.SQL.Add
          ('insert into nota_fiscal_item (id, nota_fiscal_id, fornecedor_item_id, cProd, xProd, NCM, CFOP, qCom, uCom, vUnCom, vProd, vDesc, vFrete, vOutro, uTrib, criado_em)');
        Conexao.SQL.Add
          ('values (UUID(), :nota_fiscal_id, :fornecedor_item_id, :cProd, :xProd, :NCM, :CFOP, :qCom, :uCom, :vUnCom, :vProd, :vDesc, :vFrete, :vOutro, :uTrib, NOW())');
        Conexao.Parametros('nota_fiscal_id', CodigoNota);
        Conexao.Parametros('fornecedor_item_id', CodigoFornecedorItem);
        Conexao.Parametros('cProd', Produtos[I].Codigo);
        Conexao.Parametros('xProd', Produtos[I].Nome);
        Conexao.Parametros('NCM', Produtos[I].NCM);
        Conexao.Parametros('CFOP', Produtos[I].CFOP);
        Conexao.Parametros('qCom', Produtos[I].qCom);
        Conexao.Parametros('uCom', Produtos[I].uCom);
        Conexao.Parametros('qCom', FormatFloat('0.######',
          Produtos[I].qCom, Fmt));
        Conexao.Parametros('vUnCom', FormatFloat('0.######',
          Produtos[I].vUnCom, Fmt));
        Conexao.Parametros('vProd', FormatFloat('0.##',
          Produtos[I].vProd, Fmt));
        Conexao.Parametros('vDesc', FormatFloat('0.##',
          Produtos[I].vDesc, Fmt));
        Conexao.Parametros('vFrete', FormatFloat('0.##',
          Produtos[I].vFrete, Fmt));
        Conexao.Parametros('vOutro', FormatFloat('0.##',
          Produtos[I].vOutro, Fmt));

        Conexao.ExecuteSQL;
      end;

      // --- RETORNO ORIGINAL ---
      Conexao.SQL.Add('select fi.*, ');
      Conexao.SQL.Add
        ('CASE WHEN fi.tabela_vinculo = "produto" THEN upper(p.nome_produto) ELSE upper(i.descricao) END AS insumo_nome,');
      Conexao.SQL.Add
        ('CASE WHEN fi.tabela_vinculo = "produto" THEN upper(p.un) ELSE upper(i.unidade) END AS insumo_unidade ');
      Conexao.SQL.Add('from fornecedor_item as fi ');
      Conexao.SQL.Add
        ('left join produto as p on p.codigo = fi.codigo_vinculo ');
      Conexao.SQL.Add
        ('left join ingredientes as i on i.id = fi.codigo_vinculo ');
      Conexao.SQL.Add('where fornecedor_id = :fornecedor');
      Conexao.Parametros('fornecedor', CodigoFornecedor);

      Res.Send<TJSONArray>(Conexao.ConsultaSQL);
    finally
      Produtos.Free;
    end;
  finally
    Conexao.Free;

  end;
end;

procedure DoPostValidarNotaFiscalDespesa(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSONBody: TJSONObject;
  Retorno: Boolean;
  reqs: String;
begin
  Conexao := TConexao.Create('DoPostValidarNotaFiscalDespesa');
  JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Conexao.SQL.Add
    ('select id, 0 as zero from despesa where chave_nota = :chave');
  Conexao.Parametros('chave', JSONBody.GetValue<string>('chave'));
  reqs := 'true';
  try
    Retorno := Conexao.FieldByName('id') > 0;
  except
    Retorno := False;

  end;

  if Retorno then
    reqs := 'false';
  Res.Send(reqs);

  Conexao.Free;
  JSONBody.Free;
end;

procedure DoPostDadosNotaFiscalFornecedorItemFator(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSONBody: TJSONObject;
begin
  Conexao := TConexao.Create('DoPostDadosNotaFiscalFornecedorItemFator');
  JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

  // JSONBody.GetValue<TJSONObject>('empresa');
  Conexao.SQL.Add
    ('update fornecedor_item set tabela_vinculo = :vinculo, campo_vinculo = "codigo", codigo_vinculo = :codigo, fator = :fator where fornecedor_id = :fornecedor and cprod = :prod');
  Conexao.Parametros('vinculo', JSONBody.GetValue<string>('tipo'));
  Conexao.Parametros('codigo', JSONBody.GetValue<string>('vinculoId'));
  Conexao.Parametros('fator', JSONBody.GetValue<string>('conversionFactor'));
  Conexao.Parametros('fornecedor', JSONBody.GetValue<string>('fornecedorId'));
  Conexao.Parametros('prod', JSONBody.GetValue<string>('codigo'));
  Conexao.ExecuteSQL;
  JSONBody.Free;
  Conexao.Free;
end;

end.
