object frmCore: TfrmCore
  Left = 0
  Top = 0
  Caption = 'frmCore'
  ClientHeight = 442
  ClientWidth = 965
  Color = clWindow
  Ctl3D = False
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  WindowState = wsMinimized
  OnCreate = FormCreate
  TextHeight = 15
  object tMinimiza: TTimer
    Interval = 1
    OnTimer = tMinimizaTimer
    Left = 600
    Top = 64
  end
  object dataSetMerchants2: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 912
    Top = 88
  end
  object dataSetMerchants1: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 912
    Top = 24
  end
  object dsMerchants1: TDataSource
    DataSet = dataSetMerchants1
    Left = 912
    Top = 152
  end
  object dsMerchants2: TDataSource
    DataSet = dataSetMerchants2
    Left = 912
    Top = 206
  end
  object Configuracoes: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 824
    Top = 24
  end
end
