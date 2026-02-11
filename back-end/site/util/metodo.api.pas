unit metodo.api;

interface

type
  TInsertUpdate = class
  public
    function InserirUpdate(Tabela: String;
      ArrayCampos, ArrayValores: Array of String): Integer;
    function ConsultaSQL(SQL: String): String;
    function BuscaDadosDados(Campo, SQL: String): Integer;
    function BuscaDadosDadosS(Campo, SQL: String): String;

    procedure ExecutaSQL(SQL: String);
  end;

implementation

{ TInsertUpdate }

uses FireDAC.Comp.Client, SysUtils, uModulo, DataSet.Serialize, Vcl.Dialogs;

function TInsertUpdate.BuscaDadosDados(Campo, SQL: String): Integer;
var
  qry: TFDquery;
begin
  try
    qry := dmModulo.CriaQry('API');
    qry.SQL.Clear;
    qry.SQL.Add(SQL);
    qry.Open;

    Result := qry.FieldByName(Campo).AsInteger;
    qry.Free;

  except
    on E: Exception do
    begin
      qry.Free;
      Result := 0;
    end;
    // ////showmessage(E.message);

  end;
end;

function TInsertUpdate.BuscaDadosDadosS(Campo, SQL: String): String;
var
  qry: TFDquery;
begin
  try
    qry := dmModulo.CriaQry('API');
    qry.SQL.Clear;
    qry.SQL.Add(SQL);
    qry.Open;

    Result := qry.FieldByName(Campo).AsString;
    qry.Free;

  except
    on E: Exception do
    begin
      qry.Free;
      Result := '';
    end;
    // ////showmessage(E.message);

  end;
end;

function TInsertUpdate.ConsultaSQL(SQL: String): String;
var
  qry: TFDquery;
begin
  try
    qry := dmModulo.CriaQry('API');
    qry.SQL.Clear;
    qry.SQL.Add(SQL);
    qry.Open;

    Result := qry.ToJSONArray().ToJSON;
    qry.Free;

  except
    on E: Exception do
      // ////showmessage(E.message);

  end;
end;

procedure TInsertUpdate.ExecutaSQL(SQL: String);
var
  qry: TFDquery;
begin
  qry := dmModulo.CriaQry('API');
  qry.SQL.Clear;
  qry.SQL.Add(SQL);
  try
    qry.ExecSQL;
  except

  end;

  qry.Free;
end;

function TInsertUpdate.InserirUpdate(Tabela: String;
  ArrayCampos, ArrayValores: array of String): Integer;
var
  qry: TFDquery;
  Inserir: Boolean;

  Campos: String;
  Parametros: String;
  I: Integer;

  SQL: String;
  arq: TextFile;

begin

  // DMSitePapaleguas := TDMSitePapaleguas.Create(nil);
  qry := dmModulo.CriaQry('API');

  qry.Close;
  qry.SQL.Clear;

  try
    qry.SQL.Add('select * from ' + Tabela + ' where ' + ArrayCampos[0] + ' = :'
      + ArrayCampos[0]);
    qry.ParamByName(ArrayCampos[0]).Value := ArrayValores[0];
    qry.Open;
    Inserir := qry.RecordCount = 0;

  except
    Inserir := True;
  end;
  if trim(ArrayValores[0]) = '' then
  begin
    Inserir := True;
  end;
  if trim(ArrayValores[0]) = '0' then
  begin
    Inserir := True;
  end;
  if Inserir then
  begin
    // insert into () values ();
    for I := 0 to length(ArrayCampos) - 1 do
    begin
      if I = 0 then
      begin
        Campos := ArrayCampos[I];
        Parametros := ':' + ArrayCampos[I];
      end
      else
      begin
        Campos := Campos + ',' + ArrayCampos[I];
        Parametros := Parametros + ',:' + ArrayCampos[I];
      end;
    end;

    ArrayValores[0] := IntToStr(dmModulo.GerarCodigo(Tabela, ArrayCampos[0]));

    SQL := 'insert into ' + Tabela + ' (' + Campos + ') values (' +
      Parametros + ')';

  end
  else
  begin
    for I := 1 to length(ArrayCampos) - 1 do
    begin
      if I = 1 then
      begin
        Campos := ArrayCampos[I] + ' = ' + ':' + ArrayCampos[I];
      end
      else
      begin
        Campos := Campos + ', ' + ArrayCampos[I] + ' = ' + ':' + ArrayCampos[I];
      end;
    end;

    Parametros := ' where ' + ArrayCampos[0] + ' = :' + ArrayCampos[0];
    // update tabela set
    SQL := 'update ' + Tabela + ' set ' + Campos + Parametros;
  end;
  qry.Close;
  qry.SQL.Clear;
  qry.SQL.Add(SQL);
  for I := 0 to length(ArrayCampos) - 1 do
  begin
    qry.ParamByName(ArrayCampos[I]).Value := StringReplace(ArrayValores[I], ',',
      '.', [rfReplaceAll]);
  end;
  try
    qry.ExecSQL;
  except
    on E: Exception do
    begin
      // ////showmessage(E.message);
      AssignFile(arq, '\log.txt');
      Rewrite(arq);
      Writeln(arq, 'Erro ' + DateToStr(now));
      Writeln(arq, E.message);
      Writeln(arq, '');
      CloseFile(arq);
    end;

  end;

  Result := StrToInt(ArrayValores[0]);

  qry.Free;

  // DMSitePapaleguas.Free;
end;

end.
