unit uClassProduto;

interface

uses uBotConversa, FireDAC.Comp.Client, uPrincipal, System.SysUtils,
  uClassPizza, uClassAdicionais,Dialogs;

type

  TTipoProduto = (Simples, AdicionarRemover, Configuravel, Pizza);

  TSeparadoPorVirgula = class
  public
    Separados: Array of Integer;

    function Retorno(Index: Integer): Integer;
  end;

  TProduto = class
  private
    FControlaEstoque: Boolean;
    FSaldoEstoque: Integer;
    FValor: Real;
    FAtivo: Boolean;
    FDescricao: String;
    FNome: String;
    FTipo: TTipoProduto;
    FCodigo: Integer;
    FPizza: TConfiguracaoPizza;
    FDescricaoCategoria: String;
    FCodigoCategoria: Integer;
    FInformaObs: Boolean;
    FValorComBaseAdicional: Boolean;
    FInfoAdicional: TConfiguracaoAdicional;
    FValorEmbalagemDelivery: Real;
    FValorEmbalagemVembuscar: Real;
    FValorAtual: Real;
    procedure SetAtivo(const Value: Boolean);
    procedure SetControlaEstoque(const Value: Boolean);
    procedure SetDescricao(const Value: String);
    procedure SetNome(const Value: String);
    procedure SetSaldoEstoque(const Value: Integer);
    procedure SetTipo(const Value: TTipoProduto);
    procedure SetValor(const Value: Real);

    function LocalizaTipoProduto(Codigo: Integer): TTipoProduto;

    function TabelaPreco(Codigo: Integer; Valor: Real): Real;
    procedure SetCodigo(const Value: Integer);

    function DiaDaSemana: String;
    procedure CadastraTabela(Codigo: Integer; Valor: Real);
    procedure SetPizza(const Value: TConfiguracaoPizza);

    function DadosPizza(Codigo: Integer): TConfiguracaoPizza;
    function DadosAdicional(Codigo: Integer): TConfiguracaoAdicional;
    procedure SetCodigoCategoria(const Value: Integer);
    procedure SetDescricaoCategoria(const Value: String);
    procedure SetInformaObs(const Value: Boolean);
    procedure SetValorComBaseAdicional(const Value: Boolean);
    procedure SetInfoAdicional(const Value: TConfiguracaoAdicional);

    procedure SetValorEmbalagemDelivery(const Value: Real);
    procedure SetValorEmbalagemVembuscar(const Value: Real);
    procedure SetValorAtual(const Value: Real);

    function UpperCaseN(aText: string): string;

  public
    property Codigo: Integer read FCodigo write SetCodigo;
    property Nome: String read FNome write SetNome;
    property Descricao: String read FDescricao write SetDescricao;
    property Valor: Real read FValor write SetValor;
    property Tipo: TTipoProduto read FTipo write SetTipo;
    property SaldoEstoque: Integer read FSaldoEstoque write SetSaldoEstoque;
    property ControlaEstoque: Boolean read FControlaEstoque
      write SetControlaEstoque;
    property Ativo: Boolean read FAtivo write SetAtivo;
    property CodigoCategoria: Integer read FCodigoCategoria
      write SetCodigoCategoria;
    property DescricaoCategoria: String read FDescricaoCategoria
      write SetDescricaoCategoria;
    property InformaObs: Boolean read FInformaObs write SetInformaObs;
    property ValorAtual: Real read FValorAtual write SetValorAtual;
    property InfoPizza: TConfiguracaoPizza read FPizza write SetPizza;
    property InfoAdicional: TConfiguracaoAdicional read FInfoAdicional
      write SetInfoAdicional;
    property ValorComBaseAdicional: Boolean read FValorComBaseAdicional
      write SetValorComBaseAdicional;

    property ValorEmbalagemDelivery: Real read FValorEmbalagemDelivery
      write SetValorEmbalagemDelivery;
    property ValorEmbalagemVembuscar: Real read FValorEmbalagemVembuscar
      write SetValorEmbalagemVembuscar;

    function LocalizaProduto(Codigo: Integer; Conversa: TBotConversa): TProduto;

    function SeparadoPorVirgula(Valor: String): TSeparadoPorVirgula;
    function BuscaProduto(Codigo: Integer): TProduto;
  end;

  TProdutoArray = class
  public
    procedure AdicionaProduto;
    function RetornaProduto(CodigoProduto: Integer): TProduto;

  var
    ProdutosArray: Array of TProduto;
    HoraArray: Array of TTime;

  end;

