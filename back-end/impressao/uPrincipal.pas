unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.ImageList, Vcl.ImgList,
  Vcl.ExtCtrls, requisicao, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls, XSuperObject, DataSet.Serialize,
  Winapi.TlHelp32;

type
  TInsertUpdateSite = class
  public
    function InserirUpdate(Tabela, User: String;
      ArrayCampos, ArrayValores: Array of String): Integer;
  end;

  TConexaoSite = class(TThread)
    FRequestSite: TRequest;
    Segundos: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TBuscaPedidos = class(TThread)
    MemoryTablePedidos: TFDMemTable;
    MemoryDadosItem: TFDMemTable;
    GetPedidos: Boolean;

    FUserID: Integer;
    FRequest: TRequest;
    Segundos: Integer;
    function getUser: Integer;

    property UserID: Integer read getUser;
    function TipoPedido: Integer;
  protected
    procedure Execute; override;
    procedure InserirPedidos;
    function BuscaItems(User, codigo: Integer): String;
    function QtdSabores(Valor: String): Integer;
    function Cliente(Nome, Telefone: String): Integer;
    function ClienteEndereco(CodigoCliente: Integer;
      Rua, Bairro, Cidade, Estado, Numero, Complemento: String): Integer;
    function ValorValido(Valor: Integer): Boolean;
    function GeraCodigoPorDiaPedido: Integer;
    function CodigoFormaPagamento(Forma: String): Integer;
    function CodigoProduto(CodigoSite: Integer): Integer;
    function ConverteValor(Valor: String): Real;

  published
  public
    constructor Create;
    destructor Destroy; override;
    function ExecutaSQLSite(SQL: String): Boolean;
  end;

  TfrmPrincipal = class(TForm)
    TrayIcon: TTrayIcon;
    imagemConectado: TImageList;
    imagemDesconectado: TImageList;
    memRequisicoes: TFDMemTable;
    memRequisicoesID: TIntegerField;
    memRequisicoesURL: TStringField;
    memRequisicoesDATA: TDateField;
    memRequisicoesHORA: TTimeField;
    memRequisicoesHORA_RESPOSTA: TTimeField;
    memRequisicoesBODY: TBlobField;
    memRequisicoesTOKEN: TStringField;
    DBGrid1: TDBGrid;
    memRequisicoesTEMPO: TStringField;
    memRequisicoesSTATUS: TIntegerField;
    memRequisicoesSTATUS_DESC: TStringField;
    memRequisicoesDATA_RESPOSTA: TDateField;
    lStatus: TLabel;
    DataSource1: TDataSource;
    lRequisicoes: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    FStatusConexao: Boolean;
    FIdRequisicao: Integer;
    FNomeRestaurante: String;
    FToken: String;
    FUsuario: Integer;
    FHomologacao: Boolean;
    FTempoEspera: Integer;
    procedure SetStatusConexao(const Value: Boolean);
    procedure SetIdRequisicao(const Value: Integer);
    function GetIdRequisicao: Integer;
    function getClientID: String;
    function getClientSecurity: String;
    procedure SetNomeRestaurante(const Value: String);
    procedure SetToken(const Value: String);
    procedure SetUsuario(const Value: Integer);

    Function Verifica(ExeFileName: String): Integer;

    // Taxa
    procedure EnviaTaxa;
    // Tipo Pagamento
    procedure EnviaTipoPagamento;
    // Categoria
    procedure EnviaCategoria;
    // Produto
    procedure EnviaProduto;
    // Adicionais
    procedure EnviaAdicionais;
    procedure EnviaComplementoAdicionais;
    // Sabores
    procedure EnviarSabores;
    procedure SetHomologacao(const Value: Boolean);
    procedure SetTempoEspera(const Value: Integer);

    function GetTempoEspera: Integer;
    function ConsultaSerialHD: String;
    { Private declarations }
  public
    // Envia pro Site
    procedure AtualizaSite;

    { Public declarations }
    property StatusConexao: Boolean read FStatusConexao write SetStatusConexao;
    property IdRequisicao: Integer read GetIdRequisicao write SetIdRequisicao;

    // Client
    property ClientID: String read getClientID;
    property ClientSecurity: String read getClientSecurity;
    property NomeRestaurante: String read FNomeRestaurante
      write SetNomeRestaurante;
    property Token: String read FToken write SetToken;
    property Usuario: Integer read FUsuario write SetUsuario;

    property TempoEspera: Integer read FTempoEspera write SetTempoEspera;

    property Homologacao: Boolean read FHomologacao write SetHomologacao;
    property SerialHD: String read ConsultaSerialHD;
  end;

var
  frmPrincipal: TfrmPrincipal;
  BuscaPedidoThread: TBuscaPedidos;
  ConexaoSite: TConexaoSite;

const
  URL_SITE = 'api.papaleguasfood.com.br/';

implementation

{$R *.dfm}

uses metodo.api, System.IniFiles;
{ TConexaoSite }

constructor TConexaoSite.Create;
begin
  inherited Create(True);
  FRequestSite := TRequest.Create;
  FRequestSite.BASEURL := URL_SITE;
  Segundos := 60;

end;

destructor TConexaoSite.Destroy;
begin

  inherited;
end;

procedure TConexaoSite.Execute;
begin
  inherited;

  while not Terminated do
  begin
    FRequestSite.URLI := 'status/a';
    FRequestSite.Get;
    frmPrincipal.StatusConexao := FRequestSite.Status = 200;
    // 1000
    Free;
    Sleep(Segundos * 1000);
  end;

end;

{ TfrmPrincipal }

procedure TfrmPrincipal.AtualizaSite;
begin
  if Homologacao then
    exit;
  EnviaTaxa;
  EnviaTipoPagamento;
  EnviaCategoria;
  EnviaProduto;
  EnviaAdicionais;
  EnviaComplementoAdicionais;
  EnviarSabores;
end;

function TfrmPrincipal.ConsultaSerialHD: String;
Var
  Serial: DWORD;
  DirLen, Flags: DWORD;
  DLabel: Array [0 .. 11] of Char;
