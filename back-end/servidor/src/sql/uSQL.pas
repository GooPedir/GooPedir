unit uSQL;

interface

uses
  IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase,
  IdFTP, System.Zip, ShellAPI, Registry, System.Classes, FMX.StdCtrls,
  Vcl.StdCtrls;

type
  TCallback = procedure of object;

  TSQL = class
  private
    { O Controle de atualização do banco vai ser por enquanto com base na versão do executavel }
    Function VersaoExe: String;
    procedure AtualizaCodigoUltimaVersao;
    function ExecultaSQL(SQL: String): Boolean;
    function VerificaSQL: Boolean;
    procedure AtualizaBanco;
    procedure Banco(Versao: Integer);
    procedure IniciaAtualizacao;
    function UltimoCodigo(tabela, campo: String): string;

  var

    CodigoSQL: Integer;
    UltimoSQL: Integer; // Inicial 1
    UltimoSQLBanco: Integer;
    ListaSQL: TStringList;
  public
    constructor Create;
    procedure VerificaAtualizacao;
    procedure AtualizarBanco;

  var
    SeTiverAtualizacao: TCallback;
    seNaoTiverAtualizacao: TCallback;
    IniciarAtualizacao: TCallback;
    AposConcluirAtualizacao: TCallback;
    AtualizaEstoque: TCallback;
    LabelInfo: TLabel;
    MemoLog: TMemo;
    StatusAtualizacao: Integer;

  end;

implementation

{ TSQL }

uses conexao, System.SysUtils;

procedure TSQL.AtualizaBanco;
var
  I: Integer;
  Inicio: Integer;
begin
  // frmAtualizandoSQL := TfrmAtualizandoSQL.Create(nil);
  // sleep(1000);
  // frmAtualizandoSQL.Refresh;
  // frmAtualizandoSQL.Repaint;
  // frmAtualizandoSQL.Visible := True;
  // frmAtualizandoSQL.Refresh;
  // frmAtualizandoSQL.Repaint;

  for I := UltimoSQLBanco to UltimoSQL do
  begin
    Banco(I);
  end;

  // frmAtualizandoSQL.Free;
end;

procedure TSQL.AtualizaCodigoUltimaVersao;
var
  Versao: String;
begin
  Versao := VersaoExe;
  Versao := Copy(Versao, 7, 4);
  UltimoSQL := StrToInt(Versao);
end;

procedure TSQL.AtualizarBanco;
Var
  I: Integer;
begin
  // Banco(VersaoExe.ToInteger);

  for I := UltimoSQLBanco to VersaoExe.ToInteger do
  begin
    Banco(I);
  end;

  TThread.CreateAnonymousThread(
    procedure
    begin

      IniciaAtualizacao;
      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin

          if Assigned(AposConcluirAtualizacao) then
          begin
            AposConcluirAtualizacao;

          end;

          StatusAtualizacao := 1;
        end);
    end).Start;

end;

constructor TSQL.Create;
var
  Versao: String;
begin
  ListaSQL := TStringList.Create;

end;

function TSQL.ExecultaSQL(SQL: String): Boolean;
begin
  ListaSQL.Add(SQL);

end;

procedure TSQL.IniciaAtualizacao;
var
  conexao: TConexao;
  I: Integer;
begin
  conexao := TConexao.Create('uSQL');
  MemoLog.Lines.Add
    ('****************************************************************************');
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('Inicio Atualização');
  MemoLog.Lines.Add('Data/Hora: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', now));
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add
    ('****************************************************************************');

  for I := 0 to ListaSQL.Count - 1 do
  begin
    MemoLog.Lines.Add('');
    // MemoLog.Lines.Add(ListaSQL[I]);
    // LabelInfo.Text := (I + 1).ToString + '/' + (ListaSQL.Count).ToString;

    if conexao.ExecutarSQLAtualizacao(ListaSQL[I], VersaoExe) then
    begin
      MemoLog.Lines.Add('Executado com sucesso!');
    end
    else
    begin
      MemoLog.Lines.Add('Erro ao executar!');
    end;
    MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', now));
    MemoLog.Lines.Add
      ('****************************************************************************');
    sleep(200);
  end;
  StatusAtualizacao := 1;

  conexao.Free;
end;

function TSQL.UltimoCodigo(tabela, campo: String): string;
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('uSQL');
  conexao.SQL.Add('SELECT ifnull(MAX(' + campo +
    ')+1,0) AS codigo,0 as zero FROM ' + tabela);
  Result := conexao.FieldByName('codigo');
  conexao.Free;
end;

procedure TSQL.VerificaAtualizacao;
var
  conexao: TConexao;
begin

  conexao := TConexao.Create('TConexao');
  conexao.SQL.Add('SET GLOBAL max_connections = 1000;');
  conexao.ExecuteSQL;
  conexao.Free;

  if not VerificaSQL then
  begin
    if Assigned(SeTiverAtualizacao) then
      SeTiverAtualizacao;
    MemoLog.Lines.Add('Nova atualização disponível!');
    // AtualizaBanco;
  end
  else
  begin
    if Assigned(seNaoTiverAtualizacao) then
      seNaoTiverAtualizacao;

    StatusAtualizacao := 1;

    MemoLog.Lines.Clear;

  end;
end;

function TSQL.VerificaSQL: Boolean;
var
  conexao: TConexao;
begin
  Result := False;

  conexao := TConexao.Create('uSQL');

  conexao.SQL.Add('select max(versaosql) as maior, 0 as zero from meu_sql');

  try
    UltimoSQLBanco := conexao.FieldByName('maior');
  except
    UltimoSQLBanco := 0;
  end;
  Result := UltimoSQLBanco = StrToInt(VersaoExe);

  conexao.Free;
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('Verificando Atualizações . . .');
end;

procedure TSQL.Banco(Versao: Integer);
var
  SQL: String;
  tabela: String;
  campo: String;
