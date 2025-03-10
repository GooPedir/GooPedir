unit uframeDadosiFood;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.ListBox, FMX.Edit, FMX.Objects, FMX.Layouts,
  FMX.ComboEdit;

type
  TframeDadosiFood = class(TFrame)
    rBottom: TRectangle;
    rLateral: TRectangle;
    tImprimindo: TTimer;
    Layout3: TLayout;
    Layout1: TLayout;
    lOrigem: TLabel;
    lCodigoDia: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    edtCelular: TEdit;
    Label5: TLabel;
    edtNome: TEdit;
    Label3: TLabel;
    edtEndereco: TEdit;
    Label4: TLabel;
    GridPanelLayout2: TGridPanelLayout;
    edtPedido: TEdit;
    Label8: TLabel;
    edtDesconto: TEdit;
    Label10: TLabel;
    edtTaxa: TEdit;
    Label1: TLabel;
    edtTotal: TEdit;
    Label7: TLabel;
    layDescontoIfood: TLayout;
    Image5: TImage;
    lDescricaoDesconto: TLabel;
    cStatus: TComboBox;
    Label6: TLabel;
    lDescricaoStatusiFood: TLabel;
    edtCpfCnpj: TEdit;
    Label11: TLabel;
    lDataAgendada: TLabel;
    lDataEstimada: TLabel;
    edtTipoPagamento: TEdit;
    Label12: TLabel;
    cSelecionar: TCheckBox;
    lDataHora: TLabel;
    lTempo: TLabel;
    lCodigo: TLabel;
    GridPanelLayout3: TGridPanelLayout;
    lImpressao: TLayout;
    Image1: TImage;
    lImprimir: TLabel;
    lVisualizacao: TLayout;
    Image2: TImage;
    Label9: TLabel;
    lStatus: TLayout;
    Image4: TImage;
    Label2: TLabel;
    layMotoboy: TLayout;
    Image3: TImage;
    lMotoboy: TLabel;
    rAcao: TRectangle;
    rStatuspedidoiFood: TRectangle;
    lStatusPedidoiFood: TLabel;
    cStatusCancelamento: TComboEdit;
    rCancelar: TRectangle;
    Label14: TLabel;
    rConfirmaCancelamento: TRectangle;
    Label13: TLabel;
    procedure lImpressaoMouseEnter(Sender: TObject);
    procedure lImpressaoMouseLeave(Sender: TObject);
    procedure lVisualizacaoClick(Sender: TObject);
    procedure lImpressaoClick(Sender: TObject);
    procedure tImprimindoTimer(Sender: TObject);
    procedure cStatusChange(Sender: TObject);
    procedure lStatusClick(Sender: TObject);
    procedure rStatuspedidoiFoodClick(Sender: TObject);
    procedure rCancelarClick(Sender: TObject);
    procedure rConfirmaCancelamentoClick(Sender: TObject);
  private
    CodigoCancelamento: Array of String;
    FCodigoDia: Integer;
    FDataPedido: TDate;
    FCodigoEndereco: Integer;
    FHoraPedido: TTime;
    FStatus: Integer;
    FCodigoInterno: Integer;
    FNome: String;
    FEndereco: String;
    FCelular: String;
    FTaxa: Real;
    FTotal: Real;
    FOrigem: Integer;
    FTempo: String;
    FMotoboy: String;
    FCaixa: Integer;
    FDesconto: Real;
    FTroco: Real;
    FDataEstimada: TDateTime;
    FCodigoiFood: String;
    FDescricaoDescontoiFood: String;
    FDocumento: String;
    FStatusiFood: String;
    FDataAgendamento: TDateTime;
    FTipoPagamento: String;
    FDescricaoStatus: String;
    FValorPedido: Real;
    FOrder: String;
    procedure SetCelular(const Value: String);
    procedure SetCodigoDia(const Value: Integer);
    procedure SetCodigoEndereco(const Value: Integer);
    procedure SetCodigoInterno(const Value: Integer);
    procedure SetDataPedido(const Value: TDate);
    procedure SetEndereco(const Value: String);
    procedure SetHoraPedido(const Value: TTime);
    procedure SetNome(const Value: String);
    procedure SetStatus(const Value: Integer);
    procedure SetTaxa(const Value: Real);
    procedure SetTotal(const Value: Real);
    procedure SetOrigem(const Value: Integer);
    procedure SetTempo(const Value: String);
    procedure CancelaPedido;
    procedure SetCaixa(const Value: Integer);
    procedure SetMotoboy(const Value: String);
    procedure SetCodigoiFood(const Value: String);
    procedure SetDataAgendamento(const Value: TDateTime);
    procedure SetDataEstimada(const Value: TDateTime);
    procedure SetDesconto(const Value: Real);
    procedure SetDescricaoDescontoiFood(const Value: String);
    procedure SetDocumento(const Value: String);
    procedure SetStatusiFood(const Value: String);
    procedure SetTroco(const Value: Real);
    procedure SetTipoPagamento(const Value: String);
    procedure Calcula;
    procedure SetDescricaoStatus(const Value: String);
    procedure SetValorPedido(const Value: Real);
    procedure SimStatus;
    procedure SetOrder(const Value: String);

  var
    Carregando: Boolean;
    { Private declarations }
  public
    { Public declarations }
    property CodigoDia: Integer read FCodigoDia write SetCodigoDia;
    property CodigoInterno: Integer read FCodigoInterno write SetCodigoInterno;
    property CodigoEndereco: Integer read FCodigoEndereco
      write SetCodigoEndereco;
    property Endereco: String read FEndereco write SetEndereco;
    property DataPedido: TDate read FDataPedido write SetDataPedido;
    property HoraPedido: TTime read FHoraPedido write SetHoraPedido;
    property Celular: String read FCelular write SetCelular;
    property Nome: String read FNome write SetNome;
    property Status: Integer read FStatus write SetStatus;
    property Taxa: Real read FTaxa write SetTaxa;
    property Total: Real read FTotal write SetTotal;
    property Troco: Real read FTroco write SetTroco;
    property ValorPedido: Real read FValorPedido write SetValorPedido;
    property Desconto: Real read FDesconto write SetDesconto;
    property Documento: String read FDocumento write SetDocumento;
    property Origem: Integer read FOrigem write SetOrigem;
    property Tempo: String read FTempo write SetTempo;
    property Motoboy: String read FMotoboy write SetMotoboy;
    property Caixa: Integer read FCaixa write SetCaixa;
    property CodigoiFood: String read FCodigoiFood write SetCodigoiFood;
    property DataAgendamento: TDateTime read FDataAgendamento
      write SetDataAgendamento;
    property DataEstimada: TDateTime read FDataEstimada write SetDataEstimada;
    property StatusiFood: String read FStatusiFood write SetStatusiFood;
    property DescricaoStatus: String read FDescricaoStatus
      write SetDescricaoStatus;
    property DescricaoDescontoiFood: String read FDescricaoDescontoiFood
      write SetDescricaoDescontoiFood;
    property TipoPagamento: String read FTipoPagamento write SetTipoPagamento;
    property Order : String read FOrder write SetOrder;

  end;

