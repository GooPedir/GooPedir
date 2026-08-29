unit uAtualizacaoPDV;

interface

uses System.SysUtils;

const
  ATU_SEM_ATUALIZACAO = 0;
  ATU_DISPONIVEL = 1;
  ATU_OBRIGATORIA = 2;
  ATU_APLICADA = 3;
  ATU_ERRO_PARAMETROS = 10;
  ATU_ERRO_AUTENTICACAO = 11;
  ATU_ERRO_SERVIDOR = 12;
  ATU_ERRO_DOWNLOAD = 13;
  ATU_ERRO_PROCESSO_ABERTO = 14;
  ATU_ERRO_ROLLBACK = 15;
  ATU_ERRO_CRITICO = 16;
  ATU_ERRO_BACKUP = 17;

type
  TAtualizacaoConfig = class
  private
    FBaseUrl, FToken, FCompany, FCompanyName, FCompanyDocument: string;
    FTerminal, FProduct, FChannel: string;
    FCurrentVersion, FEntryPoint, FProcesses: string;
    FBackupExe, FDbHost, FDbUser, FDbPassword, FDbName: string;
    FDbPort: Integer;
    FCloseTimeoutSeconds: Integer;
    function NovoIdEstacao: string;
    procedure Validar;
  public
    constructor Create(const ACompanyName, ACompanyDocument,
      ACurrentVersion: string;
      const AArquivoIni: string = '');
    procedure ConfigurarBanco(const AHost: string; APort: Integer;
      const AUser, APassword, ADatabase: string;
      const ABackupExe: string = '');
    property BaseUrl: string read FBaseUrl;
    property Token: string read FToken;
    property Company: string read FCompany;
    property CompanyName: string read FCompanyName;
    property CompanyDocument: string read FCompanyDocument;
    property Terminal: string read FTerminal;
    property Product: string read FProduct;
    property Channel: string read FChannel;
    property CurrentVersion: string read FCurrentVersion;
    property EntryPoint: string read FEntryPoint;
    property Processes: string read FProcesses;
    property CloseTimeoutSeconds: Integer read FCloseTimeoutSeconds;
  end;

  TConsultaAtualizacao = record
    Codigo: Cardinal;
    Disponivel, Obrigatoria: Boolean;
    Versao, ReleaseId, Notas, MensagemErro: string;
  end;

  TAtualizacaoPDV = class
  private
    class var FReportandoErro: Integer;
    FConfig: TAtualizacaoConfig;
    FAtualizadorExe: string;
    function Parametros(const AModo, AResultFile, AErrorFile: string): string;
    function ParametrosParaLog(const AParametros: string): string;
    function ExecutarEAguardar(const AParametros: string;
      out ACodigo: Cardinal): Boolean;
    function LerArquivo(const AArquivo: string): string;
    procedure GravarLog(const AMensagem: string);
    procedure LerResultado(const AArquivo: string;
      var AResultado: TConsultaAtualizacao);
  public
    constructor Create(AConfig: TAtualizacaoConfig;
      const AAtualizadorExe: string = '');
    destructor Destroy; override;
    function Consultar: TConsultaAtualizacao;
    function IniciarAtualizacao(const AReleaseId: string;
      out AMensagemErro: string): Boolean;
    class procedure ReportarErro(const AConfig: TAtualizacaoConfig;
      const AStackTrace, AUsuario, ASessao, ATerminal, AMacAddress: string;
      ACaixa: Integer; const AException: Exception;
      ACapturarPrint: Boolean; AJanela: NativeUInt = 0); static;
  end;

implementation

uses Winapi.Windows, Winapi.ShellAPI, System.Classes, System.Hash,
  System.Variants,
  System.IOUtils, System.JSON, System.StrUtils, System.Net.HttpClient,
  System.Net.URLClient, System.NetEncoding, Vcl.Graphics,
  Vcl.Imaging.pngimage, conexao, uGlobais;

type
  TBcryptHandle = Pointer;
  PBcryptHandle = ^TBcryptHandle;
  NTSTATUS = LongInt;

  TBcryptAuthenticatedCipherModeInfo = record
    cbSize: ULONG;
    dwInfoVersion: ULONG;
    pbNonce: PByte;
    cbNonce: ULONG;
    pbAuthData: PByte;
    cbAuthData: ULONG;
    pbTag: PByte;
    cbTag: ULONG;
    pbMacContext: PByte;
    cbMacContext: ULONG;
    cbAAD: ULONG;
    cbData: UInt64;
    dwFlags: ULONG;
  end;

const
  BCRYPT_ALG_HANDLE_HMAC_FLAG = $00000008;
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;
  BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO_VERSION = 1;
  STATUS_SUCCESS = 0;
  ERROR_KDF_INFO = 'central-atualizacao:error-payload:v1';

function BCryptOpenAlgorithmProvider(phAlgorithm: PBcryptHandle;
  pszAlgId, pszImplementation: PWideChar; dwFlags: ULONG): NTSTATUS; stdcall;
  external 'bcrypt.dll';
function BCryptCloseAlgorithmProvider(hAlgorithm: TBcryptHandle;
  dwFlags: ULONG): NTSTATUS; stdcall; external 'bcrypt.dll';
function BCryptGetProperty(hObject: TBcryptHandle; pszProperty: PWideChar;
  pbOutput: PByte; cbOutput: ULONG; out pcbResult: ULONG;
  dwFlags: ULONG): NTSTATUS; stdcall; external 'bcrypt.dll';
