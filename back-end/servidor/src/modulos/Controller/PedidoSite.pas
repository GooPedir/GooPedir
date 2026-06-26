unit PedidoSite;

interface

uses JOSE.Types.JSON, conexao, DataSet.Serialize;

function ClientePedido(JSON: TJSONObject): TJSONObject;
function PagamentoPedido(JSON: TJSONObject): TJSONObject;
function ClienteEnderecoPedido(JSON: TJSONObject; Cliente: Integer)
  : TJSONObject;
function GerarPedidoSite(Pedido: Integer; Cliente, Endereco, FormaPagamento,
  Valores, Outros: TJSONObject; Produtos: TJSONArray): TJSONObject;

function RetornarCodigoProduto(Produto: TJSONObject): Integer;

procedure ProcessarProdutosSite(Pedido: Integer; Produtos: TJSONArray);

function ValidaSeProdutoJaLancado(Produto: TJSONObject): Boolean;

procedure Imprimir(Pedido: Integer);

implementation

uses
  System.SysUtils, uMain, FireDAC.Comp.Client;

function ClientePedido(JSON: TJSONObject): TJSONObject;
var
  conexao: TConexao;
  Cliente: Integer;
begin
  conexao := TConexao.Create('PedidoSite');
  conexao.SQL.Add
    ('select * from cliente where (celular = :celular or celular_wpp = :celular or cpf = :cpf or upper(nome) = upper(:nome)) limit 1');
  conexao.Parametros('celular', JSON.GetValue('celular').Value);
  conexao.Parametros('cpf', JSON.GetValue('cpf').Value);
  conexao.Parametros('nome', (JSON.GetValue('cliente').Value));
  try
    Cliente := conexao.FieldByName('codigo');
  except
    Cliente := 0;
  end;

  if Cliente = 0 then
  begin
    Cliente := conexao.GerarID('cliente', 'codigo');
    conexao.SQL.Add
      ('insert into cliente (codigo,nome,celular,celular_wpp,ativo,cpf,data_nascimento) values (:codigo,upper(:nome),:celular,:celular_wpp,1,:cpf,curdate())');
    conexao.Parametros('codigo', Cliente);
    conexao.Parametros('nome', JSON.GetValue('cliente').Value);
    conexao.Parametros('celular', JSON.GetValue('celular').Value);
    conexao.Parametros('celular_wpp', JSON.GetValue('celular').Value);
    conexao.Parametros('cpf', JSON.GetValue('cpf').Value);
    conexao.ExecuteSQL;
    // Depois colocar a data de nascimento
  end;

  JSON.AddPair('codigo', Cliente);

  Result := JSON;

  conexao.Free;
end;

function PagamentoPedido(JSON: TJSONObject): TJSONObject;
var
  conexao: TConexao;
  Codigo: Integer;
begin
  Result := JSON;
  conexao := TConexao.Create('PedidoSite');
  conexao.SQL.Add
    ('select * from tipo_pagamento where upper(descricao) = upper(:nome) AND ativo = 1');
  conexao.Parametros('nome', Result.GetValue('descricao').Value);

  try
    Codigo := conexao.FieldByName('codigo');
  except
    Codigo := 0;
  end;

  Result.AddPair('codigo', Codigo);
  conexao.Free;
end;

function ClienteEnderecoPedido(JSON: TJSONObject; Cliente: Integer)
  : TJSONObject;
var
  conexao: TConexao;
  Codigo: Integer;
