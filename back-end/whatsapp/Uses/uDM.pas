unit uDM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  FireDAC.Stan.StorageXML, FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.VCLUI.Wait, System.Win.Registry, Vcl.Forms, IdIPWatch,
  FireDAC.DApt.Intf, FireDAC.Comp.UI, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, windows, FireDAC.DApt,
  IniFiles,
  Vcl.ExtCtrls, uRequisicao;

type
  TRegistro = class
  public
    function GravaRegistro(Secao, Identificacao, Valor: String): Boolean;
    function LerRegistro(Identificacao, Secao: String): String;
  end;

  Tdm = class(TDataModule)
    DADOS_EMPRESA: TFDMemTable;
    DADOS_EMPRESANOME: TStringField;
    DADOS_EMPRESATELEFONE: TStringField;
    DADOS_EMPRESAPEDIDO_MINIMO: TFloatField;
    DADOS_EMPRESAKM_MAXIMO: TFloatField;
    DADOS_EMPRESACEP: TStringField;
    DADOS_EMPRESABAIRRO: TStringField;
    DADOS_EMPRESACIDADE: TStringField;
    DADOS_EMPRESAESTADO: TStringField;
    DADOS_EMPRESANUMERO: TStringField;
    DADOS_EMPRESASELECIONA_BAIRROS: TIntegerField;
    DADOS_EMPRESATAXA_POR_KM: TIntegerField;
    DADOS_EMPRESATIPO_ENTREGA: TIntegerField;
    DADOS_EMPRESATIPO_VALOR_PIZZA: TIntegerField;
    DADOS_EMPRESAMENSAGEM_INICIAL: TBlobField;
    DADOS_EMPRESARUA: TStringField;
    Banco: TFDConnection;
    memTabelas: TFDMemTable;
    memTabelastipo: TStringField;
    memTabelasnome: TStringField;
    memTabelastabela: TStringField;
    memTabelasregistros: TIntegerField;
    DADOS_EMPRESALAT: TStringField;
    DADOS_EMPRESALONG: TStringField;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    DADOS_EMPRESATAXA_ENTREGA: TFloatField;
    DADOS_EMPRESAATENDIMENTO: TIntegerField;
    memDadosCelular: TFDMemTable;
    memDadosCelularcelular: TStringField;
    memDadosCelularbateria: TStringField;
    memDadosCelularatendimentos: TIntegerField;
    memDadosCelularpedidos: TIntegerField;
    memDadosCelularenviada: TIntegerField;
    memDadosCelularrecebida: TIntegerField;
    memDadosCelulartempo: TStringField;
    DADOS_EMPRESAPERMITIR_CEP: TIntegerField;
    tTravado: TTimer;
    DADOS_EMPRESAtipo_wpp_confirmacao: TIntegerField;
    DADOS_EMPRESAtipo_wpp_status: TIntegerField;
    DADOS_EMPRESAtipo_wpp_pix: TIntegerField;
    DADOS_EMPRESAtipo_wpp_motoboy: TIntegerField;
    DADOS_EMPRESAtipo_wpp_auto_bot: TIntegerField;
    DADOS_EMPRESAhorario_fechamento: TTimeField;
    getCodigo: iRequisicao;
    procedure DataModuleCreate(Sender: TObject);
    procedure DADOS_EMPRESAAfterPost(DataSet: TDataSet);
    procedure tTravadoTimer(Sender: TObject);
  private
    { Private declarations }
    function MensagemPrincipal: String;

    function NOMEBANCO: String;
    function DADOSHOST: String;
    function DADOSPORT: String;

    procedure CarregaBanco;
    function ValorArray(Posicao: Integer): String;

  public
    { Public declarations }
    procedure CarregaDados;

    function CriaQRY(Nome: String): TFDQuery;
    function CriaTabela(Tabela, PK: String): TFDTable; Overload;
    function GerarID(Tabela, Campo: String): Integer;

    procedure ExecutaSQL(SQL: String);

    procedure LimpaMemoria;

    procedure GerarXML;

    Function GetTemporaryDir: String;

  end;

