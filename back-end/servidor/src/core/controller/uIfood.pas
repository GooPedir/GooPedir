unit uIfood;

interface

uses
  conexao, DataSet.Serialize, FireDAC.Comp.Client, Vcl.Dialogs, System.SysUtils,
  IdHTTP, IdSSLOpenSSL, FireDAC.Stan.Error,
  System.IniFiles, ADRIFood.Model.Interfaces, ADRIFood.Model.Types,
  ADRIFood.Component.Events, ADRIFood.Component, uProcessamentoiFood,
  uRequisicao, JOSE.Types.JSON, uFrmCore;

type
  TIfood = class
  private
    procedure IFoodLogRequest(ARequestId, AContent: string);
    procedure IFoodLogResponse(ARequestId, AContent: string;
      AStatusCode: Integer);
    procedure IFoodMerchantStatus
      (Status: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelMerchantStatus>);
    procedure IFoodMerchantStatusError(AError: Exception);
    procedure IFoodOrderArrivedAtOrigin(OrderHead: IADRIFoodModelOrderHead;
      var bAcknowledgment: Boolean);
    procedure IFoodPollingEnd(EndPooling: TDateTime;
      OrdersHead: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelOrderHead>);
    procedure IFoodPollingError(Error: Exception);
    procedure IFoodPollingStart(StartPolling: TDateTime);
    procedure IFoodRefreshTokenSave1(RefreshToken: string);
    procedure IFoodRefreshTokenSave2(RefreshToken: string);
    function IFoodRefreshTokenGet1: string;
    function IFoodRefreshTokenGet2: string;

    function GetToken(Numero: Integer): String;
    procedure SaveToken(Numero: Integer; RefreshToken: string);
    procedure IFoodOrderPlaced1(Order: IADRIFoodModelOrder;
      OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
    procedure IFoodOrderPlaced2(Order: IADRIFoodModelOrder;
      OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);

  var
    conexao: TConexao;
    ProcessamentoiFood1: TProcessamentoiFood;
    ProcessamentoiFood2: TProcessamentoiFood;
    ClientId: String;
    ClientSecret: String;
  public
    procedure Iniciar(Name, MerchantID: String);
    procedure AtualizaStatus(OrderHead: IADRIFoodModelOrderHead);
    procedure Create;
  end;

implementation

{ TIfood }

procedure TIfood.AtualizaStatus(OrderHead: IADRIFoodModelOrderHead);
var
  conexao: TConexao;
  SQL: String;
  statuscod: String;
  Status: String;
  IFood: String;
  Codigo, CodigoIntermo: Integer;
  imprimir: Integer;
begin

  statuscod := OrderHead.code;
  Status := OrderHead.fullCode;
  IFood := OrderHead.orderId;

  if OrderHead.code = 'CAN' then
  begin
    SQL := 'update pedido set status = 0, desc_desconto_ifood = motivo_cancelamento, status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
  end
  else
  begin
    if OrderHead.code = 'CAR' then
    begin
      SQL := 'update pedido set desc_desconto_ifood = "CANCELADO PELO GESTO", motivo_cancelamento = "CANCELADO PELO GESTO", status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
    end;

    SQL := 'update pedido set status_ifood = :status_ifood, status_ifood_descricao = :status_ifood_descricao where id_ifood = :id_ifood';
  end;
  conexao := TConexao.Create('main');
  conexao.SQL.Add(SQL);
  conexao.Parametros('id_ifood', IFood);
  conexao.Parametros('status_ifood', statuscod);
  conexao.Parametros('status_ifood_descricao', Status);
  conexao.ExecuteSQL;

  if OrderHead.code = 'CFM' then
  begin
    conexao.SQL.Add
      ('SELECT codigo, 0 as zero FROM pedido where id_ifood = :codigo');
    conexao.Parametros('codigo', IFood);
    CodigoIntermo := conexao.FieldByName('codigo');

    if CodigoIntermo > 0 then
    begin

      conexao.SQL.Add
        ('select * from impressao_pedido where id_pedido = :pedido');
      conexao.Parametros('pedido', CodigoIntermo);
      try
        imprimir := conexao.FieldByName('id');
      except
        imprimir := 0;
      end;
      // Imprimir

      if imprimir = 0 then
      begin
        Codigo := conexao.GerarID('impressao_pedido', 'id');
        conexao.SQL.Add
          ('insert into impressao_pedido (id,data_solicitacao,hora_solicitacao,id_pedido,status,vias) values (:id,current_date(),current_time(),:pedido,0,0)');
        conexao.Parametros('id', Codigo);
        conexao.Parametros('pedido', CodigoIntermo);
        conexao.ExecuteSQL;
      end;

      conexao.SQL.Add('UPDATE impressao_pedido_produto');
      conexao.SQL.Add('SET status = 0');
      conexao.SQL.Add('WHERE data_impressao IS NULL');
      conexao.SQL.Add
        ('AND id_pedido IN (SELECT codigo FROM pedido_produtos WHERE pedido_produtos.codigo_pedido = :pedido)');
      conexao.Parametros('pedido', CodigoIntermo);
      conexao.ExecuteSQL;
    end;
  end;

  conexao.Free;

end;

procedure TIfood.Create;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  ClientId := IniFile.ReadString('IFOOD', 'CLIENTID', '');
  ClientSecret := IniFile.ReadString('IFOOD', 'CLIENTSECRET', '');
  IniFile.Free;
end;

function TIfood.GetToken(Numero: Integer): String;
var
  conexao: TConexao;
begin

  conexao := TConexao.Create('IFoodRefreshTokenGet');
  conexao.SQL.Add('select * from ifood_connect where id = :id');
  conexao.Parametros('id', Numero);
  try
    Result := conexao.FieldByName('token');
  except
    Result := '';
  end;
  conexao.Free;

end;

procedure TIfood.IFoodLogRequest(ARequestId, AContent: string);

var
  arq: TextFile;
  Requisicao: iRequisicao;
  JSON: TJsonObject;
begin
  

end;

procedure TIfood.IFoodLogResponse(ARequestId, AContent: string;
  AStatusCode: Integer);
begin
  //
end;

procedure TIfood.IFoodMerchantStatus
  (Status: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelMerchantStatus>);
begin
  //
end;

procedure TIfood.IFoodMerchantStatusError(AError: Exception);
var
  arq: TextFile;
  Requisicao: iRequisicao;
  JSON: TJsonObject;
  a: String;
begin
  

end;

procedure TIfood.IFoodOrderArrivedAtOrigin(OrderHead: IADRIFoodModelOrderHead;
  var bAcknowledgment: Boolean);
begin
  bAcknowledgment := True;
  AtualizaStatus(OrderHead);
end;

procedure TIfood.IFoodOrderPlaced1(Order: IADRIFoodModelOrder;
  OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin
  bAcknowledgment := True;
  ProcessamentoiFood1.orderId(Order, OrderHead);

end;

procedure TIfood.IFoodOrderPlaced2(Order: IADRIFoodModelOrder;
  OrderHead: IADRIFoodModelOrderHead; var bAcknowledgment: Boolean);
begin
  bAcknowledgment := True;
  ProcessamentoiFood2.orderId(Order, OrderHead);

end;

procedure TIfood.IFoodPollingEnd(EndPooling: TDateTime;
  OrdersHead: TArray<ADRIFood.Model.Interfaces.IADRIFoodModelOrderHead>);
begin

end;

procedure TIfood.IFoodPollingError(Error: Exception);
begin

end;

procedure TIfood.IFoodPollingStart(StartPolling: TDateTime);
begin

end;

function TIfood.IFoodRefreshTokenGet1: string;
begin
  Result := GetToken(1);
end;

function TIfood.IFoodRefreshTokenGet2: string;
begin
  Result := GetToken(2);
end;

procedure TIfood.IFoodRefreshTokenSave1(RefreshToken: string);
begin
  SaveToken(1, RefreshToken);
end;

procedure TIfood.IFoodRefreshTokenSave2(RefreshToken: string);
begin
  SaveToken(2, RefreshToken);
end;

procedure TIfood.Iniciar(Name, MerchantID: String);
var
  NewIfood: TADRIFood;
  Processamento: TProcessamentoiFood;
begin
  conexao := TConexao.Create('ifood');
  NewIfood := TADRIFood.Create(nil);
  NewIfood.Name := 'IFOOD' + Name;
  NewIfood.Tag := StrToInt(Name);

  NewIfood.SoftwareHouse.Id := '09071157997';
  NewIfood.OnLogRequest := IFoodLogRequest;
  NewIfood.OnLogResponse := IFoodLogResponse;
  NewIfood.OnMerchantStatus := IFoodMerchantStatus;
  NewIfood.OnMerchantStatusError := IFoodMerchantStatusError;
  NewIfood.OnOrderArrivedAtOrigin := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderAssignDriver := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderBoxAssigned := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderCancellationFailed := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderCancellationRequested := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderCancelled := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderChangePreparationTime := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderCollected := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderConcluded := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderConfirmed := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderConsumerCancellationRequested := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderConsumerCancellationAccepted := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderConsumerCancellationDenied := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderDelayNotification := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderDelivered := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderDispatched := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderGoingToOrigin := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderIntegrated := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderPickupAreaAssigned := IFoodOrderArrivedAtOrigin;

  NewIfood.OnOrderPreparationStarted := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderReadyToDeliver := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderReadyToPickup := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderRecommendedPreparation := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderRequestDriver := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderRequestDriverAvailability := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderRequestDriverFailed := IFoodOrderArrivedAtOrigin;
  NewIfood.OnOrderRequestDriverSuccess := IFoodOrderArrivedAtOrigin;
  NewIfood.OnPollingEnd := IFoodPollingEnd;
  NewIfood.OnPollingError := IFoodPollingError;
  NewIfood.OnPollingStart := IFoodPollingStart;
  if StrToInt(Name) = 1 then
  begin
    NewIfood.OnRefreshTokenSave := IFoodRefreshTokenSave1;
    NewIfood.OnRefreshTokenGet := IFoodRefreshTokenGet1;
    NewIfood.OnOrderPlaced := IFoodOrderPlaced1;

  end;
  if StrToInt(Name) = 2 then
  begin
    NewIfood.OnRefreshTokenSave := IFoodRefreshTokenSave2;
    NewIfood.OnRefreshTokenGet := IFoodRefreshTokenGet2;
    NewIfood.OnOrderPlaced := IFoodOrderPlaced2;

  end;

  NewIfood.Credentials.ClientId := ClientId;
  NewIfood.Credentials.ClientSecret := ClientSecret;
  if (ClientId = '1a5799db-d82c-4a5d-a003-36247fe18176') then
  begin
    NewIfood.Credentials.AuthorizationType := ctCentralized;
  end
  else
  begin
    NewIfood.Credentials.AuthorizationType := ctDistributed;
  end;

  if (MerchantID <> '') then
  begin
    try
      NewIfood.MerchantStatus.AutoStatus := True;
      NewIfood.Polling.AutoPolling := True;
      NewIfood.MerchantID(MerchantID);

      if StrToInt(Name) = 1 then
      begin
        ProcessamentoiFood1 := TProcessamentoiFood.Create;
        ProcessamentoiFood1.IFood := NewIfood;
        ProcessamentoiFood1.statusiFood := frmCore.Configuracoes.FieldByName
          ('aceitar_pedidos_ifood').AsInteger;
        ProcessamentoiFood1.Start;
        NewIfood.MerchantStatus.DataSource := frmCore.dsMerchants1;

      end;
      if StrToInt(Name) = 2 then
      begin
        ProcessamentoiFood2 := TProcessamentoiFood.Create;
        ProcessamentoiFood2.IFood := NewIfood;
        ProcessamentoiFood2.statusiFood := frmCore.Configuracoes.FieldByName
          ('aceitar_pedidos_ifood').AsInteger;
        ProcessamentoiFood2.Start;
        NewIfood.MerchantStatus.DataSource := frmCore.dsMerchants2;
      end;

    except
      on E: Exception do
      begin
        // ////ShowMessage1(E.Message);

      end;

    end;

  end;
  conexao.Free;
end;

procedure TIfood.SaveToken(Numero: Integer; RefreshToken: string);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('SaveToken');
  conexao.SQL.Add('update ifood_connect set token = :token where id = :id');
  conexao.Parametros('id', Numero);
  conexao.Parametros('token', RefreshToken);
  conexao.ExecuteSQL;
  conexao.Free;
end;

end.
