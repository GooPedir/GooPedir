object ServiceSections: TServiceSections
  OldCreateOrder = True
  Height = 349
  Width = 505
  object Sections: TFDQuery
    SQL.Strings = (
      'select'
      '  sections.id,'
      '  sections.name,'
      '  sections.board_id'
      'from sections')
    Left = 232
    Top = 24
    object SectionsId: TLargeintField
      AutoGenerateValue = arAutoInc
      FieldName = 'id'
      Origin = 'id'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
    end
    object SectionsName: TWideStringField
      FieldName = 'name'
      Origin = 'name'
      Size = 255
    end
    object SectionsBoardId: TLargeintField
      FieldName = 'board_id'
      Origin = 'board_id'
      Visible = False
    end
  end
  object Banco: TFDConnection
    Params.Strings = (
      'Database=C:\iCep\Base\BASE30.FDB'
      'User_Name=SYSDBA'
      'Password=P@m$O&s#'
      'Server=localhost'
      'Port=3050'
      'CharacterSet=WIN1254'
      'DriverID=FB')
    LoginPrompt = False
    Left = 88
    Top = 56
  end
end
