unit uAtualizador;

interface

uses
  conexao, DataSet.Serialize, FireDAC.Comp.Client, Vcl.Dialogs, System.SysUtils,
  IdHTTP, IdSSLOpenSSL, FireDAC.Stan.Error,
  System.IniFiles;

type
  TAtualizacao = class
  private
    procedure VerificarOuCriarBanco(Configuracao: TFDMemTable);
    procedure AposConectarBanco(Configuracao: TFDMemTable);
    procedure ExecutarSQLScript(const SQLText: string);
  public
    procedure Iniciar;

  var
    conexao: TConexao;
    IniFile: TIniFile;
  end;

implementation

uses
  uRequisicao, System.Classes, System.IOUtils;

{ TAtualizacao }

procedure TAtualizacao.AposConectarBanco(Configuracao: TFDMemTable);
var
  conexao: TConexao;
begin
  conexao := TConexao.Create('main'); // Se precisar reabrir
  conexao.SQL.Add('select * from dados_whatsapp');
  Configuracao.Close;
  Configuracao.LoadFromJSON(conexao.ConsultaSQL);
  IniFile.WriteString('site', 'clientId',    Configuracao.FieldByName('client_id').AsString);
  IniFile.WriteString('site', 'clientSecurity',Configuracao.FieldByName('client_security').AsString);
  //Apos deve abrir o exe do servidor
  //Chamar backup do Banco

end;

procedure TAtualizacao.ExecutarSQLScript(const SQLText: string);
var
  Lista: TStringList;
  Qry: TFDQuery;
  i, Tentativas: Integer;
  ComandoAtual: string;
  Pendentes, Erros: TStringList;
  ExecucaoRestante: Boolean;
  conexao: TConexao;
begin
  conexao := TConexao.Create('ExecutarSQLScript');
  Lista := TStringList.Create;
  Pendentes := TStringList.Create;
  Erros := TStringList.Create;
  Qry := conexao.CriaQRY;
  try
    Lista.Text := SQLText;
    ComandoAtual := '';

    // Primeira rodada: executa tudo possível
    for i := 0 to Lista.Count - 1 do
    begin
      if (trim(Lista[i]) = '') or (trim(Lista[i]).StartsWith('--')) or
        (trim(Lista[i]).StartsWith('/*!')) or
        (trim(Lista[i]).StartsWith('LOCK TABLES')) or
        (trim(Lista[i]).StartsWith('UNLOCK TABLES')) or
        (trim(Lista[i]).StartsWith('ALTER TABLE')) then
        Continue;

      ComandoAtual := ComandoAtual + sLineBreak + Lista[i];

      if pos(';', Lista[i]) > 0 then
      begin
        try
          Qry.SQL.Clear;
          Qry.SQL.Text := ComandoAtual;
          Qry.ExecSQL;
        except
          on E: Exception do
          begin
            if pos('Failed to open the referenced table', E.Message) > 0 then
            begin
              // Se for erro de foreign key, adia
              Pendentes.Add(ComandoAtual);
            end
            else
              raise Exception.Create('Erro executando SQL: ' + E.Message +
                sLineBreak + 'Comando: ' + ComandoAtual);
          end;
        end;
        ComandoAtual := '';
      end;
    end;

    // Agora tenta executar os pendentes
    Tentativas := 0;
    repeat
      ExecucaoRestante := false;
      Inc(Tentativas);

      for i := Pendentes.Count - 1 downto 0 do
      begin
        try
          Qry.SQL.Clear;
          Qry.SQL.Text := Pendentes[i];
          Qry.ExecSQL;
          Pendentes.Delete(i); // Deu certo, remove da lista
        except
          on E: Exception do
          begin
            if (Tentativas >= 3) then
            begin
              // Se já tentou 3x e não deu, grava no erro
              Erros.Add(Pendentes[i]);
              Pendentes.Delete(i);
            end
            else
              ExecucaoRestante := True; // Ainda tem pendente, mais uma rodada
          end;
        end;
      end;

    until (not ExecucaoRestante) or (Tentativas >= 3);

    // Se sobrou algum erro grave, salva o log
    if Erros.Count > 0 then
    begin
      Erros.SaveToFile(ExtractFilePath(ParamStr(0)) + 'log_erros_sql.txt');
      ShowMessage
        ('Alguns comandos SQL não puderam ser executados. Veja o arquivo log_erros_sql.txt');
    end;

  finally
    Qry.Free;
    Lista.Free;
    Pendentes.Free;
    Erros.Free;
  end;
end;

procedure TAtualizacao.Iniciar;
var
  VersaoMysql: String;
  Configuracao: TFDMemTable;
begin
  IniFile := TIniFile.Create('./goopedir.ini');
  conexao := TConexao.Create('TAtualizacao');
  Configuracao := TFDMemTable.Create(nil);
  conexao.SQL.Add('SET GLOBAL max_connections = 1000;');
  conexao.ExecuteSQL;
  VersaoMysql := conexao.ValidaVersao;

  try
    TDirectory.Delete(ExtractFilePath(ParamStr(0)) + 'cache\', True);
  except

  end;

  try
    conexao.SQL.Add('select * from dados_whatsapp');
    Configuracao.LoadFromJSON(conexao.ConsultaSQL);

    if Configuracao.RecordCount = 0 then
    begin
      VerificarOuCriarBanco(Configuracao);
      AposConectarBanco(Configuracao);
    end
    else
    begin
      AposConectarBanco(Configuracao);
    end;

  except
    on E: Exception do
    begin
      ShowMessage('Erro ao conectar/criar banco: ' + E.Message);
      exit;
    end;
  end;

end;

procedure TAtualizacao.VerificarOuCriarBanco(Configuracao: TFDMemTable);
var
  Qry: TFDQuery;
  HTTP: TIdHTTP;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  SQLScript, DatabaseName: string;
  Stream: TStringStream;
  conexao: TConexao;
  iReq: iRequisicao;
begin
  conexao := TConexao.Create('VerificarOuCriarBanco');
  try
    if Configuracao.RecordCount = 0 then
    begin
      Qry := conexao.CriaQRY;
      try
        Qry.SQL.Text := 'SELECT * FROM version';
        Qry.Open;
      finally
        Qry.Free;
      end;
    end;
  except
    on E: EFDDBEngineException do
    begin
      // Captura erro de banco inexistente
      if pos('Unknown database', E.Message) > 0 then
      begin
        // Extrai nome do banco entre as aspas
        DatabaseName := Copy(E.Message, pos('''', E.Message) + 1, MaxInt);
        DatabaseName := Copy(DatabaseName, 1, pos('''', DatabaseName) - 1);

        iReq := iRequisicao.Create(nil);
        iReq.URL := 'https://goopedir.com/new.sql';
        iReq.TempoExpiracao := 15000;
        try
          iReq.Execute;
        finally
          SQLScript := iReq.Retorno;
        end;

        conexao.DisconectBanco;
        conexao.CriaQRY.ExecSQL('CREATE DATABASE `' + DatabaseName +
          '` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
        conexao.ConectaBanco(DatabaseName);
        conexao.Free;
        ExecutarSQLScript(SQLScript);

        ShowMessage('Banco de dados criado com sucesso.');
      end
      else
      begin
        raise; // Se for outro erro, apenas repassa
      end;
    end;
  end;
end;

end.