const
  CAMINHO_ARQUIVOS_CONF = 'ARQUIVOS\DADOS\CLIENTE\';
  CAMINHO_PATCH = 'C:\PapaLeguas\';
  NomeAplicacao = 'PAPA-LEGUAS FOOD';
  ArraySenha: Array [0 .. 1] of String = ('root', 'P4P4L3GU45F00D');

var
  dm: Tdm;
  ArrayHost: Array of String;
  ArrayPorta: Array of String;
  ArrayUsuario: Array of String;
  ArraySenhas: Array of String;
  ArrayBanco: Array of String;

  ArrayTipo: Array of Integer;

implementation

{ %CLASSGROUP 'FMX.Controls.TControl' }

//uses uFuncoes;

{$R *.dfm}

function Tdm.NOMEBANCO: String;
begin
  // Result := ArrayBanco[0];
end;

procedure Tdm.tTravadoTimer(Sender: TObject);
begin
  // ArquivoINI.WriteDateTime('Whats', 'Ultima interação',now);
  try
    if CriaTabela('whats_travado', 'id').Locate('id', '1', []) then
    begin
      CriaTabela('whats_travado', 'id').Edit;
    end
    else
    begin
      CriaTabela('whats_travado', 'id').Insert;
      CriaTabela('whats_travado', 'id').FieldByName('id').AsInteger := 1;
    end;
    CriaTabela('whats_travado', 'id').FieldByName('hora').AsDateTime := Time;
    CriaTabela('whats_travado', 'id').Post;
  except

  end;
end;

procedure Tdm.CarregaBanco;
var

  Quantidade: Integer;
  Registro: TRegistro;

  TipoConexao: Integer;
  I: Integer;

  DataBase: String;
  Password: String;
  IP: TIdIPWatch;
  IPs: TIdIPWatch;
  buffer: array [0 .. 255] of Char;
  // size: dword;
  Nome: String;
  Porta: String;
  UserName: String;
  HOST: String;
  Caminho : String;

begin
  Caminho := ExtractFileDir(ParamStr(0));
  // Banco.Params.a
  // Banco.Params.DataBase := Caminho + '\database\database.db';   ,

  Banco.Params.LoadFromFile('CONFIGURACAO\Confi.dados');
{
  SetLength(ArrayHost, 1);
  SetLength(ArrayPorta, 1);
  SetLength(ArrayUsuario, 1);
  SetLength(ArraySenhas, 1);
  SetLength(ArrayBanco, 1);
  SetLength(ArrayTipo, 1);

  try
    Quantidade := StrToInt(Registro.LerRegistro('MULTIEMPRESA', 'QUANTIDADE'));
  except
    Quantidade := 0;
  end;

  if Quantidade > 0 then
  begin

    for I := 1 to Quantidade do
    begin
      try
        if StrToInt(Registro.LerRegistro('LOGIN', 'EMPRESA')) = I - 1 then
        begin
          ArrayHost[0] := Registro.LerRegistro('MULTIEMPRESA',
            'HOST' + IntToStr(I));
          ArrayPorta[0] := Registro.LerRegistro('MULTIEMPRESA',
            'PORTA' + IntToStr(I));
          ArrayUsuario[0] := Registro.LerRegistro('MULTIEMPRESA',
            'USUARIO' + IntToStr(I));
          ArraySenhas[0] :=
            ValorArray(StrToInt(Registro.LerRegistro('MULTIEMPRESA',
            'SENHA' + IntToStr(I))));
          ArrayBanco[0] := Registro.LerRegistro('MULTIEMPRESA',
            'BANCO' + IntToStr(I));
        end;
      except
        ArrayHost[0] := Registro.LerRegistro('MULTIEMPRESA',
          'HOST' + IntToStr(1));
        ArrayPorta[0] := Registro.LerRegistro('MULTIEMPRESA',
          'PORTA' + IntToStr(1));
        ArrayUsuario[0] := Registro.LerRegistro('MULTIEMPRESA',
          'USUARIO' + IntToStr(1));
        ArraySenhas[0] :=
          ValorArray(StrToInt(Registro.LerRegistro('MULTIEMPRESA',
          'SENHA' + IntToStr(1))));
        ArrayBanco[0] := Registro.LerRegistro('MULTIEMPRESA',
          'BANCO' + IntToStr(1));
      end;
    end;
  end
  else
  begin
    DataBase := Registro.LerRegistro('CONEXAO', 'DADOS');
    Porta := Registro.LerRegistro('CONEXAO', 'PORTA');
    UserName := Registro.LerRegistro('CONEXAO', 'USUARIO');
    try
      Password := ValorArray(StrToInt(Registro.LerRegistro('CONEXAO',
        'SENHA')));
    except
      Password := 'root';
    end;
    IP := TIdIPWatch.Create(nil);
    // 127.0.0.1
    // localhost
    HOST := Registro.LerRegistro('CONEXAO', 'HOST');

    IP.Free;

    ArrayHost[0] := HOST;
    ArrayPorta[0] := Porta;
    ArrayUsuario[0] := UserName;
    ArraySenhas[0] := Password;
    ArrayBanco[0] := DataBase;
  end;
  Banco.Params.Clear;
  Banco.DriverName := 'Mysql';
  Banco.Params.DataBase := ArrayBanco[0];
  Banco.Params.Password := ArraySenhas[0];
  Banco.Params.UserName := ArrayUsuario[0];
  Banco.Params.Add('server=' + ArrayHost[0]);
  Banco.Params.Add('port=' + ArrayPorta[0]);

  try
    Banco.Open;
  except
    on E: Exception do
    begin

      // frmPrincipal.FinalizaProcesso(ExtractFileName(Application.ExeName));
    end;
  end;
   }
