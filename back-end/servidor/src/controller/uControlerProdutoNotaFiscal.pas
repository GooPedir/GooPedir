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

  TNota = record
    ValorTotal: Double;
    DataExpedicao: TDate;
  end;

  TNotaProduto = record
    Codigo: string;
    Nome: string;
    NCM: string;
    Unidade: string;
    Quantidade: Double;
    ValorUnitario: Double;
    cEAN: String;
    CEST: String;
    CFOP: String;
    uCom: String;
  end;

procedure DoPostDadosNotaFiscalFornecedor(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

implementation

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
  CodigoFornecedor: String;
  CodigoProduto: String;
begin
  Conexao := TConexao.Create('DoPostDadosNotaFiscalFornecedor');
  try

    JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

    // --- Empresa ---
    EmpresaObj := JSONBody.GetValue<TJSONObject>('empresa');
    Empresa.CNPJ := EmpresaObj.GetValue<string>('cnpj');
    Empresa.Nome := EmpresaObj.GetValue<string>('nome');

    // --- Nota ---
    NotaObj := JSONBody.GetValue<TJSONObject>('nota');
    Nota.ValorTotal := NotaObj.GetValue<Double>('valorTotal');
    Nota.DataExpedicao :=
      ISO8601ToDate(NotaObj.GetValue<string>('dataExpedicao'));

    // --- Produtos ---
    Produtos := TList<TNotaProduto>.Create;
    try
      ProdutosArray := JSONBody.GetValue<TJSONArray>('produtos');
      for I := 0 to ProdutosArray.Count - 1 do
      begin
        with TJSONObject(ProdutosArray.Items[I]) do
        begin
          ProdutoItem.Codigo := GetValue<string>('codigo');
          ProdutoItem.Nome := GetValue<string>('nome');
          ProdutoItem.NCM := GetValue<string>('ncm');
          ProdutoItem.cEAN := GetValue<string>('cEAN');
          ProdutoItem.CEST := GetValue<string>('CEST');
          ProdutoItem.CFOP := GetValue<string>('CFOP');
          ProdutoItem.uCom := GetValue<string>('uCom');
          ProdutoItem.Unidade := GetValue<string>('unidade');
          ProdutoItem.Quantidade := GetValue<Double>('quantidade');
          ProdutoItem.ValorUnitario := GetValue<Double>('valorUnitario');

        end;
        Produtos.Add(ProdutoItem);
      end;

      Conexao.SQL.Add('select * from fornecedor where cnpj = :cnpj');
      Conexao.Parametros('cnpj', Empresa.CNPJ);
      try
        CodigoFornecedor := Conexao.FieldByName('id');
      except

      end;

      if CodigoFornecedor = '0' then
      begin
        Conexao.SQL.Add
          ('insert into fornecedor (id,cnpj,nome) value (UUID(),:cnpj,:nome)');
        Conexao.Parametros('cnpj', Empresa.CNPJ);
        Conexao.Parametros('nome', Empresa.Nome);
        Conexao.ExecuteSQL;
        Conexao.SQL.Add('select * from fornecedor where cnpj = :cnpj');
        Conexao.Parametros('cnpj', Empresa.CNPJ);
        try
          CodigoFornecedor := Conexao.FieldByName('id');
        except

        end;
      end;

      for I := 0 to Produtos.Count - 1 do
      begin
        CodigoProduto := '';
        Conexao.SQL.Add
          ('select * from fornecedor_item  where fornecedor_id = :fornecedor and cprod = :cprod');
        Conexao.Parametros('fornecedor', CodigoFornecedor);
        Conexao.Parametros('cprod', Produtos[I].Codigo);
        try
          CodigoProduto := Conexao.FieldByName('id');
        except

        end;
        if CodigoProduto = '0' then
        begin
          Conexao.SQL.Add
            ('insert into fornecedor_item (id,fornecedor_id,cprod,cEAN,xProd,NCM,CEST,CFOP,uCom)');
          Conexao.SQL.Add
            ('values (UUID(),:fornecedor_id,:cprod,:cEAN,:xProd,:NCM,:CEST,:CFOP,:uCom)');
          Conexao.Parametros('fornecedor_id', CodigoFornecedor);
          Conexao.Parametros('cprod', Produtos[I].Codigo);
          Conexao.Parametros('cEAN', Produtos[I].cEAN);
          Conexao.Parametros('xProd', Produtos[I].Nome);
          Conexao.Parametros('NCM', Produtos[I].NCM);
          Conexao.Parametros('CEST', Produtos[I].CEST);
          Conexao.Parametros('CFOP', Produtos[I].CFOP);
          Conexao.Parametros('uCom', Produtos[I].uCom);
          Conexao.ExecuteSQL;
        end;

      end;


      // Aqui você pode integrar com o banco
      // Exemplo:
      // Conexao.InserirEmpresa(Empresa);
      // Conexao.InserirNota(Nota, Empresa.CNPJ);
      // for ProdutoItem in Produtos do
      // Conexao.InserirProduto(ProdutoItem, NotaID);

      Conexao.SQL.Add
        ('select * from fornecedor_item  where fornecedor_id = :fornecedor');
      Conexao.Parametros('fornecedor', CodigoFornecedor);

      Res.Send<TJSONArray>(Conexao.ConsultaSQL);
    finally
      Produtos.Free;
    end;
  finally
    Conexao.Free;
  end;
end;

end.
