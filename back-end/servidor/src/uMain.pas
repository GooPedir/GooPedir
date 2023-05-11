unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, uSQL,
  Winapi.TlHelp32, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, conexao, Vcl.Menus,
  FMX.Printer, uRequisicao, ADRIFood.Model.Interfaces, ADRIFood.Model.Types,
  ADRIFood.Component.Events, ADRIFood.Component, FireDAC.Stan.StorageBin;

type
  TAbrirServicos = class(TThread)
  protected
    procedure Execute; override;

  var
    conexao: Tconexao;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TfrmServidor = class(TForm)
    TrayIcon1: TTrayIcon;
    tMinimiza: TTimer;
    memoHistorico: TMemo;
    memoImagem: TMemo;
    Configuracoes: TFDMemTable;
    PopupMenu1: TPopupMenu;
    Fechar1: TMenuItem;
    memImpressora: TFDMemTable;
    memImpressoraID: TIntegerField;
    memImpressoraDRIVER: TStringField;
    memEstoque: TFDMemTable;
    memEstoqueID: TIntegerField;
    memEstoqueTIPO: TIntegerField;
    memEstoqueNOME: TStringField;
    memEstoqueUN: TStringField;
    memEstoqueENTRADA: TFloatField;
    memEstoqueSEQUENCIAL: TIntegerField;
    memEstoqueQTD: TCurrencyField;
    memTesteImpressao: TFDMemTable;
    memTesteImpressaoIMPRESSORA: TIntegerField;
    memTesteImpressaoID: TIntegerField;
    dataSetPolling: TFDMemTable;
    dsPolling: TDataSource;
    dataSetOrders: TFDMemTable;
    dataSetOrderItems: TFDMemTable;
    dsOrderItems: TDataSource;
    dsOrders: TDataSource;
    dataSetOrderBenefits: TFDMemTable;
    dataSetOrderSubItems: TFDMemTable;
    dsOrderSubItems: TDataSource;
    dsOrderBenefits: TDataSource;
    dsOrderPayments: TDataSource;
    dataSetOrderPayments: TFDMemTable;
    dataSetCategoy: TFDMemTable;
    memItens: TFDMemTable;
    memCategoriaExtra: TFDMemTable;
    memItensPreco: TFDMemTable;
    procedure tMinimizaTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Fechar1Click(Sender: TObject);
    // procedure iFoodPollingEnd(EndPooling: TDateTime;OrdersHead: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelOrderHead>);
  private
    { Private declarations }
    procedure TemAtualizacao;
    procedure SemAtualizacao;
    procedure IniciarAtualizacao;
    procedure FimAtualizacao;
    procedure Executaveis;
    function ConverteValoriFood(Valor: String): Real;

    procedure BuscaDadosiFood;

  public
    { Public declarations }
    Function VerificaExe(Nome: String): Boolean;
    procedure AbrirExe(Nome: String);
    procedure FecharExe(ExeFileName: String);
    function IMPRESSAO: String;
    function WHATSAPP: String;
    function SITE: String;
    procedure LoadImpressora;
    procedure FichaTecnica;
    function PathExe: String;

    function IntegracaoiFood: Boolean;
    function IDiFood: String;
    function TaxaiFood: Real;
    function StatusPedidoiFood: Integer;
    procedure AtualizaDadosiFood;

  var
    FechouWhatsapp: Boolean;
    FechouSite: Boolean;

  end;

var
  frmServidor: TfrmServidor;
  Atualizacao: TSQL;
  Servicos: TAbrirServicos;

implementation

{$R *.dfm}

