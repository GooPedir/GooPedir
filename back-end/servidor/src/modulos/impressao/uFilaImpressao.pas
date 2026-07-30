unit uFilaImpressao;

interface

uses
  conexao;

function GarantirTabelaFilaImpressao(AConexao: TConexao): Boolean;
function EnfileirarImpressaoPedido(AConexao: TConexao; Codigo: Integer;
  const Tipo: string = 'PEDIDO_PRODUTO'; const Payload: string = ''): Boolean;
function EnfileirarImpressaoGo(Codigo: Integer; const Tipo: string = 'PRODUTO')
  : Boolean;

implementation

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections, System.Variants,
  uMain, uPerformanceMetrics;

var
  FilaImpressaoLock: TCriticalSection;
  FilaImpressaoChaves: TDictionary<string, TDateTime>;

function ChaveImpressao(Codigo: Integer; const Tipo: string): string;
begin
  Result := UpperCase(Trim(Tipo)) + ':' + Codigo.ToString;
end;

procedure RemoverChaveImpressao(const Chave: string);
begin
  FilaImpressaoLock.Acquire;
  try
    FilaImpressaoChaves.Remove(Chave);
  finally
    FilaImpressaoLock.Release;
  end;
end;

function EnfileirarImpressaoGo(Codigo: Integer; const Tipo: string): Boolean;
var
  Chave: string;
begin
  Result := False;
  Chave := ChaveImpressao(Codigo, Tipo);

  FilaImpressaoLock.Acquire;
  try
    if FilaImpressaoChaves.ContainsKey(Chave) then
    begin
      PerformanceStep('impressao_duplicada', 0);
      Exit;
    end;

    FilaImpressaoChaves.Add(Chave, Now);
    Result := True;
  finally
    FilaImpressaoLock.Release;
  end;

  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        frmServidor.enviarImpressaoGo(Codigo);
      except
        on E: Exception do
          PerformanceStep('impressao_worker_erro', 0);
      end;
      RemoverChaveImpressao(Chave);
    end).Start;
end;

function GarantirTabelaFilaImpressao(AConexao: TConexao): Boolean;
begin
  Result := False;
  if not Assigned(AConexao) then
    Exit;

  AConexao.ExecuteSQL(
    'CREATE TABLE IF NOT EXISTS fila_impressao (' +
    'id BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    'pedido_id BIGINT NOT NULL,' +
    'tipo VARCHAR(50) NOT NULL,' +
    'payload LONGTEXT NULL,' +
    'status VARCHAR(20) NOT NULL DEFAULT ''PENDENTE'',' +
    'tentativas INT NOT NULL DEFAULT 0,' +
    'erro TEXT NULL,' +
    'criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    'processado_em DATETIME NULL,' +
    'INDEX idx_fila_status_criado (status, criado_em),' +
    'INDEX idx_fila_pedido (pedido_id)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
  Result := True;
end;

function EnfileirarImpressaoPedido(AConexao: TConexao; Codigo: Integer;
  const Tipo: string; const Payload: string): Boolean;
begin
  Result := False;
  if (Codigo <= 0) or (not Assigned(AConexao)) then
    Exit;

  GarantirTabelaFilaImpressao(AConexao);
  AConexao.SQL.Add('INSERT INTO fila_impressao (pedido_id, tipo, payload, status)');
  AConexao.SQL.Add('SELECT :pedido_id, :tipo, :payload, ''PENDENTE''');
  AConexao.SQL.Add('FROM DUAL WHERE NOT EXISTS (');
  AConexao.SQL.Add('  SELECT 1 FROM fila_impressao');
  AConexao.SQL.Add('  WHERE pedido_id = :pedido_id AND tipo = :tipo');
  AConexao.SQL.Add('    AND status IN (''PENDENTE'', ''PROCESSANDO'')');
  AConexao.SQL.Add(')');
  AConexao.Parametros('pedido_id', Codigo);
  AConexao.Parametros('tipo', UpperCase(Trim(Tipo)));
  if Payload = '' then
    AConexao.Parametros('payload', Null)
  else
    AConexao.Parametros('payload', Payload);
  AConexao.ExecuteSQL;
  Result := true;
end;

initialization
  FilaImpressaoLock := TCriticalSection.Create;
  FilaImpressaoChaves := TDictionary<string, TDateTime>.Create;

finalization
  FilaImpressaoChaves.Free;
  FilaImpressaoLock.Free;

end.