function BCryptSetProperty(hObject: TBcryptHandle; pszProperty: PWideChar;
  pbInput: PByte; cbInput, dwFlags: ULONG): NTSTATUS; stdcall;
  external 'bcrypt.dll';
function BCryptCreateHash(hAlgorithm: TBcryptHandle; out phHash: TBcryptHandle;
  pbHashObject: PByte; cbHashObject: ULONG; pbSecret: PByte;
  cbSecret, dwFlags: ULONG): NTSTATUS; stdcall; external 'bcrypt.dll';
function BCryptHashData(hHash: TBcryptHandle; pbInput: PByte;
  cbInput, dwFlags: ULONG): NTSTATUS; stdcall; external 'bcrypt.dll';
function BCryptFinishHash(hHash: TBcryptHandle; pbOutput: PByte;
  cbOutput, dwFlags: ULONG): NTSTATUS; stdcall; external 'bcrypt.dll';
function BCryptDestroyHash(hHash: TBcryptHandle): NTSTATUS; stdcall;
  external 'bcrypt.dll';
function BCryptGenRandom(hAlgorithm: TBcryptHandle; pbBuffer: PByte;
  cbBuffer, dwFlags: ULONG): NTSTATUS; stdcall; external 'bcrypt.dll';
function BCryptGenerateSymmetricKey(hAlgorithm: TBcryptHandle;
  out phKey: TBcryptHandle; pbKeyObject: PByte; cbKeyObject: ULONG;
  pbSecret: PByte; cbSecret, dwFlags: ULONG): NTSTATUS; stdcall;
  external 'bcrypt.dll';
function BCryptDestroyKey(hKey: TBcryptHandle): NTSTATUS; stdcall;
  external 'bcrypt.dll';
function BCryptEncrypt(hKey: TBcryptHandle; pbInput: PByte; cbInput: ULONG;
  pPaddingInfo: Pointer; pbIV: PByte; cbIV: ULONG; pbOutput: PByte;
  cbOutput: ULONG; out pcbResult: ULONG; dwFlags: ULONG): NTSTATUS; stdcall;
  external 'bcrypt.dll';
function PrintWindow(hWnd: HWND; hdcBlt: HDC; nFlags: UINT): BOOL; stdcall;
  external 'user32.dll';

procedure VerificarStatus(AStatus: NTSTATUS; const AOperacao: string);
begin
  if AStatus <> STATUS_SUCCESS then
    raise Exception.CreateFmt('Falha criptográfica em %s (0x%.8x)',
      [AOperacao, Cardinal(AStatus)]);
end;

function PrimeiroByte(var ABytes: TBytes): PByte;
begin
  if Length(ABytes) = 0 then
    Result := nil
  else
    Result := @ABytes[0];
end;

function BytesPtr(const ABytes: TBytes): PByte;
begin
  if Length(ABytes) = 0 then
    Result := nil
  else
    Result := @ABytes[0];
end;

