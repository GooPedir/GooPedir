unit GooPedirAPIController;

interface

uses
  System.SysUtils, System.Classes, Data.Bind.Components, Data.Bind.ObjectScope,
  uRequisicao, System.JSON, DataSet.Serialize, Conexao, Inifiles,
  DateUtils, Data.DB;

type
  // Define tipos para as funções que serão passadas
  TFunctionHorarioAbertura = function(Dia: String): String of object;

  TGooPedirAPIController = class
  private
    FBaseURL: string;
    FClientID: String;
    FClientSecret: String;
    FClientToken: Boolean;
    TObjetoEmpresa : TJSONObject;
    FToken: string;
    FName: String;
    FUserID: Integer;
    FSlug : String;
    FDataBloqueio: TDate;
    FHorarioAberturaFunc: TFunctionHorarioAbertura;
    // Campo para armazenar a função de abertura
    FHorarioFechamentoFunc: TFunctionHorarioAbertura;
    // Campo para armazenar a função de fechamento
    FStatusHorario: TFunctionHorarioAbertura;
    //
    FUrlLoja : String;
    function ConfigureRESTClient: iRequisicao;

    procedure EnviaPostParam(JSON: TJSONObject);
    function ApenasLetrasENumeros(const S: string): string;
  public
    constructor Create(const ABaseURL, ClientId, ClientSecret: string;
      HorarioAberturaFunc, HorarioFechamentoFunc, StatusHorario
      : TFunctionHorarioAbertura; User: String);
    destructor Destroy; override;
    function GetToken: string;
    function Name: String;
    function UserID: Integer;
    function GetBloqueio: TDate;
    function GetUrlLoja : String;
    procedure SincronizaParametros(Param: String);
    procedure EnviaParametroUnico(Campo, Valor, Tipo: String);
    procedure EnviaFuncionamento;
    function GetCupom: String;
    procedure BuscarToken;
    procedure EnviaDetalhesAtualizacao(banco, caminho, arquivo: String);
    function GetApi(base: String): String;
    function PostApi(base, body: String): String;
    function PostRotas(body: String): TJSONObject;
    function PutApi(Url, body: String): String;
    procedure SalvarConf(Nome, Valor: String);
    function GetConf(Nome: String): String;
    function Criptografar(const Texto, Chave: string): string;
    function Descriptografar(const Texto, Chave: string): string;
    function GetDataEmpresa : String;


    // Módulo de Rotas
    function GetRotas: TJSONObject;
    function GetMotoboy: TJSONObject;
    function PutInicia(Id: String): TJSONObject;
    function PutFinalizar(Id: String): TJSONObject;

    //
    procedure LoadDefault;

  end;

implementation

uses
  FireDAC.Comp.Client, Vcl.Dialogs;

{ TGooPedirAPIController }

function TGooPedirAPIController.ApenasLetrasENumeros(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    if S[i] in ['A' .. 'Z', 'a' .. 'z', '0' .. '9'] then
      Result := Result + S[i];
  end;
end;

procedure TGooPedirAPIController.BuscarToken;
var
  JsonObject: TJSONObject;
  FRequisicao: iRequisicao;
  IniFile: TIniFile;

begin
  FRequisicao := ConfigureRESTClient;
  try
    FRequisicao.Url := 'api/goopedir/token';
    FRequisicao.Metodo := mPost;
    FRequisicao.AddHeader('client-id', FClientID);
    FRequisicao.AddHeader('client-security', FClientSecret);
    FRequisicao.Execute;
    JsonObject := TJSONObject.ParseJSONValue(FRequisicao.Retorno) as TJSONObject;
    try
      if JsonObject.GetValue<String>('error') <> '' then
      begin
        FUserID := -1;
        FSlug := '';
        LoadDefault;
        FRequisicao.Free;
        exit;
      end;
    except
    end;
    FUserID := JsonObject.GetValue<Integer>('user');
    FSlug := JsonObject.GetValue<String>('slug');
    SalvarConf('user', FUserID.ToString);
    FName := JsonObject.GetValue<String>('name');
    SalvarConf('name', FName);
    FToken := JsonObject.GetValue<String>('token');
    SalvarConf('token', FToken);
    FDataBloqueio := ISO8601ToDate(JsonObject.GetValue<String>('bloqueio'));
    SalvarConf('vencimento', DateToStr(FDataBloqueio));
    FUrlLoja := JsonObject.GetValue<String>('link');
    SalvarConf('url', FUrlLoja);
    try
      FRequisicao.Url := 'api/empresa/'+FSlug;
      FRequisicao.Metodo := mGet;
      FRequisicao.Execute;
      TObjetoEmpresa := TJSONObject.ParseJSONValue(FRequisicao.Retorno) as TJSONObject;
    except
      TObjetoEmpresa := TJSONObject.Create;
    end;
  except
    on e: exception do
    begin
      FUserID := -1;
      LoadDefault;
      FClientToken := False;
      TObjetoEmpresa := TJSONObject.Create;
    end;
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
  StatusHorario: TFunctionHorarioAbertura; User: String);
