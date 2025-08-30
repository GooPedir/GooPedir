object frmProdutoSite: TfrmProdutoSite
  Left = 0
  Top = 0
  Caption = 'frmProdutoSite'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
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
    Left = 384
    Top = 240
  end
  object TrayIcon1: TTrayIcon
    Visible = True
    Left = 384
    Top = 176
  end
  object tClose: TTimer
    Interval = 1
    OnTimer = tCloseTimer
    Left = 208
    Top = 168
  end
  object iReq: iRequisicao
    eTAG = False
    Metodo = mGet
    Status = 0
    MostrarAguarde = False
    TempoExpiracao = 2000
    Left = 208
    Top = 224
  end
end
