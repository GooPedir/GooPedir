unit uSite;

interface

uses util, conexao, FireDAC.Comp.Client, DataSet.Serialize, System.SysUtils,
   uInserirUpdate, Winapi.Windows, Winapi.ShellAPI, Vcl.Forms,
  uControllerSite, JOSE.Types.JSON;

// Local
function EnviaProduto(codigo: Integer; Base64Imagem: String): Integer;
procedure AlteraExtrasIguais(Categoria, Nome: String; Valor: Real;
  CodigoProdutoAtual: Integer);

function EnviaCategoria(codigo: Integer): Integer;
procedure EnviaSabores(codigoGrupo: Integer);

procedure EnviaFotoProduto(codigo: Integer; Base64: String; user: Integer);

procedure EnviaTempoDelivery(Tempo: Integer);
procedure EnviaTempoVemBuscar(Tempo: Integer);

implementation

uses uMain, System.Classes, uRequisicao, uControllCaches;

procedure EnviaTempoDelivery(Tempo: Integer);
begin
  InserirUpdate('ws_empresa', frmServidor.UserID.ToString,
    ['user_id', 'msg_tempo_delivery'], [frmServidor.UserID.ToString,
    'Aproximado ' + IntToStr(Tempo) + ' minutos.']);
end;

procedure EnviaTempoVemBuscar(Tempo: Integer);
begin
  InserirUpdate('ws_empresa', frmServidor.UserID.ToString,
    ['user_id', 'msg_tempo_buscar'], [frmServidor.UserID.ToString,
    'Aproximado ' + IntToStr(Tempo) + ' minutos.']);
end;

function EnviaCategoria(codigo: Integer): Integer;
begin
  SiteCategoria(codigo, frmServidor.UserID);
  frmServidor.AtualizaCacheSite;
end;

procedure AlteraExtrasIguais(Categoria, Nome: String; Valor: Real;
  CodigoProdutoAtual: Integer);
var
  conexao: TConexao;
  Dados: TFDMemTable;

  JsonObject: TJSONObject;
  Qry: TFDQuery;
begin
  JsonObject := TJSONObject.Create;
  JsonObject.AddPair('categoria', Categoria);
  JsonObject.AddPair('nome', Nome);
  JsonObject.AddPair('valor', Valor);
  JsonObject.AddPair('codigo', CodigoProdutoAtual);
  conexao := TConexao.Create('AlteraExtrasIguais');
  Qry := conexao.CriaQRY;
  Qry.SQL.Add('insert into fila (origem,json)');
  Qry.SQL.Add('values (:origem,:json)');
  Qry.ParamByName('origem').AsString := 'AlteraExtrasIguais';
  Qry.ParamByName('json').AsString := JsonObject.ToString;
  Qry.ExecSQL;
  Qry.Free;
  conexao.Free;
  JsonObject.Free;
end;

function EnviaProduto(codigo: Integer; Base64Imagem: String): Integer;
var
  prog: String;
  conexao: TConexao;
  Dados: TFDQuery;
begin
  frmServidor.Queue.Enfileirar(codigo);
  if Base64Imagem <> '' then
  begin
    EnviaFotoProduto(codigo, Base64Imagem, frmServidor.UserID);
  end;

  prog := ExtractFileDir(Application.ExeName) + '\ProdutoGoopedir.exe';
  ShellExecute(0, 'open', PChar(prog),PChar(codigo.ToString + ' ' + frmServidor.UserID.ToString), nil,SW_SHOWNORMAL);

end;

procedure EnviaFotoProduto(codigo: Integer; Base64: String; user: Integer);
begin
  SiteEnviaFotoProduto(codigo, Base64, user);
end;

procedure EnviaSabores(codigoGrupo: Integer);
begin
  SiteSabores(codigoGrupo, frmServidor.UserID);
end;

end.
