unit uMontaPedido;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.StrUtils,
  Data.DB, System.Generics.Collections,uImportacaoPedio;

function BuildPedidoJSON(const mtPedido, mtProdutos: TDataSet): TJSONObject;

implementation

function StripAccentsUpper(const S: string): string;
const
  FromChars = 'ÁÀÂÃÄáàâãäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÕÖóòôõöÚÙÛÜúùûüÇç';
  ToChars = 'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCc';
var
  I, P: Integer;
  C: Char;
  Tmp: string;
begin
  Tmp := S;
  for I := 1 to Length(Tmp) do
  begin
    C := Tmp[I];
    P := Pos(C, FromChars);
    if P > 0 then
      Tmp[I] := ToChars[P];
  end;
  Result := UpperCase(Tmp);
end;

function IsObservacaoCategoria(const Categoria: string): Boolean;
var
  Norm: string;
begin
  Norm := StripAccentsUpper(Trim(Categoria));
  // cobre: Observacao, Observações, OBSERVAÇÃO, etc.
  Result := (Norm = 'OBSERVACAO') or (Norm = 'OBSERVACOES') or (Norm = 'OBS') or
    (Pos('OBSERVAC', Norm) = 1); // começa com OBSERVAC...
end;

function FieldAsStringSafe(DS: TDataSet; const Name: string;
  const Default: string = ''): string;
var
  F: TField;
begin
  F := DS.FindField(Name);
  if Assigned(F) and not F.IsNull then
    Result := F.AsString
  else
    Result := Default;
end;

function FieldAsFloatSafe(DS: TDataSet; const Name: string;
  const Default: Double = 0): Double;
var
  F: TField;
begin
  F := DS.FindField(Name);
  if Assigned(F) and not F.IsNull then
    Result := F.AsFloat
  else
    Result := Default;
end;

function FieldAsIntSafe(DS: TDataSet; const Name: string;
  const Default: Integer = 0): Integer;
var
  F: TField;
begin
  F := DS.FindField(Name);
  if Assigned(F) and not F.IsNull then
    Result := F.AsInteger
  else
    Result := Default;
end;

type
  TProdutoAgg = class
  public
    IdProduto: Integer;
    Nome: string;
    Valor: Double;
    Quantidade: Integer;
    Observacao: string;
    Extras: TJSONArray; // de objetos {categoria,nome,quantidade,valor}
    constructor Create;
    destructor Destroy; override;
  end;

constructor TProdutoAgg.Create;
begin
  Extras := TJSONArray.Create;
end;

destructor TProdutoAgg.Destroy;
begin
  Extras.Free;
  inherited;
end;

function BuildPedidoJSON(const mtPedido, mtProdutos: TDataSet): TJSONObject;
var
  root, cliente, endereco, pagamento, totalizador, other: TJSONObject;
  produtosArr: TJSONArray;
  // agregação
  map: TObjectDictionary<Integer, TProdutoAgg>;
  prodKey: Integer;
  agg: TProdutoAgg;
  // campos auxiliares
  cpf, nasc, Nome, cel: string;
  CodigoPedido, CodigoDia : String;
  rua, bairro, cidade, uf, numero, complemento: string;
  tipoPagamento: string;
  totProdutos, totEntrega, totDesconto, totTotal, trocoValor: Double;
  statusPedido : String;
  // loop produtos
  objExtra: TJSONObject;
  observacaoCat, nomeExtra, catExtra: string;
  qtdExtra: Integer;
  valorExtra: Double;
  // saída produto
  produtoJSON: TJSONObject;