end;

procedure Tdm.CarregaDados;
var
  Arquivo: String;
  QRY: TFDQuery;
  I: Integer;

begin
  DADOS_EMPRESA.Open;

  QRY := CriaQRY('LOCALIZA');
  QRY.Close;
  QRY.SQL.Clear;
  QRY.SQL.Add('SELECT * FROM dados_whatsapp');
  QRY.Open;


  DADOS_EMPRESA.Open;
  DADOS_EMPRESA.Insert;
  for I := 0 to DADOS_EMPRESA.FieldCount - 1 do
  begin
    try
      DADOS_EMPRESA.FieldByName(DADOS_EMPRESA.Fields[I].FieldName).AsString := QRY.FieldByName(DADOS_EMPRESA.Fields[I].FieldName).AsString;
//        QRY.FieldByName('tipo_wpp_auto_bot').AsString;
    except

    end;

  end;
//  DADOS_EMPRESA.Post;

   DADOS_EMPRESA.FieldByName('nome').AsString := QRY.FieldByName('nome')
   .AsString;
   DADOS_EMPRESA.FieldByName('telefone').AsString := '(48)99811-1156';
   DADOS_EMPRESA.FieldByName('pedido_minimo').AsFloat :=
   QRY.FieldByName('valor_pedido_minimo').AsFloat;
   DADOS_EMPRESA.FieldByName('km_maximo').AsFloat :=
   QRY.FieldByName('kmmaximo').AsFloat;

   DADOS_EMPRESA.FieldByName('cep').AsString := QRY.FieldByName('cep').AsString;
   DADOS_EMPRESA.FieldByName('bairro').AsString :=
   QRY.FieldByName('bairro').AsString;
   DADOS_EMPRESA.FieldByName('cidade').AsString :=
   QRY.FieldByName('cidade').AsString;
   DADOS_EMPRESA.FieldByName('rua').AsString := QRY.FieldByName('rua').AsString;
   DADOS_EMPRESA.FieldByName('estado').AsString :=
   QRY.FieldByName('estado').AsString;
   DADOS_EMPRESA.FieldByName('numero').AsString :=
   QRY.FieldByName('numero').AsString;
   DADOS_EMPRESA.FieldByName('lat').AsString :=
   QRY.FieldByName('latitude').AsString;
   DADOS_EMPRESA.FieldByName('long').AsString :=
   QRY.FieldByName('longitude').AsString;
   DADOS_EMPRESA.FieldByName('seleciona_bairros').AsInteger :=
   QRY.FieldByName('lista_bairros').AsInteger;
   DADOS_EMPRESA.FieldByName('taxa_por_km').AsInteger :=
   QRY.FieldByName('taxa_por_km').AsInteger;
   DADOS_EMPRESA.FieldByName('tipo_valor_pizza').AsInteger :=
   QRY.FieldByName('tipo_preco_pizza').AsInteger + 1;

   DADOS_EMPRESA.FieldByName('taxa_entrega').AsInteger :=
   QRY.FieldByName('valor_taxa').AsInteger;

   DADOS_EMPRESA.FieldByName('atendimento').AsInteger :=
   QRY.FieldByName('atendimento_atendente').AsInteger;

   if QRY.FieldByName('lista_bairros').AsFloat = 1 then
   DADOS_EMPRESA.FieldByName('taxa_por_km').AsInteger := 0;

   DADOS_EMPRESA.FieldByName('tipo_entrega').AsInteger :=
   QRY.FieldByName('permitir_retirada').AsInteger;;

   DADOS_EMPRESA.FieldByName('MENSAGEM_INICIAL').AsString :=
   QRY.FieldByName('mensagem_inicio').AsString;

   DADOS_EMPRESA.FieldByName('PERMITIR_CEP').AsString :=
   QRY.FieldByName('permitir_cep').AsString;
   DADOS_EMPRESA.Post;
  QRY.Free;

