unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uTInject, uBotConversa, uBotGestor,
  uCEFWinControl, uCEFWindowParent, uTInject.Classes, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs;

type
  TdmPrincipal = class(TForm)
    iWhatsapp: TInject;
    CEFWindowParent1: TCEFWindowParent;
    Banco: TFDConnection;
    procedure FormCreate(Sender: TObject);
    procedure iWhatsappGetQrCode(const Sender: TObject;
      const QrCode: TResultQRCodeClass);
    procedure iWhatsappGetUnReadMessages(const Chats: TChatList);
  private
    { Private declarations }

    procedure LimpaConversaBackup(Conversa: TBotConversa);

  public
    { Public declarations }
    procedure GestorInteracao(Conversa: TBotConversa);
    function MenuInicial(Conversa: TBotConversa): String;

    function CriaQRY(Nome: String): TFDQuery;
    function CriaTabela(Tabela, PK: String): TFDTable; Overload;
    function CriaTabela(Tabela: String): TFDTable; Overload;
    function ParametrosDadosEmpresa: TFDMemTable;

    function GerarID(Tabela, Campo: String): integer;

    function Enviamensagem(Etapa: integer; Mensagem: String;
      Conversa: TBotConversa): TBotConversa;

    procedure GravaConversa(Conversa: TBotConversa);
  end;

const
  MENSAGEM_QUEBRA_LINHA = '\n';
  MENSAGEM_QUEBRA_LINHA_DUPLA = '\n\n';
  FORMATA_CAMPO_MENU = '00';

var
  dmPrincipal: TdmPrincipal;

  Gestor: TBotManager;

implementation

{$R *.dfm}

uses uConversa, uClassPedido, uClassEndereco, uDM, uClassFinalizarPedido,
  uAlteracaoCancelamento, uClassPedidoRecente;

function TdmPrincipal.CriaQRY(Nome: String): TFDQuery;
var
  I: integer;
  NomePadrao: String;
  Achou: Boolean;
begin
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
  end;
end;

function TdmPrincipal.CriaTabela(Tabela, PK: String): TFDTable;
var
  I: integer;
  NomePadrao: String;
  Achou: Boolean;
begin
  Achou := False;

  NomePadrao := 'TABELA_AUTO' + UpperCase(Tabela);
  for I := 0 to ComponentCount - 1 do
  begin
    if (Components[I] is TFDTable) then
    begin
      if (Components[I] as TFDTable).Name = NomePadrao then
      begin
        Result := (Components[I] as TFDTable);
        Achou := True;
      end;
    end;
  end;
  if not Achou then
  begin
    Result := TFDTable.Create(self);
    Result.Name := NomePadrao;
    Result.TableName := Tabela;
    // Result.IndexName := PK;
    Result.Connection := Banco;
    Result.Open;
  end;
end;

function TdmPrincipal.CriaTabela(Tabela: String): TFDTable;
begin
  Result := CriaTabela(Tabela, '');
end;

function TdmPrincipal.Enviamensagem(Etapa: integer; Mensagem: String;
  Conversa: TBotConversa): TBotConversa;
begin
  Result := Conversa;

  Result.Etapa := Etapa;
  Result.Pergunta := Mensagem;
  Result.Resposta := '';

  iWhatsapp.ReadMessages(Result.ID);
  iWhatsapp.Send(Result.ID, Mensagem);
  iWhatsapp.ReadMessages(Result.ID);
  Conversa := Result;

end;

procedure TdmPrincipal.FormCreate(Sender: TObject);
begin
  Gestor := TBotManager.Create(self);
  Gestor.OnInteracao := GestorInteracao;

  if not iWhatsapp.Auth(False) then
  Begin
    iWhatsapp.FormQrCodeStart;
  End;

  // CRIAR UMA QRY PARA AS CONFIGURAÇÕES
  // DADOSCONFIGURACAO := CriaQRY('DC');
  // DADOSCONFIGURACAO.SQL.Clear;
  // DADOSCONFIGURACAO.SQL.Add('select * from dados_whatsapp');
  // DADOSCONFIGURACAO.Open;

end;

function TdmPrincipal.GerarID(Tabela, Campo: String): integer;
begin
  CriaQRY('GERADOR').Close;
  CriaQRY('GERADOR').SQL.Clear;
  CriaQRY('GERADOR').SQL.Add('select max(' + Campo + ') as max from ' + Tabela);
  CriaQRY('GERADOR').Open;
  try
    Result := CriaQRY('GERADOR').FieldByName('max').AsInteger + 1;
    if Result < 1 then
      Result := 1;
  except
    Result := -1;
  end;

end;

procedure TdmPrincipal.GestorInteracao(Conversa: TBotConversa);
var
  UsuarioValido: Boolean;

  GeralConversautil: TGeralConversa;
  MenuGeral: TMenu;
  EnderecoGeral: TEndereco;
  Finaliza: TFinalizarPedido;
  CancelamentoF: TCancelamento;
  AlteracaoRemover: TAlteracaoRemover;
  VerificaPedido: TPedidoRecente;

  Erro: String;