begin
  Try
    GetVolumeInformation(PChar('C:\'), DLabel, 12, @Serial, DirLen,
      Flags, nil, 0);
    Result := IntToHex(Serial, 8);
  Except
    Result := '';
  end;
end;

procedure TfrmPrincipal.EnviaAdicionais;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;
  DadosAdicionais: TFDMemTable;

  InsertSite: TInsertUpdateSite;
begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);
  SQL := 'select * from produto where id_site > 0';
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    Insert.Free;
    Dados.Free;
    exit;
  end;

  Dados.First;
  InsertSite := TInsertUpdateSite.Create;
  DadosAdicionais := TFDMemTable.Create(nil);
  while not Dados.Eof do
  begin
    DadosAdicionais.Close;

    SQL := 'select pap.id, pap.descricao, pap.ativo, pap.qtd_minima, pap.qtd_maxima, pap.id_site, p.id_site as produto, ';
    SQL := SQL + ' tp.id_site as categoria from pro_adi_personalizado as pap';
    SQL := SQL + ' join produto as p on p.codigo = pap.id_produto';
    SQL := SQL + ' join tipo_produto as tp on p.codigo_grupo = tp.codigo';
    SQL := SQL + ' where pap.id_produto = ' + Dados.FieldByName('codigo')
      .AsString +
      ' and (pap.modificado_site = 0 or pap.modificado_site is null)';

    DadosAdicionais.LoadFromJSON(Insert.ConsultaSQL(SQL));

    while not DadosAdicionais.Eof do
    begin

      if DadosAdicionais.FieldByName('ativo').AsInteger = 1 then
      begin
        codigo := InsertSite.InserirUpdate('ws_adicionais_cat',
          Usuario.ToString, ['id', 'user_id', 'pay', 'img_cat', 'id_itens',
          'id_cat', 'name_adicionais_cat', 'minimo', 'amount'],
          [DadosAdicionais.FieldByName('id_site').AsString, Usuario.ToString,
          '1', '', DadosAdicionais.FieldByName('produto').AsString,
          DadosAdicionais.FieldByName('categoria').AsString,
          DadosAdicionais.FieldByName('descricao').AsString,
          DadosAdicionais.FieldByName('qtd_minima').AsString,
          DadosAdicionais.FieldByName('qtd_maxima').AsString]);
        if codigo > 0 then
        begin
          SQL := 'update pro_adi_personalizado set modificado_site = 1 where id = '
            + DadosAdicionais.FieldByName('id').AsString;
          Insert.ExecutaSQL(SQL);
          SQL := 'update pro_adi_personalizado set id_site = ' + codigo.ToString
            + ' where id = ' + DadosAdicionais.FieldByName('id').AsString;
          Insert.ExecutaSQL(SQL);
        end;
      end
      else
      begin
        BuscaPedidoThread.ExecutaSQLSite
          ('delete from ws_adicionais_cat wehre id = ' +
          DadosAdicionais.FieldByName('id_site').AsString);
        SQL := 'update pro_adi_personalizado set modificado_site = 0 where id = '
          + DadosAdicionais.FieldByName('id').AsString;
        Insert.ExecutaSQL(SQL);
        SQL := 'update pro_adi_personalizado set id_site = 0 where id = ' +
          DadosAdicionais.FieldByName('id').AsString;
        Insert.ExecutaSQL(SQL);
      end;

      DadosAdicionais.Next;
    end;

    Dados.Next;
  end;
  DadosAdicionais.Free;
  Dados.Free;
  Insert.Free;
end;

procedure TfrmPrincipal.EnviaCategoria;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;

  InsertSite: TInsertUpdateSite;
begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);
  SQL := 'SELECT tp.*, (select count(*) from produto where codigo_grupo = tp.codigo) as total FROM tipo_produto as tp where tp.modificado_site = 0 order by tp.ordem';
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    Insert.Free;
    Dados.Free;
    exit;
  end;

  Dados.First;
  InsertSite := TInsertUpdateSite.Create;

  while not Dados.Eof do
  begin

    if (Dados.FieldByName('total').AsInteger > 0) then
    begin

      codigo := InsertSite.InserirUpdate('ws_cat', Usuario.ToString,
        ['id', 'user_id', 'dias_semana', 'nome_cat', 'desc_cat', 'icon_cat'],
        [Dados.FieldByName('id_site').AsString, Usuario.ToString,
        'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado',
        Dados.FieldByName('descricao').AsString, '', '']);

      if codigo > 0 then
      begin
        SQL := 'update tipo_produto set modificado_site = 1 where codigo = ' +
          Dados.FieldByName('codigo').AsString;
        Insert.ExecutaSQL(SQL);
        SQL := 'update tipo_produto set id_site = ' + codigo.ToString +
          ' where codigo = ' + Dados.FieldByName('codigo').AsString;
        Insert.ExecutaSQL(SQL);
      end;

    end;

    Dados.Next;
  end;
  Dados.Free;
  Insert.Free;
end;

procedure TfrmPrincipal.EnviaComplementoAdicionais;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;
  DadosAdicionais: TFDMemTable;
  InsertSite: TInsertUpdateSite;
begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);
  SQL := 'select * from pro_adi_personalizado where id_site > 0';
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    Insert.Free;
    Dados.Free;
    exit;
  end;
  Dados.First;
  InsertSite := TInsertUpdateSite.Create;
  DadosAdicionais := TFDMemTable.Create(nil);
  while not Dados.Eof do
  begin
    DadosAdicionais.Close;
    SQL := 'SELECT paps.id, paps.id_site, paps.nome,paps.ativo, paps.valor, pap.id_site as id_adicionais_cat, ';
    SQL := SQL +
      ' tp.id_site as categorias_adicional FROM pro_adi_personalizado_sabores as paps';
    SQL := SQL +
      ' join pro_adi_personalizado as pap on pap.id = paps.id_pro_adi_personalizado';
    SQL := SQL + ' join produto as p on p.codigo = pap.id_produto';
    SQL := SQL + ' join tipo_produto as tp on tp.codigo = p.codigo_grupo';
    SQL := SQL +
      ' where pap.id_site > 0 and paps.modificado_site = 0 and paps.id_pro_adi_personalizado = '
      + Dados.FieldByName('id').AsString;
    DadosAdicionais.LoadFromJSON(Insert.ConsultaSQL(SQL));

    while not DadosAdicionais.Eof do
    begin

      codigo := InsertSite.InserirUpdate('ws_adicionais_itens',
        Usuario.ToString, ['id_adicionais', 'user_id', 'categorias_adicional',
        'id_adicionais_cat', 'medida_adicional', 'nome_adicional',
        'valor_adicional', 'status_adicional'],
        [DadosAdicionais.FieldByName('id_site').AsString, Usuario.ToString,
        DadosAdicionais.FieldByName('categorias_adicional').AsString,
        DadosAdicionais.FieldByName('id_adicionais_cat').AsString, 'UN',
        DadosAdicionais.FieldByName('nome').AsString,
        DadosAdicionais.FieldByName('valor').AsString,
        DadosAdicionais.FieldByName('ativo').AsString]);

      if codigo > 0 then
      begin
        SQL := 'update pro_adi_personalizado_sabores set modificado_site = 1 where id = '
          + DadosAdicionais.FieldByName('id').AsString;
        Insert.ExecutaSQL(SQL);
        SQL := 'update pro_adi_personalizado_sabores set id_site = ' +
          codigo.ToString + ' where id = ' + DadosAdicionais.FieldByName
          ('id').AsString;
        Insert.ExecutaSQL(SQL);
      end;

      DadosAdicionais.Next;
    end;

    Dados.Next;
  end;

  Dados.Free;
  Insert.Free;
end;

procedure TfrmPrincipal.EnviaProduto;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;
  InsertSite: TInsertUpdateSite;
begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);
  SQL := 'SELECT p.codigo,p.codigo_interno, p.nome_produto as produto, p.descricao, p.valor_venda as venda, p.id_site, p.ativo,p.valor_embalagem_delivery as vl_embalagem_delivery, tipo_produto.id_site as categoria FROM produto as p ';
  SQL := SQL + ' join tipo_produto on tipo_produto.codigo = p.codigo_grupo ';
  SQL := SQL + ' where p.modificado_site = 0 and tipo_produto.id_site > 0 ';
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    Insert.Free;
    Dados.Free;
    exit;
  end;
  Dados.First;
  InsertSite := TInsertUpdateSite.Create;
  while not Dados.Eof do
  begin

    codigo := InsertSite.InserirUpdate('ws_itens', Usuario.ToString,
      ['id', 'user_id', 'img_item', 'config_total_s', 'dia_semana',
      'number_adicional', 'number_adicional_pago', 'posicao', 'id_cat',
      'nome_item', 'descricao_item', 'preco_item', 'disponivel',
      'valor_delivery'], [Dados.FieldByName('id_site').AsString,
      Usuario.ToString, 'false', '0',
      'Domingo,Segunda,Terça,Quarta,Quinta,Sexta,Sabado', '0', '0',
      Dados.FieldByName('codigo_interno').AsString,
      Dados.FieldByName('categoria').AsString, Dados.FieldByName('produto')
      .AsString, Dados.FieldByName('descricao').AsString,
      Dados.FieldByName('venda').AsString, Dados.FieldByName('ativo').AsString,
      Dados.FieldByName('vl_embalagem_delivery').AsString]);

    if codigo > 0 then
    begin
      SQL := 'update produto set modificado_site = 1 where codigo = ' +
        Dados.FieldByName('codigo').AsString;
      Insert.ExecutaSQL(SQL);
      SQL := 'update produto set id_site = ' + codigo.ToString +
        ' where codigo = ' + Dados.FieldByName('codigo').AsString;
      Insert.ExecutaSQL(SQL);
    end;

    Dados.Next;
  end;
  Dados.Free;
  Insert.Free;
