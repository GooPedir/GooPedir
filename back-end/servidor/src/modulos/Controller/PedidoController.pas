unit PedidoController;

interface

uses
  System.SysUtils, System.Classes, System.JSON, IdHTTP, IdSSLOpenSSL,
  Vcl.ExtCtrls, uRequisicao, System.Generics.Collections, conexao, uDM,
  FireDAC.Comp.Client;

type
  TExtra = class
  private
    FCategoria: string;
    FDescricao: string;
    FValor: Double;
    FQuantidade: Integer;
  public
    property Categoria: string read FCategoria write FCategoria;
    property Descricao: string read FDescricao write FDescricao;
    property Valor: Double read FValor write FValor;
    property Quantidade: Integer read FQuantidade write FQuantidade;
  end;

  // Classe para representar um produto
  TProduto = class
  private
    FId: string;
    FNome: string;
    FPreco: Double;
    FQuantidade: Integer;
    FExtras: TObjectList<TExtra>;
  public
    constructor Create;
    destructor Destroy; override;
    property Id: string read FId write FId;
    property Nome: string read FNome write FNome;
    property Preco: Double read FPreco write FPreco;
    property Quantidade: Integer read FQuantidade write FQuantidade;
    property Extras: TObjectList<TExtra> read FExtras;
  end;

  TPedido = class
  private
    FTaxa: Double;
    FDesconto: Double;
    FLatitude: Double;
    FClienteNome: string;
    FCupom: string;
    FSubTotal: Double;
    FPagamentoTransacao: string;
    FClienteCelular: string;
    FTotal: Double;
    FId: Integer;
    FLongitude: Double;
    FPagamentoMP: string;
    FClienteNascimento: string;
    FClienteCPF: string;

    FURL: string;
    FPagamentoDescricao: string;
    FData: TDateTime;
    FPartner: string;
    FProdutos: TObjectList<TProduto>;
    FEnderecoBairro: String;
    FCodigoEndereco: Integer;
    FEnderecoNumero: String;
    FEnderecoComplemento: String;
    FCodigoCliente: Integer;
    FEnderecoCidade: String;
    FEnderecoEstado: String;
    FEnderecoRua: String;
    procedure SetProdutos(const Value: TObjectList<TProduto>);
    procedure SetCodigoCliente(const Value: Integer);
    procedure SetCodigoEndereco(const Value: Integer);
    procedure SetEnderecoBairro(const Value: String);
    procedure SetEnderecoCidade(const Value: String);
    procedure SetEnderecoComplemento(const Value: String);
    procedure SetEnderecoEstado(const Value: String);
    procedure SetEnderecoNumero(const Value: String);
    procedure SetEnderecoRua(const Value: String);
    procedure BuscaCliente;
  public
    property Id: Integer read FId write FId;
    property Data: TDateTime read FData write FData;
    property ClienteNome: string read FClienteNome write FClienteNome;
    property ClienteCelular: string read FClienteCelular write FClienteCelular;
    property ClienteCPF: string read FClienteCPF write FClienteCPF;
    property ClienteNascimento: string read FClienteNascimento
      write FClienteNascimento;
    property PagamentoDescricao: string read FPagamentoDescricao
      write FPagamentoDescricao;
    property PagamentoMP: string read FPagamentoMP write FPagamentoMP;
    property PagamentoTransacao: string read FPagamentoTransacao
      write FPagamentoTransacao;
    property SubTotal: Double read FSubTotal write FSubTotal;
    property Desconto: Double read FDesconto write FDesconto;
    property Taxa: Double read FTaxa write FTaxa;
    property Total: Double read FTotal write FTotal;
    property URL: string read FURL write FURL;
    property Partner: string read FPartner write FPartner;
    property Cupom: string read FCupom write FCupom;
    property Latitude: Double read FLatitude write FLatitude;
    property Longitude: Double read FLongitude write FLongitude;
    // property Produtos: TJSONArray read FProdutos write FProdutos;
    // property Produtos: TObjectList<TProduto> read FProdutos;
    property Produtos: TObjectList<TProduto> read FProdutos write SetProdutos;
    property EnderecoRua: String read FEnderecoRua write SetEnderecoRua;
    property EnderecoNumero: String read FEnderecoNumero
      write SetEnderecoNumero;
    property EnderecoBairro: String read FEnderecoBairro
      write SetEnderecoBairro;
    property EnderecoCidade: String read FEnderecoCidade
      write SetEnderecoCidade;
    property EnderecoEstado: String read FEnderecoEstado
      write SetEnderecoEstado;
    property EnderecoComplemento: String read FEnderecoComplemento
      write SetEnderecoComplemento;

    property CodigoCliente: Integer read FCodigoCliente write SetCodigoCliente;
    property CodigoEndereco: Integer read FCodigoEndereco
      write SetCodigoEndereco;
    function RemoveAcentos(const Texto: string): string;
  end;

  TPedidosManager = class
  private
    iReq: iRequisicao;
    FTimer: TTimer;
    FUser: string;

    Modulo: Tdm;
    Qry: TFDQuery;
    Tabela: TFDTable;
    procedure OnTimer(Sender: TObject);
    procedure ConsultarPedidos;
    procedure ProcessarPedido(PedidoID: Integer);
    function CarregarProdutos(JSONArray: TJSONArray): TObjectList<TProduto>;
  public
    constructor Create(User: string);
    destructor Destroy; override;
  end;