end;

function Tdm.CriaQRY(Nome: String): TFDQuery;
var
  I: Integer;
  NomePadrao: String;
  Achou: Boolean;
begin
  try
    Achou := False;

    NomePadrao := 'QRYAUTOMATICA_' + UpperCase(Nome);
    for I := 0 to ComponentCount - 1 do
    begin
      if (Components[I] is TFDQuery) then
      begin
        if (Components[I] as TFDQuery).Name = NomePadrao then
        begin
          Result := (Components[I] as TFDQuery);
          Achou := True;
        end;
      end;
    end;
    if not Achou then
    begin
      Result := TFDQuery.Create(self);
      Result.Name := NomePadrao;
      Result.Connection := Banco;
      Result.FetchOptions.Mode := fmOnDemand;
      Result.FetchOptions.Unidirectional := True;
      if memTabelas.Locate('nome', NomePadrao, []) then
      begin
      end
      else
      begin
        memTabelas.Insert;
        memTabelas.FieldByName('tipo').AsString := 'Query';
        memTabelas.FieldByName('nome').AsString := NomePadrao;
        memTabelas.FieldByName('tabela').AsString := '';
        memTabelas.FieldByName('registros').AsInteger := 0;
        memTabelas.Post;
      end;

    end;
  except

  end;
end;

function Tdm.CriaTabela(Tabela, PK: String): TFDTable;
var
  I: Integer;
  NomePadrao: String;
  Achou: Boolean;
begin
  Achou := False;
  try
    NomePadrao := UpperCase(Tabela);
    for I := 0 to ComponentCount - 1 do
    begin
      if (Components[I] is TFDTable) then
      begin
        if (Components[I] as TFDTable).Name = NomePadrao then
        begin
          Result := (Components[I] as TFDTable);
          Achou := True;
          if not Result.Active then
            Result.Open;
          if memTabelas.Locate('nome', NomePadrao, []) then
          begin
            memTabelas.Edit;
            memTabelas.FieldByName('registros').AsInteger :=
              (Components[I] as TFDTable).RecordCount;
            memTabelas.Post;
          end
          else
          begin
            memTabelas.Insert;
            memTabelas.FieldByName('tipo').AsString := 'Tabela';
            memTabelas.FieldByName('nome').AsString := NomePadrao;
            memTabelas.FieldByName('tabela').AsString := Tabela;
            memTabelas.FieldByName('registros').AsInteger :=
              (Components[I] as TFDTable).RecordCount;
            memTabelas.Post;
          end;
          break;
        end;
      end;
    end;
    if not Achou then
    begin
      Result := TFDTable.Create(self);
      Result.Name := NomePadrao;
      Result.TableName := Tabela;
      // Result.IndexName := PK;
      Result.Connection := dm.Banco;
      Result.Open;

      if memTabelas.Locate('nome', NomePadrao, []) then
      begin
        memTabelas.Edit;
        memTabelas.FieldByName('registros').AsInteger := Result.RecordCount;
        memTabelas.Post;
      end
      else
      begin
        memTabelas.Insert;
        memTabelas.FieldByName('tipo').AsString := 'Tabela';
        memTabelas.FieldByName('nome').AsString := NomePadrao;
        memTabelas.FieldByName('tabela').AsString := Tabela;
        memTabelas.FieldByName('registros').AsInteger := Result.RecordCount;
        memTabelas.Post;
      end;

    end;
  except

  end;