end;

procedure TfrmPrincipal.EnviarSabores;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;

  InsertSite: TInsertUpdateSite;
begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);
  SQL := 'SELECT cs.id, cs.id_site, cs.nome, cs.vl_venda as valor, cs.ativo, ts.nome as tipo,p.id_site as id_itens,pp.quantidade_sabores as qtd_sabor, (SELECT tipo_preco_pizza FROM dados_whatsapp limit 1) as tipo_valor FROM sabores_completo as cs';
  SQL := SQL + ' join tipo_sabor as ts on ts.id = cs.id_tipo_sabor';
  SQL := SQL + ' join produto as p on p.codigo = cs.id_produto';
  SQL := SQL + ' join produto_pizza as pp on pp.codigo_produto = p.codigo';
  SQL := SQL + ' where cs.modificado_site = 0';
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    Insert.Free;
    Dados.Free;
    exit;
  end;
  Dados.First;
  InsertSite := TInsertUpdateSite.Create;
  while not Dados.Eof do
  begin
    if Dados.FieldByName('ativo').AsInteger = 1 then
    begin

      codigo := InsertSite.InserirUpdate('ws_sabores', Usuario.ToString,
        ['id', 'user_id', 'id_itens', 'qtd_sabor', 'ativo', 'tipo_valor',
        'valor', 'tipo', 'sabor'], [Dados.FieldByName('id_site').AsString,
        Usuario.ToString, Dados.FieldByName('id_itens').AsString,
        Dados.FieldByName('qtd_sabor').AsString, Dados.FieldByName('ativo')
        .AsString, Dados.FieldByName('tipo_valor').AsString,
        Dados.FieldByName('valor').AsString, Dados.FieldByName('tipo').AsString,
        Dados.FieldByName('nome').AsString]);
      if codigo > 0 then
      begin
        SQL := 'update sabores_completo set modificado_site = 1 where id = ' +
          Dados.FieldByName('id').AsString;
        Insert.ExecutaSQL(SQL);
        SQL := 'update sabores_completo set id_site = ' + codigo.ToString +
          ' where id = ' + Dados.FieldByName('id').AsString;
        Insert.ExecutaSQL(SQL);
        // SQL := 'update ws_itens set preco_item = 0 where id = '+Dados.FieldByName('id_site').AsString;

      end;
    end
    else
    begin
      if Dados.FieldByName('id_site').AsInteger > 0 then
        BuscaPedidoThread.ExecutaSQLSite('delete from ws_sabores where id = ' +
          Dados.FieldByName('id_site').AsString);
    end;
    BuscaPedidoThread.ExecutaSQLSite(SQL);
    Dados.Next;
  end;
  Dados.Free;
  Insert.Free;
end;

procedure TfrmPrincipal.EnviaTaxa;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;

  InsertSite: TInsertUpdateSite;
begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);
  SQL := 'SELECT * FROM taxa_entrega where modificado_site = 0';
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    Insert.Free;
    Dados.Free;
    exit;
  end;
  Dados.First;
  InsertSite := TInsertUpdateSite.Create;
  while not Dados.Eof do
  begin
    if Dados.FieldByName('ativo').AsInteger = 1 then
    begin
      codigo := InsertSite.InserirUpdate('bairros_delivery', Usuario.ToString,
        ['id', 'user_id', 'uf', 'cidade', 'bairro', 'taxa'],
        [Dados.FieldByName('id_site').AsString, Usuario.ToString,
        Dados.FieldByName('estado').AsString, Dados.FieldByName('cidade')
        .AsString, Dados.FieldByName('bairro').AsString,
        StringReplace(Dados.FieldByName('valor_taxa').AsString, ',', '.',
        [rfReplaceAll])]);
      if codigo > 0 then
      begin
        SQL := 'update taxa_entrega set modificado_site = 1 where codigo = ' +
          Dados.FieldByName('codigo').AsString;
        Insert.ExecutaSQL(SQL);
        SQL := 'update taxa_entrega set id_site = ' + codigo.ToString +
          ' where codigo = ' + Dados.FieldByName('codigo').AsString;
        Insert.ExecutaSQL(SQL);
      end;
    end
    else
    begin
      if Dados.FieldByName('id_site').AsInteger > 0 then
        BuscaPedidoThread.ExecutaSQLSite
          ('delete from bairros_delivery where id = ' +
          Dados.FieldByName('id_site').AsString);
    end;

    Dados.Next;
  end;
  Dados.Free;
  Insert.Free;
end;

procedure TfrmPrincipal.EnviaTipoPagamento;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;

  InsertSite: TInsertUpdateSite;
begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);
  SQL := 'SELECT * FROM tipo_pagamento where modificado_site = 0 and apenas_delivery = 1';
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    Insert.Free;
    Dados.Free;
    exit;
  end;

  Dados.First;
  InsertSite := TInsertUpdateSite.Create;
  while not Dados.Eof do
  begin
    if Dados.FieldByName('ativo').AsInteger > 0 then
    begin
      codigo := InsertSite.InserirUpdate('ws_formas_pagamento',
        Usuario.ToString, ['id_f_pagamento', 'user_id', 'f_pagamento'],
        [Dados.FieldByName('id_site').AsString, Usuario.ToString,
        Dados.FieldByName('descricao').AsString]);
      if codigo > 0 then
      begin
        SQL := 'update tipo_pagamento set modificado_site = 1 where codigo = ' +
          Dados.FieldByName('codigo').AsString;
        Insert.ExecutaSQL(SQL);
        SQL := 'update tipo_pagamento set id_site = ' + codigo.ToString +
          ' where codigo = ' + Dados.FieldByName('codigo').AsString;
        Insert.ExecutaSQL(SQL);
      end;
    end
    else
    begin
      if Dados.FieldByName('id_site').AsInteger > 0 then
        BuscaPedidoThread.ExecutaSQLSite
          ('delete from ws_formas_pagamento where id_f_pagamento = ' +
          Dados.FieldByName('id_site').AsString);
    end;

    Dados.Next;
  end;
  Dados.Free;
  Insert.Free;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin

  if Verifica('site.exe') = 1 then
  Begin
    { Seu Codigo }
  end
  else
  Begin
    Application.Terminate;
    exit;
  end;

  // Sleep(5000);
  lStatus.Caption := '';
  Caption := URL_SITE;
  memRequisicoes.Open;
  ConexaoSite := TConexaoSite.Create;
  ConexaoSite.Start;
  GetTempoEspera;
end;

function TfrmPrincipal.getClientID: String;
var
  ArquivoINI: TIniFile;
begin
  ArquivoINI := TIniFile.Create(ExtractFilePath(Application.ExeName) +
    'CONFIGURACAO\site.ini');
  Result := ArquivoINI.ReadString('integracao', 'client_id', '');
  ArquivoINI.Free;
  // Demo
  // Result := '826d45891e154d8e3ff269f99e533dc075d23af433e0cea4c0e45a56dba18b30';
