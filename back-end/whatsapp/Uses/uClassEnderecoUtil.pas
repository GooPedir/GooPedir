unit uClassEnderecoUtil;

interface

uses FireDAC.Comp.Client, System.SysUtils,
  REST.Response.Adapter, REST.Client, JSON;

type
  TEnderecoLocalizacao = class
  private
    FEnderecoCompleto: String;
    FEnderecoComNumero: String;
    procedure SetEnderecoComNumero(const Value: String);
    procedure SetEnderecoCompleto(const Value: String);

  public
    Rua: String;
    CEP: String;
    Bairro: String;
    Cidade: String;
    Estado: String;
    KM: Real;
    Correto: Boolean;

    ArrayRetornoInformacoes: Array of String;

    property EnderecoComNumero: String read FEnderecoComNumero
      write SetEnderecoComNumero;
    property EnderecoCompleto: String read FEnderecoCompleto
      write SetEnderecoCompleto;

    function CorrecaoEndereco(txJason: String): TEnderecoLocalizacao;
    function RemoveCaracteresEndereco(txMensagem: String): String;
    function RemoveAcento(aText: string): string;
  end;

implementation

{ TEnderecoLocalizacao }

function TEnderecoLocalizacao.CorrecaoEndereco(txJason: String)
  : TEnderecoLocalizacao;
var
  I: Integer;
  Texto: String;
  ArrayResultado: Array of String;
  AuxArray: Integer;
  Separador: String;

  Endereco: TEnderecoLocalizacao;

  txMensagem: String;

  txAux: String;
  nrAux: Integer;
