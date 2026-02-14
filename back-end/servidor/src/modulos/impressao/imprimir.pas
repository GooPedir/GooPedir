unit imprimir;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, Dialogs, Xml.XMLIntf, Xml.XMLDoc;

procedure Registry;

function AtualizaLetra(Valor: String): String;

implementation

uses
  conexao, uMain, System.IOUtils, System.Classes;

function AtualizaLetra(Valor: String): String;
begin
  result := AnsiUpperCase(Valor);
end;

procedure DoPostImpressaoQrcodPix(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('update qrcod_pix set status = 2 where base64 = :base64');
  conexao.Parametros('base64', Req.Params['pix']);
  conexao.ExecuteSQL;
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetImpressaoQrcodPix(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('select CAST(base64 AS CHAR) as base64, valor from qrcod_pix where status = 1 limit 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.OutrosStatus;
end;

procedure DoGetImpressaoPedidos(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Pedidos: TFDMemTable;
  Codigo: Integer;
  CodigoAnterior: Integer;
begin
  Dados := TFDMemTable.Create(nil);
  Pedidos := TFDMemTable.Create(nil);

  conexao := TConexao.Create('imprimir');
  // conexao.SQL.Add('SELECT ip.* FROM impressao_pedido as ip join pedido as p on p.codigo = ip.id_pedido where ip.status = 0 and ip.id_pedido > 0 ');
  conexao.SQL.Add
    ('SELECT distinct id as ides, ip.*, p.codigo_cliente_endereco, p.pedido_site, TIMESTAMPDIFF(MINUTE, p.hora_pedido, NOW()) AS tempo FROM impressao_pedido as ip');
  conexao.SQL.Add('join pedido as p on p.codigo = ip.id_pedido');
  conexao.SQL.Add('join pedido_produtos as pp on pp.codigo_pedido = p.codigo');

  conexao.SQL.Add
    ('where ip.status = 0 and ip.id_pedido > 0 and pedido_impresso = 0');
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  CodigoAnterior := 0;
  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      if CodigoAnterior <> Dados.FieldByName('id_pedido').AsInteger then
      begin
        if Dados.FieldByName('codigo_cliente_endereco').AsInteger > 0 then
        begin

          if Dados.FieldByName('pedido_site').AsString = '' then
          begin
            Dados.Edit;
            Dados.FieldByName('pedido_site').AsFloat := 0;
          end;

          if Dados.FieldByName('pedido_site').AsInteger > 0 then
          begin
            Dados.Next;
          end
          else
          begin
            //
            if Dados.FieldByName('tempo').AsInteger > 5 then
            begin
              Dados.Next;
            end
            else
            begin
              Dados.Delete;
            end;
          end;

        end
        else
        begin
          Dados.Next;
        end;
        CodigoAnterior := Dados.FieldByName('id_pedido').AsInteger;
      end
      else
      begin
        conexao.SQL.Add('delete from impressao_pedido where id = :id');
        conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
        conexao.ExecuteSQL;
        Dados.Delete;
        CodigoAnterior := 0;
      end;

    end;

  end;

  Res.Send<TJSONArray>(Dados.ToJSONArray());

  frmServidor.ImpressoraStatus;
  frmServidor.ComandaStatus;

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      Pedidos.Close;
      conexao.SQL.Add('');
      conexao.SQL.Add('select pp.* from pedido as p');
      conexao.SQL.Add
        ('join pedido_produtos as pp on pp.codigo_pedido = p.codigo');
      conexao.SQL.Add('where p.codigo = :pedido and impresso = 0');
      conexao.Parametros('pedido', Dados.FieldByName('id_pedido').AsInteger);
      Pedidos.LoadFromJSON(conexao.ConsultaSQL);
      if Pedidos.RecordCount > 0 then
      begin
        while not Pedidos.Eof do
        begin
          conexao.SQL.Add
            ('select * from impressao_pedido_produto where id_pedido = :pedido');
          conexao.Parametros('pedido', Pedidos.FieldByName('codigo').AsInteger);
          Codigo := conexao.FieldByName('id');
          if Codigo = 0 then
          begin
            conexao.SQL.Add
              ('insert into impressao_pedido_produto (id_pedido,status,vias,usuario,data_solicitacao,hora_solicitacao) values (:pedido,0,0,-2,curdate(),curtime())');
            conexao.Parametros('pedido', Pedidos.FieldByName('codigo')
              .AsInteger);
            conexao.ExecuteSQL;
          end
          else
          begin
            conexao.SQL.Add
              ('update impressao_pedido_produto set status = 0 where id = ' +
              Codigo.toString);
            conexao.ExecuteSQL;
          end;
          Pedidos.Next;
        end;
      end;
      Dados.Next;
    end;

  end;
  Dados.Free;
  Pedidos.Free;
  conexao.Free;
end;

procedure DoGetImpressaoPadrao(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('SELECT * FROM impressoras where impressora_padrao = 1 and ativo = 1 limit 1');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetImpressaoPedidosCozinhaPedido(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  // conexao := TConexao.Create('imprimir');
  // // conexao.SQL.Add('SELECT * FROM impressao_pedido where status = 0 and id_pedido > 0');
  //
  // conexao.SQL.Add('SELECT 0 as zero, group_concat(distinct  ipp.id_pedido) as grupo, (select nome from usuario where codigo = ipp.usuario) as usuario');
  // conexao.SQL.Add('FROM impressao_pedido_produto as ipp');
  // conexao.SQL.Add('join pedido_produtos as pp on pp.codigo = ipp.id_pedido');
  // conexao.SQL.Add('join pedido as ped on ped.codigo = pp.codigo_pedido');
  // conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  // conexao.SQL.Add('join tipo_produto as tp on tp.codigo = p.codigo_grupo');
  // conexao.SQL.Add('left join usuario as u on u.codigo = pp.usuario');
  // conexao.SQL.Add('join impressoras as i on i.codigo = tp.impressora');
  // if frmServidor.Configuracoes.FieldByName('cozinha_apenas_mesa').AsInteger > 0
  // then
  // begin
  // conexao.SQL.Add
  // ('join pedido on pedido.codigo = pp.codigo_pedido and pedido.id_ficha > 0');
  // end;
  // conexao.SQL.Add
  // ('where (ped.codigo_pedido_dia = 0 and ipp.status = 0) OR (ped.codigo_pedido_dia > 0 AND (ped.id_ficha IS NULL or ped.id_ficha = 0)  and ipp.status = 0)   OR (ped.codigo_pedido_dia = 0 AND ped.id_ficha > 0 and ipp.status = 0)');
  // conexao.SQL.Add(' and pp.codigo_pedido = :codigo');
  //
  // try
  // if frmServidor.Configuracoes.FieldByName('impressao_agrupada').AsInteger = 1
  // then
  // begin
  // conexao.SQL.Add
  // ('group by pp.codigo_pedido,i.codigo,i.codigo,ipp.usuario');
  // end
  // else
  // begin
  // conexao.SQL.Add('group by pp.codigo_pedido,ipp.usuario');
  // end;
  // except
  // end;
  // conexao.Parametros('codigo', Req.Params['codigo']);
  //
  // Res.Send<TJSONArray>(conexao.ConsultaSQL);
  // conexao.Free;
  // frmServidor.ImpressoraStatus;
  conexao := TConexao.Create('imprimir');

  conexao.SQL.Add('SELECT');
  conexao.SQL.Add('  0 AS zero,');
  conexao.SQL.Add('  GROUP_CONCAT(DISTINCT ipp.id_pedido) AS grupo,');
  conexao.SQL.Add('  max(u.nome) AS usuario,');
  conexao.SQL.Add('  max(i.codigo) AS impressora_codigo,');
  conexao.SQL.Add('  max(i.descricao)   AS impressora_nome');
  conexao.SQL.Add('FROM impressao_pedido_produto AS ipp');
  conexao.SQL.Add
    ('JOIN pedido_produtos AS pp   ON pp.codigo         = ipp.id_pedido');
  conexao.SQL.Add
    ('JOIN pedido          AS ped  ON ped.codigo        = pp.codigo_pedido');
  conexao.SQL.Add
    ('JOIN produto         AS p    ON p.codigo          = pp.codigo_produto');
  conexao.SQL.Add
    ('JOIN tipo_produto    AS tp   ON tp.codigo         = p.codigo_grupo');
  conexao.SQL.Add
    ('LEFT JOIN usuario    AS u    ON u.codigo          = pp.usuario');

  /// * 🔽 AQUI ESTÁ A MÁGICA DO FALLBACK:
  // Usa a impressora do usuário (se > 0), senão a da categoria (tp.impressora) */
  conexao.SQL.Add
    ('JOIN impressoras AS i ON i.codigo = COALESCE(NULLIF(u.impressora, 0), tp.impressora)');

  if frmServidor.Configuracoes.FieldByName('cozinha_apenas_mesa').AsInteger > 0
  then
  begin
    conexao.SQL.Add
      ('JOIN pedido ON pedido.codigo = pp.codigo_pedido AND pedido.id_ficha > 0');
  end;

  conexao.SQL.Add('WHERE (ped.codigo_pedido_dia = 0 AND ipp.status = 0)');
  conexao.SQL.Add
    ('   OR (ped.codigo_pedido_dia > 0 AND (ped.id_ficha IS NULL OR ped.id_ficha = 0) AND ipp.status = 0)');
  conexao.SQL.Add
    ('   OR (ped.codigo_pedido_dia = 0 AND ped.id_ficha > 0 AND ipp.status = 0)');
  conexao.SQL.Add('  AND pp.codigo_pedido = :codigo');

  try
    if frmServidor.Configuracoes.FieldByName('impressao_agrupada').AsInteger = 1
    then
    begin
      // Agrupa por pedido + impressora + usuário (mantive i.codigo uma única vez)
      conexao.SQL.Add('GROUP BY pp.codigo_pedido, i.codigo, ipp.usuario');
    end
    else
    begin
      conexao.SQL.Add('GROUP BY pp.codigo_pedido, ipp.usuario');
    end;
  except
  end;

  conexao.Parametros('codigo', Req.Params['codigo']);

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;

end;

procedure DoGetImpressaoPedidosCozinha(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  frmServidor.ReProcessaImpressaoPedidoProduto(conexao);

  // conexao.SQL.Add('SELECT * FROM impressao_pedido where status = 0 and id_pedido > 0');

  conexao.SQL.Add
    ('SELECT 0 as zero, group_concat(distinct ipp.id_pedido) as grupo, concat("(",upper(max(i.descricao)),") ",max(u.nome)) as usuario');
  conexao.SQL.Add('FROM impressao_pedido_produto as ipp');
  conexao.SQL.Add('join pedido_produtos as pp on pp.codigo = ipp.id_pedido');
  if frmServidor.Configuracoes.FieldByName('cozinha_apenas_mesa').AsInteger > 0
  then
  begin
    conexao.SQL.Add
      ('join pedido as ped on ped.codigo = pp.codigo_pedido and ped.id_ficha > 0');
  end
  else
  begin
    conexao.SQL.Add
      ('join pedido as ped on ped.codigo = pp.codigo_pedido and (ped.codigo_pedido_dia > 0 or ped.id_ficha)');
    // conexao.SQL.Add('join pedido as ped on ped.codigo = pp.codigo_pedido and (ped.id_ficha)');
    // conexao.SQL.Add('join pedido as ped on ped.codigo = pp.codigo_pedido and (ped.codigo_pedido_dia > 0 or ped.id_ficha)');
  end;

  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  conexao.SQL.Add('join tipo_produto as tp on tp.codigo = p.codigo_grupo');
  conexao.SQL.Add('left join usuario as u on u.codigo = pp.usuario');
  conexao.SQL.Add
    ('join impressoras as i on i.codigo = COALESCE(NULLIF(u.impressora, 0), tp.impressora) ');
  conexao.SQL.Add('where (ipp.status = 0) ');
  // conexao.SQL.Add('where (ipp.status = 0 and (ped.codigo_pedido_dia > 0 or ped.id_ficha))');
  // if frmServidor.Configuracoes.FieldByName('cozinha_apenas_mesa').AsInteger > 0 then
  // begin
  // //conexao.SQL.Add('join pedido on pedido.codigo = pp.codigo_pedido');
  // conexao.SQL.Add('and ped.id_ficha > 0');
  // end;
  // // conexao.SQL.Add('where ipp.status = 0');

  try
    if frmServidor.Configuracoes.FieldByName('impressao_agrupada').AsInteger = 1
    then
    begin
      conexao.SQL.Add
        ('group by pp.codigo_pedido,i.codigo,i.codigo,ipp.usuario');
    end
    else
    begin
      conexao.SQL.Add('group by pp.codigo_pedido,ipp.usuario');
    end;
  except
  end;

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;
  frmServidor.CozinhaStatus;
end;

procedure DoGetImpressaoPedidosCozinhaCodigo(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Memory: TFDMemTable;
begin
  conexao := TConexao.Create('imprimir');
  Memory := TFDMemTable.Create(nil);
  conexao.SQL.Add('SELECT ');
  conexao.SQL.Add('CASE ');
  conexao.SQL.Add(' when ped.id_ficha > 0 then ped.desc_ficha');
  conexao.SQL.Add
    (' else CONCAT(IF(ped.codigo_cliente_endereco > 0, "Delivery ", "Retirada "),ped.codigo_pedido_dia)');
  conexao.SQL.Add('END as origem_pedido,');
  conexao.SQL.Add('CASE ');
  conexao.SQL.Add(' when ped.origem = 1 then ');
  conexao.SQL.Add
    (' CONCAT(''WHATSAPP '','' '',(select nome from usuario where codigo = case when pp.usuario > 0 then pp.usuario else (select codigo from usuario limit 1) end limit 1))');
  conexao.SQL.Add(' when ped.origem = 2 then ');
  conexao.SQL.Add
    (' CONCAT(''SITE '','' '',(select nome from usuario where codigo = case when pp.usuario > 0 then pp.usuario else (select codigo from usuario limit 1) end limit 1))');
  conexao.SQL.Add(' when ped.origem = 3 then ');
  conexao.SQL.Add
    (' CONCAT(''APP '','' '',(select nome from usuario where codigo = case when pp.usuario > 0 then pp.usuario else (select codigo from usuario limit 1) end limit 1))');
  conexao.SQL.Add(' else "ORIGEM OUTROS"');
  conexao.SQL.Add('END as origem_local, ');
  conexao.SQL.Add
    ('DATE_FORMAT(current_timestamp(), "%d/%m/%Y %H:%i") AS data_impressao,');
  conexao.SQL.Add('pp.codigo,');
  conexao.SQL.Add('pp.valor_unitario as vl_unitario,');
  conexao.SQL.Add('pp.quantidade as qtd,');
  conexao.SQL.Add('pp.valor_total as vl_total,');
  conexao.SQL.Add('p.codigo_interno as codigo_produto,');
  if frmServidor.Configuracoes.FieldByName('oculta_categoria').AsInteger = 1
  then
  begin
    conexao.SQL.Add('"" as categoria,');
  end
  else
  begin
    conexao.SQL.Add('tp.descricao as categoria,');
  end;
  conexao.SQL.Add('CASE');
  conexao.SQL.Add(' WHEN c.nome = ' + QuotedStr('BALCÃO'));
  conexao.SQL.Add(' THEN ped.nome');
  conexao.SQL.Add(' ELSE c.nome');
  conexao.SQL.Add('END as nome,');
  conexao.SQL.Add
    ('p.nome_produto as produto,  c.celular, case  when ped.codigo_cliente_endereco = 0 then "Vem Buscar" else "Delivery" end as tipo,');
  conexao.SQL.Add('    TIME_FORMAT(ped.hora_pedido, "%H:%i") as hora_pedido,');
  conexao.SQL.Add
    ('     DATE_FORMAT(ped.data_pedido, "%d/%m/%Y") as data_pedido,');
  conexao.SQL.Add('upper(pps.nomeclatura) as nomeclatura,ped.origem, ');
  conexao.SQL.Add('upper(pps.descricao) as descricao,');
  conexao.SQL.Add('pps.id as iddescricao,');
  conexao.SQL.Add('sum(pps.valor) as vl_adicional,');
  conexao.SQL.Add
    ('(select descricao from mesa where id_mesa = ped.id_ficha) as mesa,');
  // conexao.SQL.Add('max(imp.driver) as driver,');
  // conexao.SQL.Add('max(imp.tipo_impressao) as tipoimp,');
  // conexao.SQL.Add('upper(imp.descricao) as impressora');
  conexao.SQL.Add
    ('(select driver from impressoras where codigo = COALESCE(NULLIF(usu.impressora, 0), tp.impressora) )as driver,');
  conexao.SQL.Add
    ('(select tipo_impressao from impressoras where codigo = COALESCE(NULLIF(usu.impressora, 0), tp.impressora) )as tipoimp,');
  conexao.SQL.Add
    ('(select descricao from impressoras where codigo = COALESCE(NULLIF(usu.impressora, 0), tp.impressora) )as impressora');
  conexao.SQL.Add('FROM pedido_produtos as pp');
  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  conexao.SQL.Add
    ('left join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp.codigo');
  conexao.SQL.Add('left join pedido as ped on ped.codigo = pp.codigo_pedido');
  conexao.SQL.Add('left join tipo_produto as tp on tp.codigo = p.codigo_grupo');
  conexao.SQL.Add('left join usuario as usu on usu.codigo = pp.usuario');
  conexao.SQL.Add
    ('left join impressoras as imp on tp.codigo = COALESCE(NULLIF(usu.impressora, 0), tp.impressora)  ');
  conexao.SQL.Add('left join cliente as c on c.codigo = ped.codigo_cliente');
  conexao.SQL.Add('where pp.codigo in (' + Req.Params['codigo'] + ')');
  conexao.SQL.Add('GROUP BY');
  conexao.SQL.Add
    ('origem_pedido, origem_local, data_impressao, pp.codigo, pp.valor_unitario, pp.quantidade, pp.valor_total,');
  conexao.SQL.Add
    ('p.codigo_interno, p.nome_produto, c.nome,  c.celular, tipo, hora_pedido, data_pedido, pps.nomeclatura, pps.id, pps.descricao,');
  conexao.SQL.Add('ped.origem, mesa, ped.nome, ped.codigo_cliente_endereco');
  conexao.SQL.Add('order by pp.codigo, pps.nomeclatura');

  Memory.LoadFromJSON(conexao.ConsultaSQL);

  if Memory.RecordCount > 0 then
  begin
    while not Memory.Eof do
    begin

      if Memory.FieldByName('nomeclatura').AsString = 'SABORES' then
      begin
        Memory.Edit;
        Memory.FieldByName('descricao').AsString :=
          AtualizaLetra(Memory.FieldByName('descricao').AsString);
        Memory.FieldByName('nomeclatura').AsString :=
          AtualizaLetra(Memory.FieldByName('nomeclatura').AsString);
        Memory.FieldByName('descricao').AsString :=
          StringReplace(Memory.FieldByName('descricao').AsString, ' 1/1 -', '',
          [rfReplaceAll]);
        Memory.FieldByName('descricao').AsString :=
          StringReplace(Memory.FieldByName('descricao').AsString, '1/1 - ', '',
          [rfReplaceAll]);
        Memory.FieldByName('descricao').AsString :=
          AnsiUpperCase(Memory.FieldByName('descricao').AsString);
      end;
      Memory.Next;

    end;
  end;

  Res.Send<TJSONArray>(Memory.ToJSONArray());
  conexao.Free;
  Memory.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetImpressaoCaixa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  frmServidor.OutrosStatus;
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('SELECT * FROM impressao_caixa where status = 0 and id_Caixa > 0');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetImpressaoPedidosNFCE(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('select impressao_pedido_nfce.*,pedido_nfce.*, i.driver from impressao_pedido_nfce');
  conexao.SQL.Add
    ('join pedido_nfce on pedido_nfce.id_pedido = impressao_pedido_nfce.id_pedido');
  conexao.SQL.Add('join pedido as p on p.codigo = pedido_nfce.id_pedido');
  conexao.SQL.Add('join caixa as c on c.id = p.id_caixa');
  conexao.SQL.Add('join usuario as u on u.codigo = c.id_usuario');
  conexao.SQL.Add('left join impressoras as i on i.codigo = u.impressora');
  conexao.SQL.Add('where impressao_pedido_nfce.status = 0');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
end;

procedure DoGetXmlNfce(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Conteudo: TStringList;
  ireq: iRequisicao;
begin
  conexao := TConexao.Create('DoGetXmlNfce');
  conexao.SQL.Add('select * from pedido_nfce where chave = :chave');
  conexao.Parametros('chave', Req.Params['chave']);
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  Res.ContentType('application/xml');

  if FileExists(Dados.FieldByName('caminho').AsString) then
  begin
    // Lê o conteúdo do arquivo XML

    try
      Conteudo.LoadFromFile(Dados.FieldByName('caminho').AsString,
        TEncoding.UTF8);
      Conteudo := TStringList.Create;
      Res.Send(Conteudo.Text);
    finally
      Conteudo.Free;
    end;
  end
  else
  begin
    ireq := iRequisicao.Create(nil);
    ireq.BaseURL := Dados.FieldByName('caminho').AsString;
    try
      ireq.Execute;
      Res.Send(ireq.Retorno);
    except

    end;

  end;

  Dados.Free;
  conexao.Free;

end;

procedure DoPostPedidoNFCe(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('update impressao_pedido_nfce set status = 1, impressao = current_timestamp() where id_pedido = :pedido');
  conexao.Parametros('pedido', Req.Params['codigo']);
  conexao.ExecuteSQL;
  conexao.Free;
end;

procedure DoGetImpressaoPedidoNFCe(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  JsonObject: TJSONObject;
begin
  conexao := TConexao.Create('imprimir');
  try
    conexao.SQL.Add('select * from pedido_nfce where id_pedido = :pedido');
    conexao.Parametros('pedido', Req.Params['codigo']);
    Caminho := conexao.FieldByName('caminho'); // Obtenha o caminho do campo
    JsonObject := TJSONObject.Create;
    JsonObject.AddPair('url', Caminho);
    Res.Send<TJSONObject>(JsonObject);

  finally
    conexao.Free; // Certifique-se de liberar a memória após o uso
  end;
end;

procedure DoGetImpressaoPedido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Memory: TFDMemTable;
  status: Integer;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,"ONLY_FULL_GROUP_BY",""));');
  conexao.ExecuteSQL;
  Memory := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select p.codigo, p.codigo_pedido_dia as codigo_comanda,p.pedido_site, DATE_FORMAT(p.data_pedido, '
    + QuotedStr('%d/%m/%Y') + ') as data_pedido, TIME_FORMAT(p.hora_pedido, ' +
    QuotedStr('%H:%i') +
    ') as hora_pedido, p.status, p.valor_pedido as vl_pedido,p.valor_desconto as vl_desconto,p.valor_taxa_entrega as vl_taxa,');
  conexao.SQL.Add
    ('p.valor_total_pedido as vl_total,p.troco,p.origem,tp.descricao as tipo_pagamento,');
  conexao.SQL.Add('p.servico,');
  conexao.SQL.Add('c.codigo as codigo_cliente, p.mp,');
  conexao.SQL.Add('CASE');
  conexao.SQL.Add(' WHEN c.nome = ' + QuotedStr('BALCÃO') +
    ' AND p.nome <> ''''');
  conexao.SQL.Add(' THEN p.nome');
  conexao.SQL.Add(' ELSE c.nome');
  conexao.SQL.Add('END AS nome,');
  conexao.SQL.Add('c.celular, ');
  conexao.SQL.Add('p.desc_desconto_ifood as desc_desconto,');
  conexao.SQL.Add('p.servico_percentual,');
  conexao.SQL.Add('CASE ');
  conexao.SQL.Add(' when p.origem = 1 then "ORIGEM WHATSAPP"');
  conexao.SQL.Add(' when p.origem = 2 then "ORIGEM SITE"');
  conexao.SQL.Add(' when p.origem = 3 then "ORIGEM APP"');
  conexao.SQL.Add(' when p.origem = 4 then "ORIGEM IFOOD" ');
  conexao.SQL.Add(' else "ORIGEM OUTROS"');
  conexao.SQL.Add('END as origem, ');
  conexao.SQL.Add('CASE ');
  conexao.SQL.Add('   when p.codigo_cliente_endereco = 0 then "VEM BUSCAR"');
  conexao.SQL.Add('   else "DELIVERY" ');
  conexao.SQL.Add('END as tipo_pedido, ');
  conexao.SQL.Add('case');
  conexao.SQL.Add(' when ce.latitude = 0 then ""');
  conexao.SQL.Add
    (' else CONCAT("https://www.google.com.br/maps/dir/",(SELECT CONCAT(latitude,",",longitude) FROM dados_whatsapp limit 1),"/",ce.latitude,",",ce.longitude)');
  conexao.SQL.Add(' end as endereco_qrcod, ');
  conexao.SQL.Add('case ');
  conexao.SQL.Add
    ('   when (select count(*) from pedido where codigo_cliente = c.codigo and status in (1,2,3,4,5,6,7,9)) = 1 then "Primeiro Pedido"');
  conexao.SQL.Add
    ('   else CONCAT((select count(*) from pedido where codigo_cliente = c.codigo and status in (1,2,3,4,5,6,7,9)), " Pedidos No Seu Restaurante")');
  conexao.SQL.Add(' END as qtd_pedidos_cliente,');
  conexao.SQL.Add('');
  conexao.SQL.Add('');
  conexao.SQL.Add('CASE');
  conexao.SQL.Add('    WHEN p.codigo_cliente_endereco = 0 THEN ""');
  conexao.SQL.Add
    ('    ELSE CONCAT("Endereço: ",ce.rua," ",ce.numero,", ",ce.bairro," - ",ce.cidade," [",ce.complemento,"]") ');
  conexao.SQL.Add('END as endereco_completo,');
  conexao.SQL.Add('');
  conexao.SQL.Add('tprod.codigo as tipo_produto_codigo,');
  if frmServidor.Configuracoes.FieldByName('oculta_categoria').AsInteger = 1
  then
  begin
    conexao.SQL.Add('"" as tipo_produto_nome,');
  end
  else
  begin
    conexao.SQL.Add('tprod.descricao as tipo_produto_nome,');
  end;
  conexao.SQL.Add
    ('pp.codigo as codigo_grupo,prod.codigo as codigo_produto, prod.nome_produto,');
  conexao.SQL.Add('pp.valor_unitario as vl_unitario, pp.valor_total as total,');
  conexao.SQL.Add('pp.quantidade as qtd,');
  conexao.SQL.Add('');
  conexao.SQL.Add('pps.nomeclatura as tipo,');
  // conexao.SQL.Add('(');
  // conexao.SQL.Add('  SELECT ');
  // conexao.SQL.Add('    CASE ');
  // conexao.SQL.Add('      WHEN COUNT(*) > 1 THEN CONCAT(COUNT(*), " x ", descricao)');
  // conexao.SQL.Add('      ELSE descricao');
  // conexao.SQL.Add('    END');
  // conexao.SQL.Add('  FROM pedido_produto_sap');
  // conexao.SQL.Add('  WHERE codigo_pedido_produto = pp.codigo ');
  // conexao.SQL.Add('    AND descricao = pps.descricao');
  // conexao.SQL.Add(') AS descricao,');
  // conexao.SQL.Add('(');
  // conexao.SQL.Add('  SELECT  concat(count(*)," x ",descricao) ');
  // conexao.SQL.Add('  FROM pedido_produto_sap');
  // conexao.SQL.Add('  WHERE codigo_pedido_produto = pp.codigo and descricao = pps.descricao');
  // conexao.SQL.Add(') as descricao,');

  conexao.SQL.Add('group_concat(pps.descricao SEPARATOR "; ")  as descricao,');
  conexao.SQL.Add('pps.descricao  as descricao,');
  conexao.SQL.Add('');
  conexao.SQL.Add('CASE');
  conexao.SQL.Add
    ('    WHEN group_concat(pps.descricao SEPARATOR "; ") = "" THEN ""');
  conexao.SQL.Add('    ELSE pps.nomeclatura');
  conexao.SQL.Add('END as tipo,');
  conexao.SQL.Add('');
  conexao.SQL.Add
    ('desc_ficha, p.ifood_phone as ifoodphone, p.ifood_localizador as ifoodlocalizador, p.ifood_pedido as ifoodpedido,');
  conexao.SQL.Add('sum(pps.valor) as valor,');
  conexao.SQL.Add
    ('(SELECT nome FROM dados_whatsapp limit 1) as nome_estabelecimento,');
  conexao.SQL.Add
    ('(SELECT impressaotipopro FROM dados_whatsapp limit 1) as imprimir_separado,');
  conexao.SQL.Add
    ('(select descricao from mesa where id_mesa = p.id_ficha) as mesa,');
  conexao.SQL.Add
    ('(select count(driver) from impressoras  where impressora_padrao = 1 and ativo = 1 group by descricao limit 1) as via_impressao,');
  conexao.SQL.Add
    ('(select CONCAT(group_concat(codigo),",") from impressoras where upper(descricao) = "COMANDA" and ativo = 1 group by descricao limit 1) as impressora_separado,');
  conexao.SQL.Add
    ('(select CONCAT(group_concat(codigo),",") from impressoras where upper(descricao) = "DELIVERY" and ativo = 1 limit 1) as impressora_delivery,');
  conexao.SQL.Add
    ('(SELECT impressora FROM usuario where codigo = p.usuario) as impressora_usuario,');
  conexao.SQL.Add('');
  conexao.SQL.Add('');
  conexao.SQL.Add
    ('TO_BASE64(upper(concat(p.codigo,"|",p.codigo_pedido_dia,"|",p.data_pedido,"|",p.hora_pedido,"|",c.celular,"|",c.nome,"|",ce.rua,"|",ce.numero,"|",ce.bairro,"|",ce.cidade,"|",ce.estado,"|",p.valor_total_pedido,"|",p.valor_taxa_entrega,"|",tp.descricao))) ');
  conexao.SQL.Add('  as qrcod_motooby,');
  conexao.SQL.Add('upper(usu.nome) as usuario,');
  conexao.SQL.Add('upper(imp.driver) as driver');
  conexao.SQL.Add('');
  conexao.SQL.Add('from pedido as p ');
  conexao.SQL.Add('left join cliente as c on c.codigo = p.codigo_cliente');
  conexao.SQL.Add
    ('left join cliente_endereco as ce on ce.codigo = p.codigo_cliente_endereco');
  conexao.SQL.Add
    ('left join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento');
  conexao.SQL.Add
    ('left join pedido_produtos as pp on pp.codigo_pedido = p.codigo');
  conexao.SQL.Add
    ('left join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp.codigo');
  conexao.SQL.Add
    ('left join produto as prod on prod.codigo = pp.codigo_produto');
  conexao.SQL.Add
    ('left join tipo_produto as tprod on tprod.codigo = prod.codigo_grupo');
  conexao.SQL.Add('left join usuario as usu on usu.codigo = p.usuario');
  conexao.SQL.Add
    ('left join impressoras as imp on imp.codigo = COALESCE(NULLIF(usu.impressora, 0), tprod.impressora)  ');
  conexao.SQL.Add('where p.codigo = :codigo_pedido');
  conexao.SQL.Add('group by p.codigo,');
  conexao.SQL.Add('p.codigo_pedido_dia,');
  conexao.SQL.Add('p.pedido_site,');
  conexao.SQL.Add('p.data_pedido,');
  conexao.SQL.Add('p.hora_pedido,');
  conexao.SQL.Add('p.status,p.valor_pedido,');
  conexao.SQL.Add('p.valor_desconto,');
  conexao.SQL.Add('p.valor_taxa_entrega,');
  conexao.SQL.Add('p.valor_total_pedido,');
  conexao.SQL.Add('p.troco,');
  conexao.SQL.Add('p.origem,');
  conexao.SQL.Add('tp.descricao,');
  conexao.SQL.Add('p.servico,');
  conexao.SQL.Add('c.codigo,');
  conexao.SQL.Add('p.mp,');
  conexao.SQL.Add('c.nome,');
  conexao.SQL.Add('c.celular,');
  conexao.SQL.Add('p.pedido_site,');
  conexao.SQL.Add('p.desc_desconto_ifood,');
  conexao.SQL.Add('p.nome,');
  conexao.SQL.Add('p.codigo_cliente_endereco,');
  conexao.SQL.Add('tprod.codigo,');
  conexao.SQL.Add('pp.codigo,');
  conexao.SQL.Add('pps.descricao,');
  conexao.SQL.Add('pps.nomeclatura,');
  conexao.SQL.Add('p.desc_ficha,');
  conexao.SQL.Add('p.ifood_phone,');
  conexao.SQL.Add('p.ifood_localizador,');
  conexao.SQL.Add('p.ifood_pedido,');
  conexao.SQL.Add('p.id_ficha');
  conexao.Parametros('codigo_pedido', Req.Params['codigo']);
  Memory.LoadFromJSON(conexao.ConsultaSQL);

  if Memory.RecordCount > 0 then
  begin
    while not Memory.Eof do
    begin
      Memory.Edit;
      if Memory.FieldByName('impressora_usuario').AsString = '0' then
        Memory.FieldByName('impressora_usuario').AsString := '';
      if (Memory.FieldByName('impressora_usuario').AsString <> '') then
      begin
        Memory.FieldByName('impressora_delivery').AsString :=
          Memory.FieldByName('impressora_usuario').AsString + ',';
      end;

      if Memory.FieldByName('tipo').AsString = 'SABORES' then
      begin
        Memory.FieldByName('tipo').AsString :=
          AtualizaLetra(Memory.FieldByName('tipo').AsString);
        Memory.FieldByName('descricao').AsString :=
          AtualizaLetra(Memory.FieldByName('descricao').AsString);
        Memory.FieldByName('descricao').AsString :=
          StringReplace(Memory.FieldByName('descricao').AsString, ' 1/1 -', '',
          [rfReplaceAll]);
        Memory.FieldByName('descricao').AsString :=
          StringReplace(Memory.FieldByName('descricao').AsString, '1/1 - ', '',
          [rfReplaceAll]);
        Memory.FieldByName('descricao').AsString :=
          AnsiUpperCase(Memory.FieldByName('descricao').AsString);
      end
      else
      begin
        Memory.FieldByName('tipo').AsString :=
          AtualizaLetra(Memory.FieldByName('tipo').AsString);
        Memory.FieldByName('descricao').AsString :=
          AtualizaLetra(Memory.FieldByName('descricao').AsString);
      end;

      // Validar se o produto esta na lista para imprimir, se nao tiver colocar ele
      conexao.SQL.Add
        ('SELECT * FROM impressao_pedido_produto where id_pedido = :id');
      conexao.Parametros('id', Memory.FieldByName('codigo_grupo').AsInteger);
      try
        status := conexao.FieldByName('id');
      except
        status := -1
      end;

      if status = -1 then
      begin
        conexao.SQL.Add
          ('insert into impressao_pedido_produto (id_pedido,status,vias,usuario,data_solicitacao,hora_solicitacao) values (:pedido,0,0,-2,curdate(),curtime())');
        conexao.Parametros('pedido', Memory.FieldByName('codigo_grupo')
          .AsInteger);
        conexao.ExecuteSQL;
      end;

      conexao.SQL.Add
        ('update impressao_pedido_produto set status = 0, data_solicitacao = curdate(), hora_solicitacao = curtime() where data_impressao is null and id = :id');
      conexao.Parametros('id', status);
      conexao.ExecuteSQL;

      Memory.Next;

    end;
  end;

  Res.Send<TJSONArray>(Memory.ToJSONArray());
  conexao.Free;
  Memory.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetImpressoras(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('select * from impressoras where codigo = :codigo');
  conexao.Parametros('codigo', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoPostImpressaoPedido(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('update impressao_pedido set data_impressao = current_date, hora_impressao = current_time, status = 1 where id_pedido = :id');
  conexao.Parametros('id', Req.Params['codigo']);
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('update pedido set status = 1 where codigo = :id and status = -1');
  conexao.Parametros('id', Req.Params['codigo']);
  conexao.ExecuteSQL;

  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetImpressaoCaixaCodigo(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('SELECT ');
  conexao.SQL.Add('CASE ');
  conexao.SQL.Add(' when ped.id_ficha > 0 then ped.desc_ficha');
  conexao.SQL.Add(' else CONCAT(''Pedido '',ped.codigo_pedido_dia)');
  conexao.SQL.Add('END as origem_pedido,');
  conexao.SQL.Add('CASE ');
  conexao.SQL.Add(' when ped.origem = 1 then ');
  conexao.SQL.Add
    (' CONCAT(''WHATSAPP '','' '',(select nome from usuario where codigo = case when pp.usuario > 0 then pp.usuario else (select codigo from usuario limit 1) end limit 1))');
  conexao.SQL.Add(' when ped.origem = 2 then ');
  conexao.SQL.Add
    (' CONCAT(''SITE '','' '',(select nome from usuario where codigo = case when pp.usuario > 0 then pp.usuario else (select codigo from usuario limit 1) end limit 1))');
  conexao.SQL.Add(' when ped.origem = 3 then ');
  conexao.SQL.Add
    (' CONCAT(''APP '','' '',(select nome from usuario where codigo = case when pp.usuario > 0 then pp.usuario else (select codigo from usuario limit 1) end limit 1))');
  conexao.SQL.Add(' else "ORIGEM OUTROS"');
  conexao.SQL.Add('END as origem_local, ');
  conexao.SQL.Add('current_timestamp() as data_impressao,');
  conexao.SQL.Add('pp.codigo,');
  conexao.SQL.Add('pp.valor_unitario as vl_unitario,');
  conexao.SQL.Add('pp.quantidade as qtd,');
  conexao.SQL.Add('pp.valor_total as vl_total,');
  conexao.SQL.Add
    ('p.codigo_interno as codigo_produto,tp.descricao as categoria,');
  conexao.SQL.Add('CASE');
  conexao.SQL.Add(' WHEN c.nome = ' + QuotedStr('BALCÃO'));
  conexao.SQL.Add(' THEN ped.nome');
  conexao.SQL.Add(' ELSE c.nome');
  conexao.SQL.Add('END as nome,');
  conexao.SQL.Add
    ('p.nome_produto as produto,c.celular, ped.data_pedido, ped.hora_pedido, case  when ped.codigo_cliente_endereco = 0 then "Vem Buscar" else "Delivery" end as tipo,');
  conexao.SQL.Add('pps.nomeclatura as nomeclatura,ped.origem, ');
  conexao.SQL.Add
    ('group_concat(pps.descricao SEPARATOR ''; '')  as descricao,');
  conexao.SQL.Add('sum(pps.valor) as vl_adicional,');
  conexao.SQL.Add
    ('(select descricao from mesa where id_mesa = ped.id_ficha) as mesa,');
  conexao.SQL.Add
    ('(SELECT driver FROM impressoras where codigo = (select impressora from tipo_produto where codigo = p.codigo_grupo)) as driver,');
  conexao.SQL.Add
    ('(SELECT upper(descricao) FROM impressoras where codigo = (select impressora from tipo_produto where codigo = p.codigo_grupo)) as impressora');
  conexao.SQL.Add('FROM pedido_produtos as pp');
  conexao.SQL.Add('join produto as p on p.codigo = pp.codigo_produto');
  conexao.SQL.Add
    ('join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp.codigo');
  conexao.SQL.Add('join pedido as ped on ped.codigo = pp.codigo_pedido');
  conexao.SQL.Add('join tipo_produto as tp on tp.codigo = p.codigo_grupo');
  conexao.SQL.Add('left join cliente as c on c.codigo = ped.codigo_cliente');
  conexao.SQL.Add('where pp.codigo in (' + Req.Params['codigo'] +
    ') and pp.codigo_pedido > 0');
  conexao.SQL.Add('group by pps.nomeclatura, pps.codigo_pedido_produto');
  conexao.SQL.Add('order by pp.codigo');

  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoPostImpressaoPedidoProduto(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Codigo: String;
begin
  conexao := TConexao.Create('imprimir');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('select * from pedido_produtos where codigo_pedido = :codigo');
  conexao.Parametros('codigo', Req.Params['codigo']);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  if Dados.RecordCount > 0 then
  begin

    while not Dados.Eof do
    begin
      if Codigo = '' then
        Codigo := Dados.FieldByName('codigo').AsString
      else
        Codigo := Codigo + ',' + Dados.FieldByName('codigo').AsString;
      Dados.Next;
    end;
  end;

  conexao.SQL.Add
    ('update impressao_pedido_produto set status = 0 where data_impressao is null and id_pedido in ('
    + Codigo + ')');
  conexao.ExecuteSQL;

  Dados.Free;

  conexao.SQL.Add
    ('update pedido_produtos set impresso = 1, impressao = 1 where codigo = :codigo');
  conexao.Parametros('codigo', Req.Params['codigo']);
  conexao.ExecuteSQL;
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoPostImpressaoPedidoProdutos(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Codigo: String;
begin
  Codigo := Req.Params['codigo'];
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('update impressao_pedido_produto set data_impressao = current_date, hora_impressao = current_time, status = 1 where id_pedido in ('
    + Req.Params['codigo'] + ')');
  conexao.ExecuteSQL;
  conexao.SQL.Add('update pedido_produtos set impresso = 1 where codigo in(' +
    Req.Params['codigo'] + ')');
  conexao.ExecuteSQL;
  conexao.Free;
  frmServidor.ImpressoraStatus;


  // conexao := TConexao.Create('imprimir');

  // conexao.Parametros('codigo', Req.Params['codigo']);
  // conexao.ExecuteSQL;
  // conexao.Free;
  // frmServidor.ImpressoraStatus;

end;

procedure DoGetCaixaTresSangria(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send<TJSONArray>(frmServidor.DoGetCaixaTresSangria(Req.Params['codigo']
    .ToInteger));
  frmServidor.ImpressoraStatus;
end;

procedure DoGetCaixaTresLancado(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send<TJSONArray>(frmServidor.DoGetCaixaTresLancado(Req.Params['codigo']
    .ToInteger));
  frmServidor.ImpressoraStatus;
end;

procedure DoGetCaixaTres(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJSONArray>(frmServidor.DoGetCaixaTres(Req.Params['codigo']
    .ToInteger));
  frmServidor.ImpressoraStatus;
end;

procedure DoGetCaixaQuatro(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('select ');
  conexao.SQL.Add('c.id,');
  conexao.SQL.Add('DATE_FORMAT(c.data_abertura, "%d/%m/%Y") as data_abertura,');
  conexao.SQL.Add('TIME_FORMAT(c.hora_abertura, "%H:%i") as hora_abertura,');
  conexao.SQL.Add
    ('DATE_FORMAT(c.data_fechamento, "%d/%m/%Y") as data_fechamento,');
  conexao.SQL.Add
    ('TIME_FORMAT(c.hora_fechamento, "%H:%i") as hora_fechamento,');
  conexao.SQL.Add('c.valor_abertura,');
  conexao.SQL.Add('c.valor_fechamento,');
  conexao.SQL.Add
    ('(select sum(valor) from caixa_movimento as cmm where cmm.id_caixa = c.id and cmm.tipo = 226) as valor_computado,');
  conexao.SQL.Add
    ('(select sum(valor) from caixa_movimento as cmm where cmm.id_caixa = c.id and cmm.tipo = 262626) as valor_informado,');
  conexao.SQL.Add
    ('((select sum(valor) from caixa_movimento as cmm where cmm.id_caixa = c.id and cmm.tipo = 262626)- (select sum(valor) from caixa_movimento as cmm where cmm.id_caixa = c.id and cmm.tipo = 226)) as valor_diferenca,');
  conexao.SQL.Add('cm.tipo,');
  conexao.SQL.Add('cm.valor as transacao_valor,');
  conexao.SQL.Add('DATE_FORMAT(cm.data, "%d/%m/%Y") as transacao_data,');
  conexao.SQL.Add('TIME_FORMAT(cm.hora, "%H:%i") as transacao_hora,');
  conexao.SQL.Add('CONVERT(cm.descricao USING utf8)as transacao_descricao');
  conexao.SQL.Add('from caixa as c');
  conexao.SQL.Add('join caixa_movimento as cm on cm.id_caixa = c.id');
  conexao.SQL.Add('where c.id = :id and cm.tipo = 1');
  conexao.SQL.Add('order by cm.id_pedido');
  conexao.Parametros('id', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetCaixaCincoProduto(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send<TJSONArray>(frmServidor.DoGetCaixaCincoProduto(Req.Params['codigo']
    .ToInteger));
  frmServidor.ImpressoraStatus;
end;

procedure DoGetCaixaCincoCategoria(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send<TJSONArray>(frmServidor.DoGetCaixaCincoCategoria(Req.Params['codigo']
    .ToInteger));
  frmServidor.ImpressoraStatus;
end;

procedure DoGetCaixaCinco(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
  I: Integer;
  Dados: TFDMemTable;
begin
  conexao := TConexao.Create('imprimir');
  frmServidor.PRODUTOS.Close;
  frmServidor.PRODUTOS.Open;

  I := Req.Params['codigo'].ToInteger();
  // for I := 0 to 2 do

  conexao.SQL.Clear;
  conexao.SQL.Add('SELECT');
  conexao.SQL.Add(Req.Params['codigo'] + ' as id,');
  conexao.SQL.Add('produtos.codigo,');
  conexao.SQL.Add('produtos.descricao,');
  conexao.SQL.Add('produtos.nome,');
  conexao.SQL.Add('max(produtos.total) as total,');
  conexao.SQL.Add('sum(produtos.quantidade) as quantidade,');
  conexao.SQL.Add('produtos.tipo');
  conexao.SQL.Add('FROM(');
  conexao.SQL.Add('select ');
  conexao.SQL.Add('prod.codigo,');
  conexao.SQL.Add
    ('(select descricao from tipo_produto where codigo = prod.codigo_grupo) as descricao,');
  conexao.SQL.Add('upper(prod.nome_produto) as nome,');
  conexao.SQL.Add('prod.valor_venda as total,');
  conexao.SQL.Add('pp.quantidade as quantidade,');
  conexao.SQL.Add('CASE');
  case I of
    0:
      begin
        conexao.SQL.Add('    WHEN p.codigo_cliente_endereco = 0 THEN "Mesa"');
      end
  else
    begin
      conexao.SQL.Add
        ('    WHEN p.codigo_cliente_endereco = 0 THEN "Vem Buscar"');
    end;
  end;
  conexao.SQL.Add('    ELSE "Delivery"');
  conexao.SQL.Add('END as tipo');
  conexao.SQL.Add(' from pedido as p');
  conexao.SQL.Add('join pedido_produtos as pp on pp.codigo_pedido = p.codigo ');
  conexao.SQL.Add('join produto as prod on prod.codigo = pp.codigo_produto');

  case I of
    0:
      begin
        // Mesa
        conexao.SQL.Add
          ('where p.id_caixa = :id and p.codigo_cliente_endereco = 0 and p.id_ficha > 0')
      end;
    1:
      begin
        // Vem Buscar
        conexao.SQL.Add
          ('where p.id_caixa = :id and p.codigo_cliente_endereco = 0 and p.id_ficha is null')
      end
  else
    begin
      // Delivery
      conexao.SQL.Add
        ('where p.id_caixa = :id and p.codigo_cliente_endereco > 0');
    end;
  end;

  conexao.SQL.Add(') as produtos');
  conexao.SQL.Add('group by codigo, descricao,nome,tipo');
  conexao.Parametros('id', Req.Params['codigo']);

  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      frmServidor.PRODUTOS.Insert;

      frmServidor.PRODUTOS.FieldByName('codigo').AsString :=
        Dados.FieldByName('codigo').AsString;
      frmServidor.PRODUTOS.FieldByName('id').AsString :=
        Dados.FieldByName('id').AsString;
      frmServidor.PRODUTOS.FieldByName('grupo').AsString := '1';
      frmServidor.PRODUTOS.FieldByName('descricao').AsString :=
        Dados.FieldByName('descricao').AsString;
      frmServidor.PRODUTOS.FieldByName('nome').AsString :=
        Dados.FieldByName('nome').AsString;

      frmServidor.PRODUTOS.FieldByName('tipo').AsString :=
        Dados.FieldByName('tipo').AsString;
      frmServidor.PRODUTOS.FieldByName('quantidade').AsString :=
        Dados.FieldByName('quantidade').AsString;
      frmServidor.PRODUTOS.FieldByName('total').AsFloat :=
        Dados.FieldByName('total').AsFloat * frmServidor.PRODUTOS.FieldByName
        ('quantidade').AsFloat;
      frmServidor.PRODUTOS.FieldByName('unitario').AsFloat :=
        frmServidor.PRODUTOS.FieldByName('total').AsFloat /
        frmServidor.PRODUTOS.FieldByName('quantidade').AsFloat;

      frmServidor.PRODUTOS.Post;

      Dados.Next;
    end;
  end;
  Dados.Free;

  conexao.SQL.Clear;
  conexao.SQL.Add('SELECT');
  conexao.SQL.Add(Req.Params['codigo'] + ' as id,');
  conexao.SQL.Add('max(produtos.codigo) as codigo,');
  conexao.SQL.Add('produtos.descricao,');
  conexao.SQL.Add('produtos.nome,');
  conexao.SQL.Add('sum(produtos.total) as total,');
  conexao.SQL.Add('sum(produtos.quantidade) as quantidade,');
  conexao.SQL.Add('produtos.tipo');
  conexao.SQL.Add('FROM(');
  conexao.SQL.Add('select ');
  conexao.SQL.Add('pps.id as codigo,');
  conexao.SQL.Add('pps.nomeclatura as descricao,');
  conexao.SQL.Add('pps.descricao as nome,');
  conexao.SQL.Add('(pp.quantidade * pps.valor) as total,');
  conexao.SQL.Add('pp.quantidade as quantidade,');
  conexao.SQL.Add('CASE');
  case I of
    0:
      begin
        conexao.SQL.Add('    WHEN p.codigo_cliente_endereco = 0 THEN "Mesa"');
      end
  else
    begin
      conexao.SQL.Add
        ('    WHEN p.codigo_cliente_endereco = 0 THEN "Vem Buscar"');
    end;
  end;
  conexao.SQL.Add('    ELSE "Delivery"');
  conexao.SQL.Add('END as tipo');
  conexao.SQL.Add('from pedido as p');
  conexao.SQL.Add('join pedido_produtos as pp on pp.codigo_pedido = p.codigo');
  conexao.SQL.Add
    ('join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp.codigo and pps.valor > 0');
  case I of
    0:
      begin
        // Mesa
        conexao.SQL.Add
          ('where p.id_caixa = :id and p.codigo_cliente_endereco = 0 and p.id_ficha > 0')
      end;
    1:
      begin
        // Vem Buscar
        conexao.SQL.Add
          ('where p.id_caixa = :id and p.codigo_cliente_endereco = 0 and p.id_ficha is null')
      end
  else
    begin
      // Delivery
      conexao.SQL.Add
        ('where p.id_caixa = :id and p.codigo_cliente_endereco > 0');
    end;
  end;
  conexao.SQL.Add(') as produtos');
  conexao.SQL.Add('group by descricao,nome,tipo ');
  conexao.SQL.Add('order by descricao,nome');
  conexao.Parametros('id', Req.Params['codigo']);
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  while not Dados.Eof do
  begin
    frmServidor.PRODUTOS.Insert;
    frmServidor.PRODUTOS.FieldByName('codigo').AsString :=
      Dados.FieldByName('codigo').AsString;
    frmServidor.PRODUTOS.FieldByName('id').AsString :=
      Dados.FieldByName('id').AsString;
    frmServidor.PRODUTOS.FieldByName('grupo').AsString := '2';
    frmServidor.PRODUTOS.FieldByName('descricao').AsString :=
      Dados.FieldByName('descricao').AsString;
    frmServidor.PRODUTOS.FieldByName('nome').AsString :=
      Dados.FieldByName('nome').AsString;
    frmServidor.PRODUTOS.FieldByName('total').AsString :=
      Dados.FieldByName('total').AsString;
    frmServidor.PRODUTOS.FieldByName('tipo').AsString :=
      Dados.FieldByName('tipo').AsString;
    frmServidor.PRODUTOS.FieldByName('quantidade').AsString :=
      Dados.FieldByName('quantidade').AsString;
    frmServidor.PRODUTOS.FieldByName('unitario').AsFloat :=
      frmServidor.PRODUTOS.FieldByName('total').AsFloat /
      frmServidor.PRODUTOS.FieldByName('quantidade').AsFloat;
    frmServidor.PRODUTOS.Post;

    Dados.Next;
  end;

  Dados.Free;

  conexao.Free;

  Res.Send<TJSONArray>(frmServidor.PRODUTOS.ToJSONArray());
  frmServidor.ImpressoraStatus;
end;

procedure DoGetCaixaSeis(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('select ' + Req.Params['codigo'] +
    ' as id, upper(m.nome) as motoboy,  group_concat(p.codigo_pedido_dia) as codigo, sum(p.valor_taxa_entrega) as taxa_entrega, sum(p.valor_total_pedido) as total, ce.bairro  from pedido as p ');
  conexao.SQL.Add
    ('join cliente_endereco as ce on ce.codigo = p.codigo_cliente_endereco');
  conexao.SQL.Add('join pedido_motoboy as pm on pm.codigo_pedido = p.codigo');
  conexao.SQL.Add('join motoboy as m on m.codigo = pm.codigo_motoboy');
  conexao.SQL.Add('where p.id_caixa  = :id');
  conexao.SQL.Add('group by m.codigo, ce.bairro');
  conexao.Parametros('id', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;

end;

procedure DoGetCaixaSete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('select pedido.data_pedido,pedido.hora_pedido, pedido.codigo_pedido_dia, (select nome from cliente where cliente.codigo = pedido.codigo_cliente) as cliente,');
  conexao.SQL.Add
    ('pedido_produtos.valor_total, pedido_produtos.quantidade, (select upper(nome_produto) from produto where produto.codigo = pedido_produtos.codigo_produto) as produto,');
  conexao.SQL.Add('pedido_produtos.id_caixa as id');
  conexao.SQL.Add('from pedido_produtos ');
  conexao.SQL.Add('join pedido on pedido.codigo = pedido_produtos.id_pedido');
  conexao.SQL.Add('where pedido_produtos.id_caixa = :id');
  conexao.Parametros('id', Req.Params['codigo']);
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.ImpressoraStatus;

end;

procedure DoPostImpressaoCaixa(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add
    ('update impressao_caixa set data_impressao = current_date, hora_impressao = current_time, status = :status where id_caixa = :id');
  conexao.Parametros('status', Req.Params['status']);
  conexao.Parametros('id', Req.Params['codigo']);
  conexao.ExecuteSQL;
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoPostImpressoras(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  frmServidor.memImpressora.Close;
  try
    // ////////showmessage1(req.Body);
    frmServidor.memImpressora.LoadFromJSON(Req.Body);
    // ////////showmessage1(frmServidor.memImpressora.RecordCount.ToString);
  except

  end;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetSangria(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('SELECT *, CAST(descricao AS CHAR(100)) as sangria');
  conexao.SQL.Add('FROM caixa_movimento');
  conexao.SQL.Add('WHERE tipo = 2 and impressao = 0');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;
  frmServidor.OutrosStatus;

end;

procedure DoPostSangria(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('update caixa_movimento set impressao = 1 where id = :id');
  conexao.Parametros('id', Req.Params['codigo']);
  conexao.ExecuteSQL;
  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetStatusServico(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  if frmServidor.ValidaTempoImpressaoStatus then
  begin
    Res.Send('true')
  end
  else
  begin
    Res.Send('false')
  end;
end;

procedure DoPostImpressaoPedidoProdutoUsuario(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('DoPostImpressaoPedidoProduto');
  conexao.SQL.Add
    ('update pedido_produtos set tempo_liberacao = 0 where codigo_pedido = :pedido and usuario = :usuario');
  conexao.Parametros('pedido', Req.Params['pedido']);
  conexao.Parametros('usuario', Req.Params['usuario']);
  conexao.ExecuteSQL;
  conexao.Free;

end;

procedure DoPostImpressaoRecibo(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
  Codigo: Integer;
begin
  conexao := TConexao.Create('imprimir');
  conexao.SQL.Add('update caixa_receber set impressao = 1 where id = :id');
  conexao.Parametros('id', Req.Params['codigo']);
  conexao.ExecuteSQL;

  Codigo := conexao.GerarID('impressao_pedido', 'id');
  conexao.SQL.Add
    ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
  conexao.Parametros('id', Codigo);
  conexao.Parametros('pedido', Req.Params['pedido']);
  conexao.ExecuteSQL;

  conexao.Free;
  frmServidor.ImpressoraStatus;
end;

procedure DoGetReciboFiado(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('imprimir');

  conexao.SQL.Add
    ('select id, id_caixa, (select upper(nome) from cliente where codigo = id_cliente) as cliente, ');
  conexao.SQL.Add
    ('id_pedido, (select upper(descricao) from tipo_pagamento where codigo = id_tipo_pagamento limit 1) as pagamento,');
  conexao.SQL.Add
    ('DATE_FORMAT(data, "%d/%m/%Y") as data, TIME_FORMAT(hora, "%H:%i") as hora, valor');
  conexao.SQL.Add('from caixa_receber as cr');
  conexao.SQL.Add('where impressao = 0');
  Res.Send<TJSONArray>(conexao.ConsultaSQL);
  conexao.Free;

  frmServidor.OutrosStatus;

end;

procedure DoGetStatusServicoTempo(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
begin
  Res.Send(DateTimeToStr(frmServidor.DataHoraImpressaoService));
end;

procedure Registry;
begin
  THorse.get('/impressao/qrcod/pix', DoGetImpressaoQrcodPix);
  THorse.Post('/impressao/qrcod/pix/:pix', DoPostImpressaoQrcodPix);
  THorse.get('/impressao/pedidos', DoGetImpressaoPedidos);
  THorse.get('/impressao/padrao', DoGetImpressaoPadrao);
  THorse.get('/impressao/pedidos/cozinha', DoGetImpressaoPedidosCozinha);
  THorse.get('/impressao/cozinha/:codigo', DoGetImpressaoPedidosCozinhaPedido);
  THorse.get('/impressao/pedidos/cozinha/:codigo',
    DoGetImpressaoPedidosCozinhaCodigo);
  THorse.get('/impressao/caixa', DoGetImpressaoCaixa);
  THorse.get('/impressao/caixa/:codigo', DoGetImpressaoCaixaCodigo);
  THorse.get('/impressao/pedido/:codigo', DoGetImpressaoPedido);
  THorse.get('/impressao/impressoras/:codigo', DoGetImpressoras);

  THorse.get('/impressao/xml/nfce/:chave', DoGetXmlNfce);
  THorse.get('/impressao/pedido/nfce', DoGetImpressaoPedidosNFCE);
  THorse.Post('/impressao/pedido/nfce/:codigo', DoPostPedidoNFCe);
  THorse.get('/impressao/pedido/nfce/:codigo', DoGetImpressaoPedidoNFCe);

  THorse.get('/impressao/caixa/tres/:codigo', DoGetCaixaTres);
  THorse.get('/impressao/caixa/tres/lancado/:codigo', DoGetCaixaTresLancado);
  THorse.get('/impressao/caixa/tres/sangria/:codigo', DoGetCaixaTresSangria);
  THorse.get('/impressao/caixa/quatro/:codigo', DoGetCaixaQuatro);
  THorse.get('/impressao/caixa/cinco/:codigo', DoGetCaixaCinco);
  THorse.get('/impressao/caixa/cinco/produto/:codigo', DoGetCaixaCincoProduto);
  THorse.get('/impressao/caixa/cinco/categoria/:codigo',
    DoGetCaixaCincoCategoria);
  THorse.get('/impressao/caixa/seis/:codigo', DoGetCaixaSeis);
  THorse.get('/impressao/caixa/sete/:codigo', DoGetCaixaSete);
  THorse.Post('/impressao/caixa/:codigo/:status', DoPostImpressaoCaixa);
  THorse.get('/impressao/sangria', DoGetSangria);
  THorse.Post('/impressao/sangria/:codigo', DoPostSangria);

  THorse.Post('/impressao/pedido/:codigo', DoPostImpressaoPedido);
  THorse.Post('/impressao/pedido/produto/:codigo',
    DoPostImpressaoPedidoProduto);
  THorse.Post('/impressao/pedido/produtos/:codigo',
    DoPostImpressaoPedidoProdutos);
  THorse.Post('/impressao/impressoras', DoPostImpressoras);
  THorse.get('/impressao/status/servico', DoGetStatusServico);
  THorse.get('/impressao/status/servico/tempo', DoGetStatusServicoTempo);

  THorse.get('/impressao/recibo/fiado', DoGetReciboFiado);
  THorse.Post('/impressao/recibo/:codigo/:pedido', DoPostImpressaoRecibo);

  THorse.Post('/impressao/pedido/produto/:pedido/:usuario',
    DoPostImpressaoPedidoProdutoUsuario)

end;

end.