end;

function TfrmPrincipal.getClientSecurity: String;
var
  ArquivoINI: TIniFile;
begin
  // Demo
  // Result := '1c1917a062221a94c4d4557e9b79e28e';

  ArquivoINI := TIniFile.Create(ExtractFilePath(Application.ExeName) +
    'CONFIGURACAO\site.ini');
  Result := ArquivoINI.ReadString('integracao', 'client_security', '');
  ArquivoINI.Free;

end;

function TfrmPrincipal.GetIdRequisicao: Integer;
begin
  inc(FIdRequisicao);
  Result := FIdRequisicao;
  lRequisicoes.Caption := 'Requisições: ' + IntToStr(Result) + ' - ' + SerialHD;
  if Homologacao then
    lRequisicoes.Caption := lRequisicoes.Caption + ' - [HOMOLOGAÇÃO]';
end;

function TfrmPrincipal.GetTempoEspera: Integer;
var
  ArquivoINI: TIniFile;
begin
  Homologacao := False;
  ArquivoINI := TIniFile.Create(ExtractFilePath(Application.ExeName) +
    'CONFIGURACAO\site.ini');
  Result := ArquivoINI.ReadInteger('integracao', 'tempo', 5);
  ArquivoINI.WriteInteger('integracao', 'tempo', Result);
  if Result = 0 then
    Homologacao := True;
  ArquivoINI.Free;
end;

procedure TfrmPrincipal.SetHomologacao(const Value: Boolean);
begin
  FHomologacao := Value;
end;

procedure TfrmPrincipal.SetIdRequisicao(const Value: Integer);
begin
  FIdRequisicao := Value;
end;

procedure TfrmPrincipal.SetNomeRestaurante(const Value: String);
begin
  FNomeRestaurante := Value;
end;

procedure TfrmPrincipal.SetStatusConexao(const Value: Boolean);
var
  Status: String;
begin
  FStatusConexao := Value;
  if Value then
  begin
    Status := 'Conectado com Sucesso ' + FormatDateTime('hh:mm', now);
    TrayIcon.Icons := imagemConectado;

    BuscaPedidoThread := TBuscaPedidos.Create;
    BuscaPedidoThread.Start;
  end
  else
  begin
    Status := 'Sem Conexão!';
    TrayIcon.Icons := imagemDesconectado;

    if Assigned(BuscaPedidoThread) then
      BuscaPedidoThread.Free;
  end;

  Self.Caption := URL_SITE + ' - ' + Status;
end;

procedure TfrmPrincipal.SetTempoEspera(const Value: Integer);
begin
  FTempoEspera := Value;
end;

procedure TfrmPrincipal.SetToken(const Value: String);
begin
  FToken := Value;
end;

procedure TfrmPrincipal.SetUsuario(const Value: Integer);
begin
  FUsuario := Value;
end;

function TfrmPrincipal.Verifica(ExeFileName: String): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32 { declarar Uses Tlhelp32 };
begin
  Result := 0;

  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile))
      = UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile)
      = UpperCase(ExeFileName))) then
    begin
      inc(Result);
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

{ TBuscaPedidos }

function TBuscaPedidos.BuscaItems(User, codigo: Integer): String;
var
  MemoryPedidoItem: TFDMemTable;

  // QryPedidoItemAdicionaisSabores: TFDQuery;
  memoryItemAdicionaisSabors: TFDMemTable;
  MemoryDados: TFDMemTable;
  ArrayAdicionais: Array of String;
  Adicional: String;
  Aux: String;
  I: Integer;
  K: Integer;
  J: Integer;
  TotalSabores: Integer;
  Resultado: String;
