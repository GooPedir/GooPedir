unit uPrincipalServicos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  Winapi.ShellAPI, Winapi.TlHelp32,
  System.Classes, Vcl.Graphics, System.DateUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inifiles, FireDAC.Comp.Client,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, conexao, Vcl.ExtCtrls, uSQL, Vcl.StdCtrls,
  DataSet.Serialize, JSON, uRequisicao;

type

  TAbrirServicos = class(TThread)
  protected
    procedure Execute; override;
    Function VerificaExe(Nome: String): Boolean;
    procedure AbrirExe(Nome: String);
    procedure FecharExe(ExeFileName: String);
    function ATUALIZADOR: String;
    function USANFCE: String;
    function SERVIDORB: String;
    function SITE(Nome: string): String;
    function IMPRESSAO: String;
    function SERVIDOR: String;
    function PSSITE: String;
    procedure AlteraExtrasIguais;

  var
    conexao: Tconexao;
    Name: String;
    URL: String;
    URLBKP: String;
    uReq: iRequisicao;
    ExeAtualizador: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

  end;

  TfrmServicosGoopedir = class(TForm)
    Configuracoes: TFDMemTable;
    tMinimiza: TTimer;
    TrayIcon1: TTrayIcon;
    Memo1: TMemo;
    FDMemTable1: TFDMemTable;
    FDMemTable1sdasd: TStringField;
    procedure FormCreate(Sender: TObject);
    procedure tMinimizaTimer(Sender: TObject);
  private
    { Private declarations }
    procedure TemAtualizacao;
    procedure SemAtualizacao;
    procedure IniciarAtualizacao;
    procedure FimAtualizacao;
    procedure AtualizaSaldoEstoque;
    procedure AtivaInativaProdutos;
    procedure AlteraExtrasIguais;
    function ObterDiaDaSemana: string;
    procedure FazExclusaoClientes;

    procedure ClonaPedido;
    procedure Pedido(Tabela: TFDQuery; conexao: Tconexao;
      Data, NomeTabela, CampoID: String);

  public
    { Public declarations }
  end;

var
  frmServicosGoopedir: TfrmServicosGoopedir;
  Atualizacao: TSQL;
  Servicos: TAbrirServicos;

implementation

{$R *.dfm}
{ TAbrirServicos }

procedure TfrmServicosGoopedir.AlteraExtrasIguais;
begin
  //
end;

procedure TfrmServicosGoopedir.AtivaInativaProdutos;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  prog: String;
begin

  try
    conexao := Tconexao.Create('main');
    Dados := TFDMemTable.Create(nil);
    conexao.SQL.Add('select * from produto where dias = 1');
    Dados.LoadFromJSON(conexao.ConsultaSQL);

    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        conexao.SQL.Add
          ('update produto set ativo = :ativo, modificado_site = 0 where codigo = :codigo');
        conexao.Parametros('ativo', Dados.FieldByName(ObterDiaDaSemana)
          .AsString);
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsString);
        conexao.ExecuteSQL;
        Dados.Next;
      end;
    end;
    Dados.Free;
    Dados := TFDMemTable.Create(nil);
    conexao.SQL.Add
      ('select codigo, userid from produto where modificado_site = 0 and userid > 0');
    Dados.LoadFromJSON(conexao.ConsultaSQL);
    if Dados.RecordCount > 0 then
    begin
      while not Dados.Eof do
      begin
        prog := ExtractFileDir(Application.ExeName) + '\ProdutoGoopedir.exe';
        ShellExecute(0, 'open', PChar(prog),
          PChar(Dados.FieldByName('codigo').AsString + ' ' +
          Dados.FieldByName('userid').AsString), nil, SW_SHOWNORMAL);

        Dados.Next;
      end;
    end;

  except
    on E: Exception do
    begin

    end;

  end;
  Dados.Free;

  conexao.Free;
end;

