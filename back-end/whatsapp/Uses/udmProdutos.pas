unit udmProdutos;

interface

uses
  System.SysUtils, System.Classes, uClassProduto;

type
  TdmProdutos = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
  private
    FProdutosArrayGeral: TProdutoArray;
    procedure SetProdutosArrayGeral(const Value: TProdutoArray);
    { Private declarations }
  public
    { Public declarations }
    property   ProdutosArrayGeral: TProdutoArray read FProdutosArrayGeral write SetProdutosArrayGeral;
  end;

var
  dmProdutos: TdmProdutos;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmProdutos.DataModuleCreate(Sender: TObject);
begin
  ProdutosArrayGeral := TProdutoArray.create;
  ProdutosArrayGeral.AdicionaProduto;
end;

procedure TdmProdutos.SetProdutosArrayGeral(const Value: TProdutoArray);
begin
  FProdutosArrayGeral := Value;
end;

end.
