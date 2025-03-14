unit GooPedirAPIController;

interface

uses
  System.SysUtils, System.Classes, Data.Bind.Components, Data.Bind.ObjectScope,
  uRequisicao, System.JSON, DataSet.Serialize, uLogThread;

type
  // Define tipos para as funções que serão passadas
  TFunctionHorarioAbertura = function(Dia: String): String of object;

  TGooPedirAPIController = class
  private
    FBaseURL: string;
    FClientID: String;
    FClientSecret: String;
    FClientToken: Boolean;
    FToken: string;
    FName: String;
    FUserID: Integer;
    FHorarioAberturaFunc: TFunctionHorarioAbertura;
    // Campo para armazenar a função de abertura
    FHorarioFechamentoFunc: TFunctionHorarioAbertura;
    // Campo para armazenar a função de fechamento
    FStatusHorario: TFunctionHorarioAbertura;
    function ConfigureRESTClient: iRequisicao;
    procedure BuscarToken;
    procedure EnviaPostParam(JSON: TJSONObject);
  public
    constructor Create(const ABaseURL, ClientId, ClientSecret: string;
      HorarioAberturaFunc, HorarioFechamentoFunc, StatusHorario
      : TFunctionHorarioAbertura);
    destructor Destroy; override;
    function GetToken: string;
    function Name: String;
    function UserID: Integer;
    procedure SincronizaParametros(Param: String);
    procedure EnviaParametroUnico(Campo, Valor, Tipo: String);
    procedure EnviaFuncionamento;
  end;

implementation

uses
  FireDAC.Comp.Client, Vcl.Dialogs;

{ TGooPedirAPIController }

procedure TGooPedirAPIController.BuscarToken;
var
  JsonObject: TJSONObject;
  FRequisicao: iRequisicao;
begin
  FRequisicao := ConfigureRESTClient;
  try
    FRequisicao.URL := 'api/goopedir/token';
    FRequisicao.Metodo := mPost;
    FRequisicao.AddHeader('client-id', FClientID);
    FRequisicao.AddHeader('client-security', FClientSecret);
    FRequisicao.Execute;
    JsonObject := TJSONObject.ParseJSONValue(FRequisicao.Retorno)
      as TJSONObject;

    FUserID := JsonObject.GetValue<Integer>('user');
    FName := JsonObject.GetValue<String>('name');
    FToken := JsonObject.GetValue<String>('token');

  except
    FClientToken := False;
  end;

  FRequisicao.Free;
end;

function TGooPedirAPIController.ConfigureRESTClient: iRequisicao;
begin
  Result := iRequisicao.Create(nil);
  Result.BaseURL := FBaseURL;
  Result.TempoExpiracao := 20 * 1000;
  if FToken <> '' then
    Result.Token(FToken);
end;

constructor TGooPedirAPIController.Create(const ABaseURL, ClientId,
  ClientSecret: string; HorarioAberturaFunc, HorarioFechamentoFunc,
  StatusHorario: TFunctionHorarioAbertura);
begin
  FBaseURL := ABaseURL;
  FClientID := ClientId;
  FClientSecret := ClientSecret;
  FHorarioAberturaFunc := HorarioAberturaFunc;
  FHorarioFechamentoFunc := HorarioFechamentoFunc;
  FStatusHorario := StatusHorario;
  BuscarToken;
end;

destructor TGooPedirAPIController.Destroy;
begin
  // Qualquer limpeza adicional necessária
  inherited;
end;

procedure TGooPedirAPIController.EnviaFuncionamento;
const
  DiasDaSemana: array [1 .. 7] of string = ('domingo', 'segunda', 'terca',
    'quarta', 'quinta', 'sexta', 'sabado');