begin

  if codigo = 0 then
  begin
    Resultado := 'ERRO';
  end
  else
  begin

    FRequest.URLI := 'item/' + User.ToString + '/' + codigo.ToString + '/a';
    FRequest.Get;

    MemoryPedidoItem := TFDMemTable.Create(nil);
    MemoryPedidoItem.LoadFromJSON(FRequest.Retorno);

    MemoryDados := TFDMemTable.Create(nil);
    MemoryDados.FieldDefs.Add('id', ftInteger);
    MemoryDados.FieldDefs.Add('idproduto', ftInteger);
    MemoryDados.FieldDefs.Add('qtd', ftInteger);
    MemoryDados.FieldDefs.Add('valor', ftFloat);
    MemoryDados.FieldDefs.Add('categoria', ftString, 100);
    MemoryDados.FieldDefs.Add('adicional', ftString, 100);
    MemoryDados.FieldDefs.Add('valoradicional', ftFloat);
    MemoryDados.Open;
    while not MemoryPedidoItem.Eof do
    begin
      try
        FRequest.URLI := 'obs/' + MemoryPedidoItem.FieldByName('tabela')
          .AsString + '/a';
        FRequest.Get;
        MemoryPedidoItem.Edit;
        MemoryPedidoItem.FieldByName('obs').AsString := FRequest.Retorno;
        MemoryPedidoItem.Post;
      except

      end;

      SetLength(ArrayAdicionais, 0);
      Adicional := MemoryPedidoItem.FieldByName('adicionais').AsString;
      Aux := '';

      MemoryDados.Insert;
      MemoryDados.FieldByName('id').AsInteger := MemoryPedidoItem.FieldByName
        ('tabela').AsInteger;
      MemoryDados.FieldByName('idproduto').AsInteger :=
        MemoryPedidoItem.FieldByName('produto').AsInteger;
      MemoryDados.FieldByName('qtd').AsInteger :=
        MemoryPedidoItem.FieldByName('qtde').AsInteger;
      try
        MemoryDados.FieldByName('valor').AsString :=
          StringReplace(MemoryPedidoItem.FieldByName('valor').AsString, '.',
          ',', [rfReplaceAll]);
      except
        MemoryDados.FieldByName('valor').AsString := '0';
      end;

      if MemoryPedidoItem.FieldByName('obs').AsString = '' then
      begin
        MemoryDados.FieldByName('categoria').AsString := '';
        MemoryDados.FieldByName('adicional').AsString := '';
        MemoryDados.FieldByName('valoradicional').AsFloat := 0;
      end
      else
      begin
        MemoryDados.FieldByName('categoria').AsString := 'OBSERVAÇÃO';
        MemoryDados.FieldByName('adicional').AsString :=
          MemoryPedidoItem.FieldByName('obs').AsString;
        MemoryDados.FieldByName('valoradicional').AsFloat := 0;
      end;
      MemoryDados.Post;

      for I := 1 to length(Adicional) do
      begin
        if Adicional[I] = ',' then
        begin
          SetLength(ArrayAdicionais, length(ArrayAdicionais) + 1);
          ArrayAdicionais[length(ArrayAdicionais) - 1] := trim(Aux);
          Aux := '';
        end
        else
        begin
          Aux := Aux + Adicional[I];
        end;
      end;
      try
        for I := 0 to length(ArrayAdicionais) - 1 do
        begin
          memoryItemAdicionaisSabors := TFDMemTable.Create(nil);
          try
            FRequest.URLI := 'Itemcat/' + User.ToString + '/' + ArrayAdicionais
              [I] + '/' + MemoryPedidoItem.FieldByName('produto')
              .AsString + '/a';
            FRequest.Get;

            if FRequest.Retorno <> 'null' then
            begin
              memoryItemAdicionaisSabors.LoadFromJSON(FRequest.Retorno);
            end
            else
            begin
              FRequest.URLI := 'pizza/' + User.ToString + '/' + ArrayAdicionais
                [I] + '/' + MemoryPedidoItem.FieldByName('produto')
                .AsString + '/a';
              FRequest.Get;

              memoryItemAdicionaisSabors.LoadFromJSON(FRequest.Retorno);
            end;
          except
          end;
          while not memoryItemAdicionaisSabors.Eof do
          begin
            memoryItemAdicionaisSabors.Edit;
            TotalSabores := 1;
            if memoryItemAdicionaisSabors.FieldByName('idcat').AsInteger > 0
            then
            begin
              FRequest.URLI := 'catadicional/' +
                memoryItemAdicionaisSabors.FieldByName('idcat').AsString + '/a';
              FRequest.Get;
              memoryItemAdicionaisSabors.FieldByName('categoria').AsString :=
                trim(FRequest.Retorno);
            end
            else
            begin
              TotalSabores := QtdSabores(ArrayAdicionais[I]);
            end;

            if memoryItemAdicionaisSabors.FieldByName('idadc').AsInteger > 0
            then
            begin
              FRequest.URLI := 'adicional/' +
                memoryItemAdicionaisSabors.FieldByName('idadc').AsString + '/a';
              FRequest.Get;
              memoryItemAdicionaisSabors.FieldByName('nome').AsString :=
                trim(FRequest.Retorno);
            end;
            memoryItemAdicionaisSabors.Post;

            for J := 0 to TotalSabores - 1 do
            begin
              MemoryDados.Insert;
              MemoryDados.FieldByName('id').AsInteger :=
                MemoryPedidoItem.FieldByName('tabela').AsInteger;
              MemoryDados.FieldByName('idproduto').AsInteger :=
                MemoryPedidoItem.FieldByName('produto').AsInteger;
              MemoryDados.FieldByName('qtd').AsInteger :=
                MemoryPedidoItem.FieldByName('qtde').AsInteger;
              MemoryDados.FieldByName('valor').AsString :=
                StringReplace(MemoryPedidoItem.FieldByName('valor').AsString,
                '.', ',', [rfReplaceAll]);
              // MemoryPedidoItem.FieldByName('valor').AsFloat;
              try
                MemoryDados.FieldByName('valor').AsString :=
                  StringReplace(MemoryPedidoItem.FieldByName('valor').AsString,
                  '.', ',', [rfReplaceAll]);
              except
                MemoryDados.FieldByName('valor').AsString := '0';
              end;

              MemoryDados.FieldByName('categoria').AsString :=
                memoryItemAdicionaisSabors.FieldByName('categoria').AsString;
              MemoryDados.FieldByName('adicional').AsString :=
                memoryItemAdicionaisSabors.FieldByName('nome').AsString;
              // MemoryDados.FieldByName('valoradicional').AsFloat :=
              // memoryItemAdicionaisSabors.FieldByName('valor').AsFloat;

              try
                MemoryDados.FieldByName('valoradicional').AsString :=
                  StringReplace(memoryItemAdicionaisSabors.FieldByName('valor')
                  .AsString, '.', ',', [rfReplaceAll]);
              except
                MemoryDados.FieldByName('valoradicional').AsString := '0';
              end;

              MemoryDados.Post;
            end;
            memoryItemAdicionaisSabors.Next;
          end;
          if memoryItemAdicionaisSabors.RecordCount = 0 then
          begin
            MemoryDados.Insert;
            MemoryDados.FieldByName('id').AsInteger :=
              MemoryPedidoItem.FieldByName('tabela').AsInteger;
            MemoryDados.FieldByName('idproduto').AsInteger :=
              MemoryPedidoItem.FieldByName('produto').AsInteger;
            MemoryDados.FieldByName('qtd').AsInteger :=
              MemoryPedidoItem.FieldByName('qtde').AsInteger;
            try
              MemoryDados.FieldByName('valor').AsString :=
                StringReplace(MemoryPedidoItem.FieldByName('valor').AsString,
                '.', ',', [rfReplaceAll]);
            except
              MemoryDados.FieldByName('valor').AsString := '0';
            end;
            MemoryDados.FieldByName('categoria').AsString := 'Categoria';

            for K := 1 to length(ArrayAdicionais[I]) - 1 do
            begin
              if ArrayAdicionais[I] = '-' then
              begin

              end
              else
              begin
                MemoryDados.FieldByName('categoria').AsString :=
                  trim(MemoryDados.FieldByName('categoria').AsString +
                  ArrayAdicionais[I]);
                break
              end;
            end;

            ArrayAdicionais[I] := StringReplace(ArrayAdicionais[I],
              trim(MemoryDados.FieldByName('categoria').AsString) + ' -', '',
              [rfReplaceAll]);

            MemoryDados.FieldByName('adicional').AsString := ArrayAdicionais[I];
            MemoryDados.FieldByName('valoradicional').AsFloat := 0;
            MemoryDados.Post;
          end;

        end;

      except
        on E: Exception do
        begin
          Result := E.Message;
          exit;
        end;

      end;

      MemoryPedidoItem.Next;
    end;
  end;

  Result := MemoryDados.ToJSONArray().ToJSON;

end;

function TBuscaPedidos.Cliente(Nome, Telefone: String): Integer;
var
  Celular: String;
  CelularAntigo: String;
  Dados: TFDMemTable;

  Insert: TInsertUpdate;
  // Geral: TGeral;
begin
  // Geral := TGeral.Create;
  // Telefone := Geral.SoNumero(Telefone);
  // Geral.Free;

  // So numero Celular
  try
    Nome := UpperCase(StringReplace(Nome, '%20', ' ', [rfReplaceAll]));
    CelularAntigo := Copy(Telefone, 0, 2) + Copy(Telefone, 4, 8);
    Celular := Telefone;
    Insert := TInsertUpdate.Create;;

    Dados := TFDMemTable.Create(nil);

    Dados.LoadFromJSON
      (Insert.ConsultaSQL('select * from cliente where celular = ' +
      QuotedStr(Celular)));

    if Dados.RecordCount = 0 then
    begin

      Result := Insert.InserirUpdate('cliente',
        ['codigo', 'celular', 'celular_wpp', 'nome', 'ativo', 'bloqueado',
        'id_cliente_site'], ['0', Celular, CelularAntigo, Nome, '1', '0', '0']);

    end
    else
    begin
      Result := Dados.FieldByName('codigo').AsInteger;
      Insert.InserirUpdate('cliente', ['codigo', 'nome'],
        [Result.ToString, Nome]);
      // Dar update no nome
      // dmModulo.ExecutaSQL('update cliente set nome = ' + QuotedStr(Nome) +
      // ' where codigo = ' + QRY.FieldByName('codigo').AsString);
    end;

  except
    on E: Exception do
    begin
      Result := -1;
      // ShowMessage(E.Message);
    end;

  end;
  Dados.Free;
end;

function TBuscaPedidos.ClienteEndereco(CodigoCliente: Integer;
  Rua, Bairro, Cidade, Estado, Numero, Complemento: String): Integer;
var
  Insert: TInsertUpdate;
begin
  if Complemento = '*Não informado*' then
    Complemento := '';
  Insert := TInsertUpdate.Create;
  Insert.ExecutaSQL
    ('update cliente_endereco set ativo = 0 where codigo_cliente = ' +
    IntToStr(CodigoCliente));
  Result := Insert.InserirUpdate('cliente_endereco',
    ['codigo', 'codigo_cliente', 'descricao', 'numero', 'rua', 'bairro',
    'cidade', 'estado', 'cep', 'complemento', 'ativo', 'km'],
    ['0', CodigoCliente.ToString, 'site', Numero, Rua, Bairro, Cidade, Estado,
    ' ', Complemento, '0', '0']);
end;

