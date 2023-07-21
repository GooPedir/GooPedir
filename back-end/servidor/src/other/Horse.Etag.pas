unit Horse.Etag;

{$IF DEFINED(FPC)}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
    fpjson,
  {$ELSE}
    System.SysUtils, System.Classes, System.JSON, Web.HTTPApp,
  {$ENDIF}
  Horse, Horse.Commons, IdHashMessageDigest;

procedure eTag(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});

implementation

procedure eTag(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
var
  LContent: TObject;
  Hash: TIdHashMessageDigest5;
  eTag: String;
begin
//  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Origin','*');
//  Res.RawWebResponse.SetCustomHeader('Access-Control-Allow-Methods','DELETE, POST, GET, OPTIONS');
  try
    Next;
  finally
    LContent := Res.Content;

    if Assigned(LContent) and LContent.InheritsFrom({$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}) then
    begin
      Hash := TIdHashMessageDigest5.Create;
      try
        eTag := Hash.HashStringAsHex({$IF DEFINED(FPC)}TJSONData{$ELSE}TJSONValue{$ENDIF}(LContent).ToString);
      finally
        Hash.Free;
      end;
    end;

    if (Req.Headers['If-None-Match'] = eTag) and                                                              (eTag <> '') then
      Res.Status(THTTPStatus.NotModified);

    Res.RawWebResponse.SetCustomHeader('ETag', eTag);
    //Access-Control-Allow-Origin: *
  end;

end;

end.
