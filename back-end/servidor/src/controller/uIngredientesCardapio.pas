unit uIngredientesCardapio;

interface

uses
  JOSE.Types.JSON;

function ProcessarIngredientesCardapio: TJSONObject;
function GravarIngredientesCardapio(const Body: string): TJSONObject;
function ValidarAlertaIngredientesPendentes: TJSONObject;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Character,
  System.RegularExpressions,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  conexao,
  uCacheControl;

const
  CACHE_ORIGEM = 'IngredientesCardapio';
  CACHE_CHAVE = 'gerados';

var
  ProcessLock: TObject;

function TextoLimpo(const Texto: string): string;
var
  I: Integer;
  C: Char;
  UltimoEspaco: Boolean;
begin
  Result := '';
  UltimoEspaco := True;

  for I := 1 to Length(Texto) do
  begin
    C := Texto[I];
    if TCharacter.IsLetterOrDigit(C) then
    begin
      Result := Result + C;
      UltimoEspaco := False;
    end
    else if not UltimoEspaco then
    begin
      Result := Result + ' ';
      UltimoEspaco := True;
    end;
  end;

  Result := Trim(UpperCase(Result));
end;

function PrimeiraPalavraSem(const Texto: string): Boolean;
begin
  Result := SameText(Copy(Trim(Texto), 1, 4), 'SEM ');
end;

function ToFloatInvariant(const Valor: string): Double;
var
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Invariant;
  Result := StrToFloatDef(StringReplace(Valor, ',', '.', [rfReplaceAll]), 0, FS);
end;

procedure ExtrairUnidade(var Descricao: string; out Unidade: string;
  out Quantidade: Double);
var
  Match: TMatch;
  Valor: Double;
  UnidadeTexto: string;
begin
  Unidade := 'G';
  Quantidade := 1;

  Match := TRegEx.Match(Descricao,
    '^(.*?)(?:\s*)(\d+(?:[\.,]\d+)?)\s*(GRAMAS|GRAMA|KILOS|KILO|KG|UN|G|L)$',
    [roIgnoreCase]);

  if not Match.Success then
    Exit;

  Descricao := Trim(Match.Groups[1].Value);
  Valor := ToFloatInvariant(Match.Groups[2].Value);
  UnidadeTexto := UpperCase(Match.Groups[3].Value);

  if (UnidadeTexto = 'G') or (UnidadeTexto = 'GRAMA') or
    (UnidadeTexto = 'GRAMAS') then
  begin
    Unidade := 'G';
    Quantidade := Valor / 1000;
  end
  else if (UnidadeTexto = 'KG') or (UnidadeTexto = 'KILO') or
    (UnidadeTexto = 'KILOS') then
  begin
    Unidade := 'G';
    Quantidade := Valor;
  end
  else if UnidadeTexto = 'UN' then
  begin
    Unidade := 'G';
    Quantidade := Valor;
  end
  else if UnidadeTexto = 'L' then
  begin
    Unidade := 'G';
    Quantidade := Valor;
  end;
end;

function SepararPorE(const Texto: string): TArray<string>;
begin
  Result := TRegEx.Split(Texto, '\s+E\s+', [roIgnoreCase]);
end;

function BuscarIngredienteID(Conexao: TConexao; const Descricao: string): Integer;
var
  Qry: TFDQuery;
begin
  Result := 0;
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Text :=
      'select id from ingredientes where upper(descricao) = :descricao limit 1';
    Qry.ParamByName('descricao').AsString := UpperCase(Descricao);
    Qry.Open;
    if not Qry.Eof then
      Result := Qry.FieldByName('id').AsInteger;
  finally
    Qry.Free;
  end;
end;

procedure AtualizarAdicional(Conexao: TConexao; const NomeOriginal: string;
  IngredienteID: Integer; Quantidade: Double);
begin
  Conexao.SQL.Add
    ('update pro_adi_personalizado_sabores set id_ingredientes = :id_ingredientes, quantidade_ingredientes = :quantidade');
  Conexao.SQL.Add('where upper(nome) = :nome and nome not like ''%Sem %''');
  Conexao.Parametros('id_ingredientes', IngredienteID);
  Conexao.Parametros('quantidade', Quantidade);
  Conexao.Parametros('nome', UpperCase(NomeOriginal));
  Conexao.ExecuteSQL;
