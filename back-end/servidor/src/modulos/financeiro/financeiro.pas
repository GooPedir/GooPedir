unit financeiro;

interface

uses
  Horse, System.JSON;

procedure Registry;
procedure ImportarBancosBrasilAPI;
function AtualizarBancosBrasilAPI: TJSONObject;

implementation

uses
  conexao, DataSet.Serialize, System.SysUtils, System.Net.HttpClient,
  System.Net.HttpClientComponent, DateUtils, System.RegularExpressions,
  FireDAC.Comp.Client;

const
  URL_BRASIL_API_BANCOS = 'https://brasilapi.com.br/api/banks/v1';

function JsonString(Objeto: TJSONObject; const Campo, Padrao: string): string;
var
  Valor: TJSONValue;
begin
  Result := Padrao;
  Valor := Objeto.GetValue(Campo);
  if Assigned(Valor) and not(Valor is TJSONNull) then
    Result := Valor.Value;
end;

function ParamRota(Req: THorseRequest; const Nome: string): string;
begin
  Result := '';
  try
    Result := Req.Params[Nome];
  except
    Result := '';
  end;
end;

function JsonInteger(Objeto: TJSONObject; const Campo: string;
  out ValorInteiro: Integer): Boolean;
var
  Valor: TJSONValue;
begin
  Result := False;
  ValorInteiro := 0;
  Valor := Objeto.GetValue(Campo);
  if Assigned(Valor) and not(Valor is TJSONNull) then
    Result := TryStrToInt(Valor.Value, ValorInteiro);
end;

function JsonIntegerPadrao(Objeto: TJSONObject; const Campo: string;
  Padrao: Integer): Integer;
begin
  Result := Padrao;
  JsonInteger(Objeto, Campo, Result);
end;

function JsonFloatPadrao(Objeto: TJSONObject; const Campo: string;
  Padrao: Double): Double;
var
  Valor: TJSONValue;
  FormatSettings: TFormatSettings;
begin
  Result := Padrao;
  Valor := Objeto.GetValue(Campo);
  if not Assigned(Valor) or (Valor is TJSONNull) then
    exit;
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';
  TryStrToFloat(Valor.Value, Result, FormatSettings);
end;

function FloatSQL(Valor: Double): string;
var
  FormatSettings: TFormatSettings;
begin
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';
  Result := FloatToStr(Valor, FormatSettings);
end;

function DataISOFinanceiro(const Valor: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(Valor, 1, 4)),
    StrToInt(Copy(Valor, 6, 2)), StrToInt(Copy(Valor, 9, 2)));
end;

function DataComDiaValido(Ano, Mes, Dia: Word): TDate;
var
  UltimoDia: Word;
begin
  UltimoDia := DaysInAMonth(Ano, Mes);
  if Dia < 1 then
    Dia := 1
  else if Dia > UltimoDia then
    Dia := UltimoDia;
  Result := EncodeDate(Ano, Mes, Dia);
end;

function CalcularVencimentoFatura(Conexao: TConexao; CartaoID: Integer;
  DataCompra: TDate): TDate;
var
  Qry: TFDQuery;
  MelhorDia: Word;
  DiaVencimento: Word;
  Ano: Word;
  Mes: Word;
  Dia: Word;
  DataFatura: TDate;
begin
  MelhorDia := 1;
  DiaVencimento := 1;
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('select melhor_dia, dia_vencimento');
    Qry.SQL.Add('from cartoes where id = :id limit 1');
    Qry.ParamByName('id').AsInteger := CartaoID;
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.Create('cartao nao encontrado');
    MelhorDia := Qry.FieldByName('melhor_dia').AsInteger;
    DiaVencimento := Qry.FieldByName('dia_vencimento').AsInteger;
  finally
    Qry.Free;
  end;

  DataFatura := DataCompra;
  if DayOf(DataCompra) >= MelhorDia then
    DataFatura := IncMonth(DataFatura, 1);

  DecodeDate(DataFatura, Ano, Mes, Dia);
  Result := DataComDiaValido(Ano, Mes, DiaVencimento);
end;

procedure GarantirCamposFatura(Conexao: TConexao);
var
  Qry: TFDQuery;
begin
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('show columns from despesas like "data_compra"');
    Qry.Open;
    if Qry.IsEmpty then
    begin
      if not Conexao.ExecuteSQL
        ('ALTER TABLE despesas ADD COLUMN data_compra DATE DEFAULT NULL') then
        raise Exception.Create('erro ao criar campo data_compra');
      Conexao.ExecuteSQL
        ('CREATE INDEX idx_despesas_data_compra ON despesas (data_compra)');
    end;
  finally
    Qry.Free;
  end;
end;

function ExtrairParcelaFatura(const Texto: string; out ParcelaAtual,
  TotalParcelas: Integer): Boolean;
var
  Match: TMatch;
