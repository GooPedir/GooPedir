object dmModulo: TdmModulo
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 379
  Width = 712
  PixelsPerInch = 96
  object BANCO: TFDConnection
    Params.Strings = (
      'Port=2020'
      'User_Name=sistema'
      'Password=P4P4L3GU45F00D'
      'Database=viapian_forquilhinha'
      'Server=192.168.0.60'
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