end;

procedure InserirIngrediente(Conexao: TConexao; const Descricao, Unidade: string;
  Quantidade: Double; out IngredienteID: Integer);
begin
  IngredienteID := Conexao.GerarID('ingredientes', 'id');
  Conexao.SQL.Add
    ('insert into ingredientes (id, descricao, unidade, saldo, tipo, custo, custo_medio, custo_ultimo, quantidade)');
  Conexao.SQL.Add
    ('values (:id, :descricao, :unidade, 0, 0, 0, 0, 0, :quantidade)');
  Conexao.Parametros('id', IngredienteID);
  Conexao.Parametros('descricao', Descricao);
  Conexao.Parametros('unidade', Unidade);
  Conexao.Parametros('quantidade', Quantidade);
  Conexao.ExecuteSQL;
end;

procedure AdicionarItem(Itens: TJSONArray; const Origem, Original, Descricao,
  Unidade, Status: string; Quantidade: Double; IngredienteID: Integer);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('origem', Origem);
  Obj.AddPair('original', Original);
  Obj.AddPair('descricao', Descricao);
  Obj.AddPair('unidade', Unidade);
  Obj.AddPair('quantidade', Quantidade);
  Obj.AddPair('status', Status);
  Obj.AddPair('id', IngredienteID);
  Itens.AddElement(Obj);
end;

procedure ProcessarTexto(Conexao: TConexao; Visitados: TDictionary<string, Boolean>;
  Itens: TJSONArray; const Origem, Texto: string; var Total, Novos,
  Existentes: Integer);
var
  Partes: TArray<string>;
  SubPartes: TArray<string>;
  Parte: string;
  SubParte: string;
  Descricao: string;
  Unidade: string;
  Quantidade: Double;
  IngredienteID: Integer;
  Chave: string;
begin
  Partes := Texto.Split([',', '.']);
  for Parte in Partes do
  begin
    SubPartes := SepararPorE(TextoLimpo(Parte));
    for SubParte in SubPartes do
    begin
      Descricao := TextoLimpo(SubParte);

      if (Descricao = '') or PrimeiraPalavraSem(Descricao) then
        Continue;

      ExtrairUnidade(Descricao, Unidade, Quantidade);
      Descricao := TextoLimpo(Descricao);

      if Descricao = '' then
        Continue;

      Chave := Origem + ':' + Descricao;
      if Visitados.ContainsKey(Chave) then
        Continue;

      Visitados.Add(Chave, True);
      Inc(Total);

      IngredienteID := BuscarIngredienteID(Conexao, Descricao);
      if IngredienteID = 0 then
      begin
        Inc(Novos);
        AdicionarItem(Itens, Origem, Texto, Descricao, Unidade, 'novo',
          Quantidade, 0);
      end
      else
      begin
        Inc(Existentes);
        AdicionarItem(Itens, Origem, Texto, Descricao, Unidade, 'existente',
          Quantidade, IngredienteID);
      end;
    end;
  end;
end;

procedure ProcessarSQL(Conexao: TConexao; Visitados: TDictionary<string, Boolean>;
  Itens: TJSONArray; const Origem, SQL, Campo: string; var Total, Novos,
  Existentes: Integer);
var
  Qry: TFDQuery;
begin
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Text := SQL;
    Qry.Open;

    while not Qry.Eof do
    begin
      ProcessarTexto(Conexao, Visitados, Itens, Origem,
        Qry.FieldByName(Campo).AsString, Total, Novos, Existentes);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function ProcessarIngredientesCardapio: TJSONObject;
var
  Conexao: TConexao;
  Visitados: TDictionary<string, Boolean>;
  Itens: TJSONArray;
  Total: Integer;
  Novos: Integer;
  Existentes: Integer;
