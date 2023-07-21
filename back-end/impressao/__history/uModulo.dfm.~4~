object dmModulo: TdmModulo
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 379
  Width = 712
  object BANCO: TFDConnection
    Params.Strings = (
      'Port=2626'
      'User_Name=root'
      'Password=root'
      'Database=viapian_forquilhinha'
      'Server=localhost'
      'DriverID=MySQL')
    ResourceOptions.AssignedValues = [rvAutoReconnect]
    ResourceOptions.AutoReconnect = True
    LoginPrompt = False
    Left = 304
    Top = 120
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 192
    Top = 120
  end
  object FDSchemaAdapter1: TFDSchemaAdapter
    Left = 24
    Top = 24
  end
end