implementation

uses
  Vcl.Dialogs;

{ TPedidosManager }

function TPedidosManager.CarregarProdutos(JSONArray: TJSONArray)
  : TObjectList<TProduto>;
var
  JSONProduto: TJSONObject;
  JSONExtra: TJSONObject;
  Produto: TProduto;
  Extra: TExtra;
  I, J: Integer;
begin
  Result := TObjectList<TProduto>.Create;
  try
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONProduto := JSONArray.Items[I] as TJSONObject;
      Produto := TProduto.Create;
      Produto.Id := JSONProduto.GetValue<string>('id');
      Produto.Nome := JSONProduto.GetValue<string>('nome');
      Produto.Preco := JSONProduto.GetValue<Double>('preco');
      Produto.Quantidade := JSONProduto.GetValue<Integer>('quantidade');

      // Carregar extras do produto
      for J := 0 to (JSONProduto.GetValue<TJSONArray>('extra').Count - 1) do
      begin
        JSONExtra := JSONProduto.GetValue<TJSONArray>('extra')
          .Items[J] as TJSONObject;
        Extra := TExtra.Create;
        Extra.Categoria := JSONExtra.GetValue<string>('categoria');
        Extra.Descricao := JSONExtra.GetValue<string>('descricao');
        Extra.Valor := JSONExtra.GetValue<Double>('valor');
        Extra.Quantidade := JSONExtra.GetValue<Integer>('quantidade');
        Produto.Extras.Add(Extra);
      end;

      Result.Add(Produto);
    end;
  except
    on E: Exception do
    begin
      Result.Free;
      raise;
    end;
  end;
end;

procedure TPedidosManager.ConsultarPedidos;
var
  URL: string;
  Response: string;
  JSONArray: TJSONArray;
  JSONValue: TJSONValue;
  PedidoID: Integer;

begin

  URL := 'https://old.goopedir.com/v2/pedidos.php';
  try
    // Response := FHTTP.Get(URL);
    iReq.URL := URL;
    iReq.Metodo := mGet;
    iReq.Execute;
    Response := iReq.Retorno;
    JSONArray := TJSONObject.ParseJSONValue(Response) as TJSONArray;
    try
      for JSONValue in JSONArray do
      begin
        PedidoID := (JSONValue as TJSONObject).GetValue<Integer>('id');
        ProcessarPedido(PedidoID);
      end;
    finally
      JSONArray.Free;
    end;
  except
    on E: Exception do
      Writeln('Erro ao consultar pedidos: ' + E.Message);
  end;
end;

constructor TPedidosManager.Create(User: string);
begin
  FUser := User;

  // Configuração do HTTP e SSL
  iReq := iRequisicao.Create(nil);

  // Configuração do Timer
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 10000; // 10 segundos
  FTimer.OnTimer := OnTimer;
  FTimer.Enabled := True;
  Modulo := Tdm.Create(nil);
  Qry := Modulo.CriaQry;

end;

destructor TPedidosManager.Destroy;
begin
  FTimer.Free;
  iReq.Free;

  inherited;
end;

procedure TPedidosManager.OnTimer(Sender: TObject);
begin
  ConsultarPedidos;
end;

procedure TPedidosManager.ProcessarPedido(PedidoID: Integer);
var
  URL: string;
  Response: string;
  JSONObject: TJSONObject;
  Pedido: TPedido;
  FormatSettings: TFormatSettings;