begin
  FBaseURL := ABaseURL;
  FClientID := ClientId;
  FClientSecret := ClientSecret;
  FHorarioAberturaFunc := HorarioAberturaFunc;
  FHorarioFechamentoFunc := HorarioFechamentoFunc;
  FStatusHorario := StatusHorario;
  BuscarToken;
end;

function TGooPedirAPIController.Criptografar(const Texto,
  Chave: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Texto) do
    Result := Result +
      Char(Byte(Texto[i]) xor Byte(Chave[(i mod Length(Chave)) + 1]));
end;

function TGooPedirAPIController.Descriptografar(const Texto,
  Chave: string): string;
begin
  Result := Criptografar(Texto, Chave); // XOR é reversível
end;

destructor TGooPedirAPIController.Destroy;
begin
  // Qualquer limpeza adicional necessária
  inherited;
end;

function TGooPedirAPIController.GetMotoboy: TJSONObject;
var
  Retorno: String;
begin
  Retorno := GetApi('api/empresa/motoboys/rotas');

  if Retorno <> '' then
  begin
    try
      Result := TJSONObject.ParseJSONValue(Retorno) as TJSONObject;
      exit;
    except
      on e: exception do
      begin
        ShowMessage(e.Message);
      end;
    end;

  end;

  Result := TJSONObject.Create;

end;

procedure TGooPedirAPIController.EnviaDetalhesAtualizacao(banco, caminho,
  arquivo: String);
var
  objeto: TJSONObject;
begin
  objeto := TJSONObject.Create;
  objeto.AddPair('banco', banco);
  objeto.AddPair('caminho', caminho);
  objeto.AddPair('arquivo', arquivo);
  objeto.AddPair('user', TJSONNumber.Create(FUserID));
end;

procedure TGooPedirAPIController.EnviaFuncionamento;
const
  DiasDaSemana: array [1 .. 7] of string = ('domingo', 'segunda', 'terca',
    'quarta', 'quinta', 'sexta', 'sabado');
