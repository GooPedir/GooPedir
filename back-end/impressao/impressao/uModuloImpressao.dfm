object dmImpressaoV2: TdmImpressaoV2
  OnCreate = C
  Height = 822
  Width = 1183
  object DADOS: TFDQuery
    Connection = dmModulo.BANCO
    SQL.Strings = (
      
        'select p.codigo, p.codigo_pedido_dia as codigo_comanda,p.pedido_' +
        'site, p.data_pedido, p.hora_pedido, p.status, p.valor_pedido as ' +
        'vl_pedido,p.valor_desconto as vl_desconto,p.valor_taxa_entrega a' +
        's vl_taxa, p.valor_total_pedido as vl_total,p.troco,p.origem,tp.' +
        'descricao as tipo_pagamento, '
      'c.codigo as codigo_cliente, p.mp,'
      'c.nome, c.celular, '
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
      ''
      
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
    Left = 16
    Top = 136
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
    PrinterSetup.PaperName = 'Normal 72mm Large'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 72000
    PrinterSetup.PaperSize = 123
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
    Left = 8
    Top = 8
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppDados'
    object ppTitleBand3: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 48154
      mmPrintPosition = 0
      object ppLine1: TppLine
        DesignLayer = ppDesignLayer1
        UserName = 'Line1'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = -842
        mmTop = 203
        mmWidth = 85196
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
          '0\fnil\fcharset0 Courier New;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs30 CONFER\'#39'caNCIA\fs24\par'#13 +
          #10'\fs20 #<dbtext displayformat='#39'0000'#39'>codigo</dbtext>\par'#13#10'\fs32 ' +
          '<dbtext>nome</dbtext>\fs20\par'#13#10'\par'#13#10'\par'#13#10#13#10'\pard\cf0\b0\f1\fs' +
          '24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3981
        mmLeft = 265
        mmTop = 2117
        mmWidth = 67386
        BandType = 1
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText1: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs' +
          '24 * * * PEDIDO <dbtext displayformat='#39'000000'#39'>codigo_comanda</d' +
          'btext> * * *\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 33602
        mmWidth = 67102
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
          '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 <dbtext>nome_estabelecimento' +
          '</dbtext>\par'#13#10'\fs16 <dbtext>origem_1</dbtext>\par'#13#10'\par'#13#10#13#10'\par' +
          'd\f1\fs20 Data Pedido: <dbtext>data_pedido</dbtext> <dbtext>hora' +
          '_pedido</dbtext>\par'#13#10'Cliente: <dbtext>nome</dbtext>\par'#13#10'Celula' +
          'r: <dbtext>celular</dbtext>\par'#13#10'<dbtext>qtd_pedidos_cliente</db' +
          'text>\par'#13#10'<dbtext>endereco_completo</dbtext>\par'#13#10'\par'#13#10#13#10'\pard' +
          '\qc\ul\fs24 <dbtext>pedido_site</dbtext>\ulnone\f0\fs16\par'#13#10'\fs' +
          '20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 43033
        mmWidth = 67101
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
        mmLeft = 265
        mmTop = 38894
        mmWidth = 67102
        BandType = 1
        LayerName = Foreground
      end
      object ppLogo80mm: TppImage
        DesignLayer = ppDesignLayer1
        UserName = 'Logo80mm'
        AlignHorizontal = ahCenter
        AlignVertical = avCenter
        MaintainAspectRatio = False
        Stretch = True
        Border.mmPadding = 0
        mmHeight = 29369
        mmLeft = 18785
        mmTop = 3175
        mmWidth = 32015
        BandType = 1
        LayerName = Foreground
      end
    end
    object ppHeaderBand1: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 8467
      mmPrintPosition = 0
      object ppLine2: TppLine
        DesignLayer = ppDesignLayer1
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1323
        mmLeft = -3969
        mmTop = 7144
        mmWidth = 82550
        BandType = 0
        LayerName = Foreground
      end
      object ppRichText10: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText6'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText6'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 ITENS DO PEDIDO\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 2239
        mmWidth = 67101
        BandType = 0
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDetailBand1: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3969
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs24 [<dbtext>tipo</dbtext>] - <dbtext>desc' +
          'ricao</dbtext>\par'#13#10'\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4233
        mmLeft = 1588
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
      mmHeight = 61913
      mmPrintPosition = 0
      object ppLabel31: TppLabel
        DesignLayer = ppDesignLayer1
        UserName = 'Label31'
        Border.mmPadding = 0
        Caption = 'Total Dos Itens'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 5027
        mmWidth = 27781
        BandType = 7
        LayerName = Foreground
      end
      object ppRichText20: TppRichText
        DesignLayer = ppDesignLayer1
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
        mmWidth = 67137
        BandType = 7
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText24: TppDBText
        DesignLayer = ppDesignLayer1
        UserName = 'DBText24'
        Border.mmPadding = 0
        DataField = 'vl_pedido'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 29633
        mmTop = 5027
        mmWidth = 37788
        BandType = 7
        LayerName = Foreground
      end
      object ppLabel32: TppLabel
        DesignLayer = ppDesignLayer1
        UserName = 'Label32'
        Border.mmPadding = 0
        Caption = 'Taxa de Entrega'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 8731
        mmWidth = 27781
        BandType = 7
        LayerName = Foreground
      end
      object ppDBText25: TppDBText
        DesignLayer = ppDesignLayer1
        UserName = 'DBText25'
        Border.mmPadding = 0
        DataField = 'vl_taxa'
        DataPipeline = ppDados
        DisplayFormat = '+$#,0.00;-+$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 29633
        mmTop = 8731
        mmWidth = 37788
        BandType = 7
        LayerName = Foreground
      end
      object ppLabel33: TppLabel
        DesignLayer = ppDesignLayer1
        UserName = 'Label33'
        Border.mmPadding = 0
        Caption = 'Valor Desconto'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 12171
        mmWidth = 27864
        BandType = 7
        LayerName = Foreground
      end
      object ppDBText27: TppDBText
        DesignLayer = ppDesignLayer1
        UserName = 'DBText27'
        Border.mmPadding = 0
        DataField = 'vl_desconto'
        DataPipeline = ppDados
        DisplayFormat = '-$#,0.00;--$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 29633
        mmTop = 12435
        mmWidth = 37788
        BandType = 7
        LayerName = Foreground
      end
      object ppLabel34: TppLabel
        DesignLayer = ppDesignLayer1
        UserName = 'Label34'
        Border.mmPadding = 0
        Caption = 'Valor Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 14
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 5536
        mmLeft = 1588
        mmTop = 15610
        mmWidth = 32015
        BandType = 7
        LayerName = Foreground
      end
      object ppDBText28: TppDBText
        DesignLayer = ppDesignLayer1
        UserName = 'DBText28'
        Border.mmPadding = 0
        DataField = 'vl_total'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 14
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 5556
        mmLeft = 29633
        mmTop = 15610
        mmWidth = 37788
        BandType = 7
        LayerName = Foreground
      end
      object ppRichText21: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText21'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText21'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 FORMA DE PAGAMENTO\f1\par'#13#10'}' +
          #13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 21532
        mmWidth = 67137
        BandType = 7
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppDBText29: TppDBText
        DesignLayer = ppDesignLayer1
        UserName = 'DBText29'
        Border.mmPadding = 0
        DataField = 'troco'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 29633
        mmTop = 26477
        mmWidth = 37788
        BandType = 7
        LayerName = Foreground
      end
      object ppDBText33: TppDBText
        DesignLayer = ppDesignLayer1
        UserName = 'DBText33'
        Border.mmPadding = 0
        DataField = 'tipo_pagamento'
        DataPipeline = ppDados
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 30412
        mmWidth = 65814
        BandType = 7
        LayerName = Foreground
      end
      object ppLabel35: TppLabel
        DesignLayer = ppDesignLayer1
        UserName = 'Label35'
        Border.mmPadding = 0
        Caption = 'Troco'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 26443
        mmWidth = 9260
        BandType = 7
        LayerName = Foreground
      end
      object ppLine16: TppLine
        DesignLayer = ppDesignLayer1
        UserName = 'Line16'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = 1588
        mmTop = 58481
        mmWidth = 85196
        BandType = 7
        LayerName = Foreground
      end
      object ppSystemVariable4: TppSystemVariable
        DesignLayer = ppDesignLayer1
        UserName = 'SystemVariable4'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 3704
        mmLeft = 0
        mmTop = 21431
        mmWidth = 70908
        BandType = 7
        LayerName = Foreground
      end
      object ppSystemVariable7: TppSystemVariable
        DesignLayer = ppDesignLayer1
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
        mmTop = 53718
        mmWidth = 35190
        BandType = 7
        LayerName = Foreground
      end
      object ppSystemVariable13: TppSystemVariable
        DesignLayer = ppDesignLayer1
        UserName = 'SystemVariable13'
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
        mmTop = 48691
        mmWidth = 38894
        BandType = 7
        LayerName = Foreground
      end
      object ppRichText88: TppRichText
        DesignLayer = ppDesignLayer1
        UserName = 'RichText4'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText4'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs20 ' +
          '<dbtext>mp</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 13758
        mmLeft = 1852
        mmTop = 34660
        mmWidth = 65617
        BandType = 7
        LayerName = Foreground
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
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
        mmHeight = 3810
        mmPrintPosition = 0
        object ppRichText6: TppRichText
          DesignLayer = ppDesignLayer1
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
            '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\par' +
            'd\b\f0\fs20 <dbtext>tipo_produto_nome</dbtext> - \fs24 <\f1 dbte' +
            'xt>nome_produto</dbtext>\par'#13#10'\b0\f2\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3921
          mmLeft = 1588
          mmTop = 0
          mmWidth = 65774
          BandType = 3
          GroupNo = 0
          LayerName = Foreground
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
        object ppDB2DBarCode1: TppDB2DBarCode
          DesignLayer = ppDesignLayer1
          UserName = 'DB2DBarCode1'
          AlignBarcode = ahLeft
          AutoScale = True
          AutoSize = False
          Border.mmPadding = 0
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Courier New'
          Font.Size = 10
          Font.Style = [fsBold]
          Transparent = True
          BackgroundColor = clPurple
          BarCodeType = bcQRCode
          DataPipeline = ppDados
          DataField = 'qrcod_motooby'
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
          QRCodeSettings.CharEncoding = bceUTF8
          QRCodeSettings.ErrorCorrection = ecHigh
          QRCodeSettings.IncludeBOM = True
          QRCodeSettings.mmModuleSize = 1059
          QRCodeSettings.mmQuietZone = 1059
          QRCodeSettings.ECICode = -1
          DataMatrixSettings.mmModuleSize = 1059
          DataMatrixSettings.mmQuietZone = 1059
          AztecCodeSettings.mmModuleSize = 1600
          DataPipelineName = 'ppDados'
          mmHeight = 15081
          mmLeft = 135996
          mmTop = 0
          mmWidth = 15610
          BandType = 3
          GroupNo = 0
          LayerName = Foreground
        end
      end
      object ppGroupFooterBand2: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 7938
        mmPrintPosition = 0
        object ppLine3: TppLine
          DesignLayer = ppDesignLayer1
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 1323
          mmLeft = -3969
          mmTop = 6384
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
            '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched2' +
            '0 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>qtd</dbtex' +
            't>\f1 Un X <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_unitario</d' +
            'btext> = \cf1\f0\fs20 <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_' +
            '\f1 total_1\f0 </dbtext>\par'#13#10'\cf0\b0\f2\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5821
          mmLeft = 1588
          mmTop = 231
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
    Left = 104
    Top = 120
  end
  object ppCozinha: TppBDEPipeline
    DataSource = dsCozinha
    UserName = 'Cozinha'
    Left = 616
    Top = 8
    object ppCozinhappField1: TppField
      FieldAlias = 'origem_pedido'
      FieldName = 'origem_pedido'
      FieldLength = 0
      DisplayWidth = 0
      Position = 0
    end
    object ppCozinhappField2: TppField
      FieldAlias = 'origem_local'
      FieldName = 'origem_local'
      FieldLength = 265
      DisplayWidth = 265
      Position = 1
    end
    object ppCozinhappField3: TppField
      FieldAlias = 'data_impressao'
      FieldName = 'data_impressao'
      FieldLength = 0
      DataType = dtDateTime
      DisplayWidth = 18
      Position = 2
    end
    object ppCozinhappField4: TppField
      Alignment = taRightJustify
      FieldAlias = 'codigo'
      FieldName = 'codigo'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 3
    end
    object ppCozinhappField5: TppField
      Alignment = taRightJustify
      FieldAlias = 'vl_unitario'
      FieldName = 'vl_unitario'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 4
    end
    object ppCozinhappField6: TppField
      Alignment = taRightJustify
      FieldAlias = 'qtd'
      FieldName = 'qtd'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 5
    end
    object ppCozinhappField7: TppField
      Alignment = taRightJustify
      FieldAlias = 'vl_total'
      FieldName = 'vl_total'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 6
    end
    object ppCozinhappField8: TppField
      FieldAlias = 'codigo_produto'
      FieldName = 'codigo_produto'
      FieldLength = 10
      DisplayWidth = 10
      Position = 7
    end
    object ppCozinhappField9: TppField
      FieldAlias = 'produto'
      FieldName = 'produto'
      FieldLength = 255
      DisplayWidth = 255
      Position = 8
    end
    object ppCozinhappField10: TppField
      FieldAlias = 'nomeclatura'
      FieldName = 'nomeclatura'
      FieldLength = 255
      DisplayWidth = 255
      Position = 9
    end
    object ppCozinhappField11: TppField
      FieldAlias = 'descricao'
      FieldName = 'descricao'
      FieldLength = 1024
      DisplayWidth = 1024
      Position = 10
    end
    object ppCozinhappField12: TppField
      Alignment = taRightJustify
      FieldAlias = 'vl_adicional'
      FieldName = 'vl_adicional'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 11
    end
    object ppCozinhappField13: TppField
      FieldAlias = 'driver'
      FieldName = 'driver'
      FieldLength = 255
      DisplayWidth = 255
      Position = 12
    end
    object ppCozinhappField14: TppField
      FieldAlias = 'impressora'
      FieldName = 'impressora'
      FieldLength = 255
      DisplayWidth = 255
      Position = 13
    end
    object ppCozinhappField15: TppField
      FieldAlias = 'nome'
      FieldName = 'nome'
      FieldLength = 255
      DisplayWidth = 255
      Position = 14
    end
    object ppCozinhappField16: TppField
      FieldAlias = 'celular'
      FieldName = 'celular'
      FieldLength = 14
      DisplayWidth = 14
      Position = 15
    end
    object ppCozinhappField17: TppField
      FieldAlias = 'data_pedido'
      FieldName = 'data_pedido'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 16
    end
    object ppCozinhappField18: TppField
      FieldAlias = 'hora_pedido'
      FieldName = 'hora_pedido'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 17
    end
    object ppCozinhappField19: TppField
      FieldAlias = 'tipo'
      FieldName = 'tipo'
      FieldLength = 10
      DisplayWidth = 10
      Position = 18
    end
    object ppCozinhappField20: TppField
      FieldAlias = 'categoria'
      FieldName = 'categoria'
      FieldLength = 255
      DisplayWidth = 255
      Position = 19
    end
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
    PrinterSetup.mmPaperHeight = 304800
    PrinterSetup.mmPaperWidth = 55800
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
    Left = 104
    Top = 64
    Version = '21.02'
    mmColumnWidth = 80000
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
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs' +
          '24 * * * <dbtext datapipeline='#39'ppCozinha'#39'>origem_pedido</dbtext>' +
          ' * * *\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5025
        mmLeft = 528
        mmTop = 5032
        mmWidth = 51216
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
        mmWidth = 55800
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
          PrinterSetup.mmPaperHeight = 304800
          PrinterSetup.mmPaperWidth = 55800
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
            mmHeight = 3704
            mmPrintPosition = 0
            object ppRichText43: TppRichText
              DesignLayer = ppDesignLayer5
              UserName = 'RichText31'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Courier New'
              Font.Size = 12
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText31'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\*\gene' +
                'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 - \f1' +
                ' <dbtext>descricao</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 3907
              mmLeft = 4347
              mmTop = -265
              mmWidth = 45168
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
              mmHeight = 5821
              mmPrintPosition = 0
              object ppRichText42: TppRichText
                DesignLayer = ppDesignLayer5
                UserName = 'RichText42'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Courier New'
                Font.Size = 14
                Font.Style = [fsBold]
                Border.mmPadding = 0
                Caption = 'RichText42'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\*\gene' +
                  'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs28 <dbte' +
                  'xt>qtd</dbtext>\f1 Un - <dbtext>produto</dbtext>\f0\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Stretch = True
                Transparent = True
                mmHeight = 4763
                mmLeft = 4233
                mmTop = 794
                mmWidth = 48419
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
              mmHeight = 3969
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
              mmHeight = 5292
              mmPrintPosition = 0
              object ppRichText44: TppRichText
                DesignLayer = ppDesignLayer5
                UserName = 'RichText1'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Courier New'
                Font.Size = 12
                Font.Style = [fsBold]
                Border.mmPadding = 0
                Caption = 'RichText1'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
                  'nd4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>nomeclatura</dbtext>\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Transparent = True
                mmHeight = 4498
                mmLeft = 4233
                mmTop = 529
                mmWidth = 45244
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
      mmHeight = 17727
      mmPrintPosition = 0
      object ppSystemVariable5: TppSystemVariable
        DesignLayer = ppDesignLayer13
        UserName = 'SystemVariable5'
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
        mmTop = 14023
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 6879
        mmWidth = 38894
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = []
        Transparent = True
        DataPipelineName = 'ppCozinha'
        mmHeight = 3440
        mmLeft = 1852
        mmTop = 10583
        mmWidth = 41275
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
    Left = 848
    Top = 184
  end
  object ppFechamentoCaixaCabechado: TppBDEPipeline
    DataSource = dsFechamentoCaixaCabechado
    UserName = 'FechamentoCaixaCabechado'
    Left = 1048
    Top = 184
    object ppFechamentoCaixaCabechadoppField1: TppField
      Alignment = taRightJustify
      FieldAlias = 'id'
      FieldName = 'id'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 0
      Position = 0
    end
    object ppFechamentoCaixaCabechadoppField2: TppField
      Alignment = taRightJustify
      FieldAlias = 'id_caixa'
      FieldName = 'id_caixa'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 1
    end
    object ppFechamentoCaixaCabechadoppField3: TppField
      Alignment = taRightJustify
      FieldAlias = 'id_pedido'
      FieldName = 'id_pedido'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 2
    end
    object ppFechamentoCaixaCabechadoppField4: TppField
      Alignment = taRightJustify
      FieldAlias = 'tipo'
      FieldName = 'tipo'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 3
    end
    object ppFechamentoCaixaCabechadoppField5: TppField
      Alignment = taRightJustify
      FieldAlias = 'id_tipo_pagamento'
      FieldName = 'id_tipo_pagamento'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 4
    end
    object ppFechamentoCaixaCabechadoppField6: TppField
      FieldAlias = 'data'
      FieldName = 'data'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 5
    end
    object ppFechamentoCaixaCabechadoppField7: TppField
      FieldAlias = 'hora'
      FieldName = 'hora'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 6
    end
    object ppFechamentoCaixaCabechadoppField8: TppField
      FieldAlias = 'valor'
      FieldName = 'valor'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 7
    end
    object ppFechamentoCaixaCabechadoppField9: TppField
      FieldAlias = 'descricao'
      FieldName = 'descricao'
      FieldLength = 0
      DataType = dtBLOB
      DisplayWidth = 10
      Position = 8
      Searchable = False
      Sortable = False
    end
    object ppFechamentoCaixaCabechadoppField10: TppField
      Alignment = taRightJustify
      FieldAlias = 'id_1'
      FieldName = 'id_1'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 9
    end
    object ppFechamentoCaixaCabechadoppField11: TppField
      Alignment = taRightJustify
      FieldAlias = 'id_usuario'
      FieldName = 'id_usuario'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 10
    end
    object ppFechamentoCaixaCabechadoppField12: TppField
      FieldAlias = 'data_abertura'
      FieldName = 'data_abertura'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 11
    end
    object ppFechamentoCaixaCabechadoppField13: TppField
      FieldAlias = 'hora_abertura'
      FieldName = 'hora_abertura'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 12
    end
    object ppFechamentoCaixaCabechadoppField14: TppField
      FieldAlias = 'data_fechamento'
      FieldName = 'data_fechamento'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 13
    end
    object ppFechamentoCaixaCabechadoppField15: TppField
      FieldAlias = 'hora_fechamento'
      FieldName = 'hora_fechamento'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 14
    end
    object ppFechamentoCaixaCabechadoppField16: TppField
      FieldAlias = 'valor_abertura'
      FieldName = 'valor_abertura'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 15
    end
    object ppFechamentoCaixaCabechadoppField17: TppField
      Alignment = taRightJustify
      FieldAlias = 'status'
      FieldName = 'status'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 16
    end
    object ppFechamentoCaixaCabechadoppField18: TppField
      FieldAlias = 'observacao'
      FieldName = 'observacao'
      FieldLength = 0
      DataType = dtBLOB
      DisplayWidth = 10
      Position = 17
      Searchable = False
      Sortable = False
    end
    object ppFechamentoCaixaCabechadoppField19: TppField
      FieldAlias = 'valor_fechamento'
      FieldName = 'valor_fechamento'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 18
    end
    object ppFechamentoCaixaCabechadoppField20: TppField
      FieldAlias = 'tipo_pagamento'
      FieldName = 'tipo_pagamento'
      FieldLength = 255
      DisplayWidth = 255
      Position = 19
    end
    object ppFechamentoCaixaCabechadoppField21: TppField
      FieldAlias = 'descricao_utf8'
      FieldName = 'descricao_utf8'
      FieldLength = 0
      DataType = dtMemo
      DisplayWidth = 10
      Position = 20
      Searchable = False
      Sortable = False
    end
    object ppFechamentoCaixaCabechadoppField22: TppField
      FieldAlias = 'descricao_tipo'
      FieldName = 'descricao_tipo'
      FieldLength = 26
      DisplayWidth = 26
      Position = 21
    end
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
  end
  object COZINHA80MM: TppReport
    DataPipeline = ppCozinha
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Scaled 80mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 124
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
    Left = 104
    Top = 16
    Version = '21.02'
    mmColumnWidth = 55800
    DataPipelineName = 'ppCozinha'
    object ppHeaderBand3: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 13229
      mmPrintPosition = 0
      object ppRichText8: TppRichText
        DesignLayer = ppDesignLayer4
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs' +
          '24 * * * <dbtext datapipeline='#39'ppCozinha'#39'>origem_pedido</dbtext>' +
          ' * * *\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5025
        mmLeft = 528
        mmTop = 5032
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
        mmHeight = 2114
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
        mmHeight = 2117
        mmLeft = 0
        mmTop = 11113
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
        mmWidth = 80300
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
          PrinterSetup.PaperName = 'Scaled 80mm Small'
          PrinterSetup.PrinterName = 'Default'
          PrinterSetup.SaveDeviceSettings = True
          PrinterSetup.mmMarginBottom = 0
          PrinterSetup.mmMarginLeft = 0
          PrinterSetup.mmMarginRight = 0
          PrinterSetup.mmMarginTop = 0
          PrinterSetup.mmPaperHeight = 209900
          PrinterSetup.mmPaperWidth = 80300
          PrinterSetup.PaperSize = 124
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
            mmHeight = 3704
            mmPrintPosition = 0
            object ppRichText11: TppRichText
              DesignLayer = ppDesignLayer3
              UserName = 'RichText31'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Name = 'Courier New'
              Font.Size = 12
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText31'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\*\gene' +
                'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 - \f1' +
                ' <dbtext>descricao</dbtext>\par'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 3907
              mmLeft = 4347
              mmTop = -265
              mmWidth = 66533
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
              Font.Name = 'Courier New'
              Font.Size = 8
              Font.Style = [fsBold]
              Border.mmPadding = 0
              Caption = 'RichText87'
              ExportRTFAsBitmap = False
              MailMerge = True
              RichText = 
                '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                '0\fnil\fcharset0 Courier New;}}'#13#10'{\*\generator Riched20 10.0.190' +
                '41}\viewkind4\uc1 '#13#10'\pard\qc\b\f0\fs24 <dbtext>tipo</dbtext>\fs2' +
                '0\par'#13#10#13#10'\pard Cliente: <dbtext>celular</dbtext> - <dbtext>nome<' +
                '/dbtext>\par'#13#10'Data: <dbtext displayformat='#39'mm/dd/yyyy'#39'>data_pedi' +
                'do</dbtext> <dbtext displayformat='#39'h:nn'#39'>hora_pedido</dbtext>\pa' +
                'r'#13#10'}'#13#10#0
              RemoveEmptyLines = False
              Stretch = True
              Transparent = True
              mmHeight = 6634
              mmLeft = 1588
              mmTop = 511
              mmWidth = 69376
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
              mmHeight = 5821
              mmPrintPosition = 0
              object ppRichText12: TppRichText
                DesignLayer = ppDesignLayer3
                UserName = 'RichText42'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Courier New'
                Font.Size = 14
                Font.Style = [fsBold]
                Border.mmPadding = 0
                Caption = 'RichText42'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\*\gene' +
                  'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs28 <dbte' +
                  'xt>qtd</dbtext>\f1 Un - \fs20 <dbtext>categoria</dbtext>\fs28  <' +
                  'dbtext>produto</dbtext>\f0\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Stretch = True
                Transparent = True
                mmHeight = 4763
                mmLeft = 4233
                mmTop = 794
                mmWidth = 66723
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
              mmHeight = 3969
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
              mmHeight = 5292
              mmPrintPosition = 0
              object ppRichText22: TppRichText
                DesignLayer = ppDesignLayer3
                UserName = 'RichText1'
                Font.Charset = DEFAULT_CHARSET
                Font.Color = clWindowText
                Font.Name = 'Courier New'
                Font.Size = 12
                Font.Style = [fsBold]
                Border.mmPadding = 0
                Caption = 'RichText1'
                ExportRTFAsBitmap = False
                MailMerge = True
                RichText = 
                  '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
                  '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
                  'nd4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>nomeclatura</dbtext>\par'#13#10'}'#13#10#0
                RemoveEmptyLines = False
                Stretch = True
                Transparent = True
                mmHeight = 4498
                mmLeft = 4233
                mmTop = 529
                mmWidth = 66723
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
      mmHeight = 14288
      mmPrintPosition = 0
      object ppSystemVariable3: TppSystemVariable
        DesignLayer = ppDesignLayer4
        UserName = 'SystemVariable3'
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
        mmTop = 10583
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 6615
        mmWidth = 35257
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppCozinha'
        mmHeight = 3440
        mmLeft = 37042
        mmTop = 10583
        mmWidth = 35446
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
  object COMANDA56MM: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '56mm'
    PrinterSetup.PaperName = 'Normal 58mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 120
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
    Left = 8
    Top = 72
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppDados'
    object ppTitleBand2: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 33867
      mmPrintPosition = 0
      object ppLine17: TppLine
        DesignLayer = ppDesignLayer6
        UserName = 'Line1'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = -842
        mmTop = 203
        mmWidth = 85196
        BandType = 1
        LayerName = Foreground1
      end
      object ppRichText4: TppRichText
        DesignLayer = ppDesignLayer6
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
          '0\fnil\fcharset0 Courier New;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs30 CONFER\'#39'caNCIA\fs24\par'#13 +
          #10'\fs20 #<dbtext displayformat='#39'0000'#39'>codigo</dbtext>\par'#13#10'\fs32 ' +
          '<dbtext>nome</dbtext>\fs20\par'#13#10'\par'#13#10'\par'#13#10#13#10'\pard\cf0\b0\f1\fs' +
          '24\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3981
        mmLeft = 265
        mmTop = 2117
        mmWidth = 50381
        BandType = 1
        LayerName = Foreground1
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText5: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText5'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText5'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs' +
          '24 * PEDIDO <dbtext displayformat='#39'000000'#39'>codigo_comanda</dbtex' +
          't> *\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 20163
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText9'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 <dbtext>nome_estabelecimento' +
          '</dbtext>\par'#13#10'\fs16 <dbtext>origem_1</dbtext>\par'#13#10'\par'#13#10#13#10'\par' +
          'd\f1\fs20 Data Pedido: <dbtext>data_pedido</dbtext> <dbtext>hora' +
          '_pedido</dbtext>\par'#13#10'Cliente: <dbtext>nome</dbtext>\par'#13#10'Celula' +
          'r: <dbtext>celular</dbtext>\par'#13#10'<dbtext>qtd_pedidos_cliente</db' +
          'text>\par'#13#10'<dbtext>endereco_completo</dbtext>\par'#13#10'\par'#13#10#13#10'\pard' +
          '\qc\ul\fs24 <dbtext>pedido_site</dbtext>\ulnone\f0\fs16\par'#13#10'\fs' +
          '20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 28839
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        DataPipelineName = 'ppDados'
        mmHeight = 3980
        mmLeft = 265
        mmTop = 25190
        mmWidth = 48766
        BandType = 1
        LayerName = Foreground1
      end
      object ppLogo56mm: TppImage
        DesignLayer = ppDesignLayer6
        UserName = 'Logo56mm'
        AlignHorizontal = ahCenter
        AlignVertical = avCenter
        MaintainAspectRatio = False
        Stretch = True
        Border.mmPadding = 0
        mmHeight = 14023
        mmLeft = 19050
        mmTop = 5292
        mmWidth = 14023
        BandType = 1
        LayerName = Foreground1
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText6'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 PRODUTOS\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 2239
        mmWidth = 50381
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
      mmHeight = 3969
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
          '0\fnil Courier New;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\*\generator ' +
          'Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 [<dbtext>ti' +
          'po</dbtext>] - <dbtext>descricao</dbtext>\par'#13#10'\b0\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4233
        mmLeft = 1588
        mmTop = 0
        mmWidth = 44734
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
      mmHeight = 61913
      mmPrintPosition = 0
      object ppLabel1: TppLabel
        DesignLayer = ppDesignLayer6
        UserName = 'Label31'
        Border.mmPadding = 0
        Caption = 'Total Dos Itens'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 5027
        mmWidth = 27781
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
        mmWidth = 50417
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 8731
        mmWidth = 27781
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 11203
        mmTop = 8636
        mmWidth = 35067
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 12171
        mmWidth = 27864
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 11203
        mmTop = 12340
        mmWidth = 35067
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
        Font.Name = 'Courier New'
        Font.Size = 14
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 5821
        mmLeft = 1588
        mmTop = 15610
        mmWidth = 14552
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
        Font.Name = 'Courier New'
        Font.Size = 14
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 5556
        mmLeft = 11203
        mmTop = 15515
        mmWidth = 35067
        BandType = 7
        LayerName = Foreground1
      end
      object ppRichText27: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText21'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText21'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 FORMA DE PAGAMENTO\f1\par'#13#10'}' +
          #13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 21532
        mmWidth = 50381
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 11298
        mmTop = 26667
        mmWidth = 34878
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taCentered
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 4763
        mmLeft = 1588
        mmTop = 30602
        mmWidth = 47388
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 3704
        mmLeft = 1588
        mmTop = 26633
        mmWidth = 9260
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
        mmTop = 59796
        mmWidth = 85196
        BandType = 7
        LayerName = Foreground1
      end
      object ppSystemVariable9: TppSystemVariable
        DesignLayer = ppDesignLayer6
        UserName = 'SystemVariable4'
        Border.mmPadding = 0
        VarType = vtDateTime
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 3229
        mmLeft = 0
        mmTop = 21431
        mmWidth = 50381
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 55563
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 51858
        mmWidth = 38894
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 3704
        mmLeft = 10848
        mmTop = 5027
        mmWidth = 35446
        BandType = 7
        LayerName = Foreground1
      end
      object ppRichText89: TppRichText
        DesignLayer = ppDesignLayer6
        UserName = 'RichText89'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText89'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\b\f0\fs20 ' +
          '<dbtext>mp</dbtext>\par'#13#10'}'#13#10#0
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
        mmHeight = 4763
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
            '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
            'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext>qtd</dbtext>un - <dbtext>nome_' +
            'produto</dbtext>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5061
          mmLeft = 1588
          mmTop = -529
          mmWidth = 44734
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
        mmHeight = 7408
        mmPrintPosition = 0
        object ppLine20: TppLine
          DesignLayer = ppDesignLayer6
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 1323
          mmLeft = -3969
          mmTop = 6086
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
            '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched2' +
            '0 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qr\cf1\b\f0\fs20 <dbtext dis' +
            'playformat='#39'#,0.00;-#,0.00'#39'>vl_\f1 total_1\f0 </dbtext>\par'#13#10#13#10'\' +
            'pard\cf0\b0\f2\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5821
          mmLeft = 1588
          mmTop = 231
          mmWidth = 44734
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
  object CONFERENCIA80MM: TppReport
    AutoStop = False
    DataPipeline = ppDados
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Normal 72mm Large'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 72000
    PrinterSetup.PaperSize = 123
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
    Left = 296
    Top = 24
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppDados'
    object ppTitleBand5: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 12965
      mmPrintPosition = 0
      object ppLine5: TppLine
        DesignLayer = ppDesignLayer2
        UserName = 'Line1'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = -842
        mmTop = 203
        mmWidth = 85196
        BandType = 1
        LayerName = Foreground2
      end
      object ppRichText17: TppRichText
        DesignLayer = ppDesignLayer2
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs' +
          '24 * * * <dbtext>desc_ficha</dbtext> * * *\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 2381
        mmWidth = 67204
        BandType = 1
        LayerName = Foreground2
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
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
          '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 <dbtext>nome_estabelecimento' +
          '</dbtext>\par'#13#10'\fs16 <dbtext>origem_1</dbtext>\par'#13#10'\par'#13#10#13#10'\par' +
          'd\f1\fs20 Data Pedido: <dbtext>data_pedido</dbtext> <dbtext>hora' +
          '_pedido</dbtext>\par'#13#10#13#10'\pard\qc\f0\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 7938
        mmWidth = 67204
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
      mmHeight = 8467
      mmPrintPosition = 0
      object ppLine6: TppLine
        DesignLayer = ppDesignLayer2
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1323
        mmLeft = -3969
        mmTop = 7144
        mmWidth = 82550
        BandType = 0
        LayerName = Foreground2
      end
      object ppRichText19: TppRichText
        DesignLayer = ppDesignLayer2
        UserName = 'RichText6'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText6'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 ITENS DO PEDIDO\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 2239
        mmWidth = 67101
        BandType = 0
        LayerName = Foreground2
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDetailBand7: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3969
      mmPrintPosition = 0
      object ppRichText32: TppRichText
        DesignLayer = ppDesignLayer2
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs24 [<dbtext>tipo</dbtext>] - <dbtext>desc' +
          'ricao</dbtext>\par'#13#10'\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4233
        mmLeft = 1588
        mmTop = 0
        mmWidth = 65780
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
      mmBottomOffset = 0
      mmHeight = 29633
      mmPrintPosition = 0
      object ppRichText33: TppRichText
        DesignLayer = ppDesignLayer2
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
        mmWidth = 67137
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
        Caption = 'Valor Total'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 14
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 5556
        mmLeft = 265
        mmTop = 5292
        mmWidth = 32015
        BandType = 7
        LayerName = Foreground2
      end
      object ppDBText11: TppDBText
        DesignLayer = ppDesignLayer2
        UserName = 'DBText28'
        Border.mmPadding = 0
        DataField = 'vl_total'
        DataPipeline = ppDados
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 14
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
      object ppSystemVariable17: TppSystemVariable
        DesignLayer = ppDesignLayer2
        UserName = 'SystemVariable17'
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
        mmTop = 25023
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 21319
        mmWidth = 38894
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
        mmHeight = 4763
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
            '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\par' +
            'd\b\f0\fs20 <dbtext>tipo_produto_nome</dbtext> - \fs24 <\f1 dbte' +
            'xt>nome_produto</dbtext>\par'#13#10'\b0\f2\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5061
          mmLeft = 1588
          mmTop = -529
          mmWidth = 65774
          BandType = 3
          GroupNo = 0
          LayerName = Foreground2
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
        object ppDB2DBarCode5: TppDB2DBarCode
          DesignLayer = ppDesignLayer2
          UserName = 'DB2DBarCode1'
          AlignBarcode = ahLeft
          AutoScale = True
          AutoSize = False
          Border.mmPadding = 0
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Name = 'Courier New'
          Font.Size = 10
          Font.Style = [fsBold]
          Transparent = True
          BackgroundColor = clPurple
          BarCodeType = bcQRCode
          DataPipeline = ppDados
          DataField = 'qrcod_motooby'
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
          QRCodeSettings.CharEncoding = bceUTF8
          QRCodeSettings.ErrorCorrection = ecHigh
          QRCodeSettings.IncludeBOM = True
          QRCodeSettings.mmModuleSize = 1059
          QRCodeSettings.mmQuietZone = 1059
          QRCodeSettings.ECICode = -1
          DataMatrixSettings.mmModuleSize = 1059
          DataMatrixSettings.mmQuietZone = 1059
          AztecCodeSettings.mmModuleSize = 1600
          DataPipelineName = 'ppDados'
          mmHeight = 15081
          mmLeft = 135996
          mmTop = 1058
          mmWidth = 15610
          BandType = 3
          GroupNo = 0
          LayerName = Foreground2
        end
      end
      object ppGroupFooterBand8: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 7938
        mmPrintPosition = 0
        object ppLine8: TppLine
          DesignLayer = ppDesignLayer2
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 1323
          mmLeft = -3969
          mmTop = 6384
          mmWidth = 82550
          BandType = 5
          GroupNo = 0
          LayerName = Foreground2
        end
        object ppRichText36: TppRichText
          DesignLayer = ppDesignLayer2
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
            '0 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>qtd</dbtex' +
            't>\f1 Un X <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_unitario</d' +
            'btext> = \cf1\f0\fs20 <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_' +
            '\f1 total_1\f0 </dbtext>\par'#13#10'\cf0\b0\f2\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5821
          mmLeft = 1588
          mmTop = 231
          mmWidth = 65855
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
    PrinterSetup.PaperName = 'Normal 58mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 120
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
    Left = 296
    Top = 88
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppDados'
    object ppTitleBand6: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 12965
      mmPrintPosition = 0
      object ppLine7: TppLine
        DesignLayer = ppDesignLayer7
        UserName = 'Line1'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 2117
        mmLeft = -842
        mmTop = 203
        mmWidth = 85196
        BandType = 1
        LayerName = BandLayer9
      end
      object ppRichText34: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText5'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText5'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\gen' +
          'erator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs' +
          '24 * * * <dbtext>desc_ficha</dbtext> * * *\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 2646
        mmWidth = 48683
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText9'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil\f' +
          'charset0 Arial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generat' +
          'or Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 <' +
          'dbtext>nome_estabelecimento</dbtext>\par'#13#10'\fs16 <dbtext>origem_1' +
          '</dbtext>\par'#13#10'\par'#13#10#13#10'\pard\f1\fs20 Data Pedido: <dbtext>data_p' +
          'edido</dbtext> <dbtext>hora_pedido</dbtext>\par'#13#10#13#10'\pard\qc\f0\p' +
          'ar'#13#10#13#10'\pard\cf0\b0\f2\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 7938
        mmWidth = 48683
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
      mmHeight = 8467
      mmPrintPosition = 0
      object ppLine9: TppLine
        DesignLayer = ppDesignLayer7
        UserName = 'Line2'
        Border.mmPadding = 0
        Pen.Style = psDot
        Weight = 0.750000000000000000
        mmHeight = 1323
        mmLeft = -3969
        mmTop = 7144
        mmWidth = 82550
        BandType = 0
        LayerName = BandLayer9
      end
      object ppRichText38: TppRichText
        DesignLayer = ppDesignLayer7
        UserName = 'RichText6'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText6'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs20 PRODUTOS\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 5027
        mmLeft = 265
        mmTop = 2239
        mmWidth = 50381
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs24 [<dbtext>tipo</dbtext>] - <dbtext>desc' +
          'ricao</dbtext>\par'#13#10'\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 4233
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
      mmHeight = 32544
      mmPrintPosition = 0
      object ppRichText40: TppRichText
        DesignLayer = ppDesignLayer7
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
        Font.Name = 'Courier New'
        Font.Size = 14
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 5821
        mmLeft = 265
        mmTop = 5027
        mmWidth = 14552
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
        Font.Name = 'Courier New'
        Font.Size = 14
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppDados'
        mmHeight = 5556
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
        mmTop = 30253
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 25783
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 22079
        mmWidth = 38894
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
        mmHeight = 4763
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
            '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\par' +
            'd\b\f0\fs24 <\f1 dbtext>nome_produto</dbtext>\par'#13#10'\b0\f2\par'#13#10'}' +
            #13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5061
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
        mmHeight = 7938
        mmPrintPosition = 0
        object ppLine22: TppLine
          DesignLayer = ppDesignLayer7
          UserName = 'Line3'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 1323
          mmLeft = -3969
          mmTop = 6384
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
          Border.mmPadding = 0
          Caption = 'RichText23'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil A' +
            'rial;}}'#13#10'{\colortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched2' +
            '0 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>qtd</dbtex' +
            't>\f1 Un X <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_unitario</d' +
            'btext> = \cf1\f0\fs20 <dbtext displayformat='#39'#,0.00;-#,0.00'#39'>vl_' +
            '\f1 total_1\f0 </dbtext>\par'#13#10'\cf0\b0\f2\fs24\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5821
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
    Left = 48
    Top = 272
  end
  object ppResumo: TppBDEPipeline
    DataSource = dsResumo
    UserName = 'Resumo'
    Left = 48
    Top = 392
    object ppResumoppField1: TppField
      Alignment = taRightJustify
      FieldAlias = 'id'
      FieldName = 'id'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 0
      Position = 0
    end
    object ppResumoppField2: TppField
      FieldAlias = 'data_abertura'
      FieldName = 'data_abertura'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 1
    end
    object ppResumoppField3: TppField
      FieldAlias = 'hora_abertura'
      FieldName = 'hora_abertura'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 2
    end
    object ppResumoppField4: TppField
      FieldAlias = 'data_fechamento'
      FieldName = 'data_fechamento'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 3
    end
    object ppResumoppField5: TppField
      FieldAlias = 'hora_fechamento'
      FieldName = 'hora_fechamento'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 4
    end
    object ppResumoppField6: TppField
      FieldAlias = 'valor_abertura'
      FieldName = 'valor_abertura'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 5
    end
    object ppResumoppField7: TppField
      FieldAlias = 'valor_fechamento'
      FieldName = 'valor_fechamento'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 6
    end
    object ppResumoppField8: TppField
      FieldAlias = 'descricao'
      FieldName = 'descricao'
      FieldLength = 255
      DisplayWidth = 255
      Position = 7
    end
    object ppResumoppField9: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_tipo_pagamento'
      FieldName = 'valor_tipo_pagamento'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 8
    end
    object ppResumoppField10: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_mesa'
      FieldName = 'valor_mesa'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 9
    end
    object ppResumoppField11: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_vem_buscar'
      FieldName = 'valor_vem_buscar'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 10
    end
    object ppResumoppField12: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_delivery'
      FieldName = 'valor_delivery'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 11
    end
    object ppResumoppField13: TppField
      Alignment = taRightJustify
      FieldAlias = 'taxa_entrega'
      FieldName = 'taxa_entrega'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 12
    end
    object ppResumoppField14: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_diferenca'
      FieldName = 'valor_diferenca'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 13
    end
  end
  object dsResumo: TDataSource
    DataSet = CAIXA_RESUMO
    Left = 48
    Top = 336
  end
  object CAIXA_RESUMO80MM: TppReport
    AutoStop = False
    DataPipeline = ppResumo
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Scaled 80mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 124
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
    Left = 48
    Top = 463
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppResumo'
    object ppTitleBand7: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 24871
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
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs24 Fechamento de Caixa\par'#13#10'\fs20 (Resumido)\par'#13#10'\fs3' +
          '0 #<dbtext displayformat='#39'000'#39'>id</dbtext>\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 71840
        BandType = 1
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel6: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Tipo de Pagamento'
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
        mmTop = 18785
        mmWidth = 71840
        BandType = 1
        LayerName = BandLayer13
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
      mmHeight = 3969
      mmPrintPosition = 0
      object ppDBText7: TppDBText
        DesignLayer = ppDesignLayer9
        UserName = 'DBText7'
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
        mmHeight = 3243
        mmLeft = 1896
        mmTop = -265
        mmWidth = 812138
        BandType = 4
        LayerName = BandLayer13
      end
      object ppDBText8: TppDBText
        DesignLayer = ppDesignLayer9
        UserName = 'DBText8'
        Border.mmPadding = 0
        DataField = 'valor_tipo_pagamento'
        DataPipeline = ppResumo
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 9
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppResumo'
        mmHeight = 3243
        mmLeft = 44450
        mmTop = -265
        mmWidth = 25969
        BandType = 4
        LayerName = BandLayer13
      end
      object ppLine23: TppLine
        DesignLayer = ppDesignLayer9
        UserName = 'Line23'
        Border.Style = psDot
        Border.mmPadding = 0
        Pen.Style = psDash
        Weight = 0.750000000000000000
        mmHeight = 1058
        mmLeft = 0
        mmTop = 2911
        mmWidth = 84067
        BandType = 4
        LayerName = BandLayer13
      end
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
      mmBottomOffset = 0
      mmHeight = 63765
      mmPrintPosition = 0
      object ppLabel5: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label5'
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
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 0
        mmWidth = 12700
        BandType = 7
        LayerName = BandLayer13
      end
      object ppDBCalc2: TppDBCalc
        DesignLayer = ppDesignLayer9
        UserName = 'DBCalc2'
        Border.mmPadding = 0
        DataField = 'valor_tipo_pagamento'
        DataPipeline = ppResumo
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppResumo'
        mmHeight = 4498
        mmLeft = 40217
        mmTop = 298
        mmWidth = 30139
        BandType = 7
        LayerName = BandLayer13
      end
      object ppSystemVariable6: TppSystemVariable
        DesignLayer = ppDesignLayer9
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
        mmTop = 57679
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 54240
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer13
      end
      object ppLabel7: TppLabel
        DesignLayer = ppDesignLayer9
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Abertura:'
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
        mmTop = 8202
        mmWidth = 26988
        BandType = 7
        LayerName = BandLayer13
      end
      object ppRichText45: TppRichText
        DesignLayer = ppDesignLayer9
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext>data_abertura</dbtext> <dbt' +
          'ext displayformat='#39'h:nn'#39'>hora_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 8202
        mmWidth = 41504
        BandType = 7
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 12965
        mmWidth = 26988
        BandType = 7
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 17463
        mmWidth = 37306
        BandType = 7
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 22225
        mmWidth = 42069
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 39173
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 34145
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 43406
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppRichText48: TppRichText
        DesignLayer = ppDesignLayer9
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext>data_fechamento</dbtext> <d' +
          'btext displayformat='#39'h:nn'#39'>hora_fechamento</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 12700
        mmWidth = 41504
        BandType = 7
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText49'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,' +
          '0.00'#39'>valor_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 44186
        mmTop = 17463
        mmWidth = 26150
        BandType = 7
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText50'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,' +
          '0.00'#39'>valor_fechamento</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 44450
        mmTop = 22225
        mmWidth = 25961
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText51: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText501'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText501'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,' +
          '0.00'#39'>valor_delivery</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 34145
        mmWidth = 41504
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText52'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,' +
          '0.00'#39'>valor_vem_buscar</dbtext>\par'#13#10#13#10'\pard\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 39173
        mmWidth = 41504
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText53'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,' +
          '0.00'#39'>valor_mesa</dbtext>\par'#13#10#13#10'\pard\par'#13#10'\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 43406
        mmWidth = 41504
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
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 29648
        mmWidth = 42069
        BandType = 7
        LayerName = BandLayer13
      end
      object ppRichText64: TppRichText
        DesignLayer = ppDesignLayer9
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,' +
          '0.00'#39'>taxa_entrega</dbtext>\par'#13#10#13#10'\pard\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 28840
        mmTop = 29648
        mmWidth = 41559
        BandType = 7
        LayerName = BandLayer13
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
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
    Left = 200
    Top = 280
  end
  object ppCompleto: TppBDEPipeline
    DataSource = dsCompleto
    UserName = 'Completo'
    Left = 200
    Top = 400
    object ppCompletoppField1: TppField
      Alignment = taRightJustify
      FieldAlias = 'id'
      FieldName = 'id'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 0
      Position = 0
    end
    object ppCompletoppField2: TppField
      FieldAlias = 'data_abertura'
      FieldName = 'data_abertura'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 1
    end
    object ppCompletoppField3: TppField
      FieldAlias = 'hora_abertura'
      FieldName = 'hora_abertura'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 2
    end
    object ppCompletoppField4: TppField
      FieldAlias = 'data_fechamento'
      FieldName = 'data_fechamento'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 3
    end
    object ppCompletoppField5: TppField
      FieldAlias = 'hora_fechamento'
      FieldName = 'hora_fechamento'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 4
    end
    object ppCompletoppField6: TppField
      FieldAlias = 'valor_abertura'
      FieldName = 'valor_abertura'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 5
    end
    object ppCompletoppField7: TppField
      FieldAlias = 'valor_fechamento'
      FieldName = 'valor_fechamento'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 6
    end
    object ppCompletoppField8: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_computado'
      FieldName = 'valor_computado'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 7
    end
    object ppCompletoppField9: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_informado'
      FieldName = 'valor_informado'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 8
    end
    object ppCompletoppField10: TppField
      Alignment = taRightJustify
      FieldAlias = 'valor_diferenca'
      FieldName = 'valor_diferenca'
      FieldLength = 0
      DataType = dtDouble
      DisplayWidth = 10
      Position = 9
    end
    object ppCompletoppField11: TppField
      Alignment = taRightJustify
      FieldAlias = 'tipo'
      FieldName = 'tipo'
      FieldLength = 0
      DataType = dtInteger
      DisplayWidth = 10
      Position = 10
    end
    object ppCompletoppField12: TppField
      FieldAlias = 'transacao_valor'
      FieldName = 'transacao_valor'
      FieldLength = 0
      DataType = dtSingle
      DisplayWidth = 10
      Position = 11
    end
    object ppCompletoppField13: TppField
      FieldAlias = 'transacao_data'
      FieldName = 'transacao_data'
      FieldLength = 0
      DataType = dtDate
      DisplayWidth = 10
      Position = 12
    end
    object ppCompletoppField14: TppField
      FieldAlias = 'transacao_hora'
      FieldName = 'transacao_hora'
      FieldLength = 0
      DataType = dtTime
      DisplayWidth = 10
      Position = 13
    end
    object ppCompletoppField15: TppField
      FieldAlias = 'transacao_descricao'
      FieldName = 'transacao_descricao'
      FieldLength = 0
      DataType = dtMemo
      DisplayWidth = 10
      Position = 14
      Searchable = False
      Sortable = False
    end
  end
  object dsCompleto: TDataSource
    DataSet = CAIXA_COMPLETO
    Left = 200
    Top = 344
  end
  object CAIXA_COMPLETO80MM: TppReport
    AutoStop = False
    DataPipeline = ppCompleto
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Scaled 80mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 124
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
    Left = 200
    Top = 464
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
        mmWidth = 75726
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
        mmWidth = 75936
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
        Pen.Style = psDash
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
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\*\gene' +
          'rator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\b\f0\fs18 <dbte' +
          'xt>transacao_descricao</dbtext>\fs16\par'#13#10#13#10'\pard\qr [\f1 <dbtex' +
          't>transacao_data</dbtext>\f0  <dbtext displayformat='#39'h:nn'#39'>trans' +
          'acao_hora</dbtext>] - <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39 +
          '>transacao_valor</dbtext>\f1\fs18\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3886
        mmLeft = 1852
        mmTop = 1323
        mmWidth = 73025
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 28310
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 24342
        mmWidth = 38894
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
        Font.Name = 'Courier New'
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
        mmLeft = 44186
        mmTop = 6879
        mmWidth = 30687
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
        mmLeft = 44715
        mmTop = 11642
        mmWidth = 30423
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
        mmLeft = 44186
        mmTop = 16140
        mmWidth = 30952
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
    Left = 352
    Top = 288
  end
  object ppMotoboy: TppBDEPipeline
    DataSource = dsMotoboy
    UserName = 'Motoboy'
    Left = 352
    Top = 408
  end
  object dsMotoboy: TDataSource
    DataSet = CAIXA_MOTOBOY
    Left = 352
    Top = 352
  end
  object CAIXA_MOTOBOY80MM: TppReport
    AutoStop = False
    DataPipeline = ppMotoboy
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Scaled 80mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 124
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
    Left = 352
    Top = 472
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
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        TextAlignment = taCentered
        Transparent = True
        mmHeight = 4762
        mmLeft = 29104
        mmTop = 17463
        mmWidth = 21167
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 28310
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 24342
        mmWidth = 38894
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
          Font.Name = 'Courier New'
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
          Font.Name = 'Courier New'
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
          Font.Name = 'Courier New'
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
          Font.Name = 'Courier New'
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
          Font.Name = 'Courier New'
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
          Font.Name = 'Courier New'
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
          Font.Name = 'Courier New'
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
    Left = 520
    Top = 296
  end
  object ppProduto: TppBDEPipeline
    DataSource = dsProduto
    UserName = 'Produto'
    Left = 520
    Top = 416
  end
  object dsProduto: TDataSource
    DataSet = CAIXA_PRODUTO
    Left = 520
    Top = 360
  end
  object CAIXA_PRODUTO80MM: TppReport
    AutoStop = False
    DataPipeline = ppProduto
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Scaled 80mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 124
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
    Left = 520
    Top = 480
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppProduto'
    object ppTitleBand11: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 30956
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
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs24 Fechamento de Caixa\par'#13#10'\fs20 (Produto)\par'#13#10'\fs30' +
          ' #<dbtext displayformat='#39'000'#39'>id</dbtext>\par'#13#10'<dbtext>tipo</dbt' +
          'ext>\par'#13#10'\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 71082
        BandType = 1
        LayerName = BandLayer17
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel39: TppLabel
        DesignLayer = ppDesignLayer11
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
        mmLeft = 1896
        mmTop = 24342
        mmWidth = 71082
        BandType = 1
        LayerName = BandLayer17
      end
    end
    object ppHeaderBand11: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 5821
      mmPrintPosition = 0
    end
    object ppDetailBand13: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 3969
      mmPrintPosition = 0
      object ppRichText63: TppRichText
        DesignLayer = ppDesignLayer11
        UserName = 'RichText1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText1'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil\f' +
          'charset0 Arial;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\' +
          'uc1 '#13#10'\pard\b\f0\fs20 <dbtext>nome</dbtext>\par'#13#10'\b0 <dbtext>adi' +
          'cionais</dbtext>\b\par'#13#10#13#10'\pard\qr\f1 <dbtext>quantidade</dbtext' +
          '> x <dbtext displayformat='#39'$#,0.00;-$#,0.00'#39'>total</dbtext>\b0\f' +
          '2\fs24\par'#13#10#13#10'\pard\b\f0\fs20\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 265
        mmWidth = 71173
        BandType = 4
        LayerName = BandLayer17
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
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
      mmBottomOffset = 0
      mmHeight = 33338
      mmPrintPosition = 0
      object ppSystemVariable22: TppSystemVariable
        DesignLayer = ppDesignLayer11
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
        LayerName = BandLayer17
      end
      object ppSystemVariable23: TppSystemVariable
        DesignLayer = ppDesignLayer11
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
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer17
      end
      object ppLabel40: TppLabel
        DesignLayer = ppDesignLayer11
        UserName = 'Label40'
        Border.mmPadding = 0
        Caption = 'Quantidade:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4762
        mmLeft = 1852
        mmTop = 265
        mmWidth = 29104
        BandType = 7
        LayerName = BandLayer17
      end
      object ppDBCalc8: TppDBCalc
        DesignLayer = ppDesignLayer11
        UserName = 'DBCalc8'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppProduto
        DisplayFormat = '000'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppProduto'
        mmHeight = 4739
        mmLeft = 47890
        mmTop = 265
        mmWidth = 25021
        BandType = 7
        LayerName = BandLayer17
      end
      object ppLabel41: TppLabel
        DesignLayer = ppDesignLayer11
        UserName = 'Label401'
        Border.mmPadding = 0
        Caption = 'Total:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4762
        mmLeft = 1852
        mmTop = 5821
        mmWidth = 15875
        BandType = 7
        LayerName = BandLayer17
      end
      object ppDBCalc9: TppDBCalc
        DesignLayer = ppDesignLayer11
        UserName = 'DBCalc9'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppProduto
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppProduto'
        mmHeight = 4763
        mmLeft = 47890
        mmTop = 5821
        mmWidth = 25021
        BandType = 7
        LayerName = BandLayer17
      end
    end
    object ppGroup11: TppGroup
      BreakName = 'grupo'
      DataPipeline = ppProduto
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group11'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppProduto'
      NewFile = False
      object ppGroupHeaderBand11: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 5027
        mmPrintPosition = 0
        object ppRichText85: TppRichText
          DesignLayer = ppDesignLayer11
          UserName = 'RichText85'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = []
          Border.mmPadding = 0
          Caption = 'RichText85'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil\fcharset0 Courier New;}}'#13#10'{\*\generator Riched20 10.0.190' +
            '41}\viewkind4\uc1 '#13#10'\pard\qc\b\f0\fs24 <dbtext>descricao</dbtext' +
            '>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 3704
          mmLeft = 1852
          mmTop = 1323
          mmWidth = 71082
          BandType = 3
          GroupNo = 0
          LayerName = BandLayer17
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
        mmHeight = 3440
        mmPrintPosition = 0
        object ppLine26: TppLine
          DesignLayer = ppDesignLayer11
          UserName = 'Line1'
          Border.mmPadding = 0
          Pen.Style = psDash
          Weight = 0.750000000000000000
          mmHeight = 1323
          mmLeft = 265
          mmTop = 265
          mmWidth = 115359
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer17
        end
      end
    end
    object ppGroup14: TppGroup
      BreakName = 'id'
      DataPipeline = ppProduto
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group14'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppProduto'
      NewFile = False
      object ppGroupHeaderBand14: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 0
        mmPrintPosition = 0
      end
      object ppGroupFooterBand14: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 0
        mmPrintPosition = 0
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
  object CAIXA_RESUMO56MM: TppReport
    AutoStop = False
    DataPipeline = ppResumo
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Normal 58mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 120
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
    Left = 48
    Top = 551
    Version = '21.02'
    mmColumnWidth = 72000
    DataPipelineName = 'ppResumo'
    object ppTitleBand12: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 24871
      mmPrintPosition = 0
      object ppRichText65: TppRichText
        DesignLayer = ppDesignLayer12
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
          'f1\b\f0\fs24 Fechamento de Caixa\par'#13#10'\fs20 (Resumido)\par'#13#10'\fs3' +
          '0 #<dbtext displayformat='#39'000'#39'>id</dbtext>\fs24\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
        mmLeft = 1896
        mmTop = 0
        mmWidth = 48746
        BandType = 1
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel42: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label6'
        Border.mmPadding = 0
        Caption = 'Tipo de Pagamento'
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
        mmTop = 18785
        mmWidth = 48651
        BandType = 1
        LayerName = BandLayer18
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
      mmHeight = 10583
      mmPrintPosition = 0
      object ppDBText17: TppDBText
        DesignLayer = ppDesignLayer12
        UserName = 'DBText7'
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
        mmHeight = 3243
        mmLeft = 1896
        mmTop = -265
        mmWidth = 788008
        BandType = 4
        LayerName = BandLayer18
      end
      object ppDBText18: TppDBText
        DesignLayer = ppDesignLayer12
        UserName = 'DBText8'
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
        mmHeight = 3175
        mmLeft = 1852
        mmTop = 3175
        mmWidth = 24077
        BandType = 4
        LayerName = BandLayer18
      end
      object ppLine27: TppLine
        DesignLayer = ppDesignLayer12
        UserName = 'Line23'
        Border.Style = psDot
        Border.mmPadding = 0
        Pen.Style = psDash
        Weight = 0.750000000000000000
        mmHeight = 1058
        mmLeft = 0
        mmTop = 8991
        mmWidth = 59937
        BandType = 4
        LayerName = BandLayer18
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
      mmBottomOffset = 0
      mmHeight = 88106
      mmPrintPosition = 0
      object ppLabel43: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label5'
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
        mmHeight = 4233
        mmLeft = 1852
        mmTop = 0
        mmWidth = 12700
        BandType = 7
        LayerName = BandLayer18
      end
      object ppDBCalc10: TppDBCalc
        DesignLayer = ppDesignLayer12
        UserName = 'DBCalc2'
        Border.mmPadding = 0
        DataField = 'valor_tipo_pagamento'
        DataPipeline = ppResumo
        DisplayFormat = '$#,0.00;-$#,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Transparent = True
        DataPipelineName = 'ppResumo'
        mmHeight = 4498
        mmLeft = 15610
        mmTop = -41
        mmWidth = 24871
        BandType = 7
        LayerName = BandLayer18
      end
      object ppSystemVariable24: TppSystemVariable
        DesignLayer = ppDesignLayer12
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
        mmTop = 84402
        mmWidth = 48683
        BandType = 7
        LayerName = BandLayer18
      end
      object ppSystemVariable25: TppSystemVariable
        DesignLayer = ppDesignLayer12
        UserName = 'SystemVariable12'
        Border.mmPadding = 0
        VarType = vtDocumentName
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 8151
        mmLeft = 1852
        mmTop = 74613
        mmWidth = 48683
        BandType = 7
        LayerName = BandLayer18
      end
      object ppLabel44: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label7'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Abertura:'
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
        mmTop = 8202
        mmWidth = 25021
        BandType = 7
        LayerName = BandLayer18
      end
      object ppRichText66: TppRichText
        DesignLayer = ppDesignLayer12
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext>data_abertura</dbtext> <dbtext' +
          ' displayformat='#39'h:nn'#39'>hora_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 12435
        mmWidth = 24871
        BandType = 7
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel45: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label10'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Fechamento:'
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
        mmTop = 16933
        mmWidth = 25135
        BandType = 7
        LayerName = BandLayer18
      end
      object ppLabel46: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label101'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Abertura:'
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
        mmTop = 25665
        mmWidth = 25135
        BandType = 7
        LayerName = BandLayer18
      end
      object ppLabel47: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label13'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Fechamento:'
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
        mmTop = 34396
        mmWidth = 25135
        BandType = 7
        LayerName = BandLayer18
      end
      object ppLabel48: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label14'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Vem Buscar:'
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
        mmTop = 51594
        mmWidth = 23813
        BandType = 7
        LayerName = BandLayer18
      end
      object ppLabel49: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label15'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Delivery:'
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
        mmTop = 43127
        mmWidth = 23813
        BandType = 7
        LayerName = BandLayer18
      end
      object ppLabel50: TppLabel
        DesignLayer = ppDesignLayer12
        UserName = 'Label16'
        AutoSize = False
        Border.mmPadding = 0
        Caption = 'Mesas:'
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
        mmTop = 60101
        mmWidth = 23813
        BandType = 7
        LayerName = BandLayer18
      end
      object ppRichText67: TppRichText
        DesignLayer = ppDesignLayer12
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext>data_fechamento</dbtext> <dbte' +
          'xt displayformat='#39'h:nn'#39'>hora_fechamento</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 21167
        mmWidth = 24871
        BandType = 7
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText68: TppRichText
        DesignLayer = ppDesignLayer12
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
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_abertura</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 29898
        mmWidth = 24871
        BandType = 7
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText69: TppRichText
        DesignLayer = ppDesignLayer12
        UserName = 'RichText50'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText50'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_fechamento</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 38894
        mmWidth = 25135
        BandType = 7
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText70: TppRichText
        DesignLayer = ppDesignLayer12
        UserName = 'RichText501'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText501'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_delivery</dbtext>\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 47361
        mmWidth = 24871
        BandType = 7
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText71: TppRichText
        DesignLayer = ppDesignLayer12
        UserName = 'RichText52'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText52'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_vem_buscar</dbtext>\par'#13#10'\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 55563
        mmWidth = 24871
        BandType = 7
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppRichText72: TppRichText
        DesignLayer = ppDesignLayer12
        UserName = 'RichText53'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Courier New'
        Font.Size = 10
        Font.Style = [fsBold]
        Border.mmPadding = 0
        Caption = 'RichText53'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext displayformat='#39'$#,0.00;-$#,0.0' +
          '0'#39'>valor_mesa</dbtext>\par'#13#10'\par'#13#10'\par'#13#10'\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Transparent = True
        mmHeight = 4763
        mmLeft = 1852
        mmTop = 64633
        mmWidth = 24871
        BandType = 7
        LayerName = BandLayer18
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
    end
    object ppDesignLayers14: TppDesignLayers
      object ppDesignLayer12: TppDesignLayer
        UserName = 'BandLayer18'
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
  object CAIXA_COMPLETO56MM: TppReport
    AutoStop = False
    DataPipeline = ppCompleto
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Normal 58mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 120
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
    Left = 192
    Top = 560
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
          't>transacao_data</dbtext>\f0  <dbtext displayformat='#39'h:nn'#39'>trans' +
          'acao_hora</dbtext>] - <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39 +
          '>transacao_valor</dbtext>\f1\fs18\par'#13#10'}'#13#10#0
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
    PrinterSetup.PaperName = 'Normal 58mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 120
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
    Left = 344
    Top = 568
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
  object CAIXA_PRODUTO56MM: TppReport
    AutoStop = False
    DataPipeline = ppProduto
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = 'PDV #GooPedir v1.3.15'
    PrinterSetup.PaperName = 'Normal 58mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 120
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
    Left = 520
    Top = 544
    Version = '21.02'
    mmColumnWidth = 80300
    DataPipelineName = 'ppProduto'
    object ppTitleBand15: TppTitleBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 27252
      mmPrintPosition = 0
      object ppRichText81: TppRichText
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
          '0\fnil\fcharset0 Courier New;}{\f1\fnil\fcharset0 Arial;}}'#13#10'{\co' +
          'lortbl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}' +
          '\viewkind4\uc1 '#13#10'\pard\qc\cf1\b\f0\fs22 Fechamento de Caixa\fs24' +
          '\par'#13#10'\fs18 (Produto)\fs20\par'#13#10'\fs26 #<dbtext displayformat='#39'00' +
          '0'#39'>id</dbtext>\par'#13#10'<dbtext>tipo</dbtext>\par'#13#10'\fs24\par'#13#10#13#10'\par' +
          'd\cf0\b0\f1\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 20093
        mmLeft = 1896
        mmTop = 0
        mmWidth = 44734
        BandType = 1
        LayerName = BandLayer23
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
      object ppLabel65: TppLabel
        DesignLayer = ppDesignLayer17
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
        mmLeft = 1852
        mmTop = 21431
        mmWidth = 44715
        BandType = 1
        LayerName = BandLayer23
      end
    end
    object ppHeaderBand15: TppHeaderBand
      Background.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      PrintOnLastPage = False
      mmBottomOffset = 0
      mmHeight = 5027
      mmPrintPosition = 0
    end
    object ppDetailBand17: TppDetailBand
      Background1.Brush.Style = bsClear
      Background2.Brush.Style = bsClear
      Border.mmPadding = 0
      PrintHeight = phDynamic
      mmBottomOffset = 0
      mmHeight = 4763
      mmPrintPosition = 0
      object ppRichText82: TppRichText
        DesignLayer = ppDesignLayer17
        UserName = 'RichText64'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Name = 'Arial'
        Font.Size = 12
        Font.Style = []
        Border.mmPadding = 0
        Caption = 'RichText64'
        ExportRTFAsBitmap = False
        MailMerge = True
        RichText = 
          '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
          '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
          'nd4\uc1 '#13#10'\pard\b\f0\fs20 <dbtext>adicionais</dbtext>\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 3791
        mmLeft = 1852
        mmTop = 973
        mmWidth = 44734
        BandType = 4
        LayerName = BandLayer23
        mmBottomOffset = 0
        mmOverFlowOffset = 0
        mmStopPosition = 0
        mmMinHeight = 0
      end
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
      mmHeight = 42333
      mmPrintPosition = 0
      object ppSystemVariable30: TppSystemVariable
        DesignLayer = ppDesignLayer17
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
        LayerName = BandLayer23
      end
      object ppSystemVariable31: TppSystemVariable
        DesignLayer = ppDesignLayer17
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
        mmWidth = 38894
        BandType = 7
        LayerName = BandLayer23
      end
      object ppLabel66: TppLabel
        DesignLayer = ppDesignLayer17
        UserName = 'Label40'
        Border.mmPadding = 0
        Caption = 'Quantidade:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4762
        mmLeft = 1852
        mmTop = 265
        mmWidth = 29104
        BandType = 7
        LayerName = BandLayer23
      end
      object ppDBCalc16: TppDBCalc
        DesignLayer = ppDesignLayer17
        UserName = 'DBCalc8'
        Border.mmPadding = 0
        DataField = 'quantidade'
        DataPipeline = ppProduto
        DisplayFormat = '000'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppProduto'
        mmHeight = 4763
        mmLeft = 30692
        mmTop = 265
        mmWidth = 15922
        BandType = 7
        LayerName = BandLayer23
      end
      object ppLabel67: TppLabel
        DesignLayer = ppDesignLayer17
        UserName = 'Label401'
        Border.mmPadding = 0
        Caption = 'Total:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        FormFieldSettings.FormSubmitInfo.SubmitMethod = fstPost
        FormFieldSettings.FormFieldType = fftNone
        Transparent = True
        mmHeight = 4762
        mmLeft = 1852
        mmTop = 5821
        mmWidth = 15875
        BandType = 7
        LayerName = BandLayer23
      end
      object ppDBCalc17: TppDBCalc
        DesignLayer = ppDesignLayer17
        UserName = 'DBCalc9'
        Border.mmPadding = 0
        DataField = 'total'
        DataPipeline = ppProduto
        DisplayFormat = '$ #,0.00;-$ #,0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Name = 'Courier New'
        Font.Size = 12
        Font.Style = [fsBold]
        TextAlignment = taRightJustified
        Transparent = True
        DataPipelineName = 'ppProduto'
        mmHeight = 4763
        mmLeft = 19145
        mmTop = 5821
        mmWidth = 27485
        BandType = 7
        LayerName = BandLayer23
      end
    end
    object ppGroup13: TppGroup
      BreakName = 'codigo'
      DataPipeline = ppProduto
      GroupFileSettings.NewFile = False
      GroupFileSettings.EmailFile = False
      KeepTogether = True
      OutlineSettings.CreateNode = True
      StartOnOddPage = False
      UserName = 'Group11'
      mmNewColumnThreshold = 0
      mmNewPageThreshold = 0
      DataPipelineName = 'ppProduto'
      NewFile = False
      object ppGroupHeaderBand13: TppGroupHeaderBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        PrintHeight = phDynamic
        mmBottomOffset = 0
        mmHeight = 6350
        mmPrintPosition = 0
        object ppRichText84: TppRichText
          DesignLayer = ppDesignLayer17
          UserName = 'RichText84'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Courier New'
          Font.Size = 12
          Font.Style = [fsBold]
          Border.mmPadding = 0
          Caption = 'RichText84'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
            'nd4\uc1 '#13#10'\pard\b\f0\fs24 <dbtext>nome</dbtext>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Stretch = True
          Transparent = True
          mmHeight = 5556
          mmLeft = 1852
          mmTop = 795
          mmWidth = 44734
          BandType = 3
          GroupNo = 0
          LayerName = BandLayer23
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
      end
      object ppGroupFooterBand13: TppGroupFooterBand
        Background.Brush.Style = bsClear
        Border.mmPadding = 0
        HideWhenOneDetail = False
        mmBottomOffset = 0
        mmHeight = 6350
        mmPrintPosition = 0
        object ppRichText83: TppRichText
          DesignLayer = ppDesignLayer17
          UserName = 'RichText63'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Name = 'Arial'
          Font.Size = 12
          Font.Style = [fsBold]
          Border.mmPadding = 0
          Caption = 'RichText63'
          ExportRTFAsBitmap = False
          MailMerge = True
          RichText = 
            '{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1046{\fonttbl{\f' +
            '0\fnil Courier New;}}'#13#10'{\*\generator Riched20 10.0.19041}\viewki' +
            'nd4\uc1 '#13#10'\pard\qr\b\f0\fs20 <dbtext displayformat='#39'000'#39'>quantid' +
            'ade</dbtext> x <dbtext displayformat='#39'$ #,0.00;-$ #,0.00'#39'>total<' +
            '/dbtext>\par'#13#10'}'#13#10#0
          RemoveEmptyLines = False
          Transparent = True
          mmHeight = 4498
          mmLeft = 1852
          mmTop = -82
          mmWidth = 44734
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer23
          mmBottomOffset = 0
          mmOverFlowOffset = 0
          mmStopPosition = 0
          mmMinHeight = 0
        end
        object ppLine30: TppLine
          DesignLayer = ppDesignLayer17
          UserName = 'Line26'
          Border.mmPadding = 0
          Pen.Style = psDot
          Weight = 0.750000000000000000
          mmHeight = 4763
          mmLeft = 0
          mmTop = 4688
          mmWidth = 61995
          BandType = 5
          GroupNo = 0
          LayerName = BandLayer23
        end
      end
    end
    object ppDesignLayers17: TppDesignLayers
      object ppDesignLayer17: TppDesignLayer
        UserName = 'BandLayer23'
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
  object iReqImpressaoTest: iRequisicao
    BaseURL = 'http://localhost:2121/v1/util/teste/impressao'
    eTAG = False
    Metodo = mGet
    Status = 0
    MostrarAguarde = False
    TempoExpiracao = 2000
    Left = 48
    Top = 696
  end
  object ppTesteImpressao: TppReport
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Scaled 80mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 124
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
    Left = 48
    Top = 639
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
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\cf1\' +
          'b\f0\fs28 Teste de Impress\'#39'e3o GooPedir\par'#13#10'}'#13#10#0
        RemoveEmptyLines = False
        Stretch = True
        Transparent = True
        mmHeight = 16302
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
        mmHeight = 33867
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
    Left = 648
    Top = 304
    ParamData = <
      item
        Name = 'ID_CAIXA'
        ParamType = ptInput
      end>
  end
  object dsCancelamento: TDataSource
    DataSet = CAIXA_CANCELAMENTO
    Left = 648
    Top = 368
  end
  object ppCancelamento: TppBDEPipeline
    DataSource = dsCancelamento
    UserName = 'Cancelamento'
    Left = 648
    Top = 432
  end
  object CAIXA_CANCELAMENTO80MM: TppReport
    AutoStop = False
    DataPipeline = ppCancelamento
    PassSetting = psTwoPass
    PrinterSetup.BinName = 'Default'
    PrinterSetup.DocumentName = '80mm'
    PrinterSetup.PaperName = 'Scaled 80mm Small'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 209900
    PrinterSetup.mmPaperWidth = 80300
    PrinterSetup.PaperSize = 124
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
    Left = 648
    Top = 495
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
          '0\fnil\fcharset0 Courier New;}}'#13#10'{\colortbl ;\red0\green0\blue0;' +
          '}'#13#10'{\*\generator Riched20 10.0.19041}\viewkind4\uc1 '#13#10'\pard\qc\c' +
          'f1\b\f0\fs24 Fechamento de Caixa\par'#13#10'\fs20 (Cancelamento)\par'#13#10 +
          '\fs30 #<dbtext displayformat='#39'000'#39'>id</dbtext>\fs24\par'#13#10'}'#13#10#0
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
          '0\fnil\fcharset0 Courier New;}{\f1\fnil Courier New;}}'#13#10'{\colort' +
          'bl ;\red0\green0\blue0;}'#13#10'{\*\generator Riched20 10.0.19041}\vie' +
          'wkind4\uc1 '#13#10'\pard\cf1\b\f0\fs16 (<dbtext displayformat='#39'000'#39'>co' +
          'digo_pedido_dia</dbtext>) - <dbtext displayformat='#39'mm/dd'#39'>data_p' +
          'edido</dbtext> / <dbtext displayformat='#39'h:nn'#39'>hora_pedido</dbtex' +
          't> \par'#13#10' <dbtext>cliente</dbtext>\par'#13#10' <dbtext>produto</dbtext' +
          '>\par'#13#10' <dbtext displayformat='#39'00'#39'>quantidade</dbtext>Un - <dbte' +
          'xt displayformat='#39'#,0.00;-#,0.00'#39'>valor_total</dbtext>\par'#13#10'\par' +
          #13#10'-------------------------------------------\f1\par'#13#10'}'#13#10#0
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 16404
        mmWidth = 35190
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
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = [fsBold]
        Transparent = True
        mmHeight = 3704
        mmLeft = 1852
        mmTop = 12965
        mmWidth = 38894
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
        Font.Name = 'Courier New'
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
    PrinterSetup.PaperName = 'Normal 58mm Large'
    PrinterSetup.PrinterName = 'Default'
    PrinterSetup.SaveDeviceSettings = True
    PrinterSetup.mmMarginBottom = 0
    PrinterSetup.mmMarginLeft = 0
    PrinterSetup.mmMarginRight = 0
    PrinterSetup.mmMarginTop = 0
    PrinterSetup.mmPaperHeight = 4003900
    PrinterSetup.mmPaperWidth = 52000
    PrinterSetup.PaperSize = 121
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
    Left = 680
    Top = 575
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
end
