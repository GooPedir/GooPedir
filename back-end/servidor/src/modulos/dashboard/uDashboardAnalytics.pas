unit uDashboardAnalytics;

interface

uses
  System.SysUtils, System.Classes, System.JSON, DateUtils, Math,
  System.Generics.Collections, Horse, conexao, FireDAC.Comp.Client, Data.DB;

procedure Registry;

implementation

const
  DASHBOARD_HISTORY_WEEKS = 12;
  DASHBOARD_MIN_HISTORY_DAYS = 2;

type
  TDashboardContext = record
    StartAt: TDateTime;
    EndAt: TDateTime;
    NowAt: TDateTime;
    CurrentHour: Integer;
  end;

  TDashboardCalendarService = class
  public
    class function Context: TDashboardContext; static;
    class procedure BindCurrentWindow(Qry: TFDQuery; const Ctx: TDashboardContext); static;
    class function HistoricalWhere(const AliasName: string): string; static;
  end;

  TDashboardJson = class
  public
    class function Obj: TJSONObject; static;
    class function Arr: TJSONArray; static;
    class procedure Num(O: TJSONObject; const Name: string; Value: Double); static;
    class procedure Int(O: TJSONObject; const Name: string; Value: Integer); static;
    class procedure Str(O: TJSONObject; const Name, Value: string); static;
    class procedure Bool(O: TJSONObject; const Name: string; Value: Boolean); static;
  end;

  TDashboardStatsService = class
  public
    class function Variation(Current, Expected: Double): Double; static;
    class function Confidence(HistoryDays: Integer; Dispersion: Double): Double; static;
  end;

  TDashboardRepository = class
  private
    FConexao: TConexao;
  public
    constructor Create;
    destructor Destroy; override;
    function Query: TFDQuery;
  end;

  TDashboardTodayService = class
  public
    class function Execute: TJSONObject; static;
  end;

  TDashboardHourlyService = class
  public
    class function Execute: TJSONArray; static;
  end;

  TDashboardChannelService = class
  public
    class function Execute: TJSONArray; static;
  end;

  TDashboardForecastService = class
  public
    class function Execute: TJSONObject; static;
  end;

  TDashboardPeakHourService = class
  public
    class function Execute: TJSONObject; static;
  end;

  TDashboardProductService = class
  public
    class function Execute: TJSONObject; static;
  end;

  TDashboardAlertService = class
  public
    class function Execute: TJSONArray; static;
  end;

  TDashboardInsightService = class
  public
    class function Execute: TJSONArray; static;
  end;

  TDashboardOpportunityService = class
  public
    class function Execute: TJSONObject; static;
  end;

  TDashboardService = class
  public
    class function Home: TJSONObject; static;
  end;

class function TDashboardCalendarService.Context: TDashboardContext;
begin
  Result.NowAt := Now;
  Result.StartAt := EncodeDateTime(YearOf(Result.NowAt), MonthOf(Result.NowAt),
    DayOf(Result.NowAt), 2, 0, 0, 0);
  if Result.NowAt < Result.StartAt then
    Result.StartAt := IncDay(Result.StartAt, -1);
  Result.EndAt := IncDay(Result.StartAt, 1);
  Result.CurrentHour := HourOf(Result.NowAt);
end;

class procedure TDashboardCalendarService.BindCurrentWindow(Qry: TFDQuery;
  const Ctx: TDashboardContext);
begin
  Qry.ParamByName('ini').AsDateTime := Ctx.StartAt;
  Qry.ParamByName('fim').AsDateTime := Ctx.EndAt;
  Qry.ParamByName('agora').AsDateTime := Ctx.NowAt;
end;

class function TDashboardCalendarService.HistoricalWhere(const AliasName: string): string;
var
  P: string;
begin
  if AliasName <> '' then
    P := AliasName + '.'
  else
    P := '';
  Result := ' ' + P + 'data_hora >= DATE_SUB(:ini, INTERVAL ' +
    IntToStr(DASHBOARD_HISTORY_WEEKS) + ' WEEK) ' +
    'AND ' + P + 'data_hora < :ini ' +
    'AND WEEKDAY(' + P + 'data_hora) = WEEKDAY(:ini) ';
