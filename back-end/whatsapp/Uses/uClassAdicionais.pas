unit uClassAdicionais;

interface

type

  TConfiguracaoAdicional = class

  public
    function AdicionaMae(Descricao: String; Max, Min: Integer): Integer;
    procedure AdicionaItem(Index: Integer; Nome, Descricao: String;
      Valor: Real);

    function TotalPorID(ID: Integer): Integer;

  var
    ArrayDescricao: Array of String;
    ArrayMaximo: Array of Integer;
    ArrayMinimo: Array of Integer;
    ArrayItemNome: Array of String;
    ArrayItemDescricao: Array of String;
    ArrayItemValor: Array of Real;
    ArrayItemIndex: Array of Integer;

  end;

implementation

{ TConfiguracaoAdicional }

uses uDM, SysUtils;

procedure TConfiguracaoAdicional.AdicionaItem(Index: Integer;
  Nome, Descricao: String; Valor: Real);
Var
  I: Integer;
begin
  SetLength(ArrayItemNome, length(ArrayItemNome) + 1);
  SetLength(ArrayItemDescricao, length(ArrayItemDescricao) + 1);
  SetLength(ArrayItemValor, length(ArrayItemValor) + 1);
  SetLength(ArrayItemIndex, length(ArrayItemIndex) + 1);

  I := length(ArrayItemIndex) - 1;
  ArrayItemNome[I] := Nome;
  ArrayItemDescricao[I] := Descricao;
  ArrayItemIndex[I] := Index;
  ArrayItemValor[I] := Valor;

end;

function TConfiguracaoAdicional.AdicionaMae(Descricao: String;
  Max, Min: Integer): Integer;
begin
  SetLength(ArrayDescricao, length(ArrayDescricao) + 1);
  SetLength(ArrayMaximo, length(ArrayMaximo) + 1);
  SetLength(ArrayMinimo, length(ArrayMinimo) + 1);
  Result := length(ArrayDescricao) - 1;
  ArrayDescricao[Result] := Descricao;
  ArrayMaximo[Result] := Max;
  ArrayMinimo[Result] := Min;
end;

function TConfiguracaoAdicional.TotalPorID(ID: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to length(ArrayItemIndex) - 1 do
  begin
    if ArrayItemIndex[I] = ID then
    begin
      Result := Result + 1;
    end;

  end;
end;

end.