uses Data.FireDACJSONReflect, DataSet.Serialize.Config,
  DataSet.Serialize.Consts, DataSet.Serialize.Export, DataSet.Serialize.Import,
  DataSet.Serialize.Language, DataSet.Serialize,
  DataSet.Serialize.UpdatedStatus, DataSet.Serialize.Utils,
  Horse.BasicAuthentication, Horse.Commons, Horse.Constants,
  Horse.Core.Group.Contract, Horse.Core.Group, Horse.Core,
  Horse.Core.Route.Contract, Horse.Core.Route, Horse.Core.RouterTree,
  Horse.Etag, Horse.Exception, Horse.HTTP, Horse.Jhonson, Horse.JWT,
  Horse.OctetStream, Horse.Paginate, Horse, Horse.Proc, Horse.Provider.Abstract,
  Horse.Provider.Apache, Horse.Provider.CGI, Horse.Provider.Console,
  Horse.Provider.Daemon, Horse.Provider.FPC.Apache, Horse.Provider.FPC.CGI,
  Horse.Provider.FPC.Daemon, Horse.Provider.FPC.FastCGI,
  Horse.Provider.FPC.HTTPApplication, Horse.Provider.ISAPI, Horse.Provider.Vcl,
  Horse.WebModule, JOSE.Builder, JOSE.Consumer, JOSE.Consumer.Validators,
  JOSE.Context, JOSE.Core.Base, JOSE.Core.Builder, JOSE.Core.JWA.Compression,
  JOSE.Core.JWA.Encryption, JOSE.Core.JWA.Factory, JOSE.Core.JWA,
  JOSE.Core.JWA.Signing, JOSE.Core.JWE, JOSE.Core.JWK, JOSE.Core.JWS,
  JOSE.Core.JWT, JOSE.Core.Parts, JOSE.Encoding.Base64, JOSE.Hashing.HMAC,
  JOSE.OpenSSL.Headers, JOSE.Signing.Base, JOSE.Signing.ECDSA, JOSE.Signing.RSA,
  JOSE.Types.Arrays, JOSE.Types.Bytes, JOSE.Types.JSON, JOSE.Types.Utils,
  RESTRequest4D, RESTRequest4D.Request.Client, RESTRequest4D.Request.Contract,
  RESTRequest4D.Response.Client, RESTRequest4D.Response.Contract,
  RESTRequest4D.Response.Indy, RESTRequest4D.Response.NetHTTP,
  RESTRequest4D.Utils, ThirdParty.Posix.Syslog, token.autorizacao, token, uDM,
  util.backup, util, Web.WebConst, Winapi.ShellAPI;

procedure TfrmServidor.AbrirExe(Nome: String);
begin
  if length(trim(Nome)) = 0 then
    exit;

  ShellExecute(handle, 'open', PChar(Nome), '', '', SW_SHOWNORMAL);
