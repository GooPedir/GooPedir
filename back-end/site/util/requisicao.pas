unit Requisicao;

interface

uses
  REST.Client, REST.Response.Adapter, FireDAC.Comp.Client, System.JSON,
  DataSet.Serialize, System.Classes, EncdDecd;

type

  TRequest = class
  private
    RESTClient: TRESTClient;
    RESTResponse: TRESTResponse;
    RESTRequest: TRESTRequest;

    FBASEURL: String;
    FURLI: String;
    FMemoryTable: TFDMemTable;
    FRetorno: String;
    FStatus: integer;
    FDataSetRetorno: TFDMemTable;
    FStatusText: String;
    // FeTAG: TETag;
    FUsarETGA: Boolean;
    FResultadoETAG: String;
    FID: integer;
    procedure SetBASEURL(const Value: String);
    procedure SetURLI(const Value: String);
    procedure SetMemoryTable(const Value: TFDMemTable);
    procedure SetRetorno(const Value: String);
    procedure SetStatus(const Value: integer);
    procedure SetDataSetRetorno(const Value: TFDMemTable);

    procedure AtualizaRetorno(lResponse: TRESTResponse; Data: TDate;
      Hora: TTime; URL: String);
    procedure SetStatusText(const Value: String);
    // procedure SeteTAG(const Value: TETag);
    procedure SetUsarETGA(const Value: Boolean);

    function InsertRequisicao: integer;
    procedure AtualizaRequisicao(lResponse: TRESTResponse; Data: TDate;
      Hora: TTime; URL: String);

    function calcularDiferencaHoras(Dataf, datai: TDate; HoraF, HoraI: TTime)
      : TDateTime;

    function FormatacalcularDiferencaHoras(Dataf, datai: TDate;
      HoraF, HoraI: TTime): String;

  public
    constructor Create;
    destructor Destroy;
    property BASEURL: String read FBASEURL write SetBASEURL;
    property URLI: String read FURLI write SetURLI;
    property MemoryTable: TFDMemTable read FMemoryTable write SetMemoryTable;
    // Retorno
    property Status: integer read FStatus write SetStatus;
    property StatusText: String read FStatusText write SetStatusText;
    property Retorno: String read FRetorno write SetRetorno;

    procedure Body(Dados: String); overload;
    procedure Body(Dados: TJSONObject); overload;
    procedure Body(Dados: TJSONArray); overload;
    procedure Body(Dados: TFDMemTable); overload;

    procedure Token(MyToken: String);

    property UsarETGA: Boolean read FUsarETGA write SetUsarETGA;
    // property eTAG: TETag read FeTAG write SeteTAG;

    // metodos
    procedure Get;
    procedure Post;
    procedure Put;
    procedure Delete;
    procedure Patch;

  end;

implementation

uses
  System.SysUtils, REST.Types, uPrincipal, Vcl.Dialogs;

{ TRequest }

procedure TRequest.Body(Dados: TJSONObject);
begin
  // if trim(Dados) = '' then
  // Exit;

  RESTRequest.AddBody(Dados);
end;

procedure TRequest.Body(Dados: String);
begin
  if trim(Dados) = '' then
    Exit;

  RESTRequest.AddBody(Dados, ctAPPLICATION_JSON);
  // FRESTRequest.AddBody(AContent, AContentType);
end;

procedure TRequest.AtualizaRequisicao(lResponse: TRESTResponse; Data: TDate;
  Hora: TTime; URL: String);
begin
  // exit;
  frmPrincipal.memRequisicoes.DisableControls;
  try

    frmPrincipal.memRequisicoes.Last;
    frmPrincipal.memRequisicoes.Insert;
    frmPrincipal.memRequisicoes.FieldByName('ID').AsInteger :=
      frmPrincipal.IdRequisicao;
    frmPrincipal.memRequisicoes.FieldByName('URL').AsString := URL;
    frmPrincipal.memRequisicoes.FieldByName('DATA').AsDateTime := Data;
    frmPrincipal.memRequisicoes.FieldByName('HORA').AsDateTime := Hora;
    frmPrincipal.memRequisicoes.FieldByName('DATA_RESPOSTA').AsDateTime := Date;
    frmPrincipal.memRequisicoes.FieldByName('HORA_RESPOSTA').AsDateTime := Time;
    frmPrincipal.memRequisicoes.FieldByName('TEMPO').AsString :=
      FormatacalcularDiferencaHoras(frmPrincipal.memRequisicoes.FieldByName
      ('DATA_RESPOSTA').AsDateTime, frmPrincipal.memRequisicoes.FieldByName
      ('DATA').AsDateTime, frmPrincipal.memRequisicoes.FieldByName
      ('HORA_RESPOSTA').AsDateTime, frmPrincipal.memRequisicoes.FieldByName
      ('HORA').AsDateTime);

    frmPrincipal.memRequisicoes.FieldByName('STATUS').AsInteger :=
      lResponse.StatusCode;
    frmPrincipal.memRequisicoes.FieldByName('STATUS_DESC').AsString :=
      lResponse.StatusText;
    frmPrincipal.memRequisicoes.FieldByName('BODY').AsString :=
      lResponse.Content;
    frmPrincipal.memRequisicoes.Post;
  except

  end;
  frmPrincipal.memRequisicoes.EnableControls;
