unit uClassEnviaMensagem;

interface

uses System.Classes, System.SysUtils, IniFiles,
  XSuperObject, uRequisicao, FireDAC.Comp.Client;

type

  TWppThreed = class(TThread)
  private
    FRequest: iRequisicao;
    FUserId: Integer;
    FClientID: String;
    FClientSecurity: String;
    FToken: String;
    function getUser: Integer;
    procedure SetUserId(const Value: Integer);
    procedure SetClientID(const Value: String);
    procedure SetClientSecurity(const Value: String);
    procedure SetToken(const Value: String);

    function GetClientID: String;
    function GetClientSecurity: String;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    function InserirUpdate(Tabela, User: String;
      ArrayCampos, ArrayValores: Array of String): Integer;
    procedure AtualizaCelular(Telefone: String);

    property UserId: Integer read FUserId write SetUserId;
    property ClientID: String read GetClientID;
    property ClientSecurity: String read GetClientSecurity;
    property Token: String read FToken write SetToken;
  end;

  TEnviaMensagemThreed = class(TThread)
  private
    FQRY: TFDQuery;
    ArquivoINI: TIniFile;
    Index: Integer;
    FQryAtualiza: TFDQuery;
    FAguardar: Boolean;
    procedure SetAguardar(const Value: Boolean);
  protected
    procedure Execute; override;

    function BuscaResumo(Codigo, CodigoEndereco: Integer): String;

    procedure GravaTest(Texto: String);
  public
    constructor Create;
    destructor Destroy; override;

    property Aguardar: Boolean read FAguardar write SetAguardar;
  end;

  TEnviaMensagem = class
  private
    function BuscaResumo(Codigo, CodigoEndereco: Integer): String;
  public
    procedure Enviar;
  end;

const
  URL_SITE = 'api.papaleguasfood.com.br/';

implementation

{ TEnviaMensagemThreed }

uses uPrincipal, uDM, uClassFinalizarPedido, uBotConversa, Vcl.Forms,
  udmProdutos;

function TEnviaMensagemThreed.BuscaResumo(Codigo, CodigoEndereco
  : Integer): String;
var
  Produtos: String;
  Finaliza: TFinalizarPedido;
  Conversa: TBotConversa;
begin
  Result := '';
  exit;
  try

    Conversa := TBotConversa.Create(nil);
    Conversa.CodigoEndereco := CodigoEndereco;

    Finaliza := TFinalizarPedido.Create;
    Produtos := Finaliza.ProdutosResumo(Codigo, Conversa);
    Finaliza.Free;
    Conversa.Free;
    if Produtos <> '' then
    begin
      Result := '*--- RESUMO DO PEDIDO ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
      Result := Result + '*QTD - DESCRICAO*' + MENSAGEM_QUEBRA_LINHA;
      Result := Result + Produtos;
    end;
  except
    Result := '';
  end;
end;

constructor TEnviaMensagemThreed.Create;
begin
  inherited Create(True);

  FQRY := dmPrincipal.CriaQRY('ENVMSG');
  FQryAtualiza := dmPrincipal.CriaQRY('ATLMSG');
  FQRY.Close;
  FQRY.SQL.Clear;
  FQRY.SQL.Add
    ('select *, (select c.celular from cliente as c where c.codigo = codigo_cliente) as celular, (select c.celular_wpp from cliente as c where c.codigo = codigo_cliente) as celular_wpp from pedido where impresso_site <> status');

  FQryAtualiza.Close;
  FQryAtualiza.SQL.Clear;
  ArquivoINI := TIniFile.Create(ExtractFilePath(application.ExeName) +
    'LOG_ERRO_MENSAGEM.INI');
  Index := ArquivoINI.ReadInteger('TOT', 'INDEX', 0);
  inc(Index);
  ArquivoINI.WriteInteger('TOT', 'INDEX', Index);
  ArquivoINI.WriteDateTime(Index.ToString, 'INICIO', NOW);
  if Index > 1 then
    ArquivoINI.WriteDateTime((Index - 1).ToString, 'FIM', NOW);

