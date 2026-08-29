unit uUpdaterPackage;

interface

uses System.SysUtils;

type
  EUpdaterPackageError = class(Exception);

  TPackageCacheInfo = record
    ReleaseId, Version, Sha256, PackageFile: string;
    SizeBytes: Int64;
  end;

  TManifestFile = record
    Source, Destination, Sha256: string;
  end;

  TPackageManifest = record
    ReleaseId, ProductCode, Channel, Version, EntryPoint: string;
    Files: TArray<TManifestFile>;
  end;

function LoadPackageCacheInfo(const FileName: string): TPackageCacheInfo;
function LoadPackageManifest(const FileName: string): TPackageManifest;
procedure ValidateCachedPackage(const Cache: TPackageCacheInfo;
  const ExpectedReleaseId: string);
procedure ValidateManifest(const Manifest: TPackageManifest;
  const ExpectedReleaseId, ProductCode, Channel: string);
procedure ValidateManifestFiles(const Manifest: TPackageManifest;
  const StagingDirectory: string);

implementation

uses System.IOUtils, System.JSON, System.Generics.Collections, uUpdaterFiles;

function LoadJson(const FileName: string): TJSONObject;
begin
  if not TFile.Exists(FileName) then
    raise EUpdaterPackageError.Create('Arquivo nao encontrado: ' + FileName);
  Result := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(FileName, TEncoding.UTF8)) as TJSONObject;
  if not Assigned(Result) then
    raise EUpdaterPackageError.Create('JSON invalido: ' + FileName);
end;

function RequiredString(Json: TJSONObject; const Name: string): string;
begin
  if not Json.TryGetValue<string>(Name, Result) or (Result.Trim = '') then
    raise EUpdaterPackageError.Create('Campo obrigatorio nao informado: ' + Name);
  Result := Result.Trim;
end;

function LoadPackageCacheInfo(const FileName: string): TPackageCacheInfo;
var
  Json: TJSONObject;
begin
  Result := Default(TPackageCacheInfo);
  Json := LoadJson(FileName);
  try
    Result.ReleaseId := RequiredString(Json, 'releaseId');
    Result.Version := RequiredString(Json, 'version');
    Result.Sha256 := RequiredString(Json, 'sha256').ToLower;
    Result.PackageFile := RequiredString(Json, 'packageFile');
    if not Json.TryGetValue<Int64>('sizeBytes', Result.SizeBytes) then
      raise EUpdaterPackageError.Create('Campo obrigatorio nao informado: sizeBytes');
  finally
    Json.Free;
  end;
end;

function LoadPackageManifest(const FileName: string): TPackageManifest;
var
  Json: TJSONObject;
  FilesJson: TJSONArray;
  FileJson: TJSONObject;
  I: Integer;
begin
  Result := Default(TPackageManifest);
  Json := LoadJson(FileName);
  try
    Result.ReleaseId := RequiredString(Json, 'releaseId');
    Result.ProductCode := RequiredString(Json, 'product');
    Result.Channel := RequiredString(Json, 'channel');
    Result.Version := RequiredString(Json, 'version');
    Json.TryGetValue<string>('entryPoint', Result.EntryPoint);
    FilesJson := Json.GetValue<TJSONArray>('files');
    if not Assigned(FilesJson) or (FilesJson.Count = 0) then
      raise EUpdaterPackageError.Create('O manifesto nao contem arquivos');
    SetLength(Result.Files, FilesJson.Count);
    for I := 0 to FilesJson.Count - 1 do
    begin
      FileJson := FilesJson.Items[I] as TJSONObject;
      if not Assigned(FileJson) then
        raise EUpdaterPackageError.CreateFmt('Entrada files[%d] invalida', [I]);
      Result.Files[I].Source := RequiredString(FileJson, 'source');
      Result.Files[I].Destination := RequiredString(FileJson, 'destination');
      Result.Files[I].Sha256 := RequiredString(FileJson, 'sha256').ToLower;
    end;
  finally
    Json.Free;
  end;
end;

function SafeRelativePath(const Root, RelativePath: string;
  out FullPath: string): Boolean;
var
  NormalizedRoot: string;
begin
  Result := False;
  if (RelativePath = '') or TPath.IsPathRooted(RelativePath) then Exit;
  NormalizedRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(Root));
  FullPath := TPath.GetFullPath(TPath.Combine(Root,
    RelativePath.Replace('/', PathDelim)));
  Result := FullPath.StartsWith(NormalizedRoot, True);
end;

procedure ValidateManifestFiles(const Manifest: TPackageManifest;
  const StagingDirectory: string);
var
  Item: TManifestFile;
  SourceFile, DestinationCheck: string;
begin
  for Item in Manifest.Files do
  begin
    if not SafeRelativePath(StagingDirectory, Item.Source, SourceFile) then
      raise EUpdaterPackageError.Create('Origem insegura no manifesto: ' + Item.Source);
    if not SafeRelativePath(StagingDirectory, Item.Destination, DestinationCheck) then
      raise EUpdaterPackageError.Create('Destino inseguro no manifesto: ' + Item.Destination);
    if not TFile.Exists(SourceFile) then
    begin
      if TFile.Exists(DestinationCheck) then
        SourceFile := DestinationCheck
      else
        raise EUpdaterPackageError.Create('Arquivo do manifesto nao encontrado: ' + Item.Source);
    end;
    if not SameText(FileSha256(SourceFile), Item.Sha256) then
      raise EUpdaterPackageError.Create('SHA-256 divergente para: ' + Item.Source);
  end;
end;

procedure ValidateCachedPackage(const Cache: TPackageCacheInfo;
  const ExpectedReleaseId: string);
begin
  if not SameText(Cache.ReleaseId, ExpectedReleaseId) then
    raise EUpdaterPackageError.Create('releaseId do cache nao corresponde ao solicitado');
  if not TFile.Exists(Cache.PackageFile) then
    raise EUpdaterPackageError.Create('Pacote nao encontrado no cache');
  if (Cache.SizeBytes > 0) and
    (TFile.GetSize(Cache.PackageFile) <> Cache.SizeBytes) then
    raise EUpdaterPackageError.Create('Tamanho do pacote em cache divergente');
  if not SameText(FileSha256(Cache.PackageFile), Cache.Sha256) then
    raise EUpdaterPackageError.Create('SHA-256 do pacote em cache divergente');
end;

procedure ValidateManifest(const Manifest: TPackageManifest;
  const ExpectedReleaseId, ProductCode, Channel: string);
begin
  if not SameText(Manifest.ReleaseId, ExpectedReleaseId) then
    raise EUpdaterPackageError.Create('releaseId do manifesto nao corresponde ao solicitado');
  if not SameText(Manifest.ProductCode, ProductCode) then
    raise EUpdaterPackageError.Create('Produto do manifesto nao corresponde a instalacao');
  if not SameText(Manifest.Channel, Channel) then
    raise EUpdaterPackageError.Create('Canal do manifesto nao corresponde a instalacao');
end;

end.