end;

procedure TRequest.AtualizaRetorno(lResponse: TRESTResponse; Data: TDate;
  Hora: TTime; URL: String);
Var
  eTAG: String;
  RESULTADO: String;
begin
  Retorno := lResponse.Content;
  Status := lResponse.StatusCode;
  StatusText := lResponse.StatusText;

  if length(Retorno) > 0 then
  begin
    if Assigned(FMemoryTable) then
    begin
      try
        FMemoryTable.LoadFromJSON(Retorno);
      except

      end;
    end;
  end;

  if RESTRequest.Method = TRESTRequestMethod.rmGET then
  begin
    if lResponse.StatusCode = 304 then
    begin
      Retorno := FResultadoETAG;

      if Assigned(FMemoryTable) then
      begin
        try
          FMemoryTable.LoadFromJSON(Retorno);
        except

        end;
      end;
    end;

    try
      if FUsarETGA then
      begin

        eTAG := RESTResponse.Headers.Values['ETag'];
        RESULTADO := lResponse.Content;
        if length(eTAG) > 0 then
        begin
          // if Assigned(FeTAG) and (lResponse.StatusCode = 200) then
          // FeTAG.AdicionaETAG(URL, eTAG, RESULTADO, '');
        end;
      end;
    except

    end;
  end;
  AtualizaRequisicao(lResponse, Data, Hora, URL);
  RESTRequest.ClearBody;
end;

procedure TRequest.Body(Dados: TFDMemTable);
begin
  // if trim(Dados) = '' then
  // Exit;

  RESTRequest.AddBody(Dados.ToJSONArray());
end;

function TRequest.calcularDiferencaHoras(Dataf, datai: TDate;
  HoraF, HoraI: TTime): TDateTime;
var
  DataHoraF, DataHoraI: TDateTime;
begin
  DataHoraF := Dataf + HoraF;
  DataHoraI := datai + HoraI;
  if DataHoraI > DataHoraF then
    result := DataHoraI - DataHoraF
  else
    result := DataHoraF - DataHoraI;
end;

procedure TRequest.Body(Dados: TJSONArray);
begin
  // if trim(Dados) = '' then
  // Exit;

  RESTRequest.AddBody(Dados);
end;

constructor TRequest.Create;
begin
  RESTClient := TRESTClient.Create(nil);

  RESTClient.FallbackCharsetEncoding := 'UTF-8';
  RESTClient.HandleRedirects := True;

  RESTResponse := TRESTResponse.Create(nil);

  RESTRequest := TRESTRequest.Create(nil);
  RESTRequest.Client := RESTClient;
  RESTRequest.Response := RESTResponse;
  RESTRequest.Timeout := 60000;

end;

procedure TRequest.Delete;
begin
  FID := frmPrincipal.IdRequisicao;
  try
    RESTRequest.Method := TRESTRequestMethod.rmDELETE;
    RESTRequest.Execute;
  except
    Status := 999;
  end;

end;

destructor TRequest.Destroy;
begin
  RESTClient.Free;
  RESTResponse.Free;
  RESTRequest.Free;

end;

function TRequest.FormatacalcularDiferencaHoras(Dataf, datai: TDate;
  HoraF, HoraI: TTime): String;
var
  Dias: integer;
  Total, Horas: Real;
  QuerEmHorasMinutosSegundos: string;
  H, M, S, SS: Word;

begin
  Total := calcularDiferencaHoras(Dataf, datai, HoraF, HoraI);
  Dias := Trunc(Total);
  Horas := Total - Trunc(Total);
  Decodetime(Horas, H, M, S, SS);
  H := H + 24 * Trunc(Dias);

  result := '';

  if H > 0 then
    result := FormatFloat('#00', H) + 'h';

  if M > 0 then
  begin
    if length(result) > 0 then
      result := result + ' ' + FormatFloat('0', M) + 'm'
    else
      result := FormatFloat('0', M);
  end;

  if S > 0 then
  begin
    if length(result) > 0 then
      result := result + ' ' + FormatFloat('0', S) + 's'
    else
      result := FormatFloat('0', S) + 's';
  end;
  if length(result) = 0 then
    result := '1s';

  // result := QuerEmHorasMinutosSegundos;