end;

class function TDashboardJson.Obj: TJSONObject;
begin
  Result := TJSONObject.Create;
end;

class function TDashboardJson.Arr: TJSONArray;
begin
  Result := TJSONArray.Create;
end;

class procedure TDashboardJson.Num(O: TJSONObject; const Name: string; Value: Double);
begin
  O.AddPair(Name, TJSONNumber.Create(RoundTo(Value, -2)));
end;

class procedure TDashboardJson.Int(O: TJSONObject; const Name: string; Value: Integer);
begin
  O.AddPair(Name, TJSONNumber.Create(Value));
end;

class procedure TDashboardJson.Str(O: TJSONObject; const Name, Value: string);
begin
  O.AddPair(Name, Value);
end;

class procedure TDashboardJson.Bool(O: TJSONObject; const Name: string; Value: Boolean);
begin
  O.AddPair(Name, TJSONBool.Create(Value));
end;

class function TDashboardStatsService.Variation(Current, Expected: Double): Double;
begin
  if Abs(Expected) < 0.01 then
    Exit(0);
  Result := ((Current - Expected) / Expected) * 100;
end;

class function TDashboardStatsService.Confidence(HistoryDays: Integer;
  Dispersion: Double): Double;
begin
  Result := Min(0.95, HistoryDays / 8);
  if Dispersion > 0.35 then
    Result := Result * 0.75;
  Result := RoundTo(Max(0.1, Result), -2);
end;

constructor TDashboardRepository.Create;
begin
  inherited Create;
  FConexao := TConexao.Create('DashboardAnalytics');
end;

destructor TDashboardRepository.Destroy;
begin
  FConexao.Free;
  inherited;
end;

function TDashboardRepository.Query: TFDQuery;
begin
  Result := FConexao.CriaQRY;
end;

class function TDashboardTodayService.Execute: TJSONObject;
var
  Repo: TDashboardRepository;
  Q: TFDQuery;
  Ctx: TDashboardContext;
  Revenue, ExpectedRevenue, Orders, ExpectedOrders, AvgTicket, HistAvgTicket: Double;
  Cancels, Customers: Integer;
  CancellationPercent: Double;