implementation

{ TProduto }

uses udmProdutos;

function TProduto.BuscaProduto(Codigo: Integer): TProduto;
begin

  Result := TProduto.Create;
  dmPrincipal.CriaQRY('CONSPRO').Close;
  dmPrincipal.CriaQRY('CONSPRO').SQL.Clear;
  dmPrincipal.CriaQRY('CONSPRO')
    .SQL.Add('select p.*, p.descricao as nome_grupo from produto as p');
  dmPrincipal.CriaQRY('CONSPRO')
    .SQL.Add('join tipo_produto as t on t.codigo = p.codigo_grupo');
  dmPrincipal.CriaQRY('CONSPRO')
    .SQL.Add('where p.codigo = ' + IntToStr(Codigo));
  // dmPrincipal.CriaQRY('CONSPRO').SQL.Add('select * from produto where codigo = '
  // + IntToStr(Codigo));
  dmPrincipal.CriaQRY('CONSPRO').Open;

  if dmPrincipal.CriaQRY('CONSPRO').RecNo = 0 then
    exit;

  Result.ValorEmbalagemVembuscar := dmPrincipal.CriaQRY('CONSPRO')
    .FieldByName('valor_embalagem_vembusca').AsFloat;

  Result.ValorEmbalagemDelivery := dmPrincipal.CriaQRY('CONSPRO')
    .FieldByName('valor_embalagem_delivery').AsFloat;

  Result.DescricaoCategoria := UpperCaseN(dmPrincipal.CriaQRY('CONSPRO').FieldByName('nome_grupo').AsString);

  Result.CodigoCategoria := dmPrincipal.CriaQRY('CONSPRO')
    .FieldByName('codigo_grupo').AsInteger;

  Result.Nome := trim(UpperCaseN(dmPrincipal.CriaQRY('CONSPRO').FieldByName('nome_produto').AsString));
  Result.Descricao := dmPrincipal.CriaQRY('CONSPRO')
    .FieldByName('descricao').AsString;
  Result.Valor := dmPrincipal.CriaQRY('CONSPRO')
    .FieldByName('valor_venda').AsFloat;

  Result.InformaObs := dmPrincipal.CriaQRY('CONSPRO').FieldByName('observacao')
    .AsInteger = 1;
  Result.Codigo := Codigo;
  Result.Tipo := LocalizaTipoProduto(Codigo);

  Result.Ativo := dmPrincipal.CriaQRY('CONSPRO').FieldByName('ativo')
    .AsInteger = 1;

  if not Result.Ativo then
    Result.Ativo := dmPrincipal.CriaQRY('CONSPRO')
      .FieldByName('valor_calculado_no_adicional').AsInteger = 1;

  // Retornar as configuraÁıes das pizzas
  Result.InfoPizza := DadosPizza(Codigo);

  // usa_tabela_preco
  if dmPrincipal.CriaQRY('CONSPRO').FieldByName('usa_tabela_preco').AsInteger = 1
  then
  begin
    Result.Valor := TabelaPreco(Codigo, Result.Valor);
  end;

  Result.InfoAdicional := DadosAdicional(Codigo);

  Result.SaldoEstoque := 0;
  Result.ControlaEstoque := False;

  if (Result.Valor = 0) or (Result.Valor < 0) then
  begin
    Result.Ativo := False;
    try
      if dmPrincipal.CriaQRY('CONSPRO')
        .FieldByName('valor_calculado_no_adicional').AsInteger = 1 then
        Result.Ativo := true;
    except

    end;
  end;
  if Result.Ativo then
    Result.Valor := Result.Valor;

  if Result.ValorAtual = 0 then
  begin
    Result.ValorAtual := Result.Valor;
  end;
  Result.Valor := Result.ValorAtual;

