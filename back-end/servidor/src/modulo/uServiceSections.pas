unit uServiceSections;

interface

uses
  System.SysUtils, System.Classes, uDM, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.ConsoleUI.Wait, Data.DB, FireDAC.Comp.Client,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, Ragna, FireDAC.Phys.IBBase, FireDAC.Stan.StorageBin,
  FireDAC.Comp.UI;

type
  TServiceSections = class(Tdm)
    Sections: TFDQuery;
  private
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
  Sections.SQL.Clear;
  Sections.SQL.Add('select ' + Campos + ' from ' + Tabela);
  Result := Sections.OpenUp;
end;

end.
