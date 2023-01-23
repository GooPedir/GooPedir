unit conexao;

interface

uses uDM, FireDAC.Comp.Client, DataSet.Serialize, System.Classes,
  JOSE.Types.JSON;

type

  TConexao = class
  private
    FSQL: TStringlist;
    procedure Zerar;
    procedure SetSQL(const Value: TStringlist);
    function MapaErro(Erro: String): String;

  var
    DataModulo: TDM;

    FParametros: Array of String;
    FValores: Array of Variant;
  public
    constructor Create;

    destructor Destroy; override;
    function VersaoMYSQL: String;
    function ValidaVersao: string;
    function CriaQRY: TFDQuery;
    function ExecuteSQL(SQL: String): Boolean; overload;
    procedure ExecuteSQL; overload;
    function ConsultaSQL(SQL: String): TJSONArray; overload;
    function ConsultaSQL: TJSONArray; overload;
    procedure Parametros(Parametro: String; Valor: Variant);
    property SQL: TStringlist read FSQL write SetSQL;
    function GerarID(Tabela, Campo: String): integer;
    function GenID(Campo: String): integer;

    function FieldByName(Campo: String): Variant;

    function Insert(Tabela, CampoID: String; ID: Variant;
      DadoBody: String): Boolean;

    function GetAll(Tabela: String): String;
    function GetParametro(Campo: String): Variant;
    function NomeBanco: String;
    function ExecutarSQLAtualizacao(SQlText, Versao: String): Boolean;

    procedure GerarLog(Erro: String);
    function SoNumero(fField : String): String;

    // Para um insert
    {
      tabela = Banco
      campoID = nome do banco
      ID = 3 variações (Passar o GENID, SQL, ou um Valor)
      MemTable = Vai ser pego os campos

      Outra variação vai ser passar qual os fields deve ser usados

      Outra variação vai passa qual o field vai ser dado insert e qual campo do banco vai usa

    }

  end;

implementation

uses
  System.SysUtils, Vcl.Dialogs;

{ TConexao }

function TConexao.ConsultaSQL(SQL: String): TJSONArray;
var
  QRY: TFDQuery;
  I: integer;
  New: String;
begin
  QRY := CriaQRY;

  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add(SQL);
  for I := 0 to length(FParametros) - 1 do
  begin
    QRY.ParamByName(FParametros[I]).Value := FValores[I];
  end;
  try
    QRY.Open;
  except
    on E: Exception do
    begin
      // showme
      GerarLog(E.message);
    end;

  end;

  // Result := TFDMemTable.Create(nil);
  Result := QRY.ToJSONArray();

  // Writeln(SQL);

  QRY.Free;

  Zerar;
end;

function TConexao.ConsultaSQL: TJSONArray;
begin
  if SQL.Text <> '' then
    Result := ConsultaSQL(SQL.Text);
end;

constructor TConexao.Create;
begin
  DataModulo := TDM.Create(nil);
  SQL := TStringlist.Create;
  Zerar;
end;

function TConexao.CriaQRY: TFDQuery;
begin
  Result := DataModulo.CriaQRY;
end;

destructor TConexao.Destroy;
begin
  DataModulo.Banco.Connected := False;
  DataModulo.Banco.Free;
  DataModulo.Free;
  SQL.Free;
  inherited;
end;

function TConexao.ExecutarSQLAtualizacao(SQlText, Versao: String): Boolean;
var
  QRY: TFDQuery;
  Tipo: String;
  Erro: String;
  ID: integer;
begin
  QRY := DataModulo.CriaQRY;
  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add(SQlText);
  Tipo := 'SUCESSO';
  Erro := '';
  try
    Result := True;
    QRY.ExecSQL;
  except
    on E: Exception do
    begin
      Tipo := 'ERRO';
      // Erro := e.Message;
      Result := False;
      Erro := MapaErro(E.message);
    end;
  end;
  QRY.Free;
  ID := GerarID('MEU_SQL', 'IDSQL');

  SQL.Add('INSERT INTO MEU_SQL (IDSQL,VERSAOSQL,SQLUSADOSQL,ERROSQL,DATASQL,HORASQL,STATUSSQL) VALUES (:IDSQL,:VERSAOSQL,:SQLUSADOSQL,:ERROSQL,current_date,current_time,:STATUSSQL)');
  Parametros('IDSQL', ID);
  Parametros('VERSAOSQL', Versao);
  Parametros('SQLUSADOSQL', SQlText);
  Parametros('ERROSQL', Erro);
  Parametros('STATUSSQL', Tipo);
  ExecuteSQL;

end;

procedure TConexao.ExecuteSQL;
begin
  if SQL.Text <> '' then
    ExecuteSQL(SQL.Text);
end;

function TConexao.FieldByName(Campo: String): Variant;
var
  Dados: TFDMemTable;
begin
  Dados := TFDMemTable.Create(nil);

  try
    Dados.LoadFromJSON(ConsultaSQL);
    Result := Dados.FieldByName(Campo).AsVariant;
  except
    Result := 0;
  end;
  Dados.Free;