function TBuscaPedidos.CodigoFormaPagamento(Forma: String): Integer;
var
  Insert: TInsertUpdate;
  Dados: TFDMemTable;
  SQL: String;
begin
  Dados := TFDMemTable.Create(nil);
  Insert := TInsertUpdate.Create;
  SQL := 'select * from tipo_pagamento where descricao = ' + QuotedStr(Forma);

  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount = 0 then
  begin
    // Insert
    Result := Insert.InserirUpdate('tipo_pagamento',
      ['codigo', 'descricao', 'ativo'], ['0', Forma, '1']);
  end
  else
  begin
    Result := Dados.FieldByName('codigo').AsInteger;
  end;

  Dados.Free;
  Insert.Free;
end;

function TBuscaPedidos.CodigoProduto(CodigoSite: Integer): Integer;
var
  Insert: TInsertUpdate;
  SQL: String;
  Dados: TFDMemTable;
  NomeProd: String;

begin
  Dados := TFDMemTable.Create(nil);
  Insert := TInsertUpdate.Create;

  SQL := 'select codigo, 0 as id from produto where id_site = ' +
    CodigoSite.ToString;
  Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

  if Dados.RecordCount > 0 then
  begin
    Result := Dados.FieldByName('codigo').AsInteger;
  end
  else
  begin
    FRequest.URLI := 'nomeprod/' + CodigoSite.ToString + '/a';
    FRequest.Get;
    NomeProd := FRequest.Retorno;
    SQL := 'select codigo, 0 as id from produto where nome_produto = ' +
      QuotedStr(NomeProd);

    try
      Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
    except
      Dados.Free;
      Insert.Free;
      exit;
    end;
    try
      Result := Dados.FieldByName('codigo').AsInteger;
    except

    end;
  end;

  Dados.Free;
  Insert.Free;

end;

function TBuscaPedidos.ConverteValor(Valor: String): Real;
begin
  try
    Result := StrToFloat(Valor);
  except
    Result := 0;
  end;
end;

constructor TBuscaPedidos.Create;
begin
  inherited Create(True);
  FRequest := TRequest.Create;
  FRequest.BASEURL := URL_SITE;
  Segundos := 60;
  FUserID := -1;

  MemoryTablePedidos := TFDMemTable.Create(nil);
  MemoryDadosItem := TFDMemTable.Create(nil);
  GetPedidos := True;
end;

destructor TBuscaPedidos.Destroy;
begin

  inherited;
end;

function TBuscaPedidos.ExecutaSQLSite(SQL: String): Boolean;
begin

  FRequest.URLI := 'sql/a/';
  FRequest.Body('{"sql":"' + SQL +
    '","clientId":"UwMyPVWhawPQ&K@AELqpNiRU$Sh%sZDlYgnb0YyTGU^rB7B&#nszh2tR&WNthWpuGv6@JAvV^bK","clientSecurity":"B7B&#nszh2W&K@AELqpNiRU$Sh"}');
  FRequest.Post;

  Result := FRequest.Status = 200;

end;

procedure TBuscaPedidos.Execute;
var
  BuscarPedido: Boolean;
begin
  inherited;
  while not Terminated do
  begin
    if UserID = -1 then
    begin
      frmPrincipal.lStatus.Caption := 'Crédencias API - Incorretas';
      BuscarPedido := False;
    end
    else
    begin
      // Colocar o nome da empresa logada
      frmPrincipal.lStatus.Caption := 'Conectado com Sucesso - ' +
        frmPrincipal.NomeRestaurante;
      if GetPedidos then
        BuscarPedido := True;
    end;

    if BuscarPedido then
    begin
      GetPedidos := False;
      FRequest.URLI := 'pedidos/' + UserID.ToString + '/a';
      FRequest.Get;

      case FRequest.Status of
        200:
          begin
            // Sucesso
            MemoryTablePedidos.Close;
            if FRequest.Retorno <> 'null' then
            begin
              try
                MemoryTablePedidos.LoadFromJSON(FRequest.Retorno);
              except
                on E: Exception do
                begin
                  // ShowMessage(E.Message);
                end;
              end;
            end;

          end;
        304:
          begin
            // Nada Mudou ou sem pedidos
            // try
            // MemoryTablePedidos.First;
            // except
            //
            // end;
          end
      else
        begin
          // Erro
          // Token := '';
          // Dados.ClearToken;
          // FUserID := -1;

        end;
      end;

      if MemoryTablePedidos.RecordCount > 0 then
      begin
        BuscarPedido := False;
        InserirPedidos;
      end;
      frmPrincipal.AtualizaSite;
    end;

    Sleep(Segundos * 1000);
  end;

end;

function TBuscaPedidos.GeraCodigoPorDiaPedido: Integer;
var

  Data: TDate;

  Insert: TInsertUpdate;
  Dados: TFDMemTable;
  SQL: String;

begin
  Insert := TInsertUpdate.Create;
  Dados := TFDMemTable.Create(nil);

  if time > StrToTime('04:59:59') then
  begin
    SQL := 'SELECT max(codigo_pedido_dia) as maior, 0 as id FROM pedido where status > -1 and data_pedido ='
      + QuotedStr(FormatDateTime('yyyy-mm-dd', date)) + ' and hora_pedido > ' +
      QuotedStr('05:00:00');
    try
      Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
    except
      Insert.Free;
      Result := 1;
      Dados.Free;
      exit;
    end;

  end
  else
  begin

    SQL := 'SELECT max(codigo_pedido_dia) as maior, 0 as id FROM pedido where status > -1 and data_pedido ='
      + QuotedStr(FormatDateTime('yyyy-mm-dd', date)) + ' and hora_pedido > ' +
      QuotedStr('00:00:00');
    try
      Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
    except
      Insert.Free;
      Result := 1;
      Dados.Free;
      exit;
    end;

    if Dados.RecordCount > 0 then
      Result := Dados.FieldByName('maior').AsInteger + 1;

    if Result > 1 then
    begin
      Insert.Free;;
      Dados.Free;
      exit;
    end;
    SQL := 'SELECT max(codigo_pedido_dia) as maior, 0 as id FROM pedido where status > 0 and data_pedido ='
      + QuotedStr(FormatDateTime('yyyy-mm-dd', date - 1)) +
      ' and hora_pedido > ' + QuotedStr('05:00:00');
    try
      Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
    except
      Insert.Free;
      Result := 1;
      Dados.Free;
      exit;
    end;

  end;
  try
    Result := Dados.FieldByName('maior').AsInteger + 1;
  except
    Result := 1;
  end;

  if Dados.RecordCount = 0 then
    Result := 1;

  Dados.Free;
  Insert.Free;

end;

function TBuscaPedidos.getUser: Integer;
var
  Body: String;
  X: ISuperObject;
begin
  if (FUserID = 0) or (FUserID < 0) then
  begin
    Body := '{' + #13 + '"client_id":"' + frmPrincipal.ClientID + '",' + #13 +
      '"client_security":"' + frmPrincipal.ClientSecurity + '"' + #13 + '}';
    FRequest.URLI := 'token2/a';
    FRequest.Body(Body);
    FRequest.Post;
    X := TSuperObject.Create(FRequest.Retorno);

    if FRequest.Status = 200 then
    begin
      try
        FUserID := X['user'].AsInteger;
        frmPrincipal.NomeRestaurante := X['nome'].AsString;
        frmPrincipal.Token := X['token'].AsString;
      except
        FUserID := -1;
      end;
      if FUserID = 0 then
        FUserID := -1;
    end
    else
    begin
      FUserID := -1;
      // Clientid Errado
    end;
  end;
  Result := FUserID;
  frmPrincipal.Usuario := FUserID;

end;

