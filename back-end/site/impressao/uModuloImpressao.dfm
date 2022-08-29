object dmImpressaoV2: TdmImpressaoV2
  OnCreate = DataModuleCreate
  Height = 625
  Width = 1204
  PixelsPerInch = 96
  object DADOS: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      
        'select p.codigo, p.codigo_pedido_dia as codigo_comanda, p.data_p' +
        'edido, p.hora_pedido, p.status, p.valor_pedido as vl_pedido,p.va' +
        'lor_desconto as vl_desconto,p.valor_taxa_entrega as vl_taxa, p.v' +
        'alor_total_pedido as vl_total,p.troco,p.origem,tp.descricao as t' +
        'ipo_pagamento, '#10'c.codigo as codigo_cliente, '#10'c.nome, c.celular, '
      
        'CASE '#10' when p.origem = 1 then "ORIGEM WHATSAPP"'#10' when p.origem =' +
        ' 2 then "ORIGEM SITE"'#10' else "ORIGEM OUTROS"'#10'END as origem, '
      
        'CASE '#10'   when p.codigo_cliente_endereco = 0 then "VEM BUSCAR"'#10'  ' +
        ' else "DELIVERY"'#10'END as tipo_pedido, '
      
        'case'#10' when ce.latitude = 0 then ""'#10' else CONCAT('#39'https://www.goo' +
        'gle.com.br/maps/dir/'#39',(SELECT CONCAT(latitude,'#39','#39',longitude) FRO' +
        'M dados_whatsapp limit 1),'#39'/'#39',ce.latitude,'#39','#39',ce.longitude)'#10' end' +
        ' as endereco_qrcod, '
      
        'case '#10'   when (select count(*) from pedido where codigo_cliente ' +
        '= c.codigo and status in (1,2,3,4,5,6,7)) = 1 then "Primeiro Ped' +
        'ido"'#10'   else CONCAT((select count(*) from pedido where codigo_cl' +
        'iente = c.codigo and status in (1,2,3,4,5,6,7)), " Pedidos No Se' +
        'u Restaurante")'#10' END as qtd_pedidos_cliente,'#10#10
      
        'CASE'#10'    WHEN p.codigo_cliente_endereco = 0 THEN ""'#10'    ELSE CON' +
        'CAT(ce.rua,'#39' '#39',ce.numero,'#39', '#39',ce.bairro,'#39' - '#39',ce.cidade) '#10'END as' +
        ' endereco_completo,'#10
      
        'tprod.codigo as tipo_produto_codigo,'#10'tprod.descricao as tipo_pro' +
        'duto_nome,'
      
        'pps.codigo_pedido_produto as codigo_grupo,prod.codigo as codigo_' +
        'produto, prod.nome_produto,'#10'pp.valor_unitario as vl_unitario, pp' +
        '.valor_total as vl_total,'#10'pp.quantidade as qtd,'#10
      
        'pps.nomeclatura as tipo, pps.descricao, pps.valor,'#10'(SELECT nome ' +
        'FROM dados_whatsapp limit 1) as nome_estabelecimento,'#10'(SELECT im' +
        'pressaotipopro FROM dados_whatsapp limit 1) as imprimir_separado' +
        ','#10
      
        '(select count(driver) from impressoras  where upper(descricao) =' +
        ' '#39'DELIVERY'#39' and ativo = 1 group by descricao limit 1) as via_imp' +
        'ressao,'#10'(select CONCAT(group_concat(driver),'#39','#39') from impressora' +
        's where upper(descricao) = '#39'COMANDA'#39' and ativo = 1 group by desc' +
        'ricao limit 1) as impressora_separado,'#10'(select CONCAT(group_conc' +
        'at(driver),'#39','#39') descricao from impressoras  where upper(descrica' +
        'o) = '#39'DELIVERY'#39' and ativo = 1 group by descricao limit 1) as imp' +
        'ressora_delivery'#10
      
        'from pedido as p '#10'join cliente as c on c.codigo = p.codigo_clien' +
        'te'#10'join cliente_endereco as ce on ce.codigo_cliente = p.codigo_c' +
        'liente_endereco'#10'join tipo_pagamento as tp on tp.codigo = p.tipo_' +
        'pagamento'#10'join pedido_produtos as pp on pp.codigo_pedido = p.cod' +
        'igo'#10'join pedido_produto_sap as pps on pps.codigo_pedido_produto ' +
        '= pp.codigo'#10'join produto as prod on prod.codigo = pp.codigo_prod' +
        'uto'#10'join tipo_produto as tprod on tprod.codigo = prod.codigo_gru' +
        'po'#10'where p.codigo = :codigo_pedido'
      '')
    Left = 208
    Top = 192
    ParamData = <
      item
        Name = 'CODIGO_PEDIDO'
        ParamType = ptInput
        Value = Null
      end>
  end
  object dsDados: TDataSource
    DataSet = DADOS
    Left = 560
    Top = 56
  end
end
