object dmImpressaoV2: TdmImpressaoV2
  OnCreate = DataModuleCreate
  Height = 201
  Width = 389
  PixelsPerInch = 96
  object DADOS: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      
        'select p.codigo, p.codigo_pedido_dia as codigo_comanda,p.pedido_' +
        'site, p.data_pedido, p.hora_pedido, p.status, p.valor_pedido as ' +
        'vl_pedido,p.valor_desconto as vl_desconto,p.valor_taxa_entrega a' +
        's vl_taxa, p.valor_total_pedido as vl_total,p.troco,p.origem,tp.' +
        'descricao as tipo_pagamento, '
      'c.codigo as codigo_cliente, '
      'c.nome, c.celular, '
      'CASE '
      ' when p.origem = 1 then "ORIGEM WHATSAPP"'
      ' when p.origem = 2 then "ORIGEM SITE"'
      ' when p.origem = 3 then "ORIGEM APP" '
      ' else "ORIGEM OUTROS"'
      'END as origem, '
      'CASE '
      '   when p.codigo_cliente_endereco = 0 then "VEM BUSCAR"'
      '   else "DELIVERY"'
      'END as tipo_pedido, '
      'case'
      ' when ce.latitude = 0 then ""'
      
        ' else CONCAT('#39'https://www.google.com.br/maps/dir/'#39',(SELECT CONCA' +
        'T(latitude,'#39','#39',longitude) FROM dados_whatsapp limit 1),'#39'/'#39',ce.la' +
        'titude,'#39','#39',ce.longitude)'
      ' end as endereco_qrcod, '
      'case '
      
        '   when (select count(*) from pedido where codigo_cliente = c.co' +
        'digo and status in (1,2,3,4,5,6,7,9)) = 1 then "Primeiro Pedido"'
      
        '   else CONCAT((select count(*) from pedido where codigo_cliente' +
        ' = c.codigo and status in (1,2,3,4,5,6,7,9)), " Pedidos No Seu R' +
        'estaurante")'
      ' END as qtd_pedidos_cliente,'
      ''
      ''
      'CASE'
      '    WHEN p.codigo_cliente_endereco = 0 THEN ""'
      
        '    ELSE CONCAT('#39'Endere'#231'o: '#39',ce.rua,'#39' '#39',ce.numero,'#39', '#39',ce.bairro' +
        ','#39' - '#39',ce.cidade,'#39' ['#39',ce.complemento,'#39']'#39') '
      'END as endereco_completo,'
      ''
      'tprod.codigo as tipo_produto_codigo,'
      'tprod.descricao as tipo_produto_nome,'
      
        'pp.codigo as codigo_grupo,prod.codigo as codigo_produto, prod.no' +
        'me_produto,'
      'pp.valor_unitario as vl_unitario, pp.valor_total as vl_total,'
      'pp.quantidade as qtd,'
      ''
      'group_concat(pps.descricao SEPARATOR '#39'; '#39')  as descricao,'
      ''
      'CASE'
      '    WHEN group_concat(pps.descricao SEPARATOR '#39'; '#39') = "" THEN ""'
      '    ELSE pps.nomeclatura'
      'END as tipo,'
      ''
      'desc_ficha,'
      'sum(pps.valor) as valor,'
      
        '(SELECT nome FROM dados_whatsapp limit 1) as nome_estabeleciment' +
        'o,'
      
        '(SELECT impressaotipopro FROM dados_whatsapp limit 1) as imprimi' +
        'r_separado,'
      ''
      
        '(select count(driver) from impressoras  where upper(descricao) =' +
        ' '#39'DELIVERY'#39' and ativo = 1 group by descricao limit 1) as via_imp' +
        'ressao,'
      
        '(select CONCAT(group_concat(codigo),'#39','#39') from impressoras where ' +
        'upper(descricao) = '#39'COMANDA'#39' and ativo = 1 group by descricao li' +
        'mit 1) as impressora_separado,'
      
        '(select CONCAT(group_concat(codigo),'#39','#39') descricao from impresso' +
        'ras  where upper(descricao) = '#39'DELIVERY'#39' and ativo = 1 group by ' +
        'descricao limit 1) as impressora_delivery,'
      ''
      
        'TO_BASE64(upper(concat(p.codigo,'#39'|'#39',p.codigo_pedido_dia,'#39'|'#39',p.da' +
        'ta_pedido,'#39'|'#39',p.hora_pedido,'#39'|'#39',c.celular,'#39'|'#39',c.nome,'#39'|'#39',ce.rua,' +
        #39'|'#39',ce.numero,'#39'|'#39',ce.bairro,'#39'|'#39',ce.cidade,'#39'|'#39',ce.estado,'#39'|'#39',p.va' +
        'lor_total_pedido,'#39'|'#39',p.valor_taxa_entrega,'#39'|'#39',tp.descricao)))  a' +
        's qrcod_motooby '
      ''
      'from pedido as p '
      'left join cliente as c on c.codigo = p.codigo_cliente'
      
        'left join cliente_endereco as ce on ce.codigo = p.codigo_cliente' +
        '_endereco'
      'left join tipo_pagamento as tp on tp.codigo = p.tipo_pagamento'
      'left join pedido_produtos as pp on pp.codigo_pedido = p.codigo'
      
        'left join pedido_produto_sap as pps on pps.codigo_pedido_produto' +
        ' = pp.codigo'
      'left join produto as prod on prod.codigo = pp.codigo_produto'
      
        'left join tipo_produto as tprod on tprod.codigo = prod.codigo_gr' +
        'upo'
      'where p.codigo = :codigo_pedido'
      
        'group by pp.codigo, pps.codigo_pedido_produto,pps.nomeclatura, p' +
        'ps.codigo_pedido_produto')
    Left = 16
    Top = 120
    ParamData = <
      item
        Name = 'CODIGO_PEDIDO'
        ParamType = ptInput
      end>
  end
  object dsDados: TDataSource
    DataSet = DADOS
    Left = 552
    Top = 64
  end
  object COZINHA: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      'SELECT '
      'CASE '
      ' when ped.id_ficha > 0 then ped.desc_ficha'
      ' else CONCAT('#39'Pedido '#39',ped.codigo_pedido_dia)'
      'END as origem_pedido,'
      ''
      'CASE '
      ' when ped.origem = 1 then '
      
        ' CONCAT('#39'WHATSAPP '#39','#39' '#39',(select nome from usuario where codigo =' +
        ' case when pp.usuario > 0 then pp.usuario else (select codigo fr' +
        'om usuario limit 1) end limit 1))'
      ' when ped.origem = 2 then '
      
        ' CONCAT('#39'SITE '#39','#39' '#39',(select nome from usuario where codigo = cas' +
        'e when pp.usuario > 0 then pp.usuario else (select codigo from u' +
        'suario limit 1) end limit 1))'
      ' when ped.origem = 3 then '
      
        ' CONCAT('#39'APP '#39','#39' '#39',(select nome from usuario where codigo = case' +
        ' when pp.usuario > 0 then pp.usuario else (select codigo from us' +
        'uario limit 1) end limit 1))'
      ' else "ORIGEM OUTROS"'
      'END as origem_local, '
      ''
      'current_timestamp() as data_impressao,'
      'pp.codigo,'
      'pp.valor_unitario as vl_unitario,'
      'pp.quantidade as qtd,'
      'pp.valor_total as vl_total,'
      'p.codigo_interno as codigo_produto,'
      'p.nome_produto as produto,'
      ''
      'pps.nomeclatura as nomeclatura, '
      'group_concat(pps.descricao SEPARATOR '#39'; '#39')  as descricao,'
      'sum(pps.valor) as vl_adicional,'
      ''
      ''
      
        '(SELECT driver FROM impressoras where codigo = (select impressor' +
        'a from tipo_produto where codigo = p.codigo_grupo)) as driver,'
      'c.nome,'
      'c.celular,'
      'ped.data_pedido,'
      'ped.hora_pedido,'
      'case '
      'when ped.codigo_cliente_endereco = 0 then "Vem Buscar"'
      'else "Delivery"'
      'end as tipo,'
      'tp.descricao as categoria'
      ''
      ''
      'FROM pedido_produtos as pp'
      'join produto as p on p.codigo = pp.codigo_produto'
      'join tipo_produto as tp on tp.codigo = p.codigo_grupo'
      
        'join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp' +
        '.codigo'
      'join pedido as ped on ped.codigo = pp.codigo_pedido'
      'join cliente as c on c.codigo = ped.codigo_cliente'
      'where pp.codigo in (94,95)'
      ''
      'group by pps.nomeclatura, pps.codigo_pedido_produto'
      'order by pp.codigo')
    Left = 104
    Top = 120
  end
  object dsCozinha: TDataSource
    DataSet = COZINHA
    Left = 624
    Top = 64
  end
  object qryFechamentoCaixaCabechado: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      
        'select cm.*,c.*, upper(tp.descricao) as tipo_pagamento, CONVERT(' +
        ' cm.descricao using utf8)as descricao_utf8,'
      ''
      'CASE'
      '    WHEN cm.tipo = 1 THEN "ENTRADA"'
      '    WHEN cm.tipo = 2 THEN "SAIDA"'
      '    WHEN cm.tipo = 226 THEN "TIPO PAGAMENTO [COMPUTADO]"'
      '    WHEN cm.tipo = 262626 THEN "TIPO PAGAMENTO [LAN'#199'ADO]"'
      '    ELSE "OUTROS"'
      'END as descricao_tipo'
      ''
      ''
      'from caixa_movimento as cm '
      
        'left join tipo_pagamento as tp on tp.codigo = cm.id_tipo_pagamen' +
        'to'
      'join caixa as c on c.id = cm.id_caixa'
      'join usuario as u on u.codigo = c.id_usuario'
      'where cm.id_caixa = 50'
      'order by cm.tipo,id_pedido'
      '')
    Left = 840
    Top = 104
  end
  object dsFechamentoCaixaCabechado: TDataSource
    DataSet = qryFechamentoCaixaCabechado
    Left = 848
    Top = 184
  end
  object IMPRESSAO: TFDMemTable
    AfterInsert = IMPRESSAOAfterInsert
    IndexFieldNames = 'ID'
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 840
    Top = 32
    object IMPRESSAOID: TIntegerField
      DisplayLabel = 'C'#243'digo'
      FieldName = 'ID'
    end
    object IMPRESSAODATA_HORA: TDateTimeField
      DisplayLabel = 'Data/Hora'
      FieldName = 'DATA_HORA'
    end
    object IMPRESSAOTIPO: TStringField
      DisplayLabel = 'Tipo'
      FieldName = 'TIPO'
    end
    object IMPRESSAORELATORIO: TStringField
      DisplayLabel = 'Relat'#243'rio'
      FieldName = 'RELATORIO'
      Size = 255
    end
    object IMPRESSAOSTATUS: TIntegerField
      DisplayLabel = 'Status'
      FieldName = 'STATUS'
    end
    object IMPRESSAODESCRICAO: TStringField
      DisplayLabel = 'Descri'#231#227'o'
      FieldName = 'DESCRICAO'
      Size = 255
    end
    object IMPRESSAOCODIGO: TIntegerField
      DisplayLabel = 'C'#243'digo'
      FieldName = 'CODIGO'
    end
    object IMPRESSAODRIVER: TStringField
      DisplayLabel = 'Impressora'
      FieldName = 'DRIVER'
      Size = 255
    end
    object IMPRESSAOOBSERVACAO: TStringField
      DisplayLabel = 'Observa'#231#227'o'
      FieldName = 'OBSERVACAO'
      Size = 255
    end
  end
  object CAIXA_RESUMO: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      'select'
      'c.id,'
      'c.data_abertura,'
      'c.hora_abertura,'
      'c.data_fechamento,'
      'c.hora_fechamento,'
      'c.valor_abertura,'
      'c.valor_fechamento,'
      'tp.descricao,'
      'sum(cm.valor) as valor_tipo_pagamento,'
      
        '(select sum(pl.valor_total_pedido) from pedido as pl where pl.id' +
        '_caixa = c.id and pl.codigo_cliente_endereco = 0 and pl.id_ficha' +
        ' > 0) as valor_mesa,'
      
        '(select sum(pl.valor_total_pedido) from pedido as pl where pl.id' +
        '_caixa = c.id and pl.codigo_cliente_endereco = 0 and pl.id_ficha' +
        ' is null) as valor_vem_buscar,'
      
        '(select sum(pl.valor_total_pedido) from pedido as pl where pl.id' +
        '_caixa = c.id and pl.codigo_cliente_endereco > 0) as valor_deliv' +
        'ery,'
      
        '(c.valor_fechamento-(select sum(pl.valor_total_pedido) from pedi' +
        'do as pl where pl.id_caixa = c.id)) as valor_diferenca'
      'from caixa as c'
      'join caixa_movimento as cm on cm.id_caixa = c.id'
      'join pedido as p on p.codigo = cm.id_pedido'
      'join tipo_pagamento as tp on tp.codigo = cm.id_tipo_pagamento'
      'where c.id = 26 and cm.tipo = 1'
      'group by tp.codigo')
    Left = 48
    Top = 272
  end
  object dsResumo: TDataSource
    DataSet = CAIXA_RESUMO
    Left = 48
    Top = 336
  end
  object CAIXA_COMPLETO: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      'select '
      'c.id,'
      'c.data_abertura,'
      'c.hora_abertura,'
      'c.data_fechamento,'
      'c.hora_fechamento,'
      'c.valor_abertura,'
      'c.valor_fechamento,'
      
        '(select sum(valor) from caixa_movimento as cmm where cmm.id_caix' +
        'a = c.id and cmm.tipo = 226) as valor_computado,'
      
        '(select sum(valor) from caixa_movimento as cmm where cmm.id_caix' +
        'a = c.id and cmm.tipo = 262626) as valor_informado,'
      
        '((select sum(valor) from caixa_movimento as cmm where cmm.id_cai' +
        'xa = c.id and cmm.tipo = 262626)- (select sum(valor) from caixa_' +
        'movimento as cmm where cmm.id_caixa = c.id and cmm.tipo = 226)) ' +
        'as valor_diferenca,'
      'cm.tipo,'
      'cm.valor as transacao_valor,'
      'cm.data as transacao_data,'
      'cm.hora as transacao_hora,'
      'CONVERT(cm.descricao USING utf8)as transacao_descricao'
      'from caixa as c'
      'join caixa_movimento as cm on cm.id_caixa = c.id'
      'where c.id = 26 and cm.tipo = 1'
      'order by cm.id_pedido')
    Left = 200
    Top = 280
  end
  object dsCompleto: TDataSource
    DataSet = CAIXA_COMPLETO
    Left = 200
    Top = 344
  end
  object CAIXA_MOTOBOY: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      
        'select 28 as id, upper(m.nome) as motoboy,  group_concat(p.codig' +
        'o_pedido_dia) as codigo, sum(p.valor_taxa_entrega) as taxa_entre' +
        'ga, sum(p.valor_total_pedido) as total, ce.bairro  from pedido a' +
        's p '
      
        'join cliente_endereco as ce on ce.codigo = p.codigo_cliente_ende' +
        'reco'
      'join pedido_motoboy as pm on pm.codigo_pedido = p.codigo'
      'join motoboy as m on m.codigo = pm.codigo_motoboy'
      'where p.id_caixa  = 28'
      'group by m.codigo, ce.bairro')
    Left = 352
    Top = 288
  end
  object dsMotoboy: TDataSource
    DataSet = CAIXA_MOTOBOY
    Left = 352
    Top = 352
  end
  object CAIXA_PRODUTO: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      'SELECT '
      '   produtos.codigo,'
      '   produtos.id,'
      '   produtos.grupo,'
      '   produtos.descricao,'
      '   produtos.produto,'
      '   produtos.nome,'
      '   sum(produtos.total) as total,'
      '   sum(produtos.quantidade) as quantidade,'
      '   produtos.tipo,'
      '   produtos.adicionais'
      'FROM('
      'select'
      'pp.codigo,'
      '28 as id,'
      'tp.codigo as grupo,'
      'upper(tp.descricao) as descricao,'
      'prod.codigo as produto,'
      'upper(prod.nome_produto) as nome,'
      'pp.valor_total as total,'
      'pp.quantidade,'
      'CASE'
      '    WHEN p.codigo = 0 THEN "Vem Buscar"'
      '    ELSE "Delivery"'
      'END as tipo,'
      'group_concat('
      'CASE'
      '    WHEN pps.valor = 0 THEN ""'
      '    ELSE upper(pps.descricao)'
      'END'
      'separator '#39';'#39') as adicionais'
      'from pedido as p '
      'join pedido_produtos as pp on pp.codigo_pedido = p.codigo'
      'join produto as prod on prod.codigo = pp.codigo_produto '
      'join tipo_produto as tp on tp.codigo = prod.codigo_grupo'
      
        'join pedido_produto_sap as pps on pps.codigo_pedido_produto = pp' +
        '.codigo '
      'where p.id_caixa = 148'
      'group by pp.codigo'
      'order by tp.codigo,prod.codigo) as produtos'
      'group by produtos.produto, produtos.adicionais')
    Left = 496
    Top = 296
  end
  object dsProduto: TDataSource
    DataSet = CAIXA_PRODUTO
    Left = 496
    Top = 360
  end
end
