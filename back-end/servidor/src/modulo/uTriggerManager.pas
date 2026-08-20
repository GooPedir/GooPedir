unit uTriggerManager;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Comp.Client,
  Conexao;

type
  TInfraBanco = class
  private
    FConexao: TConexao;

    function TriggerExiste(const Nome: string): Boolean;
    function ProcedureExiste(const Nome: string): Boolean;
    function EventExiste(const Nome: string): Boolean;
    function ColunaExiste(const Tabela, Coluna: string): Boolean;

    procedure ExecutarSQL(const SQL: string);
    procedure RecriarTrigger(const Nome, SQL: string);
    procedure RecriarProcedure(const Nome, SQL: string);
    procedure CriarEventSeNaoExiste(const Nome, SQL: string);
    procedure GarantirEstruturaBase;

    procedure RegistrarTriggers;
    procedure RegistrarProcedures;

  public
    constructor Create;
    destructor Destroy; override;

    procedure ValidarEstrutura;
  end;

implementation

{ ===================================================== }
{ CONSTRUTOR / DESTRUTOR }
{ ===================================================== }

constructor TInfraBanco.Create;
begin
  inherited;
  FConexao := TConexao.Create('InfraBanco');
end;

destructor TInfraBanco.Destroy;
begin
  FConexao.Free;
  inherited;
end;

{ ===================================================== }
{ UTIL }
{ ===================================================== }

procedure TInfraBanco.ExecutarSQL(const SQL: string);
var
  Q: TFDQuery;
begin
  Q := FConexao.CriaQRY;
  try
    Q.SQL.Text := SQL;
    try
      Q.ExecSQL;
    except
      on E: Exception do
        raise Exception.CreateFmt('Erro ao executar SQL de infraestrutura: %s'#13#10'SQL: %s',
          [E.Message, SQL]);
    end;
  finally
    Q.Free;
  end;
end;
function TInfraBanco.TriggerExiste(const Nome: string): Boolean;
var
  Q: TFDQuery;
begin
  Q := FConexao.CriaQRY;
  try
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.TRIGGERS ' +
      'WHERE TRIGGER_SCHEMA = DATABASE() ' +
      'AND TRIGGER_NAME = :nome';

    Q.ParamByName('nome').AsString := Nome;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;

function TInfraBanco.ProcedureExiste(const Nome: string): Boolean;
var
  Q: TFDQuery;
begin
  Q := FConexao.CriaQRY;
  try
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.ROUTINES ' +
      'WHERE ROUTINE_SCHEMA = DATABASE() ' +
      'AND ROUTINE_NAME = :nome';

    Q.ParamByName('nome').AsString := Nome;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;

function TInfraBanco.EventExiste(const Nome: string): Boolean;
var
  Q: TFDQuery;
begin
  Q := FConexao.CriaQRY;
  try
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.EVENTS ' +
      'WHERE EVENT_SCHEMA = DATABASE() ' +
      'AND EVENT_NAME = :nome';

    Q.ParamByName('nome').AsString := Nome;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;
function TInfraBanco.ColunaExiste(const Tabela, Coluna: string): Boolean;
var
  Q: TFDQuery;
begin
  Q := FConexao.CriaQRY;
  try
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = :tabela ' +
      'AND COLUMN_NAME = :coluna';

    Q.ParamByName('tabela').AsString := Tabela;
    Q.ParamByName('coluna').AsString := Coluna;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;
procedure TInfraBanco.RecriarTrigger(const Nome, SQL: string);
begin
  if TriggerExiste(Nome) then
    Exit;

  ExecutarSQL(SQL);

  if not TriggerExiste(Nome) then
    raise Exception.CreateFmt('Trigger %s nao foi criada.', [Nome]);
end;

procedure TInfraBanco.RecriarProcedure(const Nome, SQL: string);
begin
  if ProcedureExiste(Nome) then
    Exit;

  ExecutarSQL(SQL);

  if not ProcedureExiste(Nome) then
    raise Exception.CreateFmt('Procedure %s nao foi criada.', [Nome]);
end;

procedure TInfraBanco.CriarEventSeNaoExiste(const Nome, SQL: string);
begin
  if EventExiste(Nome) then
    Exit;

  ExecutarSQL(SQL);

  if not EventExiste(Nome) then
    raise Exception.CreateFmt('Event %s nao foi criado.', [Nome]);
end;

{ ===================================================== }
{ REGISTRO PRINCIPAL }
{ ===================================================== }