end;

function TConexao.GenID(Campo: String): integer;
var
  lSQL: String;

  QRY: TFDQuery;
begin

  QRY := DataModulo.CriaQRY;

  lSQL := 'SELECT GEN_ID(' + Campo + ', 1) as id, 0 as zero FROM RDB$DATABASE';
  QRY.SQL.Add(lSQL);
  try
    QRY.Open;
  except
    on E: Exception do
    begin
      Writeln(E.message);
      Result := 1;
      exit;
    end;
  end;

  Result := QRY.FieldByName('id').AsInteger;
  QRY.Free;

end;

function TConexao.GerarID(Tabela, Campo: String): integer;
var
  lSQL: String;
  Dados: TFDMemTable;
  Valor: integer;
begin
  SQL.Add('update geradores set sequencial = sequencial + 1 where tabela = :tabela');
  Parametros('tabela', Tabela);
  ExecuteSQL;

  SQL.Add('select * from geradores where tabela = :tabela');
  Parametros('tabela', Tabela);
  Dados := TFDMemTable.Create(nil);
  Dados.LoadFromJSON(ConsultaSQL);

  if Dados.RecordCount = 1 then
  begin
    Valor := Dados.FieldByName('sequencial').AsInteger;
  end
  else
  begin

    Dados.Free;
    Dados := TFDMemTable.Create(nil);
    SQL.Add('select max(' + Campo + ')+99 as codigo,0 as zero from ' + Tabela);
    Dados.LoadFromJSON(ConsultaSQL);
    try
      if Dados.FieldByName('codigo').IsNull then
        Valor := 1
      else
        Valor := Dados.FieldByName('codigo').AsInteger;
    except

    end;

    SQL.Add('insert into geradores (tabela,sequencial) values (:tabela,:sequencial)');
    Parametros('tabela', Tabela);
    Parametros('sequencial', Valor);
    ExecuteSQL;

  end;

  Result := Valor;
  Dados.Free;
  exit;

end;

procedure TConexao.GerarLog(Erro: String);
var
  arq: TextFile;

begin
  if not DirectoryExists('C:\goopedir\log\') then
    ForceDirectories('C:\goopedir\log\');
  try
    AssignFile(arq, 'C:\goopedir\log\erro._banco_mysql.txt');

    if FileExists('C:\goopedir\log\erro._banco_mysql.txt') then
      Append(arq)
    else
      Rewrite(arq);
    Writeln(arq, FormatDateTime('dd/mm/yyyy hh:nn', now));
    Writeln(arq, Erro);
    CloseFile(arq);
  except

  end;
end;

function TConexao.GetAll(Tabela: String): String;
begin
  Tabela := 'select * from ' + Tabela;

  Result := ConsultaSQL(Tabela).ToString;
end;

function TConexao.GetParametro(Campo: String): Variant;
var
  QRY: TFDQuery;
begin
  QRY := CriaQRY;

  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add('select * from dados_whatsapp');
  QRY.Open;

  Result := QRY.FieldByName(Campo).AsVariant;

  QRY.Free;

  // FieldByName
end;

function TConexao.Insert(Tabela, CampoID: String; ID: Variant;
  DadoBody: String): Boolean;
var
  Dados: TFDMemTable;
  DadosQry: TFDMemTable;
  Codigo: integer;
  I: integer;

  Campos: String;
  CamposParametro: String;

  lSQL: String;
begin
  try
    Dados := TFDMemTable.Create(nil);
    Dados.LoadFromJSON(DadoBody);

    if Dados.RecordCount = 0 then
    begin
      Result := False;
      Dados.Free;
      exit;
    end;

    DadosQry := TFDMemTable.Create(nil);

    Campos := '';
    CamposParametro := '';

    for I := 0 to Dados.FieldCount - 1 do
    begin
      if I = 0 then
      begin
        Campos := Dados.Fields[I].FieldName;
        CamposParametro := ':' + Dados.Fields[I].FieldName;
      end
      else
      begin
        Campos := Campos + ',' + Dados.Fields[I].FieldName;
        CamposParametro := CamposParametro + ',:' + Dados.Fields[I].FieldName;
      end;
    end;
    Dados.first;
    while not Dados.Eof do
    begin
      Codigo := 0;
      try
        DadosQry.Close;
        DadosQry.LoadFromJSON(ConsultaSQL('SELECT GEN_ID(' + ID +
          ', 1) as ID, 0 as zero FROM RDB$DATABASE'));
        Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName).AsInteger;
      except
        // Não foi dessa vez
      end;

      if Codigo = 0 then
      begin
        try
          DadosQry.Close;
          DadosQry.LoadFromJSON
            (ConsultaSQL('SELECT MAX(' + ID + ')+1 as ID, 0 as zero FROM '
            + Tabela));

          Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName)
            .AsInteger;
        except

        end;
      end;

      // if Codigo = 0 then
      // begin
      // try
      // DadosQry.Close;
      // DadosQry.LoadFromJSON(ConsultaSQL(ID));
      // Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName)
      // .AsInteger;
      // except
      //
      // end;
      // end;

      if Codigo = 0 then
      begin
        try
          DadosQry.Close;
          DadosQry.LoadFromJSON(ConsultaSQL('SELECT MAX(' + CampoID +
            ')+1 as ID, 0 as zero FROM ' + Tabela));
          Writeln('SELECT MAX(' + CampoID + ')+1 as ID, 0 as zero FROM '
            + Tabela);
          Codigo := DadosQry.FieldByName(DadosQry.Fields[0].FieldName)
            .AsInteger;
        except

        end;
      end;
      lSQL := 'insert into ' + Tabela + ' (' + Campos + ') values (' +
        CamposParametro + ')';
      SQL.Add(lSQL);

      for I := 0 to Dados.FieldCount - 1 do
      begin
        if Dados.Fields[I].FieldName = CampoID then
          Parametros(Dados.Fields[I].FieldName, Codigo)
        else
          Parametros(Dados.Fields[I].FieldName,
            Dados.FieldByName(Dados.Fields[I].FieldName).AsVariant);
      end;
      Codigo := 0;

      ExecuteSQL(SQL.Text);

      Dados.Next;
    end;
  except
    on E: Exception do
    begin
      Writeln('1');
      Writeln(E.message);
    end;

  end;

