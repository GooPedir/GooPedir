unit uProcessamentoiFood;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.SyncObjs,
  ADRIFood.Model.Interfaces, ADRIFood.Model.Types,
  ADRIFood.Component.Events, ADRIFood.Component, util, DataSet.Serialize,
  Vcl.StdCtrls, uLogthread;

type
   TProcessamentoiFood = class(TThread)
  private
    // FQueue: TQueue<string>;
    FQueue: TQueue<TPair<IADRIFoodModelOrder, IADRIFoodModelOrderHead>>;
    FLock: TCriticalSection;
  protected
    procedure Execute; override;
    procedure Processamento(Order: IADRIFoodModelOrder;
      OrderHead: IADRIFoodModelOrderHead);
    function StatusPedidoiFood: Integer;
    procedure SalvarTextoEmArquivo(const Texto, NomeArquivo: string);
    function LerConteudoArquivo(const CaminhoArquivo: string): string;
    function ConverteAdicionais(Valor: String): String;
  public
    constructor Create;
    destructor Destroy; override;
    procedure OrderId(Order: IADRIFoodModelOrder;
      OrderHead: IADRIFoodModelOrderHead);

    procedure TestImport;

  var
    IFood: TADRIFood;
    StatusiFood: Integer;
  end;

implementation

uses
  FireDAC.Comp.Client, conexao, Vcl.Dialogs, uMain;

{ TProcessamentoiFood }

function TProcessamentoiFood.ConverteAdicionais(Valor: String): String;
var
  I, K: Integer;
begin
  Result := UpperCase(Valor);
  for I := 1 to 10 do
  begin
    for K := 1 to 10 do
    begin
      Result := StringReplace(Result, I.ToString + '/' + K.ToString, '',
        [rfReplaceAll]);
    end;
  end;

  Result := StringReplace(Result, 'MASSA TRADICIONAL', '', [rfReplaceAll]);
  Result := StringReplace(Result, 'MASSA .', '', [rfReplaceAll]);
  Result := StringReplace(Result, ' + ', '', [rfReplaceAll]);
  Result := StringReplace(Result, 'BORDA ', '', [rfReplaceAll]);

end;

constructor TProcessamentoiFood.Create;
begin
  inherited Create(True);
  FQueue := TQueue < TPair < IADRIFoodModelOrder, IADRIFoodModelOrderHead
    >>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TProcessamentoiFood.Destroy;
begin
  FreeAndNil(FQueue);
  FreeAndNil(FLock);
  inherited;
end;

procedure TProcessamentoiFood.OrderId(Order: IADRIFoodModelOrder;
  OrderHead: IADRIFoodModelOrderHead);
var
  OrderPair: TPair<IADRIFoodModelOrder, IADRIFoodModelOrderHead>;
begin
  OrderPair := TPair<IADRIFoodModelOrder, IADRIFoodModelOrderHead>.Create(Order,
    OrderHead);
  FLock.Enter;
  try
    FQueue.Enqueue(OrderPair);
  finally
    FLock.Leave;
  end;
end;

procedure TProcessamentoiFood.Processamento(Order: IADRIFoodModelOrder;
  OrderHead: IADRIFoodModelOrderHead);
var
  conexao: Tconexao;
  DadosPedido: TFDMemTable;
  CodigoIntermo: Integer;
  CodigoPedidoDia: Integer;
  CodigoCliente: Integer;
  CodigoEndereco: Integer;
  DadosCli: TFDMemTable;
  CodigoProduto: Integer;
  CodigoTipoPagamento: Integer;
  Codigo: Integer;
  CodigoItem: Integer;
  I: Integer;
  NomeTipoPagamento: String;
  DescricaoDesconto: String;
  Categoria: String;
  dataSetOrders: TFDMemTable;
  dataSetOrderItems: TFDMemTable;
  dataSetOrderPayments: TFDMemTable;
  dataSetOrderSubItems: TFDMemTable;
  dataSetOrderBenefits: TFDMemTable;
  OrderId: String;
  Memo: TMemo;
  PagamentoReduzido: Boolean;
  NomeLoja: String;