end;

destructor TEnviaMensagemThreed.Destroy;
begin

  inherited;
end;

procedure TEnviaMensagemThreed.Execute;
var
  Celular: String;
  Celular9: String;
  Mensagem: String;
  Cabecalho: String;
  Status: String;
  Origem: String;
  Agradecimento: String;
  TipoPedido: String;
  NrPedido: Integer;
  TotalPedido: Real;
  Cancelado: Boolean;
  Horario: TDateTime;
  Motivo: String;
  Resumo: Boolean;
  Enviar: Boolean;
  mensagemResumo: String;

begin
  inherited;
  try
    Cabecalho := '*' + trim(dm.DADOS_EMPRESA.FieldByName('NOME')
      .AsString) + '*';
  except

  end;

  while not Terminated do
  begin
    if dmPrincipal.cConfirmacao.Checked then
    begin

      try
        GravaTest('Antes Open');
        FQRY.Open;
        GravaTest('Depois Open');
        while not FQRY.Eof do
        begin
          dmPrincipal.AguardarEnvioMensagem := True;
          GravaTest('While');
          Enviar := True;

          NrPedido := FQRY.FieldByName('codigo_pedido_dia').AsInteger;
          TotalPedido := FQRY.FieldByName('valor_total_pedido').AsFloat;
          Celular := FQRY.FieldByName('celular').AsString;
          Celular := FQRY.FieldByName('celular_wpp').AsString;
          Horario := FQRY.FieldByName('hora_pedido').AsDateTime;
          Cancelado := False;
          GravaTest('Case 1');
          case FQRY.FieldByName('codigo_cliente_endereco').AsInteger of
            0:
              begin
                TipoPedido := 'VEM BUSCAR';
              end
          else
            begin
              TipoPedido := 'DELIVERY';
            end;

          end;

          // origem
          GravaTest('Case 2');
          case FQRY.FieldByName('origem').AsInteger of
            1:
              begin
                Origem := 'whatsapp';
              end;
            2:
              begin
                Origem := 'site';
              end
          else
            begin
              Origem := '';
            end;
          end;
          GravaTest('Case 3');
          case FQRY.FieldByName('status').AsInteger of
            0:
              begin
                GravaTest('Cancelado');
                // Cancelamento
                Status := 'Cancelado';
                Cancelado := True;
                Motivo := trim(FQRY.FieldByName('motivo_cancelamento')
                  .AsString);
              end;
            4:
              begin
                GravaTest('Pronto');
                // Disponivel pra retirada
                Status := 'Pronto para retirada no balção';
              end;
            5:
              begin
                // Saiu para entrega
                GravaTest('Saiu');
                Status := 'Saiu para entrega';
              end;
            // Apenas quando site
            1:
              begin
                // Pedido Aceito
                // nesse momento aki vai mandar o resumo
                GravaTest('Origem');
                if FQRY.FieldByName('origem').AsInteger = 2 then
                begin
                  Status := 'Pedido aceito';
                  Resumo := True;
                  GravaTest('Antes Aceito Resumo');
                  mensagemResumo :=
                    BuscaResumo(FQRY.FieldByName('codigo').AsInteger,
                    FQRY.FieldByName('codigo_cliente_endereco').AsInteger);
                  GravaTest('Depois Aceito Resumo');
                end
                else
                begin
                  GravaTest('Não Enviar');
                  Enviar := False;
                end;
              end;
            9:
              begin
                // Aguardando
                GravaTest('Aguardando');
                if FQRY.FieldByName('origem').AsInteger = 2 then
                begin
                  Status := 'Aguardando ser aceito pelo estabelecimento';
                  Resumo := True;
                  GravaTest('Antes Aguardando Resumo');
                  mensagemResumo :=
                    BuscaResumo(FQRY.FieldByName('codigo').AsInteger,
                    FQRY.FieldByName('codigo_cliente_endereco').AsInteger);
                  GravaTest('Depois Aguardando Resumo');
                end
                else
                begin
                  Enviar := False;
                  GravaTest('Não Enviar');
                end;
              end;
          end;
          GravaTest('Mensagem Enviar');
          Mensagem := Cabecalho + MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + MONO_ESPACADA + '--- ' + TipoPedido + ' ---' +
            MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*Nº Pedido:* ' + MONO_ESPACADA +
            FormatFloat('000', NrPedido) + MONO_ESPACADA +
            MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*Recebimento:* ' + MONO_ESPACADA +
            FormatDateTime('hh:mm', Horario) + 'h' + MONO_ESPACADA +
            MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*Valor R$:* ' + MONO_ESPACADA +
            FormatFloat('#0.00', TotalPedido) + MONO_ESPACADA +
            MENSAGEM_QUEBRA_LINHA;
          Mensagem := Mensagem + '*Status:* ' + MONO_ESPACADA + Status +
            MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA_DUPLA;

          Mensagem := Mensagem + MONO_ESPACADA +
            'Pedido feito através do nosso ' + Origem + '!' + MONO_ESPACADA +
            MENSAGEM_QUEBRA_LINHA;

          if Cancelado then
          begin
            GravaTest('Cancelado');
            Mensagem := Mensagem + MONO_ESPACADA +
              'Lamentamos seu pedido foi cancelado.' + MONO_ESPACADA +
              MENSAGEM_QUEBRA_LINHA;
            if length(Motivo) > 0 then
              Mensagem := Mensagem + '*Motivo:* ' + MONO_ESPACADA + Motivo +
                MONO_ESPACADA;
          end
          else
          begin
            Mensagem := Mensagem + MONO_ESPACADA +
              'Agradeçemos sua preferência.' + MONO_ESPACADA;
          end;
          if Enviar then
          begin
            GravaTest('Enviar');
            try
              dmPrincipal.iWhatsapp.Send(Celular, Mensagem);
            except

            end;
            try
              dmPrincipal.iWhatsapp.Send(Celular9, Mensagem);
            except

            end;
            if Resumo then
            begin
              try
                dmPrincipal.iWhatsapp.Send(Celular, mensagemResumo);
              except

              end;
              try
                dmPrincipal.iWhatsapp.Send(Celular9, mensagemResumo);
              except

              end;
              GravaTest('Dorme Nenem');
              sleep(3000);
            end;

          end;
          try
            GravaTest('Antes Update');
            FQryAtualiza.SQL.Clear;
            FQryAtualiza.SQL.Add
              ('update pedido set impresso_site = status where codigo = ' +
              FQRY.FieldByName('codigo').AsString);
            FQryAtualiza.ExecSQL;
          except
            GravaTest('Erro Update');
          end;
          GravaTest('Next');
          FQRY.Next;
        end;
        GravaTest('Close');
        FQRY.Close;

      except
        on E: Exception do
        begin
          Mensagem := E.Message;
        end;

      end;
    end;
    dmPrincipal.AguardarEnvioMensagem := False;
    sleep(30000);

  end;