begin
  TMonitor.Enter(ProcessLock);
  try
    Conexao := nil;
    Visitados := nil;
    Result := TJSONObject.Create;
    Itens := TJSONArray.Create;
    Total := 0;
    Novos := 0;
    Existentes := 0;

    Conexao := TConexao.Create('IngredientesCardapio');
    Visitados := TDictionary<string, Boolean>.Create;
    try
      ProcessarSQL(Conexao, Visitados, Itens, 'SABOR',
        'select upper(descricao) as descricao from sabores_completo group by descricao',
        'descricao', Total, Novos, Existentes);

      ProcessarSQL(Conexao, Visitados, Itens, 'PRODUTO',
        'select upper(descricao) as descricao from produto group by descricao',
        'descricao', Total, Novos, Existentes);

      ProcessarSQL(Conexao, Visitados, Itens, 'EXTRA',
        'select nome from pro_adi_personalizado_sabores where nome not like ''%Sem %'' group by nome',
        'nome', Total, Novos, Existentes);

      Result.AddPair('success', True);
      Result.AddPair('total', Total);
      Result.AddPair('novos', Novos);
      Result.AddPair('existentes', Existentes);
      Result.AddPair('itens', Itens);
      Itens := nil;

      GravaCache(CACHE_ORIGEM, CACHE_CHAVE, Result.ToString);
    except
      on E: Exception do
      begin
        if Assigned(Itens) then
          Itens.Free;
        Result.Free;
        Result := TJSONObject.Create;
        Result.AddPair('success', False);
        Result.AddPair('message', E.Message);
        GravaCache(CACHE_ORIGEM, CACHE_CHAVE, Result.ToString);
      end;
    end;

    if Assigned(Visitados) then
      Visitados.Free;
    if Assigned(Conexao) then
      Conexao.Free;
  finally
    TMonitor.Exit(ProcessLock);
  end;
end;

function JsonString(Obj: TJSONObject; const Nome, Padrao: string): string;
var
  Valor: TJSONValue;
begin
  Result := Padrao;
  Valor := Obj.GetValue(Nome);
  if Assigned(Valor) then
    Result := Valor.Value;
end;

function JsonFloat(Obj: TJSONObject; const Nome: string; Padrao: Double): Double;
var
  Texto: string;
begin
  Texto := JsonString(Obj, Nome, '');
  if Texto = '' then
    Exit(Padrao);

  Result := ToFloatInvariant(Texto);
end;

function JsonInt(Obj: TJSONObject; const Nome: string; Padrao: Integer): Integer;
begin
  Result := StrToIntDef(JsonString(Obj, Nome, ''), Padrao);
end;

function JsonBool(Obj: TJSONObject; const Nome: string; Padrao: Boolean): Boolean;
var
  Texto: string;
begin
  Texto := LowerCase(JsonString(Obj, Nome, ''));
  if Texto = '' then
    Exit(Padrao);

  Result := (Texto = 'true') or (Texto = '1') or (Texto = 's') or
    (Texto = 'sim');
end;

function ExtrairItensAprovados(JSON: TJSONValue): TJSONArray;
var
  Obj: TJSONObject;
begin
  Result := nil;

  if JSON is TJSONArray then
    Exit(JSON as TJSONArray);

  if JSON is TJSONObject then
  begin
    Obj := JSON as TJSONObject;
    Result := Obj.GetValue<TJSONArray>('itens');
  end;
end;

function GravarIngredientesCardapio(const Body: string): TJSONObject;
var
  Conexao: TConexao;
  JSON: TJSONValue;
  Itens: TJSONArray;
  Item: TJSONObject;
  I: Integer;
  IngredienteID: Integer;
  Descricao: string;
  Unidade: string;
  Origem: string;
  Original: string;
  Quantidade: Double;
  Gravados: Integer;
  Ignorados: Integer;