procedure TfrmServicosGoopedir.AtualizaSaldoEstoque;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Estoque: Real;
begin

  conexao := Tconexao.Create('EstoqueAtualiza');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('SELECT 0 as zero, codigo FROM produto where controle_estoque = 1');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin

    while not Dados.Eof do
    begin
      try
        conexao.SQL.Clear;
        conexao.SQL.Add
          ('select sum(quantidade) as qtd, 0 as zero from produto_estoque where codigo_produto = :codigo');
        conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
        Estoque := conexao.FieldByName('qtd');
      except
        Estoque := 0;
      end;

      conexao.SQL.Clear;
      conexao.SQL.Add
        ('update produto set saldo_atual = :estoque where codigo = :codigo');
      conexao.Parametros('codigo', Dados.FieldByName('codigo').AsInteger);
      conexao.Parametros('estoque', Estoque);
      conexao.ExecuteSQL;

      Dados.Next;
    end;
  end;

  Dados.Free;
  conexao.Free;

end;

procedure TfrmServicosGoopedir.ClonaPedido;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  Pedidos: TFDQuery;
  PedidoProdutos: TFDQuery;
  PedidoProdutosSAP: TFDQuery;
  Origem: String;
begin
  conexao := Tconexao.Create('ClonaPedido');
  Dados := TFDMemTable.Create(nil);
  conexao.SQL.Add
    ('delete from pedido where status = -1 and (id_caixa is null or id_caixa = 0)');
  conexao.ExecuteSQL;

  conexao.SQL.Add
    ('SELECT DISTINCT DATE_FORMAT(data_pedido, "%Y_%m") AS data_formatada, 0 as zero');
  conexao.SQL.Add('FROM pedido');
  conexao.SQL.Add('WHERE data_pedido > "2000-01-01"');
  conexao.SQL.Add
    ('  AND DATE_FORMAT(data_pedido, "%Y_%m") != DATE_FORMAT(CURDATE(), "%Y_%m")');
  conexao.SQL.Add('ORDER BY data_formatada;');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin
    while not Dados.Eof do
    begin
      conexao.SQL.Add('CREATE TABLE pedido_' +
        Dados.FieldByName('data_formatada').AsString + ' LIKE pedido;');
      conexao.ExecuteSQL;

      Pedidos := conexao.CriaQRY;
      Pedidos.SQL.Add
        ('SELECT * FROM pedido WHERE DATE_FORMAT(data_pedido, "%Y_%m") = "' +
        Dados.FieldByName('data_formatada').AsString + '"');
      Pedidos.Open;

      if Pedidos.RecordCount > 0 then
      begin

        while not Pedidos.Eof do
        begin

          // conexao.SQL.Add('INSERT INTO index_pedido (id, referencia)');
          // conexao.SQL.Add('VALUES (' + Pedidos.FieldByName('codigo').AsString +', ' + QuotedStr(Dados.FieldByName('data_formatada').AsString) + ')');
          // conexao.ExecuteSQL;
          conexao.SQL.Clear;
          conexao.SQL.Add('INSERT INTO index_pedido (id, referencia)');
          conexao.SQL.Add('VALUES (:codigo, :data_formatada)');
          conexao.SQL.Add
            ('ON DUPLICATE KEY UPDATE referencia = VALUES(referencia)');
          conexao.Parametros('codigo', Pedidos.FieldByName('codigo').AsString);
          conexao.Parametros('data_formatada',
            Dados.FieldByName('data_formatada').AsString);
          conexao.ExecuteSQL;

          Pedido(Pedidos, conexao, Dados.FieldByName('data_formatada').AsString,
            'pedido', 'codigo');
          Pedidos.Next;
        end;

      end;

      Pedidos.Free;
      Dados.Next;
    end;
  end;

  PedidoProdutos := conexao.CriaQRY;
  PedidoProdutos.SQL.Add
    ('select * from pedido_produtos where codigo_pedido > 0 and DATE_FORMAT(hora, "%Y_%m")  <> DATE_FORMAT(curdate(), "%Y_%m")');
  PedidoProdutos.Open;

  while not PedidoProdutos.Eof do
  begin
    conexao.SQL.Add('select * from index_pedido where id = :id');
    conexao.Parametros('id', PedidoProdutos.FieldByName('codigo_pedido')
      .AsInteger);
    Origem := conexao.FieldByName('referencia');

    if Origem <> '' then
    begin
      conexao.SQL.Add('CREATE TABLE pedido_produtos_' + Origem +
        ' LIKE pedido_produtos;');
      conexao.ExecuteSQL;
      conexao.SQL.Add('CREATE TABLE pedido_produto_sap_' + Origem +
        ' LIKE pedido_produto_sap;');
      conexao.ExecuteSQL;

      Pedido(PedidoProdutos, conexao, Origem, 'pedido_produtos', 'codigo');

      PedidoProdutosSAP := conexao.CriaQRY;
      PedidoProdutosSAP.SQL.Add
        ('SELECT * FROM pedido_produto_sap where codigo_pedido_produto = :codigo');
      PedidoProdutosSAP.ParamByName('codigo').AsInteger :=
        PedidoProdutos.FieldByName('codigo').AsInteger;
      PedidoProdutosSAP.Open;

      if PedidoProdutosSAP.RecordCount > 0 then
      begin
        while not PedidoProdutosSAP.Eof do
        begin

          Pedido(PedidoProdutosSAP, conexao, Origem,
            'pedido_produto_sap', 'id');
          PedidoProdutosSAP.Next;
        end;
      end;

      PedidoProdutosSAP.Free;
    end;

    PedidoProdutos.Next;
  end;

  PedidoProdutos.Free;