begin
  Result := JSON;
  try
    if JSON.GetValue('bairro').Value <> '' then
    begin
      exit;
    end;
  except
    exit;

  end;
  conexao := TConexao.Create('PedidoSite');
  conexao.SQL.Add
    ('SELECT * FROM cliente_endereco where codigo_cliente = :cliente and upper(rua) = upper(:rua) and upper(bairro) = upper(:bairro) and upper(cidade) = upper(:cidade) and upper(estado) = upper(:estado)');
  conexao.Parametros('cliente', Cliente);
  conexao.Parametros('rua', JSON.GetValue('rua').Value);
  conexao.Parametros('bairro', JSON.GetValue('bairro').Value);
  conexao.Parametros('cidade', JSON.GetValue('cidade').Value);
  conexao.Parametros('estado', JSON.GetValue('estado').Value);
  try
    Codigo := conexao.FieldByName('codigo');
  except
    Codigo := 0;
  end;

  if Codigo = 0 then
  begin
    Codigo := conexao.GerarID('cliente_endereco', 'codigo');
    conexao.SQL.Add
      ('insert into cliente_endereco (codigo,codigo_cliente,descricao,tipo,numero,rua,bairro,cidade,estado,complemento,ativo) values (:codigo,:cliente,upper(:descricao),1,:numero,upper(:rua),upper(:bairro),upper(:cidade),upper(:estado),upper(:complemento),1)');
    conexao.Parametros('codigo', Codigo);
    conexao.Parametros('cliente', Cliente);
    conexao.Parametros('descricao', 'SITE');
    conexao.Parametros('numero', JSON.GetValue('numero').Value);
    conexao.Parametros('rua', JSON.GetValue('rua').Value);
    conexao.Parametros('bairro', JSON.GetValue('bairro').Value);
    conexao.Parametros('cidade', JSON.GetValue('cidade').Value);
    conexao.Parametros('estado', JSON.GetValue('estado').Value);
    conexao.Parametros('complemento', JSON.GetValue('complemento').Value);
    conexao.ExecuteSQL;
  end;

  conexao.SQL.Add
    ('update cliente_endereco set numero = :numero, complemento = :complemento where codigo = :codigo');
  conexao.Parametros('codigo', Codigo);
  conexao.Parametros('numero', JSON.GetValue('numero').Value);
  conexao.Parametros('complemento', JSON.GetValue('complemento').Value);
  conexao.ExecuteSQL;

  Result.AddPair('codigo', Codigo);
  conexao.Free;
end;

function GerarPedidoSite(Pedido: Integer; Cliente, Endereco, FormaPagamento,
  Valores, Outros: TJSONObject; Produtos: TJSONArray): TJSONObject;
var
  conexao: TConexao;
  CodigoPedido: Integer;
  CodigoEndereco: Integer;
  CodigoDia: Integer;
  Retorno: TJSONObject;
  StatusPedido: Integer;
  DesricaoStatus: String;
