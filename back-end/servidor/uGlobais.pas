unit uGlobais;

interface

uses System.IniFiles;

const
  // Rotas principais da sua API
   API_BASE_URL = 'https://api.goopedir.cloud/';
//  API_BASE_URL = 'http://localhost:3001/';
  API_FOTO = 'https://fotos.goopedir.com/';
  API_NFCE = 'https://nfce.goopedir.com/';
  API_LOGIN = API_BASE_URL + 'auth/login';
  API_PEDIDOS = API_BASE_URL + 'pedidos';
  API_CLIENTES = API_BASE_URL + 'clientes';
  API_PRODUTOS = API_BASE_URL + 'produtos';
  API_CONFIGURACOES = API_BASE_URL + 'configuracoes';

var
  // Variáveis globais que podem mudar em tempo de execução
  UsuarioLogadoID: Integer;
  TokenJWT: string;
  EmpresaSelecionada: Integer;

function GetToken: String;
function BaseUrlLocal: String;
function LerIniString(const Secao, Chave, ValorPadrao: String): String;
function LerIniInteger(const Secao, Chave: String; ValorPadrao: Integer): Integer;
function LerIniBool(const Secao, Chave: String; ValorPadrao: Boolean): Boolean;
function InicializacaoHabilitada(const Chave: String;
  ValorPadrao: Boolean = True): Boolean;
procedure RegistrarConfiguracoesInicializacaoPadrao;

implementation

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
  IniFile := TIniFile.Create('./goopedir.ini');
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
  IniFile := TIniFile.Create('./goopedir.ini');
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
  IniFile := TIniFile.Create('./goopedir.ini');
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
  valor : Boolean;
begin
valor := false;
  IniFile := TIniFile.Create('./goopedir.ini');
  try
    IniFile.WriteBool('INICIALIZACAO', 'InicializarCodigo', valor);
    IniFile.WriteBool('INICIALIZACAO', 'IniciaIfood', valor);
    IniFile.WriteBool('INICIALIZACAO', 'FazerBackupMySQL', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TSincronizaProdutosThread', valor);
    IniFile.WriteBool('INICIALIZACAO', 'RegisterAllTasks', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TaskSabores', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TaskClientes', valor);
    IniFile.WriteBool('INICIALIZACAO', 'TaskVendas', False);
    IniFile.WriteBool('INICIALIZACAO', 'AgentManager', valor);
    IniFile.WriteBool('INICIALIZACAO', 'AtualizaCacheSite', valor);
    IniFile.WriteBool('INICIALIZACAO', 'LoadImpressora', valor);
    IniFile.WriteBool('INICIALIZACAO', 'DadosWhatsappThread', valor);
    IniFile.WriteBool('INICIALIZACAO', 'BackupFTPTimer', valor);
  finally
    IniFile.Free;
  end;
end;

end.