end;

procedure TEnviaMensagemThreed.GravaTest(Texto: String);
begin
  // ArquivoINI.WriteInteger('TOT', 'INDEX', Index);
   ArquivoINI.WriteDateTime(Index.ToString, 'DATA', NOW);
   ArquivoINI.WriteString(Index.ToString, 'MSG', Texto);

end;

procedure TEnviaMensagemThreed.SetAguardar(const Value: Boolean);
begin
  FAguardar := Value;
end;

{ TEnviaMensagem }

function TEnviaMensagem.BuscaResumo(Codigo, CodigoEndereco: Integer): String;
var
  Produtos: String;
  Finaliza: TFinalizarPedido;
  Conversa: TBotConversa;
begin
  Result := '';
  // exit;
  try

    Conversa := TBotConversa.Create(nil);
    Conversa.CodigoEndereco := CodigoEndereco;

    Finaliza := TFinalizarPedido.Create;
    Produtos := Finaliza.ProdutosResumo(Codigo, Conversa);
    Finaliza.Free;
    Conversa.Free;
    if Produtos <> '' then
    begin
      Result := '*--- RESUMO DO PEDIDO ---*' + MENSAGEM_QUEBRA_LINHA_DUPLA;
      Result := Result + '*QTD - DESCRICAO*' + MENSAGEM_QUEBRA_LINHA;
      Result := Result + Produtos;
    end;
  except
    Result := '';
  end;
