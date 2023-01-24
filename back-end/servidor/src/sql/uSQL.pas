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
            AposConcluirAtualizacao;

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
  conexao := TConexao.Create;
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

  if Assigned(AposConcluirAtualizacao) then
    AposConcluirAtualizacao;
  conexao.Free;
end;

procedure TSQL.VerificaAtualizacao;
begin

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

    if Assigned(AposConcluirAtualizacao) then
      AposConcluirAtualizacao;

    MemoLog.Lines.Clear;

  end;
end;

function TSQL.VerificaSQL: Boolean;
var
  conexao: TConexao;
begin
  Result := False;

  conexao := TConexao.Create;

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
begin
  ExecultaSQL
    ('create table geradores ( tabela varchar(255) not null, sequencial integer);');
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

    // Deve-se Rodar manual esses sql
    99999999:
      begin
        {


        }
      end;
  end;

end;

function TSQL.VersaoExe: String;
begin
  Result := '14';
end;

end.
