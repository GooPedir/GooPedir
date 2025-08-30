unit uProcedure;

interface

uses conexao, Winapi.Windows, uDM, FireDAC.Comp.Client, DataSet.Serialize,
  System.Classes,
  uRequisicao,
  JOSE.Types.JSON, Winapi.TlHelp32, Winapi.ShellAPI, Vcl.Controls, Vcl.Forms,
  Vcl.ExtCtrls;

procedure ContadorDePedidos;

implementation

procedure ContadorDePedidos;
var
  conexao: TConexao;
  Dados: TFDMemTable;
  Cliente: Integer;
  Chama: boolean;
begin
exit;
  conexao := TConexao.Create('ContadorDePedidos');
  conexao.SQL.Add
    ('select * from index_pedido where count = 0 order by id desc limit 100');
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      conexao.SQL.Add('select 0 as zero, codigo_cliente as codigo from pedido_'
        + Dados.FieldByName('referencia').AsString + ' where codigo = :codigo');
      conexao.Parametros('codigo', Dados.FieldByName('id').AsInteger);
      try
        Cliente := conexao.FieldByName('codigo');
      except
        Cliente := 0;
      end;
      if Cliente > 0 then
      begin
        conexao.SQL.Add
          ('update cliente set pedidos = pedidos + 1 where codigo = :codigo');
        conexao.Parametros('codigo', Cliente);
        conexao.ExecuteSQL;

        conexao.SQL.Add('update index_pedido set count = 1 where id = :id');
        conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
        conexao.ExecuteSQL;

      end;
      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.SQL.Add('select * from index_pedido where count = 0 limit 100');
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(conexao.ConsultaSQL);
  if Dados.RecordCount > 0 then
  begin
    Chama := true;
  end;
  Dados.Free;
  conexao.Free;
  if Chama then
  begin
    ContadorDePedidos;
  end;
end;

end.
