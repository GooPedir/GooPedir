unit ProcessarPedido;

interface

uses
  System.Classes, System.SysUtils, System.JSON, REST.JSON, Pedido,
  System.Generics.Collections, Vcl.Forms;

procedure ProcessarPedidos(const JSONString, Token: string;
  PedidoIDList: TList<Integer>;Form : TForm);

implementation

uses
  EnviarPedidoServidor;

procedure ProcessarPedidos(const JSONString, Token: string;
  PedidoIDList: TList<Integer>;Form : TForm);
var
  PedidosArray: TJSONArray;
  PedidoJSONValue: TJSONValue;
  PedidoObj: TPedido;

  PedidoJSONObject: TJSONObject;
begin
  PedidosArray := TJSONObject.ParseJSONValue
    (TEncoding.UTF8.GetBytes(JSONString), 0) as TJSONArray;

  try
    for PedidoJSONValue in PedidosArray do
    begin
      PedidoJSONObject := PedidoJSONValue as TJSONObject;
      PedidoObj := TPedido.Create;
      try
        PedidoObj.id := PedidoJSONObject.GetValue('id').Value.ToInteger;
        // Preencha os outros campos do pedido conforme necessário

        if not PedidoIDList.Contains(PedidoObj.id) then
        begin
          // Faça o que precisa com o pedido único
          // Por exemplo, adicionar à sua lista de pedidos únicos
          EnviarPedido(PedidoJSONObject.ToString, Token, Form);
          PedidoIDList.Add(PedidoObj.id);
        end;
      finally
        PedidoObj.Free;
      end;
    end;
  finally

    PedidosArray.Free;
  end;
end;

end.