implementation

uses
  FMXTee.Canvas, UnitResumo, uDM, uSenha, uMain, util, uSimNao;

{$R *.fmx}
{ TframeDadosVBDelivery }

procedure TframeDadosiFood.Calcula;
begin
  edtPedido.Text := FormatFloat('R$ ###,##0.00', ValorPedido);
end;

procedure TframeDadosiFood.CancelaPedido;
begin

  ShowMessageToast(frmMain, 'Pedido Cancelado Com Suceso!', 3);
  dm.PutSimples('v1/pedido/status/' + CodigoInterno.ToString + '/0/', nil);
  Status := 0;
  cStatus.Enabled := False;

end;

procedure TframeDadosiFood.cStatusChange(Sender: TObject);
begin
  if Carregando then
    exit;
  case cStatus.ItemIndex of
    0:
      begin

        if not Assigned(frmSenha) then
          frmSenha := TfrmSenha.Create(frmMain);
        frmSenha.Sim := CancelaPedido;
        frmSenha.Tipo := Validar;
        frmSenha.Show;
        Status := Status;
        exit;
      end;
  end;
  ShowMessageToast(frmMain, 'Pedido Atualizado Com Suceso!', 3);
  cStatus.Enabled := False;

  dm.PutSimples('v1/pedido/status/' + CodigoInterno.ToString + '/' +
    cStatus.ItemIndex.ToString + '/', nil);
