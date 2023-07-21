unit uEnviaProduto;

interface

function EnviaProduto(codigo:Integer):Integer;

implementation

function EnviaProduto(codigo:Integer):Integer;
var
  Insert: TInsertUpdate;
  SQL: String;
  codigo: Integer;
  Dados: TFDMemTable;
  InsertSite: TInsertUpdateSite;
  Descricao: String;
begin

end;

end.