begin
  conexao := TConexao.Create('PedidoSite');
  Retorno := TJSONObject.Create;

  case conexao.GetParametro('status_pedidos_site') of
    1:
      begin
        StatusPedido := 1;
      end;
    2:
      begin
        StatusPedido := 2;
      end;
    3:
      begin
        StatusPedido := 3;
      end;
    4:
      begin
        StatusPedido := 9;
      end;
  end;

  // status_pedidos_site

  conexao.SQL.Add('select codigo, 0 as zero from pedido where id_pedido_site = :site');
  conexao.Parametros('site', Pedido);

  try
    CodigoPedido := conexao.FieldByName('codigo');
  except
    CodigoPedido := 0;
  end;

  conexao.SQL.Add('SELECT * FROM status_pedido where id = :id');
  conexao.Parametros('id', StatusPedido);

  try
    DesricaoStatus := conexao.FieldByName('descricao');
  except
    DesricaoStatus := '';
  end;

  try
    CodigoEndereco := strtoInt(Endereco.GetValue('codigo').Value);
  except
    CodigoEndereco := 0;
  end;

  if CodigoPedido = 0 then
  begin
    CodigoPedido := conexao.GerarID('pedido', 'codigo');
    conexao.SQL.Add('insert into pedido (');
    conexao.SQL.Add
      ('codigo,codigo_pedido_dia,codigo_cliente,codigo_cliente_endereco,data_pedido,hora_pedido,status,');
    conexao.SQL.Add
      ('valor_pedido,codigo_cupom,valor_desconto,valor_taxa_entrega,valor_total_pedido,troco,tipo_pagamento,origem,id_pedido_site,impresso_site,wpp_status,partner,cpf,nome');
    conexao.SQL.Add(') values (');
    conexao.SQL.Add(':codigo,:dia,:cliente,:endereco,curdate(),curtime(),-9,');
    conexao.SQL.Add
      (':pedido,0,:desconto,:entrega,:total,:troco,:pagamento,2,:site,0,-9,:partner,:cpf,:nome');
    conexao.SQL.Add(')');
    CodigoDia := frmServidor.GerarCodigoPedidoDia;

    conexao.Parametros('codigo', CodigoPedido);
    conexao.Parametros('dia', CodigoDia);
    conexao.Parametros('cliente', Cliente.GetValue('codigo').Value);
    conexao.Parametros('endereco', CodigoEndereco);
    conexao.Parametros('pedido', Valores.GetValue('produtos').Value);
    conexao.Parametros('desconto', Valores.GetValue('desconto').Value);
    conexao.Parametros('entrega', Valores.GetValue('entrega').Value);
    conexao.Parametros('total', Valores.GetValue('total').Value);
    conexao.Parametros('troco', Valores.GetValue('troco').Value);
    conexao.Parametros('pagamento', FormaPagamento.GetValue('codigo').Value);
    conexao.Parametros('site', Pedido);
    conexao.Parametros('partner', Outros.GetValue('origem').Value);
    conexao.Parametros('cpf', Cliente.GetValue('cpf').Value);
    conexao.Parametros('nome', Cliente.GetValue('cliente').Value);
    conexao.ExecuteSQL;
  end
  else
  begin
    conexao.SQL.Add
      ('select codigo_pedido_dia as codigo, 0 as zero from pedido where id_pedido_site = :site');
    conexao.Parametros('site', Pedido);

    try
      CodigoDia := conexao.FieldByName('codigo');
    except
      CodigoDia := 0;
    end;

  end;

  Retorno.AddPair('id', CodigoPedido);
  Retorno.AddPair('dia', CodigoDia);
  Retorno.AddPair('site', Pedido);
  Retorno.AddPair('statusCode', StatusPedido);
  Retorno.AddPair('statusDescription', DesricaoStatus);

  ProcessarProdutosSite(CodigoPedido, Produtos);

  Imprimir(CodigoPedido);

  conexao.Free;

  Result := Retorno;
end;

procedure ProcessarProdutosSite(Pedido: Integer; Produtos: TJSONArray);
var
  conexao: TConexao;
  Extras: TJSONArray;
  I: Integer;
  Produto: TJSONObject;
  Extra: TJSONObject;
  CodigoProduto: Integer;
  Codigo: Integer;
  CodigoSAP: Integer;
  K: Integer;
  Y: Integer;
  Erro: String;
begin

  conexao := TConexao.Create('PedidoSite');

  for I := 0 to Produtos.Count - 1 do
  begin
    Produto := Produtos.Items[I] as TJSONObject;

    if not(ValidaSeProdutoJaLancado(Produto)) then
    begin
      Extras := TJSONObject.ParseJSONValue(Produto.GetValue('extra').ToString)
        as TJSONArray;

      CodigoProduto := RetornarCodigoProduto(Produto);



      conexao.SQL.Add
        ('insert into pedido_produtos (codigo_pedido,codigo_produto,valor_unitario,quantidade,valor_total,valor_adicional,impresso,hora,vl_delivery,id_site)');
      conexao.SQL.Add
        ('values (:pedido,:produto,:unitario,:quantidade,:total,:adicional,0,current_timestamp(),:delivery,:site)');
      conexao.Parametros('pedido', Pedido);
      conexao.Parametros('produto', CodigoProduto);
      conexao.Parametros('unitario', Produto.GetValue('valorUnitario').Value);
      conexao.Parametros('quantidade', Produto.GetValue('quantidade').Value);
      conexao.Parametros('total', Produto.GetValue('valorTotal').Value);
      conexao.Parametros('site', Produto.GetValue('id').Value);
      conexao.Parametros('adicional', 0);
      conexao.Parametros('delivery', 0);
      conexao.ExecuteSQL;

      CodigoSAP := conexao.GerarID('pedido_produto_sap', 'id');
      conexao.SQL.Add
        ('insert into pedido_produto_sap (id, codigo_pedido_produto, tipo,nomeclatura,descricao,valor)');
      conexao.SQL.Add
        ('values (:id, :produto,:tipo,:nomeclatura,:descricao,:valor)');
      conexao.Parametros('id', CodigoSAP);
      conexao.Parametros('produto', Codigo);
      conexao.Parametros('tipo', 1);
      conexao.Parametros('nomeclatura', 'OBSERVAÇÃO');
      conexao.Parametros('descricao', Produto.GetValue('observacao').Value);
      conexao.Parametros('valor', 0);
      conexao.ExecuteSQL;

      for K := 0 to Extras.Count - 1 do
      begin
        Extra := Extras.Items[K] as TJSONObject;

        for Y := 1 to Extra.GetValue('quantidade').Value.ToInteger do
        begin
          CodigoSAP := conexao.GerarID('pedido_produto_sap', 'id');
          conexao.SQL.Add
            ('insert into pedido_produto_sap (id, codigo_pedido_produto, tipo,nomeclatura,descricao,valor)');
          conexao.SQL.Add
            ('values (:id, :produto,:tipo,:nomeclatura,:descricao,:valor)');
          conexao.Parametros('id', CodigoSAP);
          conexao.Parametros('produto', Codigo);
          conexao.Parametros('tipo', 1);
          conexao.Parametros('nomeclatura', Extra.GetValue('categoria').Value);
          conexao.Parametros('descricao', Extra.GetValue('nome').Value);
          conexao.Parametros('valor', Extra.GetValue('valor').Value);
          conexao.ExecuteSQL;
        end;

      end;

    end;

  end;

  try
    if Assigned(Produto) then
      FreeAndNil(Produto);
  except

  end;
  try
    if Assigned(Extras) then
      FreeAndNil(Extras);
  except

  end;
  try
    if Assigned(Extra) then
      FreeAndNil(Extra);
  except

  end;
  try
    if Assigned(conexao) then
      FreeAndNil(conexao);
  except

  end;

