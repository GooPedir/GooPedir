unit uClassAPIGooleLocalizacao;

interface

uses FireDAC.Comp.Client, uDM, uClassEndereco, REST.Client, JSON, SysUtils;

type

  TTipo = (tLocalizacao, tCEPSituacao);

  TGoogleAPI = class
  private
    FBairro: String;
    FLat: Real;
    FLong: Real;
    FTipo: TTipo;
    FCidade: String;
    FEstado: String;
    FRua: String;
    FCEP: String;
    procedure SetBairro(const Value: String);
    procedure SetCidade(const Value: String);
    procedure SetEstado(const Value: String);
    procedure SetLat(const Value: Real);
    procedure SetLong(const Value: Real);
    procedure SetRua(const Value: String);
    procedure SetTipo(const Value: TTipo);

    function Localizacao: TDadosEndereco;
    function DADOSCEP: TDadosEndereco;

    function CEPKM(Dados: TDadosEndereco): Real;
    procedure SetCEP(const Value: String);

  public
    property Lat: Real read FLat write SetLat;
    property Long: Real read FLong write SetLong;
    property CEP: String read FCEP write SetCEP;
    property Rua: String read FRua write SetRua;
    property Bairro: String read FBairro write SetBairro;
    property Cidade: String read FCidade write SetCidade;
    property Estado: String read FEstado write SetEstado;
    property Tipo: TTipo read FTipo write SetTipo;

    function Consulta: TDadosEndereco;

    function RemoveAcento(aText: string): string;
    function RemoveCaracteresEndereco(txMensagem: String): String;

  end;

const
  CHAVE_API = 'AIzaSyDI3GxkWSwzRlxdjaJ4K8Io7Yp20BoI8BY';

implementation

{ TGoogleAPI }

uses uClassEnderecoUtil, uClassFuncoes;

function TGoogleAPI.DADOSCEP: TDadosEndereco;
var
  ConsultaCEP: TCEP;
begin
  if Result = nil then
    Result := TDadosEndereco.Create;

  ConsultaCEP := TCEP.Create;
  ConsultaCEP := ConsultaCEP.BuscaCep(CEP);
  if ConsultaCEP.Achou then
  begin
    Result.Achou := True;
    // CEP := ConsultaCEP.CEP;
    // Rua := ConsultaCEP.Rua;
    // Bairro := ConsultaCEP.Bairro;
    // Cidade := ConsultaCEP.Cidade;
    // Estado := ConsultaCEP.Estado;
    Result.Endereco := (ConsultaCEP.Rua);
    Result.Bairro := (ConsultaCEP.Bairro);
    Result.Cidade := (ConsultaCEP.Cidade);
    Result.Estado := (ConsultaCEP.Estado);
    // Result.CEP := ConsultaCEP.CEP;
    Result.KM := CEPKM(Result);
    // Busca LocalizaÁ„o
    exit;
  end;

  Result.Achou := false;

end;

function TGoogleAPI.CEPKM(Dados: TDadosEndereco): Real;
var
  RESTClient: TRESTClient;
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;

  AOrigem, ADestino: string;
  aText: string;
  Objeto: TJSONObject;
  ParRows: TJSONPair;
  jSubObj: TJSONObject;
  ArrayRows: TJSONArray;
  EnderecoTexto: string;
  LocalizadoCEP: String;
  nrPosicao: Integer;
  txRua: String;
  txBairro: String;
  txCidade: String;
  txEstado: String;

  ja: TJSONArray;
  jv: TJSONValue;

  TaxaEntregaPorKm: Boolean;
  Milha: Real;
  KM: Real;
  ValorKM: Real;

  txResposata: String;

  jsonObj: TJSONObject;
  I: Integer;
  Tipo: String;