end;

procedure TProduto.CadastraTabela(Codigo: Integer; Valor: Real);
var
  Tabela: TFDTable;
begin
  Tabela := dmPrincipal.CriaTabela('produto_preco');
  Tabela.Insert;
  Tabela.FieldByName('id').AsInteger :=
    dmPrincipal.GerarID('produto_preco', 'id');
  Tabela.FieldByName('id_produto').AsInteger := Codigo;
  Tabela.FieldByName('valor').AsFloat := Valor;
  Tabela.FieldByName('segunda').AsInteger := 1;
  Tabela.FieldByName('terca').AsInteger := 1;
  Tabela.FieldByName('quarta').AsInteger := 1;
  Tabela.FieldByName('quinta').AsInteger := 1;
  Tabela.FieldByName('sexta').AsInteger := 1;
  Tabela.FieldByName('sabado').AsInteger := 1;
  Tabela.FieldByName('domingo').AsInteger := 1;
  Tabela.FieldByName('hora_inicial').AsDateTime := StrToTime('00:00:00');
  Tabela.FieldByName('hora_final').AsDateTime := StrToTime('23:59:59');
  Tabela.Post;
  Tabela.Free;
end;

function TProduto.DadosAdicional(Codigo: Integer): TConfiguracaoAdicional;
var
  Index: Integer;

begin
  try
    if Result = nil then
      Result := TConfiguracaoAdicional.Create;

    dmPrincipal.CriaQRY('ADICIONAL').Close;
    dmPrincipal.CriaQRY('ADICIONAL').SQL.Clear;
    dmPrincipal.CriaQRY('ADICIONAL')
      .SQL.Add('SELECT * FROM pro_adi_personalizado where id_produto = ' +
      IntToStr(Codigo));
    dmPrincipal.CriaQRY('ADICIONAL').Open;
    while not dmPrincipal.CriaQRY('ADICIONAL').Eof do
    begin
      Index := Result.AdicionaMae(UpperCaseN(dmPrincipal.CriaQRY('ADICIONAL').FieldByName('descricao').AsString), dmPrincipal.CriaQRY('ADICIONAL')
        .FieldByName('qtd_maxima').AsInteger, dmPrincipal.CriaQRY('ADICIONAL')
        .FieldByName('qtd_minima').AsInteger);

      dmPrincipal.CriaQRY('ADICIONALI').Close;
      dmPrincipal.CriaQRY('ADICIONALI').SQL.Clear;
      dmPrincipal.CriaQRY('ADICIONALI')
        .SQL.Add('SELECT * FROM pro_adi_personalizado_sabores where id_pro_adi_personalizado = '
        + dmPrincipal.CriaQRY('ADICIONAL').FieldByName('id').AsString);
      dmPrincipal.CriaQRY('ADICIONALI').Open;

      while not dmPrincipal.CriaQRY('ADICIONALI').Eof do
      begin
        Result.AdicionaItem(Index,
        UpperCaseN(dmPrincipal.CriaQRY('ADICIONALI').FieldByName('nome').AsString),
        dmPrincipal.CriaQRY('ADICIONALI').FieldByName('descricao').AsString,
        dmPrincipal.CriaQRY('ADICIONALI').FieldByName('valor').AsFloat);
        dmPrincipal.CriaQRY('ADICIONALI').Next;
      end;

      dmPrincipal.CriaQRY('ADICIONAL').Next;
    end;
    dmPrincipal.CriaQRY('ADICIONAL').Free;
    dmPrincipal.CriaQRY('ADICIONALI').Free;
  except
    Result := DadosAdicional(Codigo);
  end;