end;
{
  procedure TfrmServidor.iFoodPollingEnd(EndPooling: TDateTime;
  OrdersHead: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelOrderHead>);
  var
  conexao: Tconexao;
  DadosPedido: TFDMemTable;
  CodigoIntermo: Integer;
  CodigoPedidoDia: Integer;
  CodigoCliente: Integer;
  CodigoEndereco: Integer;
  DadosCli: TFDMemTable;
  CodigoProduto: Integer;
  Codigo: Integer;
  CodigoItem: Integer;
  I: Integer;
  begin
  iFood.Polling.AutoPolling := False;
  conexao := Tconexao.Create;
  DadosPedido := TFDMemTable.Create(nil);
  DadosCli := TFDMemTable.Create(nil);
  if dataSetPolling.RecordCount > 0 then
  begin
  dataSetPolling.First;
  while not dataSetPolling.Eof do
  begin
  DadosPedido.Close;
  iFood.Order.GetOrder(dataSetPolling.FieldByName('orderId').AsString,
  dataSetOrders, dataSetOrderItems, dataSetOrderPayments,
  dataSetOrderSubItems, dataSetOrderBenefits);

  conexao.SQL.Add('select * from pedido where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', dataSetPolling.FieldByName('orderId')
  .AsString);
  DadosPedido.LoadFromJSON(conexao.ConsultaSQL);
  if DadosPedido.RecordCount = 0 then
  begin
  CodigoIntermo := conexao.GerarID('pedido', 'codigo');
  conexao.SQL.Add
  ('SELECT max(codigo_pedido_dia)+1 as max, 0 as zero FROM pedido where data_pedido = curdate()');
  try
  CodigoPedidoDia := conexao.FieldByName('max');
  except
  CodigoPedidoDia := 1;
  end;
  DadosCli.Close;
  conexao.SQL.Add('select * from cliente where cpf = :cpf');
  conexao.Parametros('cpf',
  dataSetOrders.FieldByName('customerDocumentNumber').AsString);

  DadosCli.LoadFromJSON(conexao.ConsultaSQL);
  if DadosCli.RecordCount = 0 then
  begin
  CodigoCliente := conexao.GerarID('cliente', 'codigo');;
  conexao.SQL.Add('insert into cliente (codigo,nome,ativo,cpf,origem,bloqueado) values (:codigo,:nome,1,:cpf,''ifood'',0)');
  conexao.Parametros('codigo', CodigoCliente);
  conexao.Parametros('cpf',
  dataSetOrders.FieldByName('customerDocumentNumber').AsString);
  conexao.Parametros('nome',
  UpperCase(dataSetOrders.FieldByName('customerName').AsString));
  conexao.ExecuteSQL;

  end
  else
  begin
  CodigoCliente := DadosCli.FieldByName('codigo').AsInteger;
  end;
  CodigoEndereco := 0;

  //caso for delivery
      Dados.FieldByName('endereco').AsInteger :=  conexao.GerarID('cliente_endereco', 'codigo');
      conexao.SQL.Add('insert into cliente_endereco (codigo,codigo_cliente,descricao,tipo,numero,rua,bairro,cidade,estado,complemento,ativo,km) values');
      conexao.SQL.Add('(:codigo,:codigo_cliente,:descricao,:tipo,:numero,:rua,:bairro,:cidade,:estado,:complemento,1,0)');
      conexao.Parametros('codigo', Dados.FieldByName('endereco').AsInteger);
      conexao.Parametros('codigo_cliente', Dados.FieldByName('cliente').AsString);
      conexao.Parametros('descricao', 'Principal');
      conexao.Parametros('tipo', 1);
      conexao.Parametros('rua', Dados.FieldByName('rua').AsString);
      conexao.Parametros('bairro', Dados.FieldByName('bairro').AsString);
      conexao.Parametros('cidade', Dados.FieldByName('cidade').AsString);
      conexao.Parametros('estado', Dados.FieldByName('estado').AsString);
      conexao.Parametros('complemento', Dados.FieldByName('complemento').AsString);
      conexao.Parametros('numero', Dados.FieldByName('numero').AsString);
      conexao.Parametros('codigo', Dados.FieldByName('endereco').AsString);
      conexao.ExecuteSQL;



  conexao.SQL.Add
  ('insert into pedido (codigo,codigo_pedido_dia,codigo_cliente,codigo_cliente_endereco,data_pedido,hora_pedido,status,valor_pedido,valor_desconto,valor_taxa_entrega,valor_total_pedido,troco,tipo_pagamento,id_ifood,origem)');
  conexao.SQL.Add
  ('values (:codigo,:codigo_pedido_dia,:codigo_cliente,:codigo_cliente_endereco,:data_pedido,:hora_pedido,:status,:valor_pedido,:valor_desconto,:valor_taxa_entrega,:valor_total_pedido,:troco,:tipo_pagamento,:id_ifood,4)');
  conexao.Parametros('codigo', CodigoIntermo);
  conexao.Parametros('codigo_pedido_dia', CodigoPedidoDia);
  conexao.Parametros('codigo_cliente', CodigoCliente);
  conexao.Parametros('codigo_cliente_endereco', CodigoEndereco);
  conexao.Parametros('data_pedido', dataSetOrders.FieldByName('createdAt')
  .AsDateTime);
  conexao.Parametros('hora_pedido', dataSetOrders.FieldByName('createdAt')
  .AsDateTime);
  conexao.Parametros('status', 0);
  conexao.Parametros('valor_pedido',
  (dataSetOrders.FieldByName('subTotal').AsFloat));
  conexao.Parametros('valor_taxa_entrega',
  (dataSetOrders.FieldByName('deliveryFee').AsFloat));
  conexao.Parametros('valor_desconto',
  (dataSetOrders.FieldByName('totalBenefits').AsFloat));
  conexao.Parametros('valor_total_pedido',
  (dataSetOrders.FieldByName('totalPrice').AsFloat));
  conexao.Parametros('troco', 0);
  conexao.Parametros('tipo_pagamento', 0);
  conexao.Parametros('id_ifood', dataSetPolling.FieldByName('orderId')
  .AsString);

  conexao.ExecuteSQL;

  dataSetOrderItems.First;
  while not dataSetOrderItems.Eof do
  begin
  conexao.SQL.Add('select * from produto where id_ifood = :ifood');
  conexao.Parametros('ifood', dataSetOrderItems.FieldByName('id')
  .AsString);
  try
  CodigoProduto := conexao.FieldByName('codigo');
  except
  CodigoProduto := 0;
  end;
  Codigo := conexao.GerarID('pedido_produtos', 'codigo_pedido');
  conexao.SQL.Add
  ('insert into pedido_produtos (codigo,codigo_produto,codigo_pedido,valor_unitario,valor_total,quantidade,observacao,valor_adicional)');
  conexao.SQL.Add
  ('values (:codigo,:codigo_produto,:codigo_pedido,:valor_unitario,:valor_total,:quantidade,:observacao,:valor_adicional)');
  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('codigo_pedido', CodigoIntermo);
  conexao.Parametros('codigo_produto', CodigoProduto);
  conexao.Parametros('valor_unitario',
  dataSetOrderItems.FieldByName('unitPrice').AsFloat);
  conexao.Parametros('valor_total',
  dataSetOrderItems.FieldByName('totalPrice').AsFloat);
  conexao.Parametros('quantidade',
  dataSetOrderItems.FieldByName('quantity').AsInteger);

  conexao.Parametros('observacao',
  UpperCase(RemoveAcento(dataSetOrderItems.FieldByName('observations')
  .AsString)));
  conexao.Parametros('valor_adicional',
  dataSetOrderItems.FieldByName('addition').AsFloat);
  conexao.ExecuteSQL;
  CodigoItem := Codigo;
  Codigo := conexao.GerarID('pedido_produto_sap', 'id');
  conexao.SQL.Add
  ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor)');
  conexao.SQL.Add
  ('values (:id,:codigo_pedido_produto,1,:nomeclatura,:descricao,:valor)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('codigo_pedido_produto', CodigoItem);
  conexao.Parametros('nomeclatura', 'OBSERVAÇÃO');
  conexao.Parametros('descricao',
  UpperCase(RemoveAcento(dataSetOrderItems.FieldByName('observations')
  .AsString)));
  conexao.Parametros('valor', 0);
  conexao.ExecuteSQL;

  while not dataSetOrderItems.Eof do
  begin
  // Aki devo pegar o pro_adi_personalizado_sabores

  for I := 1 to dataSetOrderItems.FieldByName('quantity').AsInteger do
  begin
  Codigo := conexao.GerarID('pedido_produto_sap', 'id');
  conexao.SQL.Add
  ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor)');
  conexao.SQL.Add
  ('values (:id,:codigo_pedido_produto,1,:nomeclatura,:descricao,:valor)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('codigo_pedido_produto', CodigoItem);
  conexao.Parametros('nomeclatura', 'IFOOD');
  conexao.Parametros('descricao',
  UpperCase(RemoveAcento(dataSetOrderItems.FieldByName('name')
  .AsString)));
  conexao.Parametros('valor',
  dataSetOrderItems.FieldByName('unitPrice').AsFloat);
  conexao.ExecuteSQL;
  end;

  dataSetOrderItems.Next;
  end;

  dataSetOrderItems.Next;
  end;


  //Validar qual o status
  case StatusPedidoiFood of
    1: begin
      //Aceitar o Pedido
        conexao.SQL.Add('update pedido set status = 1 where id_ifood = :id_ifood');
        conexao.Parametros('id_ifood', dataSetPolling.FieldByName('orderId').AsString);
        conexao.ExecuteSQL;
        Codigo := conexao.GerarID('impressao_pedido', 'id');
        conexao.SQL.Add('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
        conexao.Parametros('id', CodigoCliente);
        conexao.Parametros('pedido', CodigoIntermo);
        conexao.ExecuteSQL;
    end;
    2:begin
      //Cancelar o Pedido
    end;
  end;


  end
  else
  begin
  CodigoIntermo := DadosPedido.FieldByName('codigo').AsInteger;
  end;
  conexao.SQL.Add('update pedido set status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', dataSetPolling.FieldByName('orderId').AsString);
  conexao.Parametros('status_ifood', dataSetPolling.FieldByName('code').AsString);
  conexao.Parametros('status_ifood_descricao',dataSetPolling.FieldByName('Description').AsString);
  conexao.ExecuteSQL;





  dataSetPolling.Next;
  end;
  end;
  iFood.Polling.AutoPolling := True;
  end; }

procedure TfrmServidor.AtualizaDadosiFood;
var
  conexao: Tconexao;
begin
  if IntegracaoiFood then
  begin
    conexao := Tconexao.Create;
    conexao.SQL.Add
      ('update produto set valor_ifood = (valor_venda + ((valor_venda*' +
      FloatToStr(TaxaiFood) +
      ')/100)), atualizado = 0 where valor_venda <> (valor_venda + ((valor_venda*'
      + FloatToStr(TaxaiFood) + ')/100))');
    conexao.ExecuteSQL;
    conexao.Free;
  end;
end;

procedure TfrmServidor.BuscaDadosiFood;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Codigo: Integer;
  Categoria: Integer;
begin
  // iFood.MerchantID(IDiFood);
  // conexao := Tconexao.Create;
  // iFood.Category.List(dataSetCategoy);
  // Dados := TFDMemTable.Create(self);
  // //
  // if dataSetCategoy.RecordCount > 0 then
  // begin
  // dataSetCategoy.First;
  // while not dataSetCategoy.Eof do
  // begin
  // Dados.Close;
  //
  // conexao.SQL.Add('select * from tipo_produto where upper(descricao) like '
  // + QuotedStr('%' + UpperCase(RemoveAcento(dataSetCategoy.FieldByName
  // ('name').AsString)) + '%') + ' or id_ifood = :ifood');
  // conexao.Parametros('ifood', dataSetCategoy.FieldByName('id').AsString);
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  // if Dados.RecordCount = 0 then
  // begin
  // Codigo := conexao.GerarID('tipo_produto', 'codigo');
  // conexao.SQL.Add
  // ('insert into tipo_produto (codigo,descricao,modificado_site,id_ifood) values (:codigo,:descricao,1,:id_ifood)');
  // conexao.Parametros('codigo', Codigo);
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(dataSetCategoy.FieldByName('name').AsString)));
  // conexao.Parametros('id_ifood', dataSetCategoy.FieldByName('id')
  // .AsString);
  // conexao.ExecuteSQL;
  // end
  // else
  // begin
  // Codigo := Dados.FieldByName('codigo').AsInteger;
  // end;
  // Categoria := Codigo;
  // iFood.Item.List(dataSetCategoy.FieldByName('id').AsString, memItens,
  // memCategoriaExtra, memItensPreco);
  // memItens.First;
  // while not memItens.Eof do
  // begin
  // Dados.Close;
  // try
  // conexao.SQL.Add
  // ('select * from produto where codigo_interno = :external or id_ifood = :ifood');
  // conexao.Parametros('external', FormatFloat('000000',
  // memItens.FieldByName('externalCode').AsInteger));
  // conexao.Parametros('ifood', memItens.FieldByName('id').AsString);
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  // except
  // conexao.SQL.Add('select * from produto where id_ifood = :ifood');
  // conexao.Parametros('ifood', memItens.FieldByName('id').AsString);
  // Dados.LoadFromJSON(conexao.ConsultaSQL);
  // end;
  // if Dados.RecordCount = 0 then
  // begin
  // Codigo := conexao.GerarID('produto', 'codigo');
  // conexao.SQL.Add
  // ('insert into produto (codigo,codigo_interno,data_cadastro,nome_produto,descricao,codigo_grupo,valor_venda,valor_ifood,ativo,observacao,modificado_site,id_ifood)');
  // conexao.SQL.Add
  // ('values (:codigo,:codigo_interno,current_date,:nome_produto,:descricao,:codigo_grupo,:valor_venda,:valor_ifood,1,1,1,:id_ifood)');
  // conexao.Parametros('codigo', Codigo);
  // conexao.Parametros('codigo_interno', FormatFloat('000000', Codigo));
  // conexao.Parametros('nome_produto',
  // UpperCase(RemoveAcento(memItens.FieldByName('productName')
  // .AsString)));
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(memItens.FieldByName('productDescription')
  // .AsString)));
  // conexao.Parametros('codigo_grupo', Categoria);
  // conexao.Parametros('valor_venda',
  // memItens.FieldByName('value').AsFloat);
  // conexao.Parametros('valor_ifood',
  // memItens.FieldByName('value').AsFloat);
  // conexao.Parametros('id_ifood', memItens.FieldByName('id').AsString);
  // conexao.ExecuteSQL;
  // end;
  //
  // conexao.SQL.Add
  // ('update produto set nome_produto = :nome_produto, descricao = :descricao, valor_venda = :valor_venda, valor_ifood = :valor_ifood, codigo_grupo = :codigo_grupo where id_ifood = :id_ifood');
  // conexao.Parametros('nome_produto',
  // UpperCase(RemoveAcento(memItens.FieldByName('productName')
  // .AsString)));
  // conexao.Parametros('descricao',
  // UpperCase(RemoveAcento(memItens.FieldByName('productDescription')
  // .AsString)));
  // conexao.Parametros('codigo_grupo', Categoria);
  //
  // conexao.Parametros('valor_venda', memItens.FieldByName('value').AsFloat
  // - ((memItens.FieldByName('value').AsFloat * TaxaiFood) / 100));
  // conexao.Parametros('valor_ifood', memItens.FieldByName('value')
  // .AsFloat);
  // conexao.Parametros('id_ifood', memItens.FieldByName('id').AsString);
  // conexao.ExecuteSQL;
  //
  //
  // memItens.Next;
  // end;
  //
  // dataSetCategoy.Next;
  // end;
  //
  // end;

end;

function TfrmServidor.ConverteValoriFood(Valor: String): Real;
begin
  Result := StrToFloat(StringReplace(Valor, ',', '.', [rfReplaceAll]));
end;

procedure TfrmServidor.Executaveis;
var
  Dados: TFDMemTable;
  conexao: Tconexao;
begin
  conexao := Tconexao.Create;
  Dados := TFDMemTable.Create(self);
  conexao.SQL.Add('select * from dados_whatsapp');
  Dados.LoadStructure(conexao.ConsultaSQL);

end;

procedure TfrmServidor.Fechar1Click(Sender: TObject);
begin


  // FecharExe();

  FecharExe(frmServidor.IMPRESSAO);
  FecharExe(frmServidor.WHATSAPP);
  FecharExe(frmServidor.SITE);
  FecharExe(Application.ExeName);
  FecharExe('GooPedir.exe');

  // Application.Terminate;
end;

procedure TfrmServidor.FecharExe(ExeFileName: String);
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  ExeFileName := ExtractFileName(ExeFileName);

  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile))
      = UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile)
      = UpperCase(ExeFileName))) then
      TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0),
        FProcessEntry32.th32ProcessID), 0);
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure TfrmServidor.FichaTecnica;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  DadosProduto: TFDMemTable;
  Ingrediente: String;
  CodigoIngrediente: Integer;
  Codigo: Integer;
  I: Integer;
