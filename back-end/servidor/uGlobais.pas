unit uGlobais;

interface

const
  // Rotas principais da sua API
  API_BASE_URL         = 'https://api.goopedir.com/';
  API_FOTO             = 'https://fotos.goopedir.com/';
  API_NFCE             = 'https://nfce.goopedir.com/';
  API_LOGIN            = API_BASE_URL + 'auth/login';
  API_PEDIDOS          = API_BASE_URL + 'pedidos';
  API_CLIENTES         = API_BASE_URL + 'clientes';
  API_PRODUTOS         = API_BASE_URL + 'produtos';
  API_CONFIGURACOES    = API_BASE_URL + 'configuracoes';

var
  // Variáveis globais que podem mudar em tempo de execução
  UsuarioLogadoID: Integer;
  TokenJWT: string;
  EmpresaSelecionada: Integer;

implementation

end.

