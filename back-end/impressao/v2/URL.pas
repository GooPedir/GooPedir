unit URL;

interface

function UrlGoopedir : String;

implementation

function UrlGoopedir : String;
begin
  Result := 'http://localhost:3000/';
  //Result := 'https://api.goopedir.com.br/';
  //Result := 'https://site-api-v2.goopedir.com/';
end;


end.