begin
  conexao := Tconexao.Create;
  try
    if frmServidor.Configuracoes.FieldByName('ficha_tecnica').AsInteger = 1 then
    begin

      Dados := TFDMemTable.Create(nil);
      DadosProduto := TFDMemTable.Create(nil);
      conexao.SQL.Add
        ('SELECT group_concat(pro_adi_personalizado.id_produto) as produtos, group_concat(pro_adi_personalizado_sabores.id) as ids, upper(pro_adi_personalizado_sabores.nome) as nome  FROM pro_adi_personalizado');
      conexao.SQL.Add
        ('join pro_adi_personalizado_sabores on pro_adi_personalizado_sabores.id_pro_adi_personalizado = pro_adi_personalizado.id');
      conexao.SQL.Add('where pro_adi_personalizado_sabores.valor = 0');
      conexao.SQL.Add('group by upper(pro_adi_personalizado_sabores.nome)');
      Dados.LoadFromJSON(conexao.ConsultaSQL);
      if Dados.RecordCount > 0 then
      begin

        while not Dados.Eof do
        begin
          DadosProduto.Close;
          conexao.SQL.Add('select * from produto where codigo in (' +
            Dados.FieldByName('produtos').AsString + ')');
          DadosProduto.LoadFromJSON(conexao.ConsultaSQL);

          Ingrediente := RemoveAcento(Dados.FieldByName('nome').AsString);
          Ingrediente := StringReplace(Ingrediente, 'SEM ', '', [rfReplaceAll]);
          for I := 0 to 9 do
          begin
            Ingrediente := StringReplace(Ingrediente, I.ToString, '',
              [rfReplaceAll]);
          end;
          Ingrediente := trim(Ingrediente);

          conexao.SQL.Add('select * from ingredientes where descricao = ' +
            QuotedStr(Ingrediente));
          try
            CodigoIngrediente := conexao.FieldByName('id');
          except
            CodigoIngrediente := 0
          end;
          if CodigoIngrediente = 0 then
          begin
            CodigoIngrediente := conexao.GerarID('ingredientes', 'id');
            conexao.SQL.Add
              ('insert into ingredientes (id,descricao,unidade) values (:id,:descricao,:unidade)');
            conexao.Parametros('id', CodigoIngrediente);
            conexao.Parametros('descricao', Ingrediente);
            conexao.Parametros('unidade', 'UN');

            conexao.ExecuteSQL;
          end;
          while not DadosProduto.Eof do
          begin
            conexao.SQL.Add
              ('select * from produto_ingredientes where id_produto = :id_produto and id_ingredientes = :id_ingredientes');
            conexao.Parametros('id_ingredientes', CodigoIngrediente);
            conexao.Parametros('id_produto', DadosProduto.FieldByName('codigo')
              .AsInteger);

            try
              Codigo := conexao.FieldByName('id');

            except
              Codigo := 0;

            end;

            if Codigo = 0 then
            begin
              Codigo := conexao.GerarID('produto_ingredientes', 'id');
              conexao.SQL.Add
                ('insert into produto_ingredientes (id,id_produto,id_ingredientes,quantidade) values (:id,:id_produto,:id_ingredientes,:quantidade)');
              conexao.Parametros('id', Codigo);
              conexao.Parametros('id_produto',
                DadosProduto.FieldByName('codigo').AsInteger);
              conexao.Parametros('id_ingredientes', CodigoIngrediente);
              conexao.Parametros('quantidade', 1);
              conexao.ExecuteSQL;
            end;

            DadosProduto.Next;
          end;

          conexao.SQL.Add
            ('update pro_adi_personalizado_sabores set id_ingredientes = :id_ingredientes where id in('
            + Dados.FieldByName('ids').AsString + ')');

          conexao.Parametros('id_ingredientes', CodigoIngrediente);
          conexao.ExecuteSQL;

          Dados.Next;
        end;
      end;
      Dados.Free;
    end;
  except

  end;
  conexao.Free;