begin

  AOrigem := Dados.Endereco + ', 0 - ' + Dados.Bairro + ', ' + Dados.Cidade +
    ' - ' + Dados.Estado;
  ADestino := StringReplace(dm.DADOS_EMPRESA.FieldByName('lat').AsString, ',',
    '.', [rfReplaceAll]) + ',' + StringReplace
    (dm.DADOS_EMPRESA.FieldByName('long').AsString, ',', '.', [rfReplaceAll]);

  RESTClient := TRESTClient.Create(nil);
  RESTClient.BaseURL :=
    'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins='
    + AOrigem + '&destinations=' + ADestino + '&key=' + CHAVE_API;

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  RESTRequest.Client := RESTClient;
  RESTRequest.Response := RESTResponse;

  RESTRequest.Execute;

  // Pegar Milha

  if RESTResponse.StatusCode = 200 then
  begin
    Objeto := RESTResponse.JSONValue as TJSONObject;

    ParRows := Objeto.Get('rows');
    ArrayRows := ParRows.JSONValue as TJSONArray;

    txResposata := (ArrayRows.ToString);
    txResposata := copy(txResposata, Pos('value', txResposata) + 7, 100);
    // txResposata := copy(txResposata, 36, 10);
    txResposata := copy(txResposata, 0, Pos('}', txResposata) - 1);

    try
      KM := StrToInt(txResposata) / 1000;
    except
      KM := 0;
    end;

    Result := KM;
    ParRows := Objeto.Get('origin_addresses');
    ArrayRows := ParRows.JSONValue as TJSONArray;
    EnderecoTexto := ArrayRows.Items[0].Value;

    nrPosicao := Pos('-', UpperCase(EnderecoTexto));
    txRua := copy(EnderecoTexto, 0, nrPosicao - 1);
    EnderecoTexto := copy(EnderecoTexto, nrPosicao + 1, length(EnderecoTexto) -
      1 - nrPosicao);

    nrPosicao := Pos(',', UpperCase(EnderecoTexto));
    txBairro := copy(EnderecoTexto, 0, nrPosicao - 1);
    EnderecoTexto := copy(EnderecoTexto, nrPosicao + 2, length(EnderecoTexto) -
      1 - nrPosicao);
    nrPosicao := Pos('-', UpperCase(EnderecoTexto));
    txCidade := copy(EnderecoTexto, 0, nrPosicao);
    EnderecoTexto := copy(EnderecoTexto, nrPosicao + 1, length(EnderecoTexto) -
      1 - nrPosicao);
    nrPosicao := Pos(',', UpperCase(EnderecoTexto));
    txEstado := trim(copy(EnderecoTexto, 0, nrPosicao - 1));

    Result := KM;

  end;

end;

function TGoogleAPI.Consulta: TDadosEndereco;
begin
  case Tipo of
    tLocalizacao:
      begin
        // LocalizaÁ„o
        Result := Localizacao;
      end;
    tCEPSituacao:
      begin
        Result := DADOSCEP;
      end;
  end;

end;

function TGoogleAPI.Localizacao: TDadosEndereco;
var
  RESTClient: TRESTClient;
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;

  AOrigem, ADestino: string;
  aText: string;
  Objeto: TJSONObject;
  ParRows: TJSONPair;
  jSubObj: TJSONObject;
  ArrayRows: TJSONArray;
  EnderecoTexto: string;
  LocalizadoCEP: String;
  nrPosicao: Integer;
  txRua: String;
  txBairro: String;
  txCidade: String;
  txEstado: String;

  ja: TJSONArray;
  jv: TJSONValue;

  Milha: Real;
  KM: Real;
  ValorKM: Real;

  txResposata: String;

  jsonObj: TJSONObject;
  I: Integer;
  Tipo: String;

  Cidade: TCidade;
  Endereco: TEnderecoLocalizacao;

