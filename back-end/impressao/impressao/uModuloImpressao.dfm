object dmImpressaoV2: TdmImpressaoV2
  OnCreate = C
  Height = 1067
  Width = 2695
  object DADOS: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      
        'select p.codigo, p.codigo_pedido_dia as codigo_comanda,p.pedido_' +
        'site, p.data_pedido, p.hora_pedido, p.status, p.valor_pedido as ' +
        'vl_pedido,p.valor_desconto as vl_desconto,p.valor_taxa_entrega a' +
        's vl_taxa, p.valor_total_pedido as vl_total,p.troco,p.origem,tp.' +
        'descricao as tipo_pagamento, '
      'p.servico,'
      'c.codigo as codigo_cliente, p.mp,'
      'c.nome, c.celular, '
      'p.desc_desconto_ifood as desc_desconto,'
      'CASE '
      ' when p.origem = 1 then "ORIGEM WHATSAPP"'
      ' when p.origem = 2 then "ORIGEM SITE"'
      ' when p.origem = 3 then "ORIGEM APP"'
      ' when p.origem = 4 then "ORIGEM IFOOD" '
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
      '(select descricao from mesa where id_mesa = p.id_ficha) as mesa,'
      
        '(select count(driver) from impressoras  where impressora_padrao ' +
        '= 1 and ativo = 1 group by descricao limit 1) as via_impressao,'
      
        '(select CONCAT(group_concat(driver),'#39','#39') from impressoras where ' +
        'upper(descricao) = '#39'COMANDA'#39' and ativo = 1 group by descricao li' +
        'mit 1) as impressora_separado,'
      
        '(select CONCAT(group_concat(codigo),'#39','#39') from impressoras where ' +
        'upper(descricao) = '#39'DELIVERY'#39' and ativo = 1 limit 1) as impresso' +
        'ra_delivery,'
      ''
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
        'ps.codigo_pedido_produto, tp.descricao')
    Left = 360
    Top = 8
    ParamData = <
      item
        Name = 'CODIGO_PEDIDO'
        ParamType = ptInput
      end>
  end
  object COMANDA80MM: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 2540
    PrinterSetup.mmMarginLeft = 2540
    PrinterSetup.mmMarginRight = 2540
    PrinterSetup.mmMarginTop = 2540
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    PreviewFormSettings.PageSeparation = 1
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 74
    Top = 8
    Version = '21.02'
    mmColumnWidth = 75220
    DataPipelineName = 'ppDados'
    object ppTitleBand3: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 39688
      mmPrintPosition = 0
      object ppRichText1: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs22 <db' +
          'text displayformat='#39'000000'#39'>codigo_comanda</dbtext>\b0\fs20\par'#13 +
          #10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3905
        mmLeft = 2346
        mmTop = 25929
        mmWidth = 65387
        BandType = 1
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText3: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText3'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}{\f2\fnil\fcharset0 Arial;}' +
          '{\f3\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blu' +
          'e0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\q' +
          'c\cf1\f0\fs16 <dbtext>origem_1</dbtext>\b\f1\par'#13#10'\par'#13#10#13#10'\pard\' +
          'f2 Data Pedido: <dbtext>data_pedido</dbtext> <dbtext>hora_pedido' +
          '</dbtext>\f3\par'#13#10'\f2 Cliente: <dbtext>nome</dbtext>\par'#13#10'Celula' +
          'r: <dbtext>celular</dbtext>\par'#13#10'<dbtext>qtd_pedidos_cliente</db' +
          'text>\par'#13#10'<dbtext>endereco_completo</dbtext>\par'#13#10'\f3\fs20\par'#13 +
          #10#13#10'\pard\qc\ul\f2\fs18 <dbtext>pedido_site</dbtext>\par'#13#10'\par'#13#10'\' +
          'ulnone\fs16 Itens Do Pedido\f0\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 2381
        mmTop = 34616
        mmWidth = 65352
        BandType = 1
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText1: TppDBText
        DesignLayer = ppDesignLayer1
        UserName = 'DBText1'
        Border.mmPadding = 0
        Color = clBlack
        DataField = 'tipo_pedido'
        DataPipeline = ppDados
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 0
        mmTop = 30405
        mmWidth = 76994
        BandType = 1
        LayerName = Foreground
      end
      object ppRichText2: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText2'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generat' +
          'or Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbt' +
          'ext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0' +
          '\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <db' +
          'text datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\par'#13#10'<dbtext data' +
          'pipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>bairro</' +
          'dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <' +
          'dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtext> <dbtext datapi' +
          'peline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>ie</dbtext>\par'#13#10#13#10'\pard\b\f2\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 24380
        mmLeft = 2381
        mmTop = 794
        mmWidth = 65591
        BandType = 1
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand1: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand1: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3175
      mmPrintPosition = 0
      object ppRichText7: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText8'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText8'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\*\generator Riched20 1' +
          '0.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs20 [<dbtext>tipo</dbtext' +
          '>] - <dbtext>descricao</dbtext>\par'#13#10'\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3473
        mmLeft = 2506
        mmTop = 0
        mmWidth = 65780
        BandType = 4
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand7: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand6: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4233
      mmPrintPosition = 0
      object ppSubReport11: TppSubReport
        DesignLayer = ppDesignLayer1
        UserName = 'SubReport11'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppDados'
        mmHeight = 5027
        mmLeft = 0
        mmTop = -794
        mmWidth = 75220
        BandType = 7
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport11: TppChildReport
          AutoStop = False
          DataPipeline = ppDados
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '80mm'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 2540
          PrinterSetup.mmMarginLeft = 2540
          PrinterSetup.mmMarginRight = 2540
          PrinterSetup.mmMarginTop = 2540
          PrinterSetup.mmPaperHeight = 4003900
          PrinterSetup.mmPaperWidth = 80300
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppDados'
          object ppTitleiFood: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 49742
            mmPrintPosition = 0
            object pp2DBarCode2: Tpp2DBarCode
              DesignLayer = ppDesignLayer33
              UserName = 'TwoDBarCode1'
              AlignBarcode = ahLeft
              AutoScale = True
              AutoSize = False
              Border.mmPadding = 0
              Color = clBlack
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = []
              ReprintOnOverFlow = True
              Transparent = True
              BarCodeType = bcQRCode
              Data = 'https://confirmacao-entrega-propria.ifood.com.br/'
              PrintHumanReadable = False
              MaxiCodeSettings.CarrierPostalCode = '000000000'
              MaxiCodeSettings.HorPixelsPerMM = 4.000000000000000000
              MaxiCodeSettings.VerPixelsPerMM = 4.000000000000000000
              MaxiCodeSettings.mmBarHeight = 1059
              MaxiCodeSettings.mmBarWidth = 1059
              MaxiCodeSettings.mmQuietZone = 2118
              PDF417Settings.RelativeBarHeight = True
              PDF417Settings.mmBarHeight = 2118
              PDF417Settings.mmBarWidth = 530
              PDF417Settings.mmQuietZone = 2118
              QRCodeSettings.IncludeBOM = True
              QRCodeSettings.mmModuleSize = 1059
              QRCodeSettings.mmQuietZone = 1059
              QRCodeSettings.ECICode = -1
              DataMatrixSettings.mmModuleSize = 1059
              DataMatrixSettings.mmQuietZone = 1059
              AztecCodeSettings.mmModuleSize = 1600
              mmHeight = 16423
              mmLeft = 2381
              mmTop = 15142
              mmWidth = 17443
              BandType = 1
              LayerName = Foreground7
            end
            object ppRichText66: TppRichText
              DesignLayer = ppDesignLayer33
              UserName = 'RichText66'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText66'
              ExportRTFAsBitmap = False
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\colortbl ;\red0\gr' +
                'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
                #10'\pard\cf1\f0\fs16 Ap\f1\'#39'f3s a confirma\'#39'e7\'#39'e3o de chegada, vo' +
                'c\'#39'ea vai precisar do c\'#39'f3digo localizador do pedido que est\'#39'e' +
                '1 na comanda e do c\'#39'f3digo de seguran\'#39'e7a do cliente.\par'#13#10'\b ' +
                'Escanei o QRCode:\b0\f0\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 14383
              mmLeft = 2346
              mmTop = 529
              mmWidth = 66917
              BandType = 1
              LayerName = Foreground7
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppRichText67: TppRichText
              DesignLayer = ppDesignLayer33
              UserName = 'RichText67'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText67'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*' +
                '\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f' +
                's18 iFood\b0\fs20\par'#13#10'\b\fs16 <dbtext datapipeline='#39'ppDados'#39' di' +
                'splayformat='#39'!9999-9999;0; '#39'>ifoodlocalizador</dbtext> (<dbtext ' +
                'datapipeline='#39'ppDados'#39'>ifoodpedido</dbtext>)\fs20\par'#13#10#13#10'\pard\f' +
                's16 Telefone\b0 : <dbtext datapipeline='#39'ppDados'#39'>ifoodphone</dbt' +
                'ext>\fs20\par'#13#10'\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 23548
              mmLeft = 2381
              mmTop = 32015
              mmWidth = 66611
              BandType = 1
              LayerName = Foreground7
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppDetailBand33: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand33: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 77258
            mmPrintPosition = 0
            object ppLabel31: TppLabel
              DesignLayer = ppDesignLayer33
              UserName = 'Label3'
              Border.mmPadding = 0
              Caption = 'Total Dos Itens'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 5027
              mmWidth = 17992
              BandType = 7
              LayerName = Foreground7
            end
            object ppRichText20: TppRichText
              DesignLayer = ppDesignLayer33
              UserName = 'RichText201'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText201'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
                'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
                'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 TOTAL\f1\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5292
              mmLeft = 1588
              mmTop = -265
              mmWidth = 67019
              BandType = 7
              LayerName = Foreground7
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppDBText24: TppDBText
              DesignLayer = ppDesignLayer33
              UserName = 'DBText1'
              Border.mmPadding = 0
              DataField = 'vl_pedido'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 5027
              mmWidth = 38457
              BandType = 7
              LayerName = Foreground7
            end
            object ppLabel32: TppLabel
              DesignLayer = ppDesignLayer33
              UserName = 'Label4'
              Border.mmPadding = 0
              Caption = 'Taxa de Entrega'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 8731
              mmWidth = 19050
              BandType = 7
              LayerName = Foreground7
            end
            object ppDBText25: TppDBText
              DesignLayer = ppDesignLayer33
              UserName = 'DBText2'
              Border.mmPadding = 0
              DataField = 'vl_taxa'
              DataPipeline = ppDados
              DisplayFormat = '+$#,0.00;-+$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 8731
              mmWidth = 38457
              BandType = 7
              LayerName = Foreground7
            end
            object ppLabel33: TppLabel
              DesignLayer = ppDesignLayer33
              UserName = 'Label5'
              Border.mmPadding = 0
              Caption = 'Valor Desconto'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2910
              mmLeft = 2381
              mmTop = 12171
              mmWidth = 18521
              BandType = 7
              LayerName = Foreground7
            end
            object ppDBText27: TppDBText
              DesignLayer = ppDesignLayer33
              UserName = 'DBText3'
              Border.mmPadding = 0
              DataField = 'vl_desconto'
              DataPipeline = ppDados
              DisplayFormat = '-$#,0.00;--$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 12435
              mmWidth = 38457
              BandType = 7
              LayerName = Foreground7
            end
            object ppLabel34: TppLabel
              DesignLayer = ppDesignLayer33
              UserName = 'Label6'
              Border.mmPadding = 0
              Caption = 'Valor Total'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4234
              mmLeft = 2381
              mmTop = 15610
              mmWidth = 18521
              BandType = 7
              LayerName = Foreground7
            end
            object ppDBText28: TppDBText
              DesignLayer = ppDesignLayer33
              UserName = 'DBText4'
              Border.mmPadding = 0
              DataField = 'vl_total'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 5556
              mmLeft = 30427
              mmTop = 15610
              mmWidth = 38457
              BandType = 7
              LayerName = Foreground7
            end
            object ppRichText21: TppRichText
              DesignLayer = ppDesignLayer33
              UserName = 'RichText1'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 9
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText1'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\colortbl ;\red0\gr' +
                'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
                #10'\pard\qc\cf1\b\fs18 Forma de Pagamento\f1\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5027
              mmLeft = 2381
              mmTop = 21431
              mmWidth = 66815
              BandType = 7
              LayerName = Foreground7
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object pLabelTroco2: TppDBText
              DesignLayer = ppDesignLayer33
              UserName = 'labelTroco2'
              Border.mmPadding = 0
              DataField = 'troco'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 26458
              mmWidth = 38457
              BandType = 7
              LayerName = Foreground7
            end
            object pLabelTroco1: TppLabel
              DesignLayer = ppDesignLayer33
              UserName = 'labelTroco1'
              Border.mmPadding = 0
              Caption = 'Troco'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 26458
              mmWidth = 6879
              BandType = 7
              LayerName = Foreground7
            end
            object ppLine16: TppLine
              DesignLayer = ppDesignLayer33
              UserName = 'Line1'
              Border.mmPadding = 0
              Pen.Style = psDot
              Weight = 0.750000000000000000
              mmHeight = 2117
              mmLeft = -1323
              mmTop = 74348
              mmWidth = 85196
              BandType = 7
              LayerName = Foreground7
            end
            object ppSystemVariable7: TppSystemVariable
              DesignLayer = ppDesignLayer33
              UserName = 'SystemVariable7'
              Border.mmPadding = 0
              VarType = vtDateTime
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 2646
              mmTop = 58453
              mmWidth = 26194
              BandType = 7
              LayerName = Foreground7
            end
            object ppSystemVariable13: TppSystemVariable
              DesignLayer = ppDesignLayer33
              UserName = 'SystemVariable13'
              Border.mmPadding = 0
              VarType = vtDocumentName
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 2646
              mmTop = 54906
              mmWidth = 8996
              BandType = 7
              LayerName = Foreground7
            end
            object ppRichText88: TppRichText
              DesignLayer = ppDesignLayer33
              UserName = 'RichText4'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText4'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 <dbtex' +
                't>tipo_pagamento</dbtext>\par'#13#10'\par'#13#10'<dbtext>mp</dbtext>\par'#13#10'<d' +
                'btext>desc_desconto</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 23283
              mmLeft = 2646
              mmTop = 30956
              mmWidth = 66305
              BandType = 7
              LayerName = Foreground7
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppLabel39: TppLabel
              DesignLayer = ppDesignLayer33
              UserName = 'Label39'
              Border.mmPadding = 0
              Caption = 'goopedir.com.br'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              TextAlignment = taCentered
              Transparent = True
              mmHeight = 3704
              mmLeft = 22754
              mmTop = 69586
              mmWidth = 24342
              BandType = 7
              LayerName = Foreground7
            end
            object ppRichText68: TppRichText
              DesignLayer = ppDesignLayer33
              UserName = 'RichText68'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Arial'
              Font.Size = 12
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText68'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
                '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\b\fs20 <dbtext>bairro</d' +
                'btext>\par'#13#10#13#10'\pard\b0\f1\fs24\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 3440
              mmLeft = 2346
              mmTop = 65088
              mmWidth = 70896
              BandType = 7
              LayerName = Foreground7
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppInfo: TppLabel
              DesignLayer = ppDesignLayer33
              UserName = 'Info'
              Border.mmPadding = 0
              Caption = 'Info'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 6
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2646
              mmLeft = 2646
              mmTop = 62177
              mmWidth = 3969
              BandType = 7
              LayerName = Foreground7
            end
          end
          object ppDesignLayers33: TppDesignLayers
            object ppDesignLayer33: TppDesignLayer
              UserName = 'Foreground7'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppGroup2: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand2: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 4233
        mmPrintPosition = 0
        object ppRichText138: TppRichText
          DesignLayer = ppDesignLayer1
          UserName = 'RichText138'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText138'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\generator Riched' +
            '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>qtd</dbte' +
            'xt>un <dbtext>tipo_produto_nome</dbtext> - <dbtext>nome_produto<' +
            '/dbtext>\f1\fs14\par'#13#10'\b0\f0\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 4135
          mmLeft = 2381
          mmTop = 0
          mmWidth = 65881
          BandType = 3
          GroupNo = 0
          LayerName = Foreground
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand2: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 3969
        mmPrintPosition = 0
        object ppLine3: TppLine
          DesignLayer = ppDesignLayer1
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 753
          mmLeft = -3969
          mmTop = 3420
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = Foreground
        end
        object ppRichText23: TppRichText
          DesignLayer = ppDesignLayer1
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0' +
            '\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pa' +
            'rd\cf1\b\f0\fs16 <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>total</d' +
            'btext>\f1\par'#13#10'\cf0\b0\f0\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3310
          mmLeft = 2506
          mmTop = -75
          mmWidth = 65855
          BandType = 5
          GroupNo = 0
          LayerName = Foreground
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers1: TppDesignLayers
      object ppDesignLayer1: TppDesignLayer
        UserName = 'Foreground'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList1: TppParameterList
      object ppParameter1: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object ppDados: TppBDEPipeline
    DataSource = dsDados
    UserName = 'Dados'
    Left = 560
    Top = 8
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
      
        '(SELECT upper(descricao) FROM impressoras where codigo = (select' +
        ' impressora from tipo_produto where codigo = p.codigo_grupo)) as' +
        ' impressora,'
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
    Left = 880
    Top = 344
  end
  object ppCozinha: TppBDEPipeline
    DataSource = dsCozinha
    UserName = 'Cozinha'
    Left = 616
    Top = 8
  end
  object dsCozinha: TDataSource
    DataSet = COZINHA
    Left = 624
    Top = 64
  end
  object COZINHA56MM: TppReport
    DataPipeline = ppCozinha
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '56mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF800501000001E80B2E0264000100FFFF6400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    Template.FileName = 'C:\Users\DESENVOLVIMENTO\Desktop\56.rtm'
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    SavePrinterSetup = True
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 218
    Top = 600
    Version = '21.02'
    mmColumnWidth = 58000
    DataPipelineName = 'ppCozinha'
    object ppHeaderBand5: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 13229
      mmPrintPosition = 0
      object ppRichText41: TppRichText
        DesignLayer = ppDesignLayer13
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\f0\fs24 * * *' +
          ' <dbtext datapipeline='#39'ppCozinha'#39'>origem_pedido</dbtext> * * *\p' +
          'ar'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5025
        mmLeft = 528
        mmTop = 5032
        mmWidth = 50086
        BandType = 0
        LayerName = BandLayer12
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLine10: TppLine
        DesignLayer = ppDesignLayer13
        UserName = 'Line1'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2114
        mmLeft = -531
        mmTop = 1854
        mmWidth = 82550
        BandType = 0
        LayerName = BandLayer12
      end
      object ppLine14: TppLine
        DesignLayer = ppDesignLayer13
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = 0
        mmTop = 11113
        mmWidth = 82550
        BandType = 0
        LayerName = BandLayer12
      end
    end
    object ppDetailBand5: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4763
      mmPrintPosition = 0
      object ppSubReport5: TppSubReport
        DesignLayer = ppDesignLayer13
        UserName = 'SubReport1'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppCozinha'
        mmHeight = 5027
        mmLeft = 0
        mmTop = -265
        mmWidth = 52000
        BandType = 4
        LayerName = BandLayer12
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport5: TppChildReport
          AutoStop = False
          DataPipeline = ppCozinha
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '56mm'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 0
          PrinterSetup.mmMarginLeft = 0
          PrinterSetup.mmMarginRight = 0
          PrinterSetup.mmMarginTop = 0
          PrinterSetup.mmPaperHeight = 4003900
          PrinterSetup.mmPaperWidth = 52000
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF800501000001E80B2E0264000100FFFF6400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppCozinha'
          object ppTitleBand8: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppDetailBand10: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 3175
            mmPrintPosition = 0
            object ppRichText43: TppRichText
              DesignLayer = ppDesignLayer5
              UserName = 'RichText31'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText31'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
                '1 '#13#10'\pard\b\f0\fs16 - <dbtext>descricao</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 3397
              mmLeft = 4347
              mmTop = -265
              mmWidth = 45598
              BandType = 4
              LayerName = BandLayer11
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppSummaryBand5: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppGroup6: TppGroup
            BreakName = 'codigo'
            DataPipeline = ppCozinha
            GroupFileSettings.NewFile = False
            GroupFileSettings.EmailFile = False
            KeepTogether = True
            OutlineSettings.CreateNode = True
            StartOnOddPage = False
            UserName = 'Group6'
            mmNewColumnThreshold = 0
            mmNewPageThreshold = 0
            DataPipelineName = 'ppCozinha'
            NewFile = False
            object ppGroupHeaderBand6: TppGroupHeaderBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              PrintHeight = phDynamic
              mmBottomOffset = 0
              mmHeight = 4233
              mmPrintPosition = 0
              object ppRichText42: TppRichText
                DesignLayer = ppDesignLayer5
                UserName = 'RichText42'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Arial'
                Font.Size = 8
                Font.Style = [fsBold]
                Border.mmPadding = 0
                Caption = 'RichText42'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
                  '1 '#13#10'\pard\b\f0\fs16 <dbtext>qtd</dbtext>Un - <dbtext>produto</db' +
                  'text>\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Stretch = True
                Transparent = True
                mmHeight = 3437
                mmLeft = 4233
                mmTop = 794
                mmWidth = 45496
                BandType = 3
                GroupNo = 0
                LayerName = BandLayer11
                mmBottomOffset = 0
                mmOverFlowOffset = 0
                mmStopPosition = 0
                mmMinHeight = 0
              end
            end
            object ppGroupFooterBand6: TppGroupFooterBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              HideWhenOneDetail = False
              mmBottomOffset = 0
              mmHeight = 2381
              mmPrintPosition = 0
              object ppLine15: TppLine
                DesignLayer = ppDesignLayer5
                UserName = 'Line13'
                Border.mmPadding = 0
                Pen.Style = psDot
                Weight = 0.750000000000000000
                mmHeight = 2117
                mmLeft = 0
                mmTop = 0
                mmWidth = 82550
                BandType = 5
                GroupNo = 0
                LayerName = BandLayer11
              end
            end
          end
          object ppGroup4: TppGroup
            BreakName = 'nomeclatura'
            DataPipeline = ppCozinha
            GroupFileSettings.NewFile = False
            GroupFileSettings.EmailFile = False
            KeepTogether = True
            OutlineSettings.CreateNode = True
            StartOnOddPage = False
            UserName = 'Group5'
            mmNewColumnThreshold = 0
            mmNewPageThreshold = 0
            DataPipelineName = 'ppCozinha'
            NewFile = False
            object ppGroupHeaderBand4: TppGroupHeaderBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              PrintHeight = phDynamic
              mmBottomOffset = 0
              mmHeight = 3704
              mmPrintPosition = 0
              object ppRichText44: TppRichText
                DesignLayer = ppDesignLayer5
                UserName = 'RichText1'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Arial'
                Font.Size = 8
                Font.Style = [fsBold]
                Border.mmPadding = 0
                Caption = 'RichText1'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
                  '1 '#13#10'\pard\b\f0\fs16 <dbtext>nomeclatura</dbtext>\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Transparent = True
                mmHeight = 3274
                mmLeft = 4233
                mmTop = 429
                mmWidth = 45700
                BandType = 3
                GroupNo = 1
                LayerName = BandLayer11
                mmBottomOffset = 0
                mmOverFlowOffset = 0
                mmStopPosition = 0
                mmMinHeight = 0
              end
            end
            object ppGroupFooterBand4: TppGroupFooterBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              HideWhenOneDetail = False
              mmBottomOffset = 0
              mmHeight = 0
              mmPrintPosition = 0
            end
          end
          object ppDesignLayers5: TppDesignLayers
            object ppDesignLayer5: TppDesignLayer
              UserName = 'BandLayer11'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppFooterBand5: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand7: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 22225
      mmPrintPosition = 0
      object ppSystemVariable5: TppSystemVariable
        DesignLayer = ppDesignLayer13
        UserName = 'SystemVariable5'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 14023
        mmWidth = 26194
        BandType = 7
        LayerName = BandLayer12
      end
      object ppSystemVariable16: TppSystemVariable
        DesignLayer = ppDesignLayer13
        UserName = 'SystemVariable16'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 10319
        mmWidth = 8996
        BandType = 7
        LayerName = BandLayer12
      end
      object ppDBText26: TppDBText
        DesignLayer = ppDesignLayer13
        UserName = 'DBText26'
        Border.mmPadding = 0
        DataField = 'impressora'
        DataPipeline = ppCozinha
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCozinha'
        mmHeight = 3440
        mmLeft = 1852
        mmTop = 6879
        mmWidth = 41275
        BandType = 7
        LayerName = BandLayer12
      end
      object ppLabelUsuario56: TppLabel
        DesignLayer = ppDesignLayer13
        UserName = 'LabelUsuario56'
        Border.mmPadding = 0
        Caption = 'LabelUsuario56'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 17463
        mmWidth = 9525
        BandType = 7
        LayerName = BandLayer12
      end
    end
    object ppDesignLayers10: TppDesignLayers
      object ppDesignLayer13: TppDesignLayer
        UserName = 'BandLayer12'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList5: TppParameterList
      object ppParameter4: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
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
    Left = 1024
    Top = 216
  end
  object ppFechamentoCaixaCabechado: TppBDEPipeline
    DataSource = dsFechamentoCaixaCabechado
    UserName = 'FechamentoCaixaCabechado'
    Left = 1728
    Top = 720
  end
  object CAIXA80MM: TppReport
    AutoStop = False
    DataPipeline = ppFechamentoCaixaCabechado
    PrinterSetup.BinName = 'Bobina'
    PrinterSetup.DocumentName = 'CAIXA 80MM'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Screen'
    PrinterSetup.SaveDeviceSettings = False
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 2540
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 254001
    PrinterSetup.mmPaperWidth = 72000
    PrinterSetup.PaperSize = 256
    Units = utPrinterPixels
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 1136
    Top = 24
    Version = '21.02'
    mmColumnWidth = 59300
    DataPipelineName = 'ppFechamentoCaixaCabechado'
    object ppTitleBand4: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 23548
      mmPrintPosition = 0
      object ppRichText15: TppRichText
        DesignLayer = ppDesignLayer14
        UserName = 'RichText2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        KeepTogether = True
        Border.mmPadding = 0
        Caption = 'RichText2'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs28 FECHAMENTO DE CAIXA\par'#13#10#13#10'\' +
          'pard\f1\fs24\par'#13#10#13#10'\pard\qc\f0 CAIXA N\'#39'ba<dbtext displayformat' +
          '='#39'000'#39'>id_1</dbtext>\par'#13#10#13#10'\pard\fs20 ABERTURA\par'#13#10'<dbtext>dat' +
          'a_abertura</dbtext> <dbtext>hora</dbtext>\par'#13#10'<dbtext displayfo' +
          'rmat='#39'$ #,0.00;-$ #,0.00'#39'>valor_abertura</dbtext>\par'#13#10'\fs0 .\fs' +
          '24\par'#13#10'\fs20 FECHAMENTO\par'#13#10'<dbtext>data_fechamento</dbtext> <' +
          'dbtext>hora_fechamento</dbtext>\par'#13#10'<dbtext displayformat='#39'$ #,' +
          '0.00;-$ #,0.00'#39'>valor_fechamento</dbtext>\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 23548
        mmLeft = 265
        mmTop = 0
        mmWidth = 68792
        BandType = 1
        LayerName = BandLayer15
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand2: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand2: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 2910
      mmPrintPosition = 0
      object ppRichText14: TppRichText
        DesignLayer = ppDesignLayer14
        UserName = 'RichText14'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText14'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 ' +
          '<dbtext>descricao_utf8</dbtext>\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 2841
        mmLeft = 265
        mmTop = 0
        mmWidth = 50990
        BandType = 4
        LayerName = BandLayer15
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText28: TppRichText
        DesignLayer = ppDesignLayer14
        UserName = 'RichText28'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText28'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\*\generator Riched20 10.0.190' +
          '41}\viewkind4\uc1 '#13#10'\pard\qr\b\f0\fs16 <dbtext displayformat='#39'$#' +
          ',0.00;-$#,0.00'#39'>valor</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 2829
        mmLeft = 51464
        mmTop = 0
        mmWidth = 16775
        BandType = 4
        LayerName = BandLayer15
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand2: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand9: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 8731
      mmPrintPosition = 0
      object ppRichText13: TppRichText
        DesignLayer = ppDesignLayer14
        UserName = 'RichText13'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText13'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\cf1\b\f0\fs20 USU\'#39'c1RIO: <dbtext>nome</dbtex' +
          't>\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4170
        mmLeft = 265
        mmTop = 265
        mmWidth = 68713
        BandType = 7
        LayerName = BandLayer15
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppSystemVariable1: TppSystemVariable
        DesignLayer = ppDesignLayer14
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4234
        mmLeft = 14552
        mmTop = 4233
        mmWidth = 40217
        BandType = 7
        LayerName = BandLayer15
      end
    end
    object ppGroup3: TppGroup
      BreakName = 'tipo'
      DataPipeline = ppFechamentoCaixaCabechado
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      ReprintOnSubsequentPage = False
      StartOnOddPage = False
      UserName = 'Group1'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppFechamentoCaixaCabechado'
      NewFile = False
      object ppGroupHeaderBand3: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 3175
        mmPrintPosition = 0
        object ppRichText31: TppRichText
          DesignLayer = ppDesignLayer14
          UserName = 'RichText1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText1'
          Color = clBlack
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
            'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs' +
            '20 <dbtext>descricao_tipo</dbtext>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          mmHeight = 3503
          mmLeft = 265
          mmTop = 0
          mmWidth = 68997
          BandType = 3
          GroupNo = 0
          LayerName = BandLayer15
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand3: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 6085
        mmPrintPosition = 0
        object ppDBCalc1: TppDBCalc
          DesignLayer = ppDesignLayer14
          UserName = 'DBCalc1'
          Border.mmPadding = 0
          DataField = 'valor'
          DataPipeline = ppFechamentoCaixaCabechado
          DisplayFormat = '$#,0.00;-$#,0.00'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Courier New'
          Font.Size = 10
          Font.Style = [fsBold]
          ResetGroup = ppGroup3
          TextAlignment = taRightJustified
          Transparent = True
          DataPipelineName = 'ppFechamentoCaixaCabechado'
          mmHeight = 3548
          mmLeft = 42069
          mmTop = 265
          mmWidth = 26194
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer15
        end
        object ppLabel4: TppLabel
          DesignLayer = ppDesignLayer14
          UserName = 'Label1'
          Border.mmPadding = 0
          Caption = 'Total'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Courier New'
          Font.Size = 10
          Font.Style = [fsBold]
          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
          FormFieldSettings.FormFieldType = fftNone
          TextAlignment = taRightJustified
          Transparent = True
          mmHeight = 3568
          mmLeft = 265
          mmTop = 265
          mmWidth = 10583
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer15
        end
        object ppLine4: TppLine
          DesignLayer = ppDesignLayer14
          UserName = 'Line4'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 929
          mmLeft = -11942
          mmTop = 4654
          mmWidth = 90322
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer15
        end
      end
    end
    object ppDesignLayers12: TppDesignLayers
      object ppDesignLayer14: TppDesignLayer
        UserName = 'BandLayer15'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList2: TppParameterList
    end
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
    object IMPRESSAOURL: TStringField
      FieldName = 'URL'
      Size = 255
    end
  end
  object COZINHA80MM: TppReport
    DataPipeline = ppCozinha
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Printer Paper(80(72) x 3276mm)'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3275900
    PrinterSetup.mmPaperWidth = 71900
    PrinterSetup.PaperSize = 210
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010090003308230364000100FFFF6400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    Template.FileName = 'C:\Users\DESENVOLVIMENTO\Desktop\56.rtm'
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    SavePrinterSetup = True
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 50
    Top = 608
    Version = '21.02'
    mmColumnWidth = 55800
    DataPipelineName = 'ppCozinha'
    object ppHeaderBand3: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 9260
      mmPrintPosition = 0
      object ppRichText8: TppRichText
        DesignLayer = ppDesignLayer4
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\f0\fs20 * * *' +
          ' <dbtext datapipeline='#39'ppCozinha'#39'>origem_pedido</dbtext> * * *\p' +
          'ar'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3801
        mmLeft = 528
        mmTop = 3910
        mmWidth = 78903
        BandType = 0
        LayerName = BandLayer21
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLine11: TppLine
        DesignLayer = ppDesignLayer4
        UserName = 'Line1'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 788
        mmLeft = -531
        mmTop = 1854
        mmWidth = 82550
        BandType = 0
        LayerName = BandLayer21
      end
      object ppLine12: TppLine
        DesignLayer = ppDesignLayer4
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1097
        mmLeft = 0
        mmTop = 8053
        mmWidth = 82550
        BandType = 0
        LayerName = BandLayer21
      end
    end
    object ppDetailBand3: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4763
      mmPrintPosition = 0
      object ppSubReport1: TppSubReport
        DesignLayer = ppDesignLayer4
        UserName = 'SubReport1'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppCozinha'
        mmHeight = 5027
        mmLeft = 0
        mmTop = -265
        mmWidth = 71900
        BandType = 4
        LayerName = BandLayer21
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport1: TppChildReport
          AutoStop = False
          DataPipeline = ppCozinha
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '80mm'
          PrinterSetup.PaperName = 'Printer Paper(80(72) x 3276mm)'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 0
          PrinterSetup.mmMarginLeft = 0
          PrinterSetup.mmMarginRight = 0
          PrinterSetup.mmMarginTop = 0
          PrinterSetup.mmPaperHeight = 3275900
          PrinterSetup.mmPaperWidth = 71900
          PrinterSetup.PaperSize = 210
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010090003308230364000100FFFF6400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppCozinha'
          object ppTitleBand1: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppDetailBand4: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 4233
            mmPrintPosition = 0
            object ppRichText11: TppRichText
              DesignLayer = ppDesignLayer3
              UserName = 'RichText31'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText31'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
                '1 '#13#10'\pard\f0\fs20 - <dbtext>descricao</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 4182
              mmLeft = 2681
              mmTop = 0
              mmWidth = 64604
              BandType = 4
              LayerName = BandLayer20
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppSummaryBand3: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 7144
            mmPrintPosition = 0
            object ppRichText87: TppRichText
              DesignLayer = ppDesignLayer3
              UserName = 'RichText87'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText87'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 <db' +
                'text>tipo</dbtext>\par'#13#10#13#10'\pard Cliente: <dbtext>celular</dbtext' +
                '> - <dbtext>nome</dbtext>\par'#13#10'Data: <dbtext>data_pedido</dbtext' +
                '> <dbtext>hora_pedido</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 6634
              mmLeft = 1588
              mmTop = 511
              mmWidth = 69906
              BandType = 7
              LayerName = BandLayer20
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppGroup1: TppGroup
            BreakName = 'codigo'
            DataPipeline = ppCozinha
            GroupFileSettings.NewFile = False
            GroupFileSettings.EmailFile = False
            KeepTogether = True
            OutlineSettings.CreateNode = True
            StartOnOddPage = False
            UserName = 'Group6'
            mmNewColumnThreshold = 0
            mmNewPageThreshold = 0
            DataPipelineName = 'ppCozinha'
            NewFile = False
            object ppGroupHeaderBand1: TppGroupHeaderBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              PrintHeight = phDynamic
              mmBottomOffset = 0
              mmHeight = 5027
              mmPrintPosition = 0
              object ppRichText12: TppRichText
                DesignLayer = ppDesignLayer3
                UserName = 'RichText42'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Arial'
                Font.Size = 12
                Font.Style = [fsBold]
                Border.mmPadding = 0
                Caption = 'RichText42'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
                  '1 '#13#10'\pard\b\f0\fs24 <dbtext>qtd</dbtext>Un - <dbtext>categoria</' +
                  'dbtext> <dbtext>produto</dbtext>\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Stretch = True
                Transparent = True
                mmHeight = 4233
                mmLeft = 2548
                mmTop = 265
                mmWidth = 66880
                BandType = 3
                GroupNo = 0
                LayerName = BandLayer20
                mmBottomOffset = 0
                mmOverFlowOffset = 0
                mmStopPosition = 0
                mmMinHeight = 0
              end
            end
            object ppGroupFooterBand1: TppGroupFooterBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              HideWhenOneDetail = False
              mmBottomOffset = 0
              mmHeight = 2117
              mmPrintPosition = 0
              object ppLine13: TppLine
                DesignLayer = ppDesignLayer3
                UserName = 'Line13'
                Border.mmPadding = 0
                Pen.Style = psDot
                Weight = 0.750000000000000000
                mmHeight = 2117
                mmLeft = 0
                mmTop = 0
                mmWidth = 82550
                BandType = 5
                GroupNo = 0
                LayerName = BandLayer20
              end
            end
          end
          object ppGroup5: TppGroup
            BreakName = 'nomeclatura'
            DataPipeline = ppCozinha
            GroupFileSettings.NewFile = False
            GroupFileSettings.EmailFile = False
            KeepTogether = True
            OutlineSettings.CreateNode = True
            StartOnOddPage = False
            UserName = 'Group5'
            mmNewColumnThreshold = 0
            mmNewPageThreshold = 0
            DataPipelineName = 'ppCozinha'
            NewFile = False
            object ppGroupHeaderBand5: TppGroupHeaderBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              PrintHeight = phDynamic
              mmBottomOffset = 0
              mmHeight = 4233
              mmPrintPosition = 0
              object ppRichText22: TppRichText
                DesignLayer = ppDesignLayer3
                UserName = 'RichText1'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Arial'
                Font.Size = 10
                Font.Style = []
                Border.mmPadding = 0
                Caption = 'RichText1'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
                  '1 '#13#10'\pard\f0\fs20 <dbtext>nomeclatura</dbtext>\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Stretch = True
                Transparent = True
                mmHeight = 3978
                mmLeft = 2342
                mmTop = 0
                mmWidth = 65048
                BandType = 3
                GroupNo = 1
                LayerName = BandLayer20
                mmBottomOffset = 0
                mmOverFlowOffset = 0
                mmStopPosition = 0
                mmMinHeight = 0
              end
            end
            object ppGroupFooterBand5: TppGroupFooterBand
              Background.Brush.Style = bsClear
              Border.mmPadding = 0
              HideWhenOneDetail = False
              mmBottomOffset = 0
              mmHeight = 0
              mmPrintPosition = 0
            end
          end
          object raCodeModule1: TraCodeModule
          end
          object ppDesignLayers3: TppDesignLayers
            object ppDesignLayer3: TppDesignLayer
              UserName = 'BandLayer20'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppFooterBand3: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand4: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 19844
      mmPrintPosition = 0
      object ppSystemVariable3: TppSystemVariable
        DesignLayer = ppDesignLayer4
        UserName = 'SystemVariable3'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3439
        mmLeft = 1852
        mmTop = 12165
        mmWidth = 29684
        BandType = 7
        LayerName = BandLayer21
      end
      object ppSystemVariable15: TppSystemVariable
        DesignLayer = ppDesignLayer4
        UserName = 'SystemVariable15'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3439
        mmLeft = 1852
        mmTop = 8869
        mmWidth = 8996
        BandType = 7
        LayerName = BandLayer21
      end
      object ppDBText16: TppDBText
        DesignLayer = ppDesignLayer4
        UserName = 'DBText16'
        Border.mmPadding = 0
        DataField = 'impressora'
        DataPipeline = ppCozinha
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCozinha'
        mmHeight = 3440
        mmLeft = 1871
        mmTop = 5451
        mmWidth = 35454
        BandType = 7
        LayerName = BandLayer21
      end
      object ppDBText31: TppDBText
        DesignLayer = ppDesignLayer4
        UserName = 'DBText31'
        Border.mmPadding = 0
        DataField = 'mesa'
        DataPipeline = ppCozinha
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCozinha'
        mmHeight = 3439
        mmLeft = 1852
        mmTop = 2117
        mmWidth = 75710
        BandType = 7
        LayerName = BandLayer21
      end
      object ppLabelUsuario80: TppLabel
        DesignLayer = ppDesignLayer4
        UserName = 'Label1'
        Border.mmPadding = 0
        Caption = 'Label1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3705
        mmLeft = 1852
        mmTop = 15610
        mmWidth = 9525
        BandType = 7
        LayerName = BandLayer21
      end
    end
    object raCodeModule2: TraCodeModule
    end
    object ppDesignLayers4: TppDesignLayers
      object ppDesignLayer4: TppDesignLayer
        UserName = 'BandLayer21'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList3: TppParameterList
      object ppParameter2: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object COMANDA56MM1: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '56mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3275900
    PrinterSetup.mmPaperWidth = 48000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 1000
    Top = 128
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppDados'
    object ppTitleBand2: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 56886
      mmPrintPosition = 0
      object ppRichText5: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText5'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText5'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\f0\fs16 * PED' +
          'IDO <dbtext displayformat='#39'000000'#39'>codigo_comanda</dbtext> *\par' +
          #13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3293
        mmLeft = 265
        mmTop = 45051
        mmWidth = 48767
        BandType = 1
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText9: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText9'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText9'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs16 <db' +
          'text>nome_estabelecimento</dbtext>\par'#13#10'<dbtext>origem_1</dbtext' +
          '>\par'#13#10'\par'#13#10#13#10'\pard Data Pedido: <dbtext>data_pedido</dbtext> <' +
          'dbtext>hora_pedido</dbtext>\par'#13#10'Cliente: <dbtext>nome</dbtext>\' +
          'par'#13#10'Celular: <dbtext>celular</dbtext>\par'#13#10'<dbtext>qtd_pedidos_' +
          'cliente</dbtext>\par'#13#10'<dbtext>endereco_completo</dbtext>\par'#13#10'\p' +
          'ar'#13#10#13#10'\pard\qc <dbtext>pedido_site</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 3191
        mmLeft = 265
        mmTop = 52992
        mmWidth = 48766
        BandType = 1
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText2: TppDBText
        DesignLayer = ppDesignLayer6
        UserName = 'DBText2'
        Border.mmPadding = 0
        Color = clBlack
        DataField = 'tipo_pedido'
        DataPipeline = ppDados
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taCentered
        DataPipelineName = 'ppDados'
        mmHeight = 3980
        mmLeft = -41
        mmTop = 48446
        mmWidth = 48052
        BandType = 1
        LayerName = Foreground1
      end
      object ppRichText4: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generat' +
          'or Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbt' +
          'ext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0' +
          '\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <db' +
          'text datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\par'#13#10'<dbtext data' +
          'pipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>bairro</' +
          'dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <' +
          'dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtext> <dbtext datapi' +
          'peline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>ie</dbtext>\par'#13#10#13#10'\pard\b\f2\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 43353
        mmLeft = 341
        mmTop = 794
        mmWidth = 46823
        BandType = 1
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand7: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 8467
      mmPrintPosition = 0
      object ppLine18: TppLine
        DesignLayer = ppDesignLayer6
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1323
        mmLeft = -3969
        mmTop = 7144
        mmWidth = 82550
        BandType = 0
        LayerName = Foreground1
      end
      object ppRichText24: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText6'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText6'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs16 PRO' +
          'DUTOS\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 2239
        mmWidth = 46061
        BandType = 0
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDetailBand6: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 2646
      mmPrintPosition = 0
      object ppRichText25: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText8'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText8'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\generator Riched' +
          '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\f0\fs18 [<dbtext>tipo</dbte' +
          'xt>] - <dbtext>descricao</dbtext>\b\par'#13#10'\b0\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 2903
        mmLeft = 1588
        mmTop = 0
        mmWidth = 42649
        BandType = 4
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand4: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand15: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 67733
      mmPrintPosition = 0
      object ppLabel1: TppLabel
        DesignLayer = ppDesignLayer6
        UserName = 'Label31'
        Border.mmPadding = 0
        Caption = 'Total Dos Itens'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 5027
        mmWidth = 21695
        BandType = 7
        LayerName = Foreground1
      end
      object ppRichText26: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText20'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText20'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 TOTAL\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5292
        mmLeft = 265
        mmTop = -265
        mmWidth = 46061
        BandType = 7
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel11: TppLabel
        DesignLayer = ppDesignLayer6
        UserName = 'Label32'
        Border.mmPadding = 0
        Caption = 'Taxa de Entrega'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 8527
        mmWidth = 23018
        BandType = 7
        LayerName = Foreground1
      end
      object ppDBText4: TppDBText
        DesignLayer = ppDesignLayer6
        UserName = 'DBText25'
        Border.mmPadding = 0
        DataField = 'vl_taxa'
        DataPipeline = ppDados
        DisplayFormat = '+$#,0.00;-+$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 10848
        mmTop = 8534
        mmWidth = 33663
        BandType = 7
        LayerName = Foreground1
      end
      object ppLabel36: TppLabel
        DesignLayer = ppDesignLayer6
        UserName = 'Label33'
        Border.mmPadding = 0
        Caption = 'Valor Desconto'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 12069
        mmWidth = 22225
        BandType = 7
        LayerName = Foreground1
      end
      object ppDBText5: TppDBText
        DesignLayer = ppDesignLayer6
        UserName = 'DBText27'
        Border.mmPadding = 0
        DataField = 'vl_desconto'
        DataPipeline = ppDados
        DisplayFormat = '-$#,0.00;--$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 10848
        mmTop = 12136
        mmWidth = 33663
        BandType = 7
        LayerName = Foreground1
      end
      object ppLabel37: TppLabel
        DesignLayer = ppDesignLayer6
        UserName = 'Label34'
        Border.mmPadding = 0
        Caption = 'Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3705
        mmLeft = 1588
        mmTop = 15610
        mmWidth = 7143
        BandType = 7
        LayerName = Foreground1
      end
      object ppDBText6: TppDBText
        DesignLayer = ppDesignLayer6
        UserName = 'DBText28'
        Border.mmPadding = 0
        DataField = 'vl_total'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3516
        mmLeft = 10848
        mmTop = 15617
        mmWidth = 33459
        BandType = 7
        LayerName = Foreground1
      end
      object ppRichText27: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText21'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText21'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs16 FOR' +
          'MA DE PAGAMENTO\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3395
        mmLeft = 306
        mmTop = 21532
        mmWidth = 47434
        BandType = 7
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText34: TppDBText
        DesignLayer = ppDesignLayer6
        UserName = 'DBText29'
        Border.mmPadding = 0
        DataField = 'troco'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 11502
        mmTop = 26667
        mmWidth = 32793
        BandType = 7
        LayerName = Foreground1
      end
      object ppDBText35: TppDBText
        DesignLayer = ppDesignLayer6
        UserName = 'DBText33'
        Border.mmPadding = 0
        DataField = 'tipo_pagamento'
        DataPipeline = ppDados
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taCentered
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 4763
        mmLeft = 58
        mmTop = 30602
        mmWidth = 47694
        BandType = 7
        LayerName = Foreground1
      end
      object ppLabel38: TppLabel
        DesignLayer = ppDesignLayer6
        UserName = 'Label35'
        Border.mmPadding = 0
        Caption = 'Troco'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 26723
        mmWidth = 8466
        BandType = 7
        LayerName = Foreground1
      end
      object ppLine19: TppLine
        DesignLayer = ppDesignLayer6
        UserName = 'Line16'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = 0
        mmTop = 64488
        mmWidth = 85196
        BandType = 7
        LayerName = Foreground1
      end
      object ppSystemVariable8: TppSystemVariable
        DesignLayer = ppDesignLayer6
        UserName = 'SystemVariable8'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 55563
        mmWidth = 26194
        BandType = 7
        LayerName = Foreground1
      end
      object ppSystemVariable14: TppSystemVariable
        DesignLayer = ppDesignLayer6
        UserName = 'SystemVariable14'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3705
        mmLeft = 1852
        mmTop = 51858
        mmWidth = 8996
        BandType = 7
        LayerName = Foreground1
      end
      object ppDBText3: TppDBText
        DesignLayer = ppDesignLayer6
        UserName = 'DBText24'
        Border.mmPadding = 0
        DataField = 'vl_pedido'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 10848
        mmTop = 5027
        mmWidth = 33867
        BandType = 7
        LayerName = Foreground1
      end
      object ppRichText89: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText89'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText89'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 <dbtex' +
          't>mp</dbtext>\par'#13#10'<dbtext>desc_desconto</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 15610
        mmLeft = 1852
        mmTop = 35719
        mmWidth = 47096
        BandType = 7
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel66: TppLabel
        DesignLayer = ppDesignLayer6
        UserName = 'Label66'
        HyperlinkColor = clBlack
        Border.mmPadding = 0
        Caption = 'www.goopedir.com.br'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 7938
        mmTop = 60590
        mmWidth = 33072
        BandType = 7
        LayerName = Foreground1
      end
    end
    object ppGroup7: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand7: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 2910
        mmPrintPosition = 0
        object ppRichText29: TppRichText
          DesignLayer = ppDesignLayer6
          UserName = 'RichText7'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText7'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\*\generator Riched20 1' +
            '0.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs14 <dbtext>qtd</dbtext>u' +
            'n - <dbtext>nome_produto</dbtext>\f1\fs20\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 2725
          mmLeft = 1588
          mmTop = 0
          mmWidth = 42649
          BandType = 3
          GroupNo = 0
          LayerName = Foreground1
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand7: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 3969
        mmPrintPosition = 0
        object ppLine20: TppLine
          DesignLayer = ppDesignLayer6
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 563
          mmLeft = -3969
          mmTop = 3406
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = Foreground1
        end
        object ppRichText30: TppRichText
          DesignLayer = ppDesignLayer6
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
            ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qr\cf1\b\f0\fs16 <db' +
            'text displayformat='#39'#,0.00;-#,0.00'#39'>total</dbtext>\par'#13#10#13#10'\pard\' +
            'cf0\b0\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3601
          mmLeft = 1588
          mmTop = 231
          mmWidth = 42649
          BandType = 5
          GroupNo = 0
          LayerName = Foreground1
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers6: TppDesignLayers
      object ppDesignLayer6: TppDesignLayer
        UserName = 'Foreground1'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList7: TppParameterList
      object ppParameter5: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CONFERENCIA80MM1: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 254000506
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    PreviewFormSettings.PageSeparation = 1
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 1064
    Top = 24
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppDados'
    object ppTitleBand5: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 6085
      mmPrintPosition = 0
      object ppRichText18: TppRichText
        DesignLayer = ppDesignLayer2
        UserName = 'RichText3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText3'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}{\f3\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blu' +
          'e0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\q' +
          'c\cf1\b\fs18 <dbtext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1' +
          '\fs26\par'#13#10'\b0\f0\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>' +
          'cnpj</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\' +
          'par'#13#10'<dbtext datapipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext da' +
          'tapipeline='#39'ppCabecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>bairro</dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>ci' +
          'dade</dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtex' +
          't> <dbtext datapipeline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext d' +
          'atapipeline='#39'ppCabecalho'#39'>ie</dbtext>\par'#13#10'\b\f2\fs14\par'#13#10#13#10'\pa' +
          'rd\f0 Data: <dbtext>data_pedido</dbtext> <dbtext>hora_pedido</db' +
          'text>\par'#13#10'\f1\par'#13#10#13#10'\pard\qc\f3\fs20 <dbtext>desc_ficha</dbtex' +
          't>\f2\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 3264
        mmTop = 1058
        mmWidth = 64469
        BandType = 1
        LayerName = Foreground2
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand4: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand7: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4233
      mmPrintPosition = 0
      object ppRichText32: TppRichText
        DesignLayer = ppDesignLayer2
        UserName = 'RichText32'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText32'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\b\f0\fs16 [<dbtext>tipo</dbtext>] - <dbtext>descricao<' +
          '/dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4233
        mmLeft = 3264
        mmTop = 0
        mmWidth = 64469
        BandType = 4
        LayerName = Foreground2
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand1: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand1: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 36777
      mmPrintPosition = 0
      object ppRichText33: TppRichText
        DesignLayer = ppDesignLayer2
        UserName = 'RichText20'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText20'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs16 TOT' +
          'AL\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5292
        mmLeft = 3264
        mmTop = -265
        mmWidth = 64469
        BandType = 7
        LayerName = Foreground2
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel8: TppLabel
        DesignLayer = ppDesignLayer2
        UserName = 'Label34'
        Border.mmPadding = 0
        Caption = 'Servico(%)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 3264
        mmTop = 5292
        mmWidth = 18463
        BandType = 7
        LayerName = Foreground2
      end
      object ppDBText11: TppDBText
        DesignLayer = ppDesignLayer2
        UserName = 'DBText28'
        Border.mmPadding = 0
        DataField = 'servico'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 5556
        mmLeft = 28310
        mmTop = 5292
        mmWidth = 39237
        BandType = 7
        LayerName = Foreground2
      end
      object ppLabel81: TppLabel
        DesignLayer = ppDesignLayer2
        UserName = 'Label81'
        Border.mmPadding = 0
        Caption = 'Valor Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 3175
        mmTop = 9790
        mmWidth = 15610
        BandType = 7
        LayerName = Foreground2
      end
      object ppDBText30: TppDBText
        DesignLayer = ppDesignLayer2
        UserName = 'DBText30'
        Border.mmPadding = 0
        DataField = 'vl_total'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 5556
        mmLeft = 28310
        mmTop = 9726
        mmWidth = 39158
        BandType = 7
        LayerName = Foreground2
      end
      object ppSystemVariable17: TppSystemVariable
        DesignLayer = ppDesignLayer2
        UserName = 'SystemVariable17'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 3280
        mmTop = 25665
        mmWidth = 26194
        BandType = 7
        LayerName = Foreground2
      end
      object ppSystemVariable18: TppSystemVariable
        DesignLayer = ppDesignLayer2
        UserName = 'SystemVariable18'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3705
        mmLeft = 3280
        mmTop = 21960
        mmWidth = 8996
        BandType = 7
        LayerName = Foreground2
      end
      object ppLabel65: TppLabel
        DesignLayer = ppDesignLayer2
        UserName = 'Label65'
        Border.mmPadding = 0
        Caption = 'goopedir.com.br'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 3704
        mmLeft = 3264
        mmTop = 31221
        mmWidth = 64469
        BandType = 7
        LayerName = Foreground2
      end
    end
    object ppGroup8: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand8: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 3440
        mmPrintPosition = 0
        object ppRichText35: TppRichText
          DesignLayer = ppDesignLayer2
          UserName = 'RichText7'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText7'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
            '1 '#13#10'\pard\b\f0\fs16 <dbtext>tipo_produto_nome</dbtext> <dbtext>n' +
            'ome_produto</dbtext>\b0\fs20\par'#13#10'\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 4001
          mmLeft = 3264
          mmTop = 0
          mmWidth = 64367
          BandType = 3
          GroupNo = 0
          LayerName = Foreground2
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand8: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 4233
        mmPrintPosition = 0
        object ppRichText36: TppRichText
          DesignLayer = ppDesignLayer2
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 8
          Font.Style = [fsBold]
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
            '1 '#13#10'\pard\qr\b\f0\fs12 <dbtext>qtd</dbtext>Un X <dbtext displayf' +
            'ormat='#39'#,0.00;-#,0.00'#39'>vl_unitario</dbtext> = <dbtext displayfor' +
            'mat='#39'#,0.00;-#,0.00'#39'>total</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 2910
          mmLeft = 3264
          mmTop = 231
          mmWidth = 64469
          BandType = 5
          GroupNo = 0
          LayerName = Foreground2
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers2: TppDesignLayers
      object ppDesignLayer2: TppDesignLayer
        UserName = 'Foreground2'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList4: TppParameterList
      object ppParameter3: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CONFERENCIA56MM: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '56mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3276000
    PrinterSetup.mmPaperWidth = 58000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 210
    Top = 96
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppDados'
    object ppTitleBand6: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 55563
      mmPrintPosition = 0
      object ppRichText34: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText5'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText5'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\f0\fs20 * * *' +
          ' <dbtext>desc_ficha</dbtext> * * *\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 0
        mmTop = 44715
        mmWidth = 52432
        BandType = 1
        LayerName = BandLayer9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText37: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText9'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText9'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20\par' +
          #13#10'<dbtext>origem_1</dbtext>\par'#13#10'\par'#13#10#13#10'\pard Data: <dbtext>dat' +
          'a_pedido</dbtext> <dbtext>hora_pedido</dbtext>\par'#13#10#13#10'\pard\qc\p' +
          'ar'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 0
        mmTop = 50006
        mmWidth = 52228
        BandType = 1
        LayerName = BandLayer9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText17: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText17'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText17'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generat' +
          'or Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbt' +
          'ext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0' +
          '\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <db' +
          'text datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\par'#13#10'<dbtext data' +
          'pipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>bairro</' +
          'dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <' +
          'dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtext> <dbtext datapi' +
          'peline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>ie</dbtext>\par'#13#10#13#10'\pard\b\f2\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 43353
        mmLeft = 265
        mmTop = 794
        mmWidth = 46823
        BandType = 1
        LayerName = BandLayer9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand6: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 5821
      mmPrintPosition = 0
      object ppLine9: TppLine
        DesignLayer = ppDesignLayer7
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1323
        mmLeft = -6009
        mmTop = 4492
        mmWidth = 82550
        BandType = 0
        LayerName = BandLayer9
      end
      object ppRichText38: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText6'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText6'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs16 PRO' +
          'DUTOS\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3395
        mmLeft = 265
        mmTop = 505
        mmWidth = 51922
        BandType = 0
        LayerName = BandLayer9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDetailBand8: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3969
      mmPrintPosition = 0
      object ppRichText39: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText8'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText8'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\*\generator Riched20 1' +
          '0.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs14 [<dbtext>tipo</dbtext' +
          '>] - <dbtext>descricao</dbtext>\par'#13#10'\f1\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3519
        mmLeft = 1588
        mmTop = 0
        mmWidth = 50381
        BandType = 4
        LayerName = BandLayer9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand6: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand2: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 37306
      mmPrintPosition = 0
      object ppRichText40: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText20'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText20'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs18 TOT' +
          'AL\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5292
        mmLeft = 265
        mmTop = -265
        mmWidth = 50417
        BandType = 7
        LayerName = BandLayer9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel9: TppLabel
        DesignLayer = ppDesignLayer7
        UserName = 'Label34'
        Border.mmPadding = 0
        Caption = 'Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4233
        mmLeft = 265
        mmTop = 5027
        mmWidth = 8466
        BandType = 7
        LayerName = BandLayer9
      end
      object ppDBText12: TppDBText
        DesignLayer = ppDesignLayer7
        UserName = 'DBText28'
        Border.mmPadding = 0
        DataField = 'vl_total'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 4230
        mmLeft = 10054
        mmTop = 5027
        mmWidth = 40849
        BandType = 7
        LayerName = BandLayer9
      end
      object ppLine21: TppLine
        DesignLayer = ppDesignLayer7
        UserName = 'Line16'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = 265
        mmTop = 35047
        mmWidth = 85196
        BandType = 7
        LayerName = BandLayer9
      end
      object ppSystemVariable2: TppSystemVariable
        DesignLayer = ppDesignLayer7
        UserName = 'SystemVariable2'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 26458
        mmWidth = 30427
        BandType = 7
        LayerName = BandLayer9
      end
      object ppSystemVariable19: TppSystemVariable
        DesignLayer = ppDesignLayer7
        UserName = 'SystemVariable19'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 22225
        mmWidth = 8996
        BandType = 7
        LayerName = BandLayer9
      end
      object ppLabel67: TppLabel
        DesignLayer = ppDesignLayer7
        UserName = 'Label67'
        HyperlinkColor = clBlack
        Border.mmPadding = 0
        Caption = 'www.goopedir.com.br'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 3704
        mmLeft = 9260
        mmTop = 30427
        mmWidth = 33073
        BandType = 7
        LayerName = BandLayer9
      end
    end
    object ppGroup9: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand9: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 2910
        mmPrintPosition = 0
        object ppRichText46: TppRichText
          DesignLayer = ppDesignLayer7
          UserName = 'RichText7'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText7'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
            '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\fs16 <dbtext>nome_produto' +
            '</dbtext>\par'#13#10'\b0\f1\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3225
          mmLeft = 1588
          mmTop = -529
          mmWidth = 50381
          BandType = 3
          GroupNo = 0
          LayerName = BandLayer9
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand9: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 4763
        mmPrintPosition = 0
        object ppLine22: TppLine
          DesignLayer = ppDesignLayer7
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 1323
          mmLeft = -3969
          mmTop = 3426
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer9
        end
        object ppRichText47: TppRichText
          DesignLayer = ppDesignLayer7
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          KeepTogether = True
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
            '1 '#13#10'\pard\b\f0\fs14 <dbtext>qtd</dbtext>Un X <dbtext displayform' +
            'at='#39'#,0.00;-#,0.00'#39'>vl_unitario</dbtext>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3169
          mmLeft = 1588
          mmTop = 231
          mmWidth = 50381
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer9
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers7: TppDesignLayers
      object ppDesignLayer7: TppDesignLayer
        UserName = 'BandLayer9'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList6: TppParameterList
      object ppParameter6: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
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
      
        '(select sum(pl.valor_taxa_entrega) from pedido as pl where pl.id' +
        '_caixa = c.id and pl.codigo_cliente_endereco > 0) as taxa_entreg' +
        'a,'
      
        '(c.valor_fechamento-(select sum(pl.valor_total_pedido) from pedi' +
        'do as pl where pl.id_caixa = c.id)) as valor_diferenca'
      'from caixa as c'
      'join caixa_movimento as cm on cm.id_caixa = c.id'
      'join pedido as p on p.codigo = cm.id_pedido'
      'join tipo_pagamento as tp on tp.codigo = cm.id_tipo_pagamento'
      'where c.id = 26 and cm.tipo = 1'
      'group by tp.codigo, tp.descricao')
    Left = 1064
    Top = 280
  end
  object ppResumo: TppBDEPipeline
    DataSource = dsResumo
    UserName = 'Resumo'
    Left = 1488
    Top = 728
  end
  object dsResumo: TDataSource
    DataSet = CAIXA_RESUMO
    Left = 1064
    Top = 344
  end
  object CAIXA_RESUMO80MM: TppReport
    AutoStop = False
    DataPipeline = ppResumo
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 2540
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 58
    Top = 207
    Version = '21.02'
    mmColumnWidth = 66548
    DataPipelineName = 'ppResumo'
    object ppTitleBand7: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 61913
      mmPrintPosition = 0
      object ppRichText16: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0\fs16 CNPJ: <dbtext dat' +
          'apipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>razao</dbtext>\par'#13#10'<dbtext datapipeline='#39'ppCabecalho'#39'>' +
          'rua</dbtext>, <dbtext datapipeline='#39'ppCabecalho'#39'>rua</dbtext> <d' +
          'btext datapipeline='#39'ppCabecalho'#39'>bairro</dbtext> - <dbtext datap' +
          'ipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <dbtext datapipeline='#39'pp' +
          'Cabecalho'#39'>estado</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>ce' +
          'p</dbtext> IE: <dbtext datapipeline='#39'ppCabecalho'#39'>ie</dbtext>\pa' +
          'r'#13#10'\fs20\par'#13#10'Fechamento de Caixa\par'#13#10'\b\fs26 #<dbtext displayf' +
          'ormat='#39'000'#39'>id</dbtext>\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 33561
        mmLeft = 1896
        mmTop = 0
        mmWidth = 66805
        BandType = 1
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel7: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Abertura:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 34925
        mmWidth = 26988
        BandType = 1
        LayerName = BandLayer13
      end
      object ppRichText45: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText45'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText45'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext>data_abertura</dbtext> <dbtext>ho' +
          'ra_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 34925
        mmWidth = 34925
        BandType = 1
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel10: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Fechamento:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 39688
        mmWidth = 26988
        BandType = 1
        LayerName = BandLayer13
      end
      object ppLabel12: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label101'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Abertura:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 44186
        mmWidth = 37306
        BandType = 1
        LayerName = BandLayer13
      end
      object ppLabel13: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label13'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Fechamento:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 48948
        mmWidth = 42069
        BandType = 1
        LayerName = BandLayer13
      end
      object ppRichText48: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText48'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText48'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext>data_fechamento</dbtext> <dbtext>' +
          'hora_fechamento</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 39423
        mmWidth = 34925
        BandType = 1
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText49: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText49'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText49'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'valor_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 44186
        mmTop = 44186
        mmWidth = 19579
        BandType = 1
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText50: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText50'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText50'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'valor_fechamento</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 44450
        mmTop = 48948
        mmWidth = 19315
        BandType = 1
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppSubReport2: TppSubReport
        DesignLayer = ppDesignLayer9
        UserName = 'SubReport2'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppComputado'
        mmHeight = 5027
        mmLeft = 0
        mmTop = 55563
        mmWidth = 77760
        BandType = 1
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport2: TppChildReport
          AutoStop = False
          DataPipeline = ppComputado
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '80mm'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 0
          PrinterSetup.mmMarginLeft = 0
          PrinterSetup.mmMarginRight = 2540
          PrinterSetup.mmMarginTop = 0
          PrinterSetup.mmPaperHeight = 4003900
          PrinterSetup.mmPaperWidth = 80300
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppComputado'
          object ppTitleBand22: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 5556
            mmPrintPosition = 0
            object ppRichText101: TppRichText
              DesignLayer = ppDesignLayer24
              UserName = 'RichText101'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 12
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText101'
              ExportRTFAsBitmap = False
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs24 Inform' +
                'ado\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5556
              mmLeft = 1852
              mmTop = 0
              mmWidth = 66675
              BandType = 1
              LayerName = Foreground3
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppHeaderBand22: TppHeaderBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppDetailBand24: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 5821
            mmPrintPosition = 0
            object ppDBText32: TppDBText
              DesignLayer = ppDesignLayer24
              UserName = 'DBText32'
              Border.mmPadding = 0
              DataField = 'descricao'
              DataPipeline = ppComputado
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 9
              Font.Style = []
              Transparent = True
              DataPipelineName = 'ppComputado'
              mmHeight = 4498
              mmLeft = 1588
              mmTop = 284
              mmWidth = 41540
              BandType = 4
              LayerName = Foreground3
            end
            object ppDBText33: TppDBText
              DesignLayer = ppDesignLayer24
              UserName = 'DBText1'
              Border.mmPadding = 0
              DataField = 'valor'
              DataPipeline = ppComputado
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 9
              Font.Style = []
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppComputado'
              mmHeight = 4498
              mmLeft = 43656
              mmTop = 284
              mmWidth = 22057
              BandType = 4
              LayerName = Foreground3
            end
            object ppLine6: TppLine
              DesignLayer = ppDesignLayer24
              UserName = 'Line6'
              Border.Style = psDot
              Border.mmPadding = 0
              Pen.Style = psDot
              Weight = 0.750000000000000000
              mmHeight = 1058
              mmLeft = -14817
              mmTop = 4763
              mmWidth = 84138
              BandType = 4
              LayerName = Foreground3
            end
          end
          object ppFooterBand22: TppFooterBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand24: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 11906
            mmPrintPosition = 0
            object ppLabel6: TppLabel
              DesignLayer = ppDesignLayer24
              UserName = 'Label1'
              Border.mmPadding = 0
              Caption = 'Total:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4233
              mmLeft = 1852
              mmTop = 794
              mmWidth = 9525
              BandType = 7
              LayerName = Foreground3
            end
            object ppDBCalc26: TppDBCalc
              DesignLayer = ppDesignLayer24
              UserName = 'DBCalc26'
              Border.mmPadding = 0
              DataField = 'valor'
              DataPipeline = ppComputado
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppComputado'
              mmHeight = 4498
              mmLeft = 40217
              mmTop = 529
              mmWidth = 25494
              BandType = 7
              LayerName = Foreground3
            end
            object ppSubReport3: TppSubReport
              DesignLayer = ppDesignLayer24
              UserName = 'SubReport3'
              ExpandAll = False
              NewPrintJob = False
              OutlineSettings.CreateNode = True
              TraverseAllData = False
              DataPipelineName = 'ppResumo'
              mmHeight = 5027
              mmLeft = 0
              mmTop = 6879
              mmWidth = 77760
              BandType = 7
              LayerName = Foreground3
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
              object ppChildReport3: TppChildReport
                AutoStop = False
                DataPipeline = ppResumo
                PrinterSetup.BinName = 'Default'
                PrinterSetup.DocumentName = '80mm'
                PrinterSetup.PaperName = 'Custom'
                PrinterSetup.PrinterName = 'Default'
                PrinterSetup.SaveDeviceSettings = True
                PrinterSetup.mmMarginBottom = 0
                PrinterSetup.mmMarginLeft = 0
                PrinterSetup.mmMarginRight = 2540
                PrinterSetup.mmMarginTop = 0
                PrinterSetup.mmPaperHeight = 4003900
                PrinterSetup.mmPaperWidth = 80300
                PrinterSetup.PaperSize = 256
                PrinterSetup.DevMode = {
                  4004000044006100720075006D00610020004400520000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000001040306DC0064034FEF8005010000013A6202036400010001016400
                  0100010064000200010043007500730074006F006D0000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000100000000000000
                  010000000200000001000000FFFFFFFF00000000000000000000000000000000
                  44494E552200080164030000B8225C4F00000000000000000000000000000000
                  0000000000000000000000000800000001000000000001000000050001000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000001000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000008010000
                  534D544A000000001000F80044006100720075006D0061002000440052003700
                  300030002000530070006F006F006C00650072000000496E70757442696E004F
                  50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
                  74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
                  4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
                  53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
                  6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
                  616F000000000000000000000000000000000000000000000000000000000000
                  00000000}
                Version = '21.02'
                mmColumnWidth = 0
                DataPipelineName = 'ppResumo'
                object ppTitleBand23: TppTitleBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  PrintHeight = phDynamic
                  mmBottomOffset = 0
                  mmHeight = 5821
                  mmPrintPosition = 0
                  object ppRichText19: TppRichText
                    DesignLayer = ppDesignLayer25
                    UserName = 'RichText19'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clBlack
                    Font.Name = 'Arial'
                    Font.Size = 12
                    Font.Style = [fsBold]
                    Border.mmPadding = 0
                    Caption = 'RichText19'
                    ExportRTFAsBitmap = False
                    RichText = 
                      '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                      '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                      ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs24 Comput' +
                      'ado\par'#13#10'}'#13#10#0
                    RemoveEmptyLines = False
                    Transparent = True
                    mmHeight = 5556
                    mmLeft = 1852
                    mmTop = 265
                    mmWidth = 66675
                    BandType = 1
                    LayerName = Foreground4
                    mmBottomOffset = 0
                    mmOverFlowOffset = 0
                    mmStopPosition = 0
                    mmMinHeight = 0
                  end
                end
                object ppHeaderBand23: TppHeaderBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  mmBottomOffset = 0
                  mmHeight = 0
                  mmPrintPosition = 0
                end
                object ppDetailBand25: TppDetailBand
                  Background1.Brush.Style = bsClear
                  Background2.Brush.Style = bsClear
                  Border.mmPadding = 0
                  PrintHeight = phDynamic
                  mmBottomOffset = 0
                  mmHeight = 5556
                  mmPrintPosition = 0
                  object ppDBText7: TppDBText
                    DesignLayer = ppDesignLayer25
                    UserName = 'DBText1'
                    Border.mmPadding = 0
                    DataField = 'descricao'
                    DataPipeline = ppResumo
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clWindowText
                    Font.Name = 'Arial'
                    Font.Size = 9
                    Font.Style = []
                    Transparent = True
                    DataPipelineName = 'ppResumo'
                    mmHeight = 4498
                    mmLeft = 1852
                    mmTop = 265
                    mmWidth = 36513
                    BandType = 4
                    LayerName = Foreground4
                  end
                  object ppDBText8: TppDBText
                    DesignLayer = ppDesignLayer25
                    UserName = 'DBText2'
                    Border.mmPadding = 0
                    DataField = 'valor'
                    DataPipeline = ppResumo
                    DisplayFormat = '$#,0.00;-$#,0.00'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clWindowText
                    Font.Name = 'Arial'
                    Font.Size = 9
                    Font.Style = []
                    TextAlignment = taRightJustified
                    Transparent = True
                    DataPipelineName = 'ppResumo'
                    mmHeight = 4498
                    mmLeft = 44450
                    mmTop = 265
                    mmWidth = 21437
                    BandType = 4
                    LayerName = Foreground4
                  end
                  object ppLine23: TppLine
                    DesignLayer = ppDesignLayer25
                    UserName = 'Line1'
                    Border.Style = psDot
                    Border.mmPadding = 0
                    Pen.Style = psDot
                    Weight = 0.750000000000000000
                    mmHeight = 1058
                    mmLeft = 0
                    mmTop = 4493
                    mmWidth = 84138
                    BandType = 4
                    LayerName = Foreground4
                  end
                end
                object ppFooterBand23: TppFooterBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  mmBottomOffset = 0
                  mmHeight = 0
                  mmPrintPosition = 0
                end
                object ppSummaryBand25: TppSummaryBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  PrintHeight = phDynamic
                  mmBottomOffset = 0
                  mmHeight = 11113
                  mmPrintPosition = 0
                  object ppLabel5: TppLabel
                    DesignLayer = ppDesignLayer25
                    UserName = 'Label1'
                    Border.mmPadding = 0
                    Caption = 'Total:'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clBlack
                    Font.Name = 'Arial'
                    Font.Size = 10
                    Font.Style = [fsBold]
                    FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
                    FormFieldSettings.FormFieldType = fftNone
                    Transparent = True
                    mmHeight = 4234
                    mmLeft = 1852
                    mmTop = 529
                    mmWidth = 9525
                    BandType = 7
                    LayerName = Foreground4
                  end
                  object ppDBCalc2: TppDBCalc
                    DesignLayer = ppDesignLayer25
                    UserName = 'DBCalc1'
                    Border.mmPadding = 0
                    DataField = 'valor_tipo_pagamento'
                    DataPipeline = ppResumo
                    DisplayFormat = '$#,0.00;-$#,0.00'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clBlack
                    Font.Name = 'Arial'
                    Font.Size = 10
                    Font.Style = [fsBold]
                    TextAlignment = taRightJustified
                    Transparent = True
                    DataPipelineName = 'ppResumo'
                    mmHeight = 4498
                    mmLeft = 40217
                    mmTop = 529
                    mmWidth = 25670
                    BandType = 7
                    LayerName = Foreground4
                  end
                  object ppSubReport4: TppSubReport
                    DesignLayer = ppDesignLayer25
                    UserName = 'SubReport4'
                    ExpandAll = False
                    NewPrintJob = False
                    OutlineSettings.CreateNode = True
                    TraverseAllData = False
                    DataPipelineName = 'ppResumoSangria'
                    mmHeight = 5027
                    mmLeft = 0
                    mmTop = 6085
                    mmWidth = 77760
                    BandType = 7
                    LayerName = Foreground4
                    mmBottomOffset = 0
                    mmOverFlowOffset = 0
                    mmStopPosition = 0
                    mmMinHeight = 0
                    object ppChildReport4: TppChildReport
                      AutoStop = False
                      DataPipeline = ppResumoSangria
                      PrinterSetup.BinName = 'Default'
                      PrinterSetup.DocumentName = '80mm'
                      PrinterSetup.PaperName = 'Custom'
                      PrinterSetup.PrinterName = 'Default'
                      PrinterSetup.SaveDeviceSettings = True
                      PrinterSetup.mmMarginBottom = 0
                      PrinterSetup.mmMarginLeft = 0
                      PrinterSetup.mmMarginRight = 2540
                      PrinterSetup.mmMarginTop = 0
                      PrinterSetup.mmPaperHeight = 4003900
                      PrinterSetup.mmPaperWidth = 80300
                      PrinterSetup.PaperSize = 256
                      PrinterSetup.DevMode = {
                        4004000044006100720075006D00610020004400520000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000001040306DC0064034FEF8005010000013A6202036400010001016400
                        0100010064000200010043007500730074006F006D0000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000100000000000000
                        010000000200000001000000FFFFFFFF00000000000000000000000000000000
                        44494E552200080164030000B8225C4F00000000000000000000000000000000
                        0000000000000000000000000800000001000000000001000000050001000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000001000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000008010000
                        534D544A000000001000F80044006100720075006D0061002000440052003700
                        300030002000530070006F006F006C00650072000000496E70757442696E004F
                        50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
                        74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
                        4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
                        53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
                        6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
                        616F000000000000000000000000000000000000000000000000000000000000
                        00000000}
                      Version = '21.02'
                      mmColumnWidth = 0
                      DataPipelineName = 'ppResumoSangria'
                      object ppTitleBand24: TppTitleBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        PrintHeight = phDynamic
                        mmBottomOffset = 0
                        mmHeight = 5821
                        mmPrintPosition = 0
                        object ppRichText102: TppRichText
                          DesignLayer = ppDesignLayer26
                          UserName = 'RichText102'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Arial'
                          Font.Size = 12
                          Font.Style = [fsBold]
                          Border.mmPadding = 0
                          Caption = 'RichText102'
                          ExportRTFAsBitmap = False
                          RichText = 
                            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                            '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                            ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs24 Sangri' +
                            'a\par'#13#10'}'#13#10#0
                          RemoveEmptyLines = False
                          Transparent = True
                          mmHeight = 5556
                          mmLeft = 1852
                          mmTop = 265
                          mmWidth = 66675
                          BandType = 1
                          LayerName = Foreground5
                          mmBottomOffset = 0
                          mmOverFlowOffset = 0
                          mmStopPosition = 0
                          mmMinHeight = 0
                        end
                      end
                      object ppHeaderBand24: TppHeaderBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        PrintOnFirstPage = False
                        PrintOnLastPage = False
                        mmBottomOffset = 0
                        mmHeight = 0
                        mmPrintPosition = 0
                      end
                      object ppDetailBand26: TppDetailBand
                        Background1.Brush.Style = bsClear
                        Background2.Brush.Style = bsClear
                        Border.mmPadding = 0
                        PrintHeight = phDynamic
                        mmBottomOffset = 0
                        mmHeight = 5821
                        mmPrintPosition = 0
                        object ppDBText36: TppDBText
                          DesignLayer = ppDesignLayer26
                          UserName = 'DBText36'
                          Border.mmPadding = 0
                          DataField = 'descricao'
                          DataPipeline = ppResumoSangria
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Arial'
                          Font.Size = 9
                          Font.Style = []
                          Transparent = True
                          DataPipelineName = 'ppResumoSangria'
                          mmHeight = 4498
                          mmLeft = 1588
                          mmTop = 284
                          mmWidth = 41540
                          BandType = 4
                          LayerName = Foreground5
                        end
                        object ppDBText37: TppDBText
                          DesignLayer = ppDesignLayer26
                          UserName = 'DBText37'
                          Border.mmPadding = 0
                          DataField = 'valor'
                          DataPipeline = ppResumoSangria
                          DisplayFormat = '$ #,0.00;-$ #,0.00'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Arial'
                          Font.Size = 9
                          Font.Style = []
                          TextAlignment = taRightJustified
                          Transparent = True
                          DataPipelineName = 'ppResumoSangria'
                          mmHeight = 4498
                          mmLeft = 43656
                          mmTop = 284
                          mmWidth = 22409
                          BandType = 4
                          LayerName = Foreground5
                        end
                        object ppLine8: TppLine
                          DesignLayer = ppDesignLayer26
                          UserName = 'Line8'
                          Border.Style = psDot
                          Border.mmPadding = 0
                          Pen.Style = psDot
                          Weight = 0.750000000000000000
                          mmHeight = 1058
                          mmLeft = -14817
                          mmTop = 4683
                          mmWidth = 84138
                          BandType = 4
                          LayerName = Foreground5
                        end
                      end
                      object ppPageSummaryBand1: TppPageSummaryBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        mmBottomOffset = 0
                        mmHeight = 0
                        mmPrintPosition = 0
                      end
                      object ppFooterBand24: TppFooterBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        mmBottomOffset = 0
                        mmHeight = 0
                        mmPrintPosition = 0
                      end
                      object ppSummaryBand26: TppSummaryBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        PrintHeight = phDynamic
                        mmBottomOffset = 0
                        mmHeight = 15610
                        mmPrintPosition = 0
                        object ppLabel82: TppLabel
                          DesignLayer = ppDesignLayer26
                          UserName = 'Label82'
                          Border.mmPadding = 0
                          Caption = 'Total:'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Courier New'
                          Font.Size = 10
                          Font.Style = [fsBold]
                          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
                          FormFieldSettings.FormFieldType = fftNone
                          Transparent = True
                          mmHeight = 4234
                          mmLeft = 1588
                          mmTop = 529
                          mmWidth = 12700
                          BandType = 7
                          LayerName = Foreground5
                        end
                        object ppDBCalc27: TppDBCalc
                          DesignLayer = ppDesignLayer26
                          UserName = 'DBCalc27'
                          Border.mmPadding = 0
                          DataField = 'valor'
                          DataPipeline = ppResumoSangria
                          DisplayFormat = '$#,0.00;-$#,0.00'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Courier New'
                          Font.Size = 10
                          Font.Style = [fsBold]
                          TextAlignment = taRightJustified
                          Transparent = True
                          DataPipelineName = 'ppResumoSangria'
                          mmHeight = 4498
                          mmLeft = 39952
                          mmTop = 529
                          mmWidth = 25846
                          BandType = 7
                          LayerName = Foreground5
                        end
                      end
                      object raCodeModule5: TraCodeModule
                      end
                      object ppDesignLayers26: TppDesignLayers
                        object ppDesignLayer26: TppDesignLayer
                          UserName = 'Foreground5'
                          LayerType = ltBanded
                          Index = 0
                        end
                      end
                    end
                  end
                end
                object raCodeModule6: TraCodeModule
                end
                object ppDesignLayers25: TppDesignLayers
                  object ppDesignLayer25: TppDesignLayer
                    UserName = 'Foreground4'
                    LayerType = ltBanded
                    Index = 0
                  end
                end
              end
            end
          end
          object raCodeModule3: TraCodeModule
          end
          object ppDesignLayers24: TppDesignLayers
            object ppDesignLayer24: TppDesignLayer
              UserName = 'Foreground3'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppHeaderBand9: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand11: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppFooterBand9: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand8: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 69321
      mmPrintPosition = 0
      object ppSystemVariable6: TppSystemVariable
        DesignLayer = ppDesignLayer9
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3705
        mmLeft = 1852
        mmTop = 46831
        mmWidth = 26194
        BandType = 7
        LayerName = BandLayer13
      end
      object ppSystemVariable12: TppSystemVariable
        DesignLayer = ppDesignLayer9
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 43392
        mmWidth = 8996
        BandType = 7
        LayerName = BandLayer13
      end
      object ppLabel14: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label14'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Vem Buscar:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 28046
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppLabel15: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label15'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Delivery:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 23019
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppLabel16: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label16'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Mesas:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 32279
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppRichText51: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText501'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText501'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'valor_delivery</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 23019
        mmWidth = 37136
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText52: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText52'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText52'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'valor_vem_buscar</dbtext>\par'#13#10#13#10'\pard\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 28046
        mmWidth = 37136
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText53: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText53'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText53'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'valor_mesa</dbtext>\par'#13#10#13#10'\pard\par'#13#10'\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 32279
        mmWidth = 37136
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel68: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label68'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Taxa:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 18521
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppRichText64: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'taxa_entrega</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 18521
        mmWidth = 37136
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel73: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label73'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Sangria:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 37306
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppRichText94: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText94'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        KeepTogether = True
        Border.mmPadding = 0
        Caption = 'RichText94'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'sangria</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 37306
        mmWidth = 37136
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel74: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label74'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Servi'#231'o (%):'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 13229
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppRichText97: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText97'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText97'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'servico</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 13229
        mmWidth = 37136
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText100: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText100'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText100'
        ExportRTFAsBitmap = False
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs24 Resumo' +
          ' Geral\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5556
        mmLeft = 1852
        mmTop = 7144
        mmWidth = 64123
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object raCodeModule4: TraCodeModule
    end
    object ppDesignLayers9: TppDesignLayers
      object ppDesignLayer9: TppDesignLayer
        UserName = 'BandLayer13'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList9: TppParameterList
      object ppParameter7: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
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
    Left = 1312
    Top = 296
  end
  object ppCompleto: TppBDEPipeline
    DataSource = dsCompleto
    UserName = 'Completo'
    Left = 1424
    Top = 720
  end
  object dsCompleto: TDataSource
    DataSet = CAIXA_COMPLETO
    Left = 1312
    Top = 360
  end
  object CAIXA_COMPLETO80MM: TppReport
    AutoStop = False
    DataPipeline = ppCompleto
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 58
    Top = 304
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppCompleto'
    object ppTitleBand9: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 22225
      mmPrintPosition = 0
      object ppRichText54: TppRichText
        DesignLayer = ppDesignLayer8
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs24 Fechamento de Caixa\par'#13#10'\f' +
          's20 (Completo)\f1\par'#13#10'\f0\fs30 #<dbtext displayformat='#39'000'#39'>id<' +
          '/dbtext>\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 66186
        BandType = 1
        LayerName = BandLayer14
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel17: TppLabel
        DesignLayer = ppDesignLayer8
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Opera'#231#245'es'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 5027
        mmLeft = 24077
        mmTop = 17463
        mmWidth = 21961
        BandType = 1
        LayerName = BandLayer14
      end
    end
    object ppHeaderBand8: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand9: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 5292
      mmPrintPosition = 0
      object ppLine24: TppLine
        DesignLayer = ppDesignLayer8
        UserName = 'Line23'
        Border.Style = psDot
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1058
        mmLeft = 0
        mmTop = 156
        mmWidth = 84067
        BandType = 4
        LayerName = BandLayer14
      end
      object ppRichText58: TppRichText
        DesignLayer = ppDesignLayer8
        UserName = 'RichText58'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText58'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\vi' +
          'ewkind4\uc1 '#13#10'\pard\fs18 <dbtext>transacao_descricao</dbtext>\pa' +
          'r'#13#10#13#10'\pard\qr [<dbtext>transacao_data</dbtext> <dbtext>transacao' +
          '_hora</dbtext>] - <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39'>tra' +
          'nsacao_valor</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3886
        mmLeft = 1852
        mmTop = 1323
        mmWidth = 61824
        BandType = 4
        LayerName = BandLayer14
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand8: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand10: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 32015
      mmPrintPosition = 0
      object ppSystemVariable10: TppSystemVariable
        DesignLayer = ppDesignLayer8
        UserName = 'SystemVariable6'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3705
        mmLeft = 1852
        mmTop = 28310
        mmWidth = 26194
        BandType = 7
        LayerName = BandLayer14
      end
      object ppSystemVariable11: TppSystemVariable
        DesignLayer = ppDesignLayer8
        UserName = 'SystemVariable11'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 24342
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer14
      end
      object ppLabel18: TppLabel
        DesignLayer = ppDesignLayer8
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Computado:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 6879
        mmWidth = 42333
        BandType = 7
        LayerName = BandLayer14
      end
      object ppRichText55: TppRichText
        DesignLayer = ppDesignLayer8
        UserName = 'RichText45'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText45'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$ #,0.00;-$ #,0.00' +
          #39'>valor_computado</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 39874
        mmTop = 6879
        mmWidth = 23797
        BandType = 7
        LayerName = BandLayer14
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel19: TppLabel
        DesignLayer = ppDesignLayer8
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Informado:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 11642
        mmWidth = 37571
        BandType = 7
        LayerName = BandLayer14
      end
      object ppLabel20: TppLabel
        DesignLayer = ppDesignLayer8
        UserName = 'Label101'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Diferen'#231'a:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 16140
        mmWidth = 37306
        BandType = 7
        LayerName = BandLayer14
      end
      object ppRichText56: TppRichText
        DesignLayer = ppDesignLayer8
        UserName = 'RichText48'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText48'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$ #,0.00;-$ #,0.00' +
          #39'>valor_informado</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 40403
        mmTop = 11642
        mmWidth = 23268
        BandType = 7
        LayerName = BandLayer14
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText57: TppRichText
        DesignLayer = ppDesignLayer8
        UserName = 'RichText49'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText49'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$ #,0.00;-$ #,0.00' +
          #39'>valor_diferenca</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 39874
        mmTop = 16140
        mmWidth = 23813
        BandType = 7
        LayerName = BandLayer14
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDesignLayers8: TppDesignLayers
      object ppDesignLayer8: TppDesignLayer
        UserName = 'BandLayer14'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList8: TppParameterList
      object ppParameter8: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
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
      'where p.id_caixa  = 609'
      'group by m.codigo, ce.bairro')
    Left = 1464
    Top = 304
  end
  object ppMotoboy: TppBDEPipeline
    DataSource = dsMotoboy
    UserName = 'Motoboy'
    Left = 1336
    Top = 720
  end
  object dsMotoboy: TDataSource
    DataSet = CAIXA_MOTOBOY
    Left = 1464
    Top = 368
  end
  object CAIXA_MOTOBOY80MM: TppReport
    AutoStop = False
    DataPipeline = ppMotoboy
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3276000
    PrinterSetup.mmPaperWidth = 80000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 50
    Top = 432
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppMotoboy'
    object ppTitleBand10: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 22225
      mmPrintPosition = 0
      object ppRichText59: TppRichText
        DesignLayer = ppDesignLayer10
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs24 Fechamento de Caixa\f1\par'#13 +
          #10'\f0\fs20 (Motoboy)\f1\par'#13#10'\f0\fs30 #<dbtext displayformat='#39'000' +
          #39'>id</dbtext>\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 70134
        BandType = 1
        LayerName = BandLayer16
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel21: TppLabel
        DesignLayer = ppDesignLayer10
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Entregas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 5027
        mmLeft = 30692
        mmTop = 17463
        mmWidth = 18256
        BandType = 1
        LayerName = BandLayer16
      end
    end
    object ppHeaderBand10: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand12: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 20108
      mmPrintPosition = 0
      object ppDBText10: TppDBText
        DesignLayer = ppDesignLayer10
        UserName = 'DBText10'
        Border.mmPadding = 0
        DataField = 'bairro'
        DataPipeline = ppMotoboy
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 17628
        mmTop = 840
        mmWidth = 54402
        BandType = 4
        LayerName = BandLayer16
      end
      object ppLabel23: TppLabel
        DesignLayer = ppDesignLayer10
        UserName = 'Label23'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Taxa:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 10116
        mmWidth = 25135
        BandType = 4
        LayerName = BandLayer16
      end
      object ppDBText13: TppDBText
        DesignLayer = ppDesignLayer10
        UserName = 'DBText13'
        Border.mmPadding = 0
        DataField = 'taxa_entrega'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 28046
        mmTop = 10116
        mmWidth = 43976
        BandType = 4
        LayerName = BandLayer16
      end
      object ppLabel24: TppLabel
        DesignLayer = ppDesignLayer10
        UserName = 'Label24'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Pedido:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 14781
        mmWidth = 25210
        BandType = 4
        LayerName = BandLayer16
      end
      object ppDBText14: TppDBText
        DesignLayer = ppDesignLayer10
        UserName = 'DBText14'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 27296
        mmTop = 14781
        mmWidth = 44734
        BandType = 4
        LayerName = BandLayer16
      end
      object ppLabel26: TppLabel
        DesignLayer = ppDesignLayer10
        UserName = 'Label26'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Bairro:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 794
        mmWidth = 14975
        BandType = 4
        LayerName = BandLayer16
      end
      object ppLabel27: TppLabel
        DesignLayer = ppDesignLayer10
        UserName = 'Label27'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Pedido:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 5189
        mmWidth = 14975
        BandType = 4
        LayerName = BandLayer16
      end
      object ppDBText15: TppDBText
        DesignLayer = ppDesignLayer10
        UserName = 'DBText101'
        Border.mmPadding = 0
        DataField = 'codigo'
        DataPipeline = ppMotoboy
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 17628
        mmTop = 5581
        mmWidth = 54402
        BandType = 4
        LayerName = BandLayer16
      end
    end
    object ppFooterBand10: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand11: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 54240
      mmPrintPosition = 0
      object ppSystemVariable20: TppSystemVariable
        DesignLayer = ppDesignLayer10
        UserName = 'SystemVariable6'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3705
        mmLeft = 1852
        mmTop = 28310
        mmWidth = 26194
        BandType = 7
        LayerName = BandLayer16
      end
      object ppSystemVariable21: TppSystemVariable
        DesignLayer = ppDesignLayer10
        UserName = 'SystemVariable11'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 24342
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer16
      end
      object ppLabel28: TppLabel
        DesignLayer = ppDesignLayer10
        UserName = 'Label28'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Total Taxa:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 9493
        mmWidth = 25135
        BandType = 7
        LayerName = BandLayer16
      end
      object ppLabel29: TppLabel
        DesignLayer = ppDesignLayer10
        UserName = 'Label29'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Total Geral:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 14520
        mmWidth = 25135
        BandType = 7
        LayerName = BandLayer16
      end
      object ppRichText61: TppRichText
        DesignLayer = ppDesignLayer10
        UserName = 'RichText601'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText601'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
          '1 '#13#10'\pard\qc\b\f0\fs24 Total Geral\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5118
        mmLeft = 1852
        mmTop = 529
        mmWidth = 70134
        BandType = 7
        LayerName = BandLayer16
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBCalc18: TppDBCalc
        DesignLayer = ppDesignLayer10
        UserName = 'DBCalc18'
        Border.mmPadding = 0
        DataField = 'taxa_entrega'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4498
        mmLeft = 34925
        mmTop = 9525
        mmWidth = 37306
        BandType = 7
        LayerName = BandLayer16
      end
      object ppDBCalc5: TppDBCalc
        DesignLayer = ppDesignLayer10
        UserName = 'DBCalc1'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4498
        mmLeft = 34925
        mmTop = 14552
        mmWidth = 37306
        BandType = 7
        LayerName = BandLayer16
      end
    end
    object ppGroup10: TppGroup
      BreakName = 'motoboy'
      DataPipeline = ppMotoboy
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group10'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppMotoboy'
      NewFile = False
      object ppGroupHeaderBand10: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        mmBottomOffset = 0
        mmHeight = 6085
        mmPrintPosition = 0
        object ppDBText9: TppDBText
          DesignLayer = ppDesignLayer10
          UserName = 'DBText9'
          Border.mmPadding = 0
          DataField = 'motoboy'
          DataPipeline = ppMotoboy
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 11
          Font.Style = [fsBold]
          TextAlignment = taCentered
          Transparent = True
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 1058
          mmWidth = 70134
          BandType = 3
          GroupNo = 0
          LayerName = BandLayer16
        end
      end
      object ppGroupFooterBand10: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 26458
        mmPrintPosition = 0
        object ppLabel22: TppLabel
          DesignLayer = ppDesignLayer10
          UserName = 'Label22'
          AutoSize = False
          Border.mmPadding = 0
          Caption = 'Total Taxa:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
          FormFieldSettings.FormFieldType = fftNone
          Transparent = True
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 15763
          mmWidth = 25135
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
        end
        object ppLabel25: TppLabel
          DesignLayer = ppDesignLayer10
          UserName = 'Label25'
          AutoSize = False
          Border.mmPadding = 0
          Caption = 'Total Geral:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
          FormFieldSettings.FormFieldType = fftNone
          Transparent = True
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 20410
          mmWidth = 25135
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
        end
        object ppDBCalc3: TppDBCalc
          DesignLayer = ppDesignLayer10
          UserName = 'DBCalc3'
          Border.mmPadding = 0
          DataField = 'taxa_entrega'
          DataPipeline = ppMotoboy
          DisplayFormat = '$ #,0.00;-$ #,0.00'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          ResetGroup = ppGroup10
          TextAlignment = taRightJustified
          Transparent = True
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4498
          mmLeft = 28046
          mmTop = 15763
          mmWidth = 43976
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
        end
        object ppDBCalc4: TppDBCalc
          DesignLayer = ppDesignLayer10
          UserName = 'DBCalc4'
          Border.mmPadding = 0
          DataField = 'total'
          DataPipeline = ppMotoboy
          DisplayFormat = '$ #,0.00;-$ #,0.00'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          ResetGroup = ppGroup10
          TextAlignment = taRightJustified
          Transparent = True
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4498
          mmLeft = 28046
          mmTop = 20410
          mmWidth = 43976
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
        end
        object ppLine25: TppLine
          DesignLayer = ppDesignLayer10
          UserName = 'Line25'
          Border.mmPadding = 0
          Pen.Style = psDash
          Weight = 0.750000000000000000
          mmHeight = 1058
          mmLeft = 0
          mmTop = 25014
          mmWidth = 88636
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
        end
        object ppRichText60: TppRichText
          DesignLayer = ppDesignLayer10
          UserName = 'RichText60'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          Border.mmPadding = 0
          Caption = 'RichText60'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc' +
            '1 '#13#10'\pard\qc\b\f0\fs24 Total <dbtext>motoboy</dbtext>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Transparent = True
          mmHeight = 5118
          mmLeft = 1852
          mmTop = 570
          mmWidth = 70134
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
        object ppLabel30: TppLabel
          DesignLayer = ppDesignLayer10
          UserName = 'Label30'
          AutoSize = False
          Border.mmPadding = 0
          Caption = 'Quantidade Entregas:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
          FormFieldSettings.FormFieldType = fftNone
          Transparent = True
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 11269
          mmWidth = 49663
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
        end
        object ppDBCalc7: TppDBCalc
          DesignLayer = ppDesignLayer10
          UserName = 'DBCalc7'
          Border.mmPadding = 0
          DataField = 'taxa_entrega'
          DataPipeline = ppMotoboy
          DisplayFormat = '000'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          ResetGroup = ppGroup10
          TextAlignment = taRightJustified
          Transparent = True
          DBCalcType = dcCount
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4498
          mmLeft = 52127
          mmTop = 11004
          mmWidth = 19903
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer16
        end
      end
    end
    object ppDesignLayers11: TppDesignLayers
      object ppDesignLayer10: TppDesignLayer
        UserName = 'BandLayer16'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList10: TppParameterList
      object ppParameter9: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
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
    Left = 1024
    Top = 184
  end
  object ppProduto: TppBDEPipeline
    DataSource = dsProduto
    UserName = 'Produto'
    Left = 1088
    Top = 768
  end
  object dsProduto: TDataSource
    DataSet = CAIXA_PRODUTO
    Left = 1632
    Top = 376
  end
  object CAIXA_PRODUTO80MM: TppReport
    AutoStop = False
    DataPipeline = ppCategoria
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3276000
    PrinterSetup.mmPaperWidth = 69088
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 50
    Top = 520
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppCategoria'
    object ppTitleBand11: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 23548
      mmPrintPosition = 0
      object ppRichText62: TppRichText
        DesignLayer = ppDesignLayer11
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0\fs16 CNPJ: <dbtext dat' +
          'apipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>razao</dbtext>\par'#13#10'<dbtext datapipeline='#39'ppCabecalho'#39'>' +
          'rua</dbtext>, <dbtext datapipeline='#39'ppCabecalho'#39'>rua</dbtext> <d' +
          'btext datapipeline='#39'ppCabecalho'#39'>bairro</dbtext> - <dbtext datap' +
          'ipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <dbtext datapipeline='#39'pp' +
          'Cabecalho'#39'>estado</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>ce' +
          'p</dbtext> IE: <dbtext datapipeline='#39'ppCabecalho'#39'>ie</dbtext>\pa' +
          'r'#13#10'\fs20\par'#13#10'Fechamento de Caixa\par'#13#10'\b\fs24 #<dbtext displayf' +
          'ormat='#39'000'#39'>id</dbtext>\fs26\par'#13#10'\par'#13#10'Categoria\f1\fs24\par'#13#10#13 +
          #10'\pard\cf0\b0\f0\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 23462
        mmLeft = 1896
        mmTop = 0
        mmWidth = 66047
        BandType = 1
        LayerName = BandLayer17
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand11: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand13: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4233
      mmPrintPosition = 0
      object ppDBText38: TppDBText
        DesignLayer = ppDesignLayer11
        UserName = 'DBText38'
        Border.mmPadding = 0
        DataField = 'produto'
        DataPipeline = ppCategoria
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        ParentDataPipeline = False
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 3791
        mmLeft = 1852
        mmTop = 41
        mmWidth = 50800
        BandType = 4
        LayerName = BandLayer17
      end
      object ppDBText39: TppDBText
        DesignLayer = ppDesignLayer11
        UserName = 'DBText39'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppCategoria
        DisplayFormat = '000'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        ParentDataPipeline = False
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 3704
        mmLeft = 34688
        mmTop = 0
        mmWidth = 28622
        BandType = 4
        LayerName = BandLayer17
      end
    end
    object ppFooterBand11: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand12: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 29369
      mmPrintPosition = 0
      object ppLabel40: TppLabel
        DesignLayer = ppDesignLayer11
        UserName = 'Label40'
        Border.mmPadding = 0
        Caption = 'Quantidade:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 8467
        mmWidth = 20638
        BandType = 7
        LayerName = BandLayer17
      end
      object ppDBCalc8: TppDBCalc
        DesignLayer = ppDesignLayer11
        UserName = 'DBCalc8'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppCategoria
        DisplayFormat = '000'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4171
        mmLeft = 32544
        mmTop = 8412
        mmWidth = 30692
        BandType = 7
        LayerName = BandLayer17
      end
      object ppLabel41: TppLabel
        DesignLayer = ppDesignLayer11
        UserName = 'Label401'
        Border.mmPadding = 0
        Caption = 'Categoria R$:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4234
        mmLeft = 1852
        mmTop = 529
        mmWidth = 22754
        BandType = 7
        LayerName = BandLayer17
      end
      object ppDBCalc9: TppDBCalc
        DesignLayer = ppDesignLayer11
        UserName = 'DBCalc9'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppCategoria
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4171
        mmLeft = 34660
        mmTop = 529
        mmWidth = 28622
        BandType = 7
        LayerName = BandLayer17
      end
      object ppLabel75: TppLabel
        DesignLayer = ppDesignLayer11
        UserName = 'Label75'
        Border.mmPadding = 0
        Caption = 'Adicional R$:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 4498
        mmWidth = 22225
        BandType = 7
        LayerName = BandLayer17
      end
      object ppDBCalc22: TppDBCalc
        DesignLayer = ppDesignLayer11
        UserName = 'DBCalc22'
        Border.mmPadding = 0
        DataField = 'total_adicional'
        DataPipeline = ppCategoria
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4171
        mmLeft = 34660
        mmTop = 4565
        mmWidth = 28622
        BandType = 7
        LayerName = BandLayer17
      end
      object ppLabel79: TppLabel
        DesignLayer = ppDesignLayer11
        UserName = 'Label79'
        Border.mmPadding = 0
        Caption = 'Total R$:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4234
        mmLeft = 1852
        mmTop = 12435
        mmWidth = 14817
        BandType = 7
        LayerName = BandLayer17
      end
      object ppDBCalc23: TppDBCalc
        DesignLayer = ppDesignLayer11
        UserName = 'DBCalc23'
        Border.mmPadding = 0
        DataField = 'total_geral'
        DataPipeline = ppCategoria
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4171
        mmLeft = 26458
        mmTop = 12448
        mmWidth = 36777
        BandType = 7
        LayerName = BandLayer17
      end
      object ppSubReport6: TppSubReport
        DesignLayer = ppDesignLayer11
        UserName = 'SubReport6'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppProduto'
        mmHeight = 5027
        mmLeft = 0
        mmTop = 23813
        mmWidth = 69088
        BandType = 7
        LayerName = BandLayer17
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport6: TppChildReport
          AutoStop = False
          DataPipeline = ppProduto
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 0
          PrinterSetup.mmMarginLeft = 0
          PrinterSetup.mmMarginRight = 0
          PrinterSetup.mmMarginTop = 0
          PrinterSetup.mmPaperHeight = 3276000
          PrinterSetup.mmPaperWidth = 69088
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 69088
          DataPipelineName = 'ppProduto'
          object ppTitleBand25: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 17463
            mmPrintPosition = 0
            object ppLabel80: TppLabel
              DesignLayer = ppDesignLayer27
              UserName = 'Label80'
              Border.mmPadding = 0
              Caption = 'Produtos'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 12
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              TextAlignment = taCentered
              Transparent = True
              mmHeight = 5027
              mmLeft = 25135
              mmTop = 11642
              mmWidth = 18786
              BandType = 1
              LayerName = Foreground6
            end
          end
          object ppDetailBand27: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 3969
            mmPrintPosition = 0
            object ppDBText40: TppDBText
              DesignLayer = ppDesignLayer27
              UserName = 'DBText40'
              Border.mmPadding = 0
              DataField = 'produto'
              DataPipeline = ppProduto
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              ParentDataPipeline = False
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 3791
              mmLeft = 1852
              mmTop = 0
              mmWidth = 50800
              BandType = 4
              LayerName = Foreground6
            end
            object ppDBText41: TppDBText
              DesignLayer = ppDesignLayer27
              UserName = 'DBText41'
              Border.mmPadding = 0
              DataField = 'quantidade'
              DataPipeline = ppProduto
              DisplayFormat = '000'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              ParentDataPipeline = False
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 3704
              mmLeft = 34660
              mmTop = 0
              mmWidth = 28054
              BandType = 4
              LayerName = Foreground6
            end
          end
          object ppPageSummaryBand2: TppPageSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppFooterBand25: TppFooterBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand27: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 29898
            mmPrintPosition = 0
            object ppLabel83: TppLabel
              DesignLayer = ppDesignLayer27
              UserName = 'Label402'
              Border.mmPadding = 0
              Caption = 'Quantidade:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 8467
              mmWidth = 20637
              BandType = 7
              LayerName = Foreground6
            end
            object ppDBCalc28: TppDBCalc
              DesignLayer = ppDesignLayer27
              UserName = 'DBCalc28'
              Border.mmPadding = 0
              DataField = 'quantidade'
              DataPipeline = ppProduto
              DisplayFormat = '000'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4171
              mmLeft = 32544
              mmTop = 8412
              mmWidth = 30139
              BandType = 7
              LayerName = Foreground6
            end
            object ppLabel84: TppLabel
              DesignLayer = ppDesignLayer27
              UserName = 'Label84'
              Border.mmPadding = 0
              Caption = 'Produtos R$:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4234
              mmLeft = 1323
              mmTop = 529
              mmWidth = 21167
              BandType = 7
              LayerName = Foreground6
            end
            object ppDBCalc29: TppDBCalc
              DesignLayer = ppDesignLayer27
              UserName = 'DBCalc29'
              Border.mmPadding = 0
              DataField = 'total'
              DataPipeline = ppProduto
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4171
              mmLeft = 34131
              mmTop = 529
              mmWidth = 28575
              BandType = 7
              LayerName = Foreground6
            end
            object ppLabel85: TppLabel
              DesignLayer = ppDesignLayer27
              UserName = 'Label85'
              Border.mmPadding = 0
              Caption = 'Adicional R$:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 4498
              mmWidth = 22225
              BandType = 7
              LayerName = Foreground6
            end
            object ppDBCalc30: TppDBCalc
              DesignLayer = ppDesignLayer27
              UserName = 'DBCalc30'
              Border.mmPadding = 0
              DataField = 'total_adicional'
              DataPipeline = ppProduto
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4171
              mmLeft = 34131
              mmTop = 4450
              mmWidth = 28575
              BandType = 7
              LayerName = Foreground6
            end
            object ppLabel86: TppLabel
              DesignLayer = ppDesignLayer27
              UserName = 'Label86'
              Border.mmPadding = 0
              Caption = 'Total R$:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4234
              mmLeft = 1323
              mmTop = 12435
              mmWidth = 14817
              BandType = 7
              LayerName = Foreground6
            end
            object ppDBCalc31: TppDBCalc
              DesignLayer = ppDesignLayer27
              UserName = 'DBCalc31'
              Border.mmPadding = 0
              DataField = 'total_geral'
              DataPipeline = ppProduto
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4171
              mmLeft = 25929
              mmTop = 12448
              mmWidth = 36777
              BandType = 7
              LayerName = Foreground6
            end
            object ppSystemVariable22: TppSystemVariable
              DesignLayer = ppDesignLayer27
              UserName = 'SystemVariable22'
              Border.mmPadding = 0
              VarType = vtDocumentName
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 1323
              mmTop = 22225
              mmWidth = 32015
              BandType = 7
              LayerName = Foreground6
            end
            object ppSystemVariable23: TppSystemVariable
              DesignLayer = ppDesignLayer27
              UserName = 'SystemVariable23'
              Border.mmPadding = 0
              VarType = vtDateTime
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 1323
              mmTop = 26194
              mmWidth = 26194
              BandType = 7
              LayerName = Foreground6
            end
          end
          object ppDesignLayers27: TppDesignLayers
            object ppDesignLayer27: TppDesignLayer
              UserName = 'Foreground6'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppDesignLayers13: TppDesignLayers
      object ppDesignLayer11: TppDesignLayer
        UserName = 'BandLayer17'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList11: TppParameterList
      object ppParameter10: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CAIXA_COMPLETO56MM: TppReport
    AutoStop = False
    DataPipeline = ppCompleto
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 210
    Top = 312
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppCompleto'
    object ppTitleBand13: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 22225
      mmPrintPosition = 0
      object ppRichText73: TppRichText
        DesignLayer = ppDesignLayer15
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs24 Fechamento de Caixa\par'#13#10'\fs20 (Completo)\par'#13#10'\fs3' +
          '0 #<dbtext displayformat='#39'000'#39'>id</dbtext>\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 43976
        BandType = 1
        LayerName = BandLayer19
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel51: TppLabel
        DesignLayer = ppDesignLayer15
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Opera'#231#245'es'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 17463
        mmWidth = 43976
        BandType = 1
        LayerName = BandLayer19
      end
    end
    object ppHeaderBand13: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand15: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 5292
      mmPrintPosition = 0
      object ppLine28: TppLine
        DesignLayer = ppDesignLayer15
        UserName = 'Line23'
        Border.Style = psDot
        Border.mmPadding = 0
        Pen.Style = psDash
        Weight = 0.750000000000000000
        mmHeight = 1058
        mmLeft = 0
        mmTop = 156
        mmWidth = 55757
        BandType = 4
        LayerName = BandLayer19
      end
      object ppRichText74: TppRichText
        DesignLayer = ppDesignLayer15
        UserName = 'RichText58'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText58'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\*\gene' +
          'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs18 <dbte' +
          'xt>transacao_descricao</dbtext>\fs16\par'#13#10#13#10'\pard\qr [\f1 <dbtex' +
          't>transacao_data</dbtext>\f0  <dbtext>transacao_hora</dbtext>] -' +
          ' <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39'>transacao_valor</dbt' +
          'ext>\f1\fs18\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3886
        mmLeft = 1852
        mmTop = 1323
        mmWidth = 43976
        BandType = 4
        LayerName = BandLayer19
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand13: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand14: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 32015
      mmPrintPosition = 0
      object ppSystemVariable26: TppSystemVariable
        DesignLayer = ppDesignLayer15
        UserName = 'SystemVariable6'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 28310
        mmWidth = 43976
        BandType = 7
        LayerName = BandLayer19
      end
      object ppSystemVariable27: TppSystemVariable
        DesignLayer = ppDesignLayer15
        UserName = 'SystemVariable11'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 24342
        mmWidth = 43976
        BandType = 7
        LayerName = BandLayer19
      end
      object ppLabel52: TppLabel
        DesignLayer = ppDesignLayer15
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Computado:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 6879
        mmWidth = 22367
        BandType = 7
        LayerName = BandLayer19
      end
      object ppRichText75: TppRichText
        DesignLayer = ppDesignLayer15
        UserName = 'RichText45'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText45'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\' +
          'generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qr\b\f0\fs2' +
          '0 <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39'>valor_computado</db' +
          'text>\b0\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 24263
        mmTop = 6879
        mmWidth = 21609
        BandType = 7
        LayerName = BandLayer19
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel53: TppLabel
        DesignLayer = ppDesignLayer15
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Informado:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 11642
        mmWidth = 22367
        BandType = 7
        LayerName = BandLayer19
      end
      object ppLabel54: TppLabel
        DesignLayer = ppDesignLayer15
        UserName = 'Label101'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Diferen'#231'a:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 16140
        mmWidth = 22367
        BandType = 7
        LayerName = BandLayer19
      end
      object ppRichText76: TppRichText
        DesignLayer = ppDesignLayer15
        UserName = 'RichText48'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText48'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\' +
          'generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qr\b\f0\fs2' +
          '0 <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39'>valor_informado</db' +
          'text>\b0\f1\fs24\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 24263
        mmTop = 11642
        mmWidth = 21609
        BandType = 7
        LayerName = BandLayer19
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText77: TppRichText
        DesignLayer = ppDesignLayer15
        UserName = 'RichText49'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText49'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\' +
          'generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qr\b\f0\fs2' +
          '0 <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39'>valor_diferenca</db' +
          'text>\b0\f1\fs24\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 24263
        mmTop = 16140
        mmWidth = 21609
        BandType = 7
        LayerName = BandLayer19
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDesignLayers15: TppDesignLayers
      object ppDesignLayer15: TppDesignLayer
        UserName = 'BandLayer19'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList13: TppParameterList
      object ppParameter12: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CAIXA_MOTOBOY56MM: TppReport
    AutoStop = False
    DataPipeline = ppMotoboy
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 218
    Top = 432
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppMotoboy'
    object ppTitleBand14: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 22225
      mmPrintPosition = 0
      object ppRichText78: TppRichText
        DesignLayer = ppDesignLayer16
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs24 Fechamento de Caixa\par'#13#10'\fs20 (Motoboy)\par'#13#10'\fs30' +
          ' #<dbtext displayformat='#39'000'#39'>id</dbtext>\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 41512
        BandType = 1
        LayerName = BandLayer22
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel55: TppLabel
        DesignLayer = ppDesignLayer16
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Entregas'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 16669
        mmWidth = 41512
        BandType = 1
        LayerName = BandLayer22
      end
    end
    object ppHeaderBand14: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand16: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 20108
      mmPrintPosition = 0
      object ppDBText19: TppDBText
        DesignLayer = ppDesignLayer16
        UserName = 'DBText10'
        Border.mmPadding = 0
        DataField = 'bairro'
        DataPipeline = ppMotoboy
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 17628
        mmTop = 840
        mmWidth = 25779
        BandType = 4
        LayerName = BandLayer22
      end
      object ppLabel56: TppLabel
        DesignLayer = ppDesignLayer16
        UserName = 'Label23'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Taxa:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 10116
        mmWidth = 25135
        BandType = 4
        LayerName = BandLayer22
      end
      object ppDBText20: TppDBText
        DesignLayer = ppDesignLayer16
        UserName = 'DBText13'
        Border.mmPadding = 0
        DataField = 'taxa_entrega'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 28046
        mmTop = 10116
        mmWidth = 15354
        BandType = 4
        LayerName = BandLayer22
      end
      object ppLabel57: TppLabel
        DesignLayer = ppDesignLayer16
        UserName = 'Label24'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Pedido:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 14781
        mmWidth = 25210
        BandType = 4
        LayerName = BandLayer22
      end
      object ppDBText21: TppDBText
        DesignLayer = ppDesignLayer16
        UserName = 'DBText14'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 27296
        mmTop = 14971
        mmWidth = 16112
        BandType = 4
        LayerName = BandLayer22
      end
      object ppLabel58: TppLabel
        DesignLayer = ppDesignLayer16
        UserName = 'Label26'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Bairro:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 794
        mmWidth = 14975
        BandType = 4
        LayerName = BandLayer22
      end
      object ppLabel59: TppLabel
        DesignLayer = ppDesignLayer16
        UserName = 'Label27'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Pedido:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 5189
        mmWidth = 14975
        BandType = 4
        LayerName = BandLayer22
      end
      object ppDBText22: TppDBText
        DesignLayer = ppDesignLayer16
        UserName = 'DBText101'
        Border.mmPadding = 0
        DataField = 'codigo'
        DataPipeline = ppMotoboy
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4763
        mmLeft = 17628
        mmTop = 5391
        mmWidth = 25779
        BandType = 4
        LayerName = BandLayer22
      end
    end
    object ppFooterBand14: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand16: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 42333
      mmPrintPosition = 0
      object ppSystemVariable28: TppSystemVariable
        DesignLayer = ppDesignLayer16
        UserName = 'SystemVariable6'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 28310
        mmWidth = 35190
        BandType = 7
        LayerName = BandLayer22
      end
      object ppSystemVariable29: TppSystemVariable
        DesignLayer = ppDesignLayer16
        UserName = 'SystemVariable11'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 24342
        mmWidth = 47767
        BandType = 7
        LayerName = BandLayer22
      end
      object ppLabel60: TppLabel
        DesignLayer = ppDesignLayer16
        UserName = 'Label28'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Taxa:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4573
        mmLeft = 1852
        mmTop = 9873
        mmWidth = 15733
        BandType = 7
        LayerName = BandLayer22
      end
      object ppLabel61: TppLabel
        DesignLayer = ppDesignLayer16
        UserName = 'Label29'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Geral:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4573
        mmLeft = 1852
        mmTop = 14900
        mmWidth = 15733
        BandType = 7
        LayerName = BandLayer22
      end
      object ppDBCalc11: TppDBCalc
        DesignLayer = ppDesignLayer16
        UserName = 'DBCalc5'
        Border.mmPadding = 0
        DataField = 'taxa_entrega'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        ResetGroup = ppGroup12
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4498
        mmLeft = 17628
        mmTop = 9493
        mmWidth = 25779
        BandType = 7
        LayerName = BandLayer22
      end
      object ppDBCalc12: TppDBCalc
        DesignLayer = ppDesignLayer16
        UserName = 'DBCalc6'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppMotoboy
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        ResetGroup = ppGroup12
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppMotoboy'
        mmHeight = 4498
        mmLeft = 18387
        mmTop = 14520
        mmWidth = 25021
        BandType = 7
        LayerName = BandLayer22
      end
      object ppRichText79: TppRichText
        DesignLayer = ppDesignLayer16
        UserName = 'RichText601'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText601'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\*\gene' +
          'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\b\f0\fs22 To' +
          'tal Geral\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5118
        mmLeft = 1852
        mmTop = 529
        mmWidth = 41512
        BandType = 7
        LayerName = BandLayer22
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppGroup12: TppGroup
      BreakName = 'motoboy'
      DataPipeline = ppMotoboy
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group10'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppMotoboy'
      NewFile = False
      object ppGroupHeaderBand12: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        mmBottomOffset = 0
        mmHeight = 6085
        mmPrintPosition = 0
        object ppDBText23: TppDBText
          DesignLayer = ppDesignLayer16
          UserName = 'DBText9'
          Border.mmPadding = 0
          DataField = 'motoboy'
          DataPipeline = ppMotoboy
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Courier New'
          Font.Size = 11
          Font.Style = [fsBold]
          TextAlignment = taCentered
          Transparent = True
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 1058
          mmWidth = 41512
          BandType = 3
          GroupNo = 0
          LayerName = BandLayer22
        end
      end
      object ppGroupFooterBand12: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 26458
        mmPrintPosition = 0
        object ppLabel62: TppLabel
          DesignLayer = ppDesignLayer16
          UserName = 'Label22'
          AutoSize = False
          Border.mmPadding = 0
          Caption = 'Taxa:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
          FormFieldSettings.FormFieldType = fftNone
          Transparent = True
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 15763
          mmWidth = 18766
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
        end
        object ppLabel63: TppLabel
          DesignLayer = ppDesignLayer16
          UserName = 'Label25'
          AutoSize = False
          Border.mmPadding = 0
          Caption = 'Geral:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
          FormFieldSettings.FormFieldType = fftNone
          Transparent = True
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 20220
          mmWidth = 15733
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
        end
        object ppDBCalc13: TppDBCalc
          DesignLayer = ppDesignLayer16
          UserName = 'DBCalc3'
          Border.mmPadding = 0
          DataField = 'taxa_entrega'
          DataPipeline = ppMotoboy
          DisplayFormat = '$ #,0.00;-$ #,0.00'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          ResetGroup = ppGroup12
          TextAlignment = taRightJustified
          Transparent = True
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4498
          mmLeft = 22557
          mmTop = 15763
          mmWidth = 20851
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
        end
        object ppDBCalc14: TppDBCalc
          DesignLayer = ppDesignLayer16
          UserName = 'DBCalc4'
          Border.mmPadding = 0
          DataField = 'total'
          DataPipeline = ppMotoboy
          DisplayFormat = '$ #,0.00;-$ #,0.00'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          ResetGroup = ppGroup12
          TextAlignment = taRightJustified
          Transparent = True
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4498
          mmLeft = 18387
          mmTop = 20410
          mmWidth = 25021
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
        end
        object ppLine29: TppLine
          DesignLayer = ppDesignLayer16
          UserName = 'Line25'
          Border.mmPadding = 0
          Pen.Style = psDash
          Weight = 0.750000000000000000
          mmHeight = 1058
          mmLeft = 0
          mmTop = 25014
          mmWidth = 60706
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
        end
        object ppRichText80: TppRichText
          DesignLayer = ppDesignLayer16
          UserName = 'RichText60'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          Border.mmPadding = 0
          Caption = 'RichText60'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\*\gene' +
            'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\b\f0\fs22 To' +
            'tal <dbtext>motoboy</dbtext>\f1\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Transparent = True
          mmHeight = 5118
          mmLeft = 1852
          mmTop = 570
          mmWidth = 41512
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
        object ppLabel64: TppLabel
          DesignLayer = ppDesignLayer16
          UserName = 'Label30'
          AutoSize = False
          Border.mmPadding = 0
          Caption = 'Entregas:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
          FormFieldSettings.FormFieldType = fftNone
          Transparent = True
          mmHeight = 4763
          mmLeft = 1852
          mmTop = 11269
          mmWidth = 22557
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
        end
        object ppDBCalc15: TppDBCalc
          DesignLayer = ppDesignLayer16
          UserName = 'DBCalc7'
          Border.mmPadding = 0
          DataField = 'taxa_entrega'
          DataPipeline = ppMotoboy
          DisplayFormat = '000'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          ResetGroup = ppGroup12
          TextAlignment = taRightJustified
          Transparent = True
          DBCalcType = dcCount
          DataPipelineName = 'ppMotoboy'
          mmHeight = 4498
          mmLeft = 25400
          mmTop = 11004
          mmWidth = 18007
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer22
        end
      end
    end
    object ppDesignLayers16: TppDesignLayers
      object ppDesignLayer16: TppDesignLayer
        UserName = 'BandLayer22'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList14: TppParameterList
      object ppParameter13: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object iReqImpressaoTest: iRequisicao
    BaseURL = 'http://localhost:2121/v1/util/teste/impressao'
    eTAG = False
    Metodo = mGet
    Status = 0
    MostrarAguarde = False
    TempoExpiracao = 2000
    Left = 872
    Top = 264
  end
  object ppTesteImpressao: TppReport
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 872
    Top = 207
    Version = '21.02'
    mmColumnWidth = 72000
    object ppTitleBand16: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 54504
      mmPrintPosition = 0
      object ppRichText86: TppRichText
        DesignLayer = ppDesignLayer18
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 14
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\colortbl ;\red0\gr' +
          'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
          #10'\pard\cf1\b\fs28 Teste de Impress\'#39'e3o GooPedir\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 10886
        mmLeft = 1896
        mmTop = 0
        mmWidth = 71840
        BandType = 1
        LayerName = BandLayer24
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object pp2DBarCode1: Tpp2DBarCode
        DesignLayer = ppDesignLayer18
        UserName = 'TwoDBarCode1'
        AlignBarcode = ahLeft
        Border.mmPadding = 0
        Color = clBlack
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Transparent = True
        BarCodeType = bcQRCode
        Data = 'https://goopedir.com'
        MaxiCodeSettings.CarrierPostalCode = '000000000'
        MaxiCodeSettings.HorPixelsPerMM = 4.000000000000000000
        MaxiCodeSettings.VerPixelsPerMM = 4.000000000000000000
        MaxiCodeSettings.mmBarHeight = 1059
        MaxiCodeSettings.mmBarWidth = 1059
        MaxiCodeSettings.mmQuietZone = 2118
        PDF417Settings.mmBarHeight = 2118
        PDF417Settings.mmBarWidth = 530
        PDF417Settings.mmQuietZone = 2118
        QRCodeSettings.IncludeBOM = True
        QRCodeSettings.mmModuleSize = 1059
        QRCodeSettings.mmQuietZone = 1059
        QRCodeSettings.ECICode = -1
        DataMatrixSettings.mmModuleSize = 1059
        DataMatrixSettings.mmQuietZone = 1059
        AztecCodeSettings.mmModuleSize = 1600
        mmHeight = 34521
        mmLeft = 1852
        mmTop = 17727
        mmWidth = 71967
        BandType = 1
        LayerName = BandLayer24
      end
      object ppBarCode1: TppBarCode
        DesignLayer = ppDesignLayer18
        UserName = 'BarCode1'
        AlignBarCode = ahLeft
        BarCodeType = bcEAN_13
        BarColor = clBlack
        Border.mmPadding = 0
        Data = '0012345678905'
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = []
        Transparent = True
        mmHeight = 11642
        mmLeft = 33073
        mmTop = 17727
        mmWidth = 47625
        BandType = 1
        LayerName = BandLayer24
        mmBarWidth = 330
        mmWideBarRatio = 76200
      end
      object ppDriverTest: TppLabel
        DesignLayer = ppDesignLayer18
        UserName = 'DriverTest'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'DriverTest'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 16
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        VerticalAlignment = avCenter
        mmHeight = 12161
        mmLeft = 1863
        mmTop = 5027
        mmWidth = 67374
        BandType = 1
        LayerName = BandLayer24
      end
    end
    object ppHeaderBand16: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand18: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppFooterBand16: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand18: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 8731
      mmPrintPosition = 0
      object ppSystemVariable32: TppSystemVariable
        DesignLayer = ppDesignLayer18
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 5027
        mmWidth = 35190
        BandType = 7
        LayerName = BandLayer24
      end
      object ppSystemVariable33: TppSystemVariable
        DesignLayer = ppDesignLayer18
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 1588
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer24
      end
    end
    object ppDesignLayers18: TppDesignLayers
      object ppDesignLayer18: TppDesignLayer
        UserName = 'BandLayer24'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList16: TppParameterList
      object ppParameter15: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CAIXA_CANCELAMENTO: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      
        'select pedido.data_pedido,pedido.hora_pedido, pedido.codigo_pedi' +
        'do_dia, (select nome from cliente where cliente.codigo = pedido.' +
        'codigo_cliente) as cliente,'
      
        'pedido_produtos.valor_total, pedido_produtos.quantidade, (select' +
        ' upper(nome_produto) from produto where produto.codigo = pedido_' +
        'produtos.codigo_produto) as produto,'
      'pedido_produtos.id_caixa as id'
      'from pedido_produtos '
      'join pedido on pedido.codigo = pedido_produtos.id_pedido'
      'where pedido_produtos.id_caixa = :id_caixa')
    Left = 960
    Top = 312
    ParamData = <
      item
        Name = 'ID_CAIXA'
        ParamType = ptInput
      end>
  end
  object dsCancelamento: TDataSource
    DataSet = CAIXA_CANCELAMENTO
    Left = 960
    Top = 376
  end
  object ppCancelamento: TppBDEPipeline
    DataSource = dsCancelamento
    UserName = 'Cancelamento'
    Left = 960
    Top = 440
  end
  object CAIXA_CANCELAMENTO80MM: TppReport
    AutoStop = False
    DataPipeline = ppCancelamento
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3276000
    PrinterSetup.mmPaperWidth = 80000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 960
    Top = 503
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppCancelamento'
    object ppTitleBand17: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 24871
      mmPrintPosition = 0
      object ppRichText90: TppRichText
        DesignLayer = ppDesignLayer19
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs24 Fechamento de Caixa\f1\par'#13 +
          #10'\f0\fs20 (Cancelamento)\f1\par'#13#10'\f0\fs30 #<dbtext displayformat' +
          '='#39'000'#39'>id</dbtext>\f1\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 71840
        BandType = 1
        LayerName = BandLayer25
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel2: TppLabel
        DesignLayer = ppDesignLayer19
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Produtos Cancelados'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4763
        mmLeft = 12700
        mmTop = 18785
        mmWidth = 50271
        BandType = 1
        LayerName = BandLayer25
      end
    end
    object ppHeaderBand17: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand19: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 5027
      mmPrintPosition = 0
      object ppRichText99: TppRichText
        DesignLayer = ppDesignLayer19
        UserName = 'RichText99'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText99'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*' +
          '\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\fs16' +
          ' (<dbtext displayformat='#39'000'#39'>codigo_pedido_dia</dbtext>) - <dbt' +
          'ext displayformat='#39'mm/dd'#39'>data_pedido</dbtext> / <dbtext display' +
          'format='#39'h:nn'#39'>hora_pedido</dbtext> \par'#13#10' <dbtext>cliente</dbtex' +
          't>\par'#13#10' <dbtext>produto</dbtext>\par'#13#10' <dbtext displayformat='#39'0' +
          '0'#39'>quantidade</dbtext>Un - <dbtext displayformat='#39'#,0.00;-#,0.00' +
          #39'>valor_total</dbtext>\par'#13#10'\par'#13#10'------------------------------' +
          '-------------\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 264
        mmWidth = 71967
        BandType = 4
        LayerName = BandLayer25
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand17: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand19: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 21696
      mmPrintPosition = 0
      object ppSystemVariable34: TppSystemVariable
        DesignLayer = ppDesignLayer19
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 16404
        mmWidth = 26194
        BandType = 7
        LayerName = BandLayer25
      end
      object ppSystemVariable35: TppSystemVariable
        DesignLayer = ppDesignLayer19
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 12965
        mmWidth = 8996
        BandType = 7
        LayerName = BandLayer25
      end
      object ppLabel69: TppLabel
        DesignLayer = ppDesignLayer19
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Quantidade Total:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 2381
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer25
      end
      object ppLabel70: TppLabel
        DesignLayer = ppDesignLayer19
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Total:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 7144
        mmWidth = 26988
        BandType = 7
        LayerName = BandLayer25
      end
      object ppDBCalc6: TppDBCalc
        DesignLayer = ppDesignLayer19
        UserName = 'DBCalc1'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppCancelamento
        DisplayFormat = '00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCancelamento'
        mmHeight = 4498
        mmLeft = 41804
        mmTop = 2381
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer25
      end
      object ppDBCalc19: TppDBCalc
        DesignLayer = ppDesignLayer19
        UserName = 'DBCalc19'
        Border.mmPadding = 0
        DataField = 'valor_total'
        DataPipeline = ppCancelamento
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCancelamento'
        mmHeight = 4498
        mmLeft = 41804
        mmTop = 7144
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer25
      end
    end
    object ppDesignLayers19: TppDesignLayers
      object ppDesignLayer19: TppDesignLayer
        UserName = 'BandLayer25'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList17: TppParameterList
      object ppParameter16: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CAIXA_CANCELAMENTO56MM: TppReport
    AutoStop = False
    DataPipeline = ppCancelamento
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 960
    Top = 567
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppCancelamento'
    object ppTitleBand18: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 24871
      mmPrintPosition = 0
      object ppRichText91: TppRichText
        DesignLayer = ppDesignLayer20
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs22 Fechamento de Caixa\fs24\par'#13#10'\fs20 (Cancelamento)\' +
          'par'#13#10'\fs30 #<dbtext displayformat='#39'000'#39'>id</dbtext>\fs24\par'#13#10'}'#13 +
          #10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 47725
        BandType = 1
        LayerName = BandLayer26
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel3: TppLabel
        DesignLayer = ppDesignLayer20
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Produtos'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4763
        mmLeft = 14817
        mmTop = 18785
        mmWidth = 21166
        BandType = 1
        LayerName = BandLayer26
      end
    end
    object ppHeaderBand18: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand20: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 5027
      mmPrintPosition = 0
      object ppRichText92: TppRichText
        DesignLayer = ppDesignLayer20
        UserName = 'RichText99'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText99'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 (<dbtext displayformat='#39'000'#39'>co' +
          'digo_pedido_dia</dbtext>) - <dbtext displayformat='#39'mm/dd'#39'>data_p' +
          'edido</dbtext> / <dbtext displayformat='#39'h:nn'#39'>hora_pedido</dbtex' +
          't> \par'#13#10' <dbtext>cliente</dbtext>\par'#13#10' <dbtext>produto</dbtext' +
          '>\par'#13#10' <dbtext displayformat='#39'00'#39'>quantidade</dbtext>Un - <dbte' +
          'xt displayformat='#39'#,0.00;-#,0.00'#39'>valor_total</dbtext>\par'#13#10'\par' +
          #13#10'--------------------------\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 264
        mmWidth = 47057
        BandType = 4
        LayerName = BandLayer26
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand18: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand20: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 36248
      mmPrintPosition = 0
      object ppSystemVariable36: TppSystemVariable
        DesignLayer = ppDesignLayer20
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 29369
        mmWidth = 35190
        BandType = 7
        LayerName = BandLayer26
      end
      object ppSystemVariable37: TppSystemVariable
        DesignLayer = ppDesignLayer20
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 25929
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer26
      end
      object ppLabel71: TppLabel
        DesignLayer = ppDesignLayer20
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Quantidade Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 2381
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer26
      end
      object ppLabel72: TppLabel
        DesignLayer = ppDesignLayer20
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 14288
        mmWidth = 26988
        BandType = 7
        LayerName = BandLayer26
      end
      object ppDBCalc20: TppDBCalc
        DesignLayer = ppDesignLayer20
        UserName = 'DBCalc1'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppCancelamento
        DisplayFormat = '00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCancelamento'
        mmHeight = 4498
        mmLeft = 1852
        mmTop = 8202
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer26
      end
      object ppDBCalc21: TppDBCalc
        DesignLayer = ppDesignLayer20
        UserName = 'DBCalc19'
        Border.mmPadding = 0
        DataField = 'valor_total'
        DataPipeline = ppCancelamento
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCancelamento'
        mmHeight = 4498
        mmLeft = 1852
        mmTop = 19050
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer26
      end
    end
    object ppDesignLayers20: TppDesignLayers
      object ppDesignLayer20: TppDesignLayer
        UserName = 'BandLayer26'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList18: TppParameterList
      object ppParameter17: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CAIXA_SANGRIA: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      'SELECT *, CAST(descricao AS CHAR(100)) as sangria'
      'FROM caixa_movimento'
      'WHERE tipo = 2 and impressao = 0'
      '')
    Left = 1128
    Top = 312
  end
  object dsSangria: TDataSource
    DataSet = CAIXA_SANGRIA
    Left = 1128
    Top = 376
  end
  object ppSangria: TppBDEPipeline
    DataSource = dsSangria
    UserName = 'Cancelamento1'
    Left = 1128
    Top = 440
  end
  object CAIXA_SANGRIA80MM: TppReport
    AutoStop = False
    DataPipeline = ppSangria
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 50
    Top = 679
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppSangria'
    object ppTitleBand19: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 16404
      mmPrintPosition = 0
      object ppRichText93: TppRichText
        DesignLayer = ppDesignLayer21
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0\fs16 CNPJ: <dbtext dat' +
          'apipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>razao</dbtext>\par'#13#10'<dbtext datapipeline='#39'ppCabecalho'#39'>' +
          'rua</dbtext>, <dbtext datapipeline='#39'ppCabecalho'#39'>rua</dbtext> <d' +
          'btext datapipeline='#39'ppCabecalho'#39'>bairro</dbtext> - <dbtext datap' +
          'ipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <dbtext datapipeline='#39'pp' +
          'Cabecalho'#39'>estado</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>ce' +
          'p</dbtext> IE: <dbtext datapipeline='#39'ppCabecalho'#39'>ie</dbtext>\pa' +
          'r'#13#10'\b\f1\fs24\par'#13#10'\f0\fs20 Sangria\par'#13#10'#<dbtext displayformat=' +
          #39'000'#39'>id_caixa</dbtext>\par'#13#10#13#10'\pard\f1\fs30\par'#13#10'\par'#13#10'\par'#13#10'\p' +
          'ar'#13#10'\f0\fs20 Valor R$: <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>' +
          'valor</dbtext>\par'#13#10'Descri\'#39'e7\'#39'e3o: <dbtext>sangria</dbtext>\pa' +
          'r'#13#10'\f1\fs24\par'#13#10'\fs30\par'#13#10'\cf0\b0\f0\fs24\par'#13#10'\cf1\b\f1\par'#13#10 +
          '}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 204
        mmTop = 0
        mmWidth = 66917
        BandType = 1
        LayerName = BandLayer27
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand19: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand21: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppFooterBand19: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand21: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 7938
      mmPrintPosition = 0
      object ppSystemVariable38: TppSystemVariable
        DesignLayer = ppDesignLayer21
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 6
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 2646
        mmLeft = 1852
        mmTop = 4233
        mmWidth = 17992
        BandType = 7
        LayerName = BandLayer27
      end
      object ppSystemVariable39: TppSystemVariable
        DesignLayer = ppDesignLayer21
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 6
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 2646
        mmLeft = 1852
        mmTop = 794
        mmWidth = 5821
        BandType = 7
        LayerName = BandLayer27
      end
    end
    object ppDesignLayers21: TppDesignLayers
      object ppDesignLayer21: TppDesignLayer
        UserName = 'BandLayer27'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList19: TppParameterList
      object ppParameter18: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object ppReport2: TppReport
    AutoStop = False
    DataPipeline = ppSangria
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 1376
    Top = 167
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppSangria'
    object ppTitleBand20: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 24871
      mmPrintPosition = 0
      object ppRichText95: TppRichText
        DesignLayer = ppDesignLayer22
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs22 Fechamento de Caixa\fs24\par'#13#10'\fs20 (Cancelamento)\' +
          'par'#13#10'\fs30 #<dbtext displayformat='#39'000'#39'>id</dbtext>\fs24\par'#13#10'}'#13 +
          #10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 47725
        BandType = 1
        LayerName = BandLayer28
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel76: TppLabel
        DesignLayer = ppDesignLayer22
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Produtos'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4763
        mmLeft = 14817
        mmTop = 18785
        mmWidth = 21166
        BandType = 1
        LayerName = BandLayer28
      end
    end
    object ppHeaderBand20: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand22: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 5027
      mmPrintPosition = 0
      object ppRichText96: TppRichText
        DesignLayer = ppDesignLayer22
        UserName = 'RichText99'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText99'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 (<dbtext displayformat='#39'000'#39'>co' +
          'digo_pedido_dia</dbtext>) - <dbtext displayformat='#39'mm/dd'#39'>data_p' +
          'edido</dbtext> / <dbtext displayformat='#39'h:nn'#39'>hora_pedido</dbtex' +
          't> \par'#13#10' <dbtext>cliente</dbtext>\par'#13#10' <dbtext>produto</dbtext' +
          '>\par'#13#10' <dbtext displayformat='#39'00'#39'>quantidade</dbtext>Un - <dbte' +
          'xt displayformat='#39'#,0.00;-#,0.00'#39'>valor_total</dbtext>\par'#13#10'\par' +
          #13#10'--------------------------\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 264
        mmWidth = 47057
        BandType = 4
        LayerName = BandLayer28
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand20: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand22: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 36248
      mmPrintPosition = 0
      object ppSystemVariable40: TppSystemVariable
        DesignLayer = ppDesignLayer22
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 29369
        mmWidth = 35190
        BandType = 7
        LayerName = BandLayer28
      end
      object ppSystemVariable41: TppSystemVariable
        DesignLayer = ppDesignLayer22
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 25929
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer28
      end
      object ppLabel77: TppLabel
        DesignLayer = ppDesignLayer22
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Quantidade Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 2381
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer28
      end
      object ppLabel78: TppLabel
        DesignLayer = ppDesignLayer22
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 14288
        mmWidth = 26988
        BandType = 7
        LayerName = BandLayer28
      end
      object ppDBCalc24: TppDBCalc
        DesignLayer = ppDesignLayer22
        UserName = 'DBCalc1'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppSangria
        DisplayFormat = '00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppSangria'
        mmHeight = 4498
        mmLeft = 1852
        mmTop = 8202
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer28
      end
      object ppDBCalc25: TppDBCalc
        DesignLayer = ppDesignLayer22
        UserName = 'DBCalc19'
        Border.mmPadding = 0
        DataField = 'valor_total'
        DataPipeline = ppSangria
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppSangria'
        mmHeight = 4498
        mmLeft = 1852
        mmTop = 19050
        mmWidth = 32015
        BandType = 7
        LayerName = BandLayer28
      end
    end
    object ppDesignLayers22: TppDesignLayers
      object ppDesignLayer22: TppDesignLayer
        UserName = 'BandLayer28'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList20: TppParameterList
      object ppParameter19: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object PRODUTOS: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 1632
    Top = 256
    object PRODUTOScodigo: TIntegerField
      FieldName = 'codigo'
    end
    object PRODUTOSid: TIntegerField
      FieldName = 'id'
    end
    object PRODUTOSgrupo: TIntegerField
      FieldName = 'grupo'
    end
    object PRODUTOSdescricao: TStringField
      FieldName = 'descricao'
      Size = 255
    end
    object PRODUTOSproduto: TStringField
      FieldName = 'produto'
      Size = 255
    end
    object PRODUTOSnome: TStringField
      FieldName = 'nome'
      Size = 255
    end
    object PRODUTOStotal: TFloatField
      FieldName = 'total'
    end
    object PRODUTOSquantidade: TFloatField
      FieldName = 'quantidade'
    end
    object PRODUTOStipo: TStringField
      FieldName = 'tipo'
      Size = 255
    end
    object PRODUTOSadicionais: TStringField
      FieldName = 'adicionais'
      Size = 255
    end
    object PRODUTOSunitario: TFloatField
      FieldName = 'unitario'
    end
  end
  object ppPIX: TppReport
    AutoStop = False
    DataPipeline = pPix
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 1048
    Top = 679
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'pPix'
    object ppTitleBand21: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 90488
      mmPrintPosition = 0
      object ppRichText98: TppRichText
        DesignLayer = ppDesignLayer23
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs28 PIX <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>valor<' +
          '/dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 71840
        BandType = 1
        LayerName = BandLayer29
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppQrcodPix: Tpp2DBarCode
        DesignLayer = ppDesignLayer23
        UserName = 'TwoDBarCode2'
        AlignBarcode = ahLeft
        Border.mmPadding = 0
        Color = clBlack
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Transparent = True
        BarCodeType = bcQRCode
        Data = 
          '00020126580014br.gov.bcb.pix01368e648925-eee6-401f-9940-fd008f6b' +
          '997d520400005303986540519.555802BR5914ALLANCOLOMBO266007Cricima6' +
          '2240520mpqrinter672147195636304D4FB'
        PrintHumanReadable = False
        MaxiCodeSettings.CarrierPostalCode = '000000000'
        MaxiCodeSettings.HorPixelsPerMM = 4.000000000000000000
        MaxiCodeSettings.VerPixelsPerMM = 4.000000000000000000
        MaxiCodeSettings.mmBarHeight = 1059
        MaxiCodeSettings.mmBarWidth = 1059
        MaxiCodeSettings.mmQuietZone = 2118
        PDF417Settings.mmBarHeight = 2118
        PDF417Settings.mmBarWidth = 530
        PDF417Settings.mmQuietZone = 2118
        QRCodeSettings.IncludeBOM = True
        QRCodeSettings.mmModuleSize = 1059
        QRCodeSettings.mmQuietZone = 1059
        QRCodeSettings.ECICode = -1
        DataMatrixSettings.mmModuleSize = 1059
        DataMatrixSettings.mmQuietZone = 1059
        AztecCodeSettings.mmModuleSize = 1600
        mmHeight = 58208
        mmLeft = 9790
        mmTop = 17992
        mmWidth = 58208
        BandType = 1
        LayerName = BandLayer29
      end
      object ppSystemVariable42: TppSystemVariable
        DesignLayer = ppDesignLayer23
        UserName = 'SystemVariable42'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 84667
        mmWidth = 35190
        BandType = 1
        LayerName = BandLayer29
      end
      object ppSystemVariable43: TppSystemVariable
        DesignLayer = ppDesignLayer23
        UserName = 'SystemVariable43'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 80433
        mmWidth = 38894
        BandType = 1
        LayerName = BandLayer29
      end
    end
    object ppHeaderBand21: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand23: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppFooterBand21: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand23: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 8731
      mmPrintPosition = 0
    end
    object ppDesignLayers23: TppDesignLayers
      object ppDesignLayer23: TppDesignLayer
        UserName = 'BandLayer29'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList21: TppParameterList
      object ppParameter20: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object PIX: TFDMemTable
    Active = True
    FieldDefs = <
      item
        Name = 'valor'
        DataType = ftFloat
      end
      item
        Name = 'base64'
        DataType = ftString
        Size = 25555
      end>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 960
    Top = 672
    object PIXvalor: TFloatField
      FieldName = 'valor'
    end
    object PIXbase64: TStringField
      FieldName = 'base64'
      Size = 25555
    end
  end
  object dsPIX: TDataSource
    DataSet = PIX
    Left = 1096
    Top = 672
  end
  object pPix: TppBDEPipeline
    DataSource = dsPIX
    UserName = 'PIX'
    Left = 1008
    Top = 680
    object pPixppField1: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor'
      FieldName = 'valor'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 0
    end
    object pPixppField2: TppField
      FieldAlias = 'base64'
      FieldName = 'base64'
      FieldLength = 25555
      DisplayWidth = 25555
      Position = 1
    end
  end
  object ppComputado: TppBDEPipeline
    DataSource = dsComputado
    UserName = 'Computado'
    Left = 1544
    Top = 728
  end
  object dsComputado: TDataSource
    DataSet = CAIXA_RESUMO
    Left = 1120
    Top = 344
  end
  object ppResumoSangria: TppBDEPipeline
    DataSource = dsResumoSangria
    UserName = 'ResumoSangria'
    Left = 1616
    Top = 728
  end
  object dsResumoSangria: TDataSource
    DataSet = CAIXA_RESUMO
    Left = 1192
    Top = 344
  end
  object ppCategoria: TppBDEPipeline
    DataSource = dsCategoria
    UserName = 'Categoria'
    Left = 1160
    Top = 624
  end
  object dsCategoria: TDataSource
    DataSet = CAIXA_PRODUTO
    Left = 1720
    Top = 384
  end
  object CAIXA_RESUMO56MM: TppReport
    AutoStop = False
    DataPipeline = ppResumo
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '56mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 2540
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 48000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 218
    Top = 215
    Version = '21.02'
    mmColumnWidth = 67300
    DataPipelineName = 'ppResumo'
    object ppTitleBand26: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 60854
      mmPrintPosition = 0
      object ppRichText63: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs20 Fechamento de Caixa\par'#13#10'\fs18 (Resumido)\fs20\par'#13 +
          #10'\fs18 #<dbtext displayformat='#39'000'#39'>id</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 43187
        BandType = 1
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel87: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Abertura:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3293
        mmLeft = 1852
        mmTop = 18256
        mmWidth = 26988
        BandType = 1
        LayerName = BandLayer34
      end
      object ppRichText85: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText45'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText45'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs16 <dbtext>data_abertura</dbtext> <dbtext' +
          '>hora_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 22840
        mmWidth = 39688
        BandType = 1
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel88: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Fechamento:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 27495
        mmWidth = 26988
        BandType = 1
        LayerName = BandLayer34
      end
      object ppLabel89: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label101'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Abertura:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 36875
        mmWidth = 37306
        BandType = 1
        LayerName = BandLayer34
      end
      object ppLabel90: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label13'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Valor Fechamento:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 46236
        mmWidth = 42069
        BandType = 1
        LayerName = BandLayer34
      end
      object ppRichText103: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText48'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        KeepTogether = True
        Border.mmPadding = 0
        Caption = 'RichText48'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs16 <dbtext>data_fechamento</dbtext> <dbte' +
          'xt>hora_fechamento</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 32171
        mmWidth = 39688
        BandType = 1
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText104: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText49'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText49'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs16 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 41488
        mmWidth = 24342
        BandType = 1
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText105: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText50'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText50'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs16 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_fechamento</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 50934
        mmWidth = 24077
        BandType = 1
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppSubReport7: TppSubReport
        DesignLayer = ppDesignLayer31
        UserName = 'SubReport2'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppComputado'
        mmHeight = 5027
        mmLeft = 0
        mmTop = 56356
        mmWidth = 45460
        BandType = 1
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport7: TppChildReport
          AutoStop = False
          DataPipeline = ppComputado
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '56mm'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 0
          PrinterSetup.mmMarginLeft = 0
          PrinterSetup.mmMarginRight = 2540
          PrinterSetup.mmMarginTop = 0
          PrinterSetup.mmPaperHeight = 209900
          PrinterSetup.mmPaperWidth = 48000
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppComputado'
          object ppTitleBand27: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 3969
            mmPrintPosition = 0
            object ppRichText106: TppRichText
              DesignLayer = ppDesignLayer30
              UserName = 'RichText101'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText101'
              ExportRTFAsBitmap = False
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
                'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs20 ' +
                'Informado\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 3390
              mmLeft = 1852
              mmTop = 0
              mmWidth = 66675
              BandType = 1
              LayerName = BandLayer33
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppHeaderBand25: TppHeaderBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppDetailBand28: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 8202
            mmPrintPosition = 0
            object ppDBText42: TppDBText
              DesignLayer = ppDesignLayer30
              UserName = 'DBText32'
              Border.mmPadding = 0
              DataField = 'descricao'
              DataPipeline = ppComputado
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppComputado'
              mmHeight = 3292
              mmLeft = 1588
              mmTop = 284
              mmWidth = 41540
              BandType = 4
              LayerName = BandLayer33
            end
            object ppDBText43: TppDBText
              DesignLayer = ppDesignLayer30
              UserName = 'DBText1'
              Border.mmPadding = 0
              DataField = 'valor'
              DataPipeline = ppComputado
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppComputado'
              mmHeight = 3292
              mmLeft = 1588
              mmTop = 3501
              mmWidth = 24871
              BandType = 4
              LayerName = BandLayer33
            end
            object ppLine26: TppLine
              DesignLayer = ppDesignLayer30
              UserName = 'Line6'
              Border.Style = psDot
              Border.mmPadding = 0
              Pen.Style = psDot
              Weight = 0.750000000000000000
              mmHeight = 1234
              mmLeft = 0
              mmTop = 6850
              mmWidth = 84138
              BandType = 4
              LayerName = BandLayer33
            end
          end
          object ppFooterBand26: TppFooterBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand28: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 11642
            mmPrintPosition = 0
            object ppLabel91: TppLabel
              DesignLayer = ppDesignLayer30
              UserName = 'Label1'
              Border.mmPadding = 0
              Caption = 'Total:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 3292
              mmLeft = 1852
              mmTop = 794
              mmWidth = 12700
              BandType = 7
              LayerName = BandLayer33
            end
            object ppDBCalc32: TppDBCalc
              DesignLayer = ppDesignLayer30
              UserName = 'DBCalc26'
              Border.mmPadding = 0
              DataField = 'valor'
              DataPipeline = ppComputado
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppComputado'
              mmHeight = 3292
              mmLeft = 14817
              mmTop = 794
              mmWidth = 28310
              BandType = 7
              LayerName = BandLayer33
            end
            object ppSubReport8: TppSubReport
              DesignLayer = ppDesignLayer30
              UserName = 'SubReport3'
              ExpandAll = False
              NewPrintJob = False
              OutlineSettings.CreateNode = True
              TraverseAllData = False
              DataPipelineName = 'ppResumo'
              mmHeight = 5027
              mmLeft = 0
              mmTop = 6615
              mmWidth = 45460
              BandType = 7
              LayerName = BandLayer33
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
              object ppChildReport8: TppChildReport
                AutoStop = False
                DataPipeline = ppResumo
                PrinterSetup.BinName = 'Default'
                PrinterSetup.DocumentName = '56mm'
                PrinterSetup.PaperName = 'Custom'
                PrinterSetup.PrinterName = 'Default'
                PrinterSetup.SaveDeviceSettings = True
                PrinterSetup.mmMarginBottom = 0
                PrinterSetup.mmMarginLeft = 0
                PrinterSetup.mmMarginRight = 2540
                PrinterSetup.mmMarginTop = 0
                PrinterSetup.mmPaperHeight = 209900
                PrinterSetup.mmPaperWidth = 48000
                PrinterSetup.PaperSize = 256
                PrinterSetup.DevMode = {
                  4004000044006100720075006D00610020004400520000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000001040306DC0064034FEF8005010000013A6202036400010001016400
                  0100010064000200010043007500730074006F006D0000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000100000000000000
                  010000000200000001000000FFFFFFFF00000000000000000000000000000000
                  44494E552200080164030000B8225C4F00000000000000000000000000000000
                  0000000000000000000000000800000001000000000001000000050001000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000000000000
                  0000000000000000000000000000000001000000000000000000000000000000
                  0000000000000000000000000000000000000000000000000000000008010000
                  534D544A000000001000F80044006100720075006D0061002000440052003700
                  300030002000530070006F006F006C00650072000000496E70757442696E004F
                  50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
                  74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
                  4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
                  53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
                  6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
                  616F000000000000000000000000000000000000000000000000000000000000
                  00000000}
                Version = '21.02'
                mmColumnWidth = 0
                DataPipelineName = 'ppResumo'
                object ppTitleBand28: TppTitleBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  mmBottomOffset = 0
                  mmHeight = 4498
                  mmPrintPosition = 0
                  object ppRichText107: TppRichText
                    DesignLayer = ppDesignLayer29
                    UserName = 'RichText19'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clBlack
                    Font.Name = 'Courier New'
                    Font.Size = 9
                    Font.Style = [fsBold]
                    Border.mmPadding = 0
                    Caption = 'RichText19'
                    ExportRTFAsBitmap = False
                    RichText = 
                      '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                      '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
                      'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs18 ' +
                      'Computado\par'#13#10'}'#13#10#0
                    RemoveEmptyLines = False
                    Transparent = True
                    mmHeight = 3292
                    mmLeft = 1852
                    mmTop = 265
                    mmWidth = 66675
                    BandType = 1
                    LayerName = BandLayer32
                    mmBottomOffset = 0
                    mmOverFlowOffset = 0
                    mmStopPosition = 0
                    mmMinHeight = 0
                  end
                end
                object ppHeaderBand26: TppHeaderBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  mmBottomOffset = 0
                  mmHeight = 0
                  mmPrintPosition = 0
                end
                object ppDetailBand29: TppDetailBand
                  Background1.Brush.Style = bsClear
                  Background2.Brush.Style = bsClear
                  Border.mmPadding = 0
                  mmBottomOffset = 0
                  mmHeight = 8202
                  mmPrintPosition = 0
                  object ppDBText44: TppDBText
                    DesignLayer = ppDesignLayer29
                    UserName = 'DBText1'
                    Border.mmPadding = 0
                    DataField = 'descricao'
                    DataPipeline = ppResumo
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clWindowText
                    Font.Name = 'Courier New'
                    Font.Size = 9
                    Font.Style = [fsBold]
                    Transparent = True
                    DataPipelineName = 'ppResumo'
                    mmHeight = 3292
                    mmLeft = 1852
                    mmTop = 265
                    mmWidth = 36513
                    BandType = 4
                    LayerName = BandLayer32
                  end
                  object ppDBText45: TppDBText
                    DesignLayer = ppDesignLayer29
                    UserName = 'DBText2'
                    Border.mmPadding = 0
                    DataField = 'valor_tipo_pagamento'
                    DataPipeline = ppResumo
                    DisplayFormat = '$#,0.00;-$#,0.00'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clWindowText
                    Font.Name = 'Courier New'
                    Font.Size = 9
                    Font.Style = [fsBold]
                    Transparent = True
                    DataPipelineName = 'ppResumo'
                    mmHeight = 3292
                    mmLeft = 1852
                    mmTop = 3489
                    mmWidth = 24077
                    BandType = 4
                    LayerName = BandLayer32
                  end
                  object ppLine31: TppLine
                    DesignLayer = ppDesignLayer29
                    UserName = 'Line1'
                    Border.Style = psDot
                    Border.mmPadding = 0
                    Pen.Style = psDot
                    Weight = 0.750000000000000000
                    mmHeight = 940
                    mmLeft = 0
                    mmTop = 7212
                    mmWidth = 84138
                    BandType = 4
                    LayerName = BandLayer32
                  end
                end
                object ppFooterBand27: TppFooterBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  mmBottomOffset = 0
                  mmHeight = 0
                  mmPrintPosition = 0
                end
                object ppSummaryBand29: TppSummaryBand
                  Background.Brush.Style = bsClear
                  Border.mmPadding = 0
                  PrintHeight = phDynamic
                  mmBottomOffset = 0
                  mmHeight = 9790
                  mmPrintPosition = 0
                  object ppLabel92: TppLabel
                    DesignLayer = ppDesignLayer29
                    UserName = 'Label1'
                    Border.mmPadding = 0
                    Caption = 'Total:'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clBlack
                    Font.Name = 'Courier New'
                    Font.Size = 9
                    Font.Style = [fsBold]
                    FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
                    FormFieldSettings.FormFieldType = fftNone
                    Transparent = True
                    mmHeight = 3292
                    mmLeft = 1852
                    mmTop = 529
                    mmWidth = 11113
                    BandType = 7
                    LayerName = BandLayer32
                  end
                  object ppDBCalc33: TppDBCalc
                    DesignLayer = ppDesignLayer29
                    UserName = 'DBCalc1'
                    Border.mmPadding = 0
                    DataField = 'valor_tipo_pagamento'
                    DataPipeline = ppResumo
                    DisplayFormat = '$#,0.00;-$#,0.00'
                    Font.Charset = DEFAULT_CHARSET
                    Font.Color = clBlack
                    Font.Name = 'Courier New'
                    Font.Size = 9
                    Font.Style = [fsBold]
                    Transparent = True
                    DataPipelineName = 'ppResumo'
                    mmHeight = 3292
                    mmLeft = 15081
                    mmTop = 529
                    mmWidth = 28310
                    BandType = 7
                    LayerName = BandLayer32
                  end
                  object ppSubReport9: TppSubReport
                    DesignLayer = ppDesignLayer29
                    UserName = 'SubReport4'
                    ExpandAll = False
                    NewPrintJob = False
                    OutlineSettings.CreateNode = True
                    TraverseAllData = False
                    DataPipelineName = 'ppResumoSangria'
                    mmHeight = 5027
                    mmLeft = 0
                    mmTop = 4763
                    mmWidth = 45460
                    BandType = 7
                    LayerName = BandLayer32
                    mmBottomOffset = 0
                    mmOverFlowOffset = 0
                    mmStopPosition = 0
                    mmMinHeight = 0
                    object ppChildReport9: TppChildReport
                      AutoStop = False
                      DataPipeline = ppResumoSangria
                      PrinterSetup.BinName = 'Default'
                      PrinterSetup.DocumentName = '56mm'
                      PrinterSetup.PaperName = 'Custom'
                      PrinterSetup.PrinterName = 'Default'
                      PrinterSetup.SaveDeviceSettings = True
                      PrinterSetup.mmMarginBottom = 0
                      PrinterSetup.mmMarginLeft = 0
                      PrinterSetup.mmMarginRight = 2540
                      PrinterSetup.mmMarginTop = 0
                      PrinterSetup.mmPaperHeight = 209900
                      PrinterSetup.mmPaperWidth = 48000
                      PrinterSetup.PaperSize = 256
                      PrinterSetup.DevMode = {
                        4004000044006100720075006D00610020004400520000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000001040306DC0064034FEF8005010000013A6202036400010001016400
                        0100010064000200010043007500730074006F006D0000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000100000000000000
                        010000000200000001000000FFFFFFFF00000000000000000000000000000000
                        44494E552200080164030000B8225C4F00000000000000000000000000000000
                        0000000000000000000000000800000001000000000001000000050001000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000000000000
                        0000000000000000000000000000000001000000000000000000000000000000
                        0000000000000000000000000000000000000000000000000000000008010000
                        534D544A000000001000F80044006100720075006D0061002000440052003700
                        300030002000530070006F006F006C00650072000000496E70757442696E004F
                        50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
                        74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
                        4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
                        53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
                        6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
                        616F000000000000000000000000000000000000000000000000000000000000
                        00000000}
                      Version = '21.02'
                      mmColumnWidth = 0
                      DataPipelineName = 'ppResumoSangria'
                      object ppTitleBand29: TppTitleBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        mmBottomOffset = 0
                        mmHeight = 3969
                        mmPrintPosition = 0
                        object ppRichText108: TppRichText
                          DesignLayer = ppDesignLayer28
                          UserName = 'RichText102'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Courier New'
                          Font.Size = 9
                          Font.Style = [fsBold]
                          Border.mmPadding = 0
                          Caption = 'RichText102'
                          ExportRTFAsBitmap = False
                          RichText = 
                            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                            '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
                            'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs18 ' +
                            'Sangria\par'#13#10'}'#13#10#0
                          RemoveEmptyLines = False
                          Transparent = True
                          mmHeight = 3292
                          mmLeft = 1600
                          mmTop = 265
                          mmWidth = 66675
                          BandType = 1
                          LayerName = BandLayer31
                          mmBottomOffset = 0
                          mmOverFlowOffset = 0
                          mmStopPosition = 0
                          mmMinHeight = 0
                        end
                      end
                      object ppHeaderBand27: TppHeaderBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        PrintOnFirstPage = False
                        PrintOnLastPage = False
                        mmBottomOffset = 0
                        mmHeight = 0
                        mmPrintPosition = 0
                      end
                      object ppDetailBand30: TppDetailBand
                        Background1.Brush.Style = bsClear
                        Background2.Brush.Style = bsClear
                        Border.mmPadding = 0
                        mmBottomOffset = 0
                        mmHeight = 7938
                        mmPrintPosition = 0
                        object ppDBText46: TppDBText
                          DesignLayer = ppDesignLayer28
                          UserName = 'DBText36'
                          Border.mmPadding = 0
                          DataField = 'descricao'
                          DataPipeline = ppResumoSangria
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Courier New'
                          Font.Size = 9
                          Font.Style = [fsBold]
                          Transparent = True
                          DataPipelineName = 'ppResumoSangria'
                          mmHeight = 3292
                          mmLeft = 1588
                          mmTop = 284
                          mmWidth = 41540
                          BandType = 4
                          LayerName = BandLayer31
                        end
                        object ppDBText47: TppDBText
                          DesignLayer = ppDesignLayer28
                          UserName = 'DBText37'
                          Border.mmPadding = 0
                          DataField = 'valor'
                          DataPipeline = ppResumoSangria
                          DisplayFormat = '$ #,0.00;-$ #,0.00'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Courier New'
                          Font.Size = 9
                          Font.Style = [fsBold]
                          Transparent = True
                          DataPipelineName = 'ppResumoSangria'
                          mmHeight = 3292
                          mmLeft = 1588
                          mmTop = 3587
                          mmWidth = 24871
                          BandType = 4
                          LayerName = BandLayer31
                        end
                        object ppLine32: TppLine
                          DesignLayer = ppDesignLayer28
                          UserName = 'Line8'
                          Border.Style = psDot
                          Border.mmPadding = 0
                          Pen.Style = psDot
                          Weight = 0.750000000000000000
                          mmHeight = 1038
                          mmLeft = 0
                          mmTop = 6901
                          mmWidth = 84138
                          BandType = 4
                          LayerName = BandLayer31
                        end
                      end
                      object ppPageSummaryBand3: TppPageSummaryBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        mmBottomOffset = 0
                        mmHeight = 0
                        mmPrintPosition = 0
                      end
                      object ppFooterBand28: TppFooterBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        mmBottomOffset = 0
                        mmHeight = 0
                        mmPrintPosition = 0
                      end
                      object ppSummaryBand30: TppSummaryBand
                        Background.Brush.Style = bsClear
                        Border.mmPadding = 0
                        mmBottomOffset = 0
                        mmHeight = 5556
                        mmPrintPosition = 0
                        object ppLabel93: TppLabel
                          DesignLayer = ppDesignLayer28
                          UserName = 'Label82'
                          Border.mmPadding = 0
                          Caption = 'Total:'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Courier New'
                          Font.Size = 9
                          Font.Style = [fsBold]
                          FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
                          FormFieldSettings.FormFieldType = fftNone
                          Transparent = True
                          mmHeight = 3292
                          mmLeft = 1588
                          mmTop = 529
                          mmWidth = 11112
                          BandType = 7
                          LayerName = BandLayer31
                        end
                        object ppDBCalc34: TppDBCalc
                          DesignLayer = ppDesignLayer28
                          UserName = 'DBCalc27'
                          Border.mmPadding = 0
                          DataField = 'valor'
                          DataPipeline = ppResumoSangria
                          DisplayFormat = '$#,0.00;-$#,0.00'
                          Font.Charset = DEFAULT_CHARSET
                          Font.Color = clBlack
                          Font.Name = 'Courier New'
                          Font.Size = 9
                          Font.Style = [fsBold]
                          Transparent = True
                          DataPipelineName = 'ppResumoSangria'
                          mmHeight = 3292
                          mmLeft = 14817
                          mmTop = 529
                          mmWidth = 28310
                          BandType = 7
                          LayerName = BandLayer31
                        end
                      end
                      object raCodeModule7: TraCodeModule
                      end
                      object ppDesignLayers28: TppDesignLayers
                        object ppDesignLayer28: TppDesignLayer
                          UserName = 'BandLayer31'
                          LayerType = ltBanded
                          Index = 0
                        end
                      end
                    end
                  end
                end
                object raCodeModule8: TraCodeModule
                end
                object ppDesignLayers29: TppDesignLayers
                  object ppDesignLayer29: TppDesignLayer
                    UserName = 'BandLayer32'
                    LayerType = ltBanded
                    Index = 0
                  end
                end
              end
            end
          end
          object raCodeModule9: TraCodeModule
          end
          object ppDesignLayers30: TppDesignLayers
            object ppDesignLayer30: TppDesignLayer
              UserName = 'BandLayer33'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppHeaderBand28: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand31: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppFooterBand29: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand31: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 87842
      mmPrintPosition = 0
      object ppSystemVariable44: TppSystemVariable
        DesignLayer = ppDesignLayer31
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 82286
        mmWidth = 35190
        BandType = 7
        LayerName = BandLayer34
      end
      object ppSystemVariable45: TppSystemVariable
        DesignLayer = ppDesignLayer31
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 78846
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer34
      end
      object ppLabel94: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label14'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Vem Buscar:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 41107
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer34
      end
      object ppLabel95: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label15'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Delivery:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 31661
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer34
      end
      object ppLabel96: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label16'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Mesas:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 50496
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer34
      end
      object ppRichText109: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText501'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText501'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs18 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_delivery</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 36373
        mmWidth = 39688
        BandType = 7
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText110: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText52'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText52'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs18 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_vem_buscar</dbtext>\par'#13#10'\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1865
        mmTop = 45816
        mmWidth = 39688
        BandType = 7
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText111: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText53'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText53'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs18 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_mesa</dbtext>\par'#13#10'\par'#13#10'\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 55173
        mmWidth = 39688
        BandType = 7
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel97: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label68'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Taxa:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 22212
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer34
      end
      object ppRichText112: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs18 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>taxa_entrega</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 26979
        mmWidth = 39688
        BandType = 7
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel98: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label73'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Sangria:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 59949
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer34
      end
      object ppRichText113: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText94'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        KeepTogether = True
        Border.mmPadding = 0
        Caption = 'RichText94'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs18 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>sangria</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 64656
        mmWidth = 39688
        BandType = 7
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel99: TppLabel
        DesignLayer = ppDesignLayer31
        UserName = 'Label74'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Servi'#231'o (%):'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 12837
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer34
      end
      object ppRichText114: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText97'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText97'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs18 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>servico</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 17531
        mmWidth = 39688
        BandType = 7
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText115: TppRichText
        DesignLayer = ppDesignLayer31
        UserName = 'RichText100'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText100'
        ExportRTFAsBitmap = False
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs18 ' +
          'Resumo Geral\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3292
        mmLeft = 1852
        mmTop = 7144
        mmWidth = 66675
        BandType = 7
        LayerName = BandLayer34
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object raCodeModule10: TraCodeModule
    end
    object ppDesignLayers31: TppDesignLayers
      object ppDesignLayer31: TppDesignLayer
        UserName = 'BandLayer34'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList22: TppParameterList
      object ppParameter21: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object VAZIA: TFDMemTable
    Active = True
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 440
    Top = 24
    object VAZIAtest: TStringField
      FieldName = 'test'
    end
  end
  object CAIXA_PRODUTO56MM: TppReport
    AutoStop = False
    DataPipeline = ppCategoria
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3275900
    PrinterSetup.mmPaperWidth = 48000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 218
    Top = 528
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppCategoria'
    object ppTitleBand12: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 29898
      mmPrintPosition = 0
      object ppRichText65: TppRichText
        DesignLayer = ppDesignLayer32
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs24 Fechamento de Caixa\par'#13#10'\fs20 (Produto)\par'#13#10'\fs30' +
          ' #<dbtext displayformat='#39'000'#39'>id</dbtext>\par'#13#10'\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 66047
        BandType = 1
        LayerName = BandLayer36
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel42: TppLabel
        DesignLayer = ppDesignLayer32
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Categoria'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 23813
        mmWidth = 45014
        BandType = 1
        LayerName = BandLayer36
      end
    end
    object ppHeaderBand12: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand14: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4233
      mmPrintPosition = 0
      object ppDBText17: TppDBText
        DesignLayer = ppDesignLayer32
        UserName = 'DBText38'
        Border.mmPadding = 0
        DataField = 'produto'
        DataPipeline = ppCategoria
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        ParentDataPipeline = False
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 3704
        mmLeft = 9790
        mmTop = 0
        mmWidth = 50800
        BandType = 4
        LayerName = BandLayer36
      end
      object ppDBText18: TppDBText
        DesignLayer = ppDesignLayer32
        UserName = 'DBText39'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppCategoria
        DisplayFormat = '000'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        ParentDataPipeline = False
        TextAlignment = taCentered
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 0
        mmWidth = 7453
        BandType = 4
        LayerName = BandLayer36
      end
    end
    object ppFooterBand12: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand13: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 46302
      mmPrintPosition = 0
      object ppLabel43: TppLabel
        DesignLayer = ppDesignLayer32
        UserName = 'Label40'
        Border.mmPadding = 0
        Caption = 'Quantidade:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 17109
        mmWidth = 23283
        BandType = 7
        LayerName = BandLayer36
      end
      object ppDBCalc10: TppDBCalc
        DesignLayer = ppDesignLayer32
        UserName = 'DBCalc8'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppCategoria
        DisplayFormat = '000'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 21254
        mmWidth = 30692
        BandType = 7
        LayerName = BandLayer36
      end
      object ppLabel44: TppLabel
        DesignLayer = ppDesignLayer32
        UserName = 'Label401'
        Border.mmPadding = 0
        Caption = 'Categoria R$:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4171
        mmLeft = 1852
        mmTop = 529
        mmWidth = 27517
        BandType = 7
        LayerName = BandLayer36
      end
      object ppDBCalc35: TppDBCalc
        DesignLayer = ppDesignLayer32
        UserName = 'DBCalc9'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppCategoria
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 4674
        mmWidth = 28575
        BandType = 7
        LayerName = BandLayer36
      end
      object ppLabel45: TppLabel
        DesignLayer = ppDesignLayer32
        UserName = 'Label75'
        Border.mmPadding = 0
        Caption = 'Adicional R$:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 8819
        mmWidth = 27517
        BandType = 7
        LayerName = BandLayer36
      end
      object ppDBCalc36: TppDBCalc
        DesignLayer = ppDesignLayer32
        UserName = 'DBCalc22'
        Border.mmPadding = 0
        DataField = 'total_adicional'
        DataPipeline = ppCategoria
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 12964
        mmWidth = 28575
        BandType = 7
        LayerName = BandLayer36
      end
      object ppLabel46: TppLabel
        DesignLayer = ppDesignLayer32
        UserName = 'Label79'
        Border.mmPadding = 0
        Caption = 'Total R$:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 25398
        mmWidth = 19050
        BandType = 7
        LayerName = BandLayer36
      end
      object ppDBCalc37: TppDBCalc
        DesignLayer = ppDesignLayer32
        UserName = 'DBCalc23'
        Border.mmPadding = 0
        DataField = 'total_geral'
        DataPipeline = ppCategoria
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppCategoria'
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 29543
        mmWidth = 36777
        BandType = 7
        LayerName = BandLayer36
      end
      object ppSubReport10: TppSubReport
        DesignLayer = ppDesignLayer32
        UserName = 'SubReport6'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppProduto'
        mmHeight = 5027
        mmLeft = 0
        mmTop = 40746
        mmWidth = 48000
        BandType = 7
        LayerName = BandLayer36
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport10: TppChildReport
          AutoStop = False
          DataPipeline = ppProduto
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 0
          PrinterSetup.mmMarginLeft = 0
          PrinterSetup.mmMarginRight = 0
          PrinterSetup.mmMarginTop = 0
          PrinterSetup.mmPaperHeight = 3275900
          PrinterSetup.mmPaperWidth = 48000
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 69088
          DataPipelineName = 'ppProduto'
          object ppTitleBand30: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 17463
            mmPrintPosition = 0
            object ppLabel47: TppLabel
              DesignLayer = ppDesignLayer12
              UserName = 'Label80'
              Border.mmPadding = 0
              Caption = 'Produtos'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 12
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              TextAlignment = taCentered
              Transparent = True
              mmHeight = 4763
              mmLeft = 1323
              mmTop = 11642
              mmWidth = 45860
              BandType = 1
              LayerName = BandLayer35
            end
          end
          object ppDetailBand32: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 3969
            mmPrintPosition = 0
            object ppDBText48: TppDBText
              DesignLayer = ppDesignLayer12
              UserName = 'DBText40'
              Border.mmPadding = 0
              DataField = 'produto'
              DataPipeline = ppProduto
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 8
              Font.Style = [fsBold]
              ParentDataPipeline = False
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 3704
              mmLeft = 9790
              mmTop = 0
              mmWidth = 50800
              BandType = 4
              LayerName = BandLayer35
            end
            object ppDBText49: TppDBText
              DesignLayer = ppDesignLayer12
              UserName = 'DBText41'
              Border.mmPadding = 0
              DataField = 'quantidade'
              DataPipeline = ppProduto
              DisplayFormat = '000'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 8
              Font.Style = [fsBold]
              ParentDataPipeline = False
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 3704
              mmLeft = 1852
              mmTop = 0
              mmWidth = 7452
              BandType = 4
              LayerName = BandLayer35
            end
          end
          object ppPageSummaryBand4: TppPageSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppFooterBand30: TppFooterBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand32: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 53711
            mmPrintPosition = 0
            object ppLabel48: TppLabel
              DesignLayer = ppDesignLayer12
              UserName = 'Label402'
              Border.mmPadding = 0
              Caption = 'Quantidade:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 17022
              mmWidth = 23283
              BandType = 7
              LayerName = BandLayer35
            end
            object ppDBCalc38: TppDBCalc
              DesignLayer = ppDesignLayer12
              UserName = 'DBCalc28'
              Border.mmPadding = 0
              DataField = 'quantidade'
              DataPipeline = ppProduto
              DisplayFormat = '000'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 21167
              mmWidth = 25135
              BandType = 7
              LayerName = BandLayer35
            end
            object ppLabel49: TppLabel
              DesignLayer = ppDesignLayer12
              UserName = 'Label84'
              Border.mmPadding = 0
              Caption = 'Produtos R$:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4171
              mmLeft = 1323
              mmTop = 529
              mmWidth = 25400
              BandType = 7
              LayerName = BandLayer35
            end
            object ppDBCalc39: TppDBCalc
              DesignLayer = ppDesignLayer12
              UserName = 'DBCalc29'
              Border.mmPadding = 0
              DataField = 'total'
              DataPipeline = ppProduto
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 4587
              mmWidth = 23548
              BandType = 7
              LayerName = BandLayer35
            end
            object ppLabel50: TppLabel
              DesignLayer = ppDesignLayer12
              UserName = 'Label85'
              Border.mmPadding = 0
              Caption = 'Adicional R$:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 8732
              mmWidth = 27517
              BandType = 7
              LayerName = BandLayer35
            end
            object ppDBCalc40: TppDBCalc
              DesignLayer = ppDesignLayer12
              UserName = 'DBCalc30'
              Border.mmPadding = 0
              DataField = 'total_adicional'
              DataPipeline = ppProduto
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 12877
              mmWidth = 23548
              BandType = 7
              LayerName = BandLayer35
            end
            object ppLabel100: TppLabel
              DesignLayer = ppDesignLayer12
              UserName = 'Label86'
              Border.mmPadding = 0
              Caption = 'Total R$:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 29457
              mmWidth = 19050
              BandType = 7
              LayerName = BandLayer35
            end
            object ppDBCalc41: TppDBCalc
              DesignLayer = ppDesignLayer12
              UserName = 'DBCalc31'
              Border.mmPadding = 0
              DataField = 'total_geral'
              DataPipeline = ppProduto
              DisplayFormat = '$ #,0.00;-$ #,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppProduto'
              mmHeight = 4233
              mmLeft = 1323
              mmTop = 25312
              mmWidth = 31750
              BandType = 7
              LayerName = BandLayer35
            end
            object ppSystemVariable24: TppSystemVariable
              DesignLayer = ppDesignLayer12
              UserName = 'SystemVariable22'
              Border.mmPadding = 0
              VarType = vtDocumentName
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 1323
              mmTop = 45244
              mmWidth = 38894
              BandType = 7
              LayerName = BandLayer35
            end
            object ppSystemVariable25: TppSystemVariable
              DesignLayer = ppDesignLayer12
              UserName = 'SystemVariable23'
              Border.mmPadding = 0
              VarType = vtDateTime
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 1323
              mmTop = 49213
              mmWidth = 35190
              BandType = 7
              LayerName = BandLayer35
            end
          end
          object ppDesignLayers14: TppDesignLayers
            object ppDesignLayer12: TppDesignLayer
              UserName = 'BandLayer35'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppDesignLayers32: TppDesignLayers
      object ppDesignLayer32: TppDesignLayer
        UserName = 'BandLayer36'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList12: TppParameterList
      object ppParameter11: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object DADOS_CABECALHO: TFDMemTable
    FieldDefs = <>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 984
    Top = 392
    object DADOS_CABECALHOnome: TStringField
      FieldName = 'nome'
      Size = 255
    end
    object DADOS_CABECALHOcep: TStringField
      FieldName = 'cep'
      Size = 255
    end
    object DADOS_CABECALHOrua: TStringField
      FieldName = 'rua'
      Size = 255
    end
    object DADOS_CABECALHObairro: TStringField
      FieldName = 'bairro'
      Size = 255
    end
    object DADOS_CABECALHOcidade: TStringField
      FieldName = 'cidade'
      Size = 255
    end
    object DADOS_CABECALHOestado: TStringField
      FieldName = 'estado'
      Size = 255
    end
    object DADOS_CABECALHOcnpj: TStringField
      FieldName = 'cnpj'
      Size = 255
    end
    object DADOS_CABECALHOie: TStringField
      FieldName = 'ie'
      Size = 255
    end
    object DADOS_CABECALHOrazao: TStringField
      DisplayWidth = 255
      FieldName = 'razao'
      Size = 255
    end
    object DADOS_CABECALHOnumero: TStringField
      FieldName = 'numero'
      Size = 25
    end
  end
  object dsCabecalho: TDataSource
    DataSet = DADOS_CABECALHO
    Left = 1464
    Top = 248
  end
  object ppCabecalho: TppBDEPipeline
    DataSource = dsCabecalho
    UserName = 'Cabecalho'
    Left = 1168
    Top = 720
  end
  object DADOS_RECIBO: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 1256
    Top = 312
  end
  object dsRecibo: TDataSource
    DataSet = DADOS_RECIBO
    Left = 1256
    Top = 376
  end
  object ppRecibo: TppBDEPipeline
    DataSource = dsRecibo
    UserName = 'Recibo'
    Left = 1256
    Top = 440
  end
  object CAIXA_RECIBO: TppReport
    AutoStop = False
    DataPipeline = ppRecibo
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 50
    Top = 775
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppRecibo'
    object ppTitleBand15: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 16404
      mmPrintPosition = 0
      object ppRichText10: TppRichText
        DesignLayer = ppDesignLayer17
        UserName = 'RichText16'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText16'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0\fs16 CNPJ: <dbtext dat' +
          'apipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>razao</dbtext>\par'#13#10'<dbtext datapipeline='#39'ppCabecalho'#39'>' +
          'rua</dbtext>, <dbtext datapipeline='#39'ppCabecalho'#39'>rua</dbtext> <d' +
          'btext datapipeline='#39'ppCabecalho'#39'>bairro</dbtext> - <dbtext datap' +
          'ipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <dbtext datapipeline='#39'pp' +
          'Cabecalho'#39'>estado</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>ce' +
          'p</dbtext> IE: <dbtext datapipeline='#39'ppCabecalho'#39'>ie</dbtext>\pa' +
          'r'#13#10'\b\f1\fs24\par'#13#10'\f0\fs20 RECIBO DE(O) <dbtext>pagamento</dbte' +
          'xt>\par'#13#10'#<dbtext displayformat='#39'000'#39'>id_caixa</dbtext>\par'#13#10'\pa' +
          'r'#13#10#13#10'\pard Na data <dbtext>data</dbtext> \'#39'e1s <dbtext>hora</dbt' +
          'ext>, foi feito uma nota no valor de <dbtext displayformat='#39'$#,0' +
          '.00;-$#,0.00'#39'>valor</dbtext> para\par'#13#10'<dbtext>cliente</dbtext>.' +
          '\par'#13#10'\f1\fs30\par'#13#10#13#10'\pard\qc\f0\fs24 Assinatura\f1\par'#13#10#13#10'\par' +
          'd\fs30\par'#13#10'\cf0\b0\f0\fs24\par'#13#10'\cf1\b\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 204
        mmTop = 0
        mmWidth = 66917
        BandType = 1
        LayerName = BandLayer37
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand15: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand17: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppFooterBand15: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand17: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 16140
      mmPrintPosition = 0
      object ppSystemVariable4: TppSystemVariable
        DesignLayer = ppDesignLayer17
        UserName = 'SystemVariable1'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 6
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 2646
        mmLeft = 1852
        mmTop = 10863
        mmWidth = 17992
        BandType = 7
        LayerName = BandLayer37
      end
      object ppSystemVariable30: TppSystemVariable
        DesignLayer = ppDesignLayer17
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 6
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 2646
        mmLeft = 1852
        mmTop = 7424
        mmWidth = 5821
        BandType = 7
        LayerName = BandLayer37
      end
    end
    object ppDesignLayers17: TppDesignLayers
      object ppDesignLayer17: TppDesignLayer
        UserName = 'BandLayer37'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList15: TppParameterList
      object ppParameter14: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object pCobaia: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 2540
    PrinterSetup.mmMarginLeft = 2540
    PrinterSetup.mmMarginRight = 2540
    PrinterSetup.mmMarginTop = 2540
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    PreviewFormSettings.PageSeparation = 1
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 976
    Top = 24
    Version = '21.02'
    mmColumnWidth = 75220
    DataPipelineName = 'ppDados'
    object ppTitleBand31: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 39688
      mmPrintPosition = 0
      object ppRichText69: TppRichText
        DesignLayer = ppDesignLayer35
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs22 <db' +
          'text displayformat='#39'000000'#39'>codigo_comanda</dbtext>\b0\fs20\par'#13 +
          #10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3905
        mmLeft = 2346
        mmTop = 25929
        mmWidth = 65387
        BandType = 1
        LayerName = Foreground8
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText70: TppRichText
        DesignLayer = ppDesignLayer35
        UserName = 'RichText3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText3'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}{\f2\fnil\fcharset0 Arial;}' +
          '{\f3\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blu' +
          'e0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\q' +
          'c\cf1\f0\fs16 <dbtext>origem_1</dbtext>\b\f1\par'#13#10'\par'#13#10#13#10'\pard\' +
          'f2 Data Pedido: <dbtext>data_pedido</dbtext> <dbtext>hora_pedido' +
          '</dbtext>\f3\par'#13#10'\f2 Cliente: <dbtext>nome</dbtext>\par'#13#10'Celula' +
          'r: <dbtext>celular</dbtext>\par'#13#10'<dbtext>qtd_pedidos_cliente</db' +
          'text>\par'#13#10'<dbtext>endereco_completo</dbtext>\par'#13#10'\f3\fs20\par'#13 +
          #10#13#10'\pard\qc\ul\f2\fs18 <dbtext>pedido_site</dbtext>\par'#13#10'\par'#13#10'\' +
          'ulnone\fs16 Itens Do Pedido\f0\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 2381
        mmTop = 34616
        mmWidth = 65352
        BandType = 1
        LayerName = Foreground8
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText29: TppDBText
        DesignLayer = ppDesignLayer35
        UserName = 'DBText1'
        Border.mmPadding = 0
        Color = clBlack
        DataField = 'tipo_pedido'
        DataPipeline = ppDados
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 0
        mmTop = 30405
        mmWidth = 76994
        BandType = 1
        LayerName = Foreground8
      end
      object ppRichText71: TppRichText
        DesignLayer = ppDesignLayer35
        UserName = 'RichText2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText2'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generat' +
          'or Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbt' +
          'ext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0' +
          '\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <db' +
          'text datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\par'#13#10'<dbtext data' +
          'pipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>bairro</' +
          'dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <' +
          'dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtext> <dbtext datapi' +
          'peline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>ie</dbtext>\par'#13#10#13#10'\pard\b\f2\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 24380
        mmLeft = 2381
        mmTop = 794
        mmWidth = 65591
        BandType = 1
        LayerName = Foreground8
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand29: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand34: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3175
      mmPrintPosition = 0
      object ppRichText72: TppRichText
        DesignLayer = ppDesignLayer35
        UserName = 'RichText8'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText8'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\*\generator Riched20 1' +
          '0.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs14 [<dbtext>tipo</dbtext' +
          '>] - <dbtext>descricao</dbtext>\par'#13#10'\f1\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3473
        mmLeft = 2506
        mmTop = 0
        mmWidth = 65780
        BandType = 4
        LayerName = Foreground8
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand31: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand34: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4233
      mmPrintPosition = 0
      object ppSubReport12: TppSubReport
        DesignLayer = ppDesignLayer35
        UserName = 'SubReport11'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppDados'
        mmHeight = 5027
        mmLeft = 0
        mmTop = -794
        mmWidth = 75220
        BandType = 7
        LayerName = Foreground8
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport12: TppChildReport
          AutoStop = False
          DataPipeline = ppDados
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '80mm'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 2540
          PrinterSetup.mmMarginLeft = 2540
          PrinterSetup.mmMarginRight = 2540
          PrinterSetup.mmMarginTop = 2540
          PrinterSetup.mmPaperHeight = 4003900
          PrinterSetup.mmPaperWidth = 80300
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppDados'
          object ppTitleBand32: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 49742
            mmPrintPosition = 0
            object pp2DBarCode3: Tpp2DBarCode
              DesignLayer = ppDesignLayer34
              UserName = 'TwoDBarCode1'
              AlignBarcode = ahLeft
              AutoScale = True
              AutoSize = False
              Border.mmPadding = 0
              Color = clBlack
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = []
              ReprintOnOverFlow = True
              Transparent = True
              BarCodeType = bcQRCode
              Data = 'https://confirmacao-entrega-propria.ifood.com.br/'
              PrintHumanReadable = False
              MaxiCodeSettings.CarrierPostalCode = '000000000'
              MaxiCodeSettings.HorPixelsPerMM = 4.000000000000000000
              MaxiCodeSettings.VerPixelsPerMM = 4.000000000000000000
              MaxiCodeSettings.mmBarHeight = 1059
              MaxiCodeSettings.mmBarWidth = 1059
              MaxiCodeSettings.mmQuietZone = 2118
              PDF417Settings.RelativeBarHeight = True
              PDF417Settings.mmBarHeight = 2118
              PDF417Settings.mmBarWidth = 530
              PDF417Settings.mmQuietZone = 2118
              QRCodeSettings.IncludeBOM = True
              QRCodeSettings.mmModuleSize = 1059
              QRCodeSettings.mmQuietZone = 1059
              QRCodeSettings.ECICode = -1
              DataMatrixSettings.mmModuleSize = 1059
              DataMatrixSettings.mmQuietZone = 1059
              AztecCodeSettings.mmModuleSize = 1600
              mmHeight = 16423
              mmLeft = 2381
              mmTop = 15142
              mmWidth = 17443
              BandType = 1
              LayerName = BandLayer38
            end
            object ppRichText81: TppRichText
              DesignLayer = ppDesignLayer34
              UserName = 'RichText66'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText66'
              ExportRTFAsBitmap = False
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\colortbl ;\red0\gr' +
                'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
                #10'\pard\cf1\f0\fs16 Ap\f1\'#39'f3s a confirma\'#39'e7\'#39'e3o de chegada, vo' +
                'c\'#39'ea vai precisar do c\'#39'f3digo localizador do pedido que est\'#39'e' +
                '1 na comanda e do c\'#39'f3digo de seguran\'#39'e7a do cliente.\par'#13#10'\b ' +
                'Escanei o QRCode:\b0\f0\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 14383
              mmLeft = 2346
              mmTop = 529
              mmWidth = 66917
              BandType = 1
              LayerName = BandLayer38
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppRichText82: TppRichText
              DesignLayer = ppDesignLayer34
              UserName = 'RichText67'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText67'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*' +
                '\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f' +
                's18 iFood\b0\fs20\par'#13#10'\b\fs16 <dbtext datapipeline='#39'ppDados'#39' di' +
                'splayformat='#39'!9999-9999;0; '#39'>ifoodlocalizador</dbtext> (<dbtext ' +
                'datapipeline='#39'ppDados'#39'>ifoodpedido</dbtext>)\fs20\par'#13#10#13#10'\pard\f' +
                's16 Telefone\b0 : <dbtext datapipeline='#39'ppDados'#39'>ifoodphone</dbt' +
                'ext>\fs20\par'#13#10'\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 23548
              mmLeft = 2381
              mmTop = 32015
              mmWidth = 66611
              BandType = 1
              LayerName = BandLayer38
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppDetailBand35: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand35: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 77258
            mmPrintPosition = 0
            object ppLabel35: TppLabel
              DesignLayer = ppDesignLayer34
              UserName = 'Label3'
              Border.mmPadding = 0
              Caption = 'Total Dos Itens'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 5027
              mmWidth = 17992
              BandType = 7
              LayerName = BandLayer38
            end
            object ppRichText83: TppRichText
              DesignLayer = ppDesignLayer34
              UserName = 'RichText201'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText201'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
                'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
                'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 TOTAL\f1\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5292
              mmLeft = 1588
              mmTop = -265
              mmWidth = 67019
              BandType = 7
              LayerName = BandLayer38
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppDBText50: TppDBText
              DesignLayer = ppDesignLayer34
              UserName = 'DBText1'
              Border.mmPadding = 0
              DataField = 'vl_pedido'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 5027
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer38
            end
            object ppLabel101: TppLabel
              DesignLayer = ppDesignLayer34
              UserName = 'Label4'
              Border.mmPadding = 0
              Caption = 'Taxa de Entrega'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 8731
              mmWidth = 19050
              BandType = 7
              LayerName = BandLayer38
            end
            object ppDBText51: TppDBText
              DesignLayer = ppDesignLayer34
              UserName = 'DBText2'
              Border.mmPadding = 0
              DataField = 'vl_taxa'
              DataPipeline = ppDados
              DisplayFormat = '+$#,0.00;-+$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 8731
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer38
            end
            object ppLabel102: TppLabel
              DesignLayer = ppDesignLayer34
              UserName = 'Label5'
              Border.mmPadding = 0
              Caption = 'Valor Desconto'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2910
              mmLeft = 2381
              mmTop = 12171
              mmWidth = 18521
              BandType = 7
              LayerName = BandLayer38
            end
            object ppDBText52: TppDBText
              DesignLayer = ppDesignLayer34
              UserName = 'DBText3'
              Border.mmPadding = 0
              DataField = 'vl_desconto'
              DataPipeline = ppDados
              DisplayFormat = '-$#,0.00;--$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 12435
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer38
            end
            object ppLabel103: TppLabel
              DesignLayer = ppDesignLayer34
              UserName = 'Label6'
              Border.mmPadding = 0
              Caption = 'Valor Total'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4234
              mmLeft = 2381
              mmTop = 15610
              mmWidth = 18521
              BandType = 7
              LayerName = BandLayer38
            end
            object ppDBText53: TppDBText
              DesignLayer = ppDesignLayer34
              UserName = 'DBText4'
              Border.mmPadding = 0
              DataField = 'vl_total'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 5556
              mmLeft = 30427
              mmTop = 15610
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer38
            end
            object ppRichText84: TppRichText
              DesignLayer = ppDesignLayer34
              UserName = 'RichText1'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 9
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText1'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\colortbl ;\red0\gr' +
                'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
                #10'\pard\qc\cf1\b\fs18 Forma de Pagamento\f1\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5027
              mmLeft = 2381
              mmTop = 21431
              mmWidth = 66815
              BandType = 7
              LayerName = BandLayer38
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppDBText54: TppDBText
              DesignLayer = ppDesignLayer34
              UserName = 'labelTroco2'
              Border.mmPadding = 0
              DataField = 'troco'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 26458
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer38
            end
            object ppLabel104: TppLabel
              DesignLayer = ppDesignLayer34
              UserName = 'labelTroco1'
              Border.mmPadding = 0
              Caption = 'Troco'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 26458
              mmWidth = 6879
              BandType = 7
              LayerName = BandLayer38
            end
            object ppLine1: TppLine
              DesignLayer = ppDesignLayer34
              UserName = 'Line1'
              Border.mmPadding = 0
              Pen.Style = psDot
              Weight = 0.750000000000000000
              mmHeight = 2117
              mmLeft = -1323
              mmTop = 74348
              mmWidth = 85196
              BandType = 7
              LayerName = BandLayer38
            end
            object ppSystemVariable9: TppSystemVariable
              DesignLayer = ppDesignLayer34
              UserName = 'SystemVariable7'
              Border.mmPadding = 0
              VarType = vtDateTime
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 2646
              mmTop = 59531
              mmWidth = 26194
              BandType = 7
              LayerName = BandLayer38
            end
            object ppSystemVariable31: TppSystemVariable
              DesignLayer = ppDesignLayer34
              UserName = 'SystemVariable13'
              Border.mmPadding = 0
              VarType = vtDocumentName
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 2646
              mmTop = 55298
              mmWidth = 8996
              BandType = 7
              LayerName = BandLayer38
            end
            object ppRichText116: TppRichText
              DesignLayer = ppDesignLayer34
              UserName = 'RichText4'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText4'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 <dbtex' +
                't>tipo_pagamento</dbtext>\par'#13#10'\par'#13#10'<dbtext>mp</dbtext>\par'#13#10'<d' +
                'btext>desc_desconto</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 23283
              mmLeft = 2646
              mmTop = 30956
              mmWidth = 66305
              BandType = 7
              LayerName = BandLayer38
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppLabel105: TppLabel
              DesignLayer = ppDesignLayer34
              UserName = 'Label39'
              Border.mmPadding = 0
              Caption = 'goopedir.com.br'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              TextAlignment = taCentered
              Transparent = True
              mmHeight = 3704
              mmLeft = 22754
              mmTop = 69586
              mmWidth = 24342
              BandType = 7
              LayerName = BandLayer38
            end
            object ppRichText117: TppRichText
              DesignLayer = ppDesignLayer34
              UserName = 'RichText68'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Arial'
              Font.Size = 12
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText68'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
                '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\b\fs20 <dbtext>bairro</d' +
                'btext>\par'#13#10#13#10'\pard\b0\f1\fs24\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 3440
              mmLeft = 2346
              mmTop = 65088
              mmWidth = 70896
              BandType = 7
              LayerName = BandLayer38
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppDesignLayers34: TppDesignLayers
            object ppDesignLayer34: TppDesignLayer
              UserName = 'BandLayer38'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppGroup11: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand11: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 3175
        mmPrintPosition = 0
        object ppRichText118: TppRichText
          DesignLayer = ppDesignLayer35
          UserName = 'RichText7'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText7'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
            '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\fs14 <dbtext>tipo_produto' +
            '_nome</dbtext> - <dbtext>nome_produto</dbtext>\par'#13#10'\b0\f1\fs24\' +
            'par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3351
          mmLeft = 2506
          mmTop = 0
          mmWidth = 65774
          BandType = 3
          GroupNo = 0
          LayerName = Foreground8
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand11: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 3969
        mmPrintPosition = 0
        object ppLine2: TppLine
          DesignLayer = ppDesignLayer35
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 753
          mmLeft = -3969
          mmTop = 3420
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = Foreground8
        end
        object ppRichText119: TppRichText
          DesignLayer = ppDesignLayer35
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched2' +
            '0 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs16 <dbtext>qtd</dbtex' +
            't>\f1 Un X <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_unitario</d' +
            'btext> = \cf1\f0 <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>\f1 tota' +
            'l\f0 </dbtext>\par'#13#10'\cf0\b0\f2\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3310
          mmLeft = 2506
          mmTop = -75
          mmWidth = 65855
          BandType = 5
          GroupNo = 0
          LayerName = Foreground8
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers35: TppDesignLayers
      object ppDesignLayer35: TppDesignLayer
        UserName = 'Foreground8'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList23: TppParameterList
      object ppParameter22: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object CONFERENCIA80MM: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Printer Paper(80(72) x 3276mm)'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 3275900
    PrinterSetup.mmPaperWidth = 71900
    PrinterSetup.PaperSize = 210
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 66
    Top = 96
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppDados'
    object ppTitleBand33: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 44186
      mmPrintPosition = 0
      object ppRichText122: TppRichText
        DesignLayer = ppDesignLayer36
        UserName = 'RichText17'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText17'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}{\f3\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blu' +
          'e0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\q' +
          'c\cf1\b\fs18 <dbtext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1' +
          '\fs26\par'#13#10'\b0\f0\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>' +
          'cnpj</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\' +
          'par'#13#10'<dbtext datapipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext da' +
          'tapipeline='#39'ppCabecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>bairro</dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>ci' +
          'dade</dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtex' +
          't> <dbtext datapipeline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext d' +
          'atapipeline='#39'ppCabecalho'#39'>ie</dbtext>\par'#13#10#13#10'\pard\b\f2\fs20\par' +
          #13#10#13#10'\pard\qc\b0\f3 * * * <dbtext>desc_ficha</dbtext> * * *\par'#13#10 +
          '<dbtext>origem_1</dbtext>\par'#13#10'\par'#13#10#13#10'\pard Data: <dbtext>data_' +
          'pedido</dbtext> <dbtext>hora_pedido</dbtext>\par'#13#10'\b\f2\par'#13#10'}'#13#10 +
          #0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 43353
        mmLeft = 265
        mmTop = 794
        mmWidth = 69041
        BandType = 1
        LayerName = BandLayer39
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand30: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 5821
      mmPrintPosition = 0
      object ppLine5: TppLine
        DesignLayer = ppDesignLayer36
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1323
        mmLeft = -6009
        mmTop = 4492
        mmWidth = 85504
        BandType = 0
        LayerName = BandLayer39
      end
      object ppRichText123: TppRichText
        DesignLayer = ppDesignLayer36
        UserName = 'RichText6'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText6'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs16 PRO' +
          'DUTOS\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3395
        mmLeft = 265
        mmTop = 505
        mmWidth = 66785
        BandType = 0
        LayerName = BandLayer39
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDetailBand36: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3969
      mmPrintPosition = 0
      object ppRichText124: TppRichText
        DesignLayer = ppDesignLayer36
        UserName = 'RichText8'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText8'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}{\f2\fnil\fcharset0 Cou' +
          'rier New;}{\f3\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.' +
          '19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs14 [<dbtext>tipo</dbtext>] -' +
          ' <dbtext>descricao</dbtext>\f1  \f2\fs12 (\f0 <dbtext displayfor' +
          'mat='#39'#,0.00;-#,0.00'#39'>\f1 valor\f0 </dbtext>\f2 )\f3\fs20\par'#13#10'}'#13 +
          #10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3617
        mmLeft = 1588
        mmTop = 0
        mmWidth = 65515
        BandType = 4
        LayerName = BandLayer39
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand32: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand36: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      mmBottomOffset = 0
      mmHeight = 37306
      mmPrintPosition = 0
      object ppRichText125: TppRichText
        DesignLayer = ppDesignLayer36
        UserName = 'RichText20'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 9
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText20'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs18 TOT' +
          'AL\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5292
        mmLeft = 265
        mmTop = -265
        mmWidth = 73356
        BandType = 7
        LayerName = BandLayer39
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText55: TppDBText
        DesignLayer = ppDesignLayer36
        UserName = 'DBText28'
        Border.mmPadding = 0
        DataField = 'servico'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 4230
        mmLeft = 20104
        mmTop = 5321
        mmWidth = 46880
        BandType = 7
        LayerName = BandLayer39
      end
      object ppLine7: TppLine
        DesignLayer = ppDesignLayer36
        UserName = 'Line16'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = 265
        mmTop = 35047
        mmWidth = 85196
        BandType = 7
        LayerName = BandLayer39
      end
      object ppSystemVariable46: TppSystemVariable
        DesignLayer = ppDesignLayer36
        UserName = 'SystemVariable2'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 26458
        mmWidth = 30427
        BandType = 7
        LayerName = BandLayer39
      end
      object ppSystemVariable47: TppSystemVariable
        DesignLayer = ppDesignLayer36
        UserName = 'SystemVariable19'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 22225
        mmWidth = 8996
        BandType = 7
        LayerName = BandLayer39
      end
      object ppLabel107: TppLabel
        DesignLayer = ppDesignLayer36
        UserName = 'Label67'
        HyperlinkColor = clBlack
        Border.mmPadding = 0
        Caption = 'www.goopedir.com.br'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 3704
        mmLeft = 23813
        mmTop = 30427
        mmWidth = 33073
        BandType = 7
        LayerName = BandLayer39
      end
      object ppLabel120: TppLabel
        DesignLayer = ppDesignLayer36
        UserName = 'Label120'
        Border.mmPadding = 0
        Caption = 'Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 10054
        mmWidth = 8467
        BandType = 7
        LayerName = BandLayer39
      end
      object ppDBText68: TppDBText
        DesignLayer = ppDesignLayer36
        UserName = 'DBText68'
        Border.mmPadding = 0
        DataField = 'vl_total'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 4233
        mmLeft = 10054
        mmTop = 10378
        mmWidth = 56964
        BandType = 7
        LayerName = BandLayer39
      end
      object ppRichText142: TppRichText
        DesignLayer = ppDesignLayer36
        UserName = 'RichText142'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText142'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\colortbl ;\red0\gr' +
          'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
          #10'\pard\cf1\b\fs20 Servi\'#39'e7o (\cf0\f1 <dbtext displayformat='#39'#,0' +
          '.00;-#,0.00'#39'>\f0 servico_percentual\f1 </dbtext>\f0 %\cf1 )\f1\p' +
          'ar'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5292
        mmLeft = 1862
        mmTop = 5292
        mmWidth = 39688
        BandType = 7
        LayerName = BandLayer39
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppGroup13: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand13: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 2910
        mmPrintPosition = 0
        object ppRichText126: TppRichText
          DesignLayer = ppDesignLayer36
          UserName = 'RichText7'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText7'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
            '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\fs16 <dbtext>nome_produto' +
            '</dbtext>\par'#13#10'\b0\f1\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3225
          mmLeft = 1588
          mmTop = -529
          mmWidth = 72081
          BandType = 3
          GroupNo = 0
          LayerName = BandLayer39
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand13: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 4763
        mmPrintPosition = 0
        object ppLine17: TppLine
          DesignLayer = ppDesignLayer36
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 1323
          mmLeft = -3969
          mmTop = 3426
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer39
        end
        object ppRichText127: TppRichText
          DesignLayer = ppDesignLayer36
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          KeepTogether = True
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\generator Riched' +
            '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs14 <dbtext>qtd</dbte' +
            'xt>Un \f1 -\f0  <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>\f1 total' +
            '\f0 </dbtext>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3169
          mmLeft = 1588
          mmTop = 231
          mmWidth = 65515
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer39
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers36: TppDesignLayers
      object ppDesignLayer36: TppDesignLayer
        UserName = 'BandLayer39'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList24: TppParameterList
      object ppParameter23: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object COMANDA80MM2: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 2540
    PrinterSetup.mmMarginLeft = 2540
    PrinterSetup.mmMarginRight = 2540
    PrinterSetup.mmMarginTop = 2540
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    PreviewFormSettings.PageSeparation = 1
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 1088
    Top = 80
    Version = '21.02'
    mmColumnWidth = 75220
    DataPipelineName = 'ppDados'
    object ppTitleBand34: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 39688
      mmPrintPosition = 0
      object ppRichText120: TppRichText
        DesignLayer = ppDesignLayer38
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs22 <db' +
          'text displayformat='#39'000000'#39'>codigo_comanda</dbtext>\b0\fs20\par'#13 +
          #10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3905
        mmLeft = 2346
        mmTop = 25929
        mmWidth = 65387
        BandType = 1
        LayerName = Foreground9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText121: TppRichText
        DesignLayer = ppDesignLayer38
        UserName = 'RichText3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText3'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}{\f2\fnil\fcharset0 Arial;}' +
          '{\f3\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blu' +
          'e0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\q' +
          'c\cf1\f0\fs16 <dbtext>origem_1</dbtext>\b\f1\par'#13#10'\par'#13#10#13#10'\pard\' +
          'f2 Data Pedido: <dbtext>data_pedido</dbtext> <dbtext>hora_pedido' +
          '</dbtext>\f3\par'#13#10'\f2 Cliente: <dbtext>nome</dbtext>\par'#13#10'Celula' +
          'r: <dbtext>celular</dbtext>\par'#13#10'<dbtext>qtd_pedidos_cliente</db' +
          'text>\par'#13#10'<dbtext>endereco_completo</dbtext>\par'#13#10'\f3\fs20\par'#13 +
          #10#13#10'\pard\qc\ul\f2\fs18 <dbtext>pedido_site</dbtext>\par'#13#10'\par'#13#10'\' +
          'ulnone\fs16 Itens Do Pedido\f0\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 2381
        mmTop = 34616
        mmWidth = 65352
        BandType = 1
        LayerName = Foreground9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText56: TppDBText
        DesignLayer = ppDesignLayer38
        UserName = 'DBText1'
        Border.mmPadding = 0
        Color = clBlack
        DataField = 'tipo_pedido'
        DataPipeline = ppDados
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 0
        mmTop = 30405
        mmWidth = 76994
        BandType = 1
        LayerName = Foreground9
      end
      object ppRichText128: TppRichText
        DesignLayer = ppDesignLayer38
        UserName = 'RichText2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText2'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generat' +
          'or Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbt' +
          'ext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0' +
          '\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <db' +
          'text datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\par'#13#10'<dbtext data' +
          'pipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>bairro</' +
          'dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <' +
          'dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtext> <dbtext datapi' +
          'peline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>ie</dbtext>\par'#13#10#13#10'\pard\b\f2\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 24380
        mmLeft = 2381
        mmTop = 794
        mmWidth = 65591
        BandType = 1
        LayerName = Foreground9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand31: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand37: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3175
      mmPrintPosition = 0
      object ppRichText129: TppRichText
        DesignLayer = ppDesignLayer38
        UserName = 'RichText8'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText8'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\*\generator Riched20 1' +
          '0.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs14 [<dbtext>tipo</dbtext' +
          '>] - <dbtext>descricao</dbtext>\par'#13#10'\f1\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3473
        mmLeft = 2506
        mmTop = 0
        mmWidth = 65780
        BandType = 4
        LayerName = Foreground9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand33: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand37: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4233
      mmPrintPosition = 0
      object ppSubReport13: TppSubReport
        DesignLayer = ppDesignLayer38
        UserName = 'SubReport11'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        TraverseAllData = False
        DataPipelineName = 'ppDados'
        mmHeight = 5027
        mmLeft = 0
        mmTop = -794
        mmWidth = 75220
        BandType = 7
        LayerName = Foreground9
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport13: TppChildReport
          AutoStop = False
          DataPipeline = ppDados
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '80mm'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 2540
          PrinterSetup.mmMarginLeft = 2540
          PrinterSetup.mmMarginRight = 2540
          PrinterSetup.mmMarginTop = 2540
          PrinterSetup.mmPaperHeight = 4003900
          PrinterSetup.mmPaperWidth = 80300
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppDados'
          object ppTitleBand35: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 49742
            mmPrintPosition = 0
            object pp2DBarCode4: Tpp2DBarCode
              DesignLayer = ppDesignLayer37
              UserName = 'TwoDBarCode1'
              AlignBarcode = ahLeft
              AutoScale = True
              AutoSize = False
              Border.mmPadding = 0
              Color = clBlack
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = []
              ReprintOnOverFlow = True
              Transparent = True
              BarCodeType = bcQRCode
              Data = 'https://confirmacao-entrega-propria.ifood.com.br/'
              PrintHumanReadable = False
              MaxiCodeSettings.CarrierPostalCode = '000000000'
              MaxiCodeSettings.HorPixelsPerMM = 4.000000000000000000
              MaxiCodeSettings.VerPixelsPerMM = 4.000000000000000000
              MaxiCodeSettings.mmBarHeight = 1059
              MaxiCodeSettings.mmBarWidth = 1059
              MaxiCodeSettings.mmQuietZone = 2118
              PDF417Settings.RelativeBarHeight = True
              PDF417Settings.mmBarHeight = 2118
              PDF417Settings.mmBarWidth = 530
              PDF417Settings.mmQuietZone = 2118
              QRCodeSettings.IncludeBOM = True
              QRCodeSettings.mmModuleSize = 1059
              QRCodeSettings.mmQuietZone = 1059
              QRCodeSettings.ECICode = -1
              DataMatrixSettings.mmModuleSize = 1059
              DataMatrixSettings.mmQuietZone = 1059
              AztecCodeSettings.mmModuleSize = 1600
              mmHeight = 16423
              mmLeft = 2381
              mmTop = 15142
              mmWidth = 17443
              BandType = 1
              LayerName = BandLayer40
            end
            object ppRichText130: TppRichText
              DesignLayer = ppDesignLayer37
              UserName = 'RichText66'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText66'
              ExportRTFAsBitmap = False
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\colortbl ;\red0\gr' +
                'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
                #10'\pard\cf1\f0\fs16 Ap\f1\'#39'f3s a confirma\'#39'e7\'#39'e3o de chegada, vo' +
                'c\'#39'ea vai precisar do c\'#39'f3digo localizador do pedido que est\'#39'e' +
                '1 na comanda e do c\'#39'f3digo de seguran\'#39'e7a do cliente.\par'#13#10'\b ' +
                'Escanei o QRCode:\b0\f0\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 14383
              mmLeft = 2346
              mmTop = 529
              mmWidth = 66917
              BandType = 1
              LayerName = BandLayer40
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppRichText131: TppRichText
              DesignLayer = ppDesignLayer37
              UserName = 'RichText67'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText67'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*' +
                '\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f' +
                's18 iFood\b0\fs20\par'#13#10'\b\fs16 <dbtext datapipeline='#39'ppDados'#39' di' +
                'splayformat='#39'!9999-9999;0; '#39'>ifoodlocalizador</dbtext> (<dbtext ' +
                'datapipeline='#39'ppDados'#39'>ifoodpedido</dbtext>)\fs20\par'#13#10#13#10'\pard\f' +
                's16 Telefone\b0 : <dbtext datapipeline='#39'ppDados'#39'>ifoodphone</dbt' +
                'ext>\fs20\par'#13#10'\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 23548
              mmLeft = 2381
              mmTop = 32015
              mmWidth = 66611
              BandType = 1
              LayerName = BandLayer40
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppDetailBand38: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand38: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 77258
            mmPrintPosition = 0
            object ppLabel108: TppLabel
              DesignLayer = ppDesignLayer37
              UserName = 'Label3'
              Border.mmPadding = 0
              Caption = 'Total Dos Itens'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 5027
              mmWidth = 17992
              BandType = 7
              LayerName = BandLayer40
            end
            object ppRichText132: TppRichText
              DesignLayer = ppDesignLayer37
              UserName = 'RichText201'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Courier New'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText201'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
                'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
                'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 TOTAL\f1\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5292
              mmLeft = 1588
              mmTop = -265
              mmWidth = 67019
              BandType = 7
              LayerName = BandLayer40
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppDBText57: TppDBText
              DesignLayer = ppDesignLayer37
              UserName = 'DBText1'
              Border.mmPadding = 0
              DataField = 'vl_pedido'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 5027
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer40
            end
            object ppLabel109: TppLabel
              DesignLayer = ppDesignLayer37
              UserName = 'Label4'
              Border.mmPadding = 0
              Caption = 'Taxa de Entrega'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 8731
              mmWidth = 19050
              BandType = 7
              LayerName = BandLayer40
            end
            object ppDBText58: TppDBText
              DesignLayer = ppDesignLayer37
              UserName = 'DBText2'
              Border.mmPadding = 0
              DataField = 'vl_taxa'
              DataPipeline = ppDados
              DisplayFormat = '+$#,0.00;-+$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 8731
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer40
            end
            object ppLabel110: TppLabel
              DesignLayer = ppDesignLayer37
              UserName = 'Label5'
              Border.mmPadding = 0
              Caption = 'Valor Desconto'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2910
              mmLeft = 2381
              mmTop = 12171
              mmWidth = 18521
              BandType = 7
              LayerName = BandLayer40
            end
            object ppDBText59: TppDBText
              DesignLayer = ppDesignLayer37
              UserName = 'DBText3'
              Border.mmPadding = 0
              DataField = 'vl_desconto'
              DataPipeline = ppDados
              DisplayFormat = '-$#,0.00;--$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 12435
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer40
            end
            object ppLabel111: TppLabel
              DesignLayer = ppDesignLayer37
              UserName = 'Label6'
              Border.mmPadding = 0
              Caption = 'Valor Total'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4234
              mmLeft = 2381
              mmTop = 15610
              mmWidth = 18521
              BandType = 7
              LayerName = BandLayer40
            end
            object ppDBText60: TppDBText
              DesignLayer = ppDesignLayer37
              UserName = 'DBText4'
              Border.mmPadding = 0
              DataField = 'vl_total'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 5556
              mmLeft = 30427
              mmTop = 15610
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer40
            end
            object ppRichText133: TppRichText
              DesignLayer = ppDesignLayer37
              UserName = 'RichText1'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 9
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText1'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\colortbl ;\red0\gr' +
                'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
                #10'\pard\qc\cf1\b\fs18 Forma de Pagamento\f1\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5027
              mmLeft = 2381
              mmTop = 21431
              mmWidth = 66815
              BandType = 7
              LayerName = BandLayer40
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppDBText61: TppDBText
              DesignLayer = ppDesignLayer37
              UserName = 'labelTroco2'
              Border.mmPadding = 0
              DataField = 'troco'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              TextAlignment = taRightJustified
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 30427
              mmTop = 26458
              mmWidth = 38457
              BandType = 7
              LayerName = BandLayer40
            end
            object ppLabel112: TppLabel
              DesignLayer = ppDesignLayer37
              UserName = 'labelTroco1'
              Border.mmPadding = 0
              Caption = 'Troco'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2911
              mmLeft = 2381
              mmTop = 26458
              mmWidth = 6879
              BandType = 7
              LayerName = BandLayer40
            end
            object ppLine27: TppLine
              DesignLayer = ppDesignLayer37
              UserName = 'Line1'
              Border.mmPadding = 0
              Pen.Style = psDot
              Weight = 0.750000000000000000
              mmHeight = 2117
              mmLeft = -1323
              mmTop = 74348
              mmWidth = 85196
              BandType = 7
              LayerName = BandLayer40
            end
            object ppSystemVariable48: TppSystemVariable
              DesignLayer = ppDesignLayer37
              UserName = 'SystemVariable7'
              Border.mmPadding = 0
              VarType = vtDateTime
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 2646
              mmTop = 59531
              mmWidth = 26194
              BandType = 7
              LayerName = BandLayer40
            end
            object ppSystemVariable49: TppSystemVariable
              DesignLayer = ppDesignLayer37
              UserName = 'SystemVariable13'
              Border.mmPadding = 0
              VarType = vtDocumentName
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 2646
              mmTop = 55298
              mmWidth = 8996
              BandType = 7
              LayerName = BandLayer40
            end
            object ppRichText134: TppRichText
              DesignLayer = ppDesignLayer37
              UserName = 'RichText4'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText4'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 <dbtex' +
                't>tipo_pagamento</dbtext>\par'#13#10'\par'#13#10'<dbtext>mp</dbtext>\par'#13#10'<d' +
                'btext>desc_desconto</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 23283
              mmLeft = 2646
              mmTop = 30956
              mmWidth = 66305
              BandType = 7
              LayerName = BandLayer40
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppLabel113: TppLabel
              DesignLayer = ppDesignLayer37
              UserName = 'Label39'
              Border.mmPadding = 0
              Caption = 'goopedir.com.br'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              TextAlignment = taCentered
              Transparent = True
              mmHeight = 3704
              mmLeft = 22754
              mmTop = 69586
              mmWidth = 24342
              BandType = 7
              LayerName = BandLayer40
            end
            object ppRichText135: TppRichText
              DesignLayer = ppDesignLayer37
              UserName = 'RichText68'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Arial'
              Font.Size = 12
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText68'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
                '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\b\fs20 <dbtext>bairro</d' +
                'btext>\par'#13#10#13#10'\pard\b0\f1\fs24\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 3440
              mmLeft = 2346
              mmTop = 65088
              mmWidth = 70896
              BandType = 7
              LayerName = BandLayer40
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppDesignLayers37: TppDesignLayers
            object ppDesignLayer37: TppDesignLayer
              UserName = 'BandLayer40'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppGroup14: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand14: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 3175
        mmPrintPosition = 0
        object ppRichText136: TppRichText
          DesignLayer = ppDesignLayer38
          UserName = 'RichText7'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText7'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
            '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\fs14 <dbtext>tipo_produto' +
            '_nome</dbtext> - <dbtext>nome_produto</dbtext>\par'#13#10'\b0\f1\fs24\' +
            'par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3351
          mmLeft = 2506
          mmTop = 0
          mmWidth = 65774
          BandType = 3
          GroupNo = 0
          LayerName = Foreground9
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand14: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 3969
        mmPrintPosition = 0
        object ppLine30: TppLine
          DesignLayer = ppDesignLayer38
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 753
          mmLeft = -3969
          mmTop = 3420
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = Foreground9
        end
        object ppRichText137: TppRichText
          DesignLayer = ppDesignLayer38
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched2' +
            '0 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs16 <dbtext>qtd</dbtex' +
            't>\f1 Un X <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_unitario</d' +
            'btext> = \cf1\f0 <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>\f1 tota' +
            'l\f0 </dbtext>\par'#13#10'\cf0\b0\f2\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3310
          mmLeft = 2506
          mmTop = -75
          mmWidth = 65855
          BandType = 5
          GroupNo = 0
          LayerName = Foreground9
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers38: TppDesignLayers
      object ppDesignLayer38: TppDesignLayer
        UserName = 'Foreground9'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList25: TppParameterList
      object ppParameter24: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object iNFCE: iRequisicao
    BaseURL = 
      'https://nfce.goopedir.com/nfce/41942832000104/082024/42240841942' +
      '832000104650010000114461455979555-nfe.xml'
    eTAG = False
    Metodo = mGet
    Status = 0
    MostrarAguarde = False
    TempoExpiracao = 2000
    Left = 1104
    Top = 176
  end
  object ACBrValidador1: TACBrValidador
    TipoDocto = docGTIN
    IgnorarChar = './-'
    Left = 1192
    Top = 226
  end
  object COMANDA56MM: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '56mm'
    PrinterSetup.PaperName = 'Custom'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 2540
    PrinterSetup.mmMarginLeft = 2540
    PrinterSetup.mmMarginRight = 2540
    PrinterSetup.mmMarginTop = 2540
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 256
    PrinterSetup.DevMode = {
      4004000044006100720075006D00610020004400520000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000001040306DC0064034FEF8005010000013A6202036400010001016400
      0100010064000200010043007500730074006F006D0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000100000000000000
      010000000200000001000000FFFFFFFF00000000000000000000000000000000
      44494E552200080164030000B8225C4F00000000000000000000000000000000
      0000000000000000000000000800000001000000000001000000050001000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000001000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000008010000
      534D544A000000001000F80044006100720075006D0061002000440052003700
      300030002000530070006F006F006C00650072000000496E70757442696E004F
      50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
      74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
      4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
      53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
      6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
      616F000000000000000000000000000000000000000000000000000000000000
      00000000}
    ArchiveFileName = '($MyDocuments)\ReportArchive.raf'
    DeviceType = 'Printer'
    DefaultFileDeviceType = 'PDF'
    EmailSettings.ReportFormat = 'PDF'
    EmailSettings.ConnectionSettings.MailService = 'SMTP'
    EmailSettings.ConnectionSettings.WebMail.GmailSettings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.WebMail.Outlook365Settings.OAuth2.RedirectPort = 0
    EmailSettings.ConnectionSettings.EnableMultiPlugin = False
    LanguageID = 'Default'
    OpenFile = False
    OutlineSettings.CreateNode = True
    OutlineSettings.CreatePageNodes = True
    OutlineSettings.Enabled = True
    OutlineSettings.Visible = True
    ThumbnailSettings.Enabled = True
    ThumbnailSettings.Visible = True
    ThumbnailSettings.DeadSpace = 30
    ThumbnailSettings.PageHighlight.Width = 3
    ThumbnailSettings.ThumbnailSize = tsSmall
    PDFSettings.EmbedFontOptions = [efUseSubset]
    PDFSettings.EncryptSettings.AllowCopy = True
    PDFSettings.EncryptSettings.AllowInteract = True
    PDFSettings.EncryptSettings.AllowModify = True
    PDFSettings.EncryptSettings.AllowPrint = True
    PDFSettings.EncryptSettings.AllowExtract = True
    PDFSettings.EncryptSettings.AllowAssemble = True
    PDFSettings.EncryptSettings.AllowQualityPrint = True
    PDFSettings.EncryptSettings.Enabled = False
    PDFSettings.EncryptSettings.KeyLength = kl40Bit
    PDFSettings.EncryptSettings.EncryptionType = etRC4
    PDFSettings.DigitalSignatureSettings.SignPDF = False
    PDFSettings.FontEncoding = feAnsi
    PDFSettings.ImageCompressionLevel = 25
    PDFSettings.PDFAFormat = pafNone
    PreviewFormSettings.PageBorder.mmPadding = 0
    PreviewFormSettings.PageDisplay = pdContinuous
    PreviewFormSettings.PageSeparation = 1
    RTFSettings.DefaultFont.Charset = DEFAULT_CHARSET
    RTFSettings.DefaultFont.Color = clWindowText
    RTFSettings.DefaultFont.Height = -13
    RTFSettings.DefaultFont.Name = 'Arial'
    RTFSettings.DefaultFont.Style = []
    ShowCancelDialog = False
    ShowPrintDialog = False
    TextFileName = '($MyDocuments)\Report.pdf'
    TextSearchSettings.DefaultString = '<Texto a localizar>'
    TextSearchSettings.Enabled = True
    XLSSettings.AppName = 'ReportBuilder'
    XLSSettings.Author = 'ReportBuilder'
    XLSSettings.Subject = 'Report'
    XLSSettings.Title = 'Report'
    XLSSettings.WorksheetName = 'Report'
    CloudDriveSettings.DropBoxSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.DropBoxSettings.DirectorySupport = True
    CloudDriveSettings.GoogleDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.GoogleDriveSettings.DirectorySupport = False
    CloudDriveSettings.OneDriveSettings.OAuth2.RedirectPort = 0
    CloudDriveSettings.OneDriveSettings.DirectorySupport = True
    Left = 218
    Top = 16
    Version = '21.02'
    mmColumnWidth = 75220
    DataPipelineName = 'ppDados'
    object ppTitleBand36: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 39688
      mmPrintPosition = 0
      object ppRichText6: TppRichText
        DesignLayer = ppDesignLayer40
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Arial'
        Font.Size = 10
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
          ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs22 <db' +
          'text displayformat='#39'000000'#39'>codigo_comanda</dbtext>\b0\fs20\par'#13 +
          #10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 3905
        mmLeft = 2346
        mmTop = 25929
        mmWidth = 43053
        BandType = 1
        LayerName = Foreground10
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText139: TppRichText
        DesignLayer = ppDesignLayer40
        UserName = 'RichText3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText3'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}{\f2\fnil\fcharset0 Arial;}' +
          '{\f3\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blu' +
          'e0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\q' +
          'c\cf1\f0\fs16 <dbtext>origem_1</dbtext>\b\f1\par'#13#10'\par'#13#10#13#10'\pard\' +
          'f2 Data Pedido: <dbtext>data_pedido</dbtext> <dbtext>hora_pedido' +
          '</dbtext>\f3\par'#13#10'\f2 Cliente: <dbtext>nome</dbtext>\par'#13#10'Celula' +
          'r: <dbtext>celular</dbtext>\par'#13#10'<dbtext>qtd_pedidos_cliente</db' +
          'text>\par'#13#10'<dbtext>endereco_completo</dbtext>\par'#13#10'\f3\fs20\par'#13 +
          #10#13#10'\pard\qc\ul\f2\fs18 <dbtext>pedido_site</dbtext>\par'#13#10'\par'#13#10'\' +
          'ulnone\fs16 Itens Do Pedido\f0\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 2381
        mmTop = 34616
        mmWidth = 43053
        BandType = 1
        LayerName = Foreground10
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText62: TppDBText
        DesignLayer = ppDesignLayer40
        UserName = 'DBText1'
        Border.mmPadding = 0
        Color = clBlack
        DataField = 'tipo_pedido'
        DataPipeline = ppDados
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 0
        mmTop = 30405
        mmWidth = 49721
        BandType = 1
        LayerName = Foreground10
      end
      object ppRichText140: TppRichText
        DesignLayer = ppDesignLayer40
        UserName = 'RichText2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText2'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Arial;}{\f1\fnil\fcharset0 Courier New;}{\f2\fn' +
          'il Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generat' +
          'or Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\fs18 <dbt' +
          'ext datapipeline='#39'ppCabecalho'#39'>nome</dbtext>\f1\fs26\par'#13#10'\b0\f0' +
          '\fs16 CNPJ: <dbtext datapipeline='#39'ppCabecalho'#39'>cnpj</dbtext> <db' +
          'text datapipeline='#39'ppCabecalho'#39'>razao</dbtext>\par'#13#10'<dbtext data' +
          'pipeline='#39'ppCabecalho'#39'>rua</dbtext>, <dbtext datapipeline='#39'ppCab' +
          'ecalho'#39'>rua</dbtext> <dbtext datapipeline='#39'ppCabecalho'#39'>bairro</' +
          'dbtext> - <dbtext datapipeline='#39'ppCabecalho'#39'>cidade</dbtext> - <' +
          'dbtext datapipeline='#39'ppCabecalho'#39'>estado</dbtext> <dbtext datapi' +
          'peline='#39'ppCabecalho'#39'>cep</dbtext> IE: <dbtext datapipeline='#39'ppCa' +
          'becalho'#39'>ie</dbtext>\par'#13#10#13#10'\pard\b\f2\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 24380
        mmLeft = 2381
        mmTop = 794
        mmWidth = 43053
        BandType = 1
        LayerName = Foreground10
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppHeaderBand32: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppDetailBand39: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3175
      mmPrintPosition = 0
      object ppRichText141: TppRichText
        DesignLayer = ppDesignLayer40
        UserName = 'RichText8'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText8'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\*\generator Riched20 1' +
          '0.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs20 [<dbtext>tipo</dbtext' +
          '>] - <dbtext>descricao</dbtext>\par'#13#10'\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3473
        mmLeft = 2506
        mmTop = 0
        mmWidth = 42856
        BandType = 4
        LayerName = Foreground10
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppFooterBand34: TppFooterBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintOnFirstPage = False
      mmBottomOffset = 0
      mmHeight = 0
      mmPrintPosition = 0
    end
    object ppSummaryBand39: TppSummaryBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4233
      mmPrintPosition = 0
      object ppSubReport14: TppSubReport
        DesignLayer = ppDesignLayer40
        UserName = 'SubReport11'
        ExpandAll = False
        NewPrintJob = False
        OutlineSettings.CreateNode = True
        ParentPrinterSetup = False
        TraverseAllData = False
        DataPipelineName = 'ppDados'
        mmHeight = 5027
        mmLeft = 0
        mmTop = -794
        mmWidth = 46920
        BandType = 7
        LayerName = Foreground10
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
        object ppChildReport14: TppChildReport
          AutoStop = False
          DataPipeline = ppDados
          PrinterSetup.BinName = 'Default'
          PrinterSetup.DocumentName = '56mm'
          PrinterSetup.PaperName = 'Custom'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 2540
          PrinterSetup.mmMarginLeft = 2540
          PrinterSetup.mmMarginRight = 2540
          PrinterSetup.mmMarginTop = 2540
          PrinterSetup.mmPaperHeight = 4003900
          PrinterSetup.mmPaperWidth = 52000
          PrinterSetup.PaperSize = 256
          PrinterSetup.DevMode = {
            4004000044006100720075006D00610020004400520000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000001040306DC0064034FEF8005010000013A6202036400010001016400
            0100010064000200010043007500730074006F006D0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000100000000000000
            010000000200000001000000FFFFFFFF00000000000000000000000000000000
            44494E552200080164030000B8225C4F00000000000000000000000000000000
            0000000000000000000000000800000001000000000001000000050001000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000001000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000008010000
            534D544A000000001000F80044006100720075006D0061002000440052003700
            300030002000530070006F006F006C00650072000000496E70757442696E004F
            50424F42494E4100524553444C4C00556E69726573444C4C004F7269656E7461
            74696F6E00504F52545241495400466F726D496D7072696D697200434F4E5449
            4E5541005265736F6C7574696F6E004F7074696F6E546578746F005061706572
            53697A6500435553544F4D53495A45004465736162696C6974615465636C6164
            6F005465634E616F486162696C697461646F0048616C66746F6E650050616472
            616F000000000000000000000000000000000000000000000000000000000000
            00000000}
          Version = '21.02'
          mmColumnWidth = 0
          DataPipelineName = 'ppDados'
          object ppTitleBand37: TppTitleBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppDetailBand40: TppDetailBand
            Background1.Brush.Style = bsClear
            Background2.Brush.Style = bsClear
            Border.mmPadding = 0
            mmBottomOffset = 0
            mmHeight = 0
            mmPrintPosition = 0
          end
          object ppSummaryBand40: TppSummaryBand
            Background.Brush.Style = bsClear
            Border.mmPadding = 0
            PrintHeight = phDynamic
            mmBottomOffset = 0
            mmHeight = 90223
            mmPrintPosition = 0
            object ppLabel114: TppLabel
              DesignLayer = ppDesignLayer39
              UserName = 'Label3'
              Border.mmPadding = 0
              Caption = 'Total Dos Itens'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2910
              mmLeft = 1588
              mmTop = 5027
              mmWidth = 17992
              BandType = 7
              LayerName = BandLayer41
            end
            object ppRichText144: TppRichText
              DesignLayer = ppDesignLayer39
              UserName = 'RichText201'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText201'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 TOT' +
                'AL\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5292
              mmLeft = 1588
              mmTop = -265
              mmWidth = 43793
              BandType = 7
              LayerName = BandLayer41
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppDBText63: TppDBText
              DesignLayer = ppDesignLayer39
              UserName = 'DBText1'
              Border.mmPadding = 0
              DataField = 'vl_pedido'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 1588
              mmTop = 7845
              mmWidth = 38365
              BandType = 7
              LayerName = BandLayer41
            end
            object ppLabel115: TppLabel
              DesignLayer = ppDesignLayer39
              UserName = 'Label4'
              Border.mmPadding = 0
              Caption = 'Taxa de Entrega'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2910
              mmLeft = 1588
              mmTop = 11506
              mmWidth = 19050
              BandType = 7
              LayerName = BandLayer41
            end
            object ppDBText64: TppDBText
              DesignLayer = ppDesignLayer39
              UserName = 'DBText2'
              Border.mmPadding = 0
              DataField = 'vl_taxa'
              DataPipeline = ppDados
              DisplayFormat = '+$#,0.00;-+$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 1588
              mmTop = 14367
              mmWidth = 38365
              BandType = 7
              LayerName = BandLayer41
            end
            object ppLabel116: TppLabel
              DesignLayer = ppDesignLayer39
              UserName = 'Label5'
              Border.mmPadding = 0
              Caption = 'Valor Desconto'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2910
              mmLeft = 1588
              mmTop = 17985
              mmWidth = 18521
              BandType = 7
              LayerName = BandLayer41
            end
            object ppDBText65: TppDBText
              DesignLayer = ppDesignLayer39
              UserName = 'DBText3'
              Border.mmPadding = 0
              DataField = 'vl_desconto'
              DataPipeline = ppDados
              DisplayFormat = '-$#,0.00;--$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 1588
              mmTop = 20840
              mmWidth = 38365
              BandType = 7
              LayerName = BandLayer41
            end
            object ppLabel117: TppLabel
              DesignLayer = ppDesignLayer39
              UserName = 'Label6'
              Border.mmPadding = 0
              Caption = 'Valor Total'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 4233
              mmLeft = 1588
              mmTop = 24507
              mmWidth = 18521
              BandType = 7
              LayerName = BandLayer41
            end
            object ppDBText66: TppDBText
              DesignLayer = ppDesignLayer39
              UserName = 'DBText4'
              Border.mmPadding = 0
              DataField = 'vl_total'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 10
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 5556
              mmLeft = 1588
              mmTop = 28711
              mmWidth = 38365
              BandType = 7
              LayerName = BandLayer41
            end
            object ppRichText145: TppRichText
              DesignLayer = ppDesignLayer39
              UserName = 'RichText1'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 9
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText1'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\colortbl ;\red0\gr' +
                'een0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13 +
                #10'\pard\qc\cf1\b\fs18 Forma de Pagamento\f1\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Transparent = True
              mmHeight = 5027
              mmLeft = 1558
              mmTop = 34406
              mmWidth = 43812
              BandType = 7
              LayerName = BandLayer41
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppDBText67: TppDBText
              DesignLayer = ppDesignLayer39
              UserName = 'labelTroco2'
              Border.mmPadding = 0
              DataField = 'troco'
              DataPipeline = ppDados
              DisplayFormat = '$#,0.00;-$#,0.00'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              Transparent = True
              DataPipelineName = 'ppDados'
              mmHeight = 3704
              mmLeft = 1558
              mmTop = 42147
              mmWidth = 38365
              BandType = 7
              LayerName = BandLayer41
            end
            object ppLabel118: TppLabel
              DesignLayer = ppDesignLayer39
              UserName = 'labelTroco1'
              Border.mmPadding = 0
              Caption = 'Troco'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 7
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              Transparent = True
              mmHeight = 2910
              mmLeft = 1548
              mmTop = 39227
              mmWidth = 6879
              BandType = 7
              LayerName = BandLayer41
            end
            object ppLine33: TppLine
              DesignLayer = ppDesignLayer39
              UserName = 'Line1'
              Border.mmPadding = 0
              Pen.Style = psDot
              Weight = 0.750000000000000000
              mmHeight = 2117
              mmLeft = -1323
              mmTop = 88104
              mmWidth = 85196
              BandType = 7
              LayerName = BandLayer41
            end
            object ppSystemVariable50: TppSystemVariable
              DesignLayer = ppDesignLayer39
              UserName = 'SystemVariable7'
              Border.mmPadding = 0
              VarType = vtDateTime
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 1588
              mmTop = 73192
              mmWidth = 26194
              BandType = 7
              LayerName = BandLayer41
            end
            object ppSystemVariable51: TppSystemVariable
              DesignLayer = ppDesignLayer39
              UserName = 'SystemVariable13'
              Border.mmPadding = 0
              VarType = vtDocumentName
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Transparent = True
              mmHeight = 3704
              mmLeft = 1588
              mmTop = 69586
              mmWidth = 8996
              BandType = 7
              LayerName = BandLayer41
            end
            object ppRichText146: TppRichText
              DesignLayer = ppDesignLayer39
              UserName = 'RichText4'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText4'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator' +
                ' Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 <dbtex' +
                't>tipo_pagamento</dbtext>\par'#13#10'\par'#13#10'<dbtext>mp</dbtext>\par'#13#10'<d' +
                'btext>desc_desconto</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 23283
              mmLeft = 1588
              mmTop = 45773
              mmWidth = 20108
              BandType = 7
              LayerName = BandLayer41
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
            object ppLabel119: TppLabel
              DesignLayer = ppDesignLayer39
              UserName = 'Label39'
              Border.mmPadding = 0
              Caption = 'goopedir.com.br'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Name = 'Arial'
              Font.Size = 8
              Font.Style = [fsBold]
              FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
              FormFieldSettings.FormFieldType = fftNone
              TextAlignment = taCentered
              Transparent = True
              mmHeight = 3704
              mmLeft = 1588
              mmTop = 82550
              mmWidth = 43837
              BandType = 7
              LayerName = BandLayer41
            end
            object ppRichText147: TppRichText
              DesignLayer = ppDesignLayer39
              UserName = 'RichText68'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Arial'
              Font.Size = 12
              Font.Style = []
              Border.mmPadding = 0
              Caption = 'RichText68'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Arial;}{\f1\fnil Arial;}}'#13#10'{\*\generator Riched' +
                '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\b\fs20 <dbtext>bairro</d' +
                'btext>\par'#13#10#13#10'\pard\b0\f1\fs24\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 3440
              mmLeft = 1588
              mmTop = 76857
              mmWidth = 43847
              BandType = 7
              LayerName = BandLayer41
              mmBottomOffset = 0
              mmOverFlowOffset = 0
              mmStopPosition = 0
              mmMinHeight = 0
            end
          end
          object ppDesignLayers39: TppDesignLayers
            object ppDesignLayer39: TppDesignLayer
              UserName = 'BandLayer41'
              LayerType = ltBanded
              Index = 0
            end
          end
        end
      end
    end
    object ppGroup15: TppGroup
      BreakName = 'codigo_grupo'
      DataPipeline = ppDados
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group2'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppDados'
      NewFile = False
      object ppGroupHeaderBand15: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 4233
        mmPrintPosition = 0
        object ppRichText148: TppRichText
          DesignLayer = ppDesignLayer40
          UserName = 'RichText138'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText138'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\generator Riched' +
            '20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>qtd</dbte' +
            'xt>un <dbtext>tipo_produto_nome</dbtext> - <dbtext>nome_produto<' +
            '/dbtext>\f1\fs14\par'#13#10'\b0\f0\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 4135
          mmLeft = 2381
          mmTop = 0
          mmWidth = 43053
          BandType = 3
          GroupNo = 0
          LayerName = Foreground10
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand15: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 3969
        mmPrintPosition = 0
        object ppLine34: TppLine
          DesignLayer = ppDesignLayer40
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 753
          mmLeft = -3969
          mmTop = 3420
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = Foreground10
        end
        object ppRichText149: TppRichText
          DesignLayer = ppDesignLayer40
          UserName = 'RichText23'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Arial;}{\f1\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0' +
            '\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pa' +
            'rd\cf1\b\f0\fs16 <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>total</d' +
            'btext>\f1\par'#13#10'\cf0\b0\f0\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3310
          mmLeft = 2506
          mmTop = -75
          mmWidth = 42856
          BandType = 5
          GroupNo = 0
          LayerName = Foreground10
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
    end
    object ppDesignLayers40: TppDesignLayers
      object ppDesignLayer40: TppDesignLayer
        UserName = 'Foreground10'
        LayerType = ltBanded
        Index = 0
      end
    end
    object ppParameterList26: TppParameterList
      object ppParameter25: TppParameter
        AutoSearchSettings.LogicalPrefix = []
        AutoSearchSettings.Mandatory = True
        DataType = dtString
        LookupSettings.DisplayType = dtNameOnly
        LookupSettings.SortOrder = soName
        Value = ''
        UserName = 'Parameter1'
      end
    end
  end
  object ACBrNFe1: TACBrNFe
    Integrador = ACBrIntegrador1
    Configuracoes.Geral.SSLLib = libNone
    Configuracoes.Geral.SSLCryptLib = cryNone
    Configuracoes.Geral.SSLHttpLib = httpNone
    Configuracoes.Geral.SSLXmlSignLib = xsNone
    Configuracoes.Geral.FormaEmissao = teContingencia
    Configuracoes.Geral.FormatoAlerta = 'TAG:%TAGNIVEL% ID:%ID%/%TAG%(%DESCRICAO%) - %MSG%.'
    Configuracoes.Geral.VersaoDF = ve200
    Configuracoes.Geral.AtualizarXMLCancelado = True
    Configuracoes.Geral.VersaoQRCode = veqr000
    Configuracoes.Arquivos.OrdenacaoPath = <>
    Configuracoes.WebServices.UF = 'SP'
    Configuracoes.WebServices.AguardarConsultaRet = 15000
    Configuracoes.WebServices.AjustaAguardaConsultaRet = True
    Configuracoes.WebServices.TimeOut = 20000
    Configuracoes.WebServices.QuebradeLinha = '|'
    Configuracoes.RespTec.IdCSRT = 0
    DANFE = ACBrNFeDANFeESCPOS1
    Left = 818
    Top = 383
  end
  object ACBrMail1: TACBrMail
    Host = '127.0.0.1'
    Port = '25'
    SetSSL = False
    SetTLS = False
    Attempts = 3
    DefaultCharset = UTF_8
    IDECharset = CP1252
    Left = 1346
    Top = 295
  end
  object ACBrIntegrador1: TACBrIntegrador
    PastaInput = 'C:\Integrador\Input\'
    PastaOutput = 'C:\Integrador\Output\'
    Left = 1350
    Top = 350
  end
  object ACBrPosPrinter1: TACBrPosPrinter
    Modelo = ppEscPosEpson
    Porta = 'Defalt'
    EspacoEntreLinhas = 30
    ConfigBarras.MostrarCodigo = False
    ConfigBarras.LarguraLinha = 0
    ConfigBarras.Altura = 0
    ConfigBarras.Margem = 0
    ConfigQRCode.Tipo = 1
    ConfigQRCode.LarguraModulo = 2
    ConfigQRCode.ErrorLevel = 0
    LinhasEntreCupons = 5
    Left = 1425
    Top = 295
  end
  object ACBrNFeDANFeRL1: TACBrNFeDANFeRL
    MostraStatus = False
    Sistema = 'GooPedir'
    Usuario = 'ACBr'
    MargemInferior = 0.700000000000000000
    MargemSuperior = 0.700000000000000000
    MargemEsquerda = 0.700000000000000000
    MargemDireita = 0.700000000000000000
    ExpandeLogoMarcaConfig.Altura = 0
    ExpandeLogoMarcaConfig.Esquerda = 0
    ExpandeLogoMarcaConfig.Topo = 0
    ExpandeLogoMarcaConfig.Largura = 0
    ExpandeLogoMarcaConfig.Dimensionar = False
    ExpandeLogoMarcaConfig.Esticar = True
    CasasDecimais.Formato = tdetInteger
    CasasDecimais.qCom = 4
    CasasDecimais.vUnCom = 4
    CasasDecimais.MaskqCom = '###,###,###,##0.00'
    CasasDecimais.MaskvUnCom = '###,###,###,##0.00'
    CasasDecimais.Aliquota = 2
    CasasDecimais.MaskAliquota = ',0.00'
    ExibeTotalTributosItem = True
    ImprimeDescPorPercentual = True
    ExibeCampoFatura = False
    Left = 651
    Top = 135
  end
  object ACBrNFeDANFCeFortesA41: TACBrNFeDANFCeFortesA4
    Sistema = 'GooPedir - www.goopedir.com'
    Usuario = 'Allan'
    Site = 'www.goopedir.com'
    MargemInferior = 8.000000000000000000
    MargemSuperior = 8.000000000000000000
    MargemEsquerda = 6.000000000000000000
    MargemDireita = 5.099999999999999000
    ExpandeLogoMarcaConfig.Altura = 0
    ExpandeLogoMarcaConfig.Esquerda = 0
    ExpandeLogoMarcaConfig.Topo = 0
    ExpandeLogoMarcaConfig.Largura = 0
    ExpandeLogoMarcaConfig.Dimensionar = False
    ExpandeLogoMarcaConfig.Esticar = True
    CasasDecimais.Formato = tdetInteger
    CasasDecimais.qCom = 2
    CasasDecimais.vUnCom = 2
    CasasDecimais.MaskqCom = ',0.00'
    CasasDecimais.MaskvUnCom = ',0.00'
    CasasDecimais.Aliquota = 2
    CasasDecimais.MaskAliquota = ',0.00'
    FormularioContinuo = True
    Left = 1584
    Top = 408
  end
  object ACBrNFeDANFeESCPOS1: TACBrNFeDANFeESCPOS
    Sistema = 'GooPedir - www.goopedir.com'
    Usuario = 'Allan'
    Site = 'www.goopedir.com'
    MargemInferior = 0.800000000000000000
    MargemSuperior = 0.800000000000000000
    MargemEsquerda = 0.600000000000000000
    MargemDireita = 0.510000000000000000
    ExpandeLogoMarcaConfig.Altura = 0
    ExpandeLogoMarcaConfig.Esquerda = 0
    ExpandeLogoMarcaConfig.Topo = 0
    ExpandeLogoMarcaConfig.Largura = 0
    ExpandeLogoMarcaConfig.Dimensionar = False
    ExpandeLogoMarcaConfig.Esticar = True
    CasasDecimais.Formato = tdetInteger
    CasasDecimais.qCom = 4
    CasasDecimais.vUnCom = 4
    CasasDecimais.MaskqCom = '###,###,###,##0.00'
    CasasDecimais.MaskvUnCom = '###,###,###,##0.00'
    CasasDecimais.Aliquota = 2
    CasasDecimais.MaskAliquota = ',0.00'
    ACBrNFe = ACBrNFe1
    TipoDANFE = tiNFCe
    PosPrinter = ACBrPosPrinter1
    Left = 1625
    Top = 327
  end
  object ACBrNFeDANFCeFortes1: TACBrNFeDANFCeFortes
    Impressora = 'Print ID'
    MostraPreview = False
    MostraStatus = False
    UsaSeparadorPathPDF = True
    Sistema = 'GooPedir - www.goopedir.com'
    Usuario = 'Allan'
    Site = 'www.goopedir.com'
    MargemInferior = 0.800000000000000000
    MargemSuperior = 0.800000000000000000
    MargemEsquerda = 0.300000000000000000
    MargemDireita = 0.300000000000000000
    ExpandeLogoMarcaConfig.Altura = 0
    ExpandeLogoMarcaConfig.Esquerda = 0
    ExpandeLogoMarcaConfig.Topo = 0
    ExpandeLogoMarcaConfig.Largura = 0
    ExpandeLogoMarcaConfig.Dimensionar = False
    ExpandeLogoMarcaConfig.Esticar = True
    CasasDecimais.Formato = tdetInteger
    CasasDecimais.qCom = 2
    CasasDecimais.vUnCom = 2
    CasasDecimais.MaskqCom = '###,###,###,##0.00'
    CasasDecimais.MaskvUnCom = '###,###,###,##0.00'
    CasasDecimais.Aliquota = 2
    CasasDecimais.MaskAliquota = ',0.00'
    TipoDANFE = tiNFCe
    ImprimeTotalLiquido = True
    ImprimeNomeFantasia = True
    ImprimeXPedNItemPed = True
    ImprimeQRCodeLateral = True
    FormularioContinuo = True
    FonteLinhaItem.Charset = DEFAULT_CHARSET
    FonteLinhaItem.Color = clWindowText
    FonteLinhaItem.Height = -9
    FonteLinhaItem.Name = 'Lucida Console'
    FonteLinhaItem.Style = []
    Left = 1634
    Top = 255
  end
end