end;

function TProduto.DadosPizza(Codigo: Integer): TConfiguracaoPizza;
var
  Qry: TFDQuery;
begin
  //
  try
    if Result = nil then
      Result := TConfiguracaoPizza.Create;

    Qry := dmPrincipal.CriaQRY('PIZZA');

    Qry.Close;
    Qry.SQL.Clear;
    Qry.SQL.Add
      ('SELECT sc.nome as sabor, sc.descricao,sc.vl_venda, tp.nome as tipo_sabor FROM sabores_completo sc');
    Qry.SQL.Add('inner join tipo_sabor as tp on tp.id = sc.id_tipo_sabor');
    Qry.SQL.Add
      ('where sc.ativo = 1 and tp.ativo = 1 and sc.vl_venda > 0 and sc.id_produto = '
      + IntToStr(Codigo) + ' order by sc.id_tipo_sabor');
    Qry.Open;

    while not Qry.Eof do
    begin
      // Tipo, Sabor, Descricao, Valor
      Result.AdicionaSabor(UpperCaseN(Qry.FieldByName('tipo_sabor').AsString),
        UpperCaseN(Qry.FieldByName('sabor').AsString), (Qry.FieldByName('descricao')
        .AsString), Qry.FieldByName('vl_venda').AsFloat);
      Qry.Next;
    end;

    Qry.Close;
    Qry.SQL.Clear;
    Qry.SQL.Add('select b.descricao,b.valor from produto_pizza_borda as p');
    Qry.SQL.Add('join borda as b on b.codigo = p.codigo_borda');
    Qry.SQL.Add('where p.codigo_produto = ' + IntToStr(Codigo));
    Qry.Open;

    while not Qry.Eof do
    begin
      Result.AdicionaBorda(UpperCaseN(Qry.FieldByName('descricao').AsString),
        Qry.FieldByName('valor').AsFloat);
      Qry.Next;
    end;

    Qry.Close;
    Qry.SQL.Clear;
    Qry.SQL.Add('SELECT * FROM produto_pizza where codigo_produto = ' +
      IntToStr(Codigo));
    Qry.Open;

    Result.MaximoSabores := Qry.FieldByName('quantidade_sabores').AsInteger;
    Qry.Free;
  except
    Qry.Free;
    Result := DadosPizza(Codigo);
  end;
end;

function TProduto.DiaDaSemana: String;
begin
  case DayOfWeek(date) of
    1:
      Result := 'domingo';
    2:
      Result := 'segunda';
    3:
      Result := 'terca';
    4:
      Result := 'quarta';
    5:
      Result := 'quinta';
    6:
      Result := 'sexta';
    7:
      Result := 'sabado';

  end;
end;

function TProduto.LocalizaProduto(Codigo: Integer; Conversa: TBotConversa)
  : TProduto;
begin

//  Result := dmProdutos.ProdutosArrayGeral.RetornaProduto(Codigo);
//  Result.Valor := Result.ValorAtual;
//
//  if Result = nil then
    Result := BuscaProduto(Codigo);


  // Aki buscar do array

  case Conversa.CodigoEndereco of
    0:
      begin
        if Result.Ativo then
        begin
          Result.Valor := Result.Valor + Result.ValorEmbalagemVembuscar;
        end;
      end
  else
    begin
      if Result.Ativo then
      begin
        Result.Valor := Result.Valor + Result.ValorEmbalagemDelivery;
      end;
    end;
  end;
end;