begin
  FormatSettings := TFormatSettings.Create;
  FormatSettings.ShortDateFormat := 'yyyy-mm-dd'; // Formato da data
  FormatSettings.LongTimeFormat := 'hh:nn:ss'; // Formato da hora
  FormatSettings.DateSeparator := '-'; // Separador de data
  FormatSettings.TimeSeparator := ':'; // Separador de hora

  URL := 'https://old.goopedir.com/v2/pedido.php?codigo=' + IntToStr(PedidoID);
  try
    iReq.URL := URL;
    iReq.Metodo := mGet;
    iReq.Execute;
    Response := iReq.Retorno;
    JSONObject := TJSONObject.ParseJSONValue(Response) as TJSONObject;
    try
      Pedido := TPedido.Create;
      try
        Pedido.Id := JSONObject.GetValue<Integer>('id');
        Pedido.Data := StrToDateTime(JSONObject.GetValue<string>('data'),
          FormatSettings);
        Pedido.ClienteNome := JSONObject.GetValue<TJSONObject>('cliente')
          .GetValue<string>('nome');
        Pedido.ClienteCelular := JSONObject.GetValue<TJSONObject>('cliente')
          .GetValue<string>('celular');
        Pedido.ClienteCPF := JSONObject.GetValue<TJSONObject>('cliente')
          .GetValue<string>('cpf');
        Pedido.ClienteNascimento := JSONObject.GetValue<TJSONObject>('cliente')
          .GetValue<string>('nascimento');
        Pedido.PagamentoDescricao := JSONObject.GetValue<TJSONObject>('pagamento').GetValue<string>('descricao');
        try
          Pedido.PagamentoMP := JSONObject.GetValue<TJSONObject>('pagamento')
            .GetValue<string>('mp');
        except

        end;

        try
          Pedido.PagamentoTransacao := JSONObject.GetValue<TJSONObject>
            ('pagamento').GetValue<string>('transacao');
        except

        end;
        Pedido.EnderecoRua := JSONObject.GetValue<TJSONObject>('endereco').GetValue<string>('rua');
        Pedido.EnderecoNumero := JSONObject.GetValue<TJSONObject>('endereco').GetValue<string>('numero');
        Pedido.EnderecoBairro := JSONObject.GetValue<TJSONObject>('endereco').GetValue<string>('bairro');
        Pedido.EnderecoCidade := JSONObject.GetValue<TJSONObject>('endereco').GetValue<string>('cidade');
        Pedido.EnderecoEstado := JSONObject.GetValue<TJSONObject>('endereco').GetValue<string>('estado');
        Pedido.EnderecoComplemento := JSONObject.GetValue<TJSONObject>('endereco').GetValue<string>('complemento');


        Pedido.SubTotal := JSONObject.GetValue<Double>('sub');
        Pedido.Desconto := JSONObject.GetValue<Double>('desconto');
        Pedido.Taxa := JSONObject.GetValue<Double>('taxa');
        Pedido.Total := JSONObject.GetValue<Double>('total');
        Pedido.URL := JSONObject.GetValue<string>('url');
        Pedido.Partner := JSONObject.GetValue<string>('partner');
        Pedido.Cupom := JSONObject.GetValue<string>('cupom');
        Pedido.Latitude := JSONObject.GetValue<Double>('latitude');
        Pedido.Longitude := JSONObject.GetValue<Double>('longitude');
        Pedido.Produtos := CarregarProdutos
          (JSONObject.GetValue<TJSONArray>('produtos'));

        // Aqui você pode processar o pedido (salvar no banco, exibir, etc.)
        // //showmessage1('Pedido processado: ' + Pedido.ClienteNome);
      finally

      end;
    finally
      JSONObject.Free;
    end;
  except
    on E: Exception do
      //showmessage('Erro ao processar pedido: ' + E.Message);
  end;
  Qry.Close;
  Qry.SQL.Clear;
  Qry.SQL.Add
    ('select codigo from cliente where celular = :celular or cpf = :cpf order by codigo desc');
  Qry.ParamByName('celular').AsString := Pedido.ClienteCelular;
  Qry.ParamByName('cpf').AsString := Pedido.ClienteCPF;
  Qry.Open;

  if Qry.RecordCount > 0 then
  begin
    Pedido.CodigoCliente := Qry.FieldByName('codigo').AsInteger;
  end
  else
  begin
    Pedido.CodigoCliente := dm.GerarID('cliente', 'codigo');
    Tabela := dm.CriaTablea('cliente');
    Tabela.Insert;
    Tabela.FieldByName('codigo').AsInteger := Pedido.CodigoCliente;
    Tabela.FieldByName('nome').AsString := Pedido.ClienteNome;
    Tabela.FieldByName('celular').AsString := Pedido.ClienteCelular;
    Tabela.FieldByName('celular_wpp').AsString := Pedido.ClienteCelular;
    Tabela.FieldByName('cpf').AsString := Pedido.ClienteCPF;
    Tabela.FieldByName('ativo').AsInteger := 1;
    Tabela.FieldByName('origem').AsString := 'site';
    Tabela.Post;
    Tabela.Free;
  end;

  Qry.Close;
  Qry.SQL.Clear;
  Qry.SQL.Text :=
    'SELECT * FROM cliente_endereco where codigo_cliente = :codigo and rua = :rua and bairro = :bairro and numero = :numero';
  Qry.ParamByName('codigo').AsInteger := Pedido.CodigoCliente;
  Qry.ParamByName('bairro').AsString := Pedido.RemoveAcentos(Pedido.EnderecoBairro);
  Qry.ParamByName('rua').AsString := Pedido.RemoveAcentos(Pedido.EnderecoRua);
  Qry.ParamByName('numero').AsString := Pedido.EnderecoNumero;
  Qry.Open;

  if Qry.RecordCount > 0 then
  begin
    Pedido.CodigoEndereco := Qry.FieldByName('codigo').AsInteger;
  end
  else
  begin
    Pedido.CodigoEndereco := dm.GerarID('cliente_endereco', 'codigo');

    Tabela := dm.CriaTablea('cliente_endereco');
    Tabela.Insert;
    Tabela.FieldByName('codigo').AsInteger := Pedido.CodigoEndereco;
    Tabela.FieldByName('codigo_cliente').AsInteger := Pedido.CodigoCliente;
    Tabela.FieldByName('descricao').AsString := 'Principal';
    Tabela.FieldByName('tipo').AsString := '1';
    Tabela.FieldByName('ativo').AsString := '1';
    Tabela.FieldByName('numero').AsString := Pedido.EnderecoNumero;
    Tabela.FieldByName('rua').AsString := Pedido.EnderecoRua;
    Tabela.FieldByName('bairro').AsString := Pedido.EnderecoBairro;
    Tabela.FieldByName('cidade').AsString := Pedido.EnderecoCidade;
    Tabela.FieldByName('estado').AsString := Pedido.EnderecoEstado;
    Tabela.FieldByName('complemento').AsString := Pedido.EnderecoComplemento;
    Tabela.FieldByName('latitude').AsFloat := Pedido.Latitude;
    Tabela.FieldByName('longitude').AsFloat := Pedido.Longitude;
    Tabela.Post;
    Tabela.Free;

  end;



  // conexao.SQL.Add('select * from cliente where celular = :celular or cpf = :cpf order by codigo desc');
  // conexao.Parametros('celular',Pedido.ClienteCelular);
  // conexao.Parametros('cpf',Pedido.ClienteCPF);

  // conexao.Free;
  Pedido.Free;