end;

procedure TEnviaMensagem.Enviar;
var
  FQRY: TFDQuery;
  FQryAtualiza: TFDQuery;
  FAguardar: Boolean;

  Celular: String;
  Celular9: String;
  Mensagem: String;
  Cabecalho: String;
  Status: String;
  Origem: String;
  Agradecimento: String;
  TipoPedido: String;
  NrPedido: Integer;
  TotalPedido: Real;
  Cancelado: Boolean;
  Horario: TDateTime;
  Motivo: String;
  Resumo: Boolean;
  Enviar: Boolean;
  mensagemResumo: String;
begin
  try
{$REGION 'Create'}
    FQRY := dmPrincipal.CriaQRY('ENVMSG');
    FQryAtualiza := dmPrincipal.CriaQRY('ATLMSG');
    FQRY.Close;
    FQRY.SQL.Clear;
    FQRY.SQL.Add
      ('select *, (select c.celular from cliente as c where c.codigo = codigo_cliente) as celular, (select c.celular_wpp from cliente as c where c.codigo = codigo_cliente) as celular_wpp from pedido where impresso_site <> status and data_pedido = current_date()');
    FQryAtualiza.Close;
    FQryAtualiza.SQL.Clear;
{$ENDREGION}
    //

    FQRY.Open;

    while not FQRY.Eof do
    begin

      Enviar := True;
      NrPedido := FQRY.FieldByName('codigo_pedido_dia').AsInteger;
      TotalPedido := FQRY.FieldByName('valor_total_pedido').AsFloat;
      Celular := FQRY.FieldByName('celular').AsString;
      Celular := FQRY.FieldByName('celular_wpp').AsString;
      Horario := FQRY.FieldByName('hora_pedido').AsDateTime;
      Cancelado := False;

      case FQRY.FieldByName('codigo_cliente_endereco').AsInteger of
        0:
          begin
            TipoPedido := 'VEM BUSCAR';
          end
      else
        begin
          TipoPedido := 'DELIVERY';
        end;

      end;

      // origem

      case FQRY.FieldByName('origem').AsInteger of
        1:
          begin
            Origem := 'whatsapp';
          end;
        2:
          begin
            Origem := 'site';
          end
      else
        begin
          Origem := '';
        end;
      end;

      case FQRY.FieldByName('status').AsInteger of
        0:
          begin

            // Cancelamento
            Status := 'Cancelado';
            Cancelado := True;
            Motivo := trim(FQRY.FieldByName('motivo_cancelamento').AsString);
          end;
        4:
          begin

            // Disponivel pra retirada
            Status := 'Pronto para retirada no balção';
          end;
        5:
          begin
            // Saiu para entrega

            Status := 'Saiu para entrega';
          end;
        // Apenas quando site
        1:
          begin
            // Pedido Aceito
            // nesse momento aki vai mandar o resumo

            if FQRY.FieldByName('origem').AsInteger = 2 then
            begin
              Status := 'Pedido aceito';
              Resumo := True;

              mensagemResumo :=
                BuscaResumo(FQRY.FieldByName('codigo').AsInteger,
                FQRY.FieldByName('codigo_cliente_endereco').AsInteger);

            end
            else
            begin

              Enviar := False;
            end;
          end;
        9:
          begin
            // Aguardando

            if FQRY.FieldByName('origem').AsInteger = 2 then
            begin
              Status := 'Aguardando ser aceito pelo estabelecimento';
              Resumo := True;

              mensagemResumo :=
                BuscaResumo(FQRY.FieldByName('codigo').AsInteger,
                FQRY.FieldByName('codigo_cliente_endereco').AsInteger);

            end
            else
            begin
              Enviar := False;

            end;
          end;
      end;

      Mensagem := Cabecalho + MENSAGEM_QUEBRA_LINHA;
      Mensagem := Mensagem + MONO_ESPACADA + '--- ' + TipoPedido + ' ---' +
        MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
      Mensagem := Mensagem + '*Nº Pedido:* ' + MONO_ESPACADA +
        FormatFloat('000', NrPedido) + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
      Mensagem := Mensagem + '*Recebimento:* ' + MONO_ESPACADA +
        FormatDateTime('hh:mm', Horario) + 'h' + MONO_ESPACADA +
        MENSAGEM_QUEBRA_LINHA;
      Mensagem := Mensagem + '*Valor R$:* ' + MONO_ESPACADA +
        FormatFloat('#0.00', TotalPedido) + MONO_ESPACADA +
        MENSAGEM_QUEBRA_LINHA;
      Mensagem := Mensagem + '*Status:* ' + MONO_ESPACADA + Status +
        MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA_DUPLA;

      Mensagem := Mensagem + MONO_ESPACADA + 'Pedido feito através do nosso ' +
        Origem + '!' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;

      if Cancelado then
      begin

        Mensagem := Mensagem + MONO_ESPACADA +
          'Lamentamos seu pedido foi cancelado.' + MONO_ESPACADA +
          MENSAGEM_QUEBRA_LINHA;
        if length(Motivo) > 0 then
          Mensagem := Mensagem + '*Motivo:* ' + MONO_ESPACADA + Motivo +
            MONO_ESPACADA;
      end
      else
      begin
        Mensagem := Mensagem + MONO_ESPACADA + 'Agradeçemos sua preferência.' +
          MONO_ESPACADA;
      end;
      if Enviar then
      begin

        try
          dmPrincipal.iWhatsapp.Send(Celular, Mensagem);
        except

        end;
        try
          dmPrincipal.iWhatsapp.Send(Celular9, Mensagem);
        except

        end;
        if Resumo then
        begin
          try
            dmPrincipal.iWhatsapp.Send(Celular, mensagemResumo);
          except

          end;
          try
            dmPrincipal.iWhatsapp.Send(Celular9, mensagemResumo);
          except

          end;

          sleep(3000);
        end;

      end;
      try

        FQryAtualiza.SQL.Clear;
        FQryAtualiza.SQL.Add
          ('update pedido set impresso_site = status where codigo = ' +
          FQRY.FieldByName('codigo').AsString);
        FQryAtualiza.ExecSQL;
      except

      end;
      FQRY.Next;
    end;

    FQRY.Close;

  except
    on E: Exception do
    begin
      Mensagem := E.Message;
    end;

  end;
  FQRY.Free;
  FQryAtualiza.Free;