procedure LimparBytes(var ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    FillChar(ABytes[0], Length(ABytes), 0);
  ABytes := nil;
end;

procedure GerarBytesAleatorios(var ABytes: TBytes; ATamanho: Integer);
begin
  SetLength(ABytes, ATamanho);
  VerificarStatus(BCryptGenRandom(nil, PrimeiroByte(ABytes), Length(ABytes),
    BCRYPT_USE_SYSTEM_PREFERRED_RNG), 'geração aleatória');
end;

function HmacSha256(const AChave, ADados: TBytes): TBytes;
var
  Algoritmo, Hash: TBcryptHandle;
  ObjetoHash: TBytes;
  TamanhoObjeto, TamanhoHash, Recebido: ULONG;
begin
  Algoritmo := nil;
  Hash := nil;
  VerificarStatus(BCryptOpenAlgorithmProvider(@Algoritmo, 'SHA256', nil,
    BCRYPT_ALG_HANDLE_HMAC_FLAG), 'abertura do SHA-256');
  try
    VerificarStatus(BCryptGetProperty(Algoritmo, 'ObjectLength',
      @TamanhoObjeto, SizeOf(TamanhoObjeto), Recebido, 0), 'tamanho do HMAC');
    VerificarStatus(BCryptGetProperty(Algoritmo, 'HashDigestLength',
      @TamanhoHash, SizeOf(TamanhoHash), Recebido, 0), 'tamanho do SHA-256');
    SetLength(ObjetoHash, TamanhoObjeto);
    SetLength(Result, TamanhoHash);
    VerificarStatus(BCryptCreateHash(Algoritmo, Hash,
      PrimeiroByte(ObjetoHash), Length(ObjetoHash),
      BytesPtr(AChave), Length(AChave), 0), 'criação do HMAC');
    try
      if Length(ADados) > 0 then
        VerificarStatus(BCryptHashData(Hash, @ADados[0], Length(ADados), 0),
          'processamento do HMAC');
      VerificarStatus(BCryptFinishHash(Hash, PrimeiroByte(Result),
        Length(Result), 0), 'finalização do HMAC');
    finally
      BCryptDestroyHash(Hash);
    end;
  finally
    LimparBytes(ObjetoHash);
    BCryptCloseAlgorithmProvider(Algoritmo, 0);
  end;
end;

function DerivarChaveHkdfSha256(const ATerminalId, AToken: string;
  const ASalt: TBytes): TBytes;
var
  IKM, Info, Dados, PRK: TBytes;
begin
  IKM := TEncoding.UTF8.GetBytes(LowerCase(Trim(ATerminalId)) + ':' + AToken);
  Info := TEncoding.UTF8.GetBytes(ERROR_KDF_INFO);
  try
    PRK := HmacSha256(ASalt, IKM);
    try
      SetLength(Dados, Length(Info) + 1);
      if Length(Info) > 0 then
        Move(Info[0], Dados[0], Length(Info));
      Dados[High(Dados)] := 1;
      Result := HmacSha256(PRK, Dados);
    finally
      LimparBytes(PRK);
      LimparBytes(Dados);
    end;
  finally
    LimparBytes(IKM);
    LimparBytes(Info);
  end;
end;

procedure CriptografarAes256Gcm(const AChave, AIV, ATexto: TBytes;
  out ACiphertext, ATag: TBytes);
var
  Algoritmo, Chave: TBcryptHandle;
  ObjetoChave: TBytes;
  TamanhoObjeto, Recebido, Gravado: ULONG;
  Modo: string;
  Info: TBcryptAuthenticatedCipherModeInfo;
begin
  Algoritmo := nil;
  Chave := nil;
  VerificarStatus(BCryptOpenAlgorithmProvider(@Algoritmo, 'AES', nil, 0),
    'abertura do AES');
  try
    Modo := 'ChainingModeGCM';
    VerificarStatus(BCryptSetProperty(Algoritmo, 'ChainingMode',
      PByte(PWideChar(Modo)), (Length(Modo) + 1) * SizeOf(Char), 0),
      'configuração do AES-GCM');
    VerificarStatus(BCryptGetProperty(Algoritmo, 'ObjectLength',
      @TamanhoObjeto, SizeOf(TamanhoObjeto), Recebido, 0),
      'tamanho da chave AES');
    SetLength(ObjetoChave, TamanhoObjeto);
    VerificarStatus(BCryptGenerateSymmetricKey(Algoritmo, Chave,
      PrimeiroByte(ObjetoChave), Length(ObjetoChave),
      BytesPtr(AChave), Length(AChave), 0), 'criação da chave AES');
    try
      SetLength(ACiphertext, Length(ATexto));
      SetLength(ATag, 16);
      ZeroMemory(@Info, SizeOf(Info));
      Info.cbSize := SizeOf(Info);
      Info.dwInfoVersion := BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO_VERSION;
      if Length(AIV) > 0 then Info.pbNonce := @AIV[0];
      Info.cbNonce := Length(AIV);
      Info.pbTag := PrimeiroByte(ATag);
      Info.cbTag := Length(ATag);
      VerificarStatus(BCryptEncrypt(Chave, BytesPtr(ATexto),
        Length(ATexto), @Info, nil, 0, PrimeiroByte(ACiphertext),
        Length(ACiphertext), Gravado, 0), 'criptografia AES-GCM');
      SetLength(ACiphertext, Gravado);
    finally
      BCryptDestroyKey(Chave);
    end;
  finally
    LimparBytes(ObjetoChave);
    BCryptCloseAlgorithmProvider(Algoritmo, 0);
  end;
end;

function CapturarJanelaPngBase64(AJanela: HWND): string;
const
  PW_RENDERFULLCONTENT = $00000002;
var
  Retangulo: TRect;
  Bitmap: TBitmap;
  PNG: TPngImage;
  Stream: TMemoryStream;
  DC: HDC;
  Capturado: Boolean;
  Bytes: TBytes;
begin
  Result := '';
  if (AJanela = 0) or not IsWindow(AJanela) or
     not GetWindowRect(AJanela, Retangulo) then
    Exit;
  if (Retangulo.Right <= Retangulo.Left) or
     (Retangulo.Bottom <= Retangulo.Top) then
    Exit;
  Bitmap := TBitmap.Create;
  PNG := TPngImage.Create;
  Stream := TMemoryStream.Create;
  try
    Bitmap.PixelFormat := pf24bit;
    Bitmap.SetSize(Retangulo.Right - Retangulo.Left,
      Retangulo.Bottom - Retangulo.Top);
    Capturado := PrintWindow(AJanela, Bitmap.Canvas.Handle,
      PW_RENDERFULLCONTENT);
    if not Capturado then
    begin
      DC := GetWindowDC(AJanela);
      if DC = 0 then Exit;
      try
        Capturado := BitBlt(Bitmap.Canvas.Handle, 0, 0, Bitmap.Width,
          Bitmap.Height, DC, 0, 0, SRCCOPY);
      finally
        ReleaseDC(AJanela, DC);
      end;
    end;
    if not Capturado then Exit;
    PNG.Assign(Bitmap);
    PNG.SaveToStream(Stream);
    SetLength(Bytes, Stream.Size);
    Stream.Position := 0;
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
    Result := 'data:image/png;base64,' +
      TNetEncoding.Base64.EncodeBytesToString(Bytes);
  finally
    LimparBytes(Bytes);
    Stream.Free;
    PNG.Free;
    Bitmap.Free;
  end;
end;

function CapturarAreaPdvPngBase64(AJanelaPrincipal: HWND): string;
var
  Retangulo: TRect;
  Bitmap: TBitmap;
  PNG: TPngImage;
  Stream: TMemoryStream;
  DC: HDC;
  Bytes: TBytes;
begin
  Result := '';
  if (AJanelaPrincipal = 0) or not IsWindow(AJanelaPrincipal) or
     not GetWindowRect(AJanelaPrincipal, Retangulo) then
    Exit;
  Bitmap := TBitmap.Create;
  PNG := TPngImage.Create;
  Stream := TMemoryStream.Create;
  try
    Bitmap.PixelFormat := pf24bit;
    Bitmap.SetSize(Retangulo.Right - Retangulo.Left,
      Retangulo.Bottom - Retangulo.Top);
    DC := GetDC(0);
    if DC = 0 then Exit;
    try
      if not BitBlt(Bitmap.Canvas.Handle, 0, 0, Bitmap.Width, Bitmap.Height,
        DC, Retangulo.Left, Retangulo.Top, SRCCOPY) then
        Exit;
    finally
      ReleaseDC(0, DC);
    end;
    PNG.Assign(Bitmap);
    PNG.SaveToStream(Stream);
    SetLength(Bytes, Stream.Size);
    Stream.Position := 0;
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
    Result := 'data:image/png;base64,' +
      TNetEncoding.Base64.EncodeBytesToString(Bytes);
  finally
    LimparBytes(Bytes);
    Stream.Free;
    PNG.Free;
    Bitmap.Free;
  end;
end;

function MontarDiagnosticoJson(const AData, AVersao, ATerminal,
  ACaixa, AComputador, AMac, AUsuario, ASessao, AClasse, AMensagem,
  AStackTrace, APrint: string): string;
var
  Json: TJSONObject;
begin
  Json := TJSONObject.Create;
  try
    Json.AddPair('date', AData);
    Json.AddPair('version', AVersao);
    Json.AddPair('terminal', ATerminal);
    Json.AddPair('checkoutNumber', ACaixa);
    Json.AddPair('computerName', AComputador);
    Json.AddPair('macAddress', AMac);
    Json.AddPair('userName', AUsuario);
    Json.AddPair('sessionId', ASessao);
    Json.AddPair('exceptionClass', AClasse);
    Json.AddPair('message', AMensagem);
    Json.AddPair('stackTrace', AStackTrace);
    if APrint <> '' then
      Json.AddPair('screenshotBase64', APrint);
    Result := Json.ToJSON;
  finally
    Json.Free;
  end;
end;

function MontarEnvelopeJson(const ATerminalId, AProduct: string;
  const ASalt, AIV, ATag, ACiphertext: TBytes): string;
var
  Json: TJSONObject;
begin
  Json := TJSONObject.Create;
  try
    Json.AddPair('terminalId', ATerminalId);
    Json.AddPair('product', AProduct);
    Json.AddPair('salt', TNetEncoding.Base64.EncodeBytesToString(ASalt));
    Json.AddPair('iv', TNetEncoding.Base64.EncodeBytesToString(AIV));
    Json.AddPair('authTag', TNetEncoding.Base64.EncodeBytesToString(ATag));
    Json.AddPair('ciphertext',
      TNetEncoding.Base64.EncodeBytesToString(ACiphertext));
    Result := Json.ToJSON;
  finally
    Json.Free;
  end;
end;

procedure RegistrarFalhaReporter(const AMensagem: string);
var
  Log: TStringList;
  Arquivo: string;
begin
  try
    Arquivo := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'diagnostic-reporter.log');
    Log := TStringList.Create;
    try
      if TFile.Exists(Arquivo) then
        Log.LoadFromFile(Arquivo, TEncoding.UTF8);
      Log.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now) + ' - ' + AMensagem);
      while Log.Count > 200 do Log.Delete(0);
      Log.SaveToFile(Arquivo, TEncoding.UTF8);
    finally
      Log.Free;
    end;
  except
    { Uma falha no log auxiliar não pode gerar outro diagnóstico. }
  end;