procedure TInfraBanco.GarantirEstruturaBase;
begin
  if not ColunaExiste('cliente', 'data_cadastro') then
    ExecutarSQL('ALTER TABLE cliente ADD data_cadastro date;');
end;
procedure TInfraBanco.ValidarEstrutura;
begin
  GarantirEstruturaBase;
  RegistrarTriggers;
  RegistrarProcedures;
end;

{ ===================================================== }
{ TRIGGERS }
{ ===================================================== }

procedure TInfraBanco.RegistrarTriggers;
begin

  RecriarTrigger(
    'trg_cliente_data',
    'CREATE TRIGGER trg_cliente_data ' +
    'BEFORE INSERT ON cliente FOR EACH ROW ' +
    'SET NEW.data_cadastro = CURDATE();'
  );

  RecriarTrigger(
    'trg_pedido_produtos_after_insert',
    'CREATE TRIGGER trg_pedido_produtos_after_insert ' +
    'AFTER INSERT ON pedido_produtos FOR EACH ROW BEGIN ' +
    'INSERT INTO impressao_pedido_produto (' +
    'data_solicitacao,hora_solicitacao,data_impressao,hora_impressao,' +
    'id_pedido,status,vias,usuario) VALUES (' +
    'CURDATE(),CURTIME(),NULL,NULL,NEW.codigo,1,1,NEW.usuario); ' +
    'END;'
  );

//  RecriarTrigger(
//    'trg_pedido_after_update',
//    'CREATE TRIGGER trg_pedido_after_update ' +
//    'AFTER UPDATE ON pedido FOR EACH ROW BEGIN ' +
//    'IF NEW.recalcula_preparo = 1 THEN ' +
//    'CALL sp_atualiza_preparo_pedido(NEW.codigo); ' +
//    'END IF; END;'
//  );