begin
  try
    OrderId := Order.Id;
  except
    OrderId := '7dc93588-e799-4043-8776-431d2cfed696';
  end;
  conexao := Tconexao.Create('uProcessamentoiFood');
  PagamentoReduzido := True;

  conexao.SQL.Add('select * from pedido where id_ifood = :id_ifood');
  conexao.Parametros('id_ifood', OrderId);

  try
    Codigo := conexao.FieldByName('codigo');
  except
    Codigo := 0;
  end;

  if Codigo > 0 then
  begin
    conexao.Free;
    exit;
  end
  else
  begin
    DadosPedido := TFDMemTable.Create(nil);
    DadosCli := TFDMemTable.Create(nil);
    DadosPedido.Close;
    Codigo := 0;

    dataSetOrders := TFDMemTable.Create(nil);
    dataSetOrderItems := TFDMemTable.Create(nil);
    dataSetOrderPayments := TFDMemTable.Create(nil);
    dataSetOrderSubItems := TFDMemTable.Create(nil);
    dataSetOrderBenefits := TFDMemTable.Create(nil);

    try
      IFood.Order.GetOrder(OrderId, dataSetOrders, dataSetOrderItems,
        dataSetOrderPayments, dataSetOrderSubItems, dataSetOrderBenefits);
    except
      dataSetOrders.LoadFromJSON(LerConteudoArquivo('ifood/' + OrderId+ '.dso'));
      dataSetOrderItems.LoadFromJSON(LerConteudoArquivo('ifood/' + OrderId + '.dsoi'));
      dataSetOrderPayments.LoadFromJSON(LerConteudoArquivo('ifood/' + OrderId + '.dsop'));
      dataSetOrderSubItems.LoadFromJSON(LerConteudoArquivo('ifood/' + OrderId + '.dsosi'));
      dataSetOrderBenefits.LoadFromJSON(LerConteudoArquivo('ifood/' + OrderId + '.dsob'));
    end;

    SalvarTextoEmArquivo(dataSetOrders.ToJSONArray().ToString,
      'ifood/' + OrderId + '.dso');
    SalvarTextoEmArquivo(dataSetOrderItems.ToJSONArray().ToString,
      'ifood/' + OrderId + '.dsoi');
    SalvarTextoEmArquivo(dataSetOrderPayments.ToJSONArray().ToString,
      'ifood/' + OrderId + '.dsop');
    SalvarTextoEmArquivo(dataSetOrderSubItems.ToJSONArray().ToString,
      'ifood/' + OrderId + '.dsosi');
    SalvarTextoEmArquivo(dataSetOrderBenefits.ToJSONArray().ToString,
      'ifood/' + OrderId + '.dsob');

    DescricaoDesconto := '';
    if dataSetOrderBenefits.RecordCount > 0 then
    begin
      if dataSetOrderBenefits.FieldByName('valueifood').AsFloat > 0 then
      begin
        DescricaoDesconto := 'Desconto por conta do iFood';
      end;
      if dataSetOrderBenefits.FieldByName('valuemerchant').AsFloat > 0 then
      begin
        DescricaoDesconto := 'Desconto por conta da Loja';
      end;
      if dataSetOrderBenefits.FieldByName('valueexternal').AsFloat > 0 then
      begin
        DescricaoDesconto := 'Desconto por conta da Loja';
      end;

      if dataSetOrderBenefits.FieldByName('target').AsString = 'DELIVERY_FEE'
      then
        DescricaoDesconto := DescricaoDesconto +
          ' - Desconto é aplicado sobre a taxa de entrega';
      if dataSetOrderBenefits.FieldByName('target').AsString = 'CART' then
        DescricaoDesconto := DescricaoDesconto +
          ' - Desconto é aplicado sobre o subtotal do carrinho (somatório dos itens do pedido).';
      if dataSetOrderBenefits.FieldByName('target').AsString = 'ITEM' then
        DescricaoDesconto := DescricaoDesconto +
          ' - Desconto é aplicado sobre um item específico do carrinho. O campo targetId específica sobre qual item o desconto foi aplicado. Essa especificação é feita na configuração da campanha.';
      if dataSetOrderBenefits.FieldByName('target').AsString = 'PROGRESSIVE_DISCOUNT_ITEM'
      then
        DescricaoDesconto := DescricaoDesconto +
          ' - Desconto progressivo em itens iguais do pedido, formando um combo.';

    end;
    conexao.SQL.Add('select * from pedido where id_ifood = :id_ifood');
    conexao.Parametros('id_ifood', OrderId);
    DadosPedido.LoadFromJSON(conexao.ConsultaSQL);
    if DadosPedido.RecordCount = 0 then
    begin
      CodigoIntermo := conexao.GerarID('pedido', 'codigo');
      CodigoPedidoDia := frmServidor.GerarCodigoPedidoDia;
      DadosCli.Close;

      if dataSetOrders.FieldByName('customerDocumentNumber').AsString = '' then
      begin
        CodigoCliente := conexao.GerarID('cliente', 'codigo');
        conexao.SQL.Add
          ('insert into cliente (codigo,nome,ativo,cpf,origem,bloqueado) values (:codigo,:nome,1,:cpf,''ifood'',0)');
        conexao.Parametros('codigo', CodigoCliente);
        conexao.Parametros('cpf',
          dataSetOrders.FieldByName('customerDocumentNumber').AsString);
        conexao.Parametros('nome',
          UpperCase(dataSetOrders.FieldByName('customerName').AsString));
        conexao.ExecuteSQL;
      end
      else
      begin
        conexao.SQL.Add('select * from cliente where cpf = :cpf');
        conexao.Parametros('cpf',
          dataSetOrders.FieldByName('customerDocumentNumber').AsString);
        DadosCli.LoadFromJSON(conexao.ConsultaSQL);
      end;

      if DadosCli.RecordCount = 0 then
      begin
        CodigoCliente := conexao.GerarID('cliente', 'codigo');
        conexao.SQL.Add
          ('insert into cliente (codigo,nome,ativo,cpf,origem,bloqueado) values (:codigo,:nome,1,:cpf,''ifood'',0)');
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

      if dataSetOrders.FieldByName('type').AsString = 'DELIVERY_TYPE' then
      begin
        CodigoEndereco := conexao.GerarID('cliente_endereco', 'codigo');
        conexao.SQL.Add
          ('insert into cliente_endereco (codigo,codigo_cliente,descricao,tipo,numero,rua,bairro,cidade,estado,complemento,ativo,km,latitude,longitude) values');
        conexao.SQL.Add
          ('(:codigo,:codigo_cliente,:descricao,:tipo,:numero,:rua,:bairro,:cidade,:estado,:complemento,1,0,:latitude,:longitude)');
        conexao.Parametros('codigo', CodigoEndereco);
        conexao.Parametros('codigo_cliente', CodigoCliente);
        conexao.Parametros('descricao', 'Principal');
        conexao.Parametros('tipo', 1);
        conexao.Parametros('rua',
          UpperCase(RemoveAcento(dataSetOrders.FieldByName
          ('deliveryaddressstreetname').AsString)));
        conexao.Parametros('bairro',
          UpperCase(RemoveAcento(dataSetOrders.FieldByName
          ('deliveryaddressneighborhood').AsString)));
        conexao.Parametros('cidade',
          UpperCase(RemoveAcento(dataSetOrders.FieldByName
          ('deliveryaddresscity').AsString)));
        conexao.Parametros('estado',
          UpperCase(RemoveAcento(dataSetOrders.FieldByName
          ('deliveryaddressstate').AsString)));
        conexao.Parametros('complemento',
          UpperCase(RemoveAcento(dataSetOrders.FieldByName
          ('deliveryaddresscomplement').AsString)));
        conexao.Parametros('numero',
          UpperCase(RemoveAcento(dataSetOrders.FieldByName
          ('deliveryaddressstreetnumber').AsString)));
        conexao.Parametros('latitude',
          (RemoveAcento(dataSetOrders.FieldByName('deliveryaddresslatitude')
          .AsString)));
        conexao.Parametros('longitude',
          (RemoveAcento(dataSetOrders.FieldByName('deliveryaddresslongitude')
          .AsString)));
        conexao.ExecuteSQL;
      end;

      if dataSetOrderPayments.FieldByName('name').AsString = 'CASH' then
      begin
        NomeTipoPagamento := 'Dinheiro';
      end
      else if dataSetOrderPayments.FieldByName('name').AsString = 'CREDIT' then
      begin
        if PagamentoReduzido then
        begin
          NomeTipoPagamento := 'Cartão de Crédito ';
          if dataSetOrderPayments.FieldByName('type').AsString = 'ONLINE' then
            NomeTipoPagamento := NomeTipoPagamento + ' iFood'
          else
            NomeTipoPagamento := NomeTipoPagamento;
        end
        else
        begin
          NomeTipoPagamento := 'iFood - Cartão de Crédito ' +
            dataSetOrderPayments.FieldByName('cardbrand').AsString;
          if dataSetOrderPayments.FieldByName('type').AsString = 'ONLINE' then
            NomeTipoPagamento := NomeTipoPagamento + ' iFood'
          else
            NomeTipoPagamento := NomeTipoPagamento;
        end;

      end
      else if dataSetOrderPayments.FieldByName('name').AsString = 'DEBIT' then
      begin
        if PagamentoReduzido then
        begin
          NomeTipoPagamento := 'Cartão de Débito ';
          if dataSetOrderPayments.FieldByName('type').AsString = 'ONLINE' then
            NomeTipoPagamento := NomeTipoPagamento + ' iFood'
          else
            NomeTipoPagamento := NomeTipoPagamento;

        end
        else
        begin
          NomeTipoPagamento := 'iFood - Cartão de Débito ' +
            dataSetOrderPayments.FieldByName('cardbrand').AsString;
          if dataSetOrderPayments.FieldByName('type').AsString = 'ONLINE' then
            NomeTipoPagamento := NomeTipoPagamento + ' iFood'
          else
            NomeTipoPagamento := NomeTipoPagamento;
        end;

      end
      else
      begin
        if PagamentoReduzido then
        begin
          NomeTipoPagamento := dataSetOrderPayments.FieldByName
            ('method').AsString;
          if dataSetOrderPayments.FieldByName('type').AsString = 'ONLINE' then
            NomeTipoPagamento := NomeTipoPagamento + ' iFood'
          else
            NomeTipoPagamento := NomeTipoPagamento;
        end
        else
        begin
          NomeTipoPagamento := 'iFood - ' + dataSetOrderPayments.FieldByName
            ('method').AsString;
          if dataSetOrderPayments.FieldByName('type').AsString = 'ONLINE' then
            NomeTipoPagamento := NomeTipoPagamento + ' iFood'
          else
            NomeTipoPagamento := NomeTipoPagamento
        end;

      end;
      conexao.SQL.Add
        ('select * from tipo_pagamento where descricao = :descricao');
      conexao.Parametros('descricao', NomeTipoPagamento);

      CodigoTipoPagamento := conexao.FieldByName('codigo');
      if CodigoTipoPagamento = 0 then
      begin
        CodigoTipoPagamento := conexao.GerarID('tipo_pagamento', 'codigo');
        conexao.SQL.Add
          ('insert into tipo_pagamento (codigo,descricao,ativo) values (:codigo,:descricao,0)');
        conexao.Parametros('codigo', CodigoTipoPagamento);
        conexao.Parametros('descricao', NomeTipoPagamento);
        conexao.ExecuteSQL;
      end;

      conexao.SQL.Add('select * from pedido where id_ifood = :id_ifood');
      conexao.Parametros('id_ifood', OrderId);

      try
        Codigo := conexao.FieldByName('codigo');
      except
        Codigo := 0;
      end;

      if Codigo > 0 then
      begin
        conexao.Free;
        dataSetOrders.Free;
        dataSetOrderItems.Free;
        dataSetOrderPayments.Free;
        dataSetOrderSubItems.Free;
        dataSetOrderBenefits.Free;
        exit;
      end;

      // alter table pedido add ifood integer;

      conexao.SQL.Add('select * from ifood_connect where id = :id');
      conexao.Parametros('id', IFood.Tag);
      try
        NomeLoja := conexao.FieldByName('name');
      except
        NomeLoja := '';
      end;

      if NomeLoja <> '' then
      begin
        NomeLoja := ' (' + NomeLoja + ')';
      end;

      conexao.SQL.Add
        ('insert into pedido (codigo,codigo_pedido_dia,codigo_cliente,codigo_cliente_endereco,');
      conexao.SQL.Add
        ('data_pedido,hora_pedido,status,valor_pedido,valor_desconto,valor_taxa_entrega,');
      conexao.SQL.Add
        ('valor_total_pedido,troco,tipo_pagamento,id_ifood,origem,order_ifood,agendada_ifood,estimada_ifood,desc_desconto_ifood,ifood_phone,ifood_localizador,ifood_pedido,latitude,longitude,ifood,mp)');
      conexao.SQL.Add
        ('values (:codigo,:codigo_pedido_dia,:codigo_cliente,:codigo_cliente_endereco,:data_pedido,');
      conexao.SQL.Add
        (':hora_pedido,:status,:valor_pedido,:valor_desconto,:valor_taxa_entrega,:valor_total_pedido,');
      conexao.SQL.Add
        (':troco,:tipo_pagamento,:id_ifood,4,:order_ifood,:agendada_ifood,:estimada_ifood,:desc_desconto_ifood,:ifood_phone,:ifood_localizador,:ifood_pedido,:latitude,:longitude,:ifood,:mp)');
      conexao.Parametros('codigo', CodigoIntermo);
      conexao.Parametros('codigo_pedido_dia', CodigoPedidoDia);
      conexao.Parametros('codigo_cliente', CodigoCliente);
      conexao.Parametros('codigo_cliente_endereco', CodigoEndereco);
      if (dataSetOrders.FieldByName('deliveredby').AsString = 'MERCHANT') then
        conexao.Parametros('mp', 'Entrega Própria' + NomeLoja)
      else
        conexao.Parametros('mp', 'Entrega Parceira' + NomeLoja);

      conexao.Parametros('ifood', IFood.Tag);

      try
        conexao.Parametros('data_pedido',
          dataSetOrders.FieldByName('createdatlocal').AsDateTime);
      except
        conexao.Parametros('data_pedido', now);
      end;
      try
        conexao.Parametros('hora_pedido',
          dataSetOrders.FieldByName('createdatlocal').AsDateTime);
      except
        conexao.Parametros('hora_pedido', now);
      end;

      conexao.Parametros('status', 1);
      conexao.Parametros('valor_pedido',
        (dataSetOrders.FieldByName('subTotal').AsFloat));
      conexao.Parametros('valor_taxa_entrega',
        (dataSetOrders.FieldByName('deliveryFee').AsFloat));
      conexao.Parametros('valor_desconto',
        (dataSetOrders.FieldByName('totalBenefits').AsFloat));
      conexao.Parametros('valor_total_pedido',
        (dataSetOrders.FieldByName('totalPrice').AsFloat));
      try
        if dataSetOrderPayments.FieldByName('changeFor').AsFloat = 0 then
        begin
          conexao.Parametros('troco', 0);
        end
        else
        begin
          conexao.Parametros('troco',
            dataSetOrderPayments.FieldByName('changeFor').AsFloat -
            dataSetOrders.FieldByName('totalPrice').AsFloat);
        end;

      except
        conexao.Parametros('troco', 0);
      end;
      conexao.Parametros('tipo_pagamento', CodigoTipoPagamento);
      if dataSetOrders.FieldByName('deliveryaddresslatitude').AsString = '' then
      begin
        dataSetOrders.Edit;
        dataSetOrders.FieldByName('deliveryaddresslatitude').AsString := '0';
        dataSetOrders.FieldByName('deliveryaddresslongitude').AsString := '0';
      end;
      conexao.Parametros('id_ifood', OrderId);
      conexao.Parametros('order_ifood', dataSetOrders.FieldByName('ordertiming').AsString);
      conexao.Parametros('latitude',(RemoveAcento(dataSetOrders.FieldByName('deliveryaddresslatitude').AsString)));
      conexao.Parametros('longitude',(RemoveAcento(dataSetOrders.FieldByName('deliveryaddresslongitude').AsString)));

      if dataSetOrders.FieldByName('deliverydatetimestart').AsString = '30/12/1899'
      then
      begin
        dataSetOrders.Edit;
        try
          dataSetOrders.FieldByName('deliverydatetimestart').AsDateTime :=
            dataSetOrders.FieldByName('preparationstartdatetimelocal').AsDateTime;
        except
          dataSetOrders.FieldByName('deliverydatetimestart').AsDateTime := now;
        end;

        dataSetOrders.Post;
      end;

      try
        conexao.Parametros('agendada_ifood',
          dataSetOrders.FieldByName('deliverydatetimestart').AsDateTime);
      except
        conexao.Parametros('agendada_ifood', now);
      end;
      try
        conexao.Parametros('estimada_ifood',
          dataSetOrders.FieldByName('preparationstartdatetimelocal')
          .AsDateTime);
      except
        conexao.Parametros('estimada_ifood', now);
      end;
      conexao.Parametros('desc_desconto_ifood', DescricaoDesconto);
      conexao.Parametros('ifood_phone',
        (dataSetOrders.FieldByName('customerphone').AsString));
      conexao.Parametros('ifood_localizador',
        (dataSetOrders.FieldByName('customerphonelocalizer').AsString));
      conexao.Parametros('ifood_pedido',
        (dataSetOrders.FieldByName('displayid').AsString));
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

        if CodigoProduto = 0 then
        begin
          conexao.SQL.Add('select * from produto where codigo = :ifood');
          conexao.Parametros('ifood',
            dataSetOrderItems.FieldByName('externalCode').AsString);
          try
            CodigoProduto := conexao.FieldByName('codigo');
          except
            CodigoProduto := 0;
          end;
        end;
        if CodigoProduto = 0 then
        begin
          CodigoProduto := conexao.GerarID('produto', 'codigo');
          conexao.SQL.Add
            ('insert into produto  (codigo,codigo_interno,data_cadastro,nome_produto,codigo_grupo,valor_custo,valor_venda,ativo,foto_ifood,id_ifood)');
          conexao.SQL.Add
            ('values (:codigo,:codigo_interno,curdate(),:nome_produto,2,0,:valor_venda,1,:foto_ifood,:id_ifood)');
          conexao.Parametros('codigo', CodigoProduto);
          conexao.Parametros('codigo_interno', CodigoProduto);
          conexao.Parametros('nome_produto',
            dataSetOrderItems.FieldByName('name').AsString);
          conexao.Parametros('valor_venda',
            dataSetOrderItems.FieldByName('unitprice').AsFloat);
          conexao.Parametros('foto_ifood',
            dataSetOrderItems.FieldByName('imageurl').AsString);
          conexao.Parametros('id_ifood', dataSetOrderItems.FieldByName('id')
            .AsString);
          conexao.ExecuteSQL;

        end;

        CodigoItem := conexao.GerarID('pedido_produtos', 'codigo');
        conexao.SQL.Add
          ('insert into pedido_produtos (codigo,codigo_produto,codigo_pedido,valor_unitario,valor_total,quantidade,observacao,valor_adicional)');
        conexao.SQL.Add
          ('values (:codigo,:codigo_produto,:codigo_pedido,:valor_unitario,:valor_total,:quantidade,:observacao,:valor_adicional)');

        conexao.Parametros('codigo', CodigoItem);
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
        Codigo := conexao.GerarID('impressao_pedido_produto', 'id');
        conexao.SQL.Add
          ('insert into impressao_pedido_produto (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias,usuario) values (:id,current_date(),current_time(),:id_pedido,1,0,-5)');
        conexao.Parametros('id', Codigo);
        conexao.Parametros('id_pedido', CodigoItem);
        conexao.ExecuteSQL;

        // dataSetOrderSubItems.Filter := 'iditem = '+dataSetOrderItems.FieldByName('iditem').AsString;
        // dataSetOrderSubItems.Filtered := true;
        dataSetOrderSubItems.First;
        while not dataSetOrderSubItems.Eof do
        begin
          // Aki devo pegar o pro_adi_personalizado_sabores

          for I := 1 to dataSetOrderSubItems.FieldByName('quantity')
            .AsInteger do
          begin
            if dataSetOrderItems.FieldByName('iditem')
              .AsString = dataSetOrderSubItems.FieldByName('iditem').AsString
            then
            begin
              conexao.SQL.Add
                ('select pro_adi_personalizado.* from pro_adi_personalizado_sabores');
              conexao.SQL.Add
                ('join pro_adi_personalizado on pro_adi_personalizado.id = pro_adi_personalizado_sabores.id_pro_adi_personalizado and pro_adi_personalizado.id_produto = :produto');
              conexao.SQL.Add
                ('where upper(pro_adi_personalizado_sabores.nome) = :nome');
              conexao.Parametros('produto', CodigoProduto);
              conexao.Parametros('nome',
                UpperCase(RemoveAcento(dataSetOrderSubItems.FieldByName('name')
                .AsString)));

              Categoria := conexao.FieldByName('descricao');

              if Categoria = '0' then
              begin
                Categoria := 'IFOOD';
              end;

              if UpperCase(dataSetOrderSubItems.FieldByName('externalcode')
                .AsString) = 'SABOR' then
              begin
                Categoria := dataSetOrderSubItems.FieldByName
                  ('externalcode').AsString;
              end;

              if UpperCase(dataSetOrderSubItems.FieldByName('externalcode')
                .AsString) = 'SABORES' then
              begin
                Categoria := dataSetOrderSubItems.FieldByName
                  ('externalcode').AsString;
              end;

              if (Pos('BORDA',
                UpperCase(dataSetOrderSubItems.FieldByName('name').AsString)
                ) > 0) then
              begin
                Categoria := 'BORDA';
              end;

              Codigo := conexao.GerarID('pedido_produto_sap', 'id');
              conexao.SQL.Add
                ('insert into pedido_produto_sap (id,codigo_pedido_produto,tipo,nomeclatura,descricao,valor)');
              conexao.SQL.Add
                ('values (:id,:codigo_pedido_produto,1,:nomeclatura,:descricao,:valor)');
              conexao.Parametros('id', Codigo);
              conexao.Parametros('codigo_pedido_produto', CodigoItem);
              conexao.Parametros('nomeclatura', Categoria);
              conexao.Parametros('descricao',
                UpperCase(ConverteAdicionais
                (RemoveAcento(dataSetOrderSubItems.FieldByName('name')
                .AsString))));
              conexao.Parametros('valor',
                dataSetOrderSubItems.FieldByName('unitPrice').AsFloat *
                dataSetOrderSubItems.FieldByName('quantity').AsInteger);
              conexao.ExecuteSQL;
            end;
          end;

          dataSetOrderSubItems.Next;
        end;

        dataSetOrderItems.Next;
      end;

      // Validar qual o status
      case StatusPedidoiFood of
        1:
          begin
            // Aceitar o Pedido
            IFood.Order.Confirmation(OrderId);
            Codigo := conexao.GerarID('impressao_pedido', 'id');
            conexao.SQL.Add
              ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
            conexao.Parametros('id', Codigo);
            conexao.Parametros('pedido', CodigoIntermo);
            conexao.ExecuteSQL;

            conexao.SQL.Add
              ('update pedido set status_ifood = "CFM" where id_ifood = :id_ifood');
            conexao.Parametros('id_ifood', OrderId);
            conexao.ExecuteSQL;

            conexao.SQL.Add('UPDATE impressao_pedido_produto');
            conexao.SQL.Add('SET status = 0');
            conexao.SQL.Add('WHERE data_impressao IS NULL');
            conexao.SQL.Add
              ('AND id_pedido IN (SELECT codigo FROM pedido_produtos WHERE pedido_produtos.codigo_pedido = :pedido);');
            conexao.Parametros('pedido', CodigoIntermo);
            conexao.ExecuteSQL;
            // Imprimir
          end;
        2:
          begin
            // Cancelar o Pedido
          end;
      end;

    end
    else
    begin
      CodigoIntermo := DadosPedido.FieldByName('codigo').AsInteger;
    end;
    if StatusPedidoiFood <> 1 then
    begin
      conexao.SQL.Add
        ('update pedido set status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood');
      conexao.Parametros('id_ifood', OrderId);
      conexao.Parametros('status_ifood', OrderHead.code);
      conexao.Parametros('status_ifood_descricao', OrderHead.fullCode);
      conexao.ExecuteSQL;

      if OrderHead.code = 'CAN' then
      begin
        conexao.SQL.Add
          ('update pedido set status = 0 where id_ifood = :id_ifood');
        conexao.Parametros('id_ifood', OrderId);
        conexao.ExecuteSQL;
      end;

      if OrderHead.code = 'CON' then
      begin
        conexao.SQL.Add
          ('update pedido set status = 6 where id_ifood = :id_ifood');
        conexao.Parametros('id_ifood', OrderId);
        conexao.ExecuteSQL;
      end;

      if OrderHead.code = 'CFM' then
      begin
        conexao.SQL.Add
          ('update pedido set status = 2 where id_ifood = :id_ifood');
        conexao.Parametros('id_ifood', OrderId);
        conexao.ExecuteSQL;

        conexao.SQL.Add
          ('select count(*) as tot, 0 as zero from impressao_pedido where id_pedido = :id_pedido ');
        conexao.Parametros('id_pedido', CodigoIntermo);
        try
          Codigo := conexao.FieldByName('tot');
        except
          Codigo := 0;
        end;

        if Codigo = 0 then
        begin
          Codigo := conexao.GerarID('impressao_pedido', 'id');
          conexao.SQL.Add
            ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
          conexao.Parametros('id', CodigoCliente);
          conexao.Parametros('pedido', CodigoIntermo);
          conexao.ExecuteSQL;
        end;
      end;
    end;

    conexao.Free;
    dataSetOrders.Free;
    dataSetOrderItems.Free;
    dataSetOrderPayments.Free;
    dataSetOrderSubItems.Free;
    dataSetOrderBenefits.Free;
  end;
