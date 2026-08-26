unit uUpdaterResult;

interface

uses System.JSON;

procedure ClearOutputFiles(const ResultFile, ErrorFile: string);
procedure WriteResult(const FileName: string; Json: TJSONObject);
procedure WriteError(const FileName, MessageText: string);

implementation

uses System.SysUtils, System.IOUtils;

procedure DeleteIfExists(const FileName: string);
begin
  if (FileName <> '') and TFile.Exists(FileName) then TFile.Delete(FileName);
end;

procedure ClearOutputFiles(const ResultFile, ErrorFile: string);
begin
  DeleteIfExists(ResultFile);
  if ResultFile <> '' then DeleteIfExists(ResultFile + '.tmp');
  DeleteIfExists(ErrorFile);
  if ErrorFile <> '' then DeleteIfExists(ErrorFile + '.tmp');
end;

procedure WriteTextAtomic(const FileName, Text: string);
var
  Directory, TemporaryFile: string;
begin
  if FileName = '' then Exit;
  Directory := ExtractFilePath(FileName);
  if Directory <> '' then TDirectory.CreateDirectory(Directory);
  TemporaryFile := FileName + '.tmp';
  TFile.WriteAllText(TemporaryFile, Text, TEncoding.UTF8);
  DeleteIfExists(FileName);
  TFile.Move(TemporaryFile, FileName);
end;

procedure WriteResult(const FileName: string; Json: TJSONObject);
begin
  if Assigned(Json) then WriteTextAtomic(FileName, Json.ToJSON);
end;

procedure WriteError(const FileName, MessageText: string);
begin
  WriteTextAtomic(FileName, MessageText);
end;

end.