end;

procedure TfrmServicosGoopedir.FazExclusaoClientes;
var
  conexao: Tconexao;
  Dados: TFDMemTable;
  DadosCliente: TFDMemTable;
  Codigo: Integer;
begin

  conexao := Tconexao.Create('main');
  Dados := TFDMemTable.Create(nil);

  conexao.SQL.Add
    ('SELECT celular, 0 as zero FROM cliente GROUP BY celular HAVING COUNT(celular) > 1;');
  Dados.LoadFromJSON(conexao.ConsultaSQL);

  if Dados.RecordCount > 0 then
  begin

    while not Dados.Eof do
    begin
      DadosCliente := TFDMemTable.Create(nil);
      conexao.SQL.Add('select ');
      conexao.SQL.Add('codigo,nome,celular,cpf,');
      conexao.SQL.Add
        ('(select count(*) from pedido where pedido.codigo_cliente = cliente.codigo) as pedidos,');
      conexao.SQL.Add
        ('(select count(*) from cliente_endereco where cliente_endereco.codigo_cliente = cliente.codigo) as endereco,');
      conexao.SQL.Add
        ('(select count(*) from caixa_receber where id_cliente = cliente.codigo) as pagar');
      conexao.SQL.Add('from cliente where celular = ' +
        QuotedStr(Dados.FieldByName('celular').AsString));
      conexao.SQL.Add('order by cpf desc,nome desc, celular desc');
      DadosCliente.LoadFromJSON(conexao.ConsultaSQL);
      if DadosCliente.RecordCount > 0 then
      begin
        Codigo := DadosCliente.FieldByName('codigo').AsInteger;
        DadosCliente.Next;
        while not DadosCliente.Eof do
        begin
          conexao.SQL.Add
            ('update pedido set codigo_cliente = :cliente where codigo_cliente = :old');
          conexao.Parametros('cliente', Codigo);
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          conexao.SQL.Add
            ('update cliente_endereco set codigo_cliente = :cliente where codigo_cliente = :old');
          conexao.Parametros('cliente', Codigo);
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          conexao.SQL.Add
            ('update caixa_receber set id_cliente = :cliente where id_caixa = :old');
          conexao.Parametros('cliente', Codigo);
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          conexao.SQL.Add('delete from cliente where codigo = :old');
          conexao.Parametros('old', DadosCliente.FieldByName('codigo')
            .AsInteger);
          conexao.ExecuteSQL;

          DadosCliente.Next;
        end;
        DadosCliente.Free;
      end;

      Dados.Next;
    end;
  end;
  Dados.Free;
  conexao.Free;

end;

procedure TfrmServicosGoopedir.FimAtualizacao;
begin
  SemAtualizacao;
end;

procedure TfrmServicosGoopedir.FormCreate(Sender: TObject);
var
  conexao: Tconexao;