end;

procedure TProcessamentoiFood.SalvarTextoEmArquivo(const Texto,
  NomeArquivo: string);
var
  Arquivo: TextFile;
begin
  try
    AssignFile(Arquivo, NomeArquivo);
    Rewrite(Arquivo);
    Write(Arquivo, Texto);
    CloseFile(Arquivo);
  except
    on E: Exception do
    begin
      // Exibir mensagem de erro ou tratar de acordo com a necessidade
      // showmessage1('Erro ao salvar o arquivo: ' + E.Message);

    end;
  end;
end;

function TProcessamentoiFood.StatusPedidoiFood: Integer;
begin
  try
    Result := StatusiFood;
  except
    Result := 0;
  end;
end;

procedure TProcessamentoiFood.TestImport;
begin
  Processamento(nil, nil);
end;

procedure TProcessamentoiFood.Execute;
// var
// code: string;
// begin
// while not Terminated do
// begin
// FLock.Enter;
// try
// if FQueue.Count > 0 then
// begin
// code := FQueue.Dequeue;
// Processamento(code);
// end;
// finally
// FLock.Leave;
// end;
// Sleep(100); // Evitar consumo excessivo de CPU
// end;
// end;
var
  OrderPair: TPair<IADRIFoodModelOrder, IADRIFoodModelOrderHead>;
