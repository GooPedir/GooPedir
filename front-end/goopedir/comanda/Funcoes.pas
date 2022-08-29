unit Funcoes;

interface

uses
  uMemTable, uDM, uRequisicao, FMX.Toast, FMX.Types,
  dataset.serialize, FireDAC.Comp.Client;

function GetSimples(URL: String; Dados: IMemTable): boolean;
function GetSimples2(URL: String; Dados: TFDMemTable): boolean;
procedure ShowMessageToast(AOwner: TFmxObject; Mensage: String; Tipo: integer);
function StatusServidor: boolean;
function PostSimples(URL: String; Dados: IMemTable): boolean;
function PutSimples(URL: String; Dados: IMemTable): boolean;
function DeleteSimples(URL: String; Dados: IMemTable): boolean;

function Token: String;

function Parametros(URL: String): String;

implementation

uses
  System.SysUtils, uMain;

function GetSimples(URL: String; Dados: IMemTable): boolean;
begin
  URL := Parametros(URL);
  Dados.Close;
  DM.CONEXAO.eTAG := False;
  DM.CONEXAO.URL := URL;
  DM.CONEXAO.Metodo := mGet;
  DM.CONEXAO.Token(Token);
  DM.CONEXAO.MemTable := Dados;
  DM.CONEXAO.Execute;

  Result := True;

end;

function GetSimples2(URL: String; Dados: TFDMemTable): boolean;
begin
  URL := Parametros(URL);
  Dados.Close;
  DM.CONEXAO.eTAG := False;
  DM.CONEXAO.URL := URL;
  DM.CONEXAO.Metodo := mGet;
  DM.CONEXAO.Token(Token);
  DM.CONEXAO.MemTable2 := Dados;
  DM.CONEXAO.Execute;

  Result := True;

end;

procedure ShowMessageToast(AOwner: TFmxObject; Mensage: String; Tipo: integer);
begin
  case Tipo of
    1:
      begin
        if Assigned(frmmain) then
          TToast.New(frmmain).Error(Mensage)
        else
          TToast.New(AOwner).Error(Mensage)
      end;

    2:
      begin
        if Assigned(frmmain) then
          TToast.New(frmmain).Info(Mensage)
        else
          TToast.New(AOwner).Info(Mensage)

      end;
    3:
      begin

        if Assigned(frmmain) then
          TToast.New(frmmain).Success(Mensage)
        else
          TToast.New(AOwner).Success(Mensage)
      end;
    4:
      begin
        if Assigned(frmmain) then
          TToast.New(frmmain).Warning(Mensage)
        else
          TToast.New(AOwner).Warning(Mensage)
      end
  else
    begin
      if Assigned(frmmain) then
        TToast.New(frmmain).Info(Mensage)
      else
        TToast.New(AOwner).Info(Mensage)

    end;
  end;
end;

function StatusServidor: boolean;
begin
  Result := DM.TestaConexao;
end;

function PostSimples(URL: String; Dados: IMemTable): boolean;
begin
  URL := Parametros(URL);

  DM.CONEXAO.URL := URL;
  DM.CONEXAO.Metodo := mPost;
  DM.CONEXAO.Token(Token);
  if Assigned(Dados) then
    DM.CONEXAO.BODY(Dados.ToJSONArray().ToString);
  // showmessage(Dados.ToJSONArray().ToString);
  DM.CONEXAO.TempoExpiracao := 10000;
  DM.CONEXAO.Execute;

  Result := DM.CONEXAO.Status = 200;

end;

function PutSimples(URL: String; Dados: IMemTable): boolean;
begin
  URL := Parametros(URL);
  DM.CONEXAO.URL := URL;
  DM.CONEXAO.Metodo := mPut;
  DM.CONEXAO.Token(Token);
  if Assigned(Dados) then
    DM.CONEXAO.BODY(Dados.ToJSONArray().ToString);
  // showmessage(Dados.ToJSONArray().ToString);
  DM.CONEXAO.TempoExpiracao := 10000;
  DM.CONEXAO.Execute;

  Result := DM.CONEXAO.Status = 200;

end;

function DeleteSimples(URL: String; Dados: IMemTable): boolean;
begin
  URL := Parametros(URL);

  DM.CONEXAO.URL := URL;
  DM.CONEXAO.Metodo := mDelete;
  DM.CONEXAO.Token(Token);
  if Assigned(Dados) then
    DM.CONEXAO.BODY(Dados.ToJSONArray().ToString);
  // showmessage(Dados.ToJSONArray().ToString);
  DM.CONEXAO.TempoExpiracao := 10000;
  DM.CONEXAO.Execute;

  Result := DM.CONEXAO.Status = 200;

end;

function Parametros(URL: String): String;
begin
  URL := StringReplace(URL, ':usuario', DM.CodigoUsuario.ToString,
    [rfReplaceAll]);
  if DM.CAIXA.RecordCount > 0 then
    URL := StringReplace(URL, ':caixa', DM.CodigoCaixa.ToString,
      [rfReplaceAll]);
  Result := URL;
end;

function Token: String;
begin
  Result := '';
end;

end.