begin
  ExecultaSQL
    ('create table geradores ( tabela varchar(255) not null, sequencial integer);');
  ExecultaSQL('SET sql_mode=(SELECT REPLACE(@@sql_mode,' +
    QuotedStr('ONLY_FULL_GROUP_BY') + ',' + QuotedStr('') + '));');
  case Versao of
    1:
      begin
        ExecultaSQL
          ('CREATE TABLE MEU_SQL (IDSQL INTEGER,VERSAOSQL INTEGER, SQLUSADOSQL BLOB, ERROSQL BLOB, DATASQL DATE, HORASQL TIME, STATUSSQL VARCHAR(15));');

      end;
    2:
      begin
        ExecultaSQL
          ('CREATE TABLE ATUALIZACAOAPP (    VERSAOAPP       VARCHAR(20),    VERSAOMINIMA    VARCHAR(20),    ORIGEMDOWNLOAD  VARCHAR(255));');
      end;
    3:
      begin
        ExecultaSQL
          ('CREATE TABLE status_pedido (id int NOT NULL, descricao varchar(255) DEFAULT NULL, PRIMARY KEY (id));');

        ExecultaSQL
          ('INSERT INTO status_pedido VALUES (0,"Cancelado"),(1,"Em Espera"),(2,"Em Produção"),(3,"Pronto"),(4,"Disponível Para Retirada"),(5,"Saiu Para Entrega"),(6,"Finalizado"),(7,"Faturado");');
      end;
    4:
      begin
        ExecultaSQL('alter table impressao_caixa add tipo integer;');
      end;
    5:
      begin
        ExecultaSQL('update tipo_sabor set ativo = 0 where nome not in (' +
          QuotedStr('Promoção') + ',' + QuotedStr('Tradicional') + ',' +
          QuotedStr('Especial') + ',' + QuotedStr('Doce') + ')');
      end;
    6:
      begin
        SQL := 'create table caixa_receber(';
        SQL := SQL + ' id integer not null,';
        SQL := SQL + ' primary key(id),';
        SQL := SQL + ' id_caixa integer,';
        SQL := SQL + ' id_cliente integer,';
        SQL := SQL + ' id_pedido integer,';
        SQL := SQL + ' id_tipo_pagamento integer,';
        SQL := SQL + ' data date,';
        SQL := SQL + ' hora time,';
        SQL := SQL + ' valor float,';
        SQL := SQL + ' status integer,';
        SQL := SQL + ' observacao varchar(200));';
        ExecultaSQL(SQL);
      end;
    7:
      begin
        ExecultaSQL('alter table tipo_pagamento add tipo_chave_pix integer;');
        ExecultaSQL('alter table tipo_pagamento add chave_pix varchar(250);');
        ExecultaSQL
          ('alter table tipo_pagamento add chave_recebedor varchar(250);');
        ExecultaSQL('alter table pedido add wpp_pix integer;');
        ExecultaSQL('alter table pedido add wpp_status integer;');
        ExecultaSQL('alter table tipo_pagamento add movimentacao integer;');
      end;
    8:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add senha_gerencia varchar(50);');

        ExecultaSQL
          ('update tipo_pagamento set movimentacao = 1 where movimentacao is null');
      end;
    9:
      begin
        ExecultaSQL('alter table pedido add gerou_pontos_fidelidade integer');
      end;
    10:
      begin
        ExecultaSQL('alter table cliente add fidelidade_ponto integer');
        ExecultaSQL('alter table cliente add fidelidade_desconto float');
        ExecultaSQL('alter table tipo_produto add user_id integer');
      end;
    11:
      begin
        ExecultaSQL
          ('update produto set saldo_atual = 0 where saldo_atual < 0 ');
      end;
    12:
      begin
        ExecultaSQL
          ('create table pix(id integer,id_pedido integer,valor real,creatdatahora datetime,expdatahora datetime,transacao varchar(500),transacao_mp varchar(50));')
      end;
    13:
      begin
        ExecultaSQL
          ('create table ingredientes_estoque(id integer,id_ingredientes integer,data date,hora time,tipo integer,quantidade real,custo_total real,custo real);');
        ExecultaSQL
          ('alter table pro_adi_personalizado_sabores add id_ingredientes integer;');
        ExecultaSQL('drop table ingredientes');
        ExecultaSQL('drop table produto_ingredientes');
        ExecultaSQL
          ('create table produto_ingredientes(id integer,id_produto integer,id_ingredientes integer,quantidade real)');
        ExecultaSQL
          ('create table ingredientes (id integer,descricao varchar(200),unidade varchar(10));');
      end;
    14:
      begin
        ExecultaSQL
          ('create table conversao(id integer,tipo integer,codigo_tipo integer,un_de varchar(20),un_para varchar(20),valor real);');

      end;
    15:
      begin
        ExecultaSQL('alter table dados_whatsapp add cor_fundo varchar(255);');
        ExecultaSQL('alter table dados_whatsapp add cor_fonte varchar(255);');
      end;
    16:
      begin
        ExecultaSQL
          ('alter table pro_adi_personalizado_sabores add quantidade_ingredientes float');
      end;
    17:
      begin
        ExecultaSQL('alter table pedido add mp varchar(255)');
        ExecultaSQL('alter table motoboy add acesso_site varchar(50)');
      end;
    18:
      begin
        ExecultaSQL('alter table pedido add id_ifood varchar(255);');
        ExecultaSQL('alter table pedido add status_ifood varchar(255);');
        ExecultaSQL('alter table tipo_produto add id_ifood varchar(255);');
        ExecultaSQL('alter table produto add id_ifood varchar(255);');
        ExecultaSQL('alter table produto add valor_ifood real;');
        ExecultaSQL
          ('alter table pedido add status_ifood_descricao varchar(255);');
      end;
    19:
      begin
        ExecultaSQL
          ('alter table pro_adi_personalizado add id_ifood varchar(255);');
        ExecultaSQL
          ('alter table pro_adi_personalizado_sabores add id_ifood varchar(255);');
        ExecultaSQL('alter table produto add foto_ifood varchar(255);');
        ExecultaSQL('alter table pedido add order_ifood varchar(50);');
        ExecultaSQL('alter table pedido add desc_desconto_ifood varchar(255);');
        ExecultaSQL('alter table pedido add agendada_ifood timestamp;');
        ExecultaSQL('alter table pedido add estimada_ifood timestamp;');
      end;
    20:
      begin
        SQL := 'create table pedido_status(';
        SQL := SQL + ' id integer,';
        SQL := SQL + ' id_pedido integer,';
        SQL := SQL + ' id_status integer,';
        SQL := SQL + ' horario timestamp);';
        ExecultaSQL(SQL);
      end;
    21:
      begin
        ExecultaSQL('delete from status_pedido where descricao = ' +
          QuotedStr('Faturado'));
        ExecultaSQL('alter table produto add position integer');
        ExecultaSQL('alter table produto add pessoas integer;');
        ExecultaSQL('alter table produto add valor_desconto real;');
        ExecultaSQL('alter table produto add percentual_desconto real;');

      end;
    22:
      begin
        ExecultaSQL('alter table pedido_produtos add id_caixa integer');
        ExecultaSQL('alter table pedido_produtos add id_pedido integer');
      end;
    24:
      begin
        ExecultaSQL('alter table produto add un varchar(50)');
        ExecultaSQL('alter table produto add ncm integer default 0');
        ExecultaSQL('alter table produto add cest integer default 0');
        ExecultaSQL('alter table produto add cfop integer default 0');
        ExecultaSQL('alter table produto add cstipi integer default 0');
        ExecultaSQL('alter table produto add csticms integer default 0');
        ExecultaSQL('alter table produto add cstpis integer default 0');
        ExecultaSQL('alter table produto add cstcofins integer default 0');
        ExecultaSQL('alter table produto add csosn integer default 0');
        ExecultaSQL('alter table produto add icms real default 0');
        ExecultaSQL('alter table produto add ipi real default 0');
        ExecultaSQL('alter table produto add pis real default 0');
        ExecultaSQL('alter table produto add cofins real default 0');
        ExecultaSQL('alter table produto add frete real default 0');

        ExecultaSQL('alter table pedido add nfce_emite integer default 0;');
        ExecultaSQL('alter table pedido add nfce_chave varchar(55);');
        ExecultaSQL('alter table pedido add nfce_protocolo varchar(55);');
        ExecultaSQL('alter table pedido add nfce_ambiente varchar(55);');
        ExecultaSQL('alter table pedido add nfce_numero varchar(55);');
        ExecultaSQL('alter table pedido add nfce_lote varchar(55);');
        ExecultaSQL
          ('create table nfce_numeracao(numero integer,lote integer);');

        ExecultaSQL('alter table dados_whatsapp add cnpj varchar(50);');
        ExecultaSQL('alter table dados_whatsapp add ie varchar(50);');
        ExecultaSQL('alter table dados_whatsapp add razao varchar(100);');
        ExecultaSQL('alter table dados_whatsapp add fone varchar(50);');
        ExecultaSQL('alter table dados_whatsapp add codcidade integer;');
        ExecultaSQL('alter table dados_whatsapp add nfce integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add nfce_ifood integer default 0;');

      end;
    25:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add imprimir_cozinha_site integer default 0;');
      end;
    26:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add marketin integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_segmento integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_desc real default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_tipo_desc integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_min real default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_qtd real default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_seg integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_ter integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_qua integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_qui integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_sex integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_sab integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_dom integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add marketin_link varchar(255)');
        ExecultaSQL
          ('alter table dados_whatsapp add homologacao integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add cozinha_apenas_mesa integer default 0;');
        ExecultaSQL('alter table dados_whatsapp add tipo integer default 0;');
      end;
    27:
      begin
        SQL := 'create table marketing(id integer not null auto_increment,';
        SQL := SQL +
          'data date,validade date,cupom varchar(50),valor real,id_cliente integer,pedido integer,status integer,primary key (id));';
        ExecultaSQL(SQL);
      end;
    28:
      begin
        ExecultaSQL('alter table motoboy add id_site integer default 0;');
        ExecultaSQL
          ('alter table motoboy add modificado_site integer default 0;');
      end;
    29:
      begin
        ExecultaSQL('CREATE INDEX codigo ON produto(codigo);');
        ExecultaSQL
          ('CREATE INDEX codigo_pedido_produto ON pedido_produto_sap(codigo_pedido_produto);');
        ExecultaSQL('CREATE INDEX id_mesa ON mesa(id_mesa);');
        ExecultaSQL('CREATE INDEX id_mesa_tipo ON mesa_tipo(id_mesa_tipo);');
        ExecultaSQL('CREATE INDEX id ON sabores_completo(id);');
        ExecultaSQL('CREATE INDEX codigo ON pedido(codigo);');
        ExecultaSQL('CREATE INDEX status ON pedido(status);');
        ExecultaSQL('CREATE INDEX id_ficha ON pedido(id_ficha);');
        ExecultaSQL('CREATE INDEX data_pedido ON pedido(data_pedido);');
        ExecultaSQL('CREATE INDEX id_ifood ON pedido(id_ifood);');
        ExecultaSQL('CREATE INDEX hora_pedido ON pedido(hora_pedido);');
        ExecultaSQL('CREATE INDEX id ON caixa(id);');
        ExecultaSQL('CREATE INDEX data_abertura ON caixa(data_abertura);');
        ExecultaSQL('CREATE INDEX status ON caixa(status);');
        ExecultaSQL('CREATE INDEX id ON caixa_movimento(id);');
        ExecultaSQL('CREATE INDEX id_caixa ON caixa_movimento(id_caixa);');

      end;
    30:
      begin
        ExecultaSQL('alter table pedido add partner varchar(50)');
      end;
    31:
      begin
        ExecultaSQL('alter table produto add fidelidade integer default 0');
      end;
    32:
      begin
        ExecultaSQL('alter table pedido add servico double default 0');
        ExecultaSQL('alter table pedido add cpf varchar(20)');
        ExecultaSQL('alter table pedido add nome varchar(50)');
      end;
    33:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add contabilidade integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add emailcontabilidade varchar(100)');
        SQL := ' create table contabilidade(';
        SQL := SQL + ' id integer not null,';
        SQL := SQL + ' data_envio date,';
        SQL := SQL + ' data varchar(50),';
        SQL := SQL + ' status integer,';
        SQL := SQL + ' erro varchar(250));';
        ExecultaSQL(SQL);

      end;
    34:
      begin
        ExecultaSQL('alter table tipo_produto add local integer default 0');

        ExecultaSQL('alter table produto add dias integer default 0;');
        ExecultaSQL('alter table produto add segunda integer default 1;');
        ExecultaSQL('alter table produto add terca integer default 1;');
        ExecultaSQL('alter table produto add quarta integer default 1;');
        ExecultaSQL('alter table produto add quinta integer default 1;');
        ExecultaSQL('alter table produto add sexta integer default 1;');
        ExecultaSQL('alter table produto add sabado integer default 1;');
        ExecultaSQL('alter table produto add domingo integer default 1;');

      end;
    35:
      begin
        ExecultaSQL('ALTER TABLE cliente MODIFY COLUMN celular VARCHAR(20);');
        ExecultaSQL('alter table caixa_movimento add id_cliente integer');
        ExecultaSQL('alter table caixa_receber add pago real default 0;');
        ExecultaSQL
          ('alter table caixa_movimento add impressao integer default 0');
        ExecultaSQL('CREATE INDEX codigo_pedido ON pedido(codigo);');
        ExecultaSQL
          ('alter table pedido_produtos add hora datetime default current_timestamp;');
        ExecultaSQL('alter table mesa add descricao varchar(255)');
        ExecultaSQL('alter table dados_whatsapp add comanda integer;');
      end;
    36:
      begin
        ExecultaSQL
          ('create table qrcod_pix (base64 blob,status integer,valor real);');
        ExecultaSQL('alter table pedido_produtos add vl_delivery real;');
      end;
    37:
      begin
        ExecultaSQL('alter table usuario add dashboard integer default 1;');
        ExecultaSQL('alter table usuario add estoque integer default 1;');
        ExecultaSQL('alter table usuario add cad_mesa integer default 1;');
        ExecultaSQL('alter table usuario add cad_motoboy integer default 1;');
        ExecultaSQL('alter table usuario add cad_taxa integer default 1;');
        ExecultaSQL
          ('alter table usuario add cad_impressora integer default 1;');
        ExecultaSQL('alter table usuario add cad_cupom integer default 1;');
        ExecultaSQL('alter table usuario add cad_prod integer default 1;');
        ExecultaSQL('alter table usuario add cad_paga integer default 1;');
        ExecultaSQL('alter table usuario add cad_cli integer default 1;');
        ExecultaSQL('alter table usuario add cad_pedido integer default 1;');
        ExecultaSQL('alter table usuario add desconto integer default 1;');
        ExecultaSQL('alter table usuario add param integer default 1;');
        ExecultaSQL('alter table usuario add caixa integer default 1;');

      end;
    38:
      begin
        ExecultaSQL('alter table usuario add cancelar integer default 1;');
      end;
    39:
      begin
        SQL := 'DELIMITER //';
        SQL := SQL + ' CREATE PROCEDURE AtualizarTempoEstimado()';
        SQL := SQL + ' BEGIN';
        SQL := SQL + '     DECLARE codigo_pedido INT;';
        SQL := SQL + '     DECLARE media_tempo INT;';
        SQL := SQL +
          '     CREATE TEMPORARY TABLE IF NOT EXISTS temp_pedidos AS';
        SQL := SQL + '     SELECT codigo';
        SQL := SQL + '     FROM pedido';
        SQL := SQL +
          '     WHERE data_pedido = CURDATE() AND tempo_estimado = 0 AND codigo_pedido_dia > 0;';
        SQL := SQL + '     WHILE (SELECT COUNT(*) FROM temp_pedidos) > 0 DO';
        SQL := SQL +
          '         SELECT codigo INTO codigo_pedido FROM temp_pedidos LIMIT 1;';
        SQL := SQL + '         SELECT (SUM(tp.tempo_estimado) +';
        SQL := SQL + '                 COALESCE(';
        SQL := SQL +
          '                     (SELECT SUM(tempo_estimado) / COUNT(tempo_estimado)';
        SQL := SQL + '                      FROM pedido';
        SQL := SQL +
          '                      WHERE data_pedido = CURDATE() AND tempo_estimado > 0';
        SQL := SQL + '                        AND DATE_FORMAT(';
        SQL := SQL + '                             FROM_UNIXTIME(';
        SQL := SQL +
          '                                 UNIX_TIMESTAMP(STR_TO_DATE(CONCAT(data_pedido, " ", hora_pedido), "%Y-%m-%d %H:%i:%s"))';
        SQL := SQL + '                                 + (tempo_estimado * 60)';
        SQL := SQL + '                             ),';
        SQL := SQL + '                             "%Y-%m-%d %H:%i:%s"';
        SQL := SQL + '                         ) > CURRENT_TIMESTAMP()';
        SQL := SQL + '                     ),';
        SQL := SQL + '                     0';
        SQL := SQL + '                 )';
        SQL := SQL + '                ) / 2 AS media_tempo';
        SQL := SQL + '         INTO media_tempo';
        SQL := SQL + '         FROM pedido AS p';
        SQL := SQL +
          '         JOIN pedido_produtos AS pp ON pp.codigo_pedido = p.codigo';
        SQL := SQL +
          '         JOIN produto AS prod ON prod.codigo = pp.codigo_produto';
        SQL := SQL +
          '         JOIN tipo_produto AS tp ON tp.codigo = prod.codigo_grupo AND tp.tempo_estimado > 0';
        SQL := SQL + '         WHERE p.codigo = codigo_pedido';
        SQL := SQL + '         GROUP BY p.codigo;';
        SQL := SQL + '         -- Atualiza o tempo_estimado na tabela pedido';
        SQL := SQL + '         UPDATE pedido';
        SQL := SQL + '         SET tempo_estimado = media_tempo';
        SQL := SQL + '         WHERE codigo = codigo_pedido;';
        SQL := SQL +
          '         -- Remove o código de pedido da tabela temporária';
        SQL := SQL +
          '         DELETE FROM temp_pedidos WHERE codigo = codigo_pedido;';
        SQL := SQL + '     END WHILE;';
        SQL := SQL + '     DROP TEMPORARY TABLE IF EXISTS temp_pedidos;';
        SQL := SQL + ' END //';

        SQL := SQL + ' DELIMITER ;';
        ExecultaSQL(SQL);
        ExecultaSQL('alter table pedido add tempo_estimado integer default 0;');
        ExecultaSQL
          ('alter table tipo_produto add tempo_estimado integer default 0;');

      end;
    40:
      begin
        ExecultaSQL
          ('alter table pro_adi_personalizado_sabores add id_prod_estoque integer;');
        ExecultaSQL('alter table pedido add usuario integer');
      end;
    41:
      begin
        ExecultaSQL('ALTER TABLE produto MODIFY COLUMN cest VARCHAR(10);');
      end;
    42:
      begin
        ExecultaSQL
          ('alter table caixa_receber add impressao integer default 0');
        ExecultaSQL
          ('alter table dados_whatsapp add estoque_wpp_celular varchar(25);');
        ExecultaSQL
          ('alter table dados_whatsapp add estoque_min_recomendado integer default 30;');
        ExecultaSQL('alter table dados_whatsapp add estoque_wpp date;');
        ExecultaSQL('alter table produto add estoque_min real;');
      end;
    43:
      begin
        ExecultaSQL
          ('create table agent (id varchar(18) not null,primary key(id),datahora datetime,status integer);');
        ExecultaSQL('alter table agent add nome varchar(50);');
      end;
    44:
      begin
        ExecultaSQL('ALTER TABLE produto ALTER COLUMN cest SET DEFAULT ' +
          QuotedStr('0') + ';');
        ExecultaSQL('alter table pedido add ifood_phone varchar(50)');
        ExecultaSQL('alter table pedido add ifood_localizador varchar(50)');
        ExecultaSQL('alter table pedido add ifood_pedido varchar(50)');
      end;
    45:
      begin
        ExecultaSQL('alter table usuario add garcom integer default 0;');
      end;
    46:
      begin
        ExecultaSQL
          ('create table horario (dia_da_sema varchar(3),abertura time,fechamento time,status integer)');
      end;
    47:
      begin
        ExecultaSQL
          ('CREATE TABLE mensagem ( dia varchar(20), texto longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci)');
        ExecultaSQL
          ('ALTER SCHEMA DEFAULT CHARACTER SET utf8mb4  DEFAULT COLLATE utf8mb4_unicode_ci;');
      end;
    48:
      begin
        ExecultaSQL('alter table dados_whatsapp add certificado varchar(255);');
        ExecultaSQL('alter table dados_whatsapp add ambiente integer;');
        ExecultaSQL('alter table dados_whatsapp add forma_emissao integer;');
        ExecultaSQL('alter table dados_whatsapp add tipo_empresa integer;');
        ExecultaSQL
          ('alter table dados_whatsapp add id_token_scs varchar(255);');
        ExecultaSQL('alter table dados_whatsapp add token_scs varchar(255);');
      end;
    49:
      begin
        SQL := 'create table funcionario (id integer not null,nome varchar(50),celular varchar(15),';
        SQL := SQL +
          'funcao integer,valor double,perc_goopedir integer,perc_ifood integer,id_motoboy integer,dias varchar(50),ativo integer);';
        ExecultaSQL(SQL);
      end;
    50:
      begin
        ExecultaSQL
          ('alter table mensagem add imagem longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
      end;
    51:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add caminho_cache varchar(255)');
      end;
    52:
      begin
        ExecultaSQL
          ('ALTER TABLE produto MODIFY nome_produto VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci;');
      end;
    53:
      begin
        ExecultaSQL('delete from impressao_pedido_produto');
        ExecultaSQL
          ('ALTER TABLE impressao_pedido_produto CHANGE COLUMN id_pedido id_pedido INT NOT NULL , ADD PRIMARY KEY (id_pedido);');
      end;
    54:
      begin
        ExecultaSQL
          ('create table mensagem_whatsapp (numero varchar(50) not null, primary key (numero), data date);');
        ExecultaSQL('ALTER TABLE mensagem_whatsapp ADD UNIQUE (numero);');
        ExecultaSQL('alter table dados_whatsapp add localizacao varchar(255);');

      end;
    55:
      begin
        // tabela := 'pedido_produtos';
        // campo := 'codigo';
        //
        // SQL := 'ALTER TABLE ' + tabela + ' DROP PRIMARY KEY;';
        // ExecultaSQL(SQL);
        // SQL := 'ALTER TABLE ' + tabela + ' MODIFY COLUMN ' + campo +
        // ' INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST, AUTO_INCREMENT = ' +
        // UltimoCodigo(tabela, campo) + ';';
        // ExecultaSQL(SQL);
        //
        // tabela := 'pedido_produto_sap';
        // campo := 'id';
        // SQL := 'ALTER TABLE ' + tabela + ' DROP PRIMARY KEY;';
        // ExecultaSQL(SQL);
        // SQL := 'ALTER TABLE ' + tabela + ' MODIFY COLUMN ' + campo +
        // ' INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST, AUTO_INCREMENT = ' +
        // UltimoCodigo(tabela, campo) + ';';
        // ExecultaSQL(SQL);
        //
        // tabela := 'impressao_pedido_produto';
        // campo := 'id';
        // SQL := 'ALTER TABLE ' + tabela + ' DROP PRIMARY KEY;';
        // ExecultaSQL(SQL);
        // SQL := 'ALTER TABLE ' + tabela + ' MODIFY COLUMN ' + campo +
        // ' INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST, AUTO_INCREMENT = ' +
        // UltimoCodigo(tabela, campo) + ';';
        // ExecultaSQL(SQL);
        //
        // ExecultaSQL
        // ('alter table dados_whatsapp add caminho_purge varchar(255)');

        // UltimoCodigo
      end;
    56:
      begin
        ExecultaSQL('delete from geradores');
        ExecultaSQL('ALTER TABLE `geradores` ADD PRIMARY KEY (`tabela`);');
      end;
    57:
      begin
        ExecultaSQL('alter table dados_whatsapp add oculta_categoria integer');
      end;
    58:
      begin
        ExecultaSQL('alter table pedido add url varchar(255);');
      end;
    59:
      begin
        SQL := 'create table caixa_movimento_produto(';
        SQL := SQL + ' id integer not null,';
        SQL := SQL + ' primary key(id),';
        SQL := SQL + ' id_caixa_movimento integer not null,';
        SQL := SQL + ' id_pedido_produto integer not null,';
        SQL := SQL + ' quantidade double,';
        SQL := SQL + ' valor double);';
        ExecultaSQL(SQL);
      end;
    60:
      begin
        ExecultaSQL('alter table produto add novidade integer');
      end;
    61:
      begin
        ExecultaSQL('alter table dados_whatsapp add msg_massa integer');
      end;
    62:
      begin
        ExecultaSQL('alter table produto add vembuscar integer;');
        ExecultaSQL('alter table produto add delivery integer;');
      end;
    63:
      begin
        ExecultaSQL
          ('alter table pedido_produtos add selecionado integer default 0;');
      end;
    64:
      begin
        ExecultaSQL
          ('ALTER TABLE `mesa` CHANGE COLUMN `tot_mesa` `tot_mesa` DOUBLE NULL DEFAULT NULL ;');
      end;
    65:
      begin
        ExecultaSQL('alter table pedido_produtos add fracao double;');
        ExecultaSQL('alter table pedido_produtos add pessoas double;');
      end;
    66:
      begin
        ExecultaSQL
          ('ALTER TABLE `pedido_motoboy` DROP PRIMARY KEY, ADD PRIMARY KEY (`codigo`, `codigo_pedido`)');
      end;
    67:
      begin
        SQL := 'create table mensagem_massa (';
        SQL := SQL + ' id integer not null,';
        SQL := SQL + ' primary key(id),';
        SQL := SQL + ' celular varchar(20),';
        SQL := SQL + ' datahora datetime,';
        SQL := SQL + ' dia_da_semana varchar(10));';
        ExecultaSQL(SQL);
      end;
    68:
      begin
        ExecultaSQL
          ('alter table pedido add nfce_sinc_contabilidade integer default 0');
        ExecultaSQL('alter table pedido add nfce_data date;');
        ExecultaSQL('alter table pedido add nfce_hora time;');
      end;
    69:
      begin
        // Só fiz 1x
        ExecultaSQL('alter table pedido add nfce_imprimir integer default 0');
      end;
    70:
      begin
        ExecultaSQL('alter table sabores_completo add id_ifood varchar(50)');
      end;
    71:
      begin
        ExecultaSQL
          ('alter table tipo_produto add borda_topo_direito integer default 10;');
        ExecultaSQL
          ('alter table tipo_produto add borda_topo_esquerdo integer default 10;');
        ExecultaSQL
          ('alter table tipo_produto add borda_inferior_direito integer default 10;');
        ExecultaSQL
          ('alter table tipo_produto add borda_inferior_esquerdo integer default 10;');
        ExecultaSQL
          ('alter table tipo_produto add espacamento integer default 1;');
        ExecultaSQL
          ('alter table tipo_produto add fonte_nome integer default 16;');
        ExecultaSQL
          ('alter table tipo_produto add fonte_descricao integer default 13;');
        ExecultaSQL('alter table tipo_produto add cor_fundo varchar(20);');
        ExecultaSQL('alter table tipo_produto add cor_nome varchar(20);');
        ExecultaSQL('alter table tipo_produto add cor_descricao varchar(20);');
        ExecultaSQL('alter table tipo_produto add descricao_cat varchar(255);');
        ExecultaSQL
          ('ALTER TABLE tipo_produto CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
        ExecultaSQL
          ('ALTER TABLE tipo_produto MODIFY descricao VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
        ExecultaSQL
          ('ALTER TABLE tipo_produto MODIFY descricao_cat VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
        ExecultaSQL
          ('ALTER TABLE produto MODIFY descricao VARCHAR(2555) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');

      end;
    72:
      begin
        // ExecultaSQL('SET GLOBAL wait_timeout = 60;');
        // ExecultaSQL('SET GLOBAL interactive_timeout = 60;');
      end;
    73:
      begin
        ExecultaSQL
          ('create table conexao(id integer not null,datahora timestamp,mysql varchar(255));');
      end;
    74:
      begin
        ExecultaSQL('update motoboy set modificado_site = 0 where codigo > 0');
      end;
    75:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add fidelidade_status integer default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add fidelidade_ponto integer default 1;');
        ExecultaSQL
          ('alter table dados_whatsapp add fidelidade_pontos real default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add fidelidade_desc real default 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add fidelidade_min real default 0;');
        ExecultaSQL('alter table dados_whatsapp add cor_fundo varchar(20);');
        ExecultaSQL('alter table dados_whatsapp add cor_fonte varchar(20);');
      end;
    76:
      begin
        ExecultaSQL
          ('create table pedido_nfce(id integer not null,id_pedido integer,chave varchar(50),protocolo varchar(50),caminho varchar(2555))');
      end;
    77:
      begin
        ExecultaSQL
          ('CREATE TABLE impressao_pedido_nfce (id INTEGER NOT NULL AUTO_INCREMENT,PRIMARY KEY (id),id_pedido INTEGER,solicitacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,status INTEGER DEFAULT 0,impressao TIMESTAMP);');
      end;
    78:
      begin
      end;
    79:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add retirada integer default 1;');
        ExecultaSQL
          ('alter table dados_whatsapp add delivery integer default 1;');
      end;
    80:
      begin
        // Contagem Estoque
        if Assigned(AtualizaEstoque) then
          AtualizaEstoque;
      end;
    81:
      begin
        ExecultaSQL('alter table ingredientes add saldo real default 0;');
        ExecultaSQL('alter table ingredientes add tipo integer default 1;');
        ExecultaSQL('alter table ingredientes add custo real default 0;');
        ExecultaSQL('alter table ingredientes add custo_medio real default 0;');
        ExecultaSQL
          ('alter table ingredientes add custo_ultimo real default 0;');
        SQL := 'create table ingredientes_ficha (';
        SQL := SQL + ' id integer not null,';
        SQL := SQL + ' primary key(id),';
        SQL := SQL + ' id_ingrediente integer,';
        SQL := SQL + ' id_composicao  integer,';
        SQL := SQL + 'quantidade real);';
        ExecultaSQL(SQL);
        ExecultaSQL('alter table ingredientes add quantidade real default 0;');

      end;
    82:
      begin
        ExecultaSQL('alter table mesa add hora timestamp;');
        ExecultaSQL
          ('alter table dados_whatsapp add cx_resumido integer default 1;');
      end;
    83:
      begin
        ExecultaSQL('alter table pedido_produtos add html longtext');
      end;
    84:
      begin
        SQL := 'CREATE TABLE cmv (';
        SQL := SQL + '  id INT NOT NULL AUTO_INCREMENT,';
        SQL := SQL + '  PRIMARY KEY(id),';
        SQL := SQL + '  codigo_produto integer,';
        SQL := SQL + '  custo_ingrediente DOUBLE,';
        SQL := SQL + '  custo_indiretos DOUBLE,';
        SQL := SQL + '  percentual_imposto DOUBLE,';
        SQL := SQL + '  percentual_cartao DOUBLE,';
        SQL := SQL + '  percentual_ifood DOUBLE,';
        SQL := SQL + '  percentual_lucro DOUBLE,';
        SQL := SQL + '  valor_imposto DOUBLE,';
        SQL := SQL + '  valor_cartao DOUBLE,';
        SQL := SQL + '  valor_ifood DOUBLE,';
        SQL := SQL + '  valor_lucro DOUBLE,';
        SQL := SQL + '  preco_sugerido DOUBLE,';
        SQL := SQL + '  data_inicial TIMESTAMP DEFAULT CURRENT_TIMESTAMP,';
        SQL := SQL + '  data_final TIMESTAMP';
        SQL := SQL + ');';
        ExecultaSQL(SQL);
      end;
    85:
      begin
        ExecultaSQL('alter table produto add new boolean default true;');
        ExecultaSQL('update produto set new = false;');
      end;
    86:
      begin
        //
        ExecultaSQL('alter table taxa_entrega add tempo DOUBLE default 0;');
      end;
    87:
      begin

        ExecultaSQL
          ('alter table dados_whatsapp add token_ifood varchar(2555);');
        //
      end;
    88:
      begin
        ExecultaSQL
          ('alter table pedido_produtos add datahora_deletado timestamp');
        ExecultaSQL('alter table pedido add datahora_deletado timestamp');
        ExecultaSQL('alter table usuario add campanha integer default 0');

      end;
    89:
      begin
        ExecultaSQL('alter table pedido add latitude real default 0;');
        ExecultaSQL('alter table pedido add longitude real default 0;');
      end;
    90:
      begin
        ExecultaSQL
          ('create table ifood_connect (id integer not null,primary key(id),name varchar(20),merchantid varchar(255), data timestamp,token varchar(2555),error blob,link blob,autenticacao varchar(10));');
        ExecultaSQL('insert into ifood_connect (id) values (1);');
        ExecultaSQL('insert into ifood_connect (id) values (2);');
        ExecultaSQL('alter table pedido add ifood integer;');
      end;
    91:
      begin
        // alter table caixa add id_site integer;
        ExecultaSQL('alter table produto add userid integer;');
      end;
    92:
      begin
        ExecultaSQL
          ('create table index_pedido (id integer, primary key(id), referencia varchar(255));');
      end;
    93:
      begin
        ExecultaSQL
          ('insert into status_pedido (id,descricao) values (9,"Aguardando Confirmação")');
      end;
    94:
      begin
        ExecultaSQL
          ('insert into usuario (codigo,nome) values (-1,"Qrcod Mesa")');
        ExecultaSQL('insert into usuario (codigo,nome) values (-2,"Site")');
      end;
    95:
      begin
        ExecultaSQL
          ('create table fila (id integer not null auto_increment,primary key (id),origem varchar(255),json longtext)');
      end;
    96:
      begin
        ExecultaSQL
          ('alter table dados_whatsapp add exclusao_itens integer default 0;');
      end;
    97:
      begin
        SQL := 'ALTER TABLE `dados_whatsapp`';
        SQL := SQL +
          ' CHANGE COLUMN `mensagem_inicio` `mensagem_inicio` VARCHAR(2555) CHARACTER SET "utf8mb4" COLLATE "utf8mb4_unicode_ci" NULL DEFAULT NULL ;';
        ExecultaSQL(SQL);

      end;
    98:
      begin
        ExecultaSQL('alter table caixa add id_site integer default 0;');
        ExecultaSQL('alter table caixa add link varchar(255);');
      end;
    99:
      begin
        ExecultaSQL('alter table tipo_produto add url varchar(255);');
        ExecultaSQL('alter table tipo_produto add opacidade integer;');
      end;
    100:
      begin
        ExecultaSQL('alter table dados_whatsapp add banner longtext');
      end;
    101:
      begin
        ExecultaSQL('alter table dados_whatsapp add pixel varchar(20);');
      end;
    102:
      begin
        ExecultaSQL('alter table pedido add servico_percentual double;');
      end;
    103:
      begin
        SQL := ' CREATE TABLE despesas (';
        SQL := SQL + ' id int NOT NULL AUTO_INCREMENT,';
        SQL := SQL + ' categoria int NOT NULL,';
        SQL := SQL +
          ' descricao varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL + ' valor decimal(10,2) DEFAULT NULL,';
        SQL := SQL + ' parcelas int DEFAULT NULL,';
        SQL := SQL + ' parcela int DEFAULT NULL,';
        SQL := SQL + ' vencimento date DEFAULT NULL,';
        SQL := SQL + ' status int DEFAULT NULL,';
        SQL := SQL + ' excluida int DEFAULT "0",';
        SQL := SQL + ' PRIMARY KEY (id))';
        ExecultaSQL(SQL);

        SQL := ' CREATE TABLE descricao (';
        SQL := SQL + ' id int NOT NULL AUTO_INCREMENT,';
        SQL := SQL +
          ' descricao varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL + ' PRIMARY KEY (id))  ';
        ExecultaSQL(SQL);

      end;
    104:
      begin
        ExecultaSQL
          ('ALTER TABLE tipo_pagamento CHANGE COLUMN tipo_chave_pix tipo_chave_pix VARCHAR(50) NULL ;');
      end;
    105:
      begin
        ExecultaSQL
          ('ALTER TABLE tipo_pagamento CHANGE COLUMN tipo_chave_pix tipo_chave_pix VARCHAR(255)');
        ExecultaSQL
          ('ALTER TABLE pedido_produtos ADD COLUMN usuario_deletado INT NULL AFTER datahora_deletado;');
        ExecultaSQL
          ('ALTER TABLE pedido_produtos ADD COLUMN usuario_pedido INT NULL AFTER datahora_deletado;');
        ExecultaSQL('ALTER TABLE pedido ADD COLUMN usuario_deletado INT NULL');

      end;
    106:
      begin

        SQL := 'CREATE TABLE balanca ( ';
        SQL := SQL + '    id INT AUTO_INCREMENT PRIMARY KEY,';
        SQL := SQL + '    modelo VARCHAR(100),';
        SQL := SQL + '    descricao VARCHAR(255),';
        SQL := SQL + '    protocolo VARCHAR(100),';
        SQL := SQL + '    porta VARCHAR(50),';
        SQL := SQL + '    peso DECIMAL(10, 3),';
        SQL := SQL + '    tara DECIMAL(10, 3),';
        SQL := SQL + '    ultima_sinc TIMESTAMP NULL DEFAULT NULL';
        SQL := SQL + ');';
        ExecultaSQL(SQL);
        ExecultaSQL('alter table produto add referencia varchar(50);');
      end;
    107:
      begin
        ExecultaSQL('alter table produto add tipo_produto_site varchar(50)');
        ExecultaSQL('alter table usuario add percentual float default 0;');
      end;
    108:
      begin
        ExecultaSQL('alter table usuario add impressora integer default 0');
        ExecultaSQL('alter table pedido_nfce add path varchar(2555);');
      end;
    109:
      begin
        ExecultaSQL('delete from impressao_pedido_nfce');
        ExecultaSQL
          ('ALTER TABLE `impressao_pedido_nfce` CHANGE COLUMN `id_pedido` `id_pedido` INT NOT NULL , ADD UNIQUE INDEX `id_pedido_UNIQUE` (`id_pedido` ASC) VISIBLE;');
        ExecultaSQL('alter table produto add tiposite varchar(2555);');
      end;
    110:
      begin
        ExecultaSQL('alter table pro_adi_personalizado add categoria integer');
        ExecultaSQL('alter table produto add tiposite integer');
      end;
    111:
      begin
        ExecultaSQL
          ('CREATE INDEX idx_pedido_usuario_status_caixa ON pedido (usuario, codigo_pedido_dia, status, id_caixa, codigo);');
        ExecultaSQL
          ('CREATE INDEX idx_cmp_produto ON caixa_movimento_produto (id_pedido_produto);');
        ExecultaSQL
          ('CREATE INDEX idx_sap_produto ON pedido_produto_sap (codigo_pedido_produto);');
        ExecultaSQL
          ('CREATE INDEX idx_pedido_produtos_codigo_pedido ON pedido_produtos (codigo_pedido);');
        ExecultaSQL('CREATE INDEX idx_index_pedido_id ON index_pedido (id);');
        ExecultaSQL
          ('CREATE INDEX idx_produto_grupo_ativo ON produto (codigo_grupo, ativo);');
        ExecultaSQL('CREATE INDEX idx_balanca_id ON balanca (id);');
        ExecultaSQL
          ('CREATE INDEX idx_produto_codigo_grupo ON produto (codigo_grupo);');

      end;
    112:
      begin
        ExecultaSQL('alter table produto add referencia varchar(50)');
        ExecultaSQL('alter table produto add tiposite varchar(50)');
        ExecultaSQL
          ('ALTER TABLE tipo_pagamento CHANGE COLUMN tipo_chave_pix tipo_chave_pix VARCHAR(250) NULL DEFAULT "";');
        ExecultaSQL
          ('ALTER TABLE pro_adi_personalizado ADD COLUMN categoria INT NULL;');

      end;
    113:
      begin
        ExecultaSQL('ALTER TABLE index_pedido ADD COLUMN count INT default 0;');
        ExecultaSQL('alter table cliente add pedidos integer default 0;');
      end;
    114:
      begin
        SQL := 'create table banner (';
        SQL := SQL + ' id integer not null auto_increment,';
        SQL := SQL + ' priamry key(id),';
        SQL := SQL + ' descricao varchar(50),';
        SQL := SQL + ' dia_semana varchar(50),';
        SQL := SQL + ' status integer,';
        SQL := SQL + ' link varchar(255));';
        ExecultaSQL(SQL);

        SQL := ' create table pedido_painel (';
        SQL := SQL + ' id integer not null auto_increment,';
        SQL := SQL + ' datahora timestamp,';
        SQL := SQL + ' id_pedido integer,';
        SQL := SQL + ' quantidade integer,';
        SQL := SQL + ' id_painel  integer,';
        SQL := SQL + ' primary key(id));';
        ExecultaSQL(SQL);

        SQL := 'create table painel( ';
        SQL := SQL + 'id integer not null auto_increment,';
        SQL := SQL + 'primary key(id),';
        SQL := SQL + 'descricao varchar(50),';
        SQL := SQL + 'tipo integer);';
        ExecultaSQL(SQL);

        ExecultaSQL('alter table banner add tempo integer default 60');
        ExecultaSQL('alter table banner add paineis varchar(255);');
      end;
    115:
      begin
        SQL := 'ALTER TABLE pedido_painel ';
        SQL := SQL +
          ' CHANGE COLUMN `datahora` `datahora` TIMESTAMP NULL DEFAULT current_timestamp() ,';
        SQL := SQL +
          ' CHANGE COLUMN `quantidade` `quantidade` INT NULL DEFAULT 0 ;';
        ExecultaSQL(SQL);
      end;
    116:
      begin
        ExecultaSQL('alter table sabores_completo add url varchar(255)');
      end;
    117:
      begin
        ExecultaSQL
          ('ALTER TABLE pro_adi_personalizado_sabores ADD COLUMN alerta INT NULL DEFAULT 0;');
        ExecultaSQL
          ('ALTER TABLE produto ADD COLUMN alerta INT NULL DEFAULT 0;');
        ExecultaSQL
          ('ALTER TABLE sabores_completo ADD COLUMN alerta INT NULL DEFAULT 0;');
        ExecultaSQL('alter table produto add deletado integer NULL DEFAULT 0;');
        SQL := 'CREATE TABLE `produto_pendencia` (';
        SQL := SQL + '  `id` INT NOT NULL AUTO_INCREMENT,';
        SQL := SQL + '  `id_produto` INT NULL,';
        SQL := SQL + '  `detalhe` VARCHAR(225) NULL,';
        SQL := SQL + '  `observacao` VARCHAR(255) NULL,';
        SQL := SQL + '  PRIMARY KEY (`id`));';
        ExecultaSQL(SQL);

        ExecultaSQL
          ('alter table pro_adi_personalizado_sabores add deletado integer DEFAULT 0');

        ExecultaSQL
          ('ALTER TABLE pedido_produtos ADD COLUMN tempo_liberacao INT NULL DEFAULT 2');
      end;
    118:
      begin
        ExecultaSQL
          ('alter table pro_adi_personalizado add deletado integer DEFAULT 0');
      end;
    119:
      begin
        SQL := ' CREATE TABLE banner (';
        SQL := SQL + '   id int NOT NULL AUTO_INCREMENT,';
        SQL := SQL +
          '   descricao varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL +
          '   dia_semana varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL + '   status int DEFAULT NULL,';
        SQL := SQL +
          '   link varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL + '   tempo int DEFAULT 60,';
        SQL := SQL +
          '   paines varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL +
          '   paineis varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL + '   PRIMARY KEY (id)';
        SQL := SQL + ' )';
        ExecultaSQL(SQL);
        SQL := ' CREATE TABLE painel (';
        SQL := SQL + '   id int NOT NULL AUTO_INCREMENT,';
        SQL := SQL +
          '   descricao varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,';
        SQL := SQL + '   tipo int DEFAULT NULL,';
        SQL := SQL + '   PRIMARY KEY (id)';
        SQL := SQL + ' )';
        ExecultaSQL(SQL);
      end;
    120:
      begin
        ExecultaSQL
          ('alter table pro_adi_personalizado add categoria integer DEFAULT 0');
        ExecultaSQL
          ('ALTER TABLE cliente CHANGE COLUMN data_nascimento data_nascimento VARCHAR(10) NULL DEFAULT NULL ;');

      end;
    121:
      begin
        SQL := SQL + ' CREATE TABLE favoritos (';
        SQL := SQL + '   id INT NOT NULL AUTO_INCREMENT,';
        SQL := SQL + '   usuario INT NULL,';
        SQL := SQL + '   descricao VARCHAR(45) NULL,';
        SQL := SQL + '   rota VARCHAR(45) NULL,';
        SQL := SQL + '   icone VARCHAR(45) NULL DEFAULT "FaHamburger",';
        SQL := SQL + '   ordem INT NULL,';
        SQL := SQL + '   ativo INT NULL,';
        SQL := SQL + '   created_at DATETIME NULL,';
        SQL := SQL + '   updated_at DATETIME NULL,';
        SQL := SQL + '   PRIMARY KEY (id));';
        ExecultaSQL(SQL);
      end;
    122:
      begin
        ExecultaSQL('alter table pedido_produtos add uuid varchar(50)');
      end;
    123:
      begin
        // ============================================================
        // TABELA: fornecedor
        // ============================================================
        SQL := 'CREATE TABLE fornecedor (';
        SQL := SQL + '    id CHAR(36) PRIMARY KEY,';
        SQL := SQL + '    cnpj VARCHAR(20) NOT NULL UNIQUE,';
        SQL := SQL + '    nome VARCHAR(255) NOT NULL,';
        SQL := SQL + '    inscricao_estadual VARCHAR(30),';
        SQL := SQL + '    endereco VARCHAR(255),';
        SQL := SQL + '    municipio VARCHAR(100),';
        SQL := SQL + '    uf CHAR(2),';
        SQL := SQL + '    email VARCHAR(150),';
        SQL := SQL + '    telefone VARCHAR(50),';
        SQL := SQL + '    tipo_fornecedor ENUM("PJ", "PF") DEFAULT "PJ",';
        SQL := SQL + '    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP';
        SQL := SQL + ');';
        ExecultaSQL(SQL);
        // ============================================================
        // TABELA: fornecedor_item (catálogo do fornecedor)
        // ============================================================
        SQL := ' CREATE TABLE fornecedor_item (';
        SQL := SQL + '     id CHAR(36) PRIMARY KEY,';
        SQL := SQL + '     fornecedor_id CHAR(36) NOT NULL,';
        SQL := SQL + '     cprod VARCHAR(60) NOT NULL,';
        SQL := SQL + '     cEAN VARCHAR(20),';
        SQL := SQL + '     xProd VARCHAR(255),';
        SQL := SQL + '     NCM VARCHAR(20),';
        SQL := SQL + '     CEST VARCHAR(10),';
        SQL := SQL + '     CFOP VARCHAR(10),';
        SQL := SQL + '     uCom VARCHAR(10),';
        SQL := SQL + '     ultimo BOOLEAN DEFAULT TRUE,';
        SQL := SQL + '     tabela_vinculo ENUM("produto", "ingrediente"),';
        SQL := SQL + '     campo_vinculo VARCHAR(100),';
        SQL := SQL + '     codigo_vinculo CHAR(36),';
        SQL := SQL + '     ativo BOOLEAN DEFAULT TRUE,';
        SQL := SQL + '     criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,';
        SQL := SQL +
          '     FOREIGN KEY (fornecedor_id) REFERENCES fornecedor(id)';
        SQL := SQL + ' );';
        ExecultaSQL(SQL);
        // ============================================================
        // TABELA: unidade_conversao
        // ============================================================
        SQL := ' CREATE TABLE unidade_conversao (';
        SQL := SQL + '     id CHAR(36) PRIMARY KEY,';
        SQL := SQL + '     fornecedor_item_id CHAR(36) NOT NULL,';
        SQL := SQL + '     unidade_fornecedor VARCHAR(10) NOT NULL,';
        SQL := SQL + '     unidade_interna VARCHAR(10) NOT NULL,';
        SQL := SQL + '     fator DECIMAL(15,6) NOT NULL,';
        SQL := SQL + '     criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,';
        SQL := SQL +
          '     FOREIGN KEY (fornecedor_item_id) REFERENCES fornecedor_item(id)';
        SQL := SQL + ' );';
        ExecultaSQL(SQL);
        // ============================================================
        // TABELA: nota_fiscal
        // ============================================================
        SQL := ' CREATE TABLE nota_fiscal (';
        SQL := SQL + '     id CHAR(36) PRIMARY KEY,';
        SQL := SQL + '     fornecedor_id CHAR(36) NOT NULL,';
        SQL := SQL + '     serie VARCHAR(10),';
        SQL := SQL + '     numero VARCHAR(20),';
        SQL := SQL + '     chave VARCHAR(44) UNIQUE,';
        SQL := SQL + '     modelo VARCHAR(5),';
        SQL := SQL + '     tipo ENUM("NF", "NFCe"),';
        SQL := SQL + '     data_emissao DATETIME,';
        SQL := SQL + '     data_entrada DATETIME,';
        SQL := SQL + '     vNF DECIMAL(15,2),';
        SQL := SQL + '     vFrete DECIMAL(15,2),';
        SQL := SQL + '     vDesc DECIMAL(15,2),';
        SQL := SQL + '     vOutro DECIMAL(15,2),';
        SQL := SQL + '     xml_original LONGTEXT,';
        SQL := SQL +
          '     status_importacao ENUM("pendente", "processada", "erro") DEFAULT "pendente",';
        SQL := SQL + '     criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,';
        SQL := SQL +
          '     FOREIGN KEY (fornecedor_id) REFERENCES fornecedor(id)';
        SQL := SQL + ' );';
        ExecultaSQL(SQL);
        // ============================================================
        // TABELA: nota_fiscal_item
        // ============================================================
        SQL := ' CREATE TABLE nota_fiscal_item (';
        SQL := SQL + '     id CHAR(36) PRIMARY KEY,';
        SQL := SQL + '     nota_fiscal_id CHAR(36) NOT NULL,';
        SQL := SQL + '     fornecedor_item_id CHAR(36),';
        SQL := SQL + '     cProd VARCHAR(60),';
        SQL := SQL + '     xProd VARCHAR(255),';
        SQL := SQL + '     NCM VARCHAR(20),';
        SQL := SQL + '     CFOP VARCHAR(10),';
        SQL := SQL + '     qCom DECIMAL(15,6),';
        SQL := SQL + '     uCom VARCHAR(10),';
        SQL := SQL + '     vUnCom DECIMAL(15,6),';
        SQL := SQL + '     vProd DECIMAL(15,2),';
        SQL := SQL + '     vDesc DECIMAL(15,2),';
        SQL := SQL + '     vFrete DECIMAL(15,2),';
        SQL := SQL + '     vOutro DECIMAL(15,2),';
        SQL := SQL +
          '     vTotal DECIMAL(15,2) GENERATED ALWAYS AS (vProd - IFNULL(vDesc,0) + IFNULL(vFrete,0) + IFNULL(vOutro,0)) STORED,';
        SQL := SQL + '     uTrib VARCHAR(10),';
        SQL := SQL + '     criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,';
        SQL := SQL +
          '     FOREIGN KEY (nota_fiscal_id) REFERENCES nota_fiscal(id),';
        SQL := SQL +
          '     FOREIGN KEY (fornecedor_item_id) REFERENCES fornecedor_item(id)';
        SQL := SQL + ' );';
        ExecultaSQL(SQL);
        ExecultaSQL
          ('insert into usuario (codigo,nome) values (-1,"QRCOD MESA");');
        ExecultaSQL
          ('insert into usuario (codigo,nome) values (-2,"PEDIDO SITE");');
      end;
      124: begin
        ExecultaSQL('ALTER TABLE fornecedor_item ADD COLUMN fator FLOAT NULL DEFAULT 0;');
      end;
    99999999:
      begin
        {


        }
      end;
  end;

end;

function TSQL.VersaoExe: String;
begin
  Result := '123';
end;

end.
