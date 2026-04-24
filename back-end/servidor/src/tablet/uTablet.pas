unit uTablet;

interface

uses Dialogs, Math, Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils,
  Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao, Web.HTTPApp,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, DateUtils, PedidoSite,
  System.Threading, uControllCaches, System.Generics.Collections,
  uNewConsultas, uControllerSite, GooPedirAPIController, uAtualizacaoSite,
  System.IOUtils, uGlobais, conexao, Xml.XMLDoc, Xml.XMLIntf,
  uControlerProdutoNotaFiscal,
  System.NetEncoding, System.Classes, uImageLocal, System.Variants;

type
  TMenuItem = record
    Id: Integer;
    PaiId: Variant;
    Nome: string;
    ProdutoId: Variant;
    CategoriaId: Variant;
  end;

  TMenuItemList = TList<TMenuItem>;
  TMenuIndex = TObjectDictionary<Variant, TMenuItemList>;

procedure Registry;
function retornarCor(Cor: String): String;

procedure DoGetConfigTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
procedure DoPostImagemTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
procedure DoGetImagemTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

procedure DoChamarGarcom(Req: THorseRequest; Res: THorseResponse; Next: TProc);

procedure DoAlertaSenhaTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

procedure DoMarcarAlertaLido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

procedure DoListarAlertasTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