begin
  while not Terminated do
  begin
  LogThread('ifood','Iniciando');
    FLock.Enter;
    try
      if FQueue.Count > 0 then
      begin
        OrderPair := FQueue.Dequeue;
        // Processar o pedido aqui
        // Exemplo de processamento:
        // Exibir os detalhes do pedido em uma MessageBox
        // //showmessage1('Detalhes do pedido: ' + OrderPair.Key.OrderDetails);
        // //showmessage1('Cliente: ' + OrderPair.Value.CustomerName);
        Processamento(OrderPair.Key, OrderPair.Value);
        LogThread('ifood','Processando');
      end;
    finally
      FLock.Leave;
    end;
    Sleep(100); // Evitar consumo excessivo de CPU
  end;
end;

function TProcessamentoiFood.LerConteudoArquivo(const CaminhoArquivo
  : string): string;
var
  Arquivo: TextFile;
  Linha: string;
  Conteudo: TStringList;
begin
  Conteudo := TStringList.Create;
  try
    AssignFile(Arquivo, CaminhoArquivo);
    Reset(Arquivo);
    try
      while not Eof(Arquivo) do
      begin
        Readln(Arquivo, Linha);
        Conteudo.Add(Linha);
      end;
    finally
      CloseFile(Arquivo);
    end;
    Result := Conteudo.Text;
  finally
    Conteudo.Free;
  end;
end;

end.
