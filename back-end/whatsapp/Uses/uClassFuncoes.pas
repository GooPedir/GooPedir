unit uClassFuncoes;

interface

uses REST.Client, REST.Response.Adapter, FireDAC.Comp.Client, SysUtils, Dialogs;

type
  TCEP = class
  private
    FBairro: String;
    FCEP: String;
    FCidade: String;
    FEstado: String;
    FRua: String;
    FAchou: Boolean;
    procedure SetBairro(const Value: String);
    procedure SetCEP(const Value: String);
    procedure SetCidade(const Value: String);
    procedure SetEstado(const Value: String);
    procedure SetRua(const Value: String);

    function SoNumero(fField: String): String;
    procedure SetAchou(const Value: Boolean);

    function ValidaDados: Boolean;

  public
    property CEP: String read FCEP write SetCEP;
    property Rua: String read FRua write SetRua;
    property Bairro: String read FBairro write SetBairro;
    property Cidade: String read FCidade write SetCidade;
    Property Estado: String read FEstado write SetEstado;
    property Achou: Boolean read FAchou write SetAchou;
    function BuscaCep(CEP: String): TCEP;
    function ValidaCEP(CEP: String): Boolean;
  end;

implementation

{ TCEP }

uses uClassAPIGooleLocalizacao;

function TCEP.BuscaCep(CEP: String): TCEP;
var
  RESTClient: TRESTClient;
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;
  RESTResponseDataSetAdapter: TRESTResponseDataSetAdapter;
  FDMemTable1: TFDMemTable;

  Google: TGoogleAPI;
begin
  if Result = nil then
    Result := TCEP.Create;
  if Google = nil then
    Google := TGoogleAPI.Create;

  Result.CEP := CEP;
  if not ValidaCEP(CEP) then
  begin
    Result.Achou := False;
    exit;
  end;

  RESTClient := TRESTClient.Create(nil);

  RESTClient.FallbackCharsetEncoding := 'UTF-8';
  RESTClient.HandleRedirects := True;

  RESTResponse := TRESTResponse.Create(nil);

  RESTRequest := TRESTRequest.Create(nil);
  RESTRequest.Client := RESTClient;
  RESTRequest.Response := RESTResponse;

  FDMemTable1 := TFDMemTable.Create(nil);

  RESTResponseDataSetAdapter := TRESTResponseDataSetAdapter.Create(nil);
  RESTResponseDataSetAdapter.DataSet := FDMemTable1;
  RESTResponseDataSetAdapter.Response := RESTResponse;
  RESTResponseDataSetAdapter.Active := True;

  RESTClient.BaseURL := 'http://viacep.com.br/ws/' + Result.CEP + '/json/';
  RESTRequest.Execute;
  Result.Achou := False;
  if RESTResponse.StatusCode = 200 then
  begin
    try
    try
      if uppercase(FDMemTable1.FieldByName('erro').AsString) = 'TRUE' then
      begin
        Result.Achou := False;

        RESTClient.Free;
        RESTResponse.Free;
        RESTRequest.Free;
        RESTResponseDataSetAdapter.Free;
        FDMemTable1.Free;
        exit;
      end;
    except

    end;

      Result.Achou := True;
      try
        Result.Rua := Google.RemoveCaracteresEndereco
          (FDMemTable1.FieldByName('logradouro').AsString);
      except

      end;

      try
        Result.Bairro := Google.RemoveCaracteresEndereco
          (FDMemTable1.FieldByName('bairro').AsString);
      except

      end;
      try
        Result.Cidade := Google.RemoveCaracteresEndereco
          (FDMemTable1.FieldByName('localidade').AsString);
      except

      end;
      try
        Result.Estado := Google.RemoveCaracteresEndereco
          (FDMemTable1.FieldByName('uf').AsString);
      except

      end;
      // Result.Achou := ValidaDados;

    except
      Result.Achou := False;

    end;
  end;

  RESTClient.Free;
  RESTResponse.Free;
  RESTRequest.Free;
  RESTResponseDataSetAdapter.Free;
  FDMemTable1.Free;

end;

procedure TCEP.SetAchou(const Value: Boolean);
begin
  FAchou := Value;
end;

procedure TCEP.SetBairro(const Value: String);
begin
  FBairro := Value;
end;

procedure TCEP.SetCEP(const Value: String);
begin
  FCEP := SoNumero(Value);
end;

procedure TCEP.SetCidade(const Value: String);
begin
  FCidade := Value;
end;

procedure TCEP.SetEstado(const Value: String);
begin
  FEstado := Value;
end;

procedure TCEP.SetRua(const Value: String);
begin
  FRua := Value;
end;

function TCEP.SoNumero(fField: String): String;
var
  I: Byte;
begin
  Result := '';
  for I := 1 To length(fField) do
    if fField[I] In ['0' .. '9'] Then
      Result := Result + fField[I];
end;

function TCEP.ValidaCEP(CEP: String): Boolean;
begin
  CEP := SoNumero(CEP);
  if length(CEP) = 8 then
    Result := True;
end;

function TCEP.ValidaDados: Boolean;
begin
  if Rua = '' then
  begin
    Achou := False;
    exit;
  end;
  if Bairro = '' then
  begin
    Achou := False;
    exit;
  end;
  if Cidade = '' then
  begin
    Achou := False;
    exit;
  end;
  if Estado = '' then
  begin
    Achou := False;
    exit;
  end;

  Achou := True;
end;

end.