end;

procedure EnviarEnvelope(const ABaseUrl, AToken, AEnvelope: string);
var
  Cliente: THTTPClient;
  Conteudo: TStringStream;
  Resposta: IHTTPResponse;
  Cabecalhos: TNetHeaders;
begin
  Cliente := THTTPClient.Create;
  Conteudo := TStringStream.Create(AEnvelope, TEncoding.UTF8);
  try
    Cliente.ConnectionTimeout := 3000;
    Cliente.ResponseTimeout := 5000;
    SetLength(Cabecalhos, 2);
    Cabecalhos[0] := TNameValuePair.Create('Authorization',
      'Bearer ' + AToken);
    Cabecalhos[1] := TNameValuePair.Create('Content-Type',
      'application/json');
    Resposta := Cliente.Post(ABaseUrl.TrimRight(['/']) + '/api/v1/errors',
      Conteudo, nil, Cabecalhos);
    case Resposta.StatusCode of
      201: ;
      400: RegistrarFalhaReporter(
        'Diagnóstico rejeitado pelo servidor (HTTP 400)');
      401: RegistrarFalhaReporter(
        'INSTALLATION_KEY inválida para o envio de diagnóstico (HTTP 401)');
    else
      RegistrarFalhaReporter(Format(
        'Falha ao enviar diagnóstico (HTTP %d)', [Resposta.StatusCode]));
    end;
  finally
    Conteudo.Free;
    Cliente.Free;
  end;
end;

function Quoted(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '\"', [rfReplaceAll]) + '"';
end;

function MascaraParametro(const AParametros, ANome: string): string;
var
  Inicio, Fim: Integer;
  Prefixo: string;