end;

procedure TfrmServidor.FimAtualizacao;
begin
  //
end;

procedure TfrmServidor.FormCreate(Sender: TObject);
var
  conexao: Tconexao;
  VersaoMysql: String;
begin
  conexao := Tconexao.Create;
  VersaoMysql := conexao.ValidaVersao;
  if length(VersaoMysql) > 0 then
    ShowMessage(VersaoMysql);
  conexao.Free;

  THorse.Use(Jhonson);
  THorse.Use(Etag);
  THorse.Use(OctetStream);
  // Declaração das URI da API
  token.Registry;
  util.Registry;

  // util.backup.Registry;

  // Inicialização do Console
  try
    THorse.Listen(2121,
      procedure(Horse: THorse)
      begin
        // Writeln('Server is runing on port ' + THorse.Port.ToString);
        // Writeln('');
      end);
  except
    Application.Terminate;
    exit;
  end;

  Atualizacao := TSQL.Create;
  // Atualizacao.LabelInfo := labelInfoAtualizacao;
  Atualizacao.MemoLog := memoHistorico;

  Atualizacao.SeTiverAtualizacao := TemAtualizacao;
  Atualizacao.seNaoTiverAtualizacao := SemAtualizacao;
  Atualizacao.IniciarAtualizacao := IniciarAtualizacao;
  Atualizacao.AposConcluirAtualizacao := FimAtualizacao;
  Atualizacao.VerificaAtualizacao;

  Servicos := TAbrirServicos.Create;
  Servicos.Start;

  FichaTecnica;
  BuscaDadosiFood;

