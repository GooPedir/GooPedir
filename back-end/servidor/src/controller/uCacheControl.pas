//unit uCacheControl;
//
//interface
//
//uses
//  SysUtils, IOUtils, System.JSON, Conexao;
//
//procedure GravaCache(Origem, Chave, Dados: String);
//function BuscaCache(Origem, Chave: String): TJSONArray;
//function BuscaCacheObject(Origem, Chave: String): TJsonObject;
//procedure LimpaCache(Origem, Chave: String);
//procedure ClearAll;
//
//implementation
//
//uses
//  System.Classes, Vcl.Dialogs;
//
//procedure GravaCache(Origem, Chave, Dados: String);
//var
//  CaminhoExecutavel: string;
//  PastaCache: string;
//  CaminhoArquivo: string;
//  StringStream: TStringStream;
//begin
//
//  try
//    CaminhoExecutavel := ExtractFilePath(ParamStr(0));
//    PastaCache := CaminhoExecutavel + 'cache';
//
//    // Cria a pasta cache, caso não exista
//    if not DirectoryExists(PastaCache) then
//      ForceDirectories(PastaCache);
//
//    // Define o caminho completo do arquivo
//    CaminhoArquivo := TPath.Combine(PastaCache, Origem + Chave + '.txt');
//
//    // Grava o conteúdo no arquivo com encoding UTF-8
//    StringStream := TStringStream.Create(Dados, TEncoding.UTF8);
//    try
//      StringStream.SaveToFile(CaminhoArquivo);
//    finally
//      StringStream.Free;
//    end;
//  except
//
//  end;
//end;
//
//function BuscaCacheObject(Origem, Chave: String): TJsonObject;
//var
//  CaminhoExecutavel: string;
//  PastaCache: string;
//  CaminhoArquivo: string;
//  NomeArquivo: string;
//  StringStream: TStringStream;
//  Conteudo: string;
//  Conexao: Tconexao;
//begin
//  Conexao := Tconexao.Create('BuscaCacheObject');
//  NomeArquivo := Origem + Chave + '.txt';
//
//  // Obtém o caminho do executável
//  CaminhoExecutavel := ExtractFilePath(ParamStr(0));
//
//  // Define o caminho da pasta cache
//  PastaCache := CaminhoExecutavel + 'cache';
//
//  // Define o caminho completo do arquivo
//  CaminhoArquivo := TPath.Combine(PastaCache, NomeArquivo);
//
//  // Verifica se o arquivo existe
//  if not FileExists(CaminhoArquivo) then
//  begin
//    Result := TJsonObject.Create;
//    Exit;
//  end;
//
//  // Lê o conteúdo do arquivo com encoding UTF-8
//  StringStream := TStringStream.Create('', TEncoding.UTF8);
//  try
//    StringStream.LoadFromFile(CaminhoArquivo);
//    Conteudo := StringStream.DataString;
//
//    // Tenta parsear o conteúdo como JSON
//    try
//      Result := TJsonObject.ParseJSONValue(Conteudo) as TJsonObject;
//    except
//      Result := TJsonObject.Create;
//    end;
//  finally
//    StringStream.Free;
//  end;
//end;
//
//function BuscaCache(Origem, Chave: String): TJSONArray;
//var
//  CaminhoExecutavel: string;
//  PastaCache: string;
//  CaminhoArquivo: string;
//  NomeArquivo: string;
//  StringStream: TStringStream;
//  Conteudo: string;
//begin
//
//  Result := TJSONArray.Create;
//
//  NomeArquivo := Origem + Chave + '.txt';
//
//  // Obtém o caminho do executável
//  CaminhoExecutavel := ExtractFilePath(ParamStr(0));
//
//  // Define o caminho da pasta cache
//  PastaCache := CaminhoExecutavel + 'cache';
//
//  // Define o caminho completo do arquivo
//  CaminhoArquivo := TPath.Combine(PastaCache, NomeArquivo);
//
//  // Verifica se o arquivo existe
//  if not FileExists(CaminhoArquivo) then
//  begin
//    Result := TJSONArray.Create;
//    Exit;
//  end;
//
//  // Lê o conteúdo do arquivo com encoding UTF-8
//  StringStream := TStringStream.Create('', TEncoding.UTF8);
//  try
//    StringStream.LoadFromFile(CaminhoArquivo);
//    Conteudo := StringStream.DataString;
//
//    // Tenta parsear o conteúdo como JSON
//    try
//      Result := TJsonObject.ParseJSONValue(Conteudo) as TJSONArray;
//    except
//      Result := TJSONArray.Create;
//    end;
//  finally
//    StringStream.Free;
//  end;
//end;
//
//procedure LimpaCache(Origem, Chave: String);
//var
//  NomeArquivo: String;
//  CaminhoExecutavel: String;
//  PastaCache: String;
//begin
//  NomeArquivo := Origem + Chave + '.txt';
//
//  // Obtém o caminho do executável
//  CaminhoExecutavel := ExtractFilePath(ParamStr(0));
//
//  // Define o caminho da pasta cache
//  PastaCache := CaminhoExecutavel + 'cache\';
//
//  if FileExists(PastaCache + NomeArquivo) then
//  begin
//    DeleteFile(PastaCache + NomeArquivo);
//  end;
//
//end;
//
//procedure ClearAll;
//var
//  CaminhoExecutavel: String;
//  PastaCache: String;
//begin
//
//  // Obtém o caminho do executável
//  CaminhoExecutavel := ExtractFilePath(ParamStr(0));
//
//  // Define o caminho da pasta cache
//  PastaCache := CaminhoExecutavel + 'cache\';
//
//  try
//    TDirectory.Delete(PastaCache, True);
//  except
//
//  end;
//end;
//
//end.