end;

{ TWppThreed }

procedure TWppThreed.AtualizaCelular(Telefone: String);
begin
  if UserId > 0 then
  begin
    InserirUpdate('ws_empresa', UserId.ToString, ['user_id', 'telefone_wpp'],
      [UserId.ToString, Telefone]);
  end;
end;

constructor TWppThreed.Create;
begin
  inherited Create(True);
  FRequest := iRequisicao.Create(nil);
  FRequest.BASEURL := URL_SITE;
end;

destructor TWppThreed.Destroy;
begin

  inherited;
end;

procedure TWppThreed.Execute;
begin
  inherited;

  while not Terminated do
  begin
    try
      getUser;
      if UserId > 0 then
      begin
        InserirUpdate('ws_empresa', UserId.ToString, ['user_id', 'ultima_wpp'],
          [UserId.ToString, FormatDateTime('yyyy-mm-dd hh:nn:ss', NOW)]);
      end;
    except

    end;

    sleep(5000);
  end;

end;

function TWppThreed.GetClientID: String;
var
  QRY: TFDQuery;
begin
  QRY := dm.CriaQRY('CLIENT');
  QRY.SQL.Clear;
  QRY.SQL.Add('select * from dados_whatsapp');
  QRY.Open;
  Result := QRY.FieldByName('client_id').AsString;
  QRY.Free;