procedure TBuscaPedidos.InserirPedidos;
var
  Insert: TInsertUpdate;
  StatusPedido: Integer;
  Resultado: String;
  CodigoCliente: Integer;
  Endereco: Integer;
  CodigoNovoPeiddo: Integer;
  Dados: TFDMemTable;
  SQL: String;
  CodigoPedidoItem: Integer;
  CodigoPedidoDia: Integer;
  Messa: Boolean;
  Novo: Boolean;
  DadosConsulta: TFDMemTable;
  SAP: Boolean;

begin
  Insert := TInsertUpdate.Create;
  case TipoPedido of
    0:
      begin
        // Aguardar
        StatusPedido := 9;
      end;
    1:
      begin
        // Aceitar
        StatusPedido := 1;
      end;
    2:
      begin
        // Cancelar
        StatusPedido := 0;
      end;
  end;
  try
    if MemoryTablePedidos.RecordCount > 0 then
    begin

      MemoryTablePedidos.First;
      while not MemoryTablePedidos.Eof do
      begin
        SAP := False;
        Resultado := BuscaItems(UserID, MemoryTablePedidos.FieldByName('id')
          .AsInteger);
        MemoryDadosItem.Close;
        MemoryDadosItem.LoadFromJSON(Resultado);
        CodigoCliente := -1;

        FRequest.URLI := 'rua/' + MemoryTablePedidos.FieldByName('id')
          .AsString + '/a';
        FRequest.Get;
        MemoryTablePedidos.Edit;
        MemoryTablePedidos.FieldByName('rua').AsString := FRequest.Retorno;
        MemoryTablePedidos.Post;

        while CodigoCliente = -1 do
        begin
          try
            Messa := False;
            if MemoryTablePedidos.FieldByName('idmesa').AsInteger > 0 then
            begin
              CodigoCliente := Cliente(MemoryTablePedidos.FieldByName('desmesa')
                .AsString + '%20' + MemoryTablePedidos.FieldByName('idmesa')
                .AsString, MemoryTablePedidos.FieldByName('idmesa').AsString);
              Messa := True;
            end
            else
            begin
              if MemoryTablePedidos.FieldByName('nome').AsString <> '' then
              begin
                CodigoCliente := Cliente(MemoryTablePedidos.FieldByName('nome')
                  .AsString, MemoryTablePedidos.FieldByName('telefone')
                  .AsString);
              end
              else
              begin
                CodigoCliente := Cliente('ERRO NO PEDIDO', '0404');
              end;

            end;

          except
            CodigoCliente := Cliente(MemoryTablePedidos.FieldByName('nome')
              .AsString, MemoryTablePedidos.FieldByName('telefone').AsString);
          end;
        end;
        Endereco := 0;
        if MemoryTablePedidos.FieldByName('rua').AsString <> '' then
        begin
          while Endereco = 0 do
          begin
            Endereco := ClienteEndereco(CodigoCliente,
              MemoryTablePedidos.FieldByName('rua').AsString,
              MemoryTablePedidos.FieldByName('bairro').AsString,
              MemoryTablePedidos.FieldByName('cidade').AsString,
              MemoryTablePedidos.FieldByName('uf').AsString,
              MemoryTablePedidos.FieldByName('unidade').AsString,
              MemoryTablePedidos.FieldByName('complemento').AsString);
          end;
        end;
        if ValorValido(CodigoCliente) and ValorValido(Endereco) then
        begin
          CodigoPedidoDia := GeraCodigoPorDiaPedido;
          if Messa then
          begin
            // Se for mesa verificar se tem mesa em aberto
            SQL := 'SELECT * FROM pedido where codigo_cliente = ' +
              CodigoCliente.ToString + ' and data_pedido = ' +
              QuotedStr(FormatDateTime('yyyy-mm-dd', now)) +
              ' and status in (9,0,1)';
            Dados := TFDMemTable.Create(nil);
            Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

            Novo := True;

            if Dados.RecordCount > 0 then
            begin
              CodigoNovoPeiddo := Dados.FieldByName('codigo').AsInteger;
              Novo := False;
            end;
            Dados.Free;
          end
          else
          begin
            Novo := True;
          end;

          if Novo then
          begin
            if not Assigned(DadosConsulta) then
              DadosConsulta := TFDMemTable.Create(nil);
            DadosConsulta.Close;
            SQL := 'select * from pedido where id_pedido_site = ' +
              MemoryTablePedidos.FieldByName('id').AsString;
            DadosConsulta.LoadFromJSON(Insert.ConsultaSQL(SQL));

            if DadosConsulta.RecordCount = 0 then
            begin
              if MemoryDadosItem.RecordCount > 0 then
              begin
                MemoryTablePedidos.Edit;

                FRequest.URLI := 'pag/' + MemoryTablePedidos.FieldByName('id')
                  .AsString + '/a';
                FRequest.Get;
                try
                  MemoryTablePedidos.FieldByName('forma_pagamento').AsString :=
                    FRequest.Retorno;
                except
                  MemoryTablePedidos.FieldByName('forma_pagamento').AsString
                    := 'Outros';
                end;

                FRequest.URLI := 'comp/' + MemoryTablePedidos.FieldByName('id')
                  .AsString + '/a';
                FRequest.Get;
                MemoryTablePedidos.FieldByName('complemento').AsString :=
                  FRequest.Retorno;

                MemoryTablePedidos.Post;
              end;

              CodigoNovoPeiddo := Insert.InserirUpdate('pedido',
                ['codigo', 'codigo_pedido_dia', 'codigo_cliente',
                'codigo_cliente_endereco', 'data_pedido', 'hora_pedido',
                'status', 'valor_pedido', 'valor_desconto',
                'valor_taxa_entrega', 'valor_total_pedido', 'troco',
                'impresso_site', 'pedido_impresso', 'origem', 'id_pedido_site',
                'tipo_pagamento'], ['0', CodigoPedidoDia.ToString,
                CodigoCliente.ToString, Endereco.ToString,
                FormatDateTime('yyyy-mm-dd', date), TimeToStr(time),
                StatusPedido.ToString, MemoryTablePedidos.FieldByName('sub')
                .AsString, MemoryTablePedidos.FieldByName('desconto').AsString,
                MemoryTablePedidos.FieldByName('taxa').AsString,
                MemoryTablePedidos.FieldByName('total').AsString,
                MemoryTablePedidos.FieldByName('troco').AsString, '0', '1', '2',
                MemoryTablePedidos.FieldByName('id').AsString,
                CodigoFormaPagamento(MemoryTablePedidos.FieldByName
                ('forma_pagamento').AsString).ToString]);

              Insert.InserirUpdate('impressao_pedido',
                ['id', 'data_solicitacao', 'hora_solicitacao', 'id_pedido',
                'status', 'vias'], ['0', FormatDateTime('yyyy-mm-dd',date), FormatDateTime('hh:mm:ss',time), CodigoNovoPeiddo.ToString,
                '0', '0']);

            end
            else
            begin
              CodigoNovoPeiddo := DadosConsulta.FieldByName('codigo').AsInteger;
              Novo := False;
            end;
          end;
        end;

        MemoryTablePedidos.First;

        while not MemoryDadosItem.Eof do
        begin
          // Consultar
          SAP := False;
          if Assigned(Dados) then
            Dados.Close;
          SQL := 'select * from pedido_produtos where id_site = ' +
            MemoryDadosItem.FieldByName('id').AsString + ' and codigo_pedido = '
            + CodigoNovoPeiddo.ToString;
          Dados := TFDMemTable.Create(nil);
          Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

          if Dados.RecordCount = 0 then
          begin
            // Insert
            CodigoPedidoItem := Insert.InserirUpdate('pedido_produtos',
              ['codigo', 'codigo_pedido', 'codigo_produto', 'id_site',
              'valor_unitario', 'quantidade', 'valor_total', 'impresso'],
              ['0', CodigoNovoPeiddo.ToString,
              CodigoProduto(MemoryDadosItem.FieldByName('idproduto').AsInteger)
              .ToString, MemoryDadosItem.FieldByName('id').AsString,
              (ConverteValor(MemoryDadosItem.FieldByName('valor').AsString) /
              MemoryDadosItem.FieldByName('qtd').AsFloat).ToString,
              MemoryDadosItem.FieldByName('qtd').AsString,
              MemoryDadosItem.FieldByName('valor').AsString, '0']);

            if not Novo then
            begin
              SQL := 'update pedido set valor_pedido = valor_pedido + ' +
                StringReplace(MemoryDadosItem.FieldByName('valor').AsString,
                ',', '.', [rfReplaceAll]) + ' where codigo = ' +
                CodigoNovoPeiddo.ToString;
              Insert.ExecutaSQL(SQL);

              SQL := 'update pedido set valor_total_pedido = valor_total_pedido + '
                + StringReplace(MemoryDadosItem.FieldByName('valor').AsString,
                ',', '.', [rfReplaceAll]) + ' where codigo = ' +
                CodigoNovoPeiddo.ToString;
              Insert.ExecutaSQL(SQL);
            end;
          end
          else
          begin
            CodigoPedidoItem := Dados.FieldByName('codigo').AsInteger;
          end;

          if Assigned(Dados) then
            Dados.Close
          else
            Dados := TFDMemTable.Create(nil);

          SQL := 'select * from pedido_produto_sap where ';
          SQL := SQL + 'codigo_pedido_produto = ' + CodigoPedidoItem.ToString
            + ' and ';
          SQL := SQL + 'nomeclatura = ' +
            QuotedStr(MemoryDadosItem.FieldByName('categoria').AsString)
            + ' and ';
          SQL := SQL + 'descricao = ' +
            QuotedStr(MemoryDadosItem.FieldByName('adicional').AsString)
            + ' and ';
          SQL := SQL + 'valor = ' + StringReplace
            (trim(MemoryDadosItem.FieldByName('valoradicional').AsString),
            ',', '.', []);
          SQL := SQL + '';

          Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));

          if Dados.RecordCount = 0 then
          begin
            Insert.InserirUpdate('pedido_produto_sap',
              ['id', 'codigo_pedido_produto', 'tipo', 'nomeclatura',
              'descricao', 'valor'], ['0', CodigoPedidoItem.ToString, '1',
              MemoryDadosItem.FieldByName('categoria').AsString,
              MemoryDadosItem.FieldByName('adicional').AsString,
              (MemoryDadosItem.FieldByName('valoradicional').AsString)]);
            SAP := True;
          end
          else
          begin
            SAP := True;
          end;
          Dados.Close;
          SQL := 'select * from pedido_produto_sap where ';
          SQL := SQL + 'codigo_pedido_produto = ' + CodigoPedidoItem.ToString;
          Dados.LoadFromJSON(Insert.ConsultaSQL(SQL));
          if Dados.RecordCount = 0 then
          begin
            Insert.InserirUpdate('pedido_produto_sap',
              ['id', 'codigo_pedido_produto', 'tipo', 'nomeclatura',
              'descricao', 'valor'], ['0', CodigoPedidoItem.ToString, '1', '',
              '', '0']);
          end;

          MemoryDadosItem.Next;
        end;
        if not frmPrincipal.Homologacao then
        begin
          ExecutaSQLSite('update ws_pedidos set id_sistema = ' +
            CodigoNovoPeiddo.ToString + ' where id = ' +
            MemoryTablePedidos.FieldByName('id').AsString);
          ExecutaSQLSite('update ws_pedidos set view = 1 where id = ' +
            MemoryTablePedidos.FieldByName('id').AsString);

          ExecutaSQLSite('update ws_pedidos set status = ' +
            QuotedStr('Finalizado') + ' where id_sistema > 0 and user_id = ' +
            UserID.ToString);
          ExecutaSQLSite('update ws_pedidos set codigo_pedido = ' +
            QuotedStr(FormatFloat('00000', CodigoPedidoDia)) + ' where id = ' +
            MemoryTablePedidos.FieldByName('id').AsString);
        end;

        case StatusPedido of
          0:
            begin
              if Novo then
              begin
                Insert.InserirUpdate('pedido', ['codigo', 'pedido_impresso',
                  'impresso_site'], [CodigoNovoPeiddo.ToString, '0',
                  StatusPedido.ToString]);
              end;
              // Insert.InserirUpdate('pedido', ['codigo', 'view',
              // 'impresso_site'], [CodigoNovoPeiddo.ToString, '1',
              // StatusPedido.ToString]);
            end;
          9:
            begin

            end;
          1:
            begin
              if Novo then
              begin
                Insert.InserirUpdate('pedido', ['codigo', 'pedido_impresso',
                  'impresso_site'], [CodigoNovoPeiddo.ToString, '0',
                  StatusPedido.ToString]);
              end;
            end;
        end;

        MemoryTablePedidos.Next;
      end;
    end;
  except
    on E: Exception do
    begin

      // ShowMessage(FRequest.BASEURL+FRequest.URLI+#13+E.Message);
    end;

  end;
  GetPedidos := True;
  Insert.Free;