begin
  conexao := Tconexao.Create('main');
  // VersaoMysql := conexao.ValidaVersao;
  conexao.SQL.Add('select * from dados_whatsapp');
  Configuracoes.LoadFromJSON(conexao.ConsultaSQL);
  conexao.Free;

  Atualizacao := TSQL.Create;
  Atualizacao.MemoLog := Memo1;

  Atualizacao.SeTiverAtualizacao := TemAtualizacao;
  Atualizacao.seNaoTiverAtualizacao := SemAtualizacao;
  Atualizacao.IniciarAtualizacao := IniciarAtualizacao;
  Atualizacao.AposConcluirAtualizacao := FimAtualizacao;
  Atualizacao.AtualizaEstoque := AtualizaSaldoEstoque;
  Atualizacao.VerificaAtualizacao;
end;

procedure TfrmServicosGoopedir.IniciarAtualizacao;
begin

end;

function TfrmServicosGoopedir.ObterDiaDaSemana: string;
const
  NomesDiasSemana: array [1 .. 7] of string = ('domingo', 'segunda', 'terca',
    'quarta', 'quinta', 'sexta', 'sabado');
var
  DiaDaSemana: Integer;
begin
  // Obter o índice do dia da semana (1 para domingo, 2 para segunda, etc.)
  DiaDaSemana := DayOfWeek(now);

  // Mapear o índice para o nome do dia da semana
  Result := NomesDiasSemana[DiaDaSemana];
end;

procedure TfrmServicosGoopedir.Pedido(Tabela: TFDQuery; conexao: Tconexao;
  Data, NomeTabela, CampoID: String);
var
  I: Integer;
  Campo: String;
  Param: String;
  FieldValue: Variant;
begin

  for I := 0 to Tabela.FieldCount - 1 do
  begin
    FieldValue := Tabela.FieldByName(Tabela.Fields[I].FieldName).Value;

    // Validação do campo antes de adicionar ao parâmetro
    if VarIsNull(FieldValue) or VarIsEmpty(FieldValue) then
    begin
      // Se o campo for nulo ou vazio, atribui um valor padrão ou ignora
      Continue; // Ignora campos nulos ou vazios
    end;

    try
      // Verifica o tipo do campo e adiciona ao parâmetro correspondente
      case Tabela.Fields[I].DataType of
        ftFloat, ftCurrency, ftBCD, ftFMTBcd:
          conexao.Parametros(Tabela.Fields[I].FieldName,
            Tabela.FieldByName(Tabela.Fields[I].FieldName).AsFloat);
        ftInteger, ftSmallint, ftWord, ftLargeint, ftAutoInc:
          conexao.Parametros(Tabela.Fields[I].FieldName,
            Tabela.FieldByName(Tabela.Fields[I].FieldName).AsInteger);
        ftDate, ftTime, ftDateTime, ftTimeStamp:
          conexao.Parametros(Tabela.Fields[I].FieldName,
            Tabela.FieldByName(Tabela.Fields[I].FieldName).AsDateTime);
        ftString, ftWideString, ftMemo, ftWideMemo, ftsingle:
          conexao.Parametros(Tabela.Fields[I].FieldName,
            Tabela.FieldByName(Tabela.Fields[I].FieldName).AsString);
      else
        // Caso o tipo de campo não seja tratado, lança uma exceção ou ignora
        raise Exception.Create('Tipo de campo não suportado: ' + Tabela.Fields
          [I].FieldName);
      end;
    except
      on E: Exception do
      begin
        // Trata exceções (opcional)
        raise Exception.Create('Erro ao processar campo ' + Tabela.Fields[I]
          .FieldName + ': ' + E.Message);
      end;
    end;

    // Concatena os campos e parâmetros para o SQL
    if I = 0 then
    begin
      Campo := Tabela.Fields[I].FieldName;
      Param := ':' + Tabela.Fields[I].FieldName;
    end
    else
    begin
      Campo := Campo + ',' + Tabela.Fields[I].FieldName;
      Param := Param + ',:' + Tabela.Fields[I].FieldName;
    end;
  end;

  // Monta e executa o SQL
  conexao.SQL.Add('insert into ' + NomeTabela + '_' + Data + ' (' + Campo +
    ') values (' + Param + ')');
  conexao.ExecuteSQL;

  conexao.SQL.Add('delete from ' + NomeTabela + ' where ' + CampoID +
    ' = :codigo');
  conexao.Parametros('codigo', Tabela.FieldByName(CampoID).AsInteger);
  conexao.ExecuteSQL;