end;

function TWppThreed.GetClientSecurity: String;
var
  QRY: TFDQuery;
begin
  QRY := dm.CriaQRY('CLIENT');
  QRY.SQL.Clear;
  QRY.SQL.Add('select * from dados_whatsapp');
  QRY.Open;
  Result := QRY.FieldByName('client_security').AsString;
  QRY.Free;
end;

function TWppThreed.getUser: Integer;
var
  Body: String;
  X: ISuperObject;
  SQL: String;

begin
  if (FUserId = 0) or (FUserId < 0) then
  begin
    Body := '{' + #13 + '"client_id":"' + ClientID + '",' + #13 +
      '"client_security":"' + ClientSecurity + '"' + #13 + '}';
    FRequest.URL := 'token2/a';
    FRequest.Body(Body);
    FRequest.Metodo := mPost;
    FRequest.Execute;
    X := TSuperObject.Create(FRequest.Retorno);

    if FRequest.Status = 200 then
    begin
      try
        FUserId := X['user'].AsInteger;
        // frmPrincipal.NomeRestaurante := X['nome'].AsString;
        Token := X['token'].AsString;
      except
        FUserId := -1;
      end;
      if FUserId = 0 then
        FUserId := -1;
    end
    else
    begin
      FUserId := -1;
      // Clientid Errado
    end;
  end;
  Result := FUserId;
  // Enviar pro site

end;

function TWppThreed.InserirUpdate(Tabela, User: String;
  ArrayCampos, ArrayValores: array of String): Integer;
var
  QRY: TFDQuery;
  Inserir: Boolean;

  Campos: String;
  Parametros: String;
  I: Integer;

  SQL: String;

  Montado: String;
  Requisicao: iRequisicao;
  Valor: String;
begin

  //Requisicao := iRequisicao.Create(nil);
  //Requisicao.BASEURL := URL_SITE;
  //
  //Requisicao.URL := 'insert/' + Tabela + '/' + User + '/a';
  //
  //Montado := '';
  //
  //for I := 0 to length(ArrayCampos) - 1 do
  //begin
  //  Valor := ArrayValores[I];
  //
  //  try
  //    StrToFloat(Valor);
  //    Valor := StringReplace(Valor, ',', '.', [rfReplaceAll]);
  //  except
  //
  //  end;
  //
  //  if I = 0 then
  //  begin
  //    Montado := '"' + ArrayCampos[I] + '":"' + Valor + '"';
  //  end
  //  else
  //  begin
  //    Montado := Montado + ',"' + ArrayCampos[I] + '":"' + Valor + '"';
  //  end;
  //end;
  //Montado := '{' + Montado + '}';
  //
  //// frmPrincipal.AdicionaLog(Montado);
  //Requisicao.Body(Montado);
  //Requisicao.Metodo:= mPost;
  //Requisicao.Execute;
  //try
  //  Result := StrToInt(Requisicao.Retorno);
  //except
  //  Result := 0;
  //
  //end;
  //Requisicao.Free;
end;

procedure TWppThreed.SetClientID(const Value: String);
begin
  FClientID := Value;
end;

procedure TWppThreed.SetClientSecurity(const Value: String);
begin
  FClientSecurity := Value;
end;

procedure TWppThreed.SetToken(const Value: String);
begin
  FToken := Value;
end;

procedure TWppThreed.SetUserId(const Value: Integer);
begin
  FUserId := Value;
end;

end.