procedure DoListarAlertasMesaPorUsuario(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

procedure DoValidarGarcom(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure DoSetarGarcomMesa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

procedure DoGetMenuTablet(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure DoPostMenuItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure DoPutMenuItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure DoPutMenuReorder(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
procedure DoDeleteMenuItem(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

procedure DoGetMenuTabletEscalonado(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);

function CriarIndiceMenu(Itens: TFDMemTable): TMenuIndex;

function MontarArvoreMenuIndexada(Indice: TMenuIndex; PaiId: Integer)
  : TJSONArray;

procedure DoGetConsumo(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

procedure Registry;
begin
  THorse.Get('/tablet/config', DoGetConfigTablet);
  THorse.Post('/tablet/imagem', DoPostImagemTablet);
  THorse.Get('/tablet/imagens/:arquivo', DoGetImagemTablet);

  THorse.Post('/alerta/chamar-garcom', DoChamarGarcom);
  THorse.Post('/alerta/senha-tablet', DoAlertaSenhaTablet);
  THorse.Put('/alerta/lido/:id', DoMarcarAlertaLido);
  THorse.Get('/alerta/tablet', DoListarAlertasTablet);
  THorse.Post('/alerta/mesa/usuario', DoListarAlertasMesaPorUsuario);

  THorse.Post('/garcom/validar', DoValidarGarcom);
  THorse.Post('/mesa/setar-garcom', DoSetarGarcomMesa);

  THorse.Get('/tablet/menu', DoGetMenuTablet);
  THorse.Post('/tablet/menu-item', DoPostMenuItem);
  THorse.Put('/tablet/menu-item/:id', DoPutMenuItem);
  THorse.Put('/tablet/menu-reorder', DoPutMenuReorder);
  THorse.Delete('/tablet/menu-item/:id', DoDeleteMenuItem);
  THorse.Get('/cardapio/tablet', DoGetMenuTabletEscalonado);

  THorse.Get('/busca/consumo/:id', DoGetConsumo);

end;

function retornarCor(Cor: String): String;
begin
  Result := StringReplace(Cor, '"', '', [rfReplaceAll]);
  Result := '#' + Result;
end;

procedure DoGetConfigTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  mem: TFDMemTable;
  obj: TJSONObject;
begin
  conexao := TConexao.Create('DoGetConfigTablet');
  obj := TJSONObject.Create;
  mem := TFDMemTable.Create(nil);
  conexao.SQL.Add('select * from dados_whatsapp');
  mem.LoadFromJSON(conexao.ConsultaSQL);
  if mem.RecordCount > 0 then
  begin
    obj.AddPair('nome', mem.FieldByName('nome').AsString);

    obj.AddPair('logo', mem.FieldByName('logo').AsString);
    obj.AddPair('comanda', mem.FieldByName('comanda').AsInteger);
    conexao.SQL.Add
      ('select banner.link, banner.tempo, banner.titulo, banner.subtitulo, banner.produto from banner ');
    conexao.SQL.Add
      ('join painel on painel.id = banner.paineis and painel.tipo = 3');
    conexao.SQL.Add
      ('where link <> "" and dia_semana like concat("%",DAYOFWEEK(curdate()),"%")');
    obj.AddPair('banner', conexao.ConsultaSQL);

    obj.AddPair('corFundo', '#000000');
    obj.AddPair('corFonte', '#ffffff');
    obj.AddPair('corPrincipal', '#a8001c');

  end;

  Res.Send(obj);
  conexao.Free;
  mem.Free;
end;

procedure DoPostImagemTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  JSON: TJSONObject;
  ImgBase64: string;
  Retorno: TJSONObject;
begin
  ImgBase64 := Req.Body;
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  try
    if not JSON.TryGetValue<string>('imagem', ImgBase64) then
    begin
      Res.Status(400).Send('Campo "imagem" não informado');
      Exit;
    end;

    Retorno := SalvarImagemBase64TabletJSON(ImgBase64);

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True))
      .AddPair('dados', Retorno));
  finally
  end;
end;

procedure DoGetImagemTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  FilePath: string;
  Stream: TFileStream;
begin
  FilePath := 'C:\goopedir\tablet\imagens\' + Req.Params['arquivo'];

  if not FileExists(FilePath) then
  begin
    Res.Status(404).Send('Imagem não encontrada');
    Exit;
  end;
  Res.RawWebResponse.CustomHeaders.Values['Content-Disposition'] := 'inline';

  Stream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
  try
    Res.ContentType('image/png');
    Res.Send(Stream);
  except
    Stream.Free;
    raise;
  end;
end;

procedure DoChamarGarcom(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  JSON: TJSONObject;
  MesaId: Integer;
begin
  conexao := TConexao.Create('DoChamarGarcom');
  try
    JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    MesaId := JSON.GetValue<Integer>('mesa_id');

    conexao.SQL.Add('INSERT INTO alerta_sistema ' +
      '(tipo, origem, referencia_id, payload) ' +
      'VALUES (''CHAMAR_GARCOM'', ''MESA'', :mesa, ' +
      'JSON_OBJECT(''mensagem'',''Mesa solicitou atendimento''))');

    conexao.Parametros('mesa', MesaId);
    conexao.ExecuteSQL;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  finally
    conexao.Free;
  end;
end;

procedure DoAlertaSenhaTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  JSON: TJSONObject;
  TabletId: Integer;
begin
  conexao := TConexao.Create('DoAlertaSenhaTablet');
  try
    JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    TabletId := JSON.GetValue<Integer>('tablet_id');

    conexao.SQL.Add('INSERT INTO alerta_sistema ' +
      '(tipo, origem, referencia_id, tentativas, payload) ' +
      'VALUES (''ERRO_SENHA_TABLET'', ''TABLET'', :tablet, 1, ' +
      'JSON_OBJECT(''mensagem'',''Senha incorreta no tablet'')) ' +
      'ON DUPLICATE KEY UPDATE ' +
      'tentativas = tentativas + 1, data_evento = NOW()');

    conexao.Parametros('tablet', TabletId);
    conexao.ExecuteSQL;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  finally
    conexao.Free;
  end;
end;

procedure DoMarcarAlertaLido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  AlertaId: Integer;
begin
  conexao := TConexao.Create('DoMarcarAlertaLido');
  try
    AlertaId := StrToIntDef(Req.Params['id'], 0);

    conexao.SQL.Add('DELETE FROM alerta_sistema WHERE id = :id');

    conexao.Parametros('id', AlertaId);
    conexao.ExecuteSQL;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  finally
    conexao.Free;
  end;
end;

procedure DoListarAlertasTablet(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  mem: TFDMemTable;
begin
  conexao := TConexao.Create('DoListarAlertasTablet');
  mem := TFDMemTable.Create(nil);
  try
    conexao.SQL.Add('SELECT ' +
      'id, tipo, origem, referencia_id, tentativas, payload, data_evento ' +
      'FROM alerta_sistema ' + 'WHERE status = ''ABERTO'' ' +
      'ORDER BY data_evento');

    mem.LoadFromJSON(conexao.ConsultaSQL);

    Res.Send(mem.ToJSONArray);
  finally
    mem.Free;
    conexao.Free;
  end;
end;

procedure DoListarAlertasMesaPorUsuario(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  mem: TFDMemTable;
  JSON: TJSONObject;
  CodigoUsuario: string;
begin
  conexao := TConexao.Create('DoListarAlertasMesaPorUsuario');
  mem := TFDMemTable.Create(nil);
  try
    JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    CodigoUsuario := JSON.GetValue<string>('codigo_usuario');

    conexao.SQL.Add('SELECT ' + ' a.id AS alerta_id, ' +
      ' a.data_evento AS data_evento, ' + ' a.payload AS payload, ' +
      ' m.id_mesa AS mesa_id, ' + ' CASE ' +
      '   WHEN COALESCE(m.descricao, '''') <> '''' ' + '   THEN m.descricao ' +
      '   ELSE CONCAT(mt.descricao, '' '', m.nr_mesa) ' + ' END AS mesa_nome ' +
      'FROM alerta_sistema a ' + 'JOIN mesa m ON m.id_mesa = a.referencia_id ' +
      'JOIN mesa_tipo mt ON mt.id_mesa_tipo = m.fk_tipo_mesa ' +
      'WHERE a.tipo = ''CHAMAR_GARCOM'' ' + '  AND a.status = ''ABERTO'' ' +
      '  AND m.usuario = :usuario ' + 'ORDER BY a.data_evento');

    conexao.Parametros('usuario', CodigoUsuario);

    mem.LoadFromJSON(conexao.ConsultaSQL);

    Res.Send(mem.ToJSONArray);
  finally
    mem.Free;
    conexao.Free;
  end;
end;

procedure DoValidarGarcom(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  JSON: TJSONObject;
  Codigo: Integer;
  Garcom: Integer;
  Nome: String;
  dados: TFDMemTable;
begin
  conexao := TConexao.Create('DoValidarGarcom');
  try
    JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    dados := TFDMemTable.Create(nil);
    conexao.SQL.Add
      ('SELECT codigo, nome, garcom FROM usuario WHERE senha = md5(:senha)');

    conexao.Parametros('senha', JSON.GetValue<string>('senha'));
    dados.LoadFromJSON(conexao.ConsultaSQL);
    try
      Codigo := dados.FieldByName('codigo').AsInteger;
      Nome := dados.FieldByName('nome').AsString;
      Garcom := dados.FieldByName('garcom').AsInteger;
      dados.Free;
    except
      dados.Free;
      Res.Status(401).Send(TJSONObject.Create.AddPair('valido',
        TJSONBool.Create(False)).AddPair('mensagem', 'Senha inválida'));
      Exit;
    end;

    if Garcom <> 1 then
    begin
      Res.Status(403).Send(TJSONObject.Create.AddPair('valido',
        TJSONBool.Create(False)).AddPair('mensagem', 'Usuário não é garçom'));
      Exit;
    end;

    Res.Send(TJSONObject.Create.AddPair('valido', TJSONBool.Create(True))
      .AddPair('codigo', Codigo).AddPair('nome', Nome));
  finally
    conexao.Free;
  end;
end;

procedure DoSetarGarcomMesa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  JSON: TJSONObject;
  Usuario: Integer;
  Mesa: Integer;
begin
  conexao := TConexao.Create('DoSetarGarcomMesa');
  try
    JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;

    Usuario := JSON.GetValue<Integer>('usuario');
    Mesa := JSON.GetValue<Integer>('mesa');

    conexao.SQL.Add('UPDATE mesa ' + 'SET usuario = :usuario, hora = NOW() ' +
      'WHERE id_mesa = :mesa');

    conexao.Parametros('usuario', Usuario);
    conexao.Parametros('mesa', Mesa);

    conexao.ExecuteSQL;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  finally
    conexao.Free;
  end;
end;

procedure DoGetMenuTablet(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Menu, Itens: TFDMemTable;
  Retorno: TJSONObject;
begin
  conexao := TConexao.Create('DoGetMenuTablet');
  Menu := TFDMemTable.Create(nil);
  Itens := TFDMemTable.Create(nil);
  Retorno := TJSONObject.Create;
  try
    // Menu
    conexao.SQL.Add
      ('SELECT id, nome, tipo FROM menu WHERE tipo = ''tablet'' AND ativo = 1');
    Menu.LoadFromJSON(conexao.ConsultaSQL);

    if Menu.RecordCount = 0 then
    begin
      Res.Status(404).Send('Menu tablet não encontrado');
      Exit;
    end;

    // Itens
    conexao.SQL.Clear;
    conexao.SQL.Add('SELECT id, nome, pai_id AS paiId, ordem, background_link,'
      + 'produto_id AS produtoId, categoria_id AS categoriaId, ativo ' +
      'FROM menu_item WHERE menu_id = :menu AND ativo = 1 ' +
      'ORDER BY pai_id, ordem');
    conexao.Parametros('menu', Menu.FieldByName('id').AsInteger);
    Itens.LoadFromJSON(conexao.ConsultaSQL);

    Retorno.AddPair('menu', Menu.ToJSONObject);
    Retorno.AddPair('items', Itens.ToJSONArray);

    Res.Send(Retorno);
  finally
    Menu.Free;
    Itens.Free;
    conexao.Free;
  end;
end;

procedure DoPostMenuItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  JSON: TJSONObject;
begin
  conexao := TConexao.Create('DoPostMenuItem');
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  try
    conexao.SQL.Add('INSERT INTO menu_item ' +
      '(menu_id, nome, pai_id, ordem, produto_id, categoria_id, ativo,background_link) '
      + 'VALUES (:menu, :nome, :pai, :ordem, :produto, :categoria, :ativo,:background_link)');

    conexao.Parametros('menu', JSON.GetValue<Integer>('menuId', 0));
    conexao.Parametros('nome', JSON.GetValue<string>('nome'));
    conexao.Parametros('background_link',
      JSON.GetValue<string>('background_link'));
    conexao.Parametros('pai', JSONIntOrNull(JSON, 'paiId'));
    conexao.Parametros('ordem', JSON.GetValue<Integer>('ordem', 0));
    conexao.Parametros('produto', JSONIntOrNull(JSON, 'produtoId'));
    conexao.Parametros('categoria', JSONIntOrNull(JSON, 'categoriaId'));
    conexao.Parametros('ativo', JSON.GetValue<Boolean>('ativo'));

    conexao.ExecuteSQL;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  except
    on e: exception do
    begin
      /// /showmessage(e.Message);
    end;
  end;
  conexao.Free;
end;

procedure DoPutMenuItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  JSON: TJSONObject;
begin
  conexao := TConexao.Create('DoPutMenuItem');
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  try
    conexao.SQL.Add('UPDATE menu_item SET ' +
      'nome = :nome, pai_id = :pai, background_link = :background_link, ordem = :ordem, ativo = :ativo '
      + 'WHERE id = :id');

    conexao.Parametros('id', Req.Params['id']);
    conexao.Parametros('nome', JSON.GetValue<string>('nome'));
    conexao.Parametros('background_link',
      JSON.GetValue<string>('background_link'));
    conexao.Parametros('pai', JSON.GetValue<Integer>('paiId', 0));
    conexao.Parametros('ordem', JSON.GetValue<Integer>('ordem', 0));
    conexao.Parametros('ativo', JSON.GetValue<Boolean>('ativo'));

    conexao.ExecuteSQL;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  finally
    conexao.Free;
  end;
end;

procedure DoPutMenuReorder(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  JSON: TJSONObject;
  Itens: TJSONArray;
  I: Integer;
begin
  conexao := TConexao.Create('DoPutMenuReorder');
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  try
    Itens := JSON.GetValue<TJSONArray>('itens');

    for I := 0 to Itens.Count - 1 do
    begin
      conexao.SQL.Clear;
      conexao.SQL.Add
        ('UPDATE menu_item SET pai_id = :pai, ordem = :ordem WHERE id = :id');

      conexao.Parametros('id', Itens.Items[I].GetValue<Integer>('id'));
      conexao.Parametros('pai', Itens.Items[I].GetValue<Integer>('paiId', 0));
      conexao.Parametros('ordem', Itens.Items[I].GetValue<Integer>('ordem'));

      conexao.ExecuteSQL;
    end;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  finally
    conexao.Free;
  end;
end;

procedure DoDeleteMenuItem(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  mem: TFDMemTable;
begin
  conexao := TConexao.Create('DoDeleteMenuItem');
  mem := TFDMemTable.Create(nil);
  try
    // Verifica filhos
    conexao.SQL.Add('SELECT id FROM menu_item WHERE pai_id = :id');
    conexao.Parametros('id', Req.Params['id']);
    mem.LoadFromJSON(conexao.ConsultaSQL);

    if mem.RecordCount > 0 then
    begin
      Res.Status(409).Send(TJSONObject.Create.AddPair('error',
        'ITEM_HAS_CHILDREN'));
      Exit;
    end;

    conexao.SQL.Clear;
    conexao.SQL.Add('DELETE FROM menu_item WHERE id = :id');
    conexao.Parametros('id', Req.Params['id']);
    conexao.ExecuteSQL;

    Res.Send(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)));
  finally
    mem.Free;
    conexao.Free;
  end;
end;

procedure DoGetConsumo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Produtos: TJSONArray;
  Produto: TJSONObject;
  conexao: TConexao;
  Pedido: Integer;
  dados: TFDMemTable;
begin
  conexao := TConexao.Create('DoGetConsumo');
  Produtos := TJSONArray.Create;

  conexao.SQL.Add('select  * from mesa where id_mesa = :id');
  conexao.Parametros('id', Req.Params['id']);
  Pedido := conexao.FieldByName('selecionada');

  if Pedido > 0 then
  begin
    dados := TFDMemTable.Create(nil);
    conexao.SQL.Add('SELECT max(pp.codigo) as id,');
    conexao.SQL.Add('max(p.codigo) as productId,');
    conexao.SQL.Add('p.nome_produto as productName,');
    conexao.SQL.Add('p.valor_venda as productValue,');
    conexao.SQL.Add
      ('GROUP_CONCAT(ppp.descricao ORDER BY CASE WHEN ppp.nomeclatura = "Ingredientes" THEN 0 ELSE 1 END, ppp.nomeclatura SEPARATOR ", ") AS adicionais,');
    conexao.SQL.Add('max(pppO.descricao) as obs,');
    conexao.SQL.Add('pp.quantidade as qtd,');
    conexao.SQL.Add('pp.valor_total as valor');
    conexao.SQL.Add('FROM pedido_produtos as pp');
    conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
    conexao.SQL.Add
      ('left join pedido_produto_sap as ppp on ppp.codigo_pedido_produto = pp.codigo and ppp.nomeclatura not like "%OBSER%" ');
    conexao.SQL.Add
      ('left join pedido_produto_sap as pppO on ppp.codigo_pedido_produto = pp.codigo and ppp.nomeclatura like "%OBSER%" ');
    conexao.SQL.Add('where pp.codigo_pedido = :pedido');
    conexao.SQL.Add
      ('group by p.nome_produto,p.valor_venda, ppp.codigo_pedido_produto,pp.quantidade,pp.valor_total');

    conexao.Parametros('pedido', Pedido);
    dados.LoadFromJSON(conexao.ConsultaSQL);
    if dados.RecordCount > 0 then
    begin
      while not dados.Eof do
      begin
        Produto := TJSONObject.Create;
        Produto.AddPair('id', dados.FieldByName('id').AsInteger);
        Produto.AddPair('productId', dados.FieldByName('productId').AsInteger);
        Produto.AddPair('productName',
          UpperCase(dados.FieldByName('productName').AsString));
        Produto.AddPair('productValue',
          dados.FieldByName('productValue').AsFloat);
        Produto.AddPair('obs', UpperCase(dados.FieldByName('obs').AsString));
        Produto.AddPair('adittion', UpperCase(dados.FieldByName('adicionais')
          .AsString));
        Produto.AddPair('qtd', dados.FieldByName('qtd').AsFloat);
        Produto.AddPair('value', dados.FieldByName('valor').AsFloat);
        Produtos.Add(Produto);
        dados.Next;
      end;
    end;

    dados.Free;
    conexao.Free;

  end;

  Res.Send<TJSONArray>(Produtos);
end;

// procedure DoGetMenuTabletEscalonado(Req: THorseRequest; Res: THorseResponse;
// Next: TProc);
// var
// conexao: TConexao;
// MenuId: Integer;
// Itens: TFDMemTable;
// Retorno: TJSONObject;
// begin
// conexao := TConexao.Create('DoGetMenuTabletEscalonado');
// Itens := TFDMemTable.Create(nil);
// Retorno := TJSONObject.Create;
// try
// // Busca menu tablet
// conexao.SQL.Add
// ('select id, 0 as zero from menu where tipo = ''tablet'' and ativo = 1');
// MenuId := conexao.FieldByName('id');
//
// // Busca itens
// conexao.SQL.Clear;
// conexao.SQL.Add('select id, nome, pai_id, produto_id, categoria_id ' +
// 'from menu_item where menu_id = :menu and ativo = 1 ' +
// 'order by pai_id, ordem');
// conexao.Parametros('menu', MenuId);
//
// Itens.LoadFromJSON(conexao.ConsultaSQL);
//
// // Monta árvore
// Retorno.AddPair('menu', MontarArvoreMenu(Itens, Null));
//
// Res.Send(Retorno);
// finally
// conexao.Free;
// end;
// end;

procedure DoGetMenuTabletEscalonado(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  MenuId: Integer;
  Itens: TFDMemTable;
  Retorno: TJSONObject;
  Indice: TMenuIndex;
begin
  conexao := TConexao.Create('DoGetMenuTabletEscalonado');
  Itens := TFDMemTable.Create(nil);
  Retorno := TJSONObject.Create;
  try
    // 1️⃣ Busca menu tablet
    conexao.SQL.Add
      ('select id, 0 as zero from menu where tipo = ''tablet'' and ativo = 1');

    MenuId := conexao.FieldByName('id');

    // 2️⃣ Busca itens do menu
    conexao.SQL.Clear;
    conexao.SQL.Add('select id, nome, pai_id, produto_id, categoria_id ' +
      'from menu_item ' + 'where menu_id = :menu and ativo = 1 ' +
      'order by pai_id, ordem');
    conexao.Parametros('menu', MenuId);

    Itens.LoadFromJSON(conexao.ConsultaSQL);

    // 3️⃣ Cria índice em memória (🔑 passo crucial)
    Indice := CriarIndiceMenu(Itens);
    try
      // 4️⃣ Monta árvore escalonada
      Retorno.AddPair('menu', MontarArvoreMenuIndexada(Indice, 0));
    except
      on e: exception do
      begin
        Indice.Free;
        /// /showmessage(e.Message)
      end;

    end;

    Res.Send(Retorno);
  finally
    Itens.Free;
    conexao.Free;
  end;
end;

function CriarIndiceMenu(Itens: TFDMemTable): TMenuIndex;
var
  Item: TMenuItem;
  Lista: TMenuItemList;
  Chave: Integer;
begin
  Result := TMenuIndex.Create([doOwnsValues]);

  Itens.First;
  while not Itens.Eof do
  begin
    try
      Item.Id := Itens.FieldByName('id').AsInteger;
    except

    end;

    if Itens.FieldByName('pai_id').Value = 0 then
      Chave := 0
    else
      Chave := Itens.FieldByName('pai_id').AsInteger;

    Item.Nome := Itens.FieldByName('nome').AsString;
    try
      Item.ProdutoId := Itens.FieldByName('produto_id').Value;
    except

    end;
    try
      Item.CategoriaId := Itens.FieldByName('categoria_id').Value;
    except

    end;
    if not Result.TryGetValue(Chave, Lista) then
    begin
      Lista := TMenuItemList.Create;
      Result.Add(Chave, Lista);
    end;

    Lista.Add(Item);
    Itens.Next;
  end;
end;

function MontarArvoreMenuIndexada(Indice: TMenuIndex; PaiId: Integer)
  : TJSONArray;
var
  Arr: TJSONArray;
  Lista: TMenuItemList;
  Item: TMenuItem;
  obj: TJSONObject;
begin
  Arr := TJSONArray.Create;

  if not Indice.TryGetValue(PaiId, Lista) then
    Exit(Arr);

  for Item in Lista do
  begin
    obj := TJSONObject.Create;
    obj.AddPair('id', Item.Id);
    obj.AddPair('nome', Item.Nome);

    if Item.ProdutoId > 0 then
      obj.AddPair('produto', BuscarProdutoPorChave('PRODUTO', Item.ProdutoId))
    else if Item.CategoriaId > 0 then
      obj.AddPair('produtos', BuscarProdutoPorChave('CATEGORIA',
        Item.CategoriaId));

    obj.AddPair('children', MontarArvoreMenuIndexada(Indice, Item.Id));

    Arr.AddElement(obj);
  end;

  Result := Arr;
end;

end.
