inherited ServiceSections: TServiceSections
  OldCreateOrder = True
  object Sections: TFDQuery
    Connection = Banco
    SQL.Strings = (
      'select'
      '  sections.id,'
      '  sections.name,'
      '  sections.board_id'
      'from sections')
    Left = 166
    Top = 40
  end
end