end;

function TfrmServidor.IDiFood: String;
begin
  try
    Result := frmServidor.Configuracoes.FieldByName('merchant').AsString
  except
    Result := '';
  end;
  // '155cc414-36d0-4ec2-9d06-f85fad9e782a';
end;

function TfrmServidor.IMPRESSAO: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'ImpressaoGooPedir.exe';
end;

procedure TfrmServidor.IniciarAtualizacao;
begin
  //
end;

function TfrmServidor.IntegracaoiFood: Boolean;
begin
  try
    Result := frmServidor.Configuracoes.FieldByName('ifood_integracao')
      .AsInteger = 1;
    if Result then
    begin
      if IDiFood = '' then
        Result := false;
    end;
  except

  end;
end;

procedure TfrmServidor.LoadImpressora;
var
  I: Integer;
  ID: Integer;
begin
  memImpressora.Close;
  memImpressora.Open;
  ID := 1;
  memImpressora.Insert;
  memImpressora.FieldByName('ID').AsInteger := ID;
  memImpressora.FieldByName('DRIVER').AsString := 'Default';
  memImpressora.Post;
  for I := 0 to Printer.Count - 1 do
  begin

    if (UpperCase(Printer.Printers[I].Device) <> 'FAX') and
      (UpperCase(Printer.Printers[I].Device) <> 'MICROSOFT PRINT TO PDF') and
      (UpperCase(Printer.Printers[I].Device) <> 'MICROSOFT XPS DOCUMENT WRITER')
    then
    begin
      inc(ID);
      memImpressora.Insert;
      memImpressora.FieldByName('ID').AsInteger := ID;
      memImpressora.FieldByName('DRIVER').AsString :=
        Printer.Printers[I].Device;
      memImpressora.Post;
    end;
  end;

