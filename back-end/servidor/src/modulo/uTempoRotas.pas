unit uTempoRotas;

interface

uses
  Horse;

procedure InicializarTempoRotas;
procedure TempoRotasMiddleware(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
procedure RegistrarRotasTempoRotas;

implementation

uses
  Winapi.Windows, System.SysUtils, System.JSON, conexao, uGlobais;

const
  TABELA_TEMPO_ROTAS = 'log_tempo_rotas';

procedure CriarTabelaTempoRotas;
var
  LConexao: TConexao;
begin
  LConexao := TConexao.Create('CriarTabelaTempoRotas');
  try
    LConexao.SQL.Add('CREATE TABLE IF NOT EXISTS ' + TABELA_TEMPO_ROTAS + ' (');
    LConexao.SQL.Add('  id INT NOT NULL AUTO_INCREMENT,');
    LConexao.SQL.Add('  data DATE NOT NULL,');
    LConexao.SQL.Add('  hora TIME(3) NOT NULL,');
    LConexao.SQL.Add('  data_hora DATETIME(3) NOT NULL,');
    LConexao.SQL.Add('  metodo VARCHAR(10) NOT NULL,');
    LConexao.SQL.Add('  rota VARCHAR(500) NOT NULL,');
    LConexao.SQL.Add('  tempo_ms BIGINT NOT NULL,');
    LConexao.SQL.Add('  PRIMARY KEY (id),');
    LConexao.SQL.Add('  INDEX idx_log_tempo_rotas_data_hora (data_hora),');
    LConexao.SQL.Add('  INDEX idx_log_tempo_rotas_rota (rota(191))');
    LConexao.SQL.Add(') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
    LConexao.ExecuteSQL;
  finally
    LConexao.Free;
  end;
end;

procedure GravarTempoRota(const Metodo, Rota: string; TempoMs: Int64);
var
  LConexao: TConexao;
begin
  if SameText(Rota, '/v1/desenvolvimento/rotas/tempo') then
    Exit;

  LConexao := TConexao.Create('GravarTempoRota');
  try
    LConexao.SQL.Add('INSERT INTO ' + TABELA_TEMPO_ROTAS);
    LConexao.SQL.Add('(data, hora, data_hora, metodo, rota, tempo_ms)');
    LConexao.SQL.Add('VALUES (CURRENT_DATE, CURRENT_TIME(3), CURRENT_TIMESTAMP(3), :metodo, :rota, :tempo)');
    LConexao.Parametros('metodo', Metodo);
    LConexao.Parametros('rota', Copy(Rota, 1, 500));
    LConexao.Parametros('tempo', TempoMs);
    LConexao.ExecuteSQL;
  finally
    LConexao.Free;
  end;
end;

function QueryValue(Req: THorseRequest; const Nome, Padrao: string): string;
begin
  if not Req.Query.TryGetValue(Nome, Result) then
    Result := Padrao;
end;

procedure DoConsultarTempoRotas(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LConexao: TConexao;
  DataIni, DataFim, HoraIni, HoraFim: string;
begin
  if not Desenvolvimento then
  begin
    Res.Status(403).Send('Desenvolvimento desativado');
    Exit;
  end;

  DataIni := QueryValue(Req, 'ini', FormatDateTime('yyyy-mm-dd', Date));
  DataFim := QueryValue(Req, 'fim', DataIni);
  HoraIni := QueryValue(Req, 'hrInicio', '00:00:00');
  HoraFim := QueryValue(Req, 'hrFim', '23:59:59');

  LConexao := TConexao.Create('DoConsultarTempoRotas');
  try
    LConexao.SQL.Add('SELECT');
    LConexao.SQL.Add('  id,');
    LConexao.SQL.Add('  DATE_FORMAT(data, "%Y-%m-%d") AS data,');
    LConexao.SQL.Add('  TIME_FORMAT(hora, "%H:%i:%s") AS hora,');
    LConexao.SQL.Add('  metodo,');
    LConexao.SQL.Add('  rota,');
    LConexao.SQL.Add('  tempo_ms');
    LConexao.SQL.Add('FROM ' + TABELA_TEMPO_ROTAS);
    LConexao.SQL.Add('WHERE data_hora BETWEEN STR_TO_DATE(:inicio, "%Y-%m-%d %H:%i:%s")');
    LConexao.SQL.Add('  AND STR_TO_DATE(:fim, "%Y-%m-%d %H:%i:%s")');
    LConexao.SQL.Add('ORDER BY data_hora DESC, id DESC');
    LConexao.Parametros('inicio', DataIni + ' ' + HoraIni);
    LConexao.Parametros('fim', DataFim + ' ' + HoraFim);
    Res.Send<TJSONArray>(LConexao.ConsultaSQL);
  finally
    LConexao.Free;
  end;
end;

procedure InicializarTempoRotas;
begin
  if Desenvolvimento then
    CriarTabelaTempoRotas;
end;

procedure TempoRotasMiddleware(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  Inicio: Int64;
begin
  if not Desenvolvimento then
  begin
    Next;
    Exit;
  end;

  Inicio := GetTickCount64;
  try
    Next;
  finally
    GravarTempoRota(Req.RawWebRequest.Method, Req.RawWebRequest.RawPathInfo,
      GetTickCount64 - Inicio);
  end;
end;

procedure RegistrarRotasTempoRotas;
begin
  THorse.Get('/v1/desenvolvimento/rotas/tempo', DoConsultarTempoRotas);
end;

end.