begin
  Result := AParametros;
  Prefixo := '/' + ANome + '=';
  Inicio := Pos(LowerCase(Prefixo), LowerCase(Result));
  if Inicio = 0 then
    Exit;

  Fim := Inicio + Length(Prefixo);
  if (Fim <= Length(Result)) and (Result[Fim] = '"') then
  begin
    Inc(Fim);
    while (Fim <= Length(Result)) and (Result[Fim] <> '"') do
      Inc(Fim);
  end
  else
    while (Fim <= Length(Result)) and (Result[Fim] <> ' ') do
      Inc(Fim);

  Result := Copy(Result, 1, Inicio + Length(Prefixo) - 1) + '"***"' +
    Copy(Result, Fim + 1, MaxInt);
end;

constructor TAtualizacaoConfig.Create(const ACompanyName, ACompanyDocument,
  ACurrentVersion, AArquivoIni: string);
var
  Conexao: TConexao;
  ArquivoVersaoInstalada, Ambiente: string;

  function Configuracao(const AChave: string): string;
  begin
    Result := VarToStr(Conexao.GetParametro(AChave)).Trim;
  end;

  function PrimeiroValorConfigurado(const AChaves: array of string): string;
  var
    I: Integer;
  begin
    Result := '';
    for I := Low(AChaves) to High(AChaves) do
    begin
      Result := Configuracao(AChaves[I]);
      if Result <> '' then
        Exit;
    end;
  end;

  function CanalAtualizacao(const AAmbiente: string): string;
  begin
    if SameText(AAmbiente, 'testes') or SameText(AAmbiente, 'teste') or
       SameText(AAmbiente, 'test') then
      Result := 'test'
    else if SameText(AAmbiente, 'beta') then
      Result := 'beta'
    else
      Result := 'production';
  end;
begin
  inherited Create;
  Conexao := TConexao.Create('TAtualizacaoConfig');
  try
    FBaseUrl := Configuracao('atualizacao_url').TrimRight(['/']);
    FToken := Configuracao('atualizacao_token');

    FCompanyDocument := ACompanyDocument.Trim;
    if FCompanyDocument = '' then
      FCompanyDocument := Configuracao('cnpj');

    FCompanyName := ACompanyName.Trim;
    if FCompanyName = '' then
      FCompanyName := PrimeiroValorConfigurado([
        'nome_empresa',
        'razao_social',
        'razao',
        'nome'
      ]);

    FCompany := FCompanyDocument;

    FTerminal := NovoIdEstacao;
    FProduct := 'servidor';
    Ambiente := Configuracao('atualizacao_ambiente');
    FChannel := CanalAtualizacao(Ambiente);

    FCurrentVersion := ACurrentVersion.Trim;
    if FCurrentVersion = '' then
      FCurrentVersion := '0.0.0';

    ArquivoVersaoInstalada := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'installed.version');
    if TFile.Exists(ArquivoVersaoInstalada) then
      FCurrentVersion := TFile.ReadAllText(ArquivoVersaoInstalada,
        TEncoding.UTF8).Trim;

    FEntryPoint := ExtractFileName(ParamStr(0));
    FProcesses := Configuracao('atualizacao_executaveis');
    if FProcesses = '' then
      FProcesses := 'atualizador.exe;GooPedir.exe;ServicosGoopedir.exe;SiteGooPedir.exe;ImpressaoGooPedir.exe;NFCe.exe;WhatsappGoPedir.exe;psGoopedir.exe';
    FCloseTimeoutSeconds := 30;

    FBackupExe := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Backup.exe');
    FDbPort := 5432;
  finally
    Conexao.Free;
  end;
  Validar;
end;

procedure TAtualizacaoConfig.ConfigurarBanco(const AHost: string; APort: Integer;
  const AUser, APassword, ADatabase, ABackupExe: string);
