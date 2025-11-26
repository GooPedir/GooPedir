object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'Mass Requester - VCL'
  ClientHeight = 400
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 13
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 700
    Height = 56
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 696
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 44
      Height = 13
      Caption = 'Workers:'
    end
    object Label2: TLabel
      Left = 152
      Top = 8
      Width = 66
      Height = 13
      Caption = 'Timeout (ms):'
    end
    object LabelProgress: TLabel
      Left = 666
      Top = 8
      Width = 22
      Height = 13
      Alignment = taRightJustify
      Caption = '0 / 0'
    end
    object SpinWorkers: TSpinEdit
      Left = 72
      Top = 4
      Width = 64
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 0
      Value = 10
    end
    object EditTimeout: TEdit
      Left = 240
      Top = 4
      Width = 96
      Height = 21
      TabOrder = 1
      Text = '10000'
    end
    object ButtonStart: TButton
      Left = 336
      Top = 4
      Width = 88
      Height = 25
      Caption = 'Start'
      TabOrder = 3
      OnClick = ButtonStartClick
    end
    object ButtonStop: TButton
      Left = 432
      Top = 4
      Width = 88
      Height = 25
      Caption = 'Stop'
      TabOrder = 2
      OnClick = ButtonStopClick
    end
  end
  object MemoLog: TMemo
    Left = 0
    Top = 56
    Width = 700
    Height = 344
    Align = alClient
    Lines.Strings = (
      'Mass Requester Log')
    TabOrder = 1
    ExplicitWidth = 696
    ExplicitHeight = 343
  end
  object Progress: TProgressBar
    Left = 8
    Top = 368
    Width = 680
    Height = 24
    TabOrder = 2
  end
end
