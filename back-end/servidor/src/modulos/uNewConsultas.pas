unit uNewConsultas;

interface

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, Horse.JWT, uDM,
  FireDAC.Comp.Client, Dataset.Serialize, JSON, token.autorizacao,
  Data.FireDACJSONReflect, Soap.EncdDecd, FMX.Graphics, FMX.Printer,
  uRequisicao, System.RegularExpressions, DateUtils, PedidoSite,
  System.Threading, uControllCaches, uLogThread, System.Generics.Collections;

function CriaSubQuery(SQL, Campo, DataInicial, DataFinal: String): String;
function GerarArrayMesesAno(const DataInicial, DataFinal: TDateTime)
  : TArray<string>;

function CriaSubQueryCampos(SQL, Campos, DataInicial,
  DataFinal: String): String;

implementation

function CriaSubQuery(SQL, Campo, DataInicial, DataFinal: String): String;
var
  MesesAno: TArray<string>;
  formatSettings: TFormatSettings;
  MesAno: String;
  SQLLocal: String;
begin
  formatSettings := TFormatSettings.Create;
  formatSettings.ShortDateFormat := 'yyyy-mm-dd'; // Define o formato esperado
  formatSettings.DateSeparator := '-'; // Define o separador

  MesesAno := GerarArrayMesesAno(StrToDate(DataInicial, formatSettings),
    StrToDate(DataFinal, formatSettings));

  Result := 'SELECT SUM(' + Campo + ') AS quantidade, 0 AS zero';
  Result := Result + ' FROM (';

  Result := Result + ' ' + SQL;

  for MesAno in MesesAno do
  begin
    Result := Result + ' UNION ALL ';
    SQLLocal := SQL;
    SQLLocal := StringReplace(SQLLocal, 'from pedido',
      'from pedido_' + MesAno, []);
    Result := Result + SQLLocal;
  end;

  Result := Result + ' ) AS subquery;';

end;

function GerarArrayMesesAno(const DataInicial, DataFinal: TDateTime)
  : TArray<string>;
var
  DataAtual, DataAtualSemDia: TDateTime;
  AnoMes, AnoMesAtual: string;
  ListaMesesAno: TList<string>;
begin
  ListaMesesAno := TList<string>.Create;
  try
    DataAtual := StartOfTheMonth(DataInicial);
    // Começa no primeiro dia do mês da data inicial
    DataAtualSemDia := StartOfTheMonth(now);
    // Obtém o primeiro dia do mês atual

    while DataAtual <= DataFinal do
    begin
      AnoMes := FormatDateTime('yyyy_mm', DataAtual);
      // Formata a data como 'yyyy_mm'
      AnoMesAtual := FormatDateTime('yyyy_mm', DataAtualSemDia);
      // Formata o mês/ano atual

      // Adiciona ao array apenas se não for o mês/ano atual e não estiver duplicado
      if (AnoMes <> AnoMesAtual) and (not ListaMesesAno.Contains(AnoMes)) then
        ListaMesesAno.Add(AnoMes);

      DataAtual := IncMonth(DataAtual, 1); // Avança para o próximo mês
    end;

    Result := ListaMesesAno.ToArray; // Converte a lista para um array
  finally
    ListaMesesAno.Free;
  end;
end;

function CriaSubQueryCampos(SQL, Campos, DataInicial,
  DataFinal: String): String;
var
  MesesAno: TArray<string>;
  formatSettings: TFormatSettings;
  MesAno: String;
  SQLLocal: String;
begin
  formatSettings := TFormatSettings.Create;
  formatSettings.ShortDateFormat := 'yyyy-mm-dd'; // Define o formato esperado
  formatSettings.DateSeparator := '-'; // Define o separador

  MesesAno := GerarArrayMesesAno(StrToDate(DataInicial, formatSettings),
    StrToDate(DataFinal, formatSettings));

  Result := 'SELECT ' + Campos;
  Result := Result + ' FROM (';

  Result := Result + ' ' + SQL;

  for MesAno in MesesAno do
  begin
    Result := Result + ' UNION ALL ';
    SQLLocal := SQL;
    SQLLocal := StringReplace(SQLLocal, 'from pedido ', 'from pedido_' + MesAno
      + ' ', [rfReplaceAll]);
    SQLLocal := StringReplace(SQLLocal, 'join pedido_produtos ','join pedido_produtos_' + MesAno + ' ', [rfReplaceAll]);
    SQLLocal := StringReplace(SQLLocal, 'from pedido_produtos ','from pedido_produtos_' + MesAno + ' ', [rfReplaceAll]);
    Result := Result + SQLLocal;
  end;

  Result := Result + ' ) AS subquery';

end;

end.