begin
  ParcelaAtual := 1;
  TotalParcelas := 1;
  Match := TRegEx.Match(Texto, '(\d+)\s*/\s*(\d+)');
  Result := Match.Success;
  if Result then
  begin
    ParcelaAtual := StrToIntDef(Match.Groups[1].Value, 1);
    TotalParcelas := StrToIntDef(Match.Groups[2].Value, 1);
    if ParcelaAtual < 1 then
      ParcelaAtual := 1;
    if TotalParcelas < ParcelaAtual then
      TotalParcelas := ParcelaAtual;
  end;
end;


function NormalizarTextoFatura(const Texto: string): string;
begin
  Result := LowerCase(Trim(Texto));
  Result := TRegEx.Replace(Result, '\s+', ' ');
end;

function DescricaoSemParcelaFatura(const Texto: string): string;
begin
  Result := Trim(TRegEx.Replace(Texto,
    '\s*-\s*parcela\s+\d+\s*/\s*\d+\s*$', '',
    [roIgnoreCase]));
  Result := TRegEx.Replace(Result, '\s+', ' ');
end;

function DespesaFaturaJaExiste(Conexao: TConexao; const Descricao: string;
  Valor: Double; Parcela, Parcelas: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('select id');
    Qry.SQL.Add('from despesas');
    Qry.SQL.Add('where upper(trim(descricao)) = upper(trim(:descricao))');
    Qry.SQL.Add('and parcela = :parcela');
    Qry.SQL.Add('and parcelas = :parcelas');
    Qry.SQL.Add('and abs(valor - :valor) < 0.01');
    Qry.SQL.Add('and coalesce(excluida, 0) = 0');
    Qry.SQL.Add('limit 1');
    Qry.ParamByName('descricao').AsString := Descricao;
    Qry.ParamByName('parcela').AsInteger := Parcela;
    Qry.ParamByName('parcelas').AsInteger := Parcelas;
    Qry.ParamByName('valor').AsFloat := Valor;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

procedure SomarLimiteUsadoCartao(Conexao: TConexao; CartaoID: Integer;
  Valor: Double);
begin
  if (CartaoID <= 0) or (Valor <= 0) then
    exit;
  Conexao.SQL.Clear;
  Conexao.SQL.Add('update cartoes set limite_usado = coalesce(limite_usado, 0) + :valor,');
  Conexao.SQL.Add('atualizado_em = now() where id = :cartao_id');
  Conexao.Parametros('valor', FloatSQL(Valor));
  Conexao.Parametros('cartao_id', CartaoID);
  Conexao.ExecuteSQL;
  Conexao.SQL.Clear;
end;

procedure SalvarBancoBrasilAPI(Conexao: TConexao; Banco: TJSONObject);
var
  Codigo: Integer;
begin
  if not JsonInteger(Banco, 'code', Codigo) then
    exit;

  Conexao.SQL.Clear;
  Conexao.SQL.Add('insert into bancos');
  Conexao.SQL.Add('(codigo, ispb, nome, nome_completo, ativo, atualizado_em)');
  Conexao.SQL.Add('values');
  Conexao.SQL.Add('(:codigo, :ispb, :nome, :nome_completo, 1, now())');
  Conexao.SQL.Add('on duplicate key update');
  Conexao.SQL.Add('ispb = values(ispb),');
  Conexao.SQL.Add('nome = values(nome),');
  Conexao.SQL.Add('nome_completo = values(nome_completo),');
  Conexao.SQL.Add('ativo = 1,');
  Conexao.SQL.Add('atualizado_em = now()');
  Conexao.Parametros('codigo', Codigo);
  Conexao.Parametros('ispb', JsonString(Banco, 'ispb', ''));
  Conexao.Parametros('nome', JsonString(Banco, 'name', ''));
  Conexao.Parametros('nome_completo', JsonString(Banco, 'fullName', ''));
  Conexao.ExecuteSQL;
  Conexao.SQL.Clear;
end;

function AtualizarBancosBrasilAPI: TJSONObject;
var
  HTTP: TNetHTTPClient;
  Resposta: IHTTPResponse;
  JSON: TJSONValue;
  Lista: TJSONArray;
  Banco: TJSONObject;
  Conexao: TConexao;
  I: Integer;
  Importados: Integer;
  Ignorados: Integer;
  Codigo: Integer;
begin
  Result := TJSONObject.Create;
  HTTP := TNetHTTPClient.Create(nil);
  Conexao := TConexao.Create('AtualizarBancosBrasilAPI');
  try
    HTTP.ConnectionTimeout := 15000;
    HTTP.ResponseTimeout := 30000;
    Resposta := HTTP.Get(URL_BRASIL_API_BANCOS);
    JSON := TJSONObject.ParseJSONValue(Resposta.ContentAsString(TEncoding.UTF8));
    if not Assigned(JSON) or not(JSON is TJSONArray) then
      raise Exception.Create('Retorno invalido da BrasilAPI.');

    Lista := JSON as TJSONArray;
    Importados := 0;
    Ignorados := 0;
    try
      for I := 0 to Lista.Count - 1 do
      begin
        if not(Lista.Items[I] is TJSONObject) then
        begin
          Inc(Ignorados);
          Continue;
        end;

        Banco := Lista.Items[I] as TJSONObject;
        if JsonInteger(Banco, 'code', Codigo) then
        begin
          SalvarBancoBrasilAPI(Conexao, Banco);
          Inc(Importados);
        end
        else
          Inc(Ignorados);
      end;
    finally
      JSON.Free;
    end;

    Result.AddPair('status', 'ok');
    Result.AddPair('importados', TJSONNumber.Create(Importados));
    Result.AddPair('ignorados', TJSONNumber.Create(Ignorados));
  finally
    Conexao.Free;
    HTTP.Free;
  end;
end;

procedure ImportarBancosBrasilAPI;
var
  Retorno: TJSONObject;
begin
  Retorno := AtualizarBancosBrasilAPI;
  Retorno.Free;
end;

procedure DoGetBancos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
begin
  Conexao := TConexao.Create('DoGetBancos');
  try
    Conexao.SQL.Add('select id, codigo, ispb, nome, nome_completo, ativo,');
    Conexao.SQL.Add('criado_em, atualizado_em from bancos');
    Conexao.SQL.Add('where ativo = 1');
    Conexao.SQL.Add('order by codigo');
    Res.Send<TJSONArray>(Conexao.ConsultaSQL);
  finally
    Conexao.Free;
  end;
end;

procedure DoGetBanco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
begin
  Conexao := TConexao.Create('DoGetBanco');
  try
    Conexao.SQL.Add('select id, codigo, ispb, nome, nome_completo, ativo,');
    Conexao.SQL.Add('criado_em, atualizado_em from bancos');
    Conexao.SQL.Add('where codigo = :codigo');
    Conexao.Parametros('codigo', Req.Params['codigo']);
    Res.Send<TJSONArray>(Conexao.ConsultaSQL);
  finally
    Conexao.Free;
  end;
end;

procedure DoPostBanco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSON: TJSONObject;
  Codigo: Integer;
begin
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Conexao := TConexao.Create('DoPostBanco');
  try
    if not JsonInteger(JSON, 'codigo', Codigo) then
    begin
      Res.Status(400);
      Res.Send('codigo obrigatorio');
      exit;
    end;
    Conexao.SQL.Add('insert into bancos');
    Conexao.SQL.Add('(codigo, ispb, nome, nome_completo, ativo, atualizado_em)');
    Conexao.SQL.Add('values');
    Conexao.SQL.Add('(:codigo, :ispb, :nome, :nome_completo, :ativo, now())');
    Conexao.Parametros('codigo', Codigo);
    Conexao.Parametros('ispb', JsonString(JSON, 'ispb', ''));
    Conexao.Parametros('nome', JsonString(JSON, 'nome', ''));
    Conexao.Parametros('nome_completo', JsonString(JSON, 'nome_completo', ''));
    Conexao.Parametros('ativo', JsonIntegerPadrao(JSON, 'ativo', 1));
    Conexao.ExecuteSQL;
    Res.Send('true');
  finally
    JSON.Free;
    Conexao.Free;
  end;
end;

procedure DoPutBanco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSON: TJSONObject;
begin
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Conexao := TConexao.Create('DoPutBanco');
  try
    Conexao.SQL.Add('update bancos set');
    Conexao.SQL.Add('ispb = :ispb,');
    Conexao.SQL.Add('nome = :nome,');
    Conexao.SQL.Add('nome_completo = :nome_completo,');
    Conexao.SQL.Add('ativo = :ativo,');
    Conexao.SQL.Add('atualizado_em = now()');
    Conexao.SQL.Add('where codigo = :codigo');
    Conexao.Parametros('codigo', Req.Params['codigo']);
    Conexao.Parametros('ispb', JsonString(JSON, 'ispb', ''));
    Conexao.Parametros('nome', JsonString(JSON, 'nome', ''));
    Conexao.Parametros('nome_completo', JsonString(JSON, 'nome_completo', ''));
    Conexao.Parametros('ativo', JsonIntegerPadrao(JSON, 'ativo', 1));
    Conexao.ExecuteSQL;
    Res.Send('true');
  finally
    JSON.Free;
    Conexao.Free;
  end;
end;

procedure DoDeleteBanco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
begin
  Conexao := TConexao.Create('DoDeleteBanco');
  try
    Conexao.SQL.Add('update bancos set ativo = 0, atualizado_em = now()');
    Conexao.SQL.Add('where codigo = :codigo');
    Conexao.Parametros('codigo', Req.Params['codigo']);
    Conexao.ExecuteSQL;
    Res.Send('true');
  finally
    Conexao.Free;
  end;
end;

procedure DoPostAtualizarBancos(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send<TJSONObject>(AtualizarBancosBrasilAPI);
end;

procedure DoGetCartoes(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
begin
  Conexao := TConexao.Create('DoGetCartoes');
  try
    Conexao.SQL.Add('select c.id, c.banco_id, b.codigo as banco_codigo,');
    Conexao.SQL.Add('b.nome as banco_nome, c.nome, c.tipo, c.melhor_dia,');
    Conexao.SQL.Add('c.dia_vencimento, c.limite, c.limite_usado,');
    Conexao.SQL.Add('(coalesce(c.limite, 0) - coalesce(c.limite_usado, 0)) as limite_disponivel,');
    Conexao.SQL.Add('c.vencimento_ano_mes, c.ativo, c.criado_em, c.atualizado_em');
    Conexao.SQL.Add('from cartoes c');
    Conexao.SQL.Add('left join bancos b on b.id = c.banco_id');
    Conexao.SQL.Add('where c.ativo = 1');
    Conexao.SQL.Add('order by c.nome');
    Res.Send<TJSONArray>(Conexao.ConsultaSQL);
  finally
    Conexao.Free;
  end;
end;

procedure DoGetCartao(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
begin
  Conexao := TConexao.Create('DoGetCartao');
  try
    Conexao.SQL.Add('select c.id, c.banco_id, b.codigo as banco_codigo,');
    Conexao.SQL.Add('b.nome as banco_nome, c.nome, c.tipo, c.melhor_dia,');
    Conexao.SQL.Add('c.dia_vencimento, c.limite, c.limite_usado,');
    Conexao.SQL.Add('(coalesce(c.limite, 0) - coalesce(c.limite_usado, 0)) as limite_disponivel,');
    Conexao.SQL.Add('c.vencimento_ano_mes, c.ativo, c.criado_em, c.atualizado_em');
    Conexao.SQL.Add('from cartoes c');
    Conexao.SQL.Add('left join bancos b on b.id = c.banco_id');
    Conexao.SQL.Add('where c.id = :id');
    Conexao.Parametros('id', Req.Params['id']);
    Res.Send<TJSONArray>(Conexao.ConsultaSQL);
  finally
    Conexao.Free;
  end;
end;

procedure DoPostCartao(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSON: TJSONObject;
  BancoID: Integer;
begin
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Conexao := TConexao.Create('DoPostCartao');
  try
    if not JsonInteger(JSON, 'banco_id', BancoID) then
    begin
      Res.Status(400);
      Res.Send('banco_id obrigatorio');
      exit;
    end;
    Conexao.SQL.Add('insert into cartoes');
    Conexao.SQL.Add('(banco_id, nome, tipo, melhor_dia, dia_vencimento,');
    Conexao.SQL.Add('limite, limite_usado, vencimento_ano_mes, ativo, atualizado_em)');
    Conexao.SQL.Add('values');
    Conexao.SQL.Add('(:banco_id, :nome, :tipo, :melhor_dia, :dia_vencimento,');
    Conexao.SQL.Add(':limite, :limite_usado, :vencimento_ano_mes, :ativo, now())');
    Conexao.Parametros('banco_id', BancoID);
    Conexao.Parametros('nome', JsonString(JSON, 'nome', ''));
    Conexao.Parametros('tipo', JsonString(JSON, 'tipo', 'credito'));
    Conexao.Parametros('melhor_dia', JsonIntegerPadrao(JSON, 'melhor_dia', 1));
    Conexao.Parametros('dia_vencimento',
      JsonIntegerPadrao(JSON, 'dia_vencimento', 1));
    Conexao.Parametros('limite', JsonString(JSON, 'limite', '0'));
    Conexao.Parametros('limite_usado', JsonString(JSON, 'limite_usado', '0'));
    Conexao.Parametros('vencimento_ano_mes',
      JsonString(JSON, 'vencimento_ano_mes', ''));
    Conexao.Parametros('ativo', JsonIntegerPadrao(JSON, 'ativo', 1));
    Conexao.ExecuteSQL;
    Res.Send('true');
  finally
    JSON.Free;
    Conexao.Free;
  end;
end;

procedure DoPutCartao(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSON: TJSONObject;
begin
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Conexao := TConexao.Create('DoPutCartao');
  try
    Conexao.SQL.Add('update cartoes set');
    Conexao.SQL.Add('banco_id = :banco_id,');
    Conexao.SQL.Add('nome = :nome,');
    Conexao.SQL.Add('tipo = :tipo,');
    Conexao.SQL.Add('melhor_dia = :melhor_dia,');
    Conexao.SQL.Add('dia_vencimento = :dia_vencimento,');
    Conexao.SQL.Add('limite = :limite,');
    Conexao.SQL.Add('limite_usado = :limite_usado,');
    Conexao.SQL.Add('vencimento_ano_mes = :vencimento_ano_mes,');
    Conexao.SQL.Add('ativo = :ativo,');
    Conexao.SQL.Add('atualizado_em = now()');
    Conexao.SQL.Add('where id = :id');
    Conexao.Parametros('id', Req.Params['id']);
    Conexao.Parametros('banco_id', JsonIntegerPadrao(JSON, 'banco_id', 0));
    Conexao.Parametros('nome', JsonString(JSON, 'nome', ''));
    Conexao.Parametros('tipo', JsonString(JSON, 'tipo', 'credito'));
    Conexao.Parametros('melhor_dia', JsonIntegerPadrao(JSON, 'melhor_dia', 1));
    Conexao.Parametros('dia_vencimento',
      JsonIntegerPadrao(JSON, 'dia_vencimento', 1));
    Conexao.Parametros('limite', JsonString(JSON, 'limite', '0'));
    Conexao.Parametros('limite_usado', JsonString(JSON, 'limite_usado', '0'));
    Conexao.Parametros('vencimento_ano_mes',
      JsonString(JSON, 'vencimento_ano_mes', ''));
    Conexao.Parametros('ativo', JsonIntegerPadrao(JSON, 'ativo', 1));
    Conexao.ExecuteSQL;
    Res.Send('true');
  finally
    JSON.Free;
    Conexao.Free;
  end;
end;

procedure DoDeleteCartao(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
begin
  Conexao := TConexao.Create('DoDeleteCartao');
  try
    Conexao.SQL.Add('update cartoes set ativo = 0, atualizado_em = now()');
    Conexao.SQL.Add('where id = :id');
    Conexao.Parametros('id', Req.Params['id']);
    Conexao.ExecuteSQL;
    Res.Send('true');
  finally
    Conexao.Free;
  end;
end;

procedure DoPostFatura(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conexao: TConexao;
  JSONValue: TJSONValue;
  JSON: TJSONObject;
  JSONArray: TJSONArray;
  Retorno: TJSONObject;
  CartaoID: Integer;
  Categoria: Integer;
  ParcelaAtual: Integer;
  TotalParcelas: Integer;
  ParcelasRestantes: Integer;
  IndiceItem: Integer;
  Inseridas: Integer;
  Ignoradas: Integer;
  ValorParcela: Double;
  ValorTotalLancado: Double;
  TotalLancadoGeral: Double;
  DataCompra: TDate;
  VencimentoBase: TDate;
  Vencimento: TDate;
  Descricao: string;
  Grupo: string;

  procedure ProcessarItem(Item: TJSONObject);
  var
    IndiceParcela: Integer;
  begin
    if not JsonInteger(Item, 'cartao_id', CartaoID) then
      raise Exception.Create('cartao_id obrigatorio');
    if not JsonInteger(Item, 'categoria', Categoria) then
      raise Exception.Create('categoria obrigatoria');

    Descricao := JsonString(Item, 'descricao', '');
    if Descricao = '' then
      Descricao := JsonString(Item, 'title', '');
    ValorParcela := JsonFloatPadrao(Item, 'valor',
      JsonFloatPadrao(Item, 'amount', 0));
    DataCompra := DataISOFinanceiro(JsonString(Item, 'data',
      JsonString(Item, 'date', FormatDateTime('yyyy-mm-dd', Date))));
    VencimentoBase := CalcularVencimentoFatura(Conexao, CartaoID, DataCompra);

    ExtrairParcelaFatura(Descricao, ParcelaAtual, TotalParcelas);
    Descricao := DescricaoSemParcelaFatura(Descricao);
    ParcelasRestantes := TotalParcelas - ParcelaAtual + 1;
    if ParcelasRestantes < 1 then
      ParcelasRestantes := 1;

    Grupo := FormatDateTime('yyyymmddhhnnsszzz', Now) + IntToStr(Random(10000));
    ValorTotalLancado := 0;

    for IndiceParcela := 0 to ParcelasRestantes - 1 do
    begin
      Vencimento := IncMonth(VencimentoBase, IndiceParcela);

      if DespesaFaturaJaExiste(Conexao, Descricao, ValorParcela,
        ParcelaAtual + IndiceParcela, TotalParcelas) then
      begin
        Inc(Ignoradas);
        Continue;
      end;

      Conexao.SQL.Clear;
      Conexao.SQL.Add('insert into despesas');
      Conexao.SQL.Add('(categoria, descricao, valor, parcelas, parcela, vencimento,');
      Conexao.SQL.Add('data_compra, status, cartao_id, limite_cartao_retornado, recorrente,');
      Conexao.SQL.Add('recorrencia_tipo, recorrencia_grupo, fatura_ano_mes) values');
      Conexao.SQL.Add('(:categoria, :descricao, :valor, :parcelas, :parcela,');
      Conexao.SQL.Add(':vencimento, :data_compra, 1, :cartao_id, 0, 0, 3, :recorrencia_grupo,');
      Conexao.SQL.Add(':fatura_ano_mes)');
      Conexao.Parametros('categoria', Categoria);
      Conexao.Parametros('descricao', Descricao);
      Conexao.Parametros('valor', FloatSQL(ValorParcela));
      Conexao.Parametros('parcelas', TotalParcelas);
      Conexao.Parametros('parcela', ParcelaAtual + IndiceParcela);
      Conexao.Parametros('vencimento', FormatDateTime('yyyy-mm-dd', Vencimento));
      Conexao.Parametros('data_compra', FormatDateTime('yyyy-mm-dd', DataCompra));
      Conexao.Parametros('cartao_id', CartaoID);
      Conexao.Parametros('recorrencia_grupo', Grupo);
      Conexao.Parametros('fatura_ano_mes', FormatDateTime('yyyy-mm', Vencimento));
      if not Conexao.ExecuteSQL(Conexao.SQL.Text) then
        raise Exception.Create('erro ao inserir despesa da fatura');
      Inc(Inseridas);
      ValorTotalLancado := ValorTotalLancado + ValorParcela;
      TotalLancadoGeral := TotalLancadoGeral + ValorParcela;
    end;

    SomarLimiteUsadoCartao(Conexao, CartaoID, ValorTotalLancado);
  end;
begin
  JSONValue := TJSONObject.ParseJSONValue(Req.Body);
  JSON := nil;
  JSONArray := nil;
  if Assigned(JSONValue) and (JSONValue is TJSONObject) then
    JSON := JSONValue as TJSONObject
  else if Assigned(JSONValue) and (JSONValue is TJSONArray) then
    JSONArray := JSONValue as TJSONArray;
  Conexao := TConexao.Create('DoPostFatura');
  Retorno := TJSONObject.Create;
  try
    if (not Assigned(JSON)) and (not Assigned(JSONArray)) then
    begin
      Res.Status(400);
      Res.Send('json invalido');
      exit;
    end;
    Inseridas := 0;
    Ignoradas := 0;
    TotalLancadoGeral := 0;
    GarantirCamposFatura(Conexao);

    try
      if Assigned(JSON) then
        ProcessarItem(JSON)
      else
      begin
        for IndiceItem := 0 to JSONArray.Count - 1 do
          if JSONArray.Items[IndiceItem] is TJSONObject then
            ProcessarItem(JSONArray.Items[IndiceItem] as TJSONObject);
      end;
    except
      on E: Exception do
      begin
        Res.Status(400);
        Res.Send(E.Message);
        exit;
      end;
    end;

    Retorno.AddPair('status', 'ok');
    Retorno.AddPair('parcelas_lancadas', TJSONNumber.Create(Inseridas));
    Retorno.AddPair('parcelas_ignoradas', TJSONNumber.Create(Ignoradas));
    Retorno.AddPair('valor_total_lancado', TJSONNumber.Create(TotalLancadoGeral));
    Res.Send<TJSONObject>(Retorno);
  finally
    JSONValue.Free;
    Conexao.Free;
  end;
end;

procedure AdicionarResumoAgrupado(Conexao: TConexao; Destino: TJSONArray;
  const DataInicial, DataFinal: string; Cartao: Boolean);
var
  Qry: TFDQuery;
  Item: TJSONObject;
begin
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('select coalesce(d.categoria, 0) as categoria_id,');
    Qry.SQL.Add('coalesce(dc.descricao, "") as categoria,');
    Qry.SQL.Add('d.descricao as nome, count(*) as quantidade,');
    Qry.SQL.Add('sum(d.valor) as valor_total');
    Qry.SQL.Add('from despesas d');
    Qry.SQL.Add('left join descricao dc on dc.id = d.categoria');
    Qry.SQL.Add('where d.vencimento between :data_inicial and :data_final');
    Qry.SQL.Add('and coalesce(d.excluida, 0) = 0');
    if Cartao then
      Qry.SQL.Add('and coalesce(d.cartao_id, 0) > 0')
    else
      Qry.SQL.Add('and coalesce(d.cartao_id, 0) = 0');
    Qry.SQL.Add('group by coalesce(d.categoria, 0), coalesce(dc.descricao, ""), d.descricao');
    Qry.SQL.Add('order by coalesce(dc.descricao, ""), d.descricao');
    Qry.ParamByName('data_inicial').AsString := DataInicial;
    Qry.ParamByName('data_final').AsString := DataFinal;
    Qry.Open;
    while not Qry.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('categoria_id',
        TJSONNumber.Create(Qry.FieldByName('categoria_id').AsInteger));
      Item.AddPair('categoria', Qry.FieldByName('categoria').AsString);
      Item.AddPair('nome', Qry.FieldByName('nome').AsString);
      Item.AddPair('quantidade',
        TJSONNumber.Create(Qry.FieldByName('quantidade').AsInteger));
      Item.AddPair('valor_total',
        TJSONNumber.Create(Qry.FieldByName('valor_total').AsFloat));
      Destino.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

procedure AdicionarResumoCategorias(Conexao: TConexao; Destino: TJSONArray;
  const DataInicial, DataFinal: string; Cartao: Boolean);
var
  Qry: TFDQuery;
  Item: TJSONObject;
begin
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('select coalesce(d.categoria, 0) as categoria_id,');
    Qry.SQL.Add('coalesce(dc.descricao, "") as categoria,');
    Qry.SQL.Add('count(*) as quantidade, sum(d.valor) as valor_total');
    Qry.SQL.Add('from despesas d');
    Qry.SQL.Add('left join descricao dc on dc.id = d.categoria');
    Qry.SQL.Add('where d.vencimento between :data_inicial and :data_final');
    Qry.SQL.Add('and coalesce(d.excluida, 0) = 0');
    if Cartao then
      Qry.SQL.Add('and coalesce(d.cartao_id, 0) > 0')
    else
      Qry.SQL.Add('and coalesce(d.cartao_id, 0) = 0');
    Qry.SQL.Add('group by coalesce(d.categoria, 0), coalesce(dc.descricao, "")');
    Qry.SQL.Add('order by sum(d.valor) desc, coalesce(dc.descricao, "")');
    Qry.ParamByName('data_inicial').AsString := DataInicial;
    Qry.ParamByName('data_final').AsString := DataFinal;
    Qry.Open;
    while not Qry.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('categoria_id',
        TJSONNumber.Create(Qry.FieldByName('categoria_id').AsInteger));
      Item.AddPair('categoria', Qry.FieldByName('categoria').AsString);
      Item.AddPair('quantidade',
        TJSONNumber.Create(Qry.FieldByName('quantidade').AsInteger));
      Item.AddPair('valor_total',
        TJSONNumber.Create(Qry.FieldByName('valor_total').AsFloat));
      Destino.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

procedure AdicionarComprasParceladas(Conexao: TConexao; Destino: TJSONArray;
  const DataInicial, DataFinal: string);
var
  Qry: TFDQuery;
  Item: TJSONObject;
begin
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('select coalesce(d.categoria, 0) as categoria_id,');
    Qry.SQL.Add('coalesce(dc.descricao, "") as categoria,');
    Qry.SQL.Add('d.descricao as nome, coalesce(d.cartao_id, 0) as cartao_id,');
    Qry.SQL.Add('coalesce(c.nome, "") as cartao, d.parcelas as quantidade_parcelas,');
    Qry.SQL.Add('sum(d.valor) as valor_total, min(d.vencimento) as inicio,');
    Qry.SQL.Add('max(d.vencimento) as termino, count(*) as parcelas_lancadas');
    Qry.SQL.Add('from despesas d');
    Qry.SQL.Add('left join descricao dc on dc.id = d.categoria');
    Qry.SQL.Add('left join cartoes c on c.id = d.cartao_id');
    Qry.SQL.Add('where d.vencimento between :data_inicial and :data_final');
    Qry.SQL.Add('and coalesce(d.excluida, 0) = 0');
    Qry.SQL.Add('and coalesce(d.parcelas, 1) > 1');
    Qry.SQL.Add('group by coalesce(d.categoria, 0), coalesce(dc.descricao, ""),');
    Qry.SQL.Add('d.descricao, coalesce(d.cartao_id, 0), coalesce(c.nome, ""), d.parcelas');
    Qry.SQL.Add('order by min(d.vencimento), d.descricao');
    Qry.ParamByName('data_inicial').AsString := DataInicial;
    Qry.ParamByName('data_final').AsString := DataFinal;
    Qry.Open;
    while not Qry.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('categoria_id',
        TJSONNumber.Create(Qry.FieldByName('categoria_id').AsInteger));
      Item.AddPair('categoria', Qry.FieldByName('categoria').AsString);
      Item.AddPair('nome', Qry.FieldByName('nome').AsString);
      Item.AddPair('cartao_id',
        TJSONNumber.Create(Qry.FieldByName('cartao_id').AsInteger));
      Item.AddPair('cartao', Qry.FieldByName('cartao').AsString);
      Item.AddPair('valor_total',
        TJSONNumber.Create(Qry.FieldByName('valor_total').AsFloat));
      Item.AddPair('inicio', FormatDateTime('yyyy-mm-dd',
        Qry.FieldByName('inicio').AsDateTime));
      Item.AddPair('termino', FormatDateTime('yyyy-mm-dd',
        Qry.FieldByName('termino').AsDateTime));
      Item.AddPair('quantidade_parcelas',
        TJSONNumber.Create(Qry.FieldByName('quantidade_parcelas').AsInteger));
      Item.AddPair('parcelas_lancadas',
        TJSONNumber.Create(Qry.FieldByName('parcelas_lancadas').AsInteger));
      Destino.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

procedure AdicionarResumoCartoes(Conexao: TConexao; Destino: TJSONArray;
  const DataInicial, DataFinal: string);
var
  Qry: TFDQuery;
  Item: TJSONObject;
begin
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('select coalesce(d.cartao_id, 0) as cartao_id,');
    Qry.SQL.Add('coalesce(c.nome, "") as cartao,');
    Qry.SQL.Add('coalesce(c.tipo, "") as tipo, count(*) as quantidade,');
    Qry.SQL.Add('sum(d.valor) as valor_total');
    Qry.SQL.Add('from despesas d');
    Qry.SQL.Add('left join cartoes c on c.id = d.cartao_id');
    Qry.SQL.Add('where d.vencimento between :data_inicial and :data_final');
    Qry.SQL.Add('and coalesce(d.excluida, 0) = 0');
    Qry.SQL.Add('and coalesce(d.cartao_id, 0) > 0');
    Qry.SQL.Add('group by coalesce(d.cartao_id, 0), coalesce(c.nome, ""), coalesce(c.tipo, "")');
    Qry.SQL.Add('order by sum(d.valor) desc, coalesce(c.nome, "")');
    Qry.ParamByName('data_inicial').AsString := DataInicial;
    Qry.ParamByName('data_final').AsString := DataFinal;
    Qry.Open;
    while not Qry.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('cartao_id',
        TJSONNumber.Create(Qry.FieldByName('cartao_id').AsInteger));
      Item.AddPair('cartao', Qry.FieldByName('cartao').AsString);
      Item.AddPair('tipo', Qry.FieldByName('tipo').AsString);
      Item.AddPair('quantidade',
        TJSONNumber.Create(Qry.FieldByName('quantidade').AsInteger));
      Item.AddPair('valor_total',
        TJSONNumber.Create(Qry.FieldByName('valor_total').AsFloat));
      Destino.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

procedure DoGetResumoFinanceiro(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Conexao: TConexao;
  JSONValue: TJSONValue;
  JSON: TJSONObject;
  Retorno: TJSONObject;
  Despesas: TJSONObject;
  CartaoCredito: TJSONObject;
  DespesasCategorias: TJSONArray;
  DespesasNomes: TJSONArray;
  CartaoCategorias: TJSONArray;
  CartaoNomes: TJSONArray;
  Cartoes: TJSONArray;
  Parceladas: TJSONArray;
  DataInicial: string;
  DataFinal: string;
begin
  Conexao := TConexao.Create('DoGetResumoFinanceiro');
  JSONValue := nil;
  Retorno := TJSONObject.Create;
  Despesas := TJSONObject.Create;
  CartaoCredito := TJSONObject.Create;
  DespesasCategorias := TJSONArray.Create;
  DespesasNomes := TJSONArray.Create;
  CartaoCategorias := TJSONArray.Create;
  CartaoNomes := TJSONArray.Create;
  Cartoes := TJSONArray.Create;
  Parceladas := TJSONArray.Create;
  try
    DataInicial := ParamRota(Req, 'dataini');
    DataFinal := ParamRota(Req, 'datafim');
    if (DataInicial = '') or (DataFinal = '') then
    begin
      JSONValue := TJSONObject.ParseJSONValue(Req.Body);
      if Assigned(JSONValue) and (JSONValue is TJSONObject) then
      begin
        JSON := JSONValue as TJSONObject;
        DataInicial := JsonString(JSON, 'data_inicial',
          JsonString(JSON, 'dataini', ''));
        DataFinal := JsonString(JSON, 'data_final',
          JsonString(JSON, 'datafim', ''));
      end;
    end;

    if (DataInicial = '') or (DataFinal = '') then
    begin
      Res.Status(400);
      Res.Send('data_inicial e data_final obrigatorias');
      exit;
    end;

    AdicionarResumoCategorias(Conexao, DespesasCategorias, DataInicial,
      DataFinal, False);
    AdicionarResumoAgrupado(Conexao, DespesasNomes, DataInicial, DataFinal,
      False);
    AdicionarResumoCategorias(Conexao, CartaoCategorias, DataInicial,
      DataFinal, True);
    AdicionarResumoAgrupado(Conexao, CartaoNomes, DataInicial, DataFinal,
      True);
    AdicionarResumoCartoes(Conexao, Cartoes, DataInicial, DataFinal);
    AdicionarComprasParceladas(Conexao, Parceladas, DataInicial, DataFinal);

    Despesas.AddPair('categorias', DespesasCategorias);
    Despesas.AddPair('nomes', DespesasNomes);
    CartaoCredito.AddPair('categorias', CartaoCategorias);
    CartaoCredito.AddPair('nomes', CartaoNomes);

    Retorno.AddPair('data_inicial', DataInicial);
    Retorno.AddPair('data_final', DataFinal);
    Retorno.AddPair('despesas', Despesas);
    Retorno.AddPair('cartao_credito', CartaoCredito);
    Retorno.AddPair('cartoes', Cartoes);
    Retorno.AddPair('compras_parceladas', Parceladas);
    Res.Send<TJSONObject>(Retorno);
  finally
    JSONValue.Free;
    Conexao.Free;
  end;
end;

procedure Registry;
begin
  THorse.Get('/v2/financeiro/bancos', DoGetBancos);
  THorse.Post('/v2/financeiro/bancos/atualizar', DoPostAtualizarBancos);
  THorse.Put('/v2/financeiro/bancos/atualizar', DoPostAtualizarBancos);
  THorse.Get('/v2/financeiro/bancos/:codigo', DoGetBanco);
  THorse.Post('/v2/financeiro/bancos', DoPostBanco);
  THorse.Put('/v2/financeiro/bancos/:codigo', DoPutBanco);
  THorse.Delete('/v2/financeiro/bancos/:codigo', DoDeleteBanco);
  THorse.Get('/v2/financeiro/cartoes', DoGetCartoes);
  THorse.Get('/v2/financeiro/cartoes/:id', DoGetCartao);
  THorse.Post('/v2/financeiro/cartoes', DoPostCartao);
  THorse.Put('/v2/financeiro/cartoes/:id', DoPutCartao);
  THorse.Delete('/v2/financeiro/cartoes/:id', DoDeleteCartao);
  THorse.Post('/v2/financeiro/fatura', DoPostFatura);
  THorse.Get('/v2/financeiro/resumo/:dataini/:datafim', DoGetResumoFinanceiro);
  THorse.Post('/v2/financeiro/resumo', DoGetResumoFinanceiro);
end;

end.