end;

function TfrmServidor.PathExe: String;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

procedure TfrmServidor.SemAtualizacao;
begin
  //
end;

function TfrmServidor.SITE: String;
begin
  if not FechouSite then
    Result := ExtractFileDir(Application.ExeName) + '\' + 'SiteGooPedir.exe';
end;

function TfrmServidor.StatusPedidoiFood: Integer;
begin
  try
    Result := frmServidor.Configuracoes.FieldByName('aceitar_pedidos_ifood')
      .AsInteger;
  except

  end;
end;

function TfrmServidor.TaxaiFood: Real;
begin
  try
    Result := frmServidor.Configuracoes.FieldByName
      ('aceitar_pedidos_ifood').AsFloat;
  except
    Result := 0;
  end;
end;

procedure TfrmServidor.TemAtualizacao;
begin
  Atualizacao.AtualizarBanco;
end;

procedure TfrmServidor.tMinimizaTimer(Sender: TObject);
begin
  tMinimiza.Enabled := false;
  self.Hide();
  self.WindowState := wsMinimized;
  // StatusForm := sOcuto;
end;

function TfrmServidor.VerificaExe(Nome: String): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Nome := ExtractFileName(Nome);
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := false;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(Nome)
      ) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(Nome))) then
    begin
      Result := True;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function TfrmServidor.WHATSAPP: String;
