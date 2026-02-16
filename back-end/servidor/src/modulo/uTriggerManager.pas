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

    procedure ExecutarSQL(const SQL: string);
    procedure RecriarTrigger(const Nome, SQL: string);
    procedure RecriarProcedure(const Nome, SQL: string);

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
    Q.ExecSQL;
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

procedure TInfraBanco.RecriarTrigger(const Nome, SQL: string);
begin
  if TriggerExiste(Nome) then
    ExecutarSQL('DROP TRIGGER ' + Nome);

  ExecutarSQL(SQL);
end;

procedure TInfraBanco.RecriarProcedure(const Nome, SQL: string);
begin
  if ProcedureExiste(Nome) then
    ExecutarSQL('DROP PROCEDURE ' + Nome);

  ExecutarSQL(SQL);
end;

{ ===================================================== }
{ REGISTRO PRINCIPAL }
{ ===================================================== }

procedure TInfraBanco.ValidarEstrutura;
begin
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

  RecriarTrigger(
    'trg_pedido_after_update',
    'CREATE TRIGGER trg_pedido_after_update ' +
    'AFTER UPDATE ON pedido FOR EACH ROW BEGIN ' +
    'IF NEW.recalcula_preparo = 1 THEN ' +
    'CALL sp_atualiza_preparo_pedido(NEW.codigo); ' +
    'END IF; END;'
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
    '/* aqui entra o corpo completo que você já possui */ ' +
    'END;'
  );

  RecriarProcedure(
    'sp_atualiza_preparo_pedido',
    'CREATE PROCEDURE sp_atualiza_preparo_pedido(IN p_codigo_pedido INT) BEGIN ' +
    '/* aqui entra o corpo completo que você já possui */ ' +
    'END;'
  );

end;

end.
