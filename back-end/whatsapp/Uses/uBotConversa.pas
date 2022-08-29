unit uBotConversa;

interface

uses
  System.Classes, Vcl.ExtCtrls, uTInject, uClassEnderecoUtil,
  FireDAC.Comp.Client;

type
  TTipoUsuario = (Cliente, Motoboy);
  TSituacaoConversa = (Aguardando, NovoCliente, NovoPedido, MenuPedido,
    AdicionandoProduto, AdicionandoPizza, SelecionandoFormaPedido,
    FinalizandoPedido, CaschBack, Finalizado, VerificaUltimoPedido,
    EnderecoCliente, AlteraRemove, Cancelamento, AtendimentoHumano);
  TTipoEntrega = (VemBuscar, Delivery);

  TBotConversa = class;
  TNotifyConversa = procedure(Conversa: TBotConversa) of object;

  TBotConversa = class(TComponent)
  private
    // Enumerado
    FTipoUsuario: TTipoUsuario;
    FSituacao: TSituacaoConversa;
    // Propriedades
    FID: String;
    FTelefone: String;
    FIDMensagem: Extended;
    FNome: String;
    FEtapa: Integer;
    FPergunta: String;
    FResposta: String;
    FTempoInatividade: Integer;

    // Objeto

    // Notifys Eventos
    FOnSituacaoAlterada: TNotifyConversa;
    FOnRespostaRecebida: TNotifyConversa;
    FLat: Extended;
    FLng: Extended;
    FErrosCliente: Integer;
    FAuxCliente: variant;
    FEntrega: TTipoEntrega;
    FCodigoAdicionalPersonalizado: Integer;
    FCodigosAdiconsidP: String;
    FnrAux: Integer;
    FCPF: String;
    FDataNascimento: TDate;
    FValorDescontoCashback: real;
    FEnviarMensagem: Boolean;
    FClienteLocalizado: Boolean;
    FNomeValido: String;
    FProdutoCodigoSelecionado: Integer;
    FProdutoCategoriaSelecionada: Integer;
    FSQLCategoria: String;
    FCategoriaDescricao: String;
    FCodigoClienteInterno: Integer;
    FDadosEnderecoCliente: TEnderecoLocalizacao;
    FProdutoQuantidade: real;
    FCodigoEndereco: Integer;
    FCategoriaAtual: Integer;
    FQuantidadeCategoria: Integer;

    FCodigoPedido: Integer;
    FMinimoCategoria: Integer;
    FMaximoCategoria: Integer;
    FNumero: String;
    FComplemento: String;
    FValorBotao: String;

    procedure TimerSleepExecute(Sender: TObject);

    procedure TimerEnviaMensagemNaoFInalizouTipoPagamentoExecute
      (Sender: TObject);

    procedure SetSituacao(const Value: TSituacaoConversa);
    procedure SetTempoInatividade(const Value: Integer);
    procedure SetLat(const Value: Extended);
    procedure SetLng(const Value: Extended);
    procedure SetErrosCliente(const Value: Integer);
    procedure SetAuxCliente(const Value: variant);
    procedure SetEntrega(const Value: TTipoEntrega);
    procedure SetCodigoAdicionalPersonalizado(const Value: Integer);
    procedure SetCodigosAdiconsidP(const Value: String);
    procedure SetnrAux(const Value: Integer);
    procedure SetCPF(const Value: String);
    procedure SetDataNascimento(const Value: TDate);
    procedure SetValorDescontoCashback(const Value: real);
    procedure SetEnviarMensagem(const Value: Boolean);
    procedure SetClienteLocalizado(const Value: Boolean);
    procedure SetNomeValido(const Value: String);
    procedure SetProdutoCategoriaSelecionada(const Value: Integer);
    procedure SetProdutoCodigoSelecionado(const Value: Integer);
    procedure SetSQLCategoria(const Value: String);
    procedure SetCategoriaDescricao(const Value: String);
    procedure SetCodigoClienteInterno(const Value: Integer);
    procedure SetDadosEnderecoCliente(const Value: TEnderecoLocalizacao);
    procedure SetProdutoQuantidade(const Value: real);
    procedure SetCodigoEndereco(const Value: Integer);
    procedure SetCategoriaAtual(const Value: Integer);

    procedure SetQuantidadeCategoria(const Value: Integer);
    procedure SetCodigoPedido(const Value: Integer);
    procedure SetMinimoCategoria(const Value: Integer);
    procedure SetMaximoCategoria(const Value: Integer);
    procedure SetComplemento(const Value: String);
    procedure SetNumero(const Value: String);
    procedure SetValorBotao(const Value: String);

  public
    // Construtores destrutores
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property TipoUsuario: TTipoUsuario read FTipoUsuario write FTipoUsuario
      default Cliente;
    property Situacao: TSituacaoConversa read FSituacao write SetSituacao
      default Aguardando;
    property ID: String read FID write FID;
    property Telefone: String read FTelefone write FTelefone;
    property IDMensagem: Extended read FIDMensagem write FIDMensagem;
    property Nome: String read FNome write FNome;
    property Etapa: Integer read FEtapa write FEtapa default 0;
    property Pergunta: String read FPergunta write FPergunta;
    property Resposta: String read FResposta write FResposta;
    property TempoInatividade: Integer read FTempoInatividade
      write SetTempoInatividade;
    property Entrega: TTipoEntrega read FEntrega write SetEntrega;
    property EnviarMensagem: Boolean read FEnviarMensagem
      write SetEnviarMensagem;

    property OnSituacaoAlterada: TNotifyConversa read FOnSituacaoAlterada
      write FOnSituacaoAlterada;
    property OnRespostaRecebida: TNotifyConversa read FOnRespostaRecebida
      write FOnRespostaRecebida;

    property Lat: Extended read FLat write SetLat;
    property Lng: Extended read FLng write SetLng;

    property ErrosCliente: Integer read FErrosCliente write SetErrosCliente;
    property AuxCliente: variant read FAuxCliente write SetAuxCliente;
    property CodigoAdicionalPersonalizado: Integer
      read FCodigoAdicionalPersonalizado write SetCodigoAdicionalPersonalizado;
    property CodigosAdiconsidP: String read FCodigosAdiconsidP
      write SetCodigosAdiconsidP;
    property nrAux: Integer read FnrAux write SetnrAux;
    property CPF: String read FCPF write SetCPF;
    property DataNascimento: TDate read FDataNascimento write SetDataNascimento;
    property ValorDescontoCashback: real read FValorDescontoCashback
      write SetValorDescontoCashback;
    property CodigoClienteInterno: Integer read FCodigoClienteInterno
      write SetCodigoClienteInterno;

    // Campos Novos
    property ClienteLocalizado: Boolean read FClienteLocalizado
      write SetClienteLocalizado default false;
    property NomeValido: String read FNomeValido write SetNomeValido;
    property CategoriaDescricao: String read FCategoriaDescricao
      write SetCategoriaDescricao;
    property ProdutoCategoriaSelecionada: Integer
      read FProdutoCategoriaSelecionada write SetProdutoCategoriaSelecionada;
    property SQLCategoria: String read FSQLCategoria write SetSQLCategoria;
    property ProdutoCodigoSelecionado: Integer read FProdutoCodigoSelecionado
      write SetProdutoCodigoSelecionado;
    property DadosEnderecoCliente: TEnderecoLocalizacao
      read FDadosEnderecoCliente write SetDadosEnderecoCliente;
    property ProdutoQuantidade: real read FProdutoQuantidade
      write SetProdutoQuantidade;
    property CodigoEndereco: Integer read FCodigoEndereco
      write SetCodigoEndereco;
    property Numero: String read FNumero write SetNumero;
    property Complemento: String read FComplemento write SetComplemento;

    property QuantidadeCategoria: Integer read FQuantidadeCategoria
      write SetQuantidadeCategoria;
    property CategoriaAtual: Integer read FCategoriaAtual
      write SetCategoriaAtual;
    property MinimoCategoria: Integer read FMinimoCategoria
      write SetMinimoCategoria;
    property MaximoCategoria: Integer read FMaximoCategoria
      write SetMaximoCategoria;

    property CodigoPedido: Integer read FCodigoPedido write SetCodigoPedido;

    property ValorBotao : String read FValorBotao write SetValorBotao;

    procedure ReiniciarTimer;

  var
    ArrayCategorias: Array of String;
    ArrayCategoriasItens: Array of String;
    ArrayCategoriasValores: Array of real;
    ArrayCategoriasTipoValor: Array of Integer;

  var
    ArrayDadosEndereco: Array of String;
    IDMensagemPagamento: String;
  end;