end;

procedure TframeDadosiFood.lStatusClick(Sender: TObject);
begin
  cStatus.Enabled := True;
end;

procedure TframeDadosiFood.lImpressaoClick(Sender: TObject);
begin
  dm.PostSimples('/v1/imprimir/1/' + CodigoInterno.ToString, nil);
  lImprimir.Text := 'Imprimindo...';
  tImprimindo.Enabled := True;
end;

procedure TframeDadosiFood.lImpressaoMouseEnter(Sender: TObject);
begin
  (Sender as TLayout).Opacity := 1;
end;

procedure TframeDadosiFood.lImpressaoMouseLeave(Sender: TObject);
begin
  (Sender as TLayout).Opacity := 0.5;
end;

procedure TframeDadosiFood.lVisualizacaoClick(Sender: TObject);
begin

  FrmResumo.MESA := 0;
  FrmResumo.CodigoPedido := CodigoInterno;
  frmMain.OpenClose;
end;

procedure TframeDadosiFood.rCancelarClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := 0;
  cStatusCancelamento.Items.Clear;
  dm.GetSimples2('v1/util/ifood/lista/motivo/' + CodigoiFood,
    dm.MotivoCancelamentoiFood);
  SetLength(CodigoCancelamento, dm.MotivoCancelamentoiFood.RecordCount);
  while not dm.MotivoCancelamentoiFood.Eof do
  begin
    rConfirmaCancelamento.Enabled := True;
    CodigoCancelamento[Index] := dm.MotivoCancelamentoiFood.FieldByName
      ('cancellationcode').AsString;
    cStatusCancelamento.Items.Add(dm.MotivoCancelamentoiFood.FieldByName
      ('description').AsString);
    dm.MotivoCancelamentoiFood.Next;
    Inc(Index);
  end;
end;

procedure TframeDadosiFood.rConfirmaCancelamentoClick(Sender: TObject);
begin
  if cStatusCancelamento.ItemIndex < 0 then
  begin
    ShowMessageToast(nil, 'Selecione o motivo do cancelamento', 1);
    exit;
  end;
  dm.PostSimplesUnico('v1/util/ifood/cancelar/' + CodigoiFood + '/' +
    CodigoCancelamento[cStatusCancelamento.ItemIndex]+'/'+cStatusCancelamento.Items[cStatusCancelamento.ItemIndex], nil);
  ShowMessageToast(nil, 'Solicitação de cancelamento enviada!', 2);
  rConfirmaCancelamento.Enabled := False;
  rStatuspedidoiFood.Enabled := False;
  rCancelar.Enabled := False;
end;

procedure TframeDadosiFood.rStatuspedidoiFoodClick(Sender: TObject);
begin
  frmSimNao.Titulo := lStatusPedidoiFood.Text;;
  frmSimNao.Descricao := 'Confirma?';
  frmSimNao.Sim := SimStatus;
  frmSimNao.Show;

end;

procedure TframeDadosiFood.SetCaixa(const Value: Integer);
begin
  FCaixa := Value;
end;

procedure TframeDadosiFood.SetCelular(const Value: String);
begin
  FCelular := Value;
  edtCelular.Text := Value;
  CodigoiFood := '';
end;

procedure TframeDadosiFood.SetCodigoDia(const Value: Integer);
begin
  FCodigoDia := Value;
  lCodigoDia.Text := FormatFloat('000', Value);
end;

procedure TframeDadosiFood.SetCodigoEndereco(const Value: Integer);
begin
  FCodigoEndereco := Value;
  // cSelecionar.Visible := Value > 0;
  // edtEndereco.Visible := Value > 0;
  // edtTaxa.Visible := Value > 0;
