unit uServices;

interface

uses System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.PG,
  FireDAC.Phys.PGDef, FireDAC.ConsoleUI.Wait, Data.DB, FireDAC.Comp.Client,
  System.JSON, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.VCLUI.Wait,
  udm, Ragna, FireDAC.Phys.FB, FireDAC.Phys.FBDef;

type
  TServiceSections = class(Tdm)
    Sections: TFDQuery;
    SectionsId: TLargeintField;
    SectionsName: TWideStringField;
    SectionsBoardId: TLargeintField;
//    Banco: TFDConnection;
    { Private declarations }
  public
    { Public declarations }
    function Get(Tabela, Campos, Where: String): TFDQuery;
  end;

var
  ServiceSections: TServiceSections;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}
{$R *.dfm}
{ TServiceSections }

function TServiceSections.Get(Tabela, Campos, Where: String): TFDQuery;
begin
  Sections.SQL.Add('select ' + Campos + ' from ' + Tabela +
    ' where 1 = 1 ' + Where);
  Result := Sections.OpenUp;

end;

end.
