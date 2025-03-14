unit ControllerGooPedirAPI;

interface

uses
  System.SysUtils, System.Classes, Data.Bind.Components, Data.Bind.ObjectScope, uRequisicao;


implementation

uses
  System.JSON;

type
  TGooPedirAPIController = class
  private
    FRequisicao: iRequisicao;
    FBaseURL: string;
    FClientID : String;
    FClientSecret: String;
    FClientToken : Boolean;
    FToken: string;
    FName : String;
    FUserID : Integer;
    procedure ConfigureRESTClient;
    procedure BuscarToken;
  public
    constructor Create(const ABaseURL, ClientId, ClientSecret: string);
    destructor Destroy; override;
    function GetToken: string;
    function Name : String;
    function UserID : Integer;

  end;

{ TGooPedirAPIController }

procedure TGooPedirAPIController.BuscarToken;
var
JsonObject : TJsonObject;
begin

try
  FRequisicao.Execute;
  JsonObject := TJsonObject.ParseJSONValue(FRequisicao.Retorno) as TJsonObject;

  FUserID := JsonObject.GetValue<Integer>('user');
  FName := JsonObject.GetValue<String>('name');
  FToken := JsonObject.GetValue<String>('token');

except
  FClientToken := False;
end;

end;

procedure TGooPedirAPIController.ConfigureRESTClient;
begin

if not Assigned(FRequisicao) then
FRequisicao := iRequisicao.Create(nil);
FRequisicao.BaseURL := FBaseURL;
FRequisicao.AddHEader('client-id',FClientID);
FRequisicao.AddHEader('client-security',FClientSecret);
FRequisicao.URL := 'api/goopedir/token';
FRequisicao.TempoExpiracao := 20 * 1000;


end;

constructor TGooPedirAPIController.Create(const ABaseURL, ClientId, ClientSecret: string);
begin
  FBaseURL := ABaseURL;
  FClientID := ClientId;
  FClientSecret := ClientSecret;
end;

destructor TGooPedirAPIController.Destroy;
begin

  inherited;
end;

function TGooPedirAPIController.GetToken: string;
begin
Result := FToken;
end;

function TGooPedirAPIController.Name: String;
begin
Result := FName;
end;

function TGooPedirAPIController.UserID: Integer;
begin
Result := FUserID;
end;

end.

