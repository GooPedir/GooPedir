unit Tasks;

interface

procedure RegisterAllTasks;

implementation

uses
  TaskManager, conexao, System.SysUtils, System.Classes, Vcl.Dialogs,
  FireDAC.Comp.Client, uCacheControl, Dataset.Serialize, uControllCaches, v2,
  System.DateUtils, JOSE.Types.JSON;

procedure Sabores;
var
  conexao: TConexao;
  dados: TFDMemTable;
begin
  conexao := TConexao.Create('TaskSabores');
  dados := TFDMemTable.Create(nil);

  conexao.SQL.Add('select 0 as zero, codigo from tipo_produto where pizza = 1');
  dados.LoadFromJSON(conexao.ConsultaSQL);

  if dados.RecordCount > 0 then
  begin
    while not dados.Eof do
    begin
      LimpaCache('GetFlavor', dados.FieldByName('codigo').AsString);
      GetFlavor(dados.FieldByName('codigo').AsString);
      dados.Next;
    end;
  end;

  dados.Free;

  conexao.Free;
end;

procedure Clientes;
begin

end;

procedure RelatorioVenda;
var
  AnoAtual, MesAtual, Mes: Word;
  DataIni, DataFim: TDate;
  Data: TJsonArray;
begin
  AnoAtual := YearOf(Date);
  MesAtual := MonthOf(Date);

  try
    // Gera relatórios do mês atual até janeiro
    for Mes := MesAtual downto 1 do
    begin
      DataIni := EncodeDate(AnoAtual, Mes, 1);

      if Mes = MesAtual then
        // Mês atual: até o dia anterior
        DataFim := Date - 1
      else
        // Meses anteriores: até o fim do mês
        DataFim := EndOfTheMonth(DataIni);

      Data := BuscarRelatorioVenda(FormatDateTime('yyyy-mm-dd', DataIni),
        FormatDateTime('yyyy-mm-dd', DataFim));

      Data.Free;
    end;

    // Depois faz o relatório dos últimos 3 meses
    DataFim := Date;
    DataIni := IncMonth(Date, -3);

    Data := BuscarRelatorioVenda(FormatDateTime('yyyy-mm-dd', DataIni),
      FormatDateTime('yyyy-mm-dd', DataFim));
    Data.Free;

  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure RegisterAllTasks;
begin
  TTaskManager.RegisterTask('sabores', Sabores);
  TTaskManager.RegisterTask('clientes', Clientes);
  TTaskManager.RegisterTask('vendas', RelatorioVenda);
end;

end.
