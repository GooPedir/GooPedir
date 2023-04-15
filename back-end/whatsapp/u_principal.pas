unit u_principal;

interface

uses

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  DataSet.Serialize,
  // ############ ATENCAO AQUI ####################
  // units adicionais obrigatorias
  uTInject.ConfigCEF, uTInject, uTInject.Constant, uTInject.JS,
  uInjectDecryptFile,
  uTInject.Console, uTInject.Diversos, uTInject.AdjustNumber, uTInject.Config,
  uTInject.Classes,

  // units Opcionais (dependendo do que ira fazer)
  System.NetEncoding, System.TypInfo, WinInet,

  Vcl.StdCtrls, System.ImageList, Vcl.ImgList, Vcl.AppEvnts, Vcl.ComCtrls,
  Vcl.Imaging.pngimage, Vcl.Buttons, Vcl.Mask, Data.DB, Vcl.DBCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.Dialogs, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, Vcl.OleCtrls, SHDocVw, IdHTTP, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, Vcl.Imaging.jpeg,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, uRequisicao;

type
  TfrmPrincipal = class(TForm)
    TInject1: TInject;
    OpenDialog1: TOpenDialog;
    TrayIcon1: TTrayIcon;
    ImageList1: TImageList;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    memo_unReadMessage: TMemo;
    StatusBar1: TStatusBar;
    groupEnvioMsg: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    mem_message: TMemo;
    btSendTextAndFile: TButton;
    btSendText: TButton;
    Panel1: TPanel;
    groupListaChats: TGroupBox;
    Button3: TButton;
    listaChats: TListView;
    groupListaContatos: TGroupBox;
    Splitter1: TSplitter;
    ed_num: TComboBox;
    Pnl_Config: TPanel;
    Panel2: TPanel;
    Lbl_Avisos: TLabel;
    CheckBox5: TCheckBox;
    Label3: TLabel;
    Panel3: TPanel;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit1: TLabeledEdit;
    chk_apagarMsg: TCheckBox;
    btStatusBat: TButton;
    Panel4: TPanel;
    Button2: TButton;
    chk_AutoResposta: TCheckBox;
    ComboBox1: TComboBox;
    Label5: TLabel;
    listaContatos: TListView;
    Pnl_FONE: TPanel;
    Edt_LengDDD: TLabeledEdit;
    Edt_LengDDI: TLabeledEdit;
    Edt_LengFone: TLabeledEdit;
    Edt_DDIPDR: TLabeledEdit;
    CheckBox4: TCheckBox;
    btSendContact: TButton;
    SpeedButton3: TSpeedButton;
    btCheckNumber: TButton;
    btIsConnected: TButton;
    btSendLocation: TButton;
    btSendLinkWithPreview: TButton;
    Label6: TLabel;
    ed_videoLink: TEdit;
    Button1: TButton;
    Image2: TImage;
    ed_profilePicThumbURL: TEdit;
    TabSheet2: TTabSheet;
    Panel5: TPanel;
    Panel6: TPanel;
    listaGrupos: TListView;
    GroupBox1: TGroupBox;
    Button4: TButton;
    listaParticipantes: TListView;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    lbl_idGroup: TLabel;
    lbl_idParticipant: TLabel;
    edt_nomeGrupo: TEdit;
    edt_foneParticipante: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    Button11: TButton;
    Button12: TButton;
    ed_idParticipant: TEdit;
    Label4: TLabel;
    edt_groupInviteLink: TEdit;
    Label7: TLabel;
    listaAdministradores: TListView;
    Label10: TLabel;
    GroupBox2: TGroupBox;
    btCleanChat: TButton;
    btGetMe: TButton;
    btnTestCheckNumber: TButton;
    btGetSeveralStatus: TButton;
    btGetStatus: TButton;
    Panel7: TPanel;
    btSetProfileName: TButton;
    btSetProfileStatus: TButton;
    ed_profileData: TEdit;
    Image3: TImage;
    Button19: TButton;
    btnRemoveGroupLink: TButton;
    lblNumeroConectado: TLabel;
    lblContactStatus: TLabel;
    lblContactNumber: TLabel;
    Label11: TLabel;
    btSendTextButton: TButton;
    SpeedButton2: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton11: TSpeedButton;
    SpeedButton7: TSpeedButton;
    btnSendPool: TButton;
    btSendButtonList: TButton;
    Rdb_FormaConexao: TRadioGroup;
    SpeedButton1: TSpeedButton;
    RequisicaoVencidas: iRequisicao;
    dadosEnvio: TFDMemTable;
    tLoad: TTimer;
    iConfirmaEnvio: iRequisicao;
    Timer2: TTimer;
    lblStatus: TLabel;
    whatsOff: TImage;
    whatsOn: TImage;
    Image1: TImage;
    lStatusFaturamento: TLabel;
    RequisicaoPIX: iRequisicao;
    dadosPIX: TFDMemTable;
    iRequisicao1: iRequisicao;
    memDadosWhatsapp: TFDMemTable;
    memDadosWhatsappmensagemInicio: TStringField;
    memDadosWhatsappmensagem_Inicio: TStringField;
    memDadosWhatsappnome: TStringField;
    RequisicaoCelular: iRequisicao;
    memCliente: TFDMemTable;
    memClientenome: TStringField;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btSendTextClick(Sender: TObject);
    procedure btSendTextAndFileClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);

    procedure TInject1GetUnReadMessages(Const Chats: TChatList);
    procedure listaChatsDblClick(Sender: TObject);
    procedure listaContatosDblClick(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TInject1GetStatus(Sender: TObject);
    procedure Edt_DDIPDRExit(Sender: TObject);
    procedure ed_numChange(Sender: TObject);
    procedure ed_numSelect(Sender: TObject);
    procedure TInject1GetMyNumber(Sender: TObject);
    procedure TInject1ErroAndWarning(Sender: TObject;
      const PError, PInfoAdc: string);
    procedure Timer2Timer(Sender: TObject);
    procedure TInject1GetChatList(const Chats: TChatList);
    procedure TInject1GetAllContactList(const AllContacts: TRetornoAllContacts);
    procedure SpeedButton1Click(Sender: TObject);
    procedure TInject1GetQrCode(COnst Sender: TObject;
      const QrCode: TResultQRCodeClass);
    procedure whatsOnClick(Sender: TObject);
    procedure TInject1LowBattery(Sender: TObject);
    procedure TInject1DisconnectedBrute(Sender: TObject);
    procedure chk_3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure btSendContactClick(Sender: TObject);
    procedure listaContatosClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure btCheckNumberClick(Sender: TObject);
    procedure TInject1GetCheckIsValidNumber(Sender: TObject; Number: string;
      IsValid: Boolean);
    procedure btIsConnectedClick(Sender: TObject);
    procedure TInject1IsConnected(Sender: TObject; Connected: Boolean);
    procedure TInject1GetBatteryLevel(Sender: TObject);
    procedure btSendLinkWithPreviewClick(Sender: TObject);
    procedure btSendLocationClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure WebBrowser1DocumentComplete(ASender: TObject;
      const pDisp: IDispatch; const URL: OleVariant);
    procedure TInject1GetProfilePicThumb(Sender: TObject; Base64: string);
    procedure Button5Click(Sender: TObject);
    procedure listaGruposClick(Sender: TObject);
    procedure TInject1GetAllGroupList(const AllGroups: TRetornoAllGroups);
    procedure TInject1GetAllGroupContacts(const Contacts
      : TClassAllGroupContacts);
    procedure listaParticipantesClick(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure TInject1GetAllGroupAdmins(const AllGroups
      : TRetornoAllGroupAdmins);
    procedure btSetProfileNameClick(Sender: TObject);
    procedure btnRemoveGroupLinkClick(Sender: TObject);
    procedure btSetProfileStatusClick(Sender: TObject);
    procedure btCleanChatClick(Sender: TObject);
    procedure btGetStatusClick(Sender: TObject);
    procedure TInject1GetStatusMessage(const Result: TResponseStatusMessage);
    procedure btGetSeveralStatusClick(Sender: TObject);
    procedure Button19Click(Sender: TObject);
    procedure TInject1GetInviteGroup(const Invite: string);
    procedure TInject1GetMe(const vMe: TGetMeClass);
    procedure btGetMeClick(Sender: TObject);
    procedure btnTestCheckNumberClick(Sender: TObject);
    procedure TInject1NewGetNumber(const vCheckNumber: TReturnCheckNumber);
    procedure listaChatsClick(Sender: TObject);
    procedure ed_numKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SpeedButton4Click(Sender: TObject);
    procedure TInject1Disconnected(Sender: TObject);
    procedure SpeedButton8Click(Sender: TObject);
    procedure SpeedButton11Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure btSendTextButtonClick(Sender: TObject);
    procedure TInject1GetIncomingCall(const incomingCall: TReturnIncomingCall);
    procedure btSendButtonListClick(Sender: TObject);
    procedure tLoadTimer(Sender: TObject);

    procedure EnviaAtualizacao;
    function ConverterHora(Hora: String): TDateTime;
    function RemoveNonoDigito(telefone: string): string;
    function NonoDigito(telefone: string): string;

  private
    { Private declarations }
    FIniciando: Boolean;
    FStatus: Boolean;
    FNameContact: string;
    FChatID: string;
    Procedure ExecuteFilter;

  public
    { Public declarations }
    mensagem: string;
    AFile: string;

    procedure AddChatList(ANumber: String);
    procedure AddContactList(ANumber: String);
    procedure AddGroupList(ANumber: string);
    procedure AddGroupAdmins(ANumber: string);
    procedure AddGroupContacts(ANumber: string);
    function VerificaPalavraChave(pMensagem, pSessao, pTelefone,
      pContato: String): Boolean;
    function MenuInicial(Texto, nome: String): String;
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses
  Datasnap.DBClient, Winapi.ShellAPI, System.AnsiStrings, System.JSON;

{$R *.dfm}

procedure TfrmPrincipal.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  self.Height := 267;
  self.Width := 316;

  try
    iRequisicao1.Execute;
    if iRequisicao1.Status = 200 then
    begin
      memDadosWhatsapp.LoadFromJSON(iRequisicao1.Retorno);
    end;
  except

  end;

  ReportMemoryLeaksOnShutdown := false;
  PageControl1.ActivePageIndex := 0;
  FIniciando := True;
  try
    ComboBox1.Items.Clear;
    for I := 0 to 3 do
    Begin
      ComboBox1.Items.Add(GetEnumName(TypeInfo(TLanguageInject),
        ord(TLanguageInject(I))));
    End;

    GlobalCEFApp.LogConsoleActive := True;
    ComboBox1.ItemIndex := Integer(TInject1.LanguageInject);
    TabSheet2.TabVisible := false;
    TabSheet3.TabVisible := false;
    TabSheet4.TabVisible := false;
    chk_apagarMsg.Checked := TInject1.Config.AutoDelete;
    LabeledEdit1.text := TInject1.Config.ControlSendTimeSec.ToString;
    LabeledEdit2.text := TInject1.Config.SecondsMonitor.ToString;
  finally
    FIniciando := false;
  end;
  if not TInject1.Auth(false) then
  Begin
    TInject1.FormQrCodeType := TFormQrCodeType(Rdb_FormaConexao.ItemIndex);
    TInject1.FormQrCodeStart;
  End;

  if not TInject1.FormQrCodeShowing then
    TInject1.FormQrCodeShowing := True;
end;

procedure TfrmPrincipal.AddContactList(ANumber: String);
var
  Item: TListItem;
begin
  Item := listaContatos.Items.Add;
  if Length(ANumber) < 12 then
    ANumber := '55' + ANumber;
  Item.Caption := ANumber;
  Item.SubItems.Add(Item.Caption + 'SubItem 1');
  Item.SubItems.Add(Item.Caption + 'SubItem 2');
  Item.ImageIndex := 0;
end;

procedure TfrmPrincipal.AddGroupAdmins(ANumber: string);
var
  Item: TListItem;
begin
  Item := listaAdministradores.Items.Add;
  Item.Caption := ANumber;
  Item.SubItems.Add(Item.Caption + 'SubItem 1');
  Item.SubItems.Add(Item.Caption + 'SubItem 2');
  Item.ImageIndex := 0;
end;

procedure TfrmPrincipal.AddGroupContacts(ANumber: string);
var
  Item: TListItem;
begin
  Item := listaParticipantes.Items.Add;
  Item.Caption := ANumber;
  Item.SubItems.Add(Item.Caption + 'SubItem 1');
  Item.SubItems.Add(Item.Caption + 'SubItem 2');
  Item.ImageIndex := 0;
end;

procedure TfrmPrincipal.AddGroupList(ANumber: string);
var
  Item: TListItem;
begin
  Item := listaGrupos.Items.Add;
  Item.Caption := ANumber;
  Item.SubItems.Add(Item.Caption + 'SubItem 1');
  Item.SubItems.Add(Item.Caption + 'SubItem 2');
  Item.ImageIndex := 0;
end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  TInject1.ShutDown;
  // FreeAndNil(GlobalCEFApp);
end;

Procedure TfrmPrincipal.AddChatList(ANumber: String);
var
  Item: TListItem;
begin
  Item := listaChats.Items.Add;
  if Length(ANumber) < 12 then
    ANumber := '55' + ANumber;
  Item.Caption := ANumber;
  Item.SubItems.Add(Item.Caption + 'SubItem 1');
  Item.SubItems.Add(Item.Caption + 'SubItem 2');
  Item.ImageIndex := 2;
end;

procedure TfrmPrincipal.ApplicationEvents1Minimize(Sender: TObject);
begin
  self.Hide();
  self.WindowState := wsMinimized;
  TrayIcon1.Visible := True;
  TrayIcon1.Animate := True;
  TrayIcon1.ShowBalloonHint;
end;

procedure TfrmPrincipal.btCheckNumberClick(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  // TInject1.CheckIsValidNumber(ed_num.Text); deprecated
  TInject1.NewCheckIsValidNumber(ed_num.text);
end;

procedure TfrmPrincipal.btSendButtonListClick(Sender: TObject);
const
  options = '[' +
    '{ title: "Na Hora", rows: [{ title: "💵 Dinheiro", description: "Pagar no local.", }]},'
    + '{ title: "On-line", rows: [{ title: "💱 Pix", description: "Chave: comercial.softmais@gmail.com",},'
    + '{ title: "1 Cartão Crédito", description: "Parcelar em 1x", },' +
    '{ title: "2 Cartão Crédito", description: "Parcelar em 2x", },' +
    '{ title: "3 Cartão Crédito", description: "Parcelar em 3x", },' +
    '{ title: "4 Cartão Crédito", description: "Parcelar em 4x", },' +
    '{ title: "5 Cartão Crédito", description: "Parcelar em 5x", },' + ']}]';

begin
  try
    if not TInject1.Auth then
      Exit;

    TInject1.sendButtonList(ed_num.text, mem_message.text,
      'TInject Community. Valor total da sua compra: R$299',
      'Escolha uma opção de pagamento:', options);
  finally
    ed_num.SelectAll;
    ed_num.SetFocus;
  end;

end;

procedure TfrmPrincipal.btSendContactClick(Sender: TObject);
begin
  try
    if not TInject1.Auth then
      Exit;
    // Dest                    Contact
    // ex: 558199301443@c.us   558187576958@c.us
    TInject1.sendContact(ed_num.text, mem_message.text);
  finally
    ed_num.SelectAll;
    ed_num.SetFocus;
  end;
end;

procedure TfrmPrincipal.btSendLinkWithPreviewClick(Sender: TObject);
begin
  try
    if not TInject1.Auth then
      Exit;

    TInject1.sendLinkPreview(ed_num.text, ed_videoLink.text, mem_message.text);
  finally
    ed_num.SelectAll;
    ed_num.SetFocus;
  end;
end;

procedure TfrmPrincipal.btSendLocationClick(Sender: TObject);
begin
  try
    if not TInject1.Auth then
      Exit;
    // number        lat         lgn        Message link
    TInject1.sendLocation(ed_num.text, '-70.4078', '25.3789',
      'Segue a localização');
  finally
    ed_num.SelectAll;
    ed_num.SetFocus;
  end;
end;

procedure TfrmPrincipal.btSendTextAndFileClick(Sender: TObject);
Begin
  if not OpenDialog1.Execute then
    Exit;

  try
    if not TInject1.Auth then
      Exit;

    TInject1.SendFile(ed_num.text, OpenDialog1.FileName, mem_message.text);
  finally
    ed_num.SelectAll;
    ed_num.SetFocus;
  end;
end;

procedure TfrmPrincipal.btSendTextButtonClick(Sender: TObject);
const
  Buttons = '[{buttonId: "id1", buttonText:{displayText: "OPTION1"}, type: 1}, {buttonId: "id2", buttonText: {displayText: "OPTION2"}, type: 1}]';
const
  footer = 'Choose option';
begin
  try
    if not TInject1.Auth then
      Exit;

    TInject1.sendButtons(ed_num.text, mem_message.text, Buttons, footer);
  finally
    ed_num.SelectAll;
    ed_num.SetFocus;
  end;

end;

procedure TfrmPrincipal.btIsConnectedClick(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.CheckIsConnected();
end;

{ procedure TfrmPrincipal.btNewCheckNumberClick(Sender: TObject);
  begin



  end;



  Funcao nao utilizada
  function DownloadArquivo(const Origem, Destino: String): Boolean;
  const BufferSize = 1024;
  var
  hSession, hURL: HInternet;
  Buffer: array[1..BufferSize] of Byte;
  BufferLen: DWORD;
  f: File;
  sAppName: string;
  begin
  Result   := False;
  sAppName := ExtractFileName(Application.ExeName);
  hSession := InternetOpen(PChar(sAppName),
  INTERNET_OPEN_TYPE_PRECONFIG,
  nil, nil, 0);
  try
  hURL := InternetOpenURL(hSession,
  PChar(Origem),
  nil,0,0,0);
  try
  AssignFile(f, Destino);
  Rewrite(f,1);
  repeat
  InternetReadFile(hURL, @Buffer,
  SizeOf(Buffer), BufferLen);
  BlockWrite(f, Buffer, BufferLen)
  until BufferLen = 0;
  CloseFile(f);
  Result:=True;
  finally
  InternetCloseHandle(hURL)
  end
  finally
  InternetCloseHandle(hSession)
  end
  end; }

procedure TfrmPrincipal.Button10Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.groupJoinViaLink(edt_groupInviteLink.text);
end;

procedure TfrmPrincipal.Button11Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.groupLeave(lbl_idGroup.Caption);
end;

procedure TfrmPrincipal.Button12Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.groupDelete(lbl_idGroup.Caption);
end;

procedure TfrmPrincipal.btGetSeveralStatusClick(Sender: TObject);
begin

  try

    FStatus := false;
    if not TInject1.Auth then
      Exit;

    TInject1.GetStatusContact('558196988474@c.us');
    TInject1.GetStatusContact('558198007759@c.us');
  finally

  end;

end;

procedure TfrmPrincipal.btGetMeClick(Sender: TObject);
begin

  try

    if not TInject1.Auth then
      Exit;

    TInject1.GetMe();
  finally

  end;

end;

procedure TfrmPrincipal.Button19Click(Sender: TObject);
begin

  if not TInject1.Auth then

    Exit;

  TInject1.GetGroupInviteLink(lbl_idGroup.Caption);
  // '558192317066-1592044430@g.us'

end;

procedure TfrmPrincipal.btCleanChatClick(Sender: TObject);
begin

  if not TInject1.Auth then

    Exit;

  TInject1.CleanALLChat(ed_num.text);

end;

procedure TfrmPrincipal.btGetStatusClick(Sender: TObject);
begin

  try

    FStatus := True;
    if not TInject1.Auth then
      Exit;

    TInject1.GetStatusContact(ed_num.text);
  finally

  end;

end;

procedure TfrmPrincipal.btnRemoveGroupLinkClick(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.sendPool(edt_nomeGrupo.text,
    'TInject Community. Novo recurso de Enquete: Qual a melhor linguagem?',
    '["DELPHI", "JAVA", "C#", "PYTHON", "JAVASCRIPT", "PHP"]');
end;

procedure TfrmPrincipal.btSetProfileNameClick(Sender: TObject);
begin

  try

    if not TInject1.Auth then
      Exit;

    TInject1.SetProfileName(ed_profileData.text);
  finally

  end;

end;

procedure TfrmPrincipal.btSetProfileStatusClick(Sender: TObject);
begin

  try

    if not TInject1.Auth then
      Exit;

    TInject1.SetStatus(ed_profileData.text);
  finally

  end;

end;

procedure TfrmPrincipal.btnTestCheckNumberClick(Sender: TObject);
begin

  if not TInject1.Auth then

    Exit;

  TInject1.NewCheckIsValidNumber('558195833533@c.us');

  TInject1.NewCheckIsValidNumber('558195833532@c.us');

  TInject1.NewCheckIsValidNumber('558195833531@c.us');

end;

procedure TfrmPrincipal.Button1Click(Sender: TObject);
var
  JS: string;
begin
  if (not TInject1.Auth) then
    Exit;

  TInject1.getProfilePicThumb(FChatID);
end;

procedure TfrmPrincipal.Button2Click(Sender: TObject);
begin
  TInject1.getAllContacts;
end;

procedure TfrmPrincipal.Button3Click(Sender: TObject);
begin
  TInject1.getAllChats;
end;

procedure TfrmPrincipal.Button4Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.createGroup(edt_nomeGrupo.text, edt_foneParticipante.text);
  edt_nomeGrupo.Clear;
  edt_foneParticipante.Clear;
end;

procedure TfrmPrincipal.Button5Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.getAllGroups;
end;

procedure TfrmPrincipal.Button6Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.groupAddParticipant(lbl_idGroup.Caption, ed_idParticipant.text);
end;

procedure TfrmPrincipal.btSendTextClick(Sender: TObject);
begin
  try
    if not TInject1.Auth then
      Exit;

    TInject1.send(ed_num.text, mem_message.text);
  finally
    ed_num.SelectAll;
    ed_num.SetFocus;
  end;
end;

procedure TfrmPrincipal.Button7Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.groupRemoveParticipant(lbl_idGroup.Caption, ed_idParticipant.text);
end;

procedure TfrmPrincipal.Button8Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.groupPromoteParticipant(lbl_idGroup.Caption, ed_idParticipant.text);
end;

procedure TfrmPrincipal.Button9Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.groupDemoteParticipant(lbl_idGroup.Caption, ed_idParticipant.text);
end;

procedure TfrmPrincipal.chk_3Click(Sender: TObject);
begin
  ExecuteFilter;
end;

function TfrmPrincipal.ConverterHora(Hora: String): TDateTime;
begin
  try
    if pos('T', Hora) > 0 then
      Result := StrToTime(copy(Hora, 12, 8))
    else
      Result := StrToTime(copy(Hora, 0, 8));
  except
    Result := StrToTime(copy(Hora, 11, 8));
  end;
end;

procedure TfrmPrincipal.ed_numChange(Sender: TObject);
var
  LRet: TStringList;
  I: Integer;
  Ltexto: String;
begin
  // Esta processando outro CHANGE
  if not CheckBox5.Checked then
    Exit;

  if ed_num.AutoComplete = false Then
    Exit;

  {
    ##### modo 1
    TInject1.GetContacts(ComboBox1.Text, ComboBox1.Items);
    if ComboBox1.Items.Count <= 0 then
    ComboBox1.Style := csSimple else
    ComboBox1.Style := csOwnerDrawFixed;


    ##### modo 2
  }

  LRet := TStringList.Create;
  ed_num.AutoComplete := false;
  Ltexto := ed_num.text;
  try
    ed_num.Items.Clear;
    if LRet.Count <= 0 then
      ed_num.Style := csSimple
    else
      ed_num.Style := csDropDown;

    for I := 0 to LRet.Count - 1 do
      ed_num.Items.Add(LRet.Strings[I]);
  finally
    ed_num.text := Ltexto;
    ed_num.SelStart := Length(Ltexto);
    ed_num.AutoComplete := True;
    FreeAndNil(LRet);
  end;
end;

procedure TfrmPrincipal.ed_numKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin

  lblContactNumber.Caption := ed_num.text;

  lblContactStatus.Caption := '-';

end;

procedure TfrmPrincipal.ed_numSelect(Sender: TObject);
begin
  if not CheckBox5.Checked then
    Exit;

  if (ed_num.ItemIndex >= 0) and (ed_num.Items.Count > 0) then
  Begin
    ed_num.AutoComplete := false;
    ed_num.text := ed_num.Items.Strings[ed_num.ItemIndex];
    ed_num.AutoComplete := True;
  End;
end;

procedure TfrmPrincipal.EnviaAtualizacao;
const
  MENSAGEM_QUEBRA_LINHA = '\n';
  MENSAGEM_QUEBRA_LINHA_DUPLA = '\n\n';
  FORMATA_CAMPO_MENU = '00';
  MONO_ESPACADA = '```';
  MEU_NUMERO = '5548998111156@c.us';
var
  RequisicaoDados: iRequisicao;
  Dados: TFDMemTable;
  Celular: String;
  Celular9: String;
  mensagem: String;
  Cabecalho: String;
  Status: String;
  Origem: String;
  Agradecimento: String;
  TipoPedido: String;
  NrPedido: Integer;
  TotalPedido: Real;
  Cancelado: Boolean;
  Horario: TDateTime;
  Motivo: String;
  Resumo: Boolean;
  Enviar: Boolean;
  mensagemResumo: String;
begin
  RequisicaoDados := iRequisicao.Create(self);
  Dados := TFDMemTable.Create(self);
  RequisicaoDados.URL := 'http://localhost:2121/v1/util/status/pedido';
  RequisicaoDados.MemTable2 := Dados;
  RequisicaoDados.Execute;

  while not Dados.Eof do
  begin
    NrPedido := Dados.FieldByName('codigo_pedido_dia').AsInteger;
    TotalPedido := Dados.FieldByName('valor_total_pedido').AsFloat;
    Celular := '55'+RemoveNonoDigito(Dados.FieldByName('celular').AsString) + '@c.us';
    Celular9 := '55'+NonoDigito(Dados.FieldByName('celular_wpp').AsString) + '@c.us';

    Horario := ConverterHora(Dados.FieldByName('hora_pedido').AsString);
    Cancelado := false;

    case Dados.FieldByName('origem').AsInteger of
      1:
        begin
          Origem := 'whatsapp';
        end;
      2:
        begin
          Origem := 'site';
        end
    else
      begin
        Origem := '';
      end;
    end;
    case Dados.FieldByName('codigo_cliente_endereco').AsInteger of
      0:
        begin
          TipoPedido := 'VEM BUSCAR';
        end
    else
      begin
        TipoPedido := 'DELIVERY';
      end;

    end;

    case Dados.FieldByName('status').AsInteger of
      0:
        begin
          // Cancelamento
          Status := 'Cancelado';
          Cancelado := True;
          Motivo := trim(Dados.FieldByName('motivo_cancelamento').AsString);
        end;
      4:
        begin
          // Disponivel pra retirada
          Status := 'Pronto para retirada no balção';
        end;
      5:
        begin
          // Saiu para entrega

          Status := 'Saiu para entrega';
        end;
      // Apenas quando site
      1:
        begin
          // Pedido Aceito
          // nesse momento aki vai mandar o resumo
          if Dados.FieldByName('origem').AsInteger = 2 then
          begin
            Status := 'Pedido aceito';
            Resumo := True;

            // mensagemResumo := BuscaResumo(Dados.FieldByName('codigo').AsInteger,
            // Dados.FieldByName('codigo_cliente_endereco').AsInteger);
          end
          else
          begin
            Enviar := false;
          end;
        end;
      9:
        begin
          // Aguardando

          if Dados.FieldByName('origem').AsInteger = 2 then
          begin
            Status := 'Aguardando ser aceito pelo estabelecimento';
            Resumo := True;

            // mensagemResumo := BuscaResumo(FQRY.FieldByName('codigo').AsInteger,
            // FQRY.FieldByName('codigo_cliente_endereco').AsInteger);
            //
          end
          else
          begin
            Enviar := false;
          end;
        end;
    end;
    mensagem := Cabecalho + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + MONO_ESPACADA + '--- ' + TipoPedido + ' ---' +
      MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*Nº Pedido:* ' + MONO_ESPACADA +
      FormatFloat('000', NrPedido) + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*Recebimento:* ' + MONO_ESPACADA +
      FormatDateTime('hh:mm', Horario) + 'h' + MONO_ESPACADA +
      MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*Valor R$:* ' + MONO_ESPACADA +
      FormatFloat('#0.00', TotalPedido) + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;
    mensagem := mensagem + '*Status:* ' + MONO_ESPACADA + Status + MONO_ESPACADA
      + MENSAGEM_QUEBRA_LINHA_DUPLA;

    mensagem := mensagem + MONO_ESPACADA + 'Pedido feito através do nosso ' +
      Origem + '!' + MONO_ESPACADA + MENSAGEM_QUEBRA_LINHA;

    if Cancelado then
    begin

      mensagem := mensagem + MONO_ESPACADA +
        'Lamentamos seu pedido foi cancelado.' + MONO_ESPACADA +
        MENSAGEM_QUEBRA_LINHA;
      if Length(Motivo) > 0 then
        mensagem := mensagem + '*Motivo:* ' + MONO_ESPACADA + Motivo +
          MONO_ESPACADA;
    end
    else
    begin
      mensagem := mensagem + MONO_ESPACADA + 'Agradeçemos sua preferência.' +
        MONO_ESPACADA;
    end;

    try
      TInject1.send(Celular, mensagem);
    except

    end;
    try
      TInject1.send(Celular9, mensagem);
    except

    end;

    Dados.Next;
  end;

  Dados.Free;
  RequisicaoDados.Free;
end;

procedure TfrmPrincipal.ExecuteFilter;
begin
  //
end;

procedure TfrmPrincipal.Edt_DDIPDRExit(Sender: TObject);
begin
  if FIniciando then
    Exit;

  TInject1.Config.AutoDelete := chk_apagarMsg.Checked;
  // TInject1.Config.AutoStart           := chk_AutoStart.Checked;

  TInject1.Config.ControlSendTimeSec := StrToIntDef(LabeledEdit1.text, 8);
  TInject1.Config.SecondsMonitor := StrToIntDef(LabeledEdit2.text, 3);


  // TInject1.Config.ShowRandom          := .Checked;
  // TInject1.Config.SyncContacts        := .Checked;

  TInject1.AjustNumber.LengthDDI := StrToIntDef(Edt_LengDDI.text, 2);
  TInject1.AjustNumber.LengthDDD := StrToIntDef(Edt_LengDDD.text, 2);
  TInject1.AjustNumber.LengthPhone := StrToIntDef(Edt_LengFone.text, 8);
  TInject1.AjustNumber.DDIDefault := StrToIntDef(Edt_DDIPDR.text, 55);
  TInject1.AjustNumber.AllowOneDigitMore := CheckBox4.Checked;

  ExecuteFilter;

  TInject1.LanguageInject := TLanguageInject(ComboBox1.ItemIndex);
end;

procedure TfrmPrincipal.TInject1Disconnected(Sender: TObject);
begin
  ShowMessage('Conexão foi finalizada');
end;

procedure TfrmPrincipal.TInject1DisconnectedBrute(Sender: TObject);
begin
  ShowMessage('Conexão foi finalizada pelo celular');
end;

procedure TfrmPrincipal.TInject1ErroAndWarning(Sender: TObject;
  const PError, PInfoAdc: string);
begin
  Timer2.Enabled := false;
  Lbl_Avisos.Caption := PError + ' -> ' + PInfoAdc;
  Lbl_Avisos.Font.Color := clBlack;

  Timer2.Enabled := True;
end;

procedure TfrmPrincipal.TInject1GetAllContactList(const AllContacts
  : TRetornoAllContacts);
var
  AContact: TContactClass;
begin
  listaContatos.Clear;

  for AContact in AllContacts.Result do
  begin
    AddContactList(AContact.id + ' ' + AContact.name);
  end;

  AContact := nil;

end;

procedure TfrmPrincipal.TInject1GetAllGroupAdmins(const AllGroups
  : TRetornoAllGroupAdmins);
var
  I: Integer;
begin
  listaAdministradores.Clear;

  for I := 0 to (AllGroups.Numbers.Count) - 1 do
  begin
    AddGroupAdmins(AllGroups.Numbers[I])
  end;
end;

procedure TfrmPrincipal.TInject1GetAllGroupContacts(const Contacts
  : TClassAllGroupContacts);
var
  JSonValue: TJSonValue;
  ArrayRows: TJSONArray;
  I: Integer;
begin
  JSonValue := TJSonObject.ParseJSONValue(Contacts.Result);
  ArrayRows := JSonValue as TJSONArray;

  listaParticipantes.Clear;

  for I := 0 to ArrayRows.Size - 1 do
  begin
    AddGroupContacts(ArrayRows.Items[I].value)
  end;
end;

procedure TfrmPrincipal.TInject1GetAllGroupList(const AllGroups
  : TRetornoAllGroups);
var
  I: Integer;
begin
  listaGrupos.Clear;

  for I := 0 to (AllGroups.Numbers.Count) - 1 do
  begin
    AddGroupList(AllGroups.Numbers[I])
  end;

end;

procedure TfrmPrincipal.TInject1GetBatteryLevel(Sender: TObject);
begin
  Lbl_Avisos.Caption := 'O telefone ' + TInject(Sender).MyNumber + ' está com '
    + TInject(Sender).BatteryLevel.ToString + '% de bateria';
  btStatusBat.Caption := 'Status da bateria (' + TInject(Sender)
    .BatteryLevel.ToString + '%)';
end;

procedure TfrmPrincipal.TInject1GetChatList(const Chats: TChatList);
var
  AChat: TChatClass;
begin
  listaChats.Clear;
  for AChat in Chats.Result do
    AddChatList('(' + AChat.unreadCount.ToString + ') ' + AChat.name + ' - ' +
      AChat.id);
end;

procedure TfrmPrincipal.TInject1GetCheckIsValidNumber(Sender: TObject;
  Number: string; IsValid: Boolean);
begin
  if IsValid then
    ShowMessage('Whatsapp Valid -' + Number)
  else
    ShowMessage('Whatsapp Invalid');
end;

procedure TfrmPrincipal.TInject1GetIncomingCall(const incomingCall
  : TReturnIncomingCall);
begin
  memo_unReadMessage.text := 'Incoming call: ' + incomingCall.contact;
end;

procedure TfrmPrincipal.TInject1GetInviteGroup(const Invite: string);
begin
  edt_groupInviteLink.text := Invite;
  ShowMessage(Invite);
end;

procedure TfrmPrincipal.TInject1GetMe(const vMe: TGetMeClass);
var
  aList: TStringList;
begin

  try

    aList := TStringList.Create();

    aList.Add('Battery: ' + vMe.battery.ToString);

    aList.Add('LC: ' + vMe.lc);

    aList.Add('LG: ' + vMe.lg);

    aList.Add('Locate: ' + vMe.locate);

    if vMe.plugged then

      aList.Add('Plugged: true')

    else

      aList.Add('Plugged: false');

    aList.Add('Pushname: ' + vMe.pushname);

    aList.Add('ServerToken: ' + vMe.serverToken);

    aList.Add('Status: ' + vMe.Status.Status);

    aList.Add('Me: ' + vMe.me);

    aList.Add('Phone Device_Manufacturer:  ' + vMe.phone.device_manufacturer);

    aList.Add('Phone Device Model: ' + vMe.phone.device_model);

    aList.Add('Phone MCC: ' + vMe.phone.mcc);

    aList.Add('Phone MNC: ' + vMe.phone.mnc);

    aList.Add('Phone OS Builder Number: ' + vMe.phone.os_build_number);

    aList.Add('Phone OS Version: ' + vMe.phone.os_version);

    aList.Add('Phone wa Version: ' + vMe.phone.wa_version);

    if vMe.phone.InjectWorking then

      aList.Add('Phone InjectWorkink: true')

    else

      aList.Add('Phone InjectWorkin: false');

    ShowMessage(aList.text);

  finally

    aList.Free;

  end;

end;

procedure TfrmPrincipal.TInject1GetMyNumber(Sender: TObject);
begin
  lblNumeroConectado.Caption := TInject(Sender).MyNumber;
end;

procedure TfrmPrincipal.TInject1GetProfilePicThumb(Sender: TObject;
  Base64: string);
var
  LInput: TMemoryStream;
  LOutput: TMemoryStream;
  AStr: TStringList;
  lThread: TThread;
begin
  lThread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        LInput := TMemoryStream.Create;
        LOutput := TMemoryStream.Create;
        AStr := TStringList.Create;
        AStr.Add(Base64);
        AStr.SaveToStream(LInput);
        LInput.Position := 0;
        TNetEncoding.Base64.Decode(LInput, LOutput);
        LOutput.Position := 0;
{$IFDEF VER330}
        Image2.Picture.LoadFromStream(LOutput);
{$ELSE}
        Image2.Picture.Bitmap.LoadFromStream(LOutput);
{$ENDIF}
      finally
        LInput.Free;
        LOutput.Free;
        AStr.Free;
      end;
    end);
  lThread.FreeOnTerminate := True;
  lThread.Start;
end;

procedure TfrmPrincipal.TInject1GetQrCode(Const Sender: TObject;
const QrCode: TResultQRCodeClass);
begin
  if TInject1.FormQrCodeType = TFormQrCodeType(Ft_none) then
    Image1.Picture := QrCode.AQrCodeImage
  else
    Image1.Picture := nil; // Limpa foto
end;

procedure TfrmPrincipal.TInject1GetStatus(Sender: TObject);
// Const PStatus : TStatusType; Const PFormQrCode: TFormQrCodeType);
begin
  if not Assigned(Sender) Then
    Exit;

  try
    TabSheet2.TabVisible := (TInject(Sender).Status = Inject_Initialized);
    TabSheet3.TabVisible := (TInject(Sender).Status = Inject_Initialized);
    TabSheet4.TabVisible := (TInject(Sender).Status = Inject_Initialized);
  Except
  end;

  if (TInject(Sender).Status = Inject_Initialized) and (TInject1.Auth) then
  begin
    lblStatus.Caption := 'Online';
    lblStatus.Font.Color := $0000AE11;
    SpeedButton3.Enabled := True;
    tLoad.Enabled := True;
  end
  else
  begin
    SpeedButton3.Enabled := false;
    lblStatus.Caption := 'Offline';
    lblStatus.Font.Color := $002894FF;
    tLoad.Enabled := false;
  end;

  StatusBar1.Panels[1].text := lblStatus.Caption;
  whatsOn.Visible := SpeedButton3.Enabled;
  lblNumeroConectado.Visible := whatsOn.Visible;
  whatsOff.Visible := Not whatsOn.Visible;

  Label3.Visible := false;
  case TInject(Sender).Status of
    Server_ConnectedDown:
      Label3.Caption := TInject(Sender).StatusToStr;
    Server_Disconnected:
      Label3.Caption := TInject(Sender).StatusToStr;
    Server_Disconnecting:
      Label3.Caption := TInject(Sender).StatusToStr;
    Server_Connected:
      Label3.Caption := '';
    Server_Connecting:
      Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Initializing:
      Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Initialized:
      Label3.Caption := TInject(Sender).StatusToStr;
    Server_ConnectingNoPhone:
      Label3.Caption := TInject(Sender).StatusToStr;
    Server_ConnectingReaderCode:
      Label3.Caption := TInject(Sender).StatusToStr;
    Server_TimeOut:
      Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Destroying:
      Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Destroy:
      Label3.Caption := TInject(Sender).StatusToStr;
  end;
  If Label3.Caption <> '' Then
    Label3.Visible := True;

  If TInject(Sender).Status in [Server_ConnectingNoPhone, Server_TimeOut] Then
  Begin
    if TInject(Sender).FormQrCodeType = Ft_Desktop then
    Begin
      if TInject(Sender).Status = Server_ConnectingNoPhone then
        TInject1.FormQrCodeStop;
    end
    else
    Begin
      if TInject(Sender).Status = Server_ConnectingNoPhone then
      Begin
        if not TInject(Sender).FormQrCodeShowing then
          TInject(Sender).FormQrCodeShowing := True;
      end
      else
      begin
        TInject(Sender).FormQrCodeReloader;
      end;
    end;
  end;
end;

procedure TfrmPrincipal.TInject1GetStatusMessage(const Result
  : TResponseStatusMessage);

var

  I: Integer;

var

  AResult: String;

var

  cara: TResponseStatusMessage;

begin

  if FStatus = True then

  begin

    // lblContactStatus.Caption := Result.status ;
    ShowMessage(Result.id + ' - ' + Result.Status);

  end
  else

  begin

    ShowMessage(Result.id + ' - ' + Result.Status);

  end;

end;

procedure TfrmPrincipal.TInject1GetUnReadMessages(Const Chats: TChatList);
var
  AChat: TChatClass;
  AMessage: TMessagesClass;
  contato, telefone: string;
  injectDecrypt: TInjectDecryptFile;
  Cell: String;
  ddd: String;

begin
  for AChat in Chats.Result do
  begin
    for AMessage in AChat.Messages do
    begin
      if not AChat.isGroup then // Não exibe mensages de grupos
      begin

        if not AMessage.Sender.isMe then // Não exibe mensages enviadas por mim
        begin
          memo_unReadMessage.Clear;
          if memDadosWhatsapp.RecordCount > 0 then
          begin
            try
              memCliente.Close;
              Cell := AChat.id;
              Cell := StringReplace(Cell, '@c.us', '', [rfReplaceAll]);
              ddd := copy(Cell, 3, 2);
              Cell := copy(Cell, 5, 10);

              RequisicaoCelular.BaseURL :=
                'http://localhost:2121/v1/dados/consulta/cliente/celular/' +
                ddd + Cell;
              RequisicaoCelular.Execute;
              memCliente.LoadFromJSON(RequisicaoCelular.Retorno);

              if memCliente.RecordCount = 0 then
              begin
                RequisicaoCelular.BaseURL :=
                  'http://localhost:2121/v1/dados/consulta/cliente/celular/' +
                  ddd + '9' + Cell;
                RequisicaoCelular.Execute;
                memCliente.LoadFromJSON(RequisicaoCelular.Retorno);
              end;

              TInject1.send('554898111156@c.us',
                MenuInicial(memDadosWhatsapp.FieldByName('mensagem_Inicio')
                .AsString, memCliente.FieldByName('nome').AsString));
              Exit;

            except

            end;
          end;

        end;
      end;
    end;
  end;
end;

procedure TfrmPrincipal.TInject1IsConnected(Sender: TObject;
Connected: Boolean);
begin
  if Connected = True then
    ShowMessage('Conectado / Connected')
  else
    ShowMessage('Desconectado / Not connected')
end;

procedure TfrmPrincipal.TInject1LowBattery(Sender: TObject);
begin
  Timer2.Enabled := false;
  Lbl_Avisos.Caption := 'Alarme de BATERIA.  Você está com ' + TInject(Sender)
    .BatteryLevel.ToString + '%';
  Lbl_Avisos.Font.Color := clRed;
  Timer2.Enabled := True;
end;

procedure TfrmPrincipal.TInject1NewGetNumber(const vCheckNumber
  : TReturnCheckNumber);

begin
  if vCheckNumber.valid then
    ShowMessage(vCheckNumber.id + ' é um numero Válido')

  else
    ShowMessage(vCheckNumber.id + ' é um numero INVÁLIDO');

end;

procedure TfrmPrincipal.tLoadTimer(Sender: TObject);
var
  mensagem: String;
  I: Integer;
  telefone: String;

begin
  //

  if memDadosWhatsapp.RecordCount > 0 then
  begin
    EnviaAtualizacao;
  end
  else
  begin

    if (time > StrToTime('08:00:00')) and (time < StrToTime('18:00:00')) then
    begin
      lStatusFaturamento.Caption := 'Buscando Faturas';
      try
        dadosEnvio.Close;
        RequisicaoVencidas.Execute;
        if dadosEnvio.RecordCount > 0 then
        begin
          dadosEnvio.First;
          while not dadosEnvio.Eof do
          begin
            lStatusFaturamento.Caption := 'Enviando Mensagem';

            mensagem := '*' + UpperCase(dadosEnvio.FieldByName('company')
              .AsString) + '*\n\n';
            mensagem := mensagem +
              'Segue link para pagamento da sua fatura com vencimento dia *' +
              copy(dadosEnvio.FieldByName('duedate').AsString, 9, 2) + '/' +
              copy(dadosEnvio.FieldByName('duedate').AsString, 6, 2) + '/' +
              copy(dadosEnvio.FieldByName('duedate').AsString, 0, 4) + '*.\n';
            mensagem := mensagem + '*' + dadosEnvio.FieldByName('prefix')
              .AsString + copy(dadosEnvio.FieldByName('duedate').AsString, 0, 4)
              + '/' + FormatFloat('000000', dadosEnvio.FieldByName('number')
              .AsInteger) + '* \n';
            mensagem := mensagem + 'Valor R$: ' + FormatFloat('#0.00',
              StrToFloat(StringReplace(dadosEnvio.FieldByName('total').AsString,
              '.', ',', []))) + '\n\n';

            mensagem := mensagem +
              '*ATENÇÃO: Abra sempre o link no navegador, é apos o pagamento so feche quando aparecer "Pagamento Aprovado"!*\n';
            mensagem := mensagem + 'Link:\n';
            mensagem := mensagem + 'https://portal.goopedir.com/invoice/' +
              dadosEnvio.FieldByName('id').AsString + '/' +
              dadosEnvio.FieldByName('hash').AsString + '\n\n';

            mensagem := mensagem + 'Atenciosamente GooPedir.';

            telefone := '55' + dadosEnvio.FieldByName('phonenumber').AsString
              + '@c.us';
            TInject1.send(telefone, mensagem);
            // ShowMessage(mensagem);
            iConfirmaEnvio.URL := 'https://goopedir.com/ws/v1/wpp/' +
              dadosEnvio.FieldByName('id').AsString + '/a';
            // ShowMessage(iConfirmaEnvio.URL);
            iConfirmaEnvio.Execute;
            dadosEnvio.Next;
          end;
        end;
        {
          dadosPIX.Close;
          RequisicaoPIX.Execute;

          if dadosPIX.RecordCount > 0 then
          while not dadosPIX.Eof do
          begin
          mensagem := '*' + UpperCase(dadosPIX.FieldByName('company').AsString)
          + '*\n\n';
          mensagem := mensagem +
          'Recebemos seu pagamento via *PIX* no valor de R$ *' +
          FormatFloat('#0.00',
          StrToFloat(StringReplace(dadosPIX.FieldByName('amount').AsString,
          '.', ',', []))) + '*\n';
          mensagem := mensagem + '*Código da Transação: ' +
          dadosPIX.FieldByName('transactionid').AsString + '*\n\n';
          mensagem := mensagem + 'Atenciosamente GooPedir.';
          telefone := '55' + dadosPIX.FieldByName('phonenumber').AsString
          + '@c.us';
          TInject1.send(telefone, mensagem);
          iConfirmaEnvio.URL := 'https://goopedir.com/ws/v1/wpp/' +
          dadosPIX.FieldByName('invoiceid').AsString + '/a';
          // ShowMessage(iConfirmaEnvio.URL);
          iConfirmaEnvio.Execute;
          dadosPIX.Next;
          end;
        }
      except
        on E: Exception do
        begin
          ShowMessage(E.Message);
        end;

      end;
      lStatusFaturamento.Caption := 'Aguardando';
    end
    else
    begin
      lStatusFaturamento.Caption := 'Fora do Horário de Espediente';
    end;
  end;
end;

procedure TfrmPrincipal.listaChatsClick(Sender: TObject);
begin

  lblContactStatus.Caption := '-';

end;

procedure TfrmPrincipal.listaChatsDblClick(Sender: TObject);
begin
  ed_num.text := TInject1.GetChat(listaChats.Selected.Index).id;
  lblContactNumber.Caption := ed_num.text;
end;

procedure TfrmPrincipal.listaContatosClick(Sender: TObject);
begin
  mem_message.text := copy(listaContatos.Items[listaContatos.Selected.Index]
    .SubItems[1], 0, pos('@', listaContatos.Items[listaContatos.Selected.Index]
    .SubItems[1]) + 4);

  FNameContact := StringReplace(copy(listaContatos.Items[listaContatos.Selected.
    Index].SubItems[1], pos('@', listaContatos.Items[listaContatos.Selected.
    Index].SubItems[1]) + 6, Length(listaContatos.Items[listaContatos.Selected.
    Index].SubItems[1])), 'Subitem 2', '', [rfReplaceAll, rfIgnoreCase]);

  lblContactStatus.Caption := '-';
end;

procedure TfrmPrincipal.listaContatosDblClick(Sender: TObject);
begin
  ed_num.text := copy(listaContatos.Items[listaContatos.Selected.Index].SubItems
    [1], 0, pos('@', listaContatos.Items[listaContatos.Selected.Index].SubItems
    [1])) + 'c.us';

  lblContactNumber.Caption := ed_num.text;
end;

procedure TfrmPrincipal.listaGruposClick(Sender: TObject);
begin
  if listaGrupos.ItemIndex <> -1 then
  begin
    lbl_idGroup.Caption := copy(listaGrupos.Items[listaGrupos.Selected.Index]
      .SubItems[1], 0, pos('@', listaGrupos.Items[listaGrupos.Selected.Index]
      .SubItems[1])) + 'g.us';

    if not TInject1.Auth then
      Exit;

    TInject1.listGroupContacts(lbl_idGroup.Caption);
  end;
end;

procedure TfrmPrincipal.listaParticipantesClick(Sender: TObject);
begin
  if listaParticipantes.ItemIndex <> -1 then
  begin
    ed_idParticipant.text :=
      copy(listaParticipantes.Items[listaParticipantes.Selected.Index].SubItems
      [1], 0, pos('@', listaParticipantes.Items[listaParticipantes.Selected.
      Index].SubItems[1])) + 'c.us';
  end;
end;

function TfrmPrincipal.MenuInicial(Texto, nome: String): String;
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

  Result := Texto;
  Result := StringReplace(Result, '[NOME_CLIENTE]', trim(nome), [rfReplaceAll]);
  Result := StringReplace(Result, '[SAUDACAO]', trim(txSaudacao),
    [rfReplaceAll]);
  Result := StringReplace(Result, '[NOME_EMPRESA]',
    trim(memDadosWhatsapp.FieldByName('NOME').AsString), [rfReplaceAll]);
  Result := StringReplace(Result, '[TECLA_DELIVERY]', 'D', [rfReplaceAll]);
  Result := StringReplace(Result, '[TECLA_VEMBUSCAR]', 'V', [rfReplaceAll]);
end;

function TfrmPrincipal.NonoDigito(telefone: string): string;
begin

  if Length(telefone) = 10 then
    Result := Copy(telefone, 1, 2) +'9'+ Copy(telefone, 3, 10)
  else
    Result := telefone;
end;

function TfrmPrincipal.RemoveNonoDigito(telefone: string): string;
begin
  if Length(telefone) = 11 then
    Result := Copy(telefone, 1, 2) + Copy(telefone, 4, 10)
  else
    Result := telefone;
end;

procedure TfrmPrincipal.SpeedButton11Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'https://github.com/mikelustosa/Projeto-TInject',
    '', '', 1);
end;

procedure TfrmPrincipal.SpeedButton1Click(Sender: TObject);
begin
  if not TInject1.Auth(false) then
  Begin
    TInject1.FormQrCodeType := TFormQrCodeType(Rdb_FormaConexao.ItemIndex);
    TInject1.FormQrCodeStart;
  End;

  if not TInject1.FormQrCodeShowing then
    TInject1.FormQrCodeShowing := True;

end;

procedure TfrmPrincipal.SpeedButton2Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://mikelustosa.kpages.online/tinject',
    '', '', 1);
end;

procedure TfrmPrincipal.SpeedButton3Click(Sender: TObject);
begin
  if not TInject1.Auth then
    Exit;

  TInject1.Logtout;
  sleepNoFreeze(3000);
  TInject1.Disconnect;
end;

procedure TfrmPrincipal.SpeedButton4Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'https://www.youtube.com/user/mikelustosa',
    '', '', 1);
end;

procedure TfrmPrincipal.SpeedButton7Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open',
    'https://api.whatsapp.com/send?phone=558199301443&text=Preciso%20de%20suporte',
    '', '', 1);
