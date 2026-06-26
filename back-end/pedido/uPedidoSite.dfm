object frmPedidoSite: TfrmPedidoSite
  Left = 0
  Top = 0
  Caption = 'frmPedidoSite'
  ClientHeight = 600
  ClientWidth = 872
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Button1: TButton
    Left = 136
    Top = 8
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
    Left = 64
    Top = 8
  end
  object tMinimiza: TTimer
    Interval = 1
    OnTimer = tMinimizaTimer
    Left = 8
    Top = 128
  end
  object TrayIcon1: TTrayIcon
    Visible = True
    Left = 8
    Top = 64
  end
end