begin
  Result := TDashboardJson.Obj;
  Repo := TDashboardRepository.Create;
  Q := Repo.Query;
  Ctx := TDashboardCalendarService.Context;
  try
    Q.SQL.Text :=
      'SELECT ' +
      'SUM(CASE WHEN status = 6 THEN valor_total_pedido ELSE 0 END) revenue, ' +
      'COUNT(CASE WHEN status = 6 THEN 1 END) orders_count, ' +
      'COUNT(DISTINCT CASE WHEN status = 6 AND codigo_cliente > 0 THEN codigo_cliente END) customers, ' +
      'COUNT(CASE WHEN status = 0 THEN 1 END) cancellations, ' +
      'SUM(CASE WHEN status = 6 THEN valor_desconto ELSE 0 END) discounts ' +
      'FROM pedido WHERE codigo_pedido_dia > 0 AND data_hora BETWEEN :ini AND :agora';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    Revenue := Q.FieldByName('revenue').AsFloat;
    Orders := Q.FieldByName('orders_count').AsFloat;
    Customers := Q.FieldByName('customers').AsInteger;
    Cancels := Q.FieldByName('cancellations').AsInteger;

    Q.Close;
    Q.SQL.Text :=
      'SELECT COUNT(*) history_days, AVG(day_revenue) expected_revenue, AVG(day_orders) expected_orders, AVG(avg_ticket) avg_ticket ' +
      'FROM (SELECT DATE(data_hora) d, SUM(valor_total_pedido) day_revenue, COUNT(*) day_orders, AVG(valor_total_pedido) avg_ticket ' +
      'FROM pedido WHERE codigo_pedido_dia > 0 AND status = 6 AND ' +
      TDashboardCalendarService.HistoricalWhere('') +
      'AND TIME(data_hora) <= TIME(:agora) GROUP BY DATE(data_hora)) x';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    ExpectedRevenue := Q.FieldByName('expected_revenue').AsFloat;
    ExpectedOrders := Q.FieldByName('expected_orders').AsFloat;
    HistAvgTicket := Q.FieldByName('avg_ticket').AsFloat;

    if Orders > 0 then AvgTicket := Revenue / Orders else AvgTicket := 0;
    if (Orders + Cancels) > 0 then CancellationPercent := Cancels / (Orders + Cancels) * 100 else CancellationPercent := 0;

    TDashboardJson.Str(Result, 'generatedAt', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Ctx.NowAt));
    Result.AddPair('revenue', TDashboardJson.Obj);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('revenue'), 'current', Revenue);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('revenue'), 'expectedUntilNow', ExpectedRevenue);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('revenue'), 'variationPercent', TDashboardStatsService.Variation(Revenue, ExpectedRevenue));
    Result.AddPair('orders', TDashboardJson.Obj);
    TDashboardJson.Int(Result.GetValue<TJSONObject>('orders'), 'current', Trunc(Orders));
    TDashboardJson.Num(Result.GetValue<TJSONObject>('orders'), 'expectedUntilNow', ExpectedOrders);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('orders'), 'variationPercent', TDashboardStatsService.Variation(Orders, ExpectedOrders));
    Result.AddPair('averageTicket', TDashboardJson.Obj);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('averageTicket'), 'current', AvgTicket);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('averageTicket'), 'historical', HistAvgTicket);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('averageTicket'), 'variationPercent', TDashboardStatsService.Variation(AvgTicket, HistAvgTicket));
    Result.AddPair('cancellations', TDashboardJson.Obj);
    TDashboardJson.Int(Result.GetValue<TJSONObject>('cancellations'), 'count', Cancels);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('cancellations'), 'percent', CancellationPercent);
    TDashboardJson.Int(Result, 'customers', Customers);
  finally
    Q.Free;
    Repo.Free;
  end;
end;

class function TDashboardHourlyService.Execute: TJSONArray;
var
  Repo: TDashboardRepository;
  Q: TFDQuery;
  Ctx: TDashboardContext;
  ByHour: TObjectDictionary<Integer,TJSONObject>;
  Obj: TJSONObject;
  H: Integer;
begin
  Result := TDashboardJson.Arr;
  ByHour := TObjectDictionary<Integer,TJSONObject>.Create([]);
  Repo := TDashboardRepository.Create;
  Q := Repo.Query;
  Ctx := TDashboardCalendarService.Context;
  try
    Q.SQL.Text :=
      'SELECT HOUR(data_hora) h, COUNT(*) orders_count, SUM(valor_total_pedido) revenue ' +
      'FROM pedido WHERE codigo_pedido_dia > 0 AND status = 6 AND data_hora BETWEEN :ini AND :agora GROUP BY HOUR(data_hora)';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    while not Q.Eof do
    begin
      Obj := TDashboardJson.Obj;
      TDashboardJson.Int(Obj, 'orders', Q.FieldByName('orders_count').AsInteger);
      TDashboardJson.Num(Obj, 'revenue', Q.FieldByName('revenue').AsFloat);
      ByHour.AddOrSetValue(Q.FieldByName('h').AsInteger, Obj);
      Q.Next;
    end;

    Q.Close;
    Q.SQL.Text :=
      'SELECT h, AVG(orders_count) expected_orders, AVG(revenue) expected_revenue FROM (' +
      'SELECT DATE(data_hora) d, HOUR(data_hora) h, COUNT(*) orders_count, SUM(valor_total_pedido) revenue ' +
      'FROM pedido WHERE codigo_pedido_dia > 0 AND status = 6 AND ' +
      TDashboardCalendarService.HistoricalWhere('') +
      'GROUP BY DATE(data_hora), HOUR(data_hora)) x GROUP BY h';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    while not Q.Eof do
    begin
      H := Q.FieldByName('h').AsInteger;
      if not ByHour.TryGetValue(H, Obj) then
      begin
        Obj := TDashboardJson.Obj;
        TDashboardJson.Int(Obj, 'orders', 0);
        TDashboardJson.Num(Obj, 'revenue', 0);
        ByHour.Add(H, Obj);
      end;
      TDashboardJson.Num(Obj, 'expectedOrders', Q.FieldByName('expected_orders').AsFloat);
      TDashboardJson.Num(Obj, 'expectedRevenue', Q.FieldByName('expected_revenue').AsFloat);
      Q.Next;
    end;

    for H := 0 to 23 do
      if ByHour.TryGetValue(H, Obj) then
      begin
        Obj.AddPair('hour', Format('%.2d:00', [H]));
        Result.AddElement(Obj);
      end;
  finally
    Q.Free;
    Repo.Free;
    ByHour.Free;
  end;