var
  JSonBody: TJSONObject;
  JsonCampos: TJSONArray;
  JsonCampo: TJSONObject;
  i: Integer;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      i: Integer;
    begin

      JsonCampos := TJSONArray.Create;
      JSonBody := TJSONObject.Create;
      try
        JSonBody.AddPair('user', TJSONNumber.Create(FUserID));

        for i := Low(DiasDaSemana) to High(DiasDaSemana) do
        begin

          if Assigned(FStatusHorario) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', 'config_' + DiasDaSemana[i]);
            JsonCampo.AddPair('valor', FStatusHorario(DiasDaSemana[i]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end
          else
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', 'config_' + DiasDaSemana[i]);
            JsonCampo.AddPair('valor', 'false');
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioAberturaFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[i] + '_tarde_de');
            JsonCampo.AddPair('valor', FHorarioAberturaFunc(DiasDaSemana[i]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioFechamentoFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[i] + '_tarde_ate');
            JsonCampo.AddPair('valor', FHorarioFechamentoFunc(DiasDaSemana[i]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioAberturaFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[i] + '_manha_de');
            JsonCampo.AddPair('valor', FHorarioAberturaFunc(DiasDaSemana[i]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;

          if Assigned(FHorarioFechamentoFunc) then
          begin
            JsonCampo := TJSONObject.Create;
            JsonCampo.AddPair('campo', DiasDaSemana[i] + '_manha_ate');
            JsonCampo.AddPair('valor', FHorarioFechamentoFunc(DiasDaSemana[i]));
            JsonCampo.AddPair('type', 'string');
            JsonCampos.AddElement(JsonCampo);
          end;
        end;

        JSonBody.AddPair('campos', JsonCampos);
        EnviaPostParam(JSonBody);

      finally

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
    exit;

  FRequisicao := ConfigureRESTClient;
  FRequisicao.Metodo := mPost;
  FRequisicao.Url := 'api/goopedir/parametros';
  try
    FRequisicao.body(JSON);

    FRequisicao.Execute;
  except
    on e: exception do
  end;
  FRequisicao.Free;
end;

function TGooPedirAPIController.GetApi(base: String): String;
var
  req: iRequisicao;
begin
  req := ConfigureRESTClient;
  req.Url := base;
  try
    req.Execute;
    Result := req.Retorno;
  except
    on e: exception do
    begin
    end;
  end;
  req.Free;
end;

function TGooPedirAPIController.GetBloqueio: TDate;
begin
  Result := FDataBloqueio;
end;

function TGooPedirAPIController.GetConf(Nome: String): String;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  if (Nome = 'token') then
  begin
    Result := IniFile.ReadString('server', Nome, '')
  end
  else
  begin
    Result := Descriptografar(IniFile.ReadString('server', Nome, ''), Nome);
  end;

  IniFile.Free;
end;

function TGooPedirAPIController.GetCupom: String;
begin
  //
end;

function TGooPedirAPIController.GetDataEmpresa: String;
var
  Retorno : String;
begin
  Retorno := GetApi('api/empresa/functionamento/'+UserID.ToString);
  TObjetoEmpresa.AddPair('status',TJSONObject.ParseJSONValue(Retorno) as TJSONObject);
  Result := TObjetoEmpresa.ToString();
end;

function TGooPedirAPIController.GetRotas: TJSONObject;
var
  Retorno: String;
begin
  Retorno := GetApi('api/empresa/rotas/pendentes');

  if Retorno <> '' then
  begin
    try
      Result := TJSONObject.ParseJSONValue(Retorno) as TJSONObject;
      exit;
    except
      on e: exception do
      begin
        //ShowMessage(e.Message);
      end;
    end;

  end;
  Result := TJSONObject.Create;
end;

function TGooPedirAPIController.GetToken: string;
begin
  if FToken = '' then
  begin
    BuscarToken;
  end;
  Result := FToken;
end;

function TGooPedirAPIController.GetUrlLoja: String;
begin
Result := FUrlLoja;
end;

procedure TGooPedirAPIController.LoadDefault;
begin
  try
    FUserID := GetConf('user').ToInteger;
  except

  end;

  FName := GetConf('name');

  FToken := GetConf('token');

  FUrlLoja := GetConf('url');

  try
    FDataBloqueio := StrToDate(GetConf('vencimento'))
  except

  end;

end;

function TGooPedirAPIController.Name: String;
begin
  Result := FName;
end;

function TGooPedirAPIController.PostApi(base, body: String): String;
var
  req: iRequisicao;
begin
  req := ConfigureRESTClient;
  req.Url := base;
  try
    req.Metodo := mPost;
    req.body(body);
    req.Execute;
    Result := req.Retorno;
  except
    on e: exception do
    begin

    end;
  end;
  req.Free;
end;

function TGooPedirAPIController.PostRotas(body: String): TJSONObject;
var
  Retorno: String;
begin
  Retorno := PostApi('api/empresa/rotas/recriar', body);

  if Retorno <> '' then
  begin
    try
      Result := TJSONObject.ParseJSONValue(Retorno) as TJSONObject;
      exit;
    except
      on e: exception do
      begin
      end;
    end;

  end;
  Result := TJSONObject.Create;
end;

function TGooPedirAPIController.PutApi(Url, body: String): String;
var
  req: iRequisicao;
begin
  req := ConfigureRESTClient;
  req.Url := Url;
  try
    req.Metodo := mPut;
    if (body <> '') then
      req.body(body);
    req.Execute;
    Result := req.Retorno;
  except
    on e: exception do
    begin

    end;
  end;
  req.Free;
end;

function TGooPedirAPIController.PutFinalizar(Id: String): TJSONObject;
var
  Retorno: String;
begin
  Retorno := PutApi('api/empresa/rotas/pedidos/finalizar/' + Id, '');

  if Retorno <> '' then
  begin
    try
      Result := TJSONObject.ParseJSONValue(Retorno) as TJSONObject;
      exit;
    except
      on e: exception do
      begin
        ShowMessage(e.Message);
      end;
    end;

  end;

  Result := TJSONObject.Create;

end;

function TGooPedirAPIController.PutInicia(Id: String): TJSONObject;
var
  Retorno: String;
begin
  Retorno := PutApi('api/empresa/rotas/pedidos/iniciar/' + Id, '');

  if Retorno <> '' then
  begin
    try
      Result := TJSONObject.ParseJSONValue(Retorno) as TJSONObject;
      exit;
    except
      on e: exception do
      begin
//        ShowMessage(e.Message);
      end;
    end;

  end;

  Result := TJSONObject.Create;

end;

procedure TGooPedirAPIController.SalvarConf(Nome, Valor: String);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  if (Nome='token') then
  begin
    IniFile.WriteString('server', Nome, Valor);
  end else begin
    IniFile.WriteString('server', Nome, Criptografar(Valor, Nome));
  end;

  IniFile.Free;
end;

//procedure TGooPedirAPIController.SincronizaParametros(Param: String);
//var
//  Dados: TFDMemTable;
//  JSonBody: TJSONObject;
//  JsonCampos: TJSONArray;
//  JsonCampo: TJSONObject;
//
//begin
//  if FUserID < 1 then
//    exit;
//
//  TThread.CreateAnonymousThread(
//    procedure
//    var
//      Conexao: TConexao;
//      Qry: TFDQuery;
//    begin
//      Dados := TFDMemTable.Create(nil);
//      Dados.LoadFromJSON(Param);
//      JsonCampos := TJSONArray.Create;
//      JSonBody := TJSONObject.Create;
//      JSonBody.AddPair('user', FUserID);
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'mensagem');
//      JsonCampo.AddPair('valor', Dados.FieldByName('mensagem_inicio').AsWideString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'nome_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('nome').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'img_header');
//      JsonCampo.AddPair('valor', Dados.FieldByName('banner').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'img_logo');
//      JsonCampo.AddPair('valor', Dados.FieldByName('logo').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'cnpj_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('cnpj').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'pixel');
//      JsonCampo.AddPair('valor', Dados.FieldByName('pixel').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'telefone_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('fone').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'end_rua_n_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('rua').AsString + ', nº ' +
//        Dados.FieldByName('numero').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'end_bairro_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('bairro').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'cidade_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('cidade').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'end_uf_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('estado').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'cep_empresa');
//      JsonCampo.AddPair('valor', Dados.FieldByName('cep').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'minimo_delivery');
//      JsonCampo.AddPair('valor', Dados.FieldByName('valor_pedido_minimo')
//        .AsString);
//      JsonCampo.AddPair('type', 'float');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'confirm_delivery');
//      JsonCampo.AddPair('valor', Dados.FieldByName('delivery').AsString);
//
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'confirm_balcao');
//      JsonCampo.AddPair('valor', Dados.FieldByName('retirada').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'access_token_mp');
//      JsonCampo.AddPair('valor', Dados.FieldByName('token_mp').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'merchant');
//      JsonCampo.AddPair('valor', Dados.FieldByName('merchant').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'mensagem');
//      JsonCampo.AddPair('valor', Dados.FieldByName('mensagem_inicio').AsWideString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'mensagem_conclusao');
//      JsonCampo.AddPair('valor', Dados.FieldByName('mensagem_conclusao').AsWideString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'conclusao_envio_range');
//      JsonCampo.AddPair('valor', Dados.FieldByName('conclusao_envio_range').AsWideString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo.AddPair('campo', 'mensagem_fora_horario');
//      JsonCampo.AddPair('valor', Dados.FieldByName('mensagem_fora_expediente').AsWideString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'fidelidade_status');
//      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'fidelidade_pontos');
//      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade_pontos')
//        .AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'fidelidade_desc');
//      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade_desc').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'fidelidade_min');
//      JsonCampo.AddPair('valor', Dados.FieldByName('fidelidade_min').AsString);
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'cor_topo');
//      JsonCampo.AddPair('valor',
//        ApenasLetrasENumeros(Dados.FieldByName('cor_fundo').AsString));
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'cor_loading');
//      JsonCampo.AddPair('valor',
//        ApenasLetrasENumeros(Dados.FieldByName('cor_fundo').AsString));
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'cor_titulo_produtos');
//      JsonCampo.AddPair('valor',
//        ApenasLetrasENumeros(Dados.FieldByName('cor_fonte').AsString));
//      JsonCampo.AddPair('type', 'string');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'lgn');
//      JsonCampo.AddPair('valor', Dados.FieldByName('longitude').AsString);
//      JsonCampo.AddPair('type', 'float');
//      JsonCampos.AddElement(JsonCampo);
//
//      JsonCampo := TJSONObject.Create;
//      JsonCampo.AddPair('campo', 'lat');
//      JsonCampo.AddPair('valor', Dados.FieldByName('latitude').AsString);
//      JsonCampo.AddPair('type', 'float');
//      JsonCampos.AddElement(JsonCampo);
//
//      JSonBody.AddPair('campos', JsonCampos);
//
//      EnviaPostParam(JSonBody);
//
//    end).Start;
//end;

