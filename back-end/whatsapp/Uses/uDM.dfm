object dm: Tdm
  OnCreate = DataModuleCreate
  Height = 791
  Width = 1180
  PixelsPerInch = 96
  object DADOS_EMPRESA: TFDMemTable
    AfterPost = DADOS_EMPRESAAfterPost
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired]
    UpdateOptions.CheckRequired = False
    Left = 12
    Top = 8
    object DADOS_EMPRESANOME: TStringField
      FieldName = 'NOME'
      Size = 200
    end
    object DADOS_EMPRESATELEFONE: TStringField
      FieldName = 'TELEFONE'
    end
    object DADOS_EMPRESAPEDIDO_MINIMO: TFloatField
      FieldName = 'PEDIDO_MINIMO'
    end
    object DADOS_EMPRESAKM_MAXIMO: TFloatField
      FieldName = 'KM_MAXIMO'
    end
    object DADOS_EMPRESACEP: TStringField
      FieldName = 'CEP'
    end
    object DADOS_EMPRESARUA: TStringField
      FieldName = 'RUA'
    end
    object DADOS_EMPRESABAIRRO: TStringField
      FieldName = 'BAIRRO'
    end
    object DADOS_EMPRESACIDADE: TStringField
      FieldName = 'CIDADE'
    end
    object DADOS_EMPRESAESTADO: TStringField
      FieldName = 'ESTADO'
    end
    object DADOS_EMPRESANUMERO: TStringField
      FieldName = 'NUMERO'
    end
    object DADOS_EMPRESASELECIONA_BAIRROS: TIntegerField
      FieldName = 'SELECIONA_BAIRROS'
    end
    object DADOS_EMPRESATAXA_POR_KM: TIntegerField
      FieldName = 'TAXA_POR_KM'
    end
    object DADOS_EMPRESATIPO_ENTREGA: TIntegerField
      FieldName = 'TIPO_ENTREGA'
    end
    object DADOS_EMPRESATIPO_VALOR_PIZZA: TIntegerField
      FieldName = 'TIPO_VALOR_PIZZA'
    end
    object DADOS_EMPRESAMENSAGEM_INICIAL: TBlobField
      FieldName = 'MENSAGEM_INICIAL'
    end
    object DADOS_EMPRESALAT: TStringField
      FieldName = 'LAT'
    end
    object DADOS_EMPRESALONG: TStringField
      FieldName = 'LONG'
    end
    object DADOS_EMPRESATAXA_ENTREGA: TFloatField
      FieldName = 'TAXA_ENTREGA'
    end
    object DADOS_EMPRESAATENDIMENTO: TIntegerField
      FieldName = 'ATENDIMENTO'
    end
    object DADOS_EMPRESAPERMITIR_CEP: TIntegerField
      FieldName = 'PERMITIR_CEP'
    end
  end
  object Banco: TFDConnection
    Params.Strings = (
      'Port=2020'
      'Database=tio_scooby'
      'User_Name=sistema'
      'Password=P4P4L3GU45F00D'
      'DriverID=MySQL')
    FetchOptions.AssignedValues = [evAutoClose, evUnidirectional]
    FetchOptions.AutoClose = False
    ResourceOptions.AssignedValues = [rvBackup, rvAutoReconnect]
    ResourceOptions.Backup = True
    ResourceOptions.AutoReconnect = True
    LoginPrompt = False
    Left = 56
    Top = 160
  end
  object memTabelas: TFDMemTable
    IndexFieldNames = 'tipo;registros'
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 12
    Top = 72
    object memTabelastipo: TStringField
      DisplayLabel = 'Tipo'
      FieldName = 'tipo'
    end
    object memTabelasnome: TStringField
      DisplayLabel = 'Nome'
      FieldName = 'nome'
      Size = 50
    end
    object memTabelastabela: TStringField
      DisplayLabel = 'Tabela'
      FieldName = 'tabela'
      Size = 50
    end
    object memTabelasregistros: TIntegerField
      DisplayLabel = 'Registros'
      FieldName = 'registros'
    end
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 928
    Top = 32
  end
  object memDadosCelular: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 392
    Top = 120
    object memDadosCelularcelular: TStringField
      FieldName = 'celular'
      Size = 200
    end
    object memDadosCelularbateria: TStringField
      FieldName = 'bateria'
    end
    object memDadosCelularatendimentos: TIntegerField
      FieldName = 'atendimentos'
    end
    object memDadosCelularpedidos: TIntegerField
      FieldName = 'pedidos'
    end
    object memDadosCelularenviada: TIntegerField
      FieldName = 'enviada'
    end
    object memDadosCelularrecebida: TIntegerField
      FieldName = 'recebida'
    end
    object memDadosCelulartempo: TStringField
      FieldName = 'tempo'
    end
  end
  object tTravado: TTimer
    Enabled = False
    Interval = 30000
    OnTimer = tTravadoTimer
    Left = 456
    Top = 272
  end
end