end;

class function TDashboardChannelService.Execute: TJSONArray;
var
  Repo: TDashboardRepository;
  Q: TFDQuery;
  Ctx: TDashboardContext;
  TotalRevenue: Double;
  Item: TJSONObject;
begin
  Result := TDashboardJson.Arr;
  Repo := TDashboardRepository.Create;
  Q := Repo.Query;
  Ctx := TDashboardCalendarService.Context;
  try
    Q.SQL.Text :=
      'SELECT SUM(valor_total_pedido) total_revenue FROM pedido WHERE codigo_pedido_dia > 0 AND status = 6 AND data_hora BETWEEN :ini AND :agora';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    TotalRevenue := Q.FieldByName('total_revenue').AsFloat;

    Q.Close;
    Q.SQL.Text :=
      'SELECT CASE WHEN IFNULL(id_ficha,0) > 0 THEN ''table'' WHEN IFNULL(codigo_cliente_endereco,0) > 0 THEN ''delivery'' ELSE ''pickup'' END channel, ' +
      'COUNT(*) orders_count, SUM(valor_total_pedido) revenue, AVG(valor_total_pedido) avg_ticket ' +
      'FROM pedido WHERE codigo_pedido_dia > 0 AND status = 6 AND data_hora BETWEEN :ini AND :agora GROUP BY channel';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    while not Q.Eof do
    begin
      Item := TDashboardJson.Obj;
      TDashboardJson.Str(Item, 'channel', Q.FieldByName('channel').AsString);
      TDashboardJson.Int(Item, 'orders', Q.FieldByName('orders_count').AsInteger);
      TDashboardJson.Num(Item, 'revenue', Q.FieldByName('revenue').AsFloat);
      TDashboardJson.Num(Item, 'averageTicket', Q.FieldByName('avg_ticket').AsFloat);
      if TotalRevenue > 0 then
        TDashboardJson.Num(Item, 'sharePercent', Q.FieldByName('revenue').AsFloat / TotalRevenue * 100)
      else
        TDashboardJson.Num(Item, 'sharePercent', 0);
      Result.AddElement(Item);
      Q.Next;
    end;
  finally
    Q.Free;
    Repo.Free;
  end;
end;

class function TDashboardForecastService.Execute: TJSONObject;
var
  Repo: TDashboardRepository;
  Q: TFDQuery;
  Ctx: TDashboardContext;
  CurrentRevenue, CurrentOrders, HistUntilNow, HistTotal, HistOrders, PercentDone: Double;
  HistoryDays: Integer;
  EstimatedRevenue, EstimatedOrders: Double;
