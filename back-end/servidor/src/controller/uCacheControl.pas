unit uCacheControl;

interface

uses
  System.SysUtils,
  System.JSON;

procedure GravaCache(Origem, Chave, Dados: String; ValidadeMinutos: Integer = 5);
function BuscaCache(Origem, Chave: String): TJSONArray;
function BuscaCacheObject(Origem, Chave: String): TJsonObject;
procedure LimpaCache(Origem, Chave: String);
procedure ClearAll;

implementation

uses
  System.SyncObjs,
  FireDAC.Comp.Client,
  conexao;

const
  CACHE_DATABASE = 'goopedir_cache';
  CACHE_TABLE = 'cache';
  CACHE_VALIDADE_PADRAO_MINUTOS = 5;

var
  CacheLock: TObject;
  CacheInicializado: Boolean = False;

procedure GarantirBancoCache;
var
  Con: Tconexao;
begin
  if CacheInicializado then
    Exit;

  TMonitor.Enter(CacheLock);
  try
    if CacheInicializado then
      Exit;

    Con := Tconexao.Create('GarantirBancoCache');
    try
      Con.ExecuteSQL('CREATE DATABASE IF NOT EXISTS ' + CACHE_DATABASE +
        ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
      Con.ExecuteSQL('CREATE TABLE IF NOT EXISTS ' + CACHE_DATABASE + '.' +
        CACHE_TABLE + ' (' +
        'origem VARCHAR(100) NOT NULL, ' +
        'chave VARCHAR(255) NOT NULL, ' +
        'dados LONGTEXT NOT NULL, ' +
        'criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, ' +
        'expira_em DATETIME NULL, ' +
        'atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, '
        + 'PRIMARY KEY (origem, chave), ' +
        'INDEX idx_cache_expira (expira_em), ' +
        'INDEX idx_cache_atualizado (atualizado_em)' +
        ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
      CacheInicializado := True;
    finally
      Con.Free;
    end;
  finally
    TMonitor.Exit(CacheLock);
  end;
end;

function NormalizaValidade(ValidadeMinutos: Integer): Integer;
begin
  Result := ValidadeMinutos;
  if Result <= 0 then
    Result := CACHE_VALIDADE_PADRAO_MINUTOS;
end;

procedure GravaCache(Origem, Chave, Dados: String; ValidadeMinutos: Integer);
var
  Con: Tconexao;
begin
  try
    GarantirBancoCache;
      Con := Tconexao.Create('GravaCache');
    try
      Con.SQL.Add('INSERT INTO ' + CACHE_DATABASE + '.' + CACHE_TABLE);
      Con.SQL.Add('(origem, chave, dados, expira_em)');
      Con.SQL.Add('VALUES (:origem, :chave, :dados, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL ' +
        NormalizaValidade(ValidadeMinutos).ToString + ' MINUTE))');
      Con.SQL.Add('ON DUPLICATE KEY UPDATE dados = VALUES(dados),');
      Con.SQL.Add('expira_em = VALUES(expira_em),');
      Con.SQL.Add('atualizado_em = CURRENT_TIMESTAMP');
      Con.Parametros('origem', Origem);
      Con.Parametros('chave', Chave);
      Con.Parametros('dados', Dados);
      Con.ExecuteSQL;
    finally
      Con.Free;
    end;
  except
  end;
end;

function LerCacheTexto(Origem, Chave: String): String;
var
  Con: Tconexao;
  Qry: TFDQuery;
begin
  Result := '';
  try
    GarantirBancoCache;
    Con := Tconexao.Create('LerCacheTexto');
    try
      Qry := Con.CriaQRY;
      try
        Qry.SQL.Text := 'SELECT dados FROM ' + CACHE_DATABASE + '.' +
          CACHE_TABLE + ' WHERE origem = :origem AND chave = :chave' +
          ' AND (expira_em IS NULL OR expira_em > CURRENT_TIMESTAMP)';
        Qry.ParamByName('origem').AsString := Origem;
        Qry.ParamByName('chave').AsString := Chave;
        Qry.Open;
        if not Qry.Eof then
          Result := Qry.FieldByName('dados').AsString;
        if Result = '' then
        begin
          Qry.Close;
          Qry.SQL.Text := 'DELETE FROM ' + CACHE_DATABASE + '.' + CACHE_TABLE +
            ' WHERE origem = :origem AND chave = :chave' +
            ' AND expira_em <= CURRENT_TIMESTAMP';
          Qry.ParamByName('origem').AsString := Origem;
          Qry.ParamByName('chave').AsString := Chave;
          Qry.ExecSQL;
        end;
      finally
        Qry.Free;
      end;
    finally
      Con.Free;
    end;
  except
    Result := '';
  end;
end;

function BuscaCacheObject(Origem, Chave: String): TJsonObject;
var
  Conteudo: String;
  ValorJSON: TJSONValue;
begin
  Conteudo := LerCacheTexto(Origem, Chave);
  if Conteudo = '' then
    Exit(TJsonObject.Create);

  try
    ValorJSON := TJSONObject.ParseJSONValue(Conteudo);
    if ValorJSON is TJsonObject then
      Result := TJsonObject(ValorJSON)
    else
    begin
      ValorJSON.Free;
      Result := TJsonObject.Create;
    end;
  except
    Result := TJsonObject.Create;
  end;
end;

function BuscaCache(Origem, Chave: String): TJSONArray;
var
  Conteudo: String;
  ValorJSON: TJSONValue;
begin
  Conteudo := LerCacheTexto(Origem, Chave);
  if Conteudo = '' then
    Exit(TJSONArray.Create);

  try
    ValorJSON := TJSONObject.ParseJSONValue(Conteudo);
    if ValorJSON is TJSONArray then
      Result := TJSONArray(ValorJSON)
    else
    begin
      ValorJSON.Free;
      Result := TJSONArray.Create;
    end;
  except
    Result := TJSONArray.Create;
  end;
end;

procedure LimpaCache(Origem, Chave: String);
var
  Con: Tconexao;
begin
  try
    GarantirBancoCache;
    Con := Tconexao.Create('LimpaCache');
    try
      Con.SQL.Add('DELETE FROM ' + CACHE_DATABASE + '.' + CACHE_TABLE);
      Con.SQL.Add('WHERE origem = :origem AND chave = :chave');
      Con.Parametros('origem', Origem);
      Con.Parametros('chave', Chave);
      Con.ExecuteSQL;
    finally
      Con.Free;
    end;
  except
  end;
end;

procedure ClearAll;
var
  Con: Tconexao;
begin
  try
    GarantirBancoCache;
    Con := Tconexao.Create('ClearAllCache');
    try
      Con.ExecuteSQL('TRUNCATE TABLE ' + CACHE_DATABASE + '.' + CACHE_TABLE);
    finally
      Con.Free;
    end;
  except
  end;
end;

initialization
  CacheLock := TObject.Create;

finalization
  CacheLock.Free;

end.
