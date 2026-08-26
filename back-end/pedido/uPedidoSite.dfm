object frmPedidoSite: TfrmPedidoSite
  Left = 0
  Top = 0
  Caption = 'frmPedidoSite'
  ClientHeight = 570
  ClientWidth = 895
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object Button1: TButton
    Left = 8
    Top = 240
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object ReqPedidos: iRequisicao
    BaseURL = 'https://ws.goopedir.com/v2/pedidos.php'
    eTAG = False
    Metodo = mGet
    Status = 0
    MostrarAguarde = False
    TempoExpiracao = 2000
    Left = 16
    Top = 8
  end
  object tMinimiza: TTimer
    Interval = 1
    OnTimer = tMinimizaTimer
    Left = 16
    Top = 128
  end
  object TrayIcon1: TTrayIcon
    Visible = True
    Left = 16
    Top = 64
  end
  object Timer1: TTimer
    Interval = 120000
    OnTimer = Timer1Timer
    Left = 8
    Top = 192
  end
end