begin
  Result := TDashboardJson.Obj;
  Repo := TDashboardRepository.Create;
  Q := Repo.Query;
  Ctx := TDashboardCalendarService.Context;
  try
    Q.SQL.Text :=
      'SELECT SUM(valor_total_pedido) revenue, COUNT(*) orders_count FROM pedido ' +
      'WHERE codigo_pedido_dia > 0 AND status = 6 AND data_hora BETWEEN :ini AND :agora';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    CurrentRevenue := Q.FieldByName('revenue').AsFloat;
    CurrentOrders := Q.FieldByName('orders_count').AsFloat;

    Q.Close;
    Q.SQL.Text :=
      'SELECT COUNT(*) history_days, AVG(until_now) hist_until_now, AVG(total_day) hist_total, AVG(orders_day) hist_orders FROM (' +
      'SELECT DATE(data_hora) d, SUM(CASE WHEN TIME(data_hora) <= TIME(:agora) THEN valor_total_pedido ELSE 0 END) until_now, ' +
      'SUM(valor_total_pedido) total_day, COUNT(*) orders_day FROM pedido ' +
      'WHERE codigo_pedido_dia > 0 AND status = 6 AND ' +
      TDashboardCalendarService.HistoricalWhere('') +
      'GROUP BY DATE(data_hora)) x';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    HistoryDays := Q.FieldByName('history_days').AsInteger;
    HistUntilNow := Q.FieldByName('hist_until_now').AsFloat;
    HistTotal := Q.FieldByName('hist_total').AsFloat;
    HistOrders := Q.FieldByName('hist_orders').AsFloat;

    if HistoryDays < DASHBOARD_MIN_HISTORY_DAYS then
    begin
      TDashboardJson.Bool(Result, 'available', False);
      TDashboardJson.Str(Result, 'reason', 'INSUFFICIENT_HISTORY');
      Exit;
    end;

    if HistTotal > 0 then PercentDone := HistUntilNow / HistTotal else PercentDone := 0;
    if PercentDone > 0.05 then
      EstimatedRevenue := ((CurrentRevenue / PercentDone) + HistTotal) / 2
    else
      EstimatedRevenue := HistTotal;
    if (HistUntilNow > 0) and (HistTotal > 0) then
      EstimatedOrders := ((CurrentOrders / (HistUntilNow / HistTotal)) + HistOrders) / 2
    else
      EstimatedOrders := HistOrders;

    TDashboardJson.Bool(Result, 'available', True);
    Result.AddPair('revenue', TDashboardJson.Obj);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('revenue'), 'estimated', EstimatedRevenue);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('revenue'), 'minimum', EstimatedRevenue * 0.92);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('revenue'), 'maximum', EstimatedRevenue * 1.08);
    Result.AddPair('orders', TDashboardJson.Obj);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('orders'), 'estimated', EstimatedOrders);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('orders'), 'minimum', EstimatedOrders * 0.92);
    TDashboardJson.Num(Result.GetValue<TJSONObject>('orders'), 'maximum', EstimatedOrders * 1.08);
    Result.AddPair('averageTicket', TDashboardJson.Obj);
    if EstimatedOrders > 0 then
      TDashboardJson.Num(Result.GetValue<TJSONObject>('averageTicket'), 'estimated', EstimatedRevenue / EstimatedOrders)
    else
      TDashboardJson.Num(Result.GetValue<TJSONObject>('averageTicket'), 'estimated', 0);
    TDashboardJson.Num(Result, 'confidence', TDashboardStatsService.Confidence(HistoryDays, 0.15));
    TDashboardJson.Str(Result, 'method', 'weighted_weekday_history_plus_current_day_pace');
  finally
    Q.Free;
    Repo.Free;
  end;
end;

class function TDashboardPeakHourService.Execute: TJSONObject;
var
  Hourly: TJSONArray;
  I: Integer;
  Item, Best: TJSONObject;
  BestOrders, Orders: Double;