begin
  root := TJSONObject.Create;
  try
    // === 1) Pedido (dataset único) ===
    if not Assigned(mtPedido) or (mtPedido.IsEmpty) then
      raise Exception.Create('Dataset de pedido vazio/nulo.');

    // garante estar posicionado
    mtPedido.First;

    // cliente
    cpf := FieldAsStringSafe(mtPedido, 'cpf');
    nasc := FieldAsStringSafe(mtPedido, 'data_nascimento');
    // já no formato dd/mm/yyyy conforme sua origem
    Nome := FieldAsStringSafe(mtPedido, 'nome');
    cel := FieldAsStringSafe(mtPedido, 'celular');
//    cel := '48998111156';
    statusPedido := FieldAsStringSafe(mtPedido, 'statusPedido');

    CodigoPedido := FieldAsStringSafe(mtPedido, 'codigo');
    CodigoDia := FormatFloat('000',FieldAsIntSafe(mtPedido,'codigoDia'));

    cliente := TJSONObject.Create;
    cliente.AddPair('cpf', TJSONString.Create(cpf));
    cliente.AddPair('nascimento', TJSONString.Create(nasc));
    cliente.AddPair('nome', TJSONString.Create(Nome));
    cliente.AddPair('celular', TJSONString.Create(cel));
    root.AddPair('cliente', cliente);

    // endereço
    rua := FieldAsStringSafe(mtPedido, 'rua');
    bairro := FieldAsStringSafe(mtPedido, 'bairro');
    cidade := FieldAsStringSafe(mtPedido, 'cidade');
    uf := FieldAsStringSafe(mtPedido, 'uf', FieldAsStringSafe(mtPedido,
      'estado')); // fallback
    numero := FieldAsStringSafe(mtPedido, 'numero');
    complemento := FieldAsStringSafe(mtPedido, 'complemento');

    endereco := TJSONObject.Create;
    endereco.AddPair('rua', TJSONString.Create(rua));
    endereco.AddPair('bairro', TJSONString.Create(bairro));
    endereco.AddPair('cidade', TJSONString.Create(cidade));
    endereco.AddPair('uf', TJSONString.Create(uf));
    endereco.AddPair('numero', TJSONString.Create(numero));
    endereco.AddPair('complemento', TJSONString.Create(complemento));
    root.AddPair('endereco', endereco);

    // pagamento
    tipoPagamento := FieldAsStringSafe(mtPedido, 'tipoPagamento');
    trocoValor := FieldAsFloatSafe(mtPedido, 'totalizadorTroco',
      FieldAsFloatSafe(mtPedido, 'troco')); // alias alternativo
    pagamento := TJSONObject.Create;
    pagamento.AddPair('descricao', TJSONString.Create(tipoPagamento));
    pagamento.AddPair('troco', TJSONBool.Create(trocoValor > 0.0001));
    root.AddPair('pagamento', pagamento);

    // totalizador (com fallback se vier alias duplicado)
    totProdutos := FieldAsFloatSafe(mtPedido, 'totalizadorProdutos',
      FieldAsFloatSafe(mtPedido, 'totalizadorProdutos'));
    totEntrega := FieldAsFloatSafe(mtPedido, 'totalizadorEntrega',
      FieldAsFloatSafe(mtPedido, 'totalizadorEntrega'));
    totDesconto := FieldAsFloatSafe(mtPedido, 'totalizadorDesconto',
      FieldAsFloatSafe(mtPedido, 'totalizadorDesconto'));

    // tentar pegar total direto; se não vier, calcular
    totTotal := FieldAsFloatSafe(mtPedido, 'totalizadorPedido', 0);

    totalizador := TJSONObject.Create;
    totalizador.AddPair('produtos', TJSONNumber.Create(totProdutos));
    totalizador.AddPair('entrega', TJSONNumber.Create(totEntrega));
    totalizador.AddPair('desconto', TJSONNumber.Create(totDesconto));
    totalizador.AddPair('total', TJSONNumber.Create(totTotal));
    totalizador.AddPair('troco', TJSONNumber.Create(trocoValor));
    root.AddPair('totalizador', totalizador);

    // === 2) Itens agregados por codigoAgrupamentoProduto ===
    if not Assigned(mtProdutos) then
      raise Exception.Create('Dataset de produtos nulo.');

    map := TObjectDictionary<Integer, TProdutoAgg>.Create([doOwnsValues]);
    try
      mtProdutos.First;
      while not mtProdutos.Eof do
      begin
        prodKey := FieldAsIntSafe(mtProdutos, 'codigoAgrupamentoProduto');

        if not map.TryGetValue(prodKey, agg) then
        begin
          agg := TProdutoAgg.Create;
          agg.IdProduto := FieldAsIntSafe(mtProdutos, 'idProduto');
          agg.Nome := FieldAsStringSafe(mtProdutos, 'nomeProduto');
          agg.Valor := FieldAsFloatSafe(mtProdutos, 'valorProduto');
          agg.Quantidade := FieldAsIntSafe(mtProdutos, 'quantidadeProduto', 1);
          agg.Observacao := '';
          map.Add(prodKey, agg);
        end;

        // tratar extras/observação (left join pode trazer nulos)
        catExtra := FieldAsStringSafe(mtProdutos, 'categoriaExtra');
        nomeExtra := FieldAsStringSafe(mtProdutos, 'nomeExtra');
        qtdExtra := FieldAsIntSafe(mtProdutos, 'quantidadeExtra', 1);
        valorExtra := FieldAsFloatSafe(mtProdutos, 'valorExtra', 0);

        if (Trim(catExtra) <> '') and (Trim(nomeExtra) <> '') then
        begin
          if IsObservacaoCategoria(catExtra) then
          begin
            if agg.Observacao <> '' then
              agg.Observacao := agg.Observacao + '; ';
            agg.Observacao := agg.Observacao + nomeExtra;
          end
          else
          begin
            objExtra := TJSONObject.Create;
            objExtra.AddPair('categoria', TJSONString.Create(catExtra));
            objExtra.AddPair('nome', TJSONString.Create(nomeExtra));
            objExtra.AddPair('quantidade', TJSONNumber.Create(qtdExtra));
            objExtra.AddPair('valor', TJSONNumber.Create(valorExtra));
            agg.Extras.AddElement(objExtra);
          end;
        end;

        mtProdutos.Next;
      end;

      // montar array "produtos"
      produtosArr := TJSONArray.Create;
      for agg in map.Values do
      begin
        produtoJSON := TJSONObject.Create;
        produtoJSON.AddPair('id', TJSONNumber.Create(agg.IdProduto));
        produtoJSON.AddPair('nome', TJSONString.Create(agg.Nome));
        produtoJSON.AddPair('valor', TJSONNumber.Create(agg.Valor));
        produtoJSON.AddPair('quantidade', TJSONNumber.Create(agg.Quantidade));
        produtoJSON.AddPair('observacao', TJSONString.Create(agg.Observacao));
        // clonar extras (para não transferir ownership do objeto interno):
//        produtoJSON.AddPair('extra',
//          TJSONArray.Create(agg.Extras.Clone as TJSONArray));
        produtoJSON.AddPair('extra', agg.Extras);
        agg.Extras := nil;
        produtosArr.AddElement(produtoJSON);
      end;
      root.AddPair('produtos', produtosArr);
    finally
      map.Free; // libera TProdutoAgg e seus TJSONArray internos
    end;

    // campos finais fixos do seu layout
    root.AddPair('site', TJSONBool.Create(False));

    other := TJSONObject.Create;
    other.AddPair('partner', TJSONString.Create('PDV'));
    other.AddPair('codigoDia', CodigoDia);
    other.AddPair('codigoPedido',CodigoPedido);
    other.AddPair('statusPedido',statusPedido);
    root.AddPair('other', other);
    root.AddPair('empresa',UserID);

    Result := root; // transferimos ownership
    root := nil;
  finally
    root.Free; // no-op se Result já levou ownership
  end;
end;

end.