end;

function RetornarCodigoProduto(Produto: TJSONObject): Integer;
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('PedidoSite');

  conexao.SQL.Add('select * from produto where id_site = :site');
  conexao.Parametros('site', Produto.GetValue('idProduto').ToString);

  try
    Result := conexao.FieldByName('codigo');
  except
    Result := 0;
  end;
  conexao.Free;
end;

function ValidaSeProdutoJaLancado(Produto: TJSONObject): Boolean;
var
  conexao: TConexao;
  Codigo: Integer;
begin
  conexao := TConexao.Create('PedidoSite');

  conexao.SQL.Add('select * from pedido_produtos where id_site = :site');
  conexao.Parametros('site', Produto.GetValue('id').Value);

  try
    Codigo := conexao.FieldByName('codigo');
  except
    Codigo := 0;
  end;

  Result := Codigo > 0;

  conexao.Free;
end;

procedure Imprimir(Pedido: Integer);
var
  conexao: TConexao;
  Codigo: Integer;
  Dados: TFDMemTable;
begin

  conexao := TConexao.Create('PedidoSite');
  Dados := TFDMemTable.Create(nil);

  Codigo := conexao.GerarID('impressao_pedido', 'id');

  conexao.SQL.Add
    ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status) values (:id,curdate(),curtime(),:pedido,0)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('pedido', Pedido);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('select * from pedido_produtos where codigo_pedido = :codigo and impresso = 0');
  conexao.Parametros('codigo', Pedido);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      conexao.SQL.Add
        ('update pedido_produtos set impresso = 1 where codigo_pedido = :codigo');
      conexao.Parametros('codigo', Pedido);
      conexao.ExecuteSQL;

      Codigo := conexao.GerarID('impressao_pedido', 'id');
      conexao.SQL.Add
        ('insert into impressao_pedido_produto (id_Pedido_SitePAS,data_solicitacao,hora_solicitacao,id_pedido,status) values (:id,curdate(),curtime(),:pedido,-1)');
      conexao.Parametros('id', Codigo);
      conexao.Parametros('pedido', Dados.FieldByName('codigo').AsString);
      conexao.ExecuteSQL;

      Dados.Next;
    end;
  end;

  conexao.SQL.Add('update pedido set status = 1 where codigo = :codigo');
  conexao.Parametros('codigo', Pedido);
  conexao.ExecuteSQL;

  Dados.Free;
  conexao.Free;

end;

end.