begin
  Result := TDashboardJson.Obj;
  Hourly := TDashboardHourlyService.Execute;
  Best := nil;
  BestOrders := -1;
  for I := 0 to Hourly.Count - 1 do
  begin
    Item := Hourly.Items[I] as TJSONObject;
    Orders := StrToFloatDef(Item.GetValue('expectedOrders').Value, 0);
    if Orders > BestOrders then
    begin
      BestOrders := Orders;
      Best := Item;
    end;
  end;
  Result.AddPair('overall', TDashboardJson.Obj);
  if Assigned(Best) then
  begin
    TDashboardJson.Str(Result.GetValue<TJSONObject>('overall'), 'start', Best.GetValue('hour').Value);
    TDashboardJson.Str(Result.GetValue<TJSONObject>('overall'), 'end', Format('%.2d:00', [(StrToIntDef(Copy(Best.GetValue('hour').Value, 1, 2), 0) + 1) mod 24]));
    TDashboardJson.Num(Result.GetValue<TJSONObject>('overall'), 'expectedOrders', BestOrders);
  end;
  Result.AddPair('channels', TJSONArray.Create);
  Hourly.Free;
end;

class function TDashboardProductService.Execute: TJSONObject;
var
  Repo: TDashboardRepository;
  Q: TFDQuery;
  Ctx: TDashboardContext;
  Arr: TJSONArray;
  Item: TJSONObject;
begin
  Result := TDashboardJson.Obj;
  Repo := TDashboardRepository.Create;
  Q := Repo.Query;
  Ctx := TDashboardCalendarService.Context;
  try
    Arr := TDashboardJson.Arr;
    Q.SQL.Text :=
      'SELECT pro.codigo product_id, pro.nome_produto name, SUM(pp.quantidade) quantity, SUM(pp.valor_total) revenue ' +
      'FROM pedido p JOIN pedido_produtos pp ON pp.codigo_pedido = p.codigo JOIN produto pro ON pro.codigo = pp.codigo_produto ' +
      'WHERE p.codigo_pedido_dia > 0 AND p.status = 6 AND p.data_hora BETWEEN :ini AND :agora ' +
      'GROUP BY pro.codigo, pro.nome_produto ORDER BY SUM(pp.quantidade) DESC LIMIT 10';
    TDashboardCalendarService.BindCurrentWindow(Q, Ctx);
    Q.Open;
    while not Q.Eof do
    begin
      Item := TDashboardJson.Obj;
      TDashboardJson.Int(Item, 'productId', Q.FieldByName('product_id').AsInteger);
      TDashboardJson.Str(Item, 'name', Q.FieldByName('name').AsString);
      TDashboardJson.Num(Item, 'quantity', Q.FieldByName('quantity').AsFloat);
      TDashboardJson.Num(Item, 'revenue', Q.FieldByName('revenue').AsFloat);
      Arr.AddElement(Item);
      Q.Next;
    end;
    Result.AddPair('topToday', Arr);
    Result.AddPair('expectedToday', TJSONArray.Create);
    Result.AddPair('aboveExpected', TJSONArray.Create);
    Result.AddPair('belowExpected', TJSONArray.Create);
  finally
    Q.Free;
    Repo.Free;
  end;
end;

class function TDashboardAlertService.Execute: TJSONArray;
var
  Today, Revenue: TJSONObject;
  Variation: Double;
  Alert: TJSONObject;
begin
  Result := TDashboardJson.Arr;
  Today := TDashboardTodayService.Execute;
  try
    Revenue := Today.GetValue<TJSONObject>('revenue');
    Variation := StrToFloatDef(Revenue.GetValue('variationPercent').Value, 0);
    if Abs(Variation) >= 12 then
    begin
      Alert := TDashboardJson.Obj;
      if Variation > 0 then
      begin
        TDashboardJson.Str(Alert, 'type', 'positive');
        TDashboardJson.Str(Alert, 'code', 'REVENUE_ABOVE_EXPECTED');
        TDashboardJson.Str(Alert, 'title', 'Faturamento acima do esperado');
      end
      else
      begin
        TDashboardJson.Str(Alert, 'type', 'warning');
        TDashboardJson.Str(Alert, 'code', 'REVENUE_BELOW_EXPECTED');
        TDashboardJson.Str(Alert, 'title', 'Faturamento abaixo do esperado');
      end;
      TDashboardJson.Str(Alert, 'category', 'revenue');
      TDashboardJson.Str(Alert, 'message', Format('Faturamento esta %.2f%% em relacao ao esperado para este horario.', [Variation]));
      TDashboardJson.Num(Alert, 'variationPercent', Variation);
      Result.AddElement(Alert);
    end;
  finally
    Today.Free;
  end;
