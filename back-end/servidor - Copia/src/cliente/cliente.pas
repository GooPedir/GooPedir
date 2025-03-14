unit cliente;

interface

procedure Registry;

implementation

uses Horse, JOSE.Core.JWT, JOSE.Core.Builder, SysUtils, JSON, token.autorizacao,
  DataSet.Serialize, FireDAC.Comp.Client, util, uDM;

procedure PostCliente(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  InsertGenerico(Req.Body, 'cliente', 'id');
  Res.Send<TJSONArray>(GetGenerico('cliente', '', ''));
end;

procedure GetCliente(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Where: String;
  ID: Int64;
begin
  try
    ID := Req.Params['id'].ToInt64;
  except
    ID := 0;
  end;
  if ID > 0 then
  begin
    Where := ' and id = ' + IntToStr(ID);
  end;

  Res.Send<TJSONArray>(GetGenerico('cliente', '', Where));
end;

procedure PostMensalidade(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  InsertGenerico(Req.Body, 'clientemensalidade', 'id');

end;

procedure GetMensalidade(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Where: String;
  ID: Int64;
begin
  try
    ID := Req.Params['id'].ToInt64;
  except
    ID := 0;
  end;
  if ID > 0 then
  begin
    Where := ' and idcliente = ' + IntToStr(ID);
  end;

  Res.Send<TJSONArray>(GetGenerico('clientemensalidade', '', Where));
end;

procedure PostFaturamento(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  InsertGenerico(Req.Body, 'clientefaturamento', 'id');
end;

procedure GetFatuamento(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Where: String;
  ID: Int64;
begin
  try
    ID := Req.Params['id'].ToInt64;
  except
    ID := 0;
  end;
  if ID > 0 then
  begin
    Where := ' and idmensalidade = (select idmensalidade from clientemensalidade where idcliente = '
      + IntToStr(ID) + ') ';
  end;
  // SELECT * FROM clientefaturamento where
  Res.Send<TJSONArray>(GetGenerico('clientefaturamento', '', Where));
end;

procedure PostSerial(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  SQL: String;
begin
  InsertGenerico(Req.Body, 'clienteserial', 'id');

  SQL := 'update clienteserial set serial = CONCAT(LPAD(id,5,' + QuotedStr('0')
    + '),' + QuotedStr('-') + ', LPAD(idcliente,5,' + QuotedStr('0') + '),' +
    QuotedStr('-') + ', LPAD(idmensalidade,5,' + QuotedStr('0') +
    ')) where serial is null or serial = ' + QuotedStr('') + ';';

  UpdateGenerico(SQL);
end;

procedure GetSerial(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Where: String;
  ID: Int64;
begin
  try
    ID := Req.Params['id'].ToInt64;
  except
    ID := 0;
  end;
  if ID > 0 then
  begin
    Where := ' and idcliente = '+IntToStr(id);
  end;
  // SELECT * FROM clientefaturamento where
  Res.Send<TJSONArray>(GetGenerico('clienteserial', '', Where));
end;

procedure Registry;
begin
  // Cadastro Cliente
  THorse.Post('/cliente', Authorization(), PostCliente);
  // Busca Todos Clientes
  THorse.Get('/clientes', Authorization(), GetCliente);
  // Busca Cliente Especifico
  THorse.Get('/clientes/:id', Authorization(), GetCliente);

  // Cadastra Mensalidade
  THorse.Post('/cliente/mensalidade/', Authorization(), PostMensalidade);
  // Busca Mensalidade Cliente
  THorse.Get('/cliente/mensalidade/cliente/:id', Authorization(),
    GetMensalidade);

  // Cadastra Faturamento
  THorse.Post('/cliente/faturamento', Authorization(), PostFaturamento);
  // Busca Faturamento
  THorse.Get('/cliente/faturamento/cliente/:id', Authorization(),
    GetFatuamento);

  // Cadastra Serial
  THorse.Post('/cliente/serial', Authorization(), PostSerial);
  // Busca Serial Cliente
  THorse.Get('/cliente/serial/:id', Authorization(), GetSerial);

end;

end.