end;

procedure TframeDadosiFood.SetCodigoiFood(const Value: String);
begin
  FCodigoiFood := Value;

  // lDataEstimada.Visible := length(Value) > 0;
  // lDataAgendada.Visible := length(Value) > 0;
  // edtCpfCnpj.Visible := length(Value) > 0;
  // layDescontoIfood.Visible := length(Value) > 0;
  // lDescricaoStatusiFood.Visible := length(Value) > 0;

end;

procedure TframeDadosiFood.SetCodigoInterno(const Value: Integer);
begin
  FCodigoInterno := Value;
  lCodigo.Text := FormatFloat('#000', Value);
end;

procedure TframeDadosiFood.SetDataAgendamento(const Value: TDateTime);
begin
  FDataAgendamento := Value;
  lDataAgendada.Text := 'Data/Hora Agendamento: ' +
    FormatDateTime('dd/mm/yyyy hh:nn:ss', Value);
  // lDataAgendada.Visible := True;
end;

procedure TframeDadosiFood.SetDataEstimada(const Value: TDateTime);
begin
  FDataEstimada := Value;
  lDataEstimada.Text := 'Data/Hora Estimada: ' +
    FormatDateTime('dd/mm/yyyy hh:nn:ss', Value);
  // lDataEstimada.Visible := True;
end;

procedure TframeDadosiFood.SetDataPedido(const Value: TDate);
begin
  FDataPedido := Value;

end;

procedure TframeDadosiFood.SetDesconto(const Value: Real);
begin
  FDesconto := Value;
  edtDesconto.Text := FormatFloat('R$ ###,##0.00', Value);
end;

procedure TframeDadosiFood.SetDescricaoDescontoiFood(const Value: String);
begin
  FDescricaoDescontoiFood := Value;
  lDescricaoDesconto.Text := Value;
  // layDescontoIfood.Visible := (length(Value) > 0);

end;

procedure TframeDadosiFood.SetDescricaoStatus(const Value: String);
begin
  FDescricaoStatus := Value;
  lDescricaoStatusiFood.Text := Value;
  // lDescricaoStatusiFood.Visible := True;
end;

procedure TframeDadosiFood.SetDocumento(const Value: String);
begin
  FDocumento := Value;
  edtCpfCnpj.Text := Value;
end;

procedure TframeDadosiFood.SetEndereco(const Value: String);
begin
  FEndereco := Value;
  edtEndereco.Text := UpperCase(Value);
end;

procedure TframeDadosiFood.SetHoraPedido(const Value: TTime);
begin
  FHoraPedido := Value;
end;

procedure TframeDadosiFood.SetMotoboy(const Value: String);
begin
  FMotoboy := Value;
  // if length(Value) > 0 then
  // begin
  // self.Height := 260;
  // end
  // else
  // begin
  // self.Height := 220;
  // end;
  lMotoboy.Text := UpperCase(Value);
  // layMotoboy.Visible := self.Height > 220;
end;

procedure TframeDadosiFood.SetNome(const Value: String);
begin
  FNome := Value;
  edtNome.Text := UpperCase(Value);
end;

procedure TframeDadosiFood.SetOrder(const Value: String);
begin
  FOrder := Value;

  lDataEstimada.Visible := not (Value = 'IMMEDIATE');
  lDataAgendada.Visible := not (Value = 'IMMEDIATE');

end;

procedure TframeDadosiFood.SetOrigem(const Value: Integer);
var
  Cor: TColor;
begin
  FOrigem := Value;
  case Value of
    1:
      begin
        lOrigem.Text := 'Whatsapp';
        Cor := RGB(189, 246, 227);
      end;
    2:
      begin
        lOrigem.Text := 'Site';
        Cor := RGB(175, 222, 250);
      end;
    3:
      begin
        lOrigem.Text := Nome;
        Cor := RGB(227, 210, 244);
        // edtCelular.Visible := False;
        edtNome.Visible := False;
      end;
    4:
      begin
        lOrigem.Text := 'iFood';
        Cor := RGB(105, 26, 1);
      end;
  else
    begin
      lOrigem.Text := 'Pedido Local';
      Cor := RGB(227, 210, 244);
    end;
  end;
  rLateral.Fill.Color := Cor;
  rLateral.Stroke.Color := Cor;
  rBottom.Fill.Color := Cor;
  rBottom.Stroke.Color := Cor;
