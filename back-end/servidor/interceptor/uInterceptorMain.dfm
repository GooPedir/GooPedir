object frmInterceptor: TfrmInterceptor
  Left = 0
  Top = 0
  Caption = 'GooPedir Interceptor'
  ClientHeight = 520
  ClientWidth = 860
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object lblStatus: TLabel
    Left = 16
    Top = 16
    Width = 44
    Height = 15
    Caption = 'Parado'
  end
  object lblStats: TLabel
    Left = 16
    Top = 42
    Width = 220
    Height = 15
    Caption = 'Requisicoes: 0 | Erros: 0 | Lentas: 0'
  end
  object grpConfig: TGroupBox
    Left = 16
    Top = 72
    Width = 385
    Height = 185
    Caption = 'Configuracao'
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 28
      Width = 69
      Height = 15
      Caption = 'Porta publica'
    end
    object Label2: TLabel
      Left = 136
      Top = 28
      Width = 54
      Height = 15
      Caption = 'Instancias'
    end
    object Label3: TLabel
      Left = 256
      Top = 28
      Width = 43
      Height = 15
      Caption = 'Erros OK'
    end
    object Label4: TLabel
      Left = 16
      Top = 84
      Width = 64
      Height = 15
      Caption = 'Porta inicial'
    end
    object Label5: TLabel
      Left = 136
      Top = 84
      Width = 55
      Height = 15
      Caption = 'Porta final'
    end
    object Label6: TLabel
      Left = 256
      Top = 84
      Width = 65
      Height = 15
      Caption = 'Timeout ms'
    end
    object edtPublicPort: TEdit
      Left = 16
      Top = 48
      Width = 90
      Height = 23
      TabOrder = 0
      Text = '2121'
    end
    object edtInstances: TEdit
      Left = 136
      Top = 48
      Width = 90
      Height = 23
      TabOrder = 1
      Text = '2'
    end
    object edtMaxErrors: TEdit
      Left = 256
      Top = 48
      Width = 90
      Height = 23
      TabOrder = 2
      Text = '5'
    end
    object edtStartPort: TEdit
      Left = 16
      Top = 104
      Width = 90
      Height = 23
      TabOrder = 3
      Text = '2122'
    end
    object edtEndPort: TEdit
      Left = 136
      Top = 104
      Width = 90
      Height = 23
      TabOrder = 4
      Text = '2125'
    end
    object edtTimeout: TEdit
      Left = 256
      Top = 104
      Width = 90
      Height = 23
      TabOrder = 5
      Text = '5000'
    end
    object chkAutoStart: TCheckBox
      Left = 16
      Top = 144
      Width = 145
      Height = 17
      Caption = 'Iniciar configurado'
      Checked = True
      State = cbChecked
      TabOrder = 6
    end
  end
  object btnSave: TButton
    Left = 424
    Top = 80
    Width = 145
    Height = 33
    Caption = 'Salvar'
    TabOrder = 1
    OnClick = btnSaveClick
  end
  object btnStart: TButton
    Left = 424
    Top = 120
    Width = 145
    Height = 33
    Caption = 'Iniciar'
    TabOrder = 2
    OnClick = btnStartClick
  end
  object btnStop: TButton
    Left = 424
    Top = 160
    Width = 145
    Height = 33
    Caption = 'Parar instancias'
    TabOrder = 3
    OnClick = btnStopClick
  end
  object memInstances: TMemo
    Left = 16
    Top = 280
    Width = 385
    Height = 217
    Lines.Strings = (
      'Instancias')
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 4
  end
  object memLog: TMemo
    Left = 424
    Top = 216
    Width = 409
    Height = 281
    Lines.Strings = (
      'Log')
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object TrayIcon1: TTrayIcon
    Hint = 'GooPedir Interceptor'
    PopupMenu = PopupMenuTray
    Visible = True
    OnDblClick = TrayIcon1DblClick
    Left = 672
    Top = 80
  end
  object tHealth: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tHealthTimer
    Left = 736
    Top = 80
  end
  object PopupMenuTray: TPopupMenu
    Left = 672
    Top = 144
    object mAbrirInterceptor: TMenuItem
      Caption = 'Abrir Interceptor'
      OnClick = mAbrirInterceptorClick
    end
    object mOcultarInterceptor: TMenuItem
      Caption = 'Ocultar'
      OnClick = mOcultarInterceptorClick
    end
    object mFecharInterceptor: TMenuItem
      Caption = 'Fechar'
      OnClick = mFecharInterceptorClick
    end
  end
end
