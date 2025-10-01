unit ProdutoQueue;

interface

uses
  System.Generics.Collections, System.SysUtils;

type
  TProdutoQueue = class
  private
    FLista: TList<Integer>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Enfileirar(const AProdutoID: Integer);
    function PegarProximo: Integer;
    procedure Finalizar(const AProdutoID: Integer);

    function Count: Integer;
  end;

implementation

{ TProdutoQueue }

constructor TProdutoQueue.Create;
begin
  inherited;
  FLista := TList<Integer>.Create;
end;

destructor TProdutoQueue.Destroy;
begin
  FLista.Free;
  inherited;
end;

procedure TProdutoQueue.Enfileirar(const AProdutoID: Integer);
begin
  // Se já existe na lista, não adiciona novamente
  if FLista.Contains(AProdutoID) then
    Exit;

  FLista.Add(AProdutoID);
end;

function TProdutoQueue.PegarProximo: Integer;
begin
  if FLista.Count = 0 then
    Exit(0); // 0 significa "não tem mais nada"

  Result := FLista.First;
end;

procedure TProdutoQueue.Finalizar(const AProdutoID: Integer);
begin
  FLista.Remove(AProdutoID);
end;

function TProdutoQueue.Count: Integer;
begin
  Result := FLista.Count;
end;

end.