end;

{ TProduto }

constructor TProduto.Create;
begin
  FExtras := TObjectList<TExtra>.Create;
end;

destructor TProduto.Destroy;
begin
  FExtras.Free;
  inherited;

end;

{ TPedido }

procedure TPedido.BuscaCliente;
begin

end;

function TPedido.RemoveAcentos(const Texto: string): string;
const
  ComAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  SemAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
var
  I: Integer;
  Posicao: Integer;
begin
  Result := Texto;
  for I := 1 to Length(Result) do
  begin
    Posicao := Pos(Result[I], ComAcento);
    if Posicao > 0 then
      Result[I] := SemAcento[Posicao];
  end;
  Result := UpperCase(Result);
end;

procedure TPedido.SetCodigoCliente(const Value: Integer);
begin
  FCodigoCliente := Value;
end;

procedure TPedido.SetCodigoEndereco(const Value: Integer);
begin
  FCodigoEndereco := Value;
end;

procedure TPedido.SetEnderecoBairro(const Value: String);
begin
  FEnderecoBairro := RemoveAcentos(Value);;
end;

procedure TPedido.SetEnderecoCidade(const Value: String);
begin
  FEnderecoCidade := RemoveAcentos(Value);;
end;

procedure TPedido.SetEnderecoComplemento(const Value: String);
begin
  FEnderecoComplemento := RemoveAcentos(Value);;
end;

procedure TPedido.SetEnderecoEstado(const Value: String);
begin
  FEnderecoEstado := RemoveAcentos(Value);;
end;

procedure TPedido.SetEnderecoNumero(const Value: String);
begin
  FEnderecoNumero := RemoveAcentos(Value);;
end;

procedure TPedido.SetEnderecoRua(const Value: String);
begin
  FEnderecoRua := RemoveAcentos(Value);
end;

procedure TPedido.SetProdutos(const Value: TObjectList<TProduto>);
begin
  FProdutos := Value;
end;

end.