end;

class function TDashboardInsightService.Execute: TJSONArray;
var
  Alerts: TJSONArray;
  I: Integer;
  Insight, Alert: TJSONObject;
begin
  Result := TDashboardJson.Arr;
  Alerts := TDashboardAlertService.Execute;
  try
    for I := 0 to Min(Alerts.Count, 5) - 1 do
    begin
      Alert := Alerts.Items[I] as TJSONObject;
      Insight := TDashboardJson.Obj;
      TDashboardJson.Str(Insight, 'type', 'performance');
      TDashboardJson.Int(Insight, 'priority', 80 - I);
      TDashboardJson.Str(Insight, 'title', Alert.GetValue('title').Value);
      TDashboardJson.Str(Insight, 'message', Alert.GetValue('message').Value);
      Insight.AddPair('metadata', TJSONObject.Create);
      Result.AddElement(Insight);
    end;
  finally
    Alerts.Free;
  end;
end;

class function TDashboardOpportunityService.Execute: TJSONObject;
begin
  Result := TDashboardJson.Obj;
  TDashboardJson.Bool(Result, 'available', False);
  TDashboardJson.Str(Result, 'reason', 'OPPORTUNITIES_REQUIRE_DEEPER_PRODUCT_PAIR_AND_CUSTOMER_ANALYSIS');
  Result.AddPair('items', TJSONArray.Create);
end;

class function TDashboardService.Home: TJSONObject;
begin
  Result := TDashboardJson.Obj;
  TDashboardJson.Str(Result, 'generatedAt', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
  Result.AddPair('today', TDashboardTodayService.Execute);
  Result.AddPair('forecast', TDashboardForecastService.Execute);
  Result.AddPair('peakHours', TDashboardPeakHourService.Execute);
  Result.AddPair('hourly', TDashboardHourlyService.Execute);
  Result.AddPair('channels', TDashboardChannelService.Execute);
  Result.AddPair('products', TDashboardProductService.Execute);
  Result.AddPair('alerts', TDashboardAlertService.Execute);
  Result.AddPair('insights', TDashboardInsightService.Execute);
  Result.AddPair('opportunities', TDashboardOpportunityService.Execute);
end;

procedure SendJson(Res: THorseResponse; Value: TJSONValue);
begin
  Res.Send<TJSONValue>(Value);
end;

procedure GetToday(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardTodayService.Execute);
end;

procedure GetHourly(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardHourlyService.Execute);
end;

procedure GetChannels(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardChannelService.Execute);
end;

procedure GetForecast(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardForecastService.Execute);
end;

procedure GetPeakHours(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardPeakHourService.Execute);
end;

procedure GetProducts(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardProductService.Execute);
end;

procedure GetAlerts(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardAlertService.Execute);
end;

procedure GetInsights(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardInsightService.Execute);
end;

procedure GetOpportunities(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardOpportunityService.Execute);
end;

procedure GetHome(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  SendJson(Res, TDashboardService.Home);
end;

procedure Registry;
begin
  THorse.Get('/dashboard/today', GetToday);
  THorse.Get('/dashboard/hourly', GetHourly);
  THorse.Get('/dashboard/channels', GetChannels);
  THorse.Get('/dashboard/forecast', GetForecast);
  THorse.Get('/dashboard/peak-hours', GetPeakHours);
  THorse.Get('/dashboard/products', GetProducts);
  THorse.Get('/dashboard/alerts', GetAlerts);
  THorse.Get('/dashboard/insights', GetInsights);
  THorse.Get('/dashboard/opportunities', GetOpportunities);
  THorse.Get('/dashboard/home', GetHome);
end;

end.
