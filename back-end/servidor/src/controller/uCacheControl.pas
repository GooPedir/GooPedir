unit uCacheControl;

interface

uses
  System.SysUtils,
  System.JSON;

procedure GravaCache(Origem, Chave, Dados: String;
  ValidadeMinutos: Integer = 5);
function BuscaCache(Origem, Chave: String): TJSONArray;
function BuscaCacheObject(Origem, Chave: String): TJsonObject;
procedure LimpaCache(Origem, Chave: String);
procedure ClearAll;

implementation

uses
  Winapi.Windows,
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

procedure AplicarCharsetCache(Con: Tconexao);
begin
  // Charset ja e configurado na conexao FireDAC. Evita SET NAMES em toda chamada.
end;

procedure GarantirBancoCache;
var
  Con: Tconexao;
  Inicio: UInt64;
  LockInicio: UInt64;
  HoldInicio: UInt64;
begin
  if CacheInicializado then
    Exit;

  LockInicio := GetTickCount64;
  TMonitor.Enter(CacheLock);

  HoldInicio := GetTickCount64;
  try
    if CacheInicializado then
      Exit;

    Inicio := GetTickCount64;
    Con := Tconexao.Create('GarantirBancoCache');

    try
      Inicio := GetTickCount64;
      AplicarCharsetCache(Con);

      Inicio := GetTickCount64;
      Con.ExecuteSQL('CREATE DATABASE IF NOT EXISTS ' + CACHE_DATABASE +
        ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
      Con.ExecuteSQL('ALTER DATABASE ' + CACHE_DATABASE +
        ' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
      Con.ExecuteSQL('CREATE TABLE IF NOT EXISTS ' + CACHE_DATABASE + '.' +
        CACHE_TABLE + ' (' + 'origem VARCHAR(100) NOT NULL, ' +
        'chave VARCHAR(255) NOT NULL, ' + 'dados LONGTEXT NOT NULL, ' +
        'criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, ' +
        'expira_em DATETIME NULL, ' +
        'atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, '
        + 'PRIMARY KEY (origem, chave), ' +
        'INDEX idx_cache_expira (expira_em), ' +
        'INDEX idx_cache_atualizado (atualizado_em)' +
        ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
      Con.ExecuteSQL('ALTER TABLE ' + CACHE_DATABASE + '.' + CACHE_TABLE +
        ' CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
      Con.ExecuteSQL('ALTER TABLE ' + CACHE_DATABASE + '.' + CACHE_TABLE +
        ' MODIFY dados LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL');

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
  Inicio: UInt64;
begin
  try
    Inicio := GetTickCount64;
    GarantirBancoCache;

    Inicio := GetTickCount64;
    Con := Tconexao.Create('GravaCache');
    try
      Inicio := GetTickCount64;
      AplicarCharsetCache(Con);
      Inicio := GetTickCount64;
      Con.SQL.Add('INSERT INTO ' + CACHE_DATABASE + '.' + CACHE_TABLE);
      Con.SQL.Add('(origem, chave, dados, expira_em)');
      Con.SQL.Add
        ('VALUES (:origem, :chave, :dados, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL '
        + NormalizaValidade(ValidadeMinutos).ToString + ' MINUTE))');
      Con.SQL.Add('ON DUPLICATE KEY UPDATE dados = VALUES(dados),');
      Con.SQL.Add('expira_em = VALUES(expira_em),');
      Con.SQL.Add('atualizado_em = CURRENT_TIMESTAMP');
      Con.Parametros('origem', Origem);
      Con.Parametros('chave', Chave);
      Con.Parametros('dados', Dados);
      Inicio := GetTickCount64;
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
  Inicio: UInt64;
begin
  Result := '';
  try
    Inicio := GetTickCount64;
    GarantirBancoCache;
    Inicio := GetTickCount64;
    Con := Tconexao.Create('LerCacheTexto');
    try
      Inicio := GetTickCount64;
      AplicarCharsetCache(Con);
      Inicio := GetTickCount64;
      Qry := Con.CriaQRY;
      try
        Inicio := GetTickCount64;
        Qry.SQL.Text := 'SELECT dados FROM ' + CACHE_DATABASE + '.' +
          CACHE_TABLE + ' WHERE origem = :origem AND chave = :chave' +
          ' AND (expira_em IS NULL OR expira_em > CURRENT_TIMESTAMP)';
        Qry.ParamByName('origem').AsString := Origem;
        Qry.ParamByName('chave').AsString := Chave;

        Inicio := GetTickCount64;
        Qry.Open;
        if not Qry.Eof then
        begin
          Inicio := GetTickCount64;
          Result := Qry.FieldByName('dados').AsWideString;
        end;
        if Result = '' then
        begin
          Inicio := GetTickCount64;
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
  Inicio: UInt64;
begin
  Inicio := GetTickCount64;
  Conteudo := LerCacheTexto(Origem, Chave);
  if Conteudo = '' then
    Exit(TJsonObject.Create);

  try
    Inicio := GetTickCount64;
    ValorJSON := TJsonObject.ParseJSONValue(Conteudo);
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
  Inicio: UInt64;
begin
  Inicio := GetTickCount64;
  Conteudo := LerCacheTexto(Origem, Chave);
  if Conteudo = '' then
    Exit(TJSONArray.Create);

  try
    Inicio := GetTickCount64;
    ValorJSON := TJsonObject.ParseJSONValue(Conteudo);
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
  Inicio: UInt64;
begin
  try
    Inicio := GetTickCount64;
    GarantirBancoCache;
    Inicio := GetTickCount64;
    Con := Tconexao.Create('LimpaCache');
    try
      Inicio := GetTickCount64;
      AplicarCharsetCache(Con);
      Inicio := GetTickCount64;
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
  Inicio: UInt64;
begin
  try
    Inicio := GetTickCount64;
    GarantirBancoCache;
    Inicio := GetTickCount64;
    Con := Tconexao.Create('ClearAllCache');
    try
      Inicio := GetTickCount64;
      AplicarCharsetCache(Con);
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