var
  JSonBody: TJSONObject;
  JsonCampos: TJSONArray;
  JsonCampo: TJSONObject;
  I: Integer;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      I: Integer;
    begin
    LogThread('EnviaFuncionamento','Iniciando');
      JsonCampos := TJSONArray.Create;
      JSonBody := TJSONObject.Create;
      try
        JSonBody.AddPair('user', TJSONNumber.Create(FUserID));

        for I := Low(DiasDaSemana) to High(DiasDaSemana) do
        begin

          if Assigned(FStatusHorario) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', 'config_' + DiasDaSemana[I]);
            JsonCampo.AddPair('valor', FStatusHorario(DiasDaSemana[I]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end else begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', 'config_' + DiasDaSemana[I]);
            JsonCampo.AddPair('valor', 'false');
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioAberturaFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[I] + '_tarde_de');
            JsonCampo.AddPair('valor', FHorarioAberturaFunc(DiasDaSemana[I]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioFechamentoFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[I] + '_tarde_ate');
            JsonCampo.AddPair('valor', FHorarioFechamentoFunc(DiasDaSemana[I]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioAberturaFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[I] + '_manha_de');
            JsonCampo.AddPair('valor', FHorarioAberturaFunc(DiasDaSemana[I]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioFechamentoFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[I] + '_manha_ate');
            JsonCampo.AddPair('valor', FHorarioFechamentoFunc(DiasDaSemana[I]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;


        end;

        JSonBody.AddPair('campos', JsonCampos);
        EnviaPostParam(JSonBody);

      finally
       LogThread('EnviaFuncionamento','Finalizando');
      end;
    end).Start;
end;

procedure TGooPedirAPIController.EnviaParametroUnico(Campo, Valor,
  Tipo: String);
var
  JSonBody: TJSONObject;
  JsonCampos: TJSONArray;
  JsonCampo: TJSONObject;
begin
  JsonCampos := TJSONArray.Create;
  JSonBody := TJSONObject.Create;
  try
    JSonBody.AddPair('user', TJSONNumber.Create(FUserID));

    JsonCampo := TJSONObject.Create;
    JsonCampo.AddPair('campo', Campo);
    JsonCampo.AddPair('valor', Valor);
    JsonCampo.AddPair('type', Tipo);
    JsonCampos.AddElement(JsonCampo);
    JSonBody.AddPair('campos', JsonCampos);

    EnviaPostParam(JSonBody);

  finally
    // JsonCampos.Free;
    // JSonBody.Free;
  end;
end;

procedure TGooPedirAPIController.EnviaPostParam(JSON: TJSONObject);
var
  FRequisicao: iRequisicao;
begin
  if FUserID < 1 then
    Exit;

  FRequisicao := ConfigureRESTClient;
  FRequisicao.Metodo := mPost;
  FRequisicao.URL := 'api/goopedir/parametros';
  try
    FRequisicao.BODY(JSON);

    FRequisicao.Execute;
  except
    on E: Exception do
      // showmessage1('Erro ao enviar os parâmetros: ' + E.Message);
  end;
  FRequisicao.Free;
end;

function TGooPedirAPIController.GetToken: string;
begin
  if FToken = '' then
  begin
    BuscarToken;
  end;
  Result := FToken;
end;

function TGooPedirAPIController.Name: String;
begin
  Result := FName;
end;

procedure TGooPedirAPIController.SincronizaParametros(Param: String);
var
  Dados: TFDMemTable;
  JSonBody: TJSONObject;
  JsonCampos: TJSONArray;
  JsonCampo: TJSONObject;
begin
  if FUserID < 1 then
    Exit;

  TThread.CreateAnonymousThread(
    procedure
    begin
      LogThread('SincronizaParametros','Iniciando');

      Dados := TFDMemTable.Create(nil);
      Dados.LoadFromJSON(Param);

      JsonCampos := TJSONArray.Create;

      JSonBody := TJSONObject.Create;
      JSonBody.AddPair('user', FUserID);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'nome_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('nome').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'cnpj_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('cnpj').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'telefone_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('fone').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'end_rua_n_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('rua').AsString + ', nº ' +
        Dados.FieldByName('numero').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'end_bairro_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('bairro').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'cidade_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('cidade').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'end_uf_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('estado').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'cep_empresa');
      JsonCampo.AddPair('valor', Dados.FieldByName('cep').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'minimo_delivery');
      JsonCampo.AddPair('valor', Dados.FieldByName('valor_pedido_minimo')
        .AsString);
      JsonCampo.AddPair('type', 'float');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'confirm_delivery');
      JsonCampo.AddPair('valor', Dados.FieldByName('delivery').AsString);

      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'confirm_balcao');
      JsonCampo.AddPair('valor', Dados.FieldByName('retirada').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'access_token_mp');
      JsonCampo.AddPair('valor', Dados.FieldByName('token_mp').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'localizacao_gp');
      JsonCampo.AddPair('valor', Dados.FieldByName('localizacao').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'mensagem');
      JsonCampo.AddPair('valor', Dados.FieldByName('mensagem_inicio').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'fidelidade_status');
      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'fidelidade_pontos');
      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade_pontos')
        .AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'fidelidade_desc');
      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade_desc').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JsonCampo := TJSONObject.Create;
      JsonCampo.AddPair('campo', 'fidelidade_min');
      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade_min').AsString);
      JsonCampo.AddPair('type', 'string');
      JsonCampos.AddElement(JsonCampo);

      JSonBody.AddPair('campos', JsonCampos);

      EnviaPostParam(JSonBody);

      LogThread('SincronizaParametros','Finalizando');
    end).Start;
end;

function TGooPedirAPIController.UserID: Integer;
begin
  Result := FUserID;
end;

end.