begin
  Texto := txJason;
  SetLength(ArrayResultado, 1);
  AuxArray := 0;
  Separador := ',|-';
  Endereco := TEnderecoLocalizacao.Create;

  for I := 0 to length(Texto) do
  begin
    if Texto[I] <> '' then
    begin
      if Pos(Texto[I], Separador) > 0 then
      begin
        if Texto[I] = '-' then
        begin
          if Texto[I - 1] + Texto[I] = ' -' then
          begin
            SetLength(ArrayResultado, length(ArrayResultado) + 1);
            Inc(AuxArray);
          end
          else
            ArrayResultado[AuxArray] := ArrayResultado[AuxArray] + Texto[I];

        end
        else
        begin

        SetLength(ArrayResultado, length(ArrayResultado) + 1);
        Inc(AuxArray);
        end;
      end
      else
      begin
        ArrayResultado[AuxArray] := ArrayResultado[AuxArray] + Texto[I];
      end;
    end;
  end;
  Texto := '';
  nrAux := 0;
  for I := 0 to length(ArrayResultado) - 1 do
  begin
    // Validar
    txAux := RemoveCaracteresEndereco(ArrayResultado[I]);
    if txAux <> '' then
    begin
      if (txAux <> 'BRASIL') then
      begin
        if (txAux <> 'BRAZIL') then
        begin
          if length(txAux) > 2 then
          begin
            SetLength(Endereco.ArrayRetornoInformacoes,
              length(Endereco.ArrayRetornoInformacoes) + 1);
            Endereco.ArrayRetornoInformacoes[nrAux] := txAux;
            Inc(nrAux);
          end;
        end;
      end;
    end;

    Texto := Texto + ArrayResultado[I] + '[' + IntToStr(I) + '] ';
  end;
  Endereco.EnderecoComNumero := Texto;
  Endereco.EnderecoCompleto := txJason;
  if length(ArrayResultado) = 10 then
  begin
    Endereco.Rua := ArrayResultado[0] + ' - ' + ArrayResultado[2];
    Endereco.Bairro := ArrayResultado[4];
    Endereco.Cidade := ArrayResultado[5];
    Endereco.Estado := ArrayResultado[6];
  end
  else if length(ArrayResultado) = 9 then
  begin
    Endereco.CEP := ArrayResultado[6] + ArrayResultado[7];
    // Consulta o CEP
    // Se localizar o CEP, validar informaÁıes (PRINCIPAL BAIRRO/CIDADE)
    Endereco.Rua := ArrayResultado[0];
    Endereco.Bairro := ArrayResultado[3];
    Endereco.Cidade := ArrayResultado[4];
    Endereco.Estado := ArrayResultado[5];
    // NovoCampo no cadastro do cliente no endereco, endereÁo retornado pelo google maps.
    // Outro Campo com as informaÁıes do array[]
  end
  else if length(ArrayResultado) = 8 then
  begin
    Endereco.CEP := ArrayResultado[5] + ArrayResultado[6];
    Endereco.Rua := ArrayResultado[0];
    Endereco.Bairro := ArrayResultado[2];
    Endereco.Cidade := ArrayResultado[3];
    Endereco.Estado := ArrayResultado[4];
  end
  else if length(ArrayResultado) = 7 then
  begin
    // if ArrayResultado[4] = 'SC' then
    // begin
    // if ArrayResultado[2] = 'Metropol' then
    // begin
    // Endereco.Rua := ArrayResultado[0];
    // Endereco.Bairro := ArrayResultado[2];
    // Endereco.Cidade := ArrayResultado[3];
    // Endereco.Estado := ArrayResultado[4];
    // end;
    // end
    // else
    // begin
    Endereco.CEP := ArrayResultado[4] + ArrayResultado[5];
    Endereco.Rua := ArrayResultado[0];
    Endereco.Bairro := ArrayResultado[1];
    Endereco.Cidade := ArrayResultado[2];
    Endereco.Estado := ArrayResultado[3];
    // end;

  end
  else if length(ArrayResultado) = 6 then
  begin

    Endereco.CEP := (ArrayResultado[4] + ArrayResultado[5]);
    Endereco.Rua := ArrayResultado[0];
    Endereco.Bairro := ArrayResultado[2];
    Endereco.Cidade := ArrayResultado[3];
    // Endereco.Estado := ArrayResultado[3]; {RECEBER O ESTADO DO CEP OU PEGAR DO ENDERECO}
  end
  else if length(ArrayResultado) = 5 then
  begin
    Endereco.CEP := ArrayResultado[3] + ArrayResultado[4];
    Endereco.Rua := ArrayResultado[0];
    Endereco.Bairro := ArrayResultado[1];
    Endereco.Cidade := ArrayResultado[2];
    // Endereco.Estado := ArrayResultado[3]; {RECEBER O ESTADO DO CEP OU PEGAR DO ENDERECO}
  end
  else
  begin
    // Enviar a URL utilizada, baixar o json fazer o que for preciso kkk
    // txMensagem := 'Dados de envio' + MENSAGEM_QUEBRA_LINHA;
    // txMensagem := txMensagem + 'Erro nos dados de endereÁo' +
    // MENSAGEM_QUEBRA_LINHA;
    // txMensagem := txMensagem + 'Nome: ' + ConversaAtual.Nome +
    // MENSAGEM_QUEBRA_LINHA;
    // txMensagem := txMensagem + 'Telefone:' + ConversaAtual.Telefone +
    // MENSAGEM_QUEBRA_LINHA;
    // txMensagem := txMensagem + 'Latitude:' + FloatToStr(ConversaAtual.Lat) +
    // MENSAGEM_QUEBRA_LINHA;
    // txMensagem := txMensagem + 'Longitude:' + FloatToStr(ConversaAtual.Lng) +
    // MENSAGEM_QUEBRA_LINHA;
    // txMensagem := txMensagem + 'EndereÁo Completo:' + Endereco.EnderecoCompleto
    // + MENSAGEM_QUEBRA_LINHA;
    // txMensagem := txMensagem + 'EndereÁo Com N˙meraÁ„o:' +
    // Endereco.EnderecoComNumero + MENSAGEM_QUEBRA_LINHA;
    Endereco.Correto := False;
    Result := Endereco;
    exit;
  end;
  if length(trim(Endereco.Estado)) > 2 then
  begin
    Endereco.Correto := False;
    Result := Endereco;
    exit;
  end;
  if Endereco.Estado = '' then
  begin
    if length(Endereco.CEP) <> 8 then
    begin
      Endereco.Correto := False;
      Result := Endereco;
      exit;
    end;

  end;
  Endereco.Correto := False;
  if Endereco.Rua <> '' then
  begin
    Endereco.Correto := Endereco.Rua <> '';
  end;
  if Endereco.Bairro <> '' then
  begin
    Endereco.Correto := Endereco.Bairro <> '';

  end;
  if Endereco.Cidade <> '' then
  begin
    Endereco.Correto := Endereco.Cidade <> '';

  end;
  if Endereco.Estado <> '' then
  begin
    Endereco.Correto := Endereco.Estado <> '';

  end;
  Result := Endereco;
  exit;
  {

    Av. Brg. LuÌs AntÙnio, Rep˙blica, S„o Paulo, 01318-000, Brasil > 5 Registro
    0                       1          2           3    4     5
    Av. Brg. LuÌs AntÙnio, 400 - Rep˙blica, S„o Paulo, 01318-000, Brasil > 6 Registro
    0                       1       2           3       4     5     6

    R. AntÙnio Valcir Dagostim - Santa LÌbera, Forquilhinha - SC, 88850-000, Brazil > 7 Registro
    0                                  1        2              3     4   5     6
    R. AntÙnio Valcir Dagostim, 400 - Santa LÌbera, Forquilhinha - SC, 88850-000, Brazil > 8 Registro
    0                            1       2              3           4     5   6     7

    R. CecÌlia Daros - R. Defendi Casagrande, 163 - Comerciario, Crici˙ma - SC, 88802-400, Brazil > 9
    0                      1                   2       3           4         5     6   7     8
  }

end;

function TEnderecoLocalizacao.RemoveAcento(aText: string): string;
const
  ComAcento = '‡‚ÍÙ˚„ı·ÈÌÛ˙Á¸Ò˝¿¬ ‘€√’¡…Õ”⁄«‹—›';
  SemAcento = 'aaeouaoaeioucunyAAEOUAOAEIOUCUNY';
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

  Result := aText;
end;

function TEnderecoLocalizacao.RemoveCaracteresEndereco
  (txMensagem: String): String;
begin
//  txMensagem := StringReplace(txMensagem, ',', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '-', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '0', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '1', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '2', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '3', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '4', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '5', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '6', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '7', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '8', '', [rfReplaceAll]);
//  txMensagem := StringReplace(txMensagem, '9', '', [rfReplaceAll]);
  txMensagem := RemoveAcento(txMensagem);
  txMensagem := trim(UpperCase(txMensagem));
  Result := trim(txMensagem);
end;

procedure TEnderecoLocalizacao.SetEnderecoComNumero(const Value: String);
begin
  FEnderecoComNumero := RemoveAcento(Value);
end;

procedure TEnderecoLocalizacao.SetEnderecoCompleto(const Value: String);
begin
  FEnderecoCompleto := RemoveAcento(Value);
end;

end.