begin
  if not FechouWhatsapp then
    Result := ExtractFileDir(Application.ExeName) + '\' + 'WhatsappGoPedir.exe';
end;

{ TAbrirServicos }

constructor TAbrirServicos.Create;
begin
  inherited Create(True);
  conexao := Tconexao.Create;
end;

destructor TAbrirServicos.Destroy;
begin
  conexao.Free;
  inherited;
end;

procedure TAbrirServicos.Execute;
var

  ServicoImpressao: Boolean;
  ServicoWhatsapp: Boolean;
  DadosImpressao: TFDMemTable;

begin
  inherited;
  DadosImpressao := TFDMemTable.Create(nil);
  while not Terminated do
  begin
    conexao.SQL.Add('select * from dados_whatsapp');
    frmServidor.Configuracoes.LoadFromJSON(conexao.ConsultaSQL);
    conexao.SQL.Add
      ('SELECT * FROM impressao_pedido where data_solicitacao = current_date() and status = 0 and id_pedido > 0');
    DadosImpressao.LoadFromJSON(conexao.ConsultaSQL);

    if DadosImpressao.RecordCount >= 5 then
    begin
      frmServidor.FecharExe(frmServidor.IMPRESSAO);
    end;

    try
      ServicoImpressao := frmServidor.Configuracoes.FieldByName('a_impressora')
        .AsInteger = 1;
    except
      ServicoImpressao := false;
    end;
    try
      ServicoWhatsapp := frmServidor.Configuracoes.FieldByName('a_whatsapp')
        .AsInteger = 1;
    except
      ServicoWhatsapp := false;
    end;
    // ImpressaoGooPedir
    // ServidorGooPedir
    // WhatsappGoPedir
    // SiteGooPedir
    // GooPedir
    if (not frmServidor.VerificaExe(frmServidor.IMPRESSAO)) and ServicoImpressao
    then
      frmServidor.AbrirExe(frmServidor.IMPRESSAO);

    if (not frmServidor.VerificaExe(frmServidor.WHATSAPP)) and ServicoWhatsapp
    then
    begin
      if Time >= StrToTime
        (copy(frmServidor.Configuracoes.FieldByName('horario_abertura')
        .AsString, 0, 8)) then
        frmServidor.AbrirExe(frmServidor.WHATSAPP);
    end;
    if Time >= StrToTime
      (copy(frmServidor.Configuracoes.FieldByName('horario_fechamento')
      .AsString, 0, 8)) then
    begin
      frmServidor.FecharExe(frmServidor.WHATSAPP);
    end;

    if (not frmServidor.VerificaExe(frmServidor.SITE)) then
      frmServidor.AbrirExe(frmServidor.SITE);

    Sleep(60 * 1000);
  end;

end;

end.