implementation

uses
  System.SysUtils, uPrincipal;

{ TBotConversa }

constructor TBotConversa.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Prepara Timer

end;

destructor TBotConversa.Destroy;
begin

  inherited Destroy;
end;

procedure TBotConversa.SetAuxCliente(const Value: variant);
begin
  FAuxCliente := Value;
end;

procedure TBotConversa.SetCategoriaAtual(const Value: Integer);
begin
  FCategoriaAtual := Value;
end;

procedure TBotConversa.SetCategoriaDescricao(const Value: String);
begin
  FCategoriaDescricao := Value;
end;

procedure TBotConversa.SetClienteLocalizado(const Value: Boolean);
begin
  FClienteLocalizado := Value;
end;

procedure TBotConversa.SetCodigoAdicionalPersonalizado(const Value: Integer);
begin
  FCodigoAdicionalPersonalizado := Value;
end;

procedure TBotConversa.SetCodigoClienteInterno(const Value: Integer);
begin
  FCodigoClienteInterno := Value;
end;

procedure TBotConversa.SetCodigoEndereco(const Value: Integer);
begin
  FCodigoEndereco := Value;
end;

procedure TBotConversa.SetCodigoPedido(const Value: Integer);
begin
  FCodigoPedido := Value;
end;

procedure TBotConversa.SetCodigosAdiconsidP(const Value: String);
begin
  FCodigosAdiconsidP := Value;