end;

procedure TRequest.Get;
var
  Tempo: integer;
  Data: TDate;
  Hora: TTime;
  URL: String;
begin
  Tempo := Random(frmPrincipal.TempoEspera);
  if Tempo = 0 then
    Tempo := 1;
  Tempo := Tempo * 1000;
  // FID := InsertRequisicao;

  try
    URL := BASEURL + URLI;
    Data := Date;
    Hora := Time;
    RESTClient.BASEURL := URL;
    RESTRequest.Method := TRESTRequestMethod.rmGET;
    if not frmPrincipal.Homologacao then
      Sleep(Tempo);
    RESTRequest.Execute;
    AtualizaRetorno(RESTResponse, Data, Hora, URL);
  except
    on E: Exception do
    begin
      Status := 999;
       //ShowMessage(BASEURL+URLI+#13+E.Message);
       //showmessage(E.Message);
    end;
  end;

end;

function TRequest.InsertRequisicao: integer;
begin
  result := frmPrincipal.IdRequisicao;
  if frmPrincipal.memRequisicoes.RecordCount> 20 then
  begin
    frmPrincipal.memRequisicoes.Close;
    frmPrincipal.memRequisicoes.Open;
  end;
  frmPrincipal.memRequisicoes.Insert;
  frmPrincipal.memRequisicoes.FieldByName('ID').AsInteger := result;
  frmPrincipal.memRequisicoes.FieldByName('URL').AsString := BASEURL + URLI;
  frmPrincipal.memRequisicoes.FieldByName('DATA').AsDateTime := Date;
  frmPrincipal.memRequisicoes.FieldByName('HORA').AsDateTime := Time;
  frmPrincipal.memRequisicoes.Post;
end;

procedure TRequest.Patch;
begin
  FID := frmPrincipal.IdRequisicao;
  RESTRequest.Method := TRESTRequestMethod.rmPATCH;
  RESTRequest.Execute;
end;

procedure TRequest.Post;
var
  Data: TDate;
  Hora: TTime;
  URL: String;
  Tempo: integer;
begin
  Tempo := Random(frmPrincipal.TempoEspera);
  if Tempo = 0 then
    Tempo := 1;
  Tempo := Tempo * 1000;
  // FID := InsertRequisicao3;
  try
    URL := BASEURL + URLI;
    Data := Date;
    Hora := Time;
    RESTClient.BASEURL := URL;
    RESTRequest.Method := TRESTRequestMethod.rmPOST;
    if not frmPrincipal.Homologacao then
      Sleep(Tempo);
    RESTRequest.Execute;
    AtualizaRetorno(RESTResponse, Data, Hora, URL);
  except
    Status := 999;
  end;

end;

procedure TRequest.Put;
begin
  FID := frmPrincipal.IdRequisicao;
  try
    RESTRequest.Method := TRESTRequestMethod.rmPUT;
    RESTRequest.Execute;
  except
    Status := 999;
  end;

end;

procedure TRequest.SetBASEURL(const Value: String);
begin
  FBASEURL := Value;
end;

procedure TRequest.SetDataSetRetorno(const Value: TFDMemTable);
begin
  FDataSetRetorno := Value;
end;

// procedure TRequest.SeteTAG(const Value: TETag);
// begin
// FeTAG := Value;
// end;

procedure TRequest.SetMemoryTable(const Value: TFDMemTable);
begin
  FMemoryTable := Value;
end;

procedure TRequest.SetRetorno(const Value: String);
begin
  FRetorno := Value;
end;

procedure TRequest.SetStatus(const Value: integer);
begin
  FStatus := Value;
end;

procedure TRequest.SetStatusText(const Value: String);
begin
  FStatusText := Value;
end;

procedure TRequest.SetURLI(const Value: String);
var
  MyeTAG: String;
begin
  FURLI := Value;

  // if Assigned(eTAG) then
  // begin
  // if UsarETGA then
  // begin
  // MyeTAG := eTAG.LocalizaETAG(BASEURL + URLI);
  // if length(MyeTAG) > 0 then
  // begin
  // RESTRequest.Params.AddHeader('If-None-Match', MyeTAG);
  // FResultadoETAG := eTAG.LocalizaRESULTADO(BASEURL + URLI);
  // end;
  // end;
  // end;
end;

procedure TRequest.SetUsarETGA(const Value: Boolean);
begin
  FUsarETGA := Value;
end;

procedure TRequest.Token(MyToken: String);
const
  AUTHORIZATION = 'Authorization';
begin
  if trim(MyToken) = '' then
    Exit;

  RESTRequest.Params.AddHeader(AUTHORIZATION, MyToken);
  RESTRequest.Params.ParameterByName(AUTHORIZATION).Options := [poDoNotEncode];
end;

end.