end;

function TConexao.MapaErro(Erro: String): String;
begin
  Erro := UpperCase(Erro);
  Result := Erro;
  if pos('TOKEN UNKNOWN', Erro) > 0 then
  begin
    Result := 'Tabela Não Localizada';
  end;

  if pos('TABLE SQL ALREADY EXISTS', Erro) > 0 then
  begin
    Result := 'Tabela já Existente';
  end;
end;

function TConexao.NomeBanco: String;
begin
  Result := LowerCase(DataModulo.Banco.Params.Database);
end;

function TConexao.ExecuteSQL(SQL: String): Boolean;
var
  QRY: TFDQuery;
  I: integer;
  New: String;
begin
  try
    QRY := DataModulo.CriaQRY;
    Result := True;
    QRY.Close;
    QRY.SQL.Clear;
    QRY.SQL.Add(SQL);
    for I := 0 to length(FParametros) - 1 do
    begin
      QRY.ParamByName(FParametros[I]).Value := FValores[I];
    end;

    QRY.ExecSQL;
  except
    on E: Exception do
    begin
      GerarLog(E.message);

      Result := False;
    end;
  end;
  QRY.Free;
  Zerar;

end;

procedure TConexao.Parametros(Parametro: String; Valor: Variant);
var
  I: integer;
  Achou: Boolean;
begin
  Achou := False;
  for I := 0 to length(FParametros) - 1 do
  begin
    if FParametros[I] = Parametro then
    begin
      Achou := True;
      break;
    end;
  end;

  if Achou then
  begin
    FValores[I] := Valor;
  end
  else
  begin
    I := length(FParametros);
    SetLength(FParametros, I + 1);
    SetLength(FValores, I + 1);
    FParametros[I] := Parametro;
    FValores[I] := Valor;
  end;

end;

procedure TConexao.SetSQL(const Value: TStringlist);
begin
  FSQL := Value;
end;

function TConexao.SoNumero(fField: String): String;
var
  I : Byte;
begin
   Result := '';
   for I := 1 To Length(fField) do
       if fField [I] In ['0'..'9'] Then
            Result := Result + fField [I];
end;

function TConexao.ValidaVersao: string;
Var
  MYSQL: String;
  VersaoNumber: integer;
begin
  MYSQL := SoNumero(VersaoMYSQL);
//  MYSQL := SoNumero('5.7.37-log');
//  ShowMessage(MYSQL);

  VersaoNumber := StrToInt(StringReplace(MYSQL, '.', '', [rfReplaceAll]));

  if VersaoNumber = 8027 then
  begin
    Result := '';
  end
  else
  begin
    Result := 'A sua versão do mysql (' + VersaoMYSQL +
      ') está desatualizada, para o funcionamento do sistema deve-se instalar a versão (8.0.27)';
  end;

end;

function TConexao.VersaoMYSQL: String;
Var
  Banco: String;
  Query: TFDQuery;
begin

  Banco := DataModulo.Banco.Params.Database;
  DataModulo.Banco.Close;
  DataModulo.Banco.Params.Database := 'sys';
  DataModulo.Banco.Open;
  Query := DataModulo.CriaQRY;
  Query.SQL.Add('SELECT * FROM version');
  Query.Open;

  Result := Query.FieldByName('mysql_version').AsString;

  DataModulo.Banco.Close;
  DataModulo.Banco.Params.Database := Banco;
  DataModulo.Banco.Open;

  Query.Free;

end;

procedure TConexao.Zerar;
begin
  SetLength(FParametros, 0);
  SetLength(FValores, 0);
  SQL.Clear;
end;

end.