function TProduto.LocalizaTipoProduto(Codigo: Integer): TTipoProduto;
begin
  // SELECT * FROM produto_ingredientes where codigo_produto = X
  Result := Simples;

  dmPrincipal.CriaQRY('LTP').Close;
  dmPrincipal.CriaQRY('LTP').SQL.Clear;
  dmPrincipal.CriaQRY('LTP')
    .SQL.Add('SELECT * FROM pro_adi_personalizado where id_produto = ' +
    IntToStr(Codigo));
  dmPrincipal.CriaQRY('LTP').Open;
  if dmPrincipal.CriaQRY('LTP').RecordCount > 0 then
    Result := Configuravel;

  dmPrincipal.CriaQRY('LTP').Close;
  dmPrincipal.CriaQRY('LTP').SQL.Clear;
  dmPrincipal.CriaQRY('LTP')
    .SQL.Add('SELECT * FROM sabores_completo where id_produto = ' +
    IntToStr(Codigo));
  dmPrincipal.CriaQRY('LTP').Open;
  if dmPrincipal.CriaQRY('LTP').RecordCount > 0 then
    Result := Pizza;

end;

function TProduto.SeparadoPorVirgula(Valor: String): TSeparadoPorVirgula;
var
  I: Integer;
  Aux: String;
begin
  SetLength(Result.Separados, 0);
  if Result = nil then
    Result := TSeparadoPorVirgula.Create;
  for I := 1 to length(Valor) do
  begin
    if Valor[I] = ',' then
    begin
      if trim(Aux) <> '' then
      begin
        try
          if StrToInt(Aux) > 0 then
          begin
            SetLength(Result.Separados, length(Result.Separados) + 1);
            Result.Separados[length(Result.Separados) - 1] := StrToInt(Aux);
          end;
        except

        end;
      end;
      Aux := '';
    end
    else
    begin
      Aux := Aux + Valor[I];
    end;
  end;
  if Aux <> '' then
  begin

    SetLength(Result.Separados, length(Result.Separados) + 1);
    Result.Separados[length(Result.Separados) - 1] := StrToInt(Aux);
  end;

end;

procedure TProduto.SetAtivo(const Value: Boolean);
begin
  FAtivo := Value;
end;

procedure TProduto.SetCodigo(const Value: Integer);
begin
  FCodigo := Value;
end;

procedure TProduto.SetCodigoCategoria(const Value: Integer);
begin
  FCodigoCategoria := Value;
end;

procedure TProduto.SetControlaEstoque(const Value: Boolean);
begin
  FControlaEstoque := Value;
end;

procedure TProduto.SetDescricao(const Value: String);
begin
  FDescricao := Value;
end;

procedure TProduto.SetDescricaoCategoria(const Value: String);
begin
  FDescricaoCategoria := Value;
end;

procedure TProduto.SetInfoAdicional(const Value: TConfiguracaoAdicional);
begin
  FInfoAdicional := Value;
end;

procedure TProduto.SetInformaObs(const Value: Boolean);
begin
  FInformaObs := Value;
end;

procedure TProduto.SetNome(const Value: String);
begin
  FNome := Value;
end;

procedure TProduto.SetPizza(const Value: TConfiguracaoPizza);
begin
  FPizza := Value;
end;

procedure TProduto.SetSaldoEstoque(const Value: Integer);
begin
  FSaldoEstoque := Value;
end;

procedure TProduto.SetTipo(const Value: TTipoProduto);
begin
  FTipo := Value;
end;

procedure TProduto.SetValor(const Value: Real);
begin
  FValor := Value;
end;

procedure TProduto.SetValorAtual(const Value: Real);
begin
  FValorAtual := Value;
end;

procedure TProduto.SetValorComBaseAdicional(const Value: Boolean);
begin
  FValorComBaseAdicional := Value;
end;

procedure TProduto.SetValorEmbalagemDelivery(const Value: Real);
begin
  FValorEmbalagemDelivery := Value;
end;

procedure TProduto.SetValorEmbalagemVembuscar(const Value: Real);
begin
  FValorEmbalagemVembuscar := Value;
end;

