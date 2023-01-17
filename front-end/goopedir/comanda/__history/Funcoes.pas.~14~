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
  dm.GetSimples(Parametros(URL), Dados);
end;

function GetSimples2(URL: String; Dados: TFDMemTable): boolean;
begin
  dm.GetSimples2(Parametros(URL), Dados);
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
  Result := dm.TestaConexao;
end;

function PostSimples(URL: String; Dados: IMemTable): boolean;
begin

  dm.PostSimples(Parametros(URL), Dados);
end;

function PutSimples(URL: String; Dados: IMemTable): boolean;
begin
  dm.PutSimples(Parametros(URL), Dados);
end;

function DeleteSimples(URL: String; Dados: IMemTable): boolean;
begin
  dm.DeleteSimples(Parametros(URL), Dados);
end;

function Parametros(URL: String): String;
begin
  URL := StringReplace(URL, ':usuario', dm.CodigoUsuario.ToString,
    [rfReplaceAll]);
  if dm.CAIXA.RecordCount > 0 then
    URL := StringReplace(URL, ':caixa', dm.CodigoCaixa.ToString,
      [rfReplaceAll]);
  Result := URL;
end;

function Token: String;
begin
  Result := '';
end;

end.
