object dm: Tdm
  OldCreateOrder = True
  OnCreate = DataModuleCreate
  Height = 485
  Width = 872
  object SQLite: TFDConnection
    Params.Strings = (
      'Password=root'
      'User_Name=root'
      'Database=santo_alho'
      'Port=2020'
      'DriverID=mySQL')
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvAutoReconnect]
    ResourceOptions.AutoReconnect = True
    LoginPrompt = False
    OnError = SQLiteError
    Left = 368
    Top = 64
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Console'
    Left = 184
    Top = 32
  end
  object FDStanStorageBinLink1: TFDStanStorageBinLink
    Left = 64
    Top = 120
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    Left = 208
    Top = 120
  end
  object Banco: TFDConnection
    Params.Strings = (
      'Port=2020'
      'User_Name=sistema'
      'Password=P4P4L3GU45F00D'
      'Server=localhost'
      'Database=santinho'
      'DriverID=MySQL')
    LoginPrompt = False
    Left = 392
    Top = 256
  end
  object dados: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 632
    Top = 232
  end
end
