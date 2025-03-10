unit Pedido;

interface

uses
  System.Generics.Collections, System.SysUtils;

type
  TProduto = class
  public
    id: Integer;
    idProduto: Integer;
    nomeProduto: string;
    valorProduto: Double;
    quantidade: Integer;
    valorUnitario: Double;
    valorTotal: Double;
    observacao: string;
    extra: TArray<TPair<Integer, Double>>;
  end;

  TCliente = class
  public
    celular: string;
    cliente: string;
    cpf: string;
    nascimento: string;
  end;

  TPagamento = class
  public
    descricao: string;
  end;

  TEndereco = class
  public
    rua: string;
    bairro: string;
    cidade: string;
    estado: string;
    numero: Integer;
    complemento: string;
  end;

  TValores = class
  public
    produtos: Double;
    desconto: Double;
    entrega: Double;
    total: Double;
    troco: Double;
  end;

  TOutros = class
  public
    origem: string;
    nota: Integer;
    url: string;
    cupom: string;
    status: string;
  end;

  TPedido = class
  public
    id: Integer;
    cliente: TCliente;
    pagamento: TPagamento;
    endereco: TEndereco;
    valores: TValores;
    outros: TOutros;
    produtos: TObjectList<TProduto>;
  end;

implementation

end.