end;

procedure TfrmPrincipal.SpeedButton8Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'https://youtu.be/dZ1RRXKbjCU', '', '', 1);
end;

procedure TfrmPrincipal.Timer2Timer(Sender: TObject);
begin
  Lbl_Avisos.Caption := '';
  Timer2.Enabled := false;
end;

procedure TfrmPrincipal.TrayIcon1Click(Sender: TObject);
begin
  TrayIcon1.Visible := false;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

function TfrmPrincipal.VerificaPalavraChave(pMensagem, pSessao, pTelefone,
  pContato: String): Boolean;
begin
  Result := false;
  if (pos('OLA', AnsiUpperCase(pMensagem)) > 0) or
    (pos('OLÁ', AnsiUpperCase(pMensagem)) > 0) or
    (pos('BOM DIA', AnsiUpperCase(pMensagem)) > 0) or
    (pos('BOA TARDE', AnsiUpperCase(pMensagem)) > 0) or
    (pos('BOA NOITE', AnsiUpperCase(pMensagem)) > 0) or
    (pos('INÍCIO', AnsiUpperCase(pMensagem)) > 0) or
    (pos('HELLO', AnsiUpperCase(pMensagem)) > 0) or
    (pos('HI', AnsiUpperCase(pMensagem)) > 0) or
    (pos('INICIO', AnsiUpperCase(pMensagem)) > 0) or
    (pos('OI', AnsiUpperCase(pMensagem)) > 0) then
  begin
    mensagem := TInject1.Emoticons.AtendenteH + 'Olá *' + pContato + '!*\n\n' +
      'Você está no auto atendimento do *TInject*!\n\n' +
      'Digite um número:\n\n' + TInject1.Emoticons.Um + ' Suporte\n\n' +
      TInject1.Emoticons.Dois + ' Consultar CEP\n\n' + TInject1.Emoticons.Tres +
      ' Financeiro\n\n' + TInject1.Emoticons.Quatro +
      ' Horários de atendimento\n\n';
    TInject1.SendFile(pTelefone, ExtractFileDir(Application.ExeName) +
      '\Img\softmais.png', mensagem);
    Result := True;
    Exit;
  end;
  Exit;
end;

procedure TfrmPrincipal.WebBrowser1DocumentComplete(ASender: TObject;
const pDisp: IDispatch; const URL: OleVariant);
begin
  { if WebBrowser1.Document <> nil then
    begin
    WebBrowser1.Document.QueryInterface(IViewObject, viewObject) ;
    if Assigned(viewObject) then
    try
    bitmap := TBitmap.Create;
    try
    r := Rect(0, 0, WebBrowser1.Width, WebBrowser1.Height) ;

    bitmap.Height := WebBrowser1.Height;
    bitmap.Width := WebBrowser1.Width;

    viewObject.Draw(DVASPECT_CONTENT, 1, nil, nil, Application.Handle, bitmap.Canvas.Handle, @r, nil, nil, 0) ;

    with TJPEGImage.Create do
    try
    Assign(bitmap) ;
    //SaveToFile(fileName) ;
    image2.Picture.Assign(bitmap);
    finally
    Free;
    end;
    finally
    bitmap.Free;
    end;
    finally
    viewObject._Release;
    end;
    end; }

end;

procedure TfrmPrincipal.whatsOnClick(Sender: TObject);
begin
  if not TInject1.FormQrCodeShowing then
    TInject1.FormQrCodeShowing := True;
end;

end.
