unit uSQL;

interface

uses
  IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase,
  IdFTP, System.Zip, ShellAPI, Registry, System.Classes, FMX.StdCtrls,
  Vcl.StdCtrls, FireDAC.Comp.Client, DataSet.Serialize;

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

    function MaiorValorDaLista(const Lista: string): Integer;
    function ValoresSemMaior(const Lista: string): string;
    procedure CriarPrimeiraParticaoPedidoAll;
    function FromDays(Days: Integer): TDate;

  var

    CodigoSQL: Integer;
    UltimoSQL: Integer; // Inicial 1
    UltimoSQLBanco: Integer;
    ListaSQL: TStringList;
  public
    constructor Create;
    procedure VerificaAtualizacao;
    procedure AtualizarBanco;
    procedure LimpaClientesDuplicado;
    procedure ProcessaHistoricoCliente(DataBase: TDate);

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

procedure TSQL.CriarPrimeiraParticaoPedidoAll;
var

  conexao: TConexao;
begin
  conexao := TConexao.Create('CriarPrimeiraParticaoPedidoAll');
  conexao.CriarParticoesHistoricasPedidoAll;
  conexao.ExecuteSQL;
end;

function TSQL.ExecultaSQL(SQL: String): Boolean;
begin
  ListaSQL.Add(SQL);

end;

function TSQL.FromDays(Days: Integer): TDate;
begin
  Result := EncodeDate(0001, 1, 1) + Days - 366;
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

procedure TSQL.LimpaClientesDuplicado;
var
  conexao: TConexao;
  dados: TFDMemTable;
  nomeTabela: TFDMemTable;
  CodigoCliente: Integer;
begin
  conexao := TConexao.Create('LimpaClientesDuplicado');
  nomeTabela := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT distinct concat("pedido_",referencia) as tabela, 0 FROM index_pedido');
  nomeTabela.LoadFromJSON(conexao.ConsultaSQL);

  conexao.SQL.Add('SELECT');
  conexao.SQL.Add('    nome_norm,');
  conexao.SQL.Add('    contato_norm,');
  conexao.SQL.Add('    COUNT(*) AS total,');
  conexao.SQL.Add('    GROUP_CONCAT(codigo) AS ids');
  conexao.SQL.Add('FROM (');
  conexao.SQL.Add('    SELECT ');
  conexao.SQL.Add('        CASE ');
  conexao.SQL.Add
    ('            WHEN nome IS NULL OR nome = "" THEN "__SEM_NOME__"');
  conexao.SQL.Add('            ELSE UPPER(TRIM(nome))');
  conexao.SQL.Add('        END AS nome_norm,');
  conexao.SQL.Add('        CASE');
  conexao.SQL.Add
    ('            WHEN cpf IS NOT NULL AND cpf <> "" THEN REPLACE(REPLACE(REPLACE(cpf, ".", ""), "-", ""), " ", "")');
  conexao.SQL.Add
    ('            WHEN celular IS NOT NULL AND celular <> "" THEN REPLACE(REPLACE(REPLACE(REPLACE(celular, "(", ""), ")", ""), "-", ""), " ", "")');
  conexao.SQL.Add
    ('            WHEN celular_wpp IS NOT NULL AND celular_wpp <> "" THEN REPLACE(REPLACE(REPLACE(REPLACE(celular_wpp, "(", ""), ")", ""), "-", ""), " ", "")');
  conexao.SQL.Add('            ELSE ""');
  conexao.SQL.Add('        END AS contato_norm,');
  conexao.SQL.Add('');
  conexao.SQL.Add('        codigo');
  conexao.SQL.Add('    FROM cliente');
  conexao.SQL.Add(') AS t');
  conexao.SQL.Add('GROUP BY nome_norm, contato_norm');
  conexao.SQL.Add('HAVING COUNT(*) > 1;');

  dados := TFDMemTable.Create(nil);
  dados.LoadFromJSON(conexao.ConsultaSQL);
  if dados.RecordCount > 0 then
  begin
    while not dados.Eof do
    begin
      CodigoCliente := MaiorValorDaLista(dados.FieldByName('ids').AsString);

      if nomeTabela.RecordCount > 0 then
      begin
        nomeTabela.First;
        while not nomeTabela.Eof do
        begin
          conexao.SQL.Add('update ' + nomeTabela.FieldByName('tabela').AsString
            + ' set codigo_cliente = :cliente where codigo_cliente in (' +
            dados.FieldByName('ids').AsString + ')');
          conexao.Parametros('cliente', CodigoCliente);
          conexao.ExecuteSQL;
          nomeTabela.Next;
        end;
      end;
      conexao.SQL.Add
        ('update cliente_endereco set codigo_cliente = :codigo where codigo in ('
        + dados.FieldByName('ids').AsString + ')');
      conexao.Parametros('codigo', CodigoCliente);
      conexao.ExecuteSQL;

      conexao.SQL.Add('delete from cliente where codigo in (' +
        ValoresSemMaior(dados.FieldByName('ids').AsString) + ')');
      conexao.ExecuteSQL;

      dados.Next;
    end;
  end;

  dados.Free;
  nomeTabela.Free;
  conexao.Free;