function TProduto.TabelaPreco(Codigo: Integer; Valor: Real): Real;
var
  QryCpnsulta: TFDQuery;
  HoraIni: TTime;
  HoraFim: TTime;
  HoraAtual: TTime;
begin
  Result := Valor;
  try
    QryCpnsulta := dmPrincipal.CriaQRY('PRODPRECO');
    QryCpnsulta.Close;
    QryCpnsulta.SQL.Clear;
    QryCpnsulta.SQL.Add('select * from produto_preco where id_produto = ' +
      IntToStr(Codigo) + ' and ' + DiaDaSemana +
      ' = 1 order by id desc limit 1');
    QryCpnsulta.Open;

    Result := 0;
    while not QryCpnsulta.Eof do
    begin
      HoraIni := QryCpnsulta.FieldByName('hora_inicial').AsDateTime;
      HoraFim := QryCpnsulta.FieldByName('hora_final').AsDateTime;
      HoraAtual := Time;
      if (HoraAtual > HoraIni) and (HoraFim > HoraAtual) then
      begin

        // Pega o valor
        Result := QryCpnsulta.FieldByName('valor').AsFloat;
        Valor := QryCpnsulta.FieldByName('valor').AsFloat;
      end;
      QryCpnsulta.Next;
    end;
    if QryCpnsulta.RecordCount = 0 then
    begin
      Result := Valor;
      QryCpnsulta.Free;
      exit;
      // Cadastra a tabela
      CadastraTabela(Codigo, Valor);
      QryCpnsulta.Free;
      Result := TabelaPreco(Codigo, Valor);
      exit;
    end;
    QryCpnsulta.Free;
  except
    Result := TabelaPreco(Codigo, Valor);
    exit;
  end;
end;

function TProduto.UpperCaseN(aText: string): string;
  const
    ComAcento = '‡‚ÍÙ˚„ı·ÈÌÛ˙Á¸Ò˝¿¬ ‘€√’¡…Õ”⁄«‹—›';
    SemAcento = '¿¬ ‘€√’¡…Õ”⁄«‹—›¿¬ ‘€√’¡…Õ”⁄«‹—›';
  var
    X: Cardinal;
  begin;
    for X := 1 to length(aText) do
      try
        if (Pos(aText[X], ComAcento) <> 0) then
          aText[X] := SemAcento[Pos(aText[X], ComAcento)];
      except
        on E: Exception do
          raise Exception.Create('Erro no processo.');
      end;

    Result := uppercase(aText);
  end;

{ TSeparadoPorVirgula }

function TSeparadoPorVirgula.Retorno(Index: Integer): Integer;
begin
  Result := Separados[Index];
end;

{ TProdutoArray }

procedure TProdutoArray.AdicionaProduto;
var
  Index: Integer;

  Produto: TProduto;
begin

  dmPrincipal.CriaQRY('PRO').Close;
  dmPrincipal.CriaQRY('PRO').SQL.Clear;
  dmPrincipal.CriaQRY('PRO').SQL.Add('select * from produto where ativo = 1');
  dmPrincipal.CriaQRY('PRO').Open;


  // SetLength(ProdutosArray, dmPrincipal.CriaQRY('PRO').RecordCount);
  Index := 0;

  while not dmPrincipal.CriaQRY('PRO').Eof do
  begin
    SetLength(ProdutosArray, Index + 1);
    ProdutosArray[Index] := Produto.BuscaProduto(dmPrincipal.CriaQRY('PRO')
      .FieldByName('codigo').AsInteger);
    Inc(Index);
    dmPrincipal.CriaQRY('PRO').Next;
  end;


end;

function TProdutoArray.RetornaProduto(CodigoProduto: Integer): TProduto;
var
  I: Integer;
begin

  for I := 0 to length(ProdutosArray) - 1 do
  begin
    if ProdutosArray[I].Codigo = CodigoProduto then
    begin
      Result := ProdutosArray[I];
      break;
    end;
  end;

end;

end.
