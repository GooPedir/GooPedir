unit uGlobais;

interface

uses System.IniFiles, ComObj, ActiveX, Variants, SysUtils;

const
  // Rotas principais da sua API
  // getUrlGoopedir = 'http://localhost:3001/';
  API_FOTO = 'https://fotos.goopedir.com/';
  API_NFCE = 'https://nfce.goopedir.com/';
  // API_LOGIN = API_BASE_URL + 'auth/login';
  // API_PEDIDOS = API_BASE_URL + 'pedidos';
  // API_CLIENTES = API_BASE_URL + 'clientes';
  // API_PRODUTOS = API_BASE_URL + 'produtos';
  // API_CONFIGURACOES = API_BASE_URL + 'configuracoes';

var
  // Variáveis globais que podem mudar em tempo de execução
  UsuarioLogadoID: Integer;
  TokenJWT: string;
  EmpresaSelecionada: Integer;

function GetToken: String;
function BaseUrlLocal: String;
function LerIniString(const Secao, Chave, ValorPadrao: String): String;
function LerIniInteger(const Secao, Chave: String;
  ValorPadrao: Integer): Integer;
function LerIniBool(const Secao, Chave: String; ValorPadrao: Boolean): Boolean;
function InicializacaoHabilitada(const Chave: String;
  ValorPadrao: Boolean = True): Boolean;
procedure RegistrarConfiguracoesInicializacaoPadrao;
function getUrlGoopedir: String;
function GetMotherboardSerial: string;
function Desenvolvimento: Boolean;
function pcLocal: Boolean;
function API_BASE_URL: string;

implementation

function CaminhoIniGoopedir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'goopedir.ini';
end;

function GetToken: String;
begin
  Result := LerIniString('server', 'token', '');
end;

function BaseUrlLocal: String;
begin
  Result := LerIniString('server', 'baseurl', 'http://localhost:2121/');
end;

function LerIniString(const Secao, Chave, ValorPadrao: String): String;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(CaminhoIniGoopedir);
  try
    Result := IniFile.ReadString(Secao, Chave, ValorPadrao);
  finally
    IniFile.Free;
  end;
end;

function LerIniInteger(const Secao, Chave: String;
  ValorPadrao: Integer): Integer;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(CaminhoIniGoopedir);
  try
    Result := IniFile.ReadInteger(Secao, Chave, ValorPadrao);
  finally
    IniFile.Free;
  end;
end;

function LerIniBool(const Secao, Chave: String; ValorPadrao: Boolean): Boolean;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(CaminhoIniGoopedir);
  try
    Result := IniFile.ReadBool(Secao, Chave, ValorPadrao);
  finally
    IniFile.Free;
  end;
end;

function InicializacaoHabilitada(const Chave: String;
  ValorPadrao: Boolean = True): Boolean;
begin
  Result := LerIniBool('INICIALIZACAO', Chave, ValorPadrao);
end;

procedure RegistrarConfiguracoesInicializacaoPadrao;
var
  IniFile: TIniFile;
  valor: Boolean;
begin
  valor := false;
  IniFile := TIniFile.Create(CaminhoIniGoopedir);
  try
    IniFile.WriteBool('INICIALIZACAO', 'InicializarCodigo', valor);
    IniFile.WriteBool('INICIALIZACAO', 'IniciaIfood', valor);
    IniFile.WriteBool('INICIALIZACAO', 'FazerBackupMySQL', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TSincronizaProdutosThread', valor);
    IniFile.WriteBool('INICIALIZACAO', 'RegisterAllTasks', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TaskSabores', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TaskClientes', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TaskVendas', false);
    IniFile.WriteBool('INICIALIZACAO', 'AgentManager', valor);
    IniFile.WriteBool('INICIALIZACAO', 'AtualizaCacheSite', valor);
    IniFile.WriteBool('INICIALIZACAO', 'LoadImpressora', valor);
    IniFile.WriteBool('INICIALIZACAO', 'DadosWhatsappThread', valor);
    IniFile.WriteBool('INICIALIZACAO', 'BackupFTPTimer', valor);
  finally
    IniFile.Free;
  end;
end;

function getUrlGoopedir: String;
begin
  Result := LerIniString('goopedir', 'baseURL', API_BASE_URL);
end;

function GetMotherboardSerial: string;
var
  Locator, Services, ObjSet, Obj: OleVariant;
  Enum: IEnumVariant;
  Value: LongWord;
begin
  Result := '';

  CoInitialize(nil);
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Services := Locator.ConnectServer('.', 'root\CIMV2');

    ObjSet := Services.ExecQuery('SELECT SerialNumber FROM Win32_BaseBoard');
    Enum := IUnknown(ObjSet._NewEnum) as IEnumVariant;

    while Enum.Next(1, Obj, Value) = 0 do
    begin
      Result := VarToStr(Obj.SerialNumber);
      Break;
    end;
  finally
    CoUninitialize;
  end;
end;

function pcLocal: Boolean;
begin
  Result := false;
{$IFDEF DEBUG}
  // PC Allan (240538505700048)
  if GetMotherboardSerial() = '240538505700048' then
  begin
    Result := True;
    exit;
  end;
{$ENDIF}
end;

function Desenvolvimento: Boolean;
begin
  Result := pcLocal;
end;

function API_BASE_URL: string;
begin
  if Desenvolvimento then
    // Result := 'https://api-dev.goopedir.cloud/'
//    Result := 'http://localhost:3001/'
Result := 'https://api.goopedir.cloud/'
  else
  begin
    if pcLocal then
      Result := 'https://api-dev.goopedir.cloud/'
    else
      Result := 'https://api.goopedir.cloud/'
  end;
end;

function API_LOGIN: string;
begin
  Result := API_BASE_URL + 'auth/login';
end;

function API_PEDIDOS: string;
begin
  Result := API_BASE_URL + 'pedidos';
end;

function API_CLIENTES: string;
begin
  Result := API_BASE_URL + 'clientes';
end;

function API_PRODUTOS: string;
begin
  Result := API_BASE_URL + 'produtos';
end;

function API_CONFIGURACOES: string;
begin
  Result := API_BASE_URL + 'configuracoes';
end;

end.