begin
  if AHost.Contains('"') or AUser.Contains('"') or APassword.Contains('"') or
    ADatabase.Contains('"') or AHost.Contains(#13) or AHost.Contains(#10) or
    AUser.Contains(#13) or AUser.Contains(#10) or APassword.Contains(#13) or
    APassword.Contains(#10) or ADatabase.Contains(#13) or ADatabase.Contains(#10) then
    raise Exception.Create('Dados da conexão contêm caractere inválido para execução do backup');
  FDbHost := AHost.Trim;
  FDbPort := APort;
  FDbUser := AUser.Trim;
  FDbPassword := APassword;
  FDbName := ADatabase.Trim;
  if ABackupExe <> '' then FBackupExe := ExpandFileName(ABackupExe);
  if FDbHost = '' then raise Exception.Create('Host do banco não informado');
  if (FDbPort < 1) or (FDbPort > 65535) then raise Exception.Create('Porta do banco inválida');
  if FDbUser = '' then raise Exception.Create('Usuário do banco não informado');
  if FDbPassword = '' then raise Exception.Create('Senha do banco não informada');
  if FDbName = '' then raise Exception.Create('Banco não informado');
end;

function TAtualizacaoConfig.NovoIdEstacao: string;
var
  Serial: string;
begin
  Serial := LowerCase(Trim(GetMotherboardSerial));
  if Serial = '' then
    Serial := LowerCase(Trim(GetEnvironmentVariable('COMPUTERNAME')));
  if Serial = '' then
    Serial := 'terminal-sem-identificador';

  Result := THashSHA2.GetHashString(Serial, THashSHA2.TSHA2Version.SHA256);
  Result := Copy(LowerCase(Result), 1, 32);
end;

procedure TAtualizacaoConfig.Validar;
begin
  if FBaseUrl = '' then raise Exception.Create('URL de atualização não informada em configuracoes.atualizacao_url');
  if FToken = '' then raise Exception.Create('Token de atualização não informado em configuracoes.atualizacao_token');
  if (FCompany = '') or SameText(FCompany, 'UUID-ESTAVEL-DO-CLIENTE') then
    raise Exception.Create('Identificador global da empresa não informado para a atualização');
  if FCompanyName = '' then
    raise Exception.Create('Nome da empresa não informado para a atualização');
  if FCompanyDocument = '' then
    raise Exception.Create('Documento da empresa não informado para a atualização');
  if FProduct = '' then raise Exception.Create('Produto não informado para a atualização');
  if not MatchText(FChannel, ['test', 'beta', 'production']) then raise Exception.Create('Canal inválido: ' + FChannel);
  if FCurrentVersion = '' then raise Exception.Create('Versão atual não informada');
  if FCloseTimeoutSeconds < 1 then raise Exception.Create('CloseTimeoutSeconds deve ser maior que zero');
end;

constructor TAtualizacaoPDV.Create(AConfig: TAtualizacaoConfig;
  const AAtualizadorExe: string);
begin
  inherited Create;
  if not Assigned(AConfig) then raise Exception.Create('Configuração não informada');
  FConfig := AConfig;
  if AAtualizadorExe <> '' then FAtualizadorExe := ExpandFileName(AAtualizadorExe)
  else FAtualizadorExe := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Atualizador.exe');
end;

destructor TAtualizacaoPDV.Destroy;
begin
  FConfig.Free;
  inherited;
end;

function TAtualizacaoPDV.Parametros(const AModo, AResultFile,
  AErrorFile: string): string;
var
  Processos: string;

  function ProcessosParaAtualizacao(const AProcessos: string): string;
  var
    Item: string;
    NomeServidor: string;
    NomeAtualizador: string;
  begin
    Result := '';
    NomeServidor := ExtractFileName(ParamStr(0));
    NomeAtualizador := ExtractFileName(FAtualizadorExe);
    for Item in AProcessos.Split([';'], TStringSplitOptions.ExcludeEmpty) do
      if not SameText(Trim(Item), NomeServidor) and
         not SameText(Trim(Item), NomeAtualizador) then
      begin
        if Result <> '' then
          Result := Result + ';';
        Result := Result + Trim(Item);
      end;
  end;
begin
  Processos := FConfig.Processes;
  if SameText(AModo, 'atualizar') then
    Processos := ProcessosParaAtualizacao(Processos);

  Result := '/' + AModo + ' /baseurl=' + Quoted(FConfig.BaseUrl) +
    ' /token=' + Quoted(FConfig.Token) + ' /empresa=' + Quoted(FConfig.Company) +
    ' /empresanome=' + Quoted(FConfig.CompanyName) +
    ' /empresadocumento=' + Quoted(FConfig.CompanyDocument) +
    ' /estacao=' + Quoted(FConfig.Terminal) + ' /produto=' + Quoted(FConfig.Product) +
    ' /canal=' + Quoted(FConfig.Channel) + ' /versao=' + Quoted(FConfig.CurrentVersion) +
    ' /installdirectory=' + Quoted(ExcludeTrailingPathDelimiter(
      ExtractFilePath(ParamStr(0)))) +
    ' /entrypoint=' + Quoted(FConfig.EntryPoint) + ' /processos=' + Quoted(Processos) +
    ' /closetimeoutseconds=' + IntToStr(FConfig.CloseTimeoutSeconds);
  if AResultFile <> '' then Result := Result + ' /resultfile=' + Quoted(AResultFile);
  if AErrorFile <> '' then Result := Result + ' /errorfile=' + Quoted(AErrorFile);
  if SameText(AModo, 'atualizar') then
  begin
    if TFile.Exists(FConfig.FBackupExe) then
      Result := Result + ' /backupexe=' + Quoted(FConfig.FBackupExe);
    Result := Result + ' /dbhost=' + Quoted(FConfig.FDbHost) +
      ' /dbporta=' + IntToStr(FConfig.FDbPort) +
      ' /dbusuario=' + Quoted(FConfig.FDbUser) +
      ' /dbsenha=' + Quoted(FConfig.FDbPassword) +
      ' /dbbanco=' + Quoted(FConfig.FDbName);
  end;
end;

function TAtualizacaoPDV.ParametrosParaLog(const AParametros: string): string;
begin
  Result := AParametros;
  Result := MascaraParametro(Result, 'token');
  Result := MascaraParametro(Result, 'dbsenha');
end;

procedure TAtualizacaoPDV.GravarLog(const AMensagem: string);
var
  Diretorio, Arquivo: string;
begin
  try
    Diretorio := TPath.Combine(ExtractFilePath(ParamStr(0)), 'log');
    TDirectory.CreateDirectory(Diretorio);
    Arquivo := TPath.Combine(Diretorio, 'atualizacao-pdv.log');
    TFile.AppendAllText(Arquivo, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) +
      ' ' + AMensagem + sLineBreak, TEncoding.UTF8);
  except
  end;
end;

function TAtualizacaoPDV.ExecutarEAguardar(const AParametros: string;
  out ACodigo: Cardinal): Boolean;
var
  Info: TShellExecuteInfo;
  Diretorio: string;
begin
  ACodigo := ATU_ERRO_CRITICO;
  if not TFile.Exists(FAtualizadorExe) then raise Exception.Create('Atualizador.exe não encontrado: ' + FAtualizadorExe);
  ZeroMemory(@Info, SizeOf(Info));
  Info.cbSize := SizeOf(Info); Info.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
  Info.lpVerb := 'open'; Info.lpFile := PChar(FAtualizadorExe);
  Diretorio := ExtractFilePath(FAtualizadorExe);
  Info.lpParameters := PChar(AParametros); Info.lpDirectory := PChar(Diretorio); Info.nShow := SW_HIDE;
  if not ShellExecuteEx(@Info) then RaiseLastOSError;
  try
    if WaitForSingleObject(Info.hProcess, INFINITE) <> WAIT_OBJECT_0 then RaiseLastOSError;
    if not GetExitCodeProcess(Info.hProcess, ACodigo) then RaiseLastOSError;
    Result := True;
  finally
    CloseHandle(Info.hProcess);
  end;
end;

function TAtualizacaoPDV.LerArquivo(const AArquivo: string): string;
begin
  Result := '';
  if TFile.Exists(AArquivo) then
    try Result := TFile.ReadAllText(AArquivo, TEncoding.UTF8).Trim; except Result := ''; end;
end;

procedure TAtualizacaoPDV.LerResultado(const AArquivo: string;
  var AResultado: TConsultaAtualizacao);
var Json: TJSONObject;
begin
  if not TFile.Exists(AArquivo) then Exit;
  Json := TJSONObject.ParseJSONValue(TFile.ReadAllText(AArquivo, TEncoding.UTF8)) as TJSONObject;
  try
    if not Assigned(Json) then raise Exception.Create('Resultado inválido do atualizador');
    Json.TryGetValue<Boolean>('available', AResultado.Disponivel);
    Json.TryGetValue<Boolean>('mandatory', AResultado.Obrigatoria);
    Json.TryGetValue<string>('version', AResultado.Versao);
    Json.TryGetValue<string>('releaseId', AResultado.ReleaseId);
    Json.TryGetValue<string>('notes', AResultado.Notas);
  finally Json.Free; end;
end;

function TAtualizacaoPDV.Consultar: TConsultaAtualizacao;
var ResultFile, ErrorFile: string;
begin
  Result := Default(TConsultaAtualizacao);
  ResultFile := TPath.GetTempFileName; ErrorFile := TPath.GetTempFileName;
  try
    ExecutarEAguardar(Parametros('consultar', ResultFile, ErrorFile), Result.Codigo);
    Result.Disponivel := Result.Codigo in [ATU_DISPONIVEL, ATU_OBRIGATORIA];
    Result.Obrigatoria := Result.Codigo = ATU_OBRIGATORIA;
    if Result.Disponivel then LerResultado(ResultFile, Result);
    if Result.Codigo >= ATU_ERRO_PARAMETROS then Result.MensagemErro := LerArquivo(ErrorFile);
  finally
    if TFile.Exists(ResultFile) then TFile.Delete(ResultFile);
    if TFile.Exists(ErrorFile) then TFile.Delete(ErrorFile);
  end;
end;

function TAtualizacaoPDV.IniciarAtualizacao(const AReleaseId: string;
  out AMensagemErro: string): Boolean;
var
  Info: TShellExecuteInfo;
  Codigo: Cardinal;
  Espera: DWORD;
  ResultFile, ErrorFile, ParametrosAtualizacao, Diretorio: string;
begin
  Result := False; AMensagemErro := '';
  if not TFile.Exists(FAtualizadorExe) then begin AMensagemErro := 'Atualizador.exe não encontrado: ' + FAtualizadorExe; Exit; end;
  ResultFile := TPath.Combine(TPath.GetTempPath, 'updater-result-' + FConfig.Terminal + '.json');
  ErrorFile := TPath.Combine(TPath.GetTempPath, 'updater-error-' + FConfig.Terminal + '.txt');
  if AReleaseId.Trim = '' then begin AMensagemErro := 'releaseId não informado'; Exit; end;
  if TFile.Exists(ResultFile) then TFile.Delete(ResultFile);
  if TFile.Exists(ErrorFile) then TFile.Delete(ErrorFile);
  ParametrosAtualizacao := Parametros('atualizar', ResultFile, ErrorFile) +
    ' /releaseid=' + Quoted(AReleaseId);
  GravarLog('Iniciando Atualizador.exe em /atualizar');
  GravarLog('Exe=' + FAtualizadorExe);
  GravarLog('Parametros=' + ParametrosParaLog(ParametrosAtualizacao));
  Diretorio := ExtractFilePath(FAtualizadorExe);
  ZeroMemory(@Info, SizeOf(Info));
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
  Info.lpVerb := 'open'; Info.lpFile := PChar(FAtualizadorExe);
  Info.lpParameters := PChar(ParametrosAtualizacao);
  Info.lpDirectory := PChar(Diretorio); Info.nShow := SW_SHOWNORMAL;
  Result := ShellExecuteEx(@Info);
  if not Result then
  begin
    AMensagemErro := SysErrorMessage(GetLastError);
    GravarLog('Falha ao abrir Atualizador.exe: ' + AMensagemErro);
    Exit;
  end;

  try
    GravarLog('Atualizador.exe aberto. Aguardando inicialização...');
    Espera := WaitForSingleObject(Info.hProcess, 5000);
    if Espera = WAIT_TIMEOUT then
    begin
      GravarLog('Atualizador.exe continua em execução. Atualização iniciada.');
      Result := True;
      Exit;
    end;
    if Espera <> WAIT_OBJECT_0 then
      RaiseLastOSError;
    if not GetExitCodeProcess(Info.hProcess, Codigo) then
      RaiseLastOSError;
    GravarLog('Atualizador.exe finalizou durante a inicialização com código ' + IntToStr(Codigo));
    Result := Codigo = ATU_APLICADA;
    if not Result then
      AMensagemErro := LerArquivo(ErrorFile);
    if not Result and (AMensagemErro = '') then
      AMensagemErro := 'Atualizador finalizou com código ' + IntToStr(Codigo);
    if AMensagemErro <> '' then
      GravarLog('Erro retornado=' + AMensagemErro);
    if TFile.Exists(ResultFile) then
      GravarLog('Resultado=' + LerArquivo(ResultFile));
  finally
    CloseHandle(Info.hProcess);
  end;
end;

class procedure TAtualizacaoPDV.ReportarErro(
  const AConfig: TAtualizacaoConfig; const AStackTrace, AUsuario, ASessao,
  ATerminal, AMacAddress: string; ACaixa: Integer;
  const AException: Exception; ACapturarPrint: Boolean; AJanela: NativeUInt);
var
  BaseUrl, Token, TerminalId, Product, Versao: string;
  DataErro, Usuario, Sessao, Terminal, Mac, Computador: string;
  ClasseExcecao, MensagemExcecao, StackTrace, PrintBase64: string;
  Caixa: string;
begin
  if not Assigned(AConfig) or not Assigned(AException) then Exit;
  if InterlockedCompareExchange(FReportandoErro, 1, 0) <> 0 then Exit;
  try
    BaseUrl := AConfig.BaseUrl;
    Token := AConfig.Token;
    TerminalId := LowerCase(Trim(AConfig.Terminal));
    Product := AConfig.Product;
    Versao := AConfig.CurrentVersion;
    DataErro := FormatDateTime('dd/mm/yyyy hh:nn:ss', Now);
    Usuario := AUsuario;
    Sessao := ASessao;
    Terminal := ATerminal;
    Mac := AMacAddress;
    Computador := GetEnvironmentVariable('COMPUTERNAME');
    Caixa := IntToStr(ACaixa);
  ClasseExcecao := AException.ClassName;
  MensagemExcecao := AException.Message;
  StackTrace := AStackTrace;
  PrintBase64 := '';

    TThread.CreateAnonymousThread(
      procedure
      var
        Diagnostico, Envelope: string;
        DiagnosticoBytes, Salt, IV, Chave, Ciphertext, Tag: TBytes;
        JanelaCaptura, JanelaPrincipal: HWND;
        Tentativa: Integer;
      begin
        try
          try
            if ACapturarPrint then
            begin
              JanelaPrincipal := HWND(AJanela);
              JanelaCaptura := JanelaPrincipal;
              { Aguarda o MessageDlg criado logo após o disparo do reporter. }
              for Tentativa := 1 to 10 do
              begin
                Sleep(100);
                JanelaCaptura := GetLastActivePopup(JanelaPrincipal);
                if (JanelaCaptura <> 0) and
                   (JanelaCaptura <> JanelaPrincipal) and
                   IsWindowVisible(JanelaCaptura) then
                  Break;
              end;
              try
                if (JanelaCaptura <> 0) and
                   (JanelaCaptura <> JanelaPrincipal) and
                   IsWindowVisible(JanelaCaptura) then
                  PrintBase64 := CapturarAreaPdvPngBase64(JanelaPrincipal)
                else
                  PrintBase64 := CapturarJanelaPngBase64(JanelaPrincipal);
              except
                PrintBase64 := '';
              end;
            end;
            Diagnostico := MontarDiagnosticoJson(DataErro, Versao, Terminal,
              Caixa, Computador, Mac, Usuario, Sessao, ClasseExcecao,
              MensagemExcecao, StackTrace, PrintBase64);
            DiagnosticoBytes := TEncoding.UTF8.GetBytes(Diagnostico);
            GerarBytesAleatorios(Salt, 32);
            GerarBytesAleatorios(IV, 12);
            Chave := DerivarChaveHkdfSha256(TerminalId, Token, Salt);
            CriptografarAes256Gcm(Chave, IV, DiagnosticoBytes,
              Ciphertext, Tag);
            Envelope := MontarEnvelopeJson(TerminalId, Product, Salt, IV,
              Tag, Ciphertext);
            EnviarEnvelope(BaseUrl, Token, Envelope);
          except
            RegistrarFalhaReporter(
              'Falha genérica ao preparar ou enviar diagnóstico');
          end;
        finally
          LimparBytes(Chave);
          LimparBytes(DiagnosticoBytes);
          LimparBytes(Salt);
          LimparBytes(IV);
          LimparBytes(Tag);
          LimparBytes(Ciphertext);
          Diagnostico := '';
          Envelope := '';
          PrintBase64 := '';
          Token := '';
          InterlockedExchange(FReportandoErro, 0);
        end;
      end).Start;
  except
    InterlockedExchange(FReportandoErro, 0);
  end;
end;

end.