end;

procedure TfrmServicosGoopedir.SemAtualizacao;
begin

  AtivaInativaProdutos;
  FazExclusaoClientes;
  // Abrir Servidor
  Servicos := TAbrirServicos.Create;
  Servicos.Start;
  ClonaPedido;
end;

procedure TfrmServicosGoopedir.TemAtualizacao;
begin
  Atualizacao.AtualizarBanco;
end;

procedure TfrmServicosGoopedir.tMinimizaTimer(Sender: TObject);
begin

  tMinimiza.Enabled := false;
  self.Hide();
  self.WindowState := wsMinimized;

end;

{ TAbrirServicos }

procedure TAbrirServicos.AbrirExe(Nome: String);
begin
  if length(trim(Nome)) = 0 then
    exit;

  ShellExecute(handle, 'open', PChar(Nome), '', '', SW_SHOWNORMAL);

end;

procedure TAbrirServicos.AlteraExtrasIguais;
var
  conexao: Tconexao;
  QRY: TFDQuery;
  Obje: TJsonObject;
  Dados: TFDMemTable;
  prog: String;
begin
  prog := ExtractFileDir(Application.ExeName) + '\ProdutoGoopedir.exe';
  conexao := Tconexao.Create('AlteraExtrasIguais');
  QRY := conexao.CriaQRY;
  QRY.SQL.Add('select * from fila where origem = "AlteraExtrasIguais"');
  QRY.Open;

  if QRY.RecordCount > 0 then
  begin
    while not QRY.Eof do
    begin
      try
        Obje := TJsonObject.ParseJSONValue(QRY.FieldByName('json').AsString)
          as TJsonObject;

        conexao.SQL.Add
          ('select paps.id, pap.id_produto, p.codigo, p.userid from pro_adi_personalizado_sabores as paps ');
        conexao.SQL.Add
          ('join pro_adi_personalizado as pap on pap.id = paps.id_pro_adi_personalizado ');
        conexao.SQL.Add('join produto as p on p.codigo = pap.id_produto ');
        conexao.SQL.Add
          ('where upper(pap.descricao) = :categoria and upper(paps.nome) = :adicional ');
        conexao.SQL.Add
          ('and pap.id_produto <> :produto and paps.valor <> :valor ');
        Dados := TFDMemTable.Create(nil);
        conexao.Parametros('categoria',
          UpperCase(Obje.GetValue<String>('categoria')));
        conexao.Parametros('adicional',
          UpperCase(Obje.GetValue<String>('nome')));
        conexao.Parametros('valor', Obje.GetValue<String>('valor'));
        conexao.Parametros('produto', Obje.GetValue<String>('codigo'));
        Dados.LoadFromJSON(conexao.ConsultaSQL);

        if Dados.RecordCount > 0 then
        begin

          while not Dados.Eof do
          begin
            conexao.SQL.Add
              ('update pro_adi_personalizado_sabores set valor = :valor where id =:id');
            conexao.Parametros('adicional', Obje.GetValue<String>('nome'));
            conexao.Parametros('id', Dados.FieldByName('id').AsInteger);
            conexao.ExecuteSQL;

            if FileExists(prog) then
            begin
              ShellExecute(0, 'open', PChar(prog),
                PChar(Dados.FieldByName('codigo').AsString + ' ' +
                Dados.FieldByName('userid').AsString), nil, SW_SHOWNORMAL);
              conexao.SQL.Add('delete from fila where id = :id');
              conexao.Parametros('id', QRY.FieldByName('id').AsInteger);
              conexao.ExecuteSQL;
            end;

            Dados.Next;
          end;

        end;

        Dados.Free;
        Obje.Free;
      except
        on E: Exception do
        begin
          // //showmessage(E.Message)
        end;
      end;

      QRY.Next;
    end;
  end;

  QRY.Free;
  conexao.Free;

end;

function TAbrirServicos.ATUALIZADOR: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'atualizador.exe';
end;

constructor TAbrirServicos.Create;
var
  IniFile: TIniFile;