begin
  try

    GeralConversautil := TGeralConversa.Create;

    // Conversa := GeralConversautil.EtapaConversa(Conversa);

    MenuGeral := TMenu.Create;
    EnderecoGeral := TEndereco.Create;
    Finaliza := TFinalizarPedido.Create;
    CancelamentoF := TCancelamento.Create;
    AlteracaoRemover := TAlteracaoRemover.Create;
    VerificaPedido := TPedidoRecente.Create;

    // Grava em Qual Etapa o Cliente Esta
    GravaConversa(Conversa);

    // Valida Se o Cliente é cadastrado
    UsuarioValido := GeralConversautil.ClienteCadastrado(Conversa);

    case Conversa.Situacao of
      Aguardando:
        begin
          if UsuarioValido then
          begin
            // Já é Cliente
            Conversa := GeralConversautil.DadosDoCliente(Conversa);
            Conversa.Etapa := 0;
            Conversa.Situacao := MenuPedido;
            GravaConversa(Conversa);
            GestorInteracao(Conversa);

            exit;

            // Mandar Para NovoPedido
          end
          else
          begin
            // Novo Cliente
            if Conversa.Situacao = Aguardando then
            begin
              Conversa.Situacao := NovoCliente;
              Conversa.Etapa := 0;
              GravaConversa(Conversa);
              GestorInteracao(Conversa);
              exit;
            end;
          end;
        end;

      NovoCliente:
        begin
          GeralConversautil.DadosNovoCliente(Conversa);
          GravaConversa(Conversa);
        end;
      VerificaUltimoPedido:
        begin
          VerificaPedido.VerificaPedidoRecente(Conversa);
          GravaConversa(Conversa);
          exit;
        end;

      MenuPedido:
        begin
          // MENU
          MenuGeral.MenuPedido(Conversa);
          GravaConversa(Conversa);

        end;

      NovoPedido:
        begin

        end;

      AdicionandoProduto:
        ;
      AdicionandoPizza:
        ;
      SelecionandoFormaPedido:
        ;
      FinalizandoPedido:
        begin
          Finaliza.Finalizando(Conversa);
          GravaConversa(Conversa);
          LimpaConversaBackup(Conversa);
        end;
      AlteraRemove:
        begin
          AlteracaoRemover.AlterarRemover(Conversa);
          GravaConversa(Conversa);
        end;
      Cancelamento:
        begin
          CancelamentoF.Cancelamento(Conversa);
          GravaConversa(Conversa);
        end;

      CaschBack:
        ;
      Finalizado:
        begin
          Gestor.Conversas.Remove(Conversa);
          GravaConversa(Conversa);
          exit;
        end;

      EnderecoCliente:
        begin
          EnderecoGeral.Endereco(Conversa);
          GravaConversa(Conversa);
        end;
    end;
  except
    on E: Exception do
    begin
      if Conversa <> nil then
      begin
        // GravaErroConversa(E, Conversa);
        // Erro := '*Nome:* ' + ConfDelivery.Nome + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Data/Hora:* ' + FormatDateTime('dd/hh/yyyy hh:mm', now)
          + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Cliente:* ' + Conversa.Nome + MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Celular:* ' + Conversa.Telefone +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Etapa:* ' + IntToStr(Conversa.Etapa) +
          MENSAGEM_QUEBRA_LINHA;
        // Erro := Erro + '*Situação:* ' + SituacaoConversa(Conversa.Situacao) +
        // MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Pergunta:* ' + Conversa.Pergunta +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Resposta:* ' + Conversa.Resposta +
          MENSAGEM_QUEBRA_LINHA;
        Erro := Erro + '*Erro:* ' + E.Message + #13 + E.ClassName;
        iWhatsapp.Send('554898111156@c.us', Erro);
        Erro := Conversa.Pergunta;
        if Conversa.Resposta = '' then
          Erro := '';
        iWhatsapp.Send(Conversa.ID, Erro);
        exit;
      end;
    end;
  end;

end;

procedure TdmPrincipal.GravaConversa(Conversa: TBotConversa);
var
  GeralConversautil: TGeralConversa;
begin
  // EtapaConversa
  try
    GeralConversautil := GeralConversautil.Create;
    GeralConversautil.GravaEtapaConversa(Conversa);
    GeralConversautil.Free;
  except

  end;
end;

procedure TdmPrincipal.iWhatsappGetQrCode(const Sender: TObject;
  const QrCode: TResultQRCodeClass);
begin
  //
end;

procedure TdmPrincipal.iWhatsappGetUnReadMessages(const Chats: TChatList);
begin
  Gestor.AdministrarChatList(iWhatsapp, Chats);
end;

procedure TdmPrincipal.LimpaConversaBackup(Conversa: TBotConversa);
var
  Tabela: TFDTable;
begin
  Tabela := CriaTabela('conversa_backup');

  if Tabela.Locate('id_wpp', Conversa.ID, []) then
    Tabela.Delete;

  Tabela.Post;

end;

function TdmPrincipal.MenuInicial(Conversa: TBotConversa): String;
Var
  txSaudacao: String;
begin

  if time > StrToDateTime('06:00') then
  begin
    txSaudacao := 'bom dia';
  end;
  if time > StrToDateTime('12:00') then
  begin
    txSaudacao := 'boa tarde';
  end;
  if time > StrToDateTime('18:00') then
  begin
    txSaudacao := 'boa noite';
  end;

  Result := dm.DADOS_EMPRESA.FieldByName('MENSAGEM_INICIAL').AsString;
  Result := StringReplace(Result, '[NOME_CLIENTE]', trim(Conversa.Nome),
    [rfReplaceAll]);
  Result := StringReplace(Result, '[SAUDACAO]', trim(txSaudacao),
    [rfReplaceAll]);
  Result := StringReplace(Result, '[NOME_EMPRESA]',
    trim(dm.DADOS_EMPRESA.FieldByName('NOME').AsString), [rfReplaceAll]);
  Result := StringReplace(Result, '[TECLA_DELIVERY]', 'D', [rfReplaceAll]);
  Result := StringReplace(Result, '[TECLA_VEMBUSCAR]', 'V', [rfReplaceAll]);
end;

function TdmPrincipal.ParametrosDadosEmpresa: TFDMemTable;
begin
  Result := dm.DADOS_EMPRESA;
end;

end.
