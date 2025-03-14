unit uToPedindo;

interface

uses
  System.Generics.Collections, REST.Json.Types, System.JSON, REST.Json;

type
  TCategoriaComplementosNaoPausados = class
  private
    FID: Integer;
    FNome: string;
    FOrdem: Integer;
    FQtdMinima: Integer;
    FQtdMaxima: Integer;
    FCodigo: Integer;
    procedure SetCodigo(const Value: Integer);
  public
    property Codigo : Integer read FCodigo write SetCodigo;
    property ID: Integer read FID write FID;
    property Nome: string read FNome write FNome;
    property Ordem: Integer read FOrdem write FOrdem;
    property QtdMinima: Integer read FQtdMinima write FQtdMinima;
    property QtdMaxima: Integer read FQtdMaxima write FQtdMaxima;
  end;

  TComplementoNaoPausado = class
  private
    FID: Integer;
    FNome: string;
    FIDComplementoCategoria: Integer;
    FPreco: string;
    FStatus: Integer;
    FQtdMinima: Integer;
    FQtdMaxima: Integer;
    FCodigo: Integer;
    FCategoria: Integer;
    FDescricao: String;
    procedure SetCodigo(const Value: Integer);
    procedure SetCategoria(const Value: Integer);
    procedure SetDescricao(const Value: String);
  public
    property Codigo : Integer read FCodigo write SetCodigo;
    property Categoria : Integer read FCategoria write SetCategoria;
    property ID: Integer read FID write FID;
    property Nome: string read FNome write FNome;
    property Descricao : String read FDescricao write SetDescricao;
    property IDComplementoCategoria: Integer read FIDComplementoCategoria write FIDComplementoCategoria;
    property Preco: string read FPreco write FPreco;
    property Status: Integer read FStatus write FStatus;
    property QtdMinima: Integer read FQtdMinima write FQtdMinima;
    property QtdMaxima: Integer read FQtdMaxima write FQtdMaxima;
  end;

  TDisponibilidade = class
  private
    FDom: Integer;
    FSeg: Integer;
    FTer: Integer;
    FQua: Integer;
    FQui: Integer;
    FSex: Integer;
    FSab: Integer;
  public
    property Dom: Integer read FDom write FDom;
    property Seg: Integer read FSeg write FSeg;
    property Ter: Integer read FTer write FTer;
    property Qua: Integer read FQua write FQua;
    property Qui: Integer read FQui write FQui;
    property Sex: Integer read FSex write FSex;
    property Sab: Integer read FSab write FSab;
  end;

  TCategoriaItem = class
  private
    FID: Integer;
    FNome: string;
    FOrdem: Integer;
    FStatus: Integer;
    FCodigo: Integer;
    FDescricao: String;
    procedure SetCodigo(const Value: Integer);
    procedure SetDescricao(const Value: String);
  public
    property ID: Integer read FID write FID;
    property Nome: string read FNome write FNome;
    property Ordem: Integer read FOrdem write FOrdem;
    property Status: Integer read FStatus write FStatus;
    property Codigo : Integer read FCodigo write SetCodigo;
    property Descricao : String read FDescricao write SetDescricao;
  end;

  TProdutoToPedindo = class
  private
    FNome: string;
    FDescricao: string;
    FURLImg: string;
    FPreco: Real;
    FOrdem: Integer;
    FStatus: Integer;
    FDisponivelPorPontos: Integer;
    FResgate: Boolean;
    [JSONReflect(ctTypeObject, rtTypeArray, nil, true)]
    FCategoriasComplementosNaoPausados: TObjectList<TCategoriaComplementosNaoPausados>;
    [JSONReflect(ctTypeObject, rtTypeArray, nil, true)]
    FComplementosNaoPausados: TObjectList<TComplementoNaoPausado>;
    [JsonName('disponibilidade')]
    FDisponibilidade: TDisponibilidade;
    [JsonName('categoria_item')]
    FCategoriaItem: TCategoriaItem;
    FID: integer;
    FCodigo: integer;
    FPorcentagemPromocional: Real;
    FPrecoComDescontoPromocional: Real;
    FValorPontos: Integer;
    FValorProduto: Real;
    FImage: String;
    procedure SetID(const Value: integer);
    procedure SetCodigo(const Value: integer);
    procedure SetPorcentagemPromocional(const Value: Real);
    procedure SetPrecoComDescontoPromocional(const Value: Real);
    procedure SetValorPontos(const Value: Integer);
    procedure SetValorProduto(const Value: Real);
    procedure SetImage(const Value: String);
  public
    property Codigo : integer read FCodigo write SetCodigo;
    property ID : integer read FID write SetID;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property URLImg: string read FURLImg write FURLImg;
    property Preco: Real read FPreco write FPreco;
    property Ordem: Integer read FOrdem write FOrdem;
    property Status: Integer read FStatus write FStatus;
    property DisponivelPorPontos: Integer read FDisponivelPorPontos write FDisponivelPorPontos;
    property Resgate: Boolean read FResgate write FResgate;
    property CategoriasComplementosNaoPausados: TObjectList<TCategoriaComplementosNaoPausados> read FCategoriasComplementosNaoPausados write FCategoriasComplementosNaoPausados;
    property ComplementosNaoPausados: TObjectList<TComplementoNaoPausado> read FComplementosNaoPausados write FComplementosNaoPausados;
    property Disponibilidade: TDisponibilidade read FDisponibilidade write FDisponibilidade;
    property CategoriaItem: TCategoriaItem read FCategoriaItem write FCategoriaItem;
    property PorcentagemPromocional : Real read FPorcentagemPromocional write SetPorcentagemPromocional;
    property PrecoComDescontoPromocional : Real read FPrecoComDescontoPromocional write SetPrecoComDescontoPromocional;
    property ValorPontos : Integer read FValorPontos write SetValorPontos;
    property ValorProduto : Real read FValorProduto write SetValorProduto;
    property Image : String read FImage write SetImage;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TProdutoToPedindo.Create;