RecriarTrigger(
  'trg_pedido_before_update',
  'CREATE TRIGGER trg_pedido_before_update ' +
  'BEFORE UPDATE ON pedido FOR EACH ROW BEGIN ' +

  // regra do preparo (pode manter)
  'IF NEW.recalcula_preparo = 1 THEN ' +
  '  CALL sp_atualiza_preparo_pedido(NEW.codigo); ' +
  'END IF; ' +

  // regra da descri��o
  'IF (NEW.desc_ficha IS NULL OR NEW.desc_ficha = '''') ' +
  'AND NEW.codigo_pedido_dia <> 0 THEN ' +

  '  IF NEW.codigo_cliente_endereco = 0 THEN ' +
  '    SET NEW.desc_ficha = CONCAT(''RETIRADA '', NEW.codigo_pedido_dia); ' +

  '  ELSE ' +
  '    SET NEW.desc_ficha = CONCAT(''DELIVERY '', NEW.codigo_pedido_dia); ' +

  '  END IF; ' +

  'END IF; ' +

  'END;'
);
  RecriarTrigger(
    'trg_produto_estoque_after_insert',
    'CREATE TRIGGER trg_produto_estoque_after_insert ' +
    'AFTER INSERT ON produto_estoque FOR EACH ROW BEGIN ' +
    'DECLARE v_saldo INT DEFAULT 0; ' +
    'DECLARE v_status INT DEFAULT 0; ' +
    'DECLARE v_mov INT DEFAULT 0; ' +
    'DECLARE v_controle INT DEFAULT 0; ' +
    'SET v_mov := CASE WHEN NEW.operacao = 1 THEN NEW.quantidade ' +
    'WHEN NEW.operacao = 2 THEN -NEW.quantidade ELSE 0 END; ' +
    'SELECT controle_estoque INTO v_controle FROM produto WHERE codigo = NEW.codigo_produto; ' +
    'IF v_controle = 1 THEN ' +
    'UPDATE produto SET saldo_atual = IFNULL(saldo_atual,0)+v_mov WHERE codigo=NEW.codigo_produto; ' +
    'SELECT saldo_atual INTO v_saldo FROM produto WHERE codigo=NEW.codigo_produto; ' +
    'IF v_saldo > 0 THEN SET v_status = 1; ELSE SET v_status = 0; END IF; ' +
    'UPDATE produto SET ativo=v_status, modificado_site=0 ' +
    'WHERE codigo=NEW.codigo_produto AND controle_estoque=1; ' +
    'END IF; ' +
    'UPDATE pro_adi_personalizado_sabores SET ativo=v_status, modificado_site=0 ' +
    'WHERE id_prod_estoque = NEW.codigo_produto; ' +
    'END;'
  );

end;

{ ===================================================== }
{ PROCEDURES }
{ ===================================================== }

procedure TInfraBanco.RegistrarProcedures;
begin

  RecriarProcedure(
    'atualizar_data_cadastro_cliente',
    'CREATE PROCEDURE atualizar_data_cadastro_cliente() BEGIN ' +
    'UPDATE cliente c INNER JOIN ( ' +
    'SELECT codigo_cliente, MIN(data_pedido) data_primeiro_pedido ' +
    'FROM pedido GROUP BY codigo_cliente ) x ' +
    'ON x.codigo_cliente=c.codigo ' +
    'SET c.data_cadastro=x.data_primeiro_pedido ' +
    'WHERE c.data_cadastro IS NULL; END;'
  );

  RecriarProcedure(
    'sp_calcula_tempo_preparo_pedido_produto',
    'CREATE PROCEDURE sp_calcula_tempo_preparo_pedido_produto(IN p_codigo_pedido_produto INT) BEGIN ' +
    '/* aqui entra o corpo completo que voc� j� possui */ ' +
    'END;'
  );

  RecriarProcedure(
    'sp_atualiza_preparo_pedido',
    'CREATE PROCEDURE sp_atualiza_preparo_pedido(IN p_codigo_pedido INT) BEGIN ' +
    '/* aqui entra o corpo completo que voc� j� possui */ ' +
    'END;'
  );
  
RecriarProcedure(
  'proc_atualiza_cliente_estatistica',
  'CREATE PROCEDURE proc_atualiza_cliente_estatistica() BEGIN ' +
  'DECLARE v_codigo_cliente INT; ' +
  'DECLARE v_fim INT DEFAULT 0; ' +
  'DECLARE cur CURSOR FOR ' +
  'SELECT DISTINCT codigo_cliente ' +
  'FROM pedido ' +
  'WHERE status IN (0,6) ' +
  'AND cliente_count = 0 ' +
  'AND codigo_cliente > 0 ' +
  'LIMIT 10; ' +
  'DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fim = 1; ' +
  'OPEN cur; ' +
  'loop_clientes: LOOP ' +
  'FETCH cur INTO v_codigo_cliente; ' +
  'IF v_fim = 1 THEN ' +
  'LEAVE loop_clientes; ' +
  'END IF; ' +
  'INSERT INTO cliente_estatistica ( ' +
  'codigo_cliente, ' +
  'pedidos, ' +
  'cancelados, ' +
  'finalizados, ' +
  'total_pedidos, ' +
  'total_cancelados, ' +
  'total_finalizados, ' +
  'ultimo_pedido ' +
  ') ' +
  'SELECT ' +
  'p.codigo_cliente, ' +
  'COUNT(*) AS pedidos, ' +
  'SUM(CASE WHEN p.status = 0 THEN 1 ELSE 0 END) AS cancelados, ' +
  'SUM(CASE WHEN p.status = 6 THEN 1 ELSE 0 END) AS finalizados, ' +
  'SUM(p.valor_total_pedido) AS total_pedidos, ' +
  'SUM(CASE WHEN p.status = 0 THEN p.valor_total_pedido ELSE 0 END) AS total_cancelados, ' +
  'SUM(CASE WHEN p.status = 6 THEN p.valor_total_pedido ELSE 0 END) AS total_finalizados, ' +
  'MAX(CONCAT(p.data_pedido, '' '', IFNULL(p.hora_pedido, ''00:00:00''))) AS ultimo_pedido ' +
  'FROM pedido p ' +
  'WHERE p.codigo_cliente = v_codigo_cliente ' +
  'GROUP BY p.codigo_cliente ' +
  'ON DUPLICATE KEY UPDATE ' +
  'pedidos = VALUES(pedidos), ' +
  'cancelados = VALUES(cancelados), ' +
  'finalizados = VALUES(finalizados), ' +
  'total_pedidos = VALUES(total_pedidos), ' +
  'total_cancelados = VALUES(total_cancelados), ' +
  'total_finalizados = VALUES(total_finalizados), ' +
  'ultimo_pedido = VALUES(ultimo_pedido), ' +
  'data_atualizacao = CURRENT_TIMESTAMP; ' +
  'UPDATE pedido ' +
  'SET cliente_count = 1 ' +
  'WHERE codigo_cliente = v_codigo_cliente ' +
  'AND cliente_count = 0; ' +
  'END LOOP; ' +
  'CLOSE cur; ' +
  'END;'
);  

CriarEventSeNaoExiste('ev_cliente_estatistica', 'CREATE EVENT ev_cliente_estatistica ON SCHEDULE EVERY 5 SECOND DO CALL proc_atualiza_cliente_estatistica();');

end;

end.
