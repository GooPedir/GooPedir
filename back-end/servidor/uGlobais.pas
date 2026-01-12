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

implementation

function GetToken: String;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  Result := IniFile.ReadString('server', 'token', '');
  IniFile.Free;
end;

function BaseUrlLocal: String;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  Result := IniFile.ReadString('server', 'baseurl', 'http://localhost:2121/');
  IniFile.Free;
end;

end.
