unit uClassPizza;

interface


type

  TConfiguracaoPizza = class
  private
    FMaximoSabores: Integer;
    function RetornaArrayBorda(Index: Integer): Integer;
    function RetornaArraySabor(Index: Integer): Integer;
    procedure SetMaximoSabores(const Value: Integer);
  public
    procedure AdicionaBorda(Descricao: String; Valor: Real);
    procedure AdicionaSabor(TipoSabor, Nome, DescricaoSabor: String;
      Valor: Real);

    function RetornaBordaDescricao(Index: Integer): String;
    function RetornaBordaValor(Index: Integer): Real;

    function RetornaSaborNome(Index: Integer): String;
    function RetornaSaborDescricao(Index: Integer): String;
    function RetornaSaborTipoSabor(Index: Integer): String;
    function RetornaSaborValor(Index: Integer): Real;

    function TotalSabores:Integer;

    property MaximoSabores : Integer read FMaximoSabores write SetMaximoSabores;

  var
    ArrayBordaIndex: Array of Integer;
    ArrayBordaDescricao: Array of String;
    ArrayBordaValor: Array of Real;
    ArraySaborIndex: Array of Integer;
    ArraySaborNome: Array of String;
    ArraySaborDescricao: Array of String;
    ArraySaborTipoSabor: Array of String;
    ArraySaborValor: Array of Real;

  end;

implementation

{ TConfiguracaoPizza }

procedure TConfiguracaoPizza.AdicionaBorda(Descricao: String; Valor: Real);
begin
  SetLength(ArrayBordaIndex, length(ArrayBordaIndex) + 1);
  SetLength(ArrayBordaDescricao, length(ArrayBordaDescricao) + 1);
  SetLength(ArrayBordaValor, length(ArrayBordaValor) + 1);
  ArrayBordaIndex[length(ArrayBordaIndex) - 1] := length(ArrayBordaIndex);
  ArraySaborDescricao[length(ArrayBordaIndex) - 1] := Descricao;
  ArrayBordaValor[length(ArrayBordaIndex) - 1] := Valor;
end;

procedure TConfiguracaoPizza.AdicionaSabor(TipoSabor, Nome, DescricaoSabor
  : String; Valor: Real);
begin
  SetLength(ArraySaborIndex, length(ArraySaborIndex) + 1); // Index
  SetLength(ArraySaborNome, length(ArraySaborNome) + 1); // Nome do Sabor
  SetLength(ArraySaborDescricao, length(ArraySaborDescricao) + 1);
  // Descrição
  SetLength(ArraySaborTipoSabor, length(ArraySaborTipoSabor) + 1);
  // Tipo do Sabor
  SetLength(ArraySaborValor, length(ArraySaborValor) + 1); // Valor
  ArraySaborIndex[length(ArraySaborIndex) - 1] := length(ArraySaborIndex);
  ArraySaborNome[length(ArraySaborNome) - 1] := Nome;
  ArraySaborDescricao[length(ArraySaborIndex) - 1] := DescricaoSabor;
  ArraySaborTipoSabor[length(ArraySaborIndex) - 1] := TipoSabor;
  ArraySaborValor[length(ArraySaborIndex) - 1] := Valor;
end;

function TConfiguracaoPizza.RetornaArrayBorda(Index: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to length(ArrayBordaIndex) - 1 do
  begin
    if ArrayBordaIndex[I] = Index then
    begin
      Result := I;
      exit;
    end;
  end;
end;

function TConfiguracaoPizza.RetornaArraySabor(Index: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to length(ArraySaborIndex) - 1 do
  begin
    if ArraySaborIndex[I] = Index then
    begin
      Result := I;
      exit;
    end;
  end;
end;

function TConfiguracaoPizza.RetornaBordaDescricao(Index: Integer): String;
begin

  try
    Result := ArrayBordaDescricao[RetornaArrayBorda(Index)];
  except
    Result := '';
  end;
end;

function TConfiguracaoPizza.RetornaBordaValor(Index: Integer): Real;
begin
  try
    Result := ArrayBordaValor[RetornaArrayBorda(Index)];
  except
    Result := 0;
  end;
end;

function TConfiguracaoPizza.RetornaSaborDescricao(Index: Integer): String;
begin
  try
    Result := ArraySaborDescricao[RetornaArraySabor(Index)];
  except
    Result := '';
  end;
end;

function TConfiguracaoPizza.RetornaSaborNome(Index: Integer): String;
begin
  try
    Result := ArraySaborNome[RetornaArraySabor(Index)];
  except
    Result := '';
  end;
end;

function TConfiguracaoPizza.RetornaSaborTipoSabor(Index: Integer): String;
begin
  try
    Result := ArraySaborTipoSabor[RetornaArraySabor(Index)];
  except
    Result := '';
  end;
end;

function TConfiguracaoPizza.RetornaSaborValor(Index: Integer): Real;
begin
  try
    Result := ArraySaborValor[RetornaArraySabor(Index)];
  except
    Result := 0;
  end;
end;

procedure TConfiguracaoPizza.SetMaximoSabores(const Value: Integer);
begin
  FMaximoSabores := Value;
end;

function TConfiguracaoPizza.TotalSabores: Integer;
begin
Result := Length(ArraySaborNome);
end;

end.