procedure TGooPedirAPIController.SincronizaParametros(Param: String);
begin
  if FUserID < 1 then
    Exit;

  TThread.CreateAnonymousThread(
    procedure

      function GetJsonValue(
        Json: TJSONObject;
        const Campo: string): string;
      var
        V: TJSONValue;
      begin
        Result := '';

        V := Json.GetValue(Campo);

        if Assigned(V) then
          Result := V.Value;
      end;

function SnakeToCamel(const Texto: string): string;
var
  i: Integer;
  UpperNext: Boolean;
begin
  Result := '';
  UpperNext := False;

  for i := 1 to Length(Texto) do
  begin
    if Texto[i] = '_' then
    begin
      UpperNext := True;
      Continue;
    end;

    if UpperNext then
    begin
      Result := Result + UpperCase(Texto[i]);
      UpperNext := False;
    end
    else
    begin
      Result := Result + LowerCase(Texto[i]);
    end;
  end;
end;

      procedure AddCampo(
        JsonCampos: TJSONArray;
        Dados: TJSONObject;
        const CampoJson,
              CampoOrigem,
              Tipo: string);
      var
        JsonCampo: TJSONObject;
        Valor: string;
      begin
        Valor := GetJsonValue(Dados, SnakeToCamel(CampoOrigem));

        if Valor <> '' then
        begin
          JsonCampo := TJSONObject.Create;

          JsonCampo.AddPair(
            'campo',
            TJSONString.Create(CampoJson)
          );

          JsonCampo.AddPair(
            'valor',
            TJSONString.Create(Valor)
          );

          JsonCampo.AddPair(
            'type',
            TJSONString.Create(Tipo)
          );

          JsonCampos.AddElement(JsonCampo);
        end;
      end;

      procedure AddCampoValor(
        JsonCampos: TJSONArray;
        const CampoJson,
              Valor,
              Tipo: string);
      var
        JsonCampo: TJSONObject;
      begin
        if Valor <> '' then
        begin
          JsonCampo := TJSONObject.Create;

          JsonCampo.AddPair(
            'campo',
            TJSONString.Create(CampoJson)
          );

          JsonCampo.AddPair(
            'valor',
            TJSONString.Create(Valor)
          );

          JsonCampo.AddPair(
            'type',
            TJSONString.Create(Tipo)
          );

          JsonCampos.AddElement(JsonCampo);
        end;
      end;

    var
      JSONArray: TJSONArray;
      Dados: TJSONObject;
      JsonBody: TJSONObject;
      JsonCampos: TJSONArray;

    begin

      JSONArray := nil;
      JsonBody := nil;

      try

        JSONArray := TJSONObject.ParseJSONValue(Param) as TJSONArray;

        if not Assigned(JSONArray) then
          Exit;

        if JSONArray.Count = 0 then
          Exit;

        Dados := JSONArray.Items[0] as TJSONObject;

        JsonCampos := TJSONArray.Create;
        JsonBody := TJSONObject.Create;

        JsonBody.AddPair(
          'user',
          TJSONNumber.Create(FUserID)
        );

        AddCampo(JsonCampos, Dados,
          'mensagem',
          'mensagem_inicio',
          'string');

        AddCampo(JsonCampos, Dados,
          'nome_empresa',
          'nome',
          'string');

        AddCampo(JsonCampos, Dados,
          'img_header',
          'banner',
          'string');

        AddCampo(JsonCampos, Dados,
          'img_logo',
          'logo',
          'string');

        AddCampo(JsonCampos, Dados,
          'cnpj_empresa',
          'cnpj',
          'string');

        AddCampo(JsonCampos, Dados,
          'pixel',
          'pixel',
          'string');

        AddCampo(JsonCampos, Dados,
          'telefone_empresa',
          'fone',
          'string');

        AddCampoValor(
          JsonCampos,
          'end_rua_n_empresa',
          GetJsonValue(Dados, 'rua') +
          ', nº ' +
          GetJsonValue(Dados, 'numero'),
          'string'
        );

        AddCampo(JsonCampos, Dados,
          'end_bairro_empresa',
          'bairro',
          'string');

        AddCampo(JsonCampos, Dados,
          'cidade_empresa',
          'cidade',
          'string');

        AddCampo(JsonCampos, Dados,
          'end_uf_empresa',
          'estado',
          'string');

        AddCampo(JsonCampos, Dados,
          'cep_empresa',
          'cep',
          'string');

        AddCampo(JsonCampos, Dados,
          'minimo_delivery',
          'valor_pedido_minimo',
          'float');

        AddCampo(JsonCampos, Dados,
          'confirm_delivery',
          'delivery',
          'string');

        AddCampo(JsonCampos, Dados,
          'confirm_balcao',
          'retirada',
          'string');

        AddCampo(JsonCampos, Dados,
          'access_token_mp',
          'token_mp',
          'string');

        AddCampo(JsonCampos, Dados,
          'merchant',
          'merchant',
          'string');

        AddCampo(JsonCampos, Dados,
          'mensagem_conclusao',
          'mensagem_conclusao',
          'string');

        AddCampo(JsonCampos, Dados,
          'conclusao_envio_range',
          'conclusao_envio_range',
          'string');

        AddCampo(JsonCampos, Dados,
          'mensagem_fora_horario',
          'mensagem_fora_expediente',
          'string');

        AddCampo(JsonCampos, Dados,
          'fidelidade_status',
          'fidelidade',
          'string');

        AddCampo(JsonCampos, Dados,
          'fidelidade_pontos',
          'fidelidade_pontos',
          'string');

        AddCampo(JsonCampos, Dados,
          'fidelidade_desc',
          'fidelidade_desc',
          'string');

        AddCampo(JsonCampos, Dados,
          'fidelidade_min',
          'fidelidade_min',
          'string');

        AddCampoValor(
          JsonCampos,
          'cor_topo',
          ApenasLetrasENumeros(
            GetJsonValue(Dados, 'cor_fundo')
          ),
          'string'
        );

        AddCampoValor(
          JsonCampos,
          'cor_loading',
          ApenasLetrasENumeros(
            GetJsonValue(Dados, 'cor_fundo')
          ),
          'string'
        );

        AddCampoValor(
          JsonCampos,
          'cor_titulo_produtos',
          ApenasLetrasENumeros(
            GetJsonValue(Dados, 'cor_fonte')
          ),
          'string'
        );

        AddCampo(JsonCampos, Dados,
          'lgn',
          'longitude',
          'float');

        AddCampo(JsonCampos, Dados,
          'lat',
          'latitude',
          'float');

        JsonBody.AddPair(
          'campos',
          JsonCampos
        );


        EnviaPostParam(JsonBody);

      finally
        JSONArray.Free;
        JsonBody.Free;
      end;

    end).Start;
end;

function TGooPedirAPIController.UserID: Integer;
begin
  Result := FUserID;
end;

end.