begin
  FCategoriasComplementosNaoPausados := TObjectList<TCategoriaComplementosNaoPausados>.Create;
  FComplementosNaoPausados := TObjectList<TComplementoNaoPausado>.Create;
end;

destructor TProdutoToPedindo.Destroy;
begin
  FCategoriasComplementosNaoPausados.Free;
  FComplementosNaoPausados.Free;
  inherited;
end;

procedure TProdutoToPedindo.SetCodigo(const Value: integer);
begin
  FCodigo := Value;
end;

procedure TProdutoToPedindo.SetID(const Value: integer);
begin
  FID := Value;
end;

procedure TProdutoToPedindo.SetPorcentagemPromocional(const Value: Real);
begin
  FPorcentagemPromocional := Value;
end;

procedure TProdutoToPedindo.SetPrecoComDescontoPromocional(const Value: Real);
begin
  FPrecoComDescontoPromocional := Value;
end;

procedure TProdutoToPedindo.SetValorPontos(const Value: Integer);
begin
  FValorPontos := Value;
end;

procedure TProdutoToPedindo.SetValorProduto(const Value: Real);
begin
  FValorProduto := Value;
end;

procedure TProdutoToPedindo.SetImage(const Value: String);
begin
  FImage := Value;
end;

{ TCategoriaComplementosNaoPausados }

procedure TCategoriaComplementosNaoPausados.SetCodigo(const Value: Integer);
begin
  FCodigo := Value;
end;

{ TComplementoNaoPausado }

procedure TComplementoNaoPausado.SetCategoria(const Value: Integer);
begin
  FCategoria := Value;
end;

procedure TComplementoNaoPausado.SetCodigo(const Value: Integer);
begin
  FCodigo := Value;
end;

procedure TComplementoNaoPausado.SetDescricao(const Value: String);
begin
  FDescricao := Value;
end;

{ TCategoriaItem }

procedure TCategoriaItem.SetCodigo(const Value: Integer);
begin
 FCodigo := Value;
end;

procedure TCategoriaItem.SetDescricao(const Value: String);
begin
  FDescricao := Value;
end;

end.