unit uCacheControl;

interface

uses
  System.SysUtils,
  System.JSON;

procedure GravaCache(Origem, Chave, Dados: String);
function BuscaCache(Origem, Chave: String): TJSONArray;
function BuscaCacheObject(Origem, Chave: String): TJsonObject;
procedure LimpaCache(Origem, Chave: String);
procedure ClearAll;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SyncObjs;

var
  CacheLock: TObject;

function GetCacheFile(Origem, Chave: String): String;
var
  PastaCache: string;
begin
  PastaCache := TPath.Combine(ExtractFilePath(ParamStr(0)), 'cache');

  if not DirectoryExists(PastaCache) then
    ForceDirectories(PastaCache);

  Result := TPath.Combine(PastaCache, Origem + Chave + '.txt');
end;

procedure GravaCache(Origem, Chave, Dados: String);
var
  CaminhoArquivo, TempFile: string;
  StringStream: TStringStream;
begin
  TMonitor.Enter(CacheLock);
  try
    CaminhoArquivo := GetCacheFile(Origem, Chave);
    TempFile := CaminhoArquivo + '.tmp';

    StringStream := TStringStream.Create(Dados, TEncoding.UTF8);
    try
      StringStream.SaveToFile(TempFile);

      // substituição atômica
      if FileExists(CaminhoArquivo) then
        DeleteFile(CaminhoArquivo);

      RenameFile(TempFile, CaminhoArquivo);
    finally
      StringStream.Free;
    end;

  except
    // aqui você pode logar se quiser
  end;
  TMonitor.Exit(CacheLock);
end;

function BuscaCacheObject(Origem, Chave: String): TJsonObject;
var
  CaminhoArquivo: string;
  StringStream: TStringStream;
  Conteudo: string;
begin
  CaminhoArquivo := GetCacheFile(Origem, Chave);

  if not FileExists(CaminhoArquivo) then
    Exit(TJsonObject.Create);

  TMonitor.Enter(CacheLock);
  try
    StringStream := TStringStream.Create('', TEncoding.UTF8);
    try
      StringStream.LoadFromFile(CaminhoArquivo);
      Conteudo := StringStream.DataString;

      try
        Result := TJsonObject.ParseJSONValue(Conteudo) as TJsonObject;
        if Result = nil then
          Result := TJsonObject.Create;
      except
        Result := TJsonObject.Create;
      end;

    finally
      StringStream.Free;
    end;
  finally
    TMonitor.Exit(CacheLock);
  end;
end;

function BuscaCache(Origem, Chave: String): TJSONArray;
var
  CaminhoArquivo: string;
  StringStream: TStringStream;
  Conteudo: string;
begin
  CaminhoArquivo := GetCacheFile(Origem, Chave);

  if not FileExists(CaminhoArquivo) then
    Exit(TJSONArray.Create);

  TMonitor.Enter(CacheLock);
  try
    StringStream := TStringStream.Create('', TEncoding.UTF8);
    try
      StringStream.LoadFromFile(CaminhoArquivo);
      Conteudo := StringStream.DataString;

      try
        Result := TJSONObject.ParseJSONValue(Conteudo) as TJSONArray;
        if Result = nil then
          Result := TJSONArray.Create;
      except
        Result := TJSONArray.Create;
      end;

    finally
      StringStream.Free;
    end;
  finally
    TMonitor.Exit(CacheLock);
  end;
end;

procedure LimpaCache(Origem, Chave: String);
var
  CaminhoArquivo: String;
begin
  CaminhoArquivo := GetCacheFile(Origem, Chave);

  TMonitor.Enter(CacheLock);
  try
    if FileExists(CaminhoArquivo) then
      DeleteFile(CaminhoArquivo);
  finally
    TMonitor.Exit(CacheLock);
  end;
end;

procedure ClearAll;
var
  PastaCache: String;
begin
  PastaCache := TPath.Combine(ExtractFilePath(ParamStr(0)), 'cache');

  TMonitor.Enter(CacheLock);
  try
    if DirectoryExists(PastaCache) then
      TDirectory.Delete(PastaCache, True);
  except
  end;
  TMonitor.Exit(CacheLock);
end;

initialization
  CacheLock := TObject.Create;

finalization
  CacheLock.Free;

end.