end;

procedure Tdm.DADOS_EMPRESAAfterPost(DataSet: TDataSet);
var
  Arquivo: String;
begin
  Arquivo := CAMINHO_PATCH + CAMINHO_ARQUIVOS_CONF + 'empresa.xml';

  ForceDirectories(CAMINHO_PATCH + CAMINHO_ARQUIVOS_CONF);

  DADOS_EMPRESA.SaveToFile(Arquivo);
end;

procedure Tdm.DataModuleCreate(Sender: TObject);
begin

  memTabelas.Open;
  CarregaBanco;
  CarregaDados;
  exit;
  // ArquivoIni.Arquivo := 'conf';
  // ArquivoIni.Secao := 'banco';
  // ArquivoIni.Propiedade := 'caminho';
  // ArquivoIni.LocalizaCaminho;
  // ArquivoIni.Ler;
  // if Trim(ArquivoIni.Valor) = '' then
  // begin
  // ArquivoIni.Valor := ArquivoIni.Caminho + 'papaleguas.db';
  // if FileExists(ArquivoIni.Valor) then
  // begin
  // // Banco Localizado
  // ArquivoIni.Gravar;
  // end
  // else
  // begin
  // // Banco não localizado
  // DadosBanco.BaixarBanco;
  //
  // end;
  // end;
  //
  // Banco.Params.DataBase := ArquivoIni.Valor;
  // Banco.Open;

  // Banco.

end;

procedure Tdm.ExecutaSQL(SQL: String);
var
  QRYEXE: TFDQuery;
begin
  QRYEXE := TFDQuery.Create(self);
  QRYEXE.Connection := Banco;

  try
    QRYEXE.SQL.Clear;
    QRYEXE.SQL.Add(SQL);
    QRYEXE.ExecSQL;
  except

  end;
  QRYEXE.Free;

end;

function Tdm.GerarID(Tabela, Campo: String): Integer;
var
  QRYAux001: TFDQuery;
  Valor: Integer;
begin
  QRYAux001 := CriaQRY('');


  QRYAux001.SQL.Add
    ('update geradores set sequencial = sequencial + 1 where tabela = :tabela');
  QRYAux001.ParamByName('tabela').AsString := Tabela;
  QRYAux001.ExecSQL;
  QRYAux001.Close;
  QRYAux001.SQL.Clear;
  QRYAux001.SQL.Add('select * from geradores where tabela = :tabela');
  QRYAux001.ParamByName('tabela').AsString := Tabela;
  QRYAux001.Open;

  if QRYAux001.RecordCount = 1 then
  begin
    Valor := QRYAux001.FieldByName('sequencial').AsInteger;
  end
  else
  begin
    QRYAux001.Close;
    QRYAux001.SQL.Clear;
    QRYAux001.SQL.Add('select max(' + Campo + ')+100 as codigo from ' +
      Tabela);
    QRYAux001.Open;

    if QRYAux001.FieldByName('codigo').IsNull then
      Valor := 1
    else
      Valor := QRYAux001.FieldByName('codigo').AsInteger;

    QRYAux001.Close;
    QRYAux001.SQL.Clear;
    QRYAux001.SQL.Add
      ('insert into geradores (tabela,sequencial) values (:tabela,:sequencial)');
    QRYAux001.ParamByName('tabela').AsString := Tabela;
    QRYAux001.ParamByName('sequencial').AsInteger := Valor;
    QRYAux001.ExecSQL;
  end;

  Result := Valor;

  QRYAux001.Free;
end;

procedure Tdm.GerarXML;
var
  Arquivo: String;