begin
  TMonitor.Enter(ProcessLock);
  JSON := nil;
  Conexao := nil;
  Result := TJSONObject.Create;
  Gravados := 0;
  Ignorados := 0;
  try
    JSON := TJSONObject.ParseJSONValue(Body);
    Itens := ExtrairItensAprovados(JSON);

    if not Assigned(Itens) then
      raise Exception.Create('JSON inválido. Envie um array ou objeto com "itens".');

    Conexao := TConexao.Create('GravarIngredientesCardapio');
    for I := 0 to Itens.Count - 1 do
    begin
      if not(Itens.Items[I] is TJSONObject) then
      begin
        Inc(Ignorados);
        Continue;
      end;

      Item := Itens.Items[I] as TJSONObject;
      if not JsonBool(Item, 'aprovado', True) then
      begin
        Inc(Ignorados);
        Continue;
      end;

      Descricao := TextoLimpo(JsonString(Item, 'descricao', ''));
      Unidade := 'G';
      Origem := UpperCase(JsonString(Item, 'origem', ''));
      Original := JsonString(Item, 'original', '');
      Quantidade := JsonFloat(Item, 'quantidade', 1);

      if Descricao = '' then
      begin
        Inc(Ignorados);
        Continue;
      end;

      IngredienteID := JsonInt(Item, 'id', 0);
      if IngredienteID = 0 then
        IngredienteID := BuscarIngredienteID(Conexao, Descricao);

      if IngredienteID = 0 then
        InserirIngrediente(Conexao, Descricao, Unidade, Quantidade,
          IngredienteID);

      if SameText(Origem, 'EXTRA') and (IngredienteID > 0) then
        AtualizarAdicional(Conexao, Original, IngredienteID, Quantidade);

      Inc(Gravados);
    end;

    Result.AddPair('success', True);
    Result.AddPair('gravados', Gravados);
    Result.AddPair('ignorados', Ignorados);
  except
    on E: Exception do
    begin
      Result.Free;
      Result := TJSONObject.Create;
      Result.AddPair('success', False);
      Result.AddPair('message', E.Message);
    end;
  end;

  if Assigned(Conexao) then
    Conexao.Free;
  if Assigned(JSON) then
    JSON.Free;
  TMonitor.Exit(ProcessLock);
end;

function JaExisteAlertaIngredientesPendentes(Conexao: TConexao): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  Qry := Conexao.CriaQRY;
  try
    Qry.SQL.Add('SELECT id FROM alerta_sistema');
    Qry.SQL.Add('WHERE tipo = ''SISTEMA''');
    Qry.SQL.Add('  AND origem = ''SISTEMA''');
    Qry.SQL.Add('  AND data_evento >= DATE_SUB(NOW(), INTERVAL 7 DAY)');
    Qry.SQL.Add
      ('  AND CAST(payload AS CHAR) LIKE ''%INGREDIENTES_PENDENTES%''');
    Qry.SQL.Add('LIMIT 1');
    Qry.Open;
    Result := not Qry.Eof;
  finally
    Qry.Free;
  end;
end;

procedure RegistrarAlertaIngredientesPendentes(Conexao: TConexao;
  Quantidade: Integer);
var
  Mensagem: string;
begin
  Mensagem := Quantidade.ToString +
    ' ingredientes identificados pendente de cadastro acesse o menu PRODUTOS > INGREDIENTES e aprove o cadastro';

  Conexao.SQL.Add('INSERT INTO alerta_sistema');
  Conexao.SQL.Add('(tipo, origem, referencia_id, payload)');
  Conexao.SQL.Add('VALUES (''SISTEMA'', ''SISTEMA'', NULL,');
  Conexao.SQL.Add
    ('JSON_OBJECT(''codigo'', ''INGREDIENTES_PENDENTES'', ''mensagem'', :mensagem, ''quantidade'', :quantidade, ''rota'', ''/v2/ingredientes/cardapio/processar''))');
  Conexao.Parametros('mensagem', Mensagem);
  Conexao.Parametros('quantidade', Quantidade);
  Conexao.ExecuteSQL;
end;

function ValidarAlertaIngredientesPendentes: TJSONObject;
var
  Preview: TJSONObject;
  Conexao: TConexao;
  Novos: Integer;
  Criado: Boolean;
begin
  Preview := ProcessarIngredientesCardapio;
  Conexao := nil;
  Result := TJSONObject.Create;
  Criado := False;
  try
    Novos := JsonInt(Preview, 'novos', 0);

    if Novos > 0 then
    begin
      Conexao := TConexao.Create('AlertaIngredientesPendentes');
      if not JaExisteAlertaIngredientesPendentes(Conexao) then
      begin
        RegistrarAlertaIngredientesPendentes(Conexao, Novos);
        Criado := True;
      end;
    end;

    Result.AddPair('success', True);
    Result.AddPair('pendentes', Novos);
    Result.AddPair('alertaCriado', Criado);
  except
    on E: Exception do
    begin
      Result.Free;
      Result := TJSONObject.Create;
      Result.AddPair('success', False);
      Result.AddPair('message', E.Message);
    end;
  end;

  if Assigned(Conexao) then
    Conexao.Free;
  Preview.Free;
end;

initialization
  ProcessLock := TObject.Create;

finalization
  ProcessLock.Free;

end.
