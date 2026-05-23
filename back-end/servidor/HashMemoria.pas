unit HashMemoria;

interface

uses
  System.Generics.Collections, System.SysUtils, System.Hash;

type
  THashMemoria = class
  private
    class var FHashes: TDictionary<String, String>;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure GerarHash(const ID: String; const Hash: String);
    class function ValidarHash(const ID: String; const Hash: String): Boolean;
    class function ExisteID(const ID: String): Boolean;
    class procedure Remover(const ID: String);
    class procedure Limpar;
    function Gerar(const Valor: String): String;
  end;

implementation

{ THashMemoria }

class constructor THashMemoria.Create;
begin
  FHashes := TDictionary<String, String>.Create;
end;

class destructor THashMemoria.Destroy;
begin
  FHashes.Free;
end;

function THashMemoria.Gerar(const Valor: String): String;
begin
  Result := THashSHA2.GetHashString(Valor);
end;

class procedure THashMemoria.GerarHash(const ID, Hash: String);
begin
  // AddOrSetValue já sobrescreve se existir
  FHashes.AddOrSetValue(ID, Hash);
end;

class function THashMemoria.ValidarHash(const ID, Hash: String): Boolean;
var
  HashSalvo: String;
begin
  Result := False;

  if FHashes.TryGetValue(ID, HashSalvo) then
    Result := HashSalvo = Hash;
end;

class function THashMemoria.ExisteID(const ID: String): Boolean;
begin
  Result := FHashes.ContainsKey(ID);
end;

class procedure THashMemoria.Remover(const ID: String);
begin
  FHashes.Remove(ID);
end;

class procedure THashMemoria.Limpar;
begin
  FHashes.Clear;
end;

end.