end;

procedure TframeDadosiFood.SetStatus(const Value: Integer);
begin
  Carregando := True;
  FStatus := Value;
  // cStatus.ItemIndex := Value;
  // lStatus.Visible := Value <= 5;
  Carregando := False;
end;

procedure TframeDadosiFood.SetStatusiFood(const Value: String);
begin
  FStatusiFood := Value;
  rStatuspedidoiFood.Enabled := True;
  rCancelar.Enabled := True;
  rStatuspedidoiFood.Enabled := True;

  if FStatusiFood = 'CAN' then
  begin
    rAcao.Visible := False;
    Layout1.Height := 295;
    self.Height := 374;
  end
  else if FStatusiFood = 'CON' then
  begin
    rAcao.Visible := False;
    Layout1.Height := 295;
    self.Height := 374;
  end
  else if FStatusiFood = 'PLC' then
  begin
    lStatusPedidoiFood.Text := 'Confirmar';
  end
  else if FStatusiFood = 'CFM' then
  begin
    lStatusPedidoiFood.Text := 'Preparar';
  end
  else if FStatusiFood = 'PRS' then
  begin

    if CodigoEndereco > 0 then
    begin
      lStatusPedidoiFood.Text := 'Despachar';
    end
    else
    begin
      lStatusPedidoiFood.Text := 'Pronto';
    end;

  end
  else
  begin
    rStatuspedidoiFood.Visible := False;
    rStatuspedidoiFood.Enabled := False;
  end;

end;

procedure TframeDadosiFood.SetTaxa(const Value: Real);
begin
  FTaxa := Value;
  edtTaxa.Text := FormatFloat('R$ ###,##0.00', Value);
  Calcula;
end;

procedure TframeDadosiFood.SetTempo(const Value: String);
begin
  FTempo := Value;
  lTempo.Text := Value;
  lDataHora.Text := DateToStr(DataPedido) + ' ' + TimeToStr(HoraPedido);
end;

procedure TframeDadosiFood.SetTipoPagamento(const Value: String);
begin
  FTipoPagamento := Value;
  edtTipoPagamento.Text := Value;
end;

procedure TframeDadosiFood.SetTotal(const Value: Real);
begin
  FTotal := Value;
  edtTotal.Text := FormatFloat('R$ ###,##0.00', Value);
end;

procedure TframeDadosiFood.SetTroco(const Value: Real);
begin
  FTroco := Value;
  Calcula;
end;

procedure TframeDadosiFood.SetValorPedido(const Value: Real);
begin
  FValorPedido := Value;
  Calcula;
end;

procedure TframeDadosiFood.SimStatus;
begin

  rStatuspedidoiFood.Enabled := False;


  if FStatusiFood = 'PLC' then
  begin
    dm.PostSimples('v1/util/ifood/confirmar/' + CodigoiFood, nil);
  end
  else if FStatusiFood = 'CFM' then
  begin
    dm.PostSimples('v1/util/ifood/preparar/' + CodigoiFood, nil);
  end
  else if FStatusiFood = 'PRS' then
  begin

    if CodigoEndereco > 0 then
    begin
      dm.PostSimples('v1/util/ifood/despachar/' + CodigoiFood, nil);
    end
    else
    begin
      dm.PostSimples('v1/util/ifood/retirar/' + CodigoiFood, nil);
    end;

  end
  else
  begin
    rStatuspedidoiFood.Visible := False;
    rStatuspedidoiFood.Enabled := False;
  end;
end;

procedure TframeDadosiFood.tImprimindoTimer(Sender: TObject);
begin
  lImprimir.Text := 'Imprimir Pedido';
end;

end.