end;

function TSQL.MaiorValorDaLista(const Lista: string): Integer;
var
  Partes: TArray<string>;
  I, N, Maior: Integer;
begin
  Result := 0;
  if Trim(Lista) = '' then
    Exit;

  Partes := Lista.Split([',']);
  Maior := Low(Integer);

  for I := 0 to High(Partes) do
  begin
    if TryStrToInt(Trim(Partes[I]), N) then
      if N > Maior then
        Maior := N;
  end;

  Result := Maior;
end;

procedure TSQL.ProcessaHistoricoCliente(DataBase: TDate);
var
  conexao: TConexao;
  DataAtual: TDate;
  AnoInicial, MesInicial, Dia: Word;
  AnoAtual, MesAtual: Word;
  Ano, Mes: Integer;
  DataInicioMes, DataFimMes: TDate;
  tabela: String;
  dados: TFDMemTable;
begin
  conexao := TConexao.Create('ProcessaHistoricoCliente');
  try
    DataAtual := Date; // hoje

    DecodeDate(DataBase, AnoInicial, MesInicial, Dia);
    DecodeDate(DataAtual, AnoAtual, MesAtual, Dia);

    // Loop do ano/mês inicial até o ano/mês anterior ao atual
    Ano := AnoInicial;
    Mes := MesInicial;

    while (Ano < AnoAtual) or ((Ano = AnoAtual) and (Mes < MesAtual)) do
    begin
      // Monta início e fim do mês
      DataInicioMes := EncodeDate(Ano, Mes, 1);
      tabela := 'pedido_' + Ano.ToString + '_' + FormatFloat('00', Mes);
      dados := TFDMemTable.Create(nil);
      conexao.SQL.Add('SELECT ');
      conexao.SQL.Add('    codigo_cliente,    ');
      conexao.SQL.Add('    COUNT(*) AS total_pedidos,');
      conexao.SQL.Add('    SUM(valor_total_pedido) AS total_valor_pedidos,');
      conexao.SQL.Add
        ('    SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS qtd_cancelados,');
      conexao.SQL.Add
        ('    SUM(CASE WHEN status = 0 THEN valor_total_pedido ELSE 0 END) AS valor_cancelado,');
      conexao.SQL.Add
        ('    SUM(CASE WHEN status <> 0 THEN 1 ELSE 0 END) AS qtd_finalizados,');
      conexao.SQL.Add
        ('    SUM(CASE WHEN status <> 0 THEN valor_total_pedido ELSE 0 END) AS valor_finalizado,');
      conexao.SQL.Add('	MAX(data_pedido) as ultimo');
      conexao.SQL.Add('FROM ' + tabela);
      conexao.SQL.Add('GROUP BY codigo_cliente');
      conexao.SQL.Add('ORDER BY total_pedidos DESC');
      dados.LoadFromJSON(conexao.ConsultaSQL);

      if dados.RecordCount > 0 then
      begin
        while not dados.Eof do
        begin

          conexao.SQL.Add
            ('update cliente set total_cancelados = total_cancelados+ :total_cancelados, total_efetivados = total_efetivados + :total_efetivados,');
          conexao.SQL.Add
            ('valor_total_cancelado = valor_total_cancelado + :valor_total_cancelado, valor_total_pedidos = valor_total_pedidos + :valor_total_pedidos,');
          conexao.SQL.Add
            ('data_ultima_atualizacao = :data where codigo = :codigo and data_ultima_atualizacao < :data');
          conexao.Parametros('total_cancelados',
            dados.FieldByName('qtd_cancelados').AsInteger);
          conexao.Parametros('total_efetivados',
            dados.FieldByName('qtd_finalizados').AsInteger);
          conexao.Parametros('valor_total_cancelado',
            dados.FieldByName('valor_cancelado').AsFloat);
          conexao.Parametros('valor_total_pedidos',
            dados.FieldByName('valor_finalizado').AsFloat);
          conexao.Parametros('codigo', dados.FieldByName('codigo_cliente')
            .AsInteger);
          conexao.Parametros('data', dados.FieldByName('ultimo').AsString);
          conexao.ExecuteSQL;

          dados.Next;
        end;
      end;

      dados.Free;

      // Próximo mês
      Inc(Mes);
      if Mes > 12 then
      begin
        Mes := 1;
        Inc(Ano);
      end;
    end;

  finally
    conexao.Free;
  end;
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