end;

procedure TBotConversa.SetComplemento(const Value: String);
begin
  FComplemento := Value;
end;

procedure TBotConversa.SetCPF(const Value: String);
begin
  FCPF := Value;
end;

procedure TBotConversa.SetDadosEnderecoCliente(const Value
  : TEnderecoLocalizacao);
begin
  FDadosEnderecoCliente := Value;
end;

procedure TBotConversa.SetDataNascimento(const Value: TDate);
begin
  FDataNascimento := Value;
end;

procedure TBotConversa.SetEntrega(const Value: TTipoEntrega);
begin
  FEntrega := Value;
end;

procedure TBotConversa.SetEnviarMensagem(const Value: Boolean);
begin
  FEnviarMensagem := Value;
end;

procedure TBotConversa.SetErrosCliente(const Value: Integer);
begin
  FErrosCliente := Value;
end;

procedure TBotConversa.SetLat(const Value: Extended);
begin
  FLat := Value;
end;

procedure TBotConversa.SetLng(const Value: Extended);
begin
  FLng := Value;
end;

procedure TBotConversa.SetMaximoCategoria(const Value: Integer);
begin
  FMaximoCategoria := Value;
end;

procedure TBotConversa.SetMinimoCategoria(const Value: Integer);
begin
  FMinimoCategoria := Value;
end;

procedure TBotConversa.SetNomeValido(const Value: String);
begin
  FNomeValido := Value;
end;

procedure TBotConversa.SetnrAux(const Value: Integer);
begin
  FnrAux := Value;
end;

procedure TBotConversa.SetNumero(const Value: String);
begin
  FNumero := Value;
end;

procedure TBotConversa.SetProdutoCategoriaSelecionada(const Value: Integer);
begin
  FProdutoCategoriaSelecionada := Value;
end;

procedure TBotConversa.SetProdutoCodigoSelecionado(const Value: Integer);
begin
  FProdutoCodigoSelecionado := Value;
end;

procedure TBotConversa.SetProdutoQuantidade(const Value: real);
begin
  FProdutoQuantidade := Value;
end;

procedure TBotConversa.SetQuantidadeCategoria(const Value: Integer);
begin
  FQuantidadeCategoria := Value;
end;

procedure TBotConversa.SetSituacao(const Value: TSituacaoConversa);
begin
  // DoChange
  if FSituacao <> Value then
  begin
    FSituacao := Value;
    if Assigned(OnSituacaoAlterada) then
      OnSituacaoAlterada(Self);
  end;
end;

procedure TBotConversa.SetSQLCategoria(const Value: String);
begin
  FSQLCategoria := Value;
end;

procedure TBotConversa.SetTempoInatividade(const Value: Integer);
begin
  FTempoInatividade := Value;

end;

procedure TBotConversa.SetValorBotao(const Value: String);
begin
  FValorBotao := Value;
end;

procedure TBotConversa.SetValorDescontoCashback(const Value: real);
begin
  FValorDescontoCashback := Value;
end;



procedure TBotConversa.TimerEnviaMensagemNaoFInalizouTipoPagamentoExecute
  (Sender: TObject);
var
  Mensagem: String;
  ConversaEnvia: TBotConversa;
begin
  (Sender as TTimer).Enabled := false;
  {
    ConversaEnvia := Gestor.BuscarConversa(IDMensagemPagamento);
    if ConversaEnvia <> nil then
    begin
    Mensagem := 'Opa *' + ConversaEnvia.Nome +
    '*, agora so falta escolher o tipo de pagamento para finalizar seu pedido '
    + frmPrincipal.Inject1.Emoticons.SorridenteLingua;
    frmPrincipal.Inject1.Send(ConversaEnvia.ID, Mensagem);
    end;
  }
end;

procedure TBotConversa.TimerSleepExecute(Sender: TObject);
begin
  Self.Situacao := Finalizado;
end;

procedure TBotConversa.ReiniciarTimer;
begin

end;

end.
