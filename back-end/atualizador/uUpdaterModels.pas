unit uUpdaterModels;

interface

type
  TUpdateInfo = record
    Available: Boolean;
    Version, ReleaseId: string;
    Mandatory, MandatoryNow: Boolean;
    MandatoryAt, ServerTime: TDateTime;
    HasMandatoryAt, HasServerTime: Boolean;
    DownloadUrl: string;
    Sha256: string;
    SizeBytes: Int64;
    Notes: string;
  end;

implementation

end.