function TSQL.ValoresSemMaior(const Lista: string): string;
var
  Partes: TArray<string>;
  I, N, Maior: Integer;
  ResultList: TStringList;
begin
  Result := '';

  if Trim(Lista) = '' then
    Exit;

  Partes := Lista.Split([',']);
  Maior := Low(Integer);

  // Primeiro: descobrir o maior valor
  for I := 0 to High(Partes) do
    if TryStrToInt(Trim(Partes[I]), N) then
      if N > Maior then
        Maior := N;

  // Segundo: montar lista sem os valores iguais ao maior
  ResultList := TStringList.Create;
  try
    ResultList.Delimiter := ',';
    ResultList.StrictDelimiter := True;

    for I := 0 to High(Partes) do
    begin
      if TryStrToInt(Trim(Partes[I]), N) then
      begin
        if N <> Maior then
          ResultList.Add(IntToStr(N));
      end;
    end;

    Result := ResultList.DelimitedText;
  finally
    ResultList.Free;
  end;
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
    124:
      begin
        ExecultaSQL
          ('ALTER TABLE fornecedor_item ADD COLUMN fator FLOAT NULL DEFAULT 0;');
        ExecultaSQL
          ('alter table dados_whatsapp add mensagem_conclusao varchar(2555);');
        ExecultaSQL
          ('alter table dados_whatsapp add conclusao_envio_range varchar(20) default "3,24";');
      end;
    125:
      begin
        SQL := 'CREATE TABLE dfe_consulta (';
        SQL := SQL + '  id INT AUTO_INCREMENT PRIMARY KEY,';
        SQL := SQL + '  cnpj_empresa VARCHAR(18) NOT NULL,';
        SQL := SQL + '  data_consulta DATE NOT NULL,';
        SQL := SQL + '  hora_consulta TIME NOT NULL,';
        SQL := SQL + '  ultimo_nsu VARCHAR(15) NOT NULL,';
        SQL := SQL + '  qtd_documentos INT DEFAULT 0,';
        SQL := SQL +
          '  ambiente ENUM("producao", "homologacao") DEFAULT "producao",';
        SQL := SQL + '  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP';
        SQL := SQL +
          ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;';
        ExecultaSQL(SQL);
        SQL := ' CREATE TABLE dfe_documento (';
        SQL := SQL + '   id INT AUTO_INCREMENT PRIMARY KEY,';
        SQL := SQL + '   id_consulta INT NOT NULL,';
        SQL := SQL + '   nsu VARCHAR(15) NOT NULL,';
        SQL := SQL + '   chave VARCHAR(44) NOT NULL,';
        SQL := SQL + '   cnpj_emitente VARCHAR(18),';
        SQL := SQL + '   nome_emitente VARCHAR(150),';
        SQL := SQL + '   valor DECIMAL(15,2),';
        SQL := SQL + '   data_emissao DATETIME,';
        SQL := SQL + '   situacao VARCHAR(30),';
        SQL := SQL + '   xml_base64 LONGTEXT,';
        SQL := SQL + '   tipo ENUM("nfe", "evento", "resumo") DEFAULT "nfe",';
        SQL := SQL + '   criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,';
        SQL := SQL + '   UNIQUE KEY uk_chave (chave),';
        SQL := SQL + '   INDEX idx_nsu (nsu),';
        SQL := SQL +
          '   CONSTRAINT fk_dfe_consulta FOREIGN KEY (id_consulta) REFERENCES dfe_consulta(id)';
        SQL := SQL + '     ON DELETE CASCADE';
        SQL := SQL +
          ' ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;';
        ExecultaSQL(SQL);
        ExecultaSQL
          ('ALTER TABLE despesas ADD COLUMN `chave_nota` VARCHAR(45);');
      end;
    126:
      begin
        ExecultaSQL
          ('CREATE INDEX idx_estoque_ingrediente_id_desc ON ingredientes_estoque (id_ingredientes, id DESC);');
        ExecultaSQL
          ('CREATE INDEX idx_estoque_ingrediente_quantidade ON ingredientes_estoque (id_ingredientes, quantidade);');
        ExecultaSQL
          ('CREATE INDEX idx_cliente_endereco_cliente_codigo ON cliente_endereco (codigo_cliente, codigo DESC);');
        ExecultaSQL('CREATE INDEX idx_cliente_nome ON cliente (nome);');
        ExecultaSQL
          ('CREATE INDEX idx_cliente_endereco_cliente_codigo ON cliente_endereco (codigo_cliente, codigo);');
        ExecultaSQL
          ('ALTER TABLE fornecedor_item ADD COLUMN fator FLOAT NULL DEFAULT 1;');
        ExecultaSQL('delete from produto_estoque');
        ExecultaSQL('alter table produto_estoque add transacao varchar(255)');
        ExecultaSQL
          ('ALTER TABLE produto_estoque ADD UNIQUE KEY unq_pedido_item (transacao);');
      end;
    127:
      begin

        SQL := ' CREATE TRIGGER trg_produto_estoque_after_insert';
        SQL := SQL + ' AFTER INSERT ON produto_estoque';
        SQL := SQL + ' FOR EACH ROW';
        SQL := SQL + ' BEGIN';
        SQL := SQL + '     DECLARE v_saldo INT DEFAULT 0;';
        SQL := SQL + '     DECLARE v_status INT DEFAULT 0;';
        SQL := SQL + '     DECLARE v_mov INT DEFAULT 0;';
        SQL := SQL + '     DECLARE v_controle INT DEFAULT 0;';
        SQL := SQL + '     SET v_mov := CASE';
        SQL := SQL + '         WHEN NEW.operacao = 1 THEN NEW.quantidade';
        SQL := SQL + '         WHEN NEW.operacao = 2 THEN -NEW.quantidade';
        SQL := SQL + '         ELSE 0';
        SQL := SQL + '     END;';
        SQL := SQL + '     SELECT controle_estoque INTO v_controle';
        SQL := SQL + '     FROM produto';
        SQL := SQL + '     WHERE codigo = NEW.codigo_produto;';
        SQL := SQL + '     IF v_controle = 1 THEN';
        SQL := SQL + '         UPDATE produto';
        SQL := SQL +
          '         SET saldo_atual = IFNULL(saldo_atual, 0) + v_mov';
        SQL := SQL + '         WHERE codigo = NEW.codigo_produto;';
        SQL := SQL + '         SELECT saldo_atual INTO v_saldo';
        SQL := SQL + '         FROM produto';
        SQL := SQL + '         WHERE codigo = NEW.codigo_produto;';
        SQL := SQL + '         IF v_saldo > 0 THEN';
        SQL := SQL + '             SET v_status = 1;';
        SQL := SQL + '         ELSE';
        SQL := SQL + '             SET v_status = 0;';
        SQL := SQL + '         END IF;';
        SQL := SQL + '         UPDATE produto';
        SQL := SQL + '         SET ativo = v_status,';
        SQL := SQL + '             modificado_site = 0';
        SQL := SQL +
          '         WHERE codigo = NEW.codigo_produto and controle_estoque = 1; ';
        SQL := SQL + '     END IF;';
        SQL := SQL + '     UPDATE pro_adi_personalizado_sabores';
        SQL := SQL + '     SET ativo = v_status,';
        SQL := SQL + '         modificado_site = 0';
        SQL := SQL + '     WHERE id_prod_estoque = NEW.codigo_produto;';
        SQL := SQL + ' END';
        ExecultaSQL(SQL);
      end;
    128:
      begin
        SQL := ' ALTER TABLE `cliente`';
        SQL := SQL + ' DROP COLUMN `fidelidade_desconto`,';
        SQL := SQL + ' DROP COLUMN `fidelidade_ponto`,';
        SQL := SQL + ' DROP COLUMN `id_cliente_site`,';
        SQL := SQL + ' DROP COLUMN `cashback_saldo`,';
        SQL := SQL + ' DROP COLUMN `oculto`,';
        SQL := SQL + ' DROP COLUMN `salvar_dados`,';
        SQL := SQL + ' DROP COLUMN `bloqueado`;';
        ExecultaSQL(SQL);

        SQL := ' ALTER TABLE cliente';
        SQL := SQL + ' ADD total_pedidos INT DEFAULT 0,';
        SQL := SQL + ' ADD total_cancelados INT DEFAULT 0,';
        SQL := SQL + ' ADD total_efetivados INT DEFAULT 0,';
        SQL := SQL + ' ADD percentual_cancelado DECIMAL(5,2) DEFAULT 0,';
        SQL := SQL + ' ADD percentual_efetivado DECIMAL(5,2) DEFAULT 0,';
        SQL := SQL + ' ADD nota_cliente DECIMAL(3,2) DEFAULT 0,';
        SQL := SQL + ' ADD valor_total_pedidos DECIMAL(10,2) DEFAULT 0,';
        SQL := SQL + ' ADD valor_total_cancelado DECIMAL(10,2) DEFAULT 0,';
        SQL := SQL + ' ADD data_ultima_atualizacao DATETIME NULL;';
        ExecultaSQL(SQL);
        ExecultaSQL
          ('update cliente set total_efetivados = 0, valor_total_pedidos = 0, data_ultima_atualizacao = "2000-01-01"');
      end;
    129:
      begin
        ExecultaSQL
          ('ALTER TABLE impressao_pedido_produto MODIFY id INT NOT NULL AUTO_INCREMENT;');
        SQL := ' CREATE TRIGGER trg_pedido_produtos_after_insert ';
        SQL := SQL + ' AFTER INSERT ON pedido_produtos';
        SQL := SQL + ' FOR EACH ROW';
        SQL := SQL + ' BEGIN';
        SQL := SQL + '     INSERT INTO impressao_pedido_produto (';
        SQL := SQL + '         data_solicitacao,';
        SQL := SQL + '         hora_solicitacao,';
        SQL := SQL + '         data_impressao,';
        SQL := SQL + '         hora_impressao,';
        SQL := SQL + '         id_pedido,';
        SQL := SQL + '         status,';
        SQL := SQL + '         vias,';
        SQL := SQL + '         usuario';
        SQL := SQL + '     ) VALUES (';
        SQL := SQL + '         CURDATE(),';
        SQL := SQL + '         CURTIME(),';
        SQL := SQL + '         NULL,';
        SQL := SQL + '         NULL,';
        SQL := SQL + '         NEW.codigo,';
        SQL := SQL + '         0,';
        SQL := SQL + '         1,';
        SQL := SQL + '         NEW.usuario';
        SQL := SQL + '     );';
        SQL := SQL + ' END ';
        ExecultaSQL(SQL);
      end;
    130:
      begin
       
       
        SQL := ' CREATE PROCEDURE migrar_tabela(';
        SQL := SQL + '     IN baseTable VARCHAR(100),';
        SQL := SQL + '     IN oldTable VARCHAR(100),';
        SQL := SQL + '     IN targetTable VARCHAR(100)';
        SQL := SQL + ' )';
        SQL := SQL + ' migracao: BEGIN';
        SQL := SQL + '     DECLARE colList TEXT;';
        SQL := SQL + '     DECLARE sqlCmd TEXT;';
        SQL := SQL + ' ';
        SQL := SQL + '     DECLARE qtOrigem BIGINT DEFAULT 0;';
        SQL := SQL + '     DECLARE qtDestinoAntes BIGINT DEFAULT 0;';
        SQL := SQL + '     DECLARE qtDestinoDepois BIGINT DEFAULT 0;';
        SQL := SQL + '     DECLARE qtInseridos BIGINT DEFAULT 0;';
        SQL := SQL + ' ';
        SQL := SQL + '     IF NOT EXISTS (';
        SQL := SQL + '         SELECT 1 FROM information_schema.tables';
        SQL := SQL + '         WHERE table_schema = DATABASE()';
        SQL := SQL + '           AND table_name = oldTable';
        SQL := SQL + '     ) THEN';
        SQL := SQL + '         LEAVE migracao;';
        SQL := SQL + '     END IF;';
        SQL := SQL + ' ';
        SQL := SQL +
          '     SET @q1 = CONCAT("SELECT COUNT(*) INTO @qtOrigem FROM ", oldTable);';
        SQL := SQL + '     PREPARE s1 FROM @q1;';
        SQL := SQL + '     EXECUTE s1;';
        SQL := SQL + '     DEALLOCATE PREPARE s1;';
        SQL := SQL + '     SET qtOrigem = @qtOrigem;';
        SQL := SQL + ' ';
        SQL := SQL +
          '     SET @q2 = CONCAT("SELECT COUNT(*) INTO @qtDestinoAntes FROM ", targetTable);';
        SQL := SQL + '     PREPARE s2 FROM @q2;';
        SQL := SQL + '     EXECUTE s2;';
        SQL := SQL + '     DEALLOCATE PREPARE s2;';
        SQL := SQL + '     SET qtDestinoAntes = @qtDestinoAntes;';

        SQL := SQL +
          '     SELECT GROUP_CONCAT(c.COLUMN_NAME ORDER BY c.ORDINAL_POSITION)';
        SQL := SQL + '     INTO colList';
        SQL := SQL + '     FROM information_schema.columns c';
        SQL := SQL + '     WHERE c.table_schema = DATABASE()';
        SQL := SQL + '       AND c.table_name = baseTable';
        SQL := SQL + '       AND c.COLUMN_NAME IN (';
        SQL := SQL + '             SELECT COLUMN_NAME';
        SQL := SQL + '             FROM information_schema.columns';
        SQL := SQL + '             WHERE table_schema = DATABASE()';
        SQL := SQL + '               AND table_name = oldTable';
        SQL := SQL + '       );';
        SQL := SQL + ' ';
        SQL := SQL + '     IF colList IS NULL THEN';
        SQL := SQL + '         LEAVE migracao;';
        SQL := SQL + '     END IF;';
        SQL := SQL + ' ';
        SQL := SQL + ' ';
        SQL := SQL + '     SET sqlCmd = CONCAT(';
        SQL := SQL +
          '         "INSERT INTO ", targetTable, " (", colList, ") ",';
        SQL := SQL + '         "SELECT ", colList, " FROM ", oldTable';
        SQL := SQL + '     );';
        SQL := SQL + ' ';
        SQL := SQL + '     SET @s = sqlCmd;';
        SQL := SQL + '     PREPARE stmt FROM @s;';
        SQL := SQL + '     EXECUTE stmt;';
        SQL := SQL + '     DEALLOCATE PREPARE stmt;';
        SQL := SQL +
          '     SET @q3 = CONCAT("SELECT COUNT(*) INTO @qtDestinoDepois FROM ", targetTable);';
        SQL := SQL + '     PREPARE s3 FROM @q3;';
        SQL := SQL + '     EXECUTE s3;';
        SQL := SQL + '     DEALLOCATE PREPARE s3;';
        SQL := SQL + '     SET qtDestinoDepois = @qtDestinoDepois;';
        SQL := SQL + ' ';
        SQL := SQL + '     SET qtInseridos = qtDestinoDepois - qtDestinoAntes;';
        SQL := SQL + ' ';
        SQL := SQL + '     IF qtInseridos = qtOrigem THEN';
        SQL := SQL + '         SET @q4 = CONCAT("DROP TABLE ", oldTable);';
        SQL := SQL + '         PREPARE s4 FROM @q4;';
        SQL := SQL + '         EXECUTE s4;';
        SQL := SQL + '         DEALLOCATE PREPARE s4;';
        SQL := SQL + '     END IF;';
        SQL := SQL + ' ';
        SQL := SQL + ' END;';
        ExecultaSQL(SQL);
      end;
    133:
      begin
        ExecultaSQL('ALTER TABLE `pedido` ENGINE = InnoDB');
        CriarPrimeiraParticaoPedidoAll;
        SQL := ' CREATE PROCEDURE criar_proxima_particao_pedido_all()';
        SQL := SQL + ' proc: BEGIN';
        SQL := SQL + '     DECLARE ult_descricao BIGINT;';
        SQL := SQL + '     DECLARE ult_data DATE;';
        SQL := SQL + '     DECLARE prox_data DATE;';
        SQL := SQL + '     DECLARE limite DATE;';
        SQL := SQL + '     DECLARE nome_part VARCHAR(20);';
        SQL := SQL + '     DECLARE sql_cmd TEXT;';
        SQL := SQL + ' ';
        SQL := SQL + '     SELECT PARTITION_DESCRIPTION';
        SQL := SQL + '     INTO ult_descricao';
        SQL := SQL + '     FROM INFORMATION_SCHEMA.PARTITIONS';
        SQL := SQL + '     WHERE TABLE_SCHEMA = DATABASE()';
        SQL := SQL + '       AND TABLE_NAME = "pedido"';
        SQL := SQL + '       AND PARTITION_NAME IS NOT NULL';
        SQL := SQL + '     ORDER BY PARTITION_DESCRIPTION + 0 DESC';
        SQL := SQL + '     LIMIT 1;';
        SQL := SQL + ' ';
        SQL := SQL + '     IF ult_descricao IS NULL THEN';
        SQL := SQL + '         LEAVE proc;';
        SQL := SQL + '     END IF;';
        SQL := SQL + ' ';
        SQL := SQL + '     SET ult_data = FROM_DAYS(ult_descricao);';
        SQL := SQL +
          '     SET prox_data = DATE_ADD(ult_data, INTERVAL 1 MONTH);';
        SQL := SQL +
          '     SET limite    = DATE_ADD(prox_data, INTERVAL 1 MONTH);';
        SQL := SQL + ' ';
        SQL := SQL +
          '     SET nome_part = CONCAT("p", DATE_FORMAT(prox_data, "%Y%m"));';
        SQL := SQL + ' ';
        SQL := SQL + '     SET sql_cmd = CONCAT(';
        SQL := SQL + '         "ALTER TABLE pedido ADD PARTITION ( ",';
        SQL := SQL + '         "PARTITION ", nome_part,';
        SQL := SQL +
          '         " VALUES LESS THAN (TO_DAYS(""", limite, """))",';
        SQL := SQL + '         " )"';
        SQL := SQL + '     );';
        SQL := SQL + ' ';
        SQL := SQL + '     SET @s = sql_cmd;';
        SQL := SQL + '     PREPARE stmt FROM @s;';
        SQL := SQL + '     EXECUTE stmt;';
        SQL := SQL + '     DEALLOCATE PREPARE stmt;';
        SQL := SQL + ' END';
        ExecultaSQL(SQL);
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
  Result := '133';
end;

end.