end;

function TBuscaPedidos.QtdSabores(Valor: String): Integer;
var
  I: Integer;

begin
  Result := 0;
  for I := 1 to length(Valor) do
  begin
    if Valor[I] = '/' then
    begin
      try
        Valor := Copy(Valor, I - 1, 1);
        Result := StrToInt(Valor);
      except
        Result := 0;
      end;
    end;
  end;
end;

function TBuscaPedidos.TipoPedido: Integer;
var
  ArquivoINI: TIniFile;
begin
  ArquivoINI := TIniFile.Create(ExtractFilePath(Application.ExeName) +
    'CONFIGURACAO\site.ini');
  Result := ArquivoINI.ReadInteger('integracao', 'cNovosPedidos', 0);
  ArquivoINI.Free;
end;

function TBuscaPedidos.ValorValido(Valor: Integer): Boolean;
begin
  Result := False;
  if Valor > 0 then
  begin
    Result := True;
  end
  else if Valor = 0 then
  begin
    Result := True;
  end;
end;

{ TInsertUpdateSite }

function TInsertUpdateSite.InserirUpdate(Tabela, User: String;
  ArrayCampos, ArrayValores: array of String): Integer;
var
  qry: TFDquery;
  Inserir: Boolean;

  Campos: String;
  Parametros: String;
  I: Integer;

  SQL: String;

  Montado: String;
  requisicao: TRequest;
begin

  requisicao := TRequest.Create;
  requisicao.BASEURL := URL_SITE;

  requisicao.URLI := 'insert/' + Tabela + '/' + User + '/a';

  Montado := '';

  for I := 0 to length(ArrayCampos) - 1 do
  begin
    if I = 0 then
    begin
      Montado := '"' + ArrayCampos[I] + '":"' + ArrayValores[I] + '"';
    end
    else
    begin
      Montado := Montado + ',"' + ArrayCampos[I] + '":"' + ArrayValores
        [I] + '"';
    end;
  end;
  Montado := '{' + Montado + '}';

  requisicao.Body(Montado);
  requisicao.Post;

  try
    Result := StrToInt(requisicao.Retorno);
  except
    Result := 0;

  end;
  requisicao.Free;
end;

end.