begin
  inherited Create(true);

  IniFile := TIniFile.Create('./goopedir.ini');
  Name := IniFile.ReadString('server', 'name', 'SiteGooPedir');
  URL := IniFile.ReadString('server', 'baseurl', 'http://localhost:2121/');
  URLBKP := IniFile.ReadString('server', 'baseurlB', '');
  IniFile.Free;
  uReq := iRequisicao.Create(nil);
  uReq.BaseURL := URL;

end;

destructor TAbrirServicos.Destroy;
begin

  inherited;
end;

procedure TAbrirServicos.Execute;
var
  ServicoNFCe: Boolean;
  contador: Integer;
  JSONValue: TJSONValue;
  JSONObject: TJsonObject;
  ImpressoraObject: TJsonObject;
  ComandaValue: Boolean;
  UltimoRestartNFCe: TDateTime;
begin
  inherited;
  contador := 0;
  UltimoRestartNFCe := now;
  while not Terminated do
  begin

    inc(contador);
    if URLBKP <> '' then
    begin

      uReq.BaseURL := URLBKP;
      uReq.URL := '/v2/status';
      uReq.Metodo := mGet;
      try
        uReq.Execute;
      except
         FecharExe(SERVIDORB);
         AbrirExe(SERVIDORB);
      end;

    end;

    uReq.BaseURL := URL;
    uReq.URL := '/v2/status';
    uReq.Metodo := mGet;
    try
      uReq.Execute;

      JSONValue := TJsonObject.ParseJSONValue(uReq.Retorno);
      try
        if JSONValue is TJsonObject then
        begin
          JSONObject := JSONValue as TJsonObject;

          // Acessa o objeto "impressora"
          ImpressoraObject := JSONObject.GetValue('impressora') as TJsonObject;

          // Obtém o valor da chave "comanda"
          ComandaValue := ImpressoraObject.GetValue<Boolean>('comanda');

          // Exibe o valor no console

        end;
      finally
        JSONValue.Free;
      end;

    except

    end;

    try
      ServicoNFCe := frmServicosGoopedir.Configuracoes.FieldByName('nfce')
        .AsInteger = 1;
    except
      ServicoNFCe := false;
    end;

    if ServicoNFCe then
    begin
      if (not VerificaExe((USANFCE))) then
      begin
        AbrirExe(USANFCE);
      end;
    end;

    if (not VerificaExe(SITE(Name))) then
    begin
      AbrirExe(SITE(Name));
    end;

    if (not VerificaExe(IMPRESSAO)) then
      AbrirExe(IMPRESSAO);

    if (not VerificaExe(SERVIDOR)) then
      AbrirExe(SERVIDOR);

    if ComandaValue then
    begin
      if (not VerificaExe(PSSITE)) then
        AbrirExe(PSSITE);
    end;

    AlteraExtrasIguais;
    Sleep(15 * 1000);
  end;

end;

procedure TAbrirServicos.FecharExe(ExeFileName: String);
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin

  ExeFileName := ExtractFileName(ExeFileName);

  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile))
      = UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile)
      = UpperCase(ExeFileName))) then
      TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0),
        FProcessEntry32.th32ProcessID), 0);
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);

end;

function TAbrirServicos.IMPRESSAO: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'ImpressaoGooPedir.exe';
end;

function TAbrirServicos.PSSITE: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'psGoopedir.exe';
end;

function TAbrirServicos.SERVIDOR: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'ServidorGooPedir.exe';
end;

function TAbrirServicos.SERVIDORB: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'ServidorGooPedirB.exe';
end;

function TAbrirServicos.SITE(Nome: string): String;
var
  NomeEXE: String;
begin
  if Nome <> '' then
    NomeEXE := Nome + '.exe'
  else
    NomeEXE := 'SiteGooPedir.exe';

  Result := ExtractFileDir(Application.ExeName) + '\' + NomeEXE;
end;

function TAbrirServicos.USANFCE: String;
begin
  Result := ExtractFileDir(Application.ExeName) + '\' + 'NFCe.exe';
end;

function TAbrirServicos.VerificaExe(Nome: String): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Nome := ExtractFileName(Nome);
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := false;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(Nome)
      ) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(Nome))) then
    begin
      Result := true;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

end.