begin
  exit;
  try
    Arquivo := GetTemporaryDir + 'dadoscelular.xml';
    if not FileExists(Arquivo) then
      memDadosCelular.SaveToFile(Arquivo);
  except

  end;

end;

function Tdm.GetTemporaryDir: String;
var
  DiretorioTemp: PChar;
  TempBuffer: Dword;
begin
  TempBuffer := 255;
  GetMem(DiretorioTemp, 255);
  try
    GetTempPath(TempBuffer, DiretorioTemp);
    Result := DiretorioTemp;
  finally
    FreeMem(DiretorioTemp);
  end;
end;

procedure Tdm.LimpaMemoria;
var
  I: Integer;
  NomePadrao: String;
begin
  NomePadrao := 'QRYAUTOMATICA_';
  for I := 0 to ComponentCount - 1 do
  begin
    if (Components[I] is TFDQuery) then
    begin
      if pos(NomePadrao, (Components[I] as TFDQuery).Name) > 0 then
      begin
        try

          if memTabelas.Locate('nome', (Components[I] as TFDQuery).Name, [])
          then
          begin
            memTabelas.Delete;
          end;
          (Components[I] as TFDQuery).Free;
        except

        end;
      end;

    end;
  end;
end;

function Tdm.DADOSHOST: String;
begin
  Result := ArrayHost[0];
end;

function Tdm.MensagemPrincipal: String;
begin
  Result :=

    '*[NOME_EMPRESA]*' + '\n\n' +

    'Olá *[NOME_CLIENTE]*, esse é um canal de *ATENDIMENTO DIGITAL* não há uma pessoa lendo suas mensagens e não visualizamos imagens, vídeos e áudios.'
    + '\n\n' +

    'Você deve informar apenas o que lhe for solicitado e sempre aguardar a resposta do sistema.'
    + '\n\n' +

    'Para Iniciar o Auto Atendimento, envie:' + '\n\n' +

    '*D* para *DELIVERY*' + '\n\n' + '*V* para *Vem Buscar*';

end;

function Tdm.DADOSPORT: String;
begin
  Result := ArrayPorta[0];
end;

function Tdm.ValorArray(Posicao: Integer): String;
begin
  Result := ArraySenha[Posicao];
end;

{ TRegistro }

function TRegistro.GravaRegistro(Secao, Identificacao, Valor: String): Boolean;
var
  ArqReg: TRegIniFile;
  NomeEXE: String;
begin
  NomeEXE := ExtractFilePath(Application.ExeName) + 'papaleguasfood.exe';
  NomeEXE := StringReplace(NomeEXE, ':', '', [rfReplaceAll]);
  NomeEXE := StringReplace(NomeEXE, '\', '', [rfReplaceAll]);
  NomeEXE := StringReplace(NomeEXE, '/', '', [rfReplaceAll]);
  NomeEXE := StringReplace(NomeEXE, '.', '', [rfReplaceAll]);
  Secao := UpperCase(NomeEXE + Secao);
  ArqReg := TRegIniFile.Create(NomeAplicacao);
  Try
    ArqReg.WriteString(Secao, Identificacao, Valor);
  Finally
    ArqReg.Free;
  end;
end;

function TRegistro.LerRegistro(Identificacao, Secao: String): String;
var

  ArqReg: TRegIniFile;
  NomeEXE: String;
begin
  NomeEXE := ExtractFilePath(Application.ExeName) + 'PapaleguasFood.exe';
  NomeEXE := StringReplace(NomeEXE, ':', '', [rfReplaceAll]);
  NomeEXE := StringReplace(NomeEXE, '\', '', [rfReplaceAll]);
  NomeEXE := StringReplace(NomeEXE, '/', '', [rfReplaceAll]);
  NomeEXE := StringReplace(NomeEXE, '.', '', [rfReplaceAll]);
  Secao := UpperCase(Secao);
  Identificacao := UpperCase(NomeEXE + Identificacao);
  ArqReg := TRegIniFile.Create(NomeAplicacao);
  Try
    Result := ArqReg.ReadString(Identificacao, Secao, '');
  Finally
    ArqReg.Free;
  end;
end;

end.