begin

  AOrigem := StringReplace(FloatToStr(Lat), ',', '.', [rfReplaceAll]) + ',' +
    StringReplace(FloatToStr(Long), ',', '.', [rfReplaceAll]);
  ADestino := StringReplace(dm.DADOS_EMPRESA.FieldByName('lat').AsString, ',',
    '.', [rfReplaceAll]) + ',' + StringReplace
    (dm.DADOS_EMPRESA.FieldByName('long').AsString, ',', '.', [rfReplaceAll]);
  RESTClient := TRESTClient.Create(nil);
  RESTClient.BaseURL :=
    'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins='
    + AOrigem + '&destinations=' + ADestino + '&key=' + CHAVE_API;
  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  RESTRequest.Client := RESTClient;
  RESTRequest.Response := RESTResponse;
  RESTRequest.Execute;

  // Pegar Milha

  if RESTResponse.StatusCode = 200 then
  begin
    Objeto := RESTResponse.JSONValue as TJSONObject;

    ParRows := Objeto.Get('rows');
    ArrayRows := ParRows.JSONValue as TJSONArray;

    txResposata := (ArrayRows.ToString);
    txResposata := copy(txResposata, 36, 10);
    txResposata := copy(txResposata, 0, Pos('"', txResposata) - 1);
    Tipo := trim(UpperCase(copy(txResposata, Pos(' ', txResposata), 5)));
    txResposata := trim(copy(txResposata, 0, Pos(' ', txResposata) - 1));
    txResposata := StringReplace(txResposata, '.', ',', [rfReplaceAll]);

    if Tipo = 'M' then
    begin
      txResposata := '0,' + txResposata;
    end;
    Milha := 0;
    if txResposata <> '' then
    begin
      Milha := StrToFloat(txResposata);
    end;

    KM := Milha;

    ParRows := Objeto.Get('origin_addresses');
    ArrayRows := ParRows.JSONValue as TJSONArray;
    EnderecoTexto := ArrayRows.Items[0].Value;
    // Validar aqui se È uma CIDADE das quais precisa do bairro
    if Cidade.CidadeFazParte(EnderecoTexto) then
    begin
      Endereco := Endereco.CorrecaoEndereco(EnderecoTexto);
      if Endereco.Correto then
      begin
        txRua := Endereco.Rua;
        txBairro := Endereco.Bairro;
        txCidade := Endereco.Cidade;
        txEstado := Endereco.Estado;
        LocalizadoCEP := Endereco.CEP;
      end
      else
      begin
        Result := TDadosEndereco.Create;
        Result.Achou := false;
        Result.KM := KM;
        SetLength(Result.ArrayRetornoJason,
          length(Endereco.ArrayRetornoInformacoes));
        for I := 0 to length(Endereco.ArrayRetornoInformacoes) - 1 do
        begin
          Result.ArrayRetornoJason[I] := Endereco.ArrayRetornoInformacoes[I];
        end;

        // Result.ArrayRetornoJason := ;
        exit;
      end;
      Result := TDadosEndereco.Create;
      Result.Achou := True;

      Result.Endereco := UpperCase(RemoveAcento(txRua));
      Result.Bairro := RemoveCaracteresEndereco('BUSCAR_BANCO');
      Result.Cidade := RemoveCaracteresEndereco(txCidade);
      Result.Estado := RemoveCaracteresEndereco(txEstado);
      Result.KM := KM;
      exit;
      // Result.CEP := LocalizadoCEP;

    end
    else
    begin
      Endereco := Endereco.CorrecaoEndereco(EnderecoTexto);
      if Endereco.Correto then
      begin
        txRua := Endereco.Rua;
        txBairro := Endereco.Bairro;
        txCidade := Endereco.Cidade;
        txEstado := Endereco.Estado;
        LocalizadoCEP := Endereco.CEP;
      end
      else
      begin
        Result := TDadosEndereco.Create;
        Result.Achou := false;
        SetLength(Result.ArrayRetornoJason,
          length(Endereco.ArrayRetornoInformacoes));
        for I := 0 to length(Endereco.ArrayRetornoInformacoes) - 1 do
        begin
          Result.ArrayRetornoJason[I] := Endereco.ArrayRetornoInformacoes[I];
        end;
        Result.KM := KM;
        // Nese Momento
        exit;
      end;

    end;

    Result := TDadosEndereco.Create;
    Result.Achou := True;
    Result.KM := KM;
    Result.Endereco := trim(UpperCase(RemoveAcento(txRua)));
    Result.Bairro := trim(RemoveCaracteresEndereco(txBairro));
    Result.Cidade := trim(RemoveCaracteresEndereco(txCidade));
    Result.Estado := trim(RemoveCaracteresEndereco(txEstado));
    Result.CEP := LocalizadoCEP;

  end;

end;

function TGoogleAPI.RemoveAcento(aText: string): string;
const
  ComAcento = '‡‚ÍÙ˚„ı·ÈÌÛ˙Á¸Ò˝¿¬ ‘€√’¡…Õ”⁄«‹—›';
  SemAcento = 'aaeouaoaeioucunyAAEOUAOAEIOUCUNY';
var
  X: Cardinal;
begin;
  for X := 1 to length(aText) do
    try
      if (Pos(aText[X], ComAcento) <> 0) then
        aText[X] := SemAcento[Pos(aText[X], ComAcento)];
    except
      on E: Exception do
        raise Exception.Create('Erro no processo.');
    end;

  Result := aText;
end;

function TGoogleAPI.RemoveCaracteresEndereco(txMensagem: String): String;
begin
  txMensagem := StringReplace(txMensagem, ',', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '-', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '0', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '1', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '2', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '3', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '4', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '5', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '6', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '7', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '8', '', [rfReplaceAll]);
  txMensagem := StringReplace(txMensagem, '9', '', [rfReplaceAll]);
  txMensagem := RemoveAcento(txMensagem);
  txMensagem := trim(UpperCase(txMensagem));
  Result := trim(txMensagem);
end;

procedure TGoogleAPI.SetBairro(const Value: String);
begin
  FBairro := Value;
end;

procedure TGoogleAPI.SetCEP(const Value: String);
begin
  FCEP := Value;
end;

procedure TGoogleAPI.SetCidade(const Value: String);
begin
  FCidade := Value;
end;

procedure TGoogleAPI.SetEstado(const Value: String);
begin
  FEstado := Value;
end;

procedure TGoogleAPI.SetLat(const Value: Real);
begin
  FLat := Value;
end;

procedure TGoogleAPI.SetLong(const Value: Real);
begin
  FLong := Value;
end;

procedure TGoogleAPI.SetRua(const Value: String);
begin
  FRua := Value;
end;

procedure TGoogleAPI.SetTipo(const Value: TTipo);
begin
  FTipo := Value;
end;

end.
