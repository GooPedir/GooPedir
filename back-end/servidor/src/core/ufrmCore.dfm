object frmCore: TfrmCore
  Left = 0
  Top = 0
  Caption = 'frmCore'
  ClientHeight = 442
  ClientWidth = 628
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
end
