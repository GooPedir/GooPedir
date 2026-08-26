unit uControlerProdutoNotaFiscal;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  Horse, Conexao, System.DateUtils, dialogs, FireDAC.Comp.Client, DataSet.Serialize,
  System.RegularExpressions, System.Net.HttpClient, System.Net.URLClient,
  System.StrUtils;

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

procedure DoPostConsultarNFCeSantaCatarina(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

procedure DoPostDadosNotaFiscalFornecedorItemFator(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

procedure DoPostValidarNotaFiscalDespesa(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
procedure DoGetFornecedores(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

procedure DoPostFornecedor(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

procedure DoGetFornecedorDossie(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

procedure DoPostNotaFiscalEntradaEstoque(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);

function ValidarAlertaNotasFiscaisSemEntradaEstoque: TJSONObject;

implementation

function JSONStringValue(JSON: TJSONObject; const Name: string): string;
var
  Value: TJSONValue;
begin
  Result := '';
  if not Assigned(JSON) then
    Exit;

  Value := JSON.GetValue(Name);
  if Assigned(Value) and not (Value is TJSONNull) then
    Result := Value.Value;
end;

function BuscarFornecedorPorParametro(Conexao: TConexao; const Valor: string): string;
begin
  Result := '';
  if Trim(Valor) = '' then
    Exit;

  Conexao.SQL.Add('select id, 0 as zero from fornecedor where id = :valor or cnpj = :valor limit 1');
  Conexao.Parametros('valor', Valor);
  try
    Result := Conexao.FieldByName('id');
  except
    Result := '';
  end;
end;

function JSONParamValue(Req: THorseRequest; const Name: string): string;
begin
  Result := '';
  try
    Result := Req.Params[Name];
  except
  end;
end;

function JSONQueryValue(Req: THorseRequest; const Name: string): string;
begin
  Result := '';
  try
    Result := Req.Query[Name];
  except
  end;
end;
function NormalizarDataSQL(const Valor: string): string;
var
  Data: TDateTime;
  Fmt: TFormatSettings;
begin
  Result := Trim(Valor);
  if Result = '' then
    Exit;
  Fmt := TFormatSettings.Create;
  Fmt.DateSeparator := '-';
  Fmt.ShortDateFormat := 'dd-mm-yyyy';
  if TryStrToDate(Result, Data, Fmt) then
  begin
    Result := FormatDateTime('yyyy-mm-dd', Data);
    Exit;
  end;
  Fmt.DateSeparator := '/';
  Fmt.ShortDateFormat := 'dd/mm/yyyy';
  if TryStrToDate(Result, Data, Fmt) then
  begin
    Result := FormatDateTime('yyyy-mm-dd', Data);
    Exit;
  end;
  Fmt.DateSeparator := '-';
  Fmt.ShortDateFormat := 'yyyy-mm-dd';
  if TryStrToDate(Result, Data, Fmt) then
    Result := FormatDateTime('yyyy-mm-dd', Data);
end;

procedure GarantirCamposEntradaEstoqueNotaFiscal(Conexao: TConexao);
begin
  try
    Conexao.SQL.Add('ALTER TABLE nota_fiscal_item ADD COLUMN entrada_estoque TINYINT DEFAULT 0');
    Conexao.ExecuteSQL;
  except
  end;

  try
    Conexao.SQL.Add('ALTER TABLE nota_fiscal_item ADD COLUMN entrada_estoque_em DATETIME NULL');
    Conexao.ExecuteSQL;
  except
  end;

  try
    Conexao.SQL.Add('ALTER TABLE nota_fiscal_item ADD COLUMN entrada_estoque_msg VARCHAR(255) NULL');
    Conexao.ExecuteSQL;
  except
  end;
end;

procedure GarantirTipoAlertaEstoqueNotaFiscal(Conexao: TConexao);
begin
  try
    Conexao.SQL.Add
      ('ALTER TABLE alerta_sistema MODIFY COLUMN tipo ENUM("CHAMAR_GARCOM","ERRO_SENHA_TABLET","ALERTA_SEGURANCA","NFCE_ERRO","OUTRO","PRODUTO","SISTEMA","DFE","ESTOQUE") NOT NULL');
    Conexao.ExecuteSQL;
  except
  end;
end;

function ValidarAlertaNotasFiscaisSemEntradaEstoque: TJSONObject;
var
  Conexao: TConexao;
  TotalNotas, TotalItens: Integer;
  AlertaExistente: string;
  Mensagem: string;
begin
  Conexao := TConexao.Create('ValidarAlertaNotasFiscaisSemEntradaEstoque');
  Result := TJSONObject.Create;
  try
    GarantirCamposEntradaEstoqueNotaFiscal(Conexao);
    GarantirTipoAlertaEstoqueNotaFiscal(Conexao);

    Conexao.SQL.Add('select count(distinct nf.id) as total_notas, count(nfi.id) as total_itens');
    Conexao.SQL.Add('from nota_fiscal nf');
    Conexao.SQL.Add('join nota_fiscal_item nfi on nfi.nota_fiscal_id = nf.id');
    Conexao.SQL.Add('where date(nf.data_emissao) >= date_sub(curdate(), interval 7 day)');
    Conexao.SQL.Add('and coalesce(nfi.entrada_estoque, 0) <> 1');
    TotalNotas := StrToIntDef(Conexao.FieldByName('total_notas'), 0);
    TotalItens := StrToIntDef(Conexao.FieldByName('total_itens'), 0);

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('total_notas', TJSONNumber.Create(TotalNotas));
    Result.AddPair('total_itens', TJSONNumber.Create(TotalItens));
    Result.AddPair('alertaCriado', TJSONBool.Create(False));

    if TotalNotas = 0 then
      Exit;

    Conexao.SQL.Add('select id, 0 as zero from alerta_sistema');
    Conexao.SQL.Add('where status = "ABERTO" and tipo = "ESTOQUE"');
    Conexao.SQL.Add('and CAST(payload AS CHAR) LIKE "%NOTAS_FISCAIS_SEM_ENTRADA_ESTOQUE%"');
    Conexao.SQL.Add('limit 1');
    AlertaExistente := Conexao.FieldByName('id');
    if (AlertaExistente <> '') and (AlertaExistente <> '0') then
      Exit;

    Mensagem := IntToStr(TotalNotas) +
      ' notas fiscais dos ultimos 7 dias pendentes de entrada no estoque.';

    Conexao.SQL.Add('INSERT INTO alerta_sistema');
    Conexao.SQL.Add('(tipo, origem, referencia_id, payload)');
    Conexao.SQL.Add('VALUES ("ESTOQUE", "SISTEMA", NULL,');
    Conexao.SQL.Add('JSON_OBJECT("tipo_alerta", "NOTAS_FISCAIS_SEM_ENTRADA_ESTOQUE",');
    Conexao.SQL.Add('"mensagem", :mensagem, "total_notas", :total_notas,');
    Conexao.SQL.Add('"total_itens", :total_itens, "periodo_dias", 7,');
    Conexao.SQL.Add('"rota", "/v2/notafiscal/entrada-estoque"))');
    Conexao.Parametros('mensagem', Mensagem);
    Conexao.Parametros('total_notas', TotalNotas);
    Conexao.Parametros('total_itens', TotalItens);
    Conexao.ExecuteSQL;

    Result.RemovePair('alertaCriado').Free;
    Result.AddPair('alertaCriado', TJSONBool.Create(True));
  except
    on E: Exception do
    begin
      Result.Free;
      Result := TJSONObject.Create;
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('erro', E.Message);
    end;
  end;
  Conexao.Free;
end;
procedure EntradaEstoqueProdutoNota(Conexao: TConexao; const ItemID: string;
  CodigoProduto: Integer; Quantidade: Double);
var
  MovimentoID: Integer;
  Transacao: string;
begin
  MovimentoID := Conexao.GerarID('produto_estoque', 'codigo');
  Transacao := 'NF-' + ItemID;
  Conexao.SQL.Add('insert ignore into produto_estoque (codigo,data,hora,operacao,codigo_produto,quantidade,saldo_novo,saldo_atual,transacao)');
  Conexao.SQL.Add('values (:codigo,current_date,current_time,1,:codigo_produto,:quantidade,0,0,:transacao)');
  Conexao.Parametros('codigo', MovimentoID);
  Conexao.Parametros('codigo_produto', CodigoProduto);
  Conexao.Parametros('quantidade', Quantidade);
  Conexao.Parametros('transacao', Transacao);
  Conexao.ExecuteSQL;
end;

procedure EntradaEstoqueIngredienteNota(Conexao: TConexao; const ItemID: string;
  CodigoIngrediente: Integer; Quantidade, CustoTotal, Custo: Double);
var
  MovimentoID: Integer;
begin
  MovimentoID := Conexao.GerarID('ingredientes_estoque', 'id');

  Conexao.SQL.Add('update ingredientes set saldo = COALESCE(saldo, 0) + :saldo where id = :id_ingredientes');
  Conexao.Parametros('id_ingredientes', CodigoIngrediente);
  Conexao.Parametros('saldo', Quantidade);
  Conexao.ExecuteSQL;

  Conexao.SQL.Add('insert into ingredientes_estoque (id,id_ingredientes,data,hora,tipo,quantidade,custo_total,custo)');
  Conexao.SQL.Add('values (:id,:id_ingredientes,current_date,current_time,1,:quantidade,:custo_total,:custo)');
  Conexao.Parametros('id', MovimentoID);
  Conexao.Parametros('id_ingredientes', CodigoIngrediente);
  Conexao.Parametros('quantidade', Quantidade);
  Conexao.Parametros('custo_total', CustoTotal);
  Conexao.Parametros('custo', Custo);
  Conexao.ExecuteSQL;

  if Custo > 0 then
  begin
    Conexao.SQL.Add('update ingredientes set custo = :custo, custo_ultimo = :custo where id = :id');
    Conexao.Parametros('custo', Custo);
    Conexao.Parametros('id', CodigoIngrediente);
    Conexao.ExecuteSQL;
  end;
end;
function FormatarValorNotificacaoNotaFiscal(Valor: Double): string;
var
  FmtMoeda: TFormatSettings;
begin
  FmtMoeda := TFormatSettings.Create;
  FmtMoeda.DecimalSeparator := '.';
  FmtMoeda.ThousandSeparator := '.';
  Result := FormatFloat('#,##0.00', Valor, FmtMoeda);
end;
procedure RegistrarNotificacaoNotaFiscalBaixada(Conexao: TConexao;
  const CodigoNota, FornecedorNome, Chave: string; ValorNota: Double);
var
  Mensagem, ValorFormatado: string;
  FmtBanco: TFormatSettings;
begin
  ValorFormatado := FormatarValorNotificacaoNotaFiscal(ValorNota);
  Mensagem := 'Nova nota fiscal lancada manualmente ' + FornecedorNome + ' R$ ' +
    ValorFormatado;
  FmtBanco := TFormatSettings.Create;
  FmtBanco.DecimalSeparator := '.';
  Conexao.SQL.Add('INSERT INTO alerta_sistema ' +
    '(tipo, origem, referencia_id, payload) ' +
    'VALUES (''SISTEMA'', ''SISTEMA'', NULL, ' +
    'JSON_OBJECT(''mensagem'', :mensagem, ''fornecedor'', :fornecedor, ' +
    '''origem_entrada'', ''manual'', ''valor'', :valor, ''valor_numero'', :valor_numero, ' +
    '''nota_id'', :nota_id, ''chave'', :chave))');
  Conexao.Parametros('mensagem', Mensagem);
  Conexao.Parametros('fornecedor', FornecedorNome);
  Conexao.Parametros('valor', 'R$ ' + ValorFormatado);
  Conexao.Parametros('valor_numero', FormatFloat('0.00', ValorNota, FmtBanco));
  Conexao.Parametros('nota_id', CodigoNota);
  Conexao.Parametros('chave', Chave);
  Conexao.ExecuteSQL;
end;

function ImportarPayloadNotaFiscalFornecedor(JSONBody: TJSONObject): TJSONObject;
var
  Conexao: TConexao;
  EmpresaObj, NotaObj: TJSONObject;
  ProdutosArray, ItensFornecedor: TJSONArray;
  ProdutoObj: TJSONObject;
  Empresa: TNotaEmpresa;
  Nota: TNota;
  I: Integer;
  CodigoFornecedor, CodigoNota, CodigoFornecedorItem: String;
  Fmt: TFormatSettings;
  NotaJaExistia: Boolean;
begin
  Result := TJSONObject.Create;
  Conexao := TConexao.Create('ImportarPayloadNotaFiscalFornecedor');
  Fmt := TFormatSettings.Create;
  Fmt.DecimalSeparator := '.';
  try
    EmpresaObj := JSONBody.GetValue<TJSONObject>('empresa');
    NotaObj := JSONBody.GetValue<TJSONObject>('nota');
    ProdutosArray := JSONBody.GetValue<TJSONArray>('produtos');
    if (not Assigned(EmpresaObj)) or (not Assigned(NotaObj)) or (not Assigned(ProdutosArray)) then
      raise Exception.Create('Payload de importacao da nota fiscal invalido.');

    Empresa.CNPJ := JSONStringValue(EmpresaObj, 'cnpj');
    Empresa.Nome := JSONStringValue(EmpresaObj, 'nome');
    Nota.Serie := JSONStringValue(NotaObj, 'serie');
    Nota.Numero := JSONStringValue(NotaObj, 'numero');
    Nota.Chave := JSONStringValue(NotaObj, 'chave');
    Nota.Modelo := JSONStringValue(NotaObj, 'modelo');
    Nota.Tipo := JSONStringValue(NotaObj, 'tipo');
    if SameText(Nota.Modelo, '65') then
      Nota.Tipo := 'NFCe'
    else if Nota.Tipo = '' then
      Nota.Tipo := 'NF';
    Nota.DataEmissao := ISO8601ToDate(JSONStringValue(NotaObj, 'data_emissao'));
    Nota.DataEntrada := ISO8601ToDate(JSONStringValue(NotaObj, 'data_entrada'));
    Nota.vNF := StrToFloatDef(StringReplace(JSONStringValue(NotaObj, 'vNF'), ',', '.', [rfReplaceAll]), 0, Fmt);
    Nota.vFrete := StrToFloatDef(StringReplace(JSONStringValue(NotaObj, 'vFrete'), ',', '.', [rfReplaceAll]), 0, Fmt);
    Nota.vDesc := StrToFloatDef(StringReplace(JSONStringValue(NotaObj, 'vDesc'), ',', '.', [rfReplaceAll]), 0, Fmt);
    Nota.vOutro := StrToFloatDef(StringReplace(JSONStringValue(NotaObj, 'vOutro'), ',', '.', [rfReplaceAll]), 0, Fmt);
    Nota.XML := JSONStringValue(NotaObj, 'xml_original');
    Nota.Status := JSONStringValue(NotaObj, 'status_importacao');
    if Nota.Status = '' then
      Nota.Status := 'pendente';

    Conexao.SQL.Add('select id, 0 as zero from fornecedor where cnpj = :cnpj');
    Conexao.Parametros('cnpj', Empresa.CNPJ);
    CodigoFornecedor := Conexao.FieldByName('id');
    if (CodigoFornecedor = '') or (CodigoFornecedor = '0') then
    begin
      Conexao.SQL.Add('insert into fornecedor (id, cnpj, nome, criado_em) values (UUID(), :cnpj, :nome, NOW())');
      Conexao.Parametros('cnpj', Empresa.CNPJ);
      Conexao.Parametros('nome', Empresa.Nome);
      Conexao.ExecuteSQL;
      Conexao.SQL.Add('select id, 0 as zero from fornecedor where cnpj = :cnpj');
      Conexao.Parametros('cnpj', Empresa.CNPJ);
      CodigoFornecedor := Conexao.FieldByName('id');
    end;

    Conexao.SQL.Add('select id, 0 as zero from nota_fiscal where chave = :chave');
    Conexao.Parametros('chave', Nota.Chave);
    CodigoNota := Conexao.FieldByName('id');
    NotaJaExistia := (CodigoNota <> '') and (CodigoNota <> '0');

    if not NotaJaExistia then
    begin
      Conexao.SQL.Add('select UUID() as id, 0 as zero');
      CodigoNota := Conexao.FieldByName('id');
      if (CodigoNota = '') or (CodigoNota = '0') then
        raise Exception.Create('Nao foi possivel gerar o ID da nota fiscal.');

      Conexao.SQL.Add('insert into nota_fiscal (id, fornecedor_id, serie, numero, chave, modelo, tipo, data_emissao, data_entrada, vNF, vFrete, vDesc, vOutro, xml_original, status_importacao, criado_em)');
      Conexao.SQL.Add('values (:id, :fornecedor_id, :serie, :numero, :chave, :modelo, :tipo, :data_emissao, :data_entrada, :vNF, :vFrete, :vDesc, :vOutro, :xml_original, :status_importacao, NOW())');
      Conexao.Parametros('id', CodigoNota);
      Conexao.Parametros('fornecedor_id', CodigoFornecedor);
      Conexao.Parametros('serie', Nota.Serie);
      Conexao.Parametros('numero', Nota.Numero);
      Conexao.Parametros('chave', Nota.Chave);
      Conexao.Parametros('modelo', Nota.Modelo);
      Conexao.Parametros('tipo', Nota.Tipo);
      Conexao.Parametros('data_emissao', FormatDateTime('yyyy-mm-dd hh:nn:ss', Nota.DataEmissao));
      Conexao.Parametros('data_entrada', FormatDateTime('yyyy-mm-dd hh:nn:ss', Nota.DataEntrada));
      Conexao.Parametros('vNF', FormatFloat('0.##', Nota.vNF, Fmt));
      Conexao.Parametros('vFrete', FormatFloat('0.##', Nota.vFrete, Fmt));
      Conexao.Parametros('vDesc', FormatFloat('0.##', Nota.vDesc, Fmt));
      Conexao.Parametros('vOutro', FormatFloat('0.##', Nota.vOutro, Fmt));
      Conexao.Parametros('xml_original', Nota.XML);
      Conexao.Parametros('status_importacao', Nota.Status);
      Conexao.ExecuteSQL;
      RegistrarNotificacaoNotaFiscalBaixada(Conexao, CodigoNota, Empresa.Nome, Nota.Chave, Nota.vNF);
    end;

    if not NotaJaExistia then
    begin
      for I := 0 to ProdutosArray.Count - 1 do
      begin
        ProdutoObj := ProdutosArray.Items[I] as TJSONObject;
        Conexao.SQL.Add('select id, 0 as zero from fornecedor_item where fornecedor_id = :fornecedor and cprod = :cprod');
        Conexao.Parametros('fornecedor', CodigoFornecedor);
        Conexao.Parametros('cprod', JSONStringValue(ProdutoObj, 'cProd'));
        CodigoFornecedorItem := Conexao.FieldByName('id');

        if (CodigoFornecedorItem = '') or (CodigoFornecedorItem = '0') then
        begin
          Conexao.SQL.Add('insert into fornecedor_item (id, fornecedor_id, cprod, xProd, NCM, CFOP, uCom, criado_em)');
          Conexao.SQL.Add('values (UUID(), :fornecedor_id, :cprod, :xProd, :NCM, :CFOP, :uCom, NOW())');
          Conexao.Parametros('fornecedor_id', CodigoFornecedor);
          Conexao.Parametros('cprod', JSONStringValue(ProdutoObj, 'cProd'));
          Conexao.Parametros('xProd', JSONStringValue(ProdutoObj, 'xProd'));
          Conexao.Parametros('NCM', JSONStringValue(ProdutoObj, 'NCM'));
          Conexao.Parametros('CFOP', JSONStringValue(ProdutoObj, 'CFOP'));
          Conexao.Parametros('uCom', JSONStringValue(ProdutoObj, 'uCom'));
          Conexao.ExecuteSQL;
          Conexao.SQL.Add('select id, 0 as zero from fornecedor_item where fornecedor_id = :fornecedor and cprod = :cprod');
          Conexao.Parametros('fornecedor', CodigoFornecedor);
          Conexao.Parametros('cprod', JSONStringValue(ProdutoObj, 'cProd'));
          CodigoFornecedorItem := Conexao.FieldByName('id');
        end;

        Conexao.SQL.Add('insert into nota_fiscal_item (id, nota_fiscal_id, fornecedor_item_id, cProd, xProd, NCM, CFOP, qCom, uCom, vUnCom, vProd, vDesc, vFrete, vOutro, uTrib, criado_em)');
        Conexao.SQL.Add('values (UUID(), :nota_fiscal_id, :fornecedor_item_id, :cProd, :xProd, :NCM, :CFOP, :qCom, :uCom, :vUnCom, :vProd, :vDesc, :vFrete, :vOutro, :uTrib, NOW())');
        Conexao.Parametros('nota_fiscal_id', CodigoNota);
        Conexao.Parametros('fornecedor_item_id', CodigoFornecedorItem);
        Conexao.Parametros('cProd', JSONStringValue(ProdutoObj, 'cProd'));
        Conexao.Parametros('xProd', JSONStringValue(ProdutoObj, 'xProd'));
        Conexao.Parametros('NCM', JSONStringValue(ProdutoObj, 'NCM'));
        Conexao.Parametros('CFOP', JSONStringValue(ProdutoObj, 'CFOP'));
        Conexao.Parametros('qCom', FormatFloat('0.######', StrToFloatDef(StringReplace(JSONStringValue(ProdutoObj, 'qCom'), ',', '.', [rfReplaceAll]), 0, Fmt), Fmt));
        Conexao.Parametros('uCom', JSONStringValue(ProdutoObj, 'uCom'));
        Conexao.Parametros('vUnCom', FormatFloat('0.######', StrToFloatDef(StringReplace(JSONStringValue(ProdutoObj, 'vUnCom'), ',', '.', [rfReplaceAll]), 0, Fmt), Fmt));
        Conexao.Parametros('vProd', FormatFloat('0.##', StrToFloatDef(StringReplace(JSONStringValue(ProdutoObj, 'vProd'), ',', '.', [rfReplaceAll]), 0, Fmt), Fmt));
        Conexao.Parametros('vDesc', FormatFloat('0.##', StrToFloatDef(StringReplace(JSONStringValue(ProdutoObj, 'vDesc'), ',', '.', [rfReplaceAll]), 0, Fmt), Fmt));
        Conexao.Parametros('vFrete', FormatFloat('0.##', StrToFloatDef(StringReplace(JSONStringValue(ProdutoObj, 'vFrete'), ',', '.', [rfReplaceAll]), 0, Fmt), Fmt));
        Conexao.Parametros('vOutro', FormatFloat('0.##', StrToFloatDef(StringReplace(JSONStringValue(ProdutoObj, 'vOutro'), ',', '.', [rfReplaceAll]), 0, Fmt), Fmt));
        Conexao.Parametros('uTrib', JSONStringValue(ProdutoObj, 'uTrib'));
        Conexao.ExecuteSQL;
      end;
    end;

    Conexao.SQL.Add('select fi.*, ');
    Conexao.SQL.Add('CASE WHEN fi.tabela_vinculo = "produto" THEN upper(p.nome_produto) ELSE upper(i.descricao) END AS insumo_nome,');
    Conexao.SQL.Add('CASE WHEN fi.tabela_vinculo = "produto" THEN upper(p.un) ELSE upper(i.unidade) END AS insumo_unidade ');
    Conexao.SQL.Add('from fornecedor_item as fi ');
    Conexao.SQL.Add('left join produto as p on p.codigo = fi.codigo_vinculo ');
    Conexao.SQL.Add('left join ingredientes as i on i.id = fi.codigo_vinculo ');
    Conexao.SQL.Add('where fornecedor_id = :fornecedor');
    Conexao.Parametros('fornecedor', CodigoFornecedor);
    ItensFornecedor := Conexao.ConsultaSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('fornecedor_id', CodigoFornecedor);
    Result.AddPair('nota_fiscal_id', CodigoNota);
    Result.AddPair('nota_ja_existia', TJSONBool.Create(NotaJaExistia));
    Result.AddPair('itens_fornecedor', ItensFornecedor);
  except
    Result.Free;
    Conexao.Free;
    raise;
  end;
  Conexao.Free;
end;

function NFCeSomenteNumeros(const Valor: string): string;
var I: Integer;
begin
  Result := '';
  for I := 1 to Length(Valor) do
    if CharInSet(Valor[I], ['0'..'9']) then
      Result := Result + Valor[I];
end;

function NFCeDecodeHTML(const Valor: string): string;
begin
  Result := Valor;
  Result := StringReplace(Result, '&nbsp;', ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&#160;', ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&#39;', '''', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, #$C2#$A0, ' ', [rfReplaceAll]);
  Result := Trim(Result);
end;

function NFCeStripTags(const Valor: string): string;
begin
  Result := TRegEx.Replace(Valor, '<br\s*/?>', ' ', [roIgnoreCase]);
  Result := TRegEx.Replace(Result, '<[^>]+>', ' ', [roSingleLine]);
  Result := TRegEx.Replace(Result, '\s+', ' ', [roSingleLine]);
  Result := NFCeDecodeHTML(Result);
end;

function NFCeValorBR(const Valor: string): Double;
var Fmt: TFormatSettings;
begin
  Fmt := TFormatSettings.Create;
  Fmt.DecimalSeparator := ',';
  Fmt.ThousandSeparator := '.';
  Result := StrToFloatDef(Trim(Valor), 0, Fmt);
end;

function NFCeTextoMatch(const Texto, Padrao: string): string;
var Match: TMatch;
begin
  Result := '';
  Match := TRegEx.Match(Texto, Padrao, [roIgnoreCase, roSingleLine]);
  if Match.Success then
    Result := NFCeStripTags(Match.Groups[1].Value);
end;

function NFCeDataEmissaoSC(const Valor: string): TDateTime;
var Fmt: TFormatSettings;
begin
  Result := Now;
  Fmt := TFormatSettings.Create;
  Fmt.DateSeparator := '/';
  Fmt.TimeSeparator := ':';
  Fmt.ShortDateFormat := 'dd/mm/yyyy';
  Fmt.LongTimeFormat := 'hh:nn:ss';
  TryStrToDateTime(Trim(Valor), Result, Fmt);
end;
procedure NFCeSetJSONNumber(Obj: TJSONObject; const Nome: string; Valor: Double);
var
  Par: TJSONPair;
begin
  Par := Obj.RemovePair(Nome);
  if Assigned(Par) then
    Par.Free;
  Obj.AddPair(Nome, TJSONNumber.Create(Valor));
end;

function NFCeChaveAgrupamentoProduto(const Codigo, Nome, Unidade: string;
  ValorUnitario: Double): string;
var
  Fmt: TFormatSettings;
begin
  Fmt := TFormatSettings.Create;
  Fmt.DecimalSeparator := '.';
  Result := Trim(Codigo) + '|' + UpperCase(Trim(Nome)) + '|' +
    UpperCase(Trim(Unidade)) + '|' + FormatFloat('0.000000', ValorUnitario, Fmt);
end;

function BaixarHTMLNFCeSC(const URL: string): string;
var
  HTTP: THTTPClient;
  Response: IHTTPResponse;
begin
  if (Pos('sat.sef.sc.gov.br', LowerCase(URL)) = 0) or
     (Pos('nfce_detalhes.aspx', LowerCase(URL)) = 0) then
    raise Exception.Create('URL de NFC-e de Santa Catarina invalida.');

  HTTP := THTTPClient.Create;
  try
    HTTP.ConnectionTimeout := 15000;
    HTTP.ResponseTimeout := 30000;
    HTTP.UserAgent := 'Mozilla/5.0 GooPedir NFCe Parser';
    Response := HTTP.Get(URL);
    if Response.StatusCode <> 200 then
      raise Exception.Create('Falha ao consultar NFC-e SC. HTTP ' + Response.StatusCode.ToString);
    Result := Response.ContentAsString(TEncoding.UTF8);
  finally
    HTTP.Free;
  end;
end;

function ParseNFCeSantaCatarina(const URL, HTML: string): TJSONObject;
var
  Produtos, PayloadProdutos: TJSONArray;
  Produto, PayloadProduto, Empresa, Nota, Totais, Payload: TJSONObject;
  ProdutosAgrupados, PayloadProdutosAgrupados: TDictionary<string, TJSONObject>;
  Matches: TMatchCollection;
  Linha, InfoNota, Chave, Numero, Serie, EmissaoTexto, CNPJ, Nome, Codigo, ProdutoNome, Unidade, ChaveAgrupamento: string;
  I: Integer;
  ValorTotal, Desconto, ValorPagar, Qtd, Unitario, TotalItem, QtdAgrupada, TotalAgrupado: Double;
begin
  Result := TJSONObject.Create;
  Produtos := TJSONArray.Create;
  PayloadProdutos := TJSONArray.Create;
  Empresa := TJSONObject.Create;
  Nota := TJSONObject.Create;
  Totais := TJSONObject.Create;
  Payload := TJSONObject.Create;
  ProdutosAgrupados := TDictionary<string, TJSONObject>.Create;
  PayloadProdutosAgrupados := TDictionary<string, TJSONObject>.Create;
  try
    Nome := NFCeTextoMatch(HTML, '<div\s+id="u20"\s+class="txtTopo">(.*?)</div>');
    CNPJ := NFCeSomenteNumeros(NFCeTextoMatch(HTML, 'CNPJ:\s*(.*?)</div>'));
    Chave := NFCeSomenteNumeros(NFCeTextoMatch(HTML, '<span\s+class="chave">(.*?)</span>'));
    InfoNota := NFCeTextoMatch(HTML, '<strong>N.?mero:\s*</strong>(.*?)<br><br><strong>Protocolo');
    Numero := NFCeSomenteNumeros(NFCeTextoMatch(InfoNota, '^(.*?)S.?rie:'));
    Serie := NFCeSomenteNumeros(NFCeTextoMatch(InfoNota, 'S.?rie:\s*(.*?)Emiss'));
    EmissaoTexto := NFCeTextoMatch(InfoNota, 'Emiss.o:\s*([0-9/]+\s+[0-9:]+)');

    ValorTotal := NFCeValorBR(NFCeTextoMatch(HTML, 'Valor total R\$:\s*</label><span[^>]*>(.*?)</span>'));
    Desconto := NFCeValorBR(NFCeTextoMatch(HTML, 'Descontos R\$:\s*</label><span[^>]*>(.*?)</span>'));
    ValorPagar := NFCeValorBR(NFCeTextoMatch(HTML, 'Valor a pagar R\$:\s*</label><span[^>]*>(.*?)</span>'));

    Matches := TRegEx.Matches(HTML, '<tr\s+id="Item \+ [0-9]+">(.*?)</tr>', [roIgnoreCase, roSingleLine]);
    for I := 0 to Matches.Count - 1 do
    begin
      Linha := Matches.Item[I].Groups[1].Value;
      Codigo := NFCeSomenteNumeros(NFCeTextoMatch(Linha, '\(C.?digo:\s*(.*?)\)'));
      ProdutoNome := NFCeTextoMatch(Linha, '<span\s+class="txtTit">(.*?)</span>');
      Unidade := NFCeTextoMatch(Linha, 'UN:\s*</strong>(.*?)</span>');
      Qtd := NFCeValorBR(NFCeTextoMatch(Linha, 'Qtde\.:</strong>(.*?)</span>'));
      Unitario := NFCeValorBR(NFCeTextoMatch(Linha, 'Vl\. Unit\.:</strong>(.*?)</span>'));
      TotalItem := NFCeValorBR(NFCeTextoMatch(Linha, '<span\s+class="valor">(.*?)</span>'));

      ChaveAgrupamento := NFCeChaveAgrupamentoProduto(Codigo, ProdutoNome,
        Unidade, Unitario);

      if ProdutosAgrupados.TryGetValue(ChaveAgrupamento, Produto) then
      begin
        QtdAgrupada := Produto.GetValue<Double>('quantidade') + Qtd;
        TotalAgrupado := Produto.GetValue<Double>('valor_total') + TotalItem;
        NFCeSetJSONNumber(Produto, 'quantidade', QtdAgrupada);
        NFCeSetJSONNumber(Produto, 'valor_total', TotalAgrupado);

        PayloadProduto := PayloadProdutosAgrupados.Items[ChaveAgrupamento];
        NFCeSetJSONNumber(PayloadProduto, 'qCom', QtdAgrupada);
        NFCeSetJSONNumber(PayloadProduto, 'vProd', TotalAgrupado);
        NFCeSetJSONNumber(PayloadProduto, 'vTotal', TotalAgrupado);
      end
      else
      begin
        Produto := TJSONObject.Create;
        Produto.AddPair('codigo', Codigo);
        Produto.AddPair('nome', ProdutoNome);
        Produto.AddPair('unidade', Unidade);
        Produto.AddPair('quantidade', TJSONNumber.Create(Qtd));
        Produto.AddPair('valor_unitario', TJSONNumber.Create(Unitario));
        Produto.AddPair('valor_total', TJSONNumber.Create(TotalItem));
        Produtos.AddElement(Produto);
        ProdutosAgrupados.Add(ChaveAgrupamento, Produto);

        PayloadProduto := TJSONObject.Create;
        PayloadProduto.AddPair('cProd', Codigo);
        PayloadProduto.AddPair('xProd', ProdutoNome);
        PayloadProduto.AddPair('NCM', '');
        PayloadProduto.AddPair('CFOP', '');
        PayloadProduto.AddPair('qCom', TJSONNumber.Create(Qtd));
        PayloadProduto.AddPair('uCom', Unidade);
        PayloadProduto.AddPair('vUnCom', TJSONNumber.Create(Unitario));
        PayloadProduto.AddPair('vProd', TJSONNumber.Create(TotalItem));
        PayloadProduto.AddPair('vDesc', TJSONNumber.Create(0));
        PayloadProduto.AddPair('vFrete', TJSONNumber.Create(0));
        PayloadProduto.AddPair('vOutro', TJSONNumber.Create(0));
        PayloadProduto.AddPair('vTotal', TJSONNumber.Create(TotalItem));
        PayloadProduto.AddPair('uTrib', Unidade);
        PayloadProdutos.AddElement(PayloadProduto);
        PayloadProdutosAgrupados.Add(ChaveAgrupamento, PayloadProduto);
      end;
    end;

    Empresa.AddPair('nome', Nome);
    Empresa.AddPair('cnpj', CNPJ);
    Nota.AddPair('serie', Serie);
    Nota.AddPair('numero', Numero);
    Nota.AddPair('chave', Chave);
    Nota.AddPair('modelo', '65');
    Nota.AddPair('tipo', 'NFCe');
    Nota.AddPair('data_emissao', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', NFCeDataEmissaoSC(EmissaoTexto)));
    Nota.AddPair('data_entrada', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
    Nota.AddPair('vNF', TJSONNumber.Create(ValorPagar));
    Nota.AddPair('vFrete', TJSONNumber.Create(0));
    Nota.AddPair('vDesc', TJSONNumber.Create(Desconto));
    Nota.AddPair('vOutro', TJSONNumber.Create(0));
    Nota.AddPair('xml_original', HTML);
    Nota.AddPair('status_importacao', 'pendente');

    Totais.AddPair('valor_total_produtos', TJSONNumber.Create(ValorTotal));
    Totais.AddPair('desconto', TJSONNumber.Create(Desconto));
    Totais.AddPair('valor_total_nota', TJSONNumber.Create(ValorPagar));
    Totais.AddPair('quantidade_itens', TJSONNumber.Create(Produtos.Count));

    Payload.AddPair('empresa', TJSONObject.ParseJSONValue(Empresa.ToString) as TJSONObject);
    Payload.AddPair('nota', TJSONObject.ParseJSONValue(Nota.ToString) as TJSONObject);
    Payload.AddPair('produtos', TJSONObject.ParseJSONValue(PayloadProdutos.ToString) as TJSONArray);

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('uf', 'SC');
    Result.AddPair('tipo', 'NFCe');
    Result.AddPair('url', URL);
    Result.AddPair('empresa', Empresa);
    Result.AddPair('nota', Nota);
    Result.AddPair('totais', Totais);
    Result.AddPair('produtos', Produtos);
    Result.AddPair('payload_importacao', Payload);
    Empresa := nil; Nota := nil; Totais := nil; Produtos := nil; Payload := nil;
    PayloadProdutos.Free; PayloadProdutos := nil;
    ProdutosAgrupados.Free; PayloadProdutosAgrupados.Free;
  except
    Empresa.Free; Nota.Free; Totais.Free; Produtos.Free; PayloadProdutos.Free; Payload.Free;
    ProdutosAgrupados.Free; PayloadProdutosAgrupados.Free;
    raise;
  end;
end;

procedure DoPostConsultarNFCeSantaCatarina(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  JSONBody, Retorno, PayloadImportacao, Importacao: TJSONObject;
  URL, HTML: string;
begin
  JSONBody := nil;
  Retorno := nil;
  Importacao := nil;
  try
    JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    if not Assigned(JSONBody) then
      raise Exception.Create('Body JSON invalido.');

    URL := JSONStringValue(JSONBody, 'url');
    if URL = '' then
      URL := JSONStringValue(JSONBody, 'URL');
    if URL = '' then
      raise Exception.Create('Informe a URL da NFC-e no campo url.');

    HTML := BaixarHTMLNFCeSC(URL);
    Retorno := ParseNFCeSantaCatarina(URL, HTML);
    PayloadImportacao := Retorno.GetValue<TJSONObject>('payload_importacao');
    Importacao := ImportarPayloadNotaFiscalFornecedor(PayloadImportacao);
    Retorno.AddPair('importacao', Importacao);
    Importacao := nil;
    Res.Send<TJSONObject>(Retorno);
    Retorno := nil;
  except
    on E: Exception do
    begin
      Importacao.Free;
      Retorno.Free;
      Retorno := TJSONObject.Create;
      Retorno.AddPair('success', TJSONBool.Create(False));
      Retorno.AddPair('erro', E.Message);
      Res.Status(400).Send<TJSONObject>(Retorno);
      Retorno := nil;
    end;
  end;
  JSONBody.Free;
  Importacao.Free;
  Retorno.Free;
end;

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
    if SameText(Nota.Modelo, '65') then
      Nota.Tipo := 'NFCe'
    else if Nota.Tipo = '' then
      Nota.Tipo := 'NF';
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
        Conexao.SQL.Add('select UUID() as id, 0 as zero');
        CodigoNota := Conexao.FieldByName('id');
        if (CodigoNota = '') or (CodigoNota = '0') then
          raise Exception.Create('Nao foi possivel gerar o ID da nota fiscal.');

        Conexao.SQL.Add
          ('insert into nota_fiscal (id, fornecedor_id, serie, numero, chave, modelo, tipo, data_emissao, data_entrada, vNF, vFrete, vDesc, vOutro, xml_original, status_importacao, criado_em)');
        Conexao.SQL.Add
          ('values (:id, :fornecedor_id, :serie, :numero, :chave, :modelo, :tipo, :data_emissao, :data_entrada, :vNF, :vFrete, :vDesc, :vOutro, :xml_original, :status_importacao, NOW())');
        Conexao.Parametros('id', CodigoNota);
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

        RegistrarNotificacaoNotaFiscalBaixada(Conexao, CodigoNota,
          Empresa.Nome, Nota.Chave, Nota.vNF);
      end;

      // --- ITENS DA NOTA ---
      for I := 0 to Produtos.Count - 1 do
      begin
        // Verifica se j� existe o item do fornecedor
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
        Conexao.Parametros('qCom', FormatFloat('0.######',Produtos[I].qCom, Fmt));
        Conexao.Parametros('vUnCom', FormatFloat('0.######',Produtos[I].vUnCom, Fmt));
        Conexao.Parametros('vProd', FormatFloat('0.##',Produtos[I].vProd, Fmt));
        Conexao.Parametros('vDesc', FormatFloat('0.##',Produtos[I].vDesc, Fmt));
        Conexao.Parametros('vFrete', FormatFloat('0.##',Produtos[I].vFrete, Fmt));
        Conexao.Parametros('vOutro', FormatFloat('0.##',Produtos[I].vOutro, Fmt));
        Conexao.Parametros('uTrib', Produtos[I].uTrib);
        Conexao.ExecuteSQL;
      end;

      // --- RETORNO ORIGINAL ---
      Conexao.SQL.Add('select fi.*, ');
      Conexao.SQL.Add
        ('CASE WHEN fi.tabela_vinculo = "produto" THEN upper(p.nome_produto) ELSE upper(i.descricao) END AS insumo_nome,');
      Conexao.SQL.Add
        ('CASE WHEN fi.tabela_vinculo = "produto" THEN upper(p.un) ELSE upper(i.unidade) END AS insumo_unidade ');
      Conexao.SQL.Add('from fornecedor_item  as fi ');
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
  Conexao.SQL.Add('select id, 0 as zero from despesas');
  Conexao.SQL.Add
    ('where replace(replace(replace(replace(coalesce(chave_nota, ""), " ", ""), ".", ""), "-", ""), "/", "") = replace(replace(replace(replace(:chave, " ", ""), ".", ""), "-", ""), "/", "")');
  Conexao.SQL.Add('and coalesce(excluida, 0) = 0 limit 1');
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

procedure DoGetFornecedores(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
begin
  Conexao := TConexao.Create('DoGetFornecedores');
  try
    Conexao.SQL.Add('select f.id, upper(f.nome) as nome, f.cnpj, f.telefone, f.email,');
    Conexao.SQL.Add('coalesce(prod.quantidade_produtos, 0) as quantidade_produtos,');
    Conexao.SQL.Add('coalesce(notas.total_notas, 0) as total_notas,');
    Conexao.SQL.Add('coalesce(notas.valor_total_notas, 0) as valor_total_notas,');
    Conexao.SQL.Add('coalesce(notas.total_desconto, 0) as total_desconto,');
    Conexao.SQL.Add('coalesce(notas.total_frete, 0) as total_frete');
    Conexao.SQL.Add('from fornecedor f');
    Conexao.SQL.Add('left join (select fornecedor_id, count(distinct id) as quantidade_produtos from fornecedor_item group by fornecedor_id) prod on prod.fornecedor_id = f.id');
    Conexao.SQL.Add('left join (select fornecedor_id, count(id) as total_notas, sum(vNF) as valor_total_notas, sum(vDesc) as total_desconto, sum(vFrete) as total_frete from nota_fiscal group by fornecedor_id) notas on notas.fornecedor_id = f.id');
    Conexao.SQL.Add('order by nome');
    Res.Send<TJSONArray>(Conexao.ConsultaSQL);
  finally
    Conexao.Free;
  end;
end;

procedure DoPostFornecedor(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSONBody: TJSONObject;
  CodigoFornecedor: string;
begin
  Conexao := TConexao.Create('DoPostFornecedor');
  JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  try
    CodigoFornecedor := Req.Params['id'];
    if CodigoFornecedor = '' then
      CodigoFornecedor := JSONStringValue(JSONBody, 'id');

    if CodigoFornecedor = '' then
    begin
      Res.Status(400).Send('Fornecedor nao informado');
      Exit;
    end;

    Conexao.SQL.Add('update fornecedor set nome = :nome, cnpj = :cnpj, telefone = :telefone, email = :email');
    Conexao.SQL.Add('where id = :id');
    Conexao.Parametros('nome', JSONStringValue(JSONBody, 'nome'));
    Conexao.Parametros('cnpj', JSONStringValue(JSONBody, 'cnpj'));
    Conexao.Parametros('telefone', JSONStringValue(JSONBody, 'telefone'));
    Conexao.Parametros('email', JSONStringValue(JSONBody, 'email'));
    Conexao.Parametros('id', CodigoFornecedor);
    Conexao.ExecuteSQL;

    Res.Send<TJSONObject>(TJSONObject.Create
      .AddPair('success', TJSONBool.Create(True))
      .AddPair('id', CodigoFornecedor));
  finally
    if Assigned(JSONBody) then
      JSONBody.Free;
    Conexao.Free;
  end;
end;

procedure DoGetFornecedorDossie(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  Resultado: TJSONObject;
  CodigoFornecedor, DataInicio, DataFim, DataInicioSQL, DataFimSQL: string;
begin
  Conexao := TConexao.Create('DoGetFornecedorDossie');
  Resultado := TJSONObject.Create;
  try
    CodigoFornecedor := BuscarFornecedorPorParametro(Conexao, Req.Params['fornecedor']);
    DataInicio := Req.Params['data_inicio'];
    DataFim := Req.Params['data_fim'];
    DataInicioSQL := NormalizarDataSQL(DataInicio);
    DataFimSQL := NormalizarDataSQL(DataFim);

    if CodigoFornecedor = '' then
    begin
      Resultado.AddPair('success', TJSONBool.Create(False));
      Resultado.AddPair('message', 'Fornecedor nao encontrado');
      Res.Status(404).Send<TJSONObject>(Resultado);
      Exit;
    end;

    Resultado.AddPair('success', TJSONBool.Create(True));
    Resultado.AddPair('fornecedor_id', CodigoFornecedor);
    Resultado.AddPair('data_inicio', DataInicio);
    Resultado.AddPair('data_fim', DataFim);
    Resultado.AddPair('dossie_versao', TJSONNumber.Create(2));

    Conexao.SQL.Add('select id, upper(nome) as nome, cnpj, telefone, email');
    Conexao.SQL.Add('from fornecedor');
    Conexao.SQL.Add('where id = :fornecedor');
    Conexao.Parametros('fornecedor', CodigoFornecedor);
    Resultado.AddPair('fornecedor', Conexao.ConsultaSQL);

    Conexao.SQL.Add('select count(nf.id) as total_notas,');
    Conexao.SQL.Add('coalesce(sum(itens.total_itens), 0) as total_itens,');
    Conexao.SQL.Add('coalesce(sum(itens.quantidade_total), 0) as quantidade_total,');
    Conexao.SQL.Add('coalesce(sum(nf.vDesc), 0) as total_desconto,');
    Conexao.SQL.Add('coalesce(sum(nf.vFrete), 0) as total_frete,');
    Conexao.SQL.Add('coalesce(sum(nf.vNF), 0) as total_comprado');
    Conexao.SQL.Add('from nota_fiscal nf');
    Conexao.SQL.Add('left join (select nota_fiscal_id, count(id) as total_itens, sum(qCom) as quantidade_total from nota_fiscal_item group by nota_fiscal_id) itens on itens.nota_fiscal_id = nf.id');
    Conexao.SQL.Add('where nf.fornecedor_id = :fornecedor');
    Conexao.SQL.Add('and date(nf.data_emissao) between :inicio and :fim');
    Conexao.Parametros('fornecedor', CodigoFornecedor);
    Conexao.Parametros('inicio', DataInicioSQL);
    Conexao.Parametros('fim', DataFimSQL);
    Resultado.AddPair('resumo', Conexao.ConsultaSQL);

    Conexao.SQL.Add('select fi.id as fornecedor_item_id,');
    Conexao.SQL.Add('fi.cprod, upper(fi.xProd) as produto_fornecedor, fi.uCom as unidade_fornecedor,');
    Conexao.SQL.Add('fi.tabela_vinculo, fi.codigo_vinculo, fi.fator,');
    Conexao.SQL.Add('case when fi.tabela_vinculo = "produto" then upper(p.nome_produto) when fi.tabela_vinculo = "ingrediente" then upper(i.descricao) else null end as vinculo_nome,');
    Conexao.SQL.Add('case when fi.tabela_vinculo = "produto" then p.saldo_atual when fi.tabela_vinculo = "ingrediente" then i.saldo else null end as saldo_atual,');
    Conexao.SQL.Add('case when count(nfi.id) > 0 then 1 else 0 end as comprado_periodo,');
    Conexao.SQL.Add('count(distinct nf.id) as notas_periodo,');
    Conexao.SQL.Add('count(nfi.id) as compras_periodo,');
    Conexao.SQL.Add('coalesce(sum(case when nf.id is not null then nfi.qCom else 0 end), 0) as quantidade_periodo,');
    Conexao.SQL.Add('coalesce(sum(case when nf.id is not null then nfi.vDesc else 0 end), 0) as desconto_periodo,');
    Conexao.SQL.Add('coalesce(sum(case when nf.id is not null then nfi.vFrete else 0 end), 0) as frete_periodo,');
    Conexao.SQL.Add('coalesce(sum(case when nf.id is not null then coalesce(nfi.vTotal, coalesce(nfi.vProd, 0) + coalesce(nfi.vFrete, 0) + coalesce(nfi.vOutro, 0) - coalesce(nfi.vDesc, 0)) else 0 end), 0) as total_periodo,');
    Conexao.SQL.Add('min(case when nf.id is not null then nfi.vUnCom end) as menor_valor_periodo,');
    Conexao.SQL.Add('max(case when nf.id is not null then nfi.vUnCom end) as maior_valor_periodo,');
    Conexao.SQL.Add('avg(case when nf.id is not null then nfi.vUnCom end) as media_valor_periodo,');
    Conexao.SQL.Add('(select count(*) from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id) as compras_historico,');
    Conexao.SQL.Add('(select min(nfi2.vUnCom) from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id) as menor_valor_historico,');
    Conexao.SQL.Add('(select max(nfi2.vUnCom) from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id) as maior_valor_historico,');
    Conexao.SQL.Add('(select avg(nfi2.vUnCom) from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id) as media_valor_historico,');
    Conexao.SQL.Add('(select avg(nfi2.vUnCom) from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id and date(nf2.data_emissao) < :inicio) as media_valor_anterior,');
    Conexao.SQL.Add('(select nfi2.vUnCom from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao asc limit 1) as primeiro_valor,');
    Conexao.SQL.Add('(select nf2.data_emissao from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao asc limit 1) as primeira_compra,');
    Conexao.SQL.Add('(select nfi2.vUnCom from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao desc limit 1) as ultimo_valor,');
    Conexao.SQL.Add('(select nf2.data_emissao from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao desc limit 1) as ultima_compra,');
    Conexao.SQL.Add('case when (select nfi2.vUnCom from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao asc limit 1) > 0 then');
    Conexao.SQL.Add('(((select nfi2.vUnCom from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao desc limit 1) -');
    Conexao.SQL.Add('(select nfi2.vUnCom from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao asc limit 1)) /');
    Conexao.SQL.Add('(select nfi2.vUnCom from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id order by nf2.data_emissao asc limit 1)) * 100 else null end as variacao_ultimo_vs_primeiro_percentual,');
    Conexao.SQL.Add('case when (select avg(nfi2.vUnCom) from nota_fiscal_item nfi2 join nota_fiscal nf2 on ');
    Conexao.SQL.Add('nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id and date(nf2.data_emissao) < :inicio) > 0 and avg(case when nf.id is not null then nfi.vUnCom end) is not null then');
    Conexao.SQL.Add('((avg(case when nf.id is not null then nfi.vUnCom end) - (select avg(nfi2.vUnCom) from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id and date(nf2.data_emissao) < :inicio)) /');
    Conexao.SQL.Add('(select avg(nfi2.vUnCom) from nota_fiscal_item nfi2 join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id where nfi2.fornecedor_item_id = fi.id and date(nf2.data_emissao) < :inicio)) * 100 else null end as variacao_periodo_vs_anterior_percentual,');
    Conexao.SQL.Add('coalesce((select concat(''['', group_concat(json_object(');
    Conexao.SQL.Add('''nota_fiscal_id'', nf2.id, ''chave'', nf2.chave,');
    Conexao.SQL.Add('''serie'', nf2.serie, ''numero'', nf2.numero,');
    Conexao.SQL.Add('''data_emissao'', date_format(nf2.data_emissao, ''%Y-%m-%d''),');
    Conexao.SQL.Add('''quantidade'', nfi2.qCom, ''unidade'', nfi2.uCom,');
    Conexao.SQL.Add('''valor_unitario'', nfi2.vUnCom, ''valor_produto'', nfi2.vProd,');
    Conexao.SQL.Add('''desconto'', nfi2.vDesc, ''frete'', nfi2.vFrete, ''outros'', nfi2.vOutro,');
    Conexao.SQL.Add('''total_item'', coalesce(nfi2.vTotal, coalesce(nfi2.vProd, 0) +');
    Conexao.SQL.Add('coalesce(nfi2.vFrete, 0) + coalesce(nfi2.vOutro, 0) - coalesce(nfi2.vDesc, 0)))');
    Conexao.SQL.Add('order by nf2.data_emissao asc separator '',''), '']'')');
    Conexao.SQL.Add('from nota_fiscal_item nfi2');
    Conexao.SQL.Add('join nota_fiscal nf2 on nf2.id = nfi2.nota_fiscal_id');
    Conexao.SQL.Add('where nfi2.fornecedor_item_id = fi.id), ''[]'') as historico_precos');
    Conexao.SQL.Add('from fornecedor_item fi');
    Conexao.SQL.Add('left join nota_fiscal_item nfi on nfi.fornecedor_item_id = fi.id');
    Conexao.SQL.Add('left join nota_fiscal nf on nf.id = nfi.nota_fiscal_id and date(nf.data_emissao) between :inicio and :fim');
    Conexao.SQL.Add('left join produto p on p.codigo = fi.codigo_vinculo');
    Conexao.SQL.Add('left join ingredientes i on i.id = fi.codigo_vinculo');
    Conexao.SQL.Add('where fi.fornecedor_id = :fornecedor');
    Conexao.SQL.Add('group by fi.id, fi.cprod, fi.xProd, fi.uCom, fi.tabela_vinculo, fi.codigo_vinculo, fi.fator, p.nome_produto, p.saldo_atual, i.descricao, i.saldo');
    Conexao.SQL.Add('order by quantidade_periodo desc, produto_fornecedor');
    Conexao.Parametros('inicio', DataInicioSQL);
    Conexao.Parametros('fim', DataFimSQL);
    Conexao.Parametros('fornecedor', CodigoFornecedor);
    Resultado.AddPair('itens', Conexao.ConsultaSQL);
    Conexao.SQL.Add('select fi.id as fornecedor_item_id, fi.cprod, upper(fi.xProd) as produto_fornecedor,');
    Conexao.SQL.Add('nf.id as nota_fiscal_id, nf.chave, nf.serie, nf.numero, nf.data_emissao,');
    Conexao.SQL.Add('nfi.qCom as quantidade, nfi.uCom as unidade, nfi.vUnCom as valor_unitario,');
    Conexao.SQL.Add('nfi.vProd as valor_produto, nfi.vDesc as desconto, nfi.vFrete as frete, nfi.vOutro as outros,');
    Conexao.SQL.Add('coalesce(nfi.vTotal, coalesce(nfi.vProd, 0) + coalesce(nfi.vFrete, 0) + coalesce(nfi.vOutro, 0) - coalesce(nfi.vDesc, 0)) as total_item,');
    Conexao.SQL.Add('case when date(nf.data_emissao) between :inicio and :fim then 1 else 0 end as no_periodo');
    Conexao.SQL.Add('from fornecedor_item fi');
    Conexao.SQL.Add('join nota_fiscal_item nfi on nfi.fornecedor_item_id = fi.id');
    Conexao.SQL.Add('join nota_fiscal nf on nf.id = nfi.nota_fiscal_id');
    Conexao.SQL.Add('where fi.fornecedor_id = :fornecedor');
    Conexao.SQL.Add('order by produto_fornecedor, nf.data_emissao');
    Conexao.Parametros('inicio', DataInicioSQL);
    Conexao.Parametros('fim', DataFimSQL);
    Conexao.Parametros('fornecedor', CodigoFornecedor);
    Resultado.AddPair('historico_precos', Conexao.ConsultaSQL);
    Res.Send<TJSONObject>(Resultado);
  finally
    Conexao.Free;
  end;
end;
procedure DoPostNotaFiscalEntradaEstoque(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSONBody: TJSONObject;
  DadosItens: TFDMemTable;
  Retorno, ItemRetorno: TJSONObject;
  Itens: TJSONArray;
  NotaID, Chave, ItemID, TipoVinculo, CodigoVinculo, Mensagem, Token: string;
  Quantidade, Fator, QuantidadeEntrada, CustoTotal, Custo: Double;
  Processados, Ignorados, Erros: Integer;
begin
  Conexao := TConexao.Create('DoPostNotaFiscalEntradaEstoque');
  DadosItens := TFDMemTable.Create(nil);
  JSONBody := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Retorno := TJSONObject.Create;
  Itens := TJSONArray.Create;
  Processados := 0;
  Ignorados := 0;
  Erros := 0;
  try
    GarantirCamposEntradaEstoqueNotaFiscal(Conexao);

    NotaID := JSONParamValue(Req, 'id');
    Chave := JSONParamValue(Req, 'chave');
    if NotaID = '' then
      NotaID := JSONQueryValue(Req, 'id');
    if Chave = '' then
      Chave := JSONQueryValue(Req, 'chave');
    if Assigned(JSONBody) then
    begin
      if NotaID = '' then
        NotaID := JSONStringValue(JSONBody, 'id');
      if Chave = '' then
        Chave := JSONStringValue(JSONBody, 'chave');
      if NotaID = '' then
        NotaID := JSONStringValue(JSONBody, 'nota_fiscal_id');
    end;

    if (NotaID = '') and (Chave = '') then
    begin
      Retorno.AddPair('success', TJSONBool.Create(False));
      Retorno.AddPair('message', 'Informe id ou chave da nota fiscal.');
      Retorno.AddPair('itens', Itens);
      Itens := nil;
      Res.Status(400).Send<TJSONObject>(Retorno);
      Exit;
    end;

    Conexao.SQL.Add('select nfi.id, nfi.qCom, nfi.vTotal, nfi.vProd, nfi.vUnCom,');
    Conexao.SQL.Add('coalesce(nfi.entrada_estoque, 0) as entrada_estoque,');
    Conexao.SQL.Add('fi.tabela_vinculo, fi.codigo_vinculo, coalesce(fi.fator, 1) as fator,');
    Conexao.SQL.Add('nfi.xProd, nf.id as nota_id, nf.chave');
    Conexao.SQL.Add('from nota_fiscal_item nfi');
    Conexao.SQL.Add('join nota_fiscal nf on nf.id = nfi.nota_fiscal_id');
    Conexao.SQL.Add('left join fornecedor_item fi on fi.id = nfi.fornecedor_item_id');
    Conexao.SQL.Add('where 1=1');
    if NotaID <> '' then
    begin
      Conexao.SQL.Add('and nf.id = :nota_id');
      Conexao.Parametros('nota_id', NotaID);
    end;
    if Chave <> '' then
    begin
      Conexao.SQL.Add('and nf.chave = :chave');
      Conexao.Parametros('chave', Chave);
    end;
    DadosItens.LoadFromJSON(Conexao.ConsultaSQL);

    while not DadosItens.Eof do
    begin
      ItemID := DadosItens.FieldByName('id').AsString;
      TipoVinculo := DadosItens.FieldByName('tabela_vinculo').AsString;
      CodigoVinculo := DadosItens.FieldByName('codigo_vinculo').AsString;
      Mensagem := '';

      ItemRetorno := TJSONObject.Create;
      ItemRetorno.AddPair('id', ItemID);
      ItemRetorno.AddPair('xProd', DadosItens.FieldByName('xProd').AsString);
      ItemRetorno.AddPair('tabela_vinculo', TipoVinculo);
      ItemRetorno.AddPair('codigo_vinculo', CodigoVinculo);

      if DadosItens.FieldByName('entrada_estoque').AsInteger = 1 then
      begin
        Inc(Ignorados);
        ItemRetorno.AddPair('status', 'ignorado');
        ItemRetorno.AddPair('message', 'Item ja teve entrada no estoque.');
        Itens.AddElement(ItemRetorno);
        DadosItens.Next;
        Continue;
      end;

      if (CodigoVinculo = '') or ((TipoVinculo <> 'produto') and
        (TipoVinculo <> 'ingrediente')) then
      begin
        Inc(Erros);
        ItemRetorno.AddPair('status', 'erro');
        ItemRetorno.AddPair('message', 'Item sem vinculo com produto ou ingrediente.');
        Itens.AddElement(ItemRetorno);
        DadosItens.Next;
        Continue;
      end;

      Quantidade := DadosItens.FieldByName('qCom').AsFloat;
      Fator := DadosItens.FieldByName('fator').AsFloat;
      if Fator <= 0 then
        Fator := 1;
      QuantidadeEntrada := Quantidade * Fator;
      CustoTotal := DadosItens.FieldByName('vTotal').AsFloat;
      if QuantidadeEntrada > 0 then
        Custo := CustoTotal / QuantidadeEntrada
      else
        Custo := 0;

      try
        Token := 'PROC-' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '-' +
          IntToStr(Random(999999));
        Conexao.SQL.Add('update nota_fiscal_item set entrada_estoque = 2, entrada_estoque_msg = :token where id = :id and coalesce(entrada_estoque, 0) = 0');
        Conexao.Parametros('token', Token);
        Conexao.Parametros('id', ItemID);
        Conexao.ExecuteSQL;
        Conexao.SQL.Add('select 0 as zero, entrada_estoque_msg from nota_fiscal_item where id = :id');
        Conexao.Parametros('id', ItemID);
        if Conexao.FieldByName('entrada_estoque_msg') <> Token then
        begin
          Inc(Ignorados);
          ItemRetorno.AddPair('status', 'ignorado');
          ItemRetorno.AddPair('message', 'Item em processamento ou ja processado.');
          Itens.AddElement(ItemRetorno);
          DadosItens.Next;
          Continue;
        end;
        if TipoVinculo = 'produto' then
          EntradaEstoqueProdutoNota(Conexao, ItemID, StrToIntDef(CodigoVinculo, 0),
            QuantidadeEntrada)
        else
          EntradaEstoqueIngredienteNota(Conexao, ItemID,
            StrToIntDef(CodigoVinculo, 0), QuantidadeEntrada, CustoTotal, Custo);
        Conexao.SQL.Add('update nota_fiscal_item set entrada_estoque = 1, entrada_estoque_em = current_timestamp, entrada_estoque_msg = null where id = :id');
        Conexao.Parametros('id', ItemID);
        Conexao.ExecuteSQL;
        Inc(Processados);
        ItemRetorno.AddPair('status', 'processado');
        ItemRetorno.AddPair('quantidade_entrada', TJSONNumber.Create(QuantidadeEntrada));
        ItemRetorno.AddPair('custo_total', TJSONNumber.Create(CustoTotal));
        ItemRetorno.AddPair('custo', TJSONNumber.Create(Custo));
      except
        on E: Exception do
        begin
          Inc(Erros);
          Mensagem := Copy(E.Message, 1, 255);
          Conexao.SQL.Add('update nota_fiscal_item set entrada_estoque = 0, entrada_estoque_msg = :msg where id = :id');
          Conexao.Parametros('msg', Mensagem);
          Conexao.Parametros('id', ItemID);
          Conexao.ExecuteSQL;
          ItemRetorno.AddPair('status', 'erro');
          ItemRetorno.AddPair('message', Mensagem);
        end;
      end;

      Itens.AddElement(ItemRetorno);
      DadosItens.Next;
    end;

    if Processados > 0 then
    begin
      Conexao.SQL.Add('update nota_fiscal set status_importacao = ''processada'' where (id = :nota_id or chave = :chave) and not exists (select 1 from nota_fiscal_item where nota_fiscal_id = nota_fiscal.id and coalesce(entrada_estoque, 0) = 0)');
      Conexao.Parametros('nota_id', NotaID);
      Conexao.Parametros('chave', Chave);
      Conexao.ExecuteSQL;
    end;

    Retorno.AddPair('success', TJSONBool.Create(Erros = 0));
    Retorno.AddPair('processados', TJSONNumber.Create(Processados));
    Retorno.AddPair('ignorados', TJSONNumber.Create(Ignorados));
    Retorno.AddPair('erros', TJSONNumber.Create(Erros));
    Retorno.AddPair('itens', Itens);
    Itens := nil;
    Res.Send<TJSONObject>(Retorno);
  finally
    if Assigned(JSONBody) then
      JSONBody.Free;
    Itens.Free;
    DadosItens.Free;
    Conexao.Free;
  end;
end;
end.
