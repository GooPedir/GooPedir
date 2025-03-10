unit uLogThread;

interface

procedure LogThread(Nome,Msg : String);

implementation

uses
  System.Classes, System.SysUtils;

procedure LogThread(Nome,Msg : String);
var
  LogFile: TStringList;
  FLogFileName : String;
begin
 FLogFileName := 'logThread1.txt';;
  LogFile := TStringList.Create;
  try
    if FileExists(FLogFileName) then
      LogFile.LoadFromFile(FLogFileName);
    LogFile.Add(Format('%s: %s - %s', [DateTimeToStr(Now), Nome, Msg]));
    LogFile.SaveToFile(FLogFileName);
  finally
    LogFile.Free;
  end;
end;

end.
