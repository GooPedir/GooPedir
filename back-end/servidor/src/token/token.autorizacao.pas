unit token.autorizacao;

interface

uses Horse, Horse.JWT;

function Authorization: THorseCallback;

implementation

uses uDM;

function Authorization: THorseCallback;
begin
 //Deve-se utilizar a mesma chave passada na uses "token", podendo criar uma variavel global
  Result := HorseJWT(CHAVE_SECRETA);
end;

end.
